package repository_test

import (
	"sync"
	"testing"
	"time"

	"github.com/pitabwire/frame/v3/frametests/definition"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"

	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/tests"
)

type SocialTraderRepositoryTestSuite struct {
	tests.BaseTestSuite
}

func TestSocialTraderRepositoryTestSuite(t *testing.T) {
	suite.Run(t, new(SocialTraderRepositoryTestSuite))
}

func binding(roomID, pool, leader string) *models.SocialTraderRoomBinding {
	return &models.SocialTraderRoomBinding{RoomID: roomID, PoolID: pool, LeaderProfileID: leader, BoundAt: time.Now()}
}

// TestRoomBinding_ConcurrentRebindLosesToOwner: ownership is enforced in the
// write itself. Two writers race for one room; only the owner's row persists,
// the other is refused, however the race interleaves (security review: the
// read-then-upsert was a TOCTOU).
func (s *SocialTraderRepositoryTestSuite) TestRoomBinding_ConcurrentRebindLosesToOwner() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan, dbPool := s.GetRepoDeps(ctx, svc)
		repo := repository.NewSocialTraderRoomRepository(ctx, dbPool, workMan)

		const room, owner, other = "room-1", "leader-a", "leader-b"
		require.NoError(t, repo.Upsert(ctx, binding(room, "0xaaa", owner)))

		for range 20 {
			var wg sync.WaitGroup
			errs := make([]error, 2)
			for i, b := range []*models.SocialTraderRoomBinding{
				binding(room, "0xaa1", owner), binding(room, "0xbbb", other),
			} {
				wg.Add(1)
				go func() {
					defer wg.Done()
					errs[i] = repo.Upsert(ctx, b)
				}()
			}
			wg.Wait()
			require.NoError(t, errs[0], "the owner's write always lands")
			require.ErrorIs(t, errs[1], repository.ErrBindingOwnedByAnother)

			got, err := repo.GetByRoomID(ctx, room)
			require.NoError(t, err)
			require.Equal(t, owner, got.LeaderProfileID)
			require.Equal(t, "0xaa1", got.PoolID)
		}

		// Delete is owner-scoped too.
		require.ErrorIs(t, repo.DeleteByRoomID(ctx, room, other), repository.ErrBindingOwnedByAnother)
		require.NoError(t, repo.DeleteByRoomID(ctx, room, owner))
		got, err := repo.GetByRoomID(ctx, room)
		require.NoError(t, err)
		require.Nil(t, got)
		require.NoError(t, repo.DeleteByRoomID(ctx, room, owner), "deleting nothing is not an error")
	})
}

// TestRoomBinding_UnbindThenRebindWorks: an unbound room (soft-deleted row)
// can be bound again, by anyone entitled; the unique index on room_id is no
// obstacle because the upsert resurrects the row.
func (s *SocialTraderRepositoryTestSuite) TestRoomBinding_UnbindThenRebindWorks() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan, dbPool := s.GetRepoDeps(ctx, svc)
		repo := repository.NewSocialTraderRoomRepository(ctx, dbPool, workMan)

		const room = "room-2"
		require.NoError(t, repo.Upsert(ctx, binding(room, "0xaaa", "leader-a")))
		require.NoError(t, repo.DeleteByRoomID(ctx, room, "leader-a"))
		got, err := repo.GetByRoomID(ctx, room)
		require.NoError(t, err)
		require.Nil(t, got, "unbound")

		require.NoError(t, repo.Upsert(ctx, binding(room, "0xccc", "leader-c")), "another leader may bind a free room")
		got, err = repo.GetByRoomID(ctx, room)
		require.NoError(t, err)
		require.NotNil(t, got)
		require.Equal(t, "leader-c", got.LeaderProfileID)
		require.Equal(t, "0xccc", got.PoolID)
	})
}
