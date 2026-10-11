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

func requireChainManaged(t *testing.T, err error) {
	t.Helper()
	require.Error(t, err)
	require.Equal(t, connect.CodeFailedPrecondition, connect.CodeOf(err), err.Error())
	require.Contains(t, err.Error(), "STAWI_SIGNED_CALL", "the refusal points at the signed-call path")
}

// TestBoundStawiRoomRefusesChatNativeGovernance: once the chain has a room,
// its membership, roles, proposals and existence change only on chain. The
// plain RPCs and chat-native motions and votes are refused with a pointer to
// the signed-call path, and nothing changes.
func (s *MessageBusinessTestSuite) TestBoundStawiRoomRefusesChatNativeGovernance() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		f.bind(t)
		before := f.activeSubscriptions(t)
		carol := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}

		requireChainManaged(t, f.rb.AddRoomSubscriptions(f.ctx, &chatv1.AddRoomSubscriptionsRequest{
			RoomId:  f.roomID,
			Members: []*chatv1.RoomSubscription{{Member: carol, Roles: []string{"member"}}},
		}, f.alice))
		requireChainManaged(t, f.rb.RemoveRoomSubscriptions(f.ctx, &chatv1.RemoveRoomSubscriptionsRequest{
			RoomId: f.roomID, SubscriptionId: []string{f.bobSub},
		}, f.alice))
		requireChainManaged(t, f.rb.UpdateSubscriptionRole(f.ctx, &chatv1.UpdateSubscriptionRoleRequest{
			RoomId: f.roomID, SubscriptionId: f.bobSub, Roles: []string{"admin"},
		}, f.alice))
		requireChainManaged(t, f.rb.DeleteRoom(f.ctx, &chatv1.DeleteRoomRequest{RoomId: f.roomID}, f.alice))

		for name, payload := range map[string]*chatv1.Payload{
			"motion": {
				Type: chatv1.PayloadType_PAYLOAD_TYPE_MOTION,
				Data: &chatv1.Payload_Motion{Motion: &chatv1.MotionContent{Id: "m1", Title: "Buy a mill"}},
			},
			"vote": {
				Type: chatv1.PayloadType_PAYLOAD_TYPE_VOTE,
				Data: &chatv1.Payload_Vote{Vote: &chatv1.VoteCast{MotionId: "m1", ChoiceId: "yes"}},
			},
		} {
			t.Run(name, func(t *testing.T) {
				ack := f.send(t, f.alice, payload)
				require.NotNil(t, ack.GetError())
				require.Equal(t, int32(connect.CodeFailedPrecondition), ack.GetError().GetCode())
				require.Contains(t, ack.GetError().GetMessage(), "STAWI_SIGNED_CALL")
			})
		}

		// Ordinary conversation carries on.
		requireAckOK(t, f.send(t, f.bob, &chatv1.Payload{
			Type: chatv1.PayloadType_PAYLOAD_TYPE_TEXT,
			Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "hello", Format: "plain"}},
		}))

		require.Equal(t, before, f.activeSubscriptions(t))
		_, err := f.rb.GetRoom(f.ctx, f.roomID, f.alice)
		require.NoError(t, err, "the room still exists")
	})
}

// TestUnboundRoomKeepsChatNativeGovernance: a room the chain does not have
// (including one with a pending genesis) still uses the plain RPCs.
func (s *MessageBusinessTestSuite) TestUnboundRoomKeepsChatNativeGovernance() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		requireAckOK(t, f.send(t, f.alice, conversion(f.aliceSub))) // pending genesis only

		require.NoError(t, f.rb.RemoveRoomSubscriptions(f.ctx, &chatv1.RemoveRoomSubscriptionsRequest{
			RoomId: f.roomID, SubscriptionId: []string{f.bobSub},
		}, f.alice))
	})
}
