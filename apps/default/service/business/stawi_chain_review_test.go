package business_test

import (
	"context"
	"errors"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	financev1 "buf.build/gen/go/stawi/finance/protocolbuffers/go/finance/v1"
	"github.com/pitabwire/frame/v2/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/proto"
	"gorm.io/gorm"

	"github.com/stawilabs/chat/apps/default/service/authz"
	"github.com/stawilabs/chat/apps/default/service/business"
	"github.com/stawilabs/chat/apps/default/service/models"
)

// address builds a distinct 20-byte chain address.
func address(tag byte, n byte) []byte {
	a := make([]byte, 20)
	a[0], a[19] = tag, n
	return a
}

// TestFactRecordedWhileItsRoomIsBoundIsPlaced: a membership fact recorded
// with no room while the room's activation binds it (on another replica)
// is still applied — when it races in, and from the sweep if it slipped
// through before its room existed in any lookup.
func (s *MessageBusinessTestSuite) TestFactRecordedWhileItsRoomIsBoundIsPlaced() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		const joiners = 6
		profiles := make([]string, joiners)
		facts := make([][]byte, joiners)
		for i := range joiners {
			profiles[i] = util.IDString()
			addr := address(0x70, byte(i+1))
			cf.accounts.Own(hexAddr(addr), profiles[i])
			_, facts[i] = cf.stateChanged("", addr, none, active, 60, uint64(i))
		}

		// Two handlers at once: the activation and the facts race.
		name, activation := cf.activated()
		var wg sync.WaitGroup
		errs := make([]error, joiners+1)
		wg.Add(joiners + 1)
		go func() { defer wg.Done(); errs[joiners] = cf.chain.Receive(cf.ctx, name, activation) }()
		for i := range joiners {
			go func() {
				defer wg.Done()
				errs[i] = cf.chain.Receive(cf.ctx, business.FactRoomMembershipObserved, facts[i])
			}()
		}
		wg.Wait()
		for _, err := range errs {
			require.NoError(t, err)
		}
		for _, profileID := range profiles {
			require.True(t, cf.live(t, profileID), "a fact that raced the binding is applied")
		}

		// A fact left unplaced (recorded before the binding was visible to it)
		// is placed by the sweep.
		late := &models.StawiChainFact{
			FactKey: "late:1", EventName: business.FactRoomMembershipObserved, CustodyAddress: hexAddr(custody),
			ChainID: testChainID, BlockNumber: 70, Payload: func() []byte {
				_, p := cf.stateChanged("", carolAddr, none, active, 70, 0)
				return p
			}(),
		}
		_, err := cf.store.Record(cf.ctx, late)
		require.NoError(t, err)
		require.False(t, cf.live(t, cf.carol.GetProfileId()))
		cf.chain.Sweep(cf.ctx)
		require.True(t, cf.live(t, cf.carol.GetProfileId()))
	})
}

// TestOneProfileWithTwoAccountsKeepsOneSubscription: a profile holding two
// accounts in the room has one subscription, kept while either account is a
// member; the reconciler leaves it alone.
func (s *MessageBusinessTestSuite) TestOneProfileWithTwoAccountsKeepsOneSubscription() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		second := address(0xca, 0x02)
		cf.accounts.Own(hexAddr(second), cf.carol.GetProfileId())
		cf.deliver(t,
			f2(cf.activated()),
			f2(cf.stateChanged(cf.roomID, aliceAddr, none, active, 79, 0)),
			f2(cf.stateChanged(cf.roomID, bobAddr, none, active, 79, 1)),
			f2(cf.stateChanged(cf.roomID, carolAddr, none, active, 80, 0)),
			f2(cf.stateChanged(cf.roomID, second, none, active, 80, 1)),
		)
		require.True(t, cf.live(t, cf.carol.GetProfileId()))

		// The first account exits; the second still holds the membership.
		cf.deliver(t, f2(cf.stateChanged(cf.roomID, carolAddr, active, exited, 81, 0)))
		require.True(t, cf.live(t, cf.carol.GetProfileId()), "the other account keeps the subscription")
		require.True(t, cf.canSend(cf.carol.GetProfileId()))

		for range 2 {
			report, err := cf.chain.Reconcile(cf.ctx)
			require.NoError(t, err)
			require.Zero(t, report.Repaired, "no flapping")
		}
		subs, err := cf.subRepo.GetAllByRoomID(cf.ctx, cf.roomID, nil)
		require.NoError(t, err)
		var carolSubs int
		for _, sub := range subs {
			if sub.ProfileID == cf.carol.GetProfileId() {
				carolSubs++
			}
		}
		require.Equal(t, 1, carolSubs)

		cf.deliver(t, f2(cf.stateChanged(cf.roomID, second, active, exited, 82, 0)))
		require.False(t, cf.live(t, cf.carol.GetProfileId()))
		require.False(t, cf.canView(cf.carol.GetProfileId()))
	})
}

// TestAFailingFactBacksOffThenIsQuarantined: an addition that keeps failing is
// retried on a time-based backoff (redeliveries in between do not count),
// quarantined at the limit while other members' facts keep applying, and
// re-driven by an operator once the cause is fixed.
func (s *MessageBusinessTestSuite) TestAFailingFactBacksOffThenIsQuarantined() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.chain = cf.newChain(func(d *business.StawiChainDeps) {
			d.MaxFactAttempts = 3
			d.FactRetryBackoff = time.Hour
		})
		cf.deliver(t, f2(cf.activated()),
			f2(cf.stateChanged(cf.roomID, bobAddr, none, active, 90, 0)),
			f2(cf.stateChanged(cf.roomID, carolAddr, none, active, 90, 1)))
		key := business.LogKey(testChainID, txHash(91, 0), 0)
		healFact := cf.failFact(91, 0)
		fact := func() models.StawiChainFact {
			var stored models.StawiChainFact
			require.NoError(t, cf.dbPool.DB(cf.ctx, false).Where("fact_key = ?", key).First(&stored).Error)
			return stored
		}

		name, grant := cf.roleChanged(carolAddr, true, 91, 0)
		require.Error(t, cf.chain.Receive(cf.ctx, name, grant))
		for range 3 { // redeliveries within the backoff do not count
			_ = cf.chain.Receive(cf.ctx, name, grant)
			require.NoError(t, cf.chain.ApplyRoom(cf.ctx, cf.roomID))
		}
		require.Equal(t, 1, fact().Attempts)
		require.NotEmpty(t, fact().LastError)

		// With the backoff elapsed, attempts count up to the quarantine.
		for range 2 {
			require.NoError(t, cf.dbPool.DB(cf.ctx, false).Exec(
				"UPDATE stawi_chain_facts SET next_attempt_at = now() - interval '1 second' WHERE fact_key = ?",
				key).Error)
			_ = cf.chain.ApplyRoom(cf.ctx, cf.roomID)
		}
		require.True(t, fact().Quarantined)
		require.Equal(t, 3, fact().Attempts)
		require.Equal(t, "member", cf.subscription(t, cf.carol.GetProfileId()).Role, "the grant has not applied")

		name, bobExit := cf.stateChanged(cf.roomID, bobAddr, active, exited, 92, 0)
		require.NoError(t, cf.chain.Receive(cf.ctx, name, bobExit))
		require.False(t, cf.live(t, cf.bob.GetProfileId()), "another member's exit still applies")

		healFact()
		require.NoError(t, cf.chain.Redrive(cf.ctx, cf.roomID))
		require.True(t, fact().Applied)
		require.Equal(t, "admin", cf.subscription(t, cf.carol.GetProfileId()).Role)
	})
}

// flakyAuthz fails Keto writes while down is set.
type flakyAuthz struct {
	authz.Middleware
	down atomic.Bool
}

func (f *flakyAuthz) SetRoomMemberRole(ctx context.Context, roomID, subscriptionID, role string) error {
	if f.down.Load() {
		return errors.New("keto down")
	}
	return f.Middleware.SetRoomMemberRole(ctx, roomID, subscriptionID, role)
}

func (f *flakyAuthz) RemoveRoomMember(ctx context.Context, roomID, subscriptionID string) error {
	if f.down.Load() {
		return errors.New("keto down")
	}
	return f.Middleware.RemoveRoomMember(ctx, roomID, subscriptionID)
}

// TestKetoOutageNeverLosesAWrite: with Keto down, the subscription rows still
// move (a removal takes effect in the database at once) and the Keto writes
// wait as ops until Keto is back.
func (s *MessageBusinessTestSuite) TestKetoOutageNeverLosesAWrite() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		flaky := &flakyAuthz{Middleware: cf.authz}
		cf.chain = cf.newChain(func(d *business.StawiChainDeps) { d.Authz = flaky })
		cf.deliver(t, f2(cf.activated()), f2(cf.stateChanged(cf.roomID, carolAddr, none, active, 95, 0)))
		require.True(t, cf.canSend(cf.carol.GetProfileId()))

		flaky.down.Store(true)
		cf.deliver(t, f2(cf.stateChanged(cf.roomID, carolAddr, active, exited, 96, 0)))
		require.False(t, cf.live(t, cf.carol.GetProfileId()), "the database refuses the member at once")
		carolSub := cf.subscription(t, cf.carol.GetProfileId()).GetID()
		require.NoError(t, cf.authz.CanRoomView(cf.ctx, carolSub, cf.roomID), "the Keto removal is still pending")

		flaky.down.Store(false)
		cf.chain.Sweep(cf.ctx)
		require.Error(t, cf.authz.CanRoomView(cf.ctx, carolSub, cf.roomID), "the pending removal landed")
		var pending int64
		require.NoError(t, cf.dbPool.DB(cf.ctx, false).Table("stawi_keto_ops").Count(&pending).Error)
		require.Zero(t, pending)
	})
}

// TestSweepRunsOnOneReplicaAtATime: the sweep lease is exclusive.
func (s *MessageBusinessTestSuite) TestSweepRunsOnOneReplicaAtATime() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		var inner bool
		held, err := cf.store.TryLease(cf.ctx, "sweep", func(ctx context.Context) {
			var innerErr error
			inner, innerErr = cf.store.TryLease(ctx, "sweep", func(context.Context) {})
			require.NoError(t, innerErr)
		})
		require.NoError(t, err)
		require.True(t, held)
		require.False(t, inner, "a second replica does not get the lease")
	})
}

// TestReconcilerRotatesThroughBoundRooms: each pass handles a bounded share
// and the next pass continues where it stopped.
func (s *MessageBusinessTestSuite) TestReconcilerRotatesThroughBoundRooms() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.chain = cf.newChain(func(d *business.StawiChainDeps) { d.ReconcileRoomsPerPass = 1 })
		cf.deliver(t, f2(cf.activated()))
		second := cf.otherRoom(t, true)
		pending, err := cf.bindings.GetByID(cf.ctx, second)
		require.NoError(t, err)
		b, _ := proto.Marshal(&financev1.RoomActivated{
			Meta: meta(second), RoomId: second, ChainId: testChainID, CustodyAddress: otherCustody,
			GovernanceAddress: otherGovernor, GenesisId: pending.GenesisID, ChatRoomId: second,
		})
		cf.deliver(t, f2(business.FactRoomActivated, b))

		seen := map[int]int{}
		for pass := range 4 {
			report, reconcileErr := cf.chain.Reconcile(cf.ctx)
			require.NoError(t, reconcileErr)
			require.LessOrEqual(t, report.Rooms, 1, "bounded per pass")
			seen[pass%2] += report.Rooms
		}
		require.Positive(t, seen[0])
		require.Positive(t, seen[1])
	})
}

// TestWaitingRoomsAndStaleCallsAreServedLeastRecentlyTriedFirst keeps a room
// whose facts keep failing from starving the others.
func (s *MessageBusinessTestSuite) TestWaitingRoomsAndStaleCallsAreServedLeastRecentlyTriedFirst() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		tried, fresh := util.IDString(), util.IDString()
		for _, roomID := range []string{tried, fresh} {
			_, err := cf.store.Record(cf.ctx, &models.StawiChainFact{FactKey: "wait:" + roomID, RoomID: roomID,
				EventName: business.FactRoomMembershipObserved, CustodyAddress: "0x01", Payload: []byte{1}})
			require.NoError(t, err)
		}
		var fact models.StawiChainFact
		require.NoError(t, cf.dbPool.DB(cf.ctx, false).Where("fact_key = ?", "wait:"+tried).First(&fact).Error)
		require.NoError(t, cf.dbPool.DB(cf.ctx, false).Transaction(func(tx *gorm.DB) error {
			_, recErr := cf.store.RecordFailure(tx, &fact, errors.New("boom"), 10, 0, time.Hour)
			return recErr
		}))
		rooms, err := cf.store.RoomsWithPending(cf.ctx, 10)
		require.NoError(t, err)
		require.Equal(t, []string{fresh, tried}, rooms)

		before := time.Now().Add(time.Hour)
		for _, id := range []string{"call-old", "call-new"} {
			c := &models.StawiRoomCall{RoomID: cf.roomID, SignerAddress: "0xa", State: models.StawiCallStateSubmitted}
			c.ID = id
			require.NoError(t, cf.calls.Record(cf.ctx, c))
		}
		require.NoError(t, cf.calls.MarkChecked(cf.ctx, "call-old"))
		calls, err := cf.calls.ListSubmittedBefore(cf.ctx, before, 10)
		require.NoError(t, err)
		require.Equal(t, "call-new", calls[0].GetID(), "never-checked calls first")
	})
}

// TestAppliedFactsArePrunedAfterRetention.
func (s *MessageBusinessTestSuite) TestAppliedFactsArePrunedAfterRetention() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.deliver(t, f2(cf.activated()),
			f2(cf.stateChanged(cf.roomID, aliceAddr, none, active, 98, 0)),
			f2(cf.stateChanged(cf.roomID, bobAddr, none, active, 98, 1)),
			f2(cf.stateChanged(cf.roomID, carolAddr, none, active, 99, 0)))
		require.NoError(t, cf.dbPool.DB(cf.ctx, false).Exec(
			"UPDATE stawi_chain_facts SET applied_at = now() - interval '40 days' WHERE applied = true").Error)
		pruned, err := cf.store.PruneApplied(cf.ctx, time.Now().Add(-30*24*time.Hour))
		require.NoError(t, err)
		require.Positive(t, pruned)
		require.True(t, cf.live(t, cf.carol.GetProfileId()), "membership survives pruning")
		report, err := cf.chain.Reconcile(cf.ctx)
		require.NoError(t, err)
		require.Zero(t, report.Repaired)
	})
}
