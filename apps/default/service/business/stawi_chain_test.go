package business_test

import (
	"context"
	"errors"
	"sync"
	"testing"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	financev1 "buf.build/gen/go/stawi/finance/protocolbuffers/go/finance/v1"
	"connectrpc.com/connect"
	"github.com/pitabwire/frame/v2/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/proto"

	"github.com/stawilabs/chat/apps/default/service/business"
	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/service/stawi"
)

const testChainID = 84532

// Addresses of the fixture's members on chain.
//
//nolint:gochecknoglobals // immutable test fixtures
var (
	aliceAddr = []byte{0xa1, 0x1c, 0xe0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x01}
	bobAddr   = []byte{0xb0, 0xb0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x02}
	carolAddr = []byte{0xca, 0x01, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x03}
	custody   = []byte{0xc0, 0x57, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x04}
	governor  = []byte{0x60, 0x7e, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x05}
	officer   = make([]byte, 32)
)

// recordingDrift collects drift reports.
type recordingDrift struct {
	mu      sync.Mutex
	reports []business.StawiDrift
}

func (r *recordingDrift) PublishDrift(_ context.Context, drift business.StawiDrift) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.reports = append(r.reports, drift)
	return nil
}

func (r *recordingDrift) all() []business.StawiDrift {
	r.mu.Lock()
	defer r.mu.Unlock()
	return append([]business.StawiDrift(nil), r.reports...)
}

type chainFixture struct {
	*stawiFixture
	chain     *business.StawiChain
	store     repository.StawiChainStore
	drift     *recordingDrift
	carol     *commonv1.ContactLink
	genesisID string
}

func (s *MessageBusinessTestSuite) newChainFixture(t *testing.T, dep *definition.DependencyOption) *chainFixture {
	t.Helper()
	f := s.newStawiFixture(t, dep)
	dbPool := f.dbPool
	cf := &chainFixture{
		stawiFixture: f,
		store:        repository.NewStawiChainStore(dbPool),
		drift:        &recordingDrift{},
		carol:        &commonv1.ContactLink{ProfileId: util.IDString()},
	}
	f.accounts.Own(hexAddr(aliceAddr), f.alice.GetProfileId())
	f.accounts.Own(hexAddr(bobAddr), f.bob.GetProfileId())
	f.accounts.Own(hexAddr(carolAddr), cf.carol.GetProfileId())
	// The room's owner converts it, as every binding requires.
	requireAckOK(t, f.send(t, f.alice, conversion(f.aliceSub, f.bobSub)))
	pending, err := f.bindings.GetByID(f.ctx, f.roomID)
	require.NoError(t, err)
	cf.genesisID = pending.GenesisID
	cf.chain = business.NewStawiChain(business.StawiChainDeps{
		Pool:     dbPool,
		RoomRepo: repository.NewRoomRepository(f.ctx, dbPool, f.workMan),
		SubRepo:  f.subRepo,
		Bindings: f.bindings,
		Calls:    f.calls,
		Store:    cf.store,
		Accounts: f.accounts,
		Rooms:    f.rooms,
		Authz:    s.AuthzMiddleware,
		Drift:    cf.drift,
	})
	return cf
}

func hexAddr(b []byte) string { return business.HexAddress(b) }

func meta(roomID string) *financev1.EventMeta {
	return &financev1.EventMeta{EventId: util.IDString(), AggregateType: "room", AggregateId: roomID, RoomId: roomID}
}

func (cf *chainFixture) activated() (string, []byte) {
	return cf.activatedFor(cf.genesisID, cf.roomID)
}

// activatedFor is room.activated naming a genesis and a chat room.
func (cf *chainFixture) activatedFor(genesisID, chatRoomID string) (string, []byte) {
	b, _ := proto.Marshal(&financev1.RoomActivated{
		Meta: meta(cf.roomID), RoomId: cf.roomID, ChainId: testChainID,
		CustodyAddress: custody, GovernanceAddress: governor, PolicyEpoch: 1,
		GenesisId: genesisID, ChatRoomId: chatRoomID,
	})
	return business.FactRoomActivated, b
}

func (cf *chainFixture) stateChanged(roomID string, member []byte, from, to financev1.RoomMemberState,
	block, log uint64,
) (string, []byte) {
	b, _ := proto.Marshal(&financev1.RoomMembershipObserved{
		Meta: meta(roomID), ChainId: testChainID, CustodyAddress: custody,
		Event:  financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_MEMBER_STATE_CHANGED,
		Member: member, FromState: from, ToState: to,
		TxHash: txHash(block, log), BlockNumber: block, LogIndex: log, RoomId: roomID,
	})
	return business.FactRoomMembershipObserved, b
}

func (cf *chainFixture) roleChanged(member []byte, assigned bool, block, log uint64) (string, []byte) {
	b, _ := proto.Marshal(&financev1.RoomMembershipObserved{
		Meta: meta(cf.roomID), ChainId: testChainID, CustodyAddress: custody,
		Event:  financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_ROLE_CHANGED,
		Member: member, RoleId: officer, RoleAssigned: assigned, RoleCapabilities: 1,
		TxHash: txHash(block, log), BlockNumber: block, LogIndex: log, RoomId: cf.roomID,
	})
	return business.FactRoomMembershipObserved, b
}

func (cf *chainFixture) callObserved(member []byte, nonce, block, log uint64) (string, []byte) {
	b, _ := proto.Marshal(&financev1.GovernanceCallObserved{
		Meta: meta(cf.roomID), ChainId: testChainID, Emitter: governor,
		Event:      financev1.GovernanceChainEvent_GOVERNANCE_CHAIN_EVENT_VOTE_CAST,
		CallKind:   financev1.GovernanceCallKind_GOVERNANCE_CALL_KIND_CAST_VOTE,
		CallMember: member, CallNonce: nonce,
		TxHash: txHash(block, log), BlockNumber: block, LogIndex: log, RoomId: cf.roomID,
	})
	return business.FactGovernanceCallObserved, b
}

func txHash(block, log uint64) []byte {
	h := make([]byte, 32)
	h[0], h[1] = byte(block), byte(log)
	return h
}

const (
	active  = financev1.RoomMemberState_ROOM_MEMBER_STATE_ACTIVE
	none    = financev1.RoomMemberState_ROOM_MEMBER_STATE_UNSPECIFIED
	exited  = financev1.RoomMemberState_ROOM_MEMBER_STATE_EXITED
	suspend = financev1.RoomMemberState_ROOM_MEMBER_STATE_SUSPENDED
)

type fact struct {
	name    string
	payload []byte
}

func f2(name string, payload []byte) fact { return fact{name, payload} }

func (cf *chainFixture) deliver(t *testing.T, facts ...fact) {
	t.Helper()
	for _, fc := range facts {
		require.NoError(t, cf.chain.Receive(cf.ctx, fc.name, fc.payload))
	}
}

// subscription returns the member's subscription in the room, active or not.
func (cf *chainFixture) subscription(t *testing.T, profileID string) *models.RoomSubscription {
	t.Helper()
	subs, err := cf.subRepo.GetAllByRoomID(cf.ctx, cf.roomID, nil)
	require.NoError(t, err)
	var found *models.RoomSubscription
	for _, sub := range subs {
		if sub.ProfileID == profileID && (found == nil || sub.IsActive()) {
			found = sub
		}
	}
	return found
}

// live reports whether the member has an active subscription in the room.
func (cf *chainFixture) live(t *testing.T, profileID string) bool {
	t.Helper()
	sub := cf.subscription(t, profileID)
	return sub != nil && sub.IsActive()
}

func (cf *chainFixture) canSend(profileID string) bool {
	sub := cf.subscriptionOfProfile(profileID)
	if sub == nil {
		return false
	}
	return cf.authz.CanMessageSend(cf.ctx, sub.GetID(), cf.roomID) == nil
}

func (cf *chainFixture) canView(profileID string) bool {
	sub := cf.subscriptionOfProfile(profileID)
	if sub == nil {
		return false
	}
	return cf.authz.CanRoomView(cf.ctx, sub.GetID(), cf.roomID) == nil
}

func (cf *chainFixture) subscriptionOfProfile(profileID string) *models.RoomSubscription {
	subs, err := cf.subRepo.GetByContactLinkAndRooms(cf.ctx, &commonv1.ContactLink{ProfileId: profileID}, cf.roomID)
	if err != nil || len(subs) == 0 {
		return nil
	}
	return subs[0]
}

func (cf *chainFixture) outcomes(t *testing.T) []*chatv1.StawiCallOutcomeContent {
	t.Helper()
	var out []*chatv1.StawiCallOutcomeContent
	for _, evt := range cf.history(t) {
		if o := evt.GetPayload().GetStawiCallOutcome(); o != nil {
			out = append(out, o)
		}
	}
	return out
}

func (cf *chainFixture) eventCount(t *testing.T) int {
	t.Helper()
	return len(cf.history(t))
}

// TestChainActivationBindsTheRoom: room.activated binds the chat room to its
// custody and tells the room the genesis landed.
func (s *MessageBusinessTestSuite) TestChainActivationBindsTheRoom() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		pending, err := cf.bindings.GetByID(cf.ctx, cf.roomID)
		require.NoError(t, err)

		cf.deliver(t, f2(cf.activated()))

		bound, err := cf.bindings.GetByID(cf.ctx, cf.roomID)
		require.NoError(t, err)
		require.True(t, bound.IsBound())
		require.Equal(t, hexAddr(custody), bound.CustodyAddress)
		require.Equal(t, hexAddr(governor), bound.GovernanceAddress)
		require.EqualValues(t, testChainID, bound.ChainID)

		outcomes := cf.outcomes(t)
		require.Len(t, outcomes, 1)
		require.Equal(t, chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_OBSERVED, outcomes[0].GetState())
		require.Equal(t, pending.GenesisID, outcomes[0].GetGenesisId())
		require.Equal(t, pending.GenesisEventID, outcomes[0].GetSourceEventId())

		// A second activation for another custody cannot rebind the room.
		b, _ := proto.Marshal(&financev1.RoomActivated{
			Meta: meta(cf.roomID), RoomId: cf.roomID, ChainId: testChainID,
			CustodyAddress: carolAddr, GovernanceAddress: governor,
		})
		require.Error(t, cf.chain.Receive(cf.ctx, business.FactRoomActivated, b))
		still, err := cf.bindings.GetByID(cf.ctx, cf.roomID)
		require.NoError(t, err)
		require.Equal(t, hexAddr(custody), still.CustodyAddress)
	})
}

// TestChainMembershipWritesSubscriptionsAndRoles: membership facts write the
// room's subscriptions and Keto tuples through one path: existing chat
// subscriptions are reused, a member new to chat gets one, an officer role
// makes an admin, suspension leaves a reader, exit removes.
func (s *MessageBusinessTestSuite) TestChainMembershipWritesSubscriptionsAndRoles() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.deliver(t,
			f2(cf.activated()),
			f2(cf.stateChanged(cf.roomID, aliceAddr, none, active, 10, 1)),
			f2(cf.stateChanged(cf.roomID, bobAddr, none, active, 10, 2)),
			f2(cf.roleChanged(aliceAddr, true, 10, 3)),
			f2(cf.stateChanged(cf.roomID, carolAddr, none, active, 11, 0)),
		)

		require.Equal(t, cf.aliceSub, cf.subscription(t, cf.alice.GetProfileId()).GetID(), "reused")
		require.Equal(t, "admin", cf.subscription(t, cf.alice.GetProfileId()).Role)
		require.Equal(t, "member", cf.subscription(t, cf.bob.GetProfileId()).Role)
		carolSub := cf.subscription(t, cf.carol.GetProfileId())
		require.NotNil(t, carolSub)
		require.True(t, carolSub.IsActive())
		require.True(t, cf.canSend(cf.carol.GetProfileId()), "the Keto tuple is written with the row")

		cf.deliver(t,
			f2(cf.stateChanged(cf.roomID, bobAddr, active, suspend, 12, 0)),
			f2(cf.stateChanged(cf.roomID, carolAddr, active, exited, 12, 1)),
			f2(cf.roleChanged(aliceAddr, false, 12, 2)),
		)
		require.Equal(t, "guest", cf.subscription(t, cf.bob.GetProfileId()).Role)
		require.True(t, cf.canView(cf.bob.GetProfileId()))
		require.False(t, cf.canSend(cf.bob.GetProfileId()), "a suspended member reads but cannot send")
		require.False(t, cf.subscription(t, cf.carol.GetProfileId()).IsActive())
		require.False(t, cf.canView(cf.carol.GetProfileId()))
		require.Equal(t, "member", cf.subscription(t, cf.alice.GetProfileId()).Role)
	})
}

// TestChainFactsAreIdempotentAndOrdered: duplicates, a reordered delivery and
// a full replay leave the same state, and post each room event once.
func (s *MessageBusinessTestSuite) TestChainFactsAreIdempotentAndOrdered() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		joined := f2(cf.stateChanged(cf.roomID, carolAddr, none, active, 20, 4))
		left := f2(cf.stateChanged(cf.roomID, carolAddr, active, exited, 21, 0))
		promoted := f2(cf.roleChanged(bobAddr, true, 22, 0))
		bobActive := f2(cf.stateChanged(cf.roomID, bobAddr, none, active, 19, 0))

		// Reordered: carol's exit and bob's role arrive before the facts they follow.
		cf.deliver(t, f2(cf.activated()), left, promoted, joined, bobActive)
		require.False(t, cf.live(t, cf.carol.GetProfileId()),
			"the later exit wins over the earlier join, whatever the arrival order")
		require.Equal(t, "admin", cf.subscription(t, cf.bob.GetProfileId()).Role)

		events := cf.eventCount(t)
		subs, err := cf.subRepo.GetAllByRoomID(cf.ctx, cf.roomID, nil)
		require.NoError(t, err)

		// Duplicates and a full replay change nothing and post nothing.
		cf.deliver(t, joined, joined, left, promoted, bobActive, f2(cf.activated()))
		cf.deliver(t, f2(cf.activated()), bobActive, joined, left, promoted)
		require.Equal(t, events, cf.eventCount(t))
		again, err := cf.subRepo.GetAllByRoomID(cf.ctx, cf.roomID, nil)
		require.NoError(t, err)
		require.Len(t, again, len(subs))
		require.False(t, cf.live(t, cf.carol.GetProfileId()))
	})
}

// TestChainFactsWaitForTheirRoom: membership that arrives before activation,
// naming only the custody, is applied once activation tells chat the room.
func (s *MessageBusinessTestSuite) TestChainFactsWaitForTheirRoom() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.deliver(t, f2(cf.stateChanged("", carolAddr, none, active, 5, 0)))
		require.Nil(t, cf.subscription(t, cf.carol.GetProfileId()))

		cf.deliver(t, f2(cf.activated()))
		require.True(t, cf.subscription(t, cf.carol.GetProfileId()).IsActive())
	})
}

// TestChainNeverSkipsAFactWhenProfileIsDown: if addresses cannot be resolved
// the fact is not applied and the delivery fails, so the queue redelivers.
func (s *MessageBusinessTestSuite) TestChainNeverSkipsAFactWhenProfileIsDown() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.deliver(t, f2(cf.activated()))
		cf.accounts.Fail(connect.NewError(connect.CodeUnavailable, errors.New("profile down")))
		name, payload := cf.stateChanged(cf.roomID, carolAddr, none, active, 7, 0)
		require.Error(t, cf.chain.Receive(cf.ctx, name, payload))
		require.Nil(t, cf.subscription(t, cf.carol.GetProfileId()))

		cf.accounts.Fail(nil)
		require.NoError(t, cf.chain.Receive(cf.ctx, name, payload))
		require.True(t, cf.subscription(t, cf.carol.GetProfileId()).IsActive())
	})
}

// TestChainObservedCallIsReportedAgainstItsAct: governance.call_observed for a
// call chat relayed posts an OBSERVED outcome replying to the act.
func (s *MessageBusinessTestSuite) TestChainObservedCallIsReportedAgainstItsAct() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.deliver(t, f2(cf.activated()))
		cf.rooms.AddCall(stawi.RoomCall{CallID: "call-vote", RoomID: cf.roomID, Kind: "CAST_VOTE",
			SignerAddress: hexAddr(aliceAddr), Nonce: 9})
		actID := requireAckOK(t, cf.send(t, cf.alice, signedCall("call-vote", "CAST_VOTE")))

		obs := f2(cf.callObserved(aliceAddr, 9, 30, 1))
		cf.deliver(t, obs, obs)

		var observed []*chatv1.StawiCallOutcomeContent
		for _, o := range cf.outcomes(t) {
			if o.GetState() == chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_OBSERVED {
				observed = append(observed, o)
			}
		}
		require.Len(t, observed, 2, "activation and the vote, each once")
		var vote *chatv1.StawiCallOutcomeContent
		for _, o := range observed {
			if o.GetKind() == "VOTE_CAST" {
				vote = o
			}
		}
		require.NotNil(t, vote)
		require.Equal(t, "call-vote", vote.GetCallId())
		require.Equal(t, actID, vote.GetSourceEventId())
		require.EqualValues(t, 30, vote.GetBlockNumber())

		call, err := cf.calls.GetByID(cf.ctx, "call-vote")
		require.NoError(t, err)
		require.Equal(t, models.StawiCallStateObserved, call.State)
	})
}

// TestReconcilerRepairsDrift: when chat's subscriptions or Keto tuples drift
// from the chain's membership, the reconciler restores them and reports it.
func (s *MessageBusinessTestSuite) TestReconcilerRepairsDrift() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.deliver(t,
			f2(cf.activated()),
			f2(cf.stateChanged(cf.roomID, aliceAddr, none, active, 10, 1)),
			f2(cf.stateChanged(cf.roomID, bobAddr, none, active, 10, 2)),
		)
		report, err := cf.chain.Reconcile(cf.ctx)
		require.NoError(t, err)
		require.Zero(t, report.Repaired, "nothing to repair")
		require.Empty(t, cf.drift.all())

		// Drift: alice's row deactivated behind the chain's back, bob's Keto
		// tuple lost, and a stray subscription for someone the chain never admitted.
		require.NoError(t, cf.subRepo.Deactivate(cf.ctx, cf.aliceSub))
		require.NoError(t, s.AuthzMiddleware.RemoveRoomMember(cf.ctx, cf.roomID, cf.bobSub))
		stray := &models.RoomSubscription{RoomID: cf.roomID, ProfileID: util.IDString(), Role: "member",
			SubscriptionState: models.RoomSubscriptionStateActive}
		stray.GenID(cf.ctx)
		require.NoError(t, cf.subRepo.Create(cf.ctx, stray))
		require.NoError(t, s.AuthzMiddleware.AddRoomMember(cf.ctx, cf.roomID, stray.GetID(), "member"))

		report, err = cf.chain.Reconcile(cf.ctx)
		require.NoError(t, err)
		require.Equal(t, 3, report.Repaired)

		require.True(t, cf.subscription(t, cf.alice.GetProfileId()).IsActive())
		require.True(t, cf.canSend(cf.alice.GetProfileId()))
		require.True(t, cf.canSend(cf.bob.GetProfileId()))
		strayNow, err := cf.subRepo.GetByID(cf.ctx, stray.GetID())
		require.NoError(t, err)
		require.False(t, strayNow.IsActive())
		require.Error(t, s.AuthzMiddleware.CanRoomView(cf.ctx, stray.GetID(), cf.roomID))

		drift := cf.drift.all()
		require.Len(t, drift, 1)
		require.Equal(t, cf.roomID, drift[0].RoomID)
		require.Equal(t, 1, drift[0].Restored)
		require.Equal(t, 1, drift[0].Removed)
		require.Equal(t, 1, drift[0].PermissionsRepaired)

		report, err = cf.chain.Reconcile(cf.ctx)
		require.NoError(t, err)
		require.Zero(t, report.Repaired, "repair is stable")
	})
}

// TestStaleCallOutcomeComesOnlyFromItsOwnRoomsCall: the reconciler settles a
// relayed call from settlement's record only when that record is for the
// call's room.
func (s *MessageBusinessTestSuite) TestStaleCallOutcomeComesOnlyFromItsOwnRoomsCall() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.deliver(t, f2(cf.activated()))
		cf.chain = business.NewStawiChain(business.StawiChainDeps{
			Pool: cf.dbPool, RoomRepo: repository.NewRoomRepository(cf.ctx, cf.dbPool, cf.workMan),
			SubRepo: cf.subRepo, Bindings: cf.bindings, Calls: cf.calls, Store: cf.store,
			Accounts: cf.accounts, Rooms: cf.rooms, Authz: cf.authz, Drift: cf.drift,
			StaleCallAfter: 1,
		})
		for _, id := range []string{"call-a", "call-b"} {
			cf.rooms.AddCall(stawi.RoomCall{CallID: id, RoomID: cf.roomID, Kind: "INVITE",
				SignerAddress: hexAddr(aliceAddr), Nonce: map[string]uint64{"call-a": 1, "call-b": 2}[id]})
			requireAckOK(t, cf.send(t, cf.alice, signedCall(id, "INVITE")))
		}
		// Settlement now reports call-a under another room (a mismatch), and
		// call-b final for this room.
		cf.rooms.AddCall(stawi.RoomCall{CallID: "call-a", RoomID: util.IDString(), Kind: "INVITE",
			SignerAddress: hexAddr(aliceAddr), Nonce: 1, State: stawi.CallStateFinal})
		cf.rooms.SetCallState("call-b", stawi.CallStateFinal, "")

		report, err := cf.chain.Reconcile(cf.ctx)
		require.NoError(t, err)
		require.Equal(t, 1, report.CallsResolved)

		a, err := cf.calls.GetByID(cf.ctx, "call-a")
		require.NoError(t, err)
		require.Equal(t, models.StawiCallStateSubmitted, a.State)
		b, err := cf.calls.GetByID(cf.ctx, "call-b")
		require.NoError(t, err)
		require.Equal(t, models.StawiCallStateObserved, b.State)
	})
}

// TestChainDropsADeliveryWhoseHeaderDisagreesWithTheFact: a delivery is taken
// only when the event id settlement's relay put in the header is the fact's
// own; anything else is dropped unapplied.
func (s *MessageBusinessTestSuite) TestChainDropsADeliveryWhoseHeaderDisagreesWithTheFact() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		var activated financev1.RoomActivated
		name, payload := cf.activated()
		require.NoError(t, proto.Unmarshal(payload, &activated))

		require.NoError(t, cf.chain.ReceiveDelivery(cf.ctx, name, util.IDString(), payload))
		bound, err := cf.bindings.IsBound(cf.ctx, cf.roomID)
		require.NoError(t, err)
		require.False(t, bound, "a mismatched delivery is dropped")

		require.NoError(t, cf.chain.ReceiveDelivery(cf.ctx, name, activated.GetMeta().GetEventId(), payload))
		bound, err = cf.bindings.IsBound(cf.ctx, cf.roomID)
		require.NoError(t, err)
		require.True(t, bound)
	})
}

func (cf *chainFixture) callFinal(callID string, custodyAddr []byte, block uint64) (string, []byte) {
	b, _ := proto.Marshal(&financev1.RoomCallFinal{
		Meta: meta(cf.roomID), CallId: callID, RoomId: cf.roomID, ChainId: testChainID,
		CustodyAddress: custodyAddr, Kind: 2, TxHash: txHash(block, 0), BlockNumber: block,
	})
	return business.FactRoomCallFinal, b
}

func (cf *chainFixture) callFailed(callID string, custodyAddr []byte, reason string) (string, []byte) {
	b, _ := proto.Marshal(&financev1.RoomCallFailed{
		Meta: meta(cf.roomID), CallId: callID, RoomId: cf.roomID, ChainId: testChainID,
		CustodyAddress: custodyAddr, Kind: 2, Reason: reason,
	})
	return business.FactRoomCallFailed, b
}

func (cf *chainFixture) genesisFailed(genesisID, reason string) (string, []byte) {
	b, _ := proto.Marshal(&financev1.RoomGenesisFailed{
		Meta: meta(cf.roomID), GenesisId: genesisID, RoomId: cf.roomID, ChainId: testChainID, Reason: reason,
	})
	return business.FactRoomGenesisFailed, b
}

func (cf *chainFixture) outcomeFor(t *testing.T, callID string) []*chatv1.StawiCallOutcomeContent {
	t.Helper()
	var out []*chatv1.StawiCallOutcomeContent
	for _, o := range cf.outcomes(t) {
		if o.GetCallId() == callID && o.GetState() != chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_ACCEPTED {
			out = append(out, o)
		}
	}
	return out
}

// TestRoomCallFactsReportTheOutcomeOfARelayedCall: room.call_final and
// room.call_failed close a call chat relayed, once, against its act — and
// only from the call's own room's custody.
func (s *MessageBusinessTestSuite) TestRoomCallFactsReportTheOutcomeOfARelayedCall() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.deliver(t, f2(cf.activated()))
		finalID, failedID, elsewhereID := util.IDString(), util.IDString(), util.IDString()
		for i, id := range []string{finalID, failedID, elsewhereID} {
			cf.rooms.AddCall(stawi.RoomCall{CallID: id, RoomID: cf.roomID, Kind: "CAST_VOTE",
				SignerAddress: hexAddr(aliceAddr), Nonce: uint64(i + 1)})
			requireAckOK(t, cf.send(t, cf.alice, signedCall(id, "CAST_VOTE")))
		}

		final := f2(cf.callFinal(finalID, custody, 50))
		cf.deliver(t, final, final)
		outcomes := cf.outcomeFor(t, finalID)
		require.Len(t, outcomes, 1)
		require.Equal(t, chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_OBSERVED, outcomes[0].GetState())
		require.EqualValues(t, 50, outcomes[0].GetBlockNumber())
		require.NotEmpty(t, outcomes[0].GetSourceEventId())

		cf.deliver(t, f2(cf.callFailed(failedID, custody, "reverted: quorum not met")))
		outcomes = cf.outcomeFor(t, failedID)
		require.Len(t, outcomes, 1)
		require.Equal(t, chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_FAILED, outcomes[0].GetState())
		require.Equal(t, "reverted: quorum not met", outcomes[0].GetReason())

		// Another custody's fact cannot close this room's call.
		cf.deliver(t, f2(cf.callFinal(elsewhereID, otherCustody, 51)))
		require.Empty(t, cf.outcomeFor(t, elsewhereID))
		call, err := cf.calls.GetByID(cf.ctx, elsewhereID)
		require.NoError(t, err)
		require.Equal(t, models.StawiCallStateSubmitted, call.State)
	})
}

// TestGenesisFailedReopensTheConversion: room.genesis_failed for the room's
// genesis reports it against the genesis card and lets the room be converted
// again; one naming another genesis changes nothing.
func (s *MessageBusinessTestSuite) TestGenesisFailedReopensTheConversion() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.deliver(t, f2(cf.genesisFailed(util.IDString(), "not mine")))
		pending, err := cf.bindings.GetByID(cf.ctx, cf.roomID)
		require.NoError(t, err)
		require.Equal(t, models.StawiRoomStatePending, pending.State)

		cf.deliver(t, f2(cf.genesisFailed(cf.genesisID, "quorum did not sign in time")))
		var failed []*chatv1.StawiCallOutcomeContent
		for _, o := range cf.outcomes(t) {
			if o.GetGenesisId() == cf.genesisID &&
				o.GetState() == chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_FAILED {
				failed = append(failed, o)
			}
		}
		require.Len(t, failed, 1)
		require.Equal(t, "quorum did not sign in time", failed[0].GetReason())
		require.Equal(t, pending.GenesisEventID, failed[0].GetSourceEventId())

		// The genesis is gone: an activation for it is refused, and another
		// admin may now convert.
		name, payload := cf.activated()
		require.Error(t, cf.chain.Receive(cf.ctx, name, payload))
		require.NoError(t, cf.rb.UpdateSubscriptionRole(cf.ctx, &chatv1.UpdateSubscriptionRoleRequest{
			RoomId: cf.roomID, SubscriptionId: cf.bobSub, Roles: []string{"admin"},
		}, cf.alice))
		requireAckOK(t, cf.send(t, cf.bob, conversion(cf.bobSub)))
	})
}

// TestActivationMustNameTheRoomsGenesis: room.activated binds only when it
// names the genesis chat recorded for the room and that chat room.
func (s *MessageBusinessTestSuite) TestActivationMustNameTheRoomsGenesis() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		for name, fact := range map[string][2]string{
			"another genesis":   {util.IDString(), cf.roomID},
			"no genesis":        {"", cf.roomID},
			"another chat room": {cf.genesisID, util.IDString()},
		} {
			t.Run(name, func(t *testing.T) {
				factName, payload := cf.activatedFor(fact[0], fact[1])
				require.Error(t, cf.chain.Receive(cf.ctx, factName, payload))
				bound, err := cf.bindings.IsBound(cf.ctx, cf.roomID)
				require.NoError(t, err)
				require.False(t, bound)
			})
		}
		cf.deliver(t, f2(cf.activated()))
		bound, err := cf.bindings.IsBound(cf.ctx, cf.roomID)
		require.NoError(t, err)
		require.True(t, bound)
	})
}

// TestGovernanceCallFailedMatchesByCallID: settlement now names the call.
func (s *MessageBusinessTestSuite) TestGovernanceCallFailedMatchesByCallID() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.deliver(t, f2(cf.activated()))
		callX := util.IDString()
		cf.rooms.AddCall(stawi.RoomCall{CallID: callX, RoomID: cf.roomID, Kind: "PROPOSE",
			SignerAddress: hexAddr(aliceAddr), Nonce: 4})
		requireAckOK(t, cf.send(t, cf.alice, signedCall(callX, "PROPOSE")))

		b, _ := proto.Marshal(&financev1.GovernanceCallFailed{
			Meta: meta(cf.roomID), CallId: callX, Reason: "deadline passed",
			Call: &financev1.SignedGovernanceCall{ChainId: testChainID, Verifier: governor, RoomId: cf.roomID},
		})
		cf.deliver(t, f2(business.FactGovernanceCallFailed, b))
		outcomes := cf.outcomeFor(t, callX)
		require.Len(t, outcomes, 1)
		require.Equal(t, "deadline passed", outcomes[0].GetReason())
	})
}
