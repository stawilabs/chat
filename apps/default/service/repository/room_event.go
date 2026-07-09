package repository

import (
	"context"
	"time"

	"github.com/pitabwire/frame/v2/datastore"
	"github.com/pitabwire/frame/v2/datastore/pool"
	"github.com/pitabwire/frame/v2/workerpool"
	"github.com/rs/xid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/stawilabs/chat/apps/default/service/models"
)

const defaultUnboundedLimit = 500

// eventTimeBound returns the second-resolution timestamp embedded in a cursor
// xid. Every event's created_at is derived from its xid timestamp (and event IDs
// are validated as xids on write), so pairing the id keyset with a created_at
// bound lets TimescaleDB prune chunks by time without changing the result set.
func eventTimeBound(cursor string) (time.Time, bool) {
	id, err := xid.FromString(cursor)
	if err != nil {
		return time.Time{}, false
	}
	return id.Time(), true
}

type roomEventRepository struct {
	datastore.BaseRepository[*models.RoomEvent]
}

// NewRoomEventRepository creates a new room event repository instance.
func NewRoomEventRepository(ctx context.Context, dbPool pool.Pool, workMan workerpool.Manager) RoomEventRepository {
	return &roomEventRepository{
		BaseRepository: datastore.NewBaseRepository[*models.RoomEvent](
			ctx, dbPool, workMan, func() *models.RoomEvent { return &models.RoomEvent{} },
		),
	}
}

// GetByRoomID retrieves all events for a specific room, ordered by ID (naturally time-sorted).
func (rer *roomEventRepository) GetByRoomID(
	ctx context.Context,
	roomID string,
	limit int,
) ([]*models.RoomEvent, error) {
	var events []*models.RoomEvent
	query := rer.Pool().DB(ctx, true).
		Unscoped(). // Disable GORM's automatic soft delete filtering
		Where("room_id = ? AND deleted_at IS NULL", roomID).
		Order("id ASC")

	if limit > 0 {
		query = query.Limit(limit)
	} else {
		query = query.Limit(defaultUnboundedLimit) // Safety net: prevent unbounded full-table scans
	}

	err := query.Find(&events).Error
	return events, err
}

// GetHistory retrieves room events with pagination support.
// beforeEventID: get events before this event ID (exclusive)
// afterEventID: get events after this event ID (exclusive)
// limit: maximum number of events to return
func (rer *roomEventRepository) GetHistory(
	ctx context.Context,
	roomID string,
	beforeEventID string,
	afterEventID string,
	limit int,
) ([]*models.RoomEvent, error) {
	var events []*models.RoomEvent
	query := rer.Pool().DB(ctx, true).
		Unscoped(). // Disable GORM's automatic soft delete filtering
		Where("room_id = ? AND deleted_at IS NULL", roomID)

	if beforeEventID != "" {
		query = query.Where("id < ?", beforeEventID)
		// Chunk-exclusion bound: created_at <= cursor time is implied by id < cursor
		// (created_at is the xid timestamp), so this prunes chunks without
		// changing results.
		if t, ok := eventTimeBound(beforeEventID); ok {
			query = query.Where("created_at <= ?", t)
		}
	}

	if afterEventID != "" {
		query = query.Where("id > ?", afterEventID)
		if t, ok := eventTimeBound(afterEventID); ok {
			query = query.Where("created_at >= ?", t)
		}
	}

	// "before" queries page backwards from the newest entries, while "after"
	// queries page forward from an existing cursor.
	if afterEventID != "" {
		query = query.Order("id ASC")
	} else {
		query = query.Order("id DESC")
	}

	if limit > 0 {
		query = query.Limit(limit)
	}

	err := query.Find(&events).Error
	return events, err
}

// GetByEventID retrieves a room event by its event ID (xid).
func (rer *roomEventRepository) GetByEventID(ctx context.Context, roomID, eventID string) (*models.RoomEvent, error) {
	event := &models.RoomEvent{}
	err := rer.Pool().DB(ctx, true).
		Unscoped().
		Where("room_id = ? AND id = ? AND deleted_at IS NULL", roomID, eventID).
		First(event).Error
	return event, err
}

// CountByRoomID counts the total number of events in a room.
func (rer *roomEventRepository) CountByRoomID(ctx context.Context, roomID string) (int64, error) {
	var count int64
	err := rer.Pool().DB(ctx, true).
		Model(&models.RoomEvent{}).
		Unscoped().
		Where("room_id = ? AND deleted_at IS NULL", roomID).
		Count(&count).Error
	return count, err
}

// CreateIgnoringDuplicates inserts events individually with ON CONFLICT DO NOTHING.
// Returns a map of eventID -> true for events that were actually inserted.
// This prevents race conditions where concurrent requests insert the same event ID.
func (rer *roomEventRepository) CreateIgnoringDuplicates(
	ctx context.Context,
	events []*models.RoomEvent,
) (map[string]bool, error) {
	insertedIDs := make(map[string]bool, len(events))
	if len(events) == 0 {
		return insertedIDs, nil
	}

	db := rer.Pool().DB(ctx, false)
	err := db.Transaction(func(tx *gorm.DB) error {
		for _, event := range events {
			result := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(event)
			if result.Error != nil {
				return result.Error
			}
			if result.RowsAffected > 0 {
				insertedIDs[event.GetID()] = true
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return insertedIDs, nil
}

// ExistsByIDs checks if any of the given event IDs already exist.
// Returns a map of eventID -> exists for efficient deduplication.
// This is used to implement idempotency - preventing duplicate message inserts.
func (rer *roomEventRepository) ExistsByIDs(ctx context.Context, eventIDs []string) (map[string]bool, error) {
	result := make(map[string]bool, len(eventIDs))

	// Initialize all as not existing
	for _, id := range eventIDs {
		result[id] = false
	}

	if len(eventIDs) == 0 {
		return result, nil
	}

	// Query for existing IDs
	var existingIDs []string
	err := rer.Pool().DB(ctx, true).
		Model(&models.RoomEvent{}).
		Unscoped().
		Where("id IN ? AND deleted_at IS NULL", eventIDs).
		Pluck("id", &existingIDs).Error
	if err != nil {
		return nil, err
	}

	// Mark existing IDs
	for _, id := range existingIDs {
		result[id] = true
	}

	return result, nil
}
