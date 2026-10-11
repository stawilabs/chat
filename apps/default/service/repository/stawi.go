package repository

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/pitabwire/frame/v2/data"
	"github.com/pitabwire/frame/v2/datastore"
	"github.com/pitabwire/frame/v2/datastore/pool"
	"github.com/pitabwire/frame/v2/workerpool"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/stawilabs/chat/apps/default/service/models"
)

// colState is the state column of the Stawi tables.
const colState = "state"

// StawiRoomRepository stores the binding between a chat room and its custody.
type StawiRoomRepository interface {
	datastore.BaseRepository[*models.StawiRoom]
	// IsBound reports whether the chain has the room. A missing row is not bound.
	IsBound(ctx context.Context, roomID string) (bool, error)
	// RecordGenesis records the genesis prepared for a room that is not bound.
	RecordGenesis(ctx context.Context, room *models.Room, genesisID, eventID string, founders []string) error
	// GetByGovernance returns the room a GovernanceModule belongs to.
	GetByGovernance(ctx context.Context, governance string) (*models.StawiRoom, error)
	// ListBound pages through bound rooms by id.
	ListBound(ctx context.Context, afterID string, limit int) ([]*models.StawiRoom, error)
}

type stawiRoomRepository struct {
	datastore.BaseRepository[*models.StawiRoom]
}

// NewStawiRoomRepository creates a Stawi room binding repository.
func NewStawiRoomRepository(ctx context.Context, dbPool pool.Pool, workMan workerpool.Manager) StawiRoomRepository {
	return &stawiRoomRepository{
		BaseRepository: datastore.NewBaseRepository[*models.StawiRoom](
			ctx, dbPool, workMan, func() *models.StawiRoom { return &models.StawiRoom{} },
		),
	}
}

func (r *stawiRoomRepository) IsBound(ctx context.Context, roomID string) (bool, error) {
	var count int64
	err := r.Pool().DB(ctx, false).Model(&models.StawiRoom{}).
		Where("id = ? AND state = ?", roomID, models.StawiRoomStateBound).Count(&count).Error
	return count > 0, err
}

func (r *stawiRoomRepository) RecordGenesis(
	ctx context.Context, room *models.Room, genesisID, eventID string, founders []string,
) error {
	row := &models.StawiRoom{
		State:          models.StawiRoomStatePending,
		GenesisID:      genesisID,
		GenesisEventID: eventID,
		Founders:       strings.Join(founders, ","),
	}
	row.ID = room.GetID()
	row.TenantID, row.PartitionID, row.AccessID = room.TenantID, room.PartitionID, room.AccessID
	// A bound room keeps its binding: a later conversion of a bound room is
	// refused before this point, and the WHERE guards a race with activation.
	return r.Pool().DB(ctx, false).Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "id"}},
		DoUpdates: clause.Assignments(map[string]any{
			"genesis_id":       genesisID,
			"genesis_event_id": eventID,
			"founders":         row.Founders,
			"modified_at":      time.Now(),
		}),
		Where: clause.Where{Exprs: []clause.Expression{
			clause.Neq{Column: clause.Column{Table: "stawi_rooms", Name: colState}, Value: models.StawiRoomStateBound},
		}},
	}).Create(row).Error
}

func (r *stawiRoomRepository) GetByGovernance(ctx context.Context, governance string) (*models.StawiRoom, error) {
	var row models.StawiRoom
	err := r.Pool().DB(ctx, false).Where("governance_address = ?", strings.ToLower(governance)).First(&row).Error
	if err != nil {
		return nil, err
	}
	return &row, nil
}

func (r *stawiRoomRepository) ListBound(ctx context.Context, afterID string, limit int) ([]*models.StawiRoom, error) {
	var rows []*models.StawiRoom
	err := r.Pool().DB(ctx, false).
		Where("state = ? AND id > ?", models.StawiRoomStateBound, afterID).
		Order("id ASC").Limit(limit).Find(&rows).Error
	return rows, err
}

// StawiRoomCallRepository tracks the signed calls chat relayed.
type StawiRoomCallRepository interface {
	datastore.BaseRepository[*models.StawiRoomCall]
	// Record stores a relayed call once; a repeat relay keeps the first row.
	Record(ctx context.Context, call *models.StawiRoomCall) error
	// FindBySigner finds the call a chain fact names by signer and nonce.
	FindBySigner(ctx context.Context, roomID, signer string, nonce uint64) (*models.StawiRoomCall, error)
	// SetState moves a call to a final state; it reports false if it was
	// already final (so its outcome is posted once).
	SetState(ctx context.Context, callID, state string) (bool, error)
	// ListSubmittedBefore returns calls still awaiting an outcome.
	ListSubmittedBefore(ctx context.Context, before time.Time, limit int) ([]*models.StawiRoomCall, error)
}

type stawiRoomCallRepository struct {
	datastore.BaseRepository[*models.StawiRoomCall]
}

// NewStawiRoomCallRepository creates a relayed-call repository.
func NewStawiRoomCallRepository(
	ctx context.Context, dbPool pool.Pool, workMan workerpool.Manager,
) StawiRoomCallRepository {
	return &stawiRoomCallRepository{
		BaseRepository: datastore.NewBaseRepository[*models.StawiRoomCall](
			ctx, dbPool, workMan, func() *models.StawiRoomCall { return &models.StawiRoomCall{} },
		),
	}
}

func (r *stawiRoomCallRepository) Record(ctx context.Context, call *models.StawiRoomCall) error {
	call.SignerAddress = strings.ToLower(call.SignerAddress)
	return r.Pool().DB(ctx, false).Clauses(clause.OnConflict{DoNothing: true}).Create(call).Error
}

func (r *stawiRoomCallRepository) FindBySigner(
	ctx context.Context, roomID, signer string, nonce uint64,
) (*models.StawiRoomCall, error) {
	var row models.StawiRoomCall
	err := r.Pool().DB(ctx, false).
		Where("room_id = ? AND signer_address = ? AND nonce = ?", roomID, strings.ToLower(signer), nonce).
		First(&row).Error
	if err != nil {
		return nil, err
	}
	return &row, nil
}

func (r *stawiRoomCallRepository) SetState(ctx context.Context, callID, state string) (bool, error) {
	res := r.Pool().DB(ctx, false).Model(&models.StawiRoomCall{}).
		Where("id = ? AND state = ?", callID, models.StawiCallStateSubmitted).
		Updates(map[string]any{colState: state, "modified_at": time.Now()})
	return res.RowsAffected > 0, res.Error
}

func (r *stawiRoomCallRepository) ListSubmittedBefore(
	ctx context.Context, before time.Time, limit int,
) ([]*models.StawiRoomCall, error) {
	var rows []*models.StawiRoomCall
	err := r.Pool().DB(ctx, false).
		Where("state = ? AND created_at < ?", models.StawiCallStateSubmitted, before).
		Order("created_at ASC").Limit(limit).Find(&rows).Error
	return rows, err
}

// StawiChainStore is the chain consumer's storage: the fact inbox and the
// membership the facts fold into. Everything a room's facts change is written
// inside WithRoomLock, so replicas apply one room's facts one at a time.
type StawiChainStore interface {
	// Record inserts a fact into the inbox once; it reports whether it was new.
	Record(ctx context.Context, fact *models.StawiChainFact) (bool, error)
	// AssignRoom places facts that arrived before their room was known.
	AssignRoom(ctx context.Context, custody, roomID string) error
	// RoomsWithPending returns rooms that have facts waiting to be applied.
	RoomsWithPending(ctx context.Context, limit int) ([]string, error)
	// WithRoomLock runs fn in a transaction holding the room's lock.
	WithRoomLock(ctx context.Context, roomID string, fn func(tx *gorm.DB) error) error
	// Pending returns the room's unapplied facts in chain order.
	Pending(tx *gorm.DB, roomID string) ([]*models.StawiChainFact, error)
	// MarkApplied marks a fact applied.
	MarkApplied(tx *gorm.DB, fact *models.StawiChainFact) error
	// Member returns the member row for an address, or a new unsaved one.
	Member(tx *gorm.DB, room *models.Room, address string) (*models.StawiRoomMember, error)
	// SaveMember upserts a member row.
	SaveMember(tx *gorm.DB, member *models.StawiRoomMember) error
	// Members returns every member row of a room.
	Members(ctx context.Context, roomID string) ([]*models.StawiRoomMember, error)
}

type stawiChainStore struct {
	pool pool.Pool
}

// NewStawiChainStore creates the chain consumer's store.
func NewStawiChainStore(dbPool pool.Pool) StawiChainStore {
	return &stawiChainStore{pool: dbPool}
}

func (s *stawiChainStore) Record(ctx context.Context, fact *models.StawiChainFact) (bool, error) {
	fact.CustodyAddress = strings.ToLower(fact.CustodyAddress)
	fact.GenID(ctx)
	res := s.pool.DB(ctx, false).Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "fact_key"}},
		DoNothing: true,
	}).Create(fact)
	return res.RowsAffected == 1, res.Error
}

func (s *stawiChainStore) AssignRoom(ctx context.Context, custody, roomID string) error {
	return s.pool.DB(ctx, false).Model(&models.StawiChainFact{}).
		Where("room_id = '' AND custody_address = ?", strings.ToLower(custody)).
		Update("room_id", roomID).Error
}

func (s *stawiChainStore) RoomsWithPending(ctx context.Context, limit int) ([]string, error) {
	var rooms []string
	err := s.pool.DB(ctx, false).Model(&models.StawiChainFact{}).
		Where("applied = ? AND room_id <> ''", false).
		Distinct("room_id").Limit(limit).Pluck("room_id", &rooms).Error
	return rooms, err
}

func (s *stawiChainStore) WithRoomLock(ctx context.Context, roomID string, fn func(tx *gorm.DB) error) error {
	return s.pool.DB(ctx, false).Transaction(func(tx *gorm.DB) error {
		if err := tx.Exec("SELECT pg_advisory_xact_lock(hashtext(?))", "stawi_room:"+roomID).Error; err != nil {
			return err
		}
		return fn(tx)
	})
}

func (s *stawiChainStore) Pending(tx *gorm.DB, roomID string) ([]*models.StawiChainFact, error) {
	var facts []*models.StawiChainFact
	err := tx.Where("room_id = ? AND applied = ?", roomID, false).
		Order("block_number ASC, log_index ASC, created_at ASC").Find(&facts).Error
	return facts, err
}

func (s *stawiChainStore) MarkApplied(tx *gorm.DB, fact *models.StawiChainFact) error {
	now := time.Now()
	fact.Applied, fact.AppliedAt = true, &now
	return tx.Model(&models.StawiChainFact{}).Where("id = ?", fact.GetID()).
		Updates(map[string]any{"applied": true, "applied_at": now, "outcome_event_id": fact.OutcomeEventID}).Error
}

func (s *stawiChainStore) Member(
	tx *gorm.DB, room *models.Room, address string,
) (*models.StawiRoomMember, error) {
	address = strings.ToLower(address)
	var member models.StawiRoomMember
	err := tx.Where("room_id = ? AND address = ?", room.GetID(), address).First(&member).Error
	if err == nil {
		return &member, nil
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}
	fresh := &models.StawiRoomMember{RoomID: room.GetID(), Address: address, Roles: data.JSONMap{}}
	fresh.TenantID, fresh.PartitionID, fresh.AccessID = room.TenantID, room.PartitionID, room.AccessID
	return fresh, nil
}

func (s *stawiChainStore) SaveMember(tx *gorm.DB, member *models.StawiRoomMember) error {
	if member.GetID() == "" {
		member.GenID(tx.Statement.Context)
		return tx.Create(member).Error
	}
	return tx.Save(member).Error
}

func (s *stawiChainStore) Members(ctx context.Context, roomID string) ([]*models.StawiRoomMember, error) {
	var members []*models.StawiRoomMember
	err := s.pool.DB(ctx, false).Where("room_id = ?", roomID).Order("address ASC").Find(&members).Error
	return members, err
}
