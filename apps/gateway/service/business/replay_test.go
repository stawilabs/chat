package business

import (
	"context"
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
	resolveCursorFn func(ctx context.Context, profileID, deviceID, token string) (string, bool, error)
	latestCursorFn  func(ctx context.Context, profileID, deviceID string) (string, error)
	listAfterFn     func(
		ctx context.Context,
		profileID string,
		deviceID string,
		afterCursor string,
		upperBoundCursor string,
		limit int,
	) ([]*chatv1.StreamResponse, error)
}

func (s *stubReplayClient) ResolveCursor(
	ctx context.Context,
	profileID string,
	deviceID string,
	token string,
) (string, bool, error) {
	if s.resolveCursorFn == nil {
		return "", false, nil
	}
	return s.resolveCursorFn(ctx, profileID, deviceID, token)
}

func (s *stubReplayClient) LatestCursor(ctx context.Context, profileID, deviceID string) (string, error) {
	if s.latestCursorFn == nil {
		return "", nil
	}
	return s.latestCursorFn(ctx, profileID, deviceID)
}

func (s *stubReplayClient) ListAfterCursor(
	ctx context.Context,
	profileID string,
	deviceID string,
	afterCursor string,
	upperBoundCursor string,
	limit int,
) ([]*chatv1.StreamResponse, error) {
	if s.listAfterFn == nil {
		return nil, nil
	}
	return s.listAfterFn(ctx, profileID, deviceID, afterCursor, upperBoundCursor, limit)
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
		resume:                resumeCache,
		connectionTimeoutSec:  300,
		heartbeatIntervalSec:  30,
		resumeRoomPageSize:    50,
		resumeHistoryPageSize: 50,
		resumeMaxRooms:        250,
		resumeMaxEvents:       1000,
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
		replayCli:             &stubReplayClient{},
		resumeRoomPageSize:    50,
		resumeHistoryPageSize: 50,
		resumeMaxRooms:        250,
		resumeMaxEvents:       1000,
	}

	cursor, err := cm.resolveResumeCursor(t.Context(), "profile-1", "device-1", "missing-token")
	assert.Empty(t, cursor)
	require.Error(t, err)
	assert.Equal(t, connect.CodeFailedPrecondition, connect.CodeOf(err))
}

func TestConnectionManagerReplayMissedEventsUsesDurableDeviceLog(t *testing.T) {
	rawCache := cache.NewInMemoryCache()
	resumeCache := cache.NewGenericCache[string, string](rawCache, nil)
	responses := []*chatv1.StreamResponse{
		{
			Id:        "cur-002",
			Timestamp: timestamppb.Now(),
			Payload: &chatv1.StreamResponse_Message{
				Message: &chatv1.RoomEvent{Id: "evt-002", RoomId: "room-a", SentAt: timestamppb.Now()},
			},
		},
		{
			Id:        "cur-003",
			Timestamp: timestamppb.Now(),
			Payload: &chatv1.StreamResponse_Message{
				Message: &chatv1.RoomEvent{Id: "evt-003", RoomId: "room-b", SentAt: timestamppb.Now()},
			},
		},
		{
			Id:        "cur-004",
			Timestamp: timestamppb.Now(),
			Payload: &chatv1.StreamResponse_Message{
				Message: &chatv1.RoomEvent{Id: "evt-004", RoomId: "room-a", SentAt: timestamppb.Now()},
			},
		},
		{
			Id:        "cur-005",
			Timestamp: timestamppb.Now(),
			Payload: &chatv1.StreamResponse_Message{
				Message: &chatv1.RoomEvent{Id: "evt-005", RoomId: "room-b", SentAt: timestamppb.Now()},
			},
		},
	}

	cm := &connectionManager{
		replayCli: &stubReplayClient{
			latestCursorFn: func(_ context.Context, _, _ string) (string, error) {
				return "cur-005", nil
			},
			listAfterFn: func(
				_ context.Context,
				_, _ string,
				afterCursor string,
				upperBoundCursor string,
				_ int,
			) ([]*chatv1.StreamResponse, error) {
				filtered := make([]*chatv1.StreamResponse, 0, len(responses))
				for _, response := range responses {
					if response.GetId() > afterCursor && response.GetId() <= upperBoundCursor {
						filtered = append(filtered, response)
					}
				}
				return filtered, nil
			},
		},
		resume:                resumeCache,
		connectionTimeoutSec:  300,
		heartbeatIntervalSec:  30,
		connectionOpts:        ConnectionOptions{}.withDefaults(),
		resumeRoomPageSize:    50,
		resumeHistoryPageSize: 50,
		resumeMaxRooms:        250,
		resumeMaxEvents:       1000,
	}

	stream := &replayTestStream{}
	conn := NewConnection(stream, &Metadata{
		ProfileID: "profile-1",
		DeviceID:  "device-1",
	}, ConnectionOptions{}.withDefaults())

	lastCursor, replayed, err := cm.replayMissedEvents(t.Context(), conn, stream, "cur-001")
	require.NoError(t, err)
	assert.Equal(t, 4, replayed)
	assert.Equal(t, "cur-005", lastCursor)

	var ids []string
	for _, response := range stream.sent {
		ids = append(ids, response.GetId())
	}
	assert.Equal(t, []string{"cur-002", "cur-003", "cur-004", "cur-005"}, ids)

	cursor, found, err := resumeCache.Get(t.Context(), resumeTokenKey("profile-1", "device-1", "cur-005"))
	require.NoError(t, err)
	assert.True(t, found)
	assert.Equal(t, "cur-005", cursor)
}
