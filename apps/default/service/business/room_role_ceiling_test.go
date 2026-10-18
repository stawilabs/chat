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

// subscriptionOf answers the member's subscription id in the room.
func subscriptionOf(
	ctx context.Context,
	t *testing.T,
	rb business.RoomBusiness,
	roomID string,
	reader, member *commonv1.ContactLink,
) string {
	t.Helper()
	subs, err := rb.SearchRoomSubscriptions(ctx, &chatv1.SearchRoomSubscriptionsRequest{RoomId: roomID}, reader)
	require.NoError(t, err)
	for _, sub := range subs {
		if sub.GetMember().GetProfileId() == member.GetProfileId() {
			return sub.GetId()
		}
	}
	t.Fatalf("%s is not in the room", member.GetProfileId())
	return ""
}

// TestRemoveRoomSubscriptions_RoleCeiling: removing is held to the same
// ceiling as adding. An admin cannot remove any owner (not only the last), so
// cannot demote one by removing and re-adding them; an owner still can remove
// a co-owner, and an admin still removes members.
func (s *RoomBusinessTestSuite) TestRemoveRoomSubscriptions_RoleCeiling() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		rb := s.setupBusinessLayer(ctx, svc)

		owner := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		coOwner := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		admin := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		member := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}

		created, err := rb.CreateRoom(ctx, &chatv1.CreateRoomRequest{Name: "Ceiling"}, owner)
		require.NoError(t, err)
		roomID := created.GetId()
		s.WaitForMemberSubscription(ctx, svc, roomID, owner.GetProfileId(), t)
		s.WaitForAuthzAccess(ctx, svc, owner.GetProfileId(), roomID, t)

		require.NoError(t, rb.AddRoomSubscriptions(ctx, &chatv1.AddRoomSubscriptionsRequest{
			RoomId: roomID,
			Members: []*chatv1.RoomSubscription{
				{Member: coOwner, Roles: []string{"owner"}},
				{Member: admin, Roles: []string{"admin"}},
				{Member: member, Roles: []string{"member"}},
			},
		}, owner))
		for _, m := range []*commonv1.ContactLink{coOwner, admin, member} {
			s.WaitForMemberSubscription(ctx, svc, roomID, m.GetProfileId(), t)
		}
		s.WaitForAuthzAccess(ctx, svc, admin.GetProfileId(), roomID, t)

		remove := func(by *commonv1.ContactLink, who ...*commonv1.ContactLink) error {
			ids := make([]string, 0, len(who))
			for _, w := range who {
				ids = append(ids, subscriptionOf(ctx, t, rb, roomID, owner, w))
			}
			return rb.RemoveRoomSubscriptions(ctx, &chatv1.RemoveRoomSubscriptionsRequest{
				RoomId: roomID, SubscriptionId: ids,
			}, by)
		}

		t.Run("an admin cannot remove an owner who is not the last", func(t *testing.T) {
			require.ErrorIs(t, remove(admin, coOwner), service.ErrRoleRemoveDenied)
			require.Equal(t, []string{"owner"}, rolesOf(ctx, t, rb, roomID, owner)[coOwner.GetProfileId()])
		})

		t.Run("nor demote one by removing and re-adding them", func(t *testing.T) {
			require.ErrorIs(t, remove(admin, member, coOwner), service.ErrRoleRemoveDenied,
				"one owner in the batch refuses it all")
			_ = rb.AddRoomSubscriptions(ctx, &chatv1.AddRoomSubscriptionsRequest{
				RoomId:  roomID,
				Members: []*chatv1.RoomSubscription{{Member: coOwner, Roles: []string{"member"}}},
			}, admin)
			roles := rolesOf(ctx, t, rb, roomID, owner)
			require.Equal(t, []string{"owner"}, roles[coOwner.GetProfileId()])
			require.Equal(t, []string{"member"}, roles[member.GetProfileId()], "the member was not removed")
		})

		t.Run("an admin still removes a member", func(t *testing.T) {
			require.NoError(t, remove(admin, member))
			_, present := rolesOf(ctx, t, rb, roomID, owner)[member.GetProfileId()]
			require.False(t, present)
		})

		t.Run("an owner removes a co-owner", func(t *testing.T) {
			require.NoError(t, remove(owner, coOwner))
			_, present := rolesOf(ctx, t, rb, roomID, owner)[coOwner.GetProfileId()]
			require.False(t, present)
		})
	})
}
