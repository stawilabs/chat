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
	CanViewRoom(ctx context.Context, subscriptionID string, roomID string) error
	CanSendMessage(ctx context.Context, subscriptionID string, roomID string) error
	CanUpdateRoom(ctx context.Context, subscriptionID string, roomID string) error
	CanDeleteRoom(ctx context.Context, subscriptionID string, roomID string) error
	CanManageMembers(ctx context.Context, subscriptionID string, roomID string) error
	CanManageRoles(ctx context.Context, subscriptionID string, roomID string) error

	// Message permissions - identity-based, not room access
	CanDeleteMessage(
		ctx context.Context,
		actor *commonv1.ContactLink,
		messageID string,
		senderProfileID string,
		roomID string,
	) error
	CanEditMessage(ctx context.Context, actor *commonv1.ContactLink, messageID string, senderProfileID string) error

	// Batch operations - map[roomID]subscriptionID
	CanSendMessagesToRooms(ctx context.Context, subscriptionsByRoom map[string]string) (map[string]bool, error)

	// Tuple management - subscriptionID as subject
	AddRoomMember(ctx context.Context, roomID string, subscriptionID string, role string) error
	RemoveRoomMember(ctx context.Context, roomID string, subscriptionID string) error
	UpdateRoomMemberRole(ctx context.Context, roomID string, subscriptionID string, oldRole, newRole string) error

	// SetMessageSender Message tuple management
	SetMessageSender(ctx context.Context, messageID string, senderProfileID string, roomID string) error
}
