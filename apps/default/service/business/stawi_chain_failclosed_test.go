package business_test

import (
	"testing"

	"connectrpc.com/connect/v2"
	"github.com/pitabwire/frame/v3/frametests/definition"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/service/business"
	"github.com/stawilabs/chat/apps/default/service/models"
)

// stuckChain quarantines a failing addition at its first failure.
func (cf *chainFixture) stuckChain() {
	cf.chain = cf.newChain(func(d *business.StawiChainDeps) { d.MaxFactAttempts = 1 })
}

// TestAnExitBehindAStuckRoleGrantRemovesAccessNow: a member's role grant is
// stuck (quarantined); their exit, a later fact, takes effect at once — the
// subscription is blocked and the Keto tuples removed — and re-driving the
// grant afterwards does not give access back.
func (s *MessageBusinessTestSuite) TestAnExitBehindAStuckRoleGrantRemovesAccessNow() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.stuckChain()
		cf.deliver(t, f2(cf.activated()), f2(cf.stateChanged(cf.roomID, carolAddr, none, active, 9, 0)))
		carolSub := cf.subscription(t, cf.carol.GetProfileId()).GetID()

		healFact := cf.failFact(10, 0)
		name, grant := cf.roleChanged(carolAddr, true, 10, 0)
		_ = cf.chain.Receive(cf.ctx, name, grant) // stuck
		name, exit := cf.stateChanged(cf.roomID, carolAddr, active, exited, 11, 0)
		_ = cf.chain.Receive(cf.ctx, name, exit)

		require.False(t, cf.live(t, cf.carol.GetProfileId()), "the exit applies despite the stuck grant")
		require.Error(t, cf.authz.CanRoomView(cf.ctx, carolSub, cf.roomID), "and the Keto access is gone")

		healFact()
		_ = cf.chain.Redrive(cf.ctx, cf.roomID)
		require.False(t, cf.live(t, cf.carol.GetProfileId()), "re-driving the grant restores nothing")
		require.Error(t, cf.authz.CanRoomView(cf.ctx, carolSub, cf.roomID))
		require.Equal(t, models.StawiMemberStateExited, cf.memberState(t, carolAddr))
	})
}

// TestAnExitBehindAStuckInvitationIsFinal: an invitation is stuck and the
// member's join waits behind it; their exit applies, and after re-drive the
// member has no subscription at all.
func (s *MessageBusinessTestSuite) TestAnExitBehindAStuckInvitationIsFinal() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.stuckChain()
		cf.deliver(t, f2(cf.activated()))

		healFact := cf.failFact(10, 0)
		name, invite := cf.invitation(carolAddr, false, 10, 0)
		_ = cf.chain.Receive(cf.ctx, name, invite)
		name, join := cf.stateChanged(cf.roomID, carolAddr, none, active, 11, 0)
		_ = cf.chain.Receive(cf.ctx, name, join)
		require.False(t, cf.live(t, cf.carol.GetProfileId()), "the join (an addition) waits behind the invitation")
		name, exit := cf.stateChanged(cf.roomID, carolAddr, active, exited, 12, 0)
		_ = cf.chain.Receive(cf.ctx, name, exit)

		healFact()
		_ = cf.chain.Redrive(cf.ctx, cf.roomID)
		require.Equal(t, models.StawiMemberStateExited, cf.memberState(t, carolAddr))
		sub := cf.subscription(t, cf.carol.GetProfileId())
		require.True(t, sub == nil || sub.SubscriptionState == models.RoomSubscriptionStateBlocked)
	})
}

// TestASuspensionAndARoleRevocationApplyBehindStuckFacts: reductions short of
// an exit are immediate too: a suspension lowers the member to reading, a
// role revocation drops admin, and re-driving an older grant of the same role
// does not restore it.
func (s *MessageBusinessTestSuite) TestASuspensionAndARoleRevocationApplyBehindStuckFacts() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.stuckChain()
		cf.deliver(t, f2(cf.activated()),
			f2(cf.stateChanged(cf.roomID, carolAddr, none, active, 9, 0)),
			f2(cf.roleChanged(carolAddr, true, 9, 1)))
		require.Equal(t, "admin", cf.subscription(t, cf.carol.GetProfileId()).Role)

		healFact := cf.failFact(10, 0)
		name, regrant := cf.roleChanged(carolAddr, true, 10, 0)
		_ = cf.chain.Receive(cf.ctx, name, regrant) // stuck
		name, revoke := cf.roleChanged(carolAddr, false, 11, 0)
		_ = cf.chain.Receive(cf.ctx, name, revoke)
		require.Equal(t, "member", cf.subscription(t, cf.carol.GetProfileId()).Role, "the revocation is immediate")

		name, suspend := cf.stateChanged(cf.roomID, carolAddr, active, suspend, 12, 0)
		_ = cf.chain.Receive(cf.ctx, name, suspend)
		require.Equal(t, "guest", cf.subscription(t, cf.carol.GetProfileId()).Role)
		require.False(t, cf.canSend(cf.carol.GetProfileId()))

		healFact()
		_ = cf.chain.Redrive(cf.ctx, cf.roomID)
		require.Equal(t, "guest", cf.subscription(t, cf.carol.GetProfileId()).Role,
			"re-driving the older grant changes nothing")
	})
}

// TestARevocationIsNeverQuarantined: a reduction that keeps failing is
// retried for as long as it fails — it is never set aside behind an operator
// — so the access it removes cannot linger unnoticed.
func (s *MessageBusinessTestSuite) TestARevocationIsNeverQuarantined() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.stuckChain()
		cf.deliver(t, f2(cf.activated()), f2(cf.stateChanged(cf.roomID, carolAddr, none, active, 9, 0)))

		healFact := cf.failFact(10, 0)
		name, exit := cf.stateChanged(cf.roomID, carolAddr, active, exited, 10, 0)
		require.Error(t, cf.chain.Receive(cf.ctx, name, exit))
		var stored models.StawiChainFact
		require.NoError(t, cf.dbPool.DB(cf.ctx, false).
			Where("fact_key = ?", business.LogKey(testChainID, txHash(10, 0), 0)).First(&stored).Error)
		require.False(t, stored.Quarantined, "a revocation is retried, not quarantined")

		healFact()
		require.NoError(t, cf.dbPool.DB(cf.ctx, false).Exec(
			"UPDATE stawi_chain_facts SET next_attempt_at = NULL WHERE id = ?", stored.GetID()).Error)
		cf.chain.Sweep(cf.ctx)
		require.False(t, cf.live(t, cf.carol.GetProfileId()))
	})
}

// TestRevocationsApplyWhileProfileIsDown: with the profile service down, a
// known member's exit still applies (it needs no lookup); only facts that
// need one wait, and the delivery reports the outage.
func (s *MessageBusinessTestSuite) TestRevocationsApplyWhileProfileIsDown() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.deliver(t, f2(cf.activated()), f2(cf.stateChanged(cf.roomID, carolAddr, none, active, 9, 0)))

		stranger := address(0x5e, 1)
		cf.accounts.Fail(connect.NewError(connect.CodeUnavailable, "profile down"))
		name, join := cf.stateChanged(cf.roomID, stranger, none, active, 10, 0)
		require.Error(t, cf.chain.Receive(cf.ctx, name, join), "the join needs a lookup and waits")
		name, exit := cf.stateChanged(cf.roomID, carolAddr, active, exited, 11, 0)
		_ = cf.chain.Receive(cf.ctx, name, exit)
		require.False(t, cf.live(t, cf.carol.GetProfileId()), "the known member's exit did not wait for profile")
	})
}
