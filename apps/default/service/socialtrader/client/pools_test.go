package client_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"buf.build/gen/go/stawi/socialtrader/connectrpc/go/v2/socialtrader/v1/socialtraderv1connect"
	socialtraderv1 "buf.build/gen/go/stawi/socialtrader/protocolbuffers/go/socialtrader/v1"
	"connectrpc.com/connect/v2"
	"connectrpc.com/connect/v2/connecthttp"
	"github.com/pitabwire/frame/v3/security"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/service/socialtrader"
	"github.com/stawilabs/chat/apps/default/service/socialtrader/client"
)

const (
	poolAddress  = "0x00000000000000000000000000000000000000Aa"
	leaderWallet = "0xAbCdEf0000000000000000000000000000000001"
	profileID    = "profile-1"
)

// fakePools is the service's PoolService answering GetPool from its fields.
type fakePools struct {
	socialtraderv1connect.UnimplementedPoolServiceHandler
	asked *socialtraderv1.GetPoolRequest
	resp  *socialtraderv1.GetPoolResponse
	err   error
}

func (f *fakePools) GetPool(
	_ context.Context,
	req *socialtraderv1.GetPoolRequest,
) (*socialtraderv1.GetPoolResponse, error) {
	f.asked = req
	if f.err != nil {
		return nil, f.err
	}
	return f.resp, nil
}

// fakeLinks is the service's LinkService recording the bearer token it saw.
type fakeLinks struct {
	socialtraderv1connect.UnimplementedLinkServiceHandler
	authorization string
	resp          *socialtraderv1.GetLinkedWalletResponse
	err           error
}

func (f *fakeLinks) GetLinkedWallet(
	ctx context.Context, _ *socialtraderv1.GetLinkedWalletRequest,
) (*socialtraderv1.GetLinkedWalletResponse, error) {
	if info, ok := connect.CallInfoForServerContext(ctx); ok {
		f.authorization = info.RequestHeader().Get("Authorization")
	}
	if f.err != nil {
		return nil, f.err
	}
	return f.resp, nil
}

func serve(t *testing.T, register func(*connect.Server)) *connect.Client {
	t.Helper()
	mux := http.NewServeMux()
	srv := connect.NewServer()
	register(srv)
	connecthttp.Mount(mux, srv)
	server := httptest.NewServer(mux)
	t.Cleanup(server.Close)
	return connect.NewClient(connecthttp.NewTransport(server.Client(), server.URL))
}

func newPools(t *testing.T, fake *fakePools) socialtrader.Pools {
	t.Helper()
	return client.NewPools(socialtraderv1connect.NewPoolServiceClient(serve(t, func(s *connect.Server) {
		socialtraderv1connect.RegisterPoolServiceHandler(s, fake)
	})))
}

func newLinks(t *testing.T, fake *fakeLinks) socialtrader.WalletLinks {
	t.Helper()
	return client.NewWalletLinks(socialtraderv1connect.NewLinkServiceClient(serve(t, func(s *connect.Server) {
		socialtraderv1connect.RegisterLinkServiceHandler(s, fake)
	})))
}

// callerCtx is the context of a person authenticated with a session token.
func callerCtx(ctx context.Context, profile, token string) context.Context {
	claims := &security.AuthenticationClaims{}
	claims.Subject = profile
	ctx = claims.ClaimsToContext(ctx)
	if token != "" {
		ctx = security.JwtToContext(ctx, token)
	}
	return ctx
}

func TestGetPool_MapsThePoolWithLowercaseAddresses(t *testing.T) {
	fake := &fakePools{resp: &socialtraderv1.GetPoolResponse{Pool: &socialtraderv1.Pool{
		Address: poolAddress, Leader: leaderWallet, MarketId: "0x01", RoomRef: "room-1",
	}}}
	pool, err := newPools(t, fake).GetPool(t.Context(), poolAddress)
	require.NoError(t, err)
	require.Equal(t, poolAddress, fake.asked.GetPool())
	require.Equal(t, "0x00000000000000000000000000000000000000aa", pool.Address)
	require.Equal(t, "0xabcdef0000000000000000000000000000000001", pool.Leader)
	require.Equal(t, "0x01", pool.MarketID)
	require.Equal(t, "room-1", pool.RoomRef)
}

func TestGetPool_UnknownPoolIsNotFound(t *testing.T) {
	cases := map[string]*fakePools{
		"service says not found": {err: connect.NewError(connect.CodeNotFound, "no such pool")},
		"empty answer":           {resp: &socialtraderv1.GetPoolResponse{}},
	}
	for name, fake := range cases {
		t.Run(name, func(t *testing.T) {
			_, err := newPools(t, fake).GetPool(t.Context(), poolAddress)
			require.Equal(t, connect.CodeNotFound, connect.CodeOf(err))
		})
	}
}

func TestGetLinkedWallet_ForwardsTheCallersToken(t *testing.T) {
	fake := &fakeLinks{resp: &socialtraderv1.GetLinkedWalletResponse{Wallet: leaderWallet}}
	wallet, err := newLinks(t, fake).GetLinkedWallet(callerCtx(t.Context(), profileID, "tok-123"), profileID)
	require.NoError(t, err)
	require.Equal(t, "Bearer tok-123", fake.authorization, "the caller's own session answers for them")
	require.Equal(t, "0xabcdef0000000000000000000000000000000001", wallet)
}

func TestGetLinkedWallet_NoLinkIsAnEmptyWallet(t *testing.T) {
	for name, fake := range map[string]*fakeLinks{
		"not found":    {err: connect.NewError(connect.CodeNotFound, "no link")},
		"empty answer": {resp: &socialtraderv1.GetLinkedWalletResponse{}},
	} {
		t.Run(name, func(t *testing.T) {
			wallet, err := newLinks(t, fake).GetLinkedWallet(callerCtx(t.Context(), profileID, "tok"), profileID)
			require.NoError(t, err)
			require.Empty(t, wallet)
		})
	}
}

func TestGetLinkedWallet_AnswersOnlyTheCallerWithASession(t *testing.T) {
	fake := &fakeLinks{resp: &socialtraderv1.GetLinkedWalletResponse{Wallet: leaderWallet}}
	links := newLinks(t, fake)

	_, err := links.GetLinkedWallet(callerCtx(t.Context(), profileID, "tok"), "someone-else")
	require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err))

	_, err = links.GetLinkedWallet(callerCtx(t.Context(), profileID, ""), profileID)
	require.Equal(t, connect.CodeUnauthenticated, connect.CodeOf(err))

	_, err = links.GetLinkedWallet(t.Context(), profileID)
	require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err))
	require.Empty(t, fake.authorization, "the service was never asked")
}

func TestGetLinkedWallet_KeepsTheServicesOtherCodes(t *testing.T) {
	fake := &fakeLinks{err: connect.NewError(connect.CodeUnavailable, "down")}
	_, err := newLinks(t, fake).GetLinkedWallet(callerCtx(t.Context(), profileID, "tok"), profileID)
	require.Equal(t, connect.CodeUnavailable, connect.CodeOf(err))
}
