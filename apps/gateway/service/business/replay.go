package business

import (
	"container/heap"
	"context"
	"errors"
	"fmt"
	"time"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/pitabwire/util"
	"google.golang.org/protobuf/types/known/timestamppb"
)

const (
	minResumeTokenTTL         = 15 * time.Minute
	emptyResumeCursorSentinel = "__empty__"
)

type replayState struct {
	roomID    string
	cursor    string
	buffer    []*chatv1.RoomEvent
	index     int
	hasMore   bool
	exhausted bool
}

type replayItem struct {
	event      *chatv1.RoomEvent
	stateIndex int
}

type replayHeap []*replayItem

func (h *replayHeap) Len() int { return len(*h) }

func (h *replayHeap) Less(i, j int) bool {
	return (*h)[i].event.GetId() < (*h)[j].event.GetId()
}

func (h *replayHeap) Swap(i, j int) {
	(*h)[i], (*h)[j] = (*h)[j], (*h)[i]
}

func (h *replayHeap) Push(x any) {
	item, ok := x.(*replayItem)
	if !ok {
		return
	}
	*h = append(*h, item)
}

func (h *replayHeap) Pop() any {
	old := *h
	n := len(old)
	item := old[n-1]
	*h = old[:n-1]
	return item
}

func (cm *connectionManager) resumeConnection(
	ctx context.Context,
	conn Connection,
	stream DeviceStream,
	hello *chatv1.StreamHello,
) (string, int, error) {
	if hello == nil || hello.GetResumeToken() == "" {
		return "", 0, nil
	}

	cursor, err := cm.resolveResumeCursor(
		ctx,
		conn.Metadata().ProfileID,
		conn.Metadata().DeviceID,
		hello.GetResumeToken(),
	)
	if err != nil {
		return "", 0, err
	}

	if cursor == "" {
		return "", 0, nil
	}

	boundary := util.IDString()
	replayedCursor, replayedCount, err := cm.replayMissedEvents(ctx, conn, stream, cursor, boundary)
	if err != nil {
		return "", 0, err
	}

	return replayedCursor, replayedCount, nil
}

func (cm *connectionManager) resolveResumeCursor(
	ctx context.Context,
	profileID string,
	deviceID string,
	token string,
) (string, error) {
	if token == "" {
		return "", nil
	}

	lookupCtx, cancel := context.WithTimeout(ctx, resumeLookupTimeout)
	defer cancel()

	if cm.resume != nil {
		cursor, found, err := cm.resume.Get(lookupCtx, resumeTokenKey(profileID, deviceID, token))
		if err != nil {
			return "", fmt.Errorf("resume token lookup failed: %w", err)
		}
		if found {
			if cursor == emptyResumeCursorSentinel {
				return "", nil
			}
			return cursor, nil
		}
	}

	if cm.replayCli == nil {
		return "", connect.NewError(connect.CodeFailedPrecondition, errors.New("resume replay unavailable"))
	}

	_, err := cm.replayCli.GetEvent(lookupCtx, token)
	if err == nil {
		return token, nil
	}

	//nolint:exhaustive // All non-retryable token resolution failures are handled explicitly; the rest bubble up.
	switch connect.CodeOf(err) {
	case connect.CodeNotFound,
		connect.CodePermissionDenied,
		connect.CodeInvalidArgument,
		connect.CodeFailedPrecondition:
		util.Log(ctx).WithFields(map[string]any{
			"profile_id":   profileID,
			"device_id":    deviceID,
			"resume_token": token,
		}).Warn("resume token could not be resolved; client must resync")
		return "", connect.NewError(
			connect.CodeFailedPrecondition,
			errors.New("resume token is invalid or expired; perform a full sync and reconnect"),
		)
	default:
		return "", fmt.Errorf("failed to verify resume token: %w", err)
	}
}

//nolint:gocognit // Merge-replay logic coordinates pagination, ordering, and bounded catch-up safety.
func (cm *connectionManager) replayMissedEvents(
	ctx context.Context,
	conn Connection,
	stream DeviceStream,
	cursor string,
	boundary string,
) (string, int, error) {
	roomIDs, err := cm.listReplayRoomIDs(ctx)
	if err != nil {
		return "", 0, err
	}
	if len(roomIDs) == 0 {
		return cursor, 0, nil
	}

	states := make([]*replayState, 0, len(roomIDs))
	queue := &replayHeap{}
	heap.Init(queue)

	for _, roomID := range roomIDs {
		state := &replayState{roomID: roomID, cursor: cursor}
		fillErr := cm.fillReplayState(ctx, state, boundary)
		if fillErr != nil {
			return "", 0, fillErr
		}
		if state.exhausted && len(state.buffer) == 0 {
			continue
		}

		stateIndex := len(states)
		states = append(states, state)
		heap.Push(queue, &replayItem{
			event:      state.buffer[state.index],
			stateIndex: stateIndex,
		})
	}

	lastDurableCursor := cursor
	replayedCount := 0

	for queue.Len() > 0 {
		if replayedCount >= cm.resumeMaxEvents {
			return "", 0, connect.NewError(
				connect.CodeFailedPrecondition,
				errors.New("resume replay window exceeded; perform a full sync and reconnect"),
			)
		}

		rawItem := heap.Pop(queue)
		item, ok := rawItem.(*replayItem)
		if !ok {
			return "", 0, errors.New("invalid replay heap item")
		}
		state := states[item.stateIndex]

		resp := &chatv1.StreamResponse{
			Id:        item.event.GetId(),
			Timestamp: replayTimestamp(item.event),
			Payload: &chatv1.StreamResponse_Message{
				Message: item.event,
			},
		}

		sendErr := cm.sendStreamResponse(ctx, conn, stream, resp, &lastDurableCursor)
		if sendErr != nil {
			return "", 0, sendErr
		}
		replayedCount++

		state.index++
		if state.index >= len(state.buffer) {
			if state.exhausted || !state.hasMore {
				continue
			}
			fillErr := cm.fillReplayState(ctx, state, boundary)
			if fillErr != nil {
				return "", 0, fillErr
			}
			if len(state.buffer) == 0 {
				continue
			}
		}

		heap.Push(queue, &replayItem{
			event:      state.buffer[state.index],
			stateIndex: item.stateIndex,
		})
	}

	return lastDurableCursor, replayedCount, nil
}

func (cm *connectionManager) listReplayRoomIDs(ctx context.Context) ([]string, error) {
	if cm.replayCli == nil {
		return nil, nil
	}

	roomIDs := make([]string, 0, cm.resumeRoomPageSize)
	seen := make(map[string]struct{})

	for offset := 0; offset < cm.resumeMaxRooms; offset += cm.resumeRoomPageSize {
		reqCtx, cancel := context.WithTimeout(ctx, resumeReplayTimeout)
		rooms, err := cm.replayCli.ListRooms(reqCtx, offset, cm.resumeRoomPageSize)
		cancel()
		if err != nil {
			return nil, fmt.Errorf("failed to list subscribed rooms for resume replay: %w", err)
		}

		for _, room := range rooms {
			if room == nil || room.GetId() == "" {
				continue
			}
			if _, ok := seen[room.GetId()]; ok {
				continue
			}
			seen[room.GetId()] = struct{}{}
			roomIDs = append(roomIDs, room.GetId())
			if len(roomIDs) > cm.resumeMaxRooms {
				return nil, connect.NewError(
					connect.CodeFailedPrecondition,
					errors.New("too many subscribed rooms for resume replay; perform a full sync and reconnect"),
				)
			}
		}

		if len(rooms) < cm.resumeRoomPageSize {
			break
		}
	}

	return roomIDs, nil
}

func (cm *connectionManager) fillReplayState(
	ctx context.Context,
	state *replayState,
	boundary string,
) error {
	if state == nil || state.exhausted {
		return nil
	}

	reqCtx, cancel := context.WithTimeout(ctx, resumeReplayTimeout)
	defer cancel()

	events, err := cm.replayCli.GetHistory(reqCtx, state.roomID, state.cursor, cm.resumeHistoryPageSize)
	if err != nil {
		return fmt.Errorf("failed to fetch replay history for room %s: %w", state.roomID, err)
	}

	state.buffer = state.buffer[:0]
	state.index = 0
	state.hasMore = false

	for _, event := range events {
		if event == nil || event.GetId() == "" {
			continue
		}
		if boundary != "" && event.GetId() >= boundary {
			state.exhausted = true
			break
		}
		state.buffer = append(state.buffer, event)
	}

	if len(state.buffer) == 0 {
		state.exhausted = state.exhausted || len(events) < cm.resumeHistoryPageSize
		return nil
	}

	state.cursor = state.buffer[len(state.buffer)-1].GetId()
	state.hasMore = !state.exhausted && len(events) == cm.resumeHistoryPageSize
	if !state.hasMore {
		state.exhausted = true
	}

	return nil
}

func (cm *connectionManager) sendStreamResponse(
	ctx context.Context,
	conn Connection,
	stream DeviceStream,
	response *chatv1.StreamResponse,
	lastDurableCursor *string,
) error {
	if err := stream.Send(response); err != nil {
		return fmt.Errorf("%w: %w", ErrStreamSendFailed, err)
	}

	cm.touchConnection(ctx, conn, false)

	if lastDurableCursor != nil {
		nextCursor := *lastDurableCursor
		if response.GetMessage() != nil && response.GetId() != "" {
			nextCursor = response.GetId()
		}
		if err := cm.persistResumeToken(
			ctx,
			conn.Metadata().ProfileID,
			conn.Metadata().DeviceID,
			response.GetId(),
			nextCursor,
		); err != nil {
			util.Log(ctx).WithError(err).WithFields(map[string]any{
				"profile_id":  conn.Metadata().ProfileID,
				"device_id":   conn.Metadata().DeviceID,
				"response_id": response.GetId(),
			}).Warn("failed to persist resume token state")
		}
		*lastDurableCursor = nextCursor
	}

	return nil
}

func (cm *connectionManager) persistResumeToken(
	ctx context.Context,
	profileID string,
	deviceID string,
	token string,
	cursor string,
) error {
	if token == "" || cm.resume == nil {
		return nil
	}

	if cursor == "" {
		cursor = emptyResumeCursorSentinel
	}

	return cm.resume.Set(ctx, resumeTokenKey(profileID, deviceID, token), cursor, cm.resumeTokenTTL())
}

func (cm *connectionManager) resumeTokenTTL() time.Duration {
	ttl := cm.metadataTTL() * cacheTTLMultiplier
	if ttl < minResumeTokenTTL {
		ttl = minResumeTokenTTL
	}
	return ttl
}

func resumeTokenKey(profileID string, deviceID string, token string) string {
	return fmt.Sprintf("gateway:resume:%s:%s:%s", profileID, deviceID, token)
}

func replayTimestamp(event *chatv1.RoomEvent) *timestamppb.Timestamp {
	if event != nil && event.GetSentAt() != nil {
		return event.GetSentAt()
	}
	return timestamppb.Now()
}
