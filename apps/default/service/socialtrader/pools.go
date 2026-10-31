// Package socialtrader is chat's view of the socialtrader service: the pool
// lookups and wallet links that decide whether a room may be bound to a
// strategy pool. Everything here is plain data passed to and from the
// service's PoolService and LinkService; chat never reads the chain itself.
package socialtrader

import (
	"context"
	"regexp"
	"strings"
)

// Pool is a strategy pool as the socialtrader service indexed it.
type Pool struct {
	// Address is the pool contract, lowercase hex.
	Address string
	// Leader is the wallet that trades for the pool, lowercase hex.
	Leader string
	// MarketID is the market the pool trades.
	MarketID string
	// RoomRef is the chat room the pool was created for, when it was created
	// through the service; empty for a pool created directly on chain.
	RoomRef string
}

// Pools answers pool lookups from the socialtrader service.
type Pools interface {
	// GetPool returns the pool at address; connect.CodeNotFound when the
	// service does not know it.
	GetPool(ctx context.Context, address string) (*Pool, error)
}

// WalletLinks answers the wallet a profile linked to itself (Sign-In with
// Ethereum) in the socialtrader service. Chat asks only for the caller in
// ctx: the service answers from the caller's own session.
type WalletLinks interface {
	// GetLinkedWallet returns the wallet linked to profileID, lowercase hex,
	// or "" when the profile linked none.
	GetLinkedWallet(ctx context.Context, profileID string) (string, error)
}

var addressPattern = regexp.MustCompile(`^0x[0-9a-fA-F]{40}$`)

// NormalizeAddress lowercases an EVM address; ok is false when value is not
// one.
func NormalizeAddress(value string) (string, bool) {
	trimmed := strings.TrimSpace(value)
	if !addressPattern.MatchString(trimmed) {
		return "", false
	}
	return strings.ToLower(trimmed), true
}
