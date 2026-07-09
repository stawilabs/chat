package authz_test

import (
	"context"
	"errors"
	"testing"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	"github.com/pitabwire/frame/v2/security"
	"github.com/pitabwire/frame/v2/security/authorizer"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/suite"

	"github.com/stawilabs/chat/apps/default/service/authz"
	"github.com/stawilabs/chat/apps/default/service/authz/mock"
)

type MiddlewareTestSuite struct {
	suite.Suite
	mockService *mock.AuthzService
	middleware  authz.Middleware
}

func TestMiddlewareTestSuite(t *testing.T) {
	suite.Run(t, new(MiddlewareTestSuite))
}

func (s *MiddlewareTestSuite) SetupTest() {
	s.mockService = mock.NewAuthzService()
	s.middleware = authz.NewMiddleware(s.mockService)
}

func (s *MiddlewareTestSuite) TearDownTest() {
	s.mockService.Reset()
}

func (s *MiddlewareTestSuite) actor(profileID string) *commonv1.ContactLink {
	return &commonv1.ContactLink{
		ProfileId: profileID,
		ContactId: util.IDString(),
	}
}

// CanViewRoom tests.
func (s *MiddlewareTestSuite) TestCanViewRoom() {
	testCases := []struct {
		name            string
		role            string
		addMembership   bool
		shouldBeAllowed bool
	}{
		{"MemberCanView", authz.RoleMember, true, true},
		{"AdminCanView", authz.RoleAdmin, true, true},
		{"OwnerCanView", authz.RoleOwner, true, true},
		{"GuestCanView", authz.RoleGuest, true, true},
		{"NonMemberDenied", "", false, false},
	}

	for _, tc := range testCases {
		s.Run(tc.name, func() {
			ctx := context.Background()
			roomID := util.IDString()
			subscriptionID := util.IDString()

			if tc.addMembership {
				err := s.mockService.AddRoomMember(roomID, subscriptionID, tc.role)
				s.Require().NoError(err)
			}

			err := s.middleware.CanRoomView(ctx, subscriptionID, roomID)

			if tc.shouldBeAllowed {
				s.Require().NoError(err)
			} else {
				s.Require().Error(err)
				s.Require().ErrorIs(err, authorizer.ErrPermissionDenied)
			}
		})
	}
}

func (s *MiddlewareTestSuite) TestCanViewRoom_EmptySubscriptionIDDenied() {
	ctx := context.Background()
	roomID := util.IDString()

	err := s.middleware.CanRoomView(ctx, "", roomID)
	s.Require().Error(err)
	s.Require().ErrorIs(err, authorizer.ErrInvalidSubject)
}

// CanSendMessage tests.
func (s *MiddlewareTestSuite) TestCanSendMessage_MemberCanSend() {
	ctx := context.Background()
	roomID := util.IDString()
	subscriptionID := util.IDString()

	err := s.mockService.AddRoomMember(roomID, subscriptionID, authz.RoleMember)
	s.Require().NoError(err)

	err = s.middleware.CanMessageSend(ctx, subscriptionID, roomID)
	s.Require().NoError(err)
}

func (s *MiddlewareTestSuite) TestCanSendMessage_AdminCanSend() {
	ctx := context.Background()
	roomID := util.IDString()
	subscriptionID := util.IDString()

	err := s.mockService.AddRoomMember(roomID, subscriptionID, authz.RoleAdmin)
	s.Require().NoError(err)

	err = s.middleware.CanMessageSend(ctx, subscriptionID, roomID)
	s.Require().NoError(err)
}

func (s *MiddlewareTestSuite) TestCanSendMessage_OwnerCanSend() {
	ctx := context.Background()
	roomID := util.IDString()
	subscriptionID := util.IDString()

	err := s.mockService.AddRoomMember(roomID, subscriptionID, authz.RoleOwner)
	s.Require().NoError(err)

	err = s.middleware.CanMessageSend(ctx, subscriptionID, roomID)
	s.Require().NoError(err)
}

func (s *MiddlewareTestSuite) TestCanSendMessage_GuestCannotSend() {
	ctx := context.Background()
	roomID := util.IDString()
	subscriptionID := util.IDString()

	// Guest (viewer) should not be able to send messages
	err := s.mockService.AddRoomMember(roomID, subscriptionID, authz.RoleGuest)
	s.Require().NoError(err)

	err = s.middleware.CanMessageSend(ctx, subscriptionID, roomID)
	s.Require().Error(err)
	s.Require().ErrorIs(err, authorizer.ErrPermissionDenied)
}

func (s *MiddlewareTestSuite) TestCanSendMessage_NonMemberDenied() {
	ctx := context.Background()
	roomID := util.IDString()
	subscriptionID := util.IDString()

	err := s.middleware.CanMessageSend(ctx, subscriptionID, roomID)
	s.Require().Error(err)
	s.Require().ErrorIs(err, authorizer.ErrPermissionDenied)
}

// CanUpdateRoom tests.
func (s *MiddlewareTestSuite) TestCanUpdateRoom_AdminCanUpdate() {
	ctx := context.Background()
	roomID := util.IDString()
	subscriptionID := util.IDString()

	err := s.mockService.AddRoomMember(roomID, subscriptionID, authz.RoleAdmin)
	s.Require().NoError(err)

	err = s.middleware.CanRoomUpdate(ctx, subscriptionID, roomID)
	s.Require().NoError(err)
}

func (s *MiddlewareTestSuite) TestCanUpdateRoom_OwnerCanUpdate() {
	ctx := context.Background()
	roomID := util.IDString()
	subscriptionID := util.IDString()

	err := s.mockService.AddRoomMember(roomID, subscriptionID, authz.RoleOwner)
	s.Require().NoError(err)

	err = s.middleware.CanRoomUpdate(ctx, subscriptionID, roomID)
	s.Require().NoError(err)
}

func (s *MiddlewareTestSuite) TestCanUpdateRoom_MemberCannotUpdate() {
	ctx := context.Background()
	roomID := util.IDString()
	subscriptionID := util.IDString()

	err := s.mockService.AddRoomMember(roomID, subscriptionID, authz.RoleMember)
	s.Require().NoError(err)

	err = s.middleware.CanRoomUpdate(ctx, subscriptionID, roomID)
	s.Require().Error(err)
	s.Require().ErrorIs(err, authorizer.ErrPermissionDenied)
}

// CanDeleteRoom tests.
func (s *MiddlewareTestSuite) TestCanDeleteRoom_OwnerCanDelete() {
	ctx := context.Background()
	roomID := util.IDString()
	subscriptionID := util.IDString()

	err := s.mockService.AddRoomMember(roomID, subscriptionID, authz.RoleOwner)
	s.Require().NoError(err)

	err = s.middleware.CanRoomDelete(ctx, subscriptionID, roomID)
	s.Require().NoError(err)
}

func (s *MiddlewareTestSuite) TestCanDeleteRoom_AdminCannotDelete() {
	ctx := context.Background()
	roomID := util.IDString()
	subscriptionID := util.IDString()

	err := s.mockService.AddRoomMember(roomID, subscriptionID, authz.RoleAdmin)
	s.Require().NoError(err)

	err = s.middleware.CanRoomDelete(ctx, subscriptionID, roomID)
	s.Require().Error(err)
	s.Require().ErrorIs(err, authorizer.ErrPermissionDenied)
}

// CanManageMembers tests.
func (s *MiddlewareTestSuite) TestCanManageMembers_AdminCanManage() {
	ctx := context.Background()
	roomID := util.IDString()
	subscriptionID := util.IDString()

	err := s.mockService.AddRoomMember(roomID, subscriptionID, authz.RoleAdmin)
	s.Require().NoError(err)

	err = s.middleware.CanMembersManage(ctx, subscriptionID, roomID)
	s.Require().NoError(err)
}

func (s *MiddlewareTestSuite) TestCanManageMembers_OwnerCanManage() {
	ctx := context.Background()
	roomID := util.IDString()
	subscriptionID := util.IDString()

	err := s.mockService.AddRoomMember(roomID, subscriptionID, authz.RoleOwner)
	s.Require().NoError(err)

	err = s.middleware.CanMembersManage(ctx, subscriptionID, roomID)
	s.Require().NoError(err)
}

func (s *MiddlewareTestSuite) TestCanManageMembers_MemberCannotManage() {
	ctx := context.Background()
	roomID := util.IDString()
	subscriptionID := util.IDString()

	err := s.mockService.AddRoomMember(roomID, subscriptionID, authz.RoleMember)
	s.Require().NoError(err)

	err = s.middleware.CanMembersManage(ctx, subscriptionID, roomID)
	s.Require().Error(err)
	s.Require().ErrorIs(err, authorizer.ErrPermissionDenied)
}

// CanManageRoles tests.
func (s *MiddlewareTestSuite) TestCanManageRoles_OwnerCanManage() {
	ctx := context.Background()
	roomID := util.IDString()
	subscriptionID := util.IDString()

	err := s.mockService.AddRoomMember(roomID, subscriptionID, authz.RoleOwner)
	s.Require().NoError(err)

	err = s.middleware.CanRolesManage(ctx, subscriptionID, roomID)
	s.Require().NoError(err)
}

func (s *MiddlewareTestSuite) TestCanManageRoles_AdminCannotManage() {
	ctx := context.Background()
	roomID := util.IDString()
	subscriptionID := util.IDString()

	err := s.mockService.AddRoomMember(roomID, subscriptionID, authz.RoleAdmin)
	s.Require().NoError(err)

	err = s.middleware.CanRolesManage(ctx, subscriptionID, roomID)
	s.Require().Error(err)
	s.Require().ErrorIs(err, authorizer.ErrPermissionDenied)
}

// CanDeleteMessage tests - these still use actor (identity-based).
func (s *MiddlewareTestSuite) TestCanDeleteMessage_SenderCanDelete() {
	ctx := context.Background()
	roomID := util.IDString()
	messageID := util.IDString()
	profileID := util.IDString()

	// Sender can always delete their own message (fast path)
	err := s.middleware.CanMessageDelete(ctx, s.actor(profileID), messageID, profileID, roomID)
	s.Require().NoError(err)
}

func (s *MiddlewareTestSuite) TestCanDeleteMessage_AdminCanDeleteOthers() {
	ctx := context.Background()
	roomID := util.IDString()
	messageID := util.IDString()
	adminID := util.IDString()
	senderID := util.IDString()

	// Admin can delete others' messages - note: CanDeleteMessage uses profileID as subscriptionID
	// for non-sender path (checking room permission)
	err := s.mockService.AddRoomMember(roomID, adminID, authz.RoleAdmin)
	s.Require().NoError(err)

	err = s.middleware.CanMessageDelete(ctx, s.actor(adminID), messageID, senderID, roomID)
	s.Require().NoError(err)
}

func (s *MiddlewareTestSuite) TestCanDeleteMessage_OwnerCanDeleteOthers() {
	ctx := context.Background()
	roomID := util.IDString()
	messageID := util.IDString()
	ownerID := util.IDString()
	senderID := util.IDString()

	err := s.mockService.AddRoomMember(roomID, ownerID, authz.RoleOwner)
	s.Require().NoError(err)

	err = s.middleware.CanMessageDelete(ctx, s.actor(ownerID), messageID, senderID, roomID)
	s.Require().NoError(err)
}

func (s *MiddlewareTestSuite) TestCanDeleteMessage_MemberCannotDeleteOthers() {
	ctx := context.Background()
	roomID := util.IDString()
	messageID := util.IDString()
	memberID := util.IDString()
	senderID := util.IDString()

	err := s.mockService.AddRoomMember(roomID, memberID, authz.RoleMember)
	s.Require().NoError(err)

	err = s.middleware.CanMessageDelete(ctx, s.actor(memberID), messageID, senderID, roomID)
	s.Require().Error(err)
	s.Require().ErrorIs(err, authorizer.ErrPermissionDenied)
}

// CanEditMessage tests - these still use actor (identity-based).
func (s *MiddlewareTestSuite) TestCanEditMessage_SenderCanEdit() {
	ctx := context.Background()
	messageID := util.IDString()
	profileID := util.IDString()

	// Sender can always edit their own message
	err := s.middleware.CanMessageEdit(ctx, s.actor(profileID), messageID, profileID)
	s.Require().NoError(err)
}

func (s *MiddlewareTestSuite) TestCanEditMessage_OthersCannotEdit() {
	ctx := context.Background()
	messageID := util.IDString()
	profileID := util.IDString()
	senderID := util.IDString()

	// Others cannot edit (even admin/owner)
	err := s.middleware.CanMessageEdit(ctx, s.actor(profileID), messageID, senderID)
	s.Require().Error(err)
	s.Require().ErrorIs(err, authorizer.ErrPermissionDenied)
}

// CanSendMessagesToRooms tests.
func (s *MiddlewareTestSuite) TestCanSendMessagesToRooms_BatchCheck() {
	ctx := context.Background()
	sub1ID := util.IDString()
	sub2ID := util.IDString()
	sub3ID := util.IDString()
	room1ID := util.IDString()
	room2ID := util.IDString()
	room3ID := util.IDString()

	// Add member to room1 and room2, but not room3
	err := s.mockService.AddRoomMember(room1ID, sub1ID, authz.RoleMember)
	s.Require().NoError(err)
	err = s.mockService.AddRoomMember(room2ID, sub2ID, authz.RoleAdmin)
	s.Require().NoError(err)

	subscriptionsByRoom := map[string]string{
		room1ID: sub1ID,
		room2ID: sub2ID,
		room3ID: sub3ID,
	}
	allowed, err := s.middleware.CanMessageSendToRooms(ctx, subscriptionsByRoom)
	s.Require().NoError(err)

	s.True(allowed[room1ID], "Member should be able to send to room1")
	s.True(allowed[room2ID], "Admin should be able to send to room2")
	s.False(allowed[room3ID], "Non-member should not be able to send to room3")
}

func (s *MiddlewareTestSuite) TestCanSendMessagesToRooms_EmptyList() {
	ctx := context.Background()

	allowed, err := s.middleware.CanMessageSendToRooms(ctx, map[string]string{})
	s.Require().NoError(err)
	s.Empty(allowed)
}

// AddRoomMember tests.
func (s *MiddlewareTestSuite) TestAddRoomMember_CreatesMemberTuple() {
	ctx := context.Background()
	roomID := util.IDString()
	subscriptionID := util.IDString()

	err := s.middleware.AddRoomMember(ctx, roomID, subscriptionID, authz.RoleMember)
	s.Require().NoError(err)

	// Verify tuple was created with subscription namespace
	tuple := security.RelationTuple{
		Object:   security.ObjectRef{Namespace: authz.NamespaceRoom, ID: roomID},
		Relation: authz.RelationMember,
		Subject:  security.SubjectRef{Namespace: authz.NamespaceSubscription, ID: subscriptionID},
	}
	s.True(s.mockService.HasTuple(tuple))
}

func (s *MiddlewareTestSuite) TestAddRoomMember_CreatesOwnerTuple() {
	ctx := context.Background()
	roomID := util.IDString()
	subscriptionID := util.IDString()

	err := s.middleware.AddRoomMember(ctx, roomID, subscriptionID, authz.RoleOwner)
	s.Require().NoError(err)

	tuple := security.RelationTuple{
		Object:   security.ObjectRef{Namespace: authz.NamespaceRoom, ID: roomID},
		Relation: authz.RelationOwner,
		Subject:  security.SubjectRef{Namespace: authz.NamespaceSubscription, ID: subscriptionID},
	}
	s.True(s.mockService.HasTuple(tuple))
}

// RemoveRoomMember tests.
func (s *MiddlewareTestSuite) TestRemoveRoomMember_RemovesAllRelations() {
	ctx := context.Background()
	roomID := util.IDString()
	subscriptionID := util.IDString()

	// Add member
	err := s.mockService.AddRoomMember(roomID, subscriptionID, authz.RoleMember)
	s.Require().NoError(err)

	// Remove member
	err = s.middleware.RemoveRoomMember(ctx, roomID, subscriptionID)
	s.Require().NoError(err)

	// Verify all tuples for this member are removed
	tuples := s.mockService.GetTuples()
	for _, tuple := range tuples {
		if tuple.Object.ID == roomID && tuple.Subject.ID == subscriptionID {
			s.Fail("Found remaining tuple for removed member")
		}
	}
}

// UpdateRoomMemberRole tests.
func (s *MiddlewareTestSuite) TestUpdateRoomMemberRole_UpdatesRole() {
	ctx := context.Background()
	roomID := util.IDString()
	subscriptionID := util.IDString()

	// Add member
	err := s.mockService.AddRoomMember(roomID, subscriptionID, authz.RoleMember)
	s.Require().NoError(err)

	// Update to admin
	err = s.middleware.UpdateRoomMemberRole(ctx, roomID, subscriptionID, authz.RoleMember, authz.RoleAdmin)
	s.Require().NoError(err)

	// Verify new admin tuple exists
	adminTuple := security.RelationTuple{
		Object:   security.ObjectRef{Namespace: authz.NamespaceRoom, ID: roomID},
		Relation: authz.RelationAdmin,
		Subject:  security.SubjectRef{Namespace: authz.NamespaceSubscription, ID: subscriptionID},
	}
	s.True(s.mockService.HasTuple(adminTuple))

	// Verify old member tuple is removed
	memberTuple := security.RelationTuple{
		Object:   security.ObjectRef{Namespace: authz.NamespaceRoom, ID: roomID},
		Relation: authz.RelationMember,
		Subject:  security.SubjectRef{Namespace: authz.NamespaceSubscription, ID: subscriptionID},
	}
	s.False(s.mockService.HasTuple(memberTuple), "old member role should be removed")
}

// SetMessageSender tests.
func (s *MiddlewareTestSuite) TestSetMessageSender_CreatesTuples() {
	ctx := context.Background()
	messageID := util.IDString()
	senderID := util.IDString()
	roomID := util.IDString()

	err := s.middleware.SetMessageSender(ctx, messageID, senderID, roomID)
	s.Require().NoError(err)

	// Verify sender tuple
	senderTuple := security.RelationTuple{
		Object:   security.ObjectRef{Namespace: authz.NamespaceMessage, ID: messageID},
		Relation: authz.RelationSender,
		Subject:  security.SubjectRef{Namespace: authz.NamespaceProfile, ID: senderID},
	}
	s.True(s.mockService.HasTuple(senderTuple))

	// Verify room tuple
	roomTuple := security.RelationTuple{
		Object:   security.ObjectRef{Namespace: authz.NamespaceMessage, ID: messageID},
		Relation: authz.RelationRoom,
		Subject:  security.SubjectRef{Namespace: authz.NamespaceRoom, ID: roomID},
	}
	s.True(s.mockService.HasTuple(roomTuple))
}

// Service error handling tests.
func (s *MiddlewareTestSuite) TestCanViewRoom_ServiceError() {
	ctx := context.Background()
	roomID := util.IDString()
	subscriptionID := util.IDString()

	// Configure mock to return error
	s.mockService.CheckFunc = func(_ context.Context, _ security.CheckRequest) (security.CheckResult, error) {
		return security.CheckResult{}, errors.New("service unavailable")
	}

	err := s.middleware.CanRoomView(ctx, subscriptionID, roomID)
	s.Require().Error(err)
	s.Require().Contains(err.Error(), "authorization check failed")
}
