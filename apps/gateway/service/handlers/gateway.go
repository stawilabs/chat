package handlers

import (
	"context"

	"buf.build/gen/go/stawi/chat/connectrpc/go/v2/chat/v1/chatv1connect"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect/v2"
	"github.com/pitabwire/frame/v3"
	"github.com/pitabwire/frame/v3/security"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/stawilabs/chat/apps/gateway/service/business"
)

// GatewayServer handles the gateway-specific chat service operations.
// It focuses on the Connect functionality for real-time communication with edge devices.
type GatewayServer struct {
	svc        *frame.Service
	chatClient chatv1connect.ChatServiceClient
	cm         business.ConnectionManager

	chatv1connect.UnimplementedGatewayServiceHandler
}

// NewGatewayServer creates a new gateway server instance.
func NewGatewayServer(
	service *frame.Service,
	chatServiceClient chatv1connect.ChatServiceClient,
	connectionManager business.ConnectionManager,
) *GatewayServer {
	return &GatewayServer{
		svc:        service,
		chatClient: chatServiceClient,
		cm:         connectionManager,
	}
}

// Stream handles bidirectional streaming connections from edge devices.
// This is the primary method for maintaining real-time connections.
func (gs *GatewayServer) Stream(
	ctx context.Context,
	stream chatv1connect.GatewayServiceStreamServerStream,
) error {
	// Extract profile ID from context
	authClaims := security.ClaimsFromContext(ctx)
	if authClaims == nil {
		return connect.NewError(
			connect.CodeUnauthenticated,
			status.Error(codes.Unauthenticated, "request needs to be authenticated").Error(),
		)
	}

	profileID, _ := authClaims.GetSubject()
	deviceID := authClaims.GetDeviceID()
	if deviceID == "" {
		deviceID = "default"
	}

	gs.svc.Log(ctx).WithFields(map[string]any{
		"profile_id": profileID,
		"device_id":  deviceID,
	}).Debug("new device connection request")

	// Create stream wrapper
	streamWrapper := &deviceStreamImpl{stream: stream}

	// Handle the connection through the connection manager
	return gs.cm.HandleConnection(ctx, profileID, deviceID, streamWrapper)
}

// deviceStreamImpl wraps the gateway stream to implement business.DeviceStream.
type deviceStreamImpl struct {
	stream chatv1connect.GatewayServiceStreamServerStream
}

func (w *deviceStreamImpl) Receive() (*chatv1.StreamRequest, error) {
	return w.stream.Receive()
}

func (w *deviceStreamImpl) Send(event *chatv1.StreamResponse) error {
	return w.stream.Send(event)
}
