package queues

import (
	"context"

	"github.com/pitabwire/frame/queue"
	"github.com/pitabwire/util"

	"github.com/stawilabs/chat/apps/default/config"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/pkg/chatutil"
	chattel "github.com/stawilabs/chat/pkg/telemetry"
)

// deadLetterConsumer drains the dead-letter queue, persisting each message for
// forensics/replay, logging it, and recording a metric so operators can alert
// on DLQ depth.
type deadLetterConsumer struct {
	cfg  *config.ChatConfig
	repo repository.DeadLetterRepository
}

// NewDeadLetterConsumer creates a queue subscriber that consumes, persists, and
// observes dead-lettered messages. Without this consumer the DLQ grows
// unboundedly; without the repo the messages would be lost after log rotation.
func NewDeadLetterConsumer(cfg *config.ChatConfig, repo repository.DeadLetterRepository) queue.SubscribeWorker {
	return &deadLetterConsumer{cfg: cfg, repo: repo}
}

func (dlc *deadLetterConsumer) Handle(
	ctx context.Context,
	headers map[string]string,
	payload []byte,
) error {
	chattel.DeadLetterConsumedCounter.Add(ctx, 1)

	originalQueue := headers[chatutil.HeaderDLQOriginalQueue]
	errMsg := headers[chatutil.HeaderDLQErrorMessage]

	util.Log(ctx).WithFields(map[string]any{
		chatutil.KeyOriginalQueue: originalQueue,
		"error":                   errMsg,
	}).Warn("consumed dead-lettered message")

	if dlc.repo != nil {
		if err := dlc.repo.Record(ctx, originalQueue, errMsg, payload, headers); err != nil {
			// Don't silently ACK-drop a persistence failure — return the error so
			// the message is retried rather than lost.
			util.Log(ctx).WithError(err).Error("failed to persist dead-lettered message")
			return err
		}
	}

	// ACK — the message is now durably recorded; it had already exhausted retries.
	return nil
}
