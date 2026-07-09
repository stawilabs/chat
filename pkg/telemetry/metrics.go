// Package telemetry provides OpenTelemetry metrics and tracing for the chat service.
package telemetry

import "github.com/pitabwire/frame/v2/telemetry"

// Message metrics track message send/receive operations.
//
//nolint:gochecknoglobals // OpenTelemetry metrics must be global for instrumentation
var (
	MessagesSentCounter = telemetry.DimensionlessMeasure(
		"",
		"chat.messages.sent",
		"Total messages sent",
	)

	MessagesDeliveredCounter = telemetry.DimensionlessMeasure(
		"",
		"chat.messages.delivered",
		"Total messages delivered to recipients",
	)

	MessagesFailedCounter = telemetry.DimensionlessMeasure(
		"",
		"chat.messages.failed",
		"Total message delivery failures",
	)

	MessagesDeadLetteredCounter = telemetry.DimensionlessMeasure(
		"",
		"chat.messages.dead_lettered",
		"Total messages sent to dead letter queue",
	)
)

// Room metrics track room lifecycle events.
//
//nolint:gochecknoglobals // OpenTelemetry metrics must be global for instrumentation
var (
	RoomsCreatedCounter = telemetry.DimensionlessMeasure(
		"",
		"chat.rooms.created",
		"Total rooms created",
	)

	RoomsDeletedCounter = telemetry.DimensionlessMeasure(
		"",
		"chat.rooms.deleted",
		"Total rooms deleted",
	)
)

// Subscription metrics track member operations.
//
//nolint:gochecknoglobals // OpenTelemetry metrics must be global for instrumentation
var (
	SubscriptionsAddedCounter = telemetry.DimensionlessMeasure(
		"",
		"chat.subscriptions.added",
		"Total subscriptions added",
	)

	SubscriptionsRemovedCounter = telemetry.DimensionlessMeasure(
		"",
		"chat.subscriptions.removed",
		"Total subscriptions removed",
	)
)

// Delivery metrics track the delivery pipeline.
//
//nolint:gochecknoglobals // OpenTelemetry metrics must be global for instrumentation
var (
	OutboxEntriesCreatedCounter = telemetry.DimensionlessMeasure(
		"",
		"chat.outbox.created",
		"Total outbox entries created",
	)

	DeliveryQueueProcessedCounter = telemetry.DimensionlessMeasure(
		"",
		"chat.delivery.queue.processed",
		"Total delivery queue messages processed",
	)

	DeliveryQueueRetriedCounter = telemetry.DimensionlessMeasure(
		"",
		"chat.delivery.queue.retried",
		"Total delivery queue messages retried",
	)

	DeliverySkippedEmptyProfileCounter = telemetry.DimensionlessMeasure(
		"",
		"chat.delivery.skipped.empty_profile",
		"Total deliveries skipped due to empty profile ID",
	)

	DeliveryLatencyHistogram = telemetry.LatencyMeasure(
		"chat.delivery",
	)
)

// Notification metrics track push notification operations.
//
//nolint:gochecknoglobals // OpenTelemetry metrics must be global for instrumentation
var (
	NotificationsSentCounter = telemetry.DimensionlessMeasure(
		"",
		"chat.notifications.sent",
		"Total push notifications sent",
	)

	NotificationsFailedCounter = telemetry.DimensionlessMeasure(
		"",
		"chat.notifications.failed",
		"Total push notification failures",
	)
)

// EventFanoutCounter tracks event fanout operations.
//
//nolint:gochecknoglobals // OpenTelemetry metrics must be global for instrumentation
var EventFanoutCounter = telemetry.DimensionlessMeasure(
	"",
	"chat.events.fanout",
	"Total event fanout operations",
)

// DeadLetterConsumedCounter tracks messages consumed from the DLQ.
//
//nolint:gochecknoglobals // OpenTelemetry metrics must be global for instrumentation
var DeadLetterConsumedCounter = telemetry.DimensionlessMeasure(
	"",
	"chat.dlq.consumed",
	"Total dead-lettered messages consumed",
)

// Device replay metrics track the replay API used by the gateway for reconnection catch-up.
//
//nolint:gochecknoglobals // OpenTelemetry metrics must be global for instrumentation
var (
	ReplayCursorResolvedCounter = telemetry.DimensionlessMeasure(
		"",
		"chat.replay.cursor.resolved",
		"Total replay cursor resolution requests",
	)

	ReplayEventsListedCounter = telemetry.DimensionlessMeasure(
		"",
		"chat.replay.events.listed",
		"Total replay event list requests",
	)

	ReplayLatencyHistogram = telemetry.LatencyMeasure(
		"chat.replay",
	)
)
