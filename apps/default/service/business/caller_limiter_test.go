package business

import (
	"testing"
	"time"

	"github.com/stretchr/testify/require"
)

// TestCallerLimiterAllowsSixtyAMinutePerCaller: each caller has their own
// bucket of 60 that refills at one a second; an idle caller's bucket is
// dropped once it is full again.
func TestCallerLimiterAllowsSixtyAMinutePerCaller(t *testing.T) {
	limiter := newCallerLimiter(defaultPartnerLookupsPerWindow, defaultPartnerLookupWindow)
	start := time.Unix(1_800_000_000, 0)

	for i := range 60 {
		require.True(t, limiter.allow("alice", start), "call %d", i+1)
	}
	require.False(t, limiter.allow("alice", start), "the 61st call in the minute")
	require.True(t, limiter.allow("bob", start), "another caller has their own bucket")

	require.False(t, limiter.allow("alice", start.Add(500*time.Millisecond)))
	require.True(t, limiter.allow("alice", start.Add(time.Second)), "one call back each second")
	require.False(t, limiter.allow("alice", start.Add(time.Second)))

	later := start.Add(2 * time.Minute)
	require.True(t, limiter.allow("carol", later))
	require.NotContains(t, limiter.callers, "bob", "an idle caller's full bucket is dropped")
	for range 60 {
		require.True(t, limiter.allow("alice", later))
	}
	require.False(t, limiter.allow("alice", later))

	var none *callerLimiter
	require.True(t, none.allow("alice", start))
}
