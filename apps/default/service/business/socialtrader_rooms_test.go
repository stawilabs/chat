package business_test

import (
	"context"
	"fmt"
	"testing"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect/v2"
	"github.com/pitabwire/frame/v3"
	"github.com/pitabwire/frame/v3/datastore"
	"github.com/pitabwire/frame/v3/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/types/known/structpb"

	"github.com/stawilabs/chat/apps/default/service/business"
	"github.com/stawilabs/chat/apps/default/service/events"
	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/service/socialtrader"
	"github.com/stawilabs/chat/apps/default/service/socialtrader/socialtradertest"
)

const (
	bindPool         = "0x00000000000000000000000000000000000000d4"
	bindLeaderWallet = "0xAbCdEf0000000000000000000000000000000001"
)

type bindingFixture struct {
	ctx      context.Context
	svc      *frame.Service
	rb       business.RoomBusiness
	pools    *socialtradertest.Pools
	links    *socialtradertest.WalletLinks
	bindings repository.SocialTraderRoomRepository
	stawi    repository.StawiRoomRepository
	subs     repository.RoomSubscriptionRepository
	leader   *commonv1.ContactLink
	member   *commonv1.ContactLink
}

// promote makes member an admin of roomID the way the room's owner does,
// through UpdateSubscriptionRole, so UpdateRoom reaches the binding checks.
func (f *bindingFixture) promote(t *testing.T, roomID string, member *commonv1.ContactLink) error {
	t.Helper()
	subs, err := f.subs.GetByContactLinkAndRooms(f.ctx,
		&commonv1.ContactLink{ProfileId: member.GetProfileId()}, roomID)
	if err != nil {
		return err
	}
	if len(subs) != 1 {
		return fmt.Errorf("expected one subscription, got %d", len(subs))
	}
	return f.rb.UpdateSubscriptionRole(f.ctx, &chatv1.UpdateSubscriptionRoleRequest{
		RoomId: roomID, SubscriptionId: subs[0].GetID(), Roles: []string{"admin"},
	}, f.leader)
}

// markStawiRoom makes the room a Stawi room (genesis prepared), as a
// conversion relayed to settlement does.
func (f *bindingFixture) markStawiRoom(t *testing.T, roomID string) {
	t.Helper()
	row := &models.StawiRoom{State: models.StawiRoomStatePending, GenesisID: util.IDString()}
	row.ID = roomID
	require.NoError(t, f.stawi.Create(f.ctx, row))
}

// newBindingFixture wires the room business with a fake socialtrader (one
// pool whose leader is the fixture's leader profile) when configured is true,
// and without any socialtrader client otherwise.
func (s *RoomBusinessTestSuite) newBindingFixture(
	t *testing.T, dep *definition.DependencyOption, configured bool,
) *bindingFixture {
	t.Helper()
	ctx, svc := s.CreateService(t, dep)
	f := &bindingFixture{
		ctx:    ctx,
		svc:    svc,
		pools:  socialtradertest.NewPools(),
		links:  socialtradertest.NewWalletLinks(),
		leader: &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()},
		member: &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()},
	}
	f.pools.Add(&socialtrader.Pool{Address: bindPool, Leader: bindLeaderWallet, MarketID: "0x01"})
	f.links.Link(f.leader.GetProfileId(), bindLeaderWallet)
	f.rb, f.bindings, f.stawi, f.subs = s.setupBindingBusinessLayer(ctx, svc, f, configured)
	return f
}

func (s *RoomBusinessTestSuite) setupBindingBusinessLayer(
	ctx context.Context, svc *frame.Service, f *bindingFixture, configured bool,
) (business.RoomBusiness, repository.SocialTraderRoomRepository, repository.StawiRoomRepository,
	repository.RoomSubscriptionRepository,
) {
	workMan := svc.WorkManager()
	evtsMan := svc.EventsManager()
	dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)

	roomRepo := repository.NewRoomRepository(ctx, dbPool, workMan)
	eventRepo := repository.NewRoomEventRepository(ctx, dbPool, workMan)
	outboxRepo := repository.NewRoomOutboxRepository(ctx, dbPool, workMan)
	subRepo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)
	bindings := repository.NewSocialTraderRoomRepository(ctx, dbPool, workMan)
	stawiBindings := repository.NewStawiRoomRepository(ctx, dbPool, workMan)

	subscriptionSvc := business.NewSubscriptionService(svc, subRepo)
	mb := business.NewMessageBusiness(evtsMan, eventRepo, outboxRepo, subRepo, subscriptionSvc, s.AuthzMiddleware)
	opts := []business.RoomBusinessOption{business.WithStawiBindings(stawiBindings)}
	if configured {
		opts = append(opts, business.WithSocialTrader(f.pools, f.links, bindings))
	} else {
		opts = append(opts, business.WithSocialTrader(nil, nil, bindings))
	}
	rb := business.NewRoomBusiness(svc, roomRepo, eventRepo, subRepo, nil, subscriptionSvc, evtsMan, mb, nil,
		s.AuthzMiddleware, opts...)
	return rb, bindings, stawiBindings, subRepo
}

func poolMetadata(t *testing.T, pool string) *structpb.Struct {
	t.Helper()
	metadata, err := structpb.NewStruct(map[string]any{events.SocialTraderPoolMetadataKey: pool})
	require.NoError(t, err)
	return metadata
}

func (f *bindingFixture) createBound(t *testing.T, by *commonv1.ContactLink, pool string) (*chatv1.Room, error) {
	t.Helper()
	return f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{
		Name: "Trading group", Metadata: poolMetadata(t, pool),
		Members: []*commonv1.ContactLink{f.member},
	}, by)
}

// TestRoomBinding_LeaderCanBind: the pool's leader (the profile whose linked
// wallet is the pool's leader) binds a room on creation, and later another
// through UpdateRoom; the binding is recorded server-side.
func (s *RoomBusinessTestSuite) TestRoomBinding_LeaderCanBind() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newBindingFixture(t, dep, true)

		room, err := f.createBound(t, f.leader, bindPool)
		require.NoError(t, err)
		binding, err := f.bindings.GetByRoomID(f.ctx, room.GetId())
		require.NoError(t, err)
		require.NotNil(t, binding, "the binding is recorded")
		require.Equal(t, bindPool, binding.PoolID)
		require.Equal(t, f.leader.GetProfileId(), binding.LeaderProfileID)
		require.Equal(t, bindPool, room.GetMetadata().GetFields()[events.SocialTraderPoolMetadataKey].GetStringValue(),
			"the metadata stays as a display hint")

		plain, err := f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{Name: "Plain"}, f.leader)
		require.NoError(t, err)
		s.WaitForMemberSubscription(f.ctx, f.svc, plain.GetId(), f.leader.GetProfileId(), t)
		_, err = f.rb.UpdateRoom(f.ctx, &chatv1.UpdateRoomRequest{
			RoomId: plain.GetId(), Metadata: poolMetadata(t, bindPool),
		}, f.leader)
		require.NoError(t, err)
		binding, err = f.bindings.GetByRoomID(f.ctx, plain.GetId())
		require.NoError(t, err)
		require.NotNil(t, binding)
		require.Equal(t, bindPool, binding.PoolID)
	})
}

// TestRoomBinding_NonLeaderCannotBind: a profile whose linked wallet is not
// the pool's leader, or with no linked wallet, is refused and no room is
// created and no binding recorded.
func (s *RoomBusinessTestSuite) TestRoomBinding_NonLeaderCannotBind() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newBindingFixture(t, dep, true)
		other := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		f.links.Link(other.GetProfileId(), "0x0000000000000000000000000000000000000bad")

		for name, by := range map[string]*commonv1.ContactLink{
			"another linked wallet": other,
			"no linked wallet":      f.member,
		} {
			t.Run(name, func(t *testing.T) {
				_, err := f.createBound(t, by, bindPool)
				require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err), "%v", err)
			})
		}

		rooms, err := f.rb.SearchRooms(f.ctx, &chatv1.SearchRoomsRequest{}, other)
		require.NoError(t, err)
		require.Empty(t, rooms, "no room was created")
	})
}

// TestRoomBinding_UnknownPoolRejected: a pool the service does not know, or
// a value that is not a pool address, is refused.
func (s *RoomBusinessTestSuite) TestRoomBinding_UnknownPoolRejected() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newBindingFixture(t, dep, true)

		_, err := f.createBound(t, f.leader, "0x00000000000000000000000000000000000000ee")
		require.Equal(t, connect.CodeNotFound, connect.CodeOf(err), "%v", err)

		_, err = f.createBound(t, f.leader, "not-a-pool")
		require.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err), "%v", err)
	})
}

// TestRoomBinding_UnconfiguredRefuses: without a socialtrader client no room
// may be bound, whoever asks.
func (s *RoomBusinessTestSuite) TestRoomBinding_UnconfiguredRefuses() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newBindingFixture(t, dep, false)

		_, err := f.createBound(t, f.leader, bindPool)
		require.Equal(t, connect.CodeFailedPrecondition, connect.CodeOf(err), "%v", err)
	})
}

// TestRoomBinding_MetadataWithoutValidBindingIsRejected: the metadata key is
// never accepted on its own. The nested form is validated like the flat one,
// a pool created for another room is refused, and a refused request leaves
// neither room nor binding row behind.
func (s *RoomBusinessTestSuite) TestRoomBinding_MetadataWithoutValidBindingIsRejected() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newBindingFixture(t, dep, true)
		nested, err := structpb.NewStruct(map[string]any{
			"socialtrader": map[string]any{"pool_id": bindPool},
		})
		require.NoError(t, err)

		_, err = f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{Name: "Nested", Metadata: nested}, f.member)
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err), "nested key is validated too: %v", err)

		otherRoom := "0x00000000000000000000000000000000000000f5"
		f.pools.Add(&socialtrader.Pool{
			Address: otherRoom, Leader: bindLeaderWallet, MarketID: "0x01", RoomRef: util.IDString(),
		})
		_, err = f.createBound(t, f.leader, otherRoom)
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err), "pool of another room: %v", err)

		// A member of a plain room cannot bind it through UpdateRoom either.
		plain, err := f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{Name: "Plain"}, f.member)
		require.NoError(t, err)
		s.WaitForMemberSubscription(f.ctx, f.svc, plain.GetId(), f.member.GetProfileId(), t)
		_, err = f.rb.UpdateRoom(f.ctx, &chatv1.UpdateRoomRequest{
			RoomId: plain.GetId(), Metadata: poolMetadata(t, bindPool),
		}, f.member)
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err), "%v", err)
		binding, err := f.bindings.GetByRoomID(f.ctx, plain.GetId())
		require.NoError(t, err)
		require.Nil(t, binding, "no binding row for a refused request")
		got, err := f.rb.GetRoom(f.ctx, plain.GetId(), f.member)
		require.NoError(t, err)
		require.Empty(t, got.GetMetadata().GetFields()[events.SocialTraderPoolMetadataKey].GetStringValue(),
			"the refused metadata was not persisted")
	})
}

// TestRoomBinding_StawiKeysAreNotWritableOnAStawiRoom: once a room is a Stawi
// room (its genesis prepared or bound), UpdateRoom may not rewrite stawi.*
// metadata, which the Stawi flow owns.
func (s *RoomBusinessTestSuite) TestRoomBinding_StawiKeysAreNotWritableOnAStawiRoom() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newBindingFixture(t, dep, true)
		room, err := f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{Name: "Savings"}, f.leader)
		require.NoError(t, err)
		s.WaitForMemberSubscription(f.ctx, f.svc, room.GetId(), f.leader.GetProfileId(), t)

		stawiMeta, err := structpb.NewStruct(map[string]any{events.GroupMetadataKey: "grp-x"})
		require.NoError(t, err)
		_, err = f.rb.UpdateRoom(f.ctx, &chatv1.UpdateRoomRequest{RoomId: room.GetId(), Metadata: stawiMeta}, f.leader)
		require.NoError(t, err, "a plain room's stawi hint is the client's to set, as before")

		f.markStawiRoom(t, room.GetId())
		_, err = f.rb.UpdateRoom(f.ctx, &chatv1.UpdateRoomRequest{RoomId: room.GetId(), Metadata: stawiMeta}, f.leader)
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err), "%v", err)
	})
}

// TestCreateRoom_RetryAfterBindingFailureBinds: a creator retrying CreateRoom
// with the same id (the room exists, the binding does not) gets the room
// bound; the existing-room answer re-validates and records the binding
// (review finding: room and binding were not written together).
func (s *RoomBusinessTestSuite) TestCreateRoom_RetryAfterBindingFailureBinds() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newBindingFixture(t, dep, true)
		roomID := util.IDString()

		plain, err := f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{Id: roomID, Name: "Traders"}, f.leader)
		require.NoError(t, err)
		require.Equal(t, roomID, plain.GetId())
		binding, err := f.bindings.GetByRoomID(f.ctx, roomID)
		require.NoError(t, err)
		require.Nil(t, binding, "the first create asked for no pool")

		again, err := f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{
			Id: roomID, Name: "Traders", Metadata: poolMetadata(t, bindPool),
		}, f.leader)
		require.NoError(t, err)
		require.Equal(t, roomID, again.GetId())
		binding, err = f.bindings.GetByRoomID(f.ctx, roomID)
		require.NoError(t, err)
		require.NotNil(t, binding, "the retry binds the existing room")
		require.Equal(t, bindPool, binding.PoolID)

		// A non-leader retrying with a pool is still refused.
		_, err = f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{
			Id: roomID, Name: "Traders", Metadata: poolMetadata(t, bindPool),
		}, f.member)
		require.Error(t, err)
	})
}

// TestUpdateRoom_BindingFailureLeavesMetadataUnchanged: when the binding
// cannot be validated or recorded, the room's metadata is not changed either.
func (s *RoomBusinessTestSuite) TestUpdateRoom_BindingFailureLeavesMetadataUnchanged() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newBindingFixture(t, dep, true)
		room, err := f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{Name: "Traders"}, f.leader)
		require.NoError(t, err)
		s.WaitForMemberSubscription(f.ctx, f.svc, room.GetId(), f.leader.GetProfileId(), t)

		f.pools.Refuse(connect.NewError(connect.CodeUnavailable, "indexer down"))
		_, err = f.rb.UpdateRoom(f.ctx, &chatv1.UpdateRoomRequest{
			RoomId: room.GetId(), Name: "Renamed", Metadata: poolMetadata(t, bindPool),
		}, f.leader)
		require.Equal(t, connect.CodeUnavailable, connect.CodeOf(err), "%v", err)

		got, err := f.rb.GetRoom(f.ctx, room.GetId(), f.leader)
		require.NoError(t, err)
		require.Equal(t, "Traders", got.GetName(), "nothing of the update was saved")
		require.Empty(t, got.GetMetadata().GetFields()[events.SocialTraderPoolMetadataKey].GetStringValue())
		binding, err := f.bindings.GetByRoomID(f.ctx, room.GetId())
		require.NoError(t, err)
		require.Nil(t, binding)
	})
}

// TestRoomBinding_RebindByOtherLeaderRefused: a room bound by one leader
// cannot be re-bound to another pool by a different leader, even one who
// leads that other pool (review finding: Upsert overwrote any binding).
func (s *RoomBusinessTestSuite) TestRoomBinding_RebindByOtherLeaderRefused() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newBindingFixture(t, dep, true)
		room, err := f.createBound(t, f.leader, bindPool)
		require.NoError(t, err)
		s.WaitForMemberSubscription(f.ctx, f.svc, room.GetId(), f.member.GetProfileId(), t)

		otherPool := "0x00000000000000000000000000000000000000e6"
		otherWallet := "0x0000000000000000000000000000000000000e6e"
		f.pools.Add(&socialtrader.Pool{Address: otherPool, Leader: otherWallet, MarketID: "0x01"})
		f.links.Link(f.member.GetProfileId(), otherWallet)
		// The member is made an admin so UpdateRoom reaches the binding check.
		require.NoError(t, f.promote(t, room.GetId(), f.member))

		_, err = f.rb.UpdateRoom(f.ctx, &chatv1.UpdateRoomRequest{
			RoomId: room.GetId(), Metadata: poolMetadata(t, otherPool),
		}, f.member)
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err), "%v", err)
		binding, err := f.bindings.GetByRoomID(f.ctx, room.GetId())
		require.NoError(t, err)
		require.Equal(t, bindPool, binding.PoolID, "the original binding stands")
		require.Equal(t, f.leader.GetProfileId(), binding.LeaderProfileID)
	})
}

// TestRoomBinding_ClearingKeyUnbinds: the bound leader clears the key to
// unbind (the row is deleted and the hint removed); anyone else clearing it
// is refused and the binding stands.
func (s *RoomBusinessTestSuite) TestRoomBinding_ClearingKeyUnbinds() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newBindingFixture(t, dep, true)
		room, err := f.createBound(t, f.leader, bindPool)
		require.NoError(t, err)
		s.WaitForMemberSubscription(f.ctx, f.svc, room.GetId(), f.leader.GetProfileId(), t)
		s.WaitForMemberSubscription(f.ctx, f.svc, room.GetId(), f.member.GetProfileId(), t)
		require.NoError(t, f.promote(t, room.GetId(), f.member))

		cleared, err := structpb.NewStruct(map[string]any{events.SocialTraderPoolMetadataKey: ""})
		require.NoError(t, err)

		_, err = f.rb.UpdateRoom(f.ctx, &chatv1.UpdateRoomRequest{RoomId: room.GetId(), Metadata: cleared}, f.member)
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err), "%v", err)
		binding, err := f.bindings.GetByRoomID(f.ctx, room.GetId())
		require.NoError(t, err)
		require.NotNil(t, binding, "a non-leader cannot unbind")

		got, err := f.rb.UpdateRoom(f.ctx, &chatv1.UpdateRoomRequest{RoomId: room.GetId(), Metadata: cleared}, f.leader)
		require.NoError(t, err)
		require.Empty(t, got.GetMetadata().GetFields()[events.SocialTraderPoolMetadataKey].GetStringValue())
		binding, err = f.bindings.GetByRoomID(f.ctx, room.GetId())
		require.NoError(t, err)
		require.Nil(t, binding, "the leader unbound the room")
	})
}

// TestCreateRoom_RetryByNonCreatorCannotBind: answering an existing room id
// never binds it for a caller who is neither its creator nor an admin, even
// a member who leads the requested pool (security review of the retry path).
func (s *RoomBusinessTestSuite) TestCreateRoom_RetryByNonCreatorCannotBind() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newBindingFixture(t, dep, true)
		roomID := util.IDString()
		room, err := f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{
			Id: roomID, Name: "Traders", Members: []*commonv1.ContactLink{f.member},
		}, f.leader)
		require.NoError(t, err)
		s.WaitForMemberSubscription(f.ctx, f.svc, room.GetId(), f.member.GetProfileId(), t)

		otherPool := "0x00000000000000000000000000000000000000e7"
		otherWallet := "0x0000000000000000000000000000000000000e7e"
		f.pools.Add(&socialtrader.Pool{Address: otherPool, Leader: otherWallet, MarketID: "0x01"})
		f.links.Link(f.member.GetProfileId(), otherWallet)

		_, err = f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{
			Id: roomID, Name: "Traders", Metadata: poolMetadata(t, otherPool),
		}, f.member)
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err), "%v", err)
		binding, err := f.bindings.GetByRoomID(f.ctx, roomID)
		require.NoError(t, err)
		require.Nil(t, binding, "the member's retry bound nothing")

		// Without a binding hint the member still gets the room answered.
		again, err := f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{Id: roomID, Name: "Traders"}, f.member)
		require.NoError(t, err)
		require.Equal(t, roomID, again.GetId())

		// An admin may bind through the retry, like through UpdateRoom.
		require.NoError(t, f.promote(t, roomID, f.member))
		_, err = f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{
			Id: roomID, Name: "Traders", Metadata: poolMetadata(t, otherPool),
		}, f.member)
		require.NoError(t, err)
		binding, err = f.bindings.GetByRoomID(f.ctx, roomID)
		require.NoError(t, err)
		require.NotNil(t, binding)
		require.Equal(t, otherPool, binding.PoolID)
	})
}

// TestRoomBinding_UnbindThenRebindWorks: the leader unbinds and binds again
// (same or another pool) through UpdateRoom.
func (s *RoomBusinessTestSuite) TestRoomBinding_UnbindThenRebindWorks() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newBindingFixture(t, dep, true)
		room, err := f.createBound(t, f.leader, bindPool)
		require.NoError(t, err)
		s.WaitForMemberSubscription(f.ctx, f.svc, room.GetId(), f.leader.GetProfileId(), t)

		cleared, err := structpb.NewStruct(map[string]any{events.SocialTraderPoolMetadataKey: ""})
		require.NoError(t, err)
		_, err = f.rb.UpdateRoom(f.ctx, &chatv1.UpdateRoomRequest{RoomId: room.GetId(), Metadata: cleared}, f.leader)
		require.NoError(t, err)

		_, err = f.rb.UpdateRoom(f.ctx, &chatv1.UpdateRoomRequest{
			RoomId: room.GetId(), Metadata: poolMetadata(t, bindPool),
		}, f.leader)
		require.NoError(t, err, "rebinding after an unbind")
		binding, err := f.bindings.GetByRoomID(f.ctx, room.GetId())
		require.NoError(t, err)
		require.NotNil(t, binding)
		require.Equal(t, bindPool, binding.PoolID)
	})
}
