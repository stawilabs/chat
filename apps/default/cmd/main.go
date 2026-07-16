package main

import (
	"context"
	_ "embed"
	"fmt"
	"net/http"

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
	"github.com/antinvestor/common/v2/timescale"
	"github.com/pitabwire/frame/v2"
	"github.com/pitabwire/frame/v2/config"
	"github.com/pitabwire/frame/v2/datastore"
	"github.com/pitabwire/frame/v2/datastore/pool"
	frevents "github.com/pitabwire/frame/v2/events"
	"github.com/pitabwire/frame/v2/security/authorizer"
	connectInterceptors "github.com/pitabwire/frame/v2/security/interceptors/connect"
	"github.com/pitabwire/frame/v2/workerpool"
	"github.com/pitabwire/util"

	aconfig "github.com/stawilabs/chat/apps/default/config"
	"github.com/stawilabs/chat/apps/default/service/authz"
	"github.com/stawilabs/chat/apps/default/service/events"
	"github.com/stawilabs/chat/apps/default/service/handlers"
	"github.com/stawilabs/chat/apps/default/service/health"
	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/queues"
	"github.com/stawilabs/chat/apps/default/service/repository"
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

	// Setup clients and services
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

	// Migration mode runs SQL migrations then hypertable setup (see
	// handleDatabaseMigration) and exits; hypertables are never promoted on a
	// normal boot, avoiding the boot-vs-migrate ordering race.
	if handleDatabaseMigration(ctx, dbManager, dbPool, cfg) {
		return nil
	}

	// Setup Keto authorization service
	auth := sm.GetAuthorizer(ctx)
	authzMiddleware := authz.NewMiddleware(auth)

	// Setup Connect server and HTTP handlers
	connectHandler := setupConnectServer(ctx, svc, notificationCli, profileCli, authzMiddleware)
	dlp := queues.NewDeadLetterPublisher(&cfg, queueMan)
	deadLetterRepo := repository.NewDeadLetterRepository(ctx, dbPool, workMan)

	serviceOptions := []frame.Option{
		// Outbox relay: sole publisher draining room_outbox, run as a frame
		// background consumer so its lifecycle is owned by the service.
		outboxRelayOption(ctx, dbPool, workMan, eventsMan),
		frame.WithHTTPHandler(connectHandler),
		frame.WithPermissionRegistration(chatpb.File_chat_v1_chat_proto.Services().ByName("ChatService")),
		frame.WithRegisterPublisher(cfg.QueueDeadLetterName, cfg.QueueDeadLetterURI),
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
// lifetime of the service.
func outboxRelayOption(
	ctx context.Context,
	dbPool pool.Pool,
	workMan workerpool.Manager,
	eventsMan frevents.Manager,
) frame.Option {
	outboxRepo := repository.NewRoomOutboxRepository(ctx, dbPool, workMan)
	return frame.WithBackgroundConsumer(events.NewOutboxRelay(outboxRepo, eventsMan).Run)
}

// ensureHypertables registers TimescaleDB hypertables idempotently.
// Called only from the migrate job after SQL migrations (composite PK must
// include the time-partition column). Returns an error so the migrate job
// fails closed when TimescaleDB conversion cannot complete — a silent WARN
// previously let the job report success while room_events stayed a plain table.
func ensureHypertables(ctx context.Context, dbPool pool.Pool) error {
	if tsErr := timescale.Ensure(ctx, dbPool.DB(ctx, false), models.Hypertables()); tsErr != nil {
		return tsErr
	}
	return nil
}

// handleDatabaseMigration performs database migration if configured to do so.
// On success it also (idempotently) promotes the configured hypertables, so all
// schema setup — SQL migrations then TimescaleDB hypertable conversion — happens
// in one ordered place: the migrate job.
func handleDatabaseMigration(
	ctx context.Context,
	dbManager datastore.Manager,
	dbPool pool.Pool,
	cfg aconfig.ChatConfig,
) bool {
	if !cfg.DoDatabaseMigrate() {
		return false
	}

	err := repository.Migrate(ctx, dbManager, cfg.GetDatabaseMigrationPath())
	if err != nil {
		util.Log(ctx).WithError(err).Fatal("main -- Could not migrate successfully")
	}

	// Promote hypertables after the SQL migrations have run.
	if tsErr := ensureHypertables(ctx, dbPool); tsErr != nil {
		util.Log(ctx).WithError(tsErr).Fatal("main -- Could not ensure TimescaleDB hypertables")
	}
	return true
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

	implementation := handlers.NewChatServer(ctx, svc, notificationCli, profileCli, authzMiddleware)

	_, serverHandler := chatv1connect.NewChatServiceHandler(
		implementation, connect.WithInterceptors(defaultInterceptorList...))

	mux := http.NewServeMux()
	mux.Handle("/", serverHandler)
	mux.Handle("/openapi.yaml", common.NewOpenAPIHandler(chatAPISpecFile, nil))

	return mux
}
