package business_test

import (
	"context"
	"testing"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	"github.com/pitabwire/frame"
	"github.com/pitabwire/frame/datastore"
	"github.com/pitabwire/frame/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"

	"github.com/stawilabs/chat/apps/default/service/business"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/tests"
)

type SubscriptionServiceTestSuite struct {
	tests.BaseTestSuite
}

func TestSubscriptionServiceTestSuite(t *testing.T) {
	suite.Run(t, new(SubscriptionServiceTestSuite))
}

func (s *SubscriptionServiceTestSuite) setupBusinessLayer(
	ctx context.Context, svc *frame.Service,
) (business.SubscriptionService, business.RoomBusiness) {
	workMan := svc.WorkManager()
	evtsMan := svc.EventsManager()
	dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)

	roomRepo := repository.NewRoomRepository(ctx, dbPool, workMan)
	eventRepo := repository.NewRoomEventRepository(ctx, dbPool, workMan)
	subRepo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

	subscriptionSvc := business.NewSubscriptionService(svc, subRepo)
	messageBusiness := business.NewMessageBusiness(evtsMan, eventRepo, subRepo, subscriptionSvc, s.AuthzMiddleware)
	roomBusiness := business.NewRoomBusiness(
		svc,
		roomRepo,
		eventRepo,
		subRepo,
		nil, // proposalRepo
		subscriptionSvc,
		evtsMan,
		messageBusiness,
		nil,
		s.AuthzMiddleware,
	)

	return subscriptionSvc, roomBusiness
}

func (s *SubscriptionServiceTestSuite) TestGetSubscription() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		subscriptionSvc, roomBusiness := s.setupBusinessLayer(ctx, svc)

		// Create room
		creatorID := util.IDString()
		creatorContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()
		nonMemberID := util.IDString()
		nonMemberContactID := util.IDString()

		roomReq := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
			Members:   []*commonv1.ContactLink{{ProfileId: memberID, ContactId: memberContactID}},
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			roomReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), memberID, t)

		// Creator should have a subscription
		sub, err := subscriptionSvc.GetSubscription(
			ctx,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
			room.GetId(),
		)
		require.NoError(t, err)
		s.NotNil(sub)

		// Member should have a subscription
		sub, err = subscriptionSvc.GetSubscription(
			ctx,
			&commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
			room.GetId(),
		)
		require.NoError(t, err)
		s.NotNil(sub)

		// Non-member should not have a subscription
		_, err = subscriptionSvc.GetSubscription(
			ctx,
			&commonv1.ContactLink{ProfileId: nonMemberID, ContactId: nonMemberContactID},
			room.GetId(),
		)
		require.Error(t, err)
	})
}

func (s *SubscriptionServiceTestSuite) TestHasRole() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		subscriptionSvc, roomBusiness := s.setupBusinessLayer(ctx, svc)

		// Create room
		creatorID := util.IDString()
		creatorContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()

		roomReq := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
			Members:   []*commonv1.ContactLink{{ProfileId: memberID, ContactId: memberContactID}},
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			roomReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), memberID, t)

		// Creator should have owner role
		hasRole, err := subscriptionSvc.HasRole(
			ctx,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
			room.GetId(),
			3, // roleOwnerLevel
		)
		require.NoError(t, err)
		require.NotNil(t, hasRole)

		// Member should not have owner role
		hasRole, err = subscriptionSvc.HasRole(
			ctx,
			&commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
			room.GetId(),
			3, // roleOwnerLevel
		)
		require.NoError(t, err)
		require.Nil(t, hasRole, "member should not have owner-level role")

		// Member should have member role
		hasRole, err = subscriptionSvc.HasRole(
			ctx,
			&commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
			room.GetId(),
			1, // roleMemberLevel
		)
		require.NoError(t, err)
		require.NotNil(t, hasRole)
	})
}

func (s *SubscriptionServiceTestSuite) TestGetSubscribedRoomIDs() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		subscriptionSvc, roomBusiness := s.setupBusinessLayer(ctx, svc)

		// Create multiple rooms
		userID := util.IDString()
		userContactID := util.IDString()
		roomCount := 5

		for range roomCount {
			roomReq := &chatv1.CreateRoomRequest{
				Name:      util.RandomAlphaNumericString(10),
				IsPrivate: false,
			}

			created, crErr := roomBusiness.CreateRoom(
				ctx,
				roomReq,
				&commonv1.ContactLink{ProfileId: userID, ContactId: userContactID},
			)
			require.NoError(t, crErr)
			s.WaitForRoomSubscription(ctx, svc, created.GetId(), t)
		}

		// Get subscribed room IDs
		roomIDs, err := subscriptionSvc.GetSubscribedRoomIDs(
			ctx,
			&commonv1.ContactLink{ProfileId: userID, ContactId: userContactID},
		)
		require.NoError(t, err)
		s.GreaterOrEqual(len(roomIDs), roomCount)
	})
}

func (s *SubscriptionServiceTestSuite) TestIsRoomMemberViaGetSubscription() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		subscriptionSvc, roomBusiness := s.setupBusinessLayer(ctx, svc)

		// Create room
		creatorID := util.IDString()
		creatorContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()
		nonMemberID := util.IDString()
		nonMemberContactID := util.IDString()

		roomReq := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
			Members:   []*commonv1.ContactLink{{ProfileId: memberID, ContactId: memberContactID}},
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			roomReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), memberID, t)

		// Check membership via GetSubscription
		creatorSub, err := subscriptionSvc.GetSubscription(
			ctx,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
			room.GetId(),
		)
		require.NoError(t, err)
		s.NotNil(creatorSub)

		memberSub, err := subscriptionSvc.GetSubscription(
			ctx,
			&commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
			room.GetId(),
		)
		require.NoError(t, err)
		s.NotNil(memberSub)

		_, err = subscriptionSvc.GetSubscription(
			ctx,
			&commonv1.ContactLink{ProfileId: nonMemberID, ContactId: nonMemberContactID},
			room.GetId(),
		)
		require.Error(t, err)
	})
}

func (s *SubscriptionServiceTestSuite) TestAccessAfterRemoval() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		subscriptionSvc, roomBusiness := s.setupBusinessLayer(ctx, svc)

		// Create room with member
		creatorID := util.IDString()
		creatorContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()

		roomReq := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
			Members:   []*commonv1.ContactLink{{ProfileId: memberID, ContactId: memberContactID}},
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			roomReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), memberID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, room.GetId(), t)
		s.WaitForAuthzAccess(ctx, svc, memberID, room.GetId(), t)

		// Verify member has subscription
		sub, err := subscriptionSvc.GetSubscription(
			ctx,
			&commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
			room.GetId(),
		)
		require.NoError(t, err)
		s.NotNil(sub)

		// Get subscription ID
		searchReq := &chatv1.SearchRoomSubscriptionsRequest{
			RoomId: room.GetId(),
		}
		searchResp, err := roomBusiness.SearchRoomSubscriptions(
			ctx,
			searchReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)

		var subscriptionID string
		for _, sub := range searchResp {
			if sub.GetMember().GetProfileId() == memberID {
				subscriptionID = sub.GetId()
				break
			}
		}
		require.NotEmpty(t, subscriptionID)

		// Remove member
		removeReq := &chatv1.RemoveRoomSubscriptionsRequest{
			RoomId:         room.GetId(),
			SubscriptionId: []string{subscriptionID},
		}

		err = roomBusiness.RemoveRoomSubscriptions(
			ctx,
			removeReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)

		// Verify member no longer has an active subscription
		_, err = subscriptionSvc.GetSubscription(
			ctx,
			&commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
			room.GetId(),
		)
		require.Error(t, err, "Removed member should not have active subscription")
	})
}

// TestValidationErrors_SubscriptionService tests all validation error paths
// in SubscriptionService methods in a single service setup to minimise DB usage.
func (s *SubscriptionServiceTestSuite) TestValidationErrors_SubscriptionService() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		subscriptionSvc, _ := s.setupBusinessLayer(ctx, svc)

		validContact := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}

		// --- GetSubscription validation ---
		t.Run("GetSubscription_InvalidContact", func(t *testing.T) {
			_, err := subscriptionSvc.GetSubscription(ctx, nil, "room-id")
			require.Error(t, err)

			_, err = subscriptionSvc.GetSubscription(ctx, &commonv1.ContactLink{}, "room-id")
			require.Error(t, err)
		})

		t.Run("GetSubscription_EmptyRoomID", func(t *testing.T) {
			_, err := subscriptionSvc.GetSubscription(ctx, validContact, "")
			require.Error(t, err)
		})

		// --- GetSubscriptionsForRooms validation ---
		t.Run("GetSubscriptionsForRooms_InvalidContact", func(t *testing.T) {
			_, err := subscriptionSvc.GetSubscriptionsForRooms(ctx, nil, []string{"room-id"})
			require.Error(t, err)

			_, err = subscriptionSvc.GetSubscriptionsForRooms(ctx, &commonv1.ContactLink{}, []string{"room-id"})
			require.Error(t, err)
		})

		t.Run("GetSubscriptionsForRooms_EmptyRoomIDs", func(t *testing.T) {
			result, err := subscriptionSvc.GetSubscriptionsForRooms(ctx, validContact, []string{})
			require.NoError(t, err)
			s.Empty(result, "empty room IDs should return empty result")

			result, err = subscriptionSvc.GetSubscriptionsForRooms(ctx, validContact, nil)
			require.NoError(t, err)
			s.Empty(result, "nil room IDs should return empty result")
		})

		t.Run("GetSubscriptionsForRooms_NonExistentRooms", func(t *testing.T) {
			result, err := subscriptionSvc.GetSubscriptionsForRooms(ctx, validContact,
				[]string{util.IDString(), util.IDString()})
			require.NoError(t, err)
			s.Empty(result, "non-existent rooms should return empty map")
		})

		// --- HasRole validation ---
		t.Run("HasRole_InvalidContact", func(t *testing.T) {
			_, err := subscriptionSvc.HasRole(ctx, nil, "room-id", business.RoleMemberLevel)
			require.Error(t, err)

			_, err = subscriptionSvc.HasRole(ctx, &commonv1.ContactLink{}, "room-id", business.RoleMemberLevel)
			require.Error(t, err)
		})

		t.Run("HasRole_EmptyRoomID", func(t *testing.T) {
			_, err := subscriptionSvc.HasRole(ctx, validContact, "", business.RoleMemberLevel)
			require.Error(t, err)
		})

		t.Run("HasRole_NonMember", func(t *testing.T) {
			result, err := subscriptionSvc.HasRole(ctx, validContact, util.IDString(), business.RoleOwnerLevel)
			require.NoError(t, err)
			s.Nil(result, "non-member should not have any role")
		})

		// --- CanMembersManage validation ---
		t.Run("CanMembersManage_InvalidContact", func(t *testing.T) {
			_, err := subscriptionSvc.CanMembersManage(ctx, nil, "room-id")
			require.Error(t, err)
		})

		t.Run("CanMembersManage_NonMember", func(t *testing.T) {
			result, err := subscriptionSvc.CanMembersManage(ctx, validContact, util.IDString())
			require.NoError(t, err)
			s.Nil(result, "non-member should not be able to manage members")
		})

		// --- CanRolesManage validation ---
		t.Run("CanRolesManage_InvalidContact", func(t *testing.T) {
			_, err := subscriptionSvc.CanRolesManage(ctx, nil, "room-id")
			require.Error(t, err)
		})

		t.Run("CanRolesManage_NonMember", func(t *testing.T) {
			result, err := subscriptionSvc.CanRolesManage(ctx, validContact, util.IDString())
			require.NoError(t, err)
			s.Nil(result, "non-member should not be able to manage roles")
		})

		// --- GetSubscribedRoomIDs validation ---
		t.Run("GetSubscribedRoomIDs_InvalidContact", func(t *testing.T) {
			_, err := subscriptionSvc.GetSubscribedRoomIDs(ctx, nil)
			require.Error(t, err)

			_, err = subscriptionSvc.GetSubscribedRoomIDs(ctx, &commonv1.ContactLink{})
			require.Error(t, err)
		})

		t.Run("GetSubscribedRoomIDs_NoSubscriptions", func(t *testing.T) {
			roomIDs, err := subscriptionSvc.GetSubscribedRoomIDs(ctx, validContact)
			require.NoError(t, err)
			s.Empty(roomIDs, "user with no subscriptions should return empty list")
		})
	})
}

// TestGetSubscriptionsForRooms_WithActiveRooms tests batch subscription lookup
// when the user is a member of some of the requested rooms.
func (s *SubscriptionServiceTestSuite) TestGetSubscriptionsForRooms_WithActiveRooms() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		subscriptionSvc, roomBusiness := s.setupBusinessLayer(ctx, svc)

		userID := util.IDString()
		userContactID := util.IDString()
		user := &commonv1.ContactLink{ProfileId: userID, ContactId: userContactID}

		// Create two rooms
		room1, err := roomBusiness.CreateRoom(ctx,
			&chatv1.CreateRoomRequest{Name: "Batch Room 1", IsPrivate: false}, user)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room1.GetId(), userID, t)

		room2, err := roomBusiness.CreateRoom(ctx,
			&chatv1.CreateRoomRequest{Name: "Batch Room 2", IsPrivate: false}, user)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room2.GetId(), userID, t)

		nonExistentRoomID := util.IDString()

		// Request subscriptions for two existing rooms and one non-existent
		result, err := subscriptionSvc.GetSubscriptionsForRooms(ctx, user,
			[]string{room1.GetId(), room2.GetId(), nonExistentRoomID})
		require.NoError(t, err)
		s.Len(result, 2, "should find subscriptions for two existing rooms")
		s.Contains(result, room1.GetId())
		s.Contains(result, room2.GetId())
		s.NotContains(result, nonExistentRoomID)
	})
}

// TestHasRole_DifferentLevels tests role hierarchy checking at different levels.
func (s *SubscriptionServiceTestSuite) TestHasRole_DifferentLevels() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		subscriptionSvc, roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()
		creator := &commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID}
		member := &commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID}

		room, err := roomBusiness.CreateRoom(ctx,
			&chatv1.CreateRoomRequest{
				Name:      "Role Test Room",
				IsPrivate: false,
				Members:   []*commonv1.ContactLink{member},
			}, creator)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), memberID, t)

		// Owner should satisfy all role levels
		for _, level := range []business.RoleLevel{
			business.RoleGuestLevel,
			business.RoleMemberLevel,
			business.RoleAdminLevel,
			business.RoleOwnerLevel,
		} {
			result, err := subscriptionSvc.HasRole(ctx, creator, room.GetId(), level)
			require.NoError(t, err)
			s.NotNil(result, "owner should satisfy role level %d", level)
		}

		// Member should satisfy guest and member but not admin or owner
		for _, level := range []business.RoleLevel{
			business.RoleGuestLevel,
			business.RoleMemberLevel,
		} {
			result, err := subscriptionSvc.HasRole(ctx, member, room.GetId(), level)
			require.NoError(t, err)
			s.NotNil(result, "member should satisfy role level %d", level)
		}

		for _, level := range []business.RoleLevel{
			business.RoleAdminLevel,
			business.RoleOwnerLevel,
		} {
			result, err := subscriptionSvc.HasRole(ctx, member, room.GetId(), level)
			require.NoError(t, err)
			s.Nil(result, "member should NOT satisfy role level %d", level)
		}
	})
}
