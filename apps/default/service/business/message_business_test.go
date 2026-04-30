package business_test

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"github.com/pitabwire/frame"
	"github.com/pitabwire/frame/data"
	"github.com/pitabwire/frame/datastore"
	"github.com/pitabwire/frame/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	"google.golang.org/protobuf/types/known/structpb"

	"github.com/stawilabs/chat/apps/default/service"
	"github.com/stawilabs/chat/apps/default/service/business"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/tests"
)

type MessageBusinessTestSuite struct {
	tests.BaseTestSuite
}

func TestMessageBusinessTestSuite(t *testing.T) {
	suite.Run(t, new(MessageBusinessTestSuite))
}

func (s *MessageBusinessTestSuite) setupBusinessLayer(
	ctx context.Context, svc *frame.Service,
) (business.MessageBusiness, business.RoomBusiness) {
	return s.setupBusinessLayerWithCallPolicy(ctx, svc, business.DefaultCallPolicyConfig())
}

func (s *MessageBusinessTestSuite) setupBusinessLayerWithCallPolicy(
	ctx context.Context,
	svc *frame.Service,
	callPolicy business.CallPolicyConfig,
) (business.MessageBusiness, business.RoomBusiness) {
	workMan := svc.WorkManager()
	evtsMan := svc.EventsManager()
	dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)

	roomRepo := repository.NewRoomRepository(ctx, dbPool, workMan)
	eventRepo := repository.NewRoomEventRepository(ctx, dbPool, workMan)
	subRepo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)
	callRepo := repository.NewRoomCallRepository(ctx, dbPool, workMan)

	subscriptionSvc := business.NewSubscriptionService(svc, subRepo)
	messageBusiness := business.NewMessageBusiness(
		evtsMan,
		eventRepo,
		subRepo,
		subscriptionSvc,
		s.AuthzMiddleware,
		business.WithCallPolicy(callRepo, callPolicy),
	)
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

	return messageBusiness, roomBusiness
}

func (s *MessageBusinessTestSuite) TestSendMessage() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		// Create room first
		creatorID := util.IDString()
		creatorContactID := util.IDString()
		roomReq := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			roomReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, room.GetId(), t)

		// Send message
		msgReq := &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{
				{
					RoomId: room.GetId(),
					Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{
						Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "test message"}},
					},
				},
			},
		}

		acks, err := messageBusiness.SendEvents(
			ctx,
			msgReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.Len(acks, 1)
		s.Len(acks[0].GetEventId(), 1)
		s.NotEmpty(acks[0].GetEventId()[0])
	})
}

func (s *MessageBusinessTestSuite) TestSendMessageToNonExistentRoom() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, _ := s.setupBusinessLayer(ctx, svc)

		msgReq := &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{
				{
					RoomId: util.IDString(), // Non-existent room
					Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{
						Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "test message"}},
					},
				},
			},
		}

		senderID := util.IDString()
		senderContactID := util.IDString()
		acks, err := messageBusiness.SendEvents(
			ctx,
			msgReq,
			&commonv1.ContactLink{ProfileId: senderID, ContactId: senderContactID},
		)
		require.NoError(t, err) // Should return acks with errors
		s.Len(acks, 1)
		// Check if ack contains error
		s.NotNil(acks[0].GetError())
	})
}

func (s *MessageBusinessTestSuite) TestSendMultipleMessages() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		// Create room
		creatorID := util.IDString()
		creatorContactID := util.IDString()
		roomReq := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			roomReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, room.GetId(), t)

		// Send multiple messages
		var messages []*chatv1.RoomEvent
		for range 5 {
			messages = append(messages, &chatv1.RoomEvent{
				RoomId:  room.GetId(),
				Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
				Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "test message"}}},
			})
		}

		msgReq := &chatv1.SendEventRequest{
			Event: messages,
		}

		acks, err := messageBusiness.SendEvents(
			ctx,
			msgReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.Len(acks, 5)

		for _, ack := range acks {
			s.NotEmpty(ack.GetEventId())
			s.Len(ack.GetEventId(), 1)
		}
	})
}

func (s *MessageBusinessTestSuite) TestGetHistory() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		// Create room and send messages
		creatorID := util.IDString()
		creatorContactID := util.IDString()
		roomReq := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			roomReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, room.GetId(), t)

		// Send 10 messages
		for range 10 {
			msgReq := &chatv1.SendEventRequest{
				Event: []*chatv1.RoomEvent{
					{
						RoomId: room.GetId(),
						Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
						Payload: &chatv1.Payload{
							Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "test message"}},
						},
					},
				},
			}

			_, sendErr := messageBusiness.SendEvents(
				ctx,
				msgReq,
				&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
			)
			require.NoError(t, sendErr)
		}

		// Get history
		historyReq := &chatv1.GetHistoryRequest{
			RoomId: room.GetId(),
			Cursor: &commonv1.PageCursor{Limit: 5, Page: ""},
		}

		events, err := messageBusiness.GetHistory(
			ctx,
			historyReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.Len(events, 5)
	})
}

func (s *MessageBusinessTestSuite) TestGetMessageViaHistory() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		// Create room and send message
		creatorID := util.IDString()
		creatorContactID := util.IDString()
		roomReq := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			roomReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, room.GetId(), t)

		msgReq := &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{
				{
					RoomId: room.GetId(),
					Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{
						Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "test message"}},
					},
				},
			},
		}

		acks, err := messageBusiness.SendEvents(
			ctx,
			msgReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		messageID := acks[0].GetEventId()[0]

		// Get the message via history
		historyReq := &chatv1.GetHistoryRequest{
			RoomId: room.GetId(),
			Cursor: &commonv1.PageCursor{Limit: 10, Page: ""},
		}

		events, err := messageBusiness.GetHistory(
			ctx,
			historyReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.NotEmpty(events)

		// Find our message
		found := false
		for _, event := range events {
			if event.GetId() == messageID {
				found = true
				break
			}
		}
		s.True(found, "Message should be in history")
	})
}

func (s *MessageBusinessTestSuite) TestDeleteMessageViaRepository() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		workMan := svc.WorkManager()
		dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)

		eventRepo := repository.NewRoomEventRepository(ctx, dbPool, workMan)

		// Create room and send message
		creatorID := util.IDString()
		creatorContactID := util.IDString()

		roomReq := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			roomReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, room.GetId(), t)

		msgReq := &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{
				{
					Id:     util.IDString(),
					RoomId: room.GetId(),
					Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{
						Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "test message"}},
					},
				},
			},
		}

		acks, err := messageBusiness.SendEvents(
			ctx,
			msgReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		messageID := acks[0].GetEventId()[0]

		_, err = eventRepo.GetByID(ctx, messageID)
		require.NoError(t, err)

		// Delete the message via repository
		err = eventRepo.Delete(ctx, messageID)
		require.NoError(t, err)

		// Verify deletion
		_, err = eventRepo.GetByID(ctx, messageID)
		require.Error(t, err)
		require.True(t, data.ErrorIsNoRows(err))
	})
}

func (s *MessageBusinessTestSuite) TestMarkMessagesAsRead() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		// Create room with member
		creatorID := util.IDString()
		creatorContactID := util.IDString()

		memberID := util.IDString()
		memberContactID := util.IDString()

		roomReq := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
			Members:   []*commonv1.ContactLink{{ProfileId: memberID, ContactId: memberContactID}},
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			roomReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), memberID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, room.GetId(), t)
		s.WaitForAuthzAccess(ctx, svc, memberID, room.GetId(), t)

		// Send message
		msgReq := &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{
				{
					RoomId: room.GetId(),
					Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{
						Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "test message"}},
					},
				},
			},
		}

		acks, err := messageBusiness.SendEvents(
			ctx,
			msgReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		eventID := acks[0].GetEventId()[0]

		// Mark as read by member
		err = messageBusiness.MarkMessagesAsRead(
			ctx,
			room.GetId(),
			eventID,
			&commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
		)
		require.NoError(t, err)
	})
}

func (s *MessageBusinessTestSuite) TestSendMessageAccessDenied() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		// Create room with one member
		creatorID := util.IDString()
		creatorContactID := util.IDString()
		roomReq := &chatv1.CreateRoomRequest{
			Name:      "Private Room",
			IsPrivate: true,
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			roomReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForRoomSubscription(ctx, svc, room.GetId(), t)

		// Non-member tries to send a message
		nonMemberID := util.IDString()
		nonMemberContactID := util.IDString()
		msgReq := &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{
				{
					RoomId: room.GetId(),
					Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{
						Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "unauthorized message"}},
					},
				},
			},
		}

		acks, err := messageBusiness.SendEvents(
			ctx,
			msgReq,
			&commonv1.ContactLink{ProfileId: nonMemberID, ContactId: nonMemberContactID},
		)
		require.NoError(t, err) // Returns acks with errors, not a top-level error
		require.Len(t, acks, 1)
		s.NotNil(acks[0].GetError(), "non-member should get error on send")
	})
}

func (s *MessageBusinessTestSuite) TestGetHistoryAccessDenied() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		// Create room
		creatorID := util.IDString()
		creatorContactID := util.IDString()
		roomReq := &chatv1.CreateRoomRequest{
			Name:      "Private Room",
			IsPrivate: true,
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			roomReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForRoomSubscription(ctx, svc, room.GetId(), t)

		// Non-member tries to get history
		nonMemberID := util.IDString()
		nonMemberContactID := util.IDString()
		historyReq := &chatv1.GetHistoryRequest{
			RoomId: room.GetId(),
			Cursor: &commonv1.PageCursor{Limit: 10, Page: ""},
		}

		_, err = messageBusiness.GetHistory(
			ctx,
			historyReq,
			&commonv1.ContactLink{ProfileId: nonMemberID, ContactId: nonMemberContactID},
		)
		require.Error(t, err, "non-member should be denied history access")
	})
}

func (s *MessageBusinessTestSuite) TestDeleteMessageDenied() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		// Create room with two members
		creatorID := util.IDString()
		creatorContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()

		roomReq := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
			Members:   []*commonv1.ContactLink{{ProfileId: memberID, ContactId: memberContactID}},
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			roomReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, room.GetId(), t)

		// Creator sends a message
		msgReq := &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{
				{
					RoomId: room.GetId(),
					Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{
						Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "test message"}},
					},
				},
			},
		}

		acks, err := messageBusiness.SendEvents(
			ctx,
			msgReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		messageID := acks[0].GetEventId()[0]

		// Regular member should NOT be able to delete the creator's message
		err = messageBusiness.DeleteMessage(
			ctx,
			messageID,
			&commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
		)
		require.Error(t, err, "regular member should not be able to delete another user's message")
	})
}

func (s *MessageBusinessTestSuite) TestDeleteMessageByAdmin() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		// Create room with member
		creatorID := util.IDString()
		creatorContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()

		roomReq := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
			Members:   []*commonv1.ContactLink{{ProfileId: memberID, ContactId: memberContactID}},
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			roomReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), memberID, t)
		s.WaitForAuthzAccess(ctx, svc, memberID, room.GetId(), t)

		// Member sends a message
		msgReq := &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{
				{
					RoomId: room.GetId(),
					Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{
						Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "member's message"}},
					},
				},
			},
		}

		acks, err := messageBusiness.SendEvents(
			ctx,
			msgReq,
			&commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
		)
		require.NoError(t, err)
		messageID := acks[0].GetEventId()[0]

		// Owner (who is admin+) should be able to delete the member's message
		err = messageBusiness.DeleteMessage(
			ctx,
			messageID,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err, "admin/owner should be able to delete any message")
	})
}

func (s *MessageBusinessTestSuite) TestDeleteOwnMessage() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		// Create room with member
		creatorID := util.IDString()
		creatorContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()

		roomReq := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
			Members:   []*commonv1.ContactLink{{ProfileId: memberID, ContactId: memberContactID}},
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			roomReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), memberID, t)
		s.WaitForAuthzAccess(ctx, svc, memberID, room.GetId(), t)

		// Member sends a message
		msgReq := &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{
				{
					RoomId: room.GetId(),
					Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{
						Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "my message"}},
					},
				},
			},
		}

		acks, err := messageBusiness.SendEvents(
			ctx,
			msgReq,
			&commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
		)
		require.NoError(t, err)
		messageID := acks[0].GetEventId()[0]

		// Member should be able to delete their own message
		err = messageBusiness.DeleteMessage(
			ctx,
			messageID,
			&commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
		)
		require.NoError(t, err, "user should be able to delete their own message")
	})
}

func (s *MessageBusinessTestSuite) TestMarkMessagesAsReadDenied() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		// Create room
		creatorID := util.IDString()
		creatorContactID := util.IDString()
		roomReq := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			roomReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForRoomSubscription(ctx, svc, room.GetId(), t)

		// Non-member tries to mark messages as read
		nonMemberID := util.IDString()
		nonMemberContactID := util.IDString()
		err = messageBusiness.MarkMessagesAsRead(
			ctx,
			room.GetId(),
			"some-event-id",
			&commonv1.ContactLink{ProfileId: nonMemberID, ContactId: nonMemberContactID},
		)
		require.Error(t, err, "non-member should not be able to mark messages as read")
	})
}

func (s *MessageBusinessTestSuite) TestGetMessage() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		// Create room and send message
		creatorID := util.IDString()
		creatorContactID := util.IDString()
		roomReq := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			roomReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, room.GetId(), t)

		// Send a message
		msgReq := &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{
				{
					RoomId: room.GetId(),
					Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{
						Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "hello world"}},
					},
				},
			},
		}

		acks, err := messageBusiness.SendEvents(
			ctx,
			msgReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		require.Len(t, acks, 1)
		require.Nil(t, acks[0].GetError())
		messageID := acks[0].GetEventId()[0]

		// Get the message by ID
		event, err := messageBusiness.GetMessage(
			ctx,
			messageID,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.NotNil(event)
		s.Equal(messageID, event.GetID())
		s.Equal(room.GetId(), event.RoomID)
	})
}

func (s *MessageBusinessTestSuite) TestGetMessage_AccessDenied() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		// Create room and send message
		creatorID := util.IDString()
		creatorContactID := util.IDString()
		roomReq := &chatv1.CreateRoomRequest{
			Name:      "Private Room",
			IsPrivate: true,
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			roomReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, room.GetId(), t)

		// Send a message
		msgReq := &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{
				{
					RoomId: room.GetId(),
					Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{
						Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "secret message"}},
					},
				},
			},
		}

		acks, err := messageBusiness.SendEvents(
			ctx,
			msgReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		messageID := acks[0].GetEventId()[0]

		// Non-member tries to get the message
		nonMemberID := util.IDString()
		nonMemberContactID := util.IDString()
		_, err = messageBusiness.GetMessage(
			ctx,
			messageID,
			&commonv1.ContactLink{ProfileId: nonMemberID, ContactId: nonMemberContactID},
		)
		require.Error(t, err, "non-member should be denied access to message")
	})
}

func (s *MessageBusinessTestSuite) TestSendDifferentMessageTypes() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		// Create room
		creatorID := util.IDString()
		creatorContactID := util.IDString()
		roomReq := &chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
		}

		room, err := roomBusiness.CreateRoom(
			ctx,
			roomReq,
			&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
		)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, room.GetId(), t)

		// Test different message types
		messageTypes := []chatv1.RoomEventType{
			chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
			chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT,
		}

		for _, msgType := range messageTypes {
			msgReq := &chatv1.SendEventRequest{
				Event: []*chatv1.RoomEvent{
					{
						RoomId: room.GetId(),
						Type:   msgType,
						Payload: &chatv1.Payload{
							Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "test message"}},
						},
					},
				},
			}

			acks, sendErr := messageBusiness.SendEvents(
				ctx,
				msgReq,
				&commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID},
			)
			require.NoError(t, sendErr)
			s.Len(acks, 1)
			s.NotEmpty(acks[0].GetEventId())
			s.Len(acks[0].GetEventId(), 1)
		}
	})
}

// --- Validation Error Path Tests (consolidated to reduce DB connections) ---

// TestValidationErrors_MessageOperations tests all validation error paths in a single service setup.
func (s *MessageBusinessTestSuite) TestValidationErrors_MessageOperations() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, _ := s.setupBusinessLayer(ctx, svc)
		validContact := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}

		t.Run("SendEvents_EmptyEvents", func(t *testing.T) {
			_, err := messageBusiness.SendEvents(ctx,
				&chatv1.SendEventRequest{Event: nil}, validContact)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrMessageContentRequired)
		})

		t.Run("SendEvents_InvalidContact", func(t *testing.T) {
			msgReq := &chatv1.SendEventRequest{
				Event: []*chatv1.RoomEvent{{
					RoomId:  util.IDString(),
					Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "test"}}},
				}},
			}
			_, err := messageBusiness.SendEvents(ctx, msgReq, nil)
			require.Error(t, err)

			_, err = messageBusiness.SendEvents(ctx, msgReq, &commonv1.ContactLink{})
			require.Error(t, err)
		})

		t.Run("SendEvents_EmptyRoomID", func(t *testing.T) {
			msgReq := &chatv1.SendEventRequest{
				Event: []*chatv1.RoomEvent{{
					RoomId:  "",
					Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "test"}}},
				}},
			}
			_, err := messageBusiness.SendEvents(ctx, msgReq, validContact)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrMessageRoomIDRequired)
		})

		t.Run("GetHistory_EmptyRoomID", func(t *testing.T) {
			_, err := messageBusiness.GetHistory(ctx,
				&chatv1.GetHistoryRequest{RoomId: ""}, validContact)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrMessageRoomIDRequired)
		})

		t.Run("GetHistory_InvalidContact", func(t *testing.T) {
			_, err := messageBusiness.GetHistory(ctx,
				&chatv1.GetHistoryRequest{RoomId: "some-room-id"}, nil)
			require.Error(t, err)

			_, err = messageBusiness.GetHistory(ctx,
				&chatv1.GetHistoryRequest{RoomId: "some-room-id"}, &commonv1.ContactLink{})
			require.Error(t, err)
		})

		t.Run("DeleteMessage_EmptyID", func(t *testing.T) {
			err := messageBusiness.DeleteMessage(ctx, "", validContact)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrUnspecifiedID)
		})

		t.Run("DeleteMessage_InvalidContact", func(t *testing.T) {
			err := messageBusiness.DeleteMessage(ctx, "some-message-id", nil)
			require.Error(t, err)

			err = messageBusiness.DeleteMessage(ctx, "some-message-id", &commonv1.ContactLink{})
			require.Error(t, err)
		})

		t.Run("DeleteMessage_NonExistent", func(t *testing.T) {
			err := messageBusiness.DeleteMessage(ctx, util.IDString(), validContact)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrMessageNotFound)
		})

		t.Run("MarkMessagesAsRead_InvalidContact", func(t *testing.T) {
			err := messageBusiness.MarkMessagesAsRead(ctx, "room-id", "event-id", nil)
			require.Error(t, err)

			err = messageBusiness.MarkMessagesAsRead(ctx, "room-id", "event-id", &commonv1.ContactLink{})
			require.Error(t, err)
		})

		t.Run("MarkMessagesAsRead_EmptyRoomID", func(t *testing.T) {
			err := messageBusiness.MarkMessagesAsRead(ctx, "", "event-id", validContact)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrMessageRoomIDRequired)
		})

		t.Run("GetMessage_InvalidContact", func(t *testing.T) {
			_, err := messageBusiness.GetMessage(ctx, util.IDString(), nil)
			require.Error(t, err)

			_, err = messageBusiness.GetMessage(ctx, util.IDString(), &commonv1.ContactLink{})
			require.Error(t, err)
		})

		t.Run("GetMessage_EmptyID", func(t *testing.T) {
			_, err := messageBusiness.GetMessage(ctx, "", validContact)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrUnspecifiedID)
		})

		t.Run("GetMessage_NotFound", func(t *testing.T) {
			_, err := messageBusiness.GetMessage(ctx, util.IDString(), validContact)
			require.Error(t, err)
		})
	})
}

// TestSendEventsExtended tests idempotent duplicate, multiple rooms, and mixed access in a single setup.
func (s *MessageBusinessTestSuite) TestSendEventsExtended() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		creator := &commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID}

		// Create two rooms
		room1, err := roomBusiness.CreateRoom(ctx,
			&chatv1.CreateRoomRequest{Name: "Extended Room 1", IsPrivate: false}, creator)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room1.GetId(), creatorID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, room1.GetId(), t)

		room2, err := roomBusiness.CreateRoom(ctx,
			&chatv1.CreateRoomRequest{Name: "Extended Room 2", IsPrivate: false}, creator)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room2.GetId(), creatorID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, room2.GetId(), t)

		t.Run("IdempotentDuplicate", func(t *testing.T) {
			eventID := util.IDString()
			msgReq := &chatv1.SendEventRequest{
				Event: []*chatv1.RoomEvent{
					{
						Id:     eventID,
						RoomId: room1.GetId(),
						Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
						Payload: &chatv1.Payload{
							Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "idempotent test"}},
						},
					},
				},
			}

			acks1, err := messageBusiness.SendEvents(ctx, msgReq, creator)
			require.NoError(t, err)
			require.Len(t, acks1, 1)
			s.Nil(acks1[0].GetError())

			acks2, err := messageBusiness.SendEvents(ctx, msgReq, creator)
			require.NoError(t, err)
			require.Len(t, acks2, 1)
			s.Nil(acks2[0].GetError(), "duplicate send should succeed (idempotent)")
			s.Equal(eventID, acks2[0].GetEventId()[0])
		})

		t.Run("MultipleRooms", func(t *testing.T) {
			msgReq := &chatv1.SendEventRequest{
				Event: []*chatv1.RoomEvent{
					{
						RoomId: room1.GetId(),
						Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
						Payload: &chatv1.Payload{
							Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "msg to room 1"}},
						},
					},
					{
						RoomId: room2.GetId(),
						Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
						Payload: &chatv1.Payload{
							Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "msg to room 2"}},
						},
					},
				},
			}

			acks, err := messageBusiness.SendEvents(ctx, msgReq, creator)
			require.NoError(t, err)
			require.Len(t, acks, 2)
			for _, ack := range acks {
				s.Nil(ack.GetError())
				s.NotEmpty(ack.GetEventId())
			}
		})

		t.Run("MixedAccessRooms", func(t *testing.T) {
			nonExistentRoomID := util.IDString()
			msgReq := &chatv1.SendEventRequest{
				Event: []*chatv1.RoomEvent{
					{
						RoomId: room1.GetId(),
						Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
						Payload: &chatv1.Payload{
							Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "good msg"}},
						},
					},
					{
						RoomId: nonExistentRoomID,
						Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
						Payload: &chatv1.Payload{
							Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "bad msg"}},
						},
					},
				},
			}

			acks, err := messageBusiness.SendEvents(ctx, msgReq, creator)
			require.NoError(t, err)
			require.Len(t, acks, 2)
			s.Nil(acks[0].GetError(), "accessible room should succeed")
			s.NotNil(acks[1].GetError(), "non-existent room should have error")
		})

		t.Run("NilPayload", func(t *testing.T) {
			msgReq := &chatv1.SendEventRequest{
				Event: []*chatv1.RoomEvent{
					{
						RoomId:  room1.GetId(),
						Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
						Payload: nil, // nil payload
					},
				},
			}

			acks, err := messageBusiness.SendEvents(ctx, msgReq, creator)
			require.NoError(t, err)
			require.Len(t, acks, 1)
			s.NotNil(acks[0].GetError(), "nil payload should produce error ack")
		})

		t.Run("WithParentID", func(t *testing.T) {
			// Send original message
			acks, err := messageBusiness.SendEvents(ctx, &chatv1.SendEventRequest{
				Event: []*chatv1.RoomEvent{{
					RoomId:  room1.GetId(),
					Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "original"}}},
				}},
			}, creator)
			require.NoError(t, err)
			parentID := acks[0].GetEventId()[0]

			// Send reply
			replyAcks, err := messageBusiness.SendEvents(ctx, &chatv1.SendEventRequest{
				Event: []*chatv1.RoomEvent{{
					RoomId:   room1.GetId(),
					Type:     chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					ParentId: &parentID,
					Payload:  &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "reply"}}},
				}},
			}, creator)
			require.NoError(t, err)
			require.Len(t, replyAcks, 1)
			s.Nil(replyAcks[0].GetError())
		})
	})
}

// TestGetHistory_WithPagination tests pagination for message history.
func (s *MessageBusinessTestSuite) TestGetHistory_WithPagination() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		creator := &commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID}

		room, err := roomBusiness.CreateRoom(ctx,
			&chatv1.CreateRoomRequest{Name: "Pagination Room", IsPrivate: false}, creator)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, room.GetId(), t)

		// Send 10 messages
		for range 10 {
			msgReq := &chatv1.SendEventRequest{
				Event: []*chatv1.RoomEvent{{
					RoomId:  room.GetId(),
					Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "page test"}}},
				}},
			}
			_, sendErr := messageBusiness.SendEvents(ctx, msgReq, creator)
			require.NoError(t, sendErr)
		}

		events, err := messageBusiness.GetHistory(ctx,
			&chatv1.GetHistoryRequest{
				RoomId: room.GetId(),
				Cursor: &commonv1.PageCursor{Limit: 3, Page: ""},
			}, creator)
		require.NoError(t, err)
		s.Len(events, 3)

		events2, err := messageBusiness.GetHistory(ctx,
			&chatv1.GetHistoryRequest{RoomId: room.GetId()}, creator)
		require.NoError(t, err)
		s.GreaterOrEqual(len(events2), 10)
	})
}

// TestDeleteMessage_NonExistentSenderSubscription tests deletion when the sender's
// subscription record no longer exists (e.g. removed from room). In this case,
// the code falls through to the admin check path.
func (s *MessageBusinessTestSuite) TestDeleteMessage_NonExistentSenderSubscription() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		workMan := svc.WorkManager()
		dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)
		subRepo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

		// Create room with a member
		creatorID := util.IDString()
		creatorContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()
		creator := &commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID}
		member := &commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID}

		room, err := roomBusiness.CreateRoom(ctx,
			&chatv1.CreateRoomRequest{
				Name:      "Deleted Sender Test Room",
				IsPrivate: false,
				Members:   []*commonv1.ContactLink{member},
			}, creator)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), memberID, t)
		s.WaitForAuthzAccess(ctx, svc, memberID, room.GetId(), t)

		// Member sends a message
		msgReq := &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{{
				RoomId:  room.GetId(),
				Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
				Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "test"}}},
			}},
		}
		acks, err := messageBusiness.SendEvents(ctx, msgReq, member)
		require.NoError(t, err)
		messageID := acks[0].GetEventId()[0]

		// Hard-delete the member's subscription to simulate the sender
		// subscription not being found
		subs, err := subRepo.GetByContactLinkAndRooms(ctx, member, room.GetId())
		require.NoError(t, err)
		require.NotEmpty(t, subs)
		err = subRepo.Delete(ctx, subs[0].GetID())
		require.NoError(t, err)

		// A non-admin non-sender should be denied (sender sub missing + not admin)
		anotherUser := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		err = messageBusiness.DeleteMessage(ctx, messageID, anotherUser)
		require.Error(t, err, "non-admin with missing sender sub should be denied")

		// Owner (admin) should still be able to delete
		err = messageBusiness.DeleteMessage(ctx, messageID, creator)
		require.NoError(t, err, "admin should be able to delete when sender sub is missing")
	})
}

// TestDeleteMessageViaBusinessLayer tests the full delete message flow via business layer.
func (s *MessageBusinessTestSuite) TestDeleteMessageViaBusinessLayer() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		workMan := svc.WorkManager()
		dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)
		eventRepo := repository.NewRoomEventRepository(ctx, dbPool, workMan)

		creatorID := util.IDString()
		creatorContactID := util.IDString()
		creator := &commonv1.ContactLink{ProfileId: creatorID, ContactId: creatorContactID}

		room, err := roomBusiness.CreateRoom(ctx,
			&chatv1.CreateRoomRequest{Name: "Delete Business Room", IsPrivate: false}, creator)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), creatorID, t)
		s.WaitForAuthzAccess(ctx, svc, creatorID, room.GetId(), t)

		msgReq := &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{{
				RoomId:  room.GetId(),
				Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
				Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "to be deleted"}}},
			}},
		}
		acks, err := messageBusiness.SendEvents(ctx, msgReq, creator)
		require.NoError(t, err)
		messageID := acks[0].GetEventId()[0]

		err = messageBusiness.DeleteMessage(ctx, messageID, creator)
		require.NoError(t, err)

		_, err = eventRepo.GetByID(ctx, messageID)
		require.Error(t, err)
		require.True(t, data.ErrorIsNoRows(err))
	})
}

// TestAuthzDeniedAfterSubscription_Message tests authz-denied paths in message operations
// when a subscription exists but the authz tuple has been removed from Keto.
func (s *MessageBusinessTestSuite) TestAuthzDeniedAfterSubscription_Message() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		ownerID := util.IDString()
		ownerContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()
		owner := &commonv1.ContactLink{ProfileId: ownerID, ContactId: ownerContactID}
		member := &commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID}

		room, err := roomBusiness.CreateRoom(ctx,
			&chatv1.CreateRoomRequest{
				Name:    "Authz Message Test",
				Members: []*commonv1.ContactLink{member},
			}, owner)
		require.NoError(t, err)
		roomID := room.GetId()
		s.WaitForMemberSubscription(ctx, svc, roomID, ownerID, t)
		s.WaitForMemberSubscription(ctx, svc, roomID, memberID, t)
		s.WaitForAuthzAccess(ctx, svc, ownerID, roomID, t)
		s.WaitForAuthzAccess(ctx, svc, memberID, roomID, t)

		// Owner sends a message (before authz removal)
		acks, err := messageBusiness.SendEvents(ctx, &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{{
				RoomId:  roomID,
				Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
				Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "hello"}}},
			}},
		}, owner)
		require.NoError(t, err)
		require.Len(t, acks, 1)
		messageID := acks[0].GetEventId()[0]

		// Get member's subscription ID
		workMan := svc.WorkManager()
		dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)
		subRepo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

		subs, err := subRepo.GetByContactLinkAndRooms(ctx, member, roomID)
		require.NoError(t, err)
		require.NotEmpty(t, subs)
		memberSubID := subs[0].GetID()

		// Remove authz tuple for member
		err = s.AuthzMiddleware.RemoveRoomMember(ctx, roomID, memberSubID)
		require.NoError(t, err)

		t.Run("GetHistory_AuthzDenied", func(t *testing.T) {
			_, err := messageBusiness.GetHistory(ctx,
				&chatv1.GetHistoryRequest{RoomId: roomID}, member)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrRoomAccessDenied)
		})

		t.Run("GetMessage_AuthzDenied", func(t *testing.T) {
			_, err := messageBusiness.GetMessage(ctx, messageID, member)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrMessageAccessDenied)
		})

		t.Run("MarkMessagesAsRead_AuthzDenied", func(t *testing.T) {
			err := messageBusiness.MarkMessagesAsRead(ctx, roomID, messageID, member)
			require.Error(t, err)
			require.ErrorIs(t, err, service.ErrRoomAccessDenied)
		})

		t.Run("SendEvents_AuthzDenied", func(t *testing.T) {
			// Member has subscription but no authz → should get per-event error ack
			acks, err := messageBusiness.SendEvents(ctx, &chatv1.SendEventRequest{
				Event: []*chatv1.RoomEvent{{
					RoomId:  roomID,
					Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "denied"}}},
				}},
			}, member)
			require.NoError(t, err)
			require.Len(t, acks, 1)
			require.NotNil(t, acks[0].GetError(), "should get permission denied error ack")
		})
	})
}

// TestSendEvents_NonMemberCannotSend verifies that a user with no subscription
// to the room gets an error ack when attempting to send a message.
func (s *MessageBusinessTestSuite) TestSendEvents_NonMemberCannotSend() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		ownerID := util.IDString()
		ownerContactID := util.IDString()
		ctx = s.WithAuthClaims(ctx, "tenant1", "partition1", ownerID)
		owner := &commonv1.ContactLink{ProfileId: ownerID, ContactId: ownerContactID}

		// Create room with only the owner
		room, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{
			Name:      "Owner Only Room",
			IsPrivate: false,
		}, owner)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), ownerID, t)
		s.WaitForAuthzAccess(ctx, svc, ownerID, room.GetId(), t)

		// A completely different user tries to send a message
		nonMemberID := util.IDString()
		nonMemberContactID := util.IDString()
		nonMember := &commonv1.ContactLink{ProfileId: nonMemberID, ContactId: nonMemberContactID}

		acks, err := messageBusiness.SendEvents(ctx, &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{{
				RoomId:  room.GetId(),
				Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
				Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "intruder"}}},
			}},
		}, nonMember)
		require.NoError(t, err)
		require.Len(t, acks, 1)
		require.NotNil(t, acks[0].GetError(), "non-member should get error ack")
	})
}

// TestSendEvents_ConcurrentDuplicate verifies idempotent handling when the same
// event ID is sent twice — the second send hits the ExistsByIDs dedup path.
func (s *MessageBusinessTestSuite) TestSendEvents_ConcurrentDuplicate() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		ownerID := util.IDString()
		ownerContactID := util.IDString()
		ctx = s.WithAuthClaims(ctx, "tenant1", "partition1", ownerID)
		owner := &commonv1.ContactLink{ProfileId: ownerID, ContactId: ownerContactID}

		room, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{
			Name:      "Dedup Test Room",
			IsPrivate: false,
		}, owner)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), ownerID, t)
		s.WaitForAuthzAccess(ctx, svc, ownerID, room.GetId(), t)

		eventID := util.IDString()
		makeReq := func() *chatv1.SendEventRequest {
			return &chatv1.SendEventRequest{
				Event: []*chatv1.RoomEvent{{
					Id:      eventID,
					RoomId:  room.GetId(),
					Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "hello"}}},
				}},
			}
		}

		// First send — should succeed
		acks1, err := messageBusiness.SendEvents(ctx, makeReq(), owner)
		require.NoError(t, err)
		require.Len(t, acks1, 1)
		require.Nil(t, acks1[0].GetError(), "first send should succeed")

		// Second send with same event ID — should be idempotent (dedup)
		acks2, err := messageBusiness.SendEvents(ctx, makeReq(), owner)
		require.NoError(t, err)
		require.Len(t, acks2, 1)
		require.Nil(t, acks2[0].GetError(), "duplicate send should succeed idempotently")
	})
}

func (s *MessageBusinessTestSuite) TestCallEvents_CreateAndTransitionRoomCall() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayerWithCallPolicy(
			ctx,
			svc,
			business.CallPolicyConfig{DirectCallMemberLimit: 2, MeshCallMemberLimit: 4},
		)

		workMan := svc.WorkManager()
		dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)
		callRepo := repository.NewRoomCallRepository(ctx, dbPool, workMan)

		ownerID := util.IDString()
		ownerContactID := util.IDString()
		memberID := util.IDString()
		memberContactID := util.IDString()
		owner := &commonv1.ContactLink{ProfileId: ownerID, ContactId: ownerContactID}
		member := &commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID}

		room, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{
			Name:      "Direct Call Room",
			IsPrivate: false,
			Members:   []*commonv1.ContactLink{member},
		}, owner)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), ownerID, t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), memberID, t)
		s.WaitForAuthzAccess(ctx, svc, ownerID, room.GetId(), t)
		s.WaitForAuthzAccess(ctx, svc, memberID, room.GetId(), t)

		callID := util.IDString()
		offerSDP := "offer-sdp"
		offerReq := &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{{
				RoomId: room.GetId(),
				Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_CALL,
				Payload: &chatv1.Payload{
					Data: &chatv1.Payload_Call{Call: &chatv1.CallContent{
						CallId: callID,
						Type:   chatv1.CallContent_CALL_TYPE_VIDEO,
						Action: chatv1.CallContent_CALL_ACTION_OFFER,
						Sdp:    &offerSDP,
						Metadata: &structpb.Struct{Fields: map[string]*structpb.Value{
							"topology": {Kind: &structpb.Value_StringValue{StringValue: "p2p"}},
						}},
					}},
				},
			}},
		}

		acks, err := messageBusiness.SendEvents(ctx, offerReq, owner)
		require.NoError(t, err)
		require.Len(t, acks, 1)
		require.Nil(t, acks[0].GetError())

		callRecord, err := callRepo.GetByCallID(ctx, callID)
		require.NoError(t, err)
		require.Equal(t, repository.CallStatusRinging, callRecord.Status)

		answerSDP := "answer-sdp"
		answerReq := &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{{
				RoomId: room.GetId(),
				Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_CALL,
				Payload: &chatv1.Payload{
					Data: &chatv1.Payload_Call{Call: &chatv1.CallContent{
						CallId: callID,
						Type:   chatv1.CallContent_CALL_TYPE_VIDEO,
						Action: chatv1.CallContent_CALL_ACTION_ANSWER,
						Sdp:    &answerSDP,
					}},
				},
			}},
		}

		acks, err = messageBusiness.SendEvents(ctx, answerReq, member)
		require.NoError(t, err)
		require.Len(t, acks, 1)
		require.Nil(t, acks[0].GetError())

		callRecord, err = callRepo.GetByCallID(ctx, callID)
		require.NoError(t, err)
		require.Equal(t, repository.CallStatusActive, callRecord.Status)

		endReq := &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{{
				RoomId: room.GetId(),
				Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_CALL,
				Payload: &chatv1.Payload{
					Data: &chatv1.Payload_Call{Call: &chatv1.CallContent{
						CallId: callID,
						Type:   chatv1.CallContent_CALL_TYPE_VIDEO,
						Action: chatv1.CallContent_CALL_ACTION_END,
					}},
				},
			}},
		}

		acks, err = messageBusiness.SendEvents(ctx, endReq, owner)
		require.NoError(t, err)
		require.Len(t, acks, 1)
		require.Nil(t, acks[0].GetError())

		callRecord, err = callRepo.GetByCallID(ctx, callID)
		require.NoError(t, err)
		require.Equal(t, repository.CallStatusEnded, callRecord.Status)
	})
}

func (s *MessageBusinessTestSuite) TestCallEvents_RejectOversizedDirectRoomWithoutSFU() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayerWithCallPolicy(
			ctx,
			svc,
			business.CallPolicyConfig{DirectCallMemberLimit: 2, MeshCallMemberLimit: 4},
		)

		ownerID := util.IDString()
		ownerContactID := util.IDString()
		member1ID := util.IDString()
		member2ID := util.IDString()
		owner := &commonv1.ContactLink{ProfileId: ownerID, ContactId: ownerContactID}

		room, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{
			Name:      "Oversized Direct Call Room",
			IsPrivate: false,
			Members: []*commonv1.ContactLink{
				{ProfileId: member1ID, ContactId: util.IDString()},
				{ProfileId: member2ID, ContactId: util.IDString()},
			},
		}, owner)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), ownerID, t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), member1ID, t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), member2ID, t)
		s.WaitForAuthzAccess(ctx, svc, ownerID, room.GetId(), t)

		offerSDP := "offer-sdp"
		acks, err := messageBusiness.SendEvents(ctx, &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{{
				RoomId: room.GetId(),
				Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_CALL,
				Payload: &chatv1.Payload{
					Data: &chatv1.Payload_Call{Call: &chatv1.CallContent{
						CallId: util.IDString(),
						Type:   chatv1.CallContent_CALL_TYPE_VIDEO,
						Action: chatv1.CallContent_CALL_ACTION_OFFER,
						Sdp:    &offerSDP,
						Metadata: &structpb.Struct{Fields: map[string]*structpb.Value{
							"topology": {Kind: &structpb.Value_StringValue{StringValue: "p2p"}},
						}},
					}},
				},
			}},
		}, owner)
		require.NoError(t, err)
		require.Len(t, acks, 1)
		require.NotNil(t, acks[0].GetError())
		require.Contains(t, acks[0].GetError().GetMessage(), "without SFU assignment")
	})
}

func (s *MessageBusinessTestSuite) TestGroupCallStageUpdate_PersistsAndCapsVideoStage() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayerWithCallPolicy(
			ctx,
			svc,
			business.CallPolicyConfig{
				DirectCallMemberLimit: 2,
				MeshCallMemberLimit:   8,
				MaxVideoPublishers:    5,
			},
		)

		workMan := svc.WorkManager()
		dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)
		callRepo := repository.NewRoomCallRepository(ctx, dbPool, workMan)

		owner := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		admin := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		member := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}

		room, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{
			Name:      "Stage Room",
			IsPrivate: false,
			Members:   []*commonv1.ContactLink{admin, member},
		}, owner)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), owner.GetProfileId(), t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), admin.GetProfileId(), t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), member.GetProfileId(), t)
		s.WaitForAuthzAccess(ctx, svc, owner.GetProfileId(), room.GetId(), t)
		s.WaitForAuthzAccess(ctx, svc, admin.GetProfileId(), room.GetId(), t)
		s.WaitForAuthzAccess(ctx, svc, member.GetProfileId(), room.GetId(), t)

		adminSubs, err := roomBusiness.SearchRoomSubscriptions(
			ctx,
			&chatv1.SearchRoomSubscriptionsRequest{RoomId: room.GetId()},
			owner,
		)
		require.NoError(t, err)
		var adminSubscriptionID string
		for _, sub := range adminSubs {
			if sub.GetMember().GetProfileId() == admin.GetProfileId() {
				adminSubscriptionID = sub.GetId()
				break
			}
		}
		require.NotEmpty(t, adminSubscriptionID)
		require.NoError(t, roomBusiness.UpdateSubscriptionRole(ctx, &chatv1.UpdateSubscriptionRoleRequest{
			RoomId:         room.GetId(),
			SubscriptionId: adminSubscriptionID,
			Roles:          []string{repository.RoleAdmin},
		}, owner))

		callID := util.IDString()
		startedAt := time.Now().UnixMilli()
		stageMeta := &structpb.Struct{Fields: map[string]*structpb.Value{
			"signalKind":         {Kind: &structpb.Value_StringValue{StringValue: "group_start"}},
			"topology":           {Kind: &structpb.Value_StringValue{StringValue: "mesh"}},
			"maxVideoPublishers": {Kind: &structpb.Value_NumberValue{NumberValue: 5}},
			"activeVideoProfileIds": {Kind: &structpb.Value_ListValue{ListValue: &structpb.ListValue{
				Values: []*structpb.Value{
					{Kind: &structpb.Value_StringValue{StringValue: owner.GetProfileId()}},
				},
			}}},
		}}
		acks, err := messageBusiness.SendEvents(ctx, &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{{
				RoomId: room.GetId(),
				Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_CALL,
				Payload: &chatv1.Payload{Data: &chatv1.Payload_Call{Call: &chatv1.CallContent{
					CallId:   callID,
					Type:     chatv1.CallContent_CALL_TYPE_VIDEO,
					Action:   chatv1.CallContent_CALL_ACTION_UNSPECIFIED,
					Metadata: stageMeta,
				}}},
			}},
		}, owner)
		require.NoError(t, err)
		require.Nil(t, acks[0].GetError())

		for _, caller := range []*commonv1.ContactLink{admin, member} {
			joinMeta := &structpb.Struct{Fields: map[string]*structpb.Value{
				"signalKind": {Kind: &structpb.Value_StringValue{StringValue: "group_join"}},
				"topology":   {Kind: &structpb.Value_StringValue{StringValue: "mesh"}},
				"joinedAt":   {Kind: &structpb.Value_NumberValue{NumberValue: float64(startedAt)}},
			}}
			acks, err = messageBusiness.SendEvents(ctx, &chatv1.SendEventRequest{
				Event: []*chatv1.RoomEvent{{
					RoomId: room.GetId(),
					Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_CALL,
					Payload: &chatv1.Payload{Data: &chatv1.Payload_Call{Call: &chatv1.CallContent{
						CallId:   callID,
						Type:     chatv1.CallContent_CALL_TYPE_VIDEO,
						Action:   chatv1.CallContent_CALL_ACTION_UNSPECIFIED,
						Metadata: joinMeta,
					}}},
				}},
			}, caller)
			require.NoError(t, err)
			require.Nil(t, acks[0].GetError())
		}

		stageUpdateMeta := &structpb.Struct{Fields: map[string]*structpb.Value{
			"signalKind":         {Kind: &structpb.Value_StringValue{StringValue: "group_stage_update"}},
			"topology":           {Kind: &structpb.Value_StringValue{StringValue: "mesh"}},
			"maxVideoPublishers": {Kind: &structpb.Value_NumberValue{NumberValue: 5}},
			"activeVideoProfileIds": {Kind: &structpb.Value_ListValue{ListValue: &structpb.ListValue{
				Values: []*structpb.Value{
					{Kind: &structpb.Value_StringValue{StringValue: owner.GetProfileId()}},
					{Kind: &structpb.Value_StringValue{StringValue: admin.GetProfileId()}},
				},
			}}},
		}}
		acks, err = messageBusiness.SendEvents(ctx, &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{{
				RoomId: room.GetId(),
				Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_CALL,
				Payload: &chatv1.Payload{Data: &chatv1.Payload_Call{Call: &chatv1.CallContent{
					CallId:   callID,
					Type:     chatv1.CallContent_CALL_TYPE_VIDEO,
					Action:   chatv1.CallContent_CALL_ACTION_UNSPECIFIED,
					Metadata: stageUpdateMeta,
				}}},
			}},
		}, admin)
		require.NoError(t, err)
		require.Nil(t, acks[0].GetError())

		callRecord, err := callRepo.GetByCallID(ctx, callID)
		require.NoError(t, err)
		assert.Equal(t, 5, toInt(callRecord.Metadata["maxVideoPublishers"]))
		assert.ElementsMatch(t, []string{
			owner.GetProfileId(),
			admin.GetProfileId(),
		}, toStringSlice(callRecord.Metadata["activeVideoProfileIds"]))
	})
}

func (s *MessageBusinessTestSuite) TestGroupCallStageUpdate_RejectsUnauthorizedParticipant() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayerWithCallPolicy(
			ctx,
			svc,
			business.CallPolicyConfig{
				DirectCallMemberLimit: 2,
				MeshCallMemberLimit:   8,
				MaxVideoPublishers:    5,
			},
		)

		owner := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		member := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}

		room, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{
			Name:      "Unauthorized Stage Room",
			IsPrivate: false,
			Members:   []*commonv1.ContactLink{member},
		}, owner)
		require.NoError(t, err)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), owner.GetProfileId(), t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), member.GetProfileId(), t)
		s.WaitForAuthzAccess(ctx, svc, owner.GetProfileId(), room.GetId(), t)
		s.WaitForAuthzAccess(ctx, svc, member.GetProfileId(), room.GetId(), t)

		callID := util.IDString()
		startMeta := &structpb.Struct{Fields: map[string]*structpb.Value{
			"signalKind": {Kind: &structpb.Value_StringValue{StringValue: "group_start"}},
			"topology":   {Kind: &structpb.Value_StringValue{StringValue: "mesh"}},
		}}
		acks, err := messageBusiness.SendEvents(ctx, &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{{
				RoomId: room.GetId(),
				Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_CALL,
				Payload: &chatv1.Payload{Data: &chatv1.Payload_Call{Call: &chatv1.CallContent{
					CallId:   callID,
					Type:     chatv1.CallContent_CALL_TYPE_VIDEO,
					Action:   chatv1.CallContent_CALL_ACTION_UNSPECIFIED,
					Metadata: startMeta,
				}}},
			}},
		}, owner)
		require.NoError(t, err)
		require.Nil(t, acks[0].GetError())

		joinMeta := &structpb.Struct{Fields: map[string]*structpb.Value{
			"signalKind": {Kind: &structpb.Value_StringValue{StringValue: "group_join"}},
			"topology":   {Kind: &structpb.Value_StringValue{StringValue: "mesh"}},
		}}
		acks, err = messageBusiness.SendEvents(ctx, &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{{
				RoomId: room.GetId(),
				Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_CALL,
				Payload: &chatv1.Payload{Data: &chatv1.Payload_Call{Call: &chatv1.CallContent{
					CallId:   callID,
					Type:     chatv1.CallContent_CALL_TYPE_VIDEO,
					Action:   chatv1.CallContent_CALL_ACTION_UNSPECIFIED,
					Metadata: joinMeta,
				}}},
			}},
		}, member)
		require.NoError(t, err)
		require.Nil(t, acks[0].GetError())

		stageMeta := &structpb.Struct{Fields: map[string]*structpb.Value{
			"signalKind": {Kind: &structpb.Value_StringValue{StringValue: "group_stage_update"}},
			"topology":   {Kind: &structpb.Value_StringValue{StringValue: "mesh"}},
			"activeVideoProfileIds": {Kind: &structpb.Value_ListValue{ListValue: &structpb.ListValue{
				Values: []*structpb.Value{
					{Kind: &structpb.Value_StringValue{StringValue: member.GetProfileId()}},
				},
			}}},
		}}
		acks, err = messageBusiness.SendEvents(ctx, &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{{
				RoomId: room.GetId(),
				Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_CALL,
				Payload: &chatv1.Payload{Data: &chatv1.Payload_Call{Call: &chatv1.CallContent{
					CallId:   callID,
					Type:     chatv1.CallContent_CALL_TYPE_VIDEO,
					Action:   chatv1.CallContent_CALL_ACTION_UNSPECIFIED,
					Metadata: stageMeta,
				}}},
			}},
		}, member)
		require.NoError(t, err)
		require.NotNil(t, acks[0].GetError())
		require.Contains(t, acks[0].GetError().GetMessage(), "initiator or room admins")
	})
}

func toStringSlice(raw any) []string {
	switch typed := raw.(type) {
	case []string:
		return typed
	case []any:
		result := make([]string, 0, len(typed))
		for _, item := range typed {
			if value, ok := item.(string); ok && value != "" {
				result = append(result, value)
			}
		}
		return result
	default:
		return nil
	}
}

func toInt(raw any) int {
	switch typed := raw.(type) {
	case int:
		return typed
	case int32:
		return int(typed)
	case int64:
		return int(typed)
	case float64:
		return int(typed)
	case json.Number:
		value, err := typed.Int64()
		if err == nil {
			return int(value)
		}
		return 0
	default:
		return 0
	}
}
