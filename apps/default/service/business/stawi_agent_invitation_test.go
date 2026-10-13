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
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
)

func agentInvitation(roomID string) *chatv1.Payload {
	return &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_AGENT_INVITATION,
		Data: &chatv1.Payload_StawiAgentInvitation{StawiAgentInvitation: &chatv1.StawiAgentInvitationContent{
			RoomId: roomID,
		}},
	}
}

func agentAcceptance(invitationEventID string) *chatv1.Payload {
	return &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_AGENT_ACCEPTANCE,
		Data: &chatv1.Payload_StawiAgentAcceptance{StawiAgentAcceptance: &chatv1.StawiAgentAcceptanceContent{
			InvitationEventId: invitationEventID,
		}},
	}
}

// sendIn has member send payload as an event into roomID.
func (f *stawiFixture) sendIn(
	t *testing.T, roomID string, member *commonv1.ContactLink, payload *chatv1.Payload,
) *chatv1.AckEvent {
	t.Helper()
	acks, err := f.mb.SendEvents(f.as(member), &chatv1.SendEventRequest{Event: []*chatv1.RoomEvent{{
		RoomId: roomID, Type: chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT, Payload: payload,
	}}}, member)
	require.NoError(t, err)
	require.Len(t, acks, 1)
	return acks[0]
}

// storedIn is the event eventID of roomID as member reads it.
func (f *stawiFixture) storedIn(
	t *testing.T, roomID, eventID string, member *commonv1.ContactLink,
) *chatv1.RoomEvent {
	t.Helper()
	events, err := f.mb.GetHistory(f.as(member), &chatv1.GetHistoryRequest{RoomId: roomID}, member)
	require.NoError(t, err)
	for _, evt := range events {
		if evt.GetId() == eventID {
			return evt
		}
	}
	return nil
}

// convertNamingAgent has Alice convert the fixture room naming agent.
func (f *stawiFixture) convertNamingAgent(t *testing.T, agent *commonv1.ContactLink) *chatv1.AckEvent {
	t.Helper()
	payload := conversion(f.aliceSub)
	payload.GetStawiRoomConversion().AgentProfileId = agent.GetProfileId()
	return f.sendIn(t, f.roomID, f.alice, payload)
}

func (f *stawiFixture) requireAgentRefused(t *testing.T, agent *commonv1.ContactLink) {
	t.Helper()
	prepared := len(f.rooms.Prepared)
	ack := f.convertNamingAgent(t, agent)
	requireAckRefused(t, ack, connect.CodeInvalidArgument)
	require.Contains(t, ack.GetError().GetMessage(),
		"the agent must be a room member or someone who accepted your agent invitation for this room")
	require.Len(t, f.rooms.Prepared, prepared, "settlement is not asked")
}

func (f *stawiFixture) requireAgentAccepted(t *testing.T, agent *commonv1.ContactLink) {
	t.Helper()
	requireAckOK(t, f.convertNamingAgent(t, agent))
	require.Equal(t, agent.GetProfileId(), f.rooms.Prepared[len(f.rooms.Prepared)-1].AgentProfileID)
}

// dmSubscription is member's subscription of the DM.
func (f *stawiFixture) dmSubscription(t *testing.T, dm string, member *commonv1.ContactLink) string {
	t.Helper()
	subs, err := f.subRepo.GetByContactLinkAndRooms(f.ctx, &commonv1.ContactLink{ProfileId: member.GetProfileId()}, dm)
	require.NoError(t, err)
	require.Len(t, subs, 1)
	return subs[0].GetID()
}

// TestConversionCarriesTheAgent: a conversion may name the room's Stawi agent
// by profile. Chat hands settlement an active member of the room; anyone
// else, a DM partner who has written included, is refused without an
// accepted agent invitation, and settlement is not asked.
func (s *MessageBusinessTestSuite) TestConversionCarriesTheAgent() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		f.placeRoom(t, f.roomID, cardTenant, cardPartition)

		// No agent: settlement is given none.
		requireAckOK(t, f.convertNamingAgent(t, &commonv1.ContactLink{}))
		require.Empty(t, f.rooms.Prepared[0].AgentProfileID)

		// A stranger.
		f.requireAgentRefused(t, &commonv1.ContactLink{ProfileId: util.IDString()})

		// A DM partner who has written, and one who started the DM: neither
		// accepted an invitation.
		erin := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		f.write(t, f.dmOf(t, f.alice, erin), erin)
		f.requireAgentRefused(t, erin)
		frank := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		f.dmOf(t, frank, f.alice)
		f.requireAgentRefused(t, frank)

		// An active member of the room needs no invitation.
		f.requireAgentAccepted(t, f.bob)

		// A removed member.
		require.NoError(t, f.rb.RemoveRoomSubscriptions(f.ctx, &chatv1.RemoveRoomSubscriptionsRequest{
			RoomId: f.roomID, SubscriptionId: []string{f.bobSub},
		}, f.alice))
		f.requireAgentRefused(t, f.bob)
	})
}

// TestADMPartnerBecomesAgentOnlyByAcceptingAnInvitation: the converter
// invites a DM partner to be the agent of a named room; the partner accepts
// in the same DM; only then may the converter name them, for that room only.
func (s *MessageBusinessTestSuite) TestADMPartnerBecomesAgentOnlyByAcceptingAnInvitation() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		f.placeRoom(t, f.roomID, cardTenant, cardPartition)
		erin := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		dm := f.dmOf(t, f.alice, erin)
		f.write(t, dm, erin)

		// Uninvited: refused.
		f.requireAgentRefused(t, erin)

		// Invited and accepted, but for another of Alice's rooms: refused.
		other, err := f.rb.CreateRoom(f.as(f.alice), &chatv1.CreateRoomRequest{Name: "Other group"}, f.alice)
		require.NoError(t, err)
		f.placeRoom(t, other.GetId(), cardTenant, cardPartition)
		otherInvitation := requireAckOK(t, f.sendIn(t, dm, f.alice, agentInvitation(other.GetId())))
		requireAckOK(t, f.sendIn(t, dm, erin, agentAcceptance(otherInvitation)))
		f.requireAgentRefused(t, erin)

		// Invited for this room, not accepted: refused. Chat names the room
		// and stamps the expiry on the stored invitation, whatever was sent.
		sent := agentInvitation(f.roomID)
		sent.GetStawiAgentInvitation().RoomName = "Not the room's name"
		invitationID := requireAckOK(t, f.sendIn(t, dm, f.alice, sent))
		stored := f.storedIn(t, dm, invitationID, erin).GetPayload().GetStawiAgentInvitation()
		require.Equal(t, f.roomID, stored.GetRoomId())
		require.Equal(t, "Savings group", stored.GetRoomName())
		require.WithinDuration(t, time.Now().Add(7*24*time.Hour), stored.GetExpiresAt().AsTime(), time.Minute)
		f.requireAgentRefused(t, erin)

		// The inviter cannot accept her own invitation: refused, and still
		// no agent.
		requireAckRefused(t, f.sendIn(t, dm, f.alice, agentAcceptance(invitationID)), connect.CodePermissionDenied)
		f.requireAgentRefused(t, erin)

		// An acceptance of no invitation is refused.
		requireAckRefused(t, f.sendIn(t, dm, erin, agentAcceptance(util.IDString())), connect.CodeInvalidArgument)

		// Erin accepts: allowed. The acceptance carries the room.
		acceptanceID := requireAckOK(t, f.sendIn(t, dm, erin, agentAcceptance(invitationID)))
		accepted := f.storedIn(t, dm, acceptanceID, f.alice).GetPayload().GetStawiAgentAcceptance()
		require.Equal(t, f.roomID, accepted.GetRoomId())
		require.Equal(t, "Savings group", accepted.GetRoomName())
		require.True(t, accepted.GetExpiresAt().AsTime().After(stored.GetExpiresAt().AsTime()))
		f.requireAgentAccepted(t, erin)
	})
}

// TestAgentInvitationRefusals: an invitation is sent in a DM, for a group
// room the sender owns or administers that is not yet a Stawi room.
func (s *MessageBusinessTestSuite) TestAgentInvitationRefusals() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		f.placeRoom(t, f.roomID, cardTenant, cardPartition)
		erin := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		dm := f.dmOf(t, f.alice, erin)

		// Not in a DM.
		requireAckRefused(t, f.sendIn(t, f.roomID, f.alice, agentInvitation(f.roomID)), connect.CodeFailedPrecondition)
		// A room the sender is not in, and a room that does not exist.
		bobsDM := f.dmOf(t, f.bob, erin)
		requireAckRefused(t, f.sendIn(t, bobsDM, erin, agentInvitation(f.roomID)), connect.CodePermissionDenied)
		requireAckRefused(t, f.sendIn(t, dm, f.alice, agentInvitation(util.IDString())), connect.CodePermissionDenied)
		// A DM is never a Stawi room.
		requireAckRefused(t, f.sendIn(t, dm, f.alice, agentInvitation(dm)), connect.CodeFailedPrecondition)
		// A room already on chain.
		f.bind(t)
		requireAckRefused(t, f.sendIn(t, dm, f.alice, agentInvitation(f.roomID)), connect.CodeFailedPrecondition)
	})
}

// TestAnExpiredAgentAcceptanceIsRefused: an invitation can no longer be
// accepted once it expires, and an acceptance lets the converter name the
// agent only until it expires itself.
func (s *MessageBusinessTestSuite) TestAnExpiredAgentAcceptanceIsRefused() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		f.placeRoom(t, f.roomID, cardTenant, cardPartition)
		grace := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		dm := f.dmOf(t, f.alice, grace)
		events := repository.NewRoomEventRepository(f.ctx, f.dbPool, f.workMan)
		converter := models.NewPayloadConverter()
		store := func(sender string, payload *chatv1.Payload) string {
			t.Helper()
			content, err := converter.FromProto(payload)
			require.NoError(t, err)
			event := &models.RoomEvent{RoomID: dm, SenderID: sender, Content: content,
				EventType: int32(chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT)}
			event.GenID(f.ctx)
			require.NoError(t, events.Create(f.ctx, event))
			return event.GetID()
		}

		// Invited eight days ago, accepted seven days and an hour ago.
		now := time.Now()
		invitation := agentInvitation(f.roomID)
		invitation.GetStawiAgentInvitation().ExpiresAt = timestamppb.New(now.Add(-24 * time.Hour))
		invitationID := store(f.dmSubscription(t, dm, f.alice), invitation)
		acceptance := agentAcceptance(invitationID)
		acceptance.GetStawiAgentAcceptance().RoomId = f.roomID
		acceptance.GetStawiAgentAcceptance().ExpiresAt = timestamppb.New(now.Add(-time.Hour))
		store(f.dmSubscription(t, dm, grace), acceptance)
		f.requireAgentRefused(t, grace)

		// The expired invitation cannot be accepted again.
		requireAckRefused(t, f.sendIn(t, dm, grace, agentAcceptance(invitationID)), connect.CodeFailedPrecondition)
		f.requireAgentRefused(t, grace)
	})
}
