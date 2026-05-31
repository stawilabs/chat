// Package health provides frame health checkers for the chat service's critical
// dependencies so readiness probes reflect real connectivity instead of a
// static 200.
package health

import (
	"context"
	"time"

	"github.com/pitabwire/frame/datastore/pool"
)

// dbHealthTimeout bounds how long a database health probe may take.
const dbHealthTimeout = 2 * time.Second

// DBChecker reports the chat database as healthy only when a connection can be
// acquired and pinged. Registered via Service.AddHealthCheck so a pod whose
// database is unreachable fails its readiness probe and is pulled from rotation
// rather than silently black-holing traffic.
type DBChecker struct {
	Pool pool.Pool
}

// Name implements frame.NamedChecker.
func (DBChecker) Name() string { return "database" }

// CheckHealth implements frame.Checker; it returns nil only when the underlying
// connection responds to a ping within dbHealthTimeout.
func (c DBChecker) CheckHealth() error {
	ctx, cancel := context.WithTimeout(context.Background(), dbHealthTimeout)
	defer cancel()

	sqlDB, err := c.Pool.DB(ctx, true).DB()
	if err != nil {
		return err
	}
	return sqlDB.PingContext(ctx)
}
