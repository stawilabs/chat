package queues

import (
	"context"
	"errors"
	"fmt"
	"io"
	"strconv"
	"sync"
	"time"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	eventsv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/events/v1"
	"buf.build/gen/go/antinvestor/device/connectrpc/go/device/v1/devicev1connect"
	devicev1 "buf.build/gen/go/antinvestor/device/protocolbuffers/go/device/v1"
	"connectrpc.com/connect"
	"github.com/antinvestor/service-chat/apps/default/config"
	"github.com/antinvestor/service-chat/apps/default/service/models"
	"github.com/antinvestor/service-chat/apps/default/service/repository"
	"github.com/antinvestor/service-chat/internal"
	"github.com/antinvestor/service-chat/internal/streaming"
	chattel "github.com/antinvestor/service-chat/internal/telemetry"
	"github.com/pitabwire/frame/datastore/pool"
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
	replayRepo  repository.DeviceReplayRepository

	// Cached publishers to avoid repeated GetPublisher lookups per message.
	offlinePub     queue.Publisher
	offlinePubOnce sync.Once
	offlinePubErr  error
}

func NewHotPathDeliveryQueueHandler(
	cfg *config.ChatConfig,
	qMan queue.Manager,
	workMan workerpool.Manager,
	dbPool pool.Pool,
	deviceCli devicev1connect.DeviceServiceClient,
	dlp *DeadLetterPublisher,
) queue.SubscribeWorker {
	return &hotPathDeliveryQueueHandler{
		cfg:       cfg,
		qMan:      qMan,
		deviceCli: deviceCli,
		dlp:       dlp,
		replayRepo: repository.NewDeviceReplayRepository(
			context.Background(),
			dbPool,
			workMan,
		),
		deviceCache: newProfileDeviceCache(
			time.Duration(cfg.ProfileDeviceCacheTTLSeconds)*time.Second,
			cfg.ProfileDeviceCacheMaxEntries,
		),
	}
}

func (dq *hotPathDeliveryQueueHandler) getOfflineDeliveryTopic() (queue.Publisher, error) {
	dq.offlinePubOnce.Do(func() {
		dq.offlinePub, dq.offlinePubErr = dq.qMan.GetPublisher(dq.cfg.QueueOfflineEventDeliveryName)
	})
	return dq.offlinePub, dq.offlinePubErr
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
	replayEntries, replayErr := dq.indexReplayEntries(ctx, eventDelivery, profileID, devices)
	if replayErr != nil {
		return RetryOrDeadLetter(
			ctx,
			dq.qMan,
			dq.dlp,
			dq.cfg.QueueDeviceEventDeliveryName,
			eventDelivery,
			headers,
			replayErr,
		)
	}

	for _, dev := range devices {
		cloned := proto.Clone(eventDelivery)

		eventCopy, ok := cloned.(*eventsv1.Delivery)
		if !ok {
			deliveryErrs = append(deliveryErrs, errors.New("failed to clone event delivery"))
			continue
		}
		eventCopy.DeviceId = dev.id

		if deliverErr := dq.deliver(ctx, eventCopy, dev, replayEntries[dev.id]); deliverErr != nil {
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
	replayEntry *models.DeviceReplayEvent,
) error {
	util.Log(ctx).WithFields(map[string]any{
		"device_id": dev.id,
		"online":    dq.deviceIsOnline(ctx, dev),
	}).Debug("HotPathDelivery routing decision")

	if dq.deviceIsOnline(ctx, dev) {
		err := dq.publishToOnlineDevice(ctx, dev, msg, replayEntry)
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
	replayEntry *models.DeviceReplayEvent,
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
	if replayEntry != nil {
		deviceHeader[internal.HeaderReplayCursor] = replayEntry.GetID()
	}

	return deliveryTopic.Publish(ctx, msg, deviceHeader)
}

//nolint:gocognit // Replay indexing coordinates dedupe, serialization, and bounded retention per device.
func (dq *hotPathDeliveryQueueHandler) indexReplayEntries(
	ctx context.Context,
	delivery *eventsv1.Delivery,
	profileID string,
	devices []deliveryDevice,
) (map[string]*models.DeviceReplayEvent, error) {
	entries := make(map[string]*models.DeviceReplayEvent, len(devices))
	if dq.replayRepo == nil || !isDurableRoomEvent(delivery.GetEvent().GetEventType()) || profileID == "" ||
		len(devices) == 0 {
		return entries, nil
	}

	deviceIDs := make([]string, 0, len(devices))
	for _, dev := range devices {
		if dev.id == "" {
			continue
		}
		deviceIDs = append(deviceIDs, dev.id)
	}

	existing, err := dq.replayRepo.ListByEventAndDevices(ctx, profileID, delivery.GetEvent().GetEventId(), deviceIDs)
	if err != nil {
		return nil, err
	}

	for _, entry := range existing {
		entries[entry.DeviceID] = entry
	}

	var missing []*models.DeviceReplayEvent
	for _, dev := range devices {
		if dev.id == "" {
			continue
		}
		if _, ok := entries[dev.id]; ok {
			continue
		}

		deviceDelivery, ok := proto.Clone(delivery).(*eventsv1.Delivery)
		if !ok {
			return nil, errors.New("failed to clone device delivery for replay indexing")
		}
		deviceDelivery.DeviceId = dev.id

		entry := &models.DeviceReplayEvent{
			ProfileID: profileID,
			DeviceID:  dev.id,
			EventID:   delivery.GetEvent().GetEventId(),
			RoomID:    delivery.GetEvent().GetRoomId(),
			EventType: int32(delivery.GetEvent().GetEventType().Number()),
		}
		entry.GenID(ctx)

		responseBytes, marshalErr := proto.Marshal(streaming.ResponseFromDelivery(deviceDelivery, entry.GetID()))
		if marshalErr != nil {
			return nil, marshalErr
		}
		entry.ResponseData = responseBytes

		missing = append(missing, entry)
		entries[dev.id] = entry
	}

	if err = dq.replayRepo.CreateIgnoringDuplicates(ctx, missing); err != nil {
		return nil, err
	}

	if len(missing) > 0 {
		existing, err = dq.replayRepo.ListByEventAndDevices(ctx, profileID, delivery.GetEvent().GetEventId(), deviceIDs)
		if err != nil {
			return nil, err
		}
		for _, entry := range existing {
			entries[entry.DeviceID] = entry
		}
	}

	maxAge := time.Duration(dq.cfg.DeviceReplayRetentionHours) * time.Hour
	for _, dev := range devices {
		if dev.id == "" {
			continue
		}
		if trimErr := dq.replayRepo.TrimDevice(
			ctx,
			profileID,
			dev.id,
			dq.cfg.DeviceReplayMaxEventsPerDevice,
			maxAge,
		); trimErr != nil {
			return nil, trimErr
		}
	}

	return entries, nil
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

func isDurableRoomEvent(eventType chatv1.RoomEventType) bool {
	//nolint:exhaustive // Only explicitly ephemeral event types are excluded from durable replay.
	switch eventType {
	case chatv1.RoomEventType_ROOM_EVENT_TYPE_TYPING,
		chatv1.RoomEventType_ROOM_EVENT_TYPE_DELIVERED,
		chatv1.RoomEventType_ROOM_EVENT_TYPE_READ:
		return false
	default:
		return true
	}
}
