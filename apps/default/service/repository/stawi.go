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
	"github.com/pitabwire/util"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/stawilabs/chat/apps/default/service/models"
)

// ErrStawiGenesisNotClaimable is returned when a room's genesis may not be
// recorded by this requester: the room is bound, or another member's genesis
// is pending and unexpired.
var ErrStawiGenesisNotClaimable = errors.New("the room's genesis is not open to this requester")

// ErrStawiCallConflict is returned when a call id is already recorded for
// another room or signer.
var ErrStawiCallConflict = errors.New("the call is already recorded for another room or signer")

// Columns of the Stawi tables.
const (
	colState      = "state"
	colModifiedAt = "modified_at"
)

// StawiRoomRepository stores the binding between a chat room and its custody.
type StawiRoomRepository interface {
	datastore.BaseRepository[*models.StawiRoom]
	// IsBound reports whether the chain has the room. A missing row is not bound.
	IsBound(ctx context.Context, roomID string) (bool, error)
	// CheckGenesisClaimable reports ErrStawiGenesisNotClaimable when the
	// requester may not record a genesis for the room now.
	CheckGenesisClaimable(ctx context.Context, roomID, requestedBy string, now time.Time) error
	// ClaimGenesis records a prepared genesis: inserted if the room has none,
	// replacing a pending one only if it is the requester's or has expired,
	// never over a bound room (ErrStawiGenesisNotClaimable).
	ClaimGenesis(ctx context.Context, room *models.Room, claim models.StawiGenesisClaim) error
	// GetByGovernance returns the room a GovernanceModule belongs to.
	GetByGovernance(ctx context.Context, governance string) (*models.StawiRoom, error)
	// ListBound pages through bound rooms by id.
	ListBound(ctx context.Context, afterID string, limit int) ([]*models.StawiRoom, error)
	// GetByRoomIDs returns the bindings of the given rooms, keyed by room id,
	// in one query. A room with no binding is absent from the map.
	GetByRoomIDs(ctx context.Context, roomIDs []string) (map[string]*models.StawiRoom, error)
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

func (r *stawiRoomRepository) CheckGenesisClaimable(
	ctx context.Context, roomID, requestedBy string, now time.Time,
) error {
	row, err := r.GetByID(ctx, roomID)
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return nil
		}
		return err
	}
	if !genesisClaimable(row, requestedBy, now) {
		return ErrStawiGenesisNotClaimable
	}
	return nil
}

func genesisClaimable(row *models.StawiRoom, requestedBy string, now time.Time) bool {
	if row.State == models.StawiRoomStateFailed {
		return true
	}
	if row.State != models.StawiRoomStatePending {
		return false
	}
	if row.RequestedBy == requestedBy {
		return true
	}
	return row.GenesisExpiresAt == nil || row.GenesisExpiresAt.Before(now)
}

func (r *stawiRoomRepository) ClaimGenesis(
	ctx context.Context, room *models.Room, claim models.StawiGenesisClaim,
) error {
	expires := claim.ExpiresAt.UTC()
	row := &models.StawiRoom{
		State:            models.StawiRoomStatePending,
		GenesisID:        claim.GenesisID,
		GenesisEventID:   claim.EventID,
		Founders:         strings.Join(claim.Founders, ","),
		RequestedBy:      claim.RequestedBy,
		GenesisExpiresAt: &expires,
	}
	row.ID = room.GetID()
	row.TenantID, row.PartitionID, row.AccessID = room.TenantID, room.PartitionID, room.AccessID

	// Insert if absent; otherwise replace only a pending genesis that is the
	// requester's own or has expired. A bound room is never touched.
	res := r.Pool().DB(ctx, false).Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "id"}},
		DoUpdates: clause.Assignments(map[string]any{
			colState:             models.StawiRoomStatePending,
			"genesis_id":         claim.GenesisID,
			"genesis_event_id":   claim.EventID,
			"founders":           row.Founders,
			"requested_by":       claim.RequestedBy,
			"genesis_expires_at": expires,
			colModifiedAt:        time.Now(),
		}),
		Where: clause.Where{Exprs: []clause.Expression{
			clause.Expr{
				SQL: "stawi_rooms.state = ? OR (stawi_rooms.state = ? AND (stawi_rooms.requested_by = ? " +
					"OR stawi_rooms.genesis_expires_at IS NULL OR stawi_rooms.genesis_expires_at < ?))",
				Vars: []any{
					models.StawiRoomStateFailed,
					models.StawiRoomStatePending, claim.RequestedBy, time.Now().UTC(),
				},
			},
		}},
	}).Create(row)
	if res.Error != nil {
		return res.Error
	}
	if res.RowsAffected == 0 {
		return ErrStawiGenesisNotClaimable
	}
	return nil
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

func (r *stawiRoomRepository) GetByRoomIDs(
	ctx context.Context,
	roomIDs []string,
) (map[string]*models.StawiRoom, error) {
	bindings := make(map[string]*models.StawiRoom, len(roomIDs))
	if len(roomIDs) == 0 {
		return bindings, nil
	}
	var rows []*models.StawiRoom
	if err := r.Pool().DB(ctx, false).Where("id IN ?", roomIDs).Find(&rows).Error; err != nil {
		return nil, err
	}
	for _, row := range rows {
		bindings[row.GetID()] = row
	}
	return bindings, nil
}

// StawiRoomCallRepository tracks the signed calls chat relayed.
type StawiRoomCallRepository interface {
	datastore.BaseRepository[*models.StawiRoomCall]
	// Record stores a relayed call once. A repeat by the same room and signer
	// keeps the first row; the same call id for another room or signer is
	// ErrStawiCallConflict.
	Record(ctx context.Context, call *models.StawiRoomCall) error
	// FindBySigner finds the call a chain fact names by signer and nonce.
	FindBySigner(ctx context.Context, roomID, signer string, nonce uint64) (*models.StawiRoomCall, error)
	// SetState moves a call to a final state; it reports false if it was
	// already final (so its outcome is posted once).
	SetState(ctx context.Context, callID, state string) (bool, error)
	// ListSubmittedBefore returns calls still awaiting an outcome, the least
	// recently checked first.
	ListSubmittedBefore(ctx context.Context, before time.Time, limit int) ([]*models.StawiRoomCall, error)
	// MarkChecked records that settlement was asked about the call.
	MarkChecked(ctx context.Context, callID string) error
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
	res := r.Pool().DB(ctx, false).Clauses(clause.OnConflict{DoNothing: true}).Create(call)
	if res.Error != nil || res.RowsAffected == 1 {
		return res.Error
	}
	existing, err := r.GetByID(ctx, call.GetID())
	if err != nil {
		return err
	}
	if existing.RoomID != call.RoomID || existing.SignerAddress != call.SignerAddress ||
		existing.Nonce != call.Nonce {
		return ErrStawiCallConflict
	}
	return nil
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
	res := r.Pool().DB(ctx, false).Table("stawi_room_calls").
		Where("id = ? AND state = ?", callID, models.StawiCallStateSubmitted).
		Updates(map[string]any{colState: state, colModifiedAt: time.Now()})
	return res.RowsAffected > 0, res.Error
}

func (r *stawiRoomCallRepository) ListSubmittedBefore(
	ctx context.Context, before time.Time, limit int,
) ([]*models.StawiRoomCall, error) {
	var rows []*models.StawiRoomCall
	err := r.Pool().DB(ctx, false).
		Where("state = ? AND created_at < ?", models.StawiCallStateSubmitted, before).
		Order("last_checked_at ASC NULLS FIRST, created_at ASC").Limit(limit).Find(&rows).Error
	return rows, err
}

func (r *stawiRoomCallRepository) MarkChecked(ctx context.Context, callID string) error {
	return r.Pool().DB(ctx, false).Table("stawi_room_calls").Where("id = ?", callID).
		Update("last_checked_at", time.Now()).Error
}

// StawiChainStore is the chain consumer's storage: the fact inbox and the
// membership the facts fold into. Everything a room's facts change is written
// inside WithRoomLock, so replicas apply one room's facts one at a time.
type StawiChainStore interface {
	// Record inserts a fact into the inbox once; it reports whether it was new.
	Record(ctx context.Context, fact *models.StawiChainFact) (bool, error)
	// AssignRoom places facts that arrived before their room was known.
	AssignRoom(ctx context.Context, custody, roomID string) error
	// AssignBoundEmitters places every unplaced fact whose emitter (custody
	// or GovernanceModule) a bound room now holds; it closes the race where
	// a fact is recorded while its room is being bound.
	AssignBoundEmitters(ctx context.Context) (int64, error)
	// RoomsWithPending returns rooms with facts waiting to be applied, the
	// least recently attempted first, skipping quarantined facts.
	RoomsWithPending(ctx context.Context, limit int) ([]string, error)
	// PendingNoLock reads the room's waiting facts without the lock, to plan
	// work (profile lookups) that must not run under it.
	PendingNoLock(ctx context.Context, roomID string) ([]*models.StawiChainFact, error)
	// RecordFailure counts a failed application, schedules the next attempt
	// after an exponential backoff from base, and quarantines the fact at the
	// limit; it reports whether the fact is now quarantined.
	// A limit of zero never quarantines (revocations are retried until they
	// land); maxBackoff caps the wait.
	RecordFailure(
		tx *gorm.DB, fact *models.StawiChainFact, cause error, limit int, base, maxBackoff time.Duration,
	) (bool, error)
	// TouchWaiting stamps facts that waited behind another, so the sweep
	// serves other rooms first.
	TouchWaiting(tx *gorm.DB, ids []string) error
	// Redrive returns a room's quarantined and backing-off facts to the
	// queue at once (operator).
	Redrive(ctx context.Context, roomID string) (int64, error)
	// PruneApplied drops the payload of applied facts older than before; the
	// fact's key stays, so a replay is still recognised. Membership rows, not
	// facts, are what reconciliation reads.
	PruneApplied(ctx context.Context, before time.Time) (int64, error)
	// TryLease runs fn only if no other replica holds the named lease.
	TryLease(ctx context.Context, name string, fn func(ctx context.Context)) (bool, error)
	// ProfileMembers returns every member row of a room for one profile.
	ProfileMembers(tx *gorm.DB, roomID, profileID string) ([]*models.StawiRoomMember, error)
	// EnqueueKeto records, in the room's transaction, the relation a
	// subscription must hold ("" for none), replacing any pending op for it.
	EnqueueKeto(tx *gorm.DB, room *models.Room, subscriptionID, role string) error
	// PendingKeto returns pending Keto ops (of one room, or all if empty).
	PendingKeto(ctx context.Context, roomID string, limit int) ([]*models.StawiKetoOp, error)
	// CompleteKeto deletes an op if it has not been rewritten since read.
	CompleteKeto(ctx context.Context, op *models.StawiKetoOp) error
	// FailKeto counts a failed Keto write.
	FailKeto(ctx context.Context, op *models.StawiKetoOp) error
	// WithRoomLock runs fn in a transaction holding the room's lock.
	WithRoomLock(ctx context.Context, roomID string, fn func(tx *gorm.DB) error) error
	// Pending returns the room's unapplied facts in chain order, quarantined
	// ones included (they hold back the facts that follow them).
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
	return s.pool.DB(ctx, false).Table("stawi_chain_facts").
		Where("room_id = '' AND custody_address = ?", strings.ToLower(custody)).
		Update("room_id", roomID).Error
}

func (s *stawiChainStore) AssignBoundEmitters(ctx context.Context) (int64, error) {
	res := s.pool.DB(ctx, false).Exec(`UPDATE stawi_chain_facts AS f SET room_id = r.id
		FROM stawi_rooms AS r
		WHERE f.room_id = '' AND f.custody_address <> '' AND r.state = ?
		  AND (f.custody_address = r.custody_address OR f.custody_address = r.governance_address)`,
		models.StawiRoomStateBound)
	return res.RowsAffected, res.Error
}

func (s *stawiChainStore) RoomsWithPending(ctx context.Context, limit int) ([]string, error) {
	var rooms []string
	err := s.pool.DB(ctx, false).Raw(`SELECT room_id FROM stawi_chain_facts
		WHERE applied = false AND quarantined = false AND room_id <> ''
		  AND (next_attempt_at IS NULL OR next_attempt_at <= now())
		GROUP BY room_id
		ORDER BY MIN(COALESCE(last_attempt_at, 'epoch'::timestamptz)) ASC, room_id ASC
		LIMIT ?`, limit).Scan(&rooms).Error
	return rooms, err
}

func (s *stawiChainStore) PendingNoLock(ctx context.Context, roomID string) ([]*models.StawiChainFact, error) {
	return s.Pending(s.pool.DB(ctx, false), roomID)
}

func (s *stawiChainStore) RecordFailure(
	tx *gorm.DB, fact *models.StawiChainFact, cause error, limit int, base, maxBackoff time.Duration,
) (bool, error) {
	now := time.Now()
	fact.Attempts++
	const maxShift = 20
	var backoff time.Duration
	if base > 0 {
		backoff = base << min(fact.Attempts-1, maxShift)
		if backoff <= 0 || backoff > maxBackoff {
			backoff = maxBackoff
		}
	}
	next := now.Add(backoff)
	fact.NextAttemptAt = &next
	quarantine := limit > 0 && fact.Attempts >= limit
	msg := cause.Error()
	const maxErr = 2000
	if len(msg) > maxErr {
		msg = msg[:maxErr]
	}
	err := tx.Table("stawi_chain_facts").Where("id = ?", fact.GetID()).Updates(map[string]any{
		"attempts": fact.Attempts, "last_error": msg, "last_attempt_at": now, "quarantined": quarantine,
		"next_attempt_at": next,
	}).Error
	return quarantine, err
}

func (s *stawiChainStore) TouchWaiting(tx *gorm.DB, ids []string) error {
	if len(ids) == 0 {
		return nil
	}
	return tx.Table("stawi_chain_facts").Where("id IN ?", ids).Update("last_attempt_at", time.Now()).Error
}

func (s *stawiChainStore) Redrive(ctx context.Context, roomID string) (int64, error) {
	res := s.pool.DB(ctx, false).Table("stawi_chain_facts").
		Where("room_id = ? AND applied = ? AND (quarantined = ? OR next_attempt_at IS NOT NULL)", roomID, false, true).
		Updates(map[string]any{"quarantined": false, "attempts": 0, "next_attempt_at": nil})
	return res.RowsAffected, res.Error
}

func (s *stawiChainStore) PruneApplied(ctx context.Context, before time.Time) (int64, error) {
	res := s.pool.DB(ctx, false).Exec(`UPDATE stawi_chain_facts SET payload = ''::bytea, last_error = ''
		WHERE applied = true AND applied_at < ? AND octet_length(payload) > 0`, before)
	return res.RowsAffected, res.Error
}

func (s *stawiChainStore) TryLease(ctx context.Context, name string, fn func(ctx context.Context)) (bool, error) {
	held := false
	err := s.pool.DB(ctx, false).Transaction(func(tx *gorm.DB) error {
		if lockErr := tx.Raw("SELECT pg_try_advisory_xact_lock(hashtext(?))", "stawi_lease:"+name).
			Scan(&held).Error; lockErr != nil {
			return lockErr
		}
		if held {
			fn(ctx)
		}
		return nil
	})
	return held, err
}

func (s *stawiChainStore) ProfileMembers(tx *gorm.DB, roomID, profileID string) ([]*models.StawiRoomMember, error) {
	var members []*models.StawiRoomMember
	err := tx.Where("room_id = ? AND profile_id = ?", roomID, profileID).Order("address ASC").Find(&members).Error
	return members, err
}

func (s *stawiChainStore) EnqueueKeto(tx *gorm.DB, room *models.Room, subscriptionID, role string) error {
	op := &models.StawiKetoOp{RoomID: room.GetID(), SubscriptionID: subscriptionID, Role: role,
		Token: util.IDString()}
	op.TenantID, op.PartitionID, op.AccessID = room.TenantID, room.PartitionID, room.AccessID
	op.GenID(tx.Statement.Context)
	return tx.Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "subscription_id"}},
		DoUpdates: clause.AssignmentColumns([]string{"role", "token", colModifiedAt}),
	}).Create(op).Error
}

func (s *stawiChainStore) PendingKeto(ctx context.Context, roomID string, limit int) ([]*models.StawiKetoOp, error) {
	var ops []*models.StawiKetoOp
	// Removals first: access the chain has taken away is withdrawn before
	// anything is granted.
	query := s.pool.DB(ctx, false).Order("(role <> '') ASC, attempts ASC, modified_at ASC").Limit(limit)
	if roomID != "" {
		query = query.Where("room_id = ?", roomID)
	}
	err := query.Find(&ops).Error
	return ops, err
}

func (s *stawiChainStore) CompleteKeto(ctx context.Context, op *models.StawiKetoOp) error {
	return s.pool.DB(ctx, false).Exec("DELETE FROM stawi_keto_ops WHERE id = ? AND token = ?",
		op.GetID(), op.Token).Error
}

func (s *stawiChainStore) FailKeto(ctx context.Context, op *models.StawiKetoOp) error {
	return s.pool.DB(ctx, false).Exec(
		"UPDATE stawi_keto_ops SET attempts = attempts + 1, modified_at = now() WHERE id = ?", op.GetID()).Error
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
	return tx.Table("stawi_chain_facts").Where("id = ?", fact.GetID()).
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
