package queues

import (
	"context"
	"errors"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	eventsv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/events/v1"
	"github.com/pitabwire/frame/queue"
	"github.com/pitabwire/util"
	"google.golang.org/protobuf/proto"

	"github.com/stawilabs/chat/apps/gateway/config"
	"github.com/stawilabs/chat/apps/gateway/service/business"
	"github.com/stawilabs/chat/pkg/chatutil"
	"github.com/stawilabs/chat/pkg/streaming"
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
	profileID := headers[chatutil.HeaderProfileID]
	deviceID := headers[chatutil.HeaderDeviceID]

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

	data := dq.toStreamData(evt, headers[chatutil.HeaderReplayCursor])

	if !connection.Dispatch(data) {
		util.Log(ctx).WithFields(map[string]any{
			"profile_id": profileID,
			"device_id":  deviceID,
		}).Debug("dispatch channel full: falling back to offline delivery")

		return dq.publishToOfflineDevice(ctx, headers, evt)
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

func (dq *GatewayEventsQueueHandler) toStreamData(dlr *eventsv1.Delivery, replayCursor string) *chatv1.StreamResponse {
	responseID := dlr.GetEvent().GetEventId()
	if replayCursor != "" {
		responseID = replayCursor
	}

	return streaming.ResponseFromDelivery(dlr, responseID)
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
