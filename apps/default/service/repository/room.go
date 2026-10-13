package repository

import (
	"context"
	"errors"
	"fmt"

	"github.com/pitabwire/frame/v2/datastore"
	"github.com/pitabwire/frame/v2/datastore/pool"
	"github.com/pitabwire/frame/v2/workerpool"
	"gorm.io/gorm"

	"github.com/stawilabs/chat/apps/default/service/models"
)

type roomRepository struct {
	datastore.BaseRepository[*models.Room]
}

// GetByTenantAndType retrieves rooms by tenant ID and room type.
func (rr *roomRepository) GetByTenantAndType(ctx context.Context, tenantID, roomType string) ([]*models.Room, error) {
	var rooms []*models.Room
	err := rr.Pool().DB(ctx, true).
		Where("tenant_id = ? AND room_type = ?", tenantID, roomType).
		Find(&rooms).Error
	return rooms, err
}

// GetRoomsByProfileID retrieves all rooms a profile is subscribed to.
func (rr *roomRepository) GetRoomsByProfileID(ctx context.Context, profileID string) ([]*models.Room, error) {
	var rooms []*models.Room
	err := rr.Pool().DB(ctx, true).
		Joins("JOIN room_subscriptions ON room_subscriptions.room_id = rooms.id").
		Where("room_subscriptions.profile_id = ? AND room_subscriptions.subscription_state = ?",
			profileID, models.RoomSubscriptionStateActive).
		Find(&rooms).Error
	return rooms, err
}

// directRoomsLimit bounds a key's lookup: a pair recreates its DM only when
// someone left, so a key names a handful of rooms at most.
const directRoomsLimit = 20

// DirectRooms lists the rooms keyed by key in the tenant and partitions given,
// oldest first. The caller names the tenancy explicitly, so the read is not
// scoped by the context's tenancy. It reads the primary: a personal room made
// a moment ago must be found, or a second would be made beside it.
func (rr *roomRepository) DirectRooms(
	ctx context.Context, key, tenantID string, partitions []string,
) ([]*models.Room, error) {
	if key == "" || len(partitions) == 0 {
		return nil, nil
	}
	var rooms []*models.Room
	err := rr.Pool().DB(ctx, false).
		Where("direct_key = ? AND tenant_id = ? AND partition_id IN ? AND deleted_at IS NULL",
			key, tenantID, partitions).
		Order("created_at ASC, id ASC").
		Limit(directRoomsLimit).
		Find(&rooms).Error
	return rooms, err
}

// keyedRoomStore is a KeyedRoomStore bound to one transaction on the primary.
type keyedRoomStore struct {
	tx         *gorm.DB
	key        string
	tenantID   string
	partitions []string
}

func (s *keyedRoomStore) Rooms() ([]*models.Room, error) {
	if len(s.partitions) == 0 {
		return nil, nil
	}
	var rooms []*models.Room
	// Unbounded: a key gains a room only when a person left the previous one
	// (a room never regains a member), so a key names a handful of rooms; a
	// cap would make resolution create a new room on every call once a key
	// passed it.
	err := s.tx.
		Where("direct_key = ? AND tenant_id = ? AND partition_id IN ? AND deleted_at IS NULL",
			s.key, s.tenantID, s.partitions).
		Order("created_at ASC, id ASC").
		Find(&rooms).Error
	return rooms, err
}

func (s *keyedRoomStore) ActiveSubscriptions(roomID string) ([]*models.RoomSubscription, error) {
	var subscriptions []*models.RoomSubscription
	err := s.tx.
		Where("room_id = ? AND subscription_state = ? AND deleted_at IS NULL",
			roomID, models.RoomSubscriptionStateActive).
		Order("id ASC").
		Find(&subscriptions).Error
	return subscriptions, err
}

func (s *keyedRoomStore) Insert(room *models.Room, subscriptions []*models.RoomSubscription) error {
	if room.DirectKey != s.key {
		return errors.New("a keyed room is inserted only under its own key's lock")
	}
	if err := s.tx.Create(room).Error; err != nil {
		return err
	}
	if len(subscriptions) == 0 {
		return nil
	}
	return s.tx.Create(&subscriptions).Error
}

func (s *keyedRoomStore) InsertServerEvent(event *models.RoomEvent, outbox *models.RoomOutbox) error {
	if err := s.tx.Create(event).Error; err != nil {
		return err
	}
	return s.tx.Create(outbox).Error
}

// WithDirectKeyLock runs fn in one transaction on the primary database that
// holds a transaction-scoped advisory lock on key, so resolutions of one key
// run one at a time: each sees what the one before it committed, and two
// resolving the same people answer the same room. fn's error rolls the
// transaction back. Everything fn reads and writes goes through the store,
// on the transaction's own connection: a waiter holds one connection and the
// holder needs no other, so waiters cannot starve the holder of the pool.
func (rr *roomRepository) WithDirectKeyLock(
	ctx context.Context, key, tenantID string, partitions []string, fn func(KeyedRoomStore) error,
) error {
	if key == "" {
		return errors.New("a keyed room lock needs a key")
	}
	return rr.Pool().DB(ctx, false).Transaction(func(tx *gorm.DB) error {
		if err := tx.Exec("SELECT pg_advisory_xact_lock(hashtextextended(?, 0))", key).Error; err != nil {
			return fmt.Errorf("failed to lock the room key: %w", err)
		}
		return fn(&keyedRoomStore{tx: tx, key: key, tenantID: tenantID, partitions: partitions})
	})
}

// NewRoomRepository creates a new room repository instance.
func NewRoomRepository(ctx context.Context, dbPool pool.Pool, workMan workerpool.Manager) RoomRepository {
	return &roomRepository{
		BaseRepository: datastore.NewBaseRepository[*models.Room](
			ctx, dbPool, workMan, func() *models.Room { return &models.Room{} },
		),
	}
}
