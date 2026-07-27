package config

import (
	"errors"
	"fmt"
	"strings"

	"github.com/pitabwire/frame/v2/config"
)

type GatewayConfig struct {
	config.ConfigurationDefault

	// Chat service configuration - the gateway connects to the default chat service
	ChatServiceURI                   string `envDefault:"127.0.0.1:7010"                 env:"CHAT_SERVICE_URI"`
	ChatServiceWorkloadAPITargetPath string `envDefault:"/ns/chat/sa/service-chat-drone" env:"CHAT_SERVICE_WORKLOAD_API_TARGET_PATH"`

	// Device service configuration - for delivery status tracking
	DeviceServiceURI                   string `envDefault:"devices.stawi.org:443"          env:"DEVICE_SERVICE_URI"`
	DeviceServiceWorkloadAPITargetPath string `envDefault:"/ns/profile/sa/service-devices" env:"DEVICE_SERVICE_WORKLOAD_API_TARGET_PATH"`

	// Connection management
	MaxConnectionsPerDevice int `envDefault:"1"   env:"MAX_CONNECTIONS_PER_DEVICE"`
	ConnectionTimeoutSec    int `envDefault:"300" env:"CONNECTION_TIMEOUT_SEC"`
	HeartbeatIntervalSec    int `envDefault:"30"  env:"HEARTBEAT_INTERVAL_SEC"`

	// Rate limiting
	MaxEventsPerSecond int `envDefault:"100" env:"MAX_EVENTS_PER_SECOND"`
	MaxEventBurst      int `envDefault:"20"  env:"MAX_EVENT_BURST"`

	// Resource tuning for constrained environments. The pool size is a map
	// capacity hint (the pool grows dynamically), so these defaults give a
	// sane connection ceiling on lean hardware (~2k connections) without the
	// old 256 cap that hard-failed real load. Raise these for large instances.
	ConnectionPoolExpectedDevices int `envDefault:"2048" env:"CONNECTION_POOL_EXPECTED_DEVICES"`
	ConnectionPoolMinSize         int `envDefault:"1024" env:"CONNECTION_POOL_MIN_SIZE"`
	DispatchBufferSize            int `envDefault:"16"   env:"DISPATCH_BUFFER_SIZE"`
	DispatchTimeoutMs             int `envDefault:"100"  env:"DISPATCH_TIMEOUT_MS"`

	// Resume replay limits
	ResumeReplayRoomPageSize    int `envDefault:"50"   env:"RESUME_REPLAY_ROOM_PAGE_SIZE"`
	ResumeReplayHistoryPageSize int `envDefault:"50"   env:"RESUME_REPLAY_HISTORY_PAGE_SIZE"`
	ResumeReplayMaxRooms        int `envDefault:"250"  env:"RESUME_REPLAY_MAX_ROOMS"`
	ResumeReplayMaxEvents       int `envDefault:"1000" env:"RESUME_REPLAY_MAX_EVENTS"`

	// Cache configuration (Redis or similar)
	// Connection metadata is stored in cache to enable horizontal scaling
	// and allow multiple gateway instances to coordinate
	CacheName            string `envDefault:"defaultCache"           env:"CACHE_NAME"`
	CacheURI             string `envDefault:"redis://localhost:6379" env:"CACHE_URI"`
	CacheCredentialsFile string `envDefault:""                       env:"CACHE_CREDENTIALS_FILE"`

	QueueOfflineEventDeliveryName string `envDefault:"offline.event.delivery"              env:"QUEUE_OFFLINE_EVENT_DELIVERY_NAME"`
	QueueOfflineEventDeliveryURI  string `envDefault:"mem://offline.device.event.delivery" env:"QUEUE_OFFLINE_EVENT_DELIVERY_URI"`

	// Queue for receiving user-targeted deliveries from default service
	QueueGatewayEventDeliveryName string `envDefault:"gateway.event.delivery.%d"       env:"QUEUE_GATEWAY_EVENT_DELIVERY_NAME"`
	QueueGatewayEventDeliveryURI  string `envDefault:"mem://gateway.event.delivery.%d" env:"QUEUE_GATEWAY_EVENT_DELIVERY_URI"`

	// Shard configuration - must be coordinated with the default service's ShardCount.
	// ShardID identifies this gateway instance's shard (0-indexed).
	// TotalShards must match the default service's ShardCount exactly.
	ShardID     int `envDefault:"0" env:"SHARD_ID"`
	TotalShards int `envDefault:"1" env:"TOTAL_SHARDS"`
}

// Validate checks that the configuration is valid.
// Returns an error if any validation fails.
func (c *GatewayConfig) Validate() error {
	var errs []error

	errs = append(errs, c.validateServiceSettings()...)
	errs = append(errs, c.validateConnectionSettings()...)
	errs = append(errs, c.validateResourceSettings()...)
	errs = append(errs, c.validateShardSettings()...)

	// Validate cache configuration
	if err := validateCacheURI(c.CacheURI, "CacheURI"); err != nil {
		errs = append(errs, err)
	}

	// Validate queue URIs
	if err := validateQueueURI(c.QueueOfflineEventDeliveryURI, "QueueOfflineEventDeliveryURI"); err != nil {
		errs = append(errs, err)
	}
	if err := validateQueueURI(c.QueueGatewayEventDeliveryURI, "QueueGatewayEventDeliveryURI"); err != nil {
		errs = append(errs, err)
	}

	return errors.Join(errs...)
}

func (c *GatewayConfig) validateServiceSettings() []error {
	var errs []error
	if c.ChatServiceURI == "" {
		errs = append(errs, errors.New("ChatServiceURI cannot be empty"))
	}
	return errs
}

func (c *GatewayConfig) validateConnectionSettings() []error {
	var errs []error
	if c.MaxConnectionsPerDevice < 1 {
		errs = append(errs, errors.New("MaxConnectionsPerDevice must be >= 1"))
	}
	if c.ConnectionTimeoutSec <= 0 {
		errs = append(errs, errors.New("ConnectionTimeoutSec must be > 0"))
	}
	if c.HeartbeatIntervalSec <= 0 {
		errs = append(errs, errors.New("HeartbeatIntervalSec must be > 0"))
	}
	if c.ConnectionTimeoutSec <= c.HeartbeatIntervalSec {
		errs = append(errs, fmt.Errorf("ConnectionTimeoutSec (%d) must be > HeartbeatIntervalSec (%d)",
			c.ConnectionTimeoutSec, c.HeartbeatIntervalSec))
	}
	return errs
}

func (c *GatewayConfig) validateResourceSettings() []error {
	var errs []error
	if c.MaxEventsPerSecond <= 0 {
		errs = append(errs, errors.New("MaxEventsPerSecond must be > 0"))
	}
	if c.MaxEventBurst <= 0 {
		errs = append(errs, errors.New("MaxEventBurst must be > 0"))
	}
	if c.ConnectionPoolExpectedDevices <= 0 {
		errs = append(errs, errors.New("ConnectionPoolExpectedDevices must be > 0"))
	}
	if c.ConnectionPoolMinSize <= 0 {
		errs = append(errs, errors.New("ConnectionPoolMinSize must be > 0"))
	}
	if c.DispatchBufferSize <= 0 {
		errs = append(errs, errors.New("DispatchBufferSize must be > 0"))
	}
	if c.DispatchTimeoutMs <= 0 {
		errs = append(errs, errors.New("DispatchTimeoutMs must be > 0"))
	}
	if c.ResumeReplayRoomPageSize <= 0 {
		errs = append(errs, errors.New("ResumeReplayRoomPageSize must be > 0"))
	}
	if c.ResumeReplayHistoryPageSize <= 0 {
		errs = append(errs, errors.New("ResumeReplayHistoryPageSize must be > 0"))
	}
	if c.ResumeReplayMaxRooms <= 0 {
		errs = append(errs, errors.New("ResumeReplayMaxRooms must be > 0"))
	}
	if c.ResumeReplayMaxEvents <= 0 {
		errs = append(errs, errors.New("ResumeReplayMaxEvents must be > 0"))
	}
	return errs
}

func (c *GatewayConfig) validateShardSettings() []error {
	var errs []error
	if c.ShardID < 0 {
		errs = append(errs, errors.New("ShardID must be >= 0"))
	}
	if c.TotalShards <= 0 {
		errs = append(errs, errors.New("TotalShards must be > 0"))
	}
	if c.TotalShards > 0 && c.ShardID >= c.TotalShards {
		errs = append(errs, fmt.Errorf("ShardID (%d) must be < TotalShards (%d)",
			c.ShardID, c.TotalShards))
	}
	return errs
}

// validateCacheURI checks that a cache URI has a valid scheme.
func validateCacheURI(uri, name string) error {
	if uri == "" {
		return fmt.Errorf("%s cannot be empty", name)
	}

	validSchemes := []string{"redis://", "nats://", "mem://", "memory://"}
	for _, scheme := range validSchemes {
		if strings.HasPrefix(uri, scheme) {
			return nil
		}
	}

	return fmt.Errorf("%s has invalid scheme (must be one of: %s): %s", name, strings.Join(validSchemes, ", "), uri)
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
