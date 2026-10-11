package business

import "github.com/stawilabs/chat/apps/default/service/models"

// SetApplyFault makes the chain consumer fail facts for which f returns an
// error, before applying them (tests only).
func SetApplyFault(c *StawiChain, f func(*models.StawiChainFact) error) { c.applyFault = f }

// SetAfterReconcileLock runs f between a reconcile pass's locked repair and
// its Keto checks (tests only).
func SetAfterReconcileLock(c *StawiChain, f func()) { c.afterReconcileLock = f }

// LogKey is the inbox key of a chain log (tests only).
func LogKey(chainID uint64, txHash []byte, logIndex uint64) string {
	return logKey(chainID, txHash, logIndex)
}
