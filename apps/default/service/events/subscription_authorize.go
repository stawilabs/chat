package events

import (
	"context"
	"errors"
	"fmt"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	eventsv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/events/v1"
	"github.com/antinvestor/service-chat/apps/default/service/authz"
	"github.com/antinvestor/service-chat/apps/default/service/models"
	"github.com/antinvestor/service-chat/apps/default/service/repository"
	chattel "github.com/antinvestor/service-chat/internal/telemetry"
	"github.com/pitabwire/frame/datastore/pool"
	frevents "github.com/pitabwire/frame/events"
	"github.com/pitabwire/frame/workerpool"
	"github.com/pitabwire/util"
)

const (
	SubscriptionAuthorizeEventName = "room.subscription.authorize.event"
)

type roomSubscriptionAuthorizeQueue struct {
	*roomChangeEventEmitter
	eventsManager    frevents.Manager
	subscriptionRepo repository.RoomSubscriptionRepository
	authzMiddleware  authz.Middleware
}

func NewSubscriptionAuthorizeQueue(
	ctx context.Context,
	dbPool pool.Pool,
	workMan workerpool.Manager,
	eventsManager frevents.Manager,
	authzMiddleware authz.Middleware,
) frevents.EventI {
	return &roomSubscriptionAuthorizeQueue{
		roomChangeEventEmitter: &roomChangeEventEmitter{
			eventRepo:        repository.NewRoomEventRepository(ctx, dbPool, workMan),
			payloadConverter: models.NewPayloadConverter(),
			eventsManager:    eventsManager,
		},
		subscriptionRepo: repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan),
		eventsManager:    eventsManager,
		authzMiddleware:  authzMiddleware,
	}
}

func (csq *roomSubscriptionAuthorizeQueue) Name() string {
	return SubscriptionAuthorizeEventName
}

func (csq *roomSubscriptionAuthorizeQueue) PayloadType() any {
	return &eventsv1.RoomAction{}
}

func (csq *roomSubscriptionAuthorizeQueue) Validate(_ context.Context, payload any) error {
	_, ok := payload.(*eventsv1.RoomAction)
	if !ok {
		return errors.New("invalid payload type, expected *eventsv1.RoomAction")
	}
	return nil
}

// Execute return required for deferred tracing.
func (csq *roomSubscriptionAuthorizeQueue) Execute(ctx context.Context, payload any) error {
	var err error

	ctx, span := chattel.EventTracer.Start(ctx, "Subscription.Authorize")
	defer func() { chattel.EventTracer.End(ctx, span, err) }()

	// Unwrap payload
	action, ok := payload.(*eventsv1.RoomAction)
	if !ok {
		err = errors.New("invalid payload type")
		return err
	}

	var authzErrors []error
	for _, subscription := range action.GetTargets() {
		var targetFailed bool
		for _, role := range action.GetRoles() {
			link := subscription.GetContactLink()
			authzErr := csq.authzMiddleware.AddRoomMember(ctx, action.GetRoomId(), link.GetProfileId(), role)
			if authzErr != nil {
				util.Log(ctx).WithError(authzErr).
					WithField("room_id", action.GetRoomId()).
					WithField("profile_id", link.GetProfileId()).
					WithField("role", role).
					Warn("failed to sync authorization tuple for new room member")
				authzErrors = append(authzErrors, authzErr)
				targetFailed = true
			}
		}

		if targetFailed {
			continue
		}

		if action.GetAction() == chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_ROLE_CHANGED {
			// Emit room change event
			emitErr := csq.emitInternalRoomChangeEvents(ctx, action.GetRoomId(),
				chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_ROLE_CHANGED,
				"member role changed",
				action.GetActor(), subscription)
			if emitErr != nil {
				authzErrors = append(authzErrors, fmt.Errorf("failed to emit room change event: %w", emitErr))
			}
		}
	}

	if len(authzErrors) > 0 {
		err = fmt.Errorf("failed to authorize %d target(s): %w", len(authzErrors), errors.Join(authzErrors...))
		return err
	}

	return nil
}
