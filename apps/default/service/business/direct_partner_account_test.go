package business_test

import (
	"context"
	"errors"
	"testing"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/pitabwire/frame/v2/frametests/definition"
	"github.com/pitabwire/frame/v2/security"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/service"
)

// dmOf has from start a DM with to and returns its id.
func (f *stawiFixture) dmOf(t *testing.T, from, to *commonv1.ContactLink) string {
	t.Helper()
	room, err := f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{
		Name: "DM", Type: chatv1.RoomType_ROOM_TYPE_DIRECT,
		Members: []*commonv1.ContactLink{{ProfileId: to.GetProfileId()}},
	}, from)
	require.NoError(t, err)
	require.Equal(t, chatv1.RoomType_ROOM_TYPE_DIRECT, room.GetType())
	return room.GetId()
}

// requireNoPartner asserts the one refusal every unentitled lookup gets.
func requireNoPartner(t *testing.T, err error) {
	t.Helper()
	require.Error(t, err)
	require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err))
	require.ErrorIs(t, err, service.ErrNoDirectPartner, "every refusal is the same answer")
}

// TestADMMemberReadsThePartnersAccount: each person in a DM gets the other's
// Stawi account from settlement; a partner without one is an empty answer.
func (s *MessageBusinessTestSuite) TestADMMemberReadsThePartnersAccount() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		dm := f.dmOf(t, f.alice, f.bob)
		bobAccount := []byte{0xb0, 0xb0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x01}
		f.partners.Set(f.bob.GetProfileId(), bobAccount, true)

		got, err := f.rb.GetDirectPartnerAccount(f.ctx, dm, f.alice)
		require.NoError(t, err)
		require.Equal(t, f.bob.GetProfileId(), got.GetProfileId())
		require.Equal(t, bobAccount, got.GetAccount())
		require.True(t, got.GetDeployed())

		got, err = f.rb.GetDirectPartnerAccount(f.ctx, dm, f.bob)
		require.NoError(t, err)
		require.Equal(t, f.alice.GetProfileId(), got.GetProfileId())
		require.Empty(t, got.GetAccount(), "Alice has no Stawi account yet")
		require.False(t, got.GetDeployed())
		require.Equal(t, []string{f.bob.GetProfileId(), f.alice.GetProfileId()}, f.partners.Asked)

		// A caller of the room's tenancy is answered.
		f.placeRoom(t, dm, cardTenant, cardPartition)
		_, err = f.rb.GetDirectPartnerAccount(personCtx(f, f.alice, cardTenant), dm, f.alice)
		require.NoError(t, err)
	})
}

// TestADMPartnerLookupIsRefusedOutsideTheDM: a stranger, a group room (even of
// exactly two people), a DM someone left, an unknown room and a DM of another
// tenancy are all refused with the same answer, and settlement is never asked.
func (s *MessageBusinessTestSuite) TestADMPartnerLookupIsRefusedOutsideTheDM() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		f.partners.Set(f.bob.GetProfileId(), []byte{1}, true)
		dm := f.dmOf(t, f.alice, f.bob)
		carol := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}

		_, err := f.rb.GetDirectPartnerAccount(f.ctx, dm, carol)
		requireNoPartner(t, err)

		// f.roomID is a group of exactly Alice and Bob.
		_, err = f.rb.GetDirectPartnerAccount(f.ctx, f.roomID, f.alice)
		requireNoPartner(t, err)

		_, err = f.rb.GetDirectPartnerAccount(f.ctx, util.IDString(), f.alice)
		requireNoPartner(t, err)

		f.placeRoom(t, dm, cardTenant, cardPartition)
		_, err = f.rb.GetDirectPartnerAccount(personCtx(f, f.alice, "tenant-other"), dm, f.alice)
		requireNoPartner(t, err)

		f.leave(t, dm, f.bob)
		_, err = f.rb.GetDirectPartnerAccount(f.ctx, dm, f.alice)
		requireNoPartner(t, err)
		_, err = f.rb.GetDirectPartnerAccount(f.ctx, dm, f.bob)
		requireNoPartner(t, err)

		require.Empty(t, f.partners.Asked, "settlement is asked only for an entitled caller")
	})
}

// TestADMPartnerLookupDuringASettlementOutageIsUnavailable: whatever settlement
// fails with, the member is told to retry; settlement's own refusal is not
// passed on.
func (s *MessageBusinessTestSuite) TestADMPartnerLookupDuringASettlementOutageIsUnavailable() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		dm := f.dmOf(t, f.alice, f.bob)

		for _, cause := range []error{
			connect.NewError(connect.CodeUnavailable, errors.New("settlement is down")),
			connect.NewError(connect.CodePermissionDenied, errors.New("chat lacks profile_account_view")),
			errors.New("connection reset"),
		} {
			f.partners.Fail(cause)
			_, err := f.rb.GetDirectPartnerAccount(f.ctx, dm, f.alice)
			require.Equal(t, connect.CodeUnavailable, connect.CodeOf(err), "cause: %v", cause)
		}

		// Settlement knowing no such profile is "no account", not an outage.
		f.partners.Fail(connect.NewError(connect.CodeNotFound, errors.New("no such profile")))
		got, err := f.rb.GetDirectPartnerAccount(f.ctx, dm, f.alice)
		require.NoError(t, err)
		require.Equal(t, f.bob.GetProfileId(), got.GetProfileId())
		require.Empty(t, got.GetAccount())
	})
}

// personCtx is the context of member signed in to tenant.
func personCtx(f *stawiFixture, member *commonv1.ContactLink, tenant string) context.Context {
	claims := &security.AuthenticationClaims{TenantID: tenant, PartitionID: cardPartition,
		ContactID: member.GetContactId()}
	claims.Subject = member.GetProfileId()
	return claims.ClaimsToContext(f.ctx)
}
