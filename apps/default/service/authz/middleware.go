package authz

import (
	"context"
	"fmt"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	"github.com/pitabwire/frame/security"
	"github.com/pitabwire/frame/security/authorizer"
	"github.com/pitabwire/util"
)

// middleware implements the Middleware interface.
type middleware struct {
	service security.Authorizer
}

// NewMiddleware creates a new Middleware with the given authorizer service.
func NewMiddleware(service security.Authorizer) Middleware {
	return &middleware{
		service: service,
	}
}

// CanRoomView checks if the subscription can view a room.
func (m *middleware) CanRoomView(ctx context.Context, subscriptionID string, roomID string) error {
	return m.checkRoomPermission(ctx, subscriptionID, roomID, PermissionView)
}

// CanMessageSend checks if the subscription can send messages to a room.
func (m *middleware) CanMessageSend(ctx context.Context, subscriptionID string, roomID string) error {
	return m.checkRoomPermission(ctx, subscriptionID, roomID, PermissionMessageSend)
}

// CanRoomUpdate checks if the subscription can update a room.
func (m *middleware) CanRoomUpdate(ctx context.Context, subscriptionID string, roomID string) error {
	return m.checkRoomPermission(ctx, subscriptionID, roomID, PermissionUpdate)
}

// CanRoomDelete checks if the subscription can delete a room.
func (m *middleware) CanRoomDelete(ctx context.Context, subscriptionID string, roomID string) error {
	return m.checkRoomPermission(ctx, subscriptionID, roomID, PermissionDelete)
}

// CanMembersManage checks if the subscription can add/remove members from a room.
func (m *middleware) CanMembersManage(ctx context.Context, subscriptionID string, roomID string) error {
	return m.checkRoomPermission(ctx, subscriptionID, roomID, PermissionMembersManage)
}

// CanRolesManage checks if the subscription can change member roles in a room.
func (m *middleware) CanRolesManage(ctx context.Context, subscriptionID string, roomID string) error {
	return m.checkRoomPermission(ctx, subscriptionID, roomID, PermissionRolesManage)
}

// CanMessageDelete checks if the actor can delete a message.
// Fast path: sender can always delete their own message.
func (m *middleware) CanMessageDelete(
	ctx context.Context,
	actor *commonv1.ContactLink,
	_, senderProfileID, roomID string,
) error {
	profileID := actor.GetProfileId()

	// Fast path: sender can always delete their own message
	if profileID == senderProfileID {
		return nil
	}

	// Check room admin/owner permission for deleting others' messages
	return m.checkRoomPermission(ctx, actor.GetProfileId(), roomID, PermissionMessageDeleteAny)
}

// CanMessageEdit checks if the actor can edit a message.
// Only the sender can edit their own message.
func (m *middleware) CanMessageEdit(
	_ context.Context,
	actor *commonv1.ContactLink,
	messageID, senderProfileID string,
) error {
	profileID := actor.GetProfileId()

	// Only sender can edit their own message
	if profileID == senderProfileID {
		return nil
	}

	return authorizer.NewPermissionDeniedError(
		security.ObjectRef{Namespace: NamespaceMessage, ID: messageID},
		PermissionEdit,
		security.SubjectRef{Namespace: NamespaceProfile, ID: profileID},
		"only the message sender can edit the message",
	)
}

// CanMessageSendToRooms checks if the subscriptions can send messages to multiple rooms.
// Accepts map[roomID]subscriptionID. Returns a map of room ID to allowed status.
func (m *middleware) CanMessageSendToRooms(
	ctx context.Context,
	subscriptionsByRoom map[string]string,
) (map[string]bool, error) {
	if len(subscriptionsByRoom) == 0 {
		return map[string]bool{}, nil
	}

	util.Log(ctx).WithField("room_count", len(subscriptionsByRoom)).Debug("CanMessageSendToRooms batch check")

	roomIDs := make([]string, 0, len(subscriptionsByRoom))
	for roomID := range subscriptionsByRoom {
		roomIDs = append(roomIDs, roomID)
	}

	requests := make([]security.CheckRequest, len(roomIDs))
	for i, roomID := range roomIDs {
		subscriptionID := subscriptionsByRoom[roomID]
		requests[i] = security.CheckRequest{
			Object:     security.ObjectRef{Namespace: NamespaceRoom, ID: roomID},
			Permission: PermissionMessageSend,
			Subject:    security.SubjectRef{Namespace: NamespaceSubscription, ID: subscriptionID},
		}
	}

	results, err := m.service.BatchCheck(ctx, requests)
	if err != nil {
		return nil, fmt.Errorf("batch check failed: %w", err)
	}

	allowed := make(map[string]bool, len(roomIDs))
	for i, roomID := range roomIDs {
		allowed[roomID] = results[i].Allowed
	}
	return allowed, nil
}

// AddRoomMember adds a member to a room with the specified role.
func (m *middleware) AddRoomMember(ctx context.Context, roomID, subscriptionID, role string) error {
	relation := RoleToRelation(role)
	util.Log(ctx).WithFields(map[string]any{
		"room_id":         roomID,
		"subscription_id": subscriptionID,
		"role":            role,
		"relation":        relation,
	}).Debug("AddRoomMember writing tuple")
	return m.service.WriteTuple(ctx, security.RelationTuple{
		Object:   security.ObjectRef{Namespace: NamespaceRoom, ID: roomID},
		Relation: relation,
		Subject:  security.SubjectRef{Namespace: NamespaceSubscription, ID: subscriptionID},
	})
}

// RemoveRoomMember removes all relations for a member from a room.
func (m *middleware) RemoveRoomMember(ctx context.Context, roomID, subscriptionID string) error {
	util.Log(ctx).WithFields(map[string]any{
		"room_id":         roomID,
		"subscription_id": subscriptionID,
	}).Debug("RemoveRoomMember deleting tuples")
	// Remove all relations for this member
	tuples := make([]security.RelationTuple, len(ValidRelations()))
	for i, rel := range ValidRelations() {
		tuples[i] = security.RelationTuple{
			Object:   security.ObjectRef{Namespace: NamespaceRoom, ID: roomID},
			Relation: rel,
			Subject:  security.SubjectRef{Namespace: NamespaceSubscription, ID: subscriptionID},
		}
	}
	return m.service.DeleteTuples(ctx, tuples)
}

// UpdateRoomMemberRole updates a member's role in a room.
func (m *middleware) UpdateRoomMemberRole(ctx context.Context, roomID, subscriptionID, oldRole, newRole string) error {
	util.Log(ctx).WithFields(map[string]any{
		"room_id":         roomID,
		"subscription_id": subscriptionID,
		"old_role":        oldRole,
		"new_role":        newRole,
	}).Debug("UpdateRoomMemberRole")
	// Remove old relation if specified
	if oldRole != "" {
		_ = m.service.DeleteTuple(ctx, security.RelationTuple{
			Object:   security.ObjectRef{Namespace: NamespaceRoom, ID: roomID},
			Relation: RoleToRelation(oldRole),
			Subject:  security.SubjectRef{Namespace: NamespaceSubscription, ID: subscriptionID},
		})
	}

	// Add new relation
	return m.service.WriteTuple(ctx, security.RelationTuple{
		Object:   security.ObjectRef{Namespace: NamespaceRoom, ID: roomID},
		Relation: RoleToRelation(newRole),
		Subject:  security.SubjectRef{Namespace: NamespaceSubscription, ID: subscriptionID},
	})
}

// SetMessageSender creates a sender relation for a message.
func (m *middleware) SetMessageSender(ctx context.Context, messageID, senderProfileID, roomID string) error {
	// Create sender relation
	senderTuple := security.RelationTuple{
		Object:   security.ObjectRef{Namespace: NamespaceMessage, ID: messageID},
		Relation: RelationSender,
		Subject:  security.SubjectRef{Namespace: NamespaceProfile, ID: senderProfileID},
	}

	// Create room relation
	roomTuple := security.RelationTuple{
		Object:   security.ObjectRef{Namespace: NamespaceMessage, ID: messageID},
		Relation: RelationRoom,
		Subject:  security.SubjectRef{Namespace: NamespaceRoom, ID: roomID},
	}

	return m.service.WriteTuples(ctx, []security.RelationTuple{senderTuple, roomTuple})
}

// checkRoomPermission is a helper that checks a room permission and returns an appropriate error.
func (m *middleware) checkRoomPermission(
	ctx context.Context,
	subscriptionID, roomID, permission string,
) error {
	if subscriptionID == "" {
		return authorizer.ErrInvalidSubject
	}

	util.Log(ctx).WithFields(map[string]any{
		"room_id":         roomID,
		"subscription_id": subscriptionID,
		"permission":      permission,
	}).Debug("checkRoomPermission")

	req := security.CheckRequest{
		Object:     security.ObjectRef{Namespace: NamespaceRoom, ID: roomID},
		Permission: permission,
		Subject:    security.SubjectRef{Namespace: NamespaceSubscription, ID: subscriptionID},
	}

	result, err := m.service.Check(ctx, req)
	if err != nil {
		return fmt.Errorf("authorization check failed: %w", err)
	}

	util.Log(ctx).WithFields(map[string]any{
		"room_id":    roomID,
		"permission": permission,
		"allowed":    result.Allowed,
	}).Debug("checkRoomPermission result")

	if !result.Allowed {
		return authorizer.NewPermissionDeniedError(
			req.Object,
			permission,
			req.Subject,
			result.Reason,
		)
	}

	return nil
}
