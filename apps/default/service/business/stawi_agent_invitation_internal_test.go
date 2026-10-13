package business

import (
	"testing"
	"time"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/types/known/timestamppb"
)

// TestAgentAcceptanceHolds decides one acceptance on the expiries chat
// stamped: for the converter's invitation to exactly this room, after the
// invitation and before it expired, and not expired itself.
func TestAgentAcceptanceHolds(t *testing.T) {
	now := time.Unix(1_800_000_000, 0)
	day := 24 * time.Hour
	invitedAt, acceptedAt := now.Add(-2*day), now.Add(-day)
	invitation := func(roomID string, at time.Time) *chatv1.StawiAgentInvitationContent {
		return &chatv1.StawiAgentInvitationContent{
			RoomId: roomID, ExpiresAt: timestamppb.New(at.Add(agentInvitationTTL)),
		}
	}
	acceptance := func(roomID string, at time.Time) *chatv1.StawiAgentAcceptanceContent {
		return &chatv1.StawiAgentAcceptanceContent{
			InvitationEventId: "inv", RoomId: roomID, ExpiresAt: timestamppb.New(at.Add(agentInvitationTTL)),
		}
	}

	for name, tc := range map[string]struct {
		inviter    string
		invitation *chatv1.StawiAgentInvitationContent
		acceptance *chatv1.StawiAgentAcceptanceContent
		at         time.Time
		holds      bool
	}{
		"accepted":                  {"conv", invitation("room", invitedAt), acceptance("room", acceptedAt), now, true},
		"invited by someone else":   {"other", invitation("room", invitedAt), acceptance("room", acceptedAt), now, false},
		"no invitation":             {"conv", nil, acceptance("room", acceptedAt), now, false},
		"invitation for another":    {"conv", invitation("other", invitedAt), acceptance("room", acceptedAt), now, false},
		"acceptance for another":    {"conv", invitation("room", invitedAt), acceptance("other", acceptedAt), now, false},
		"accepted before invited":   {"conv", invitation("room", acceptedAt), acceptance("room", invitedAt), now, false},
		"accepted at the same time": {"conv", invitation("room", invitedAt), acceptance("room", invitedAt), now, false},
		"accepted after it expired": {
			"conv", invitation("room", invitedAt), acceptance("room", invitedAt.Add(agentInvitationTTL+time.Second)),
			invitedAt.Add(agentInvitationTTL + time.Minute), false,
		},
		"acceptance expired": {
			"conv", invitation("room", invitedAt), acceptance("room", acceptedAt),
			acceptedAt.Add(agentInvitationTTL), false,
		},
		"acceptance unstamped": {
			"conv", invitation("room", invitedAt),
			&chatv1.StawiAgentAcceptanceContent{InvitationEventId: "inv", RoomId: "room"}, now, false,
		},
	} {
		t.Run(name, func(t *testing.T) {
			require.Equal(t, tc.holds,
				agentAcceptanceHolds(tc.inviter, tc.invitation, tc.acceptance, "room", "conv", tc.at))
		})
	}
}
