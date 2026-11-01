package business

import (
	"context"
	"errors"
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

// requestedPoolBinding reads what a metadata change asks about the room's
// pool binding. The second result is false when it says nothing; otherwise
// the first is the pool to bind (flat socialtrader.pool_id or nested
// socialtrader.pool_id) or "" when the key is cleared, which asks to unbind.
func requestedPoolBinding(metadata map[string]any) (string, bool) {
	if metadata == nil {
		return "", false
	}
	if raw, ok := metadata[events.SocialTraderPoolMetadataKey]; ok {
		value, _ := raw.(string)
		return value, true
	}
	if nested, isMap := metadata["socialtrader"].(map[string]any); isMap {
		if raw, ok := nested["pool_id"]; ok {
			value, _ := raw.(string)
			return value, true
		}
	}
	return "", false
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
	existing, err := s.bindings.GetByRoomID(ctx, roomID)
	if err != nil {
		return nil, fmt.Errorf("failed to read the room's pool binding: %w", err)
	}
	if existing != nil && existing.LeaderProfileID != callerProfileID {
		return nil, errBindingOwnedByAnother
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
		if errors.Is(err, repository.ErrBindingOwnedByAnother) {
			return errBindingOwnedByAnother
		}
		return fmt.Errorf("failed to record the pool binding: %w", err)
	}
	return nil
}

// errBindingOwnedByAnother refuses a change to a binding another leader holds;
// the repository enforces it in the write, so a race cannot slip past the
// read in ValidateBinding.
var errBindingOwnedByAnother = connect.NewError(connect.CodePermissionDenied,
	"the room is bound by another leader; only they can change its pool")

// bindingChange is what a validated metadata change does to the room's pool
// binding once the room is saved: bind to pool, or unbind.
type bindingChange struct {
	pool   *socialtrader.Pool
	unbind bool
}

// prepareSocialTraderBinding validates a metadata change that asks to bind
// the room to a pool (or to unbind it, by clearing the key) and returns what
// to record once the room is saved; nil when the change says nothing about
// the binding. It never consults room metadata as truth: a key present
// without a validated binding is refused, and only the bound leader unbinds.
func (rb *roomBusiness) prepareSocialTraderBinding(
	ctx context.Context, callerProfileID, roomID string, metadata map[string]any,
) (*bindingChange, error) {
	poolID, present := requestedPoolBinding(metadata)
	if !present {
		return nil, nil //nolint:nilnil // the change says nothing about the binding
	}
	if rb.socialtrader == nil {
		return nil, errSocialTraderNotConfigured
	}
	if poolID == "" {
		if err := rb.socialtrader.validateUnbind(ctx, callerProfileID, roomID); err != nil {
			return nil, err
		}
		return &bindingChange{unbind: true}, nil
	}
	pool, err := rb.socialtrader.ValidateBinding(ctx, callerProfileID, roomID, poolID)
	if err != nil {
		return nil, err
	}
	return &bindingChange{pool: pool}, nil
}

// validateUnbind decides whether caller may clear the room's binding: only
// the leader who bound it. A room with no binding has nothing to clear.
func (s *socialTraderRooms) validateUnbind(ctx context.Context, callerProfileID, roomID string) error {
	existing, err := s.bindings.GetByRoomID(ctx, roomID)
	if err != nil {
		return fmt.Errorf("failed to read the room's pool binding: %w", err)
	}
	if existing != nil && existing.LeaderProfileID != callerProfileID {
		return connect.NewError(connect.CodePermissionDenied,
			"only the leader who bound the room can unbind it")
	}
	return nil
}

// recordSocialTraderBinding applies a prepared binding change for a saved
// room: writes the binding row or deletes it.
func (rb *roomBusiness) recordSocialTraderBinding(
	ctx context.Context, roomID string, change *bindingChange, leaderProfileID string,
) error {
	switch {
	case change == nil:
		return nil
	case change.unbind:
		if err := rb.socialtrader.bindings.DeleteByRoomID(ctx, roomID, leaderProfileID); err != nil {
			if errors.Is(err, repository.ErrBindingOwnedByAnother) {
				return errBindingOwnedByAnother
			}
			return fmt.Errorf("failed to remove the pool binding: %w", err)
		}
		return nil
	default:
		return rb.socialtrader.record(ctx, roomID, change.pool, leaderProfileID)
	}
}

// clearPoolHint removes the pool metadata hint from a room that was unbound.
func clearPoolHint(properties map[string]any) {
	delete(properties, events.SocialTraderPoolMetadataKey)
	if nested, ok := properties["socialtrader"].(map[string]any); ok {
		delete(nested, "pool_id")
		if len(nested) == 0 {
			delete(properties, "socialtrader")
		}
	}
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
