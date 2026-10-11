package events

import (
	"context"
	"encoding/json"
	"sync"
	"time"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	eventsv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/events/v1"
	frevents "github.com/pitabwire/frame/v2/events"
	"github.com/pitabwire/frame/v2/queue"
	"google.golang.org/protobuf/encoding/protojson"

	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
)

const (
	// RoomEventPublishedFactName is the durable fact emitted for a room that
	// opted in through room metadata. Consumers treat it as a signal only: it
	// carries no roles, claims, tokens or approvals, so nothing in it can
	// authorize a financial action.
	RoomEventPublishedFactName = "chat.room.event.published"

	// GroupMetadataKey is the room metadata key that opts a room into the
	// fact. A room without it publishes nothing.
	GroupMetadataKey = "stawi.group_id"

	// maxFactPayloadBytes caps the verbatim payload carried by a fact. A
	// larger payload (a full form schema, say) is dropped and flagged rather
	// than pushed through the queue; the consumer only ever needs the
	// summarised blocks below.
	maxFactPayloadBytes = 64 * 1024
)

// RoomEventPublishedFact is the JSON body of chat.room.event.published.
//
// It describes one durable, non-encrypted room event: who sent it (the room
// subscription and profile that chat authenticated), what kind of payload it
// was, and when. It deliberately carries no role, permission, claim, token or
// signature — a consumer can render or draft from it, never authorize.
type RoomEventPublishedFact struct {
	EventID        string `json:"event_id"`
	RoomID         string `json:"room_id"`
	GroupID        string `json:"group_id"`
	SubscriptionID string `json:"subscription_id"`
	ProfileID      string `json:"profile_id,omitempty"`
	ParentID       string `json:"parent_id,omitempty"`
	RoomEventType  string `json:"room_event_type"`
	PayloadType    string `json:"payload_type"`
	SentAt         string `json:"sent_at"`
	PublishedAt    string `json:"published_at"`

	// Summarised payloads, in the shape consumers match on.
	Vote                 *VoteFact                 `json:"vote,omitempty"`
	RoomChange           *RoomChangeFact           `json:"room_change,omitempty"`
	FormSubmissionResult *FormSubmissionResultFact `json:"form_submission_result,omitempty"`

	// Payload is the verbatim event payload in protojson form, omitted when
	// it exceeds maxFactPayloadBytes.
	Payload          json.RawMessage `json:"payload,omitempty"`
	PayloadTruncated bool            `json:"payload_truncated,omitempty"`
}

// VoteFact is a vote expressed in chat. It is not a vote: a vote counts only
// when signed on the member's device against the owning service.
type VoteFact struct {
	MotionID string `json:"motion_id"`
	ChoiceID string `json:"choice_id"`
}

// RoomChangeFact is a membership or room change.
type RoomChangeFact struct {
	Action                string   `json:"action"`
	ActorSubscriptionID   string   `json:"actor_subscription_id,omitempty"`
	TargetSubscriptionIDs []string `json:"target_subscription_ids,omitempty"`
}

// FormSubmissionResultFact is a form submitted in chat.
type FormSubmissionResultFact struct {
	FormInstanceID string `json:"form_instance_id"`
	SchemaID       string `json:"schema_id,omitempty"`
	SchemaVersion  int32  `json:"schema_version,omitempty"`
	SourceEventID  string `json:"source_event_id,omitempty"`
	State          string `json:"state,omitempty"`
}

// RoomEventFactPublisher publishes RoomEventPublishedFact for rooms that
// opted in via GroupMetadataKey. It is driven by the outbox relay, so a fact
// inherits the relay's ordering and at-least-once delivery: one fact per
// outbox row, in outbox order, never for an event the pipeline did not
// deliver.
type RoomEventFactPublisher struct {
	roomRepo         repository.RoomRepository
	eventRepo        repository.RoomEventRepository
	payloadConverter *models.PayloadConverter
	queueMan         queue.Manager
	queueName        string

	topicOnce sync.Once
	topic     queue.Publisher
	topicErr  error

	now func() time.Time
}

// NewRoomEventFactPublisher builds the publisher. An empty queueName disables
// publication entirely (the deployment has no consumer configured).
func NewRoomEventFactPublisher(
	roomRepo repository.RoomRepository,
	eventRepo repository.RoomEventRepository,
	queueMan queue.Manager,
	queueName string,
) *RoomEventFactPublisher {
	return &RoomEventFactPublisher{
		roomRepo:         roomRepo,
		eventRepo:        eventRepo,
		payloadConverter: models.NewPayloadConverter(),
		queueMan:         queueMan,
		queueName:        queueName,
		now:              time.Now,
	}
}

func (p *RoomEventFactPublisher) getTopic() (queue.Publisher, error) {
	p.topicOnce.Do(func() {
		p.topic, p.topicErr = p.queueMan.GetPublisher(p.queueName)
	})
	return p.topic, p.topicErr
}

// Enabled reports whether facts are published at all.
func (p *RoomEventFactPublisher) Enabled() bool {
	return p != nil && p.queueName != "" && p.queueMan != nil
}

// Publish emits the fact for one delivered outbox row. It returns nil without
// publishing when the event is ephemeral, when the room did not opt in, or
// when the payload is encrypted — chat never decrypts, so an encrypted event
// is never projected.
func (p *RoomEventFactPublisher) Publish(ctx context.Context, link *eventsv1.Link) error {
	if !p.Enabled() {
		return nil
	}
	if isEphemeralRoomEvent(link.GetEventType()) {
		return nil
	}

	groupID, err := p.groupOf(ctx, link.GetRoomId())
	if err != nil || groupID == "" {
		return err
	}

	event, err := p.eventRepo.GetByID(ctx, link.GetEventId())
	if err != nil {
		return err
	}
	payload, err := p.payloadConverter.ToProto(event.Content)
	if err != nil {
		return err
	}
	if payload.GetType() == chatv1.PayloadType_PAYLOAD_TYPE_ENCRYPTED || payload.GetEncrypted() != nil {
		return nil
	}

	topic, err := p.getTopic()
	if err != nil {
		return err
	}
	return topic.Publish(ctx, p.buildFact(link, groupID, payload),
		map[string]string{frevents.EventHeaderName: RoomEventPublishedFactName})
}

// groupOf returns the room's opted-in group id, or "" when the room did not
// opt in.
func (p *RoomEventFactPublisher) groupOf(ctx context.Context, roomID string) (string, error) {
	room, err := p.roomRepo.GetByID(ctx, roomID)
	if err != nil {
		return "", err
	}
	return groupIDFromProperties(room), nil
}

// groupIDFromProperties reads GroupMetadataKey from room metadata, accepting
// both the flat key ("stawi.group_id") and the nested form
// ({"stawi": {"group_id": ...}}) a client may have written.
func groupIDFromProperties(room *models.Room) string {
	if room == nil || room.Properties == nil {
		return ""
	}
	if value, ok := room.Properties[GroupMetadataKey].(string); ok {
		return value
	}
	nested, ok := room.Properties["stawi"].(map[string]any)
	if !ok {
		return ""
	}
	value, _ := nested["group_id"].(string)
	return value
}

func (p *RoomEventFactPublisher) buildFact(
	link *eventsv1.Link,
	groupID string,
	payload *chatv1.Payload,
) *RoomEventPublishedFact {
	fact := &RoomEventPublishedFact{
		EventID:        link.GetEventId(),
		RoomID:         link.GetRoomId(),
		GroupID:        groupID,
		SubscriptionID: link.GetSource().GetSubscriptionId(),
		ProfileID:      link.GetSource().GetContactLink().GetProfileId(),
		ParentID:       link.GetParentId(),
		RoomEventType:  link.GetEventType().String(),
		PayloadType:    payload.GetType().String(),
		SentAt:         link.GetCreatedAt().AsTime().UTC().Format(time.RFC3339Nano),
		PublishedAt:    p.now().UTC().Format(time.RFC3339Nano),
	}

	switch {
	case payload.GetVote() != nil:
		fact.Vote = &VoteFact{
			MotionID: payload.GetVote().GetMotionId(),
			ChoiceID: payload.GetVote().GetChoiceId(),
		}
	case payload.GetRoomChange() != nil:
		fact.RoomChange = &RoomChangeFact{
			Action:                payload.GetRoomChange().GetAction().String(),
			ActorSubscriptionID:   payload.GetRoomChange().GetActorSubscriptionId(),
			TargetSubscriptionIDs: payload.GetRoomChange().GetTargetSubscriptionIds(),
		}
	case payload.GetFormSubmissionResult() != nil:
		result := payload.GetFormSubmissionResult()
		fact.FormSubmissionResult = &FormSubmissionResultFact{
			FormInstanceID: result.GetFormInstanceId(),
			SchemaID:       result.GetSchemaId(),
			SchemaVersion:  result.GetSchemaVersion(),
			SourceEventID:  result.GetSourceEventId(),
			State:          result.GetState().String(),
		}
	}

	if raw, mErr := protojson.Marshal(payload); mErr == nil && len(raw) <= maxFactPayloadBytes {
		fact.Payload = raw
	} else {
		fact.PayloadTruncated = true
	}

	return fact
}
