package repository

import (
	"context"

	"github.com/pitabwire/frame/v3/data"
	"github.com/pitabwire/frame/v3/datastore"
	"github.com/pitabwire/frame/v3/datastore/pool"
	"github.com/pitabwire/frame/v3/workerpool"
	"gorm.io/gorm/clause"

	"github.com/stawilabs/chat/apps/default/service/models"
)

// SocialTraderRoomRepository stores the binding between a chat room and a
// strategy pool.
type SocialTraderRoomRepository interface {
	datastore.BaseRepository[*models.SocialTraderRoomBinding]
	// GetByRoomID returns the room's binding, or nil when the room is not
	// bound to a pool.
	GetByRoomID(ctx context.Context, roomID string) (*models.SocialTraderRoomBinding, error)
	// Upsert records the binding, replacing the room's earlier one.
	Upsert(ctx context.Context, binding *models.SocialTraderRoomBinding) error
}

type socialTraderRoomRepository struct {
	datastore.BaseRepository[*models.SocialTraderRoomBinding]
}

// NewSocialTraderRoomRepository creates a pool binding repository.
func NewSocialTraderRoomRepository(
	ctx context.Context, dbPool pool.Pool, workMan workerpool.Manager,
) SocialTraderRoomRepository {
	return &socialTraderRoomRepository{
		BaseRepository: datastore.NewBaseRepository[*models.SocialTraderRoomBinding](
			ctx, dbPool, workMan,
			func() *models.SocialTraderRoomBinding { return &models.SocialTraderRoomBinding{} },
		),
	}
}

func (r *socialTraderRoomRepository) GetByRoomID(
	ctx context.Context, roomID string,
) (*models.SocialTraderRoomBinding, error) {
	var binding models.SocialTraderRoomBinding
	err := r.Pool().DB(ctx, true).Where("room_id = ?", roomID).First(&binding).Error
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return nil, nil //nolint:nilnil // an unbound room has no binding
		}
		return nil, err
	}
	return &binding, nil
}

func (r *socialTraderRoomRepository) Upsert(ctx context.Context, binding *models.SocialTraderRoomBinding) error {
	if binding.GetID() == "" {
		binding.GenID(ctx)
	}
	return r.Pool().DB(ctx, false).Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "room_id"}},
		DoUpdates: clause.AssignmentColumns([]string{"pool_id", "leader_profile_id", "bound_at", "modified_at"}),
	}).Create(binding).Error
}
