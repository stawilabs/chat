-- Copyright 2023-2026 Ant Investor Ltd
--
-- Licensed under the Apache License, Version 2.0 (the "License").
--
-- Forward-only repair + dedup-safety for unique indexes.
--
-- 1. idx_room_subscription_unique_active was previously created as a FULL unique
--    index by a GORM `uniqueIndex` struct tag (AutoMigrate runs before SQL
--    migrations), which shadowed the PARTIAL index intended by 20260205 and made
--    it impossible to re-add a blocked member. The struct tag has been removed;
--    here we drop whatever index exists, deduplicate any offending active rows,
--    and (re)create the correct partial index.
-- 2. The device_replay unique index is also (re)created after a dedup pass so the
--    migration cannot fail on pre-existing duplicate rows.
--
-- Indexes here are created non-concurrently (the migrator runs each patch in a
-- transaction). Both target tables are small relative to room_events, so the
-- brief lock is acceptable.

-- ---------------------------------------------------------------------------
-- Room subscriptions: enforce the partial unique index correctly.
-- ---------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_room_subscription_unique_active;

-- Block all but the most recent active/proposed row per identity tuple so the
-- unique index can be created without violation.
WITH ranked AS (
    SELECT id,
           ROW_NUMBER() OVER (
               PARTITION BY room_id, profile_id, contact_id
               ORDER BY created_at DESC, id DESC
           ) AS rn
    FROM room_subscriptions
    WHERE subscription_state IN (0, 1)
)
UPDATE room_subscriptions
SET subscription_state = 2
WHERE id IN (SELECT id FROM ranked WHERE rn > 1);

CREATE UNIQUE INDEX IF NOT EXISTS idx_room_subscription_unique_active
    ON room_subscriptions (room_id, profile_id, contact_id)
    WHERE subscription_state IN (0, 1);

-- ---------------------------------------------------------------------------
-- Device replay: ensure the per-event unique index cannot fail on duplicates.
-- ---------------------------------------------------------------------------
DROP INDEX IF EXISTS idx_device_replay_profile_device_event;

WITH ranked AS (
    SELECT id,
           ROW_NUMBER() OVER (
               PARTITION BY profile_id, device_id, event_id
               ORDER BY id DESC
           ) AS rn
    FROM device_replay_events
)
DELETE FROM device_replay_events
WHERE id IN (SELECT id FROM ranked WHERE rn > 1);

CREATE UNIQUE INDEX IF NOT EXISTS idx_device_replay_profile_device_event
    ON device_replay_events (profile_id, device_id, event_id);
