package handlers_test

import (
	"context"
	"testing"
	"time"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect/v2"
	"github.com/antinvestor/common/v3/permissions"
	"github.com/pitabwire/frame/v3/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/service/handlers"
	"github.com/stawilabs/chat/apps/default/service/stawi"
	"github.com/stawilabs/chat/apps/default/service/stawi/stawitest"
)

func lookupKeys(
	ctx context.Context, server *handlers.ChatServer, roomID, profileID string,
) (*chatv1.LookupContactGuardianKeysResponse, error) {
	return server.LookupContactGuardianKeys(ctx,
		&chatv1.LookupContactGuardianKeysRequest{RoomId: roomID, ProfileId: profileID})
}

// TestLookupContactGuardianKeysAnswersADMPartner: once Bob has written in
// the DM, Alice gets the keys he registered, relayed from settlement.
func (s *ChatServerTestSuite) TestLookupContactGuardianKeysAnswersADMPartner() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		keys := stawitest.NewGuardianKeys()
		f := &partnerFixture{partners: stawitest.NewProfileAccounts(), alice: util.IDString(), bob: util.IDString()}
		f.server = handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware, handlers.WithGuardianKeys(keys))
		f.aliceCtx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, f.alice)
		f.bobCtx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, f.bob)
		f.dm = s.createRoomAndWait(f.aliceCtx, t, svc, f.server, f.alice, &chatv1.CreateRoomRequest{
			Name: "Bob", Type: chatv1.RoomType_ROOM_TYPE_DIRECT,
			Members: []*commonv1.ContactLink{{ProfileId: f.bob}},
		})
		s.WaitForMemberSubscription(ctx, svc, f.dm, f.bob, t)
		key := stawi.GuardianKey{
			Key: make([]byte, 20), Account: make([]byte, 20), RegisteredAt: time.Unix(1_790_000_000, 0),
		}
		key.Key[0], key.Account[0] = 0xb0, 0xb1
		keys.Set(f.bob, key)
		keys.Head = 9

		_, err := lookupKeys(f.aliceCtx, f.server, f.dm, f.bob)
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err), "Bob has not written yet")

		f.write(f.bobCtx, t, f.dm)
		got, err := lookupKeys(f.aliceCtx, f.server, f.dm, f.bob)
		require.NoError(t, err)
		require.Equal(t, f.bob, got.GetProfileId())
		require.Equal(t, uint64(9), got.GetBlockNumber())
		require.Len(t, got.GetKeys(), 1)
		require.Equal(t, key.Key, got.GetKeys()[0].GetKey())
		require.Equal(t, key.Account, got.GetKeys()[0].GetAccount())

		_, err = lookupKeys(ctx, f.server, f.dm, f.bob)
		require.Equal(t, connect.CodeUnauthenticated, connect.CodeOf(err))
		_, err = lookupKeys(s.withSystemAuth(ctx, f.alice), f.server, f.dm, f.bob)
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err), "a service caller")
		_, err = lookupKeys(f.aliceCtx, f.server, "", f.bob)
		require.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
		_, err = lookupKeys(f.aliceCtx, f.server, f.dm, "")
		require.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
		carolCtx := s.WithAuthClaims(ctx, testTenantID, testPartitionID, util.IDString())
		_, err = lookupKeys(carolCtx, f.server, f.dm, f.bob)
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err), "a stranger")
		require.Equal(t, []string{f.bob}, keys.Asked, "settlement is asked only for the entitled lookup")

		keys.Fail(connect.NewError(connect.CodeUnavailable, "settlement is down"))
		_, err = lookupKeys(f.aliceCtx, f.server, f.dm, f.bob)
		require.Equal(t, connect.CodeUnavailable, connect.CodeOf(err))
	})
}

// TestLookupContactGuardianKeysWithoutSettlementIsUnavailable: a chat with no
// settlement endpoint answers an entitled lookup Unavailable.
func (s *ChatServerTestSuite) TestLookupContactGuardianKeysWithoutSettlementIsUnavailable() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		f := s.newPartnerFixture(ctx, t, svc)
		f.write(f.bobCtx, t, f.dm)
		_, err := lookupKeys(f.aliceCtx, f.server, f.dm, f.bob)
		require.Equal(t, connect.CodeUnavailable, connect.CodeOf(err))
	})
}

// TestLookupContactGuardianKeysIsGatedLikeAPartnerLookup: the function access
// interceptor asks direct_partner_account_view, which every person role
// holds and no role but those does.
func TestLookupContactGuardianKeysIsGatedLikeAPartnerLookup(t *testing.T) {
	sd := chatv1.File_chat_v1_chat_proto.Services().ByName("ChatService")
	require.NotNil(t, sd)
	procs := permissions.BuildProcedureMap(sd)
	require.Equal(t, []string{"direct_partner_account_view"}, procs["/chat.v1.ChatService/LookupContactGuardianKeys"])
	require.Equal(t, procs["/chat.v1.ChatService/GetDirectPartnerAccount"],
		procs["/chat.v1.ChatService/LookupContactGuardianKeys"])

	manifest := permissions.BuildManifest(sd)
	for _, role := range []string{"owner", "admin", "operator", "viewer", "member"} {
		require.Contains(t, manifest.RoleBindings[role], "direct_partner_account_view", "role %s", role)
	}
	require.NotContains(t, manifest.RoleBindings["service"], "direct_partner_account_view",
		"a service never looks a contact up for itself")
}
