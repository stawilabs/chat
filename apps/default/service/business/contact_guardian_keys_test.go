package business_test

import (
	"errors"
	"testing"
	"time"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	"connectrpc.com/connect/v2"
	"github.com/pitabwire/frame/v3/frametests/definition"
	"github.com/pitabwire/frame/v3/security"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/service"
	"github.com/stawilabs/chat/apps/default/service/stawi"
)

// requireNoContact asserts the one refusal every unentitled key lookup gets.
func requireNoContact(t *testing.T, err error) {
	t.Helper()
	require.Error(t, err)
	require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err))
	require.ErrorIs(t, err, service.ErrNoSharedContact, "every refusal is the same answer")
}

func guardianKey(b byte) stawi.GuardianKey {
	key := make([]byte, 20)
	account := make([]byte, 20)
	key[0], account[0] = b, b+1
	return stawi.GuardianKey{Key: key, Account: account, RegisteredAt: time.Unix(1_790_000_000, 0).UTC()}
}

// TestADMMemberReadsTheContactsGuardianKeys: in a DM each person reads the
// other's guardian keys once the other has taken part; the answer carries
// settlement's keys and head.
func (s *MessageBusinessTestSuite) TestADMMemberReadsTheContactsGuardianKeys() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		dm := f.dmOf(t, f.alice, f.bob)
		bobKey := guardianKey(0xb0)
		f.guardians.Set(f.bob.GetProfileId(), bobKey)
		f.guardians.Head = 77

		_, err := f.rb.LookupContactGuardianKeys(f.as(f.alice), dm, f.bob.GetProfileId(), f.alice)
		requireNoContact(t, err)
		require.Empty(t, f.guardians.Asked, "Bob has not taken part yet")

		f.write(t, dm, f.bob)
		got, err := f.rb.LookupContactGuardianKeys(f.as(f.alice), dm, f.bob.GetProfileId(), f.alice)
		require.NoError(t, err)
		require.Equal(t, f.bob.GetProfileId(), got.GetProfileId())
		require.Equal(t, uint64(77), got.GetBlockNumber())
		require.Len(t, got.GetKeys(), 1)
		require.Equal(t, bobKey.Key, got.GetKeys()[0].GetKey())
		require.Equal(t, bobKey.Account, got.GetKeys()[0].GetAccount())
		require.True(t, bobKey.RegisteredAt.Equal(got.GetKeys()[0].GetRegisteredAt().AsTime()))

		// Alice started the DM: that is taking part. She registered no key.
		got, err = f.rb.LookupContactGuardianKeys(f.as(f.bob), dm, f.alice.GetProfileId(), f.bob)
		require.NoError(t, err)
		require.Equal(t, f.alice.GetProfileId(), got.GetProfileId())
		require.Empty(t, got.GetKeys())
		require.Equal(t, []string{f.bob.GetProfileId(), f.alice.GetProfileId()}, f.guardians.Asked)
	})
}

// TestAGroupMemberReadsAFellowMembersGuardianKeys: in a group room a fellow
// active member's keys are answered only once they have written in it; being
// the room's owner is not taking part, since a group's roles can be changed.
func (s *MessageBusinessTestSuite) TestAGroupMemberReadsAFellowMembersGuardianKeys() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		f.placeRoom(t, f.roomID, cardTenant, cardPartition)
		f.guardians.Set(f.bob.GetProfileId(), guardianKey(0xb0))
		f.guardians.Set(f.alice.GetProfileId(), guardianKey(0xa0))

		_, err := f.rb.LookupContactGuardianKeys(f.as(f.alice), f.roomID, f.bob.GetProfileId(), f.alice)
		requireNoContact(t, err)
		_, err = f.rb.LookupContactGuardianKeys(f.as(f.bob), f.roomID, f.alice.GetProfileId(), f.bob)
		requireNoContact(t, err)
		require.Empty(t, f.guardians.Asked, "neither has written in the group")

		f.write(t, f.roomID, f.bob)
		got, err := f.rb.LookupContactGuardianKeys(f.as(f.alice), f.roomID, f.bob.GetProfileId(), f.alice)
		require.NoError(t, err)
		require.Len(t, got.GetKeys(), 1)
		require.Equal(t, byte(0xb0), got.GetKeys()[0].GetKey()[0])

		_, err = f.rb.LookupContactGuardianKeys(f.as(f.bob), f.roomID, f.alice.GetProfileId(), f.bob)
		requireNoContact(t, err)
		f.write(t, f.roomID, f.alice)
		got, err = f.rb.LookupContactGuardianKeys(f.as(f.bob), f.roomID, f.alice.GetProfileId(), f.bob)
		require.NoError(t, err)
		require.Equal(t, byte(0xa0), got.GetKeys()[0].GetKey()[0])
	})
}

// TestAContactsGuardianKeysAreRefusedOutsideASharedRoom: a stranger, a
// contact who is not in the room, oneself, a DM's non-partner, an unknown
// room, another tenancy, claims without a tenancy, a service or internal
// principal, another profile's claims and a member who left are all refused
// with the same answer, and settlement is never asked.
func (s *MessageBusinessTestSuite) TestAContactsGuardianKeysAreRefusedOutsideASharedRoom() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		f.placeRoom(t, f.roomID, cardTenant, cardPartition)
		f.write(t, f.roomID, f.bob)
		f.write(t, f.roomID, f.alice)
		dm := f.dmOf(t, f.alice, f.bob)
		f.write(t, dm, f.bob)
		carol := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		bob := f.bob.GetProfileId()

		_, err := f.rb.LookupContactGuardianKeys(f.as(carol), f.roomID, bob, carol)
		requireNoContact(t, err)
		_, err = f.rb.LookupContactGuardianKeys(f.as(f.alice), f.roomID, carol.GetProfileId(), f.alice)
		requireNoContact(t, err)
		_, err = f.rb.LookupContactGuardianKeys(f.as(f.alice), f.roomID, f.alice.GetProfileId(), f.alice)
		requireNoContact(t, err)
		_, err = f.rb.LookupContactGuardianKeys(f.as(f.alice), dm, carol.GetProfileId(), f.alice)
		requireNoContact(t, err)
		_, err = f.rb.LookupContactGuardianKeys(f.as(f.alice), util.IDString(), bob, f.alice)
		requireNoContact(t, err)
		_, err = f.rb.LookupContactGuardianKeys(personCtx(f, f.alice, "tenant-other"), f.roomID, bob, f.alice)
		requireNoContact(t, err)

		_, err = f.rb.LookupContactGuardianKeys(f.ctx, f.roomID, bob, f.alice)
		requireNoContact(t, err)
		_, err = f.rb.LookupContactGuardianKeys(personCtx(f, f.alice, ""), f.roomID, bob, f.alice)
		requireNoContact(t, err)

		internal := &security.AuthenticationClaims{TenantID: cardTenant, PartitionID: cardPartition,
			ContactID: f.alice.GetContactId(), Roles: []string{security.ConstantSystemInternalRole}}
		internal.Subject = f.alice.GetProfileId()
		_, err = f.rb.LookupContactGuardianKeys(internal.ClaimsToContext(f.ctx), f.roomID, bob, f.alice)
		requireNoContact(t, err)
		named := &security.AuthenticationClaims{TenantID: cardTenant, PartitionID: cardPartition,
			ContactID: f.alice.GetContactId(), ServiceName: "service-finance"}
		named.Subject = f.alice.GetProfileId()
		_, err = f.rb.LookupContactGuardianKeys(named.ClaimsToContext(f.ctx), f.roomID, bob, f.alice)
		requireNoContact(t, err)

		_, err = f.rb.LookupContactGuardianKeys(f.as(carol), f.roomID, bob, f.alice)
		requireNoContact(t, err)

		f.leave(t, f.roomID, f.bob)
		_, err = f.rb.LookupContactGuardianKeys(f.as(f.alice), f.roomID, bob, f.alice)
		requireNoContact(t, err)
		_, err = f.rb.LookupContactGuardianKeys(f.as(f.bob), f.roomID, f.alice.GetProfileId(), f.bob)
		requireNoContact(t, err)

		require.Empty(t, f.guardians.Asked, "settlement is asked only for an entitled caller")
	})
}

// TestAContactsGuardianKeysDuringASettlementOutageAreUnavailable: whatever
// settlement fails with, the member is told to retry.
func (s *MessageBusinessTestSuite) TestAContactsGuardianKeysDuringASettlementOutageAreUnavailable() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		dm := f.dmOf(t, f.alice, f.bob)
		f.write(t, dm, f.bob)

		for _, cause := range []error{
			connect.NewError(connect.CodeUnavailable, "settlement is down"),
			connect.NewError(connect.CodePermissionDenied, "chat lacks account_view"),
			errors.New("connection reset"),
		} {
			f.guardians.Fail(cause)
			_, err := f.rb.LookupContactGuardianKeys(f.as(f.alice), dm, f.bob.GetProfileId(), f.alice)
			require.Equal(t, connect.CodeUnavailable, connect.CodeOf(err), "cause: %v", cause)
			require.ErrorIs(t, err, service.ErrContactKeysUnavailable)
		}
	})
}

// TestContactKeyLookupsShareThePartnerLookupLimit: a person who used up their
// partner lookups is told to wait for key lookups too, and settlement is not
// asked.
func (s *MessageBusinessTestSuite) TestContactKeyLookupsShareThePartnerLookupLimit() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		dm := f.dmOf(t, f.alice, f.bob)
		f.write(t, dm, f.bob)

		var err error
		for range 200 {
			if _, err = f.rb.GetDirectPartnerAccount(f.as(f.alice), dm, f.alice); err != nil {
				break
			}
		}
		require.Equal(t, connect.CodeResourceExhausted, connect.CodeOf(err))
		_, err = f.rb.LookupContactGuardianKeys(f.as(f.alice), dm, f.bob.GetProfileId(), f.alice)
		require.Equal(t, connect.CodeResourceExhausted, connect.CodeOf(err))
		require.Empty(t, f.guardians.Asked)

		_, err = f.rb.LookupContactGuardianKeys(f.as(f.bob), dm, f.alice.GetProfileId(), f.bob)
		require.NoError(t, err, "each person has their own limit")
	})
}
