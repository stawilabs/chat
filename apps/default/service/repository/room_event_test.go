package repository_test

import (
	"context"
	"testing"
	"time"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"github.com/pitabwire/frame/v2/data"
	"github.com/pitabwire/frame/v2/frametests"
	"github.com/pitabwire/frame/v2/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"

	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/tests"
)

type EventRepositoryTestSuite struct {
	tests.BaseTestSuite
}

func TestEventRepositoryTestSuite(t *testing.T) {
	suite.Run(t, new(EventRepositoryTestSuite))
}

func (s *EventRepositoryTestSuite) withRepo(
	testFunc func(t *testing.T, ctx context.Context, repo repository.RoomEventRepository),
) {
	frametests.WithTestDependencies(s.T(), nil, func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan, dbPool := s.GetRepoDeps(ctx, svc)
		repo := repository.NewRoomEventRepository(ctx, dbPool, workMan)
		testFunc(t, ctx, repo)
	})
}

func (s *EventRepositoryTestSuite) TestCreateEvent() {
	s.withRepo(func(t *testing.T, ctx context.Context, repo repository.RoomEventRepository) {
		event := &models.RoomEvent{
			RoomID:     util.IDString(),
			SenderID:   util.IDString(),
			EventType:  int32(chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE.Number()),
			Content:    data.JSONMap{"text": "Hello World"},
			Properties: data.JSONMap{"key": "value"},
		}
		event.GenID(ctx)

		err := repo.Create(ctx, event)
		require.NoError(t, err)
		s.NotEmpty(event.GetID())

		retrieved, err := repo.GetByID(ctx, event.GetID())
		require.NoError(t, err)
		s.Equal(event.RoomID, retrieved.RoomID)
		s.Equal(event.SenderID, retrieved.SenderID)
		s.Equal(event.EventType, retrieved.EventType)
	})
}

func (s *EventRepositoryTestSuite) TestGetHistory() {
	s.withRepo(func(t *testing.T, ctx context.Context, repo repository.RoomEventRepository) {
		roomID := util.IDString()
		senderID := util.IDString()

		for range 10 {
			event := &models.RoomEvent{
				RoomID:    roomID,
				SenderID:  senderID,
				EventType: int32(chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE.Number()),
				Content:   data.JSONMap{"text": util.RandomAlphaNumericString(10)},
			}
			event.GenID(ctx)
			require.NoError(t, repo.Create(ctx, event))
		}

		events, err := repo.GetHistory(ctx, roomID, "", "", 5)
		require.NoError(t, err)
		s.Len(events, 5)

		for i := range len(events) - 1 {
			s.True(events[i].CreatedAt.After(events[i+1].CreatedAt) ||
				events[i].CreatedAt.Equal(events[i+1].CreatedAt))
		}
	})
}

func (s *EventRepositoryTestSuite) TestGetByRoomID() {
	s.withRepo(func(t *testing.T, ctx context.Context, repo repository.RoomEventRepository) {
		roomID := util.IDString()

		for range 5 {
			event := &models.RoomEvent{
				RoomID:    roomID,
				SenderID:  util.IDString(),
				EventType: int32(chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE.Number()),
				Content:   data.JSONMap{"text": "Message"},
			}
			event.GenID(ctx)
			require.NoError(t, repo.Create(ctx, event))
		}

		events, err := repo.GetByRoomID(ctx, roomID, 10)
		require.NoError(t, err)
		s.GreaterOrEqual(len(events), 5)
	})
}

func (s *EventRepositoryTestSuite) TestCountByRoomID() {
	s.withRepo(func(t *testing.T, ctx context.Context, repo repository.RoomEventRepository) {
		roomID := util.IDString()

		for range 7 {
			event := &models.RoomEvent{
				RoomID:    roomID,
				SenderID:  util.IDString(),
				EventType: int32(chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE.Number()),
				Content:   data.JSONMap{"text": "Message"},
			}
			event.GenID(ctx)
			require.NoError(t, repo.Create(ctx, event))
		}

		count, err := repo.CountByRoomID(ctx, roomID)
		require.NoError(t, err)
		s.GreaterOrEqual(count, int64(7))
	})
}

// TestHasAuthoredInRoom: only a message or event the subscription sent in that
// room counts; a system event attributed to it, or its message in another
// room, does not.
func (s *EventRepositoryTestSuite) TestHasAuthoredInRoom() {
	s.withRepo(func(t *testing.T, ctx context.Context, repo repository.RoomEventRepository) {
		roomID, otherRoom, sender := util.IDString(), util.IDString(), util.IDString()
		put := func(room string, eventType chatv1.RoomEventType) {
			event := &models.RoomEvent{RoomID: room, SenderID: sender, EventType: int32(eventType.Number()),
				Content: data.JSONMap{"text": "x"}}
			event.GenID(ctx)
			require.NoError(t, repo.Create(ctx, event))
		}

		authored, err := repo.HasAuthoredInRoom(ctx, roomID, sender)
		require.NoError(t, err)
		require.False(t, authored)

		put(roomID, chatv1.RoomEventType_ROOM_EVENT_TYPE_SYSTEM)
		put(otherRoom, chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE)
		authored, err = repo.HasAuthoredInRoom(ctx, roomID, sender)
		require.NoError(t, err)
		require.False(t, authored, "a system event or another room's message is not taking part")

		put(roomID, chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT)
		authored, err = repo.HasAuthoredInRoom(ctx, roomID, sender)
		require.NoError(t, err)
		require.True(t, authored)

		authored, err = repo.HasAuthoredInRoom(ctx, roomID, "")
		require.NoError(t, err)
		require.False(t, authored)
	})
}

// TestAuthoredOfPayloadType reads one sender's events of one payload type in
// one room, newest first, deleted ones excluded.
func (s *EventRepositoryTestSuite) TestAuthoredOfPayloadType() {
	s.withRepo(func(t *testing.T, ctx context.Context, repo repository.RoomEventRepository) {
		roomID, otherRoom, sender, other := util.IDString(), util.IDString(), util.IDString(), util.IDString()
		acceptance := chatv1.PayloadType_PAYLOAD_TYPE_STAWI_AGENT_ACCEPTANCE
		put := func(room, from string, payloadType chatv1.PayloadType) *models.RoomEvent {
			event := &models.RoomEvent{RoomID: room, SenderID: from,
				EventType: int32(chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT.Number()),
				Content:   data.JSONMap{models.PayloadTypeField: payloadType.Number()}}
			event.GenID(ctx)
			require.NoError(t, repo.Create(ctx, event))
			return event
		}
		since := time.Now().Add(-time.Hour)

		first := put(roomID, sender, acceptance)
		put(roomID, sender, chatv1.PayloadType_PAYLOAD_TYPE_TEXT)
		put(roomID, other, acceptance)
		put(otherRoom, sender, acceptance)
		deleted := put(roomID, sender, acceptance)
		require.NoError(t, repo.Delete(ctx, deleted.GetID()))
		second := put(roomID, sender, acceptance)

		got, err := repo.AuthoredOfPayloadType(ctx, roomID, sender, acceptance, since, 10)
		require.NoError(t, err)
		ids := make([]string, 0, len(got))
		for _, event := range got {
			ids = append(ids, event.GetID())
		}
		require.ElementsMatch(t, []string{second.GetID(), first.GetID()}, ids)

		got, err = repo.AuthoredOfPayloadType(ctx, roomID, sender, acceptance, since, 1)
		require.NoError(t, err)
		require.Len(t, got, 1)

		got, err = repo.AuthoredOfPayloadType(ctx, roomID, sender, acceptance, time.Now().Add(time.Hour), 10)
		require.NoError(t, err)
		require.Empty(t, got, "nothing at or after since")
	})
}

func (s *EventRepositoryTestSuite) TestGetByEventID() {
	s.withRepo(func(t *testing.T, ctx context.Context, repo repository.RoomEventRepository) {
		roomID := util.IDString()
		senderID := util.IDString()

		event := &models.RoomEvent{
			RoomID:    roomID,
			SenderID:  senderID,
			EventType: int32(chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE.Number()),
			Content:   data.JSONMap{"text": "Message"},
		}
		event.GenID(ctx)
		require.NoError(t, repo.Create(ctx, event))

		retrieved, err := repo.GetByEventID(ctx, roomID, event.GetID())
		require.NoError(t, err)
		s.NotNil(retrieved)
		s.Equal(senderID, retrieved.SenderID)
	})
}

func (s *EventRepositoryTestSuite) TestEventTypes() {
	s.withRepo(func(t *testing.T, ctx context.Context, repo repository.RoomEventRepository) {
		roomID := util.IDString()
		messageTypes := []chatv1.RoomEventType{
			chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
			chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT,
		}

		for _, msgType := range messageTypes {
			event := &models.RoomEvent{
				RoomID:    roomID,
				SenderID:  util.IDString(),
				EventType: int32(msgType.Number()),
				Content:   data.JSONMap{"data": "test"},
			}
			event.GenID(ctx)
			require.NoError(t, repo.Create(ctx, event))
		}

		events, err := repo.GetByRoomID(ctx, roomID, 10)
		require.NoError(t, err)
		s.GreaterOrEqual(len(events), 2)
	})
}

func (s *EventRepositoryTestSuite) TestExistsByIDs() {
	s.withRepo(func(t *testing.T, ctx context.Context, repo repository.RoomEventRepository) {
		roomID := util.IDString()

		// Create 3 events
		var eventIDs []string
		for range 3 {
			event := &models.RoomEvent{
				RoomID:    roomID,
				SenderID:  util.IDString(),
				EventType: int32(chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE.Number()),
				Content:   data.JSONMap{"text": util.RandomAlphaNumericString(10)},
			}
			event.GenID(ctx)
			require.NoError(t, repo.Create(ctx, event))
			eventIDs = append(eventIDs, event.GetID())
		}

		nonExistentID := util.IDString()
		checkIDs := append([]string{}, eventIDs...)
		checkIDs = append(checkIDs, nonExistentID)

		existsMap, err := repo.ExistsByIDs(ctx, checkIDs)
		require.NoError(t, err)

		// Existing IDs should return true
		for _, id := range eventIDs {
			s.True(existsMap[id], "event %s should exist", id)
		}
		// Non-existent ID should return false
		s.False(existsMap[nonExistentID], "non-existent event should not exist")
	})
}

func (s *EventRepositoryTestSuite) TestPagination() {
	s.withRepo(func(t *testing.T, ctx context.Context, repo repository.RoomEventRepository) {
		roomID := util.IDString()

		for range 20 {
			event := &models.RoomEvent{
				RoomID:    roomID,
				SenderID:  util.IDString(),
				EventType: int32(chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE.Number()),
				Content:   data.JSONMap{"text": util.RandomAlphaNumericString(10)},
			}
			event.GenID(ctx)
			require.NoError(t, repo.Create(ctx, event))
		}

		page1, err := repo.GetByRoomID(ctx, roomID, 10)
		require.NoError(t, err)
		s.Len(page1, 10)

		page2, err := repo.GetHistory(ctx, roomID, page1[len(page1)-1].GetID(), "", 10)
		require.NoError(t, err)
		s.GreaterOrEqual(len(page2), 1)
	})
}
