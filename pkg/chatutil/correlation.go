package chatutil

import (
	"context"

	"github.com/pitabwire/util"
)

// ContextWithEventLog returns a context whose logger is tagged with the event
// and room IDs. Every util.Log(ctx) call within a delivery-pipeline handler
// then carries the same correlation fields, so grepping logs by event_id
// follows a message across every queue hop (outbox -> fanout -> delivery ->
// gateway) — the end-to-end trace that was previously impossible.
func ContextWithEventLog(ctx context.Context, eventID, roomID string) context.Context {
	fields := map[string]any{}
	if eventID != "" {
		fields[KeyEventID] = eventID
	}
	if roomID != "" {
		fields[KeyRoomID] = roomID
	}
	if len(fields) == 0 {
		return ctx
	}
	return util.ContextWithLogger(ctx, util.Log(ctx).WithFields(fields))
}
