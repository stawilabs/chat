package business

import (
	"fmt"
	"strings"
	"testing"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"buf.build/go/protovalidate"
	"connectrpc.com/connect"
	"github.com/stretchr/testify/require"
)

func stawiEvent(payload *chatv1.Payload) *chatv1.RoomEvent {
	return &chatv1.RoomEvent{
		Id:      "d3l2p7rh1v8s73a0evt0",
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
			GenesisId: "gen-1", Signature: sig65(), SignerKeyId: "key-1", Algorithm: "secp256k1",
		}),
		"signed call": signedCallPayload(&chatv1.StawiSignedCallContent{
			CallId: "call-1", Kind: "INVITE", Signature: sig65(), SignerKeyId: "key-1", Algorithm: "secp256k1",
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
			signaturePayload(
				&chatv1.StawiGenesisSignatureContent{GenesisId: "g", Signature: sig65(), Algorithm: "secp256k1"},
			),
		),
		"call without signature": stawiEvent(signedCallPayload(&chatv1.StawiSignedCallContent{
			CallId: "call-1", Kind: "INVITE",
		})),
		"type and content disagree": stawiEvent(&chatv1.Payload{
			Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_SIGNED_CALL,
			Data: &chatv1.Payload_StawiGenesisSignature{StawiGenesisSignature: &chatv1.StawiGenesisSignatureContent{
				GenesisId: "g", Signature: sig65(), SignerKeyId: "k", Algorithm: "secp256k1",
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

// TestValidateStawiPayload_TypeMustMatchPopulatedContent closes the
// differential the converter opened: it infers the type from the populated
// member when the declared type is UNSPECIFIED (or stores nothing typed when
// another type is declared), so a Stawi member under any other declared type
// skipped validation and was stored as that Stawi type — a client could post
// a forged STAWI_CALL_OUTCOME or an unrelayed signed call. Every combination
// in which a Stawi type or a Stawi member appears must agree exactly.
func TestValidateStawiPayload_TypeMustMatchPopulatedContent(t *testing.T) {
	outcome := &chatv1.Payload_StawiCallOutcome{StawiCallOutcome: &chatv1.StawiCallOutcomeContent{
		CallId: "call-1", State: chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_OBSERVED,
	}}
	call := &chatv1.Payload_StawiSignedCall{StawiSignedCall: &chatv1.StawiSignedCallContent{
		CallId: "call-1", Kind: "INVITE", Signature: sig65(), SignerKeyId: "k", Algorithm: "secp256k1",
	}}
	cases := map[string]*chatv1.Payload{
		"outcome under UNSPECIFIED": {Type: chatv1.PayloadType_PAYLOAD_TYPE_UNSPECIFIED, Data: outcome},
		"outcome under TEXT":        {Type: chatv1.PayloadType_PAYLOAD_TYPE_TEXT, Data: outcome},
		"signed call under UNSPEC":  {Type: chatv1.PayloadType_PAYLOAD_TYPE_UNSPECIFIED, Data: call},
		"signed call under CARD":    {Type: chatv1.PayloadType_PAYLOAD_TYPE_FINANCE_CARD, Data: call},
		"signed call under OUTCOME": {Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_CALL_OUTCOME, Data: call},
		"outcome under SIGNED_CALL": {Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_SIGNED_CALL, Data: outcome},
		"stawi type with text member": {
			Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_SIGNED_CALL,
			Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "x", Format: "plain"}},
		},
		"unknown type with stawi member": {Type: chatv1.PayloadType(999), Data: call},
	}
	for name, payload := range cases {
		t.Run(name, func(t *testing.T) {
			err := validateStawiPayload(stawiEvent(payload))
			require.Error(t, err)
			require.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
		})
	}
}

// TestValidateStawiPayload_ShapeVerdictIsProtovalidate feeds one corpus to
// protovalidate and to the send path's validator and requires the same
// verdict on shape: chat has no hand-written shape rules that could drift
// from the proto. (Client-ingress policy — no outcomes, no genesis, event
// type — is checked on top and only ever rejects more.)
func TestValidateStawiPayload_ShapeVerdictIsProtovalidate(t *testing.T) {
	long := func(n int) string { return strings.Repeat("a", n) }
	sig := func(n int) []byte { return make([]byte, n) }

	conv := func(mut func(*chatv1.StawiRoomConversionContent)) *chatv1.Payload {
		c := validConversion()
		mut(c)
		return conversionPayload(c)
	}
	gsig := func(mut func(*chatv1.StawiGenesisSignatureContent)) *chatv1.Payload {
		c := &chatv1.StawiGenesisSignatureContent{
			GenesisId:   "gen-1",
			Signature:   sig(65),
			SignerKeyId: "key-1",
			Algorithm:   "secp256k1",
		}
		mut(c)
		return signaturePayload(c)
	}
	scall := func(mut func(*chatv1.StawiSignedCallContent)) *chatv1.Payload {
		c := &chatv1.StawiSignedCallContent{
			CallId:      "call-1",
			Kind:        "INVITE",
			Signature:   sig(65),
			SignerKeyId: "key-1",
			Algorithm:   "secp256k1",
		}
		mut(c)
		return signedCallPayload(c)
	}

	corpus := map[string]*chatv1.Payload{
		"conv ok":             conv(func(*chatv1.StawiRoomConversionContent) {}),
		"conv empty template": conv(func(c *chatv1.StawiRoomConversionContent) { c.TemplateId = "" }),
		"conv template 64":    conv(func(c *chatv1.StawiRoomConversionContent) { c.TemplateId = long(64) }),
		"conv template 65":    conv(func(c *chatv1.StawiRoomConversionContent) { c.TemplateId = long(65) }),
		"conv founders none": conv(
			func(c *chatv1.StawiRoomConversionContent) { c.FounderSubscriptionIds = nil },
		),
		"conv founders dup": conv(
			func(c *chatv1.StawiRoomConversionContent) { c.FounderSubscriptionIds = []string{"abc", "abc"} },
		),
		"conv founder short": conv(
			func(c *chatv1.StawiRoomConversionContent) { c.FounderSubscriptionIds = []string{"ab"} },
		),
		"conv founder upper": conv(
			func(c *chatv1.StawiRoomConversionContent) { c.FounderSubscriptionIds = []string{"ABC"} },
		),
		"conv founder 41": conv(
			func(c *chatv1.StawiRoomConversionContent) { c.FounderSubscriptionIds = []string{long(41)} },
		),
		"conv founders 65": conv(
			func(c *chatv1.StawiRoomConversionContent) { c.FounderSubscriptionIds = manyIDs(65) },
		),
		"conv founders 64": conv(
			func(c *chatv1.StawiRoomConversionContent) { c.FounderSubscriptionIds = manyIDs(64) },
		),
		"conv join unknown":     conv(func(c *chatv1.StawiRoomConversionContent) { c.JoinPolicy = 7 }),
		"conv join unspecified": conv(func(c *chatv1.StawiRoomConversionContent) { c.JoinPolicy = 0 }),
		"conv rule key empty": conv(
			func(c *chatv1.StawiRoomConversionContent) { c.RuleValues = map[string]string{"": "1"} },
		),
		"conv rule value 257": conv(
			func(c *chatv1.StawiRoomConversionContent) { c.RuleValues = map[string]string{"k": long(257)} },
		),
		"gsig ok":          gsig(func(*chatv1.StawiGenesisSignatureContent) {}),
		"gsig empty id":    gsig(func(c *chatv1.StawiGenesisSignatureContent) { c.GenesisId = "" }),
		"gsig id 65":       gsig(func(c *chatv1.StawiGenesisSignatureContent) { c.GenesisId = long(65) }),
		"gsig empty sig":   gsig(func(c *chatv1.StawiGenesisSignatureContent) { c.Signature = nil }),
		"gsig sig 4096":    gsig(func(c *chatv1.StawiGenesisSignatureContent) { c.Signature = sig(4096) }),
		"gsig sig 4097":    gsig(func(c *chatv1.StawiGenesisSignatureContent) { c.Signature = sig(4097) }),
		"gsig no key":      gsig(func(c *chatv1.StawiGenesisSignatureContent) { c.SignerKeyId = "" }),
		"gsig key 129":     gsig(func(c *chatv1.StawiGenesisSignatureContent) { c.SignerKeyId = long(129) }),
		"call ok":          scall(func(*chatv1.StawiSignedCallContent) {}),
		"call empty id":    scall(func(c *chatv1.StawiSignedCallContent) { c.CallId = "" }),
		"call id 65":       scall(func(c *chatv1.StawiSignedCallContent) { c.CallId = long(65) }),
		"call empty kind":  scall(func(c *chatv1.StawiSignedCallContent) { c.Kind = "" }),
		"call kind 65":     scall(func(c *chatv1.StawiSignedCallContent) { c.Kind = long(65) }),
		"call empty sig":   scall(func(c *chatv1.StawiSignedCallContent) { c.Signature = nil }),
		"call sig 4097":    scall(func(c *chatv1.StawiSignedCallContent) { c.Signature = sig(4097) }),
		"call key 129":     scall(func(c *chatv1.StawiSignedCallContent) { c.SignerKeyId = long(129) }),
		"call summary 513": scall(func(c *chatv1.StawiSignedCallContent) { c.Summary = long(513) }),
		"call summary 512, key 128": scall(
			func(c *chatv1.StawiSignedCallContent) { c.Summary = long(512); c.SignerKeyId = long(128) },
		),
	}

	for name, payload := range corpus {
		t.Run(name, func(t *testing.T) {
			event := stawiEvent(payload)
			protoVerdict := protovalidate.Validate(event) == nil
			chatVerdict := validateStawiPayload(event) == nil
			require.Equal(t, protoVerdict, chatVerdict,
				"protovalidate accepts=%v, chat accepts=%v", protoVerdict, chatVerdict)
		})
	}
}

func sig65() []byte { return make([]byte, 65) }

func manyIDs(n int) []string {
	out := make([]string, n)
	for i := range out {
		out[i] = fmt.Sprintf("sub-%03d", i)
	}
	return out
}

// TestValidateStawiPayload_EnvelopeRulesApply checks the event around a Stawi
// payload is held to its proto rules too, not only the payload content.
func TestValidateStawiPayload_EnvelopeRulesApply(t *testing.T) {
	event := stawiEvent(conversionPayload(validConversion()))
	bad := "NOT A VALID PARENT"
	event.ParentId = &bad
	require.Error(t, protovalidate.Validate(event))
	err := validateStawiPayload(event)
	require.Error(t, err)
	require.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
}
