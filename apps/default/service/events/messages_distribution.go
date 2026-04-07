package events

import (
	"context"
	"errors"
	"slices"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	eventsv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/events/v1"
	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	"github.com/antinvestor/service-chat/apps/default/service/models"
	"github.com/antinvestor/service-chat/apps/default/service/repository"
	chattel "github.com/antinvestor/service-chat/internal/telemetry"
	"github.com/pitabwire/frame/data"
	"github.com/pitabwire/frame/datastore/pool"
	frevents "github.com/pitabwire/frame/events"
	"github.com/pitabwire/frame/workerpool"
	"github.com/pitabwire/util"
	"google.golang.org/protobuf/proto"
)

const (
	RoomOutboxLoggingEventName = "room.outbox.logging.event"
	defaultBatchSize           = 1000
	// maxContinuationDepth prevents infinite fan-out for very large rooms.
	// At 1000 subscribers per batch this allows up to 100k subscribers.
	maxContinuationDepth = 100
)

type RoomOutboxLoggingQueue struct {
	evtsManager      frevents.Manager
	subscriptionRepo repository.RoomSubscriptionRepository
	eventRepo        repository.RoomEventRepository
	payloadConverter *models.PayloadConverter

	lowPriorityEventTypes []chatv1.RoomEventType
}

func NewRoomOutboxLoggingQueue(
	ctx context.Context,
	dbPool pool.Pool,
	workMan workerpool.Manager,
	evtsManager frevents.Manager,
) *RoomOutboxLoggingQueue {
	return &RoomOutboxLoggingQueue{
		subscriptionRepo: repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan),
		eventRepo:        repository.NewRoomEventRepository(ctx, dbPool, workMan),
		payloadConverter: models.NewPayloadConverter(),
		evtsManager:      evtsManager,
		lowPriorityEventTypes: []chatv1.RoomEventType{
			chatv1.RoomEventType_ROOM_EVENT_TYPE_TYPING,
			chatv1.RoomEventType_ROOM_EVENT_TYPE_DELIVERED,
			chatv1.RoomEventType_ROOM_EVENT_TYPE_READ,
			chatv1.RoomEventType_ROOM_EVENT_TYPE_SYSTEM, // moderation events
		},
	}
}

func (csq *RoomOutboxLoggingQueue) Name() string {
	return RoomOutboxLoggingEventName
}

func (csq *RoomOutboxLoggingQueue) PayloadType() any {
	return &eventsv1.Link{}
}

func (csq *RoomOutboxLoggingQueue) Validate(_ context.Context, payload any) error {
	_, ok := payload.(*eventsv1.Link)
	if !ok {
		return errors.New("invalid payload type, expected *RoomOutboxPayload or *eventsv1.Link")
	}
	return nil
}

func (csq *RoomOutboxLoggingQueue) Execute(ctx context.Context, payload any) error {
	ctx, span := chattel.EventTracer.Start(ctx, "OutboxLogging")
	var err error
	defer func() { chattel.EventTracer.End(ctx, span, err) }()

	evtLink, ok := payload.(*eventsv1.Link)
	if !ok {
		err = errors.New("invalid payload type")
		return err
	}

	subscriptions, fetchErr := csq.fetchSubscriberBatch(ctx, evtLink)
	if fetchErr != nil {
		err = fetchErr
		return err
	}
	if len(subscriptions) == 0 {
		return nil
	}

	if emitErr := csq.emitBroadcast(ctx, evtLink, subscriptions); emitErr != nil {
		err = emitErr
		return err
	}

	err = csq.emitContinuation(ctx, evtLink, subscriptions)
	return err
}

func (csq *RoomOutboxLoggingQueue) fetchSubscriberBatch(
	ctx context.Context,
	evtLink *eventsv1.Link,
) ([]*models.RoomSubscription, error) {
	var queryCursor *commonv1.PageCursor
	if c := evtLink.GetCursor(); c != nil && c.GetPage() != "" {
		queryCursor = &commonv1.PageCursor{
			Limit: defaultBatchSize,
			Page:  c.GetPage(),
		}
	} else {
		queryCursor = &commonv1.PageCursor{Limit: defaultBatchSize}
	}

	return csq.subscriptionRepo.GetByRoomID(ctx, evtLink.GetRoomId(), queryCursor)
}

func (csq *RoomOutboxLoggingQueue) emitBroadcast(
	ctx context.Context,
	evtLink *eventsv1.Link,
	subscriptions []*models.RoomSubscription,
) error {
	var destinations []*eventsv1.Subscription
	for _, sub := range subscriptions {
		if sub.IsActive() {
			destinations = append(destinations, &eventsv1.Subscription{
				SubscriptionId: sub.GetID(),
				ContactLink:    sub.ToLink(),
			})
		}
	}

	if len(destinations) == 0 {
		return nil
	}

	// Pre-fetch event payload on the first batch only (cursor page is empty).
	var eventPayload *chatv1.Payload
	if evtLink.GetCursor() == nil || evtLink.GetCursor().GetPage() == "" {
		eventPayload = csq.prefetchPayload(ctx, evtLink)
	}

	eventBroadcast := &eventsv1.Broadcast{
		Event:        evtLink,
		Destinations: destinations,
		Priority:     csq.getBroadCastPriority(evtLink.GetEventType()),
		Payload:      eventPayload,
	}
	if err := csq.evtsManager.Emit(ctx, RoomFanoutEventName, eventBroadcast); err != nil {
		return err
	}

	chattel.OutboxEntriesCreatedCounter.Add(ctx, int64(len(destinations)))
	return nil
}

func (csq *RoomOutboxLoggingQueue) emitContinuation(
	ctx context.Context,
	evtLink *eventsv1.Link,
	subscriptions []*models.RoomSubscription,
) error {
	if len(subscriptions) < defaultBatchSize {
		return nil
	}

	depth := int32(0)
	if evtLink.GetCursor() != nil {
		depth = evtLink.GetCursor().GetLimit()
	}
	depth++

	if int(depth) > maxContinuationDepth {
		util.Log(ctx).WithField("depth", depth).
			Warn("max outbox continuation depth reached, stopping fan-out")
		return nil
	}

	nextCursor := subscriptions[len(subscriptions)-1].GetID()
	nextLink, _ := proto.Clone(evtLink).(*eventsv1.Link)
	nextLink.SetCursor(&commonv1.PageCursor{
		Limit: depth,
		Page:  nextCursor,
	})

	return csq.evtsManager.Emit(ctx, RoomOutboxLoggingEventName, nextLink)
}

func (csq *RoomOutboxLoggingQueue) prefetchPayload(
	ctx context.Context,
	evtLink *eventsv1.Link,
) *chatv1.Payload {
	if isEphemeralRoomEvent(evtLink.GetEventType()) {
		return nil
	}

	evt, err := csq.eventRepo.GetByID(ctx, evtLink.GetEventId())
	if err != nil {
		if !data.ErrorIsNoRows(err) {
			util.Log(ctx).WithError(err).WithField("event_id", evtLink.GetEventId()).
				Debug("prefetch payload failed, fanout will retry")
		}
		return nil
	}

	payload, err := csq.payloadConverter.ToProto(evt.Content)
	if err != nil {
		util.Log(ctx).WithError(err).WithField("event_id", evtLink.GetEventId()).
			Debug("prefetch payload conversion failed")
		return nil
	}

	return payload
}

func (csq *RoomOutboxLoggingQueue) getBroadCastPriority(eventType chatv1.RoomEventType) eventsv1.Broadcast_Priority {
	if eventType == chatv1.RoomEventType_ROOM_EVENT_TYPE_CALL {
		return eventsv1.Broadcast_PRIORITY_HIGH
	}

	if slices.Contains(csq.lowPriorityEventTypes, eventType) {
		return eventsv1.Broadcast_PRIORITY_UNSPECIFIED
	}

	return eventsv1.Broadcast_PRIORITY_NORMAL
}
