package connectserver_test

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	"buf.build/gen/go/stawi/chat/connectrpc/go/v2/chat/v1/chatv1connect"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect/v2"
	"connectrpc.com/connect/v2/connecthttp"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/pkg/connectserver"
)

// stub answers GetEvent with err, acknowledges every SendEvent event, and
// pages back n events of size bytes from GetHistory.
type stub struct {
	chatv1connect.UnimplementedChatServiceHandler

	err  error
	n    int
	size int
	runs int
}

func (s *stub) GetEvent(context.Context, *chatv1.GetEventRequest) (*chatv1.GetEventResponse, error) {
	s.runs++
	if s.err != nil {
		return nil, s.err
	}
	return &chatv1.GetEventResponse{}, nil
}

func (s *stub) SendEvent(_ context.Context, req *chatv1.SendEventRequest) (*chatv1.SendEventResponse, error) {
	s.runs++
	out := &chatv1.SendEventResponse{}
	for _, ev := range req.GetEvent() {
		out.Ack = append(out.Ack, &chatv1.AckEvent{EventId: []string{ev.GetId()}})
	}
	return out, nil
}

func (s *stub) GetHistory(context.Context, *chatv1.GetHistoryRequest) (*chatv1.GetHistoryResponse, error) {
	s.runs++
	out := &chatv1.GetHistoryResponse{}
	for range s.n {
		out.Events = append(out.Events, event(s.size))
	}
	return out, nil
}

// event is a room event carrying size bytes of incompressible ciphertext, so
// the limits see its real size.
func event(size int) *chatv1.RoomEvent {
	ciphertext := make([]byte, size)
	_, _ = rand.Read(ciphertext)
	return &chatv1.RoomEvent{
		Id:     "ev-" + rand.Text()[:8],
		RoomId: "room-1",
		Payload: &chatv1.Payload{Data: &chatv1.Payload_Encrypted{
			Encrypted: &chatv1.EncryptedContent{Algorithm: "megolm.v1", Ciphertext: ciphertext},
		}},
	}
}

func small() connectserver.Limits {
	return connectserver.Limits{ReadMaxBytes: 4 << 10, SendMaxBytes: 16 << 10}
}

func serve(t *testing.T, s *stub, limits connectserver.Limits, readMax int) chatv1connect.ChatServiceClient {
	t.Helper()
	server := connect.NewServer(connectserver.ErrorInterceptor())
	chatv1connect.RegisterChatServiceHandler(server, s)
	mux := http.NewServeMux()
	connectserver.Mount(mux, server, limits)
	srv := httptest.NewServer(mux)
	t.Cleanup(srv.Close)
	return chatv1connect.NewChatServiceClient(connect.NewClient(
		connecthttp.NewTransport(srv.Client(), srv.URL, connecthttp.WithReadMaxBytes(readMax)),
	))
}

func getEvent(t *testing.T, err error) *connect.Error {
	t.Helper()
	cli := serve(t, &stub{err: err}, small(), 0)
	_, got := cli.GetEvent(t.Context(), &chatv1.GetEventRequest{RoomId: "room-1", EventId: "ev-1"})
	var ce *connect.Error
	require.ErrorAs(t, got, &ce)
	return ce
}

// A business error a handler builds keeps its code and message on the wire.
func TestBusinessErrorArrivesWithItsCode(t *testing.T) {
	ce := getEvent(t, connect.NewError(connect.CodeNotFound, "no event ev-1"))
	require.Equal(t, connect.CodeNotFound, ce.Code())
	require.Equal(t, "no event ev-1", ce.Message())
}

// Connect v2 would send a plain error as a bare CodeUnknown; v1 sent its text.
func TestPlainErrorKeepsItsMessage(t *testing.T) {
	ce := getEvent(t, fmt.Errorf("history: %w", errors.New("row missing")))
	require.Equal(t, connect.CodeUnknown, ce.Code())
	require.Equal(t, "history: row missing", ce.Message())
}

// A downstream service's verdict (settlement refusing a room act), wrapped on
// its way out, keeps its code and message; connect v2 alone would send
// CodeInternal with no message.
func TestRemoteErrorKeepsItsCodeAndMessage(t *testing.T) {
	remote := connect.NewError(connect.CodeFailedPrecondition, "room frozen").WithRemote()
	ce := getEvent(t, fmt.Errorf("settlement: %w", remote))
	require.Equal(t, connect.CodeFailedPrecondition, ce.Code())
	require.Equal(t, "room frozen", ce.Message())
}

func TestToAPI(t *testing.T) {
	require.NoError(t, connectserver.ToAPI(nil))

	local := connect.NewError(connect.CodeAborted, "x")
	require.Same(t, local, connectserver.ToAPI(local))
	wrapped := fmt.Errorf("op: %w", local)
	require.Equal(
		t,
		wrapped,
		connectserver.ToAPI(wrapped),
		"a local *connect.Error in the chain is left for the transport",
	)

	require.Equal(t, connect.CodeCanceled, connect.CodeOf(connectserver.ToAPI(fmt.Errorf("op: %w", context.Canceled))))
	require.Equal(t, connect.CodeDeadlineExceeded, connect.CodeOf(connectserver.ToAPI(context.DeadlineExceeded)))

	cause := errors.New("boom")
	require.ErrorIs(t, connectserver.ToAPI(cause), cause, "the cause stays matchable on the server")
}

// A request over the read limit is refused before the handler runs.
func TestReadLimit(t *testing.T) {
	s := &stub{}
	cli := serve(t, s, small(), 0)
	_, err := cli.SendEvent(t.Context(), &chatv1.SendEventRequest{Event: []*chatv1.RoomEvent{event(8 << 10)}})
	require.Equal(t, connect.CodeResourceExhausted, connect.CodeOf(err), "%v", err)
	require.Zero(t, s.runs)

	res, err := cli.SendEvent(t.Context(), &chatv1.SendEventRequest{Event: []*chatv1.RoomEvent{event(1 << 10)}})
	require.NoError(t, err)
	require.Len(t, res.GetAck(), 1)
}

// A reply over the send limit fails instead of being sent.
func TestSendLimit(t *testing.T) {
	cli := serve(t, &stub{n: 40, size: 1 << 10}, small(), 0)
	_, err := cli.GetHistory(t.Context(), &chatv1.GetHistoryRequest{RoomId: "room-1"})
	require.Equal(t, connect.CodeResourceExhausted, connect.CodeOf(err), "%v", err)

	cli = serve(t, &stub{n: 4, size: 1 << 10}, small(), 0)
	res, err := cli.GetHistory(t.Context(), &chatv1.GetHistoryRequest{RoomId: "room-1"})
	require.NoError(t, err)
	require.Len(t, res.GetEvents(), 4)
}

// ChatService's real limits take a full SendEvent batch of budget-sized
// events, which is over connect v2's 4 MiB default, and page a full history
// page of them back to a client that reads ChatSendMaxBytes.
func TestChatLimitsCarryAFullBatchAndPage(t *testing.T) {
	// Leave room for the envelope of each event and the batch.
	size := connectserver.EventBudgetBytes - 1<<10

	batch := make([]*chatv1.RoomEvent, connectserver.MaxBatchEvents)
	for i := range batch {
		batch[i] = event(size)
	}
	s := &stub{n: connectserver.MaxPageEvents, size: size}
	cli := serve(t, s, connectserver.Chat(), connectserver.ChatSendMaxBytes)

	res, err := cli.SendEvent(t.Context(), &chatv1.SendEventRequest{Event: batch})
	require.NoError(t, err)
	require.Len(t, res.GetAck(), connectserver.MaxBatchEvents)

	page, err := cli.GetHistory(t.Context(), &chatv1.GetHistoryRequest{RoomId: "room-1"})
	require.NoError(t, err)
	require.Len(t, page.GetEvents(), connectserver.MaxPageEvents)

	// One more budget than the read limit allows is refused.
	_, err = cli.SendEvent(
		t.Context(),
		&chatv1.SendEventRequest{Event: []*chatv1.RoomEvent{event(connectserver.ChatReadMaxBytes)}},
	)
	require.Equal(t, connect.CodeResourceExhausted, connect.CodeOf(err), "%v", err)
}

// The limits hold together: a batch fits a request, a page fits a reply,
// and the gateway sends any one event chat accepted.
func TestLimitsAreConsistent(t *testing.T) {
	require.GreaterOrEqual(
		t,
		connectserver.ChatReadMaxBytes,
		connectserver.MaxBatchEvents*connectserver.EventBudgetBytes,
	)
	require.GreaterOrEqual(
		t,
		connectserver.ChatSendMaxBytes,
		connectserver.MaxPageEvents*connectserver.EventBudgetBytes,
	)
	require.Greater(t, connectserver.GatewaySendMaxBytes, connectserver.ChatReadMaxBytes)
	require.Equal(t, connectserver.ChatReadMaxBytes, connectserver.Gateway().ReadMaxBytes)
	require.Equal(t, connectserver.GatewaySendMaxBytes, connectserver.Gateway().SendMaxBytes)
	require.Equal(t, connectserver.ChatSendMaxBytes, connectserver.Chat().SendMaxBytes)
}
