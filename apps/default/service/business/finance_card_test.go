package business_test

import (
	"testing"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/pitabwire/frame/v2/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/types/known/structpb"
)

func financeCardEvent(roomID string, card *chatv1.FinanceCardContent) *chatv1.RoomEvent {
	return &chatv1.RoomEvent{
		RoomId: roomID,
		Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT,
		Payload: &chatv1.Payload{
			Type: chatv1.PayloadType_PAYLOAD_TYPE_FINANCE_CARD,
			Data: &chatv1.Payload_FinanceCard{FinanceCard: card},
		},
	}
}

func validFinanceCard() *chatv1.FinanceCardContent {
	return &chatv1.FinanceCardContent{
		CardId:  "fact-" + util.RandomAlphaNumericString(6),
		GroupId: "grp-1",
		Kind:    "PROPOSAL",
		Title:   "New proposal: buy a maize mill",
		Body:    "Open the card to review and sign your vote on your device.",
		Data:    map[string]string{"proposal_id": "prop-1", "action": "open_signing_flow"},
	}
}

// TestServiceSenderPostsFinanceCard covers the posting side of the finance
// card: the service account that renders finance facts into a group room
// sends one through the ordinary event path, and it round-trips unchanged.
func (s *MessageBusinessTestSuite) TestServiceSenderPostsFinanceCard() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		// The projection service owns the group room it renders into.
		serviceSender := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		metadata, mErr := structpb.NewStruct(map[string]any{"stawi.group_id": "grp-1"})
		require.NoError(t, mErr)

		room, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{
			Name:     "Group room",
			Metadata: metadata,
		}, serviceSender)
		require.NoError(t, err)
		require.Equal(t, "grp-1", room.GetMetadata().GetFields()["stawi.group_id"].GetStringValue(),
			"room metadata is persisted so the fact stream can opt in on it")

		s.WaitForMemberSubscription(ctx, svc, room.GetId(), serviceSender.GetProfileId(), t)
		s.WaitForAuthzAccess(ctx, svc, serviceSender.GetProfileId(), room.GetId(), t)

		card := validFinanceCard()
		acks, err := messageBusiness.SendEvents(ctx, &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{financeCardEvent(room.GetId(), card)},
		}, serviceSender)
		require.NoError(t, err)
		require.Len(t, acks, 1)
		require.Nil(t, acks[0].GetError())

		history, err := messageBusiness.GetHistory(ctx, &chatv1.GetHistoryRequest{
			RoomId: room.GetId(),
		}, serviceSender)
		require.NoError(t, err)
		require.NotEmpty(t, history)

		var stored *chatv1.FinanceCardContent
		for _, evt := range history {
			if evt.GetPayload().GetType() == chatv1.PayloadType_PAYLOAD_TYPE_FINANCE_CARD {
				stored = evt.GetPayload().GetFinanceCard()
			}
		}
		require.NotNil(t, stored, "the finance card is stored and served back")
		require.Equal(t, card.GetCardId(), stored.GetCardId())
		require.Equal(t, card.GetKind(), stored.GetKind())
		require.Equal(t, card.GetTitle(), stored.GetTitle())
		require.Equal(t, "prop-1", stored.GetData()["proposal_id"])
	})
}

// TestFinanceCardRejectedWhenMalformed keeps a card that cannot be rendered
// out of the room: the payload must be present, identified and typed as a
// room event.
func (s *MessageBusinessTestSuite) TestFinanceCardRejectedWhenMalformed() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		sender := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		room, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{Name: "Group room"}, sender)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), sender.GetProfileId(), t)
		s.WaitForAuthzAccess(ctx, svc, sender.GetProfileId(), room.GetId(), t)

		noCardID := validFinanceCard()
		noCardID.CardId = ""

		wrongEventType := financeCardEvent(room.GetId(), validFinanceCard())
		wrongEventType.Type = chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE

		emptyPayload := &chatv1.RoomEvent{
			RoomId:  room.GetId(),
			Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT,
			Payload: &chatv1.Payload{Type: chatv1.PayloadType_PAYLOAD_TYPE_FINANCE_CARD},
		}

		for name, event := range map[string]*chatv1.RoomEvent{
			"missing card id":  financeCardEvent(room.GetId(), noCardID),
			"wrong event type": wrongEventType,
			"empty payload":    emptyPayload,
		} {
			t.Run(name, func(t *testing.T) {
				acks, sendErr := messageBusiness.SendEvents(ctx, &chatv1.SendEventRequest{
					Event: []*chatv1.RoomEvent{event},
				}, sender)
				require.NoError(t, sendErr)
				require.Len(t, acks, 1)
				require.NotNil(t, acks[0].GetError())
				require.Equal(t, int32(connect.CodeInvalidArgument), acks[0].GetError().GetCode())
			})
		}
	})
}
