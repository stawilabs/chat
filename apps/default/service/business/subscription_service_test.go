package business_test

import (
	"context"
	"testing"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	"github.com/antinvestor/service-chat/apps/default/service/business"
	"github.com/antinvestor/service-chat/apps/default/service/repository"
	"github.com/antinvestor/service-chat/apps/default/tests"
	"github.com/pitabwire/frame"
	"github.com/pitabwire/frame/datastore"
	"github.com/pitabwire/frame/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
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
