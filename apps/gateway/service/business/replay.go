package business

import (
	"context"
	"errors"
	"fmt"
	"time"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/pitabwire/util"
)

const (
	minResumeTokenTTL         = 15 * time.Minute
	emptyResumeCursorSentinel = "__empty__"
)

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

	replayedCursor, replayedCount, err := cm.replayMissedEvents(ctx, conn, stream, cursor)
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

	cursor, found, err := cm.replayCli.ResolveCursor(lookupCtx, profileID, deviceID, token)
	if err != nil {
		return "", fmt.Errorf("failed to resolve resume token: %w", err)
	}
	if found {
		return cursor, nil
	}

	util.Log(ctx).WithFields(map[string]any{
		"profile_id":   profileID,
		"device_id":    deviceID,
		"resume_token": token,
	}).Warn("resume token could not be resolved; client must resync")
	return "", connect.NewError(
		connect.CodeFailedPrecondition,
		errors.New("resume token is invalid or expired; perform a full sync and reconnect"),
	)
}

//nolint:gocognit // Replay must enforce boundaries, page iteratively, and fail closed on oversized catch-up windows.
func (cm *connectionManager) replayMissedEvents(
	ctx context.Context,
	conn Connection,
	stream DeviceStream,
	cursor string,
) (string, int, error) {
	if cm.replayCli == nil {
		return cursor, 0, nil
	}

	boundaryCtx, cancel := context.WithTimeout(ctx, resumeReplayTimeout)
	defer cancel()

	boundary, err := cm.replayCli.LatestCursor(boundaryCtx, conn.Metadata().ProfileID, conn.Metadata().DeviceID)
	if err != nil {
		return "", 0, fmt.Errorf("failed to determine replay boundary: %w", err)
	}
	if boundary == "" || (cursor != "" && boundary <= cursor) {
		return cursor, 0, nil
	}

	lastDurableCursor := cursor
	replayedCount := 0
	nextCursor := cursor

	for {
		if replayedCount >= cm.resumeMaxEvents {
			return "", 0, connect.NewError(
				connect.CodeFailedPrecondition,
				errors.New("resume replay window exceeded; perform a full sync and reconnect"),
			)
		}

		reqCtx, reqCancel := context.WithTimeout(ctx, resumeReplayTimeout)
		responses, listErr := cm.replayCli.ListAfterCursor(
			reqCtx,
			conn.Metadata().ProfileID,
			conn.Metadata().DeviceID,
			nextCursor,
			boundary,
			cm.resumeHistoryPageSize,
		)
		reqCancel()
		if listErr != nil {
			return "", 0, fmt.Errorf("failed to fetch replay responses: %w", listErr)
		}
		if len(responses) == 0 {
			break
		}

		for _, response := range responses {
			if response == nil || response.GetId() == "" {
				continue
			}
			if response.GetMessage() != nil {
				lastDurableCursor = response.GetId()
			}
			if sendErr := cm.sendStreamResponse(ctx, conn, stream, response, &lastDurableCursor); sendErr != nil {
				return "", 0, sendErr
			}
			replayedCount++
			nextCursor = response.GetId()
			if replayedCount >= cm.resumeMaxEvents && nextCursor < boundary {
				return "", 0, connect.NewError(
					connect.CodeFailedPrecondition,
					errors.New("resume replay window exceeded; perform a full sync and reconnect"),
				)
			}
		}

		if nextCursor >= boundary || len(responses) < cm.resumeHistoryPageSize {
			break
		}
	}

	return lastDurableCursor, replayedCount, nil
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
