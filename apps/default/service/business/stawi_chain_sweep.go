package business

import (
	"context"
	"strings"
	"time"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"github.com/pitabwire/util"
	"gorm.io/gorm"

	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/stawi"
	"github.com/stawilabs/chat/pkg/chatutil"
	chattel "github.com/stawilabs/chat/pkg/telemetry"
)

// Run is the chain consumer's background loop: every interval one replica
// (the holder of the sweep lease) sweeps.
func (c *StawiChain) Run(ctx context.Context, interval time.Duration) error {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return nil
		case <-ticker.C:
			c.Sweep(ctx)
		}
	}
}

// Sweep runs one pass on the replica that holds the sweep lease; others skip.
func (c *StawiChain) Sweep(ctx context.Context) {
	if _, err := c.deps.Store.TryLease(ctx, "sweep", c.sweep); err != nil {
		util.Log(ctx).WithError(err).Warn("stawi chain: sweep lease unavailable")
	}
}

// sweep places facts recorded while their room was being bound, applies
// waiting facts (least recently attempted rooms first), retries pending Keto
// writes, reconciles a bounded, rotating share of bound rooms, settles stale
// calls and prunes applied facts past retention.
func (c *StawiChain) sweep(ctx context.Context) {
	logger := util.Log(ctx)
	if _, err := c.deps.Store.AssignBoundEmitters(ctx); err != nil {
		logger.WithError(err).Warn("stawi chain: could not place waiting facts")
	}
	rooms, err := c.deps.Store.RoomsWithPending(ctx, sweepBatch)
	if err != nil {
		logger.WithError(err).Warn("stawi chain: could not list rooms with waiting facts")
	}
	for _, roomID := range rooms {
		if applyErr := c.ApplyRoom(ctx, roomID); applyErr != nil {
			logger.WithError(applyErr).WithField(chatutil.KeyRoomID, roomID).
				Warn("stawi chain: waiting facts not applied; retrying next sweep")
		}
	}
	if err = c.drainKeto(ctx, ""); err != nil {
		logger.WithError(err).Warn("stawi chain: Keto writes still pending")
	}
	if _, err = c.Reconcile(ctx); err != nil {
		logger.WithError(err).Warn("stawi reconciler: pass failed")
	}
	if c.deps.FactRetention > 0 {
		if _, err = c.deps.Store.PruneApplied(ctx, time.Now().Add(-c.deps.FactRetention)); err != nil {
			logger.WithError(err).Warn("stawi chain: could not prune applied facts")
		}
	}
}

// Reconcile compares a bounded, rotating share of bound rooms
// (ReconcileRoomsPerPass, continuing where the last pass stopped) with the
// chain's membership as chat folded it, repairs subscriptions and Keto tuples
// and emits room.subscription_drift for each repaired room. It also asks
// settlement about relayed calls whose outcome never arrived, the least
// recently checked first.
func (c *StawiChain) Reconcile(ctx context.Context) (ReconcileReport, error) {
	var report ReconcileReport
	c.mu.Lock()
	after := c.reconcileCursor
	c.mu.Unlock()

	rooms, err := c.deps.Bindings.ListBound(ctx, after, c.deps.ReconcileRoomsPerPass)
	if err != nil {
		return report, err
	}
	next := ""
	if len(rooms) == c.deps.ReconcileRoomsPerPass {
		next = rooms[len(rooms)-1].GetID()
	}
	c.mu.Lock()
	c.reconcileCursor = next
	c.mu.Unlock()

	for _, binding := range rooms {
		drift, roomErr := c.reconcileRoom(ctx, binding.GetID())
		if roomErr != nil {
			util.Log(ctx).WithError(roomErr).WithField(chatutil.KeyRoomID, binding.GetID()).
				Warn("stawi reconciler: room not reconciled; retrying next pass")
			continue
		}
		report.Rooms++
		report.Repaired += drift.Total()
	}
	resolved, err := c.settleStaleCalls(ctx)
	report.CallsResolved = resolved
	return report, err
}

// ketoCheck is a subscription whose Keto tuples the reconciler verifies
// after the room's lock is released.
type ketoCheck struct {
	profileID      string
	subscriptionID string
	want           desiredSubscription
}

func (c *StawiChain) reconcileRoom(ctx context.Context, roomID string) (StawiDrift, error) {
	drift := StawiDrift{RoomID: roomID, At: time.Now()}
	room, err := c.deps.RoomRepo.GetByID(ctx, roomID)
	if err != nil {
		return drift, err
	}
	profiles, err := c.resolveUnownedMembers(ctx, roomID)
	if err != nil {
		return drift, err
	}
	var checks []ketoCheck
	err = c.deps.Store.WithRoomLock(ctx, roomID, func(tx *gorm.DB) error {
		var lockedErr error
		checks, lockedErr = c.reconcileLocked(ctx, tx, room, profiles, &drift)
		return lockedErr
	})
	if err != nil {
		return drift, err
	}
	if c.afterReconcileLock != nil {
		c.afterReconcileLock()
	}
	if err = c.repairKeto(ctx, room, checks, &drift); err != nil {
		return drift, err
	}
	if drift.Total() == 0 {
		return drift, nil
	}
	chattel.StawiDriftRepairedCounter.Add(ctx, int64(drift.Total()))
	if c.deps.Drift != nil {
		if pubErr := c.deps.Drift.PublishDrift(ctx, drift); pubErr != nil {
			util.Log(ctx).WithError(pubErr).WithField(chatutil.KeyRoomID, roomID).
				Warn("stawi reconciler: failed to publish room.subscription_drift")
		}
	}
	return drift, nil
}

// resolveUnownedMembers looks up, outside the room's lock, the addresses of
// member rows that have no profile yet.
func (c *StawiChain) resolveUnownedMembers(ctx context.Context, roomID string) (map[string]string, error) {
	members, err := c.deps.Store.Members(ctx, roomID)
	if err != nil {
		return nil, err
	}
	wanted := map[string]bool{}
	for _, member := range members {
		if member.ProfileID == "" {
			wanted[member.Address] = true
		}
	}
	return c.resolveAddresses(ctx, roomID, wanted)
}

// reconcileLocked repairs the room's subscription rows under its lock and
// returns the Keto checks to run once the lock is released.
func (c *StawiChain) reconcileLocked(
	ctx context.Context, tx *gorm.DB, room *models.Room, profiles map[string]string, drift *StawiDrift,
) ([]ketoCheck, error) {
	var rows []*models.StawiRoomMember
	if err := tx.Where("room_id = ?", room.GetID()).Order("address ASC").Find(&rows).Error; err != nil {
		return nil, err
	}
	byProfile := map[string]bool{}
	for _, member := range rows {
		if member.ProfileID == "" && profiles[member.Address] != "" {
			member.ProfileID = profiles[member.Address]
			if err := c.deps.Store.SaveMember(tx, member); err != nil {
				return nil, err
			}
		}
		if member.ProfileID != "" {
			byProfile[member.ProfileID] = true
		}
	}
	var checks []ketoCheck
	expected := map[string]bool{}
	for profileID := range byProfile {
		check, keep, err := c.reconcileProfile(ctx, tx, room, profileID, drift)
		if err != nil {
			return nil, err
		}
		if keep != "" {
			expected[keep] = true
		}
		if check != nil {
			checks = append(checks, *check)
		}
	}
	return checks, c.removeStrays(tx, room, expected, drift)
}

// repairKeto verifies, outside the lock, that each subscription holds exactly
// its role's tuples. A repair is decided again under the room's lock from the
// rows as they are then: the membership may have changed since the check (an
// exit whose removal is pending), and a repair must never replace a newer op.
func (c *StawiChain) repairKeto(ctx context.Context, room *models.Room, checks []ketoCheck, drift *StawiDrift) error {
	for _, check := range checks {
		if c.ketoHolds(ctx, room.GetID(), check.subscriptionID, check.want) {
			continue
		}
		repaired := false
		err := c.deps.Store.WithRoomLock(ctx, room.GetID(), func(tx *gorm.DB) error {
			members, err := c.deps.Store.ProfileMembers(tx, room.GetID(), check.profileID)
			if err != nil {
				return err
			}
			want := desiredForProfile(members)
			sub, err := currentProfileSubscription(tx, room.GetID(), check.profileID, members)
			if err != nil || sub == nil || sub.GetID() != check.subscriptionID || !want.matches(sub) ||
				want.ketoRole() != check.want.ketoRole() {
				return err // the row moved on since the check; its own op stands
			}
			repaired = true
			return c.deps.Store.EnqueueKeto(tx, room, sub.GetID(), want.ketoRole())
		})
		if err != nil {
			return err
		}
		if repaired {
			drift.PermissionsRepaired++
		}
	}
	if err := c.drainKeto(ctx, room.GetID()); err != nil {
		util.Log(ctx).WithError(err).WithField(chatutil.KeyRoomID, room.GetID()).
			Warn("stawi reconciler: Keto repairs pending")
	}
	return nil
}

// reconcileProfile repairs one profile's subscription row from its member
// rows. It returns the Keto check to run after the lock, and the
// subscription the chain accounts for (empty if none).
func (c *StawiChain) reconcileProfile(
	ctx context.Context, tx *gorm.DB, room *models.Room, profileID string, drift *StawiDrift,
) (*ketoCheck, string, error) {
	members, err := c.deps.Store.ProfileMembers(tx, room.GetID(), profileID)
	if err != nil {
		return nil, "", err
	}
	want := desiredForProfile(members)
	sub, err := currentProfileSubscription(tx, room.GetID(), profileID, members)
	if err != nil {
		return nil, "", err
	}
	linked := sub == nil
	if sub != nil {
		linked = true
		for _, member := range members {
			if member.SubscriptionID != sub.GetID() {
				linked = false
			}
		}
	}
	if !want.matches(sub) || !linked {
		wasMissing := sub == nil || sub.SubscriptionState == models.RoomSubscriptionStateBlocked
		if _, err = c.writeProfileSubscription(ctx, tx, room, profileID); err != nil {
			return nil, "", err
		}
		switch {
		case !want.matches(sub) && want.present && wasMissing:
			drift.Restored++
		case !want.matches(sub):
			drift.RolesFixed++
		}
		if sub, err = currentProfileSubscription(tx, room.GetID(), profileID, nil); err != nil {
			return nil, "", err
		}
	}
	if !want.present || sub == nil {
		return nil, "", nil
	}
	return &ketoCheck{profileID: profileID, subscriptionID: sub.GetID(), want: want}, sub.GetID(), nil
}

// removeStrays blocks live subscriptions the chain's membership does not
// account for, and records the Keto removal.
func (c *StawiChain) removeStrays(tx *gorm.DB, room *models.Room, expected map[string]bool, drift *StawiDrift) error {
	var live []*models.RoomSubscription
	if err := tx.Where("room_id = ? AND subscription_state IN ?", room.GetID(),
		[]models.RoomSubscriptionState{models.RoomSubscriptionStateActive, models.RoomSubscriptionStateProposed}).
		Order("id ASC").Find(&live).Error; err != nil {
		return err
	}
	for _, sub := range live {
		if expected[sub.GetID()] {
			continue
		}
		if err := setSubscription(tx, sub.GetID(), models.RoomSubscriptionStateBlocked, sub.Role); err != nil {
			return err
		}
		if err := c.deps.Store.EnqueueKeto(tx, room, sub.GetID(), ""); err != nil {
			return err
		}
		drift.Removed++
	}
	return nil
}

// settleStaleCalls asks settlement about relayed calls still waiting for an
// outcome and reports the ones settlement has settled.
func (c *StawiChain) settleStaleCalls(ctx context.Context) (int, error) {
	if c.deps.Rooms == nil {
		return 0, nil
	}
	calls, err := c.deps.Calls.ListSubmittedBefore(ctx, time.Now().Add(-c.deps.StaleCallAfter), sweepBatch)
	if err != nil {
		return 0, err
	}
	resolved := 0
	for _, tracked := range calls {
		call, getErr := c.deps.Rooms.GetRoomCall(ctx, tracked.GetID())
		if markErr := c.deps.Calls.MarkChecked(ctx, tracked.GetID()); markErr != nil {
			util.Log(ctx).WithError(markErr).Warn("stawi reconciler: could not record the call check")
		}
		if getErr != nil {
			continue
		}
		// Settle only from settlement's record of this very call: same id,
		// same room, same signer and nonce as chat relayed.
		if call.CallID != tracked.GetID() || call.RoomID != tracked.RoomID ||
			!strings.EqualFold(call.SignerAddress, tracked.SignerAddress) || call.Nonce != tracked.Nonce {
			util.Log(ctx).WithField("call_id", tracked.GetID()).
				Error("stawi reconciler: settlement's call record does not match the relayed call")
			continue
		}
		var state chatv1.StawiCallOutcomeState
		var callState string
		switch call.State {
		case stawi.CallStateFinal:
			state, callState = chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_OBSERVED, models.StawiCallStateObserved
		case stawi.CallStateFailed:
			state, callState = chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_FAILED, models.StawiCallStateFailed
		case stawi.CallStateUnspecified, stawi.CallStatePrepared, stawi.CallStateSubmitted:
			continue
		}
		room, roomErr := c.deps.RoomRepo.GetByID(ctx, tracked.RoomID)
		if roomErr != nil {
			continue
		}
		lockErr := c.deps.Store.WithRoomLock(ctx, tracked.RoomID, func(tx *gorm.DB) error {
			res := tx.Table("stawi_room_calls").Where("id = ? AND state = ?", tracked.GetID(),
				models.StawiCallStateSubmitted).Updates(map[string]any{colStawiState: callState})
			if res.Error != nil || res.RowsAffected == 0 {
				return res.Error
			}
			return c.postEvent(ctx, tx, room, util.IDString(), tracked.SourceEventID, outcomePayload(
				&chatv1.StawiCallOutcomeContent{
					CallId: tracked.GetID(), State: state, Reason: truncateReason(call.Reason),
					SourceEventId: tracked.SourceEventID, Kind: tracked.Kind, TxHash: call.TxHash,
				}))
		})
		if lockErr == nil {
			resolved++
		}
	}
	return resolved, nil
}
