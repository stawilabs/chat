package queues

import (
	"context"
	"fmt"
	"maps"
	"strconv"
	"time"

	eventsv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/events/v1"
	"github.com/pitabwire/frame/queue"
	"github.com/pitabwire/util"

	"github.com/stawilabs/chat/apps/default/config"
	"github.com/stawilabs/chat/pkg/chatutil"
	chattel "github.com/stawilabs/chat/pkg/telemetry"
)

const (
	// dlqExtraHeaders is the number of DLQ-specific headers added to the original headers.
	dlqExtraHeaders = 2

	// retryBaseDelayMs is the base delay in milliseconds for the first retry.
	retryBaseDelayMs = 500
	// retryMaxDelayMs is the maximum delay in milliseconds for any retry.
	retryMaxDelayMs = 8000
)

// retryDelay returns the exponential backoff duration for the given retry count.
func retryDelay(retryCount int32) time.Duration {
	delay := retryBaseDelayMs * (1 << max(0, retryCount-1))
	if delay > retryMaxDelayMs {
		delay = retryMaxDelayMs
	}
	return time.Duration(delay) * time.Millisecond
}

// DeadLetterPublisher publishes failed deliveries to the dead-letter queue
// when they exceed the maximum retry count.
type DeadLetterPublisher struct {
	cfg  *config.ChatConfig
	qMan queue.Manager
}

// NewDeadLetterPublisher creates a new dead-letter queue publisher.
func NewDeadLetterPublisher(cfg *config.ChatConfig, qMan queue.Manager) *DeadLetterPublisher {
	return &DeadLetterPublisher{
		cfg:  cfg,
		qMan: qMan,
	}
}

// ShouldDeadLetter returns true if the delivery has exceeded the max retry count.
func (dlp *DeadLetterPublisher) ShouldDeadLetter(retryCount int32) bool {
	return int(retryCount) >= dlp.cfg.MaxDeliveryRetries
}

// Publish sends a failed delivery message to the dead-letter queue with
// error context headers for diagnostics.
func (dlp *DeadLetterPublisher) Publish(
	ctx context.Context,
	msg any,
	originalQueue string,
	errMsg string,
	headers map[string]string,
) error {
	topic, err := dlp.qMan.GetPublisher(dlp.cfg.QueueDeadLetterName)
	if err != nil {
		return fmt.Errorf("failed to get dead-letter publisher: %w", err)
	}

	// Add DLQ context to headers
	dlqHeaders := make(map[string]string, len(headers)+dlqExtraHeaders)
	maps.Copy(dlqHeaders, headers)
	dlqHeaders[chatutil.HeaderDLQOriginalQueue] = originalQueue
	dlqHeaders[chatutil.HeaderDLQErrorMessage] = errMsg

	if pubErr := topic.Publish(ctx, msg, dlqHeaders); pubErr != nil {
		util.Log(ctx).WithError(pubErr).WithFields(map[string]any{
			chatutil.KeyOriginalQueue: originalQueue,
		}).Error("failed to publish to dead-letter queue")
		return pubErr
	}

	util.Log(ctx).WithFields(map[string]any{
		chatutil.KeyOriginalQueue: originalQueue,
		"error":                   errMsg,
	}).Warn("delivery moved to dead-letter queue after max retries exceeded")

	return nil
}

// RetryOrDeadLetter increments the retry count and republishes the delivery,
// or sends it to the dead-letter queue if max retries have been exceeded.
func RetryOrDeadLetter(
	ctx context.Context,
	qMan queue.Manager,
	dlp *DeadLetterPublisher,
	queueName string,
	delivery *eventsv1.Delivery,
	headers map[string]string,
	originalErr error,
) error {
	delivery.RetryCount++

	if dlp != nil && dlp.ShouldDeadLetter(delivery.GetRetryCount()) {
		return dlp.Publish(ctx, delivery, queueName, originalErr.Error(), headers)
	}

	// Compute exponential backoff and set retry-after header so the consumer
	// can re-enqueue without blocking the handler goroutine.
	if headers == nil {
		headers = make(map[string]string)
	}
	delay := retryDelay(delivery.GetRetryCount())
	retryAfter := time.Now().Add(delay).UnixMilli()
	headers[chatutil.HeaderRetryAfter] = strconv.FormatInt(retryAfter, 10)

	topic, err := qMan.GetPublisher(queueName)
	if err != nil {
		util.Log(ctx).WithError(err).WithField("queue_name", queueName).
			Error("failed to get publisher for retry")
		return err
	}

	if pubErr := topic.Publish(ctx, delivery, headers); pubErr != nil {
		util.Log(ctx).WithError(pubErr).WithField("queue_name", queueName).
			Error("failed to republish for retry")
		return pubErr
	}

	chattel.DeliveryQueueRetriedCounter.Add(ctx, 1)
	util.Log(ctx).WithFields(map[string]any{
		"retry_count": delivery.GetRetryCount(),
		"queue_name":  queueName,
		"retry_after": retryAfter,
		"delay_ms":    delay.Milliseconds(),
	}).
		Debug("delivery republished for retry")
	return nil
}

// ShouldDeferRetry checks whether a message has a retry-after header whose
// timestamp is still in the future. If so, it re-enqueues the message
// unchanged and returns (true, nil) so the caller can skip processing.
// When the retry-after time has elapsed the function returns (false, nil)
// and the caller should proceed normally.
func ShouldDeferRetry(
	ctx context.Context,
	qMan queue.Manager,
	queueName string,
	payload any,
	headers map[string]string,
) (bool, error) {
	retryAfterStr, ok := headers[chatutil.HeaderRetryAfter]
	if !ok {
		return false, nil
	}
	retryAfter, err := strconv.ParseInt(retryAfterStr, 10, 64)
	if err != nil {
		return false, nil //nolint:nilerr // Malformed header — process the message normally.
	}
	if time.Now().UnixMilli() >= retryAfter {
		return false, nil
	}

	topic, pubErr := qMan.GetPublisher(queueName)
	if pubErr != nil {
		return true, pubErr
	}
	if pubErr = topic.Publish(ctx, payload, headers); pubErr != nil {
		return true, pubErr
	}

	util.Log(ctx).WithField("retry_after", retryAfter).
		Debug("message deferred, retry-after still in future")
	return true, nil
}
