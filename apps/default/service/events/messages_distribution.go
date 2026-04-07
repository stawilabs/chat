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

//nolint:nonamedreturns,gocognit,funlen // named return for tracing; sequential batch/continue/emit phases.
func (csq *RoomOutboxLoggingQueue) Execute(ctx context.Context, payload any) (err error) {
	ctx, span := chattel.EventTracer.Start(ctx, "OutboxLogging")
	defer func() { chattel.EventTracer.End(ctx, span, err) }()

	// Unwrap payload
	evtLink, ok := payload.(*eventsv1.Link)
	if !ok {
		return errors.New("invalid payload type")
	}

	roomID := evtLink.GetRoomId()
	logger := util.Log(ctx).WithFields(map[string]any{
		"room_id": roomID,
		"cursor":  evtLink.GetCursor(),
		"type":    csq.Name(),
	})
	logger.Debug("handling outbox logging batch")

	// Build a pagination cursor that always uses defaultBatchSize as the SQL limit.
	// The evtLink cursor's Limit field is repurposed as a continuation depth counter,
	// so we construct a separate cursor for the repository query.
	var queryCursor *commonv1.PageCursor
	if c := evtLink.GetCursor(); c != nil && c.GetPage() != "" {
		queryCursor = &commonv1.PageCursor{
			Limit: defaultBatchSize,
			Page:  c.GetPage(),
		}
	} else {
		queryCursor = &commonv1.PageCursor{Limit: defaultBatchSize}
	}

	// Fetch one batch of subscribers
	subscriptions, err := csq.subscriptionRepo.GetByRoomID(ctx, roomID, queryCursor)
	if err != nil {
		logger.WithError(err).Error("failed to get room subscribers")
		return err
	}

	if len(subscriptions) == 0 {
		logger.Debug("no more subscribers to process")
		return nil
	}

	logger.WithField("subscriber_count", len(subscriptions)).Debug("fetched room subscribers")

	var destinations []*eventsv1.Subscription
	for _, sub := range subscriptions {
		// Only broadcast messages to active subscriptions
		if sub.IsActive() {
			destinations = append(destinations, &eventsv1.Subscription{
				SubscriptionId: sub.GetID(),
				ContactLink:    sub.ToLink(),
			})
		}
	}

	// Emit broadcast for this batch
	if len(destinations) > 0 {
		broadCastPriority := csq.getBroadCastPriority(evtLink.GetEventType())

		// Pre-fetch event payload on the first batch only (cursor page is empty).
		// Continuation batches skip the DB read — the FanoutEventHandler will use
		// the payload from the first batch's Broadcast or fall back to its own fetch.
		var eventPayload *chatv1.Payload
		if evtLink.GetCursor() == nil || evtLink.GetCursor().GetPage() == "" {
			eventPayload = csq.prefetchPayload(ctx, evtLink)
		}

		eventBroadcast := eventsv1.Broadcast{
			Event:        evtLink,
			Destinations: destinations,
			Priority:     broadCastPriority,
			Payload:      eventPayload,
		}
		if err = csq.evtsManager.Emit(ctx, RoomFanoutEventName, &eventBroadcast); err != nil {
			logger.WithError(err).Error("failed to publish event broadcast")
			return err
		}
		chattel.OutboxEntriesCreatedCounter.Add(ctx, int64(len(destinations)))
		logger.WithField("batch_size", len(destinations)).Debug("emitted broadcast batch")
	}

	// If we fetched a full batch, there might be more subscribers. Emit a new job with the next cursor.
	// Guard against infinite fan-out by tracking total subscribers processed.
	if len(subscriptions) >= defaultBatchSize {
		depth := int32(0)
		if evtLink.GetCursor() != nil {
			depth = evtLink.GetCursor().GetLimit()
		}
		depth++
		if int(depth) > maxContinuationDepth {
			logger.WithField("depth", depth).
				Warn("max outbox continuation depth reached, stopping fan-out")
			return nil
		}

		nextCursor := subscriptions[len(subscriptions)-1].GetID()
		// Clone before mutation to avoid corrupting the Broadcast's shared reference.
		cloned := proto.Clone(evtLink)

		nextLink, _ := cloned.(*eventsv1.Link)
		nextLink.SetCursor(&commonv1.PageCursor{
			Limit: depth,
			Page:  nextCursor,
		})
		if err = csq.evtsManager.Emit(ctx, RoomOutboxLoggingEventName, nextLink); err != nil {
			logger.WithError(err).Error("failed to emit next batch job")
			return err
		}
		logger.WithField("next_cursor", nextCursor).Debug("emitted next batch job")
	}

	return nil
}

// prefetchPayload loads the event content from the DB so the fanout handler
// does not need to re-fetch it for every batch.  Returns nil for ephemeral
// events or on any error (the fanout handler will fall back to its own fetch).
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
