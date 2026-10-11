package business

import (
	"context"
	"testing"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/stawi/stawitest"
)

// TestRelayRefusesASenderWithoutAnActiveSubscription is the relay's own
// guard, independent of the send path's subscription and Keto checks: an act
// with no sending subscription, or one that is not active, never reaches
// settlement.
func TestRelayRefusesASenderWithoutAnActiveSubscription(t *testing.T) {
	rooms := stawitest.NewRooms()
	relay := &stawiRelay{rooms: rooms, accounts: stawitest.NewAccounts(), converter: models.NewPayloadConverter()}

	blocked := &models.RoomSubscription{ProfileID: "p-1", SubscriptionState: models.RoomSubscriptionStateBlocked}
	blocked.ID = "sub-blocked"
	proposed := &models.RoomSubscription{ProfileID: "p-1", SubscriptionState: models.RoomSubscriptionStateProposed}
	proposed.ID = "sub-proposed"
	noProfile := &models.RoomSubscription{SubscriptionState: models.RoomSubscriptionStateActive}
	noProfile.ID = "sub-anonymous"

	for name, sender := range map[string]*models.RoomSubscription{
		"no subscription":      nil,
		"removed subscription": blocked,
		"invited, not joined":  proposed,
		"no profile":           noProfile,
	} {
		t.Run(name, func(t *testing.T) {
			event := &models.RoomEvent{RoomID: "room-1"}
			event.ID = "evt-1"
			result := relay.relay(context.Background(), &stawiAct{
				event: event,
				payload: &chatv1.Payload{
					Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_SIGNED_CALL,
					Data: &chatv1.Payload_StawiSignedCall{StawiSignedCall: &chatv1.StawiSignedCallContent{
						CallId:      "call-1",
						Kind:        "INVITE",
						Signature:   make([]byte, 65),
						SignerKeyId: "k",
						Algorithm:   "secp256k1",
					}},
				},
				sender: sender,
			})
			require.Error(t, result.ack)
			require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(result.ack))
			require.Nil(t, result.outcome)
		})
	}
	require.Empty(t, rooms.Submitted)
	require.Empty(t, rooms.Prepared)
}
