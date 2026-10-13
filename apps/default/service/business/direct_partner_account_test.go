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

// personCtx is the context of member signed in to tenant (partition
// cardPartition).
func personCtx(f *stawiFixture, member *commonv1.ContactLink, tenant string) context.Context {
	claims := &security.AuthenticationClaims{TenantID: tenant, PartitionID: cardPartition,
		ContactID: member.GetContactId()}
	claims.Subject = member.GetProfileId()
	return claims.ClaimsToContext(f.ctx)
}

// as is member's own context in the card tenancy.
func (f *stawiFixture) as(member *commonv1.ContactLink) context.Context {
	return personCtx(f, member, cardTenant)
}

// dmOf has from start a DM with to, in the card tenancy, and returns its id.
func (f *stawiFixture) dmOf(t *testing.T, from, to *commonv1.ContactLink) string {
	t.Helper()
	room, err := f.rb.CreateRoom(f.as(from), &chatv1.CreateRoomRequest{
		Name: "DM", Type: chatv1.RoomType_ROOM_TYPE_DIRECT,
		Members: []*commonv1.ContactLink{{ProfileId: to.GetProfileId()}},
	}, from)
	require.NoError(t, err)
	require.Equal(t, chatv1.RoomType_ROOM_TYPE_DIRECT, room.GetType())
	f.placeRoom(t, room.GetId(), cardTenant, cardPartition)
	return room.GetId()
}

// write has member send a text message into roomID.
func (f *stawiFixture) write(t *testing.T, roomID string, member *commonv1.ContactLink) {
	t.Helper()
	acks, err := f.mb.SendEvents(f.as(member), &chatv1.SendEventRequest{Event: []*chatv1.RoomEvent{{
		RoomId: roomID, Type: chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
		Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "hello"}}},
	}}}, member)
	require.NoError(t, err)
	require.Len(t, acks, 1)
	require.Empty(t, acks[0].GetError())
}

// requireNoPartner asserts the one refusal every unentitled lookup gets.
func requireNoPartner(t *testing.T, err error) {
	t.Helper()
	require.Error(t, err)
	require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err))
	require.ErrorIs(t, err, service.ErrNoDirectPartner, "every refusal is the same answer")
}

// TestADMMemberReadsThePartnersAccount: once each has taken part, each person
// in a DM gets the other's Stawi account; a partner without one is an empty
// answer.
func (s *MessageBusinessTestSuite) TestADMMemberReadsThePartnersAccount() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		dm := f.dmOf(t, f.alice, f.bob)
		f.write(t, dm, f.bob)
		bobAccount := []byte{0xb0, 0xb0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x01}
		f.partners.Set(f.bob.GetProfileId(), bobAccount, true)

		got, err := f.rb.GetDirectPartnerAccount(f.as(f.alice), dm, f.alice)
		require.NoError(t, err)
		require.Equal(t, f.bob.GetProfileId(), got.GetProfileId())
		require.Equal(t, bobAccount, got.GetAccount())
		require.True(t, got.GetDeployed())

		got, err = f.rb.GetDirectPartnerAccount(f.as(f.bob), dm, f.bob)
		require.NoError(t, err)
		require.Equal(t, f.alice.GetProfileId(), got.GetProfileId())
		require.Empty(t, got.GetAccount(), "Alice has no Stawi account yet")
		require.False(t, got.GetDeployed())
		require.Equal(t, []string{f.bob.GetProfileId(), f.alice.GetProfileId()}, f.partners.Asked)
	})
}

// TestADMPartnersAccountNeedsThePartnersConsent: anyone may start a DM with
// any profile, so a DM a stranger started reveals nothing until the person
// it names writes in it. The person who started a DM consented by starting it.
func (s *MessageBusinessTestSuite) TestADMPartnersAccountNeedsThePartnersConsent() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		victim, attacker := f.alice, &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		f.partners.Set(
			victim.GetProfileId(),
			[]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20},
			true,
		)

		dm := f.dmOf(t, attacker, victim)
		f.write(t, dm, attacker)
		_, err := f.rb.GetDirectPartnerAccount(f.as(attacker), dm, attacker)
		requireNoPartner(t, err)
		require.Empty(t, f.partners.Asked, "settlement is not asked before the victim takes part")

		// The victim answers: now they have taken part.
		f.write(t, dm, victim)
		got, err := f.rb.GetDirectPartnerAccount(f.as(attacker), dm, attacker)
		require.NoError(t, err)
		require.Equal(t, victim.GetProfileId(), got.GetProfileId())

		// The victim started this DM: starting it is taking part.
		started := f.dmOf(t, victim, f.bob)
		f.partners.Asked = nil
		got, err = f.rb.GetDirectPartnerAccount(f.as(f.bob), started, f.bob)
		require.NoError(t, err)
		require.Equal(t, victim.GetProfileId(), got.GetProfileId())
		// Bob, who never wrote, is not revealed to the victim.
		_, err = f.rb.GetDirectPartnerAccount(f.as(victim), started, victim)
		requireNoPartner(t, err)
		require.Equal(t, []string{victim.GetProfileId()}, f.partners.Asked)
	})
}

// TestADMPartnerLookupIsRefusedOutsideTheDM: a stranger, a group room (even of
// exactly two people), a DM someone left, an unknown room, a DM of another
// tenancy, claims without a tenancy, a service or internal principal and
// another profile's claims are all refused with the same answer, and
// settlement is never asked.
func (s *MessageBusinessTestSuite) TestADMPartnerLookupIsRefusedOutsideTheDM() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		f.partners.Set(f.bob.GetProfileId(), []byte{1}, true)
		dm := f.dmOf(t, f.alice, f.bob)
		f.write(t, dm, f.bob)
		carol := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}

		_, err := f.rb.GetDirectPartnerAccount(f.as(carol), dm, carol)
		requireNoPartner(t, err)

		// f.roomID is a group of exactly Alice and Bob.
		f.placeRoom(t, f.roomID, cardTenant, cardPartition)
		_, err = f.rb.GetDirectPartnerAccount(f.as(f.alice), f.roomID, f.alice)
		requireNoPartner(t, err)

		_, err = f.rb.GetDirectPartnerAccount(f.as(f.alice), util.IDString(), f.alice)
		requireNoPartner(t, err)

		_, err = f.rb.GetDirectPartnerAccount(personCtx(f, f.alice, "tenant-other"), dm, f.alice)
		requireNoPartner(t, err)

		// No claims at all, and claims without a tenancy, fail closed.
		_, err = f.rb.GetDirectPartnerAccount(f.ctx, dm, f.alice)
		requireNoPartner(t, err)
		_, err = f.rb.GetDirectPartnerAccount(personCtx(f, f.alice, ""), dm, f.alice)
		requireNoPartner(t, err)

		// A service or internal principal is not a person, even naming one.
		internal := &security.AuthenticationClaims{TenantID: cardTenant, PartitionID: cardPartition,
			ContactID: f.alice.GetContactId(), Roles: []string{security.ConstantSystemInternalRole}}
		internal.Subject = f.alice.GetProfileId()
		_, err = f.rb.GetDirectPartnerAccount(internal.ClaimsToContext(f.ctx), dm, f.alice)
		requireNoPartner(t, err)
		named := &security.AuthenticationClaims{TenantID: cardTenant, PartitionID: cardPartition,
			ContactID: f.alice.GetContactId(), ServiceName: "service-finance"}
		named.Subject = f.alice.GetProfileId()
		_, err = f.rb.GetDirectPartnerAccount(named.ClaimsToContext(f.ctx), dm, f.alice)
		requireNoPartner(t, err)

		// Claims of one person cannot ask as another.
		_, err = f.rb.GetDirectPartnerAccount(f.as(carol), dm, f.alice)
		requireNoPartner(t, err)

		f.leave(t, dm, f.bob)
		_, err = f.rb.GetDirectPartnerAccount(f.as(f.alice), dm, f.alice)
		requireNoPartner(t, err)
		_, err = f.rb.GetDirectPartnerAccount(f.as(f.bob), dm, f.bob)
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
		f.write(t, dm, f.bob)

		for _, cause := range []error{
			connect.NewError(connect.CodeUnavailable, errors.New("settlement is down")),
			connect.NewError(connect.CodePermissionDenied, errors.New("chat lacks profile_account_view")),
			errors.New("connection reset"),
		} {
			f.partners.Fail(cause)
			_, err := f.rb.GetDirectPartnerAccount(f.as(f.alice), dm, f.alice)
			require.Equal(t, connect.CodeUnavailable, connect.CodeOf(err), "cause: %v", cause)
		}

		// Settlement knowing no such profile is "no account", not an outage.
		f.partners.Fail(connect.NewError(connect.CodeNotFound, errors.New("no such profile")))
		got, err := f.rb.GetDirectPartnerAccount(f.as(f.alice), dm, f.alice)
		require.NoError(t, err)
		require.Equal(t, f.bob.GetProfileId(), got.GetProfileId())
		require.Empty(t, got.GetAccount())
	})
}
