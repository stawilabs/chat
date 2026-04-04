package streaming

import (
	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	eventsv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/events/v1"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func ResponseFromDelivery(dlr *eventsv1.Delivery, responseID string) *chatv1.StreamResponse {
	evt := dlr.GetEvent()
	source := evt.GetSource()
	roomID := evt.GetRoomId()
	subscriptionID := ""
	if source != nil {
		subscriptionID = source.GetSubscriptionId()
	}

	parentID := evt.GetParentId()
	eventType := chatv1.RoomEventType(dlr.GetEvent().GetEventType().Number())

	roomEvent := &chatv1.RoomEvent{
		Id:             evt.GetEventId(),
		ParentId:       &parentID,
		RoomId:         roomID,
		SubscriptionId: subscriptionID,
		Type:           eventType,
		SentAt:         evt.GetCreatedAt(),
		Edited:         false,
		Redacted:       false,
		Payload:        dlr.GetPayload(),
	}

	response := &chatv1.StreamResponse{
		Id:        responseID,
		Timestamp: timestamppb.Now(),
	}

	//nolint:exhaustive // All non-ephemeral events are represented as regular message payloads.
	switch eventType {
	case chatv1.RoomEventType_ROOM_EVENT_TYPE_TYPING:
		response.Payload = &chatv1.StreamResponse_TypingEvent{
			TypingEvent: &chatv1.TypingEvent{
				RoomId:         roomID,
				SubscriptionId: subscriptionID,
				Typing:         true,
				Since:          evt.GetCreatedAt(),
			},
		}
	case chatv1.RoomEventType_ROOM_EVENT_TYPE_DELIVERED:
		response.Payload = &chatv1.StreamResponse_ReceiptEvent{
			ReceiptEvent: &chatv1.ReceiptEvent{
				RoomId:         roomID,
				SubscriptionId: subscriptionID,
				EventId:        []string{parentID},
			},
		}
	case chatv1.RoomEventType_ROOM_EVENT_TYPE_READ:
		response.Payload = &chatv1.StreamResponse_ReadEvent{
			ReadEvent: &chatv1.ReadMarker{
				RoomId:         &roomID,
				SubscriptionId: subscriptionID,
				UpToEventId:    parentID,
			},
		}
	default:
		response.Payload = &chatv1.StreamResponse_Message{
			Message: roomEvent,
		}
	}

	return response
}
