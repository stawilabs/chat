package events

import (
	"context"
	"errors"
	"fmt"
	"sync"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	eventsv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/events/v1"
	"github.com/pitabwire/frame/data"
	"github.com/pitabwire/frame/datastore/pool"
	frevents "github.com/pitabwire/frame/events"
	"github.com/pitabwire/frame/queue"
	"github.com/pitabwire/frame/workerpool"
	"github.com/pitabwire/util"

	"github.com/stawilabs/chat/apps/default/config"
	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/pkg/chatutil"
	chattel "github.com/stawilabs/chat/pkg/telemetry"
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

func (feh *FanoutEventHandler) Execute(ctx context.Context, payload any) error {
	ctx, span := chattel.EventTracer.Start(ctx, "Fanout")
	var err error
	defer func() { chattel.EventTracer.End(ctx, span, err) }()

	broadcast, ok := payload.(*eventsv1.Broadcast)
	if !ok {
		err = errors.New("invalid payload type, expected eventsv1.Broadcast{}")
		return err
	}

	destinations := broadcast.GetDestinations()
	if len(destinations) == 0 {
		return nil
	}

	eventPayload, resolveErr := feh.resolvePayload(ctx, broadcast)
	if resolveErr != nil && !errors.Is(resolveErr, errEphemeralEvent) {
		err = resolveErr
		return err
	}

	err = feh.publishDeliveries(ctx, broadcast, eventPayload)
	return err
}

// errEphemeralEvent signals that no payload is needed for ephemeral events.
var errEphemeralEvent = errors.New("ephemeral event: no payload")

func (feh *FanoutEventHandler) resolvePayload(
	ctx context.Context,
	broadcast *eventsv1.Broadcast,
) (*chatv1.Payload, error) {
	if p := broadcast.GetPayload(); p != nil {
		return p, nil
	}

	eventLink := broadcast.GetEvent()
	if isEphemeralRoomEvent(eventLink.GetEventType()) {
		return nil, errEphemeralEvent
	}

	eventLinkData, err := feh.eventRepo.GetByID(ctx, eventLink.GetEventId())
	if err != nil {
		if data.ErrorIsNoRows(err) {
			util.Log(ctx).WithError(err).Warn("persisted room event missing, will retry fanout")
			return nil, err
		}
		return nil, err
	}

	payload, err := feh.payloadConverter.ToProto(eventLinkData.Content)
	if err != nil {
		return nil, fmt.Errorf("failed to convert event content to payload: %w", err)
	}

	return payload, nil
}

func (feh *FanoutEventHandler) publishDeliveries(
	ctx context.Context,
	broadcast *eventsv1.Broadcast,
	eventPayload *chatv1.Payload,
) error {
	eventLink := broadcast.GetEvent()
	destinations := broadcast.GetDestinations()

	deliveryTopic, err := feh.getTopic()
	if err != nil {
		return err
	}

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
			util.Log(ctx).WithError(pubErr).
				WithField(chatutil.KeySubscriptionID, destination.GetSubscriptionId()).
				Warn("failed to publish delivery")
		}
	}

	successCount := int64(len(destinations)) - int64(len(failedDestinations))
	if successCount > 0 {
		chattel.EventFanoutCounter.Add(ctx, successCount)
	}

	if len(failedDestinations) > 0 {
		chattel.MessagesFailedCounter.Add(ctx, int64(len(failedDestinations)))
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
