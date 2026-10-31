// Package client adapts the socialtrader service's Connect clients to the
// interfaces chat's business layer uses.
package client

import (
	"context"
	"strings"

	"buf.build/gen/go/stawi/socialtrader/connectrpc/go/v2/socialtrader/v1/socialtraderv1connect"
	socialtraderv1 "buf.build/gen/go/stawi/socialtrader/protocolbuffers/go/socialtrader/v1"
	"connectrpc.com/connect/v2"
	"github.com/pitabwire/frame/v3/security"

	"github.com/stawilabs/chat/apps/default/service/socialtrader"
)

type pools struct {
	client socialtraderv1connect.PoolServiceClient
}

// NewPools wraps the service's PoolService client. The client carries chat's
// service credentials; pool reads are public on the service.
func NewPools(client socialtraderv1connect.PoolServiceClient) socialtrader.Pools {
	return &pools{client: client}
}

func (p *pools) GetPool(ctx context.Context, address string) (*socialtrader.Pool, error) {
	resp, err := p.client.GetPool(ctx, &socialtraderv1.GetPoolRequest{Pool: address})
	if err != nil {
		return nil, err
	}
	pool := resp.GetPool()
	if pool == nil || pool.GetAddress() == "" {
		return nil, connect.Errorf(connect.CodeNotFound, "pool %s not found", address)
	}
	return &socialtrader.Pool{
		Address:  strings.ToLower(pool.GetAddress()),
		Leader:   strings.ToLower(pool.GetLeader()),
		MarketID: pool.GetMarketId(),
		RoomRef:  pool.GetRoomRef(),
	}, nil
}

type walletLinks struct {
	client socialtraderv1connect.LinkServiceClient
}

// NewWalletLinks wraps the service's LinkService client. GetLinkedWallet
// answers from the caller's own session: the service identifies the profile
// from the bearer token, so the adapter forwards the caller's token from ctx
// and answers only for that profile. The client must therefore be a plain
// Connect client without service credentials of its own, or the forwarded
// token would be replaced.
func NewWalletLinks(client socialtraderv1connect.LinkServiceClient) socialtrader.WalletLinks {
	return &walletLinks{client: client}
}

func (l *walletLinks) GetLinkedWallet(ctx context.Context, profileID string) (string, error) {
	claims := security.ClaimsFromContext(ctx)
	if claims == nil || claims.GetProfileID() != profileID {
		return "", connect.NewError(connect.CodePermissionDenied,
			"a linked wallet is answered only for the caller's own profile")
	}
	token := security.JwtFromContext(ctx)
	if token == "" {
		return "", connect.NewError(connect.CodeUnauthenticated, "the caller's session token is required")
	}
	callCtx, info := connect.NewClientContext(ctx)
	info.RequestHeader().Set("Authorization", "Bearer "+token)
	resp, err := l.client.GetLinkedWallet(callCtx, &socialtraderv1.GetLinkedWalletRequest{})
	if err != nil {
		if connect.CodeOf(err) == connect.CodeNotFound {
			return "", nil
		}
		return "", err
	}
	return strings.ToLower(resp.GetWallet()), nil
}
