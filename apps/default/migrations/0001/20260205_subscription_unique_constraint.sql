-- Migration: Add unique constraint to prevent duplicate room subscriptions.
-- Uses a partial unique index that only applies to active/proposed subscriptions
-- (blocked subscriptions are excluded so a user can be re-added after removal).
CREATE UNIQUE INDEX IF NOT EXISTS idx_room_subscription_unique_active
  ON room_subscriptions (room_id, profile_id, contact_id)
  WHERE subscription_state IN (0, 1);
