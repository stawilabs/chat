package business

import (
	"context"
	"fmt"
	"time"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	eventsv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/events/v1"
	"github.com/pitabwire/frame/v2/cache"
	frevents "github.com/pitabwire/frame/v2/events"
	"github.com/pitabwire/util"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/stawilabs/chat/apps/default/service"
	"github.com/stawilabs/chat/apps/default/service/authz"
	"github.com/stawilabs/chat/apps/default/service/events"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/pkg/chatutil"
)

type connectBusiness struct {
	evtsManager frevents.Manager

	subRepo         repository.RoomSubscriptionRepository
	eventRepo       repository.RoomEventRepository
	subscriptionSvc SubscriptionService
	authzMiddleware authz.Middleware

	presenceCache cache.Cache[string, *chatv1.PresenceEvent]
}

// NewConnectBusiness creates a new instance of ClientStateBusiness.
func NewConnectBusiness(
	evtsManager frevents.Manager,
	subRepo repository.RoomSubscriptionRepository,
	eventRepo repository.RoomEventRepository,
	subscriptionSvc SubscriptionService,
	authzMiddleware authz.Middleware,
	presenceCache cache.Cache[string, *chatv1.PresenceEvent],
) ClientStateBusiness {
	return &connectBusiness{
		evtsManager:     evtsManager,
		subRepo:         subRepo,
		eventRepo:       eventRepo,
		subscriptionSvc: subscriptionSvc,
		authzMiddleware: authzMiddleware,
		presenceCache:   presenceCache,
	}
}

// UpdatePresence sends presence updates to all related profiles.
func (cb *connectBusiness) UpdatePresence(
	ctx context.Context,
	presenceEvt *chatv1.PresenceEvent,
) error {
	if presenceEvt == nil {
		return service.ErrUnspecifiedID
	}

	source := presenceEvt.GetSource()
	if source == nil || source.GetProfileId() == "" {
		return service.ErrUnspecifiedID
	}

	util.Log(ctx).WithFields(map[string]any{
		chatutil.KeyProfileID: source.GetProfileId(),
		"status":              presenceEvt.GetStatus(),
	}).Debug("UpdatePresence")

	if cb.presenceCache == nil {
		util.Log(ctx).WithField(chatutil.KeyProfileID, source.GetProfileId()).
			Warn("presence cache not configured, skipping presence update")
		return nil
	}

	return cb.presenceCache.Set(ctx, source.GetProfileId(), presenceEvt, 1*time.Minute)
}

// UpdateTypingIndicator sends typing indicators to room subscribers.
func (cb *connectBusiness) UpdateTypingIndicator(
	ctx context.Context,
	roomID string,
	typer *commonv1.ContactLink,
	isTyping bool,
) error {
	if !isTyping {
		return nil
	}

	if err := chatutil.IsValidContactLink(typer); err != nil {
		return err
	}
	if roomID == "" {
		return service.ErrRoomIDRequired
	}

	// Look up subscription first - reuse for both authz check and typing event
	subscription, err := cb.subscriptionSvc.GetSubscription(ctx, typer, roomID)
	if err != nil {
		return service.ErrRoomAccessDenied
	}

	if authzErr := cb.authzMiddleware.CanMessageSend(ctx, subscription.GetID(), roomID); authzErr != nil {
		return service.ErrRoomAccessDenied
	}

	util.Log(ctx).WithFields(map[string]any{
		chatutil.KeyRoomID:    roomID,
		chatutil.KeyProfileID: typer.GetProfileId(),
		"is_typing":           isTyping,
	}).Debug("UpdateTypingIndicator")

	// Broadcast user is typing to other room members
	// Note: STATE_TYPING events don't have typed payload content
	typingEvent := eventsv1.Link{
		EventId: util.IDString(),
		RoomId:  roomID,

		Source: &eventsv1.Subscription{
			SubscriptionId: subscription.GetID(),
			ContactLink:    typer,
		},
		EventType: chatv1.RoomEventType_ROOM_EVENT_TYPE_TYPING,
		CreatedAt: timestamppb.Now(),
	}

	emitErr := cb.evtsManager.Emit(ctx, events.RoomOutboxLoggingEventName, &typingEvent)
	if emitErr != nil {
		util.Log(ctx).WithError(emitErr).WithField(chatutil.KeyRoomID, roomID).
			Error("failed to emit typing event")
		return emitErr
	}

	return nil
}

// UpdateDeliveryReceipt update read receipt and notifies room subscribers.
func (cb *connectBusiness) UpdateDeliveryReceipt(
	ctx context.Context,
	roomID string,
	recipient *commonv1.ContactLink,
	eventIDList ...string,
) error {
	if err := chatutil.IsValidContactLink(recipient); err != nil {
		return err
	}
	if roomID == "" {
		return service.ErrRoomIDRequired
	}

	// Look up subscription first - reuse for both authz check and delivery receipt
	subscription, err := cb.subscriptionSvc.GetSubscription(ctx, recipient, roomID)
	if err != nil {
		return service.ErrRoomAccessDenied
	}

	if authzErr := cb.authzMiddleware.CanRoomView(ctx, subscription.GetID(), roomID); authzErr != nil {
		return service.ErrRoomAccessDenied
	}

	util.Log(ctx).WithFields(map[string]any{
		chatutil.KeyRoomID: roomID,
		"event_count":      len(eventIDList),
	}).Debug("UpdateDeliveryReceipt")

	// Broadcast delivery receipt to other room members
	for _, eventID := range eventIDList {
		receiptEvents := eventsv1.Link{
			EventId: util.IDString(),
			RoomId:  roomID,

			Source: &eventsv1.Subscription{
				SubscriptionId: subscription.GetID(),
				ContactLink:    subscription.ToLink(),
			},
			ParentId:  eventID,
			EventType: chatv1.RoomEventType_ROOM_EVENT_TYPE_DELIVERED,
			CreatedAt: timestamppb.Now(),
		}

		emitErr := cb.evtsManager.Emit(ctx, events.RoomOutboxLoggingEventName, &receiptEvents)
		if emitErr != nil {
			util.Log(ctx).WithError(emitErr).WithField(chatutil.KeyRoomID, roomID).
				Error("failed to emit delivery receipt event")
			return emitErr
		}
	}

	return nil
}

func (cb *connectBusiness) UpdateReadMarker(
	ctx context.Context,
	roomID string,
	reader *commonv1.ContactLink,
	upToEventID string,
) error {
	if err := chatutil.IsValidContactLink(reader); err != nil {
		return err
	}
	if roomID == "" {
		return service.ErrRoomIDRequired
	}

	// Look up subscription first - reuse for both authz check and read marker update
	subscription, err := cb.subscriptionSvc.GetSubscription(ctx, reader, roomID)
	if err != nil {
		return service.ErrRoomAccessDenied
	}

	if authzErr := cb.authzMiddleware.CanRoomView(ctx, subscription.GetID(), roomID); authzErr != nil {
		return service.ErrRoomAccessDenied
	}

	util.Log(ctx).WithFields(map[string]any{
		chatutil.KeyRoomID: roomID,
		"up_to_event_id":   upToEventID,
	}).Debug("UpdateReadMarker")

	// Update the subscription's last read event ID

	subLastReadEventID := subscription.LastReadEventID
	// Update to the new event ID
	// UnreadCount is now a generated column and will be automatically calculated
	if subLastReadEventID < upToEventID {
		subLastReadEventID = upToEventID
	}

	if subLastReadEventID != subscription.LastReadEventID {
		subscription.LastReadEventID = subLastReadEventID
		subscription.LastReadAt = time.Now().Unix()
		if _, err = cb.subRepo.Update(ctx, subscription); err != nil {
			return fmt.Errorf("failed to update subscription: %w", err)
		}
	}

	// Broadcast read receipt to other room members
	readEvents := eventsv1.Link{
		EventId: util.IDString(),
		RoomId:  roomID,

		Source: &eventsv1.Subscription{
			SubscriptionId: subscription.GetID(),
			ContactLink:    subscription.ToLink(),
		},
		ParentId:  upToEventID,
		EventType: chatv1.RoomEventType_ROOM_EVENT_TYPE_READ,
		CreatedAt: timestamppb.Now(),
	}

	emitErr := cb.evtsManager.Emit(ctx, events.RoomOutboxLoggingEventName, &readEvents)
	if emitErr != nil {
		util.Log(ctx).WithError(emitErr).WithField(chatutil.KeyRoomID, roomID).
			Error("failed to emit read marker event")
		return emitErr
	}
	return nil
}
