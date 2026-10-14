//nolint:golines // Env-tagged config structs intentionally keep long single-line struct tags.
package config

import (
	"errors"
	"fmt"
	"strings"

	"github.com/pitabwire/frame/v3/config"
)

type ChatConfig struct {
	config.ConfigurationDefault

	DeviceServiceURI                         string `envDefault:"127.0.0.1:7020" env:"DEVICE_SERVICE_URI"`
	NotificationServiceURI                   string `envDefault:"127.0.0.1:7020" env:"NOTIFICATION_SERVICE_URI"`
	ProfileServiceURI                        string `envDefault:"127.0.0.1:7003" env:"PROFILE_SERVICE_URI"`
	TenancyServiceURI                        string `envDefault:"127.0.0.1:7003" env:"TENANCY_SERVICE_URI"`
	DeviceServiceWorkloadAPITargetPath       string `envDefault:"/ns/profile/sa/service-devices" env:"DEVICE_SERVICE_WORKLOAD_API_TARGET_PATH"`
	NotificationServiceWorkloadAPITargetPath string `envDefault:"/ns/notifications/sa/service-notification" env:"NOTIFICATION_SERVICE_WORKLOAD_API_TARGET_PATH"`
	ProfileServiceWorkloadAPITargetPath      string `envDefault:"/ns/profile/sa/service-profile" env:"PROFILE_SERVICE_WORKLOAD_API_TARGET_PATH"`
	TenancyServiceWorkloadAPITargetPath      string `envDefault:"/ns/auth/sa/service-tenancy" env:"TENANCY_SERVICE_WORKLOAD_API_TARGET_PATH"`

	// Settlement is Stawi's one chain writer: chat relays room acts to its
	// RoomService. Empty disables Stawi room acts (development).
	SettlementServiceURI                   string `envDefault:"" env:"SETTLEMENT_SERVICE_URI"`
	SettlementServiceWorkloadAPITargetPath string `envDefault:"/ns/stawi/sa/service-settlement" env:"SETTLEMENT_SERVICE_WORKLOAD_API_TARGET_PATH"`

	// Settlement's chain facts (finance.v1 events on svc.stawi.settlement.events)
	// that chat's chain consumer applies to Stawi rooms.
	QueueStawiFactsName string `envDefault:"stawi.settlement.facts"       env:"QUEUE_STAWI_FACTS_NAME"`
	QueueStawiFactsURI  string `envDefault:"mem://stawi.settlement.facts" env:"QUEUE_STAWI_FACTS_URI"`
	// room.subscription_drift reports from the reconciler; an empty name disables publishing.
	QueueStawiDriftName           string `envDefault:"chat.room.subscription_drift"       env:"QUEUE_STAWI_DRIFT_NAME"`
	QueueStawiDriftURI            string `envDefault:"mem://chat.room.subscription_drift" env:"QUEUE_STAWI_DRIFT_URI"`
	StawiReconcileIntervalSeconds int    `envDefault:"300"                                env:"STAWI_RECONCILE_INTERVAL_SECONDS"`

	// SystemAccessID must be supplied per-environment via STATIC_SYSTEM_ACCESS_ID.
	// No default is baked in: a hardcoded, source-visible system access identifier
	// would be a predictable, attacker-guessable privileged principal if shipped.
	SystemAccessID string `env:"STATIC_SYSTEM_ACCESS_ID"`

	QueueDeviceEventDeliveryName string `envDefault:"device.event.delivery"       env:"QUEUE_DEVICE_EVENT_DELIVERY_NAME"`
	QueueDeviceEventDeliveryURI  string `envDefault:"mem://device.event.delivery" env:"QUEUE_DEVICE_EVENT_DELIVERY_URI"`

	QueueOfflineEventDeliveryName string `envDefault:"offline.event.delivery"              env:"QUEUE_OFFLINE_EVENT_DELIVERY_NAME"`
	QueueOfflineEventDeliveryURI  string `envDefault:"mem://offline.device.event.delivery" env:"QUEUE_OFFLINE_EVENT_DELIVERY_URI"`

	QueueGatewayEventDeliveryName string   `envDefault:"gateway.event.delivery.%d"                env:"QUEUE_GATEWAY_EVENT_DELIVERY_NAME"`
	QueueGatewayEventDeliveryURI  []string `envDefault:"mem://gateway.event.delivery.0" env:"QUEUE_GATEWAY_EVENT_DELIVERY_URI"`

	ShardCount int `envDefault:"1" env:"SHARD_COUNT"`

	// Durable room-fact stream (chat.room.event.published). Published only for
	// rooms whose metadata carries the group key; an empty name disables it.
	QueueRoomEventPublishedName string `envDefault:"chat.room.event.published"       env:"QUEUE_ROOM_EVENT_PUBLISHED_NAME"`
	QueueRoomEventPublishedURI  string `envDefault:"mem://chat.room.event.published" env:"QUEUE_ROOM_EVENT_PUBLISHED_URI"`

	// Dead-letter queue for deliveries that exceed max retries
	QueueDeadLetterName            string `envDefault:"dead.letter.queue"       env:"QUEUE_DEAD_LETTER_NAME"`
	QueueDeadLetterURI             string `envDefault:"mem://dead.letter.queue" env:"QUEUE_DEAD_LETTER_URI"`
	MaxDeliveryRetries             int    `envDefault:"5"                       env:"MAX_DELIVERY_RETRIES"`
	DeviceSearchPageSize           int    `envDefault:"100"                     env:"DEVICE_SEARCH_PAGE_SIZE"`
	ProfileDeviceCacheTTLSeconds   int    `envDefault:"5" env:"PROFILE_DEVICE_CACHE_TTL_SECONDS"`
	ProfileDeviceCacheMaxEntries   int    `envDefault:"512" env:"PROFILE_DEVICE_CACHE_MAX_ENTRIES"`
	DeviceReplayMaxEventsPerDevice int    `envDefault:"1000" env:"DEVICE_REPLAY_MAX_EVENTS_PER_DEVICE"`
	DeviceReplayRetentionHours     int    `envDefault:"168" env:"DEVICE_REPLAY_RETENTION_HOURS"`
	CallDirectMaxParticipants      int    `envDefault:"2" env:"CALL_DIRECT_MAX_PARTICIPANTS"`
	CallMeshMaxParticipants        int    `envDefault:"6" env:"CALL_MESH_MAX_PARTICIPANTS"`
	CallMaxVideoPublishers         int    `envDefault:"5" env:"CALL_MAX_VIDEO_PUBLISHERS"`
}

// Validate checks that the configuration is valid.
// Returns an error if any validation fails.
func (c *ChatConfig) Validate() error {
	var errs []error

	errs = append(errs, c.validateShardConfig()...)
	errs = append(errs, c.validateQueueURIs()...)
	errs = append(errs, c.validatePositiveLimits()...)
	errs = append(errs, c.validateCallLimits()...)
	errs = append(errs, c.validateStawiRooms()...)

	return errors.Join(errs...)
}

func (c *ChatConfig) validateShardConfig() []error {
	var errs []error
	if c.ShardCount <= 0 {
		errs = append(errs, errors.New("ShardCount must be > 0"))
	}
	if len(c.QueueGatewayEventDeliveryURI) != c.ShardCount && !c.DoDatabaseMigrate() {
		errs = append(errs, fmt.Errorf("QueueGatewayEventDeliveryURI count (%d) must match ShardCount (%d)",
			len(c.QueueGatewayEventDeliveryURI), c.ShardCount))
	}
	return errs
}

func (c *ChatConfig) validateQueueURIs() []error {
	var errs []error
	if err := validateQueueURI(c.QueueDeviceEventDeliveryURI, "QueueDeviceEventDeliveryURI"); err != nil {
		errs = append(errs, err)
	}
	if err := validateQueueURI(c.QueueOfflineEventDeliveryURI, "QueueOfflineEventDeliveryURI"); err != nil {
		errs = append(errs, err)
	}
	if c.QueueRoomEventPublishedName != "" {
		if err := validateQueueURI(c.QueueRoomEventPublishedURI, "QueueRoomEventPublishedURI"); err != nil {
			errs = append(errs, err)
		}
	}
	for i, uri := range c.QueueGatewayEventDeliveryURI {
		if err := validateQueueURI(uri, fmt.Sprintf("QueueGatewayEventDeliveryURI[%d]", i)); err != nil {
			errs = append(errs, err)
		}
	}
	return errs
}

func (c *ChatConfig) validatePositiveLimits() []error {
	var errs []error
	errs = append(errs, validatePositiveInt(c.MaxDeliveryRetries, "MaxDeliveryRetries"))
	errs = append(errs, validatePositiveInt(c.DeviceSearchPageSize, "DeviceSearchPageSize"))
	errs = append(errs, validatePositiveInt(c.ProfileDeviceCacheTTLSeconds, "ProfileDeviceCacheTTLSeconds"))
	errs = append(errs, validatePositiveInt(c.ProfileDeviceCacheMaxEntries, "ProfileDeviceCacheMaxEntries"))
	errs = append(errs, validatePositiveInt(c.DeviceReplayMaxEventsPerDevice, "DeviceReplayMaxEventsPerDevice"))
	errs = append(errs, validatePositiveInt(c.DeviceReplayRetentionHours, "DeviceReplayRetentionHours"))
	return errs
}

func (c *ChatConfig) validateCallLimits() []error {
	var errs []error
	errs = append(errs, validatePositiveInt(c.CallDirectMaxParticipants, "CallDirectMaxParticipants"))
	errs = append(errs, validatePositiveInt(c.CallMeshMaxParticipants, "CallMeshMaxParticipants"))
	errs = append(errs, validatePositiveInt(c.CallMaxVideoPublishers, "CallMaxVideoPublishers"))
	if c.CallMeshMaxParticipants < c.CallDirectMaxParticipants {
		errs = append(errs, errors.New("CallMeshMaxParticipants must be >= CallDirectMaxParticipants"))
	}
	if c.CallMaxVideoPublishers > c.CallMeshMaxParticipants {
		errs = append(errs, errors.New("CallMaxVideoPublishers must be <= CallMeshMaxParticipants"))
	}
	return errs
}

// isDeployed reports whether the service runs in a shared environment, where
// Stawi rooms must be wired to real settlement, profile and queues.
func (c *ChatConfig) isDeployed() bool {
	switch strings.ToLower(c.Environment()) {
	case "staging", "production", "prod":
		return true
	default:
		return false
	}
}

func (c *ChatConfig) validateStawiRooms() []error {
	var errs []error
	if c.QueueStawiFactsName == "" {
		errs = append(errs, errors.New("QueueStawiFactsName cannot be empty"))
	}
	if err := validateQueueURI(c.QueueStawiFactsURI, "QueueStawiFactsURI"); err != nil {
		errs = append(errs, err)
	}
	if c.QueueStawiDriftName != "" {
		if err := validateQueueURI(c.QueueStawiDriftURI, "QueueStawiDriftURI"); err != nil {
			errs = append(errs, err)
		}
	}
	errs = append(errs, validatePositiveInt(c.StawiReconcileIntervalSeconds, "StawiReconcileIntervalSeconds"))
	if !c.isDeployed() || c.DoDatabaseMigrate() {
		return errs
	}
	if c.SettlementServiceURI == "" {
		errs = append(errs, errors.New("SETTLEMENT_SERVICE_URI is required in staging and production"))
	}
	if c.ProfileServiceURI == "" {
		errs = append(errs, errors.New("PROFILE_SERVICE_URI is required in staging and production: "+
			"chain addresses resolve to profiles through it"))
	}
	if strings.HasPrefix(c.QueueStawiFactsURI, "mem://") {
		errs = append(errs, errors.New("QUEUE_STAWI_FACTS_URI must be a durable subscription to settlement's "+
			"facts in staging and production, not mem://"))
	}
	if c.QueueStawiDriftName != "" && strings.HasPrefix(c.QueueStawiDriftURI, "mem://") {
		errs = append(errs, errors.New("QUEUE_STAWI_DRIFT_URI must be durable in staging and production, not mem://"))
	}
	return errs
}

func validatePositiveInt(value int, name string) error {
	if value > 0 {
		return nil
	}
	return fmt.Errorf("%s must be > 0", name)
}

// validateQueueURI checks that a queue URI has a valid scheme.
func validateQueueURI(uri, name string) error {
	if uri == "" {
		return fmt.Errorf("%s cannot be empty", name)
	}

	validSchemes := []string{"mem://", "redis://", "amqp://", "nats://", "kafka://"}
	for _, scheme := range validSchemes {
		if strings.HasPrefix(uri, scheme) {
			return nil
		}
	}

	return fmt.Errorf("%s has invalid scheme (must be one of: %s): %s", name, strings.Join(validSchemes, ", "), uri)
}
