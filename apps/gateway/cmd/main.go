package main

import (
	"context"
	_ "embed"
	"net/http"
	"time"

	"buf.build/gen/go/antinvestor/chat/connectrpc/go/chat/v1/chatv1connect"
	"buf.build/gen/go/antinvestor/device/connectrpc/go/device/v1/devicev1connect"
	"connectrpc.com/connect"
	"connectrpc.com/otelconnect"
	"github.com/antinvestor/common"
	"github.com/antinvestor/common/connection"
	gtwconfig "github.com/antinvestor/service-chat/apps/gateway/config"
	"github.com/antinvestor/service-chat/apps/gateway/service/business"
	"github.com/antinvestor/service-chat/apps/gateway/service/handlers"
	"github.com/antinvestor/service-chat/apps/gateway/service/queues"
	"github.com/pitabwire/frame"
	"github.com/pitabwire/frame/cache"
	"github.com/pitabwire/frame/cache/jetstreamkv"
	"github.com/pitabwire/frame/cache/valkey"
	"github.com/pitabwire/frame/config"
	"github.com/pitabwire/frame/data"
	securityconnect "github.com/pitabwire/frame/security/interceptors/connect"
	"github.com/pitabwire/util"
)

//go:embed spec/chat.openapi.yaml
var chatAPISpecFile []byte

const gracefulShutdownTimeout = 30 * time.Second

func main() {
	ctx := context.Background()

	// Initialize configuration
	cfg, err := config.LoadWithOIDC[gtwconfig.GatewayConfig](ctx)
	if err != nil {
		util.Log(ctx).With("err", err).Error("could not process configs")
		return
	}

	// Validate configuration (fail-fast on invalid config)
	if err = cfg.Validate(); err != nil {
		util.Log(ctx).With("err", err).Error("invalid configuration")
		return
	}

	if cfg.Name() == "" {
		cfg.ServiceName = "service_chat_gateway"
	}

	rawCache, err := setupCache(ctx, cfg)
	if err != nil {
		util.Log(ctx).WithError(err).Fatal("could not setup cache")
	}

	// Create service
	ctx, svc := frame.NewServiceWithContext(ctx, frame.WithConfig(&cfg),
		frame.WithCache(cfg.CacheName, rawCache))
	defer svc.Stop(ctx)
	log := svc.Log(ctx)

	qManager := svc.QueueManager()

	// Setup chat service client
	chatServiceClient, err := setupChatServiceClient(ctx, cfg)
	if err != nil {
		log.WithError(err).Fatal("main -- Could not setup chat service client")
	}

	// Setup device service client for delivery tracking
	deviceClient, err := setupDeviceClient(ctx, cfg)
	if err != nil {
		log.WithError(err).Fatal("main -- Could not setup device service client")
	}

	// Setup connection manager with clients
	// Note: Outbound message delivery is handled by the default service via direct publish
	// The gateway focuses on inbound request processing and real-time features
	connectionManager := business.NewConnectionManager(
		ctx,
		chatServiceClient,
		deviceClient,
		cfg.MaxConnectionsPerDevice,
		cfg.ConnectionTimeoutSec,
		cfg.HeartbeatIntervalSec,
	)
	// Graceful shutdown: drain connections and stop background tasks.
	// Defers run LIFO: connectionManager shuts down before svc.Stop.
	defer func() {
		drainCtx, drainCancel := context.WithTimeout(context.Background(), gracefulShutdownTimeout)
		defer drainCancel()
		connectionManager.DrainConnections(drainCtx)
		if shutdownErr := connectionManager.Shutdown(drainCtx); shutdownErr != nil {
			util.Log(drainCtx).WithError(shutdownErr).Error("connection manager shutdown error")
		}
	}()

	offlineDeliveryQueuePublisher := frame.WithRegisterPublisher(
		cfg.QueueOfflineEventDeliveryName,
		cfg.QueueOfflineEventDeliveryURI,
	)

	gatewayEventQueueSubscriber := frame.WithRegisterSubscriber(
		cfg.QueueGatewayEventDeliveryName, cfg.QueueGatewayEventDeliveryURI,
		queues.NewGatewayEventsQueueHandler(&cfg, qManager, connectionManager),
	)

	// Setup gateway server
	gatewayHandler := setupGatewayServer(ctx, svc, chatServiceClient, connectionManager)

	// Initialize the service with all options
	svc.Init(ctx, gatewayEventQueueSubscriber, offlineDeliveryQueuePublisher, frame.WithHTTPHandler(gatewayHandler))

	// Start the service
	err = svc.Run(ctx, "")
	if err != nil {
		log.WithError(err).Fatal("could not run Server")
	}
}

func setupCache(_ context.Context, cfg gtwconfig.GatewayConfig) (cache.RawCache, error) {
	cacheDSN := data.DSN(cfg.CacheURI)

	cacheOptions := []cache.Option{
		cache.WithDSN(cacheDSN),
	}

	if cfg.CacheCredentialsFile != "" {
		cacheOptions = append(cacheOptions, cache.WithCredsFile(cfg.CacheCredentialsFile))
	}

	switch {
	case cacheDSN.IsNats():
		// Setup cache for connection metadata
		return jetstreamkv.New(cacheOptions...)
	case cacheDSN.IsRedis():
		return valkey.New(cacheOptions...)
	default:
		return cache.NewInMemoryCache(), nil
	}
}

// setupChatServiceClient creates and configures the chat service client.
func setupChatServiceClient(
	ctx context.Context,
	cfg gtwconfig.GatewayConfig,
) (chatv1connect.ChatServiceClient, error) {
	return connection.NewServiceClient(ctx, &cfg, common.ServiceTarget{
		Endpoint:              cfg.ChatServiceURI,
		WorkloadAPITargetPath: cfg.ChatServiceWorkloadAPITargetPath,
		Audiences:             []string{"service_chat_drone"},
	}, chatv1connect.NewChatServiceClient)
}

// setupDeviceClient creates and configures the device service client.
func setupDeviceClient(
	ctx context.Context,
	cfg gtwconfig.GatewayConfig,
) (devicev1connect.DeviceServiceClient, error) {
	return connection.NewServiceClient(ctx, &cfg, common.ServiceTarget{
		Endpoint:              cfg.DeviceServiceURI,
		WorkloadAPITargetPath: cfg.DeviceServiceWorkloadAPITargetPath,
		Audiences:             []string{"service_device"},
	}, devicev1connect.NewDeviceServiceClient)
}

// setupGatewayServer initializes and configures the gateway server.
func setupGatewayServer(
	ctx context.Context,
	svc *frame.Service,
	chatServiceClient chatv1connect.ChatServiceClient,
	connectionManager business.ConnectionManager,
) http.Handler {
	securityMan := svc.SecurityManager()

	otelInterceptor, err := otelconnect.NewInterceptor()
	if err != nil {
		util.Log(ctx).WithError(err).Fatal("could not configure open telemetry")
	}

	validateInterceptor := securityconnect.NewValidationInterceptor()

	authInterceptor := securityconnect.NewAuthInterceptor(securityMan.GetAuthenticator(ctx))

	gatewayServer := handlers.NewGatewayServer(svc, chatServiceClient, connectionManager)

	// Register as GatewayServiceHandler - handles the Connect stream for real-time communication
	_, serverHandler := chatv1connect.NewGatewayServiceHandler(
		gatewayServer, connect.WithInterceptors(authInterceptor, otelInterceptor, validateInterceptor),
	)

	mux := http.NewServeMux()
	mux.Handle("/", serverHandler)
	mux.Handle("/openapi.yaml", common.NewOpenAPIHandler(chatAPISpecFile, nil))

	return mux
}
