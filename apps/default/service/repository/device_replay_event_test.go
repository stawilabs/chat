package repository_test

import (
	"context"
	"testing"
	"time"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"github.com/pitabwire/frame/v2/frametests"
	"github.com/pitabwire/frame/v2/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/tests"
)

type DeviceReplayRepositoryTestSuite struct {
	tests.BaseTestSuite
}

func TestDeviceReplayRepositoryTestSuite(t *testing.T) {
	suite.Run(t, new(DeviceReplayRepositoryTestSuite))
}

func (s *DeviceReplayRepositoryTestSuite) withRepo(
	testFunc func(t *testing.T, ctx context.Context, repo repository.DeviceReplayRepository),
) {
	frametests.WithTestDependencies(s.T(), nil, func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan, dbPool := s.GetRepoDeps(ctx, svc)
		repo := repository.NewDeviceReplayRepository(ctx, dbPool, workMan)
		testFunc(t, ctx, repo)
	})
}

func (s *DeviceReplayRepositoryTestSuite) TestListAfterCursorAndTrimDevice() {
	s.withRepo(func(t *testing.T, ctx context.Context, repo repository.DeviceReplayRepository) {
		profileID := util.IDString()
		deviceID := util.IDString()

		var entries []*models.DeviceReplayEvent
		for idx := range 3 {
			response := &chatv1.StreamResponse{
				Id:        util.IDString(),
				Timestamp: timestamppb.Now(),
				Payload: &chatv1.StreamResponse_Message{
					Message: &chatv1.RoomEvent{
						Id:     util.IDString(),
						RoomId: util.IDString(),
						SentAt: timestamppb.Now(),
					},
				},
			}
			payload, err := proto.Marshal(response)
			require.NoError(t, err)

			entry := &models.DeviceReplayEvent{
				ProfileID:    profileID,
				DeviceID:     deviceID,
				EventID:      util.IDString(),
				RoomID:       util.IDString(),
				EventType:    int32(chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE.Number()),
				ResponseData: payload,
			}
			entry.GenID(ctx)
			entry.CreatedAt = time.Now().Add(-time.Duration(3-idx) * time.Hour)
			entries = append(entries, entry)
		}

		require.NoError(t, repo.CreateIgnoringDuplicates(ctx, entries))

		listed, err := repo.ListAfterCursor(ctx, profileID, deviceID, "", "", 10)
		require.NoError(t, err)
		require.Len(t, listed, 3)

		cursor := listed[0].GetID()
		listed, err = repo.ListAfterCursor(ctx, profileID, deviceID, cursor, "", 10)
		require.NoError(t, err)
		require.Len(t, listed, 2)

		response, err := listed[0].ToStreamResponse()
		require.NoError(t, err)
		require.NotNil(t, response)
		require.NotEmpty(t, response.GetMessage().GetId())

		require.NoError(t, repo.TrimDevice(ctx, profileID, deviceID, 1, 2*time.Hour))

		listed, err = repo.ListAfterCursor(ctx, profileID, deviceID, "", "", 10)
		require.NoError(t, err)
		require.Len(t, listed, 1)
	})
}
