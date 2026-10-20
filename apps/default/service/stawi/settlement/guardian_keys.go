package settlement

import (
	"context"

	"buf.build/gen/go/stawi/finance/connectrpc/go/v2/settlement/v1/settlementv1connect"
	settlementv1 "buf.build/gen/go/stawi/finance/protocolbuffers/go/settlement/v1"

	"github.com/stawilabs/chat/apps/default/service/stawi"
)

type guardianKeys struct {
	client settlementv1connect.AccountServiceClient
}

// NewGuardianKeys wraps settlement's AccountService client for guardian key
// lookups. The client must carry chat's service credentials: settlement then
// answers a profile's keys without a room, chat having checked the
// relationship itself. Settlement's errors are returned unchanged.
func NewGuardianKeys(client settlementv1connect.AccountServiceClient) stawi.GuardianKeys {
	return &guardianKeys{client: client}
}

func (g *guardianKeys) LookupGuardianKeys(ctx context.Context, profileID string) ([]stawi.GuardianKey, uint64, error) {
	resp, err := g.client.LookupGuardianKeys(ctx, &settlementv1.LookupGuardianKeysRequest{
		ProfileId: profileID,
	})
	if err != nil {
		return nil, 0, err
	}
	keys := make([]stawi.GuardianKey, 0, len(resp.GetKeys()))
	for _, k := range resp.GetKeys() {
		key := stawi.GuardianKey{Key: k.GetKey(), Account: k.GetAccount()}
		if k.GetRegisteredAt() != nil {
			key.RegisteredAt = k.GetRegisteredAt().AsTime()
		}
		keys = append(keys, key)
	}
	return keys, resp.GetBlockNumber(), nil
}
