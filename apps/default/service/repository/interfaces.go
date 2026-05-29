package repository

import (
	"context"
	"time"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	"github.com/pitabwire/frame/datastore"

	"github.com/stawilabs/chat/apps/default/service/models"
)

// RoomRepository defines the interface for room data access operations.
type RoomRepository interface {
	datastore.BaseRepository[*models.Room]
	GetByTenantAndType(ctx context.Context, tenantID, roomType string) ([]*models.Room, error)
	GetRoomsByProfileID(ctx context.Context, profileID string) ([]*models.Room, error)
}

// RoomEventRepository defines the interface for room event data access operations.
type RoomEventRepository interface {
	datastore.BaseRepository[*models.RoomEvent]
	GetByRoomID(ctx context.Context, roomID string, limit int) ([]*models.RoomEvent, error)
	GetHistory(
		ctx context.Context,
		roomID string,
		beforeEventID, afterEventID string,
		limit int,
	) ([]*models.RoomEvent, error)
	GetByEventID(ctx context.Context, roomID, eventID string) (*models.RoomEvent, error)
	CountByRoomID(ctx context.Context, roomID string) (int64, error)
	// ExistsByIDs checks if any of the given event IDs already exist.
	// Returns a map of eventID -> exists for deduplication.
	ExistsByIDs(ctx context.Context, eventIDs []string) (map[string]bool, error)
	// CreateIgnoringDuplicates inserts events one-by-one with ON CONFLICT DO NOTHING.
	// Returns a map of eventID -> true for events that were actually inserted (not duplicates).
	CreateIgnoringDuplicates(ctx context.Context, events []*models.RoomEvent) (map[string]bool, error)
}

type DeviceReplayRepository interface {
	datastore.BaseRepository[*models.DeviceReplayEvent]
	ListAfterCursor(
		ctx context.Context,
		profileID string,
		deviceID string,
		afterCursor string,
		upperBoundCursor string,
		limit int,
	) ([]*models.DeviceReplayEvent, error)
	GetByCursor(
		ctx context.Context,
		profileID string,
		deviceID string,
		cursor string,
	) (*models.DeviceReplayEvent, error)
	GetByEventID(
		ctx context.Context,
		profileID string,
		deviceID string,
		eventID string,
	) (*models.DeviceReplayEvent, error)
	GetLatestCursor(ctx context.Context, profileID string, deviceID string) (string, error)
	CreateIgnoringDuplicates(ctx context.Context, entries []*models.DeviceReplayEvent) error
	ListByEventAndDevices(
		ctx context.Context,
		profileID string,
		eventID string,
		deviceIDs []string,
	) ([]*models.DeviceReplayEvent, error)
	TrimDevice(ctx context.Context, profileID string, deviceID string, keep int, maxAge time.Duration) error
}

// RoomSubscriptionRepository defines the interface for room subscription data access operations.
type RoomSubscriptionRepository interface {
	datastore.BaseRepository[*models.RoomSubscription]
	GetByContactLinkAndRooms(
		ctx context.Context,
		contactLink *commonv1.ContactLink,
		roomID ...string,
	) ([]*models.RoomSubscription, error)
	GetByRoomID(ctx context.Context, roomID string, cursor *commonv1.PageCursor) ([]*models.RoomSubscription, error)
	GetAllByRoomID(ctx context.Context, roomID string, cursor *commonv1.PageCursor) ([]*models.RoomSubscription, error)
	GetByRoomIDAndContactLinks(
		ctx context.Context,
		roomID string,
		contactLink ...*commonv1.ContactLink,
	) ([]*models.RoomSubscription, error)
	GetByContactLink(
		ctx context.Context,
		contactLink *commonv1.ContactLink,
		activeOnly bool,
	) ([]*models.RoomSubscription, error)
	GetMembersByRoomID(ctx context.Context, roomID string) ([]*commonv1.ContactLink, error)
	GetByRole(ctx context.Context, roomID, role string) ([]*models.RoomSubscription, error)
	UpdateRole(ctx context.Context, id, role string) error
	UpdateLastReadEventID(ctx context.Context, id string, eventID string) error
	Deactivate(ctx context.Context, id ...string) error
	// GetByIDsInRoom returns subscriptions matching the given IDs that also
	// belong to roomID. Used to validate that caller-supplied subscription IDs
	// actually belong to the room being operated on (cross-room IDOR guard).
	GetByIDsInRoom(ctx context.Context, roomID string, ids []string) ([]*models.RoomSubscription, error)
	// DeactivateInRoom blocks the given subscriptions, scoped to roomID so a
	// subscription belonging to another room can never be deactivated. Returns
	// the number of rows affected.
	DeactivateInRoom(ctx context.Context, roomID string, ids []string) (int64, error)
	// CountActiveOwners counts active subscriptions holding the owner role in a
	// room (role is a comma-separated list, so positional matches are included).
	CountActiveOwners(ctx context.Context, roomID string) (int64, error)
	Activate(ctx context.Context, id ...string) error
	CountActiveMembers(ctx context.Context, roomID string) (int64, error)
	HasPermission(ctx context.Context, roomID string, contactLink *commonv1.ContactLink, minRole string) (bool, error)
	IsActiveMember(ctx context.Context, roomID string, contactLink *commonv1.ContactLink) (bool, error)
	BulkCreate(ctx context.Context, subscriptions []*models.RoomSubscription) error
}

// RoomOutboxRepository defines the transactional-outbox data access surface.
type RoomOutboxRepository interface {
	datastore.BaseRepository[*models.RoomOutbox]
	// SaveEventsWithOutbox atomically persists events and their outbox rows in a
	// single transaction; returns the set of newly-inserted event IDs.
	SaveEventsWithOutbox(
		ctx context.Context,
		events []*models.RoomEvent,
		payloads map[string][]byte,
	) (map[string]bool, error)
	ListPending(ctx context.Context, olderThan time.Time, limit int) ([]*models.RoomOutbox, error)
	MarkDispatched(ctx context.Context, eventIDs []string) error
}

// ProposalRepository defines the interface for proposal data access operations.
// Proposals are generic and scoped by ScopeType + ScopeID, enabling reuse
// for any entity type that needs an approval/voting workflow.
type ProposalRepository interface {
	datastore.BaseRepository[*models.Proposal]
	GetPendingByScope(ctx context.Context, scopeType string, scopeID string) ([]*models.Proposal, error)
	UpdateState(ctx context.Context, id string, state models.ProposalState, resolvedBy string, reason string) error
	ExpirePending(ctx context.Context) (int64, error)
}

// RoomCallRepository defines the interface for room call data access operations.
type RoomCallRepository interface {
	datastore.BaseRepository[*models.RoomCall]
	GetByCallID(ctx context.Context, callID string) (*models.RoomCall, error)
	GetByRoomID(ctx context.Context, roomID string, limit int) ([]*models.RoomCall, error)
	GetActiveCallByRoomID(ctx context.Context, roomID string) (*models.RoomCall, error)
	GetByStatus(ctx context.Context, status string, limit int) ([]*models.RoomCall, error)
	UpdateStatus(ctx context.Context, id, status string) error
	UpdateSFUNode(ctx context.Context, id, sfuNodeID string) error
	EndCall(ctx context.Context, id string) error
	GetTimedOutCalls(ctx context.Context, timeout time.Duration) ([]*models.RoomCall, error)
	GetCallDuration(ctx context.Context, id string) (time.Duration, error)
	CountActiveCallsByRoomID(ctx context.Context, roomID string) (int64, error)
	GetCallsBySFUNode(ctx context.Context, sfuNodeID string) ([]*models.RoomCall, error)
}
