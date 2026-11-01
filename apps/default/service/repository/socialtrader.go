package repository

import (
	"context"
	"errors"
	"time"

	"github.com/pitabwire/frame/v3/data"
	"github.com/pitabwire/frame/v3/datastore"
	"github.com/pitabwire/frame/v3/datastore/pool"
	"github.com/pitabwire/frame/v3/workerpool"
	"gorm.io/gorm/clause"

	"github.com/stawilabs/chat/apps/default/service/models"
)

// ErrBindingOwnedByAnother is returned when a write would change a room's
// binding that another leader holds.
var ErrBindingOwnedByAnother = errors.New("the room's pool binding is held by another leader")

// SocialTraderRoomRepository stores the binding between a chat room and a
// strategy pool. Ownership is enforced in the writes themselves, so two
// racing writers cannot both believe they hold the room.
type SocialTraderRoomRepository interface {
	datastore.BaseRepository[*models.SocialTraderRoomBinding]
	// GetByRoomID returns the room's binding, or nil when the room is not
	// bound to a pool.
	GetByRoomID(ctx context.Context, roomID string) (*models.SocialTraderRoomBinding, error)
	// Upsert records the binding. A room with no live binding (none, or an
	// unbound soft-deleted row) takes it; a room bound by the same leader is
	// updated; a room bound by another leader refuses it with
	// ErrBindingOwnedByAnother.
	Upsert(ctx context.Context, binding *models.SocialTraderRoomBinding) error
	// DeleteByRoomID removes the room's binding when leaderProfileID holds
	// it; ErrBindingOwnedByAnother when another leader does, no error when
	// there is none.
	DeleteByRoomID(ctx context.Context, roomID, leaderProfileID string) error
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
	// One statement decides ownership: the row is updated only when the same
	// leader holds it or it was unbound (soft-deleted), and an unbound row is
	// brought back. Zero rows means another leader holds the room.
	result := r.Pool().DB(ctx, false).Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "room_id"}},
		DoUpdates: clause.Assignments(map[string]any{
			"pool_id":           binding.PoolID,
			"leader_profile_id": binding.LeaderProfileID,
			"bound_at":          binding.BoundAt,
			"modified_at":       time.Now(),
			"deleted_at":        nil,
		}),
		Where: clause.Where{Exprs: []clause.Expression{clause.Expr{
			SQL: "socialtrader_room_bindings.leader_profile_id = EXCLUDED.leader_profile_id " +
				"OR socialtrader_room_bindings.deleted_at IS NOT NULL",
		}}},
	}).Create(binding)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return ErrBindingOwnedByAnother
	}
	return nil
}

func (r *socialTraderRoomRepository) DeleteByRoomID(ctx context.Context, roomID, leaderProfileID string) error {
	result := r.Pool().DB(ctx, false).
		Where("room_id = ? AND leader_profile_id = ?", roomID, leaderProfileID).
		Delete(&models.SocialTraderRoomBinding{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected > 0 {
		return nil
	}
	// Nothing deleted: either no live binding, or another leader's.
	existing, err := r.GetByRoomID(ctx, roomID)
	if err != nil {
		return err
	}
	if existing != nil {
		return ErrBindingOwnedByAnother
	}
	return nil
}
