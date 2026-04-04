package queues

import (
	"context"
	"errors"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	eventsv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/events/v1"
	"github.com/antinvestor/service-chat/apps/gateway/config"
	"github.com/antinvestor/service-chat/apps/gateway/service/business"
	"github.com/antinvestor/service-chat/internal"
	"github.com/pitabwire/frame/queue"
	"github.com/pitabwire/util"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"
)

type GatewayEventsQueueHandler struct {
	cfg      *config.GatewayConfig
	qManager queue.Manager

	connectionManager business.ConnectionManager
}

func NewGatewayEventsQueueHandler(
	cfg *config.GatewayConfig,
	qManager queue.Manager,
	cm business.ConnectionManager,
) queue.SubscribeWorker {
	return &GatewayEventsQueueHandler{
		cfg:               cfg,
		qManager:          qManager,
		connectionManager: cm,
	}
}

func (dq *GatewayEventsQueueHandler) Handle(ctx context.Context, headers map[string]string, payload []byte) error {
	profileID := headers[internal.HeaderProfileID]
	deviceID := headers[internal.HeaderDeviceID]

	// Parse payload first so we can fall back to offline delivery if needed
	evt, err := dq.toPayloadToEventData(ctx, payload)
	if err != nil {
		util.Log(ctx).WithError(err).WithFields(map[string]any{
			"profile_id": profileID,
			"device_id":  deviceID,
		}).Error("failed to parse user delivery message, dropping corrupt message")
		return nil
	}

	connection, ok := dq.connectionManager.GetConnection(ctx, profileID, deviceID)
	if !ok {
		metadata, found, lookupErr := dq.connectionManager.GetConnectionMetadata(ctx, profileID, deviceID)
		if lookupErr != nil {
			return lookupErr
		}
		if found && metadata != nil && metadata.GatewayID != dq.connectionManager.GatewayID() {
			util.Log(ctx).WithFields(map[string]any{
				"profile_id":       profileID,
				"device_id":        deviceID,
				"owner_gateway_id": metadata.GatewayID,
				"gateway_id":       dq.connectionManager.GatewayID(),
			}).Warn("delivery consumed by non-owning gateway, retrying")
			return errors.New("delivery routed to non-owning gateway instance")
		}

		// Device is no longer connected to any gateway - fall back to offline delivery.
		util.Log(ctx).WithFields(map[string]any{
			"profile_id": profileID,
			"device_id":  deviceID,
		}).Debug("connection not found: falling back to offline delivery")
		return dq.publishToOfflineDevice(ctx, headers, evt)
	}

	data := dq.toStreamData(evt)

	if !connection.Dispatch(data) {
		util.Log(ctx).WithFields(map[string]any{
			"profile_id": profileID,
			"device_id":  deviceID,
		}).Debug("dispatch channel full: slow consumer detected")

		return errors.New("slow consumer: dispatch buffer full")
	}

	return nil
}

func (dq *GatewayEventsQueueHandler) toPayloadToEventData(
	_ context.Context,
	payload []byte,
) (*eventsv1.Delivery, error) {
	eventDelivery := &eventsv1.Delivery{}
	err := proto.Unmarshal(payload, eventDelivery)
	if err != nil {
		return nil, err
	}

	return eventDelivery, nil
}

func (dq *GatewayEventsQueueHandler) toStreamData(dlr *eventsv1.Delivery) *chatv1.StreamResponse {
	evt := dlr.GetEvent()
	source := evt.GetSource()
	roomID := evt.GetRoomId()
	subscriptionID := ""
	if source != nil {
		subscriptionID = source.GetSubscriptionId()
	}

	parentID := evt.GetParentId()

	// Convert event type
	eventType := chatv1.RoomEventType(dlr.GetEvent().GetEventType().Number())

	// Create RoomEvent with appropriate payload based on type
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
		Id:        evt.GetEventId(),
		Timestamp: timestamppb.Now(),
	}

	//nolint:exhaustive // All non-ephemeral room event types are forwarded as normal message payloads.
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

func (dq *GatewayEventsQueueHandler) getOfflineDeliveryTopic() (queue.Publisher, error) {
	deviceTopic, err := dq.qManager.GetPublisher(dq.cfg.QueueOfflineEventDeliveryName)
	if err != nil {
		return nil, err
	}

	return deviceTopic, nil
}

func (dq *GatewayEventsQueueHandler) publishToOfflineDevice(
	ctx context.Context,
	headers map[string]string,
	msg *eventsv1.Delivery,
) error {
	offlineDeliveryTopic, err := dq.getOfflineDeliveryTopic()
	if err != nil {
		return err
	}

	return offlineDeliveryTopic.Publish(ctx, msg, headers)
}
