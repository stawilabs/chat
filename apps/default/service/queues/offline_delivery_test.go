package queues_test

import (
	"context"
	"errors"
	"fmt"
	"sync/atomic"
	"testing"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	eventsv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/events/v1"
	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	devicev1 "buf.build/gen/go/antinvestor/device/protocolbuffers/go/device/v1"
	"connectrpc.com/connect"
	"github.com/antinvestor/service-chat/apps/default/config"
	"github.com/antinvestor/service-chat/apps/default/service/queues"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	"google.golang.org/protobuf/proto"
)

// testDeviceClient is a stub implementation of devicev1connect.DeviceServiceClient.
// The Notify method delegates to NotifyFunc if set; all other methods return unimplemented errors.
type testDeviceClient struct {
	NotifyFunc    func(context.Context, *connect.Request[devicev1.NotifyRequest]) (*connect.Response[devicev1.NotifyResponse], error)
	notifyCounter atomic.Uint64
}

func (c *testDeviceClient) unimplemented(method string) error {
	return connect.NewError(connect.CodeUnimplemented, fmt.Errorf("%s not implemented", method))
}

func (c *testDeviceClient) GetById(
	context.Context,
	*connect.Request[devicev1.GetByIdRequest],
) (*connect.Response[devicev1.GetByIdResponse], error) {
	return nil, c.unimplemented("GetById")
}

func (c *testDeviceClient) GetBySessionId(
	context.Context,
	*connect.Request[devicev1.GetBySessionIdRequest],
) (*connect.Response[devicev1.GetBySessionIdResponse], error) {
	return nil, c.unimplemented("GetBySessionId")
}

func (c *testDeviceClient) Search(
	context.Context,
	*connect.Request[devicev1.SearchRequest],
) (*connect.ServerStreamForClient[devicev1.SearchResponse], error) {
	return nil, errors.New("no devices found")
}

func (c *testDeviceClient) Create(
	context.Context,
	*connect.Request[devicev1.CreateRequest],
) (*connect.Response[devicev1.CreateResponse], error) {
	return nil, c.unimplemented("Create")
}

func (c *testDeviceClient) Update(
	context.Context,
	*connect.Request[devicev1.UpdateRequest],
) (*connect.Response[devicev1.UpdateResponse], error) {
	return nil, c.unimplemented("Update")
}

func (c *testDeviceClient) Link(
	context.Context,
	*connect.Request[devicev1.LinkRequest],
) (*connect.Response[devicev1.LinkResponse], error) {
	return nil, c.unimplemented("Link")
}

func (c *testDeviceClient) Remove(
	context.Context,
	*connect.Request[devicev1.RemoveRequest],
) (*connect.Response[devicev1.RemoveResponse], error) {
	return nil, c.unimplemented("Remove")
}

func (c *testDeviceClient) Log(
	context.Context,
	*connect.Request[devicev1.LogRequest],
) (*connect.Response[devicev1.LogResponse], error) {
	return nil, c.unimplemented("Log")
}

func (c *testDeviceClient) ListLogs(
	context.Context,
	*connect.Request[devicev1.ListLogsRequest],
) (*connect.ServerStreamForClient[devicev1.ListLogsResponse], error) {
	return nil, c.unimplemented("ListLogs")
}

func (c *testDeviceClient) AddKey(
	context.Context,
	*connect.Request[devicev1.AddKeyRequest],
) (*connect.Response[devicev1.AddKeyResponse], error) {
	return nil, c.unimplemented("AddKey")
}

func (c *testDeviceClient) RemoveKey(
	context.Context,
	*connect.Request[devicev1.RemoveKeyRequest],
) (*connect.Response[devicev1.RemoveKeyResponse], error) {
	return nil, c.unimplemented("RemoveKey")
}

func (c *testDeviceClient) SearchKey(
	context.Context,
	*connect.Request[devicev1.SearchKeyRequest],
) (*connect.Response[devicev1.SearchKeyResponse], error) {
	return nil, c.unimplemented("SearchKey")
}

func (c *testDeviceClient) RegisterKey(
	context.Context,
	*connect.Request[devicev1.RegisterKeyRequest],
) (*connect.Response[devicev1.RegisterKeyResponse], error) {
	return nil, c.unimplemented("RegisterKey")
}

func (c *testDeviceClient) DeRegisterKey(
	context.Context,
	*connect.Request[devicev1.DeRegisterKeyRequest],
) (*connect.Response[devicev1.DeRegisterKeyResponse], error) {
	return nil, c.unimplemented("DeRegisterKey")
}

func (c *testDeviceClient) GetTurnCredentials(
	context.Context,
	*connect.Request[devicev1.GetTurnCredentialsRequest],
) (*connect.Response[devicev1.GetTurnCredentialsResponse], error) {
	return nil, c.unimplemented("GetTurnCredentials")
}

func (c *testDeviceClient) Notify(
	ctx context.Context,
	req *connect.Request[devicev1.NotifyRequest],
) (*connect.Response[devicev1.NotifyResponse], error) {
	c.notifyCounter.Add(1)
	if c.NotifyFunc != nil {
		return c.NotifyFunc(ctx, req)
	}
	return nil, c.unimplemented("Notify")
}

func (c *testDeviceClient) UpdatePresence(
	context.Context,
	*connect.Request[devicev1.UpdatePresenceRequest],
) (*connect.Response[devicev1.UpdatePresenceResponse], error) {
	return nil, c.unimplemented("UpdatePresence")
}

type OfflineDeliveryQueueHandlerTestSuite struct {
	suite.Suite
}

func TestOfflineDeliveryQueueHandlerTestSuite(t *testing.T) {
	suite.Run(t, new(OfflineDeliveryQueueHandlerTestSuite))
}

func (s *OfflineDeliveryQueueHandlerTestSuite) createConfig() *config.ChatConfig {
	return &config.ChatConfig{
		QueueOfflineEventDeliveryName: "offline.event.delivery",
	}
}

func (s *OfflineDeliveryQueueHandlerTestSuite) createDeliveryWithPayload(
	profileID, deviceID string, payload *chatv1.Payload,
) []byte {
	delivery := &eventsv1.Delivery{
		DeviceId: deviceID,
		Event: &eventsv1.Link{
			EventId: util.IDString(),
			RoomId:  util.IDString(),
		},
		Destination: &eventsv1.Subscription{
			SubscriptionId: util.IDString(),
			ContactLink: &commonv1.ContactLink{
				ProfileId: profileID,
				ContactId: util.IDString(),
			},
		},
		Payload: payload,
	}

	data, err := proto.Marshal(delivery)
	s.Require().NoError(err)
	return data
}

func (s *OfflineDeliveryQueueHandlerTestSuite) TestHandle_TextMessage() {
	t := s.T()
	ctx := context.Background()

	cfg := s.createConfig()
	profileID := util.IDString()
	deviceID := util.IDString()

	// Create stub device client
	deviceCli := &testDeviceClient{
		NotifyFunc: func(_ context.Context, req *connect.Request[devicev1.NotifyRequest]) (*connect.Response[devicev1.NotifyResponse], error) {
			// Verify notification content
			require.Equal(t, deviceID, req.Msg.GetDeviceId())
			require.Len(t, req.Msg.GetNotifications(), 1)
			require.Equal(t, "Hello, World!", req.Msg.GetNotifications()[0].GetBody())
			return connect.NewResponse(&devicev1.NotifyResponse{}), nil
		},
	}

	handler := queues.NewOfflineDeliveryQueueHandler(cfg, nil, deviceCli, nil)

	payload := &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_TEXT,
		Data: &chatv1.Payload_Text{
			Text: &chatv1.TextContent{Body: "Hello, World!"},
		},
	}
	data := s.createDeliveryWithPayload(profileID, deviceID, payload)

	err := handler.Handle(ctx, nil, data)
	require.NoError(t, err)
}

func (s *OfflineDeliveryQueueHandlerTestSuite) TestHandle_AttachmentMessage() {
	t := s.T()
	ctx := context.Background()

	cfg := s.createConfig()
	profileID := util.IDString()
	deviceID := util.IDString()

	deviceCli := &testDeviceClient{
		NotifyFunc: func(_ context.Context, req *connect.Request[devicev1.NotifyRequest]) (*connect.Response[devicev1.NotifyResponse], error) {
			// Attachment with caption should use caption text
			require.Equal(t, "Check out this photo", req.Msg.GetNotifications()[0].GetBody())
			return connect.NewResponse(&devicev1.NotifyResponse{}), nil
		},
	}

	handler := queues.NewOfflineDeliveryQueueHandler(cfg, nil, deviceCli, nil)

	payload := &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_ATTACHMENT,
		Data: &chatv1.Payload_Attachment{
			Attachment: &chatv1.AttachmentContent{
				AttachmentId: util.IDString(),
				Uri:          "https://example.com/photo.jpg",
				MimeType:     "image/jpeg",
				Caption:      &chatv1.TextContent{Body: "Check out this photo"},
			},
		},
	}
	data := s.createDeliveryWithPayload(profileID, deviceID, payload)

	err := handler.Handle(ctx, nil, data)
	require.NoError(t, err)
}

func (s *OfflineDeliveryQueueHandlerTestSuite) TestHandle_AttachmentWithoutCaption() {
	t := s.T()
	ctx := context.Background()

	cfg := s.createConfig()
	profileID := util.IDString()
	deviceID := util.IDString()

	deviceCli := &testDeviceClient{
		NotifyFunc: func(_ context.Context, req *connect.Request[devicev1.NotifyRequest]) (*connect.Response[devicev1.NotifyResponse], error) {
			// Attachment without caption should have generic message
			require.Equal(t, "Sent an attachment", req.Msg.GetNotifications()[0].GetBody())
			return connect.NewResponse(&devicev1.NotifyResponse{}), nil
		},
	}

	handler := queues.NewOfflineDeliveryQueueHandler(cfg, nil, deviceCli, nil)

	payload := &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_ATTACHMENT,
		Data: &chatv1.Payload_Attachment{
			Attachment: &chatv1.AttachmentContent{
				AttachmentId: util.IDString(),
				Uri:          "https://example.com/file.pdf",
				MimeType:     "application/pdf",
			},
		},
	}
	data := s.createDeliveryWithPayload(profileID, deviceID, payload)

	err := handler.Handle(ctx, nil, data)
	require.NoError(t, err)
}

func (s *OfflineDeliveryQueueHandlerTestSuite) TestHandle_ReactionMessage() {
	t := s.T()
	ctx := context.Background()

	cfg := s.createConfig()
	profileID := util.IDString()
	deviceID := util.IDString()

	deviceCli := &testDeviceClient{
		NotifyFunc: func(_ context.Context, req *connect.Request[devicev1.NotifyRequest]) (*connect.Response[devicev1.NotifyResponse], error) {
			require.Equal(t, "Reacted with 👍", req.Msg.GetNotifications()[0].GetBody())
			return connect.NewResponse(&devicev1.NotifyResponse{}), nil
		},
	}

	handler := queues.NewOfflineDeliveryQueueHandler(cfg, nil, deviceCli, nil)

	payload := &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_REACTION,
		Data: &chatv1.Payload_Reaction{
			Reaction: &chatv1.ReactionContent{
				TargetEventId: util.IDString(),
				Reaction:      "👍",
				Add:           true,
			},
		},
	}
	data := s.createDeliveryWithPayload(profileID, deviceID, payload)

	err := handler.Handle(ctx, nil, data)
	require.NoError(t, err)
}

func (s *OfflineDeliveryQueueHandlerTestSuite) TestHandle_CallMessage() {
	t := s.T()
	ctx := context.Background()

	cfg := s.createConfig()
	profileID := util.IDString()
	deviceID := util.IDString()

	deviceCli := &testDeviceClient{
		NotifyFunc: func(_ context.Context, req *connect.Request[devicev1.NotifyRequest]) (*connect.Response[devicev1.NotifyResponse], error) {
			require.Equal(t, "Started a call", req.Msg.GetNotifications()[0].GetBody())
			return connect.NewResponse(&devicev1.NotifyResponse{}), nil
		},
	}

	handler := queues.NewOfflineDeliveryQueueHandler(cfg, nil, deviceCli, nil)

	payload := &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_CALL,
		Data: &chatv1.Payload_Call{
			Call: &chatv1.CallContent{
				CallId: util.IDString(),
				Type:   chatv1.CallContent_CALL_TYPE_UNSPECIFIED,
			},
		},
	}
	data := s.createDeliveryWithPayload(profileID, deviceID, payload)

	err := handler.Handle(ctx, nil, data)
	require.NoError(t, err)
}

func (s *OfflineDeliveryQueueHandlerTestSuite) TestHandle_EncryptedMessage() {
	t := s.T()
	ctx := context.Background()

	cfg := s.createConfig()
	profileID := util.IDString()
	deviceID := util.IDString()

	deviceCli := &testDeviceClient{
		NotifyFunc: func(_ context.Context, req *connect.Request[devicev1.NotifyRequest]) (*connect.Response[devicev1.NotifyResponse], error) {
			require.Equal(t, "Sent an encrypted message", req.Msg.GetNotifications()[0].GetBody())
			return connect.NewResponse(&devicev1.NotifyResponse{}), nil
		},
	}

	handler := queues.NewOfflineDeliveryQueueHandler(cfg, nil, deviceCli, nil)

	payload := &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_ENCRYPTED,
		Data: &chatv1.Payload_Encrypted{
			Encrypted: &chatv1.EncryptedContent{
				Algorithm:  "AES-256-GCM",
				Ciphertext: []byte("encrypted data"),
			},
		},
	}
	data := s.createDeliveryWithPayload(profileID, deviceID, payload)

	err := handler.Handle(ctx, nil, data)
	require.NoError(t, err)
}

func (s *OfflineDeliveryQueueHandlerTestSuite) TestHandle_ModerationMessage() {
	t := s.T()
	ctx := context.Background()

	cfg := s.createConfig()
	profileID := util.IDString()
	deviceID := util.IDString()

	deviceCli := &testDeviceClient{
		NotifyFunc: func(_ context.Context, req *connect.Request[devicev1.NotifyRequest]) (*connect.Response[devicev1.NotifyResponse], error) {
			require.Equal(t,
				"This message was removed for violating community guidelines",
				req.Msg.GetNotifications()[0].GetBody())
			return connect.NewResponse(&devicev1.NotifyResponse{}), nil
		},
	}

	handler := queues.NewOfflineDeliveryQueueHandler(cfg, nil, deviceCli, nil)

	payload := &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_MODERATION,
		Data: &chatv1.Payload_Moderation{
			Moderation: &chatv1.ModerationContent{
				Body: "This message was removed for violating community guidelines",
			},
		},
	}
	data := s.createDeliveryWithPayload(profileID, deviceID, payload)

	err := handler.Handle(ctx, nil, data)
	require.NoError(t, err)
}

func (s *OfflineDeliveryQueueHandlerTestSuite) TestHandle_MotionMessage() {
	t := s.T()
	ctx := context.Background()

	cfg := s.createConfig()
	profileID := util.IDString()
	deviceID := util.IDString()

	deviceCli := &testDeviceClient{
		NotifyFunc: func(_ context.Context, req *connect.Request[devicev1.NotifyRequest]) (*connect.Response[devicev1.NotifyResponse], error) {
			require.Equal(t, "Created a motion", req.Msg.GetNotifications()[0].GetBody())
			return connect.NewResponse(&devicev1.NotifyResponse{}), nil
		},
	}

	handler := queues.NewOfflineDeliveryQueueHandler(cfg, nil, deviceCli, nil)

	payload := &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_MOTION,
		Data: &chatv1.Payload_Motion{
			Motion: &chatv1.MotionContent{
				Id:    util.IDString(),
				Title: "Approve budget",
			},
		},
	}
	data := s.createDeliveryWithPayload(profileID, deviceID, payload)

	err := handler.Handle(ctx, nil, data)
	require.NoError(t, err)
}

func (s *OfflineDeliveryQueueHandlerTestSuite) TestHandle_VoteMessage() {
	t := s.T()
	ctx := context.Background()

	cfg := s.createConfig()
	profileID := util.IDString()
	deviceID := util.IDString()

	deviceCli := &testDeviceClient{
		NotifyFunc: func(_ context.Context, req *connect.Request[devicev1.NotifyRequest]) (*connect.Response[devicev1.NotifyResponse], error) {
			require.Equal(t, "Voted", req.Msg.GetNotifications()[0].GetBody())
			return connect.NewResponse(&devicev1.NotifyResponse{}), nil
		},
	}

	handler := queues.NewOfflineDeliveryQueueHandler(cfg, nil, deviceCli, nil)

	payload := &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_VOTE,
		Data: &chatv1.Payload_Vote{
			Vote: &chatv1.VoteCast{
				MotionId: util.IDString(),
			},
		},
	}
	data := s.createDeliveryWithPayload(profileID, deviceID, payload)

	err := handler.Handle(ctx, nil, data)
	require.NoError(t, err)
}

func (s *OfflineDeliveryQueueHandlerTestSuite) TestHandle_NotificationServiceFailure() {
	// Skip: This test requires a queue manager mock for retry functionality.
	// When qMan is nil, the handler panics on notification failure because
	// it tries to retry/dead-letter. The test setup needs to provide a mock qMan.
	s.T().Skip("requires queue manager mock for retry functionality")
}

func (s *OfflineDeliveryQueueHandlerTestSuite) TestHandle_EmptyProfileID() {
	t := s.T()
	ctx := context.Background()

	cfg := s.createConfig()
	deviceID := util.IDString()

	deviceCli := &testDeviceClient{}
	// Notify should NOT be called when profile ID is empty

	handler := queues.NewOfflineDeliveryQueueHandler(cfg, nil, deviceCli, nil)

	// Create delivery with empty profile ID
	delivery := &eventsv1.Delivery{
		DeviceId: deviceID,
		Event: &eventsv1.Link{
			EventId: util.IDString(),
			RoomId:  util.IDString(),
		},
		Destination: &eventsv1.Subscription{
			SubscriptionId: util.IDString(),
			ContactLink: &commonv1.ContactLink{
				ProfileId: "", // Empty profile ID
				ContactId: util.IDString(),
			},
		},
		Payload: &chatv1.Payload{
			Type: chatv1.PayloadType_PAYLOAD_TYPE_TEXT,
			Data: &chatv1.Payload_Text{
				Text: &chatv1.TextContent{Body: "Test"},
			},
		},
	}
	data, marshalErr := proto.Marshal(delivery)
	require.NoError(t, marshalErr)

	err := handler.Handle(ctx, nil, data)
	// Should succeed but skip notification
	require.NoError(t, err)
	// Verify Notify was never called
	require.Equal(t, uint64(0), deviceCli.notifyCounter.Load())
}

func (s *OfflineDeliveryQueueHandlerTestSuite) TestHandle_MalformedPayload() {
	t := s.T()
	ctx := context.Background()

	cfg := s.createConfig()
	deviceCli := &testDeviceClient{}

	handler := queues.NewOfflineDeliveryQueueHandler(cfg, nil, deviceCli, nil)

	invalidPayload := []byte("not a valid protobuf")
	err := handler.Handle(ctx, nil, invalidPayload)

	// Malformed payload is a non-retryable error; handler logs and returns nil
	// (would send to DLQ if one were configured)
	require.NoError(t, err)
}

func (s *OfflineDeliveryQueueHandlerTestSuite) TestHandle_NilPayload() {
	t := s.T()
	ctx := context.Background()

	cfg := s.createConfig()
	profileID := util.IDString()
	deviceID := util.IDString()

	deviceCli := &testDeviceClient{
		NotifyFunc: func(_ context.Context, req *connect.Request[devicev1.NotifyRequest]) (*connect.Response[devicev1.NotifyResponse], error) {
			// With nil payload, body should be empty
			require.Empty(t, req.Msg.GetNotifications()[0].GetBody())
			return connect.NewResponse(&devicev1.NotifyResponse{}), nil
		},
	}

	handler := queues.NewOfflineDeliveryQueueHandler(cfg, nil, deviceCli, nil)

	// Create delivery with nil payload
	delivery := &eventsv1.Delivery{
		DeviceId: deviceID,
		Event: &eventsv1.Link{
			EventId: util.IDString(),
			RoomId:  util.IDString(),
		},
		Destination: &eventsv1.Subscription{
			SubscriptionId: util.IDString(),
			ContactLink: &commonv1.ContactLink{
				ProfileId: profileID,
				ContactId: util.IDString(),
			},
		},
		Payload: nil,
	}
	data, marshalErr := proto.Marshal(delivery)
	require.NoError(t, marshalErr)

	err := handler.Handle(ctx, nil, data)
	require.NoError(t, err)
}

func (s *OfflineDeliveryQueueHandlerTestSuite) TestHandle_UnspecifiedPayloadType() {
	t := s.T()
	ctx := context.Background()

	cfg := s.createConfig()
	profileID := util.IDString()
	deviceID := util.IDString()

	deviceCli := &testDeviceClient{
		NotifyFunc: func(_ context.Context, req *connect.Request[devicev1.NotifyRequest]) (*connect.Response[devicev1.NotifyResponse], error) {
			// Unspecified type should have empty body
			require.Empty(t, req.Msg.GetNotifications()[0].GetBody())
			return connect.NewResponse(&devicev1.NotifyResponse{}), nil
		},
	}

	handler := queues.NewOfflineDeliveryQueueHandler(cfg, nil, deviceCli, nil)

	payload := &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_UNSPECIFIED,
	}
	data := s.createDeliveryWithPayload(profileID, deviceID, payload)

	err := handler.Handle(ctx, nil, data)
	require.NoError(t, err)
}
