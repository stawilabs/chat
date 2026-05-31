package repository

import (
	"context"
	"time"

	"github.com/pitabwire/frame/datastore"
	"github.com/pitabwire/frame/datastore/pool"
	"github.com/pitabwire/frame/workerpool"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/stawilabs/chat/apps/default/service/models"
)

type roomOutboxRepository struct {
	datastore.BaseRepository[*models.RoomOutbox]
}

// NewRoomOutboxRepository creates a new room outbox repository instance.
func NewRoomOutboxRepository(ctx context.Context, dbPool pool.Pool, workMan workerpool.Manager) RoomOutboxRepository {
	return &roomOutboxRepository{
		BaseRepository: datastore.NewBaseRepository[*models.RoomOutbox](
			ctx, dbPool, workMan, func() *models.RoomOutbox { return &models.RoomOutbox{} },
		),
	}
}

// SaveEventsWithOutbox persists events and their outbox rows in a SINGLE
// transaction. For each event it does an ON CONFLICT DO NOTHING insert; when the
// event is newly inserted it also inserts the matching outbox row (payloads keyed
// by event ID). Because both writes share one transaction, an event can never be
// committed without a durable record of the intent to deliver it — closing the
// crash-between-commit-and-publish gap. Returns the set of newly-inserted IDs.
func (r *roomOutboxRepository) SaveEventsWithOutbox(
	ctx context.Context,
	events []*models.RoomEvent,
	payloads map[string][]byte,
) (map[string]bool, error) {
	insertedIDs := make(map[string]bool, len(events))
	if len(events) == 0 {
		return insertedIDs, nil
	}

	db := r.Pool().DB(ctx, false)
	err := db.Transaction(func(tx *gorm.DB) error {
		for _, event := range events {
			res := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(event)
			if res.Error != nil {
				return res.Error
			}
			if res.RowsAffected == 0 {
				// Duplicate event (concurrent insert) — the winning insert owns
				// the outbox row, so skip it here.
				continue
			}

			outbox := &models.RoomOutbox{
				EventID: event.GetID(),
				RoomID:  event.RoomID,
				Payload: payloads[event.GetID()],
			}
			outbox.GenID(ctx)
			if obErr := tx.Clauses(clause.OnConflict{
				Columns:   []clause.Column{{Name: "event_id"}},
				DoNothing: true,
			}).Create(outbox).Error; obErr != nil {
				return obErr
			}

			insertedIDs[event.GetID()] = true
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return insertedIDs, nil
}

// ListPending returns undispatched outbox rows created at or before olderThan,
// oldest first, capped at limit. The olderThan grace period avoids racing the
// optimistic inline emit on the hot path.
func (r *roomOutboxRepository) ListPending(
	ctx context.Context,
	olderThan time.Time,
	limit int,
) ([]*models.RoomOutbox, error) {
	var rows []*models.RoomOutbox
	query := r.Pool().DB(ctx, true).
		Where("dispatched = ? AND created_at <= ?", false, olderThan).
		Order("created_at ASC")
	if limit > 0 {
		query = query.Limit(limit)
	}
	err := query.Find(&rows).Error
	return rows, err
}

// DeleteByEventID removes the outbox row for an event, used when an event is
// rolled back after persistence (e.g. call-state finalization failure).
func (r *roomOutboxRepository) DeleteByEventID(ctx context.Context, eventID string) error {
	return r.Pool().DB(ctx, false).
		Where("event_id = ?", eventID).
		Delete(&models.RoomOutbox{}).Error
}

// MarkDispatched marks the given outbox rows (by event ID) as dispatched.
func (r *roomOutboxRepository) MarkDispatched(ctx context.Context, eventIDs []string) error {
	if len(eventIDs) == 0 {
		return nil
	}
	return r.Pool().DB(ctx, false).
		Table("room_outbox").
		Where("event_id IN ?", eventIDs).
		Updates(map[string]any{"dispatched": true, "dispatched_at": time.Now().UnixMilli()}).
		Error
}
