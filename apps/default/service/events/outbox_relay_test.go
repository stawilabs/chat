package events_test

import (
	"testing"
	"time"

	eventsv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/events/v1"
	"github.com/pitabwire/frame/datastore"
	"github.com/pitabwire/frame/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	"google.golang.org/protobuf/encoding/protojson"

	"github.com/stawilabs/chat/apps/default/service/events"
	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/tests"
)

type OutboxRelayTestSuite struct {
	tests.BaseTestSuite
}

func TestOutboxRelayTestSuite(t *testing.T) {
	suite.Run(t, new(OutboxRelayTestSuite))
}

func (s *OutboxRelayTestSuite) TestDrainDispatchesAndDropsPoison() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan := svc.WorkManager()
		dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)
		outboxRepo := repository.NewRoomOutboxRepository(ctx, dbPool, workMan)
		relay := events.NewOutboxRelay(outboxRepo, svc.EventsManager())

		// A valid pending row: drain must emit it and mark it dispatched.
		link := &eventsv1.Link{EventId: util.IDString(), RoomId: util.IDString()}
		payload, mErr := protojson.Marshal(link)
		require.NoError(t, mErr)
		good := &models.RoomOutbox{EventID: link.GetEventId(), RoomID: link.GetRoomId(), Payload: payload}
		good.GenID(ctx)
		require.NoError(t, outboxRepo.Create(ctx, good))

		// A poison row (unparseable payload): drain must drop it (mark dispatched)
		// rather than loop on it forever.
		poison := &models.RoomOutbox{EventID: util.IDString(), RoomID: util.IDString(), Payload: []byte("not-json")}
		poison.GenID(ctx)
		require.NoError(t, outboxRepo.Create(ctx, poison))

		require.NoError(t, relay.Drain(ctx))

		pending, err := outboxRepo.ListPending(ctx, time.Now().Add(time.Hour), 100)
		require.NoError(t, err)
		for _, row := range pending {
			s.NotEqual(good.EventID, row.EventID, "valid row should be dispatched")
			s.NotEqual(poison.EventID, row.EventID, "poison row should be dropped")
		}
	})
}
