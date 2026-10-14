package business_test

import (
	"errors"
	"testing"
	"time"

	financev1 "buf.build/gen/go/stawi/finance/protocolbuffers/go/finance/v1"
	"github.com/pitabwire/frame/v3/frametests/definition"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/proto"

	"github.com/stawilabs/chat/apps/default/service/business"
	"github.com/stawilabs/chat/apps/default/service/models"
)

func (cf *chainFixture) invitation(member []byte, revoked bool, block, log uint64) (string, []byte) {
	event := financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_MEMBER_INVITED
	if revoked {
		event = financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_MEMBER_INVITE_REVOKED
	}
	b, _ := proto.Marshal(&financev1.RoomMembershipObserved{
		Meta: meta(cf.roomID), ChainId: testChainID, CustodyAddress: custody, Event: event,
		Invitee: member, InviteId: 1, TxHash: txHash(block, log), BlockNumber: block, LogIndex: log,
		RoomId: cf.roomID,
	})
	return business.FactRoomMembershipObserved, b
}

func (cf *chainFixture) nowMinusDays(days int) time.Time {
	return time.Now().Add(-time.Duration(days) * 24 * time.Hour)
}

func (cf *chainFixture) memberState(t *testing.T, member []byte) models.StawiMemberState {
	t.Helper()
	var row models.StawiRoomMember
	err := cf.dbPool.DB(cf.ctx, false).Where("room_id = ? AND address = ?", cf.roomID, hexAddr(member)).
		First(&row).Error
	if err != nil {
		return models.StawiMemberStateNone
	}
	return row.State
}

// failFact makes the consumer fail the fact with this log position until cleared.
func (cf *chainFixture) failFact(block, log uint64) func() {
	key := business.LogKey(testChainID, txHash(block, log), log)
	failing := true
	business.SetApplyFault(cf.chain, func(f *models.StawiChainFact) error {
		if failing && f.FactKey == key {
			return errors.New("injected failure")
		}
		return nil
	})
	return func() { failing = false }
}

// TestAFailedFactHoldsBackTheMembersLaterFacts: an exit that fails holds back
// the same member's later invitation; once re-driven both apply, in order,
// and the member ends invited as the chain says.
func (s *MessageBusinessTestSuite) TestAFailedFactHoldsBackTheMembersLaterFacts() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.chain = cf.newChain(func(d *business.StawiChainDeps) { d.MaxFactAttempts = 1 })
		cf.deliver(t, f2(cf.activated()), f2(cf.stateChanged(cf.roomID, carolAddr, none, active, 9, 0)))

		healFact := cf.failFact(10, 0)
		name, exit := cf.stateChanged(cf.roomID, carolAddr, active, exited, 10, 0)
		_ = cf.chain.Receive(cf.ctx, name, exit) // fails and is quarantined
		name, invite := cf.invitation(carolAddr, false, 11, 0)
		_ = cf.chain.Receive(cf.ctx, name, invite)
		require.Equal(t, models.StawiMemberStateActive, cf.memberState(t, carolAddr),
			"the invitation waits behind the member's failed exit")

		healFact()
		_ = cf.chain.Redrive(cf.ctx, cf.roomID)
		require.Equal(t, models.StawiMemberStateInvited, cf.memberState(t, carolAddr))
		sub := cf.subscription(t, cf.carol.GetProfileId())
		require.NotNil(t, sub)
		require.Equal(t, models.RoomSubscriptionStateProposed, sub.SubscriptionState)
	})
}

// TestARevokedInvitationIsNotResurrected: an invitation that fails holds back
// its revocation; after re-drive the invitee ends with no subscription.
func (s *MessageBusinessTestSuite) TestARevokedInvitationIsNotResurrected() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.chain = cf.newChain(func(d *business.StawiChainDeps) { d.MaxFactAttempts = 1 })
		cf.deliver(t, f2(cf.activated()))

		healFact := cf.failFact(5, 0)
		name, invite := cf.invitation(carolAddr, false, 5, 0)
		_ = cf.chain.Receive(cf.ctx, name, invite)
		name, revoke := cf.invitation(carolAddr, true, 6, 0)
		_ = cf.chain.Receive(cf.ctx, name, revoke)

		healFact()
		_ = cf.chain.Redrive(cf.ctx, cf.roomID)
		require.Equal(t, models.StawiMemberStateNone, cf.memberState(t, carolAddr))
		sub := cf.subscription(t, cf.carol.GetProfileId())
		require.True(t, sub == nil || sub.SubscriptionState == models.RoomSubscriptionStateBlocked,
			"a revoked invitee has no live or proposed subscription")
	})
}

// TestAnotherMembersFactsAreNotHeldBack: while one member's fact is stuck,
// another member's exit still applies.
func (s *MessageBusinessTestSuite) TestAnotherMembersFactsAreNotHeldBack() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.chain = cf.newChain(func(d *business.StawiChainDeps) { d.MaxFactAttempts = 1 })
		cf.deliver(t, f2(cf.activated()),
			f2(cf.stateChanged(cf.roomID, bobAddr, none, active, 9, 0)),
			f2(cf.stateChanged(cf.roomID, carolAddr, none, active, 9, 1)))

		cf.failFact(10, 0)
		name, exit := cf.stateChanged(cf.roomID, carolAddr, active, exited, 10, 0)
		_ = cf.chain.Receive(cf.ctx, name, exit)
		name, bobExit := cf.stateChanged(cf.roomID, bobAddr, active, exited, 11, 0)
		_ = cf.chain.Receive(cf.ctx, name, bobExit)
		require.False(t, cf.live(t, cf.bob.GetProfileId()), "bob's exit is independent of carol's stuck fact")
		require.True(t, cf.live(t, cf.carol.GetProfileId()))
	})
}

// TestAnOutOfSyncFactFailsRatherThanVanishing: a revocation for a member chat
// believes active is not silently marked applied: it fails, visibly.
func (s *MessageBusinessTestSuite) TestAnOutOfSyncFactFailsRatherThanVanishing() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.deliver(t, f2(cf.activated()), f2(cf.stateChanged(cf.roomID, carolAddr, none, active, 9, 0)))
		name, revoke := cf.invitation(carolAddr, true, 12, 0)
		require.Error(t, cf.chain.Receive(cf.ctx, name, revoke))
		var stored models.StawiChainFact
		require.NoError(t, cf.dbPool.DB(cf.ctx, false).
			Where("fact_key = ?", business.LogKey(testChainID, txHash(12, 0), 0)).First(&stored).Error)
		require.False(t, stored.Applied)
		require.NotEmpty(t, stored.LastError)
	})
}

// TestKetoRepairNeverOverwritesALaterRemoval: a reconcile pass that saw a
// member's tuple missing must not re-grant it if the member exited between
// the pass's check and its repair.
func (s *MessageBusinessTestSuite) TestKetoRepairNeverOverwritesALaterRemoval() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		flaky := &flakyAuthz{Middleware: cf.authz}
		cf.chain = cf.newChain(func(d *business.StawiChainDeps) { d.Authz = flaky })
		cf.deliver(t, f2(cf.activated()),
			f2(cf.stateChanged(cf.roomID, aliceAddr, none, active, 9, 0)),
			f2(cf.stateChanged(cf.roomID, bobAddr, none, active, 9, 1)),
			f2(cf.stateChanged(cf.roomID, carolAddr, none, active, 9, 2)))
		carolSub := cf.subscription(t, cf.carol.GetProfileId()).GetID()
		require.NoError(t, cf.authz.RemoveRoomMember(cf.ctx, cf.roomID, carolSub)) // drift

		business.SetAfterReconcileLock(cf.chain, func() {
			business.SetAfterReconcileLock(cf.chain, nil)
			flaky.down.Store(true)
			name, exit := cf.stateChanged(cf.roomID, carolAddr, active, exited, 20, 0)
			_ = cf.chain.Receive(cf.ctx, name, exit) // row blocked; the Keto removal waits
			flaky.down.Store(false)
		})
		_, err := cf.chain.Reconcile(cf.ctx)
		require.NoError(t, err)
		cf.chain.Sweep(cf.ctx)

		require.False(t, cf.live(t, cf.carol.GetProfileId()))
		require.Error(t, cf.authz.CanRoomView(cf.ctx, carolSub, cf.roomID), "the exited member holds no tuple")
	})
}

// TestAReplayAfterPruningPostsNothingTwice: a governance fact redelivered
// after its row was pruned posts no second outcome.
func (s *MessageBusinessTestSuite) TestAReplayAfterPruningPostsNothingTwice() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.deliver(t, f2(cf.activated()))
		obs := f2(cf.callObserved(aliceAddr, 77, 30, 1))
		cf.deliver(t, obs)
		before := len(cf.outcomes(t))

		require.NoError(t, cf.dbPool.DB(cf.ctx, false).Exec(
			"UPDATE stawi_chain_facts SET applied_at = now() - interval '40 days' WHERE applied = true").Error)
		_, err := cf.store.PruneApplied(cf.ctx, cf.nowMinusDays(30))
		require.NoError(t, err)

		cf.deliver(t, obs)
		require.Len(t, cf.outcomes(t), before, "the replay is recognised")
	})
}
