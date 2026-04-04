package business

import (
	"context"
	"errors"
	"io"
	"testing"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/pitabwire/frame/cache"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/types/known/timestamppb"
)

type stubReplayClient struct {
	listRoomsFn  func(ctx context.Context, offset, limit int) ([]*chatv1.Room, error)
	getHistoryFn func(ctx context.Context, roomID, cursor string, limit int) ([]*chatv1.RoomEvent, error)
	getEventFn   func(ctx context.Context, eventID string) (*chatv1.RoomEvent, error)
}

func (s *stubReplayClient) ListRooms(ctx context.Context, offset, limit int) ([]*chatv1.Room, error) {
	if s.listRoomsFn == nil {
		return nil, nil
	}
	return s.listRoomsFn(ctx, offset, limit)
}

func (s *stubReplayClient) GetHistory(
	ctx context.Context,
	roomID string,
	cursor string,
	limit int,
) ([]*chatv1.RoomEvent, error) {
	if s.getHistoryFn == nil {
		return nil, nil
	}
	return s.getHistoryFn(ctx, roomID, cursor, limit)
}

func (s *stubReplayClient) GetEvent(ctx context.Context, eventID string) (*chatv1.RoomEvent, error) {
	if s.getEventFn == nil {
		return nil, connect.NewError(connect.CodeNotFound, errors.New("not found"))
	}
	return s.getEventFn(ctx, eventID)
}

type replayTestStream struct {
	sent []*chatv1.StreamResponse
}

func (s *replayTestStream) Receive() (*chatv1.StreamRequest, error) {
	return nil, io.EOF
}

func (s *replayTestStream) Send(response *chatv1.StreamResponse) error {
	s.sent = append(s.sent, response)
	return nil
}

func TestConnectionManagerResolveResumeCursorFromCache(t *testing.T) {
	rawCache := cache.NewInMemoryCache()
	resumeCache := cache.NewGenericCache[string, string](rawCache, nil)

	cm := &connectionManager{
		resume:               resumeCache,
		connectionTimeoutSec: 300,
		heartbeatIntervalSec: 30,
	}

	err := resumeCache.Set(
		t.Context(),
		resumeTokenKey("profile-1", "device-1", "token-1"),
		"evt-123",
		cm.resumeTokenTTL(),
	)
	require.NoError(t, err)

	cursor, err := cm.resolveResumeCursor(t.Context(), "profile-1", "device-1", "token-1")
	require.NoError(t, err)
	assert.Equal(t, "evt-123", cursor)
}

func TestConnectionManagerResolveResumeCursorRejectsUnknownToken(t *testing.T) {
	cm := &connectionManager{
		replayCli: &stubReplayClient{},
	}

	cursor, err := cm.resolveResumeCursor(t.Context(), "profile-1", "device-1", "missing-token")
	assert.Empty(t, cursor)
	require.Error(t, err)
	assert.Equal(t, connect.CodeFailedPrecondition, connect.CodeOf(err))
}

func TestConnectionManagerReplayMissedEventsMergesRooms(t *testing.T) {
	rawCache := cache.NewInMemoryCache()
	resumeCache := cache.NewGenericCache[string, string](rawCache, nil)

	historyByRoom := map[string]map[string][]*chatv1.RoomEvent{
		"room-a": {
			"evt-001": {
				{Id: "evt-002", RoomId: "room-a", SentAt: timestamppb.Now()},
				{Id: "evt-004", RoomId: "room-a", SentAt: timestamppb.Now()},
				{Id: "evt-006", RoomId: "room-a", SentAt: timestamppb.Now()},
			},
		},
		"room-b": {
			"evt-001": {
				{Id: "evt-003", RoomId: "room-b", SentAt: timestamppb.Now()},
				{Id: "evt-005", RoomId: "room-b", SentAt: timestamppb.Now()},
			},
		},
	}

	cm := &connectionManager{
		replayCli: &stubReplayClient{
			listRoomsFn: func(_ context.Context, offset, _ int) ([]*chatv1.Room, error) {
				if offset > 0 {
					return nil, nil
				}
				return []*chatv1.Room{
					{Id: "room-a"},
					{Id: "room-b"},
				}, nil
			},
			getHistoryFn: func(_ context.Context, roomID, cursor string, _ int) ([]*chatv1.RoomEvent, error) {
				return historyByRoom[roomID][cursor], nil
			},
		},
		resume:               resumeCache,
		connectionTimeoutSec: 300,
		heartbeatIntervalSec: 30,
	}

	stream := &replayTestStream{}
	conn := NewConnection(stream, &Metadata{
		ProfileID: "profile-1",
		DeviceID:  "device-1",
	})

	lastCursor, replayed, err := cm.replayMissedEvents(t.Context(), conn, stream, "evt-001", "evt-006")
	require.NoError(t, err)
	assert.Equal(t, 4, replayed)
	assert.Equal(t, "evt-005", lastCursor)

	var ids []string
	for _, response := range stream.sent {
		ids = append(ids, response.GetId())
	}
	assert.Equal(t, []string{"evt-002", "evt-003", "evt-004", "evt-005"}, ids)

	cursor, found, err := resumeCache.Get(t.Context(), resumeTokenKey("profile-1", "device-1", "evt-005"))
	require.NoError(t, err)
	assert.True(t, found)
	assert.Equal(t, "evt-005", cursor)
}
