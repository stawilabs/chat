package events

import (
	"context"
	"errors"
	"fmt"
	"sync"

	eventsv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/events/v1"
	"github.com/antinvestor/service-chat/apps/default/config"
	"github.com/antinvestor/service-chat/apps/default/service/models"
	"github.com/antinvestor/service-chat/apps/default/service/repository"
	chattel "github.com/antinvestor/service-chat/internal/telemetry"
	"github.com/pitabwire/frame/data"
	"github.com/pitabwire/frame/datastore/pool"
	frevents "github.com/pitabwire/frame/events"
	"github.com/pitabwire/frame/queue"
	"github.com/pitabwire/frame/workerpool"
	"github.com/pitabwire/util"
)

const RoomFanoutEventName = "room.message.fanout.event"

type FanoutEventHandler struct {
	cfg              *config.ChatConfig
	eventRepo        repository.RoomEventRepository
	evtsManager      frevents.Manager
	queueMan         queue.Manager
	deliveryTopic    queue.Publisher
	deliveryTopicErr error
	deliveryOnce     sync.Once
	payloadConverter *models.PayloadConverter
}

func NewFanoutEventHandler(
	ctx context.Context,
	cfg *config.ChatConfig,
	dbPool pool.Pool,
	workMan workerpool.Manager,
	queueMan queue.Manager,
	evtsManager frevents.Manager,
) *FanoutEventHandler {
	return &FanoutEventHandler{
		cfg:              cfg,
		queueMan:         queueMan,
		evtsManager:      evtsManager,
		eventRepo:        repository.NewRoomEventRepository(ctx, dbPool, workMan),
		payloadConverter: models.NewPayloadConverter(),
	}
}

func (feh *FanoutEventHandler) getTopic() (queue.Publisher, error) {
	feh.deliveryOnce.Do(func() {
		feh.deliveryTopic, feh.deliveryTopicErr = feh.queueMan.GetPublisher(feh.cfg.QueueDeviceEventDeliveryName)
	})
	return feh.deliveryTopic, feh.deliveryTopicErr
}

func (feh *FanoutEventHandler) Name() string {
	return RoomFanoutEventName
}

func (feh *FanoutEventHandler) PayloadType() any {
	return &eventsv1.Broadcast{}
}

func (feh *FanoutEventHandler) Validate(_ context.Context, payload any) error {
	_, ok := payload.(*eventsv1.Broadcast)
	if !ok {
		return errors.New("invalid payload type, expected eventsv1.Broadcast")
	}
	return nil
}

//nolint:nonamedreturns // named return required for deferred tracing
func (feh *FanoutEventHandler) Execute(ctx context.Context, payload any) (err error) {
	ctx, span := chattel.EventTracer.Start(ctx, "Fanout")
	defer func() { chattel.EventTracer.End(ctx, span, err) }()

	broadcast, ok := payload.(*eventsv1.Broadcast)
	if !ok {
		return errors.New("invalid payload type, expected eventsv1.Broadcast{}")
	}

	eventLink := broadcast.GetEvent()
	destinations := broadcast.GetDestinations()

	// Early exit if no destinations
	if len(destinations) == 0 {
		return nil
	}

	logger := util.Log(ctx).WithFields(map[string]any{
		"room_id":      eventLink.GetRoomId(),
		"event_id":     eventLink.GetEventId(),
		"target_count": len(destinations),
	})
	logger.Debug("Fanout processing")

	// Use pre-fetched payload from Broadcast if available (set by RoomOutboxLoggingQueue),
	// otherwise fall back to DB read.
	eventPayload := broadcast.GetPayload()
	if eventPayload == nil && !isEphemeralRoomEvent(eventLink.GetEventType()) {
		eventLinkData, getErr := feh.eventRepo.GetByID(ctx, eventLink.GetEventId())
		if getErr != nil {
			if data.ErrorIsNoRows(getErr) {
				logger.WithError(getErr).Warn("persisted room event missing, will retry fanout")
				return getErr
			}
			logger.WithError(getErr).Error("failed to get chat event data")
			return getErr
		}

		// Convert event content to typed payload
		eventPayload, err = feh.payloadConverter.ToProto(eventLinkData.Content)
		if err != nil {
			logger.WithError(err).Error("failed to convert event content to payload")
			return fmt.Errorf("failed to convert event content to payload: %w", err)
		}
	}

	deliveryTopic, err := feh.getTopic()
	if err != nil {
		logger.WithError(err).Error("failed to get topic")
		return err
	}

	// Publish deliveries individually. On partial failure, re-emit a Broadcast
	// containing only the failed destinations instead of retrying all destinations
	// (which would cause duplicate delivery to already-succeeded recipients).
	var failedDestinations []*eventsv1.Subscription
	for _, destination := range destinations {
		eventDelivery := &eventsv1.Delivery{
			Event:        eventLink,
			Destination:  destination,
			Payload:      eventPayload,
			IsCompressed: false,
			RetryCount:   0,
		}

		if pubErr := deliveryTopic.Publish(ctx, eventDelivery); pubErr != nil {
			failedDestinations = append(failedDestinations, destination)
			logger.WithError(pubErr).
				WithField("subscription_id", destination.GetSubscriptionId()).
				Warn("failed to publish delivery")
		}
	}

	successCount := int64(len(destinations)) - int64(len(failedDestinations))
	if successCount > 0 {
		chattel.EventFanoutCounter.Add(ctx, successCount)
		logger.WithField("success_count", successCount).Debug("Fanout delivery complete")
	}
	if len(failedDestinations) > 0 {
		chattel.MessagesFailedCounter.Add(ctx, int64(len(failedDestinations)))
		logger.WithField("fail_count", len(failedDestinations)).
			Warn("some deliveries failed, re-emitting partial broadcast")

		// Re-emit a partial Broadcast with only the failed destinations.
		partialBroadcast := &eventsv1.Broadcast{
			Event:        eventLink,
			Destinations: failedDestinations,
			Priority:     broadcast.GetPriority(),
			Payload:      eventPayload,
		}
		return feh.evtsManager.Emit(ctx, RoomFanoutEventName, partialBroadcast)
	}

	return nil
}
