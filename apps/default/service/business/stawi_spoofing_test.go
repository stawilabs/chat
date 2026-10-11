package business_test

import (
	"testing"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/pitabwire/frame/v2/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
)

// TestMembersCannotSendOfficialLookingContent: cards, room changes, call
// outcomes, tallies and system events come from the server (or, for cards,
// the service card path) — never from a member, however the payload is
// declared. Ordinary messages still go through.
func (s *MessageBusinessTestSuite) TestMembersCannotSendOfficialLookingContent() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		card := &chatv1.Payload_FinanceCard{FinanceCard: &chatv1.FinanceCardContent{
			CardId: "c", GroupId: "g", Kind: "CONTRIBUTION", Title: "Bob paid 5000"}}
		change := &chatv1.Payload_RoomChange{RoomChange: &chatv1.RoomChangeContent{
			Action: chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_MEMBER_REMOVED, Body: "Bob was removed"}}
		tally := &chatv1.Payload_MotionTally{MotionTally: &chatv1.MotionTally{MotionId: "m", Passed: true}}
		voteTally := &chatv1.Payload_VoteTally{VoteTally: &chatv1.VoteTally{ChoiceId: "yes", Count: 9}}
		text := &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "hi", Format: "plain"}}

		type send struct {
			payload   *chatv1.Payload
			eventType chatv1.RoomEventType
		}
		event := chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT
		for name, c := range map[string]send{
			"finance card":               {&chatv1.Payload{Type: chatv1.PayloadType_PAYLOAD_TYPE_FINANCE_CARD, Data: card}, event},
			"finance card declared text": {&chatv1.Payload{Type: chatv1.PayloadType_PAYLOAD_TYPE_TEXT, Data: card}, event},
			"finance card undeclared":    {&chatv1.Payload{Data: card}, event},
			"room change":                {&chatv1.Payload{Type: chatv1.PayloadType_PAYLOAD_TYPE_ROOM_CHANGE, Data: change}, chatv1.RoomEventType_ROOM_EVENT_TYPE_SYSTEM},
			"room change as an event":    {&chatv1.Payload{Type: chatv1.PayloadType_PAYLOAD_TYPE_ROOM_CHANGE, Data: change}, event},
			"room change undeclared":     {&chatv1.Payload{Data: change}, event},
			"text declared room change":  {&chatv1.Payload{Type: chatv1.PayloadType_PAYLOAD_TYPE_ROOM_CHANGE, Data: text}, event},
			"motion tally":               {&chatv1.Payload{Type: chatv1.PayloadType_PAYLOAD_TYPE_MOTION_TALLY, Data: tally}, event},
			"vote tally":                 {&chatv1.Payload{Type: chatv1.PayloadType_PAYLOAD_TYPE_VOTE_TALLY, Data: voteTally}, event},
			"text as a system event":     {&chatv1.Payload{Type: chatv1.PayloadType_PAYLOAD_TYPE_TEXT, Data: text}, chatv1.RoomEventType_ROOM_EVENT_TYPE_SYSTEM},
		} {
			t.Run(name, func(t *testing.T) {
				acks, err := f.mb.SendEvents(f.ctx, &chatv1.SendEventRequest{Event: []*chatv1.RoomEvent{{
					RoomId: f.roomID, Type: c.eventType, Payload: c.payload,
				}}}, f.alice)
				require.NoError(t, err)
				require.NotNil(t, acks[0].GetError(), "must be refused")
				require.Equal(t, int32(connect.CodePermissionDenied), acks[0].GetError().GetCode(),
					acks[0].GetError().GetMessage())
				require.Nil(t, f.stored(t, acks[0].GetEventId()[0]))
			})
		}

		requireAckOK(t, f.send(t, f.alice, &chatv1.Payload{Type: chatv1.PayloadType_PAYLOAD_TYPE_TEXT, Data: text}))
	})
}

// TestTheSenderIsTheAuthenticatedCaller: an event naming another member's
// subscription, or a moderation naming another actor, is refused; naming
// oneself is fine and the stored sender is always the caller's subscription.
func (s *MessageBusinessTestSuite) TestTheSenderIsTheAuthenticatedCaller() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		text := &chatv1.Payload{Type: chatv1.PayloadType_PAYLOAD_TYPE_TEXT,
			Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "hi", Format: "plain"}}}
		moderation := func(actor string) *chatv1.Payload {
			return &chatv1.Payload{Type: chatv1.PayloadType_PAYLOAD_TYPE_MODERATION,
				Data: &chatv1.Payload_Moderation{Moderation: &chatv1.ModerationContent{
					Body: "muted for spam", ActorSubscriptionId: actor}}}
		}
		sendAs := func(subscriptionID string, payload *chatv1.Payload) *chatv1.AckEvent {
			acks, err := f.mb.SendEvents(f.ctx, &chatv1.SendEventRequest{Event: []*chatv1.RoomEvent{{
				RoomId: f.roomID, SubscriptionId: subscriptionID, Type: chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
				Payload: payload,
			}}}, f.alice)
			require.NoError(t, err)
			return acks[0]
		}

		requireAckRefused(t, sendAs(f.bobSub, text), connect.CodePermissionDenied)
		requireAckRefused(t, sendAs("", moderation(f.bobSub)), connect.CodePermissionDenied)

		own := requireAckOK(t, sendAs(f.aliceSub, text))
		require.Equal(t, f.aliceSub, f.stored(t, own).GetSubscriptionId())
		anonymous := requireAckOK(t, sendAs("", text))
		require.Equal(t, f.aliceSub, f.stored(t, anonymous).GetSubscriptionId())
		requireAckOK(t, sendAs("", moderation(f.aliceSub)))
	})
}

// TestSentEventsCannotBeRewritten: resending an existing event id with other
// content (an "edit" of a signed call or a conversion) changes nothing.
func (s *MessageBusinessTestSuite) TestSentEventsCannotBeRewritten() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		id := util.IDString()
		first, err := f.mb.SendEvents(f.ctx, &chatv1.SendEventRequest{Event: []*chatv1.RoomEvent{{
			Id: id, RoomId: f.roomID, Type: chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT,
			Payload: conversion(f.aliceSub),
		}}}, f.alice)
		require.NoError(t, err)
		require.Nil(t, first[0].GetError())
		original := f.stored(t, id).GetPayload().GetStawiRoomConversion()

		rewrite := conversion(f.aliceSub, f.bobSub)
		rewrite.GetStawiRoomConversion().TemplateId = "other-template"
		_, err = f.mb.SendEvents(f.ctx, &chatv1.SendEventRequest{Event: []*chatv1.RoomEvent{{
			Id: id, RoomId: f.roomID, Type: chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT, Payload: rewrite,
		}}}, f.alice)
		require.NoError(t, err)

		after := f.stored(t, id).GetPayload().GetStawiRoomConversion()
		require.Equal(t, original.GetTemplateId(), after.GetTemplateId())
		require.Equal(t, original.GetFounderSubscriptionIds(), after.GetFounderSubscriptionIds())
		require.Equal(t, original.GetGenesis().GetGenesisId(), after.GetGenesis().GetGenesisId())
		require.Len(t, f.rooms.Prepared, 1, "the rewrite was not relayed")
	})
}

// TestServerRoomChangesStillPost: the server's own room-change events (here
// from a role change) are still stored.
func (s *MessageBusinessTestSuite) TestServerRoomChangesStillPost() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		_, err := f.rb.UpdateRoom(f.ctx, &chatv1.UpdateRoomRequest{RoomId: f.roomID, Name: "Renamed"}, f.alice)
		require.NoError(t, err)
		var changes int
		for _, evt := range f.history(t) {
			if evt.GetPayload().GetRoomChange() != nil {
				changes++
			}
		}
		require.Positive(t, changes)
	})
}
