package queues

import (
	"context"
	"errors"
	"fmt"
	"io"
	"strconv"
	"time"

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

type hotPathDeliveryQueueHandler struct {
	qMan        queue.Manager
	cfg         *config.ChatConfig
	deviceCli   devicev1connect.DeviceServiceClient
	dlp         *DeadLetterPublisher
	deviceCache *profileDeviceCache
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
		deviceCache: newProfileDeviceCache(
			time.Duration(cfg.ProfileDeviceCacheTTLSeconds)*time.Second,
			cfg.ProfileDeviceCacheMaxEntries,
		),
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
//nolint:nonamedreturns // named return for tracing
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

	devices, err := dq.resolveDevicesForProfile(ctx, profileID)
	if err != nil {
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

	var deliveryErrs []error
	for _, dev := range devices {
		eventCopy, ok := proto.Clone(eventDelivery).(*eventsv1.Delivery)
		if !ok {
			deliveryErrs = append(deliveryErrs, errors.New("failed to clone event delivery"))
			continue
		}
		eventCopy.DeviceId = dev.id

		if deliverErr := dq.deliver(ctx, eventCopy, dev); deliverErr != nil {
			util.Log(ctx).WithError(deliverErr).WithField("device_id", dev.id).
				Error("failed to deliver event")
			deliveryErrs = append(deliveryErrs, fmt.Errorf("device %s: %w", dev.id, deliverErr))
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

	return nil
}
func (dq *hotPathDeliveryQueueHandler) deliver(
	ctx context.Context,
	msg *eventsv1.Delivery,
	dev deliveryDevice,
) error {
	util.Log(ctx).WithFields(map[string]any{
		"device_id": dev.id,
		"online":    dq.deviceIsOnline(ctx, dev),
	}).Debug("HotPathDelivery routing decision")

	if dq.deviceIsOnline(ctx, dev) {
		err := dq.publishToOnlineDevice(ctx, dev, msg)
		if err == nil {
			chattel.MessagesDeliveredCounter.Add(ctx, 1)
			return nil
		}
		util.Log(ctx).WithError(err).WithField("device_id", dev.id).
			Debug("direct delivery failed, falling back to offline delivery")
	}

	offlineDeliveryTopic, err := dq.getOfflineDeliveryTopic()
	if err != nil {
		return err
	}

	deviceHeader := map[string]string{
		internal.HeaderDeviceID: dev.id,
	}

	return offlineDeliveryTopic.Publish(ctx, msg, deviceHeader)
}

func (dq *hotPathDeliveryQueueHandler) deviceIsOnline(
	_ context.Context,
	dev deliveryDevice,
) bool {
	return dev.presence != devicev1.PresenceStatus_OFFLINE
}

func (dq *hotPathDeliveryQueueHandler) publishToOnlineDevice(
	ctx context.Context,
	dev deliveryDevice,
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
	deviceID := dev.id

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

func (dq *hotPathDeliveryQueueHandler) resolveDevicesForProfile(
	ctx context.Context,
	profileID string,
) ([]deliveryDevice, error) {
	if devices, ok := dq.deviceCache.Get(profileID); ok {
		return devices, nil
	}

	response, err := dq.deviceCli.Search(ctx, connect.NewRequest(&devicev1.SearchRequest{
		Query: profileID,
		Page:  0,
		Count: safeSearchPageSize(dq.cfg.DeviceSearchPageSize),
	}))
	if err != nil {
		return nil, err
	}

	devices := make([]deliveryDevice, 0, dq.cfg.DeviceSearchPageSize)
	for response.Receive() {
		deviceErr := response.Err()
		if deviceErr != nil && !errors.Is(deviceErr, io.EOF) {
			util.Log(ctx).WithError(deviceErr).WithField("profile_id", profileID).
				Error("failed to receive device search stream")
		}

		resp := response.Msg()
		for _, dev := range resp.GetData() {
			devices = append(devices, deliveryDevice{
				id:       dev.GetId(),
				presence: dev.GetPresence(),
			})
		}
	}

	if responseErr := response.Err(); responseErr != nil && !errors.Is(responseErr, io.EOF) {
		return nil, responseErr
	}

	dq.deviceCache.Set(profileID, devices)
	return devices, nil
}

func safeSearchPageSize(limit int) int32 {
	if limit <= 0 {
		return 0
	}
	if limit > int(^uint32(0)>>1) {
		return int32(^uint32(0) >> 1)
	}
	return int32(limit)
}
