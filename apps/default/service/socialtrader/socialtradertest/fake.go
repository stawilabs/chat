// Package socialtradertest provides in-memory stand-ins for the socialtrader
// service's PoolService and LinkService, for tests of chat's trading-group
// paths.
package socialtradertest

import (
	"context"
	"strings"
	"sync"

	"connectrpc.com/connect/v2"

	"github.com/stawilabs/chat/apps/default/service/socialtrader"
)

// Pools is a fake PoolService: pools added with Add are answered by GetPool;
// Refuse makes every lookup fail with the given error until Refuse(nil).
type Pools struct {
	mu    sync.Mutex
	pools map[string]*socialtrader.Pool
	err   error
}

// NewPools returns an empty fake PoolService.
func NewPools() *Pools {
	return &Pools{pools: map[string]*socialtrader.Pool{}}
}

// Add makes pool known, keyed by its lowercase address.
func (p *Pools) Add(pool *socialtrader.Pool) {
	p.mu.Lock()
	defer p.mu.Unlock()
	copied := *pool
	copied.Address = strings.ToLower(pool.Address)
	p.pools[copied.Address] = &copied
}

// Refuse makes GetPool fail with err until called with nil.
func (p *Pools) Refuse(err error) {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.err = err
}

func (p *Pools) GetPool(_ context.Context, address string) (*socialtrader.Pool, error) {
	p.mu.Lock()
	defer p.mu.Unlock()
	if p.err != nil {
		return nil, p.err
	}
	pool, ok := p.pools[strings.ToLower(address)]
	if !ok {
		return nil, connect.Errorf(connect.CodeNotFound, "pool %s not found", address)
	}
	copied := *pool
	return &copied, nil
}

// WalletLinks is a fake LinkService: Link records a profile's wallet.
type WalletLinks struct {
	mu    sync.Mutex
	links map[string]string
	err   error
}

// NewWalletLinks returns an empty fake LinkService.
func NewWalletLinks() *WalletLinks {
	return &WalletLinks{links: map[string]string{}}
}

// Link records wallet as profileID's linked wallet.
func (l *WalletLinks) Link(profileID, wallet string) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.links[profileID] = strings.ToLower(wallet)
}

// Refuse makes GetLinkedWallet fail with err until called with nil.
func (l *WalletLinks) Refuse(err error) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.err = err
}

func (l *WalletLinks) GetLinkedWallet(_ context.Context, profileID string) (string, error) {
	l.mu.Lock()
	defer l.mu.Unlock()
	if l.err != nil {
		return "", l.err
	}
	return l.links[profileID], nil
}
