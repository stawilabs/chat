package business

import (
	"context"
	"math"
	"strconv"

	"buf.build/gen/go/antinvestor/chat/connectrpc/go/chat/v1/chatv1connect"
	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	"connectrpc.com/connect"
)

type replayClient interface {
	ListRooms(ctx context.Context, offset, limit int) ([]*chatv1.Room, error)
	GetHistory(ctx context.Context, roomID, cursor string, limit int) ([]*chatv1.RoomEvent, error)
	GetEvent(ctx context.Context, eventID string) (*chatv1.RoomEvent, error)
}

type chatReplayClient struct {
	chatClient chatv1connect.ChatServiceClient
}

func newChatReplayClient(chatClient chatv1connect.ChatServiceClient) replayClient {
	if chatClient == nil {
		return nil
	}

	return &chatReplayClient{chatClient: chatClient}
}

func (rc *chatReplayClient) ListRooms(ctx context.Context, offset, limit int) ([]*chatv1.Room, error) {
	stream, err := rc.chatClient.SearchRooms(ctx, connect.NewRequest(&chatv1.SearchRoomsRequest{
		Query: "",
		Cursor: &commonv1.PageCursor{
			Page:  strconv.Itoa(offset),
			Limit: safeInt32Limit(limit),
		},
	}))
	if err != nil {
		return nil, err
	}
	defer func() { _ = stream.Close() }()

	rooms := make([]*chatv1.Room, 0, limit)
	for stream.Receive() {
		msg := stream.Msg()
		if msg == nil {
			continue
		}
		rooms = append(rooms, msg.GetData()...)
	}

	streamErr := stream.Err()
	if streamErr != nil {
		return nil, streamErr
	}

	return rooms, nil
}

func (rc *chatReplayClient) GetHistory(
	ctx context.Context,
	roomID string,
	cursor string,
	limit int,
) ([]*chatv1.RoomEvent, error) {
	resp, err := rc.chatClient.GetHistory(ctx, connect.NewRequest(&chatv1.GetHistoryRequest{
		RoomId:  roomID,
		Forward: true,
		Cursor: &commonv1.PageCursor{
			Page:  cursor,
			Limit: safeInt32Limit(limit),
		},
	}))
	if err != nil {
		return nil, err
	}

	return resp.Msg.GetEvents(), nil
}

func (rc *chatReplayClient) GetEvent(ctx context.Context, eventID string) (*chatv1.RoomEvent, error) {
	resp, err := rc.chatClient.GetEvent(ctx, connect.NewRequest(&chatv1.GetEventRequest{
		EventId: eventID,
	}))
	if err != nil {
		return nil, err
	}

	return resp.Msg.GetEvent(), nil
}

func safeInt32Limit(limit int) int32 {
	if limit <= 0 {
		return 0
	}
	if limit > math.MaxInt32 {
		return math.MaxInt32
	}
	return int32(limit)
}
