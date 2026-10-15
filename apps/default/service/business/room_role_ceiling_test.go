package business_test

import (
	"context"
	"testing"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"github.com/pitabwire/frame/v3/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/service"
	"github.com/stawilabs/chat/apps/default/service/business"
)

// rolesOf answers each member's roles in the room, keyed by profile id.
func rolesOf(
	ctx context.Context,
	t *testing.T,
	rb business.RoomBusiness,
	roomID string,
	reader *commonv1.ContactLink,
) map[string][]string {
	t.Helper()
	subs, err := rb.SearchRoomSubscriptions(ctx, &chatv1.SearchRoomSubscriptionsRequest{RoomId: roomID}, reader)
	require.NoError(t, err)
	out := make(map[string][]string, len(subs))
	for _, sub := range subs {
		out[sub.GetMember().GetProfileId()] = sub.GetRoles()
	}
	return out
}

// TestAddRoomSubscriptions_RoleCeiling: adding members never grants a role
// above the adder's own, never accepts an unknown role, and never changes the
// role of someone already in the room (role changes go through
// UpdateSubscriptionRole, which only an owner may call and which guards the
// last owner).
func (s *RoomBusinessTestSuite) TestAddRoomSubscriptions_RoleCeiling() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		rb := s.setupBusinessLayer(ctx, svc)

		owner := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		admin := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}

		created, err := rb.CreateRoom(ctx, &chatv1.CreateRoomRequest{Name: "Ceiling"}, owner)
		require.NoError(t, err)
		roomID := created.GetId()
		s.WaitForMemberSubscription(ctx, svc, roomID, owner.GetProfileId(), t)
		s.WaitForAuthzAccess(ctx, svc, owner.GetProfileId(), roomID, t)

		require.NoError(t, rb.AddRoomSubscriptions(ctx, &chatv1.AddRoomSubscriptionsRequest{
			RoomId:  roomID,
			Members: []*chatv1.RoomSubscription{{Member: admin, Roles: []string{"admin"}}},
		}, owner))
		s.WaitForMemberSubscription(ctx, svc, roomID, admin.GetProfileId(), t)
		s.WaitForAuthzAccess(ctx, svc, admin.GetProfileId(), roomID, t)

		add := func(by *commonv1.ContactLink, member *commonv1.ContactLink, roles ...string) error {
			return rb.AddRoomSubscriptions(ctx, &chatv1.AddRoomSubscriptionsRequest{
				RoomId:  roomID,
				Members: []*chatv1.RoomSubscription{{Member: member, Roles: roles}},
			}, by)
		}

		t.Run("an admin cannot grant owner to a newcomer", func(t *testing.T) {
			newcomer := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
			require.ErrorIs(t, add(admin, newcomer, "owner"), service.ErrRoleGrantDenied)
			_, present := rolesOf(ctx, t, rb, roomID, owner)[newcomer.GetProfileId()]
			require.False(t, present, "a refused grant adds no one")
		})

		t.Run("an admin cannot make themselves owner", func(t *testing.T) {
			require.ErrorIs(t, add(admin, admin, "owner"), service.ErrRoleGrantDenied)
			require.Equal(t, []string{"admin"}, rolesOf(ctx, t, rb, roomID, owner)[admin.GetProfileId()])
		})

		t.Run("an admin cannot demote the owner by re-adding them", func(t *testing.T) {
			_ = add(admin, owner, "member")
			require.Equal(t, []string{"owner"}, rolesOf(ctx, t, rb, roomID, owner)[owner.GetProfileId()])
		})

		t.Run("an owner re-adding a member does not change their role either", func(t *testing.T) {
			_ = add(owner, admin, "guest")
			require.Equal(t, []string{"admin"}, rolesOf(ctx, t, rb, roomID, owner)[admin.GetProfileId()])
		})

		t.Run("an unknown role is refused", func(t *testing.T) {
			newcomer := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
			require.ErrorIs(t, add(owner, newcomer, "superuser"), service.ErrInvalidRole)
		})

		t.Run("an admin may add members and admins", func(t *testing.T) {
			m := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
			a := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
			require.NoError(t, add(admin, m))
			require.NoError(t, add(admin, a, "admin"))
			s.WaitForMemberSubscription(ctx, svc, roomID, a.GetProfileId(), t)
			roles := rolesOf(ctx, t, rb, roomID, owner)
			require.Equal(t, []string{"member"}, roles[m.GetProfileId()])
			require.Equal(t, []string{"admin"}, roles[a.GetProfileId()])
		})
	})
}
