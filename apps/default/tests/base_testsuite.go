package tests

import (
	"context"
	"errors"
	"fmt"
	"net/url"
	"path/filepath"
	"runtime"
	"testing"
	"time"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	"buf.build/gen/go/antinvestor/device/connectrpc/go/device/v1/devicev1connect"
	devicev1 "buf.build/gen/go/antinvestor/device/protocolbuffers/go/device/v1"
	"buf.build/gen/go/antinvestor/notification/connectrpc/go/notification/v1/notificationv1connect"
	"buf.build/gen/go/antinvestor/profile/connectrpc/go/profile/v1/profilev1connect"
	profilev1 "buf.build/gen/go/antinvestor/profile/protocolbuffers/go/profile/v1"
	"connectrpc.com/connect"
	devicemocks "github.com/antinvestor/apis/go/device/mocks"
	notificationmocks "github.com/antinvestor/apis/go/notification/mocks"
	profilemocks "github.com/antinvestor/apis/go/profile/mocks"
	iconfig "github.com/antinvestor/service-chat/apps/default/config"
	"github.com/antinvestor/service-chat/apps/default/service/authz"
	"github.com/antinvestor/service-chat/apps/default/service/events"
	"github.com/antinvestor/service-chat/apps/default/service/queues"
	"github.com/antinvestor/service-chat/apps/default/service/repository"
	"github.com/antinvestor/service-chat/apps/default/tests/testketo"
	"github.com/gojuno/minimock/v3"
	"github.com/pitabwire/frame"
	"github.com/pitabwire/frame/config"
	"github.com/pitabwire/frame/datastore"
	"github.com/pitabwire/frame/datastore/pool"
	"github.com/pitabwire/frame/frametests"
	"github.com/pitabwire/frame/frametests/definition"
	"github.com/pitabwire/frame/frametests/deps/testpostgres"
	"github.com/pitabwire/frame/security"
	"github.com/pitabwire/frame/workerpool"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
)

const PostgresqlDBImage = "postgres:latest"

const (
	DefaultRandomStringLength = 8

	waitTimeout      = 10 * time.Second
	waitPollInterval = 50 * time.Millisecond
	startupDelay     = 200 * time.Millisecond
)

type BaseTestSuite struct {
	frametests.FrameBaseTestSuite
	AuthzMiddleware authz.Middleware
	ketoReadURI     string
	ketoWriteURI    string
}

// migrationPath returns the absolute path to the SQL migration directory.
// Uses runtime.Caller to resolve relative to this source file, so it works
// regardless of which test package's working directory is active.
func migrationPath() string {
	_, thisFile, _, _ := runtime.Caller(0)
	return filepath.Join(filepath.Dir(thisFile), "..", "migrations", "0001")
}

func initResources(_ context.Context) []definition.TestResource {
	pg := testpostgres.NewWithOpts("service_chat",
		definition.WithUserName("ant"),
		definition.WithImageName(PostgresqlDBImage),
		definition.WithEnableLogging(true))

	keto := testketo.NewWithOpts(
		definition.WithDependancies(pg),
		definition.WithEnableLogging(true),
	)

	return []definition.TestResource{pg, keto}
}

func (bs *BaseTestSuite) SetupSuite() {
	bs.InitResourceFunc = initResources
	bs.FrameBaseTestSuite.SetupSuite()

	ctx := bs.T().Context()

	// Find Keto dependency and extract read/write URIs
	var ketoDep definition.DependancyConn
	for _, res := range bs.Resources() {
		if res.Name() == testketo.ImageName {
			ketoDep = res
			break
		}
	}
	bs.Require().NotNil(ketoDep, "keto dependency should be available")

	// Write API: default port (4467/tcp, first in port list)
	writeURL, err := url.Parse(string(ketoDep.GetDS(ctx)))
	bs.Require().NoError(err)
	bs.ketoWriteURI = writeURL.Host

	// Read API: port 4466/tcp (second in port list)
	readPort, err := ketoDep.PortMapping(ctx, "4466/tcp")
	bs.Require().NoError(err)
	bs.ketoReadURI = fmt.Sprintf("%s:%s", writeURL.Hostname(), readPort)
}

func (bs *BaseTestSuite) CreateService(
	t *testing.T,
	depOpts *definition.DependencyOption,
) (context.Context, *frame.Service) {
	t.Setenv("OTEL_TRACES_EXPORTER", "none")

	ctx := t.Context()
	cfg, err := config.FromEnv[iconfig.ChatConfig]()
	require.NoError(t, err)

	cfg.LogLevel = "debug"
	cfg.DatabaseMigrate = true
	cfg.RunServiceSecurely = false
	cfg.ServerPort = ""

	res := depOpts.ByIsDatabase(ctx)
	testDS, cleanup, err0 := res.GetRandomisedDS(t.Context(), depOpts.Prefix())
	require.NoError(t, err0)

	t.Cleanup(func() {
		cleanup(t.Context())
	})

	cfg.DatabaseTraceQueries = true
	cfg.DatabasePrimaryURL = []string{testDS.String()}
	cfg.DatabaseReplicaURL = []string{testDS.String()}

	// Configure real Keto authorizer URIs
	cfg.AuthorizationServiceReadURI = bs.ketoReadURI
	cfg.AuthorizationServiceWriteURI = bs.ketoWriteURI

	ctx, svc := frame.NewServiceWithContext(t.Context(),
		frame.WithName("chat tests"),
		frame.WithConfig(&cfg),
		frametests.WithNoopDriver(),
		frame.WithDatastore())

	dbManager := svc.DatastoreManager()
	workMan := svc.WorkManager()
	queueMan := svc.QueueManager()
	eventsMan := svc.EventsManager()

	dbPool := dbManager.GetPool(ctx, datastore.DefaultPoolName)

	err = repository.Migrate(ctx, dbManager, migrationPath())
	require.NoError(t, err)

	// Use real Keto authorizer via SecurityManager
	sm := svc.SecurityManager()
	authzMw := authz.NewMiddleware(sm.GetAuthorizer(ctx))
	bs.AuthzMiddleware = authzMw

	// Register queue handlers and event handlers BEFORE Run() to avoid
	// race conditions. The queue consumer starts during Run(), so all
	// handlers must be registered before that point.
	serviceOptions := []frame.Option{
		frame.WithRegisterPublisher(
			cfg.QueueDeviceEventDeliveryName,
			cfg.QueueDeviceEventDeliveryURI,
		),
		frame.WithRegisterSubscriber(
			cfg.QueueDeviceEventDeliveryName,
			cfg.QueueDeviceEventDeliveryURI,
			queues.NewHotPathDeliveryQueueHandler(&cfg, queueMan, workMan, bs.GetDevice(t), nil),
		),
		frame.WithRegisterEvents(
			events.NewRoomCreatedQueue(ctx, eventsMan),
			events.NewSubscriptionAddQueue(ctx, dbPool, workMan, eventsMan),
			events.NewSubscriptionAuthorizeQueue(ctx, dbPool, workMan, eventsMan, authzMw),
			events.NewRoomOutboxLoggingQueue(ctx, dbPool, workMan, eventsMan),
			events.NewFanoutEventHandler(ctx, &cfg, dbPool, workMan, queueMan),
		),
	}

	// Initialize the service with all options
	svc.Init(ctx, serviceOptions...)

	// Run the service in a goroutine with a random port so the queue
	// subscribers stay alive for the full event chain (RoomCreated →
	// SubscriptionAdd → SubscriptionAuthorize). Using empty port ""
	// causes Run to exit immediately, which kills the queue subscriber
	// before all async events are processed.
	go func() {
		_ = svc.Run(ctx, ":0")
	}()

	// Give queue listeners time to start before the test proceeds
	time.Sleep(startupDelay)

	return ctx, svc
}

// GetRepoDeps is a helper to create repository dependencies.
func (bs *BaseTestSuite) GetRepoDeps(ctx context.Context, svc *frame.Service) (workerpool.Manager, pool.Pool) {
	workMan := svc.WorkManager()
	dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)
	return workMan, dbPool
}

func (bs *BaseTestSuite) GetNotificationCli(t *testing.T) notificationv1connect.NotificationServiceClient {
	ctrl := minimock.NewController(t)

	mocksvc := notificationmocks.NewNotificationServiceClientMock(ctrl)
	return mocksvc
}

func (bs *BaseTestSuite) GetProfileCli(t *testing.T) profilev1connect.ProfileServiceClient {
	ctrl := minimock.NewController(t)
	mocksvc := profilemocks.NewProfileServiceClientMock(ctrl)

	return mocksvc
}

func (bs *BaseTestSuite) GetDevice(t *testing.T) devicev1connect.DeviceServiceClient {
	ctrl := minimock.NewController(t)
	mockSvc := devicemocks.NewDeviceServiceClientMock(ctrl)

	// Configure the mock to expect Search calls and return no devices found error
	mockSvc.SearchMock.Optional().
		Set(func(_ context.Context, _ *connect.Request[devicev1.SearchRequest]) (*connect.ServerStreamForClient[devicev1.SearchResponse], error) {
			return nil, errors.New("no devices found")
		})

	return mockSvc
}

func (bs *BaseTestSuite) CreateTestProfiles(
	_ context.Context,
	_ *frame.Service,
	contacts []string,
) ([]*profilev1.ProfileObject, error) {
	// Mock profile creation for testing
	var profileSlice []*profilev1.ProfileObject

	for range contacts {
		profile := &profilev1.ProfileObject{
			Id: util.IDString(),
		}
		profileSlice = append(profileSlice, profile)
	}

	return profileSlice, nil
}

// WaitForRoomSubscription polls until at least one active subscription exists
// for the given room. This is needed because subscriptions are created
// asynchronously via event queues after CreateRoom returns.
func (bs *BaseTestSuite) WaitForRoomSubscription(
	ctx context.Context,
	svc *frame.Service,
	roomID string,
	t *testing.T,
) {
	t.Helper()
	workMan := svc.WorkManager()
	dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)
	subRepo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

	type result struct{}
	_, err := frametests.WaitForConditionWithResult(ctx, func() (*result, error) {
		subs, subErr := subRepo.GetByRoomID(ctx, roomID, nil)
		if subErr != nil || len(subs) == 0 {
			return nil, subErr
		}
		return &result{}, nil
	}, waitTimeout, waitPollInterval)
	require.NoError(t, err, "timed out waiting for subscriptions in room %s", roomID)
}

// WaitForMemberSubscription polls until a subscription exists for a specific
// member in a room. Used after AddRoomSubscriptions which creates
// subscriptions asynchronously via event queues.
func (bs *BaseTestSuite) WaitForMemberSubscription(
	ctx context.Context,
	svc *frame.Service,
	roomID string,
	profileID string,
	t *testing.T,
) {
	t.Helper()
	workMan := svc.WorkManager()
	dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)
	subRepo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

	type result struct{}
	_, err := frametests.WaitForConditionWithResult(ctx, func() (*result, error) {
		subs, subErr := subRepo.GetByContactLinkAndRooms(ctx,
			&commonv1.ContactLink{ProfileId: profileID}, roomID)
		if subErr != nil || len(subs) == 0 {
			return nil, subErr
		}
		return &result{}, nil
	}, waitTimeout, waitPollInterval)
	require.NoError(t, err, "timed out waiting for member %s subscription in room %s", profileID, roomID)
}

// WaitForAuthzAccess polls until the authz middleware grants the specified
// subscription access to a room. This is needed because authz tuples are synced
// asynchronously via event queues after subscriptions are created.
// It first resolves the subscription for the profile, then checks authz with the subscriptionID.
// Uses WaitForCheckedConditionWithResult with a custom checker because the
// authz "permission denied" error is not a "not found" error, and
// WaitForConditionWithResult would stop polling immediately on such errors.
func (bs *BaseTestSuite) WaitForAuthzAccess(
	ctx context.Context,
	svc *frame.Service,
	profileID string,
	roomID string,
	t *testing.T,
) {
	t.Helper()
	workMan := svc.WorkManager()
	dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)
	subRepo := repository.NewRoomSubscriptionRepository(ctx, dbPool, workMan)

	type result struct{}
	_, err := frametests.WaitForCheckedConditionWithResult(ctx, func() (*result, error) {
		// Resolve subscription first
		contact := &commonv1.ContactLink{ProfileId: profileID}
		subs, subErr := subRepo.GetByContactLinkAndRooms(ctx, contact, roomID)
		if subErr != nil || len(subs) == 0 {
			return nil, subErr
		}

		// Check authz with subscriptionID
		if authzErr := bs.AuthzMiddleware.CanViewRoom(ctx, subs[0].GetID(), roomID); authzErr != nil {
			return nil, authzErr
		}
		return &result{}, nil
	}, func(_ *result, err error) bool {
		// Only stop polling on success (no error); keep retrying on any error
		// since we're waiting for the async authz tuple to be created.
		return err == nil
	}, waitTimeout, waitPollInterval)
	require.NoError(t, err, "timed out waiting for authz access for profile %s in room %s", profileID, roomID)
}

func (bs *BaseTestSuite) TearDownSuite() {
	bs.FrameBaseTestSuite.TearDownSuite()
}

// WithTestDependencies Creates subtests with each known DependencyOption.
func (bs *BaseTestSuite) WithTestDependencies(
	t *testing.T,
	testFn func(t *testing.T, dep *definition.DependencyOption),
) {
	options := []*definition.DependencyOption{
		definition.NewDependancyOption(
			"default",
			util.RandomAlphaNumericString(DefaultRandomStringLength),
			bs.Resources(),
		),
	}

	frametests.WithTestDependencies(t, options, testFn)
}

// WithAuthClaims adds authentication claims to a context for testing.
func (bs *BaseTestSuite) WithAuthClaims(ctx context.Context, profileID string) context.Context {
	claims := &security.AuthenticationClaims{
		TenantID:  util.IDString(),
		AccessID:  util.IDString(),
		ContactID: profileID,
		SessionID: util.IDString(),
		DeviceID:  "test-device",
	}
	// Set the Subject field from jwt.RegisteredClaims
	claims.Subject = profileID
	return claims.ClaimsToContext(ctx)
}
