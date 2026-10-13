package business

import (
	"sync"
	"time"

	"golang.org/x/time/rate"
)

const (
	// defaultPartnerLookupsPerWindow and defaultPartnerLookupWindow bound each
	// person's GetDirectPartnerAccount calls: 60 a minute.
	defaultPartnerLookupsPerWindow = 60
	defaultPartnerLookupWindow     = time.Minute
)

// callerLimiter is an in-process token bucket per caller: each caller may
// make perWindow calls at once and regains them evenly over the window. A
// caller idle for a whole window has a full bucket again, so their bucket is
// dropped then and memory stays bounded by the callers active in a window.
// Each replica limits on its own.
type callerLimiter struct {
	mu        sync.Mutex
	limit     rate.Limit
	burst     int
	window    time.Duration
	callers   map[string]*callerBucket
	lastSweep time.Time
}

type callerBucket struct {
	limiter *rate.Limiter
	seen    time.Time
}

func newCallerLimiter(perWindow int, window time.Duration) *callerLimiter {
	if perWindow <= 0 || window <= 0 {
		perWindow, window = defaultPartnerLookupsPerWindow, defaultPartnerLookupWindow
	}
	return &callerLimiter{
		limit:   rate.Limit(float64(perWindow) / window.Seconds()),
		burst:   perWindow,
		window:  window,
		callers: map[string]*callerBucket{},
	}
}

// allow takes one call from the caller's bucket at now, or reports that the
// bucket is empty. A nil limiter allows everything.
func (l *callerLimiter) allow(caller string, now time.Time) bool {
	if l == nil {
		return true
	}
	l.mu.Lock()
	defer l.mu.Unlock()

	if now.Sub(l.lastSweep) >= l.window {
		for key, bucket := range l.callers {
			if now.Sub(bucket.seen) >= l.window {
				delete(l.callers, key)
			}
		}
		l.lastSweep = now
	}

	bucket, ok := l.callers[caller]
	if !ok {
		bucket = &callerBucket{limiter: rate.NewLimiter(l.limit, l.burst)}
		l.callers[caller] = bucket
	}
	bucket.seen = now
	return bucket.limiter.AllowN(now, 1)
}
