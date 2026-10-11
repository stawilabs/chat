package business

import (
	"testing"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/stretchr/testify/require"
)

func stawiEvent(payload *chatv1.Payload) *chatv1.RoomEvent {
	return &chatv1.RoomEvent{
		RoomId:  "d3l2p7rh1v8s73a0room",
		Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT,
		Payload: payload,
	}
}

func validConversion() *chatv1.StawiRoomConversionContent {
	return &chatv1.StawiRoomConversionContent{
		TemplateId:             "chama-basic",
		RuleValues:             map[string]string{"contribution_amount": "5000"},
		FounderSubscriptionIds: []string{"sub-aaa", "sub-bbb"},
		JoinPolicy:             chatv1.StawiJoinPolicy_STAWI_JOIN_POLICY_PRIVATE,
	}
}

func conversionPayload(c *chatv1.StawiRoomConversionContent) *chatv1.Payload {
	return &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_ROOM_CONVERSION,
		Data: &chatv1.Payload_StawiRoomConversion{StawiRoomConversion: c},
	}
}

func signaturePayload(c *chatv1.StawiGenesisSignatureContent) *chatv1.Payload {
	return &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_GENESIS_SIGNATURE,
		Data: &chatv1.Payload_StawiGenesisSignature{StawiGenesisSignature: c},
	}
}

func signedCallPayload(c *chatv1.StawiSignedCallContent) *chatv1.Payload {
	return &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_SIGNED_CALL,
		Data: &chatv1.Payload_StawiSignedCall{StawiSignedCall: c},
	}
}

func TestValidateStawiPayload_AcceptsWellFormedActs(t *testing.T) {
	for name, payload := range map[string]*chatv1.Payload{
		"conversion": conversionPayload(validConversion()),
		"genesis signature": signaturePayload(&chatv1.StawiGenesisSignatureContent{
			GenesisId: "gen-1", Signature: []byte{1, 2, 3}, SignerKeyId: "key-1",
		}),
		"signed call": signedCallPayload(&chatv1.StawiSignedCallContent{
			CallId: "call-1", Kind: "INVITE", Signature: []byte{1},
		}),
		"not a stawi payload": {
			Type: chatv1.PayloadType_PAYLOAD_TYPE_TEXT,
			Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "hi", Format: "plain"}},
		},
	} {
		t.Run(name, func(t *testing.T) {
			require.NoError(t, validateStawiPayload(stawiEvent(payload)))
		})
	}
}

func TestValidateStawiPayload_RefusesMalformedActs(t *testing.T) {
	withGenesis := validConversion()
	withGenesis.Genesis = &chatv1.StawiGenesis{GenesisId: "forged"}

	noFounders := validConversion()
	noFounders.FounderSubscriptionIds = nil

	duplicateFounders := validConversion()
	duplicateFounders.FounderSubscriptionIds = []string{"sub-aaa", "sub-aaa"}

	noJoinPolicy := validConversion()
	noJoinPolicy.JoinPolicy = chatv1.StawiJoinPolicy_STAWI_JOIN_POLICY_UNSPECIFIED

	wrongEventType := stawiEvent(conversionPayload(validConversion()))
	wrongEventType.Type = chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE

	cases := map[string]*chatv1.RoomEvent{
		"client-set genesis": stawiEvent(conversionPayload(withGenesis)),
		"no founders":        stawiEvent(conversionPayload(noFounders)),
		"duplicate founders": stawiEvent(conversionPayload(duplicateFounders)),
		"unspecified join":   stawiEvent(conversionPayload(noJoinPolicy)),
		"wrong event type":   wrongEventType,
		"missing content":    stawiEvent(&chatv1.Payload{Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_SIGNED_CALL}),
		"signature without key": stawiEvent(
			signaturePayload(&chatv1.StawiGenesisSignatureContent{GenesisId: "g", Signature: []byte{1}}),
		),
		"call without signature": stawiEvent(signedCallPayload(&chatv1.StawiSignedCallContent{
			CallId: "call-1", Kind: "INVITE",
		})),
		"type and content disagree": stawiEvent(&chatv1.Payload{
			Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_SIGNED_CALL,
			Data: &chatv1.Payload_StawiGenesisSignature{StawiGenesisSignature: &chatv1.StawiGenesisSignatureContent{
				GenesisId: "g", Signature: []byte{1}, SignerKeyId: "k",
			}},
		}),
		"client-sent outcome": stawiEvent(&chatv1.Payload{
			Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_CALL_OUTCOME,
			Data: &chatv1.Payload_StawiCallOutcome{StawiCallOutcome: &chatv1.StawiCallOutcomeContent{
				CallId: "call-1", State: chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_OBSERVED,
			}},
		}),
	}

	for name, event := range cases {
		t.Run(name, func(t *testing.T) {
			err := validateStawiPayload(event)
			require.Error(t, err)
			require.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
		})
	}
}
