package settlement_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"buf.build/gen/go/stawi/finance/connectrpc/go/v2/settlement/v1/settlementv1connect"
	financev1 "buf.build/gen/go/stawi/finance/protocolbuffers/go/finance/v1"
	settlementv1 "buf.build/gen/go/stawi/finance/protocolbuffers/go/settlement/v1"
	"connectrpc.com/connect/v2"
	"connectrpc.com/connect/v2/connecthttp"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/stawilabs/chat/apps/default/service/stawi"
	"github.com/stawilabs/chat/apps/default/service/stawi/settlement"
)

const (
	roomID    = "d3l2p7rh1v8s73a0room"
	adminID   = "d3l2p7rh1v8s73a0adm1"
	memberID  = "d3l2p7rh1v8s73a0mem1"
	genesisID = "d3l2p7rh1v8s73a0gen1"
	callID    = "d3l2p7rh1v8s73a0cal1"
)

//nolint:gochecknoglobals // immutable test fixture
var signerAccount = []byte{
	0xab,
	0xcd,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0xef,
}

// fakeRoomService is settlement's RoomService as the generated handler
// interface: it records requests and answers from its fields.
type fakeRoomService struct {
	settlementv1connect.UnimplementedRoomServiceHandler

	prepared  *settlementv1.PrepareRoomGenesisRequest
	signed    *settlementv1.SubmitRoomGenesisSignatureRequest
	submitted *settlementv1.SubmitRoomCallRequest
	call      *settlementv1.RoomCall
	err       error
}

func (f *fakeRoomService) PrepareRoomGenesis(
	_ context.Context, req *settlementv1.PrepareRoomGenesisRequest,
) (*settlementv1.PrepareRoomGenesisResponse, error) {
	if f.err != nil {
		return nil, f.err
	}
	f.prepared = req
	founders := make([]*settlementv1.RoomFounder, 0, len(req.GetFounderProfileIds()))
	for _, id := range req.GetFounderProfileIds() {
		founders = append(founders, &settlementv1.RoomFounder{ProfileId: id, Account: signerAccount})
	}
	return &settlementv1.PrepareRoomGenesisResponse{Genesis: &settlementv1.RoomGenesis{
		GenesisId: genesisID, ChatRoomId: req.GetChatRoomId(),
		State:       settlementv1.RoomGenesisState_ROOM_GENESIS_STATE_PENDING,
		GenesisHash: []byte{1, 2, 3}, ConstitutionHash: []byte{4},
		Founders: founders, SignaturesRequired: 2,
		ExpiresAt: timestamppb.New(time.Unix(1_900_000_000, 0)),
	}}, nil
}

func (f *fakeRoomService) SubmitRoomGenesisSignature(
	_ context.Context, req *settlementv1.SubmitRoomGenesisSignatureRequest,
) (*settlementv1.SubmitRoomGenesisSignatureResponse, error) {
	if f.err != nil {
		return nil, f.err
	}
	f.signed = req
	return &settlementv1.SubmitRoomGenesisSignatureResponse{
		Genesis:   &settlementv1.RoomGenesis{GenesisId: genesisID, SignaturesRequired: 2, SignaturesCollected: 2},
		Submitted: true,
	}, nil
}

func (f *fakeRoomService) SubmitRoomCall(
	_ context.Context, req *settlementv1.SubmitRoomCallRequest,
) (*settlementv1.SubmitRoomCallResponse, error) {
	if f.err != nil {
		return nil, f.err
	}
	f.submitted = req
	return &settlementv1.SubmitRoomCallResponse{Call: f.call}, nil
}

func (f *fakeRoomService) GetRoomCall(
	_ context.Context, req *settlementv1.GetRoomCallRequest,
) (*settlementv1.GetRoomCallResponse, error) {
	if f.err != nil {
		return nil, f.err
	}
	if req.GetCallId() != f.call.GetCallId() {
		return nil, connect.NewError(connect.CodeNotFound, "no such call")
	}
	return &settlementv1.GetRoomCallResponse{Call: f.call}, nil
}

func newRooms(t *testing.T, fake *fakeRoomService) stawi.Rooms {
	t.Helper()
	srv := connect.NewServer()
	settlementv1connect.RegisterRoomServiceHandler(srv, fake)
	mux := http.NewServeMux()
	connecthttp.Mount(mux, srv)
	server := httptest.NewServer(mux)
	t.Cleanup(server.Close)
	return settlement.NewRooms(settlementv1connect.NewRoomServiceClient(
		connect.NewClient(connecthttp.NewTransport(server.Client(), server.URL)),
	))
}

func TestPrepareRoomGenesisNamesTheAdminAndFounders(t *testing.T) {
	fake := &fakeRoomService{}
	rooms := newRooms(t, fake)

	genesis, err := rooms.PrepareRoomGenesis(context.Background(), stawi.PrepareGenesisRequest{
		ChatRoomID: roomID, TemplateID: "chama-basic", FounderProfileIDs: []string{adminID, memberID},
		JoinPolicy: stawi.JoinPolicyPublic, RequestedBy: adminID, AgentProfileID: memberID,
	})
	require.NoError(t, err)
	require.Equal(t, memberID, fake.prepared.GetAgentProfileId(), "settlement resolves the agent's account")
	require.Equal(t, roomID, fake.prepared.GetChatRoomId())
	require.Equal(t, "chama-basic", fake.prepared.GetTemplateId())
	require.Equal(t, []string{adminID, memberID}, fake.prepared.GetFounderProfileIds())
	require.Equal(t, financev1.RoomJoinPolicy_ROOM_JOIN_POLICY_PUBLIC, fake.prepared.GetJoinPolicy())
	require.Equal(t, adminID, fake.prepared.GetProfileId(), "chat names the converting admin")

	require.Equal(t, genesisID, genesis.GenesisID)
	require.Equal(t, []byte{1, 2, 3}, genesis.GenesisHash)
	require.Equal(t, []string{adminID, memberID}, genesis.FounderProfileIDs)
	require.Equal(t, int64(1_900_000_000), genesis.ExpiresAt.Unix())
}

// The rule values the admin chose travel with the template: settlement applies
// them before it compiles the constitution the founders sign.
func TestPrepareRoomGenesisRelaysTheRuleValues(t *testing.T) {
	fake := &fakeRoomService{}
	values := map[string]string{"contribution_amount": "5000", "voting_period": "86400"}
	_, err := newRooms(t, fake).PrepareRoomGenesis(context.Background(), stawi.PrepareGenesisRequest{
		ChatRoomID: roomID, TemplateID: "chama-basic", FounderProfileIDs: []string{adminID},
		RuleValues: values, RequestedBy: adminID,
	})
	require.NoError(t, err)
	require.Equal(t, "chama-basic", fake.prepared.GetTemplateId())
	require.Equal(t, values, fake.prepared.GetRuleValues())
}

func TestSubmitRoomGenesisSignatureRelaysTheFoundersDeviceSignature(t *testing.T) {
	fake := &fakeRoomService{}
	result, err := newRooms(t, fake).SubmitRoomGenesisSignature(context.Background(), stawi.GenesisSignature{
		GenesisID: genesisID, SignerProfileID: memberID,
		Signature: stawi.DeviceSignature{KeyID: "key-1", Algorithm: "p256-webauthn", Signature: make([]byte, 128),
			AuthenticatorData: []byte("auth"), ClientDataJSON: []byte("{}")},
	})
	require.NoError(t, err)
	require.Equal(t, genesisID, fake.signed.GetGenesisId())
	require.Equal(t, memberID, fake.signed.GetProfileId(), "the founder signs for themselves")
	sig := fake.signed.GetSignature()
	require.Equal(t, "key-1", sig.GetDeviceKeyId())
	require.Equal(t, "p256-webauthn", sig.GetAlgorithm())
	require.Len(t, sig.GetSignature(), 128)
	require.Equal(t, []byte("auth"), sig.GetWebauthnAuthenticatorData())
	require.Equal(t, []byte("{}"), sig.GetWebauthnClientDataJson())
	require.True(t, result.Submitted)
	require.Equal(t, 2, result.Signed)
	require.Equal(t, 2, result.Required)
}

func TestSubmitAndGetRoomCallMapSettlementsRecord(t *testing.T) {
	fake := &fakeRoomService{call: &settlementv1.RoomCall{
		CallId: callID, ChatRoomId: roomID, Kind: settlementv1.RoomCallKind_ROOM_CALL_KIND_CAST_VOTE,
		State: settlementv1.RoomCallState_ROOM_CALL_STATE_SUBMITTED, Signer: signerAccount, Nonce: 7,
		ProfileId: memberID, Custody: signerAccount, TxHash: []byte{9},
	}}
	rooms := newRooms(t, fake)

	call, err := rooms.SubmitRoomCall(context.Background(), stawi.CallSubmission{
		CallID: callID, SignerProfileID: memberID,
		Signature: stawi.DeviceSignature{KeyID: "key-1", Algorithm: "secp256k1", Signature: make([]byte, 65)},
	})
	require.NoError(t, err)
	require.Equal(t, callID, fake.submitted.GetCallId())
	require.Equal(t, memberID, fake.submitted.GetProfileId(), "chat names the member it relays for")
	require.Equal(t, "secp256k1", fake.submitted.GetSignature().GetAlgorithm())
	require.Equal(t, stawi.RoomCall{
		CallID: callID, RoomID: roomID, Kind: "CAST_VOTE", SignerAddress: "0xabcd0000000000000000000000000000000000ef",
		Nonce: 7, ProfileID: memberID, Custody: "0xabcd0000000000000000000000000000000000ef",
		State: stawi.CallStateSubmitted, TxHash: []byte{9},
	}, *call)

	for state, want := range map[settlementv1.RoomCallState]stawi.CallState{
		settlementv1.RoomCallState_ROOM_CALL_STATE_UNSPECIFIED: stawi.CallStateUnspecified,
		settlementv1.RoomCallState_ROOM_CALL_STATE_PREPARED:    stawi.CallStatePrepared,
		settlementv1.RoomCallState_ROOM_CALL_STATE_SUBMITTED:   stawi.CallStateSubmitted,
		settlementv1.RoomCallState_ROOM_CALL_STATE_INCLUDED:    stawi.CallStateSubmitted,
		settlementv1.RoomCallState_ROOM_CALL_STATE_FINAL:       stawi.CallStateFinal,
		settlementv1.RoomCallState_ROOM_CALL_STATE_FAILED:      stawi.CallStateFailed,
		settlementv1.RoomCallState_ROOM_CALL_STATE_EXPIRED:     stawi.CallStateFailed,
	} {
		fake.call.State = state
		fake.call.FailureReason = "why"
		got, getErr := rooms.GetRoomCall(context.Background(), callID)
		require.NoError(t, getErr)
		require.Equal(t, want, got.State, state.String())
		require.Equal(t, "why", got.Reason)
	}
}

func TestSettlementErrorsKeepTheirCode(t *testing.T) {
	fake := &fakeRoomService{err: connect.NewError(connect.CodeFailedPrecondition, "voting closed")}
	rooms := newRooms(t, fake)
	_, err := rooms.GetRoomCall(context.Background(), callID)
	require.Equal(t, connect.CodeFailedPrecondition, connect.CodeOf(err))
	require.False(t, stawi.IsTransient(err))
	require.Equal(t, "voting closed", stawi.RefusalReason(err))

	fake.err = connect.NewError(connect.CodeUnavailable, "down")
	_, err = rooms.SubmitRoomCall(context.Background(), stawi.CallSubmission{CallID: callID})
	require.True(t, stawi.IsTransient(err))
}
