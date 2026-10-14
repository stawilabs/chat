// Package connectserver is how chat's services serve Connect (v2): one error
// interceptor that keeps codes and messages on the wire, and the per-message
// limits each service mounts with.
//
// Connect v2 sends only a locally built *connect.Error with its message. A
// plain error from a handler reaches the client as CodeUnknown with no
// message, and an error a downstream service returned (a remote
// *connect.Error, settlement's verdict on a room act, say) as CodeInternal
// with no message. Connect v1 sent both with their message, the downstream
// one with its own code, and chat's clients (the app, the gateway, the
// deployment tests) read them. ErrorInterceptor restores that wire behaviour.
package connectserver

import (
	"context"
	"errors"

	"connectrpc.com/connect/v2"
	"connectrpc.com/connect/v2/connecthttp"
)

// ErrorInterceptor converts what a handler returns into the error Connect v1
// would have sent; see ToAPI. Put it last in a server's chain, closest to the
// handler, so the interceptors outside it (tracing, logging) see the error
// the client receives.
func ErrorInterceptor() connect.ServerInterceptor {
	return func(next connect.ServerFunc) connect.ServerFunc {
		return func(ctx context.Context, spec connect.Spec, stream connect.ServerStream) error {
			return ToAPI(next(ctx, spec, stream))
		}
	}
}

// ToAPI maps err to the *connect.Error the client receives:
//
//   - a locally built *connect.Error anywhere in the chain is returned
//     unchanged;
//   - a remote one (a downstream service's verdict) keeps its code, message
//     and details;
//   - context.Canceled and context.DeadlineExceeded keep their codes;
//   - anything else is CodeUnknown with the error's text, as in v1.
//
// The original error stays attached as the cause, so errors.Is and errors.As
// still match it on the server.
func ToAPI(err error) error {
	if err == nil {
		return nil
	}
	var ce *connect.Error
	if errors.As(err, &ce) && ce != nil {
		if !ce.IsRemote() {
			return err
		}
		out := connect.NewError(ce.Code(), ce.Message()).WithCause(err)
		for _, d := range ce.Details() {
			out = out.WithDetail(d)
		}
		return out
	}
	switch {
	case errors.Is(err, context.Canceled):
		return connect.NewError(connect.CodeCanceled, err.Error()).WithCause(err)
	case errors.Is(err, context.DeadlineExceeded):
		return connect.NewError(connect.CodeDeadlineExceeded, err.Error()).WithCause(err)
	}
	return connect.NewError(connect.CodeUnknown, err.Error()).WithCause(err)
}

// Limits are a service's per-message Connect limits. Connect v2 reads at most
// 4 MiB per message by default (v1 had no limit) and sends any size. Limits
// apply to each message of a stream, not to the stream as a whole, and the
// send limit counts compressed bytes when the reply is compressed.
type Limits struct {
	// ReadMaxBytes bounds one request message; a larger one fails with
	// CodeResourceExhausted when the handler receives it.
	ReadMaxBytes int
	// SendMaxBytes bounds one response message; a larger reply fails with
	// CodeResourceExhausted instead of being sent.
	SendMaxBytes int
}

// Options are the connecthttp options that apply the limits.
func (l Limits) Options() []connecthttp.Option {
	return []connecthttp.Option{
		connecthttp.WithReadMaxBytes(l.ReadMaxBytes),
		connecthttp.WithSendMaxBytes(l.SendMaxBytes),
	}
}

// Mount serves every procedure registered on server from mux with limits.
func Mount(mux connecthttp.ServeMux, server *connect.Server, limits Limits) {
	connecthttp.Mount(mux, server, limits.Options()...)
}

const (
	mib = 1 << 20

	// MaxBatchEvents is the most events one SendEvent (and the most client
	// states one Live call) may carry, and the largest ListReplayEvents page;
	// handlers.MaxBatchSize is this.
	MaxBatchEvents = 50

	// MaxPageEvents is the most rows one reply pages back: GetHistory caps its
	// limit at 100 events, SearchRooms its page at 100 rooms.
	MaxPageEvents = 100

	// EventBudgetBytes is the wire size an average event in a full batch may
	// take. Media never travels inline: attachments, images, voice and video
	// are uploaded to the files service and an event carries only their URI
	// and their previews' URIs. The largest inline payloads are a
	// 10,000-character text (up to 40 KB, or its E2E ciphertext) and form
	// schemas, whose verbatim copy the room fact already drops above 64 KiB.
	EventBudgetBytes = 160 << 10

	// ChatReadMaxBytes bounds one ChatService request: a full SendEvent batch
	// (MaxBatchEvents × EventBudgetBytes = 7.8 MiB) rounded up to 8 MiB. A
	// single event, a large form schema say, may use the whole budget alone.
	ChatReadMaxBytes = 8 * mib

	// ChatSendMaxBytes bounds one ChatService reply: a page of MaxPageEvents
	// events at EventBudgetBytes (15.6 MiB), doubled for the Struct metadata
	// rooms and subscriptions carry. A Go client that reads ChatService
	// replies (the gateway) must read this much.
	ChatSendMaxBytes = 32 * mib

	// GatewaySendMaxBytes bounds one GatewayService StreamResponse. Each
	// carries one event (or a receipt, presence or typing signal), and every
	// event entered chat through a request of at most ChatReadMaxBytes, so a
	// reply is that plus 1 MiB of envelope.
	GatewaySendMaxBytes = ChatReadMaxBytes + mib
)

// Chat returns ChatService's limits.
func Chat() Limits {
	return Limits{ReadMaxBytes: ChatReadMaxBytes, SendMaxBytes: ChatSendMaxBytes}
}

// Gateway returns GatewayService's limits. A device's StreamRequest carries
// one ClientCommand, at most one RoomEvent, so it reads what ChatService
// reads.
func Gateway() Limits {
	return Limits{ReadMaxBytes: ChatReadMaxBytes, SendMaxBytes: GatewaySendMaxBytes}
}
