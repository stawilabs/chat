package business

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	financev1 "buf.build/gen/go/stawi/finance/protocolbuffers/go/finance/v1"
	"buf.build/go/protovalidate"
	"github.com/pitabwire/frame/v2/data"
	"github.com/pitabwire/frame/v2/datastore/pool"
	"github.com/pitabwire/util"
	"google.golang.org/protobuf/encoding/protowire"
	"google.golang.org/protobuf/proto"
	"gorm.io/gorm"

	"github.com/stawilabs/chat/apps/default/service/authz"
	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/service/stawi"
	"github.com/stawilabs/chat/pkg/chatutil"
	chattel "github.com/stawilabs/chat/pkg/telemetry"
)

// Settlement fact names chat consumes (finance.v1 event protos).
const (
	FactRoomActivated          = "room.activated"
	FactRoomMembershipObserved = "room.membership_observed"
	FactGovernanceCallObserved = "governance.call_observed"
	FactGovernanceCallFailed   = "governance.call_failed"
	FactRoomCallFinal          = "room.call_final"
	FactRoomCallFailed         = "room.call_failed"
	FactRoomGenesisFailed      = "room.genesis_failed"
)

const (
	defaultMaxFactAttempts    = 5
	defaultReconcilePerPass   = 50
	defaultFactRetention      = 30 * 24 * time.Hour
	ketoDrainBatch            = 500
	stawiFactsDeadLetterQueue = "stawi.settlement.facts"
	defaultStaleCallAfter     = 10 * time.Minute
	sweepBatch                = 100
	colStawiState             = "state"
	logKeyFact                = "fact"
	colEventID                = "event_id"
	colModifiedAt             = "modified_at"
)

// ErrStawiUnrequestedBinding is returned when an activation names a room that
// did not ask for it: chat has no such room, or no genesis was prepared from it.
var ErrStawiUnrequestedBinding = errors.New("stawi: the room did not request this binding")

// ErrStawiRebind is returned when an activation names a different custody for
// a room that is already bound, or a custody another room holds. The chain cannot move a room's identity; the
// fact is refused and left for an operator.
var ErrStawiRebind = errors.New("stawi: the room is already bound to another custody")

// StawiDrift is what the reconciler found and repaired in one room
// (room.subscription_drift).
type StawiDrift struct {
	RoomID string
	// Restored members the chain has but chat had lost or deactivated.
	Restored int
	// Removed subscriptions chat had that the chain's membership does not.
	Removed int
	// RolesFixed subscriptions whose state or role differed from the chain.
	RolesFixed int
	// PermissionsRepaired subscriptions whose Keto tuples were missing or wrong.
	PermissionsRepaired int
	At                  time.Time
}

// Total is the number of repairs in the room.
func (d StawiDrift) Total() int { return d.Restored + d.Removed + d.RolesFixed + d.PermissionsRepaired }

// DriftPublisher emits room.subscription_drift.
type DriftPublisher interface {
	PublishDrift(ctx context.Context, drift StawiDrift) error
}

// ReconcileReport summarises one reconciler pass.
type ReconcileReport struct {
	Rooms         int
	Repaired      int
	CallsResolved int
}

// StawiChainDeps are the chain consumer's collaborators.
type StawiChainDeps struct {
	Pool     pool.Pool
	RoomRepo repository.RoomRepository
	SubRepo  repository.RoomSubscriptionRepository
	Bindings repository.StawiRoomRepository
	Calls    repository.StawiRoomCallRepository
	Store    repository.StawiChainStore
	Accounts stawi.AccountResolver
	// Rooms is optional; with it the reconciler settles calls whose outcome
	// never arrived as a fact.
	Rooms stawi.Rooms
	Authz authz.Middleware
	Drift DriftPublisher
	// StaleCallAfter is how long a relayed call may wait for a fact before
	// the reconciler asks settlement about it (default 10 minutes).
	StaleCallAfter time.Duration
	// MaxFactAttempts is how often a fact may fail before it is quarantined
	// (default 5).
	MaxFactAttempts int
	// ReconcileRoomsPerPass bounds one reconciler pass (default 50); passes
	// rotate through the bound rooms.
	ReconcileRoomsPerPass int
	// FactRetention is how long applied facts are kept (default 30 days);
	// reconciliation reads membership rows, not facts.
	FactRetention time.Duration
	// DeadLetters records facts refused for an operator (optional).
	DeadLetters repository.DeadLetterRepository
}

// StawiChain applies settlement's chain facts to chat. It is the only writer
// of a Stawi room's subscriptions, roles and Keto tuples, and it writes them
// only from what the chain reports: idempotent by the log's identity
// (chain_id, tx_hash, log_index), applied per room in (block, log_index)
// order under the room's lock, and monotonic, so an older fact never
// overwrites a newer one whatever order they arrive in.
//
// It runs as chat's own service identity on facts read from settlement's
// stream; nothing a chat client sends reaches it.
type StawiChain struct {
	deps      StawiChainDeps
	converter *models.PayloadConverter

	mu              sync.Mutex
	reconcileCursor string
}

// NewStawiChain creates the chain consumer.
func NewStawiChain(deps StawiChainDeps) *StawiChain {
	if deps.StaleCallAfter <= 0 {
		deps.StaleCallAfter = defaultStaleCallAfter
	}
	if deps.MaxFactAttempts <= 0 {
		deps.MaxFactAttempts = defaultMaxFactAttempts
	}
	if deps.ReconcileRoomsPerPass <= 0 {
		deps.ReconcileRoomsPerPass = defaultReconcilePerPass
	}
	if deps.FactRetention == 0 {
		deps.FactRetention = defaultFactRetention
	}
	return &StawiChain{deps: deps, converter: models.NewPayloadConverter()}
}

// HexAddress renders a chain address the way chat stores it: lowercase 0x hex.
func HexAddress(b []byte) string { return stawi.HexAddress(b) }

// ReceiveDelivery takes one delivery from settlement's stream: the fact is
// applied only if the event id the relay put in the header is the fact's
// own; a delivery that disagrees is dropped.
func (c *StawiChain) ReceiveDelivery(ctx context.Context, eventName, eventID string, payload []byte) error {
	meta, err := factMeta(payload)
	if err != nil {
		util.Log(ctx).WithError(err).WithField(logKeyFact, eventName).Error("stawi chain: dropping an undecodable fact")
		return nil
	}
	if got := meta.GetEventId(); got == "" || got != eventID {
		util.Log(ctx).
			WithFields(map[string]any{logKeyFact: eventName, "header_event_id": eventID, "fact_event_id": got}).
			Error("stawi chain: dropping a delivery whose event id does not match its fact")
		return nil
	}
	return c.Receive(ctx, eventName, payload)
}

// factMeta reads the EventMeta every finance.v1 event carries as field 1.
func factMeta(payload []byte) (*financev1.EventMeta, error) {
	for len(payload) > 0 {
		num, typ, n := protowire.ConsumeTag(payload)
		if n < 0 {
			return nil, protowire.ParseError(n)
		}
		payload = payload[n:]
		if num == 1 && typ == protowire.BytesType {
			raw, m := protowire.ConsumeBytes(payload)
			if m < 0 {
				return nil, protowire.ParseError(m)
			}
			var meta financev1.EventMeta
			if err := proto.Unmarshal(raw, &meta); err != nil {
				return nil, err
			}
			return &meta, nil
		}
		m := protowire.ConsumeFieldValue(num, typ, payload)
		if m < 0 {
			return nil, protowire.ParseError(m)
		}
		payload = payload[m:]
	}
	return nil, errors.New("fact has no meta")
}

// Receive takes one fact from settlement's stream. It returns an error only
// when the fact must be redelivered (a dependency is down); a fact chat does
// not read, or one that is malformed, is acknowledged and dropped.
func (c *StawiChain) Receive(ctx context.Context, eventName string, payload []byte) error {
	switch eventName {
	case FactRoomActivated:
		var msg financev1.RoomActivated
		if !c.decode(ctx, eventName, payload, &msg) {
			return nil
		}
		return c.receiveActivation(ctx, &msg, payload)
	case FactRoomMembershipObserved:
		var msg financev1.RoomMembershipObserved
		if !c.decode(ctx, eventName, payload, &msg) {
			return nil
		}
		return c.receivePositioned(ctx, msg.GetRoomId(), &models.StawiChainFact{
			FactKey:        logKey(msg.GetChainId(), msg.GetTxHash(), msg.GetLogIndex()),
			EventName:      eventName,
			CustodyAddress: HexAddress(msg.GetCustodyAddress()),
			ChainID:        msg.GetChainId(),
			BlockNumber:    msg.GetBlockNumber(),
			LogIndex:       msg.GetLogIndex(),
			Payload:        payload,
		})
	case FactGovernanceCallObserved:
		var msg financev1.GovernanceCallObserved
		if !c.decode(ctx, eventName, payload, &msg) {
			return nil
		}
		return c.receivePositioned(ctx, msg.GetRoomId(), &models.StawiChainFact{
			FactKey:        logKey(msg.GetChainId(), msg.GetTxHash(), msg.GetLogIndex()),
			EventName:      eventName,
			CustodyAddress: HexAddress(msg.GetEmitter()),
			ChainID:        msg.GetChainId(),
			BlockNumber:    msg.GetBlockNumber(),
			LogIndex:       msg.GetLogIndex(),
			Payload:        payload,
		})
	case FactGovernanceCallFailed:
		var msg financev1.GovernanceCallFailed
		if !c.decode(ctx, eventName, payload, &msg) {
			return nil
		}
		return c.receivePositioned(ctx, msg.GetCall().GetRoomId(), &models.StawiChainFact{
			FactKey:        "failed:" + msg.GetMeta().GetEventId(),
			EventName:      eventName,
			CustodyAddress: HexAddress(msg.GetCall().GetVerifier()),
			ChainID:        msg.GetCall().GetChainId(),
			Payload:        payload,
		})
	case FactRoomCallFinal:
		var msg financev1.RoomCallFinal
		if !c.decode(ctx, eventName, payload, &msg) {
			return nil
		}
		return c.receivePositioned(ctx, msg.GetRoomId(), &models.StawiChainFact{
			FactKey: "call_final:" + msg.GetCallId(), EventName: eventName,
			CustodyAddress: HexAddress(msg.GetCustodyAddress()), ChainID: msg.GetChainId(),
			BlockNumber: msg.GetBlockNumber(), Payload: payload,
		})
	case FactRoomCallFailed:
		var msg financev1.RoomCallFailed
		if !c.decode(ctx, eventName, payload, &msg) {
			return nil
		}
		return c.receivePositioned(ctx, msg.GetRoomId(), &models.StawiChainFact{
			FactKey: "call_failed:" + msg.GetCallId(), EventName: eventName,
			CustodyAddress: HexAddress(msg.GetCustodyAddress()), ChainID: msg.GetChainId(), Payload: payload,
		})
	case FactRoomGenesisFailed:
		var msg financev1.RoomGenesisFailed
		if !c.decode(ctx, eventName, payload, &msg) {
			return nil
		}
		return c.receiveGenesisFailed(ctx, &msg)
	default:
		return nil
	}
}

// receiveGenesisFailed reports a genesis that never landed against its card
// and reopens the room for conversion — only when it names the genesis chat
// recorded for that room and the room is still pending.
func (c *StawiChain) receiveGenesisFailed(ctx context.Context, msg *financev1.RoomGenesisFailed) error {
	room, err := c.deps.RoomRepo.GetByID(ctx, msg.GetRoomId())
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return nil
		}
		return err
	}
	return c.deps.Store.WithRoomLock(ctx, room.GetID(), func(tx *gorm.DB) error {
		var row models.StawiRoom
		if findErr := tx.Where("id = ?", room.GetID()).First(&row).Error; findErr != nil {
			if errors.Is(findErr, gorm.ErrRecordNotFound) {
				return nil
			}
			return findErr
		}
		res := tx.Table("stawi_rooms").Where("id = ? AND state = ? AND genesis_id = ?", room.GetID(),
			models.StawiRoomStatePending, msg.GetGenesisId()).
			Updates(map[string]any{colStawiState: models.StawiRoomStateFailed, colModifiedAt: time.Now()})
		if res.Error != nil || res.RowsAffected == 0 {
			return res.Error // another genesis, or already reported
		}
		return c.postEvent(ctx, tx, room, util.IDString(), row.GenesisEventID, outcomePayload(
			&chatv1.StawiCallOutcomeContent{
				GenesisId: msg.GetGenesisId(), State: chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_FAILED,
				Reason: truncateReason(msg.GetReason()), SourceEventId: row.GenesisEventID,
				Kind: "ROOM_GENESIS", ChainId: msg.GetChainId(),
			}))
	})
}

func (c *StawiChain) decode(ctx context.Context, name string, payload []byte, msg proto.Message) bool {
	if err := proto.Unmarshal(payload, msg); err != nil {
		util.Log(ctx).WithError(err).WithField(logKeyFact, name).Error("stawi chain: dropping an undecodable fact")
		return false
	}
	if err := validateFact(msg); err != nil {
		util.Log(ctx).WithError(err).WithField(logKeyFact, name).Error("stawi chain: dropping an invalid fact")
		return false
	}
	return true
}

// validateFact applies the fact's proto rules to everything chat reads. The
// event envelope (meta) is checked only for the event id: settlement names
// the aggregate by room id, which is empty exactly when it does not know the
// room yet, and such a fact must wait for its room rather than be dropped.
func validateFact(msg proto.Message) error {
	type withMeta interface {
		GetMeta() *financev1.EventMeta
		SetMeta(*financev1.EventMeta)
	}
	clone := proto.Clone(msg)
	if m, ok := clone.(withMeta); ok {
		if m.GetMeta() == nil {
			return errors.New("fact has no meta")
		}
		m.SetMeta(&financev1.EventMeta{EventId: m.GetMeta().GetEventId(), AggregateType: "fact", AggregateId: "fact"})
	}
	return protovalidate.Validate(clone)
}

func logKey(chainID uint64, txHash []byte, logIndex uint64) string {
	return fmt.Sprintf("%d:%s:%d", chainID, HexAddress(txHash), logIndex)
}

// receivePositioned records a fact in the inbox and applies its room's
// pending facts. The room is the one bound to the contract that emitted the
// log (CustodyAddress holds the custody for membership facts and the
// GovernanceModule for governance facts) — the decoded chain log, never the
// room_id settlement adds for convenience. A fact whose claimed room
// disagrees with its emitter's is dropped; one whose emitter is not bound yet
// waits until activation names it.
func (c *StawiChain) receivePositioned(ctx context.Context, claimedRoomID string, fact *models.StawiChainFact) error {
	if fact.CustodyAddress == "" {
		util.Log(ctx).WithField(logKeyFact, fact.FactKey).Error("stawi chain: dropping a fact without an emitter")
		return nil
	}
	if binding, err := c.bindingByEmitter(ctx, fact.CustodyAddress); err == nil {
		fact.RoomID = binding.GetID()
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		return err
	}
	if claimedRoomID != "" && fact.RoomID != "" && claimedRoomID != fact.RoomID {
		util.Log(ctx).WithFields(map[string]any{
			logKeyFact: fact.FactKey, "claimed_room": claimedRoomID, chatutil.KeyRoomID: fact.RoomID,
		}).Error("stawi chain: dropping a fact whose room does not match its emitter")
		return nil
	}
	if _, err := c.deps.Store.Record(ctx, fact); err != nil {
		return fmt.Errorf("failed to record the fact: %w", err)
	}
	if fact.RoomID == "" {
		// The emitter's room may have been bound while this fact was being
		// recorded (by another replica), after the binding placed waiting
		// facts: look again, so the fact is not left unplaced.
		binding, err := c.bindingByEmitter(ctx, fact.CustodyAddress)
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil // waits for activation (or the sweep) to place it
		}
		if err != nil {
			return err
		}
		if err = c.deps.Store.AssignRoom(ctx, fact.CustodyAddress, binding.GetID()); err != nil {
			return err
		}
		fact.RoomID = binding.GetID()
	}
	return c.ApplyRoom(ctx, fact.RoomID)
}

// bindingByEmitter finds the bound room whose custody or GovernanceModule is
// the address.
func (c *StawiChain) bindingByEmitter(ctx context.Context, address string) (*models.StawiRoom, error) {
	address = strings.ToLower(address)
	var row models.StawiRoom
	err := c.deps.Pool.DB(ctx, false).
		Where("state = ? AND (custody_address = ? OR governance_address = ?)",
			models.StawiRoomStateBound, address, address).
		First(&row).Error
	if err != nil {
		return nil, err
	}
	return &row, nil
}

// receiveActivation binds the room to its custody: the chat room id is the
// on-chain room binding. It is applied as it arrives; the facts that waited
// for the room's custody are then placed and applied.
func (c *StawiChain) receiveActivation(ctx context.Context, msg *financev1.RoomActivated, payload []byte) error {
	err := c.activate(ctx, msg)
	if errors.Is(err, ErrStawiUnrequestedBinding) || errors.Is(err, ErrStawiRebind) {
		// A refused binding is final: acknowledge it, keep it for an operator
		// and alert, rather than redelivering it forever.
		c.refuseActivation(ctx, msg, payload, err)
		return nil
	}
	return err
}

func (c *StawiChain) refuseActivation(ctx context.Context, msg *financev1.RoomActivated, payload []byte, cause error) {
	chattel.StawiActivationsRefusedCounter.Add(ctx, 1)
	util.Log(ctx).WithError(cause).WithFields(map[string]any{
		chatutil.KeyRoomID: msg.GetRoomId(), "genesis_id": msg.GetGenesisId(),
		"custody": HexAddress(msg.GetCustodyAddress()),
	}).Error("stawi chain: room.activated refused; kept for an operator")
	if c.deps.DeadLetters == nil {
		return
	}
	if err := c.deps.DeadLetters.Record(ctx, stawiFactsDeadLetterQueue, cause.Error(), payload,
		map[string]string{"event_name": FactRoomActivated, colEventID: msg.GetMeta().GetEventId()}); err != nil {
		util.Log(ctx).WithError(err).Error("stawi chain: could not record the refused activation")
	}
}

// activate binds the room an activation names, then places and applies the
// facts that waited for it.
func (c *StawiChain) activate(ctx context.Context, msg *financev1.RoomActivated) error {
	roomID := msg.GetRoomId()
	room, err := c.deps.RoomRepo.GetByID(ctx, roomID)
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return fmt.Errorf("%w: chat has no room %s", ErrStawiUnrequestedBinding, roomID)
		}
		return err
	}
	custody := HexAddress(msg.GetCustodyAddress())
	governance := HexAddress(msg.GetGovernanceAddress())

	err = c.deps.Store.WithRoomLock(ctx, roomID, func(tx *gorm.DB) error {
		return c.bind(ctx, tx, room, msg, custody, governance)
	})
	if err != nil {
		return err
	}

	for _, emitter := range []string{custody, governance} {
		if err = c.deps.Store.AssignRoom(ctx, emitter, roomID); err != nil {
			return err
		}
	}
	return c.ApplyRoom(ctx, roomID)
}

// bind records the activation under the room's lock: only a room that asked
// for it (a genesis prepared from it), never a rebinding, and only to a
// custody no other room holds.
func (c *StawiChain) bind(
	ctx context.Context, tx *gorm.DB, room *models.Room, msg *financev1.RoomActivated, custody, governance string,
) error {
	roomID := room.GetID()
	var row models.StawiRoom
	findErr := tx.Where("id = ?", roomID).First(&row).Error
	found := findErr == nil
	if findErr != nil && !errors.Is(findErr, gorm.ErrRecordNotFound) {
		return findErr
	}
	if found && row.IsBound() {
		if row.CustodyAddress != custody {
			return ErrStawiRebind
		}
		return nil // a duplicate activation
	}
	// Only a room whose owner or admin had chat prepare its genesis may
	// be bound, and only to a custody no other room holds.
	if !found || row.GenesisID == "" || row.State != models.StawiRoomStatePending {
		return fmt.Errorf("%w: no genesis is pending for room %s", ErrStawiUnrequestedBinding, roomID)
	}
	// Settlement names the genesis and the chat room it was prepared for;
	// both must be the ones chat recorded.
	if msg.GetGenesisId() != row.GenesisID || msg.GetChatRoomId() != roomID {
		return fmt.Errorf("%w: the activation names genesis %q for room %q", ErrStawiUnrequestedBinding,
			msg.GetGenesisId(), msg.GetChatRoomId())
	}
	var holders int64
	if countErr := tx.Table("stawi_rooms").Where("id <> ? AND (custody_address IN ? OR governance_address IN ?)",
		roomID, []string{custody, governance}, []string{custody, governance}).
		Count(&holders).Error; countErr != nil {
		return countErr
	}
	if holders > 0 {
		return ErrStawiRebind
	}

	now := time.Now()
	row.State = models.StawiRoomStateBound
	row.ChainID = msg.GetChainId()
	row.CustodyAddress = custody
	row.GovernanceAddress = governance
	row.PolicyEpoch = msg.GetPolicyEpoch()
	row.BoundAt = &now
	if saveErr := tx.Table("stawi_rooms").Where("id = ? AND state <> ?", roomID,
		models.StawiRoomStateBound).Updates(map[string]any{
		colStawiState: row.State, "chain_id": row.ChainID, "custody_address": row.CustodyAddress,
		"governance_address": row.GovernanceAddress, "policy_epoch": row.PolicyEpoch,
		"bound_at": now, colModifiedAt: now,
	}).Error; saveErr != nil {
		return saveErr
	}

	return c.postEvent(ctx, tx, room, util.IDString(), row.GenesisEventID, outcomePayload(
		&chatv1.StawiCallOutcomeContent{
			GenesisId:     row.GenesisID,
			State:         chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_OBSERVED,
			SourceEventId: row.GenesisEventID,
			Kind:          "ROOM_ACTIVATED",
			ChainId:       msg.GetChainId(),
		}))
}
