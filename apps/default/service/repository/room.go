package repository

import (
	"context"

	"github.com/pitabwire/frame/v2/datastore"
	"github.com/pitabwire/frame/v2/datastore/pool"
	"github.com/pitabwire/frame/v2/workerpool"

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

// NewRoomRepository creates a new room repository instance.
// directRoomsLimit bounds a key's lookup: a pair recreates its DM only when
// someone left, so a key names a handful of rooms at most.
const directRoomsLimit = 20

// DirectRooms lists the rooms keyed by key in the tenant and partitions given,
// oldest first. The caller names the tenancy explicitly, so the read is not
// scoped by the context's tenancy.
func (rr *roomRepository) DirectRooms(
	ctx context.Context, key, tenantID string, partitions []string,
) ([]*models.Room, error) {
	if key == "" || len(partitions) == 0 {
		return nil, nil
	}
	var rooms []*models.Room
	err := rr.Pool().DB(ctx, true).
		Where("direct_key = ? AND tenant_id = ? AND partition_id IN ? AND deleted_at IS NULL",
			key, tenantID, partitions).
		Order("created_at ASC, id ASC").
		Limit(directRoomsLimit).
		Find(&rooms).Error
	return rooms, err
}

func NewRoomRepository(ctx context.Context, dbPool pool.Pool, workMan workerpool.Manager) RoomRepository {
	return &roomRepository{
		BaseRepository: datastore.NewBaseRepository[*models.Room](
			ctx, dbPool, workMan, func() *models.Room { return &models.Room{} },
		),
	}
}
