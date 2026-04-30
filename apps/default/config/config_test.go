package config_test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/config"
)

func TestChatConfig_Validate(t *testing.T) {
	t.Run("valid configuration", func(t *testing.T) {
		cfg := validChatConfig()
		err := cfg.Validate()
		require.NoError(t, err)
	})

	t.Run("ShardCount must be > 0", func(t *testing.T) {
		cfg := validChatConfig()
		cfg.ShardCount = 0
		err := cfg.Validate()
		require.Error(t, err)
		assert.Contains(t, err.Error(), "ShardCount must be > 0")
	})

	t.Run("ShardCount must match gateway queue URIs", func(t *testing.T) {
		cfg := validChatConfig()
		cfg.ShardCount = 3
		cfg.QueueGatewayEventDeliveryURI = []string{"mem://queue1", "mem://queue2"} // Only 2
		err := cfg.Validate()
		require.Error(t, err)
		assert.Contains(t, err.Error(), "must match ShardCount")
	})

	t.Run("QueueDeviceEventDeliveryURI cannot be empty", func(t *testing.T) {
		cfg := validChatConfig()
		cfg.QueueDeviceEventDeliveryURI = ""
		err := cfg.Validate()
		require.Error(t, err)
		assert.Contains(t, err.Error(), "QueueDeviceEventDeliveryURI")
	})

	t.Run("QueueDeviceEventDeliveryURI must have valid scheme", func(t *testing.T) {
		cfg := validChatConfig()
		cfg.QueueDeviceEventDeliveryURI = "invalid://queue"
		err := cfg.Validate()
		require.Error(t, err)
		assert.Contains(t, err.Error(), "invalid scheme")
	})

	t.Run("valid queue schemes", func(t *testing.T) {
		validSchemes := []string{
			"mem://queue",
			"redis://localhost:6379/queue",
			"amqp://localhost:5672/queue",
			"nats://localhost:4222/queue",
			"kafka://localhost:9092/queue",
		}

		for _, uri := range validSchemes {
			cfg := validChatConfig()
			cfg.QueueDeviceEventDeliveryURI = uri
			err := cfg.Validate()
			require.NoError(t, err, "should accept valid URI: %s", uri)
		}
	})

	t.Run("multiple validation errors", func(t *testing.T) {
		cfg := validChatConfig()
		cfg.ShardCount = 0
		cfg.QueueDeviceEventDeliveryURI = ""
		err := cfg.Validate()
		require.Error(t, err)
		// Should contain multiple errors
		assert.Contains(t, err.Error(), "ShardCount")
		assert.Contains(t, err.Error(), "QueueDeviceEventDeliveryURI")
	})

	t.Run("resource tuning fields must be positive", func(t *testing.T) {
		cfg := validChatConfig()
		cfg.MaxDeliveryRetries = 0
		cfg.DeviceSearchPageSize = 0
		cfg.ProfileDeviceCacheTTLSeconds = 0
		cfg.ProfileDeviceCacheMaxEntries = 0
		cfg.DeviceReplayMaxEventsPerDevice = 0
		cfg.DeviceReplayRetentionHours = 0
		cfg.CallDirectMaxParticipants = 0
		cfg.CallMeshMaxParticipants = 0
		cfg.CallMaxVideoPublishers = 0

		err := cfg.Validate()
		require.Error(t, err)
		assert.Contains(t, err.Error(), "MaxDeliveryRetries")
		assert.Contains(t, err.Error(), "DeviceSearchPageSize")
		assert.Contains(t, err.Error(), "ProfileDeviceCacheTTLSeconds")
		assert.Contains(t, err.Error(), "ProfileDeviceCacheMaxEntries")
		assert.Contains(t, err.Error(), "DeviceReplayMaxEventsPerDevice")
		assert.Contains(t, err.Error(), "DeviceReplayRetentionHours")
		assert.Contains(t, err.Error(), "CallDirectMaxParticipants")
		assert.Contains(t, err.Error(), "CallMeshMaxParticipants")
		assert.Contains(t, err.Error(), "CallMaxVideoPublishers")
	})

	t.Run("mesh call limit must not be smaller than direct call limit", func(t *testing.T) {
		cfg := validChatConfig()
		cfg.CallDirectMaxParticipants = 3
		cfg.CallMeshMaxParticipants = 2

		err := cfg.Validate()
		require.Error(t, err)
		assert.Contains(t, err.Error(), "CallMeshMaxParticipants must be >=")
	})

	t.Run("video publisher limit must not exceed mesh call limit", func(t *testing.T) {
		cfg := validChatConfig()
		cfg.CallMeshMaxParticipants = 4
		cfg.CallMaxVideoPublishers = 5

		err := cfg.Validate()
		require.Error(t, err)
		assert.Contains(t, err.Error(), "CallMaxVideoPublishers must be <=")
	})
}

func validChatConfig() config.ChatConfig {
	return config.ChatConfig{
		DeviceServiceURI:               "127.0.0.1:7020",
		NotificationServiceURI:         "127.0.0.1:7020",
		ProfileServiceURI:              "127.0.0.1:7003",
		TenancyServiceURI:              "127.0.0.1:7003",
		SystemAccessID:                 "test-access-id",
		QueueDeviceEventDeliveryName:   "device.event.delivery",
		QueueDeviceEventDeliveryURI:    "mem://device.event.delivery",
		QueueOfflineEventDeliveryName:  "offline.event.delivery",
		QueueOfflineEventDeliveryURI:   "mem://offline.device.event.delivery",
		QueueGatewayEventDeliveryName:  "gateway.event.delivery.%d",
		QueueGatewayEventDeliveryURI:   []string{"mem://gateway.event.delivery.0"},
		ShardCount:                     1,
		MaxDeliveryRetries:             5,
		DeviceSearchPageSize:           100,
		ProfileDeviceCacheTTLSeconds:   5,
		ProfileDeviceCacheMaxEntries:   512,
		DeviceReplayMaxEventsPerDevice: 1000,
		DeviceReplayRetentionHours:     168,
		CallDirectMaxParticipants:      2,
		CallMeshMaxParticipants:        6,
		CallMaxVideoPublishers:         5,
	}
}
