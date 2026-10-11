package business_test

import (
	"testing"
	"time"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/pitabwire/frame/v2/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/service/stawi"
)

// TestStawiActsRefusedFromAnyoneButAnActiveAuthorisedMember: a stranger, a
// removed member, a member whose room permission was revoked in Keto (the
// subscription row still active) and an unauthenticated caller each have
// every Stawi act refused, and settlement never hears of it.
func (s *MessageBusinessTestSuite) TestStawiActsRefusedFromAnyoneButAnActiveAuthorisedMember() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		stranger := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		f.accounts.Own("0xa11ce", f.alice.GetProfileId())
		f.accounts.Own("0xb0b", f.bob.GetProfileId())
		f.accounts.Own("0x5747", stranger.GetProfileId())
		requireAckOK(t, f.send(t, f.alice, conversion(f.aliceSub, f.bobSub)))
		binding, err := f.bindings.GetByID(f.ctx, f.roomID)
		require.NoError(t, err)
		f.rooms.AddCall(stawi.RoomCall{CallID: "call-bob", RoomID: f.roomID, Kind: "LEAVE",
			SignerAddress: "0xb0b", Nonce: 1})
		f.rooms.AddCall(stawi.RoomCall{CallID: "call-stranger", RoomID: f.roomID, Kind: "JOIN",
			SignerAddress: "0x5747", Nonce: 1})

		acts := func(callID string) map[string]*chatv1.Payload {
			return map[string]*chatv1.Payload{
				"conversion":        conversion(f.aliceSub),
				"genesis signature": genesisSignature(binding.GenesisID),
				"signed call": signedCall(
					callID,
					map[string]string{"call-bob": "LEAVE", "call-stranger": "JOIN"}[callID],
				),
			}
		}
		refusedEverything := func(t *testing.T, sender *commonv1.ContactLink, callID string) {
			t.Helper()
			for name, payload := range acts(callID) {
				ack := f.send(t, sender, payload)
				require.NotNil(t, ack.GetError(), "%s must be refused", name)
				require.Nil(t, f.stored(t, ack.GetEventId()[0]), "%s must not be stored", name)
			}
		}

		t.Run("stranger", func(t *testing.T) { refusedEverything(t, stranger, "call-stranger") })

		t.Run("keto permission revoked", func(t *testing.T) {
			require.NoError(t, s.AuthzMiddleware.RemoveRoomMember(f.ctx, f.roomID, f.bobSub))
			refusedEverything(t, f.bob, "call-bob")
			require.NoError(t, s.AuthzMiddleware.AddRoomMember(f.ctx, f.roomID, f.bobSub, "member"))
		})

		t.Run("removed member", func(t *testing.T) {
			require.NoError(t, f.rb.RemoveRoomSubscriptions(f.ctx, &chatv1.RemoveRoomSubscriptionsRequest{
				RoomId: f.roomID, SubscriptionId: []string{f.bobSub},
			}, f.alice))
			refusedEverything(t, f.bob, "call-bob")
		})

		t.Run("unauthenticated", func(t *testing.T) {
			for _, nobody := range []*commonv1.ContactLink{nil, {}, {ProfileId: f.alice.GetProfileId()}} {
				_, sendErr := f.mb.SendEvents(f.ctx, &chatv1.SendEventRequest{Event: []*chatv1.RoomEvent{{
					RoomId: f.roomID, Type: chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT,
					Payload: conversion(f.aliceSub),
				}}}, nobody)
				require.Error(t, sendErr)
			}
		})

		require.Len(t, f.rooms.Prepared, 1, "only alice's conversion reached settlement")
		require.Empty(t, f.rooms.Signatures(binding.GenesisID))
		require.Empty(t, f.rooms.Submitted)
	})
}

// TestPendingGenesisBelongsToItsRequester: while a genesis is pending and
// unexpired, only the member who requested it may replace it with a new
// conversion; anyone else is refused before settlement is asked. Once it has
// expired, any member may start over.
func (s *MessageBusinessTestSuite) TestPendingGenesisBelongsToItsRequester() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		requireAckOK(t, f.send(t, f.alice, conversion(f.aliceSub, f.bobSub)))
		first, err := f.bindings.GetByID(f.ctx, f.roomID)
		require.NoError(t, err)
		require.Equal(t, f.alice.GetProfileId(), first.RequestedBy)

		requireAckRefused(t, f.send(t, f.bob, conversion(f.bobSub)), connect.CodeFailedPrecondition)
		require.Len(t, f.rooms.Prepared, 1, "settlement is not asked")
		unchanged, err := f.bindings.GetByID(f.ctx, f.roomID)
		require.NoError(t, err)
		require.Equal(t, first.GenesisID, unchanged.GenesisID)
		require.Equal(t, first.Founders, unchanged.Founders)

		// The requester may replace their own pending genesis.
		requireAckOK(t, f.send(t, f.alice, conversion(f.aliceSub)))
		replaced, err := f.bindings.GetByID(f.ctx, f.roomID)
		require.NoError(t, err)
		require.NotEqual(t, first.GenesisID, replaced.GenesisID)

		// An expired genesis may be replaced by any member.
		f.rooms.GenesisTTL = -time.Minute
		requireAckOK(t, f.send(t, f.alice, conversion(f.aliceSub)))
		requireAckOK(t, f.send(t, f.bob, conversion(f.bobSub)))
		taken, err := f.bindings.GetByID(f.ctx, f.roomID)
		require.NoError(t, err)
		require.Equal(t, f.bob.GetProfileId(), taken.RequestedBy)
	})
}

// TestStawiRepositoriesNeverOverwriteAnotherOwner covers the repository
// guards directly: a genesis is never recorded over a bound room, and a call
// id recorded for one room and signer cannot be re-recorded for another.
func (s *MessageBusinessTestSuite) TestStawiRepositoriesNeverOverwriteAnotherOwner() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		room := &models.Room{}
		room.ID = f.roomID

		f.bind(t)
		err := f.bindings.ClaimGenesis(f.ctx, room, models.StawiGenesisClaim{
			GenesisID: "g-late", EventID: util.IDString(), RequestedBy: f.alice.GetProfileId(),
			Founders: []string{f.alice.GetProfileId()}, ExpiresAt: time.Now().Add(time.Hour),
		})
		require.ErrorIs(t, err, repository.ErrStawiGenesisNotClaimable)
		bound, err := f.bindings.GetByID(f.ctx, f.roomID)
		require.NoError(t, err)
		require.Equal(t, models.StawiRoomStateBound, bound.State)
		require.Empty(t, bound.GenesisID)

		call := func(roomID, signer, eventID string) *models.StawiRoomCall {
			c := &models.StawiRoomCall{RoomID: roomID, SignerAddress: signer, Nonce: 3, SourceEventID: eventID,
				State: models.StawiCallStateSubmitted}
			c.ID = "call-owned"
			return c
		}
		require.NoError(t, f.calls.Record(f.ctx, call(f.roomID, "0xa11ce", "evt-1")))
		require.NoError(t, f.calls.Record(f.ctx, call(f.roomID, "0xA11CE", "evt-2")), "a retry by the owner is fine")
		require.ErrorIs(t, f.calls.Record(f.ctx, call(util.IDString(), "0xa11ce", "evt-3")),
			repository.ErrStawiCallConflict)
		require.ErrorIs(t, f.calls.Record(f.ctx, call(f.roomID, "0xb0b", "evt-4")), repository.ErrStawiCallConflict)
		kept, err := f.calls.GetByID(f.ctx, "call-owned")
		require.NoError(t, err)
		require.Equal(t, "evt-1", kept.SourceEventID)
		require.Equal(t, f.roomID, kept.RoomID)
	})
}

// TestStawiTablesAreTenancyIsolated: every Stawi table carries the platform's
// row-level tenancy policy, so a caller's queries are scoped to its tenant and
// partition.
func (s *MessageBusinessTestSuite) TestStawiTablesAreTenancyIsolated() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		db := f.bindings.Pool().DB(f.ctx, false)
		for _, table := range []string{"stawi_rooms", "stawi_room_calls", "stawi_chain_facts", "stawi_room_members"} {
			var secured bool
			require.NoError(t, db.Raw("SELECT relrowsecurity FROM pg_class WHERE relname = ?", table).
				Scan(&secured).Error)
			require.True(t, secured, "%s must have row-level security", table)
		}
	})
}
