package business_test

import (
	"testing"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect/v2"
	"github.com/pitabwire/frame/v3/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/stawi"
)

// An invitee holds the proposed subscription chat writes from the chain's
// MemberInvited fact, and accepting is a signed call sent into the room: the
// invitee may send exactly that act, and nothing else, until the chain admits
// them.
func (s *MessageBusinessTestSuite) TestStawiInviteeMayOnlyAcceptTheirInvitation() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		f.bind(t)
		clare := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		invitee := &models.RoomSubscription{
			RoomID:            f.roomID,
			ProfileID:         clare.GetProfileId(),
			ContactID:         clare.GetContactId(),
			SubscriptionState: models.RoomSubscriptionStateProposed,
			Role:              "member",
		}
		invitee.GenID(f.ctx)
		require.NoError(t, f.subRepo.Create(f.ctx, invitee))
		f.accounts.Own("0xC1A4E", clare.GetProfileId())
		f.rooms.AddCall(stawi.RoomCall{CallID: "call-accept", RoomID: f.roomID, Kind: "ACCEPT_INVITATION",
			SignerAddress: "0xc1a4e", Nonce: 1})
		f.rooms.AddCall(stawi.RoomCall{CallID: "call-vote", RoomID: f.roomID, Kind: "CAST_VOTE",
			SignerAddress: "0xc1a4e", Nonce: 2})

		text := &chatv1.Payload{Type: chatv1.PayloadType_PAYLOAD_TYPE_TEXT,
			Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "hello"}}}
		acks, err := f.mb.SendEvents(f.ctx, &chatv1.SendEventRequest{Event: []*chatv1.RoomEvent{{
			RoomId: f.roomID, Type: chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE, Payload: text}}}, clare)
		require.NoError(t, err)
		require.NotNil(t, acks[0].GetError(), "an invitee cannot talk in the room yet")
		require.NotNil(t, f.send(t, clare, signedCall("call-vote", "CAST_VOTE")).GetError(), "nor vote")
		// A call that names itself an acceptance but is not one, by
		// settlement's record, is refused by the relay.
		requireAckRefused(
			t,
			f.send(t, clare, signedCall("call-vote", "ACCEPT_INVITATION")),
			connect.CodeInvalidArgument,
		)
		require.Empty(t, f.rooms.Submitted)

		eventID := requireAckOK(t, f.send(t, clare, signedCall("call-accept", "ACCEPT_INVITATION")))
		require.Len(t, f.rooms.Submitted, 1)
		require.Equal(t, clare.GetProfileId(), f.rooms.Submitted[0].SignerProfileID)
		outcomes := f.outcomesFor(t, eventID)
		require.Len(t, outcomes, 1)
		require.Equal(t, chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_ACCEPTED, outcomes[0].GetState())
	})
}
