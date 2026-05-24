package models

import (
	"context"
	"testing"
	"time"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"github.com/pitabwire/frame/data"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ---------------------------------------------------------------------------
// Room.ToAPI
// ---------------------------------------------------------------------------

func TestRoom_ToAPI_Nil(t *testing.T) {
	var r *Room
	assert.Nil(t, r.ToAPI())
}

func TestRoom_ToAPI_WithProperties(t *testing.T) {
	now := time.Now().Truncate(time.Second)
	r := &Room{
		BaseModel: data.BaseModel{
			ID:        "room-1",
			CreatedAt: now,
		},
		RoomType:         RoomTypeGroup,
		Name:             "Test Room",
		Description:      "A test room",
		Properties:       data.JSONMap{"key": "value"},
		IsPublic:         true,
		RequiresApproval: true,
	}

	api := r.ToAPI()
	require.NotNil(t, api)
	assert.Equal(t, "room-1", api.GetId())
	assert.Equal(t, "Test Room", api.GetName())
	assert.Equal(t, "A test room", api.GetDescription())
	assert.Equal(t, chatv1.RoomType_ROOM_TYPE_GROUP, api.GetType())
	assert.False(t, api.GetIsPrivate(), "IsPublic=true should produce IsPrivate=false")
	assert.True(t, api.GetRequiresApproval())
	assert.NotNil(t, api.GetMetadata())
	assert.Equal(t, "value", api.GetMetadata().GetFields()["key"].GetStringValue())
	assert.Equal(t, now.Unix(), api.GetCreatedAt().AsTime().Unix())
}

func TestRoom_ToAPI_WithoutProperties(t *testing.T) {
	r := &Room{
		BaseModel: data.BaseModel{ID: "room-2"},
		RoomType:  RoomTypeDirect,
		Name:      "DM",
		IsPublic:  false,
	}

	api := r.ToAPI()
	require.NotNil(t, api)
	assert.Nil(t, api.GetMetadata())
	assert.True(t, api.GetIsPrivate(), "IsPublic=false should produce IsPrivate=true")
	assert.False(t, api.GetRequiresApproval())
}

func TestRoom_ToAPI_AllRoomTypes(t *testing.T) {
	cases := []struct {
		roomType string
		expected chatv1.RoomType
	}{
		{RoomTypeDirect, chatv1.RoomType_ROOM_TYPE_DIRECT},
		{RoomTypeGroup, chatv1.RoomType_ROOM_TYPE_GROUP},
		{RoomTypeChannel, chatv1.RoomType_ROOM_TYPE_CHANNEL},
		{RoomTypeBot, chatv1.RoomType_ROOM_TYPE_BOT},
		{"unknown", chatv1.RoomType_ROOM_TYPE_UNSPECIFIED},
		{"", chatv1.RoomType_ROOM_TYPE_UNSPECIFIED},
	}

	for _, tc := range cases {
		t.Run("type_"+tc.roomType, func(t *testing.T) {
			r := &Room{
				BaseModel: data.BaseModel{ID: "r"},
				RoomType:  tc.roomType,
			}
			assert.Equal(t, tc.expected, r.ToAPI().GetType())
		})
	}
}

// ---------------------------------------------------------------------------
// roomTypeToAPI (exercised directly)
// ---------------------------------------------------------------------------

func TestRoomTypeToAPI(t *testing.T) {
	cases := []struct {
		input    string
		expected chatv1.RoomType
	}{
		{RoomTypeDirect, chatv1.RoomType_ROOM_TYPE_DIRECT},
		{RoomTypeGroup, chatv1.RoomType_ROOM_TYPE_GROUP},
		{RoomTypeChannel, chatv1.RoomType_ROOM_TYPE_CHANNEL},
		{RoomTypeBot, chatv1.RoomType_ROOM_TYPE_BOT},
		{"", chatv1.RoomType_ROOM_TYPE_UNSPECIFIED},
		{"foobar", chatv1.RoomType_ROOM_TYPE_UNSPECIFIED},
		{"Direct", chatv1.RoomType_ROOM_TYPE_UNSPECIFIED}, // case-sensitive
	}

	for _, tc := range cases {
		t.Run("input_"+tc.input, func(t *testing.T) {
			assert.Equal(t, tc.expected, roomTypeToAPI(tc.input))
		})
	}
}

// ---------------------------------------------------------------------------
// RoomEvent.ToAPI
// ---------------------------------------------------------------------------

func TestRoomEvent_ToAPI_Nil(t *testing.T) {
	var re *RoomEvent
	converter := NewPayloadConverter()
	assert.Nil(t, re.ToAPI(context.Background(), converter))
}

func TestRoomEvent_ToAPI_WithContent(t *testing.T) {
	now := time.Now().Truncate(time.Second)
	converter := NewPayloadConverter()

	re := &RoomEvent{
		BaseModel: data.BaseModel{
			ID:        "evt-1",
			CreatedAt: now,
		},
		RoomID:    "room-1",
		SenderID:  "sub-1",
		ParentID:  "evt-parent",
		EventType: 1, // text event type
		Content: data.JSONMap{
			PayloadTypeField: float64(chatv1.PayloadType_PAYLOAD_TYPE_TEXT.Number()),
			ContentField:     []byte(`{"body":"Hello"}`),
		},
	}

	api := re.ToAPI(context.Background(), converter)
	require.NotNil(t, api)
	assert.Equal(t, "evt-1", api.GetId())
	assert.Equal(t, "room-1", api.GetRoomId())
	assert.Equal(t, "sub-1", api.GetSubscriptionId())
	assert.Equal(t, chatv1.RoomEventType(1), api.GetType())
	assert.Equal(t, now.Unix(), api.GetSentAt().AsTime().Unix())
	require.NotNil(t, api.ParentId)
	assert.Equal(t, "evt-parent", api.GetParentId())
	require.NotNil(t, api.GetPayload())
	assert.Equal(t, chatv1.PayloadType_PAYLOAD_TYPE_TEXT, api.GetPayload().GetType())
	assert.Equal(t, "Hello", api.GetPayload().GetText().GetBody())
}

func TestRoomEvent_ToAPI_WithoutParentID(t *testing.T) {
	converter := NewPayloadConverter()
	re := &RoomEvent{
		BaseModel: data.BaseModel{
			ID:        "evt-2",
			CreatedAt: time.Now(),
		},
		RoomID:   "room-1",
		SenderID: "sub-1",
		Content: data.JSONMap{
			PayloadTypeField: float64(chatv1.PayloadType_PAYLOAD_TYPE_TEXT.Number()),
			ContentField:     []byte(`{"body":"No parent"}`),
		},
	}

	api := re.ToAPI(context.Background(), converter)
	require.NotNil(t, api)
	assert.Nil(t, api.ParentId)
}

func TestRoomEvent_ToAPI_ZeroCreatedAt(t *testing.T) {
	converter := NewPayloadConverter()
	re := &RoomEvent{
		BaseModel: data.BaseModel{ID: "evt-3"},
		RoomID:    "room-1",
		SenderID:  "sub-1",
		Content: data.JSONMap{
			PayloadTypeField: float64(chatv1.PayloadType_PAYLOAD_TYPE_TEXT.Number()),
			ContentField:     []byte(`{"body":"x"}`),
		},
	}

	api := re.ToAPI(context.Background(), converter)
	require.NotNil(t, api)
	assert.Nil(t, api.GetSentAt(), "zero CreatedAt should not produce a SentAt timestamp")
}

func TestRoomEvent_ToAPI_NilContent(t *testing.T) {
	converter := NewPayloadConverter()
	re := &RoomEvent{
		BaseModel: data.BaseModel{ID: "evt-4"},
		RoomID:    "room-1",
		SenderID:  "sub-1",
		Content:   nil, // nil content causes converter.ToProto to error
	}

	api := re.ToAPI(context.Background(), converter)
	require.NotNil(t, api)
	assert.Equal(t, "evt-4", api.GetId())
	assert.Nil(t, api.GetPayload())
}

func TestRoomEvent_ToAPI_InvalidJSONContent(t *testing.T) {
	converter := NewPayloadConverter()
	re := &RoomEvent{
		BaseModel: data.BaseModel{ID: "evt-5"},
		RoomID:    "room-1",
		SenderID:  "sub-1",
		Content: data.JSONMap{
			PayloadTypeField: float64(chatv1.PayloadType_PAYLOAD_TYPE_TEXT.Number()),
			ContentField:     []byte(`{invalid`),
		},
	}

	api := re.ToAPI(context.Background(), converter)
	require.NotNil(t, api)
	assert.Equal(t, "evt-5", api.GetId())
	assert.Nil(t, api.GetPayload())
}

// ---------------------------------------------------------------------------
// RoomSubscription.ToLink
// ---------------------------------------------------------------------------

func TestRoomSubscription_ToLink(t *testing.T) {
	rs := &RoomSubscription{
		ProfileID: "prof-1",
		ContactID: "contact-1",
	}

	link := rs.ToLink()
	require.NotNil(t, link)
	assert.Equal(t, "prof-1", link.GetProfileId())
	assert.Equal(t, "contact-1", link.GetContactId())
}

func TestRoomSubscription_ToLink_EmptyFields(t *testing.T) {
	rs := &RoomSubscription{}
	link := rs.ToLink()
	require.NotNil(t, link)
	assert.Empty(t, link.GetProfileId())
	assert.Empty(t, link.GetContactId())
}

// ---------------------------------------------------------------------------
// RoomSubscription.ToAPI
// ---------------------------------------------------------------------------

func TestRoomSubscription_ToAPI_Nil(t *testing.T) {
	var rs *RoomSubscription
	assert.Nil(t, rs.ToAPI())
}

func TestRoomSubscription_ToAPI_WithLastRead(t *testing.T) {
	now := time.Now().Truncate(time.Second)
	lastRead := now.Add(-1 * time.Hour)
	rs := &RoomSubscription{
		BaseModel: data.BaseModel{
			ID:        "sub-1",
			CreatedAt: now,
		},
		RoomID:     "room-1",
		ProfileID:  "prof-1",
		ContactID:  "contact-1",
		Role:       "admin,moderator",
		LastReadAt: lastRead.Unix(),
	}

	api := rs.ToAPI()
	require.NotNil(t, api)
	assert.Equal(t, "sub-1", api.GetId())
	assert.Equal(t, "room-1", api.GetRoomId())
	assert.Equal(t, "prof-1", api.GetMember().GetProfileId())
	assert.Equal(t, "contact-1", api.GetMember().GetContactId())
	assert.Equal(t, []string{"admin", "moderator"}, api.GetRoles())
	assert.Equal(t, now.Unix(), api.GetJoinedAt().AsTime().Unix())
	require.NotNil(t, api.GetLastActive())
	assert.Equal(t, lastRead.Unix(), api.GetLastActive().AsTime().Unix())
}

func TestRoomSubscription_ToAPI_WithoutLastRead(t *testing.T) {
	rs := &RoomSubscription{
		BaseModel:  data.BaseModel{ID: "sub-2"},
		RoomID:     "room-2",
		Role:       "member",
		LastReadAt: 0,
	}

	api := rs.ToAPI()
	require.NotNil(t, api)
	assert.Nil(t, api.GetLastActive(), "LastReadAt=0 should produce nil LastActive")
	assert.Equal(t, []string{"member"}, api.GetRoles())
}

func TestRoomSubscription_ToAPI_RolesWithCommas(t *testing.T) {
	rs := &RoomSubscription{
		BaseModel: data.BaseModel{ID: "sub-3"},
		Role:      "admin,moderator,member",
	}

	api := rs.ToAPI()
	require.NotNil(t, api)
	assert.Equal(t, []string{"admin", "moderator", "member"}, api.GetRoles())
}

func TestRoomSubscription_ToAPI_EmptyRole(t *testing.T) {
	rs := &RoomSubscription{
		BaseModel: data.BaseModel{ID: "sub-4"},
		Role:      "",
	}

	api := rs.ToAPI()
	require.NotNil(t, api)
	// strings.Split("", ",") returns [""]
	assert.Equal(t, []string{""}, api.GetRoles())
}

// ---------------------------------------------------------------------------
// RoomSubscription.ToSettings
// ---------------------------------------------------------------------------

func TestRoomSubscription_ToSettings_Nil(t *testing.T) {
	var rs *RoomSubscription
	assert.Nil(t, rs.ToSettings())
}

func TestRoomSubscription_ToSettings_AllSettings(t *testing.T) {
	rs := &RoomSubscription{
		BaseModel:         data.BaseModel{ID: "sub-1"},
		RoomID:            "room-1",
		NotificationLevel: int32(chatv1.NotificationLevel_NOTIFICATION_LEVEL_UNSPECIFIED),
		Muted:             true,
		Archived:          true,
		Pinned:            true,
	}

	s := rs.ToSettings()
	require.NotNil(t, s)
	assert.Equal(t, "sub-1", s.GetSubscriptionId())
	assert.Equal(t, "room-1", s.GetRoomId())
	assert.Equal(t, chatv1.NotificationLevel_NOTIFICATION_LEVEL_UNSPECIFIED, s.GetNotificationLevel())
	assert.True(t, s.GetMuted())
	assert.True(t, s.GetArchived())
	assert.True(t, s.GetPinned())
}

func TestRoomSubscription_ToSettings_Defaults(t *testing.T) {
	rs := &RoomSubscription{
		BaseModel: data.BaseModel{ID: "sub-2"},
		RoomID:    "room-2",
	}

	s := rs.ToSettings()
	require.NotNil(t, s)
	assert.False(t, s.GetMuted())
	assert.False(t, s.GetArchived())
	assert.False(t, s.GetPinned())
	assert.Equal(t, chatv1.NotificationLevel(0), s.GetNotificationLevel())
}

// ---------------------------------------------------------------------------
// RoomSubscription.IsActive
// ---------------------------------------------------------------------------

func TestRoomSubscription_IsActive(t *testing.T) {
	cases := []struct {
		name     string
		state    RoomSubscriptionState
		expected bool
	}{
		{"active", RoomSubscriptionStateActive, true},
		{"proposed", RoomSubscriptionStateProposed, false},
		{"blocked", RoomSubscriptionStateBlocked, false},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			rs := &RoomSubscription{SubscriptionState: tc.state}
			assert.Equal(t, tc.expected, rs.IsActive())
		})
	}
}

// ---------------------------------------------------------------------------
// RoomSubscription.Matches
// ---------------------------------------------------------------------------

func TestRoomSubscription_Matches_NilContact(t *testing.T) {
	rs := &RoomSubscription{ProfileID: "prof-1", ContactID: "contact-1"}
	assert.False(t, rs.Matches(nil))
}

func TestRoomSubscription_Matches_MatchingProfile(t *testing.T) {
	rs := &RoomSubscription{ProfileID: "prof-1"}
	link := &commonv1.ContactLink{ProfileId: "prof-1"}
	assert.True(t, rs.Matches(link))
}

func TestRoomSubscription_Matches_MatchingContact(t *testing.T) {
	rs := &RoomSubscription{ContactID: "contact-1"}
	link := &commonv1.ContactLink{ContactId: "contact-1"}
	assert.True(t, rs.Matches(link))
}

func TestRoomSubscription_Matches_MismatchingProfile(t *testing.T) {
	rs := &RoomSubscription{ProfileID: "prof-1"}
	link := &commonv1.ContactLink{ProfileId: "prof-2"}
	assert.False(t, rs.Matches(link))
}

func TestRoomSubscription_Matches_MismatchingContact(t *testing.T) {
	rs := &RoomSubscription{ContactID: "contact-1"}
	link := &commonv1.ContactLink{ContactId: "contact-2"}
	assert.False(t, rs.Matches(link))
}

func TestRoomSubscription_Matches_EmptySubscriptionFields(t *testing.T) {
	// Both ProfileID and ContactID empty on subscription -> matches anything
	rs := &RoomSubscription{}
	link := &commonv1.ContactLink{ProfileId: "prof-1", ContactId: "contact-1"}
	assert.True(t, rs.Matches(link))
}

func TestRoomSubscription_Matches_EmptyLinkFields(t *testing.T) {
	// Both ProfileId and ContactId empty on link -> matches anything
	rs := &RoomSubscription{ProfileID: "prof-1", ContactID: "contact-1"}
	link := &commonv1.ContactLink{}
	assert.True(t, rs.Matches(link))
}

func TestRoomSubscription_Matches_ProfileMatchContactMismatch(t *testing.T) {
	rs := &RoomSubscription{ProfileID: "prof-1", ContactID: "contact-1"}
	link := &commonv1.ContactLink{ProfileId: "prof-1", ContactId: "contact-2"}
	assert.False(t, rs.Matches(link))
}

func TestRoomSubscription_Matches_ProfileMismatchContactMatch(t *testing.T) {
	rs := &RoomSubscription{ProfileID: "prof-1", ContactID: "contact-1"}
	link := &commonv1.ContactLink{ProfileId: "prof-2", ContactId: "contact-1"}
	assert.False(t, rs.Matches(link))
}

func TestRoomSubscription_Matches_BothMatch(t *testing.T) {
	rs := &RoomSubscription{ProfileID: "prof-1", ContactID: "contact-1"}
	link := &commonv1.ContactLink{ProfileId: "prof-1", ContactId: "contact-1"}
	assert.True(t, rs.Matches(link))
}

// ---------------------------------------------------------------------------
// Proposal.IsPending
// ---------------------------------------------------------------------------

func TestProposal_IsPending(t *testing.T) {
	cases := []struct {
		name     string
		state    ProposalState
		expected bool
	}{
		{"pending", ProposalStatePending, true},
		{"approved", ProposalStateApproved, false},
		{"rejected", ProposalStateRejected, false},
		{"expired", ProposalStateExpired, false},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			p := &Proposal{State: tc.state}
			assert.Equal(t, tc.expected, p.IsPending())
		})
	}
}

// ---------------------------------------------------------------------------
// Proposal.IsExpired
// ---------------------------------------------------------------------------

func TestProposal_IsExpired(t *testing.T) {
	t.Run("expired", func(t *testing.T) {
		p := &Proposal{ExpiresAt: time.Now().Add(-1 * time.Hour)}
		assert.True(t, p.IsExpired())
	})

	t.Run("not expired", func(t *testing.T) {
		p := &Proposal{ExpiresAt: time.Now().Add(1 * time.Hour)}
		assert.False(t, p.IsExpired())
	})

	t.Run("just expired - zero time", func(t *testing.T) {
		// Zero time is in the past, so it should be expired
		p := &Proposal{}
		assert.True(t, p.IsExpired())
	})
}
