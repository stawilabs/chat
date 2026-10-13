package settlement_test

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"buf.build/gen/go/stawi/finance/connectrpc/go/settlement/v1/settlementv1connect"
	settlementv1 "buf.build/gen/go/stawi/finance/protocolbuffers/go/settlement/v1"
	"connectrpc.com/connect"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/service/stawi"
	"github.com/stawilabs/chat/apps/default/service/stawi/settlement"
)

// fakeAccountService is settlement's AccountService answering
// GetProfileAccount from its fields.
type fakeAccountService struct {
	settlementv1connect.UnimplementedAccountServiceHandler

	asked string
	resp  *settlementv1.GetProfileAccountResponse
	err   error
}

func (f *fakeAccountService) GetProfileAccount(
	_ context.Context, req *connect.Request[settlementv1.GetProfileAccountRequest],
) (*connect.Response[settlementv1.GetProfileAccountResponse], error) {
	f.asked = req.Msg.GetProfileId()
	if f.err != nil {
		return nil, f.err
	}
	return connect.NewResponse(f.resp), nil
}

func newProfileAccounts(t *testing.T, fake *fakeAccountService) stawi.ProfileAccounts {
	t.Helper()
	mux := http.NewServeMux()
	mux.Handle(settlementv1connect.NewAccountServiceHandler(fake))
	server := httptest.NewServer(mux)
	t.Cleanup(server.Close)
	return settlement.NewProfileAccounts(settlementv1connect.NewAccountServiceClient(server.Client(), server.URL))
}

func TestGetProfileAccountMapsSettlementsAnswer(t *testing.T) {
	fake := &fakeAccountService{resp: &settlementv1.GetProfileAccountResponse{
		Account: signerAccount, Deployed: true, BlockNumber: 42,
	}}
	got, err := newProfileAccounts(t, fake).GetProfileAccount(t.Context(), memberID)
	require.NoError(t, err)
	require.Equal(t, memberID, fake.asked)
	require.Equal(t, signerAccount, got.Account)
	require.True(t, got.Deployed)

	fake.resp = &settlementv1.GetProfileAccountResponse{}
	got, err = newProfileAccounts(t, fake).GetProfileAccount(t.Context(), memberID)
	require.NoError(t, err)
	require.Empty(t, got.Account, "no account is an empty answer, not an error")
	require.False(t, got.Deployed)
}

func TestGetProfileAccountKeepsSettlementsCode(t *testing.T) {
	fake := &fakeAccountService{err: connect.NewError(connect.CodeUnavailable, errors.New("profile is down"))}
	_, err := newProfileAccounts(t, fake).GetProfileAccount(t.Context(), memberID)
	require.Equal(t, connect.CodeUnavailable, connect.CodeOf(err))
}
