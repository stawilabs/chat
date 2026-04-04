//nolint:golines // Env-tagged config structs intentionally keep long single-line struct tags.
package config

import (
	"errors"
	"fmt"
	"strings"

	"github.com/pitabwire/frame/config"
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

	SystemAccessID string `envDefault:"c8cf0ldstmdlinc3eva0" env:"STATIC_SYSTEM_ACCESS_ID"`

	QueueDeviceEventDeliveryName string `envDefault:"device.event.delivery"       env:"QUEUE_DEVICE_EVENT_DELIVERY_NAME"`
	QueueDeviceEventDeliveryURI  string `envDefault:"mem://device.event.delivery" env:"QUEUE_DEVICE_EVENT_DELIVERY_URI"`

	QueueOfflineEventDeliveryName string `envDefault:"offline.event.delivery"              env:"QUEUE_OFFLINE_EVENT_DELIVERY_NAME"`
	QueueOfflineEventDeliveryURI  string `envDefault:"mem://offline.device.event.delivery" env:"QUEUE_OFFLINE_EVENT_DELIVERY_URI"`

	QueueGatewayEventDeliveryName string   `envDefault:"gateway.event.delivery.%d"                env:"QUEUE_GATEWAY_EVENT_DELIVERY_NAME"`
	QueueGatewayEventDeliveryURI  []string `envDefault:"mem://gateway.event.delivery.0" env:"QUEUE_GATEWAY_EVENT_DELIVERY_URI"`

	ShardCount int `envDefault:"1" env:"SHARD_COUNT"`

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
