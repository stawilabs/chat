package settlement_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"buf.build/gen/go/stawi/finance/connectrpc/go/v2/settlement/v1/settlementv1connect"
	settlementv1 "buf.build/gen/go/stawi/finance/protocolbuffers/go/settlement/v1"
	"connectrpc.com/connect/v2"
	"connectrpc.com/connect/v2/connecthttp"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/stawilabs/chat/apps/default/service/stawi"
	"github.com/stawilabs/chat/apps/default/service/stawi/settlement"
)

// fakeGuardianDirectory is settlement's AccountService answering
// LookupGuardianKeys from its fields.
type fakeGuardianDirectory struct {
	settlementv1connect.UnimplementedAccountServiceHandler

	asked *settlementv1.LookupGuardianKeysRequest
	resp  *settlementv1.LookupGuardianKeysResponse
	err   error
}

func (f *fakeGuardianDirectory) LookupGuardianKeys(
	_ context.Context, req *settlementv1.LookupGuardianKeysRequest,
) (*settlementv1.LookupGuardianKeysResponse, error) {
	f.asked = req
	if f.err != nil {
		return nil, f.err
	}
	return f.resp, nil
}

func newGuardianKeys(t *testing.T, fake *fakeGuardianDirectory) stawi.GuardianKeys {
	t.Helper()
	mux := http.NewServeMux()
	srv := connect.NewServer()
	settlementv1connect.RegisterAccountServiceHandler(srv, fake)
	connecthttp.Mount(mux, srv)
	server := httptest.NewServer(mux)
	t.Cleanup(server.Close)
	return settlement.NewGuardianKeys(settlementv1connect.NewAccountServiceClient(
		connect.NewClient(connecthttp.NewTransport(server.Client(), server.URL)),
	))
}

// TestLookupGuardianKeysAsksWithoutARoom: chat, a service principal, names
// only the profile (settlement answers a service without a room); the keys
// and head come back as settlement gave them.
func TestLookupGuardianKeysAsksWithoutARoom(t *testing.T) {
	keyAccount := make([]byte, 20)
	keyAccount[0] = 0x0a
	at := time.Unix(1_790_000_000, 0).UTC()
	fake := &fakeGuardianDirectory{resp: &settlementv1.LookupGuardianKeysResponse{
		Keys: []*settlementv1.GuardianKey{
			{Key: signerAccount, Account: keyAccount, RegisteredAt: timestamppb.New(at)},
			{Key: keyAccount, Account: signerAccount},
		},
		BlockNumber: 42,
	}}
	keys, head, err := newGuardianKeys(t, fake).LookupGuardianKeys(t.Context(), memberID)
	require.NoError(t, err)
	require.Equal(t, memberID, fake.asked.GetProfileId())
	require.Nil(t, fake.asked.GetRoom(), "a service names no room")
	require.Equal(t, uint64(42), head)
	require.Len(t, keys, 2)
	require.Equal(t, signerAccount, keys[0].Key)
	require.Equal(t, keyAccount, keys[0].Account)
	require.True(t, at.Equal(keys[0].RegisteredAt))
	require.True(t, keys[1].RegisteredAt.IsZero())

	fake.resp = &settlementv1.LookupGuardianKeysResponse{BlockNumber: 43}
	keys, _, err = newGuardianKeys(t, fake).LookupGuardianKeys(t.Context(), memberID)
	require.NoError(t, err)
	require.Empty(t, keys, "no keys is an empty answer, not an error")
}

func TestLookupGuardianKeysKeepsSettlementsCode(t *testing.T) {
	fake := &fakeGuardianDirectory{err: connect.NewError(connect.CodePermissionDenied, "no account_view")}
	_, _, err := newGuardianKeys(t, fake).LookupGuardianKeys(t.Context(), memberID)
	require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err))
}
