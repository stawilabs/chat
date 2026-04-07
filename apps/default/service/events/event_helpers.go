package events

import chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"

// isEphemeralRoomEvent returns true for event types that are transient and
// should not be persisted to the replay log or trigger durable delivery.
func isEphemeralRoomEvent(eventType chatv1.RoomEventType) bool {
	//nolint:exhaustive // Only the explicitly ephemeral room event types should return true.
	switch eventType {
	case chatv1.RoomEventType_ROOM_EVENT_TYPE_TYPING,
		chatv1.RoomEventType_ROOM_EVENT_TYPE_DELIVERED,
		chatv1.RoomEventType_ROOM_EVENT_TYPE_READ:
		return true
	default:
		return false
	}
}
