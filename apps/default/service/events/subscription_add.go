package events

import (
	"context"
	"errors"
	"fmt"
	"strings"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	eventsv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/events/v1"
	"github.com/antinvestor/service-chat/apps/default/service/models"
	"github.com/antinvestor/service-chat/apps/default/service/repository"
	chattel "github.com/antinvestor/service-chat/internal/telemetry"
	"github.com/pitabwire/frame/datastore/pool"
	frevents "github.com/pitabwire/frame/events"
	"github.com/pitabwire/frame/workerpool"
	"github.com/pitabwire/util"
)

const (
	SubscriptionAddEventName = "room.subscription.add.event"
)

type roomSubscriptionAddQueue struct {
	*roomChangeEventEmitter
	subscriptionRepo repository.RoomSubscriptionRepository
}

func NewSubscriptionAddQueue(
	ctx context.Context,
	dbPool pool.Pool,
	workMan workerpool.Manager,
	eventsManager frevents.Manager,
) frevents.EventI {
	return &roomSubscriptionAddQueue{
		roomChangeEventEmitter: &roomChangeEventEmitter{
			eventRepo:        repository.NewRoomEventRepository(ctx, dbPool, workMan),
			payloadConverter: models.NewPayloadConverter(),
			eventsManager:    eventsManager,
		},
		subscriptionRepo: repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan),
	}
}

func (csq *roomSubscriptionAddQueue) Name() string {
	return SubscriptionAddEventName
}

func (csq *roomSubscriptionAddQueue) PayloadType() any {
	return &eventsv1.RoomAction{}
}

func (csq *roomSubscriptionAddQueue) Validate(_ context.Context, payload any) error {
	_, ok := payload.(*eventsv1.RoomAction)
	if !ok {
		return errors.New("invalid payload type, expected *eventsv1.RoomAction")
	}
	return nil
}

// Execute return required for deferred tracing.
func (csq *roomSubscriptionAddQueue) Execute(ctx context.Context, payload any) error {
	var err error
	ctx, span := chattel.EventTracer.Start(ctx, "Subscription.Add")
	defer func() { chattel.EventTracer.End(ctx, span, err) }()

	// Unwrap payload
	action, ok := payload.(*eventsv1.RoomAction)
	if !ok {
		err = errors.New("invalid payload type")
		return err
	}

	for _, subscription := range action.GetTargets() {
		roomID := action.GetRoomId()
		logger := util.Log(ctx).WithFields(map[string]any{
			"room_id":    roomID,
			"profile_id": subscription.GetContactLink().GetProfileId(),
			"type":       csq.Name(),
		})
		logger.Debug("handling subscription add event")

		// Create new subscriptions for profiles that don't exist.
		// Continue processing after individual validation failures so that
		// valid members are still added (partial success).
		err = csq.addSubscription(ctx, roomID, subscription, action.GetRoles(), action.GetActor())
		if err != nil {
			err = fmt.Errorf("failed to add subscription: %w", err)
			return err
		}
	}

	return nil
}

func (csq *roomSubscriptionAddQueue) addSubscription(
	ctx context.Context,
	roomID string,
	subscription *eventsv1.Subscription,
	roles []string,
	addedBy *eventsv1.Subscription,
) error {
	var err error
	contactLink := subscription.GetContactLink()
	// Get existing subscriptions to avoid duplicates
	subscriptionList, err := csq.subscriptionRepo.GetByRoomIDAndContactLinks(ctx, roomID, contactLink)
	if err != nil {
		return fmt.Errorf("failed to check existing subscriptions: %w", err)
	}

	if len(subscriptionList) > 0 {
		return nil
	}

	// Create new subscription
	subscriptionModel := &models.RoomSubscription{
		RoomID:            roomID,
		ProfileID:         contactLink.GetProfileId(),
		ContactID:         contactLink.GetContactId(),
		SubscriptionState: models.RoomSubscriptionStateActive,
		Role:              strings.Join(roles, ","),
	}

	if subscription.GetSubscriptionId() != "" {
		subscriptionModel.ID = subscription.GetSubscriptionId()
	}

	// Save new subscription
	err = csq.subscriptionRepo.Create(ctx, subscriptionModel)
	if err != nil {
		return fmt.Errorf("failed to create subscription: %w", err)
	}

	err = csq.eventsManager.Emit(ctx, SubscriptionAuthorizeEventName, subscriptionModel.ToAPI())
	if err != nil {
		return fmt.Errorf("failed to emit subscription add event: %w", err)
	}

	err = csq.emitInternalRoomChangeEvents(ctx, roomID,
		chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_MEMBER_ADDED,
		"member added to room",
		addedBy, subscription)
	if err != nil {
		return fmt.Errorf("failed to emit room change event: %w", err)
	}

	return nil
}
