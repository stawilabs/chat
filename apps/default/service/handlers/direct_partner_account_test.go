package handlers_test

import (
	"context"
	"errors"
	"testing"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/pitabwire/frame/v2"
	"github.com/pitabwire/frame/v2/datastore"
	"github.com/pitabwire/frame/v2/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/service/handlers"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/service/stawi/stawitest"
)

// partnerFixture is a chat server wired to a fake settlement account lookup,
// and a DM between Alice and Bob.
type partnerFixture struct {
	server   *handlers.ChatServer
	partners *stawitest.ProfileAccounts
	alice    string
	bob      string
	aliceCtx context.Context
	bobCtx   context.Context
	dm       string
}

func (s *ChatServerTestSuite) newPartnerFixture(
	ctx context.Context, t *testing.T, svc *frame.Service,
) *partnerFixture {
	t.Helper()
	f := &partnerFixture{partners: stawitest.NewProfileAccounts(), alice: util.IDString(), bob: util.IDString()}
	f.server = handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware, handlers.WithProfileAccounts(f.partners))
	f.aliceCtx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, f.alice)
	f.bobCtx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, f.bob)
	f.dm = s.createRoomAndWait(f.aliceCtx, t, svc, f.server, f.alice, connect.NewRequest(&chatv1.CreateRoomRequest{
		Name: "Bob", Type: chatv1.RoomType_ROOM_TYPE_DIRECT,
		Members: []*commonv1.ContactLink{{ProfileId: f.bob}},
	}))
	s.WaitForMemberSubscription(ctx, svc, f.dm, f.bob, t)
	return f
}

func (f *partnerFixture) lookup(ctx context.Context, roomID string) (*chatv1.GetDirectPartnerAccountResponse, error) {
	resp, err := f.server.GetDirectPartnerAccount(ctx,
		connect.NewRequest(&chatv1.GetDirectPartnerAccountRequest{RoomId: roomID}))
	if err != nil {
		return nil, err
	}
	return resp.Msg, nil
}

// TestGetDirectPartnerAccountAnswersADMMember: Alice gets Bob's account;
// Bob gets Alice's, which is empty because she has none.
func (s *ChatServerTestSuite) TestGetDirectPartnerAccountAnswersADMMember() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		f := s.newPartnerFixture(ctx, t, svc)
		bobAccount := []byte{0xb0, 0xb0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x02}
		f.partners.Set(f.bob, bobAccount, false)

		got, err := f.lookup(f.aliceCtx, f.dm)
		require.NoError(t, err)
		require.Equal(t, f.bob, got.GetProfileId())
		require.Equal(t, bobAccount, got.GetAccount())
		require.False(t, got.GetDeployed(), "a counterfactual account is not deployed yet")

		got, err = f.lookup(f.bobCtx, f.dm)
		require.NoError(t, err)
		require.Equal(t, f.alice, got.GetProfileId())
		require.Empty(t, got.GetAccount())
	})
}

// TestGetDirectPartnerAccountRefusesOutsideTheDM: unauthenticated, a stranger,
// a group room and a DM someone left are refused, and settlement is never asked.
func (s *ChatServerTestSuite) TestGetDirectPartnerAccountRefusesOutsideTheDM() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		f := s.newPartnerFixture(ctx, t, svc)
		f.partners.Set(f.bob, []byte{1}, true)

		_, err := f.lookup(ctx, f.dm)
		require.Equal(t, connect.CodeUnauthenticated, connect.CodeOf(err))

		_, err = f.lookup(f.aliceCtx, "")
		require.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))

		carolCtx := s.WithAuthClaims(ctx, testTenantID, testPartitionID, util.IDString())
		_, err = f.lookup(carolCtx, f.dm)
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err), "a stranger")

		group := s.createRoomAndWait(f.aliceCtx, t, svc, f.server, f.alice,
			connect.NewRequest(&chatv1.CreateRoomRequest{Name: "Pair group",
				Members: []*commonv1.ContactLink{{ProfileId: f.bob, ContactId: f.bob}}}))
		s.WaitForMemberSubscription(ctx, svc, group, f.bob, t)
		_, err = f.lookup(f.aliceCtx, group)
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err), "a group of two is not a DM")

		// Bob leaves the DM (his subscription is deactivated, as leaving does).
		subRepo := repository.NewRoomSubscriptionRepository(ctx,
			svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName), svc.WorkManager())
		subs, err := subRepo.GetByContactLinkAndRooms(ctx, &commonv1.ContactLink{ProfileId: f.bob}, f.dm)
		require.NoError(t, err)
		require.Len(t, subs, 1)
		require.NoError(t, subRepo.Deactivate(ctx, subs[0].GetID()))
		_, err = f.lookup(f.aliceCtx, f.dm)
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err), "a DM Bob left")
		_, err = f.lookup(f.bobCtx, f.dm)
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err), "Bob is no longer a member")

		require.Empty(t, f.partners.Asked)
	})
}

// TestGetDirectPartnerAccountDuringASettlementOutage is Unavailable.
func (s *ChatServerTestSuite) TestGetDirectPartnerAccountDuringASettlementOutage() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		f := s.newPartnerFixture(ctx, t, svc)
		f.partners.Fail(connect.NewError(connect.CodeUnavailable, errors.New("settlement is down")))

		_, err := f.lookup(f.aliceCtx, f.dm)
		require.Equal(t, connect.CodeUnavailable, connect.CodeOf(err))
	})
}
