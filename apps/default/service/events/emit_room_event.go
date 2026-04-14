package events

import (
	"context"
	"fmt"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	eventsv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/events/v1"
	"github.com/antinvestor/service-chat/apps/default/service/models"
	"github.com/antinvestor/service-chat/apps/default/service/repository"
	chattel "github.com/antinvestor/service-chat/pkg/telemetry"
	frevents "github.com/pitabwire/frame/events"
	"google.golang.org/protobuf/types/known/timestamppb"
)

type roomChangeEventEmitter struct {
	eventRepo        repository.RoomEventRepository
	payloadConverter *models.PayloadConverter
	eventsManager    frevents.Manager
}

func (rce *roomChangeEventEmitter) emitInternalRoomChangeEvents(
	ctx context.Context,
	roomID string,
	action chatv1.RoomChangeAction,
	body string,
	actor *eventsv1.Subscription,
	targetSubscriptions ...*eventsv1.Subscription,
) error {
	targetSubscriptionIDs := make([]string, len(targetSubscriptions))
	for i, subscription := range targetSubscriptions {
		targetSubscriptionIDs[i] = subscription.GetSubscriptionId()
	}

	roomChangePayload := &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_ROOM_CHANGE,
		Data: &chatv1.Payload_RoomChange{
			RoomChange: &chatv1.RoomChangeContent{
				Action:                action,
				ActorSubscriptionId:   actor.GetSubscriptionId(),
				TargetSubscriptionIds: targetSubscriptionIDs,
				Body:                  body,
			},
		},
	}

	// Create the message event using PayloadConverter
	content, err := rce.payloadConverter.FromProto(roomChangePayload)
	if err != nil {
		return fmt.Errorf("failed to convert event: %w", err)
	}

	// Create the message event
	event := &models.RoomEvent{
		RoomID:    roomID,
		EventType: int32(chatv1.RoomEventType_ROOM_EVENT_TYPE_SYSTEM),
		Content:   content,
		SenderID:  actor.GetSubscriptionId(),
	}

	err = rce.eventRepo.Create(ctx, event)
	if err == nil {
		chattel.MessagesSentCounter.Add(ctx, int64(1))
	}

	// Emit event to outbox for delivery
	outboxEventLink := eventsv1.Link{
		EventId: event.GetID(),
		RoomId:  event.RoomID,

		Source: &eventsv1.Subscription{
			SubscriptionId: actor.GetSubscriptionId(),
			ContactLink:    actor.GetContactLink(),
		},
		ParentId:  event.ParentID,
		EventType: chatv1.RoomEventType(event.EventType),
		CreatedAt: timestamppb.New(event.CreatedAt),
	}

	return rce.eventsManager.Emit(ctx, RoomOutboxLoggingEventName, &outboxEventLink)
}
