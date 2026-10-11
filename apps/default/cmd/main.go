package main

import (
	"context"
	_ "embed"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"buf.build/gen/go/antinvestor/device/connectrpc/go/device/v1/devicev1connect"
	"buf.build/gen/go/antinvestor/notification/connectrpc/go/notification/v1/notificationv1connect"
	"buf.build/gen/go/antinvestor/profile/connectrpc/go/profile/v1/profilev1connect"
	"buf.build/gen/go/stawi/chat/connectrpc/go/chat/v1/chatv1connect"
	chatpb "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/antinvestor/common/v2"
	"github.com/antinvestor/common/v2/connection"
	"github.com/antinvestor/common/v2/permissions"
	"github.com/antinvestor/common/v2/servicecatalog"
	"github.com/antinvestor/service-profile/client/accounts"
	"github.com/pitabwire/frame/v2"
	"github.com/pitabwire/frame/v2/config"
	"github.com/pitabwire/frame/v2/datastore"
	"github.com/pitabwire/frame/v2/datastore/pool"
	frevents "github.com/pitabwire/frame/v2/events"
	"github.com/pitabwire/frame/v2/queue"
	"github.com/pitabwire/frame/v2/security/authorizer"
	connectInterceptors "github.com/pitabwire/frame/v2/security/interceptors/connect"
	"github.com/pitabwire/frame/v2/workerpool"
	"github.com/pitabwire/util"

	aconfig "github.com/stawilabs/chat/apps/default/config"
	"github.com/stawilabs/chat/apps/default/service/authz"
	"github.com/stawilabs/chat/apps/default/service/business"
	"github.com/stawilabs/chat/apps/default/service/events"
	"github.com/stawilabs/chat/apps/default/service/handlers"
	"github.com/stawilabs/chat/apps/default/service/health"
	"github.com/stawilabs/chat/apps/default/service/queues"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/service/stawi"
)

//go:embed spec/chat.openapi.yaml
var chatAPISpecFile []byte

// runService initializes and starts the chat service with all dependencies.
func runService(ctx context.Context) error {
	// Initialize configuration
	cfg, err := config.LoadWithOIDC[aconfig.ChatConfig](ctx)
	if err != nil {
		util.Log(ctx).WithError(err).Error("could not process configs")
		return err
	}

	// Validate configuration (fail-fast on invalid config)
	if err = cfg.Validate(); err != nil {
		util.Log(ctx).WithError(err).Error("invalid configuration")
		return err
	}

	if cfg.Name() == "" {
		cfg.ServiceName = "service_chat"
	}

	// Create service
	ctx, svc := frame.NewServiceWithContext(
		ctx,
		frame.WithConfig(&cfg),
		frame.WithDatastore(),
	)
	defer svc.Stop(ctx)
	log := svc.Log(ctx)

	sm := svc.SecurityManager()

	// Get publisher for event handlers
	workMan := svc.WorkManager()
	eventsMan := svc.EventsManager()
	queueMan := svc.QueueManager()

	dbManager := svc.DatastoreManager()
	dbPool := dbManager.GetPool(ctx, datastore.DefaultPoolName)

	// Readiness reflects real DB connectivity, so a pod with a dead pool is
	// pulled from rotation instead of black-holing traffic.
	svc.AddHealthCheck(health.DBChecker{Pool: dbPool})

	// Migration mode runs SQL migrations (see handleDatabaseMigration) and
	// exits. Skip outbound service clients: they require a resolved OIDC
	// token endpoint and are unused by migrate.
	if handleDatabaseMigration(ctx, dbManager, cfg) {
		return nil
	}

	// Setup clients and services (runtime path only)
	deviceCli, err := setupDeviceClient(ctx, cfg)
	if err != nil {
		log.WithError(err).Fatal("main -- Could not setup device client")
	}

	notificationCli, err := setupNotificationClient(ctx, cfg)
	if err != nil {
		log.WithError(err).Fatal("main -- Could not setup notification client")
	}

	profileCli, err := setupProfileClient(ctx, cfg)
	if err != nil {
		log.WithError(err).Fatal("main -- Could not setup profile client")
	}

	// Setup Keto authorization service
	auth := sm.GetAuthorizer(ctx)
	authzMiddleware := authz.NewMiddleware(auth)

	stawiChain, stawiServer := setupStawi(ctx, &cfg, dbPool, workMan, queueMan, profileCli, authzMiddleware)
	connectHandler := setupConnectServer(ctx, svc, notificationCli, profileCli, authzMiddleware, stawiServer)
	dlp := queues.NewDeadLetterPublisher(&cfg, queueMan)
	deadLetterRepo := repository.NewDeadLetterRepository(ctx, dbPool, workMan)

	serviceOptions := []frame.Option{
		// Outbox relay: sole publisher draining room_outbox, run as a frame
		// background consumer so its lifecycle is owned by the service.
		outboxRelayOption(ctx, &cfg, dbPool, workMan, queueMan, eventsMan),
		frame.WithHTTPHandler(connectHandler),
		frame.WithPermissionRegistration(chatpb.File_chat_v1_chat_proto.Services().ByName("ChatService")),
		frame.WithRegisterPublisher(cfg.QueueDeadLetterName, cfg.QueueDeadLetterURI),
		frame.WithRegisterPublisher(cfg.QueueRoomEventPublishedName, cfg.QueueRoomEventPublishedURI),
		frame.WithRegisterSubscriber(
			cfg.QueueDeadLetterName, cfg.QueueDeadLetterURI,
			queues.NewDeadLetterConsumer(&cfg, deadLetterRepo),
		),
		frame.WithRegisterPublisher(cfg.QueueDeviceEventDeliveryName, cfg.QueueDeviceEventDeliveryURI),
		frame.WithRegisterSubscriber(
			cfg.QueueDeviceEventDeliveryName, cfg.QueueDeviceEventDeliveryURI,
			queues.NewHotPathDeliveryQueueHandler(&cfg, queueMan, workMan, dbPool, deviceCli, dlp),
		),
		frame.WithRegisterPublisher(cfg.QueueOfflineEventDeliveryName, cfg.QueueOfflineEventDeliveryURI),
		frame.WithRegisterSubscriber(
			cfg.QueueOfflineEventDeliveryName, cfg.QueueOfflineEventDeliveryURI,
			queues.NewOfflineDeliveryQueueHandler(&cfg, queueMan, deviceCli, dlp),
		),
	}

	serviceOptions = append(serviceOptions, gatewayPublisherOptions(cfg)...)
	serviceOptions = append(serviceOptions, stawiOptions(cfg, stawiChain)...)

	// Register queue handlers and event handlers
	serviceOptions = append(serviceOptions,
		frame.WithRegisterEvents(
			events.NewRoomCreatedQueue(ctx, eventsMan),
			events.NewSubscriptionAddQueue(ctx, dbPool, workMan, eventsMan),
			events.NewSubscriptionAuthorizeQueue(ctx, dbPool, workMan, eventsMan, authzMiddleware),
			events.NewRoomOutboxLoggingQueue(ctx, dbPool, workMan, eventsMan),
			events.NewFanoutEventHandler(ctx, &cfg, dbPool, workMan, queueMan, eventsMan),
		))

	// Initialize the service with all options
	svc.Init(ctx, serviceOptions...)

	return svc.Run(ctx, "")
}

func main() {
	ctx := context.Background()
	if err := runService(ctx); err != nil {
		util.Log(ctx).WithError(err).Fatal("could not run service")
	}
}

// gatewayPublisherOptions builds one publisher option per gateway delivery shard.
func gatewayPublisherOptions(cfg aconfig.ChatConfig) []frame.Option {
	opts := make([]frame.Option, 0, cfg.ShardCount)
	for i := range cfg.ShardCount {
		opts = append(opts, frame.WithRegisterPublisher(
			fmt.Sprintf(cfg.QueueGatewayEventDeliveryName, i),
			cfg.QueueGatewayEventDeliveryURI[i],
		))
	}
	return opts
}

// outboxRelayOption builds the frame background-consumer option that runs the
// transactional-outbox relay (sole publisher draining room_outbox) for the
// lifetime of the service. The relay also publishes the durable
// chat.room.event.published fact for rooms that opted in through room
// metadata, so the fact stream shares the relay's ordering and delivery
// guarantees instead of introducing a second publisher.
func outboxRelayOption(
	ctx context.Context,
	cfg *aconfig.ChatConfig,
	dbPool pool.Pool,
	workMan workerpool.Manager,
	queueMan queue.Manager,
	eventsMan frevents.Manager,
) frame.Option {
	outboxRepo := repository.NewRoomOutboxRepository(ctx, dbPool, workMan)
	factPublisher := events.NewRoomEventFactPublisher(
		repository.NewRoomRepository(ctx, dbPool, workMan),
		repository.NewRoomEventRepository(ctx, dbPool, workMan),
		queueMan,
		cfg.QueueRoomEventPublishedName,
	)
	return frame.WithBackgroundConsumer(events.NewOutboxRelay(outboxRepo, eventsMan, factPublisher).Run)
}

// handleDatabaseMigration performs database migration if configured to do so.
func handleDatabaseMigration(
	ctx context.Context,
	dbManager datastore.Manager,
	cfg aconfig.ChatConfig,
) bool {
	if !cfg.DoDatabaseMigrate() {
		return false
	}

	// Frame's migration scanner stores basenames, then SaveMigrationString
	// does os.Stat(basename). When WORKDIR is "/" (container default) the
	// file is not found, so frame prefixes names with "string:" and treats
	// every migration as new — re-applying SQL that already ran. Chdir into
	// the migrations directory so basename lookups succeed.
	migrationPath := cfg.GetDatabaseMigrationPath()
	if abs, err := filepath.Abs(migrationPath); err == nil {
		if chdirErr := os.Chdir(abs); chdirErr != nil {
			util.Log(ctx).WithError(chdirErr).WithField("path", abs).
				Warn("main -- could not chdir to migration path; string: migration duplicates may appear")
		} else {
			migrationPath = "."
		}
	}

	util.Log(ctx).Info("main -- starting database migration")
	err := repository.Migrate(ctx, dbManager, migrationPath)
	if err != nil {
		util.Log(ctx).WithError(err).Fatal("main -- Could not migrate successfully")
	}
	util.Log(ctx).Info("main -- database migration complete; migrate job exiting")
	return true
}

// stawiOptions subscribes the chain consumer to settlement's facts, runs the
// reconciler on its interval and registers the drift publisher.
func stawiOptions(cfg aconfig.ChatConfig, chain *business.StawiChain) []frame.Option {
	opts := []frame.Option{
		frame.WithRegisterSubscriber(
			cfg.QueueStawiFactsName,
			cfg.QueueStawiFactsURI,
			queues.NewStawiFactsHandler(chain),
		),
		frame.WithBackgroundConsumer(func(ctx context.Context) error {
			return chain.Run(ctx, time.Duration(cfg.StawiReconcileIntervalSeconds)*time.Second)
		}),
	}
	if cfg.QueueStawiDriftName != "" {
		opts = append(opts, frame.WithRegisterPublisher(cfg.QueueStawiDriftName, cfg.QueueStawiDriftURI))
	}
	return opts
}

// setupSettlementRooms returns settlement's RoomService as chat uses it.
//
// The adapter over the generated settlement.v1 RoomService client is added
// once that service is published on buf.build/stawi/finance; it will be built
// with connection.NewServiceClient(ctx, &cfg, common.ServiceTarget{Endpoint:
// cfg.SettlementServiceURI, WorkloadAPITargetPath:
// cfg.SettlementServiceWorkloadAPITargetPath, ServiceID:
// servicecatalog.ServiceStawiSettlement}, ...). Until then Stawi room acts are
// refused as unavailable; bound rooms are still guarded and settlement's facts
// still applied.
//
//nolint:unparam // returns the adapter once settlement's RoomService is published
func setupSettlementRooms(ctx context.Context, cfg aconfig.ChatConfig) stawi.Rooms {
	if cfg.SettlementServiceURI != "" {
		util.Log(ctx).WithField("endpoint", cfg.SettlementServiceURI).
			Warn("main -- settlement RoomService adapter not available yet; Stawi room acts are refused")
	}
	return nil
}

// setupStawi wires Stawi rooms: settlement relays room acts, profile maps
// chain addresses to profiles (client/accounts over the profile client), and
// the chain consumer applies settlement's facts.
func setupStawi(
	ctx context.Context,
	cfg *aconfig.ChatConfig,
	dbPool pool.Pool,
	workMan workerpool.Manager,
	queueMan queue.Manager,
	profileCli profilev1connect.ProfileServiceClient,
	authzMiddleware authz.Middleware,
) (*business.StawiChain, handlers.ServerOption) {
	rooms, accountResolver := setupSettlementRooms(ctx, *cfg), accounts.New(profileCli)
	chain := newStawiChain(ctx, dbPool, workMan, queueMan, cfg, rooms, accountResolver, authzMiddleware)
	return chain, handlers.WithStawi(rooms, accountResolver)
}

// newStawiChain builds the chain consumer that applies settlement's facts.
func newStawiChain(
	ctx context.Context,
	dbPool pool.Pool,
	workMan workerpool.Manager,
	queueMan queue.Manager,
	cfg *aconfig.ChatConfig,
	rooms stawi.Rooms,
	accountResolver stawi.AccountResolver,
	authzMiddleware authz.Middleware,
) *business.StawiChain {
	return business.NewStawiChain(business.StawiChainDeps{
		Pool:     dbPool,
		RoomRepo: repository.NewRoomRepository(ctx, dbPool, workMan),
		SubRepo:  repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan),
		Bindings: repository.NewStawiRoomRepository(ctx, dbPool, workMan),
		Calls:    repository.NewStawiRoomCallRepository(ctx, dbPool, workMan),
		Store:    repository.NewStawiChainStore(dbPool),
		Accounts: accountResolver,
		Rooms:    rooms,
		Authz:    authzMiddleware,
		Drift:    queues.NewStawiDriftPublisher(queueMan, cfg.QueueStawiDriftName),
	})
}

// setupNotificationClient creates and configures the notification client.
func setupNotificationClient(
	ctx context.Context,
	cfg aconfig.ChatConfig) (notificationv1connect.NotificationServiceClient, error) {
	return connection.NewServiceClient(ctx, &cfg, common.ServiceTarget{
		Endpoint:              cfg.NotificationServiceURI,
		WorkloadAPITargetPath: cfg.NotificationServiceWorkloadAPITargetPath,
		ServiceID:             servicecatalog.ServiceNotification,
	}, notificationv1connect.NewNotificationServiceClient)
}

// setupProfileClient creates and configures the profile client.
func setupProfileClient(
	ctx context.Context,
	cfg aconfig.ChatConfig) (profilev1connect.ProfileServiceClient, error) {
	return connection.NewServiceClient(ctx, &cfg, common.ServiceTarget{
		Endpoint:              cfg.ProfileServiceURI,
		WorkloadAPITargetPath: cfg.ProfileServiceWorkloadAPITargetPath,
		ServiceID:             servicecatalog.ServiceProfile,
	}, profilev1connect.NewProfileServiceClient)
}

// setupDeviceClient creates and configures the device client.
func setupDeviceClient(
	ctx context.Context,
	cfg aconfig.ChatConfig) (devicev1connect.DeviceServiceClient, error) {
	return connection.NewServiceClient(ctx, &cfg, common.ServiceTarget{
		Endpoint:              cfg.DeviceServiceURI,
		WorkloadAPITargetPath: cfg.DeviceServiceWorkloadAPITargetPath,
		ServiceID:             servicecatalog.ServiceDevices,
	}, devicev1connect.NewDeviceServiceClient)
}

// setupConnectServer initializes and configures the gRPC server.
func setupConnectServer(ctx context.Context, svc *frame.Service,
	notificationCli notificationv1connect.NotificationServiceClient,
	profileCli profilev1connect.ProfileServiceClient,
	authzMiddleware authz.Middleware,
	opts ...handlers.ServerOption,
) http.Handler {
	securityMan := svc.SecurityManager()

	auth := securityMan.GetAuthorizer(ctx)
	tenancyAccessChecker := authorizer.NewTenancyAccessChecker(auth, authz.NamespaceTenancyAccess)
	tenancyAccessInterceptor := connectInterceptors.NewTenancyAccessInterceptor(tenancyAccessChecker)

	// Automatic tenant-level permission enforcement from proto annotations.
	// This is complementary to the room-level checks in the authz middleware.
	sd := chatpb.File_chat_v1_chat_proto.Services().ByName("ChatService")
	procMap := permissions.BuildProcedureMap(sd)
	svcPerms := permissions.ForService(sd)
	functionChecker := authorizer.NewFunctionChecker(auth, svcPerms.Namespace)
	functionAccessInterceptor := connectInterceptors.NewFunctionAccessInterceptor(functionChecker, procMap)

	defaultInterceptorList, err := connectInterceptors.DefaultList(
		ctx, securityMan.GetAuthenticator(ctx), tenancyAccessInterceptor, functionAccessInterceptor)
	if err != nil {
		util.Log(ctx).WithError(err).Fatal("could not configure interceptors")
	}

	implementation := handlers.NewChatServer(ctx, svc, notificationCli, profileCli, authzMiddleware, opts...)

	_, serverHandler := chatv1connect.NewChatServiceHandler(
		implementation, connect.WithInterceptors(defaultInterceptorList...))

	mux := http.NewServeMux()
	mux.Handle("/", serverHandler)
	mux.Handle("/openapi.yaml", common.NewOpenAPIHandler(chatAPISpecFile, nil))

	return mux
}
