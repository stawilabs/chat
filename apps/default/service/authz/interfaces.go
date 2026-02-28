// Package authz provides a Zanzibar-style ACL authorization system with
// a clean abstraction layer allowing the authorization backend to be swapped
// without affecting business logic.
package authz

import (
	"context"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
)

// Middleware provides domain-specific authorization methods.
// These translate business operations to authorization checks.
type Middleware interface {
	// Room permissions - subscriptionID is used as the subject
	CanRoomView(ctx context.Context, subscriptionID string, roomID string) error
	CanMessageSend(ctx context.Context, subscriptionID string, roomID string) error
	CanRoomUpdate(ctx context.Context, subscriptionID string, roomID string) error
	CanRoomDelete(ctx context.Context, subscriptionID string, roomID string) error
	CanMembersManage(ctx context.Context, subscriptionID string, roomID string) error
	CanRolesManage(ctx context.Context, subscriptionID string, roomID string) error

	// Message permissions - identity-based, not room access
	CanMessageDelete(
		ctx context.Context,
		actor *commonv1.ContactLink,
		messageID string,
		senderProfileID string,
		roomID string,
	) error
	CanMessageEdit(ctx context.Context, actor *commonv1.ContactLink, messageID string, senderProfileID string) error

	// Batch operations - map[roomID]subscriptionID
	CanMessageSendToRooms(ctx context.Context, subscriptionsByRoom map[string]string) (map[string]bool, error)

	// Tuple management - subscriptionID as subject
	AddRoomMember(ctx context.Context, roomID string, subscriptionID string, role string) error
	RemoveRoomMember(ctx context.Context, roomID string, subscriptionID string) error
	UpdateRoomMemberRole(ctx context.Context, roomID string, subscriptionID string, oldRole, newRole string) error

	// SetMessageSender Message tuple management
	SetMessageSender(ctx context.Context, messageID string, senderProfileID string, roomID string) error
}
