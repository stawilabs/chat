package chatutil

const (
	HeaderPriority     = "priority"
	HeaderProfileID    = "profile_id"
	HeaderDeviceID     = "device_id"
	HeaderShardID      = "shard_id"
	HeaderReplayCursor = "replay_cursor"

	// HeaderRetryAfter is the header key for retry-after timestamp (Unix millis) used for backoff.
	HeaderRetryAfter = "retry_after"

	// HeaderDLQOriginalQueue is the header key for the original queue name in dead-letter messages.
	HeaderDLQOriginalQueue = "dlq_original_queue"
	// HeaderDLQErrorMessage is the header key for the error message in dead-letter messages.
	HeaderDLQErrorMessage = "dlq_error_message"

	KeyRoomID         = "room_id"
	KeyProfileID      = "profile_id"
	KeySubscriptionID = "subscription_id"
	KeyOriginalQueue  = "original_queue"
	KeyEventID        = "event_id"
)
