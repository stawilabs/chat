package queues

import (
	"sync"
	"time"

	devicev1 "buf.build/gen/go/antinvestor/device/protocolbuffers/go/device/v1"
)

type deliveryDevice struct {
	id       string
	presence devicev1.PresenceStatus
}

type profileDeviceCacheEntry struct {
	devices  []deliveryDevice
	expires  time.Time
	lastUsed time.Time
}

type profileDeviceCache struct {
	mu         sync.RWMutex
	entries    map[string]profileDeviceCacheEntry
	ttl        time.Duration
	maxEntries int
}

func newProfileDeviceCache(ttl time.Duration, maxEntries int) *profileDeviceCache {
	if ttl <= 0 || maxEntries <= 0 {
		return nil
	}

	return &profileDeviceCache{
		entries:    make(map[string]profileDeviceCacheEntry, maxEntries),
		ttl:        ttl,
		maxEntries: maxEntries,
	}
}

func (c *profileDeviceCache) Get(profileID string) ([]deliveryDevice, bool) {
	if c == nil || profileID == "" {
		return nil, false
	}

	now := time.Now()

	// Use a single write lock to avoid TOCTOU race between read-check and
	// write-back — a concurrent Set between those steps would be overwritten.
	c.mu.Lock()
	entry, ok := c.entries[profileID]
	if !ok {
		c.mu.Unlock()
		return nil, false
	}
	if now.After(entry.expires) {
		delete(c.entries, profileID)
		c.mu.Unlock()
		return nil, false
	}

	entry.lastUsed = now
	c.entries[profileID] = entry
	c.mu.Unlock()

	devices := append([]deliveryDevice(nil), entry.devices...)
	return devices, true
}

func (c *profileDeviceCache) Set(profileID string, devices []deliveryDevice) {
	if c == nil || profileID == "" {
		return
	}

	now := time.Now()
	cloned := append([]deliveryDevice(nil), devices...)

	c.mu.Lock()
	defer c.mu.Unlock()

	c.evictExpiredLocked(now)
	if len(c.entries) >= c.maxEntries {
		c.evictLeastRecentlyUsedLocked()
	}

	c.entries[profileID] = profileDeviceCacheEntry{
		devices:  cloned,
		expires:  now.Add(c.ttl),
		lastUsed: now,
	}
}

func (c *profileDeviceCache) evictExpiredLocked(now time.Time) {
	for key, entry := range c.entries {
		if now.After(entry.expires) {
			delete(c.entries, key)
		}
	}
}

func (c *profileDeviceCache) evictLeastRecentlyUsedLocked() {
	var oldestKey string
	var oldest time.Time

	for key, entry := range c.entries {
		if oldestKey == "" || entry.lastUsed.Before(oldest) {
			oldestKey = key
			oldest = entry.lastUsed
		}
	}

	if oldestKey != "" {
		delete(c.entries, oldestKey)
	}
}
