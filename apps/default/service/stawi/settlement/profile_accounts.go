package settlement

import (
	"context"

	"buf.build/gen/go/stawi/finance/connectrpc/go/v2/settlement/v1/settlementv1connect"
	settlementv1 "buf.build/gen/go/stawi/finance/protocolbuffers/go/settlement/v1"

	"github.com/stawilabs/chat/apps/default/service/stawi"
)

type profileAccounts struct {
	client settlementv1connect.AccountServiceClient
}

// NewProfileAccounts wraps settlement's AccountService client for profile
// account lookups. Settlement answers service principals only, so the client
// must carry chat's service credentials. Settlement's errors are returned
// unchanged.
func NewProfileAccounts(client settlementv1connect.AccountServiceClient) stawi.ProfileAccounts {
	return &profileAccounts{client: client}
}

func (p *profileAccounts) GetProfileAccount(ctx context.Context, profileID string) (*stawi.ProfileAccount, error) {
	resp, err := p.client.GetProfileAccount(ctx, &settlementv1.GetProfileAccountRequest{
		ProfileId: profileID,
	})
	if err != nil {
		return nil, err
	}
	return &stawi.ProfileAccount{Account: resp.GetAccount(), Deployed: resp.GetDeployed()}, nil
}
