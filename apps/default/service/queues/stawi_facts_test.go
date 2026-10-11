package queues

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	frevents "github.com/pitabwire/frame/v2/events"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/service/business"
)

type recordingReceiver struct {
	names    []string
	eventIDs []string
	payloads [][]byte
	err      error
}

func (r *recordingReceiver) ReceiveDelivery(_ context.Context, name, eventID string, payload []byte) error {
	r.names = append(r.names, name)
	r.eventIDs = append(r.eventIDs, eventID)
	r.payloads = append(r.payloads, payload)
	return r.err
}

// TestStawiFactsHandlerRoutesByEventName hands each settlement fact to the
// chain consumer under the name settlement published it with, and returns
// the consumer's error so the queue redelivers a fact that was not applied.
func TestStawiFactsHandlerRoutesByEventName(t *testing.T) {
	receiver := &recordingReceiver{}
	handler := NewStawiFactsHandler(receiver)
	ctx := context.Background()

	require.NoError(t, handler.Handle(ctx,
		map[string]string{"event_name": "room.activated", "event_id": "e1"}, []byte{1}))
	require.NoError(t, handler.Handle(ctx,
		map[string]string{frevents.EventHeaderName: "room.membership_observed", "event_id": "e2"}, []byte{2}))
	require.NoError(t, handler.Handle(ctx, map[string]string{"event_id": "e3"}, []byte{3}),
		"a message without a name is skipped")
	require.NoError(t, handler.Handle(ctx, map[string]string{"event_name": "room.activated"}, []byte{5}),
		"a message without settlement's event id is skipped")
	require.Equal(t, []string{"room.activated", "room.membership_observed"}, receiver.names)
	require.Equal(t, []string{"e1", "e2"}, receiver.eventIDs)

	receiver.err = errors.New("profile down")
	require.Error(t, handler.Handle(ctx, map[string]string{"event_name": "room.activated", "event_id": "e4"},
		[]byte{4}))
}

// TestDriftPublisherEmitsRoomSubscriptionDrift publishes a repair report on
// the drift queue under the room.subscription_drift name.
func TestDriftPublisherEmitsRoomSubscriptionDrift(t *testing.T) {
	qm := newMockQueueManager()
	publisher := NewStawiDriftPublisher(qm, "chat.room.subscription_drift")
	at := time.Unix(1_900_000_000, 0).UTC()
	require.NoError(t, publisher.PublishDrift(context.Background(), business.StawiDrift{
		RoomID: "room-1", Restored: 1, Removed: 2, PermissionsRepaired: 3, At: at,
	}))

	pub := qm.publishers["chat.room.subscription_drift"]
	require.NotNil(t, pub)
	require.Len(t, pub.published, 1)
	require.Equal(t, "room.subscription_drift", pub.published[0].headers["event_name"])
	var body map[string]any
	require.NoError(t, json.Unmarshal(pub.published[0].payload.([]byte), &body))
	require.Equal(t, "room-1", body["room_id"])
	require.EqualValues(t, 2, body["removed"])

	require.NoError(t, NewStawiDriftPublisher(qm, "").PublishDrift(context.Background(), business.StawiDrift{}),
		"an unnamed queue disables publishing")
}
