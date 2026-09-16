package models_test

import (
	"testing"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/reflect/protodesc"
	"google.golang.org/protobuf/types/descriptorpb"
	"google.golang.org/protobuf/types/dynamicpb"

	"github.com/stawilabs/chat/apps/default/service/models"
)

func financeCardPayload() *chatv1.Payload {
	return &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_FINANCE_CARD,
		Data: &chatv1.Payload_FinanceCard{FinanceCard: &chatv1.FinanceCardContent{
			CardId:  "evt-1",
			GroupId: "grp-1",
			Kind:    "PROPOSAL",
			Title:   "New proposal: buy a maize mill",
			Body:    "Voting happens in Stawi: open the card to sign your vote on your device.",
			Data:    map[string]string{"proposal_id": "prop-1", "action": "open_signing_flow"},
		}},
	}
}

func TestPayloadConverter_FinanceCardRoundTrip(t *testing.T) {
	converter := models.NewPayloadConverter()

	content, err := converter.FromProto(financeCardPayload())
	require.NoError(t, err)
	require.EqualValues(t,
		chatv1.PayloadType_PAYLOAD_TYPE_FINANCE_CARD.Number(),
		content[PayloadTypeField],
	)

	restored, err := converter.ToProto(content)
	require.NoError(t, err)
	require.Equal(t, chatv1.PayloadType_PAYLOAD_TYPE_FINANCE_CARD, restored.GetType())

	card := restored.GetFinanceCard()
	require.NotNil(t, card)
	require.Equal(t, "evt-1", card.GetCardId())
	require.Equal(t, "grp-1", card.GetGroupId())
	require.Equal(t, "PROPOSAL", card.GetKind())
	require.Equal(t, "New proposal: buy a maize mill", card.GetTitle())
	require.Equal(t, "prop-1", card.GetData()["proposal_id"])
}

// TestFinanceCardDegradesForOlderClients checks the forward-compatibility
// promise on PayloadType ("clients must ignore unknown values"): a client
// built before PAYLOAD_TYPE_FINANCE_CARD existed still parses the event, can
// still read the payload type, and keeps the parts it does not understand as
// unknown fields instead of failing.
func TestFinanceCardDegradesForOlderClients(t *testing.T) {
	wire, err := proto.Marshal(financeCardPayload())
	require.NoError(t, err)

	// An "old" Payload schema: the type field only, no finance_card member.
	oldSchema := &descriptorpb.FileDescriptorProto{
		Name:    proto.String("old/payload.proto"),
		Package: proto.String("old"),
		Syntax:  proto.String("proto3"),
		MessageType: []*descriptorpb.DescriptorProto{{
			Name: proto.String("Payload"),
			Field: []*descriptorpb.FieldDescriptorProto{{
				Name:   proto.String("type"),
				Number: proto.Int32(1),
				Label:  descriptorpb.FieldDescriptorProto_LABEL_OPTIONAL.Enum(),
				Type:   descriptorpb.FieldDescriptorProto_TYPE_INT32.Enum(),
			}},
		}},
	}
	fileDesc, err := protodesc.NewFile(oldSchema, nil)
	require.NoError(t, err)

	oldPayload := dynamicpb.NewMessage(fileDesc.Messages().Get(0))
	require.NoError(t, proto.Unmarshal(wire, oldPayload), "an older client must still parse the event")

	typeField := fileDesc.Messages().Get(0).Fields().ByName("type")
	require.EqualValues(t,
		chatv1.PayloadType_PAYLOAD_TYPE_FINANCE_CARD.Number(),
		oldPayload.Get(typeField).Int(),
		"the unknown type is readable, so the client can skip rendering it",
	)
	require.NotEmpty(t, oldPayload.GetUnknown(), "the card body is preserved as unknown fields")
}

// TestUnknownPayloadTypeIsStoredAsStruct covers the server side of the same
// promise: a payload type this build does not know is still persisted and
// served instead of erroring the send.
func TestUnknownPayloadTypeIsStoredAsStruct(t *testing.T) {
	converter := models.NewPayloadConverter()

	unknown := &chatv1.Payload{Type: chatv1.PayloadType(9999)}
	content, err := converter.FromProto(unknown)
	require.NoError(t, err)

	restored, err := converter.ToProto(content)
	require.NoError(t, err)
	require.EqualValues(t, 9999, restored.GetType())
}
