package repository_test

import (
	"testing"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	"github.com/pitabwire/frame/data"
	"github.com/pitabwire/frame/frametests"
	"github.com/pitabwire/frame/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"

	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/tests"
)

type SubscriptionRepositoryTestSuite struct {
	tests.BaseTestSuite
}

func TestSubscriptionRepositoryTestSuite(t *testing.T) {
	suite.Run(t, new(SubscriptionRepositoryTestSuite))
}

func (s *SubscriptionRepositoryTestSuite) TestCreateSubscription() {
	frametests.WithTestDependencies(s.T(), nil, func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan, dbPool := s.GetRepoDeps(ctx, svc)
		repo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

		sub := &models.RoomSubscription{
			RoomID:            util.IDString(),
			ProfileID:         util.IDString(),
			Role:              repository.RoleMember,
			SubscriptionState: models.RoomSubscriptionStateActive,
			Properties:        data.JSONMap{"test": "data"},
		}
		sub.GenID(ctx)

		err := repo.Create(ctx, sub)
		require.NoError(t, err)
		s.NotEmpty(sub.GetID())

		retrieved, err := repo.GetByID(ctx, sub.GetID())
		require.NoError(t, err)
		s.Equal(sub.RoomID, retrieved.RoomID)
		s.Equal(sub.ProfileID, retrieved.ProfileID)
		s.Equal(sub.Role, retrieved.Role)
	})
}

func (s *SubscriptionRepositoryTestSuite) TestGetByRoomAndProfile() {
	frametests.WithTestDependencies(s.T(), nil, func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan, dbPool := s.GetRepoDeps(ctx, svc)
		repo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

		roomID := util.IDString()
		profileID := util.IDString()

		sub := &models.RoomSubscription{
			RoomID:            roomID,
			ProfileID:         profileID,
			Role:              repository.RoleAdmin,
			SubscriptionState: models.RoomSubscriptionStateActive,
		}
		sub.GenID(ctx)
		require.NoError(t, repo.Create(ctx, sub))

		retrievedList, err := repo.GetByContactLinkAndRooms(ctx, &commonv1.ContactLink{ProfileId: profileID}, roomID)
		require.NoError(t, err)
		s.Len(retrievedList, 1)
		retrieved := retrievedList[0]
		s.Equal(sub.GetID(), retrieved.GetID())
		s.Equal(repository.RoleAdmin, retrieved.Role)
	})
}

func (s *SubscriptionRepositoryTestSuite) TestGetActiveByRoomAndProfile() {
	frametests.WithTestDependencies(s.T(), nil, func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan, dbPool := s.GetRepoDeps(ctx, svc)
		repo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

		roomID := util.IDString()
		profileID := util.IDString()
		contactID := util.IDString()

		activeSub := &models.RoomSubscription{
			RoomID:            roomID,
			ProfileID:         profileID,
			Role:              repository.RoleMember,
			SubscriptionState: models.RoomSubscriptionStateActive,
		}
		activeSub.GenID(ctx)
		require.NoError(t, repo.Create(ctx, activeSub))

		retrieved, err := repo.GetByRoomIDAndContactLinks(ctx, roomID, &commonv1.ContactLink{
			ProfileId: profileID,
			ContactId: contactID,
		})
		require.NoError(t, err)

		s.Len(retrieved, 1)
		s.Equal(activeSub.GetID(), retrieved[0].GetID())

		require.NoError(t, repo.Deactivate(ctx, activeSub.GetID()))

		_, err = repo.GetByRoomIDAndContactLinks(
			ctx,
			roomID,
			&commonv1.ContactLink{ProfileId: profileID, ContactId: contactID},
		)
		require.NoError(t, err)
		s.Empty(retrieved)
	})
}

// TestDeactivateInRoomScoping proves the cross-room IDOR guard: a subscription
// that belongs to another room is never affected even if its ID is supplied,
// and GetByIDsInRoom only returns IDs that belong to the room.
func (s *SubscriptionRepositoryTestSuite) TestDeactivateInRoomScoping() {
	frametests.WithTestDependencies(s.T(), nil, func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan, dbPool := s.GetRepoDeps(ctx, svc)
		repo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

		roomA := util.IDString()
		roomB := util.IDString()

		subA := &models.RoomSubscription{
			RoomID: roomA, ProfileID: util.IDString(),
			Role: repository.RoleMember, SubscriptionState: models.RoomSubscriptionStateActive,
		}
		subA.GenID(ctx)
		require.NoError(t, repo.Create(ctx, subA))

		subB := &models.RoomSubscription{
			RoomID: roomB, ProfileID: util.IDString(),
			Role: repository.RoleMember, SubscriptionState: models.RoomSubscriptionStateActive,
		}
		subB.GenID(ctx)
		require.NoError(t, repo.Create(ctx, subB))

		// Attempt to deactivate roomB's subscription while scoped to roomA.
		affected, err := repo.DeactivateInRoom(ctx, roomA, []string{subB.GetID()})
		require.NoError(t, err)
		s.Equal(int64(0), affected, "must not deactivate a subscription from another room")

		// roomB's subscription must still be active.
		gotB, err := repo.GetByID(ctx, subB.GetID())
		require.NoError(t, err)
		s.Equal(models.RoomSubscriptionStateActive, gotB.SubscriptionState)

		// GetByIDsInRoom must not return the foreign subscription.
		scoped, err := repo.GetByIDsInRoom(ctx, roomA, []string{subA.GetID(), subB.GetID()})
		require.NoError(t, err)
		s.Len(scoped, 1)
		s.Equal(subA.GetID(), scoped[0].GetID())

		// Correctly-scoped deactivation works.
		affected, err = repo.DeactivateInRoom(ctx, roomA, []string{subA.GetID()})
		require.NoError(t, err)
		s.Equal(int64(1), affected)
	})
}

// TestPartialUniqueIndexAllowsReAddAfterBlock proves the partial unique index
// (active/proposed only) lets a blocked member be re-added, while still blocking
// two simultaneously-active rows for the same identity.
func (s *SubscriptionRepositoryTestSuite) TestPartialUniqueIndexAllowsReAddAfterBlock() {
	frametests.WithTestDependencies(s.T(), nil, func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan, dbPool := s.GetRepoDeps(ctx, svc)
		repo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

		roomID := util.IDString()
		profileID := util.IDString()
		contactID := util.IDString()
		mk := func() *models.RoomSubscription {
			sub := &models.RoomSubscription{
				RoomID: roomID, ProfileID: profileID, ContactID: contactID,
				Role: repository.RoleMember, SubscriptionState: models.RoomSubscriptionStateActive,
			}
			sub.GenID(ctx)
			return sub
		}

		first := mk()
		require.NoError(t, repo.Create(ctx, first))

		// A second active row for the same identity must violate the unique index.
		require.Error(t, repo.Create(ctx, mk()), "duplicate active subscription must be rejected")

		// After blocking the first, re-adding (a new active row) must succeed.
		_, err := repo.DeactivateInRoom(ctx, roomID, []string{first.GetID()})
		require.NoError(t, err)
		require.NoError(t, repo.Create(ctx, mk()), "re-add after block must be allowed")
	})
}

// TestCountActiveOwners verifies owner counting including comma-separated roles.
func (s *SubscriptionRepositoryTestSuite) TestCountActiveOwners() {
	frametests.WithTestDependencies(s.T(), nil, func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan, dbPool := s.GetRepoDeps(ctx, svc)
		repo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

		roomID := util.IDString()
		mk := func(role string, state models.RoomSubscriptionState) {
			sub := &models.RoomSubscription{
				RoomID: roomID, ProfileID: util.IDString(), Role: role, SubscriptionState: state,
			}
			sub.GenID(ctx)
			require.NoError(t, repo.Create(ctx, sub))
		}
		mk(repository.RoleOwner, models.RoomSubscriptionStateActive)  // owner
		mk("admin,owner", models.RoomSubscriptionStateActive)         // csv owner
		mk(repository.RoleMember, models.RoomSubscriptionStateActive) // not owner
		mk(repository.RoleOwner, models.RoomSubscriptionStateBlocked) // blocked owner, excluded

		count, err := repo.CountActiveOwners(ctx, roomID)
		require.NoError(t, err)
		s.Equal(int64(2), count)
	})
}

func (s *SubscriptionRepositoryTestSuite) TestGetByRoomID() {
	frametests.WithTestDependencies(s.T(), nil, func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan, dbPool := s.GetRepoDeps(ctx, svc)
		repo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

		roomID := util.IDString()

		for i := range 3 {
			subState := models.RoomSubscriptionStateActive
			if i >= 2 {
				subState = models.RoomSubscriptionStateBlocked
			}

			sub := &models.RoomSubscription{
				RoomID:            roomID,
				ProfileID:         util.IDString(),
				Role:              repository.RoleMember,
				SubscriptionState: subState,
			}
			sub.GenID(ctx)
			require.NoError(t, repo.Create(ctx, sub))
		}

		allSubs, err := repo.GetByRoomID(ctx, roomID, nil)
		require.NoError(t, err)
		s.Len(allSubs, 3)

		activeSubs := 0
		inActiveSubs := 0

		for _, sub := range allSubs {
			if sub.IsActive() {
				activeSubs++
			} else {
				inActiveSubs++
			}
		}
		s.Equal(2, activeSubs)
		s.Equal(1, inActiveSubs)
	})
}

func (s *SubscriptionRepositoryTestSuite) TestGetByProfileID() {
	frametests.WithTestDependencies(s.T(), nil, func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan, dbPool := s.GetRepoDeps(ctx, svc)
		repo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

		profileID := util.IDString()

		for range 3 {
			sub := &models.RoomSubscription{
				RoomID:            util.IDString(),
				ProfileID:         profileID,
				Role:              repository.RoleMember,
				SubscriptionState: models.RoomSubscriptionStateActive,
			}
			sub.GenID(ctx)
			require.NoError(t, repo.Create(ctx, sub))
		}

		subs, err := repo.GetByContactLink(ctx, &commonv1.ContactLink{ProfileId: profileID}, true)
		require.NoError(t, err)
		s.Len(subs, 3)
	})
}

func (s *SubscriptionRepositoryTestSuite) TestUpdateRole() {
	frametests.WithTestDependencies(s.T(), nil, func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan, dbPool := s.GetRepoDeps(ctx, svc)
		repo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

		sub := &models.RoomSubscription{
			RoomID:            util.IDString(),
			ProfileID:         util.IDString(),
			Role:              repository.RoleMember,
			SubscriptionState: models.RoomSubscriptionStateActive,
		}
		sub.GenID(ctx)
		require.NoError(t, repo.Create(ctx, sub))

		err := repo.UpdateRole(ctx, sub.GetID(), repository.RoleAdmin)
		require.NoError(t, err)

		retrieved, err := repo.GetByID(ctx, sub.GetID())
		require.NoError(t, err)
		s.Equal(repository.RoleAdmin, retrieved.Role)
	})
}

func (s *SubscriptionRepositoryTestSuite) TestHasPermission() {
	frametests.WithTestDependencies(s.T(), nil, func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan, dbPool := s.GetRepoDeps(ctx, svc)
		repo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

		roomID := util.IDString()
		adminID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()

		adminSub := &models.RoomSubscription{
			RoomID:            roomID,
			ProfileID:         adminID,
			Role:              repository.RoleAdmin,
			SubscriptionState: models.RoomSubscriptionStateActive,
		}
		adminSub.GenID(ctx)
		require.NoError(t, repo.Create(ctx, adminSub))

		memberSub := &models.RoomSubscription{
			RoomID:            roomID,
			ProfileID:         memberID,
			Role:              repository.RoleMember,
			SubscriptionState: models.RoomSubscriptionStateActive,
		}
		memberSub.GenID(ctx)
		require.NoError(t, repo.Create(ctx, memberSub))

		hasPermission, err := repo.HasPermission(
			ctx,
			roomID,
			&commonv1.ContactLink{ProfileId: adminID},
			repository.RoleAdmin,
		)
		require.NoError(t, err)
		s.True(hasPermission)

		hasPermission, err = repo.HasPermission(
			ctx,
			roomID,
			&commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
			repository.RoleAdmin,
		)
		require.NoError(t, err)
		s.False(hasPermission)
	})
}

func (s *SubscriptionRepositoryTestSuite) TestCountActiveMembers() {
	frametests.WithTestDependencies(s.T(), nil, func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan, dbPool := s.GetRepoDeps(ctx, svc)
		repo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

		roomID := util.IDString()

		for i := range 5 {
			subState := models.RoomSubscriptionStateActive
			if i >= 3 {
				subState = models.RoomSubscriptionStateBlocked
			}

			sub := &models.RoomSubscription{
				RoomID:            roomID,
				ProfileID:         util.IDString(),
				Role:              repository.RoleMember,
				SubscriptionState: subState,
			}
			sub.GenID(ctx)
			require.NoError(t, repo.Create(ctx, sub))
		}

		count, err := repo.CountActiveMembers(ctx, roomID)
		require.NoError(t, err)
		s.Equal(int64(3), count)
	})
}

func (s *SubscriptionRepositoryTestSuite) TestBulkCreate() {
	frametests.WithTestDependencies(s.T(), nil, func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		workMan, dbPool := s.GetRepoDeps(ctx, svc)
		repo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

		roomID := util.IDString()
		var subs []*models.RoomSubscription

		for range 5 {
			sub := &models.RoomSubscription{
				RoomID:            roomID,
				ProfileID:         util.IDString(),
				Role:              repository.RoleMember,
				SubscriptionState: models.RoomSubscriptionStateActive,
			}
			sub.GenID(ctx)
			subs = append(subs, sub)
		}

		for _, sub := range subs {
			require.NoError(t, repo.Create(ctx, sub))
		}

		retrieved, err := repo.GetByRoomID(ctx, roomID, nil)
		require.NoError(t, err)
		s.Len(retrieved, 5)
	})
}
