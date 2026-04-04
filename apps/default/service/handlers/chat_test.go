package handlers_test

import (
	"context"
	"testing"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	"connectrpc.com/connect"
	"github.com/antinvestor/service-chat/apps/default/service/handlers"
	"github.com/antinvestor/service-chat/apps/default/tests"
	"github.com/pitabwire/frame"
	"github.com/pitabwire/frame/frametests/definition"
	"github.com/pitabwire/frame/security"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/structpb"
)

const (
	testTenantID    = "tenant1"
	testPartitionID = "partition1"
)

type ChatServerTestSuite struct {
	tests.BaseTestSuite
}

func TestChatServerTestSuite(t *testing.T) {
	suite.Run(t, new(ChatServerTestSuite))
}

// createRoomAndWait creates a room via the handler and waits for the creator's
// subscription and authz access to be set up asynchronously.
func (s *ChatServerTestSuite) createRoomAndWait(
	ctx context.Context,
	t *testing.T,
	svc *frame.Service,
	chatServer *handlers.ChatServer,
	profileID string,
	req *connect.Request[chatv1.CreateRoomRequest],
) string {
	t.Helper()
	createResp, err := chatServer.CreateRoom(ctx, req)
	require.NoError(t, err)
	roomID := createResp.Msg.GetRoom().GetId()
	s.WaitForMemberSubscription(ctx, svc, roomID, profileID, t)
	s.WaitForAuthzAccess(ctx, svc, profileID, roomID, t)
	return roomID
}

func (s *ChatServerTestSuite) TestCreateRoom() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		req := connect.NewRequest(&chatv1.CreateRoomRequest{
			Name:        "Test Room",
			Description: "A test room",
			IsPrivate:   false,
			Metadata:    &structpb.Struct{Fields: map[string]*structpb.Value{}},
		})

		resp, err := chatServer.CreateRoom(ctx, req)
		require.NoError(t, err)
		s.NotNil(resp)
		s.NotEmpty(resp.Msg.GetRoom().GetId())
		s.Equal("Test Room", resp.Msg.GetRoom().GetName())
	})
}

func (s *ChatServerTestSuite) TestCreateRoomUnauthenticated() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		req := connect.NewRequest(&chatv1.CreateRoomRequest{
			Name:      "Test Room",
			IsPrivate: false,
		})

		_, err := chatServer.CreateRoom(ctx, req)
		require.Error(t, err)
	})
}

func (s *ChatServerTestSuite) TestUpdateRoom() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		roomID := s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:      "Original Room",
				IsPrivate: false,
			}))

		// Update the room
		updateReq := connect.NewRequest(&chatv1.UpdateRoomRequest{
			RoomId:      roomID,
			Name:        "Updated Room",
			Description: "Updated topic",
		})

		updateResp, err := chatServer.UpdateRoom(ctx, updateReq)
		require.NoError(t, err)
		s.Equal("Updated Room", updateResp.Msg.GetRoom().GetName())
	})
}

func (s *ChatServerTestSuite) TestDeleteRoom() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		roomID := s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:      "Room to Delete",
				IsPrivate: false,
			}))

		// Delete the room
		deleteReq := connect.NewRequest(&chatv1.DeleteRoomRequest{
			RoomId: roomID,
		})

		_, err := chatServer.DeleteRoom(ctx, deleteReq)
		require.NoError(t, err)
	})
}

func (s *ChatServerTestSuite) TestSendEvent() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		roomID := s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:      "Message Room",
				IsPrivate: false,
			}))

		// Send message
		msgReq := connect.NewRequest(&chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{
				{
					RoomId: roomID,
					Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{
						Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "test message"}},
					},
				},
			},
		})

		msgResp, err := chatServer.SendEvent(ctx, msgReq)
		require.NoError(t, err)
		s.Len(msgResp.Msg.GetAck(), 1)
		s.NotEmpty(msgResp.Msg.GetAck()[0].GetEventId())
		s.Len(msgResp.Msg.GetAck()[0].GetEventId(), 1)
	})
}

func (s *ChatServerTestSuite) TestGetHistory() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		roomID := s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:      "History Room",
				IsPrivate: false,
			}))

		// Send messages
		for range 5 {
			msgReq := connect.NewRequest(&chatv1.SendEventRequest{
				Event: []*chatv1.RoomEvent{
					{
						RoomId: roomID,
						Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
						Payload: &chatv1.Payload{
							Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "test message"}},
						},
					},
				},
			})

			_, err := chatServer.SendEvent(ctx, msgReq)
			require.NoError(t, err)
		}

		// Get history
		historyReq := connect.NewRequest(&chatv1.GetHistoryRequest{
			RoomId: roomID,
			Cursor: &commonv1.PageCursor{Limit: 10, Page: ""},
		})

		historyResp, err := chatServer.GetHistory(ctx, historyReq)
		require.NoError(t, err)
		s.GreaterOrEqual(len(historyResp.Msg.GetEvents()), 5)
	})
}

func (s *ChatServerTestSuite) TestAddRoomSubscriptions() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		roomID := s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:      "Subscription Room",
				IsPrivate: false,
			}))

		// Add member
		memberID := util.IDString()
		memberContactID := util.IDString()
		addReq := connect.NewRequest(&chatv1.AddRoomSubscriptionsRequest{
			RoomId: roomID,
			Members: []*chatv1.RoomSubscription{
				{
					Member: &commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
					Roles:  []string{"member"},
				},
			},
		})

		_, err := chatServer.AddRoomSubscriptions(ctx, addReq)
		require.NoError(t, err)
	})
}

func (s *ChatServerTestSuite) TestRemoveRoomSubscriptions() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		roomID := s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:      "Removal Room",
				IsPrivate: false,
			}))

		// Add member
		memberID := util.IDString()
		memberContactID := util.IDString()
		addReq := connect.NewRequest(&chatv1.AddRoomSubscriptionsRequest{
			RoomId: roomID,
			Members: []*chatv1.RoomSubscription{
				{
					Member: &commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
					Roles:  []string{"member"},
				},
			},
		})

		_, err := chatServer.AddRoomSubscriptions(ctx, addReq)
		require.NoError(t, err)

		// Wait for member subscription to be created
		s.WaitForMemberSubscription(ctx, svc, roomID, memberID, t)

		// Get subscription ID
		searchReq := connect.NewRequest(&chatv1.SearchRoomSubscriptionsRequest{
			RoomId: roomID,
		})
		searchResp, err := chatServer.SearchRoomSubscriptions(ctx, searchReq)
		require.NoError(t, err)

		var subscriptionID string
		for _, sub := range searchResp.Msg.GetMembers() {
			if sub.GetMember().GetProfileId() == memberID {
				subscriptionID = sub.GetId()
				break
			}
		}
		require.NotEmpty(t, subscriptionID)

		// Remove member
		removeReq := connect.NewRequest(&chatv1.RemoveRoomSubscriptionsRequest{
			RoomId:         roomID,
			SubscriptionId: []string{subscriptionID},
		})

		_, err = chatServer.RemoveRoomSubscriptions(ctx, removeReq)
		require.NoError(t, err)
	})
}

func (s *ChatServerTestSuite) TestUpdateSubscriptionRole() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		roomID := s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:      "Role Update Room",
				IsPrivate: false,
			}))

		// Add member
		memberID := util.IDString()
		memberContactID := util.IDString()
		addReq := connect.NewRequest(&chatv1.AddRoomSubscriptionsRequest{
			RoomId: roomID,
			Members: []*chatv1.RoomSubscription{
				{
					Member: &commonv1.ContactLink{ProfileId: memberID, ContactId: memberContactID},
					Roles:  []string{"member"},
				},
			},
		})

		_, err := chatServer.AddRoomSubscriptions(ctx, addReq)
		require.NoError(t, err)

		// Wait for member subscription to be created
		s.WaitForMemberSubscription(ctx, svc, roomID, memberID, t)

		// Get subscription ID
		searchReq := connect.NewRequest(&chatv1.SearchRoomSubscriptionsRequest{
			RoomId: roomID,
		})
		searchResp, err := chatServer.SearchRoomSubscriptions(ctx, searchReq)
		require.NoError(t, err)

		var subscriptionID string
		for _, sub := range searchResp.Msg.GetMembers() {
			if sub.GetMember().GetProfileId() == memberID {
				subscriptionID = sub.GetId()
				break
			}
		}
		require.NotEmpty(t, subscriptionID)

		// Update role to moderator
		updateReq := connect.NewRequest(&chatv1.UpdateSubscriptionRoleRequest{
			RoomId:         roomID,
			SubscriptionId: subscriptionID,
			Roles:          []string{"moderator"},
		})

		_, err = chatServer.UpdateSubscriptionRole(ctx, updateReq)
		require.NoError(t, err)
	})
}

func (s *ChatServerTestSuite) TestSearchRoomSubscriptions() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		roomID := s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:      "Search Subscriptions Room",
				IsPrivate: false,
			}))

		// Search subscriptions
		searchReq := connect.NewRequest(&chatv1.SearchRoomSubscriptionsRequest{
			RoomId: roomID,
		})

		searchResp, err := chatServer.SearchRoomSubscriptions(ctx, searchReq)
		require.NoError(t, err)
		s.GreaterOrEqual(len(searchResp.Msg.GetMembers()), 1) // At least the creator
	})
}

// withSystemAuth creates a context with system_internal role for Live API tests.
func (s *ChatServerTestSuite) withSystemAuth(ctx context.Context, profileID string) context.Context {
	claims := &security.AuthenticationClaims{
		TenantID:    testTenantID,
		PartitionID: testPartitionID,
		AccessID:    util.IDString(),
		ContactID:   profileID,
		SessionID:   util.IDString(),
		DeviceID:    "test-device",
		Roles:       []string{"internal"},
	}
	claims.Subject = profileID
	return claims.ClaimsToContext(ctx)
}

func (s *ChatServerTestSuite) setupLiveTest(
	t *testing.T, dep *definition.DependencyOption,
) (context.Context, *frame.Service, *handlers.ChatServer) {
	ctx, svc := s.CreateService(t, dep)
	chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)
	profileID := util.IDString()
	ctx = s.withSystemAuth(ctx, profileID)
	return ctx, svc, chatServer
}

func (s *ChatServerTestSuite) TestLive_TypingIndicator() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc, chatServer := s.setupLiveTest(t, dep)

		profileID := security.ClaimsFromContext(ctx).ContactID

		roomID := s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:      "Typing Test Room",
				IsPrivate: false,
			}))

		// Send typing indicator via Live
		liveReq := connect.NewRequest(&chatv1.LiveRequest{
			ClientStates: []*chatv1.ClientCommand{
				{
					State: &chatv1.ClientCommand_Typing{
						Typing: &chatv1.TypingEvent{
							RoomId: roomID,
							Typing: true,
						},
					},
				},
			},
		})

		resp, err := chatServer.Live(ctx, liveReq)
		require.NoError(t, err)
		s.NotNil(resp)
	})
}

func (s *ChatServerTestSuite) TestLive_ReadMarker() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc, chatServer := s.setupLiveTest(t, dep)

		profileID := security.ClaimsFromContext(ctx).ContactID

		roomID := s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:      "ReadMarker Test Room",
				IsPrivate: false,
			}))

		msgReq := connect.NewRequest(&chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{
				{
					RoomId:  roomID,
					Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "hello"}}},
				},
			},
		})

		msgResp, err := chatServer.SendEvent(ctx, msgReq)
		require.NoError(t, err)
		eventID := msgResp.Msg.GetAck()[0].GetEventId()[0]

		// Mark as read via Live
		liveReq := connect.NewRequest(&chatv1.LiveRequest{
			ClientStates: []*chatv1.ClientCommand{
				{
					State: &chatv1.ClientCommand_ReadMarker{
						ReadMarker: &chatv1.ReadMarker{
							RoomId:      &roomID,
							UpToEventId: eventID,
						},
					},
				},
			},
		})

		resp, err := chatServer.Live(ctx, liveReq)
		require.NoError(t, err)
		s.NotNil(resp)
	})
}

func (s *ChatServerTestSuite) TestLive_EmptyClientStates() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, _, chatServer := s.setupLiveTest(t, dep)

		liveReq := connect.NewRequest(&chatv1.LiveRequest{
			ClientStates: []*chatv1.ClientCommand{},
		})

		_, err := chatServer.Live(ctx, liveReq)
		require.Error(t, err)
	})
}

func (s *ChatServerTestSuite) TestLive_Unauthenticated() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		liveReq := connect.NewRequest(&chatv1.LiveRequest{
			ClientStates: []*chatv1.ClientCommand{
				{
					State: &chatv1.ClientCommand_Presence{
						Presence: &chatv1.PresenceEvent{
							Status: chatv1.PresenceStatus_PRESENCE_STATUS_ONLINE,
						},
					},
				},
			},
		})

		_, err := chatServer.Live(ctx, liveReq)
		require.Error(t, err)
	})
}

func (s *ChatServerTestSuite) TestGetEvent() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		roomID := s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:      "GetEvent Room",
				IsPrivate: false,
			}))

		// Send a message to get an event ID
		msgReq := connect.NewRequest(&chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{
				{
					RoomId: roomID,
					Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{
						Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "get event test"}},
					},
				},
			},
		})

		msgResp, err := chatServer.SendEvent(ctx, msgReq)
		require.NoError(t, err)
		require.Len(t, msgResp.Msg.GetAck(), 1)
		require.Len(t, msgResp.Msg.GetAck()[0].GetEventId(), 1)
		eventID := msgResp.Msg.GetAck()[0].GetEventId()[0]

		// Get the event by ID
		getReq := connect.NewRequest(&chatv1.GetEventRequest{
			RoomId:  roomID,
			EventId: eventID,
		})

		getResp, err := chatServer.GetEvent(ctx, getReq)
		require.NoError(t, err)
		s.NotNil(getResp.Msg.GetEvent())
		s.Equal(eventID, getResp.Msg.GetEvent().GetId())
		s.Equal(roomID, getResp.Msg.GetEvent().GetRoomId())
	})
}

func (s *ChatServerTestSuite) TestGetEvent_InvalidEventID() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		getReq := connect.NewRequest(&chatv1.GetEventRequest{
			EventId: "",
		})

		_, err := chatServer.GetEvent(ctx, getReq)
		require.Error(t, err)
	})
}

func (s *ChatServerTestSuite) TestGetRoom() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		roomID := s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:        "GetRoom Test",
				Description: "A room to retrieve",
				IsPrivate:   false,
			}))

		// Get the room
		getReq := connect.NewRequest(&chatv1.GetRoomRequest{
			RoomId: roomID,
		})

		getResp, err := chatServer.GetRoom(ctx, getReq)
		require.NoError(t, err)
		s.NotNil(getResp.Msg.GetRoom())
		s.Equal(roomID, getResp.Msg.GetRoom().GetId())
		s.Equal("GetRoom Test", getResp.Msg.GetRoom().GetName())
	})
}

func (s *ChatServerTestSuite) TestGetRoom_InvalidRoomID() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		getReq := connect.NewRequest(&chatv1.GetRoomRequest{
			RoomId: "",
		})

		_, err := chatServer.GetRoom(ctx, getReq)
		require.Error(t, err)
	})
}

func (s *ChatServerTestSuite) TestGetRoom_Unauthenticated() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		getReq := connect.NewRequest(&chatv1.GetRoomRequest{
			RoomId: util.IDString(),
		})

		_, err := chatServer.GetRoom(ctx, getReq)
		require.Error(t, err)
	})
}

func (s *ChatServerTestSuite) TestGetSubscriptionSettings() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		roomID := s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:      "Settings Room",
				IsPrivate: false,
			}))

		// Get subscription settings
		getReq := connect.NewRequest(&chatv1.GetSubscriptionSettingsRequest{
			RoomId: roomID,
		})

		getResp, err := chatServer.GetSubscriptionSettings(ctx, getReq)
		require.NoError(t, err)
		s.NotNil(getResp.Msg.GetSettings())
		s.Equal(roomID, getResp.Msg.GetSettings().GetRoomId())
	})
}

func (s *ChatServerTestSuite) TestGetSubscriptionSettings_InvalidRoomID() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		getReq := connect.NewRequest(&chatv1.GetSubscriptionSettingsRequest{
			RoomId: "",
		})

		_, err := chatServer.GetSubscriptionSettings(ctx, getReq)
		require.Error(t, err)
	})
}

func (s *ChatServerTestSuite) TestUpdateSubscriptionSettings() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		roomID := s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:      "Update Settings Room",
				IsPrivate: false,
			}))

		// Update subscription settings with muted, pinned, and notification level
		nl := chatv1.NotificationLevel_NOTIFICATION_LEVEL_MENTIONS
		updateReq := connect.NewRequest(&chatv1.UpdateSubscriptionSettingsRequest{
			RoomId:            roomID,
			Muted:             proto.Bool(true),
			Pinned:            proto.Bool(true),
			Archived:          proto.Bool(false),
			NotificationLevel: &nl,
		})

		updateResp, err := chatServer.UpdateSubscriptionSettings(ctx, updateReq)
		require.NoError(t, err)
		s.NotNil(updateResp.Msg.GetSettings())
		s.True(updateResp.Msg.GetSettings().GetMuted())
		s.True(updateResp.Msg.GetSettings().GetPinned())
		s.False(updateResp.Msg.GetSettings().GetArchived())
		s.Equal(chatv1.NotificationLevel_NOTIFICATION_LEVEL_MENTIONS,
			updateResp.Msg.GetSettings().GetNotificationLevel())
	})
}

func (s *ChatServerTestSuite) TestLive_DeliveryReceipt() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc, chatServer := s.setupLiveTest(t, dep)

		profileID := security.ClaimsFromContext(ctx).ContactID

		roomID := s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:      "Receipt Test Room",
				IsPrivate: false,
			}))

		// Send a message to get an event ID
		msgReq := connect.NewRequest(&chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{
				{
					RoomId: roomID,
					Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{
						Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "receipt test"}},
					},
				},
			},
		})

		msgResp, err := chatServer.SendEvent(ctx, msgReq)
		require.NoError(t, err)
		eventID := msgResp.Msg.GetAck()[0].GetEventId()[0]

		// Send delivery receipt via Live
		liveReq := connect.NewRequest(&chatv1.LiveRequest{
			ClientStates: []*chatv1.ClientCommand{
				{
					State: &chatv1.ClientCommand_Receipt{
						Receipt: &chatv1.ReceiptEvent{
							RoomId:  roomID,
							EventId: []string{eventID},
						},
					},
				},
			},
		})

		resp, err := chatServer.Live(ctx, liveReq)
		require.NoError(t, err)
		s.NotNil(resp)
	})
}

func (s *ChatServerTestSuite) TestLive_Presence() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc, chatServer := s.setupLiveTest(t, dep)

		profileID := security.ClaimsFromContext(ctx).ContactID

		// Create a room so the service is fully initialized
		_ = s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:      "Presence Test Room",
				IsPrivate: false,
			}))

		liveReq := connect.NewRequest(&chatv1.LiveRequest{
			ClientStates: []*chatv1.ClientCommand{
				{
					State: &chatv1.ClientCommand_Presence{
						Presence: &chatv1.PresenceEvent{
							Status:    chatv1.PresenceStatus_PRESENCE_STATUS_ONLINE,
							StatusMsg: "Available",
						},
					},
				},
			},
		})

		resp, err := chatServer.Live(ctx, liveReq)
		require.NoError(t, err)
		require.NotNil(t, resp)
	})
}

func (s *ChatServerTestSuite) TestLive_RoomEvent() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc, chatServer := s.setupLiveTest(t, dep)

		profileID := security.ClaimsFromContext(ctx).ContactID

		roomID := s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:      "Live RoomEvent Test",
				IsPrivate: false,
			}))

		// Send a room event via Live
		liveReq := connect.NewRequest(&chatv1.LiveRequest{
			ClientStates: []*chatv1.ClientCommand{
				{
					State: &chatv1.ClientCommand_Event{
						Event: &chatv1.RoomEvent{
							RoomId: roomID,
							Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
							Payload: &chatv1.Payload{
								Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "live event message"}},
							},
						},
					},
				},
			},
		})

		resp, err := chatServer.Live(ctx, liveReq)
		require.NoError(t, err)
		s.NotNil(resp)
	})
}

func (s *ChatServerTestSuite) TestLive_NilClientState() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, _, chatServer := s.setupLiveTest(t, dep)

		// Send a nil client state in the list - should result in partial failure
		liveReq := connect.NewRequest(&chatv1.LiveRequest{
			ClientStates: []*chatv1.ClientCommand{
				nil,
			},
		})

		// All states failed so this returns an error
		_, err := chatServer.Live(ctx, liveReq)
		require.Error(t, err)
	})
}

func (s *ChatServerTestSuite) TestLive_TooManyClientStates() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, _, chatServer := s.setupLiveTest(t, dep)

		// Create more than MaxBatchSize (50) client states
		states := make([]*chatv1.ClientCommand, 51)
		for i := range states {
			states[i] = &chatv1.ClientCommand{
				State: &chatv1.ClientCommand_Presence{
					Presence: &chatv1.PresenceEvent{
						Status: chatv1.PresenceStatus_PRESENCE_STATUS_ONLINE,
					},
				},
			}
		}

		liveReq := connect.NewRequest(&chatv1.LiveRequest{
			ClientStates: states,
		})

		_, err := chatServer.Live(ctx, liveReq)
		require.Error(t, err)
	})
}

func (s *ChatServerTestSuite) TestListProposals() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		// Create a room that requires approval
		roomID := s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:             "Proposal Room",
				IsPrivate:        false,
				RequiresApproval: true,
			}))

		// Attempt to update the room — this should create a proposal instead
		// of directly updating, and return ErrProposalRequired.
		updateReq := connect.NewRequest(&chatv1.UpdateRoomRequest{
			RoomId: roomID,
			Name:   "Proposed Name Change",
		})

		_, updateErr := chatServer.UpdateRoom(ctx, updateReq)
		require.Error(t, updateErr, "UpdateRoom on a RequiresApproval room should return an error")
		s.Equal(connect.CodeFailedPrecondition, connect.CodeOf(updateErr))

		// List proposals — there should be at least one pending proposal
		listReq := connect.NewRequest(&chatv1.ListProposalsRequest{
			RoomId: roomID,
		})

		listResp, err := chatServer.ListProposals(ctx, listReq)
		require.NoError(t, err)
		s.GreaterOrEqual(len(listResp.Msg.GetProposals()), 1)

		// Verify the proposal has the expected fields
		proposal := listResp.Msg.GetProposals()[0]
		s.Equal(roomID, proposal.GetRoomId())
		s.NotEmpty(proposal.GetId())
		s.Equal(profileID, proposal.GetRequestedBy())
		s.Equal(chatv1.ProposalState_PROPOSAL_STATE_PENDING, proposal.GetState())
	})
}

func (s *ChatServerTestSuite) TestListProposals_InvalidRoomID() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		listReq := connect.NewRequest(&chatv1.ListProposalsRequest{
			RoomId: "",
		})

		_, err := chatServer.ListProposals(ctx, listReq)
		require.Error(t, err)
		s.Equal(connect.CodeInvalidArgument, connect.CodeOf(err))
	})
}

func (s *ChatServerTestSuite) TestSubmitProposal_Approve() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		// Create a room that requires approval
		roomID := s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:             "Approve Proposal Room",
				IsPrivate:        false,
				RequiresApproval: true,
			}))

		// Trigger a proposal via UpdateRoom
		updateReq := connect.NewRequest(&chatv1.UpdateRoomRequest{
			RoomId: roomID,
			Name:   "Approved Name",
		})

		_, updateErr := chatServer.UpdateRoom(ctx, updateReq)
		require.Error(t, updateErr)
		s.Equal(connect.CodeFailedPrecondition, connect.CodeOf(updateErr))

		// Get the proposal ID from ListProposals
		listReq := connect.NewRequest(&chatv1.ListProposalsRequest{
			RoomId: roomID,
		})

		listResp, err := chatServer.ListProposals(ctx, listReq)
		require.NoError(t, err)
		require.GreaterOrEqual(t, len(listResp.Msg.GetProposals()), 1)

		proposalID := listResp.Msg.GetProposals()[0].GetId()

		// Approve the proposal
		submitReq := connect.NewRequest(&chatv1.SubmitProposalRequest{
			RoomId:     roomID,
			ProposalId: proposalID,
			Action:     chatv1.ProposalAction_PROPOSAL_ACTION_APPROVE,
		})

		submitResp, err := chatServer.SubmitProposal(ctx, submitReq)
		require.NoError(t, err)
		s.NotNil(submitResp)
		// Successful approval returns no error detail
		s.Nil(submitResp.Msg.GetError())
	})
}

func (s *ChatServerTestSuite) TestSubmitProposal_Reject() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		// Create a room that requires approval
		roomID := s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:             "Reject Proposal Room",
				IsPrivate:        false,
				RequiresApproval: true,
			}))

		// Trigger a proposal via UpdateRoom
		updateReq := connect.NewRequest(&chatv1.UpdateRoomRequest{
			RoomId: roomID,
			Name:   "Rejected Name",
		})

		_, updateErr := chatServer.UpdateRoom(ctx, updateReq)
		require.Error(t, updateErr)
		s.Equal(connect.CodeFailedPrecondition, connect.CodeOf(updateErr))

		// Get the proposal ID from ListProposals
		listReq := connect.NewRequest(&chatv1.ListProposalsRequest{
			RoomId: roomID,
		})

		listResp, err := chatServer.ListProposals(ctx, listReq)
		require.NoError(t, err)
		require.GreaterOrEqual(t, len(listResp.Msg.GetProposals()), 1)

		proposalID := listResp.Msg.GetProposals()[0].GetId()

		// Reject the proposal with a reason
		submitReq := connect.NewRequest(&chatv1.SubmitProposalRequest{
			RoomId:     roomID,
			ProposalId: proposalID,
			Action:     chatv1.ProposalAction_PROPOSAL_ACTION_REJECT,
			Reason:     proto.String("Not appropriate at this time"),
		})

		submitResp, err := chatServer.SubmitProposal(ctx, submitReq)
		require.NoError(t, err)
		s.NotNil(submitResp)
		s.Nil(submitResp.Msg.GetError())
	})
}

func (s *ChatServerTestSuite) TestSubmitProposal_InvalidArgs() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		chatServer := handlers.NewChatServer(ctx, svc, nil, nil, s.AuthzMiddleware)

		profileID := util.IDString()
		ctx = s.WithAuthClaims(ctx, testTenantID, testPartitionID, profileID)

		// Empty room_id
		_, err := chatServer.SubmitProposal(ctx, connect.NewRequest(&chatv1.SubmitProposalRequest{
			RoomId:     "",
			ProposalId: util.IDString(),
			Action:     chatv1.ProposalAction_PROPOSAL_ACTION_APPROVE,
		}))
		require.Error(t, err)
		s.Equal(connect.CodeInvalidArgument, connect.CodeOf(err))

		// Empty proposal_id
		_, err = chatServer.SubmitProposal(ctx, connect.NewRequest(&chatv1.SubmitProposalRequest{
			RoomId:     util.IDString(),
			ProposalId: "",
			Action:     chatv1.ProposalAction_PROPOSAL_ACTION_APPROVE,
		}))
		require.Error(t, err)
		s.Equal(connect.CodeInvalidArgument, connect.CodeOf(err))

		// Unspecified action
		_, err = chatServer.SubmitProposal(ctx, connect.NewRequest(&chatv1.SubmitProposalRequest{
			RoomId:     util.IDString(),
			ProposalId: util.IDString(),
			Action:     chatv1.ProposalAction_PROPOSAL_ACTION_UNSPECIFIED,
		}))
		require.Error(t, err)
		s.Equal(connect.CodeInvalidArgument, connect.CodeOf(err))
	})
}

// TestLive_MixedValidAndInvalid requires a real service because it sends
// a valid typing command that reaches ConnectBusiness.
func (s *ChatServerTestSuite) TestLive_MixedValidAndInvalid() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc, chatServer := s.setupLiveTest(t, dep)

		profileID := security.ClaimsFromContext(ctx).ContactID

		roomID := s.createRoomAndWait(ctx, t, svc, chatServer, profileID,
			connect.NewRequest(&chatv1.CreateRoomRequest{
				Name:      "Mixed Live Test Room",
				IsPrivate: false,
			}))

		// One valid typing + one invalid nil receipt = partial failure (returns response with error detail, not error)
		liveReq := connect.NewRequest(&chatv1.LiveRequest{
			ClientStates: []*chatv1.ClientCommand{
				{
					State: &chatv1.ClientCommand_Typing{
						Typing: &chatv1.TypingEvent{
							RoomId: roomID,
							Typing: true,
						},
					},
				},
				{
					State: &chatv1.ClientCommand_Receipt{
						Receipt: nil,
					},
				},
			},
		})

		resp, err := chatServer.Live(ctx, liveReq)
		// Partial failure: one succeeded, one failed -- returns response with error detail
		require.NoError(t, err)
		s.NotNil(resp.Msg.GetError())
	})
}
