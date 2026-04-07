-- Scalability indexes: addresses missing indexes identified in production audit.

-- 1. room_events: composite index for history pagination (replaces single-column idx_room_id)
--    Covers: GetHistory, GetByRoomID, CountByRoomID
DROP INDEX IF EXISTS idx_room_id;
CREATE INDEX IF NOT EXISTS idx_room_event_room_id_id ON room_events (room_id, id DESC) WHERE deleted_at IS NULL;

-- 2. room_calls: basic indexes (table previously had zero indexes on queried columns)
--    Covers: GetByCallID, GetActiveCallByRoomID, CountActiveCallsByRoomID, GetByStatus,
--            GetTimedOutCalls, GetCallsBySFUNode, GetByRoomID
CREATE UNIQUE INDEX IF NOT EXISTS idx_call_call_id ON room_calls (call_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_call_room_status ON room_calls (room_id, status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_call_sfu_status ON room_calls (sfu_node_id, status) WHERE deleted_at IS NULL;

-- 3. room_subscriptions: standalone profile_id and contact_id lookups
--    Covers: GetByContactLink (used by GetSubscribedRoomIDs → SearchRooms)
CREATE INDEX IF NOT EXISTS idx_room_sub_profile_id ON room_subscriptions (profile_id, subscription_state) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_room_sub_contact_id ON room_subscriptions (contact_id, subscription_state) WHERE deleted_at IS NULL;

-- 4. rooms: description trigram index for ILIKE search
--    Covers: SearchRooms with query on description
CREATE INDEX IF NOT EXISTS idx_room_description_trgm ON rooms USING GIN (description gin_trgm_ops);

-- 5. device_replay_events: age-based trim index
--    Covers: TrimDevice cutoff query (WHERE profile_id = ? AND device_id = ? AND created_at < ?)
CREATE INDEX IF NOT EXISTS idx_replay_device_created ON device_replay_events (profile_id, device_id, created_at) WHERE deleted_at IS NULL;
