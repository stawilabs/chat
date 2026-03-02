package business_test

import (
	"context"
	"testing"
	"time"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	"github.com/antinvestor/service-chat/apps/default/service"
	"github.com/antinvestor/service-chat/apps/default/service/business"
	"github.com/antinvestor/service-chat/apps/default/service/models"
	"github.com/antinvestor/service-chat/apps/default/service/repository"
	"github.com/antinvestor/service-chat/apps/default/tests"
	"github.com/pitabwire/frame"
	"github.com/pitabwire/frame/data"
	"github.com/pitabwire/frame/datastore"
	"github.com/pitabwire/frame/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	"google.golang.org/protobuf/proto"
)

type RoomBusinessTestSuite struct {
	tests.BaseTestSuite
}

func TestRoomBusinessTestSuite(t *testing.T) {
	suite.Run(t, new(RoomBusinessTestSuite))
}

func (s *RoomBusinessTestSuite) setupBusinessLayer(
	ctx context.Context, svc *frame.Service,
) business.RoomBusiness {
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

	return roomBusiness
}

func (s *RoomBusinessTestSuite) TestCreateRoom() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		creator := &commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID}

		t.Run("BasicCreate", func(t *testing.T) {
			req := &chatv1.CreateRoomRequest{
				Name:        "Test Room",
				Description: "Test Description",
				IsPrivate:   false,
				Members: []*commonv1.ContactLink{
					{ProfileId: util.IDString()},
					{ProfileId: util.IDString()},
				},
			}

			room, err := roomBusiness.CreateRoom(ctx, req, creator)
			require.NoError(t, err)
			s.NotNil(room)
			s.Equal("Test Room", room.GetName())
			s.Equal("Test Description", room.GetDescription())
			s.False(room.GetIsPrivate())
		})

		t.Run("DuplicateMembers", func(t *testing.T) {
			memberID := util.IDString()
			memberContactID := util.IDString()
			member := &commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID}

			room, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{
				Name:      "Dedup Test Room",
				IsPrivate: false,
				Members:   []*commonv1.ContactLink{member, member},
			}, creator)
			require.NoError(t, err)
			s.NotNil(room)
			s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
			s.WaitForMemberSubscription(ctx, svc, room.GetId(), memberID, t)
			s.WaitForAuthzAccess(ctx, svc, creatorID, room.GetId(), t)

			subs, err := roomBusiness.SearchRoomSubscriptions(ctx,
				&chatv1.SearchRoomSubscriptionsRequest{RoomId: room.GetId()}, creator)
			require.NoError(t, err)
			s.Len(subs, 2, "duplicate members should be deduplicated")
		})

		t.Run("IdempotentWithID", func(t *testing.T) {
			roomID := util.IDString()

			room1, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{
				Id:        roomID,
				Name:      "Idempotent Room",
				IsPrivate: false,
			}, creator)
			require.NoError(t, err)
			s.Equal(roomID, room1.GetId())
			s.WaitForMemberSubscription(ctx, svc, roomID, creatorID, t)

			room2, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{
				Id:        roomID,
				Name:      "Different Name",
				IsPrivate: false,
			}, creator)
			require.NoError(t, err)
			s.Equal(roomID, room2.GetId())
		})
	})
}

// TestGetAndUpdateRoom tests GetRoom and UpdateRoom operations including access control.
func (s *RoomBusinessTestSuite) TestGetAndUpdateRoom() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()
		creator := &commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID}

		created, err := roomBusiness.CreateRoom(ctx,
			&chatv1.CreateRoomRequest{
				Name:      "Original Name",
				IsPrivate: false,
				Members:   []*commonv1.ContactLink{{ProfileId: memberID, ContactId: memberContactID}},
			}, creator)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), creatorID, t)
		s.WaitForRoomSubscription(ctx, svc, created.GetId(), t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, created.GetId(), t)

		t.Run("GetRoom", func(t *testing.T) {
			retrieved, err := roomBusiness.GetRoom(ctx, created.GetId(), creator)
			require.NoError(t, err)
			s.Equal(created.GetId(), retrieved.GetId())
			s.Equal(created.GetName(), retrieved.GetName())
		})

		t.Run("GetRoom_AccessDenied", func(t *testing.T) {
			nonMember := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
			_, err := roomBusiness.GetRoom(ctx, created.GetId(), nonMember)
			require.Error(t, err)
		})

		t.Run("UpdateRoom", func(t *testing.T) {
			updated, err := roomBusiness.UpdateRoom(ctx,
				&chatv1.UpdateRoomRequest{
					RoomId:      created.GetId(),
					Name:        "Updated Name",
					Description: "Updated Description",
				}, creator)
			require.NoError(t, err)
			s.Equal("Updated Name", updated.GetName())
			s.Equal("Updated Description", updated.GetDescription())
		})

		t.Run("UpdateRoom_Unauthorized", func(t *testing.T) {
			_, err := roomBusiness.UpdateRoom(ctx,
				&chatv1.UpdateRoomRequest{
					RoomId: created.GetId(),
					Name:   "Hacked Name",
				},
				&commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID})
			require.Error(t, err)
		})
	})
}

func (s *RoomBusinessTestSuite) TestDeleteRoom() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		req := &chatv1.CreateRoomRequest{
			Name:      "Room to Delete",
			IsPrivate: false,
		}

		created, err := roomBusiness.CreateRoom(
			ctx,
			req,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), creatorID, t)

		// Delete room
		deleteReq := &chatv1.DeleteRoomRequest{
			RoomId: created.GetId(),
		}

		err = roomBusiness.DeleteRoom(
			ctx,
			deleteReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)

		// Verify deletion
		_, err = roomBusiness.GetRoom(
			ctx,
			created.GetId(),
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.Error(t, err)
	})
}

func (s *RoomBusinessTestSuite) TestUpdateSubscriptionRole_NonExistentSubscription() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		creator := &commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID}

		room, err := roomBusiness.CreateRoom(ctx,
			&chatv1.CreateRoomRequest{Name: "Role Test Room", IsPrivate: false}, creator)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, room.GetId(), t)

		// Try to update a non-existent subscription
		err = roomBusiness.UpdateSubscriptionRole(ctx,
			&chatv1.UpdateSubscriptionRoleRequest{
				RoomId:         room.GetId(),
				SubscriptionId: util.IDString(),
				Roles:          []string{"admin"},
			}, creator)
		require.Error(t, err)
		require.ErrorIs(t, err, service.ErrRoomMemberNotFound)
	})
}

func (s *RoomBusinessTestSuite) TestAddRoomSubscriptions() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		newMemberID := util.IDString()
		newMemberContactID := util.IDString()

		// Create room
		req := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
		}

		created, err := roomBusiness.CreateRoom(
			ctx,
			req,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), creatorID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, created.GetId(), t)

		creator := &commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID}

		// Add new member with explicit role
		addReq := &chatv1.AddRoomSubscriptionsRequest{
			RoomId: created.GetId(),
			Members: []*chatv1.RoomSubscription{
				{
					Member: &commonv1.ContactLink{ProfileId: newMemberID, ContactId: newMemberContactID},
					Roles:  []string{"member"},
				},
			},
		}

		err = roomBusiness.AddRoomSubscriptions(ctx, addReq, creator)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), newMemberID, t)

		// Add another member WITHOUT explicit roles (should default to "member")
		defaultRoleMemberID := util.IDString()
		defaultRoleMemberContactID := util.IDString()
		addReqNoRoles := &chatv1.AddRoomSubscriptionsRequest{
			RoomId: created.GetId(),
			Members: []*chatv1.RoomSubscription{
				{
					Member: &commonv1.ContactLink{
						ProfileId: defaultRoleMemberID,
						ContactId: defaultRoleMemberContactID,
					},
					// Roles intentionally omitted to test default
				},
			},
		}

		err = roomBusiness.AddRoomSubscriptions(ctx, addReqNoRoles, creator)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), defaultRoleMemberID, t)

		// Verify members added
		searchReq := &chatv1.SearchRoomSubscriptionsRequest{
			RoomId: created.GetId(),
		}
		subs, err := roomBusiness.SearchRoomSubscriptions(ctx, searchReq, creator)
		require.NoError(t, err)
		s.GreaterOrEqual(len(subs), 3) // Creator + 2 new members
	})
}

func (s *RoomBusinessTestSuite) TestRemoveRoomSubscriptions() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()

		// Create room with member
		req := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
			Members:   []*commonv1.ContactLink{{ProfileId: memberID, ContactId: memberContactID}},
		}

		created, err := roomBusiness.CreateRoom(
			ctx,
			req,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), memberID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, created.GetId(), t)

		// Get subscription ID
		searchReq := &chatv1.SearchRoomSubscriptionsRequest{
			RoomId: created.GetId(),
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
			RoomId:         created.GetId(),
			SubscriptionId: []string{subscriptionID},
		}

		err = roomBusiness.RemoveRoomSubscriptions(
			ctx,
			removeReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)

		// Verify member removed (should not have access)
		_, err = roomBusiness.GetRoom(
			ctx,
			created.GetId(),
			&commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
		)
		require.Error(t, err)
	})
}

func (s *RoomBusinessTestSuite) TestUpdateSubscriptionRole() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()

		// Create room with member
		req := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
			Members:   []*commonv1.ContactLink{{ProfileId: memberID, ContactId: memberContactID}},
		}

		created, err := roomBusiness.CreateRoom(
			ctx,
			req,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), memberID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, created.GetId(), t)

		// Get subscription ID
		searchReq := &chatv1.SearchRoomSubscriptionsRequest{
			RoomId: created.GetId(),
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

		// Promote member to admin
		updateReq := &chatv1.UpdateSubscriptionRoleRequest{
			RoomId:         created.GetId(),
			SubscriptionId: subscriptionID,
			Roles:          []string{"admin"},
		}

		err = roomBusiness.UpdateSubscriptionRole(
			ctx,
			updateReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)

		// Verify role updated - member should now be able to update room
		roomUpdateReq := &chatv1.UpdateRoomRequest{
			RoomId: created.GetId(),
			Name:   "Updated by Admin",
		}

		_, err = roomBusiness.UpdateRoom(
			ctx,
			roomUpdateReq,
			&commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
		)
		require.NoError(t, err)
	})
}

func (s *RoomBusinessTestSuite) TestDeleteRoomDeniedForNonOwner() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()

		req := &chatv1.CreateRoomRequest{
			Name:      "Room to Delete",
			IsPrivate: false,
			Members:   []*commonv1.ContactLink{{ProfileId: memberID, ContactId: memberContactID}},
		}

		created, err := roomBusiness.CreateRoom(
			ctx,
			req,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), memberID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, created.GetId(), t)

		// Promote member to admin first
		searchReq := &chatv1.SearchRoomSubscriptionsRequest{
			RoomId: created.GetId(),
		}
		subs, err := roomBusiness.SearchRoomSubscriptions(
			ctx,
			searchReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)

		var memberSubID string
		for _, sub := range subs {
			if sub.GetMember().GetProfileId() == memberID {
				memberSubID = sub.GetId()
				break
			}
		}
		require.NotEmpty(t, memberSubID)

		err = roomBusiness.UpdateSubscriptionRole(
			ctx,
			&chatv1.UpdateSubscriptionRoleRequest{
				RoomId:         created.GetId(),
				SubscriptionId: memberSubID,
				Roles:          []string{"admin"},
			},
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)

		// Admin should NOT be able to delete room (only owner can)
		deleteReq := &chatv1.DeleteRoomRequest{
			RoomId: created.GetId(),
		}
		err = roomBusiness.DeleteRoom(
			ctx,
			deleteReq,
			&commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
		)
		require.Error(t, err)
		s.Contains(err.Error(), "only room owners")

		// Regular member should also NOT be able to delete
		newMemberID := util.IDString()
		newMemberContactID := util.IDString()
		err = roomBusiness.AddRoomSubscriptions(
			ctx,
			&chatv1.AddRoomSubscriptionsRequest{
				RoomId: created.GetId(),
				Members: []*chatv1.RoomSubscription{
					{
						Member: &commonv1.ContactLink{ProfileId: newMemberID, ContactId: newMemberContactID},
						Roles:  []string{"member"},
					},
				},
			},
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)

		err = roomBusiness.DeleteRoom(
			ctx,
			deleteReq,
			&commonv1.ContactLink{ProfileId: newMemberID, ContactId: newMemberContactID},
		)
		require.Error(t, err)
	})
}

func (s *RoomBusinessTestSuite) TestAddRoomSubscriptionsDenied() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()

		req := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
			Members:   []*commonv1.ContactLink{{ProfileId: memberID, ContactId: memberContactID}},
		}

		created, err := roomBusiness.CreateRoom(
			ctx,
			req,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForRoomSubscription(ctx, svc, created.GetId(), t)

		// Regular member should NOT be able to add members
		addReq := &chatv1.AddRoomSubscriptionsRequest{
			RoomId: created.GetId(),
			Members: []*chatv1.RoomSubscription{
				{Member: &commonv1.ContactLink{ProfileId: util.IDString()}, Roles: []string{"member"}},
			},
		}

		err = roomBusiness.AddRoomSubscriptions(
			ctx,
			addReq,
			&commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
		)
		require.Error(t, err)
	})
}

func (s *RoomBusinessTestSuite) TestRemoveRoomSubscriptionsDenied() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()
		member2ID := util.IDString()
		member2ContactID := util.IDString()

		req := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
			Members: []*commonv1.ContactLink{
				{ProfileId: memberID, ContactId: memberContactID},
				{ProfileId: member2ID, ContactId: member2ContactID},
			},
		}

		created, err := roomBusiness.CreateRoom(
			ctx,
			req,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), memberID, t)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), member2ID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, created.GetId(), t)

		// Find member2's subscription ID
		searchReq := &chatv1.SearchRoomSubscriptionsRequest{RoomId: created.GetId()}
		subs, err := roomBusiness.SearchRoomSubscriptions(
			ctx,
			searchReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)

		var member2SubID string
		for _, sub := range subs {
			if sub.GetMember().GetProfileId() == member2ID {
				member2SubID = sub.GetId()
				break
			}
		}
		require.NotEmpty(t, member2SubID)

		// Regular member should NOT be able to remove other members
		removeReq := &chatv1.RemoveRoomSubscriptionsRequest{
			RoomId:         created.GetId(),
			SubscriptionId: []string{member2SubID},
		}

		err = roomBusiness.RemoveRoomSubscriptions(
			ctx,
			removeReq,
			&commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
		)
		require.Error(t, err)
	})
}

func (s *RoomBusinessTestSuite) TestUpdateSubscriptionRoleDenied() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()
		member2ID := util.IDString()
		member2ContactID := util.IDString()

		req := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
			Members: []*commonv1.ContactLink{
				{ProfileId: memberID, ContactId: memberContactID},
				{ProfileId: member2ID, ContactId: member2ContactID},
			},
		}

		created, err := roomBusiness.CreateRoom(
			ctx,
			req,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), memberID, t)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), member2ID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, created.GetId(), t)

		// Find member2's subscription ID
		searchReq := &chatv1.SearchRoomSubscriptionsRequest{RoomId: created.GetId()}
		subs, err := roomBusiness.SearchRoomSubscriptions(
			ctx,
			searchReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)

		var member2SubID string
		for _, sub := range subs {
			if sub.GetMember().GetProfileId() == member2ID {
				member2SubID = sub.GetId()
				break
			}
		}
		require.NotEmpty(t, member2SubID)

		// Promote memberID to admin
		var memberSubID string
		for _, sub := range subs {
			if sub.GetMember().GetProfileId() == memberID {
				memberSubID = sub.GetId()
				break
			}
		}
		require.NotEmpty(t, memberSubID)

		err = roomBusiness.UpdateSubscriptionRole(
			ctx,
			&chatv1.UpdateSubscriptionRoleRequest{
				RoomId:         created.GetId(),
				SubscriptionId: memberSubID,
				Roles:          []string{"admin"},
			},
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)

		// Admin should NOT be able to change roles (only owner can)
		err = roomBusiness.UpdateSubscriptionRole(
			ctx,
			&chatv1.UpdateSubscriptionRoleRequest{
				RoomId:         created.GetId(),
				SubscriptionId: member2SubID,
				Roles:          []string{"admin"},
			},
			&commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
		)
		require.Error(t, err)
	})
}

func (s *RoomBusinessTestSuite) TestSubscriptionContactIDStored() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()

		req := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
			Members:   []*commonv1.ContactLink{{ProfileId: memberID, ContactId: memberContactID}},
		}

		created, err := roomBusiness.CreateRoom(
			ctx,
			req,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), memberID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, created.GetId(), t)

		// Get subscriptions and verify ContactID is populated
		searchReq := &chatv1.SearchRoomSubscriptionsRequest{RoomId: created.GetId()}
		subs, err := roomBusiness.SearchRoomSubscriptions(
			ctx,
			searchReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		require.GreaterOrEqual(t, len(subs), 2)

		for _, sub := range subs {
			// Each member's subscription should have both ProfileID and ContactID
			s.NotEmpty(sub.GetMember().GetProfileId(), "subscription should have profile ID")
			s.NotEmpty(sub.GetMember().GetContactId(), "subscription should have contact ID")
		}
	})
}

func (s *RoomBusinessTestSuite) TestGetSubscriptionForContact() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()

		req := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
		}

		created, err := roomBusiness.CreateRoom(
			ctx,
			req,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), creatorID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, created.GetId(), t)

		// Get subscription for creator
		sub, err := roomBusiness.GetSubscriptionForContact(
			ctx,
			created.GetId(),
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.NotNil(sub)
		s.Equal(created.GetId(), sub.RoomID)
		s.Equal(creatorID, sub.ProfileID)
	})
}

func (s *RoomBusinessTestSuite) TestUpdateSubscriptionSettings() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		creator := &commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID}

		created, err := roomBusiness.CreateRoom(ctx,
			&chatv1.CreateRoomRequest{Name: "Settings Room", IsPrivate: false}, creator)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), creatorID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, created.GetId(), t)

		t.Run("ApplyAllFields", func(t *testing.T) {
			nl := chatv1.NotificationLevel_NOTIFICATION_LEVEL_MENTIONS
			settings, err := roomBusiness.UpdateSubscriptionSettings(ctx,
				&chatv1.UpdateSubscriptionSettingsRequest{
					RoomId:            created.GetId(),
					NotificationLevel: &nl,
					Muted:             proto.Bool(true),
					Pinned:            proto.Bool(true),
					Archived:          proto.Bool(false),
				}, creator)
			require.NoError(t, err)
			s.NotNil(settings)
			s.Equal(created.GetId(), settings.GetRoomId())
			s.True(settings.GetMuted())
			s.True(settings.GetPinned())
			s.False(settings.GetArchived())
			s.Equal(chatv1.NotificationLevel_NOTIFICATION_LEVEL_MENTIONS, settings.GetNotificationLevel())
		})

		t.Run("NoChanges", func(t *testing.T) {
			settings, err := roomBusiness.UpdateSubscriptionSettings(ctx,
				&chatv1.UpdateSubscriptionSettingsRequest{RoomId: created.GetId()}, creator)
			require.NoError(t, err)
			s.NotNil(settings)
			s.Equal(created.GetId(), settings.GetRoomId())
		})

		t.Run("AccessDenied", func(t *testing.T) {
			nonMember := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
			_, err := roomBusiness.UpdateSubscriptionSettings(ctx,
				&chatv1.UpdateSubscriptionSettingsRequest{RoomId: created.GetId(), Muted: proto.Bool(true)},
				nonMember)
			require.Error(t, err)
		})

		t.Run("NonMemberGetSubscription", func(t *testing.T) {
			nonMember := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
			_, err := roomBusiness.GetSubscriptionForContact(ctx, created.GetId(), nonMember)
			require.Error(t, err)
		})
	})
}

// setupBusinessLayerWithProposals creates the full business layer including proposal
// support. Returns the room business, message business, proposal management, and
// room repository (needed to set RequiresApproval on rooms).
func (s *RoomBusinessTestSuite) setupBusinessLayerWithProposals(
	ctx context.Context, svc *frame.Service,
) (business.RoomBusiness, business.ProposalManagement, repository.RoomRepository) {
	workMan := svc.WorkManager()
	evtsMan := svc.EventsManager()
	dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)

	roomRepo := repository.NewRoomRepository(ctx, dbPool, workMan)
	eventRepo := repository.NewRoomEventRepository(ctx, dbPool, workMan)
	subRepo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)
	proposalRepo := repository.NewProposalRepository(ctx, dbPool, workMan)

	subscriptionSvc := business.NewSubscriptionService(svc, subRepo)
	messageBusiness := business.NewMessageBusiness(evtsMan, eventRepo, subRepo, subscriptionSvc, s.AuthzMiddleware)
	roomBusiness := business.NewRoomBusiness(
		svc,
		roomRepo,
		eventRepo,
		subRepo,
		proposalRepo,
		subscriptionSvc,
		evtsMan,
		messageBusiness,
		nil,
		s.AuthzMiddleware,
	)

	proposalManagement := business.NewRoomProposalManagement(
		proposalRepo, roomBusiness, subscriptionSvc, s.AuthzMiddleware,
	)

	return roomBusiness, proposalManagement, roomRepo
}

func (s *RoomBusinessTestSuite) TestSearchRooms() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		userID := util.IDString()
		userContactID := util.IDString()

		// Create multiple rooms
		rooms := []string{"Alpha Room", "Beta Room", "Gamma Room"}
		for _, name := range rooms {
			req := &chatv1.CreateRoomRequest{
				Name:      name,
				IsPrivate: false,
			}
			created, crErr := roomBusiness.CreateRoom(
				ctx,
				req,
				&commonv1.ContactLink{ProfileId: userID, ContactId: userContactID},
			)
			require.NoError(t, crErr)
			s.WaitForRoomSubscription(ctx, svc, created.GetId(), t)
		}

		user := &commonv1.ContactLink{ProfileId: userID, ContactId: userContactID}

		// Search for rooms by query
		results, err := roomBusiness.SearchRooms(ctx,
			&chatv1.SearchRoomsRequest{Query: "Alpha"}, user)
		require.NoError(t, err)
		require.GreaterOrEqual(t, len(results), 1)

		found := false
		for _, room := range results {
			if room.GetName() == "Alpha Room" {
				found = true
				break
			}
		}
		require.True(t, found)

		// Search with cursor containing invalid page (exercises strconv.Atoi fallback)
		results2, err := roomBusiness.SearchRooms(ctx,
			&chatv1.SearchRoomsRequest{
				Query: "",
				Cursor: &commonv1.PageCursor{
					Page:  "not-a-number",
					Limit: 10,
				},
			}, user)
		require.NoError(t, err)
		require.GreaterOrEqual(t, len(results2), 3) // all 3 rooms

		// Search with no query (returns all user's rooms)
		results3, err := roomBusiness.SearchRooms(ctx,
			&chatv1.SearchRoomsRequest{Query: ""}, user)
		require.NoError(t, err)
		require.GreaterOrEqual(t, len(results3), 3)
	})
}

// --- Proposal Management Tests ---

// createApprovalRoom is a helper that creates a room, waits for the owner
// subscription and authz, then sets RequiresApproval=true on the room model.
func (s *RoomBusinessTestSuite) createApprovalRoom(
	ctx context.Context,
	svc *frame.Service,
	rb business.RoomBusiness,
	roomRepo repository.RoomRepository,
	creator *commonv1.ContactLink,
	name string,
	t *testing.T,
) *chatv1.Room {
	t.Helper()

	created, err := rb.CreateRoom(ctx, &chatv1.CreateRoomRequest{
		Name:      name,
		IsPrivate: false,
	}, creator)
	require.NoError(t, err)
	s.WaitForMemberSubscription(ctx, svc, created.GetId(), creator.GetProfileId(), t)
	s.WaitForAuthzAccess(ctx, svc, creator.GetProfileId(), created.GetId(), t)

	// Set RequiresApproval directly on the DB model since CreateRoom
	// does not expose this field via the proto request.
	room, err := roomRepo.GetByID(ctx, created.GetId())
	require.NoError(t, err)
	room.RequiresApproval = true
	_, err = roomRepo.Update(ctx, room)
	require.NoError(t, err)

	return created
}

func (s *RoomBusinessTestSuite) TestRequiresApprovalCreateProposal() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		rb, pm, roomRepo := s.setupBusinessLayerWithProposals(ctx, svc)

		creator := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		room := s.createApprovalRoom(ctx, svc, rb, roomRepo, creator, "Approval Room", t)

		// Try to update the room - should create a proposal instead
		_, err := rb.UpdateRoom(ctx, &chatv1.UpdateRoomRequest{
			RoomId: room.GetId(),
			Name:   "New Name",
		}, creator)
		require.Error(t, err)
		require.ErrorIs(t, err, service.ErrProposalRequired,
			"expected ErrProposalRequired, got: %v", err)

		// Verify the room was NOT actually updated
		retrieved, err := rb.GetRoom(ctx, room.GetId(), creator)
		require.NoError(t, err)
		s.Equal("Approval Room", retrieved.GetName(), "room name should not have changed")

		// Verify proposal was created via ListPending
		proposals, err := pm.ListPending(ctx, room.GetId(), creator)
		require.NoError(t, err)
		require.Len(t, proposals, 1, "should have exactly one pending proposal")
		s.Equal(room.GetId(), proposals[0].ScopeID)
	})
}

func (s *RoomBusinessTestSuite) TestApproveProposal() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		rb, pm, roomRepo := s.setupBusinessLayerWithProposals(ctx, svc)

		creator := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		room := s.createApprovalRoom(ctx, svc, rb, roomRepo, creator, "Before Update", t)

		// UpdateRoom creates a proposal
		_, err := rb.UpdateRoom(ctx, &chatv1.UpdateRoomRequest{
			RoomId:      room.GetId(),
			Name:        "After Update",
			Description: "Updated Description",
		}, creator)
		require.Error(t, err)
		require.ErrorIs(t, err, service.ErrProposalRequired)

		// Get the pending proposal
		proposals, err := pm.ListPending(ctx, room.GetId(), creator)
		require.NoError(t, err)
		require.Len(t, proposals, 1)

		// Approve the proposal (creator is owner)
		err = pm.Approve(ctx, room.GetId(), proposals[0].GetID(), creator)
		require.NoError(t, err)

		// Verify the room is now updated
		retrieved, err := rb.GetRoom(ctx, room.GetId(), creator)
		require.NoError(t, err)
		s.Equal("After Update", retrieved.GetName())
		s.Equal("Updated Description", retrieved.GetDescription())

		// Verify no pending proposals remain
		proposals, err = pm.ListPending(ctx, room.GetId(), creator)
		require.NoError(t, err)
		s.Empty(proposals, "should have no pending proposals after approval")
	})
}

func (s *RoomBusinessTestSuite) TestRejectProposal() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		rb, pm, roomRepo := s.setupBusinessLayerWithProposals(ctx, svc)

		creator := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		room := s.createApprovalRoom(ctx, svc, rb, roomRepo, creator, "Reject Test Room", t)

		// UpdateRoom creates a proposal
		_, err := rb.UpdateRoom(ctx, &chatv1.UpdateRoomRequest{
			RoomId: room.GetId(),
			Name:   "Should Not Apply",
		}, creator)
		require.Error(t, err)
		require.ErrorIs(t, err, service.ErrProposalRequired)

		// Get and reject the proposal
		proposals, err := pm.ListPending(ctx, room.GetId(), creator)
		require.NoError(t, err)
		require.Len(t, proposals, 1)

		err = pm.Reject(ctx, room.GetId(), proposals[0].GetID(), "not appropriate", creator)
		require.NoError(t, err)

		// Verify the room was NOT updated
		retrieved, err := rb.GetRoom(ctx, room.GetId(), creator)
		require.NoError(t, err)
		s.Equal("Reject Test Room", retrieved.GetName(), "room name should remain unchanged after rejection")

		// Verify no pending proposals remain
		proposals, err = pm.ListPending(ctx, room.GetId(), creator)
		require.NoError(t, err)
		s.Empty(proposals, "should have no pending proposals after rejection")
	})
}

func (s *RoomBusinessTestSuite) TestListPendingProposals() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		rb, pm, roomRepo := s.setupBusinessLayerWithProposals(ctx, svc)

		creator := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		room := s.createApprovalRoom(ctx, svc, rb, roomRepo, creator, "Multi Proposal Room", t)

		// Create first proposal via UpdateRoom
		_, err := rb.UpdateRoom(ctx, &chatv1.UpdateRoomRequest{
			RoomId: room.GetId(),
			Name:   "Update 1",
		}, creator)
		require.Error(t, err)
		require.ErrorIs(t, err, service.ErrProposalRequired)

		// Create second proposal via AddRoomSubscriptions
		err = rb.AddRoomSubscriptions(ctx, &chatv1.AddRoomSubscriptionsRequest{
			RoomId: room.GetId(),
			Members: []*chatv1.RoomSubscription{
				{
					Member: &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()},
					Roles:  []string{"member"},
				},
			},
		}, creator)
		require.Error(t, err)
		require.ErrorIs(t, err, service.ErrProposalRequired)

		// List pending proposals - should have both
		proposals, err := pm.ListPending(ctx, room.GetId(), creator)
		require.NoError(t, err)
		require.Len(t, proposals, 2, "should have 2 pending proposals")

		// Verify both proposals belong to the same room
		for _, p := range proposals {
			s.Equal(room.GetId(), p.ScopeID)
		}
	})
}

func (s *RoomBusinessTestSuite) TestApproveProposal_NotPending() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		rb, pm, roomRepo := s.setupBusinessLayerWithProposals(ctx, svc)

		creator := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		room := s.createApprovalRoom(ctx, svc, rb, roomRepo, creator, "Double Approve Room", t)

		// Create a proposal
		_, err := rb.UpdateRoom(ctx, &chatv1.UpdateRoomRequest{
			RoomId: room.GetId(),
			Name:   "Approved Once",
		}, creator)
		require.Error(t, err)
		require.ErrorIs(t, err, service.ErrProposalRequired)

		proposals, err := pm.ListPending(ctx, room.GetId(), creator)
		require.NoError(t, err)
		require.Len(t, proposals, 1)
		proposalID := proposals[0].GetID()

		// Approve it
		err = pm.Approve(ctx, room.GetId(), proposalID, creator)
		require.NoError(t, err)

		// Try to approve again - should fail with ErrProposalNotPending
		err = pm.Approve(ctx, room.GetId(), proposalID, creator)
		require.Error(t, err)
		require.ErrorIs(t, err, service.ErrProposalNotPending,
			"expected ErrProposalNotPending, got: %v", err)
	})
}

func (s *RoomBusinessTestSuite) TestDeleteRoomRequiresApproval() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		rb, pm, roomRepo := s.setupBusinessLayerWithProposals(ctx, svc)

		creator := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		room := s.createApprovalRoom(ctx, svc, rb, roomRepo, creator, "Delete Proposal Room", t)

		// Try to delete the room - should create a proposal
		err := rb.DeleteRoom(ctx, &chatv1.DeleteRoomRequest{
			RoomId: room.GetId(),
		}, creator)
		require.Error(t, err)
		require.ErrorIs(t, err, service.ErrProposalRequired,
			"expected ErrProposalRequired, got: %v", err)

		// Verify the room still exists
		retrieved, err := rb.GetRoom(ctx, room.GetId(), creator)
		require.NoError(t, err)
		s.Equal("Delete Proposal Room", retrieved.GetName(), "room should still exist")

		// Verify proposal was created
		proposals, err := pm.ListPending(ctx, room.GetId(), creator)
		require.NoError(t, err)
		require.Len(t, proposals, 1, "should have one pending delete proposal")
	})
}

// TestSearchRoomsExtended tests search rooms with rooms created (empty query, pagination).
func (s *RoomBusinessTestSuite) TestSearchRoomsExtended() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		userID := util.IDString()
		userContactID := util.IDString()
		user := &commonv1.ContactLink{ProfileId: userID, ContactId: userContactID}

		// Create multiple rooms for pagination and empty-query testing
		for i := range 5 {
			name := "Paginated Room " + util.IDString()[:4]
			_ = i
			created, crErr := roomBusiness.CreateRoom(ctx,
				&chatv1.CreateRoomRequest{Name: name, IsPrivate: false}, user)
			require.NoError(t, crErr)
			s.WaitForRoomSubscription(ctx, svc, created.GetId(), t)
		}

		t.Run("EmptyQuery", func(t *testing.T) {
			results, err := roomBusiness.SearchRooms(ctx,
				&chatv1.SearchRoomsRequest{Query: ""}, user)
			require.NoError(t, err)
			s.GreaterOrEqual(len(results), 1)
		})

		t.Run("WithPagination", func(t *testing.T) {
			results, err := roomBusiness.SearchRooms(ctx,
				&chatv1.SearchRoomsRequest{
					Query:  "",
					Cursor: &commonv1.PageCursor{Limit: 2, Page: "0"},
				}, user)
			require.NoError(t, err)
			s.LessOrEqual(len(results), 2)
		})
	})
}

// TestSubscriptionNotInRoom tests updating a subscription role with a subscription from a different room.
func (s *RoomBusinessTestSuite) TestSubscriptionNotInRoom() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()

		// Create two rooms
		room1, err := roomBusiness.CreateRoom(ctx,
			&chatv1.CreateRoomRequest{
				Name:      "Room 1",
				IsPrivate: false,
				Members:   []*commonv1.ContactLink{{ProfileId: memberID, ContactId: memberContactID}},
			},
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room1.GetId(), creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, room1.GetId(), memberID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, room1.GetId(), t)

		room2, err := roomBusiness.CreateRoom(ctx,
			&chatv1.CreateRoomRequest{Name: "Room 2", IsPrivate: false},
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room2.GetId(), creatorID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, room2.GetId(), t)

		// Get member's subscription ID from room1
		subs, err := roomBusiness.SearchRoomSubscriptions(ctx,
			&chatv1.SearchRoomSubscriptionsRequest{RoomId: room1.GetId()},
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID})
		require.NoError(t, err)

		var memberSubID string
		for _, sub := range subs {
			if sub.GetMember().GetProfileId() == memberID {
				memberSubID = sub.GetId()
				break
			}
		}
		require.NotEmpty(t, memberSubID)

		// Try to update role using room1's subscription ID in room2
		err = roomBusiness.UpdateSubscriptionRole(ctx,
			&chatv1.UpdateSubscriptionRoleRequest{
				RoomId:         room2.GetId(),
				SubscriptionId: memberSubID,
				Roles:          []string{"admin"},
			},
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.Error(t, err)
		require.ErrorIs(t, err, service.ErrRoomMemberNotFound)
	})
}

// TestSearchRoomSubscriptions_NonMember tests non-member access denial.
func (s *RoomBusinessTestSuite) TestSearchRoomSubscriptions_NonMember() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()

		created, err := roomBusiness.CreateRoom(ctx,
			&chatv1.CreateRoomRequest{Name: "Private Room", IsPrivate: true},
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForRoomSubscription(ctx, svc, created.GetId(), t)

		// Non-member tries to search subscriptions
		nonMemberID := util.IDString()
		nonMemberContactID := util.IDString()
		_, err = roomBusiness.SearchRoomSubscriptions(ctx,
			&chatv1.SearchRoomSubscriptionsRequest{RoomId: created.GetId()},
			&commonv1.ContactLink{ProfileId: nonMemberID, ContactId: nonMemberContactID},
		)
		require.Error(t, err)
		require.ErrorIs(t, err, service.ErrRoomAccessDenied)
	})
}

// --- Proposal Validation Tests (consolidated) ---

// TestProposalValidationErrors tests validation error paths for proposal operations.
func (s *RoomBusinessTestSuite) TestProposalValidationErrors() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		_, pm, _ := s.setupBusinessLayerWithProposals(ctx, svc)

		t.Run("Approve_InvalidContact", func(t *testing.T) {
			err := pm.Approve(ctx, "some-scope", "some-proposal-id", nil)
			require.Error(t, err)
		})

		t.Run("Reject_InvalidContact", func(t *testing.T) {
			err := pm.Reject(ctx, "some-scope", "some-proposal-id", "reason", nil)
			require.Error(t, err)
		})

		t.Run("ListPending_InvalidContact", func(t *testing.T) {
			_, err := pm.ListPending(ctx, "some-scope", nil)
			require.Error(t, err)
		})

		t.Run("ListPending_EmptyScope", func(t *testing.T) {
			_, err := pm.ListPending(ctx, "",
				&commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()})
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrRoomIDRequired)
		})
	})
}

// TestProposalAuthorizationDenied tests that non-owners cannot approve/reject proposals
// and non-members cannot list pending proposals.
func (s *RoomBusinessTestSuite) TestProposalAuthorizationDenied() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		rb, pm, roomRepo := s.setupBusinessLayerWithProposals(ctx, svc)

		creator := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		nonOwner := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}

		room := s.createApprovalRoom(ctx, svc, rb, roomRepo, creator, "Auth Denied Room", t)

		// Create a proposal
		_, err := rb.UpdateRoom(ctx, &chatv1.UpdateRoomRequest{
			RoomId: room.GetId(),
			Name:   "New Name",
		}, creator)
		require.Error(t, err)
		require.ErrorIs(t, err, service.ErrProposalRequired)

		proposals, err := pm.ListPending(ctx, room.GetId(), creator)
		require.NoError(t, err)
		require.Len(t, proposals, 1)

		t.Run("Approve_NonOwnerDenied", func(t *testing.T) {
			err := pm.Approve(ctx, room.GetId(), proposals[0].GetID(), nonOwner)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrProposalApprovalDenied)
		})

		t.Run("Reject_NonOwnerDenied", func(t *testing.T) {
			err := pm.Reject(ctx, room.GetId(), proposals[0].GetID(), "no", nonOwner)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrProposalApprovalDenied)
		})

		t.Run("Approve_WrongScope", func(t *testing.T) {
			err := pm.Approve(ctx, "wrong-scope-id", proposals[0].GetID(), creator)
			require.Error(t, err)
		})

		t.Run("Reject_WrongScope", func(t *testing.T) {
			err := pm.Reject(ctx, "wrong-scope-id", proposals[0].GetID(), "no", creator)
			require.Error(t, err)
		})

		t.Run("Approve_NotFoundID", func(t *testing.T) {
			err := pm.Approve(ctx, room.GetId(), util.IDString(), creator)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrProposalNotFound)
		})

		t.Run("ListPending_NonMemberDenied", func(t *testing.T) {
			nonMember := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
			_, err := pm.ListPending(ctx, room.GetId(), nonMember)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrRoomAccessDenied)
		})
	})
}

// TestRejectProposal_AlreadyRejected tests double-reject behavior.
func (s *RoomBusinessTestSuite) TestRejectProposal_AlreadyRejected() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		rb, pm, roomRepo := s.setupBusinessLayerWithProposals(ctx, svc)

		creator := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		room := s.createApprovalRoom(ctx, svc, rb, roomRepo, creator, "Double Reject Room", t)

		// Create proposal
		_, err := rb.UpdateRoom(ctx, &chatv1.UpdateRoomRequest{
			RoomId: room.GetId(),
			Name:   "Should Not Apply",
		}, creator)
		require.Error(t, err)
		require.ErrorIs(t, err, service.ErrProposalRequired)

		proposals, err := pm.ListPending(ctx, room.GetId(), creator)
		require.NoError(t, err)
		require.Len(t, proposals, 1)
		proposalID := proposals[0].GetID()

		// Reject it
		err = pm.Reject(ctx, room.GetId(), proposalID, "no", creator)
		require.NoError(t, err)

		// Try to reject again - should fail with ErrProposalNotPending
		err = pm.Reject(ctx, room.GetId(), proposalID, "no again", creator)
		require.Error(t, err)
		require.ErrorIs(t, err, service.ErrProposalNotPending)
	})
}

// --- Proposal Execute Tests (delete room, add/remove subscriptions, update role) ---

// TestApproveProposals_ExecuteAll tests all proposal execution paths in a single service setup.
func (s *RoomBusinessTestSuite) TestApproveProposals_ExecuteAll() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		rb, pm, roomRepo := s.setupBusinessLayerWithProposals(ctx, svc)

		t.Run("DeleteRoom", func(t *testing.T) {
			creator := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
			room := s.createApprovalRoom(ctx, svc, rb, roomRepo, creator, "Delete Via Proposal", t)

			err := rb.DeleteRoom(ctx, &chatv1.DeleteRoomRequest{RoomId: room.GetId()}, creator)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrProposalRequired)

			proposals, err := pm.ListPending(ctx, room.GetId(), creator)
			require.NoError(t, err)
			require.Len(t, proposals, 1)

			err = pm.Approve(ctx, room.GetId(), proposals[0].GetID(), creator)
			require.NoError(t, err)

			_, err = rb.GetRoom(ctx, room.GetId(), creator)
			require.Error(t, err)
		})

		t.Run("AddSubscriptions", func(t *testing.T) {
			creator := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
			newMember := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}

			room := s.createApprovalRoom(ctx, svc, rb, roomRepo, creator, "Add Sub Via Proposal", t)

			err := rb.AddRoomSubscriptions(ctx, &chatv1.AddRoomSubscriptionsRequest{
				RoomId: room.GetId(),
				Members: []*chatv1.RoomSubscription{
					{Member: newMember, Roles: []string{"member"}},
				},
			}, creator)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrProposalRequired)

			proposals, err := pm.ListPending(ctx, room.GetId(), creator)
			require.NoError(t, err)
			require.Len(t, proposals, 1)

			err = pm.Approve(ctx, room.GetId(), proposals[0].GetID(), creator)
			require.NoError(t, err)

			s.WaitForMemberSubscription(ctx, svc, room.GetId(), newMember.GetProfileId(), t)
		})

		t.Run("RemoveSubscriptions", func(t *testing.T) {
			creator := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
			memberID := util.IDString()
			memberContactID := util.IDString()

			created, err := rb.CreateRoom(ctx, &chatv1.CreateRoomRequest{
				Name:      "Remove Sub Via Proposal",
				IsPrivate: false,
				Members:   []*commonv1.ContactLink{{ProfileId: memberID, ContactId: memberContactID}},
			}, creator)
			require.NoError(t, err)
			s.WaitForMemberSubscription(ctx, svc, created.GetId(), creator.GetProfileId(), t)
			s.WaitForMemberSubscription(ctx, svc, created.GetId(), memberID, t)
			s.WaitForAuthzAccess(ctx, svc, creator.GetProfileId(), created.GetId(), t)

			room, err := roomRepo.GetByID(ctx, created.GetId())
			require.NoError(t, err)
			room.RequiresApproval = true
			_, err = roomRepo.Update(ctx, room)
			require.NoError(t, err)

			subs, err := rb.SearchRoomSubscriptions(ctx,
				&chatv1.SearchRoomSubscriptionsRequest{RoomId: created.GetId()}, creator)
			require.NoError(t, err)
			var memberSubID string
			for _, sub := range subs {
				if sub.GetMember().GetProfileId() == memberID {
					memberSubID = sub.GetId()
					break
				}
			}
			require.NotEmpty(t, memberSubID)

			err = rb.RemoveRoomSubscriptions(ctx, &chatv1.RemoveRoomSubscriptionsRequest{
				RoomId:         created.GetId(),
				SubscriptionId: []string{memberSubID},
			}, creator)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrProposalRequired)

			proposals, err := pm.ListPending(ctx, created.GetId(), creator)
			require.NoError(t, err)
			require.Len(t, proposals, 1)

			err = pm.Approve(ctx, created.GetId(), proposals[0].GetID(), creator)
			require.NoError(t, err)

			_, err = rb.GetRoom(ctx, created.GetId(),
				&commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID})
			require.Error(t, err)
		})

		t.Run("UpdateSubscriptionRole", func(t *testing.T) {
			creator := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
			memberID := util.IDString()
			memberContactID := util.IDString()

			created, err := rb.CreateRoom(ctx, &chatv1.CreateRoomRequest{
				Name:      "Role Update Via Proposal",
				IsPrivate: false,
				Members:   []*commonv1.ContactLink{{ProfileId: memberID, ContactId: memberContactID}},
			}, creator)
			require.NoError(t, err)
			s.WaitForMemberSubscription(ctx, svc, created.GetId(), creator.GetProfileId(), t)
			s.WaitForMemberSubscription(ctx, svc, created.GetId(), memberID, t)
			s.WaitForAuthzAccess(ctx, svc, creator.GetProfileId(), created.GetId(), t)

			room, err := roomRepo.GetByID(ctx, created.GetId())
			require.NoError(t, err)
			room.RequiresApproval = true
			_, err = roomRepo.Update(ctx, room)
			require.NoError(t, err)

			subs, err := rb.SearchRoomSubscriptions(ctx,
				&chatv1.SearchRoomSubscriptionsRequest{RoomId: created.GetId()}, creator)
			require.NoError(t, err)
			var memberSubID string
			for _, sub := range subs {
				if sub.GetMember().GetProfileId() == memberID {
					memberSubID = sub.GetId()
					break
				}
			}
			require.NotEmpty(t, memberSubID)

			err = rb.UpdateSubscriptionRole(ctx, &chatv1.UpdateSubscriptionRoleRequest{
				RoomId:         created.GetId(),
				SubscriptionId: memberSubID,
				Roles:          []string{"admin"},
			}, creator)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrProposalRequired)

			proposals, err := pm.ListPending(ctx, created.GetId(), creator)
			require.NoError(t, err)
			require.Len(t, proposals, 1)

			err = pm.Approve(ctx, created.GetId(), proposals[0].GetID(), creator)
			require.NoError(t, err)

			// Verify role was updated
			_, err = rb.UpdateRoom(ctx, &chatv1.UpdateRoomRequest{
				RoomId: created.GetId(),
				Name:   "Updated by new admin",
			}, &commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID})
			if err != nil {
				require.ErrorIs(t, err, service.ErrProposalRequired,
					"expected ErrProposalRequired (not denied), got: %v", err)
			}
		})

		t.Run("ExpiredProposal", func(t *testing.T) {
			creator := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
			room := s.createApprovalRoom(ctx, svc, rb, roomRepo, creator, "Expired Proposal Room", t)

			_, err := rb.UpdateRoom(ctx, &chatv1.UpdateRoomRequest{
				RoomId: room.GetId(),
				Name:   "Should Expire",
			}, creator)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrProposalRequired)

			proposals, err := pm.ListPending(ctx, room.GetId(), creator)
			require.NoError(t, err)
			require.Len(t, proposals, 1)

			// Manually expire the proposal
			workMan := svc.WorkManager()
			dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)
			proposalRepo := repository.NewProposalRepository(ctx, dbPool, workMan)

			proposal, err := proposalRepo.GetByID(ctx, proposals[0].GetID())
			require.NoError(t, err)
			proposal.ExpiresAt = time.Now().Add(-1 * time.Hour)
			_, err = proposalRepo.Update(ctx, proposal)
			require.NoError(t, err)

			err = pm.Approve(ctx, room.GetId(), proposals[0].GetID(), creator)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrProposalExpired,
				"expected ErrProposalExpired, got: %v", err)
		})
	})
}

// TestRequiresApprovalFlows tests that operations correctly create proposals
// when RequiresApproval is set.
func (s *RoomBusinessTestSuite) TestRequiresApprovalFlows() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		rb, pm, roomRepo := s.setupBusinessLayerWithProposals(ctx, svc)

		creator := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		memberID := util.IDString()
		memberContactID := util.IDString()

		// Create room with a member first
		created, err := rb.CreateRoom(ctx, &chatv1.CreateRoomRequest{
			Name:      "Approval Flows Room",
			IsPrivate: false,
			Members:   []*commonv1.ContactLink{{ProfileId: memberID, ContactId: memberContactID}},
		}, creator)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), creator.GetProfileId(), t)
		s.WaitForMemberSubscription(ctx, svc, created.GetId(), memberID, t)
		s.WaitForAuthzAccess(ctx, svc, creator.GetProfileId(), created.GetId(), t)

		// Set RequiresApproval
		room, err := roomRepo.GetByID(ctx, created.GetId())
		require.NoError(t, err)
		room.RequiresApproval = true
		_, err = roomRepo.Update(ctx, room)
		require.NoError(t, err)

		// Find member's subscription ID
		subs, err := rb.SearchRoomSubscriptions(ctx,
			&chatv1.SearchRoomSubscriptionsRequest{RoomId: created.GetId()}, creator)
		require.NoError(t, err)
		var memberSubID string
		for _, sub := range subs {
			if sub.GetMember().GetProfileId() == memberID {
				memberSubID = sub.GetId()
				break
			}
		}
		require.NotEmpty(t, memberSubID)

		t.Run("RemoveSubscriptions", func(t *testing.T) {
			err := rb.RemoveRoomSubscriptions(ctx, &chatv1.RemoveRoomSubscriptionsRequest{
				RoomId:         created.GetId(),
				SubscriptionId: []string{memberSubID},
			}, creator)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrProposalRequired)

			proposals, err := pm.ListPending(ctx, created.GetId(), creator)
			require.NoError(t, err)
			require.GreaterOrEqual(t, len(proposals), 1)
		})

		t.Run("UpdateSubscriptionRole", func(t *testing.T) {
			err := rb.UpdateSubscriptionRole(ctx, &chatv1.UpdateSubscriptionRoleRequest{
				RoomId:         created.GetId(),
				SubscriptionId: memberSubID,
				Roles:          []string{"admin"},
			}, creator)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrProposalRequired)

			proposals, err := pm.ListPending(ctx, created.GetId(), creator)
			require.NoError(t, err)
			require.GreaterOrEqual(t, len(proposals), 1)
		})
	})
}

// TestProposalRepository_Update tests the proposal repository update operations.
func (s *RoomBusinessTestSuite) TestProposalRepository_Update() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)

		workMan := svc.WorkManager()
		dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)
		proposalRepo := repository.NewProposalRepository(ctx, dbPool, workMan)

		// Create a proposal
		proposal := &models.Proposal{
			ScopeType:    models.ProposalScopeRoom,
			ScopeID:      util.IDString(),
			ProposalType: models.ProposalTypeUpdateRoom,
			RequestedBy:  util.IDString(),
			Payload:      data.JSONMap{"name": "test"},
			State:        models.ProposalStatePending,
			ExpiresAt:    time.Now().Add(72 * time.Hour),
		}
		proposal.GenID(ctx)

		err := proposalRepo.Create(ctx, proposal)
		require.NoError(t, err)

		// Retrieve it
		retrieved, err := proposalRepo.GetByID(ctx, proposal.GetID())
		require.NoError(t, err)
		s.True(retrieved.IsPending())
		s.False(retrieved.IsExpired())

		// Update state to expired
		err = proposalRepo.UpdateState(ctx, proposal.GetID(),
			models.ProposalStateExpired, util.IDString(), "expired manually")
		require.NoError(t, err)

		// Verify state change
		updated, err := proposalRepo.GetByID(ctx, proposal.GetID())
		require.NoError(t, err)
		s.False(updated.IsPending())
	})
}

// --- Validation Error Path Tests (consolidated to reduce DB connections) ---

// TestValidationErrors_RoomOperations tests all validation error paths for room
// CRUD operations in a single service setup to minimize DB connection usage.
func (s *RoomBusinessTestSuite) TestValidationErrors_RoomOperations() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)
		validContact := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}

		t.Run("CreateRoom_InvalidContact", func(t *testing.T) {
			_, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{Name: "Test Room"}, nil)
			require.Error(t, err)

			_, err = roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{Name: "Test Room"}, &commonv1.ContactLink{})
			require.Error(t, err)
		})

		t.Run("CreateRoom_NoName", func(t *testing.T) {
			_, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{Name: ""}, validContact)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrRoomNameRequired)
		})

		t.Run("GetRoom_InvalidContact", func(t *testing.T) {
			_, err := roomBusiness.GetRoom(ctx, "some-room-id", nil)
			require.Error(t, err)

			_, err = roomBusiness.GetRoom(ctx, "some-room-id", &commonv1.ContactLink{})
			require.Error(t, err)
		})

		t.Run("GetRoom_NonExistentRoom", func(t *testing.T) {
			_, err := roomBusiness.GetRoom(ctx, util.IDString(), validContact)
			require.Error(t, err)
		})

		t.Run("UpdateRoom_EmptyRoomID", func(t *testing.T) {
			_, err := roomBusiness.UpdateRoom(ctx,
				&chatv1.UpdateRoomRequest{RoomId: "", Name: "New Name"}, validContact)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrRoomIDRequired)
		})

		t.Run("UpdateRoom_InvalidContact", func(t *testing.T) {
			_, err := roomBusiness.UpdateRoom(ctx,
				&chatv1.UpdateRoomRequest{RoomId: "some-room-id", Name: "New Name"}, nil)
			require.Error(t, err)

			_, err = roomBusiness.UpdateRoom(ctx,
				&chatv1.UpdateRoomRequest{RoomId: "some-room-id", Name: "New Name"}, &commonv1.ContactLink{})
			require.Error(t, err)
		})

		t.Run("DeleteRoom_EmptyRoomID", func(t *testing.T) {
			err := roomBusiness.DeleteRoom(ctx, &chatv1.DeleteRoomRequest{RoomId: ""}, validContact)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrRoomIDRequired)
		})

		t.Run("DeleteRoom_InvalidContact", func(t *testing.T) {
			err := roomBusiness.DeleteRoom(ctx, &chatv1.DeleteRoomRequest{RoomId: "some-room-id"}, nil)
			require.Error(t, err)

			err = roomBusiness.DeleteRoom(
				ctx,
				&chatv1.DeleteRoomRequest{RoomId: "some-room-id"},
				&commonv1.ContactLink{},
			)
			require.Error(t, err)
		})

		t.Run("SearchRooms_InvalidContact", func(t *testing.T) {
			_, err := roomBusiness.SearchRooms(ctx, &chatv1.SearchRoomsRequest{Query: "test"}, nil)
			require.Error(t, err)

			_, err = roomBusiness.SearchRooms(ctx, &chatv1.SearchRoomsRequest{Query: "test"}, &commonv1.ContactLink{})
			require.Error(t, err)
		})

		t.Run("SearchRooms_NoSubscriptions", func(t *testing.T) {
			results, err := roomBusiness.SearchRooms(ctx,
				&chatv1.SearchRoomsRequest{Query: "anything"}, validContact)
			require.NoError(t, err)
			s.Empty(results)
		})

		t.Run("UpdateSubscriptionSettings_InvalidContact", func(t *testing.T) {
			_, err := roomBusiness.UpdateSubscriptionSettings(ctx,
				&chatv1.UpdateSubscriptionSettingsRequest{RoomId: "some-room-id"}, nil)
			require.Error(t, err)
		})

		t.Run("UpdateSubscriptionSettings_EmptyRoomID", func(t *testing.T) {
			_, err := roomBusiness.UpdateSubscriptionSettings(ctx,
				&chatv1.UpdateSubscriptionSettingsRequest{RoomId: ""}, validContact)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrRoomIDRequired)
		})

		t.Run("GetSubscriptionForContact_InvalidContact", func(t *testing.T) {
			_, err := roomBusiness.GetSubscriptionForContact(ctx, "some-room-id", nil)
			require.Error(t, err)
			_, err = roomBusiness.GetSubscriptionForContact(ctx, "some-room-id", &commonv1.ContactLink{})
			require.Error(t, err)
		})

		t.Run("GetSubscriptionForContact_EmptyRoomID", func(t *testing.T) {
			_, err := roomBusiness.GetSubscriptionForContact(ctx, "",
				&commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()})
			require.Error(t, err)
		})
	})
}

// TestValidationErrors_SubscriptionOperations tests all validation error paths for
// subscription operations in a single service setup.
func (s *RoomBusinessTestSuite) TestValidationErrors_SubscriptionOperations() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)
		validContact := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}

		t.Run("AddRoomSubscriptions_EmptyRoomID", func(t *testing.T) {
			err := roomBusiness.AddRoomSubscriptions(ctx,
				&chatv1.AddRoomSubscriptionsRequest{
					RoomId: "",
					Members: []*chatv1.RoomSubscription{
						{Member: &commonv1.ContactLink{ProfileId: util.IDString()}, Roles: []string{"member"}},
					},
				}, validContact)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrRoomIDRequired)
		})

		t.Run("AddRoomSubscriptions_EmptyMembers", func(t *testing.T) {
			err := roomBusiness.AddRoomSubscriptions(ctx,
				&chatv1.AddRoomSubscriptionsRequest{RoomId: "some-room-id", Members: nil}, validContact)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrProfileIDsRequired)
		})

		t.Run("AddRoomSubscriptions_InvalidContact", func(t *testing.T) {
			err := roomBusiness.AddRoomSubscriptions(ctx,
				&chatv1.AddRoomSubscriptionsRequest{
					RoomId: "some-room-id",
					Members: []*chatv1.RoomSubscription{
						{Member: &commonv1.ContactLink{ProfileId: util.IDString()}, Roles: []string{"member"}},
					},
				}, nil)
			require.Error(t, err)
		})

		t.Run("RemoveRoomSubscriptions_EmptyRoomID", func(t *testing.T) {
			err := roomBusiness.RemoveRoomSubscriptions(
				ctx,
				&chatv1.RemoveRoomSubscriptionsRequest{
					RoomId:         "",
					SubscriptionId: []string{"some-sub-id"},
				},
				validContact,
			)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrRoomIDRequired)
		})

		t.Run("RemoveRoomSubscriptions_EmptySubscriptionIDs", func(t *testing.T) {
			err := roomBusiness.RemoveRoomSubscriptions(ctx,
				&chatv1.RemoveRoomSubscriptionsRequest{RoomId: "some-room-id", SubscriptionId: nil}, validContact)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrProfileIDsRequired)
		})

		t.Run("RemoveRoomSubscriptions_InvalidContact", func(t *testing.T) {
			err := roomBusiness.RemoveRoomSubscriptions(ctx,
				&chatv1.RemoveRoomSubscriptionsRequest{RoomId: "some-room-id", SubscriptionId: []string{"sub-id"}}, nil)
			require.Error(t, err)
		})

		t.Run("UpdateSubscriptionRole_EmptyRoomID", func(t *testing.T) {
			err := roomBusiness.UpdateSubscriptionRole(
				ctx,
				&chatv1.UpdateSubscriptionRoleRequest{
					RoomId:         "",
					SubscriptionId: "some-sub-id",
					Roles:          []string{"admin"},
				},
				validContact,
			)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrRoomIDRequired)
		})

		t.Run("UpdateSubscriptionRole_EmptySubscriptionID", func(t *testing.T) {
			err := roomBusiness.UpdateSubscriptionRole(
				ctx,
				&chatv1.UpdateSubscriptionRoleRequest{
					RoomId:         "some-room-id",
					SubscriptionId: "",
					Roles:          []string{"admin"},
				},
				validContact,
			)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrUnspecifiedID)
		})

		t.Run("UpdateSubscriptionRole_InvalidContact", func(t *testing.T) {
			err := roomBusiness.UpdateSubscriptionRole(
				ctx,
				&chatv1.UpdateSubscriptionRoleRequest{
					RoomId:         "some-room-id",
					SubscriptionId: "some-sub-id",
					Roles:          []string{"admin"},
				},
				nil,
			)
			require.Error(t, err)
		})

		t.Run("SearchRoomSubscriptions_EmptyRoomID", func(t *testing.T) {
			_, err := roomBusiness.SearchRoomSubscriptions(ctx,
				&chatv1.SearchRoomSubscriptionsRequest{RoomId: ""}, validContact)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrRoomIDRequired)
		})

		t.Run("SearchRoomSubscriptions_InvalidContact", func(t *testing.T) {
			_, err := roomBusiness.SearchRoomSubscriptions(ctx,
				&chatv1.SearchRoomSubscriptionsRequest{RoomId: "some-room-id"}, nil)
			require.Error(t, err)
		})
	})
}

// TestCreateRoom_DuplicateMembers tests that duplicate members in CreateRoom are deduplicated.
func (s *RoomBusinessTestSuite) TestCreateRoom_DuplicateMembers() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		creator := &commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID}

		memberID := util.IDString()
		memberContactID := util.IDString()
		member := &commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID}

		// Create room with the same member listed twice
		room, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{
			Name:      "Dedup Test Room",
			IsPrivate: false,
			Members:   []*commonv1.ContactLink{member, member},
		}, creator)
		require.NoError(t, err)
		s.NotNil(room)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), memberID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, room.GetId(), t)

		// Verify subscriptions - should only have 2 (creator + one member), not 3
		subs, err := roomBusiness.SearchRoomSubscriptions(ctx,
			&chatv1.SearchRoomSubscriptionsRequest{RoomId: room.GetId()}, creator)
		require.NoError(t, err)
		s.Len(subs, 2, "duplicate members should be deduplicated")
	})
}

// TestCreateRoom_IdempotentWithID tests that creating a room with an existing ID returns the existing room.
func (s *RoomBusinessTestSuite) TestCreateRoom_IdempotentWithID() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		creator := &commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID}
		roomID := util.IDString()

		// First create
		room1, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{
			Id:        roomID,
			Name:      "Idempotent Room",
			IsPrivate: false,
		}, creator)
		require.NoError(t, err)
		s.Equal(roomID, room1.GetId())
		s.WaitForMemberSubscription(ctx, svc, roomID, creatorID, t)

		// Second create with same ID - should return existing room
		room2, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{
			Id:        roomID,
			Name:      "Different Name",
			IsPrivate: false,
		}, creator)
		require.NoError(t, err)
		s.Equal(roomID, room2.GetId())
	})
}

// TestNonMemberAccessErrors tests error paths for non-member access to rooms.
// These tests are consolidated into a single WithTestDependencies call to minimize
// resource usage (each call creates a fresh DB + Keto container).
func (s *RoomBusinessTestSuite) TestNonMemberAccessErrors() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		ownerID := util.IDString()
		ownerContactID := util.IDString()
		owner := &commonv1.ContactLink{ProfileId: ownerID, ContactId: ownerContactID}

		room, err := roomBusiness.CreateRoom(ctx,
			&chatv1.CreateRoomRequest{Name: "Access Error Room", IsPrivate: false}, owner)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), ownerID, t)
		s.WaitForAuthzAccess(ctx, svc, ownerID, room.GetId(), t)

		nonMember := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}

		t.Run("GetRoom_NonExistentRoom", func(t *testing.T) {
			_, err := roomBusiness.GetRoom(ctx, "nonexistent-room-id", nonMember)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrRoomAccessDenied)
		})

		t.Run("GetSubscriptionForContact_NonMember", func(t *testing.T) {
			_, err := roomBusiness.GetSubscriptionForContact(ctx, room.GetId(), nonMember)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrRoomAccessDenied)
		})

		t.Run("UpdateRoom_NonMember", func(t *testing.T) {
			_, err := roomBusiness.UpdateRoom(ctx, &chatv1.UpdateRoomRequest{
				RoomId: room.GetId(),
				Name:   "New Name",
			}, nonMember)
			require.Error(t, err)
		})

		t.Run("DeleteRoom_NonMember", func(t *testing.T) {
			err := roomBusiness.DeleteRoom(ctx, &chatv1.DeleteRoomRequest{
				RoomId: room.GetId(),
			}, nonMember)
			require.Error(t, err)
		})

		t.Run("AddRoomSubscriptions_NonMember", func(t *testing.T) {
			err := roomBusiness.AddRoomSubscriptions(ctx, &chatv1.AddRoomSubscriptionsRequest{
				RoomId: room.GetId(),
				Members: []*chatv1.RoomSubscription{
					{
						Member: &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()},
						Roles:  []string{"member"},
					},
				},
			}, nonMember)
			require.Error(t, err)
		})

		t.Run("RemoveRoomSubscriptions_NonMember", func(t *testing.T) {
			err := roomBusiness.RemoveRoomSubscriptions(ctx, &chatv1.RemoveRoomSubscriptionsRequest{
				RoomId:         room.GetId(),
				SubscriptionId: []string{"some-sub-id"},
			}, nonMember)
			require.Error(t, err)
		})

		t.Run("UpdateSubscriptionRole_NonMember", func(t *testing.T) {
			err := roomBusiness.UpdateSubscriptionRole(ctx, &chatv1.UpdateSubscriptionRoleRequest{
				RoomId:         room.GetId(),
				SubscriptionId: "some-sub-id",
				Roles:          []string{"admin"},
			}, nonMember)
			require.Error(t, err)
		})

		t.Run("SearchRoomSubscriptions_NonMember", func(t *testing.T) {
			_, err := roomBusiness.SearchRoomSubscriptions(ctx,
				&chatv1.SearchRoomSubscriptionsRequest{RoomId: room.GetId()}, nonMember)
			require.Error(t, err)
		})

		// Test removing non-existent subscription from a room the owner has access to
		t.Run("RemoveRoomSubscriptions_NonExistentSubscription", func(_ *testing.T) {
			err := roomBusiness.RemoveRoomSubscriptions(ctx, &chatv1.RemoveRoomSubscriptionsRequest{
				RoomId:         room.GetId(),
				SubscriptionId: []string{"nonexistent-sub-id"},
			}, owner)
			// Exercises removeRoomMembersBySubscriptionID path
			_ = err
		})
	})
}

// TestAuthzDeniedAfterSubscription tests the authz-denied branch in functions
// that first look up a subscription and then check authz. By removing the authz
// tuple from Keto while the subscription still exists, we exercise the authz
// failure path that is distinct from the subscription-not-found path.
func (s *RoomBusinessTestSuite) TestAuthzDeniedAfterSubscription() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		ownerID := util.IDString()
		ownerContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()
		owner := &commonv1.ContactLink{ProfileId: ownerID, ContactId: ownerContactID}
		member := &commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID}

		room, err := roomBusiness.CreateRoom(ctx,
			&chatv1.CreateRoomRequest{
				Name:    "Authz Test Room",
				Members: []*commonv1.ContactLink{member},
			}, owner)
		require.NoError(t, err)
		roomID := room.GetId()
		s.WaitForMemberSubscription(ctx, svc, roomID, ownerID, t)
		s.WaitForMemberSubscription(ctx, svc, roomID, memberID, t)
		s.WaitForAuthzAccess(ctx, svc, memberID, roomID, t)

		// Get member's subscription ID for authz removal
		subs, err := roomBusiness.SearchRoomSubscriptions(ctx,
			&chatv1.SearchRoomSubscriptionsRequest{RoomId: roomID}, owner)
		require.NoError(t, err)

		var memberSubID string
		for _, sub := range subs {
			if sub.GetMember().GetProfileId() == memberID {
				memberSubID = sub.GetId()
				break
			}
		}
		require.NotEmpty(t, memberSubID)

		// Remove authz tuple for the member (subscription still exists in DB)
		err = s.AuthzMiddleware.RemoveRoomMember(ctx, roomID, memberSubID)
		require.NoError(t, err)

		// Now test all the authz-denied-after-subscription paths
		t.Run("GetRoom_AuthzDenied", func(t *testing.T) {
			_, err := roomBusiness.GetRoom(ctx, roomID, member)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrRoomAccessDenied)
		})

		t.Run("SearchRoomSubscriptions_AuthzDenied", func(t *testing.T) {
			_, err := roomBusiness.SearchRoomSubscriptions(ctx,
				&chatv1.SearchRoomSubscriptionsRequest{RoomId: roomID}, member)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrRoomAccessDenied)
		})

		t.Run("GetSubscriptionForContact_AuthzDenied", func(t *testing.T) {
			_, err := roomBusiness.GetSubscriptionForContact(ctx, roomID, member)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrRoomAccessDenied)
		})

		t.Run("UpdateSubscriptionSettings_AuthzDenied", func(t *testing.T) {
			muted := true
			_, err := roomBusiness.UpdateSubscriptionSettings(ctx,
				&chatv1.UpdateSubscriptionSettingsRequest{
					RoomId: roomID,
					Muted:  &muted,
				}, member)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrRoomAccessDenied)
		})
	})
}

// TestGetRoom_RoomDeletedAfterSubscription tests the path where a subscription
// exists but the room has been soft-deleted.
func (s *RoomBusinessTestSuite) TestGetRoom_RoomDeletedAfterSubscription() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		workMan := svc.WorkManager()
		dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)
		roomRepo := repository.NewRoomRepository(ctx, dbPool, workMan)

		ownerID := util.IDString()
		ownerContactID := util.IDString()
		owner := &commonv1.ContactLink{ProfileId: ownerID, ContactId: ownerContactID}

		room, err := roomBusiness.CreateRoom(ctx,
			&chatv1.CreateRoomRequest{Name: "Will Be Deleted"}, owner)
		require.NoError(t, err)
		roomID := room.GetId()
		s.WaitForMemberSubscription(ctx, svc, roomID, ownerID, t)
		s.WaitForAuthzAccess(ctx, svc, ownerID, roomID, t)

		// Soft-delete the room directly via repo (subscription still exists)
		err = roomRepo.Delete(ctx, roomID)
		require.NoError(t, err)

		// GetRoom should find subscription but fail to find room → ErrRoomNotFound
		_, err = roomBusiness.GetRoom(ctx, roomID, owner)
		require.Error(t, err)
		require.ErrorIs(t, err, service.ErrRoomNotFound)
	})
}

// TestRequiresApprovalWithNilProposalRepo tests that operations on rooms with
// RequiresApproval=true fail gracefully when proposalRepo is nil.
func (s *RoomBusinessTestSuite) TestRequiresApprovalWithNilProposalRepo() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		// Use setupBusinessLayer which passes nil proposalRepo
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		workMan := svc.WorkManager()
		dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)
		roomRepo := repository.NewRoomRepository(ctx, dbPool, workMan)

		ownerID := util.IDString()
		ownerContactID := util.IDString()
		owner := &commonv1.ContactLink{ProfileId: ownerID, ContactId: ownerContactID}

		room, err := roomBusiness.CreateRoom(ctx,
			&chatv1.CreateRoomRequest{Name: "Nil Proposal Room"}, owner)
		require.NoError(t, err)
		roomID := room.GetId()
		s.WaitForMemberSubscription(ctx, svc, roomID, ownerID, t)
		s.WaitForAuthzAccess(ctx, svc, ownerID, roomID, t)

		// Set RequiresApproval directly on the DB model
		dbRoom, err := roomRepo.GetByID(ctx, roomID)
		require.NoError(t, err)
		dbRoom.RequiresApproval = true
		_, err = roomRepo.Update(ctx, dbRoom)
		require.NoError(t, err)

		// UpdateRoom should fail with "proposal repository not configured"
		_, err = roomBusiness.UpdateRoom(ctx, &chatv1.UpdateRoomRequest{
			RoomId: roomID,
			Name:   "New Name",
		}, owner)
		require.Error(t, err)
		require.Contains(t, err.Error(), "proposal repository not configured")

		// DeleteRoom should fail similarly
		err = roomBusiness.DeleteRoom(ctx, &chatv1.DeleteRoomRequest{
			RoomId: roomID,
		}, owner)
		require.Error(t, err)
		require.Contains(t, err.Error(), "proposal repository not configured")
	})
}

// TestDeleteRoom_WithMembers creates a room with members, waits for subscriptions
// and authz, then deletes it. This exercises deactivateAllRoomSubscriptions with
// actual subscribers.
func (s *RoomBusinessTestSuite) TestDeleteRoom_WithMembers() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		member1ID := util.IDString()
		member1ContactID := util.IDString()
		member2ID := util.IDString()
		member2ContactID := util.IDString()
		creator := &commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID}

		created, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{
			Name:      "Room With Members",
			IsPrivate: false,
			Members: []*commonv1.ContactLink{
				{ProfileId: member1ID, ContactId: member1ContactID},
				{ProfileId: member2ID, ContactId: member2ContactID},
			},
		}, creator)
		require.NoError(t, err)
		roomID := created.GetId()
		s.WaitForMemberSubscription(ctx, svc, roomID, creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, roomID, member1ID, t)
		s.WaitForMemberSubscription(ctx, svc, roomID, member2ID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, roomID, t)

		// Verify we have 3 members
		subs, err := roomBusiness.SearchRoomSubscriptions(ctx,
			&chatv1.SearchRoomSubscriptionsRequest{RoomId: roomID}, creator)
		require.NoError(t, err)
		require.GreaterOrEqual(t, len(subs), 3)

		// Delete room — should deactivate all subscriptions + authz tuples
		err = roomBusiness.DeleteRoom(ctx, &chatv1.DeleteRoomRequest{RoomId: roomID}, creator)
		require.NoError(t, err)

		// Verify room is gone
		_, err = roomBusiness.GetRoom(ctx, roomID, creator)
		require.Error(t, err)
	})
}

// TestRemoveRoomSubscriptions_MultipleMembers removes multiple members at once,
// exercising the removeRoomMembersBySubscriptionID loop with multiple subscription IDs.
func (s *RoomBusinessTestSuite) TestRemoveRoomSubscriptions_MultipleMembers() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		member1ID := util.IDString()
		member1ContactID := util.IDString()
		member2ID := util.IDString()
		member2ContactID := util.IDString()
		creator := &commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID}

		created, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{
			Name:      "Multi Remove Room",
			IsPrivate: false,
			Members: []*commonv1.ContactLink{
				{ProfileId: member1ID, ContactId: member1ContactID},
				{ProfileId: member2ID, ContactId: member2ContactID},
			},
		}, creator)
		require.NoError(t, err)
		roomID := created.GetId()
		s.WaitForMemberSubscription(ctx, svc, roomID, creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, roomID, member1ID, t)
		s.WaitForMemberSubscription(ctx, svc, roomID, member2ID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, roomID, t)

		// Get subscription IDs for both members
		subs, err := roomBusiness.SearchRoomSubscriptions(ctx,
			&chatv1.SearchRoomSubscriptionsRequest{RoomId: roomID}, creator)
		require.NoError(t, err)

		var subIDs []string
		for _, sub := range subs {
			pid := sub.GetMember().GetProfileId()
			if pid == member1ID || pid == member2ID {
				subIDs = append(subIDs, sub.GetId())
			}
		}
		require.Len(t, subIDs, 2)

		// Remove both members at once
		err = roomBusiness.RemoveRoomSubscriptions(ctx,
			&chatv1.RemoveRoomSubscriptionsRequest{
				RoomId:         roomID,
				SubscriptionId: subIDs,
			}, creator)
		require.NoError(t, err)

		// Verify removed members can no longer access the room
		_, err = roomBusiness.GetRoom(ctx, roomID,
			&commonv1.ContactLink{ProfileId: member1ID, ContactId: member1ContactID})
		require.Error(t, err, "removed member1 should not access room")

		_, err = roomBusiness.GetRoom(ctx, roomID,
			&commonv1.ContactLink{ProfileId: member2ID, ContactId: member2ContactID})
		require.Error(t, err, "removed member2 should not access room")

		// Creator should still have access
		_, err = roomBusiness.GetRoom(ctx, roomID, creator)
		require.NoError(t, err, "creator should still access room")
	})
}

// TestSearchRooms_ByMember verifies that SearchRooms returns only rooms the
// searching user is subscribed to, exercising the GetSubscribedRoomIDs path.
func (s *RoomBusinessTestSuite) TestSearchRooms_ByMember() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		user1ID := util.IDString()
		user1ContactID := util.IDString()
		user2ID := util.IDString()
		user2ContactID := util.IDString()
		user1 := &commonv1.ContactLink{ProfileId: user1ID, ContactId: user1ContactID}
		user2 := &commonv1.ContactLink{ProfileId: user2ID, ContactId: user2ContactID}

		// User1 creates a room
		room1, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{
			Name:      "User1 Room",
			IsPrivate: false,
		}, user1)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room1.GetId(), user1ID, t)

		// User2 creates a different room
		room2, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{
			Name:      "User2 Room",
			IsPrivate: false,
		}, user2)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room2.GetId(), user2ID, t)

		// User1 should only see their room
		results, err := roomBusiness.SearchRooms(ctx,
			&chatv1.SearchRoomsRequest{}, user1)
		require.NoError(t, err)
		for _, r := range results {
			require.NotEqual(t, room2.GetId(), r.GetId(),
				"user1 should not see user2's room")
		}

		// User2 should only see their room
		results2, err := roomBusiness.SearchRooms(ctx,
			&chatv1.SearchRoomsRequest{}, user2)
		require.NoError(t, err)
		for _, r := range results2 {
			require.NotEqual(t, room1.GetId(), r.GetId(),
				"user2 should not see user1's room")
		}
	})
}

// TestUpdateSubscriptionRole_SyncRoleUpdate verifies that changing a member's
// role actually syncs the authz tuple via syncRoleUpdate by confirming the new
// role grants new permissions.
func (s *RoomBusinessTestSuite) TestUpdateSubscriptionRole_SyncRoleUpdate() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()
		creator := &commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID}
		member := &commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID}

		created, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{
			Name:      "Role Sync Room",
			IsPrivate: false,
			Members:   []*commonv1.ContactLink{member},
		}, creator)
		require.NoError(t, err)
		roomID := created.GetId()
		s.WaitForMemberSubscription(ctx, svc, roomID, creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, roomID, memberID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, roomID, t)

		// Member should NOT be able to update room initially (requires admin/owner)
		_, err = roomBusiness.UpdateRoom(ctx, &chatv1.UpdateRoomRequest{
			RoomId: roomID,
			Name:   "Member Edit",
		}, member)
		require.Error(t, err, "regular member should not be able to update room")

		// Find member subscription ID
		subs, err := roomBusiness.SearchRoomSubscriptions(ctx,
			&chatv1.SearchRoomSubscriptionsRequest{RoomId: roomID}, creator)
		require.NoError(t, err)

		var memberSubID string
		for _, sub := range subs {
			if sub.GetMember().GetProfileId() == memberID {
				memberSubID = sub.GetId()
				break
			}
		}
		require.NotEmpty(t, memberSubID)

		// Promote to admin — this calls syncRoleUpdate internally
		err = roomBusiness.UpdateSubscriptionRole(ctx,
			&chatv1.UpdateSubscriptionRoleRequest{
				RoomId:         roomID,
				SubscriptionId: memberSubID,
				Roles:          []string{"admin"},
			}, creator)
		require.NoError(t, err)

		// Member should now be able to update room (admin has update permission)
		updated, err := roomBusiness.UpdateRoom(ctx, &chatv1.UpdateRoomRequest{
			RoomId: roomID,
			Name:   "Admin Edit",
		}, member)
		require.NoError(t, err)
		require.Equal(t, "Admin Edit", updated.GetName())

		// Demote back to member — should revoke admin permissions
		err = roomBusiness.UpdateSubscriptionRole(ctx,
			&chatv1.UpdateSubscriptionRoleRequest{
				RoomId:         roomID,
				SubscriptionId: memberSubID,
				Roles:          []string{"member"},
			}, creator)
		require.NoError(t, err)

		// Member should no longer be able to update room
		_, err = roomBusiness.UpdateRoom(ctx, &chatv1.UpdateRoomRequest{
			RoomId: roomID,
			Name:   "Should Fail",
		}, member)
		require.Error(t, err, "demoted member should not be able to update room")
	})
}
