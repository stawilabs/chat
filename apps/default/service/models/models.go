package models

import (
	"context"
	"errors"
	"strings"
	"time"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"github.com/pitabwire/frame/data"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/structpb"
	"google.golang.org/protobuf/types/known/timestamppb"
)

// Room represents a chat room entity.
type Room struct {
	data.BaseModel
	RoomType         string `json:"room_type"`
	Name             string `json:"name"`
	Description      string `json:"description"`
	Properties       data.JSONMap
	IsPublic         bool
	RequiresApproval bool
}

// ToAPI converts Room model to API representation.
func (r *Room) ToAPI() *chatv1.Room {
	if r == nil {
		return nil
	}

	var metadata *structpb.Struct
	if r.Properties != nil {
		metadata, _ = structpb.NewStruct(r.Properties)
	}

	protoRoom := &chatv1.Room{
		Id:               r.GetID(),
		Name:             r.Name,
		Description:      r.Description,
		Type:             roomTypeToAPI(r.RoomType),
		IsPrivate:        !r.IsPublic,
		RequiresApproval: r.RequiresApproval,
		Metadata:         metadata,
		CreatedAt:        timestamppb.New(r.CreatedAt),
	}

	return protoRoom
}

const (
	RoomTypeDirect  = "direct"
	RoomTypeGroup   = "group"
	RoomTypeChannel = "channel"
	RoomTypeBot     = "bot"
)

func roomTypeToAPI(roomType string) chatv1.RoomType {
	switch roomType {
	case RoomTypeDirect:
		return chatv1.RoomType_ROOM_TYPE_DIRECT
	case RoomTypeGroup:
		return chatv1.RoomType_ROOM_TYPE_GROUP
	case RoomTypeChannel:
		return chatv1.RoomType_ROOM_TYPE_CHANNEL
	case RoomTypeBot:
		return chatv1.RoomType_ROOM_TYPE_BOT
	default:
		return chatv1.RoomType_ROOM_TYPE_UNSPECIFIED
	}
}

// RoomCall represents a call session in a room.
type RoomCall struct {
	data.BaseModel
	RoomID    string `gorm:"type:varchar(50)"`
	CallID    string `gorm:"type:varchar(50)"`
	SFUNodeID string `gorm:"type:varchar(250)"`
	Status    string // ringing, active, ended
	StartedAt time.Time
	EndedAt   time.Time
	Metadata  data.JSONMap
}

// RoomEvent represents a message or event in a room.
// The ID field (from BaseModel) is naturally time-sorted and used for ordering.
type RoomEvent struct {
	data.BaseModel
	RoomID     string `gorm:"type:varchar(50);index:idx_room_id"`
	SenderID   string `gorm:"type:varchar(50)"`
	ParentID   string `gorm:"type:varchar(50)"`
	EventType  int32
	Content    data.JSONMap
	Properties data.JSONMap
}

// ToAPI converts RoomEvent model to API RoomEvent representation.
func (re *RoomEvent) ToAPI(_ context.Context, converter *PayloadConverter) *chatv1.RoomEvent {
	if re == nil {
		return nil
	}

	// Use PayloadConverter for complete conversion with typed content
	protoEvent := &chatv1.RoomEvent{
		Id:             re.ID,
		RoomId:         re.RoomID,
		SubscriptionId: re.SenderID,
		Type:           chatv1.RoomEventType(re.EventType),
	}

	// Set timestamp if available
	if !re.CreatedAt.IsZero() {
		protoEvent.SentAt = timestamppb.New(re.CreatedAt)
	}

	// Set parent ID if present
	if re.ParentID != "" {
		parentID := re.ParentID
		protoEvent.ParentId = &parentID
	}

	if converter != nil && re.Content != nil {
		payload, err := converter.ToProto(re.Content)
		if err == nil {
			protoEvent.Payload = payload
		}
	}

	return protoEvent
}

type RoomSubscriptionState int

const (
	RoomSubscriptionStateProposed RoomSubscriptionState = iota
	RoomSubscriptionStateActive
	RoomSubscriptionStateBlocked
)

// RoomSubscription represents a user's subscription to a room.
type RoomSubscription struct {
	data.BaseModel
	// NOTE: the (room_id, profile_id, contact_id) uniqueness is enforced by a
	// PARTIAL unique index (idx_room_subscription_unique_active) defined in SQL
	// migrations, scoped to active/proposed states so a blocked member can be
	// re-added. It must NOT be declared as a GORM uniqueIndex tag here: AutoMigrate
	// runs before SQL migrations and would create a FULL (predicate-less) index of
	// the same name, shadowing the partial one and blocking re-adds.
	RoomID              string `gorm:"type:varchar(50);index:idx_roomsubscription_room_id_subscription_state"`
	ProfileID           string `gorm:"type:varchar(50)"`
	ContactID           string `gorm:"type:varchar(50)"`
	Role                string
	SubscriptionState   RoomSubscriptionState `gorm:"index:idx_roomsubscription_room_id_subscription_state"`
	LastReadEventID     string                `gorm:"type:varchar(50)"` // ID of the last read event (naturally time-sorted)
	LastReadAt          int64
	DisableNotification bool
	NotificationLevel   int32
	Muted               bool
	Archived            bool
	Pinned              bool
	Properties          data.JSONMap
}

func (rs *RoomSubscription) ToLink() *commonv1.ContactLink {
	return &commonv1.ContactLink{
		ProfileId: rs.ProfileID,
		ContactId: rs.ContactID,
	}
}

// ToAPI converts RoomSubscription model to API representation.
func (rs *RoomSubscription) ToAPI() *chatv1.RoomSubscription {
	if rs == nil {
		return nil
	}

	var lastActive *timestamppb.Timestamp
	if rs.LastReadAt > 0 {
		lastActive = timestamppb.New(time.Unix(rs.LastReadAt, 0))
	}

	return &chatv1.RoomSubscription{
		Id:         rs.GetID(),
		RoomId:     rs.RoomID,
		Member:     rs.ToLink(),
		Roles:      strings.Split(rs.Role, ","),
		JoinedAt:   timestamppb.New(rs.CreatedAt),
		LastActive: lastActive,
	}
}

// ToSettings converts RoomSubscription model to API SubscriptionSettings representation.
func (rs *RoomSubscription) ToSettings() *chatv1.SubscriptionSettings {
	if rs == nil {
		return nil
	}

	return &chatv1.SubscriptionSettings{
		SubscriptionId:    rs.GetID(),
		RoomId:            rs.RoomID,
		NotificationLevel: chatv1.NotificationLevel(rs.NotificationLevel),
		Muted:             rs.Muted,
		Archived:          rs.Archived,
		Pinned:            rs.Pinned,
	}
}

func (rs *RoomSubscription) IsActive() bool {
	return RoomSubscriptionStateActive == rs.SubscriptionState
}

func (rs *RoomSubscription) Matches(contactLink *commonv1.ContactLink) bool {
	if contactLink == nil {
		return false
	}

	if rs.ProfileID != "" && contactLink.GetProfileId() != "" &&
		rs.ProfileID != contactLink.GetProfileId() {
		return false
	}

	if rs.ContactID != "" && contactLink.GetContactId() != "" &&
		rs.ContactID != contactLink.GetContactId() {
		return false
	}

	return true
}

// ProposalScopeType constants define the entity type a proposal applies to.
const (
	ProposalScopeRoom = "room"
)

// ProposalType represents the kind of change being proposed.
// New types can be added for non-room proposals to reuse the voting framework.
type ProposalType int

const (
	ProposalTypeUpdateRoom ProposalType = iota + 1
	ProposalTypeDeleteRoom
	ProposalTypeAddSubscriptions
	ProposalTypeRemoveSubscriptions
	ProposalTypeUpdateSubscriptionRole
)

// ProposalState represents the current state of a proposal.
type ProposalState int

const (
	ProposalStatePending ProposalState = iota
	ProposalStateApproved
	ProposalStateRejected
	ProposalStateExpired
)

// Proposal represents a pending change that requires approval before execution.
// The ScopeType and ScopeID fields allow this model to be reused for different
// kinds of proposals beyond room changes (e.g., org-level changes, policy votes).
type Proposal struct {
	data.BaseModel
	ScopeType    string       `gorm:"type:varchar(50);index:idx_proposal_scope_state"`
	ScopeID      string       `gorm:"type:varchar(50);index:idx_proposal_scope_state"`
	ProposalType ProposalType `gorm:"index:idx_proposal_type"`
	RequestedBy  string       `gorm:"type:varchar(50)"`
	Payload      data.JSONMap
	State        ProposalState `gorm:"index:idx_proposal_scope_state"`
	ResolvedBy   string        `gorm:"type:varchar(50)"`
	ResolvedAt   *time.Time
	Reason       string
	ExpiresAt    time.Time `gorm:"index:idx_proposal_expires"`
}

// DeviceReplayEvent stores the durable per-device replay log used by gateway
// resume logic. The primary key is the replay cursor exposed to clients.
type DeviceReplayEvent struct {
	data.BaseModel
	ProfileID    string `gorm:"type:varchar(50);index:idx_device_replay_lookup,priority:1;uniqueIndex:idx_device_replay_profile_device_event"`
	DeviceID     string `gorm:"type:varchar(50);index:idx_device_replay_lookup,priority:2;uniqueIndex:idx_device_replay_profile_device_event"`
	EventID      string `gorm:"type:varchar(50);uniqueIndex:idx_device_replay_profile_device_event"`
	RoomID       string `gorm:"type:varchar(50)"`
	EventType    int32
	ResponseData []byte `gorm:"type:bytea;not null"`
}

var ErrNilDeviceReplayEvent = errors.New("device replay event is nil")

func (dre *DeviceReplayEvent) ToStreamResponse() (*chatv1.StreamResponse, error) {
	if dre == nil {
		return nil, ErrNilDeviceReplayEvent
	}

	response := &chatv1.StreamResponse{}
	if err := proto.Unmarshal(dre.ResponseData, response); err != nil {
		return nil, err
	}

	return response, nil
}

// IsPending returns true if the proposal is still pending.
func (p *Proposal) IsPending() bool {
	return p.State == ProposalStatePending
}

// IsExpired returns true if the proposal has passed its expiry time.
func (p *Proposal) IsExpired() bool {
	return time.Now().After(p.ExpiresAt)
}

// RoomOutbox is the transactional-outbox record for a room event. It is written
// in the SAME transaction as the RoomEvent so delivery intent is durable even if
// the process crashes between persisting the event and publishing it to the
// delivery pipeline. A relay drains undispatched rows as a safety net behind the
// optimistic inline emit (see WS-B design). EventID is unique so an event has at
// most one outbox row (idempotent re-saves).
type RoomOutbox struct {
	data.BaseModel
	EventID      string `gorm:"type:varchar(50);uniqueIndex:idx_room_outbox_event"`
	RoomID       string `gorm:"type:varchar(50);index"`
	Payload      []byte `gorm:"type:bytea;not null"` // protojson-encoded eventsv1.Link
	Dispatched   bool   `gorm:"index:idx_room_outbox_dispatched"`
	DispatchedAt int64
}

// TableName returns the database table name for RoomOutbox.
func (RoomOutbox) TableName() string { return "room_outbox" }

// DeadLetterEvent is a durable record of a message that exhausted its retries
// and was dead-lettered. Persisting it (instead of only logging + ACKing) keeps
// failed deliveries available for forensics and manual replay rather than being
// lost after the log rotates. Operators should apply a retention policy.
type DeadLetterEvent struct {
	data.BaseModel
	OriginalQueue string `gorm:"type:varchar(255);index"`
	ErrorMessage  string `gorm:"type:text"`
	Payload       []byte `gorm:"type:bytea"`
	Headers       data.JSONMap
}

// TableName returns the database table name for DeadLetterEvent.
func (DeadLetterEvent) TableName() string { return "dead_letter_events" }
