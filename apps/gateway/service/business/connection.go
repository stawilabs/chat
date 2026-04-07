package business

import (
	"context"
	"sync"
	"sync/atomic"
	"time"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
)

const (
	defaultDispatchChannelSize = 16
	defaultDispatchTimeout     = 100 * time.Millisecond
	defaultRateLimit           = 100
	defaultRateLimitBurst      = 20
)

type ConnectionOptions struct {
	DispatchBufferSize int
	DispatchTimeout    time.Duration
	InboundRateLimit   int
	InboundRateBurst   int
}

func (opts ConnectionOptions) withDefaults() ConnectionOptions {
	if opts.DispatchBufferSize <= 0 {
		opts.DispatchBufferSize = defaultDispatchChannelSize
	}
	if opts.DispatchTimeout <= 0 {
		opts.DispatchTimeout = defaultDispatchTimeout
	}
	if opts.InboundRateLimit <= 0 {
		opts.InboundRateLimit = defaultRateLimit
	}
	if opts.InboundRateBurst <= 0 {
		opts.InboundRateBurst = defaultRateLimitBurst
	}
	return opts
}

// tokenBucket implements a simple token bucket rate limiter.
// It allows bursting up to 'burst' tokens and refills at 'rate' tokens per second.
type tokenBucket struct {
	tokens     float64    // Current tokens available
	maxTokens  float64    // Maximum tokens (burst capacity)
	refillRate float64    // Tokens added per second
	lastRefill time.Time  // Last time tokens were refilled
	mu         sync.Mutex // Protects token state
}

// newTokenBucket creates a new token bucket rate limiter.
func newTokenBucket(ratePerSecond, burst int) *tokenBucket {
	return &tokenBucket{
		tokens:     float64(burst), // Start full
		maxTokens:  float64(burst),
		refillRate: float64(ratePerSecond),
		lastRefill: time.Now(),
	}
}

// Allow checks if a request is allowed and consumes a token if so.
// Returns true if the request is allowed, false if rate limited.
func (tb *tokenBucket) Allow() bool {
	tb.mu.Lock()
	defer tb.mu.Unlock()

	// Refill tokens based on elapsed time
	now := time.Now()
	elapsed := now.Sub(tb.lastRefill).Seconds()
	tb.tokens += elapsed * tb.refillRate
	if tb.tokens > tb.maxTokens {
		tb.tokens = tb.maxTokens
	}
	tb.lastRefill = now

	// Check if we have tokens available
	if tb.tokens >= 1 {
		tb.tokens--
		return true
	}
	return false
}

// connection represents an active edge device connection.
type connection struct {
	metadata     *Metadata
	dispatchChan chan *chatv1.StreamResponse
	stream       DeviceStream
	mu           sync.RWMutex
	closeOnce    sync.Once
	closed       atomic.Bool
	dispatchOpts ConnectionOptions

	// Rate limiting
	rateLimiter    *tokenBucket  // Token bucket for inbound rate limiting
	rateLimitedCnt atomic.Uint64 // Number of requests rate limited

	// Backpressure metrics
	droppedMsgs  atomic.Uint64 // Number of messages dropped due to slow consumer
	dispatchedMs atomic.Uint64 // Total messages successfully dispatched
}

func (c *connection) ConsumeDispatch(ctx context.Context) *chatv1.StreamResponse {
	select {
	case <-ctx.Done():
		return nil
	case data := <-c.dispatchChan:
		return data
	}
}

func (c *connection) Lock() {
	c.mu.Lock()
}

func (c *connection) Unlock() {
	c.mu.Unlock()
}

func NewConnection(stream DeviceStream, metadata *Metadata, opts ConnectionOptions) Connection {
	opts = opts.withDefaults()
	return &connection{
		metadata:     metadata,
		stream:       stream,
		dispatchChan: make(chan *chatv1.StreamResponse, opts.DispatchBufferSize),
		dispatchOpts: opts,
		rateLimiter:  newTokenBucket(opts.InboundRateLimit, opts.InboundRateBurst),
	}
}

// AllowInbound checks if an inbound request is allowed by the rate limiter.
// Returns true if allowed, false if rate limited.
func (c *connection) AllowInbound() bool {
	if c.rateLimiter == nil {
		return true
	}
	if c.rateLimiter.Allow() {
		return true
	}
	c.rateLimitedCnt.Add(1)
	return false
}

// RateLimitedCount returns the number of requests that were rate limited.
func (c *connection) RateLimitedCount() uint64 {
	return c.rateLimitedCnt.Load()
}

func (c *connection) Metadata() *Metadata {
	return c.metadata
}

//nolint:nonamedreturns // named return required for deferred recover to set result on panic
func (c *connection) Dispatch(evt *chatv1.StreamResponse) (dispatched bool) {
	// Protect against send-on-closed-channel panic.
	// Between the closed check and the channel send, another goroutine can
	// call Close(). The deferred recover is the only safe guard.
	defer func() {
		if r := recover(); r != nil {
			dispatched = false
		}
	}()

	if c.closed.Load() {
		return false
	}

	// First try non-blocking send
	select {
	case c.dispatchChan <- evt:
		c.dispatchedMs.Add(1)
		return true
	default:
	}

	// Channel full - apply backpressure with timeout
	// This gives slow consumers a brief window to catch up
	timer := time.NewTimer(c.dispatchOpts.DispatchTimeout)
	defer timer.Stop()

	select {
	case c.dispatchChan <- evt:
		c.dispatchedMs.Add(1)
		return true
	case <-timer.C:
		// Timeout expired - connection is too slow
		c.droppedMsgs.Add(1)
		return false
	}
}

// DroppedMessages returns the count of messages dropped due to slow consumer.
func (c *connection) DroppedMessages() uint64 {
	return c.droppedMsgs.Load()
}

// DispatchedMessages returns the count of successfully dispatched messages.
func (c *connection) DispatchedMessages() uint64 {
	return c.dispatchedMs.Load()
}

// ChannelUtilization returns the current channel buffer utilization (0.0 to 1.0).
func (c *connection) ChannelUtilization() float64 {
	return float64(len(c.dispatchChan)) / float64(cap(c.dispatchChan))
}

func (c *connection) Stream() DeviceStream {
	return c.stream
}

func (c *connection) Close() {
	c.closeOnce.Do(func() {
		c.closed.Store(true)
		close(c.dispatchChan)
	})
}
