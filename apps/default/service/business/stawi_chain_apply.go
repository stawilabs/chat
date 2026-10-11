package business

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	financev1 "buf.build/gen/go/stawi/finance/protocolbuffers/go/finance/v1"
	"github.com/pitabwire/frame/v2/data"
	"github.com/pitabwire/util"
	"google.golang.org/protobuf/proto"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/stawilabs/chat/apps/default/service/authz"
	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/pkg/chatutil"
	chattel "github.com/stawilabs/chat/pkg/telemetry"
)

// ApplyRoom applies the room's waiting facts in chain order.
//
// Work that leaves the database runs outside the room's lock: the members'
// profiles are resolved before it is taken, and Keto is written after it is
// released, from ops recorded in the same transaction as the subscription
// rows (so a Keto write can be retried but never lost; until it lands, a
// blocked subscription row already refuses the member). Each fact runs in its
// own savepoint: a fact that fails is rolled back on its own, counted, and
// quarantined at the attempt limit, while the room's later facts still apply
// — an exit or a suspension is never held up behind a fact that cannot be
// applied. Folding is monotonic per member, so applying past a failed fact
// leaves the same state the in-order application would.
func (c *StawiChain) ApplyRoom(ctx context.Context, roomID string) error {
	room, err := c.deps.RoomRepo.GetByID(ctx, roomID)
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return nil // facts wait for the room
		}
		return err
	}
	var stuck error
	// A fact recorded while a pass runs names an address that pass did not
	// look up; it is left waiting and the pass repeats for it.
	for range maxApplyPasses {
		deferred, passErr := c.applyPass(ctx, room)
		if passErr != nil {
			stuck = passErr
		}
		if !deferred {
			break
		}
	}
	if drainErr := c.drainKeto(ctx, roomID); drainErr != nil {
		util.Log(ctx).WithError(drainErr).WithField(chatutil.KeyRoomID, roomID).
			Warn("stawi chain: Keto writes pending; the sweep retries them")
	}
	return stuck
}

// applyPass resolves the profiles the waiting facts need, then applies the
// facts under the room's lock. It reports whether a fact was deferred for a
// profile not yet looked up.
func (c *StawiChain) applyPass(ctx context.Context, room *models.Room) (bool, error) {
	roomID := room.GetID()
	// A profile outage holds back only the facts that need a lookup; the
	// rest (revocations of known members above all) still apply, and the
	// outage is reported so the delivery is retried.
	profiles, lookupErr := c.resolvePendingProfiles(ctx, roomID)

	var outcome factResult
	err := c.deps.Store.WithRoomLock(ctx, roomID, func(tx *gorm.DB) error {
		facts, pendingErr := c.deps.Store.Pending(tx, roomID)
		if pendingErr != nil {
			return pendingErr
		}
		var passErr error
		outcome, passErr = c.applyInOrder(ctx, tx, room, facts, profiles)
		return passErr
	})
	if err != nil {
		return false, err
	}
	if lookupErr != nil {
		return false, lookupErr // the deferred facts wait for profile; no further pass now
	}
	return outcome.deferred, outcome.stuck
}

// applyInOrder applies the room's waiting facts in chain order. A fact
// waits, uncounted, while an earlier fact of its subject has not applied
// (failed, deferred, quarantined or backing off), or while it is itself
// quarantined or backing off.
func (c *StawiChain) applyInOrder(
	ctx context.Context, tx *gorm.DB, room *models.Room, facts []*models.StawiChainFact, profiles map[string]string,
) (factResult, error) {
	var outcome factResult
	gate := newFactGate()
	var waiting []string
	now := time.Now()
	for i, fact := range facts {
		subject := factSubject(fact)
		reduction := isReduction(fact)
		// A fact that removes or lowers access never waits behind an earlier
		// fact of its member: revocations fail closed. Additions wait.
		held := !reduction && gate.holds(subject)
		backingOff := fact.NextAttemptAt != nil && fact.NextAttemptAt.After(now)
		if held || backingOff || (fact.Quarantined && !reduction) {
			gate.block(subject)
			waiting = append(waiting, fact.GetID())
			continue
		}
		result, err := c.applyOne(ctx, tx, room, fact, profiles, fmt.Sprintf("stawi_fact_%d", i))
		if err != nil {
			return outcome, err
		}
		if result.deferred || result.stuck != nil {
			gate.block(subject) // later additions of the member wait
		}
		outcome.deferred = outcome.deferred || result.deferred
		if outcome.stuck == nil {
			outcome.stuck = result.stuck
		}
	}
	return outcome, c.deps.Store.TouchWaiting(tx, waiting)
}

// factResult is how one fact's application ended, short of a database error.
type factResult struct {
	deferred bool
	stuck    error
}

// applyOne applies one fact in its own savepoint. A failure rolls back only
// that fact, is counted, and quarantines it at the attempt limit.
func (c *StawiChain) applyOne(
	ctx context.Context, tx *gorm.DB, room *models.Room, fact *models.StawiChainFact,
	profiles map[string]string, savepoint string,
) (factResult, error) {
	if err := tx.SavePoint(savepoint).Error; err != nil {
		return factResult{}, err
	}
	var applyErr error
	if c.applyFault != nil {
		applyErr = c.applyFault(fact)
	}
	if applyErr == nil {
		applyErr = c.applyFact(ctx, tx, room, fact, profiles)
	}
	if applyErr == nil {
		applyErr = c.deps.Store.MarkApplied(tx, fact)
	}
	if applyErr == nil {
		return factResult{}, nil
	}
	if err := tx.RollbackTo(savepoint).Error; err != nil {
		return factResult{}, err
	}
	fact.OutcomeEventID = ""
	if errors.Is(applyErr, errProfileNotLookedUp) {
		return factResult{deferred: true}, nil // not a failure: the next pass looks it up
	}
	limit, maxBackoff := c.deps.MaxFactAttempts, maxFactBackoff
	if isReduction(fact) {
		// A revocation is never set aside: it is retried, soon, until it lands.
		limit, maxBackoff = 0, maxRevocationBackoff
	}
	quarantined, err := c.deps.Store.RecordFailure(tx, fact, applyErr, limit, c.deps.FactRetryBackoff, maxBackoff)
	if err != nil {
		return factResult{}, err
	}
	logger := util.Log(ctx).WithError(applyErr).WithFields(map[string]any{
		logKeyFact: fact.FactKey, chatutil.KeyRoomID: room.GetID(), "attempts": fact.Attempts,
	})
	if limit == 0 && fact.Attempts >= c.deps.MaxFactAttempts {
		chattel.StawiRevocationsFailingCounter.Add(ctx, 1)
		logger.Error("stawi chain: a revocation keeps failing; the member keeps access until it lands")
	}
	if quarantined {
		chattel.StawiFactsQuarantinedCounter.Add(ctx, 1)
		logger.Error("stawi chain: fact quarantined after repeated failures; re-drive once fixed")
		return factResult{}, nil
	}
	logger.Warn("stawi chain: fact not applied; it will be retried")
	return factResult{stuck: fmt.Errorf("failed to apply %s %s: %w", fact.EventName, fact.FactKey, applyErr)}, nil
}

// Backoff caps: additions back off up to an hour; revocations retry at
// least every minute.
const (
	maxFactBackoff       = time.Hour
	maxRevocationBackoff = time.Minute
)

// isReduction reports whether a fact removes or lowers a member's access:
// an exit, a suspension, a return to no state, a role revocation or an
// invitation revoked. Such facts fail closed: they apply as soon as they
// arrive, never wait behind an earlier fact of the member and are never
// quarantined. Folding is positional per member and per role, so an older
// fact applied after them (a re-driven invitation or role grant) changes
// nothing — a revocation cannot be undone by a re-drive.
func isReduction(fact *models.StawiChainFact) bool {
	if fact.EventName != FactRoomMembershipObserved {
		return false
	}
	var msg financev1.RoomMembershipObserved
	if proto.Unmarshal(fact.Payload, &msg) != nil {
		return false
	}
	return reducesAccess(&msg)
}

func reducesAccess(msg *financev1.RoomMembershipObserved) bool {
	switch msg.GetEvent() {
	case financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_MEMBER_INVITE_REVOKED:
		return true
	case financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_ROLE_CHANGED:
		return !msg.GetRoleAssigned()
	case financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_MEMBER_STATE_CHANGED:
		switch msg.GetToState() {
		case financev1.RoomMemberState_ROOM_MEMBER_STATE_EXITED,
			financev1.RoomMemberState_ROOM_MEMBER_STATE_SUSPENDED,
			financev1.RoomMemberState_ROOM_MEMBER_STATE_UNSPECIFIED:
			return true
		case financev1.RoomMemberState_ROOM_MEMBER_STATE_ACTIVE,
			financev1.RoomMemberState_ROOM_MEMBER_STATE_UNADMITTED:
			return false
		}
		return true // an unknown state is treated as the lowest
	case financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_UNSPECIFIED,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_MEMBER_INVITED,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_ROOM_BINDING_SET,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_JOIN_POLICY_SET,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_DELEGATE_CAPABILITY_SET,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_DELEGATE_CAPABILITY_REVOKED:
	}
	return false
}

// roomWide is the subject of a fact whose subject cannot be told: it waits
// for every earlier fact and holds back every later one.
const roomWide = "*"

// factSubject is what a fact orders against. Membership facts are ordered per
// account: a member's facts apply in chain order, and one that has not
// applied holds back that member's later facts. Accounts are independent —
// each has its own member row, and a profile's subscription is recomputed
// from all of its rows — so another member's facts (an exit) are not held
// back. Call facts each stand alone.
func factSubject(fact *models.StawiChainFact) string {
	if fact.EventName != FactRoomMembershipObserved {
		return "fact:" + fact.FactKey
	}
	var msg financev1.RoomMembershipObserved
	if proto.Unmarshal(fact.Payload, &msg) != nil {
		return roomWide
	}
	if address := membershipAddress(&msg); address != "" {
		return "member:" + address
	}
	return "fact:" + fact.FactKey
}

// factGate tracks which subjects are held back in a pass.
type factGate struct {
	subjects map[string]bool
	all      bool
}

func newFactGate() *factGate { return &factGate{subjects: map[string]bool{}} }

func (g *factGate) holds(subject string) bool {
	return g.all || g.subjects[subject] || (subject == roomWide && len(g.subjects) > 0)
}

func (g *factGate) block(subject string) {
	if subject == roomWide {
		g.all = true
		return
	}
	g.subjects[subject] = true
}

// errMembershipOutOfSync fails a membership fact that does not follow from
// the member's recorded state (an invitation of a member, a revocation of no
// invitation): chat's record is behind the chain, so the fact is not dropped
// but retried and, if it persists, quarantined for an operator.
var errMembershipOutOfSync = errors.New("stawi chain: the membership fact does not follow from the member's state")

// errProfileNotLookedUp defers a membership fact whose address the current
// pass did not resolve (the fact arrived after the lookup).
var errProfileNotLookedUp = errors.New("stawi chain: the member's profile was not looked up in this pass")

const maxApplyPasses = 3

// Redrive returns a room's quarantined facts to the queue and applies them;
// for an operator once the cause is fixed.
func (c *StawiChain) Redrive(ctx context.Context, roomID string) error {
	if _, err := c.deps.Store.Redrive(ctx, roomID); err != nil {
		return err
	}
	return c.ApplyRoom(ctx, roomID)
}

// resolvePendingProfiles maps the addresses the room's waiting membership
// facts name to profiles, outside the room's lock. Addresses whose member row
// already carries a profile are not looked up again.
func (c *StawiChain) resolvePendingProfiles(ctx context.Context, roomID string) (map[string]string, error) {
	facts, err := c.deps.Store.PendingNoLock(ctx, roomID)
	if err != nil {
		return nil, err
	}
	wanted := map[string]bool{}
	for _, fact := range facts {
		if fact.EventName != FactRoomMembershipObserved {
			continue
		}
		var msg financev1.RoomMembershipObserved
		if proto.Unmarshal(fact.Payload, &msg) != nil {
			continue
		}
		if address := membershipAddress(&msg); address != "" {
			wanted[address] = true
		}
	}
	return c.resolveAddresses(ctx, roomID, wanted)
}

// resolveAddresses returns the profile of each wanted address: from the
// room's member rows where known, otherwise from the profile service.
func (c *StawiChain) resolveAddresses(
	ctx context.Context, roomID string, wanted map[string]bool,
) (map[string]string, error) {
	profiles := map[string]string{}
	if len(wanted) == 0 {
		return profiles, nil
	}
	members, err := c.deps.Store.Members(ctx, roomID)
	if err != nil {
		return nil, err
	}
	for _, member := range members {
		if member.ProfileID != "" && wanted[member.Address] {
			profiles[member.Address] = member.ProfileID
		}
	}
	var unresolved []string
	for address := range wanted {
		if _, ok := profiles[address]; !ok {
			unresolved = append(unresolved, address)
		}
	}
	if len(unresolved) == 0 {
		return profiles, nil
	}
	if c.deps.Accounts == nil {
		return nil, errors.New("stawi chain: no profile account resolver configured")
	}
	owners, err := c.deps.Accounts.Resolve(ctx, unresolved)
	if err != nil {
		// The known profiles still serve; the unresolved addresses' facts wait.
		return profiles, fmt.Errorf("failed to resolve %d addresses: %w", len(unresolved), err)
	}
	for _, address := range unresolved {
		profiles[address] = "" // looked up: no profile owns it (yet)
	}
	for address, profileID := range owners {
		profiles[strings.ToLower(address)] = profileID
	}
	return profiles, nil
}

func membershipAddress(msg *financev1.RoomMembershipObserved) string {
	switch msg.GetEvent() {
	case financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_MEMBER_INVITED,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_MEMBER_INVITE_REVOKED:
		return HexAddress(msg.GetInvitee())
	case financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_MEMBER_STATE_CHANGED,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_ROLE_CHANGED:
		return HexAddress(msg.GetMember())
	case financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_UNSPECIFIED,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_ROOM_BINDING_SET,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_JOIN_POLICY_SET,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_DELEGATE_CAPABILITY_SET,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_DELEGATE_CAPABILITY_REVOKED:
		// bindings, join policy and delegates do not change subscriptions
	}
	return ""
}

func (c *StawiChain) applyFact(
	ctx context.Context, tx *gorm.DB, room *models.Room, fact *models.StawiChainFact, profiles map[string]string,
) error {
	switch fact.EventName {
	case FactRoomMembershipObserved:
		var msg financev1.RoomMembershipObserved
		if err := proto.Unmarshal(fact.Payload, &msg); err != nil {
			return err
		}
		return c.applyMembership(ctx, tx, room, fact, &msg, profiles)
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
	case FactRoomCallFinal:
		var msg financev1.RoomCallFinal
		if err := proto.Unmarshal(fact.Payload, &msg); err != nil {
			return err
		}
		return c.settleRoomCall(ctx, tx, room, fact, msg.GetCallId(), &chatv1.StawiCallOutcomeContent{
			State:   chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_OBSERVED,
			ChainId: msg.GetChainId(), TxHash: msg.GetTxHash(), BlockNumber: msg.GetBlockNumber(),
		})
	case FactRoomCallFailed:
		var msg financev1.RoomCallFailed
		if err := proto.Unmarshal(fact.Payload, &msg); err != nil {
			return err
		}
		return c.settleRoomCall(ctx, tx, room, fact, msg.GetCallId(), &chatv1.StawiCallOutcomeContent{
			State:   chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_FAILED,
			Reason:  truncateReason(msg.GetReason()),
			ChainId: msg.GetChainId(), TxHash: msg.GetTxHash(),
		})
	default:
		return nil
	}
}

func (c *StawiChain) applyMembership(
	ctx context.Context, tx *gorm.DB, room *models.Room,
	fact *models.StawiChainFact, msg *financev1.RoomMembershipObserved, profiles map[string]string,
) error {
	address := membershipAddress(msg)
	if address == "" {
		return nil
	}
	member, err := c.deps.Store.Member(tx, room, address)
	if err != nil {
		return err
	}
	pos := models.ChainPosition{Block: fact.BlockNumber, LogIndex: fact.LogIndex}
	changed, err := foldMembership(member, msg, pos)
	if err != nil {
		return err
	}
	if !changed {
		util.Log(ctx).WithFields(map[string]any{logKeyFact: fact.FactKey, "member": address}).
			Debug("stawi chain: membership fact older than the member's recorded state; nothing to change")
		return nil
	}
	if member.ProfileID == "" {
		profileID, looked := profiles[member.Address]
		switch {
		case looked:
			member.ProfileID = profileID
		case !reducesAccess(msg):
			return errProfileNotLookedUp
		default:
			// A member with no profile has no subscription, so a revocation
			// has nothing to remove: record it now, resolve later.
		}
	}
	if err = c.deps.Store.SaveMember(tx, member); err != nil {
		return err
	}
	if member.ProfileID == "" {
		return nil // no profile owns the address yet; the reconciler retries
	}
	return c.syncProfile(ctx, tx, room, member.ProfileID, fact)
}

// foldMembership applies one membership fact to the member's record. A fact
// at or before the position the record already reflects is a duplicate or a
// replay and changes nothing (false, nil). A newer fact that does not follow
// from the recorded state fails (errMembershipOutOfSync) rather than being
// dropped. State changes carry the chain's new state and are applied as is.
func foldMembership(member *models.StawiRoomMember, msg *financev1.RoomMembershipObserved,
	pos models.ChainPosition,
) (bool, error) {
	switch msg.GetEvent() {
	case financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_MEMBER_INVITED:
		if !pos.After(member.StatePosition()) {
			return false, nil
		}
		if member.State != models.StawiMemberStateNone && member.State != models.StawiMemberStateExited {
			return false, fmt.Errorf("%w: invitation of a member in state %d", errMembershipOutOfSync, member.State)
		}
		member.State = models.StawiMemberStateInvited
	case financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_MEMBER_INVITE_REVOKED:
		if !pos.After(member.StatePosition()) {
			return false, nil
		}
		switch member.State {
		case models.StawiMemberStateInvited:
			member.State = models.StawiMemberStateNone
		case models.StawiMemberStateNone, models.StawiMemberStateExited:
			// The invitation itself has not applied (it is held back or
			// missing): record the revocation's position, so that applying
			// the older invitation later changes nothing.
		case models.StawiMemberStateActive, models.StawiMemberStateSuspended, models.StawiMemberStateUnadmitted:
			return false, fmt.Errorf("%w: revocation with no open invitation (state %d)", errMembershipOutOfSync,
				member.State)
		}
	case financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_MEMBER_STATE_CHANGED:
		if !pos.After(member.StatePosition()) {
			return false, nil
		}
		member.State = models.StawiMemberState(msg.GetToState())
	case financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_ROLE_CHANGED:
		roleID := HexAddress(msg.GetRoleId())
		if entry, ok := member.Role(roleID); ok && !pos.After(entry.Position) {
			return false, nil
		}
		member.SetRole(roleID, models.RoleEntry{Assigned: msg.GetRoleAssigned(), Position: pos})
		return true, nil
	case financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_UNSPECIFIED,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_ROOM_BINDING_SET,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_JOIN_POLICY_SET,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_DELEGATE_CAPABILITY_SET,
		financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_DELEGATE_CAPABILITY_REVOKED:
		return false, nil
	default:
		return false, nil
	}
	member.StateBlock, member.StateLogIndex = pos.Block, pos.LogIndex
	return true, nil
}

// syncProfile brings a profile's subscription in line with all of its
// member rows in the room (a profile may hold several accounts there),
// posting a room change when the subscription moved.
func (c *StawiChain) syncProfile(
	ctx context.Context, tx *gorm.DB, room *models.Room, profileID string, fact *models.StawiChainFact,
) error {
	action, err := c.writeProfileSubscription(ctx, tx, room, profileID)
	if err != nil || action == chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_UNSPECIFIED || fact == nil {
		return err
	}
	if fact.OutcomeEventID == "" {
		fact.OutcomeEventID = util.IDString()
	}
	sub, err := currentProfileSubscription(tx, room.GetID(), profileID, nil)
	if err != nil || sub == nil {
		return err
	}
	return c.postEvent(ctx, tx, room, fact.OutcomeEventID, "", &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_ROOM_CHANGE,
		Data: &chatv1.Payload_RoomChange{RoomChange: &chatv1.RoomChangeContent{
			Action:                action,
			TargetSubscriptionIds: []string{sub.GetID()},
			Body:                  roomChangeBody(action),
		}},
	})
}

// desiredSubscription is the subscription the chain's membership calls for.
type desiredSubscription struct {
	present bool
	state   models.RoomSubscriptionState
	role    string
}

// Membership strength when combining a profile's accounts.
const (
	rankInvited = iota + 1
	rankSuspended
	rankActive
)

// desiredForProfile combines all of a profile's member rows: the strongest
// membership wins (active or unadmitted, then suspended, then invited), and
// an active membership holding any on-chain role makes an admin.
func desiredForProfile(members []*models.StawiRoomMember) desiredSubscription {
	rank := 0
	admin := false
	for _, member := range members {
		switch member.State {
		case models.StawiMemberStateActive, models.StawiMemberStateUnadmitted:
			rank = max(rank, rankActive)
			admin = admin || member.HoldsAnyRole()
		case models.StawiMemberStateSuspended:
			rank = max(rank, rankSuspended)
		case models.StawiMemberStateInvited:
			rank = max(rank, rankInvited)
		case models.StawiMemberStateNone, models.StawiMemberStateExited:
		}
	}
	switch rank {
	case rankActive:
		if admin {
			return desiredSubscription{present: true, state: models.RoomSubscriptionStateActive, role: authz.RoleAdmin}
		}
		return desiredSubscription{present: true, state: models.RoomSubscriptionStateActive, role: authz.RoleMember}
	case rankSuspended:
		return desiredSubscription{present: true, state: models.RoomSubscriptionStateActive, role: authz.RoleGuest}
	case rankInvited:
		return desiredSubscription{present: true, state: models.RoomSubscriptionStateProposed, role: authz.RoleMember}
	default:
		return desiredSubscription{}
	}
}

func (d desiredSubscription) matches(sub *models.RoomSubscription) bool {
	if !d.present {
		return sub == nil || sub.SubscriptionState == models.RoomSubscriptionStateBlocked
	}
	return sub != nil && sub.SubscriptionState == d.state && sub.Role == d.role
}

// ketoRole is the relation a subscription in this desired state holds.
func (d desiredSubscription) ketoRole() string {
	if d.present && d.state == models.RoomSubscriptionStateActive {
		return d.role
	}
	return ""
}

// currentProfileSubscription finds the profile's subscription in the room,
// deterministically: a subscription its member rows name or a live one of
// the profile, active before invited before blocked, then by id.
func currentProfileSubscription(
	tx *gorm.DB, roomID, profileID string, members []*models.StawiRoomMember,
) (*models.RoomSubscription, error) {
	ids := []string{}
	for _, member := range members {
		if member.SubscriptionID != "" {
			ids = append(ids, member.SubscriptionID)
		}
	}
	live := []models.RoomSubscriptionState{models.RoomSubscriptionStateActive, models.RoomSubscriptionStateProposed}
	query := tx.Where("room_id = ?", roomID)
	if len(ids) > 0 {
		query = query.Where("(profile_id = ? AND subscription_state IN ?) OR id IN ?", profileID, live, ids)
	} else {
		query = query.Where("profile_id = ? AND subscription_state IN ?", profileID, live)
	}
	var sub models.RoomSubscription
	err := query.Order(clause.Expr{SQL: "CASE subscription_state WHEN ? THEN 0 WHEN ? THEN 1 ELSE 2 END, id ASC",
		Vars: []any{models.RoomSubscriptionStateActive, models.RoomSubscriptionStateProposed}}).
		First(&sub).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil //nolint:nilnil // no subscription is an answer, not an error
	}
	if err != nil {
		return nil, err
	}
	return &sub, nil
}

// writeProfileSubscription is the one path that writes a Stawi room's
// subscription rows. It derives the profile's subscription from all of the
// profile's member rows, writes the row in the room's transaction and records
// the Keto op that brings the tuples in line (applied after the transaction
// commits). It never blocks a subscription while another of the profile's
// accounts still holds a membership. It reports the change and the
// subscription it settled on.
func (c *StawiChain) writeProfileSubscription(
	ctx context.Context, tx *gorm.DB, room *models.Room, profileID string,
) (chatv1.RoomChangeAction, error) {
	none := chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_UNSPECIFIED
	members, err := c.deps.Store.ProfileMembers(tx, room.GetID(), profileID)
	if err != nil {
		return none, err
	}
	want := desiredForProfile(members)
	sub, err := currentProfileSubscription(tx, room.GetID(), profileID, members)
	if err != nil {
		return none, err
	}
	action, sub, err := changeSubscription(ctx, tx, room, profileID, want, sub)
	if err != nil || sub == nil {
		return action, err
	}
	if linkErr := tx.Table("stawi_room_members").Where("room_id = ? AND profile_id = ?", room.GetID(), profileID).
		Update("subscription_id", sub.GetID()).Error; linkErr != nil {
		return none, linkErr
	}
	if action != none {
		if err = c.deps.Store.EnqueueKeto(tx, room, sub.GetID(), want.ketoRole()); err != nil {
			return none, err
		}
	}
	return action, nil
}

// changeSubscription moves the profile's subscription row to what the chain
// wants, reporting the change and the row it settled on (nil if none).
func changeSubscription(
	ctx context.Context, tx *gorm.DB, room *models.Room, profileID string,
	want desiredSubscription, sub *models.RoomSubscription,
) (chatv1.RoomChangeAction, *models.RoomSubscription, error) {
	none := chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_UNSPECIFIED
	switch {
	case !want.present && (sub == nil || sub.SubscriptionState == models.RoomSubscriptionStateBlocked):
		return none, sub, nil // nothing live to remove
	case !want.present:
		err := setSubscription(tx, sub.GetID(), models.RoomSubscriptionStateBlocked, sub.Role)
		return chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_MEMBER_REMOVED, sub, err
	case sub == nil:
		sub = &models.RoomSubscription{
			RoomID: room.GetID(), ProfileID: profileID, Role: want.role, SubscriptionState: want.state,
		}
		sub.TenantID, sub.PartitionID, sub.AccessID = room.TenantID, room.PartitionID, room.AccessID
		sub.GenID(ctx)
		if err := tx.Create(sub).Error; err != nil {
			return none, nil, err
		}
		if want.state == models.RoomSubscriptionStateActive {
			return chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_MEMBER_ADDED, sub, nil
		}
		return none, sub, nil
	case want.matches(sub):
		return none, sub, nil
	}
	wasActive := sub.IsActive()
	roleChanged := sub.Role != want.role
	if err := setSubscription(tx, sub.GetID(), want.state, want.role); err != nil {
		return none, sub, err
	}
	switch {
	case !wasActive && want.state == models.RoomSubscriptionStateActive:
		return chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_MEMBER_ADDED, sub, nil
	case wasActive && want.state != models.RoomSubscriptionStateActive:
		return chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_MEMBER_REMOVED, sub, nil
	case roleChanged:
		return chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_ROLE_CHANGED, sub, nil
	}
	return none, sub, nil
}

func setSubscription(tx *gorm.DB, id string, state models.RoomSubscriptionState, role string) error {
	return tx.Table("room_subscriptions").Where("id = ?", id).Updates(map[string]any{
		"subscription_state": state, "role": role, colModifiedAt: time.Now(),
	}).Error
}

// drainKeto applies pending Keto ops (of one room, or all): each brings a
// subscription's tuples to the recorded relation, or removes them. An op that
// fails stays and is retried by the next drain.
func (c *StawiChain) drainKeto(ctx context.Context, roomID string) error {
	ops, err := c.deps.Store.PendingKeto(ctx, roomID, ketoDrainBatch)
	if err != nil {
		return err
	}
	var firstErr error
	for _, op := range ops {
		var writeErr error
		if op.Role == "" {
			writeErr = c.deps.Authz.RemoveRoomMember(ctx, op.RoomID, op.SubscriptionID)
		} else {
			writeErr = c.deps.Authz.SetRoomMemberRole(ctx, op.RoomID, op.SubscriptionID, op.Role)
		}
		if writeErr != nil {
			chattel.StawiKetoWritesFailedCounter.Add(ctx, 1)
			_ = c.deps.Store.FailKeto(ctx, op)
			if firstErr == nil {
				firstErr = writeErr
			}
			continue
		}
		if doneErr := c.deps.Store.CompleteKeto(ctx, op); doneErr != nil && firstErr == nil {
			firstErr = doneErr
		}
	}
	return firstErr
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

// settleRoomCall reports settlement's verdict on a call chat relayed
// (room.call_final / room.call_failed): once, against the act, and only for a
// call of the room whose custody emitted the fact.
func (c *StawiChain) settleRoomCall(
	ctx context.Context, tx *gorm.DB, room *models.Room, fact *models.StawiChainFact,
	callID string, outcome *chatv1.StawiCallOutcomeContent,
) error {
	call, err := c.deps.Calls.GetByID(ctx, callID)
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return nil // not a call chat relayed
		}
		return err
	}
	if call.RoomID != room.GetID() {
		util.Log(ctx).WithField("call_id", callID).WithField(chatutil.KeyRoomID, room.GetID()).
			Error("stawi chain: a call fact from another room's custody; ignored")
		return nil
	}
	state := models.StawiCallStateObserved
	if outcome.GetState() == chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_FAILED {
		state = models.StawiCallStateFailed
	}
	res := tx.Table("stawi_room_calls").Where("id = ? AND state = ?", call.GetID(),
		models.StawiCallStateSubmitted).Updates(map[string]any{colStawiState: state})
	if res.Error != nil || res.RowsAffected == 0 {
		return res.Error // already settled: reported once
	}
	outcome.CallId, outcome.SourceEventId, outcome.Kind = call.GetID(), call.SourceEventID, call.Kind
	if fact.OutcomeEventID == "" {
		fact.OutcomeEventID = util.IDString()
	}
	return c.postEvent(ctx, tx, room, fact.OutcomeEventID, call.SourceEventID, outcomePayload(outcome))
}

func (c *StawiChain) applyCallFailed(
	ctx context.Context, tx *gorm.DB, room *models.Room,
	fact *models.StawiChainFact, msg *financev1.GovernanceCallFailed,
) error {
	var call *models.StawiRoomCall
	var err error
	if msg.GetCallId() != "" {
		call, err = c.deps.Calls.GetByID(ctx, msg.GetCallId())
	} else {
		call, err = c.deps.Calls.FindBySigner(ctx, room.GetID(), HexAddress(msg.GetCall().GetMember()),
			msg.GetCall().GetNonce())
	}
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return nil // not a call chat relayed
		}
		return err
	}
	if call.RoomID != room.GetID() {
		return nil
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
			Reason: truncateReason(msg.GetReason()), SourceEventId: call.SourceEventID,
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
	return tx.Clauses(clause.OnConflict{Columns: []clause.Column{{Name: colEventID}}, DoNothing: true}).
		Create(outbox).Error
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
