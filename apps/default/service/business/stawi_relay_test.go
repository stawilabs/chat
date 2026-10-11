package business_test

import (
	"context"
	"testing"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/pitabwire/frame/v2"
	"github.com/pitabwire/frame/v2/datastore"
	"github.com/pitabwire/frame/v2/datastore/pool"
	"github.com/pitabwire/frame/v2/frametests/definition"
	"github.com/pitabwire/frame/v2/security"
	"github.com/pitabwire/frame/v2/security/authorizer"
	"github.com/pitabwire/frame/v2/workerpool"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/service/authz"
	"github.com/stawilabs/chat/apps/default/service/business"
	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/service/stawi"
	"github.com/stawilabs/chat/apps/default/service/stawi/stawitest"
)

// stawiFixture is a room with two members, a business layer wired to a fake
// settlement, and the repositories a test inspects.
type stawiFixture struct {
	ctx      context.Context
	mb       business.MessageBusiness
	rb       business.RoomBusiness
	rooms    *stawitest.Rooms
	accounts *stawitest.Accounts
	bindings repository.StawiRoomRepository
	calls    repository.StawiRoomCallRepository
	subRepo  repository.RoomSubscriptionRepository
	dbPool   pool.Pool
	workMan  workerpool.Manager
	authz    authz.Middleware
	keto     security.Authorizer
	roomID   string
	alice    *commonv1.ContactLink
	bob      *commonv1.ContactLink
	aliceSub string
	bobSub   string
}

func (s *MessageBusinessTestSuite) newStawiFixture(t *testing.T, dep *definition.DependencyOption) *stawiFixture {
	t.Helper()
	ctx, svc := s.CreateService(t, dep)
	f := &stawiFixture{
		ctx:      ctx,
		rooms:    stawitest.NewRooms(),
		accounts: stawitest.NewAccounts(),
		alice:    &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()},
		bob:      &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()},
	}
	f.mb, f.rb = s.setupStawiBusinessLayer(ctx, svc, f)

	room, err := f.rb.CreateRoom(ctx, &chatv1.CreateRoomRequest{
		Name: "Savings group", Members: []*commonv1.ContactLink{f.bob},
	}, f.alice)
	require.NoError(t, err)
	f.roomID = room.GetId()
	for _, member := range []*commonv1.ContactLink{f.alice, f.bob} {
		s.WaitForMemberSubscription(ctx, svc, f.roomID, member.GetProfileId(), t)
		s.WaitForAuthzAccess(ctx, svc, member.GetProfileId(), f.roomID, t)
	}
	f.aliceSub = f.subscriptionOf(t, f.alice)
	f.bobSub = f.subscriptionOf(t, f.bob)
	return f
}

func (s *MessageBusinessTestSuite) setupStawiBusinessLayer(
	ctx context.Context, svc *frame.Service, f *stawiFixture,
) (business.MessageBusiness, business.RoomBusiness) {
	workMan := svc.WorkManager()
	evtsMan := svc.EventsManager()
	dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)
	f.dbPool, f.workMan, f.authz = dbPool, workMan, s.AuthzMiddleware
	f.keto = svc.SecurityManager().GetAuthorizer(ctx)

	roomRepo := repository.NewRoomRepository(ctx, dbPool, workMan)
	eventRepo := repository.NewRoomEventRepository(ctx, dbPool, workMan)
	outboxRepo := repository.NewRoomOutboxRepository(ctx, dbPool, workMan)
	f.subRepo = repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)
	f.bindings = repository.NewStawiRoomRepository(ctx, dbPool, workMan)
	f.calls = repository.NewStawiRoomCallRepository(ctx, dbPool, workMan)

	subscriptionSvc := business.NewSubscriptionService(svc, f.subRepo)
	mb := business.NewMessageBusiness(evtsMan, eventRepo, outboxRepo, f.subRepo, subscriptionSvc, s.AuthzMiddleware,
		business.WithStawiRooms(business.StawiDeps{
			Rooms: f.rooms, Accounts: f.accounts, RoomRepo: roomRepo, Bindings: f.bindings, CallRepo: f.calls,
		}),
		business.WithServiceCards(authorizer.NewFunctionChecker(f.keto, business.ServiceNamespace)))
	rb := business.NewRoomBusiness(svc, roomRepo, eventRepo, f.subRepo, nil, subscriptionSvc, evtsMan, mb, nil,
		s.AuthzMiddleware, business.WithStawiBindings(f.bindings))
	return mb, rb
}

func (f *stawiFixture) subscriptionOf(t *testing.T, member *commonv1.ContactLink) string {
	t.Helper()
	subs, err := f.subRepo.GetByContactLinkAndRooms(f.ctx, &commonv1.ContactLink{ProfileId: member.GetProfileId()},
		f.roomID)
	require.NoError(t, err)
	require.Len(t, subs, 1)
	return subs[0].GetID()
}

func (f *stawiFixture) send(t *testing.T, sender *commonv1.ContactLink, payload *chatv1.Payload) *chatv1.AckEvent {
	t.Helper()
	acks, err := f.mb.SendEvents(f.ctx, &chatv1.SendEventRequest{Event: []*chatv1.RoomEvent{{
		RoomId: f.roomID, Type: chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT, Payload: payload,
	}}}, sender)
	require.NoError(t, err)
	require.Len(t, acks, 1)
	return acks[0]
}

func (f *stawiFixture) history(t *testing.T) []*chatv1.RoomEvent {
	t.Helper()
	events, err := f.mb.GetHistory(f.ctx, &chatv1.GetHistoryRequest{RoomId: f.roomID}, f.alice)
	require.NoError(t, err)
	return events
}

func (f *stawiFixture) outcomesFor(t *testing.T, sourceEventID string) []*chatv1.StawiCallOutcomeContent {
	t.Helper()
	var out []*chatv1.StawiCallOutcomeContent
	for _, evt := range f.history(t) {
		if o := evt.GetPayload().GetStawiCallOutcome(); o != nil && o.GetSourceEventId() == sourceEventID {
			require.Equal(t, sourceEventID, evt.GetParentId(), "an outcome replies to the act")
			require.Equal(t, chatv1.RoomEventType_ROOM_EVENT_TYPE_SYSTEM, evt.GetType())
			out = append(out, o)
		}
	}
	return out
}

func (f *stawiFixture) stored(t *testing.T, eventID string) *chatv1.RoomEvent {
	t.Helper()
	for _, evt := range f.history(t) {
		if evt.GetId() == eventID {
			return evt
		}
	}
	return nil
}

func (f *stawiFixture) activeSubscriptions(t *testing.T) int {
	t.Helper()
	subs, err := f.subRepo.GetByRoomID(f.ctx, f.roomID, nil)
	require.NoError(t, err)
	return len(subs)
}

func (f *stawiFixture) bind(t *testing.T) {
	t.Helper()
	row := &models.StawiRoom{State: models.StawiRoomStateBound, ChainID: 84532, CustodyAddress: "0xc0ffee"}
	row.ID = f.roomID
	require.NoError(t, f.bindings.Create(f.ctx, row))
}

func conversion(founders ...string) *chatv1.Payload {
	return &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_ROOM_CONVERSION,
		Data: &chatv1.Payload_StawiRoomConversion{StawiRoomConversion: &chatv1.StawiRoomConversionContent{
			TemplateId:             "chama-basic",
			RuleValues:             map[string]string{"contribution_amount": "5000"},
			FounderSubscriptionIds: founders,
			JoinPolicy:             chatv1.StawiJoinPolicy_STAWI_JOIN_POLICY_PRIVATE,
		}},
	}
}

func genesisSignature(genesisID string) *chatv1.Payload {
	return &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_GENESIS_SIGNATURE,
		Data: &chatv1.Payload_StawiGenesisSignature{StawiGenesisSignature: &chatv1.StawiGenesisSignatureContent{
			GenesisId: genesisID, Signature: deviceSig(), SignerKeyId: "device-key-1", Algorithm: "secp256k1",
		}},
	}
}

func signedCall(callID, kind string) *chatv1.Payload {
	return &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_SIGNED_CALL,
		Data: &chatv1.Payload_StawiSignedCall{StawiSignedCall: &chatv1.StawiSignedCallContent{
			CallId: callID, Kind: kind, Signature: deviceSig(), SignerKeyId: "device-key-1", Algorithm: "secp256k1",
		}},
	}
}

// deviceSig is a well-formed secp256k1 device signature (r ‖ s ‖ v).
func deviceSig() []byte {
	sig := make([]byte, 65)
	sig[64] = 27
	return sig
}

func requireAckOK(t *testing.T, ack *chatv1.AckEvent) string {
	t.Helper()
	require.Nil(t, ack.GetError(), "ack error: %v", ack.GetError())
	return ack.GetEventId()[0]
}

func requireAckRefused(t *testing.T, ack *chatv1.AckEvent, code connect.Code) {
	t.Helper()
	require.NotNil(t, ack.GetError())
	require.Equal(t, int32(code), ack.GetError().GetCode(), ack.GetError().GetMessage())
}

// TestStawiConversionRelaysAndStoresTheGenesisCard: a member converts the
// room; chat asks settlement for the genesis with the founders' profiles and
// stores the conversion with the genesis filled in. Subscriptions do not move.
func (s *MessageBusinessTestSuite) TestStawiConversionRelaysAndStoresTheGenesisCard() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		before := f.activeSubscriptions(t)

		eventID := requireAckOK(t, f.send(t, f.alice, conversion(f.aliceSub, f.bobSub)))

		require.Len(t, f.rooms.Prepared, 1)
		prepared := f.rooms.Prepared[0]
		require.Equal(t, f.roomID, prepared.ChatRoomID)
		require.ElementsMatch(t, []string{f.alice.GetProfileId(), f.bob.GetProfileId()}, prepared.FounderProfileIDs)
		require.Equal(t, f.alice.GetProfileId(), prepared.RequestedBy)
		require.Equal(t, stawi.JoinPolicyPrivate, prepared.JoinPolicy)

		card := f.stored(t, eventID).GetPayload().GetStawiRoomConversion()
		require.NotNil(t, card)
		require.NotEmpty(t, card.GetGenesis().GetGenesisId())
		require.NotEmpty(t, card.GetGenesis().GetGenesisHash())

		binding, err := f.bindings.GetByID(f.ctx, f.roomID)
		require.NoError(t, err)
		require.Equal(t, models.StawiRoomStatePending, binding.State)
		require.Equal(t, card.GetGenesis().GetGenesisId(), binding.GenesisID)
		require.Equal(t, before, f.activeSubscriptions(t), "nothing about subscriptions changes on send")
	})
}

// TestStawiConversionRefusals covers acts refused back to the sender (stored
// nowhere) and acts settlement refuses (stored, with a FAILED outcome).
func (s *MessageBusinessTestSuite) TestStawiConversionRefusals() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)

		// A founder who is not a member of the room.
		requireAckRefused(t, f.send(t, f.alice, conversion(f.aliceSub, "notamember")), connect.CodeInvalidArgument)
		require.Empty(t, f.rooms.Prepared)

		// Settlement unreachable: the sender retries; nothing is stored.
		f.rooms.Refuse(stawitest.MethodPrepareRoomGenesis,
			connect.NewError(connect.CodeUnavailable, context.DeadlineExceeded))
		ack := f.send(t, f.alice, conversion(f.aliceSub))
		requireAckRefused(t, ack, connect.CodeUnavailable)
		require.Nil(t, f.stored(t, ack.GetEventId()[0]))

		// Settlement refuses: the act is stored and the room is told why.
		f.rooms.Refuse(stawitest.MethodPrepareRoomGenesis, stawitest.Refusal("template chama-basic needs 3 founders"))
		eventID := requireAckOK(t, f.send(t, f.alice, conversion(f.aliceSub)))
		require.NotNil(t, f.stored(t, eventID))
		outcomes := f.outcomesFor(t, eventID)
		require.Len(t, outcomes, 1)
		require.Equal(t, chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_FAILED, outcomes[0].GetState())
		require.Equal(t, "template chama-basic needs 3 founders", outcomes[0].GetReason())

		// A bound room cannot be converted again.
		f.rooms.Refuse(stawitest.MethodPrepareRoomGenesis, nil)
		f.bind(t)
		requireAckRefused(t, f.send(t, f.alice, conversion(f.aliceSub)), connect.CodeFailedPrecondition)
	})
}

// TestStawiGenesisSignatureOnlyFromAFounder relays a founder's signature with
// the founder's own profile, and refuses anyone else, whatever they claim.
func (s *MessageBusinessTestSuite) TestStawiGenesisSignatureOnlyFromAFounder() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		requireAckOK(t, f.send(t, f.alice, conversion(f.aliceSub)))
		binding, err := f.bindings.GetByID(f.ctx, f.roomID)
		require.NoError(t, err)

		// Bob is a member but not a founder of this genesis.
		requireAckRefused(t, f.send(t, f.bob, genesisSignature(binding.GenesisID)), connect.CodePermissionDenied)
		// Not the room's genesis.
		requireAckRefused(t, f.send(t, f.alice, genesisSignature("some-other-genesis")), connect.CodeFailedPrecondition)
		require.Empty(t, f.rooms.Signatures(binding.GenesisID))

		eventID := requireAckOK(t, f.send(t, f.alice, genesisSignature(binding.GenesisID)))
		sigs := f.rooms.Signatures(binding.GenesisID)
		require.Len(t, sigs, 1)
		require.Equal(t, f.alice.GetProfileId(), sigs[0].SignerProfileID)
		outcomes := f.outcomesFor(t, eventID)
		require.Len(t, outcomes, 1)
		require.Equal(t, chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_ACCEPTED, outcomes[0].GetState())
		require.Equal(t, binding.GenesisID, outcomes[0].GetGenesisId())
	})
}

// TestStawiSignedCallOnlyFromItsSigner relays a call only when the sender's
// profile owns the account settlement names as the call's signer, the call is
// for this room and the kind matches settlement's record.
func (s *MessageBusinessTestSuite) TestStawiSignedCallOnlyFromItsSigner() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		f.accounts.Own("0xA11CE", f.alice.GetProfileId())
		f.accounts.Own("0xB0B", f.bob.GetProfileId())
		f.rooms.AddCall(stawi.RoomCall{CallID: "call-invite", RoomID: f.roomID, Kind: "INVITE",
			SignerAddress: "0xa11ce", Nonce: 7})
		f.rooms.AddCall(stawi.RoomCall{CallID: "call-elsewhere", RoomID: util.IDString(), Kind: "INVITE",
			SignerAddress: "0xa11ce", Nonce: 8})

		// Calls need the room on chain.
		requireAckRefused(t, f.send(t, f.alice, signedCall("call-invite", "INVITE")), connect.CodeFailedPrecondition)
		f.bind(t)
		before := f.activeSubscriptions(t)

		requireAckRefused(t, f.send(t, f.bob, signedCall("call-invite", "INVITE")), connect.CodePermissionDenied)
		requireAckRefused(t, f.send(t, f.alice, signedCall("call-elsewhere", "INVITE")), connect.CodePermissionDenied)
		requireAckRefused(t, f.send(t, f.alice, signedCall("call-invite", "CAST_VOTE")), connect.CodeInvalidArgument)
		requireAckRefused(t, f.send(t, f.alice, signedCall("no-such-call", "INVITE")), connect.CodeFailedPrecondition)
		require.Empty(t, f.rooms.Submitted)

		eventID := requireAckOK(t, f.send(t, f.alice, signedCall("call-invite", "INVITE")))
		require.Len(t, f.rooms.Submitted, 1)
		require.Equal(t, f.alice.GetProfileId(), f.rooms.Submitted[0].SignerProfileID)
		outcomes := f.outcomesFor(t, eventID)
		require.Len(t, outcomes, 1)
		require.Equal(t, chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_ACCEPTED, outcomes[0].GetState())
		require.Equal(t, "call-invite", outcomes[0].GetCallId())

		tracked, err := f.calls.FindBySigner(f.ctx, f.roomID, "0xA11CE", 7)
		require.NoError(t, err)
		require.Equal(t, "call-invite", tracked.GetID())
		require.Equal(t, eventID, tracked.SourceEventID)

		// Settlement refuses at relay: stored, FAILED with the reason.
		f.rooms.AddCall(stawi.RoomCall{CallID: "call-vote", RoomID: f.roomID, Kind: "CAST_VOTE",
			SignerAddress: "0xb0b", Nonce: 1})
		f.rooms.Refuse(stawitest.MethodSubmitRoomCall, stawitest.Refusal("simulation reverted: voting closed"))
		eventID = requireAckOK(t, f.send(t, f.bob, signedCall("call-vote", "CAST_VOTE")))
		outcomes = f.outcomesFor(t, eventID)
		require.Len(t, outcomes, 1)
		require.Equal(t, chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_FAILED, outcomes[0].GetState())
		require.Equal(t, "simulation reverted: voting closed", outcomes[0].GetReason())

		require.Equal(t, before, f.activeSubscriptions(t), "nothing about subscriptions changes on send")
	})
}

// TestStawiActRetryIsRelayedOnce: resending an act with its event id is
// acknowledged without a second relay.
func (s *MessageBusinessTestSuite) TestStawiActRetryIsRelayedOnce() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		eventID := util.IDString()
		for range 2 {
			acks, err := f.mb.SendEvents(f.ctx, &chatv1.SendEventRequest{Event: []*chatv1.RoomEvent{{
				Id: eventID, RoomId: f.roomID, Type: chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT,
				Payload: conversion(f.aliceSub),
			}}}, f.alice)
			require.NoError(t, err)
			require.Nil(t, acks[0].GetError())
		}
		require.Len(t, f.rooms.Prepared, 1)
	})
}

// TestStawiRelayFollowsSettlementsRoomServiceRules: the converting admin must
// be a founder; a call settlement prepared for another member's profile is
// refused even when the signer account resolves to the sender; the device
// signature reaches settlement whole.
func (s *MessageBusinessTestSuite) TestStawiRelayFollowsSettlementsRoomServiceRules() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)

		requireAckRefused(t, f.send(t, f.alice, conversion(f.bobSub)), connect.CodeInvalidArgument)
		require.Empty(t, f.rooms.Prepared, "settlement would refuse an admin who is not a founder")

		f.bind(t)
		f.accounts.Own("0xa11ce", f.alice.GetProfileId())
		f.rooms.AddCall(stawi.RoomCall{CallID: "call-for-bob", RoomID: f.roomID, Kind: "LEAVE",
			SignerAddress: "0xa11ce", Nonce: 1, ProfileID: f.bob.GetProfileId()})
		requireAckRefused(t, f.send(t, f.alice, signedCall("call-for-bob", "LEAVE")), connect.CodePermissionDenied)

		f.rooms.AddCall(stawi.RoomCall{CallID: "call-for-alice", RoomID: f.roomID, Kind: "LEAVE",
			SignerAddress: "0xa11ce", Nonce: 2, ProfileID: f.alice.GetProfileId()})
		webauthn := signedCall("call-for-alice", "LEAVE")
		content := webauthn.GetStawiSignedCall()
		content.Algorithm, content.Signature = "p256-webauthn", make([]byte, 128)
		content.WebauthnAuthenticatorData, content.WebauthnClientDataJson = []byte("auth"), []byte("{}")
		requireAckOK(t, f.send(t, f.alice, webauthn))
		require.Len(t, f.rooms.Submitted, 1)
		sig := f.rooms.Submitted[0].Signature
		require.Equal(t, "p256-webauthn", sig.Algorithm)
		require.Equal(t, "device-key-1", sig.KeyID)
		require.Len(t, sig.Signature, 128)
		require.Equal(t, []byte("auth"), sig.AuthenticatorData)
		require.Equal(t, []byte("{}"), sig.ClientDataJSON)
	})
}
