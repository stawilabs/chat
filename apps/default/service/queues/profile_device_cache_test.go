package queues

import (
	"testing"
	"time"

	devicev1 "buf.build/gen/go/antinvestor/device/protocolbuffers/go/device/v1"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestProfileDeviceCache_GetSet(t *testing.T) {
	cache := newProfileDeviceCache(time.Second, 2)
	require.NotNil(t, cache)

	cache.Set("profile-1", []deliveryDevice{
		{id: "device-1", presence: devicev1.PresenceStatus_ONLINE},
	})

	devices, ok := cache.Get("profile-1")
	require.True(t, ok)
	require.Len(t, devices, 1)
	assert.Equal(t, "device-1", devices[0].id)
	assert.Equal(t, devicev1.PresenceStatus_ONLINE, devices[0].presence)
}

func TestProfileDeviceCache_ExpiresEntries(t *testing.T) {
	cache := newProfileDeviceCache(20*time.Millisecond, 2)
	require.NotNil(t, cache)

	cache.Set("profile-1", []deliveryDevice{{id: "device-1"}})
	time.Sleep(40 * time.Millisecond)

	_, ok := cache.Get("profile-1")
	assert.False(t, ok)
}

func TestProfileDeviceCache_EvictsLeastRecentlyUsed(t *testing.T) {
	cache := newProfileDeviceCache(time.Minute, 2)
	require.NotNil(t, cache)

	cache.Set("profile-1", []deliveryDevice{{id: "device-1"}})
	cache.Set("profile-2", []deliveryDevice{{id: "device-2"}})

	_, ok := cache.Get("profile-1")
	require.True(t, ok)

	cache.Set("profile-3", []deliveryDevice{{id: "device-3"}})

	_, ok = cache.Get("profile-2")
	assert.False(t, ok)

	_, ok = cache.Get("profile-1")
	assert.True(t, ok)

	_, ok = cache.Get("profile-3")
	assert.True(t, ok)
}
