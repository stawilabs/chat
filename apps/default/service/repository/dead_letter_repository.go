package repository

import (
	"context"

	"github.com/pitabwire/frame/data"
	"github.com/pitabwire/frame/datastore"
	"github.com/pitabwire/frame/datastore/pool"
	"github.com/pitabwire/frame/workerpool"

	"github.com/stawilabs/chat/apps/default/service/models"
)

// DeadLetterRepository persists dead-lettered messages for forensics and replay.
type DeadLetterRepository interface {
	datastore.BaseRepository[*models.DeadLetterEvent]
	// Record durably stores a dead-lettered message.
	Record(ctx context.Context, originalQueue, errMsg string, payload []byte, headers map[string]string) error
}

type deadLetterRepository struct {
	datastore.BaseRepository[*models.DeadLetterEvent]
}

// NewDeadLetterRepository creates a new dead-letter repository instance.
func NewDeadLetterRepository(ctx context.Context, dbPool pool.Pool, workMan workerpool.Manager) DeadLetterRepository {
	return &deadLetterRepository{
		BaseRepository: datastore.NewBaseRepository[*models.DeadLetterEvent](
			ctx, dbPool, workMan, func() *models.DeadLetterEvent { return &models.DeadLetterEvent{} },
		),
	}
}

func (r *deadLetterRepository) Record(
	ctx context.Context,
	originalQueue, errMsg string,
	payload []byte,
	headers map[string]string,
) error {
	hdr := make(data.JSONMap, len(headers))
	for k, v := range headers {
		hdr[k] = v
	}
	event := &models.DeadLetterEvent{
		OriginalQueue: originalQueue,
		ErrorMessage:  errMsg,
		Payload:       payload,
		Headers:       hdr,
	}
	event.GenID(ctx)
	return r.Create(ctx, event)
}
