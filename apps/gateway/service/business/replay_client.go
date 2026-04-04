package business

import (
	"context"
	"errors"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	defaultrepo "github.com/antinvestor/service-chat/apps/default/service/repository"
	"github.com/pitabwire/frame/data"
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

type durableReplayClient struct {
	repo defaultrepo.DeviceReplayRepository
}

func newChatReplayClient(repo defaultrepo.DeviceReplayRepository) replayClient {
	if repo == nil {
		return nil
	}

	return &durableReplayClient{repo: repo}
}

func (rc *durableReplayClient) ResolveCursor(
	ctx context.Context,
	profileID string,
	deviceID string,
	token string,
) (string, bool, error) {
	if token == "" {
		return "", false, nil
	}

	entry, err := rc.repo.GetByCursor(ctx, profileID, deviceID, token)
	if err == nil && entry != nil {
		return entry.GetID(), true, nil
	}
	if err != nil && !data.ErrorIsNoRows(err) {
		return "", false, err
	}

	// Support in-flight rolling upgrades where the client may still present the
	// older event-id-based token from before the gateway switched to replay cursors.
	entry, err = rc.repo.GetByEventID(ctx, profileID, deviceID, token)
	if err == nil && entry != nil {
		return entry.GetID(), true, nil
	}
	if err != nil && !data.ErrorIsNoRows(err) {
		return "", false, err
	}

	return "", false, nil
}

func (rc *durableReplayClient) LatestCursor(ctx context.Context, profileID, deviceID string) (string, error) {
	return rc.repo.GetLatestCursor(ctx, profileID, deviceID)
}

func (rc *durableReplayClient) ListAfterCursor(
	ctx context.Context,
	profileID string,
	deviceID string,
	afterCursor string,
	upperBoundCursor string,
	limit int,
) ([]*chatv1.StreamResponse, error) {
	entries, err := rc.repo.ListAfterCursor(ctx, profileID, deviceID, afterCursor, upperBoundCursor, limit)
	if err != nil {
		return nil, err
	}

	responses := make([]*chatv1.StreamResponse, 0, len(entries))
	for _, entry := range entries {
		response, convErr := entry.ToStreamResponse()
		if convErr != nil {
			return nil, errors.New("failed to decode stored replay response")
		}
		if response == nil {
			continue
		}
		responses = append(responses, response)
	}

	return responses, nil
}
