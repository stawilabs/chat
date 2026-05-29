package events

import (
	"context"
	"time"

	eventsv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/events/v1"
	frevents "github.com/pitabwire/frame/events"
	"github.com/pitabwire/util"
	"google.golang.org/protobuf/encoding/protojson"

	"github.com/stawilabs/chat/apps/default/service/repository"
)

const (
	// defaultRelayInterval is how often the relay polls for pending outbox rows.
	defaultRelayInterval = 200 * time.Millisecond
	// defaultRelayGrace is how old a row must be before the relay dispatches it.
	// Zero because the relay is the sole publisher (no inline emit to race).
	defaultRelayGrace = 0
	// defaultRelayBatch caps how many rows are dispatched per tick.
	defaultRelayBatch = 500
)

// OutboxRelay drains the durable room_outbox table into the fan-out pipeline. It
// is the SOLE publisher of RoomOutboxLoggingEventName: SendEvents persists an
// event and its outbox row atomically, and this relay emits it asynchronously,
// so a crash can never leave a persisted event undelivered. Delivery is
// at-least-once; downstream consumers must be idempotent.
type OutboxRelay struct {
	outboxRepo    repository.RoomOutboxRepository
	eventsManager frevents.Manager
	interval      time.Duration
	grace         time.Duration
	batch         int
}

// NewOutboxRelay creates an OutboxRelay with default polling parameters.
func NewOutboxRelay(
	outboxRepo repository.RoomOutboxRepository,
	eventsManager frevents.Manager,
) *OutboxRelay {
	return &OutboxRelay{
		outboxRepo:    outboxRepo,
		eventsManager: eventsManager,
		interval:      defaultRelayInterval,
		grace:         defaultRelayGrace,
		batch:         defaultRelayBatch,
	}
}

// Run drives the relay loop until ctx is cancelled, then returns nil. It
// satisfies frame's background-consumer contract (func(context.Context) error)
// so the relay is owned by the service worker pool and stops on graceful
// shutdown — no manually-managed goroutine, fully portable across runtimes.
func (r *OutboxRelay) Run(ctx context.Context) error {
	ticker := time.NewTicker(r.interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return nil
		case <-ticker.C:
			if err := r.Drain(ctx); err != nil {
				util.Log(ctx).WithError(err).Warn("outbox relay drain failed")
			}
		}
	}
}

// Drain dispatches one batch of pending outbox rows and marks them dispatched.
// Exported so it can be exercised directly in tests; Run calls it on each tick.
func (r *OutboxRelay) Drain(ctx context.Context) error {
	rows, err := r.outboxRepo.ListPending(ctx, time.Now().Add(-r.grace), r.batch)
	if err != nil {
		return err
	}
	if len(rows) == 0 {
		return nil
	}

	dispatched := make([]string, 0, len(rows))
	for _, row := range rows {
		link := &eventsv1.Link{}
		if umErr := protojson.Unmarshal(row.Payload, link); umErr != nil {
			// Unrecoverable payload — mark dispatched so it can't loop forever.
			util.Log(ctx).WithError(umErr).WithField("event_id", row.EventID).
				Error("outbox row has unparseable payload; dropping")
			dispatched = append(dispatched, row.EventID)
			continue
		}
		if emitErr := r.eventsManager.Emit(ctx, RoomOutboxLoggingEventName, link); emitErr != nil {
			// Leave undispatched; it is retried on the next tick.
			util.Log(ctx).WithError(emitErr).WithField("event_id", row.EventID).
				Warn("outbox relay emit failed; will retry")
			continue
		}
		dispatched = append(dispatched, row.EventID)
	}
	return r.outboxRepo.MarkDispatched(ctx, dispatched)
}
