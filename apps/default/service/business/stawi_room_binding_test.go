package business_test

import (
	"testing"
	"time"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/pitabwire/frame/v2/data"
	"github.com/pitabwire/frame/v2/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/service/models"
)

// TestRoomReadModelCarriesStawiBinding: the room read model says whether a
// room is a Stawi room, for every member, not only the one whose device saw
// the conversion. A plain room has no binding; a converted room carries its
// pending genesis; a bound room carries its chain custody and governance.
func (s *MessageBusinessTestSuite) TestRoomReadModelCarriesStawiBinding() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)

		room, err := f.rb.GetRoom(f.ctx, f.roomID, f.bob)
		require.NoError(t, err)
		require.Nil(t, room.GetStawi(), "a plain chat room has no binding")

		eventID := requireAckOK(t, f.send(t, f.alice, conversion(f.aliceSub)))
		genesisID := f.stored(t, eventID).GetPayload().GetStawiRoomConversion().GetGenesis().GetGenesisId()
		require.NotEmpty(t, genesisID)

		room, err = f.rb.GetRoom(f.ctx, f.roomID, f.bob)
		require.NoError(t, err)
		pending := room.GetStawi()
		require.NotNil(t, pending, "a member who did not convert the room sees the binding")
		require.Equal(t, chatv1.StawiRoomState_STAWI_ROOM_STATE_PENDING, pending.GetState())
		require.Equal(t, genesisID, pending.GetGenesisId())
		require.Equal(t, eventID, pending.GetGenesisEventId())
		require.Empty(t, pending.GetGovernanceAddress(), "no chain addresses before the room is bound")

		boundAt := time.Now().UTC().Truncate(time.Second)
		row, err := f.bindings.GetByID(f.ctx, f.roomID)
		require.NoError(t, err)
		row.State = models.StawiRoomStateBound
		row.ChainID = 84532
		row.CustodyAddress = "0x00000000000000000000000000000000000c0ffe"
		row.GovernanceAddress = "0x0000000000000000000000000000000000000a11"
		row.PolicyEpoch = 3
		row.BoundAt = &boundAt
		_, err = f.bindings.Update(f.ctx, row)
		require.NoError(t, err)

		room, err = f.rb.GetRoom(f.ctx, f.roomID, f.bob)
		require.NoError(t, err)
		requireBoundBinding(t, room.GetStawi(), genesisID, boundAt)
	})
}

// TestSearchRoomsCarriesStawiBindings: the room list, which the app syncs
// rooms from, carries each room's binding, and only on the rooms that have one.
func (s *MessageBusinessTestSuite) TestSearchRoomsCarriesStawiBindings() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		f.bind(t)

		plain, err := f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{Name: "Plain chat"}, f.alice)
		require.NoError(t, err)
		require.Nil(t, plain.GetStawi())

		rooms, err := f.rb.SearchRooms(f.ctx, &chatv1.SearchRoomsRequest{}, f.alice)
		require.NoError(t, err)

		byID := map[string]*chatv1.Room{}
		for _, room := range rooms {
			byID[room.GetId()] = room
		}
		require.Contains(t, byID, f.roomID)
		require.Contains(t, byID, plain.GetId())

		bound := byID[f.roomID].GetStawi()
		require.NotNil(t, bound)
		require.Equal(t, chatv1.StawiRoomState_STAWI_ROOM_STATE_BOUND, bound.GetState())
		require.Equal(t, uint64(84532), bound.GetChainId())
		require.Equal(t, "0xc0ffee", bound.GetCustodyAddress())
		require.Nil(t, byID[plain.GetId()].GetStawi(), "a plain room in the same list has no binding")
	})
}

// TestCreateRoomWithTakenIDRevealsNothingToNonMembers: creating a room with an
// id that is already in use answers with that room only to a caller who can
// already see it. A non-member learns that the id is taken, and nothing of the
// room or its Stawi binding.
func (s *MessageBusinessTestSuite) TestCreateRoomWithTakenIDRevealsNothingToNonMembers() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		f.bind(t)

		outsider := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		room, err := f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{Id: f.roomID, Name: "Taken"}, outsider)
		require.Error(t, err)
		require.Equal(t, connect.CodeAlreadyExists, connect.CodeOf(err), err.Error())
		require.Nil(t, room, "a non-member gets no room and no binding")

		room, err = f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{Id: f.roomID, Name: "Retry"}, f.bob)
		require.NoError(t, err)
		require.Equal(t, f.roomID, room.GetId())
		require.Equal(t, "Savings group", room.GetName(), "a member gets the room that exists")
		require.Equal(t, chatv1.StawiRoomState_STAWI_ROOM_STATE_BOUND, room.GetStawi().GetState())
	})
}

func requireBoundBinding(t *testing.T, binding *chatv1.StawiRoomBinding, genesisID string, boundAt time.Time) {
	t.Helper()
	require.NotNil(t, binding)
	require.Equal(t, chatv1.StawiRoomState_STAWI_ROOM_STATE_BOUND, binding.GetState())
	require.Equal(t, genesisID, binding.GetGenesisId())
	require.Equal(t, uint64(84532), binding.GetChainId())
	require.Equal(t, "0x00000000000000000000000000000000000c0ffe", binding.GetCustodyAddress())
	require.Equal(t, "0x0000000000000000000000000000000000000a11", binding.GetGovernanceAddress())
	require.Equal(t, uint64(3), binding.GetPolicyEpoch())
	require.Nil(t, binding.GetGenesisExpiresAt(), "a bound room has no pending expiry")
	require.True(t, boundAt.Equal(binding.GetBoundAt().AsTime()))
}

// TestADirectRoomIsNeverConverted: a DM stays personal. Its owner's
// conversion is refused before settlement is asked for a genesis, and no
// genesis is claimed for the room.
func (s *MessageBusinessTestSuite) TestADirectRoomIsNeverConverted() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)

		dm, err := f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{
			Name: "Bob", Type: chatv1.RoomType_ROOM_TYPE_DIRECT, Members: []*commonv1.ContactLink{f.bob},
		}, f.alice)
		require.NoError(t, err)
		f.roomID = dm.GetId()
		for _, member := range []*commonv1.ContactLink{f.alice, f.bob} {
			require.Eventually(t, func() bool {
				subs, subErr := f.subRepo.GetByContactLinkAndRooms(f.ctx,
					&commonv1.ContactLink{ProfileId: member.GetProfileId()}, f.roomID)
				return subErr == nil && len(subs) == 1 && f.authz.CanRoomView(f.ctx, subs[0].GetID(), f.roomID) == nil
			}, 30*time.Second, 100*time.Millisecond, "member %s of the DM", member.GetProfileId())
		}
		f.aliceSub = f.subscriptionOf(t, f.alice)
		f.bobSub = f.subscriptionOf(t, f.bob)
		prepared := len(f.rooms.Prepared)

		requireAckRefused(t, f.send(t, f.alice, conversion(f.aliceSub, f.bobSub)), connect.CodeFailedPrecondition)

		require.Len(t, f.rooms.Prepared, prepared, "settlement is never asked for a DM's genesis")
		_, err = f.bindings.GetByID(f.ctx, f.roomID)
		require.Error(t, err, "no genesis is claimed for a DM")
		require.True(t, data.ErrorIsNoRows(err), err.Error())
	})
}
