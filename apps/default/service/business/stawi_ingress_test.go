package business_test

import (
	"testing"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/pitabwire/frame/v2/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
)

// TestForgedStawiOutcomeIsNeverStored sends a STAWI_CALL_OUTCOME through the
// path every client ingress funnels into, both declared as such and hidden
// under another declared type (which the payload converter would otherwise
// infer back into an outcome). Neither may be acknowledged or stored.
func (s *MessageBusinessTestSuite) TestForgedStawiOutcomeIsNeverStored() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		sender := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		room, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{Name: "Group room"}, sender)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), sender.GetProfileId(), t)
		s.WaitForAuthzAccess(ctx, svc, sender.GetProfileId(), room.GetId(), t)

		forged := &chatv1.Payload_StawiCallOutcome{StawiCallOutcome: &chatv1.StawiCallOutcomeContent{
			CallId: "call-1", State: chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_OBSERVED,
		}}
		for name, declared := range map[string]chatv1.PayloadType{
			"declared outcome":   chatv1.PayloadType_PAYLOAD_TYPE_STAWI_CALL_OUTCOME,
			"declared nothing":   chatv1.PayloadType_PAYLOAD_TYPE_UNSPECIFIED,
			"declared as text":   chatv1.PayloadType_PAYLOAD_TYPE_TEXT,
			"declared as a card": chatv1.PayloadType_PAYLOAD_TYPE_FINANCE_CARD,
		} {
			t.Run(name, func(t *testing.T) {
				acks, sendErr := messageBusiness.SendEvents(ctx, &chatv1.SendEventRequest{
					Event: []*chatv1.RoomEvent{{
						RoomId:  room.GetId(),
						Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT,
						Payload: &chatv1.Payload{Type: declared, Data: forged},
					}},
				}, sender)
				require.NoError(t, sendErr)
				require.Len(t, acks, 1)
				require.NotNil(t, acks[0].GetError())
				require.Equal(t, int32(connect.CodeInvalidArgument), acks[0].GetError().GetCode())
			})
		}

		history, err := messageBusiness.GetHistory(ctx, &chatv1.GetHistoryRequest{RoomId: room.GetId()}, sender)
		require.NoError(t, err)
		for _, evt := range history {
			require.NotEqual(t, chatv1.PayloadType_PAYLOAD_TYPE_STAWI_CALL_OUTCOME, evt.GetPayload().GetType(),
				"a client-sent outcome must never be stored")
			require.Nil(t, evt.GetPayload().GetStawiCallOutcome())
		}
	})
}
