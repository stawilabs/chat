package queues

import (
	"context"

	"github.com/antinvestor/service-chat/apps/default/config"
	"github.com/antinvestor/service-chat/internal"
	chattel "github.com/antinvestor/service-chat/internal/telemetry"
	"github.com/pitabwire/frame/queue"
	"github.com/pitabwire/util"
)

// deadLetterConsumer drains the dead-letter queue, logging each message and
// recording a metric so operators can alert on DLQ depth.
type deadLetterConsumer struct {
	cfg *config.ChatConfig
}

// NewDeadLetterConsumer creates a queue subscriber that consumes and observes
// dead-lettered messages.  Without this consumer the DLQ grows unboundedly.
func NewDeadLetterConsumer(cfg *config.ChatConfig) queue.SubscribeWorker {
	return &deadLetterConsumer{cfg: cfg}
}

func (dlc *deadLetterConsumer) Handle(
	ctx context.Context,
	headers map[string]string,
	_ []byte,
) error {
	chattel.DeadLetterConsumedCounter.Add(ctx, 1)

	util.Log(ctx).WithFields(map[string]any{
		"original_queue": headers[internal.HeaderDLQOriginalQueue],
		"error":          headers[internal.HeaderDLQErrorMessage],
	}).Warn("consumed dead-lettered message")

	// Always ACK — these messages have already exhausted retries.
	return nil
}
