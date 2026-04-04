package events

import (
	"context"
	"errors"
	"fmt"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	eventsv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/events/v1"
	"github.com/antinvestor/service-chat/apps/default/config"
	"github.com/antinvestor/service-chat/apps/default/service/models"
	"github.com/antinvestor/service-chat/apps/default/service/repository"
	chattel "github.com/antinvestor/service-chat/internal/telemetry"
	"github.com/pitabwire/frame/data"
	"github.com/pitabwire/frame/datastore/pool"
	"github.com/pitabwire/frame/queue"
	"github.com/pitabwire/frame/workerpool"
	"github.com/pitabwire/util"
)

const RoomFanoutEventName = "room.message.fanout.event"

type FanoutEventHandler struct {
	cfg              *config.ChatConfig
	eventRepo        repository.RoomEventRepository
	queueMan         queue.Manager
	deliveryTopic    queue.Publisher
	payloadConverter *models.PayloadConverter
}

func NewFanoutEventHandler(
	ctx context.Context,
	cfg *config.ChatConfig,
	dbPool pool.Pool,
	workMan workerpool.Manager,
	queueMan queue.Manager,
) *FanoutEventHandler {
	return &FanoutEventHandler{
		cfg:              cfg,
		queueMan:         queueMan,
		eventRepo:        repository.NewRoomEventRepository(ctx, dbPool, workMan),
		payloadConverter: models.NewPayloadConverter(),
	}
}

func (feh *FanoutEventHandler) getTopic() (queue.Publisher, error) {
	if feh.deliveryTopic != nil {
		return feh.deliveryTopic, nil
	}

	var err error
	feh.deliveryTopic, err = feh.queueMan.GetPublisher(feh.cfg.QueueDeviceEventDeliveryName)
	if err != nil {
		return nil, err
	}
	return feh.deliveryTopic, nil
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

//nolint:nonamedreturns,nestif // fanout coordinates retryable persistence lookups and per-target publish errors.
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

	var eventPayload *chatv1.Payload
	if isEphemeralRoomEvent(eventLink.GetEventType()) {
		logger.WithField("event_type", eventLink.GetEventType().String()).
			Debug("fanout handling ephemeral room event")
	} else {
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

	// Publish all deliveries and retry the whole fanout when any target fails.
	var failCount int
	var publishErrs []error
	for _, destination := range destinations {
		eventDelivery := &eventsv1.Delivery{
			Event:        eventLink,
			Destination:  destination,
			Payload:      eventPayload,
			IsCompressed: false,
			RetryCount:   0,
		}

		if pubErr := deliveryTopic.Publish(ctx, eventDelivery); pubErr != nil {
			failCount++
			publishErrs = append(publishErrs, pubErr)
			logger.WithError(pubErr).
				WithField("subscription_id", destination.GetSubscriptionId()).
				Warn("failed to publish delivery")
		}
	}

	successCount := int64(len(destinations)) - int64(failCount)
	if successCount > 0 {
		chattel.EventFanoutCounter.Add(ctx, successCount)
		logger.WithField("success_count", successCount).Debug("Fanout delivery complete")
	}
	if failCount > 0 {
		chattel.MessagesFailedCounter.Add(ctx, int64(failCount))
		logger.WithField("fail_count", failCount).Warn("some deliveries failed")
		return fmt.Errorf("failed to publish %d/%d deliveries: %w",
			failCount, len(destinations), errors.Join(publishErrs...))
	}

	return nil
}

func isEphemeralRoomEvent(eventType chatv1.RoomEventType) bool {
	//nolint:exhaustive // Only the explicitly ephemeral room event types should return true.
	switch eventType {
	case chatv1.RoomEventType_ROOM_EVENT_TYPE_TYPING,
		chatv1.RoomEventType_ROOM_EVENT_TYPE_DELIVERED,
		chatv1.RoomEventType_ROOM_EVENT_TYPE_READ:
		return true
	default:
		return false
	}
}
