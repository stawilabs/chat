package events_test

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	eventsv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/events/v1"
	"github.com/pitabwire/frame/v3"
	"github.com/pitabwire/frame/v3/data"
	"github.com/pitabwire/frame/v3/datastore"
	"github.com/pitabwire/frame/v3/frametests/definition"
	"github.com/pitabwire/frame/v3/queue"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/stawilabs/chat/apps/default/service/events"
	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/tests"
)

const factQueueName = "chat.room.event.published"

type RoomEventPublishedTestSuite struct {
	tests.BaseTestSuite
}

func TestRoomEventPublishedTestSuite(t *testing.T) {
	suite.Run(t, new(RoomEventPublishedTestSuite))
}

// recordingPublisher records everything published to the fact queue.
type recordingPublisher struct {
	published []*events.RoomEventPublishedFact
	headers   []map[string]string
}

func (r *recordingPublisher) Initiated() bool              { return true }
func (r *recordingPublisher) Ref() string                  { return factQueueName }
func (r *recordingPublisher) Init(_ context.Context) error { return nil }
func (r *recordingPublisher) Stop(_ context.Context) error { return nil }
func (r *recordingPublisher) As(_ any) bool                { return false }

func (r *recordingPublisher) Publish(_ context.Context, payload any, headers ...map[string]string) error {
	// Round-trip through JSON exactly as the queue does, so the test asserts
	// on the bytes a consumer receives rather than on the in-process struct.
	raw, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	fact := &events.RoomEventPublishedFact{}
	if umErr := json.Unmarshal(raw, fact); umErr != nil {
		return umErr
	}
	r.published = append(r.published, fact)
	if len(headers) > 0 {
		r.headers = append(r.headers, headers[0])
	}
	return nil
}

// stubQueueManager hands out the recording publisher for the fact queue.
type stubQueueManager struct {
	publisher *recordingPublisher
}

func (m *stubQueueManager) AddPublisher(_ context.Context, _ string, _ string) error { return nil }
func (m *stubQueueManager) DiscardPublisher(_ context.Context, _ string) error       { return nil }
func (m *stubQueueManager) AddSubscriber(
	_ context.Context, _ string, _ string, _ ...queue.SubscribeWorker,
) error {
	return nil
}
func (m *stubQueueManager) DiscardSubscriber(_ context.Context, _ string) error { return nil }
func (m *stubQueueManager) GetSubscriber(_ string) (queue.Subscriber, error) {
	return nil, nil //nolint:nilnil // stub returns nil for both values
}
func (m *stubQueueManager) Publish(_ context.Context, _ string, _ any, _ ...map[string]string) error {
	return nil
}
func (m *stubQueueManager) Init(_ context.Context) error  { return nil }
func (m *stubQueueManager) Close(_ context.Context) error { return nil }
func (m *stubQueueManager) GetPublisher(_ string) (queue.Publisher, error) {
	return m.publisher, nil
}

type factHarness struct {
	relay     *events.OutboxRelay
	publisher *recordingPublisher
	roomRepo  repository.RoomRepository
	eventRepo repository.RoomEventRepository
	outbox    repository.RoomOutboxRepository
}

func (s *RoomEventPublishedTestSuite) newHarness(
	ctx context.Context,
	svc *frame.Service,
) *factHarness {
	workMan := svc.WorkManager()
	dbPool := svc.DatastoreManager().GetPool(ctx, datastore.DefaultPoolName)

	roomRepo := repository.NewRoomRepository(ctx, dbPool, workMan)
	eventRepo := repository.NewRoomEventRepository(ctx, dbPool, workMan)
	outboxRepo := repository.NewRoomOutboxRepository(ctx, dbPool, workMan)

	publisher := &recordingPublisher{}
	factPublisher := events.NewRoomEventFactPublisher(
		roomRepo, eventRepo, &stubQueueManager{publisher: publisher}, factQueueName,
	)

	return &factHarness{
		relay:     events.NewOutboxRelay(outboxRepo, svc.EventsManager(), factPublisher),
		publisher: publisher,
		roomRepo:  roomRepo,
		eventRepo: eventRepo,
		outbox:    outboxRepo,
	}
}

// seedRoom creates a room, optionally carrying the group metadata key.
func (h *factHarness) seedRoom(ctx context.Context, t *testing.T, properties data.JSONMap) string {
	t.Helper()
	room := &models.Room{RoomType: models.RoomTypeGroup, Name: "group room", Properties: properties}
	room.GenID(ctx)
	require.NoError(t, h.roomRepo.Create(ctx, room))
	return room.GetID()
}

// seedEvent persists a room event plus its outbox row, exactly as the message
// business does, and returns the event id.
func (h *factHarness) seedEvent(
	ctx context.Context,
	t *testing.T,
	roomID string,
	payload *chatv1.Payload,
) string {
	t.Helper()
	content, err := models.NewPayloadConverter().FromProto(payload)
	require.NoError(t, err)

	event := &models.RoomEvent{
		RoomID:    roomID,
		SenderID:  "sub-" + util.RandomAlphaNumericString(8),
		EventType: int32(chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT),
		Content:   content,
	}
	event.GenID(ctx)
	require.NoError(t, h.eventRepo.Create(ctx, event))

	link := &eventsv1.Link{
		EventId:   event.GetID(),
		RoomId:    roomID,
		Source:    &eventsv1.Subscription{SubscriptionId: event.SenderID},
		EventType: chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT,
		CreatedAt: timestamppb.New(time.Now()),
	}
	linkBytes, mErr := protojson.Marshal(link)
	require.NoError(t, mErr)

	row := &models.RoomOutbox{EventID: event.GetID(), RoomID: roomID, Payload: linkBytes}
	row.GenID(ctx)
	require.NoError(t, h.outbox.Create(ctx, row))

	return event.GetID()
}

func votePayload(motionID, choiceID string) *chatv1.Payload {
	return &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_VOTE,
		Data: &chatv1.Payload_Vote{Vote: &chatv1.VoteCast{MotionId: motionID, ChoiceId: choiceID}},
	}
}

func (s *RoomEventPublishedTestSuite) TestPublishesFactOnlyForMarkedRooms() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		h := s.newHarness(ctx, svc)

		groupID := util.IDString()
		markedRoom := h.seedRoom(ctx, t, data.JSONMap{events.GroupMetadataKey: groupID})
		plainRoom := h.seedRoom(ctx, t, data.JSONMap{"unrelated": "value"})

		markedEventID := h.seedEvent(ctx, t, markedRoom, votePayload("motion-1", "yes"))
		h.seedEvent(ctx, t, plainRoom, votePayload("motion-2", "yes"))

		// An encrypted event on the marked room must never be projected.
		h.seedEvent(ctx, t, markedRoom, &chatv1.Payload{
			Type: chatv1.PayloadType_PAYLOAD_TYPE_ENCRYPTED,
			Data: &chatv1.Payload_Encrypted{Encrypted: &chatv1.EncryptedContent{
				Algorithm:  "megolm.v1",
				Ciphertext: []byte("opaque"),
			}},
		})

		require.NoError(t, h.relay.Drain(ctx))

		require.Len(t, h.publisher.published, 1, "only the marked, non-encrypted event is published")
		fact := h.publisher.published[0]
		require.Equal(t, markedEventID, fact.EventID)
		require.Equal(t, markedRoom, fact.RoomID)
		require.Equal(t, groupID, fact.GroupID)
		require.Equal(t, "PAYLOAD_TYPE_VOTE", fact.PayloadType)
		require.Equal(t, "ROOM_EVENT_TYPE_EVENT", fact.RoomEventType)
		require.NotEmpty(t, fact.SubscriptionID)
		require.NotEmpty(t, fact.SentAt)
		require.NotEmpty(t, fact.PublishedAt)
		require.NotNil(t, fact.Vote)
		require.Equal(t, "motion-1", fact.Vote.MotionID)
		require.Equal(t, "yes", fact.Vote.ChoiceID)

		// Nothing that could be read as authorization travels with the fact.
		raw, mErr := json.Marshal(fact)
		require.NoError(t, mErr)
		body := map[string]any{}
		require.NoError(t, json.Unmarshal(raw, &body))
		for _, forbidden := range []string{"role", "roles", "token", "claims", "permission", "permissions", "signature", "approved"} {
			require.NotContains(t, body, forbidden)
		}
	})
}

func (s *RoomEventPublishedTestSuite) TestFactPublishedExactlyOnceUnderRedelivery() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		h := s.newHarness(ctx, svc)

		room := h.seedRoom(ctx, t, data.JSONMap{events.GroupMetadataKey: util.IDString()})
		eventID := h.seedEvent(ctx, t, room, votePayload("motion-3", "no"))

		// Drain repeatedly: the outbox row is dispatched once, so the fact is
		// published once no matter how often the relay runs.
		require.NoError(t, h.relay.Drain(ctx))
		require.NoError(t, h.relay.Drain(ctx))
		require.NoError(t, h.relay.Drain(ctx))

		require.Len(t, h.publisher.published, 1)
		require.Equal(t, eventID, h.publisher.published[0].EventID)

		pending, err := h.outbox.ListPending(ctx, time.Now().Add(time.Hour), 100)
		require.NoError(t, err)
		for _, row := range pending {
			require.NotEqual(t, eventID, row.EventID, "row should be dispatched")
		}
	})
}

func (s *RoomEventPublishedTestSuite) TestRoomChangeAndFormFactsCarryDraftFields() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		h := s.newHarness(ctx, svc)

		room := h.seedRoom(ctx, t, data.JSONMap{events.GroupMetadataKey: "grp-1"})

		h.seedEvent(ctx, t, room, &chatv1.Payload{
			Type: chatv1.PayloadType_PAYLOAD_TYPE_ROOM_CHANGE,
			Data: &chatv1.Payload_RoomChange{RoomChange: &chatv1.RoomChangeContent{
				Action:                chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_MEMBER_REMOVED,
				ActorSubscriptionId:   "actor-sub",
				TargetSubscriptionIds: []string{"target-sub"},
			}},
		})
		h.seedEvent(ctx, t, room, &chatv1.Payload{
			Type: chatv1.PayloadType_PAYLOAD_TYPE_FORM_SUBMISSION_RESULT,
			Data: &chatv1.Payload_FormSubmissionResult{
				FormSubmissionResult: &chatv1.FormSubmissionResultContent{
					FormInstanceId: "form-1",
					SchemaId:       "loan-request",
					SchemaVersion:  2,
					SourceEventId:  "source-1",
					State:          chatv1.FormMessageState_FORM_MESSAGE_STATE_SUBMITTED,
				},
			},
		})

		require.NoError(t, h.relay.Drain(ctx))
		require.Len(t, h.publisher.published, 2)

		byType := map[string]*events.RoomEventPublishedFact{}
		for _, fact := range h.publisher.published {
			byType[fact.PayloadType] = fact
		}

		roomChange := byType["PAYLOAD_TYPE_ROOM_CHANGE"]
		require.NotNil(t, roomChange)
		require.NotNil(t, roomChange.RoomChange)
		require.Equal(t, "ROOM_CHANGE_ACTION_MEMBER_REMOVED", roomChange.RoomChange.Action)
		require.Equal(t, []string{"target-sub"}, roomChange.RoomChange.TargetSubscriptionIDs)

		form := byType["PAYLOAD_TYPE_FORM_SUBMISSION_RESULT"]
		require.NotNil(t, form)
		require.NotNil(t, form.FormSubmissionResult)
		require.Equal(t, "form-1", form.FormSubmissionResult.FormInstanceID)
		require.Equal(t, "source-1", form.FormSubmissionResult.SourceEventID)
	})
}
