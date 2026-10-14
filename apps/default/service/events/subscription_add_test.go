package events_test

import (
	"testing"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	eventsv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/events/v1"
	"github.com/pitabwire/frame/v3/datastore"
	"github.com/pitabwire/frame/v3/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"

	"github.com/stawilabs/chat/apps/default/service/events"
	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/tests"
)

type SubscriptionAddTestSuite struct {
	tests.BaseTestSuite
}

func TestSubscriptionAddTestSuite(t *testing.T) {
	suite.Run(t, new(SubscriptionAddTestSuite))
}

// TestQueuedAddNeverJoinsAPersonalRoom: a queued subscription add joins a
// member to a group, but never to a DM or a bot room, whose members are fixed
// when they are created.
func (s *SubscriptionAddTestSuite) TestQueuedAddNeverJoinsAPersonalRoom() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan := svc.WorkManager()
		dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)
		roomRepo := repository.NewRoomRepository(ctx, dbPool, workMan)
		subRepo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)
		queue := events.NewSubscriptionAddQueue(ctx, dbPool, workMan, svc.EventsManager())

		for _, tc := range []struct {
			roomType string
			joins    bool
		}{
			{models.RoomTypeGroup, true},
			{models.RoomTypeDirect, false},
			{models.RoomTypeBot, false},
		} {
			t.Run(tc.roomType, func(t *testing.T) {
				room := &models.Room{RoomType: tc.roomType, Name: tc.roomType}
				if tc.roomType != models.RoomTypeGroup {
					room.DirectKey = models.DirectKey(util.IDString(), util.IDString())
				}
				require.NoError(t, roomRepo.Create(ctx, room))

				joiner := &commonv1.ContactLink{ProfileId: util.IDString()}
				require.NoError(t, queue.Execute(ctx, &eventsv1.RoomAction{
					RoomId:  room.GetID(),
					Targets: []*eventsv1.Subscription{{SubscriptionId: util.IDString(), ContactLink: joiner}},
					Roles:   []string{"member"},
				}))

				subs, err := subRepo.GetByContactLinkAndRooms(ctx, joiner, room.GetID())
				require.NoError(t, err)
				if tc.joins {
					require.Len(t, subs, 1, "a group gains the member")
				} else {
					require.Empty(t, subs, "a personal room gains no member")
				}
			})
		}
	})
}
