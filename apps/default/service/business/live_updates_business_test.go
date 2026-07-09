package business_test

import (
	"context"
	"testing"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"github.com/pitabwire/frame/v2"
	"github.com/pitabwire/frame/v2/cache"
	"github.com/pitabwire/frame/v2/datastore"
	"github.com/pitabwire/frame/v2/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"

	"github.com/stawilabs/chat/apps/default/service/business"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/tests"
)

type LiveUpdatesBusinessTestSuite struct {
	tests.BaseTestSuite
}

func TestLiveUpdatesBusinessTestSuite(t *testing.T) {
	suite.Run(t, new(LiveUpdatesBusinessTestSuite))
}

func (s *LiveUpdatesBusinessTestSuite) setupBusinessLayer(
	ctx context.Context, svc *frame.Service,
) (business.ClientStateBusiness, business.RoomBusiness, business.MessageBusiness) {
	workMan := svc.WorkManager()
	evtsMan := svc.EventsManager()
	dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)

	roomRepo := repository.NewRoomRepository(ctx, dbPool, workMan)
	eventRepo := repository.NewRoomEventRepository(ctx, dbPool, workMan)
	outboxRepo := repository.NewRoomOutboxRepository(ctx, dbPool, workMan)
	subRepo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

	subscriptionSvc := business.NewSubscriptionService(svc, subRepo)
	messageBusiness := business.NewMessageBusiness(
		evtsMan,
		eventRepo,
		outboxRepo,
		subRepo,
		subscriptionSvc,
		s.AuthzMiddleware,
	)
	connectBusiness := business.NewConnectBusiness(evtsMan, subRepo, eventRepo, subscriptionSvc, s.AuthzMiddleware, nil)
	roomBusiness := business.NewRoomBusiness(
		svc,
		roomRepo,
		eventRepo,
		subRepo,
		nil, // proposalRepo
		subscriptionSvc,
		evtsMan,
		messageBusiness,
		nil,
		s.AuthzMiddleware,
	)

	return connectBusiness, roomBusiness, messageBusiness
}

// createRoomAndWait creates a room and waits for async subscription + authz to complete.
func (s *LiveUpdatesBusinessTestSuite) createRoomAndWait(
	ctx context.Context, t *testing.T, svc *frame.Service,
	rb business.RoomBusiness, profileID, contactID string,
) string {
	t.Helper()
	creator := &commonv1.ContactLink{ProfileId: profileID, ContactId: contactID}
	room, err := rb.CreateRoom(ctx, &chatv1.CreateRoomRequest{
		Name:      "Live Test Room",
		IsPrivate: false,
	}, creator)
	require.NoError(t, err)

	roomID := room.GetId()
	s.WaitForMemberSubscription(ctx, svc, roomID, profileID, t)
	s.WaitForAuthzAccess(ctx, svc, profileID, roomID, t)
	return roomID
}

// TestValidationErrors_LiveUpdates tests all validation error paths in a single service setup.
func (s *LiveUpdatesBusinessTestSuite) TestValidationErrors_LiveUpdates() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		cb, _, _ := s.setupBusinessLayer(ctx, svc)

		t.Run("TypingIndicator_NotTyping", func(t *testing.T) {
			err := cb.UpdateTypingIndicator(ctx, "any-room", &commonv1.ContactLink{
				ProfileId: util.IDString(),
			}, false)
			require.NoError(t, err)
		})

		t.Run("TypingIndicator_InvalidContact", func(t *testing.T) {
			err := cb.UpdateTypingIndicator(ctx, "room-id", nil, true)
			require.Error(t, err)

			err = cb.UpdateTypingIndicator(ctx, "room-id", &commonv1.ContactLink{}, true)
			require.Error(t, err)
		})

		t.Run("TypingIndicator_EmptyRoomID", func(t *testing.T) {
			err := cb.UpdateTypingIndicator(ctx, "", &commonv1.ContactLink{
				ProfileId: util.IDString(),
			}, true)
			require.Error(t, err)
		})

		t.Run("DeliveryReceipt_InvalidContact", func(t *testing.T) {
			err := cb.UpdateDeliveryReceipt(ctx, "room-id", nil, "event-id")
			require.Error(t, err)
		})

		t.Run("DeliveryReceipt_EmptyRoomID", func(t *testing.T) {
			err := cb.UpdateDeliveryReceipt(ctx, "", &commonv1.ContactLink{
				ProfileId: util.IDString(),
			}, "event-id")
			require.Error(t, err)
		})

		t.Run("ReadMarker_InvalidContact", func(t *testing.T) {
			err := cb.UpdateReadMarker(ctx, "room-id", nil, "event-id")
			require.Error(t, err)
		})

		t.Run("ReadMarker_EmptyRoomID", func(t *testing.T) {
			err := cb.UpdateReadMarker(ctx, "", &commonv1.ContactLink{
				ProfileId: util.IDString(),
			}, "event-id")
			require.Error(t, err)
		})

		t.Run("Presence_NilSource", func(t *testing.T) {
			err := cb.UpdatePresence(ctx, &chatv1.PresenceEvent{
				Status: chatv1.PresenceStatus_PRESENCE_STATUS_ONLINE,
			})
			require.Error(t, err)
		})

		t.Run("Presence_EmptyProfileID", func(t *testing.T) {
			err := cb.UpdatePresence(ctx, &chatv1.PresenceEvent{
				Source: &commonv1.ContactLink{},
				Status: chatv1.PresenceStatus_PRESENCE_STATUS_ONLINE,
			})
			require.Error(t, err)
		})
	})
}

// TestLiveUpdates_HappyPath tests successful live update operations.
func (s *LiveUpdatesBusinessTestSuite) TestLiveUpdates_HappyPath() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		cb, rb, mb := s.setupBusinessLayer(ctx, svc)

		profileID := util.IDString()
		contactID := util.IDString()
		ctx = s.WithAuthClaims(ctx, "tenant1", "partition1", profileID)
		creator := &commonv1.ContactLink{ProfileId: profileID, ContactId: contactID}

		roomID := s.createRoomAndWait(ctx, t, svc, rb, profileID, contactID)

		// Send a message so we have an eventID for receipts/markers
		acks, err := mb.SendEvents(ctx, &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{{
				RoomId: roomID,
				Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
				Payload: &chatv1.Payload{
					Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "hello"}},
				},
			}},
		}, creator)
		require.NoError(t, err)
		require.Len(t, acks, 1)
		eventID := acks[0].GetEventId()[0]

		t.Run("TypingIndicator", func(t *testing.T) {
			err := cb.UpdateTypingIndicator(ctx, roomID, creator, true)
			require.NoError(t, err)
		})

		t.Run("DeliveryReceipt", func(t *testing.T) {
			err := cb.UpdateDeliveryReceipt(ctx, roomID, creator, eventID)
			require.NoError(t, err)
		})

		t.Run("ReadMarker", func(t *testing.T) {
			err := cb.UpdateReadMarker(ctx, roomID, creator, eventID)
			require.NoError(t, err)
		})
	})
}

// TestLiveUpdates_AccessDenied tests that non-members are denied live updates.
func (s *LiveUpdatesBusinessTestSuite) TestLiveUpdates_AccessDenied() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		cb, rb, _ := s.setupBusinessLayer(ctx, svc)

		ownerID := util.IDString()
		ownerContactID := util.IDString()
		ctx = s.WithAuthClaims(ctx, "tenant1", "partition1", ownerID)

		roomID := s.createRoomAndWait(ctx, t, svc, rb, ownerID, ownerContactID)

		nonMemberID := util.IDString()
		nonMember := &commonv1.ContactLink{ProfileId: nonMemberID}

		t.Run("TypingIndicator", func(t *testing.T) {
			err := cb.UpdateTypingIndicator(ctx, roomID, nonMember, true)
			require.Error(t, err)
		})

		t.Run("DeliveryReceipt", func(t *testing.T) {
			err := cb.UpdateDeliveryReceipt(ctx, roomID, nonMember, "event-id")
			require.Error(t, err)
		})

		t.Run("ReadMarker", func(t *testing.T) {
			err := cb.UpdateReadMarker(ctx, roomID, nonMember, "event-id")
			require.Error(t, err)
		})
	})
}

// TestLiveUpdates_MultipleDeliveryReceipts tests sending delivery receipts for multiple events.
func (s *LiveUpdatesBusinessTestSuite) TestLiveUpdates_MultipleDeliveryReceipts() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		cb, rb, mb := s.setupBusinessLayer(ctx, svc)

		profileID := util.IDString()
		contactID := util.IDString()
		ctx = s.WithAuthClaims(ctx, "tenant1", "partition1", profileID)
		creator := &commonv1.ContactLink{ProfileId: profileID, ContactId: contactID}

		roomID := s.createRoomAndWait(ctx, t, svc, rb, profileID, contactID)

		// Send 3 messages to have multiple event IDs
		var eventIDs []string
		for range 3 {
			acks, err := mb.SendEvents(ctx, &chatv1.SendEventRequest{
				Event: []*chatv1.RoomEvent{{
					RoomId:  roomID,
					Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "msg"}}},
				}},
			}, creator)
			require.NoError(t, err)
			require.Len(t, acks, 1)
			eventIDs = append(eventIDs, acks[0].GetEventId()[0])
		}

		// Send delivery receipt for all 3 events at once
		err := cb.UpdateDeliveryReceipt(ctx, roomID, creator, eventIDs...)
		require.NoError(t, err)
	})
}

// TestLiveUpdates_AuthzDeniedAfterSubscription tests authz-denied paths in live
// update operations when subscription exists but authz tuple is removed.
func (s *LiveUpdatesBusinessTestSuite) TestLiveUpdates_AuthzDeniedAfterSubscription() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		cb, rb, _ := s.setupBusinessLayer(ctx, svc)

		ownerID := util.IDString()
		ownerContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()
		ctx = s.WithAuthClaims(ctx, "tenant1", "partition1", ownerID)
		member := &commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID}

		room, err := rb.CreateRoom(ctx, &chatv1.CreateRoomRequest{
			Name:    "Live Authz Test",
			Members: []*commonv1.ContactLink{member},
		}, &commonv1.ContactLink{ProfileId: ownerID, ContactId: ownerContactID})
		require.NoError(t, err)
		roomID := room.GetId()
		s.WaitForMemberSubscription(ctx, svc, roomID, memberID, t)
		s.WaitForAuthzAccess(ctx, svc, memberID, roomID, t)

		// Get member's subscription ID and remove authz tuple
		workMan := svc.WorkManager()
		dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)
		subRepo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)
		subs, err := subRepo.GetByContactLinkAndRooms(ctx, member, roomID)
		require.NoError(t, err)
		require.NotEmpty(t, subs)
		err = s.AuthzMiddleware.RemoveRoomMember(ctx, roomID, subs[0].GetID())
		require.NoError(t, err)

		t.Run("TypingIndicator_AuthzDenied", func(t *testing.T) {
			err := cb.UpdateTypingIndicator(ctx, roomID, member, true)
			require.Error(t, err)
		})

		t.Run("DeliveryReceipt_AuthzDenied", func(t *testing.T) {
			err := cb.UpdateDeliveryReceipt(ctx, roomID, member, "event-id")
			require.Error(t, err)
		})

		t.Run("ReadMarker_AuthzDenied", func(t *testing.T) {
			err := cb.UpdateReadMarker(ctx, roomID, member, "event-id")
			require.Error(t, err)
		})
	})
}

// TestLiveUpdates_ReadMarkerAdvances tests that the read marker advances
// to a newer event ID (ID comparison) and updates the subscription.
func (s *LiveUpdatesBusinessTestSuite) TestLiveUpdates_ReadMarkerAdvances() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		cb, rb, mb := s.setupBusinessLayer(ctx, svc)

		profileID := util.IDString()
		contactID := util.IDString()
		ctx = s.WithAuthClaims(ctx, "tenant1", "partition1", profileID)
		creator := &commonv1.ContactLink{ProfileId: profileID, ContactId: contactID}

		roomID := s.createRoomAndWait(ctx, t, svc, rb, profileID, contactID)

		// Send 2 messages
		var eventIDs []string
		for range 2 {
			acks, err := mb.SendEvents(ctx, &chatv1.SendEventRequest{
				Event: []*chatv1.RoomEvent{{
					RoomId:  roomID,
					Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "msg"}}},
				}},
			}, creator)
			require.NoError(t, err)
			eventIDs = append(eventIDs, acks[0].GetEventId()[0])
		}

		// Mark read up to first event
		err := cb.UpdateReadMarker(ctx, roomID, creator, eventIDs[0])
		require.NoError(t, err)

		// Mark read up to second event (should advance)
		err = cb.UpdateReadMarker(ctx, roomID, creator, eventIDs[1])
		require.NoError(t, err)

		// Mark read with an older event (should NOT regress but should not error)
		err = cb.UpdateReadMarker(ctx, roomID, creator, eventIDs[0])
		require.NoError(t, err)
	})
}

// setupBusinessLayerWithPresence creates a ClientStateBusiness with a real
// in-memory presence cache, enabling UpdatePresence to run without panicking.
func (s *LiveUpdatesBusinessTestSuite) setupBusinessLayerWithPresence(
	ctx context.Context, svc *frame.Service,
) business.ClientStateBusiness {
	workMan := svc.WorkManager()
	evtsMan := svc.EventsManager()
	dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)

	eventRepo := repository.NewRoomEventRepository(ctx, dbPool, workMan)
	subRepo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

	subscriptionSvc := business.NewSubscriptionService(svc, subRepo)

	rawCache := cache.NewInMemoryCache()
	presenceCache := cache.NewGenericCache[string, *chatv1.PresenceEvent](rawCache, nil)

	return business.NewConnectBusiness(
		evtsMan,
		subRepo,
		eventRepo,
		subscriptionSvc,
		s.AuthzMiddleware,
		presenceCache,
	)
}

// TestUpdatePresence_HappyPath tests the full success path of UpdatePresence
// using a real in-memory cache.
func (s *LiveUpdatesBusinessTestSuite) TestUpdatePresence_HappyPath() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		cb := s.setupBusinessLayerWithPresence(ctx, svc)

		err := cb.UpdatePresence(ctx, &chatv1.PresenceEvent{
			Source: &commonv1.ContactLink{ProfileId: util.IDString()},
			Status: chatv1.PresenceStatus_PRESENCE_STATUS_ONLINE,
		})
		require.NoError(t, err)
	})
}

// TestUpdatePresence_InvalidStatus tests UpdatePresence with UNSPECIFIED status.
// The business layer doesn't reject unspecified status (it just sets it in cache),
// so this verifies it doesn't panic or error.
func (s *LiveUpdatesBusinessTestSuite) TestUpdatePresence_InvalidStatus() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		cb := s.setupBusinessLayerWithPresence(ctx, svc)

		err := cb.UpdatePresence(ctx, &chatv1.PresenceEvent{
			Source: &commonv1.ContactLink{ProfileId: util.IDString()},
			Status: chatv1.PresenceStatus_PRESENCE_STATUS_UNSPECIFIED,
		})
		require.NoError(t, err)
	})
}

// TestUpdateDeliveryReceipt_EmptyEventIDs verifies that calling
// UpdateDeliveryReceipt with no event IDs succeeds (loop body not entered).
func (s *LiveUpdatesBusinessTestSuite) TestUpdateDeliveryReceipt_EmptyEventIDs() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		cb, rb, _ := s.setupBusinessLayer(ctx, svc)

		profileID := util.IDString()
		contactID := util.IDString()
		ctx = s.WithAuthClaims(ctx, "tenant1", "partition1", profileID)
		creator := &commonv1.ContactLink{ProfileId: profileID, ContactId: contactID}

		roomID := s.createRoomAndWait(ctx, t, svc, rb, profileID, contactID)

		// Call with no event IDs — should succeed without emitting anything
		err := cb.UpdateDeliveryReceipt(ctx, roomID, creator)
		require.NoError(t, err)
	})
}
