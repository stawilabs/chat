-- Migration: Add durable per-device replay storage for scalable gateway resume.
CREATE INDEX IF NOT EXISTS idx_device_replay_lookup
  ON device_replay_events (profile_id, device_id, id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_device_replay_profile_device_event
  ON device_replay_events (profile_id, device_id, event_id);
