package models_test

import (
	"testing"
	"time"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/stawilabs/chat/apps/default/service/models"
)

// TestPayloadConverter_StawiPayloadsRoundTrip stores each Stawi payload the
// way the send path does and reads it back the way history does: nothing a
// client or settlement depends on (bytes, maps, the server-filled genesis)
// may be lost in the JSON column.
func TestPayloadConverter_StawiPayloadsRoundTrip(t *testing.T) {
	expires := timestamppb.New(time.Unix(1_900_000_000, 0))
	cases := map[string]*chatv1.Payload{
		"conversion": {
			Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_ROOM_CONVERSION,
			Data: &chatv1.Payload_StawiRoomConversion{StawiRoomConversion: &chatv1.StawiRoomConversionContent{
				TemplateId:             "chama-basic",
				RuleValues:             map[string]string{"contribution_amount": "5000", "period": "MONTHLY"},
				FounderSubscriptionIds: []string{"sub-a", "sub-b"},
				JoinPolicy:             chatv1.StawiJoinPolicy_STAWI_JOIN_POLICY_PRIVATE,
				Genesis: &chatv1.StawiGenesis{
					GenesisId:         "gen-1",
					GenesisHash:       []byte{0x01, 0x02, 0xff},
					ConstitutionHash:  []byte{0xaa},
					ExpiresAt:         expires,
					FounderProfileIds: []string{"p-a", "p-b"},
				},
			}},
		},
		"genesis signature": {
			Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_GENESIS_SIGNATURE,
			Data: &chatv1.Payload_StawiGenesisSignature{StawiGenesisSignature: &chatv1.StawiGenesisSignatureContent{
				GenesisId:   "gen-1",
				Signature:   []byte{0x30, 0x45, 0x00, 0x01},
				SignerKeyId: "key-1",
			}},
		},
		"signed call": {
			Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_SIGNED_CALL,
			Data: &chatv1.Payload_StawiSignedCall{StawiSignedCall: &chatv1.StawiSignedCallContent{
				CallId:      "call-1",
				Kind:        "CAST_VOTE",
				Signature:   []byte{0x30, 0x44},
				SignerKeyId: "key-1",
				Summary:     "Vote yes on proposal 3",
			}},
		},
		"call outcome": {
			Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_CALL_OUTCOME,
			Data: &chatv1.Payload_StawiCallOutcome{StawiCallOutcome: &chatv1.StawiCallOutcomeContent{
				CallId:        "call-1",
				State:         chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_OBSERVED,
				SourceEventId: "d3l2p7rh1v8s73a0abcd",
				Kind:          "VOTE_CAST",
				ChainId:       84532,
				TxHash:        []byte{0xde, 0xad},
				BlockNumber:   12,
				LogIndex:      3,
			}},
		},
	}

	converter := models.NewPayloadConverter()
	for name, payload := range cases {
		t.Run(name, func(t *testing.T) {
			content, err := converter.FromProto(payload)
			require.NoError(t, err)
			require.EqualValues(t, payload.GetType().Number(), content[models.PayloadTypeField])
			require.Contains(t, content, models.ContentField, "the typed content must be stored")

			restored, err := converter.ToProto(content)
			require.NoError(t, err)
			require.True(t, proto.Equal(payload, restored), "want %v\ngot  %v", payload, restored)
		})
	}
}

// TestPayloadConverter_InfersStawiPayloadType fills in the type from the
// populated member when a client leaves it unspecified, as for every other
// payload.
func TestPayloadConverter_InfersStawiPayloadType(t *testing.T) {
	converter := models.NewPayloadConverter()
	content, err := converter.FromProto(&chatv1.Payload{
		Data: &chatv1.Payload_StawiSignedCall{StawiSignedCall: &chatv1.StawiSignedCallContent{CallId: "call-1"}},
	})
	require.NoError(t, err)
	require.EqualValues(t, chatv1.PayloadType_PAYLOAD_TYPE_STAWI_SIGNED_CALL.Number(), content[models.PayloadTypeField])
}
