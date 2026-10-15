package business_test

import (
	"testing"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	financev1 "buf.build/gen/go/stawi/finance/protocolbuffers/go/finance/v1"
	"connectrpc.com/connect/v2"
	"github.com/pitabwire/frame/v3/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/proto"

	"github.com/stawilabs/chat/apps/default/service/business"
)

//nolint:gochecknoglobals // immutable test fixtures
var (
	otherCustody  = []byte{0xde, 0xad, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x09}
	otherGovernor = []byte{0xbe, 0xef, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x0a}
)

func activation(roomID string, custodyAddr, governance []byte) (string, []byte) {
	b, _ := proto.Marshal(&financev1.RoomActivated{
		Meta: meta(roomID), RoomId: roomID, ChainId: testChainID,
		CustodyAddress: custodyAddr, GovernanceAddress: governance, PolicyEpoch: 1,
	})
	return business.FactRoomActivated, b
}

// otherRoom creates a second chat room owned by alice, optionally converted.
func (cf *chainFixture) otherRoom(t *testing.T, convert bool) string {
	t.Helper()
	room, err := cf.rb.CreateRoom(cf.ctx, &chatv1.CreateRoomRequest{Name: "Another group"}, cf.alice)
	require.NoError(t, err)
	if !convert {
		return room.GetId()
	}
	subs, err := cf.subRepo.GetByContactLinkAndRooms(cf.ctx,
		&commonv1.ContactLink{ProfileId: cf.alice.GetProfileId()}, room.GetId())
	require.NoError(t, err)
	require.Len(t, subs, 1)
	acks, err := cf.mb.SendEvents(cf.ctx, &chatv1.SendEventRequest{Event: []*chatv1.RoomEvent{{
		RoomId: room.GetId(), Type: chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT, Payload: conversion(subs[0].GetID()),
	}}}, cf.alice)
	require.NoError(t, err)
	require.Nil(t, acks[0].GetError())
	return room.GetId()
}

// TestMembershipRoomComesFromTheLogsCustody: the room a membership fact
// changes is the one bound to the custody that emitted the log. A fact whose
// convenience room_id names one room while its custody belongs to another (or
// to no room) never touches the named room.
func (s *MessageBusinessTestSuite) TestMembershipRoomComesFromTheLogsCustody() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)
		cf.deliver(t, f2(cf.activated()))

		forged, _ := proto.Marshal(&financev1.RoomMembershipObserved{
			Meta: meta(cf.roomID), ChainId: testChainID, CustodyAddress: otherCustody,
			Event:  financev1.RoomMembershipChainEvent_ROOM_MEMBERSHIP_CHAIN_EVENT_MEMBER_STATE_CHANGED,
			Member: carolAddr, FromState: none, ToState: active,
			TxHash: txHash(40, 1), BlockNumber: 40, LogIndex: 1, RoomId: cf.roomID,
		})
		require.NoError(t, cf.chain.Receive(cf.ctx, business.FactRoomMembershipObserved, forged))
		require.False(t, cf.live(t, cf.carol.GetProfileId()), "another custody's log cannot admit into this room")

		observed, _ := proto.Marshal(&financev1.GovernanceCallObserved{
			Meta: meta(cf.roomID), ChainId: testChainID, Emitter: otherGovernor,
			Event:  financev1.GovernanceChainEvent_GOVERNANCE_CHAIN_EVENT_PROPOSED,
			TxHash: txHash(41, 0), BlockNumber: 41, RoomId: cf.roomID,
		})
		before := len(cf.outcomes(t))
		require.NoError(t, cf.chain.Receive(cf.ctx, business.FactGovernanceCallObserved, observed))
		require.Len(t, cf.outcomes(t), before, "another GovernanceModule's log is not this room's")
	})
}

// TestActivationBindsOnlyARoomThatAskedForIt: a room is bound only from a
// genesis chat prepared for that very room (by its owner or admin), never
// rebound, and a custody binds at most one room. An activation for a room
// chat does not know creates nothing.
func (s *MessageBusinessTestSuite) TestActivationBindsOnlyARoomThatAskedForIt() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		cf := s.newChainFixture(t, dep)

		// No genesis was prepared from this room.
		unconverted := cf.otherRoom(t, false)
		name, payload := activation(unconverted, otherCustody, otherGovernor)
		cf.requireActivationRefused(t, name, payload)
		bound, err := cf.bindings.IsBound(cf.ctx, unconverted)
		require.NoError(t, err)
		require.False(t, bound)

		// A room chat has never seen is not created by a fact.
		unknown := util.IDString()
		name, payload = activation(unknown, otherCustody, otherGovernor)
		cf.requireActivationRefused(t, name, payload)
		_, err = cf.rb.GetRoom(cf.ctx, unknown, cf.alice)
		require.Error(t, err)

		// The fixture room binds; its custody cannot bind a second room.
		cf.deliver(t, f2(cf.activated()))
		second := cf.otherRoom(t, true)
		name, payload = activation(second, custody, governor)
		cf.requireActivationRefused(t, name, payload)
		bound, err = cf.bindings.IsBound(cf.ctx, second)
		require.NoError(t, err)
		require.False(t, bound)
	})
}

// TestConversionNeedsTheRoomsOwnerOrAdmin: a plain member cannot start a
// conversion, so nobody can line a room up for binding without holding it.
func (s *MessageBusinessTestSuite) TestConversionNeedsTheRoomsOwnerOrAdmin() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		before := len(f.rooms.Prepared)
		requireAckRefused(t, f.send(t, f.bob, conversion(f.aliceSub, f.bobSub)), connect.CodePermissionDenied)
		require.Len(t, f.rooms.Prepared, before)
	})
}
