package business

import (
	"context"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"time"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	financev1 "buf.build/gen/go/stawi/finance/protocolbuffers/go/finance/v1"
	"buf.build/go/protovalidate"
	"github.com/pitabwire/frame/v2/data"
	"github.com/pitabwire/frame/v2/datastore/pool"
	"github.com/pitabwire/util"
	"google.golang.org/protobuf/proto"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/stawilabs/chat/apps/default/service/authz"
	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/service/stawi"
	"github.com/stawilabs/chat/pkg/chatutil"
)

// Settlement fact names chat consumes (finance.v1 event protos).
const (
	FactRoomActivated          = "room.activated"
	FactRoomMembershipObserved = "room.membership_observed"
	FactGovernanceCallObserved = "governance.call_observed"
	FactGovernanceCallFailed   = "governance.call_failed"
)

const (
	defaultStaleCallAfter = 10 * time.Minute
	sweepBatch            = 100
	colStawiState         = "state"
	logKeyFact            = "fact"
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
}

// NewStawiChain creates the chain consumer.
func NewStawiChain(deps StawiChainDeps) *StawiChain {
	if deps.StaleCallAfter <= 0 {
		deps.StaleCallAfter = defaultStaleCallAfter
	}
	return &StawiChain{deps: deps, converter: models.NewPayloadConverter()}
}

// HexAddress renders a chain address the way chat stores it: lowercase 0x hex.
func HexAddress(b []byte) string {
	if len(b) == 0 {
		return ""
	}
	return "0x" + hex.EncodeToString(b)
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
		return c.receiveActivation(ctx, &msg)
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
	default:
		return nil
	}
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
		return nil
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
func (c *StawiChain) receiveActivation(ctx context.Context, msg *financev1.RoomActivated) error {
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
	if !found || row.GenesisID == "" {
		return fmt.Errorf("%w: no genesis was prepared from room %s", ErrStawiUnrequestedBinding, roomID)
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
		"bound_at": now, "modified_at": now,
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

// ApplyRoom applies the room's pending facts in chain order.
func (c *StawiChain) ApplyRoom(ctx context.Context, roomID string) error {
	room, err := c.deps.RoomRepo.GetByID(ctx, roomID)
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return nil // facts wait for the room
		}
		return err
	}
	return c.deps.Store.WithRoomLock(ctx, roomID, func(tx *gorm.DB) error {
		facts, pendingErr := c.deps.Store.Pending(tx, roomID)
		if pendingErr != nil {
			return pendingErr
		}
		for _, fact := range facts {
			if applyErr := c.applyFact(ctx, tx, room, fact); applyErr != nil {
				return fmt.Errorf("failed to apply %s %s: %w", fact.EventName, fact.FactKey, applyErr)
			}
			if markErr := c.deps.Store.MarkApplied(tx, fact); markErr != nil {
				return markErr
			}
		}
		return nil
	})
}

func (c *StawiChain) applyFact(ctx context.Context, tx *gorm.DB, room *models.Room, fact *models.StawiChainFact) error {
	switch fact.EventName {
	case FactRoomMembershipObserved:
		var msg financev1.RoomMembershipObserved
		if err := proto.Unmarshal(fact.Payload, &msg); err != nil {
			return err
		}
		return c.applyMembership(ctx, tx, room, fact, &msg)
	case FactGovernanceCallObserved:
		var msg financev1.GovernanceCallObserved
		if err := proto.Unmarshal(fact.Payload, &msg); err != nil {
			return err
		}
		return c.applyCallObserved(ctx, tx, room, fact, &msg)
	case FactGovernanceCallFailed:
		var msg financev1.GovernanceCallFailed
		if err := proto.Unmarshal(fact.Payload, &msg); err != nil {
			return err
		}
		return c.applyCallFailed(ctx, tx, room, fact, &msg)
	default:
		return nil
	}
}

func (c *StawiChain) applyMembership(
	ctx context.Context, tx *gorm.DB, room *models.Room,
	fact *models.StawiChainFact, msg *financev1.RoomMembershipObserved,
) error {
	pos := models.ChainPosition{Block: fact.BlockNumber, LogIndex: fact.LogIndex}
	var address []byte
	switch msg.GetEvent() {
	case financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_MEMBER_INVITED,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_MEMBER_INVITE_REVOKED:
		address = msg.GetInvitee()
	case financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_MEMBER_STATE_CHANGED,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_ROLE_CHANGED:
		address = msg.GetMember()
	case financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_UNSPECIFIED,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_ROOM_BINDING_SET,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_JOIN_POLICY_SET,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_DELEGATE_CAPABILITY_SET,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_DELEGATE_CAPABILITY_REVOKED:
		return nil // bindings, join policy and delegates do not change subscriptions
	default:
		return nil
	}
	if len(address) == 0 {
		return nil
	}

	member, err := c.deps.Store.Member(tx, room, HexAddress(address))
	if err != nil {
		return err
	}
	if !foldMembership(member, msg, pos) {
		return nil // an older fact than the member's state already reflects
	}
	return c.syncMember(ctx, tx, room, member, fact)
}

// foldMembership applies one membership fact to the member's record if it is
// newer than what the record already reflects. It reports whether it changed.
func foldMembership(member *models.StawiRoomMember, msg *financev1.RoomMembershipObserved,
	pos models.ChainPosition,
) bool {
	switch msg.GetEvent() {
	case financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_MEMBER_INVITED:
		if !pos.After(member.StatePosition()) ||
			(member.State != models.StawiMemberStateNone && member.State != models.StawiMemberStateExited) {
			return false
		}
		member.State = models.StawiMemberStateInvited
	case financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_MEMBER_INVITE_REVOKED:
		if !pos.After(member.StatePosition()) || member.State != models.StawiMemberStateInvited {
			return false
		}
		member.State = models.StawiMemberStateNone
	case financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_MEMBER_STATE_CHANGED:
		if !pos.After(member.StatePosition()) {
			return false
		}
		member.State = models.StawiMemberState(msg.GetToState())
	case financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_ROLE_CHANGED:
		roleID := HexAddress(msg.GetRoleId())
		if entry, ok := member.Role(roleID); ok && !pos.After(entry.Position) {
			return false
		}
		member.SetRole(roleID, models.RoleEntry{Assigned: msg.GetRoleAssigned(), Position: pos})
		return true
	case financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_UNSPECIFIED,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_ROOM_BINDING_SET,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_JOIN_POLICY_SET,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_DELEGATE_CAPABILITY_SET,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_DELEGATE_CAPABILITY_REVOKED:
		return false
	default:
		return false
	}
	member.StateBlock, member.StateLogIndex = pos.Block, pos.LogIndex
	return true
}

// syncMember brings the member's subscription in line with the member record
// and saves the record, posting a room change when the subscription moved.
func (c *StawiChain) syncMember(
	ctx context.Context, tx *gorm.DB, room *models.Room, member *models.StawiRoomMember, fact *models.StawiChainFact,
) error {
	if err := c.resolveProfile(ctx, member); err != nil {
		return err
	}
	if member.ProfileID == "" {
		// No profile owns the address yet; the reconciler retries.
		return c.deps.Store.SaveMember(tx, member)
	}
	action, err := c.writeSubscription(ctx, tx, room, member)
	if err != nil {
		return err
	}
	if err = c.deps.Store.SaveMember(tx, member); err != nil {
		return err
	}
	if action == chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_UNSPECIFIED || fact == nil {
		return nil
	}
	if fact.OutcomeEventID == "" {
		fact.OutcomeEventID = util.IDString()
	}
	return c.postEvent(ctx, tx, room, fact.OutcomeEventID, "", &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_ROOM_CHANGE,
		Data: &chatv1.Payload_RoomChange{RoomChange: &chatv1.RoomChangeContent{
			Action:                action,
			TargetSubscriptionIds: []string{member.SubscriptionID},
			Body:                  roomChangeBody(action),
		}},
	})
}

func roomChangeBody(action chatv1.RoomChangeAction) string {
	switch action {
	case chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_MEMBER_ADDED:
		return "joined the room on chain"
	case chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_MEMBER_REMOVED:
		return "left the room on chain"
	case chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_ROLE_CHANGED:
		return "role changed on chain"
	case chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_UNSPECIFIED,
		chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_CREATED,
		chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_UPDATED,
		chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_DELETED:
	}
	return ""
}

func (c *StawiChain) resolveProfile(ctx context.Context, member *models.StawiRoomMember) error {
	if member.ProfileID != "" {
		return nil
	}
	if c.deps.Accounts == nil {
		return errors.New("stawi chain: no profile account resolver configured")
	}
	owners, err := c.deps.Accounts.Resolve(ctx, []string{member.Address})
	if err != nil {
		return fmt.Errorf("failed to resolve %s: %w", member.Address, err)
	}
	member.ProfileID = owners[member.Address]
	return nil
}

// desiredSubscription is the subscription the chain's membership calls for.
type desiredSubscription struct {
	present bool
	state   models.RoomSubscriptionState
	role    string
}

func desiredFor(member *models.StawiRoomMember) desiredSubscription {
	switch member.State {
	case models.StawiMemberStateActive, models.StawiMemberStateUnadmitted:
		role := authz.RoleMember
		if member.HoldsAnyRole() {
			role = authz.RoleAdmin
		}
		return desiredSubscription{present: true, state: models.RoomSubscriptionStateActive, role: role}
	case models.StawiMemberStateSuspended:
		return desiredSubscription{present: true, state: models.RoomSubscriptionStateActive, role: authz.RoleGuest}
	case models.StawiMemberStateInvited:
		return desiredSubscription{present: true, state: models.RoomSubscriptionStateProposed, role: authz.RoleMember}
	case models.StawiMemberStateNone, models.StawiMemberStateExited:
		return desiredSubscription{}
	}
	return desiredSubscription{}
}

func (d desiredSubscription) matches(sub *models.RoomSubscription) bool {
	if !d.present {
		return sub == nil || sub.SubscriptionState == models.RoomSubscriptionStateBlocked
	}
	return sub != nil && sub.SubscriptionState == d.state && sub.Role == d.role
}

// currentSubscription finds the member's subscription: the one the member
// record names (in any state), else a live one for the member's profile.
func currentSubscription(tx *gorm.DB, roomID string, member *models.StawiRoomMember) (*models.RoomSubscription, error) {
	var sub models.RoomSubscription
	var err error
	if member.SubscriptionID != "" {
		err = tx.Where("id = ? AND room_id = ?", member.SubscriptionID, roomID).First(&sub).Error
	} else {
		err = tx.Where("room_id = ? AND profile_id = ? AND subscription_state IN ?", roomID, member.ProfileID,
			[]models.RoomSubscriptionState{models.RoomSubscriptionStateActive, models.RoomSubscriptionStateProposed}).
			Order("id ASC").First(&sub).Error
	}
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil //nolint:nilnil // no subscription is an answer, not an error
	}
	if err != nil {
		return nil, err
	}
	return &sub, nil
}

// writeSubscription is the one path that writes a Stawi room's subscription
// row and its Keto tuple, from the member record alone. The row is written in
// the room's transaction; the tuple is written before the transaction
// commits, so a Keto failure rolls the row back and the fact is redelivered:
// it retries until both hold. Every step is idempotent.
func (c *StawiChain) writeSubscription(
	ctx context.Context, tx *gorm.DB, room *models.Room, member *models.StawiRoomMember,
) (chatv1.RoomChangeAction, error) {
	none := chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_UNSPECIFIED
	want := desiredFor(member)
	sub, err := currentSubscription(tx, room.GetID(), member)
	if err != nil {
		return none, err
	}

	if !want.present {
		return c.removeSubscription(ctx, tx, room.GetID(), member, sub)
	}

	action := none
	switch {
	case sub == nil:
		sub = &models.RoomSubscription{
			RoomID: room.GetID(), ProfileID: member.ProfileID, Role: want.role, SubscriptionState: want.state,
		}
		sub.TenantID, sub.PartitionID, sub.AccessID = room.TenantID, room.PartitionID, room.AccessID
		sub.GenID(ctx)
		if err = tx.Create(sub).Error; err != nil {
			return none, err
		}
		if want.state == models.RoomSubscriptionStateActive {
			action = chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_MEMBER_ADDED
		}
	case !want.matches(sub):
		wasActive := sub.IsActive()
		roleChanged := sub.Role != want.role
		if err = setSubscription(tx, sub.GetID(), want.state, want.role); err != nil {
			return none, err
		}
		switch {
		case !wasActive && want.state == models.RoomSubscriptionStateActive:
			action = chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_MEMBER_ADDED
		case wasActive && want.state != models.RoomSubscriptionStateActive:
			action = chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_MEMBER_REMOVED
		case roleChanged:
			action = chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_ROLE_CHANGED
		}
	}
	member.SubscriptionID = sub.GetID()

	if want.state == models.RoomSubscriptionStateActive {
		err = c.deps.Authz.SetRoomMemberRole(ctx, room.GetID(), sub.GetID(), want.role)
	} else {
		err = c.deps.Authz.RemoveRoomMember(ctx, room.GetID(), sub.GetID())
	}
	return action, err
}

// removeSubscription is writeSubscription's path for a member the chain no
// longer has: the row is blocked and the tuples removed.
func (c *StawiChain) removeSubscription(
	ctx context.Context, tx *gorm.DB, roomID string, member *models.StawiRoomMember, sub *models.RoomSubscription,
) (chatv1.RoomChangeAction, error) {
	none := chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_UNSPECIFIED
	if sub == nil {
		return none, nil
	}
	member.SubscriptionID = sub.GetID()
	wasLive := sub.SubscriptionState != models.RoomSubscriptionStateBlocked
	if wasLive {
		if err := setSubscription(tx, sub.GetID(), models.RoomSubscriptionStateBlocked, sub.Role); err != nil {
			return none, err
		}
	}
	if err := c.deps.Authz.RemoveRoomMember(ctx, roomID, sub.GetID()); err != nil {
		return none, err
	}
	if wasLive {
		return chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_MEMBER_REMOVED, nil
	}
	return none, nil
}

func setSubscription(tx *gorm.DB, id string, state models.RoomSubscriptionState, role string) error {
	return tx.Table("room_subscriptions").Where("id = ?", id).Updates(map[string]any{
		"subscription_state": state, "role": role, "modified_at": time.Now(),
	}).Error
}

func (c *StawiChain) applyCallObserved(
	ctx context.Context, tx *gorm.DB, room *models.Room,
	fact *models.StawiChainFact, msg *financev1.GovernanceCallObserved,
) error {
	outcome := &chatv1.StawiCallOutcomeContent{
		State:       chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_OBSERVED,
		Kind:        strings.TrimPrefix(msg.GetEvent().String(), "GOVERNANCE_CHAIN_EVENT_"),
		ChainId:     msg.GetChainId(),
		TxHash:      msg.GetTxHash(),
		BlockNumber: msg.GetBlockNumber(),
		LogIndex:    msg.GetLogIndex(),
	}
	parent := ""
	if len(msg.GetCallMember()) > 0 {
		call, err := c.deps.Calls.FindBySigner(ctx, room.GetID(), HexAddress(msg.GetCallMember()), msg.GetCallNonce())
		if err != nil && !data.ErrorIsNoRows(err) {
			return err
		}
		if call != nil {
			outcome.CallId, outcome.SourceEventId, parent = call.GetID(), call.SourceEventID, call.SourceEventID
			if err = settleCall(tx, call.GetID(), models.StawiCallStateObserved); err != nil {
				return err
			}
		}
	}
	if fact.OutcomeEventID == "" {
		fact.OutcomeEventID = util.IDString()
	}
	return c.postEvent(ctx, tx, room, fact.OutcomeEventID, parent, outcomePayload(outcome))
}

func (c *StawiChain) applyCallFailed(
	ctx context.Context, tx *gorm.DB, room *models.Room,
	fact *models.StawiChainFact, msg *financev1.GovernanceCallFailed,
) error {
	call, err := c.deps.Calls.FindBySigner(ctx, room.GetID(), HexAddress(msg.GetCall().GetMember()),
		msg.GetCall().GetNonce())
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return nil // not a call chat relayed
		}
		return err
	}
	res := tx.Table("stawi_room_calls").Where("id = ? AND state = ?", call.GetID(),
		models.StawiCallStateSubmitted).Updates(map[string]any{colStawiState: models.StawiCallStateFailed})
	if res.Error != nil || res.RowsAffected == 0 {
		return res.Error // already settled: reported once
	}
	if fact.OutcomeEventID == "" {
		fact.OutcomeEventID = util.IDString()
	}
	return c.postEvent(ctx, tx, room, fact.OutcomeEventID, call.SourceEventID, outcomePayload(
		&chatv1.StawiCallOutcomeContent{
			CallId: call.GetID(), State: chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_FAILED,
			Reason: truncate(msg.GetReason(), maxOutcomeReason), SourceEventId: call.SourceEventID,
			Kind: call.Kind, TxHash: msg.GetTxHash(),
		}))
}

func settleCall(tx *gorm.DB, callID, state string) error {
	return tx.Table("stawi_room_calls").Where("id = ? AND state = ?", callID, models.StawiCallStateSubmitted).
		Updates(map[string]any{colStawiState: state}).Error
}

func outcomePayload(outcome *chatv1.StawiCallOutcomeContent) *chatv1.Payload {
	return &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_CALL_OUTCOME,
		Data: &chatv1.Payload_StawiCallOutcome{StawiCallOutcome: outcome},
	}
}

// postEvent stores a server event and its outbox row in the room's
// transaction, under a fixed id, so a re-applied fact posts it once.
func (c *StawiChain) postEvent(
	ctx context.Context, tx *gorm.DB, room *models.Room, eventID, parentID string, payload *chatv1.Payload,
) error {
	content, err := c.converter.FromProto(payload)
	if err != nil {
		return err
	}
	eventType := chatv1.RoomEventType_ROOM_EVENT_TYPE_SYSTEM
	event := &models.RoomEvent{RoomID: room.GetID(), EventType: int32(eventType), Content: content, ParentID: parentID}
	event.ID = eventID
	event.CreatedAt = time.Now()
	event.TenantID, event.PartitionID, event.AccessID = room.TenantID, room.PartitionID, room.AccessID
	res := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(event)
	if res.Error != nil || res.RowsAffected == 0 {
		return res.Error
	}
	link, err := serverEventLink(event)
	if err != nil {
		return err
	}
	outbox := &models.RoomOutbox{EventID: eventID, RoomID: room.GetID(), Payload: link}
	outbox.TenantID, outbox.PartitionID, outbox.AccessID = room.TenantID, room.PartitionID, room.AccessID
	outbox.GenID(ctx)
	return tx.Clauses(clause.OnConflict{Columns: []clause.Column{{Name: "event_id"}}, DoNothing: true}).
		Create(outbox).Error
}

// Run is the chain consumer's background loop: every interval it applies
// rooms whose facts are still waiting (for instance after a failed delivery
// that the queue gave up on) and reconciles bound rooms with the chain.
func (c *StawiChain) Run(ctx context.Context, interval time.Duration) error {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return nil
		case <-ticker.C:
			c.Sweep(ctx)
		}
	}
}

// Sweep applies waiting facts and reconciles once.
func (c *StawiChain) Sweep(ctx context.Context) {
	rooms, err := c.deps.Store.RoomsWithPending(ctx, sweepBatch)
	if err != nil {
		util.Log(ctx).WithError(err).Warn("stawi chain: could not list rooms with waiting facts")
	}
	for _, roomID := range rooms {
		if applyErr := c.ApplyRoom(ctx, roomID); applyErr != nil {
			util.Log(ctx).WithError(applyErr).WithField(chatutil.KeyRoomID, roomID).
				Warn("stawi chain: waiting facts not applied; retrying next sweep")
		}
	}
	if _, err = c.Reconcile(ctx); err != nil {
		util.Log(ctx).WithError(err).Warn("stawi reconciler: pass failed")
	}
}

// Reconcile compares every bound room's subscriptions and Keto tuples with
// the chain's membership as chat has folded it from settlement's facts,
// repairs the differences and emits room.subscription_drift for each room it
// repaired. It also asks settlement about relayed calls whose outcome never
// arrived as a fact.
func (c *StawiChain) Reconcile(ctx context.Context) (ReconcileReport, error) {
	var report ReconcileReport
	const page = 100
	after := ""
	for {
		rooms, err := c.deps.Bindings.ListBound(ctx, after, page)
		if err != nil {
			return report, err
		}
		for _, binding := range rooms {
			drift, roomErr := c.reconcileRoom(ctx, binding.GetID())
			if roomErr != nil {
				util.Log(ctx).WithError(roomErr).WithField(chatutil.KeyRoomID, binding.GetID()).
					Warn("stawi reconciler: room not reconciled; retrying next pass")
				continue
			}
			report.Rooms++
			report.Repaired += drift.Total()
		}
		if len(rooms) < page {
			break
		}
		after = rooms[len(rooms)-1].GetID()
	}
	resolved, err := c.settleStaleCalls(ctx)
	report.CallsResolved = resolved
	return report, err
}

func (c *StawiChain) reconcileRoom(ctx context.Context, roomID string) (StawiDrift, error) {
	drift := StawiDrift{RoomID: roomID, At: time.Now()}
	room, err := c.deps.RoomRepo.GetByID(ctx, roomID)
	if err != nil {
		return drift, err
	}
	err = c.deps.Store.WithRoomLock(ctx, roomID, func(tx *gorm.DB) error {
		var members []*models.StawiRoomMember
		if findErr := tx.Where("room_id = ?", roomID).Find(&members).Error; findErr != nil {
			return findErr
		}
		expected := map[string]bool{}
		for _, member := range members {
			if repairErr := c.reconcileMember(ctx, tx, room, member, &drift); repairErr != nil {
				return repairErr
			}
			if desiredFor(member).present && member.SubscriptionID != "" {
				expected[member.SubscriptionID] = true
			}
		}
		return c.removeStrays(ctx, tx, roomID, expected, &drift)
	})
	if err != nil || drift.Total() == 0 {
		return drift, err
	}
	if c.deps.Drift != nil {
		if pubErr := c.deps.Drift.PublishDrift(ctx, drift); pubErr != nil {
			util.Log(ctx).WithError(pubErr).WithField(chatutil.KeyRoomID, roomID).
				Warn("stawi reconciler: failed to publish room.subscription_drift")
		}
	}
	return drift, nil
}

func (c *StawiChain) reconcileMember(
	ctx context.Context, tx *gorm.DB, room *models.Room, member *models.StawiRoomMember, drift *StawiDrift,
) error {
	if err := c.resolveProfile(ctx, member); err != nil {
		return err
	}
	if member.ProfileID == "" {
		return nil
	}
	sub, err := currentSubscription(tx, room.GetID(), member)
	if err != nil {
		return err
	}
	want := desiredFor(member)
	rowOK := want.matches(sub)
	ketoOK := true
	if rowOK && want.present {
		ketoOK = c.ketoHolds(ctx, room.GetID(), sub.GetID(), want)
	}
	if rowOK && ketoOK && (sub == nil || member.SubscriptionID == sub.GetID()) {
		return nil
	}
	if _, err = c.writeSubscription(ctx, tx, room, member); err != nil {
		return err
	}
	switch {
	case !rowOK && want.present && (sub == nil || sub.SubscriptionState == models.RoomSubscriptionStateBlocked):
		drift.Restored++
	case !rowOK:
		drift.RolesFixed++
	case !ketoOK:
		drift.PermissionsRepaired++
	}
	return c.deps.Store.SaveMember(tx, member)
}

// ketoHolds checks the subscription's room permissions are exactly the ones
// its role grants.
func (c *StawiChain) ketoHolds(ctx context.Context, roomID, subID string, want desiredSubscription) bool {
	if want.state != models.RoomSubscriptionStateActive {
		return c.deps.Authz.CanRoomView(ctx, subID, roomID) != nil
	}
	view := c.deps.Authz.CanRoomView(ctx, subID, roomID) == nil
	send := c.deps.Authz.CanMessageSend(ctx, subID, roomID) == nil
	manage := c.deps.Authz.CanMembersManage(ctx, subID, roomID) == nil
	switch want.role {
	case authz.RoleGuest:
		return view && !send && !manage
	case authz.RoleAdmin:
		return view && send && manage && c.deps.Authz.CanRolesManage(ctx, subID, roomID) != nil
	default:
		return view && send && !manage
	}
}

// removeStrays deactivates live subscriptions the chain's membership does not
// account for.
func (c *StawiChain) removeStrays(
	ctx context.Context, tx *gorm.DB, roomID string, expected map[string]bool, drift *StawiDrift,
) error {
	var live []*models.RoomSubscription
	if err := tx.Where("room_id = ? AND subscription_state IN ?", roomID,
		[]models.RoomSubscriptionState{models.RoomSubscriptionStateActive, models.RoomSubscriptionStateProposed}).
		Find(&live).Error; err != nil {
		return err
	}
	for _, sub := range live {
		if expected[sub.GetID()] {
			continue
		}
		if err := setSubscription(tx, sub.GetID(), models.RoomSubscriptionStateBlocked, sub.Role); err != nil {
			return err
		}
		if err := c.deps.Authz.RemoveRoomMember(ctx, roomID, sub.GetID()); err != nil {
			return err
		}
		drift.Removed++
	}
	return nil
}

// settleStaleCalls asks settlement about relayed calls still waiting for an
// outcome and reports the ones settlement has settled.
func (c *StawiChain) settleStaleCalls(ctx context.Context) (int, error) {
	if c.deps.Rooms == nil {
		return 0, nil
	}
	calls, err := c.deps.Calls.ListSubmittedBefore(ctx, time.Now().Add(-c.deps.StaleCallAfter), sweepBatch)
	if err != nil {
		return 0, err
	}
	resolved := 0
	for _, tracked := range calls {
		call, getErr := c.deps.Rooms.GetRoomCall(ctx, tracked.GetID())
		if getErr != nil {
			continue
		}
		var state chatv1.StawiCallOutcomeState
		var callState string
		switch call.State {
		case stawi.CallStateFinal:
			state, callState = chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_OBSERVED, models.StawiCallStateObserved
		case stawi.CallStateFailed:
			state, callState = chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_FAILED, models.StawiCallStateFailed
		case stawi.CallStateUnspecified, stawi.CallStatePrepared, stawi.CallStateSubmitted:
			continue
		}
		room, roomErr := c.deps.RoomRepo.GetByID(ctx, tracked.RoomID)
		if roomErr != nil {
			continue
		}
		lockErr := c.deps.Store.WithRoomLock(ctx, tracked.RoomID, func(tx *gorm.DB) error {
			res := tx.Table("stawi_room_calls").Where("id = ? AND state = ?", tracked.GetID(),
				models.StawiCallStateSubmitted).Updates(map[string]any{colStawiState: callState})
			if res.Error != nil || res.RowsAffected == 0 {
				return res.Error
			}
			return c.postEvent(ctx, tx, room, util.IDString(), tracked.SourceEventID, outcomePayload(
				&chatv1.StawiCallOutcomeContent{
					CallId: tracked.GetID(), State: state, Reason: truncate(call.Reason, maxOutcomeReason),
					SourceEventId: tracked.SourceEventID, Kind: tracked.Kind, TxHash: call.TxHash,
				}))
		})
		if lockErr == nil {
			resolved++
		}
	}
	return resolved, nil
}
