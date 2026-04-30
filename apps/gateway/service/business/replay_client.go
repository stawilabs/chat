package business

import (
	"context"
	"errors"
	"fmt"

	"buf.build/gen/go/stawi/chat/connectrpc/go/chat/v1/chatv1connect"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"google.golang.org/protobuf/proto"
)

type replayClient interface {
	ResolveCursor(ctx context.Context, profileID, deviceID, token string) (string, bool, error)
	LatestCursor(ctx context.Context, profileID, deviceID string) (string, error)
	ListAfterCursor(
		ctx context.Context,
		profileID string,
		deviceID string,
		afterCursor string,
		upperBoundCursor string,
		limit int,
	) ([]*chatv1.StreamResponse, error)
}

type rpcReplayClient struct {
	chatClient chatv1connect.ChatServiceClient
}

func newChatReplayClient(chatClient chatv1connect.ChatServiceClient) replayClient {
	if chatClient == nil {
		return nil
	}

	return &rpcReplayClient{chatClient: chatClient}
}

func (rc *rpcReplayClient) ResolveCursor(
	ctx context.Context,
	profileID string,
	deviceID string,
	token string,
) (string, bool, error) {
	if token == "" {
		return "", false, nil
	}

	resp, err := rc.chatClient.ResolveReplayCursor(ctx, connect.NewRequest(&chatv1.ResolveReplayCursorRequest{
		ProfileId: profileID,
		DeviceId:  deviceID,
		Token:     token,
	}))
	if err != nil {
		return "", false, fmt.Errorf("resolve replay cursor RPC failed: %w", err)
	}

	return resp.Msg.GetCursor(), resp.Msg.GetFound(), nil
}

func (rc *rpcReplayClient) LatestCursor(ctx context.Context, profileID, deviceID string) (string, error) {
	resp, err := rc.chatClient.GetLatestReplayCursor(ctx, connect.NewRequest(&chatv1.GetLatestReplayCursorRequest{
		ProfileId: profileID,
		DeviceId:  deviceID,
	}))
	if err != nil {
		return "", fmt.Errorf("get latest replay cursor RPC failed: %w", err)
	}

	return resp.Msg.GetCursor(), nil
}

func (rc *rpcReplayClient) ListAfterCursor(
	ctx context.Context,
	profileID string,
	deviceID string,
	afterCursor string,
	upperBoundCursor string,
	limit int,
) ([]*chatv1.StreamResponse, error) {
	resp, err := rc.chatClient.ListReplayEvents(ctx, connect.NewRequest(&chatv1.ListReplayEventsRequest{
		ProfileId:        profileID,
		DeviceId:         deviceID,
		AfterCursor:      afterCursor,
		UpperBoundCursor: upperBoundCursor,
		Limit:            int32(min(limit, maxInt32)), //nolint:gosec // capped to int32 range
	}))
	if err != nil {
		return nil, fmt.Errorf("list replay events RPC failed: %w", err)
	}

	entries := resp.Msg.GetEntries()
	responses := make([]*chatv1.StreamResponse, 0, len(entries))
	for _, entry := range entries {
		if entry == nil || len(entry.GetResponseData()) == 0 {
			continue
		}

		response := &chatv1.StreamResponse{}
		if unmarshalErr := proto.Unmarshal(entry.GetResponseData(), response); unmarshalErr != nil {
			return nil, errors.New("failed to decode stored replay response")
		}
		responses = append(responses, response)
	}

	return responses, nil
}
