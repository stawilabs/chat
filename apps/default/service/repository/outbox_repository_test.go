package repository_test

import (
	"testing"
	"time"

	"github.com/pitabwire/frame/v2/frametests"
	"github.com/pitabwire/frame/v2/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"

	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/tests"
)

type OutboxRepositoryTestSuite struct {
	tests.BaseTestSuite
}

func TestOutboxRepositoryTestSuite(t *testing.T) {
	suite.Run(t, new(OutboxRepositoryTestSuite))
}

func (s *OutboxRepositoryTestSuite) TestSaveEventsWithOutboxAtomicAndDrain() {
	frametests.WithTestDependencies(s.T(), nil, func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan, dbPool := s.GetRepoDeps(ctx, svc)
		eventRepo := repository.NewRoomEventRepository(ctx, dbPool, workMan)
		outboxRepo := repository.NewRoomOutboxRepository(ctx, dbPool, workMan)

		roomID := util.IDString()
		ev := &models.RoomEvent{RoomID: roomID, EventType: 10, SenderID: util.IDString()}
		ev.GenID(ctx)
		payloads := map[string][]byte{ev.GetID(): []byte(`{"event_id":"x"}`)}

		// Atomic save: both the event and its outbox row are committed together.
		inserted, err := outboxRepo.SaveEventsWithOutbox(ctx, []*models.RoomEvent{ev}, payloads)
		require.NoError(t, err)
		s.True(inserted[ev.GetID()])

		// Event is persisted.
		gotEvent, err := eventRepo.GetByEventID(ctx, roomID, ev.GetID())
		require.NoError(t, err)
		s.Equal(ev.GetID(), gotEvent.GetID())

		// A matching, undispatched outbox row exists.
		pending, err := outboxRepo.ListPending(ctx, time.Now().Add(time.Hour), 100)
		require.NoError(t, err)
		found := false
		for _, row := range pending {
			if row.EventID == ev.GetID() {
				found = true
				s.False(row.Dispatched)
				s.Equal(payloads[ev.GetID()], row.Payload)
			}
		}
		s.True(found, "outbox row must exist for the saved event")

		// Re-saving the same event is idempotent: no new insert, still one row.
		inserted2, err := outboxRepo.SaveEventsWithOutbox(ctx, []*models.RoomEvent{ev}, payloads)
		require.NoError(t, err)
		s.False(inserted2[ev.GetID()], "duplicate event must not re-insert")

		// Relay drains it.
		require.NoError(t, outboxRepo.MarkDispatched(ctx, []string{ev.GetID()}))
		stillPending, err := outboxRepo.ListPending(ctx, time.Now().Add(time.Hour), 100)
		require.NoError(t, err)
		for _, row := range stillPending {
			s.NotEqual(ev.GetID(), row.EventID, "dispatched row must not be listed as pending")
		}
	})
}
