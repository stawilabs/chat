package business

import (
	"context"
	"fmt"
	"strings"
	"time"

	"connectrpc.com/connect/v2"
	"github.com/pitabwire/frame/v3/data"

	"github.com/stawilabs/chat/apps/default/service/events"
	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/service/socialtrader"
)

// socialTraderRooms binds chat rooms to strategy pools. A room's metadata
// (socialtrader.pool_id) is only the client's request and display hint: the
// binding chat trusts is the row this writes, after the socialtrader service
// confirmed the pool and that the caller's linked wallet is its leader.
type socialTraderRooms struct {
	pools    socialtrader.Pools
	links    socialtrader.WalletLinks
	bindings repository.SocialTraderRoomRepository
	now      func() time.Time
}

// WithSocialTrader enables trading groups: a room whose metadata names a pool
// is bound only when pools and links confirm the caller leads it. With a nil
// pools or links (no SOCIALTRADER_SERVICE_URI) every binding is refused, while
// bindings is still read to recognise rooms bound earlier.
func WithSocialTrader(
	pools socialtrader.Pools, links socialtrader.WalletLinks, bindings repository.SocialTraderRoomRepository,
) RoomBusinessOption {
	return func(rb *roomBusiness) {
		rb.socialtrader = &socialTraderRooms{pools: pools, links: links, bindings: bindings, now: time.Now}
	}
}

// errSocialTraderNotConfigured refuses a binding when chat has no socialtrader
// client: nothing can confirm the pool or its leader.
var errSocialTraderNotConfigured = connect.NewError(connect.CodeFailedPrecondition,
	"trading groups are not enabled: the socialtrader service is not configured")

// requestedPoolBinding returns the pool a metadata change asks to bind the
// room to (flat socialtrader.pool_id or nested socialtrader.pool_id), or ""
// when it asks none.
func requestedPoolBinding(metadata map[string]any) string {
	if metadata == nil {
		return ""
	}
	if value, ok := metadata[events.SocialTraderPoolMetadataKey].(string); ok && value != "" {
		return value
	}
	if nested, ok := metadata["socialtrader"].(map[string]any); ok {
		value, _ := nested["pool_id"].(string)
		return value
	}
	return ""
}

// touchesStawiMetadata reports whether a metadata change writes the Stawi
// module's keys (stawi.* or a nested stawi object).
func touchesStawiMetadata(metadata map[string]any) bool {
	for key := range metadata {
		if key == "stawi" || strings.HasPrefix(key, "stawi.") {
			return true
		}
	}
	return false
}

// ValidateBinding decides whether caller may bind roomID to poolID: the pool
// must exist, must not have been created for another room, and its leader
// must be the caller's linked wallet. It returns the pool with its address
// normalised.
func (s *socialTraderRooms) ValidateBinding(
	ctx context.Context, callerProfileID, roomID, poolID string,
) (*socialtrader.Pool, error) {
	if s == nil || s.pools == nil || s.links == nil {
		return nil, errSocialTraderNotConfigured
	}
	address, ok := socialtrader.NormalizeAddress(poolID)
	if !ok {
		return nil, connect.NewError(connect.CodeInvalidArgument,
			"socialtrader.pool_id must be a pool address (0x followed by 40 hex digits)")
	}
	pool, err := s.pools.GetPool(ctx, address)
	if err != nil {
		if connect.CodeOf(err) == connect.CodeNotFound {
			return nil, connect.NewError(connect.CodeNotFound, "the pool is not known to the socialtrader service")
		}
		return nil, connect.NewError(connect.CodeUnavailable,
			fmt.Errorf("the socialtrader service could not answer for the pool: %w", err).Error())
	}
	if pool.RoomRef != "" && pool.RoomRef != roomID {
		return nil, connect.NewError(connect.CodePermissionDenied, "the pool was created for another room")
	}
	wallet, err := s.links.GetLinkedWallet(ctx, callerProfileID)
	if err != nil {
		return nil, connect.NewError(connect.CodeUnavailable,
			fmt.Errorf("the socialtrader service could not answer for the caller's wallet: %w", err).Error())
	}
	if wallet == "" || !strings.EqualFold(wallet, pool.Leader) {
		return nil, connect.NewError(connect.CodePermissionDenied,
			"only the pool leader can bind a room to this pool")
	}
	pool.Address = address
	return pool, nil
}

// record writes the binding of roomID to pool by leaderProfileID.
func (s *socialTraderRooms) record(
	ctx context.Context,
	roomID string,
	pool *socialtrader.Pool,
	leaderProfileID string,
) error {
	binding := &models.SocialTraderRoomBinding{
		RoomID:          roomID,
		PoolID:          pool.Address,
		LeaderProfileID: leaderProfileID,
		BoundAt:         s.now().UTC(),
	}
	if err := s.bindings.Upsert(ctx, binding); err != nil {
		return fmt.Errorf("failed to record the pool binding: %w", err)
	}
	return nil
}

// prepareSocialTraderBinding validates a metadata change that asks to bind
// the room to a pool and returns the pool to record once the room is saved;
// nil when the change asks no binding. It never consults room metadata as
// truth: a key present without a validated binding is refused.
func (rb *roomBusiness) prepareSocialTraderBinding(
	ctx context.Context, callerProfileID, roomID string, metadata map[string]any,
) (*socialtrader.Pool, error) {
	poolID := requestedPoolBinding(metadata)
	if poolID == "" {
		return nil, nil //nolint:nilnil // no binding requested
	}
	if rb.socialtrader == nil {
		return nil, errSocialTraderNotConfigured
	}
	return rb.socialtrader.ValidateBinding(ctx, callerProfileID, roomID, poolID)
}

// recordSocialTraderBinding writes the binding prepared for a saved room.
func (rb *roomBusiness) recordSocialTraderBinding(
	ctx context.Context, roomID string, pool *socialtrader.Pool, leaderProfileID string,
) error {
	if pool == nil {
		return nil
	}
	return rb.socialtrader.record(ctx, roomID, pool, leaderProfileID)
}

// refuseStawiMetadataOnStawiRoom refuses a metadata change writing stawi.*
// keys on a room the Stawi flow owns (its genesis prepared or bound): those
// keys describe that flow and are not the room admin's to rewrite. A plain
// room's stawi.group_id hint stays the client's to set, as before.
func (rb *roomBusiness) refuseStawiMetadataOnStawiRoom(
	ctx context.Context,
	roomID string,
	metadata map[string]any,
) error {
	if rb.stawiBindings == nil || !touchesStawiMetadata(metadata) {
		return nil
	}
	_, err := rb.stawiBindings.GetByID(ctx, roomID)
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return nil
		}
		return fmt.Errorf("failed to check the room's Stawi binding: %w", err)
	}
	return connect.NewError(connect.CodePermissionDenied,
		"stawi metadata of a Stawi room is owned by the Stawi flow and cannot be changed here")
}
