package queues

import (
	"context"
	"errors"
	"fmt"
	"io"
	"strconv"

	eventsv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/events/v1"
	"buf.build/gen/go/antinvestor/device/connectrpc/go/device/v1/devicev1connect"
	devicev1 "buf.build/gen/go/antinvestor/device/protocolbuffers/go/device/v1"
	"connectrpc.com/connect"
	"github.com/antinvestor/service-chat/apps/default/config"
	"github.com/antinvestor/service-chat/internal"
	chattel "github.com/antinvestor/service-chat/internal/telemetry"
	"github.com/pitabwire/frame/queue"
	"github.com/pitabwire/frame/workerpool"
	"github.com/pitabwire/util"
	"google.golang.org/protobuf/proto"
)

const (
	// DeviceSearchPageSize defines the number of devices to fetch per page when searching.
	DeviceSearchPageSize = 100
)

type hotPathDeliveryQueueHandler struct {
	qMan      queue.Manager
	cfg       *config.ChatConfig
	deviceCli devicev1connect.DeviceServiceClient
	dlp       *DeadLetterPublisher
}

func NewHotPathDeliveryQueueHandler(
	cfg *config.ChatConfig,
	qMan queue.Manager,
	_ workerpool.Manager,
	deviceCli devicev1connect.DeviceServiceClient,
	dlp *DeadLetterPublisher,
) queue.SubscribeWorker {
	return &hotPathDeliveryQueueHandler{
		cfg:       cfg,
		qMan:      qMan,
		deviceCli: deviceCli,
		dlp:       dlp,
	}
}

func (dq *hotPathDeliveryQueueHandler) getOfflineDeliveryTopic() (queue.Publisher, error) {
	deviceTopic, err := dq.qMan.GetPublisher(dq.cfg.QueueOfflineEventDeliveryName)
	if err != nil {
		return nil, err
	}

	return deviceTopic, nil
}

func (dq *hotPathDeliveryQueueHandler) getOnlineDeliveryTopic(
	ctx context.Context,
	profileID, deviceID string,
) (queue.Publisher, int, error) {
	shardString := internal.MetadataKey(profileID, deviceID)

	// Ensure ShardCount is valid
	if dq.cfg.ShardCount <= 0 {
		util.Log(ctx).WithField("shard_count", dq.cfg.ShardCount).
			Error("Invalid shard count, must be positive")
		return nil, 0, fmt.Errorf("invalid shard count: %d", dq.cfg.ShardCount)
	}

	shardID := internal.ShardForKey(shardString, dq.cfg.ShardCount)

	shardDeliveryQueueName := fmt.Sprintf(dq.cfg.QueueGatewayEventDeliveryName, shardID)

	deviceTopic, err := dq.qMan.GetPublisher(shardDeliveryQueueName)
	if err != nil {
		return nil, shardID, err
	}

	return deviceTopic, shardID, nil
}

//
//nolint:nonamedreturns,gocognit // named return for tracing; delivery pipeline requires device search, retry logic, and worker pool coordination
func (dq *hotPathDeliveryQueueHandler) Handle(
	ctx context.Context,
	headers map[string]string,
	payload []byte,
) (err error) {
	ctx, span := chattel.DeliveryTracer.Start(ctx, "HotPathDelivery")
	defer func() { chattel.DeliveryTracer.End(ctx, span, err) }()

	chattel.DeliveryQueueProcessedCounter.Add(ctx, 1)

	eventDelivery := &eventsv1.Delivery{}
	err = proto.Unmarshal(payload, eventDelivery)
	if err != nil {
		util.Log(ctx).WithError(err).WithField("queue", dq.cfg.QueueDeviceEventDeliveryName).
			Error("failed to unmarshal delivery payload")
		// Non-retryable: send raw payload to DLQ for diagnostics
		if dq.dlp != nil {
			_ = dq.dlp.Publish(ctx, payload, dq.cfg.QueueDeviceEventDeliveryName, err.Error(), headers)
		}
		return nil
	}

	// Check if delivery has exceeded max retries
	if dq.dlp != nil && dq.dlp.ShouldDeadLetter(eventDelivery.GetRetryCount()) {
		return dq.dlp.Publish(ctx, eventDelivery, dq.cfg.QueueDeviceEventDeliveryName,
			"max retries exceeded", headers)
	}

	destination := eventDelivery.GetDestination()
	profileID := ""
	if destination != nil {
		contactLink := destination.GetContactLink()
		if contactLink != nil {
			profileID = contactLink.GetProfileId()
		}
	}

	util.Log(ctx).WithFields(map[string]any{
		"profile_id": profileID,
		"event_id":   eventDelivery.GetEvent().GetEventId(),
	}).Debug("HotPathDelivery searching devices")

	response, err := dq.deviceCli.Search(ctx, connect.NewRequest(&devicev1.SearchRequest{
		Query: profileID,
		Page:  0,
		Count: DeviceSearchPageSize,
	}))
	if err != nil {
		// Retryable: increment retry count and republish
		return RetryOrDeadLetter(
			ctx,
			dq.qMan,
			dq.dlp,
			dq.cfg.QueueDeviceEventDeliveryName,
			eventDelivery,
			headers,
			err,
		)
	}

	for response.Receive() {
		deviceErr := response.Err()
		if deviceErr != nil && !errors.Is(deviceErr, io.EOF) {
			util.Log(ctx).WithError(deviceErr).WithField("profile_id", profileID).
				Error("failed to receive device search stream")
		}

		resp := response.Msg()
		var deliveryErrs []error

		// Deliver synchronously so failures are observed and retried instead of being dropped.
		for _, dev := range resp.GetData() {
			eventCopy, ok := proto.Clone(eventDelivery).(*eventsv1.Delivery)
			if !ok {
				deliveryErrs = append(deliveryErrs, errors.New("failed to clone event delivery"))
				continue
			}
			eventCopy.DeviceId = dev.GetId()

			if deliverErr := dq.deliver(ctx, eventCopy, dev); deliverErr != nil {
				util.Log(ctx).WithError(deliverErr).WithField("device_id", dev.GetId()).
					Error("failed to deliver event")
				deliveryErrs = append(deliveryErrs, fmt.Errorf("device %s: %w", dev.GetId(), deliverErr))
			}
		}

		if len(deliveryErrs) > 0 {
			return RetryOrDeadLetter(
				ctx,
				dq.qMan,
				dq.dlp,
				dq.cfg.QueueDeviceEventDeliveryName,
				eventDelivery,
				headers,
				errors.Join(deliveryErrs...),
			)
		}
	}

	return nil
}
func (dq *hotPathDeliveryQueueHandler) deliver(
	ctx context.Context,
	msg *eventsv1.Delivery,
	dev *devicev1.DeviceObject,
) error {
	util.Log(ctx).WithFields(map[string]any{
		"device_id": dev.GetId(),
		"online":    dq.deviceIsOnline(ctx, dev),
	}).Debug("HotPathDelivery routing decision")

	if dq.deviceIsOnline(ctx, dev) {
		err := dq.publishToOnlineDevice(ctx, dev, msg)
		if err == nil {
			chattel.MessagesDeliveredCounter.Add(ctx, 1)
			return nil
		}
		util.Log(ctx).WithError(err).WithField("device_id", dev.GetId()).
			Debug("direct delivery failed, falling back to offline delivery")
	}

	offlineDeliveryTopic, err := dq.getOfflineDeliveryTopic()
	if err != nil {
		return err
	}

	deviceHeader := map[string]string{
		internal.HeaderDeviceID: dev.GetId(),
	}

	return offlineDeliveryTopic.Publish(ctx, msg, deviceHeader)
}

func (dq *hotPathDeliveryQueueHandler) deviceIsOnline(
	_ context.Context,
	dev *devicev1.DeviceObject,
) bool {
	return dev.GetPresence() != devicev1.PresenceStatus_OFFLINE
}

func (dq *hotPathDeliveryQueueHandler) publishToOnlineDevice(
	ctx context.Context,
	dev *devicev1.DeviceObject,
	msg *eventsv1.Delivery,
) error {
	destination := msg.GetDestination()
	profileID := ""
	if destination != nil {
		contactLink := destination.GetContactLink()
		if contactLink != nil {
			profileID = contactLink.GetProfileId()
		}
	}
	deviceID := dev.GetId()

	deliveryTopic, shardID, err := dq.getOnlineDeliveryTopic(ctx, profileID, deviceID)
	if err != nil {
		return err
	}

	deviceHeader := map[string]string{
		internal.HeaderProfileID: profileID,
		internal.HeaderDeviceID:  deviceID,
		internal.HeaderShardID:   strconv.Itoa(shardID),
	}

	return deliveryTopic.Publish(ctx, msg, deviceHeader)
}
