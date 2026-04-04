package business

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/pitabwire/frame/cache"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestConnectionManager_Shutdown(t *testing.T) {
	cm := newTestConnectionManager()

	err := cm.Shutdown(context.Background())
	require.NoError(t, err)

	// Shutdown should be idempotent
	err = cm.Shutdown(context.Background())
	require.NoError(t, err)
}

func TestConnectionManager_ShutdownRejectsNewConnections(t *testing.T) {
	cm := newTestConnectionManager()

	err := cm.Shutdown(context.Background())
	require.NoError(t, err)

	// After shutdown, HandleConnection should return ErrShuttingDown
	err = cm.HandleConnection(context.Background(), "user1", "dev1", nil)
	assert.ErrorIs(t, err, ErrShuttingDown)
}

func TestConnectionManager_ActiveConnections(t *testing.T) {
	cm := newTestConnectionManager()
	assert.Equal(t, int32(0), cm.ActiveConnections())
}

func TestNewConnectionManager_AppliesResourceOptions(t *testing.T) {
	manager := NewConnectionManager(
		context.Background(),
		nil,
		nil,
		nil,
		cache.NewInMemoryCache(),
		ConnectionManagerOptions{
			MaxConnectionsPerDevice: 2,
			ConnectionTimeoutSec:    120,
			HeartbeatIntervalSec:    20,
			PoolExpectedDevices:     10,
			PoolMinSize:             32,
			DispatchBufferSize:      8,
			DispatchTimeout:         25 * time.Millisecond,
			InboundRateLimit:        40,
			InboundRateBurst:        10,
			ResumeRoomPageSize:      20,
			ResumeHistoryPageSize:   15,
			ResumeMaxRooms:          60,
			ResumeMaxEvents:         120,
		},
	)
	cm, ok := manager.(*connectionManager)
	require.True(t, ok)
	defer func() {
		require.NoError(t, cm.Shutdown(context.Background()))
	}()

	assert.Equal(t, int32(32), cm.connPool.maxSize)
	assert.Equal(t, 8, cm.connectionOpts.DispatchBufferSize)
	assert.Equal(t, 25*time.Millisecond, cm.connectionOpts.DispatchTimeout)
	assert.Equal(t, 40, cm.connectionOpts.InboundRateLimit)
	assert.Equal(t, 10, cm.connectionOpts.InboundRateBurst)
	assert.Equal(t, 20, cm.resumeRoomPageSize)
	assert.Equal(t, 15, cm.resumeHistoryPageSize)
	assert.Equal(t, 60, cm.resumeMaxRooms)
	assert.Equal(t, 120, cm.resumeMaxEvents)
}

func TestConnectionManager_DrainConnections_Empty(t *testing.T) {
	cm := newTestConnectionManager()

	ctx, cancel := context.WithTimeout(t.Context(), 2*time.Second)
	defer cancel()

	// Should return immediately with no connections
	cm.DrainConnections(ctx)
}

func TestConnectionManager_DrainConnections_Timeout(t *testing.T) {
	cm := newTestConnectionManager()

	// Add connections directly to the pool
	for i := range 3 {
		conn := makeShutdownTestConnection(fmt.Sprintf("user%d", i), fmt.Sprintf("dev%d", i))
		require.NoError(t, cm.connPool.add(conn))
	}

	assert.Equal(t, int32(3), cm.ActiveConnections())

	// Drain with short timeout should return after timeout
	ctx, cancel := context.WithTimeout(context.Background(), 500*time.Millisecond)
	defer cancel()

	start := time.Now()
	cm.DrainConnections(ctx)
	elapsed := time.Since(start)

	// Should have waited approximately the timeout
	assert.GreaterOrEqual(t, elapsed.Milliseconds(), int64(400))
}

func TestConnectionManager_DrainConnections_AllDisconnect(t *testing.T) {
	cm := newTestConnectionManager()

	// Add connections
	for i := range 3 {
		conn := makeShutdownTestConnection(fmt.Sprintf("user%d", i), fmt.Sprintf("dev%d", i))
		require.NoError(t, cm.connPool.add(conn))
	}

	// Remove connections after a delay (simulate clients disconnecting)
	go func() {
		time.Sleep(200 * time.Millisecond)
		for i := range 3 {
			key := fmt.Sprintf("user%d:dev%d", i, i)
			cm.connPool.remove(key)
		}
	}()

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	start := time.Now()
	cm.DrainConnections(ctx)
	elapsed := time.Since(start)

	// Should finish quickly after all connections are removed
	assert.Less(t, elapsed.Milliseconds(), int64(2000))
	assert.Equal(t, int32(0), cm.ActiveConnections())
}

func makeShutdownTestConnection(profileID, deviceID string) Connection {
	return NewConnection(nil, &Metadata{
		ProfileID: profileID,
		DeviceID:  deviceID,
	}, ConnectionOptions{}.withDefaults())
}

// newTestConnectionManager creates a minimal connectionManager for testing.
func newTestConnectionManager() *connectionManager {
	return &connectionManager{
		connPool:                newConnectionPool(1000),
		maxConnectionsPerDevice: 5,
		connectionTimeoutSec:    300,
		heartbeatIntervalSec:    30,
		connectionOpts:          ConnectionOptions{}.withDefaults(),
		resumeRoomPageSize:      50,
		resumeHistoryPageSize:   50,
		resumeMaxRooms:          250,
		resumeMaxEvents:         1000,
		shutdownCh:              make(chan struct{}),
	}
}
