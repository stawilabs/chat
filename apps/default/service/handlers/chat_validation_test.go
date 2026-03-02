package handlers_test

import (
	"context"
	"errors"
	"testing"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	"connectrpc.com/connect"
	"github.com/antinvestor/service-chat/apps/default/service"
	"github.com/antinvestor/service-chat/apps/default/service/handlers"
	"github.com/antinvestor/service-chat/apps/default/service/models"
	"github.com/pitabwire/frame/security"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// --- Mock business implementations for lightweight tests ---

// mockRoomBusiness implements business.RoomBusiness for controlled test results.
type mockRoomBusiness struct {
	createRoomFn              func(ctx context.Context, req *chatv1.CreateRoomRequest, createdBy *commonv1.ContactLink) (*chatv1.Room, error)
	getRoomFn                 func(ctx context.Context, roomID string, searchedBy *commonv1.ContactLink) (*chatv1.Room, error)
	updateRoomFn              func(ctx context.Context, req *chatv1.UpdateRoomRequest, updatedBy *commonv1.ContactLink) (*chatv1.Room, error)
	deleteRoomFn              func(ctx context.Context, req *chatv1.DeleteRoomRequest, deletedBy *commonv1.ContactLink) error
	searchRoomsFn             func(ctx context.Context, req *chatv1.SearchRoomsRequest, searchedBy *commonv1.ContactLink) ([]*chatv1.Room, error)
	addRoomSubscriptionsFn    func(ctx context.Context, req *chatv1.AddRoomSubscriptionsRequest, addedBy *commonv1.ContactLink) error
	removeRoomSubscriptionsFn func(ctx context.Context, req *chatv1.RemoveRoomSubscriptionsRequest, removedBy *commonv1.ContactLink) error
	updateSubscriptionRoleFn  func(ctx context.Context, req *chatv1.UpdateSubscriptionRoleRequest, updatedBy *commonv1.ContactLink) error
	searchRoomSubsFn          func(ctx context.Context, req *chatv1.SearchRoomSubscriptionsRequest, searchedBy *commonv1.ContactLink) ([]*chatv1.RoomSubscription, error)
	getSubForContactFn        func(ctx context.Context, roomID string, contact *commonv1.ContactLink) (*models.RoomSubscription, error)
	updateSubSettingsFn       func(ctx context.Context, req *chatv1.UpdateSubscriptionSettingsRequest, updatedBy *commonv1.ContactLink) (*chatv1.SubscriptionSettings, error)
}

func (m *mockRoomBusiness) CreateRoom(
	ctx context.Context,
	req *chatv1.CreateRoomRequest,
	createdBy *commonv1.ContactLink,
) (*chatv1.Room, error) {
	if m.createRoomFn != nil {
		return m.createRoomFn(ctx, req, createdBy)
	}
	return nil, errors.New("not implemented")
}

func (m *mockRoomBusiness) GetRoom(
	ctx context.Context,
	roomID string,
	searchedBy *commonv1.ContactLink,
) (*chatv1.Room, error) {
	if m.getRoomFn != nil {
		return m.getRoomFn(ctx, roomID, searchedBy)
	}
	return nil, errors.New("not implemented")
}

func (m *mockRoomBusiness) UpdateRoom(
	ctx context.Context,
	req *chatv1.UpdateRoomRequest,
	updatedBy *commonv1.ContactLink,
) (*chatv1.Room, error) {
	if m.updateRoomFn != nil {
		return m.updateRoomFn(ctx, req, updatedBy)
	}
	return nil, errors.New("not implemented")
}

func (m *mockRoomBusiness) DeleteRoom(
	ctx context.Context,
	req *chatv1.DeleteRoomRequest,
	deletedBy *commonv1.ContactLink,
) error {
	if m.deleteRoomFn != nil {
		return m.deleteRoomFn(ctx, req, deletedBy)
	}
	return errors.New("not implemented")
}

func (m *mockRoomBusiness) SearchRooms(
	ctx context.Context,
	req *chatv1.SearchRoomsRequest,
	searchedBy *commonv1.ContactLink,
) ([]*chatv1.Room, error) {
	if m.searchRoomsFn != nil {
		return m.searchRoomsFn(ctx, req, searchedBy)
	}
	return nil, errors.New("not implemented")
}

func (m *mockRoomBusiness) AddRoomSubscriptions(
	ctx context.Context,
	req *chatv1.AddRoomSubscriptionsRequest,
	addedBy *commonv1.ContactLink,
) error {
	if m.addRoomSubscriptionsFn != nil {
		return m.addRoomSubscriptionsFn(ctx, req, addedBy)
	}
	return errors.New("not implemented")
}

func (m *mockRoomBusiness) RemoveRoomSubscriptions(
	ctx context.Context,
	req *chatv1.RemoveRoomSubscriptionsRequest,
	removedBy *commonv1.ContactLink,
) error {
	if m.removeRoomSubscriptionsFn != nil {
		return m.removeRoomSubscriptionsFn(ctx, req, removedBy)
	}
	return errors.New("not implemented")
}

func (m *mockRoomBusiness) UpdateSubscriptionRole(
	ctx context.Context,
	req *chatv1.UpdateSubscriptionRoleRequest,
	updatedBy *commonv1.ContactLink,
) error {
	if m.updateSubscriptionRoleFn != nil {
		return m.updateSubscriptionRoleFn(ctx, req, updatedBy)
	}
	return errors.New("not implemented")
}

func (m *mockRoomBusiness) SearchRoomSubscriptions(
	ctx context.Context,
	req *chatv1.SearchRoomSubscriptionsRequest,
	searchedBy *commonv1.ContactLink,
) ([]*chatv1.RoomSubscription, error) {
	if m.searchRoomSubsFn != nil {
		return m.searchRoomSubsFn(ctx, req, searchedBy)
	}
	return nil, errors.New("not implemented")
}

func (m *mockRoomBusiness) GetSubscriptionForContact(
	ctx context.Context,
	roomID string,
	contact *commonv1.ContactLink,
) (*models.RoomSubscription, error) {
	if m.getSubForContactFn != nil {
		return m.getSubForContactFn(ctx, roomID, contact)
	}
	return nil, errors.New("not implemented")
}

func (m *mockRoomBusiness) UpdateSubscriptionSettings(
	ctx context.Context,
	req *chatv1.UpdateSubscriptionSettingsRequest,
	updatedBy *commonv1.ContactLink,
) (*chatv1.SubscriptionSettings, error) {
	if m.updateSubSettingsFn != nil {
		return m.updateSubSettingsFn(ctx, req, updatedBy)
	}
	return nil, errors.New("not implemented")
}

// mockMessageBusiness implements business.MessageBusiness for controlled test results.
type mockMessageBusiness struct {
	sendEventsFn    func(ctx context.Context, req *chatv1.SendEventRequest, sentBy *commonv1.ContactLink) ([]*chatv1.AckEvent, error)
	getMessageFn    func(ctx context.Context, messageID string, gottenBy *commonv1.ContactLink) (*models.RoomEvent, error)
	getHistoryFn    func(ctx context.Context, req *chatv1.GetHistoryRequest, gottenBy *commonv1.ContactLink) ([]*chatv1.RoomEvent, error)
	deleteMessageFn func(ctx context.Context, messageID string, deletedBy *commonv1.ContactLink) error
	markReadFn      func(ctx context.Context, roomID string, eventID string, markedBy *commonv1.ContactLink) error
}

func (m *mockMessageBusiness) SendEvents(
	ctx context.Context,
	req *chatv1.SendEventRequest,
	sentBy *commonv1.ContactLink,
) ([]*chatv1.AckEvent, error) {
	if m.sendEventsFn != nil {
		return m.sendEventsFn(ctx, req, sentBy)
	}
	return nil, errors.New("not implemented")
}

func (m *mockMessageBusiness) GetMessage(
	ctx context.Context,
	messageID string,
	gottenBy *commonv1.ContactLink,
) (*models.RoomEvent, error) {
	if m.getMessageFn != nil {
		return m.getMessageFn(ctx, messageID, gottenBy)
	}
	return nil, errors.New("not implemented")
}

func (m *mockMessageBusiness) GetHistory(
	ctx context.Context,
	req *chatv1.GetHistoryRequest,
	gottenBy *commonv1.ContactLink,
) ([]*chatv1.RoomEvent, error) {
	if m.getHistoryFn != nil {
		return m.getHistoryFn(ctx, req, gottenBy)
	}
	return nil, errors.New("not implemented")
}

func (m *mockMessageBusiness) DeleteMessage(
	ctx context.Context,
	messageID string,
	deletedBy *commonv1.ContactLink,
) error {
	if m.deleteMessageFn != nil {
		return m.deleteMessageFn(ctx, messageID, deletedBy)
	}
	return errors.New("not implemented")
}

func (m *mockMessageBusiness) MarkMessagesAsRead(
	ctx context.Context,
	roomID string,
	eventID string,
	markedBy *commonv1.ContactLink,
) error {
	if m.markReadFn != nil {
		return m.markReadFn(ctx, roomID, eventID, markedBy)
	}
	return errors.New("not implemented")
}

// mockConnectBusiness implements business.ClientStateBusiness for controlled test results.
type mockConnectBusiness struct {
	updatePresenceFn        func(ctx context.Context, status *chatv1.PresenceEvent) error
	updateTypingFn          func(ctx context.Context, roomID string, reader *commonv1.ContactLink, isTyping bool) error
	updateDeliveryReceiptFn func(ctx context.Context, roomID string, reader *commonv1.ContactLink, eventID ...string) error
	updateReadMarkerFn      func(ctx context.Context, roomID string, reader *commonv1.ContactLink, eventID string) error
}

func (m *mockConnectBusiness) UpdatePresence(ctx context.Context, status *chatv1.PresenceEvent) error {
	if m.updatePresenceFn != nil {
		return m.updatePresenceFn(ctx, status)
	}
	return errors.New("not implemented")
}

func (m *mockConnectBusiness) UpdateTypingIndicator(
	ctx context.Context,
	roomID string,
	reader *commonv1.ContactLink,
	isTyping bool,
) error {
	if m.updateTypingFn != nil {
		return m.updateTypingFn(ctx, roomID, reader, isTyping)
	}
	return errors.New("not implemented")
}

func (m *mockConnectBusiness) UpdateDeliveryReceipt(
	ctx context.Context,
	roomID string,
	reader *commonv1.ContactLink,
	eventID ...string,
) error {
	if m.updateDeliveryReceiptFn != nil {
		return m.updateDeliveryReceiptFn(ctx, roomID, reader, eventID...)
	}
	return errors.New("not implemented")
}

func (m *mockConnectBusiness) UpdateReadMarker(
	ctx context.Context,
	roomID string,
	reader *commonv1.ContactLink,
	eventID string,
) error {
	if m.updateReadMarkerFn != nil {
		return m.updateReadMarkerFn(ctx, roomID, reader, eventID)
	}
	return errors.New("not implemented")
}

// mockProposalManagement implements business.ProposalManagement for controlled test results.
type mockProposalManagement struct {
	approveFn     func(ctx context.Context, scopeID, proposalID string, approvedBy *commonv1.ContactLink) error
	rejectFn      func(ctx context.Context, scopeID, proposalID, reason string, rejectedBy *commonv1.ContactLink) error
	listPendingFn func(ctx context.Context, scopeID string, searchedBy *commonv1.ContactLink) ([]*models.Proposal, error)
}

func (m *mockProposalManagement) Approve(
	ctx context.Context,
	scopeID, proposalID string,
	approvedBy *commonv1.ContactLink,
) error {
	if m.approveFn != nil {
		return m.approveFn(ctx, scopeID, proposalID, approvedBy)
	}
	return errors.New("not implemented")
}

func (m *mockProposalManagement) Reject(
	ctx context.Context,
	scopeID, proposalID, reason string,
	rejectedBy *commonv1.ContactLink,
) error {
	if m.rejectFn != nil {
		return m.rejectFn(ctx, scopeID, proposalID, reason, rejectedBy)
	}
	return errors.New("not implemented")
}

func (m *mockProposalManagement) ListPending(
	ctx context.Context,
	scopeID string,
	searchedBy *commonv1.ContactLink,
) ([]*models.Proposal, error) {
	if m.listPendingFn != nil {
		return m.listPendingFn(ctx, scopeID, searchedBy)
	}
	return nil, errors.New("not implemented")
}

// strPtr returns a pointer to the given string value.
func strPtr(s string) *string { return &s }

// lightweightAuthCtx creates a context with auth claims but no real service.
// Suitable for tests that exercise validation paths before business logic.
func lightweightAuthCtx() context.Context {
	claims := &security.AuthenticationClaims{
		TenantID:    testTenantID,
		PartitionID: testPartitionID,
		AccessID:    util.IDString(),
		ContactID:   util.IDString(),
		SessionID:   util.IDString(),
		DeviceID:    "test-device",
	}
	claims.Subject = claims.ContactID
	return claims.ClaimsToContext(context.Background())
}

// lightweightSystemCtx creates a context with system_internal role claims.
func lightweightSystemCtx() context.Context {
	claims := &security.AuthenticationClaims{
		TenantID:    testTenantID,
		PartitionID: testPartitionID,
		AccessID:    util.IDString(),
		ContactID:   util.IDString(),
		SessionID:   util.IDString(),
		DeviceID:    "test-device",
		Roles:       []string{"system_internal"},
	}
	claims.Subject = claims.ContactID
	return claims.ClaimsToContext(context.Background())
}

// --- SendEvent validation ---

func TestSendEvent_EmptyEvents(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightAuthCtx()
	_, err := chatServer.SendEvent(ctx, connect.NewRequest(&chatv1.SendEventRequest{
		Event: []*chatv1.RoomEvent{},
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
}

func TestSendEvent_TooManyEvents(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightAuthCtx()
	events := make([]*chatv1.RoomEvent, 51)
	for i := range events {
		events[i] = &chatv1.RoomEvent{
			RoomId:  util.IDString(),
			Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
			Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "msg"}}},
		}
	}
	_, err := chatServer.SendEvent(ctx, connect.NewRequest(&chatv1.SendEventRequest{Event: events}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
}

func TestSendEvent_Unauthenticated(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	_, err := chatServer.SendEvent(context.Background(), connect.NewRequest(&chatv1.SendEventRequest{
		Event: []*chatv1.RoomEvent{{
			RoomId:  util.IDString(),
			Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
			Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "msg"}}},
		}},
	}))
	require.Error(t, err)
}

// --- GetHistory validation ---

func TestGetHistory_EmptyRoomID(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightAuthCtx()
	_, err := chatServer.GetHistory(ctx, connect.NewRequest(&chatv1.GetHistoryRequest{RoomId: ""}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
}

func TestGetHistory_Unauthenticated(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	_, err := chatServer.GetHistory(context.Background(), connect.NewRequest(&chatv1.GetHistoryRequest{
		RoomId: util.IDString(),
	}))
	require.Error(t, err)
}

// --- GetEvent validation ---

func TestGetEvent_Unauthenticated(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	_, err := chatServer.GetEvent(context.Background(), connect.NewRequest(&chatv1.GetEventRequest{
		EventId: util.IDString(),
	}))
	require.Error(t, err)
}

func TestGetEvent_EmptyEventID(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightAuthCtx()
	_, err := chatServer.GetEvent(ctx, connect.NewRequest(&chatv1.GetEventRequest{EventId: ""}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
}

// --- GetRoom validation ---

func TestGetRoom_Unauthenticated(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	_, err := chatServer.GetRoom(context.Background(), connect.NewRequest(&chatv1.GetRoomRequest{
		RoomId: util.IDString(),
	}))
	require.Error(t, err)
}

func TestGetRoom_EmptyRoomID(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightAuthCtx()
	_, err := chatServer.GetRoom(ctx, connect.NewRequest(&chatv1.GetRoomRequest{RoomId: ""}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
}

// --- SearchRooms validation ---

func TestSearchRooms_Unauthenticated(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	err := chatServer.SearchRooms(context.Background(),
		connect.NewRequest(&chatv1.SearchRoomsRequest{Query: "test"}), nil)
	require.Error(t, err)
}

// --- CreateRoom validation ---

func TestCreateRoom_Unauthenticated(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	_, err := chatServer.CreateRoom(context.Background(), connect.NewRequest(&chatv1.CreateRoomRequest{
		Name: "Test Room",
	}))
	require.Error(t, err)
}

// --- UpdateRoom validation ---

func TestUpdateRoom_EmptyRoomID(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightAuthCtx()
	_, err := chatServer.UpdateRoom(ctx, connect.NewRequest(&chatv1.UpdateRoomRequest{
		RoomId: "",
		Name:   "Updated Name",
	}))
	require.Error(t, err)
}

func TestUpdateRoom_Unauthenticated(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	_, err := chatServer.UpdateRoom(context.Background(), connect.NewRequest(&chatv1.UpdateRoomRequest{
		RoomId: util.IDString(),
		Name:   "Updated Name",
	}))
	require.Error(t, err)
}

// --- DeleteRoom validation ---

func TestDeleteRoom_EmptyRoomID(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightAuthCtx()
	_, err := chatServer.DeleteRoom(ctx, connect.NewRequest(&chatv1.DeleteRoomRequest{RoomId: ""}))
	require.Error(t, err)
}

func TestDeleteRoom_Unauthenticated(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	_, err := chatServer.DeleteRoom(context.Background(), connect.NewRequest(&chatv1.DeleteRoomRequest{
		RoomId: util.IDString(),
	}))
	require.Error(t, err)
}

// --- AddRoomSubscriptions validation ---

func TestAddRoomSubscriptions_EmptyRoomID(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightAuthCtx()
	_, err := chatServer.AddRoomSubscriptions(ctx, connect.NewRequest(&chatv1.AddRoomSubscriptionsRequest{
		RoomId:  "",
		Members: []*chatv1.RoomSubscription{},
	}))
	require.Error(t, err)
}

func TestAddRoomSubscriptions_Unauthenticated(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	_, err := chatServer.AddRoomSubscriptions(
		context.Background(),
		connect.NewRequest(&chatv1.AddRoomSubscriptionsRequest{
			RoomId: util.IDString(),
		}),
	)
	require.Error(t, err)
}

// --- RemoveRoomSubscriptions validation ---

func TestRemoveRoomSubscriptions_EmptyRoomID(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightAuthCtx()
	_, err := chatServer.RemoveRoomSubscriptions(ctx, connect.NewRequest(&chatv1.RemoveRoomSubscriptionsRequest{
		RoomId:         "",
		SubscriptionId: []string{util.IDString()},
	}))
	require.Error(t, err)
}

func TestRemoveRoomSubscriptions_Unauthenticated(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	_, err := chatServer.RemoveRoomSubscriptions(
		context.Background(),
		connect.NewRequest(&chatv1.RemoveRoomSubscriptionsRequest{
			RoomId:         util.IDString(),
			SubscriptionId: []string{util.IDString()},
		}),
	)
	require.Error(t, err)
}

// --- UpdateSubscriptionRole validation ---

func TestUpdateSubscriptionRole_EmptyRoomID(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightAuthCtx()
	_, err := chatServer.UpdateSubscriptionRole(ctx, connect.NewRequest(&chatv1.UpdateSubscriptionRoleRequest{
		RoomId:         "",
		SubscriptionId: util.IDString(),
		Roles:          []string{"moderator"},
	}))
	require.Error(t, err)
}

func TestUpdateSubscriptionRole_Unauthenticated(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	_, err := chatServer.UpdateSubscriptionRole(
		context.Background(),
		connect.NewRequest(&chatv1.UpdateSubscriptionRoleRequest{
			RoomId:         util.IDString(),
			SubscriptionId: util.IDString(),
			Roles:          []string{"moderator"},
		}),
	)
	require.Error(t, err)
}

// --- SearchRoomSubscriptions validation ---

func TestSearchRoomSubscriptions_EmptyRoomID(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightAuthCtx()
	_, err := chatServer.SearchRoomSubscriptions(ctx, connect.NewRequest(&chatv1.SearchRoomSubscriptionsRequest{
		RoomId: "",
	}))
	require.Error(t, err)
}

func TestSearchRoomSubscriptions_Unauthenticated(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	_, err := chatServer.SearchRoomSubscriptions(
		context.Background(),
		connect.NewRequest(&chatv1.SearchRoomSubscriptionsRequest{
			RoomId: util.IDString(),
		}),
	)
	require.Error(t, err)
}

// --- UpdateSubscriptionSettings validation ---

func TestUpdateSubscriptionSettings_EmptyRoomID(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightAuthCtx()
	_, err := chatServer.UpdateSubscriptionSettings(ctx, connect.NewRequest(&chatv1.UpdateSubscriptionSettingsRequest{
		RoomId: "",
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
}

func TestUpdateSubscriptionSettings_Unauthenticated(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	_, err := chatServer.UpdateSubscriptionSettings(
		context.Background(),
		connect.NewRequest(&chatv1.UpdateSubscriptionSettingsRequest{
			RoomId: util.IDString(),
		}),
	)
	require.Error(t, err)
}

// --- GetSubscriptionSettings validation ---

func TestGetSubscriptionSettings_EmptyRoomID(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightAuthCtx()
	_, err := chatServer.GetSubscriptionSettings(ctx, connect.NewRequest(&chatv1.GetSubscriptionSettingsRequest{
		RoomId: "",
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
}

func TestGetSubscriptionSettings_Unauthenticated(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	_, err := chatServer.GetSubscriptionSettings(
		context.Background(),
		connect.NewRequest(&chatv1.GetSubscriptionSettingsRequest{
			RoomId: util.IDString(),
		}),
	)
	require.Error(t, err)
}

// --- ListProposals validation ---

func TestListProposals_EmptyRoomID(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightAuthCtx()
	_, err := chatServer.ListProposals(ctx, connect.NewRequest(&chatv1.ListProposalsRequest{RoomId: ""}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
}

func TestListProposals_Unauthenticated(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	_, err := chatServer.ListProposals(context.Background(), connect.NewRequest(&chatv1.ListProposalsRequest{
		RoomId: util.IDString(),
	}))
	require.Error(t, err)
}

// --- SubmitProposal validation ---

func TestSubmitProposal_EmptyRoomID(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightAuthCtx()
	_, err := chatServer.SubmitProposal(ctx, connect.NewRequest(&chatv1.SubmitProposalRequest{
		RoomId:     "",
		ProposalId: util.IDString(),
		Action:     chatv1.ProposalAction_PROPOSAL_ACTION_APPROVE,
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
}

func TestSubmitProposal_EmptyProposalID(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightAuthCtx()
	_, err := chatServer.SubmitProposal(ctx, connect.NewRequest(&chatv1.SubmitProposalRequest{
		RoomId:     util.IDString(),
		ProposalId: "",
		Action:     chatv1.ProposalAction_PROPOSAL_ACTION_APPROVE,
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
}

func TestSubmitProposal_UnspecifiedAction(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightAuthCtx()
	_, err := chatServer.SubmitProposal(ctx, connect.NewRequest(&chatv1.SubmitProposalRequest{
		RoomId:     util.IDString(),
		ProposalId: util.IDString(),
		Action:     chatv1.ProposalAction_PROPOSAL_ACTION_UNSPECIFIED,
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
}

func TestSubmitProposal_Unauthenticated(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	_, err := chatServer.SubmitProposal(context.Background(), connect.NewRequest(&chatv1.SubmitProposalRequest{
		RoomId:     util.IDString(),
		ProposalId: util.IDString(),
		Action:     chatv1.ProposalAction_PROPOSAL_ACTION_APPROVE,
	}))
	require.Error(t, err)
}

// --- Live handler validation ---

func TestLive_Unauthenticated(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	_, err := chatServer.Live(context.Background(), connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{{
			State: &chatv1.ClientCommand_Typing{
				Typing: &chatv1.TypingEvent{RoomId: util.IDString(), Typing: true},
			},
		}},
	}))
	require.Error(t, err)
}

func TestLive_EmptyClientStates(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightSystemCtx()
	_, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{},
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
}

func TestLive_TooManyClientStates(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightSystemCtx()
	states := make([]*chatv1.ClientCommand, 51)
	for i := range states {
		states[i] = &chatv1.ClientCommand{}
	}
	_, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{ClientStates: states}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
}

func TestLive_DeliveryReceipt_NilReceipt(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightSystemCtx()
	_, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{{
			State: &chatv1.ClientCommand_Receipt{Receipt: nil},
		}},
	}))
	require.Error(t, err)
}

func TestLive_DeliveryReceipt_EmptyEventIDs(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightSystemCtx()
	_, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{{
			State: &chatv1.ClientCommand_Receipt{
				Receipt: &chatv1.ReceiptEvent{RoomId: util.IDString(), EventId: []string{}},
			},
		}},
	}))
	require.Error(t, err)
}

func TestLive_ReadMarker_NilReadMarker(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightSystemCtx()
	_, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{{
			State: &chatv1.ClientCommand_ReadMarker{ReadMarker: nil},
		}},
	}))
	require.Error(t, err)
}

func TestLive_ReadMarker_EmptyUpToEventID(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightSystemCtx()
	roomID := util.IDString()
	_, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{{
			State: &chatv1.ClientCommand_ReadMarker{
				ReadMarker: &chatv1.ReadMarker{RoomId: &roomID, UpToEventId: ""},
			},
		}},
	}))
	require.Error(t, err)
}

func TestLive_Typing_NilTypingEvent(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightSystemCtx()
	_, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{{
			State: &chatv1.ClientCommand_Typing{Typing: nil},
		}},
	}))
	require.Error(t, err)
}

func TestLive_Typing_EmptyRoomID(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightSystemCtx()
	_, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{{
			State: &chatv1.ClientCommand_Typing{
				Typing: &chatv1.TypingEvent{RoomId: "", Typing: true},
			},
		}},
	}))
	require.Error(t, err)
}

func TestLive_Presence_NilPresenceEvent(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightSystemCtx()
	_, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{{
			State: &chatv1.ClientCommand_Presence{Presence: nil},
		}},
	}))
	require.Error(t, err)
}

func TestLive_RoomEvent_NilEvent(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightSystemCtx()
	_, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{{
			State: &chatv1.ClientCommand_Event{Event: nil},
		}},
	}))
	require.Error(t, err)
}

func TestLive_UnknownCommandType(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightSystemCtx()
	_, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{{}},
	}))
	require.Error(t, err)
}

// =============================================================================
// Tests exercising business-layer success and error paths with mock business.
// =============================================================================

// --- SendEvent business error path ---

func TestSendEvent_BusinessError(t *testing.T) {
	chatServer := &handlers.ChatServer{
		MessageBusiness: &mockMessageBusiness{
			sendEventsFn: func(_ context.Context, _ *chatv1.SendEventRequest, _ *commonv1.ContactLink) ([]*chatv1.AckEvent, error) {
				return nil, errors.New("db connection failed")
			},
		},
	}
	ctx := lightweightAuthCtx()
	_, err := chatServer.SendEvent(ctx, connect.NewRequest(&chatv1.SendEventRequest{
		Event: []*chatv1.RoomEvent{{
			RoomId:  util.IDString(),
			Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
			Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "hi"}}},
		}},
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInternal, connect.CodeOf(err))
}

func TestSendEvent_BusinessSuccess(t *testing.T) {
	chatServer := &handlers.ChatServer{
		MessageBusiness: &mockMessageBusiness{
			sendEventsFn: func(_ context.Context, _ *chatv1.SendEventRequest, _ *commonv1.ContactLink) ([]*chatv1.AckEvent, error) {
				return []*chatv1.AckEvent{{EventId: []string{"e1"}}}, nil
			},
		},
	}
	ctx := lightweightAuthCtx()
	resp, err := chatServer.SendEvent(ctx, connect.NewRequest(&chatv1.SendEventRequest{
		Event: []*chatv1.RoomEvent{{
			RoomId:  util.IDString(),
			Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
			Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "hi"}}},
		}},
	}))
	require.NoError(t, err)
	require.Len(t, resp.Msg.GetAck(), 1)
	assert.Equal(t, []string{"e1"}, resp.Msg.GetAck()[0].GetEventId())
}

// --- GetHistory business paths ---

func TestGetHistory_BusinessError(t *testing.T) {
	chatServer := &handlers.ChatServer{
		MessageBusiness: &mockMessageBusiness{
			getHistoryFn: func(_ context.Context, _ *chatv1.GetHistoryRequest, _ *commonv1.ContactLink) ([]*chatv1.RoomEvent, error) {
				return nil, errors.New("storage unavailable")
			},
		},
	}
	ctx := lightweightAuthCtx()
	_, err := chatServer.GetHistory(ctx, connect.NewRequest(&chatv1.GetHistoryRequest{
		RoomId: util.IDString(),
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInternal, connect.CodeOf(err))
}

func TestGetHistory_BusinessSuccess(t *testing.T) {
	chatServer := &handlers.ChatServer{
		MessageBusiness: &mockMessageBusiness{
			getHistoryFn: func(_ context.Context, _ *chatv1.GetHistoryRequest, _ *commonv1.ContactLink) ([]*chatv1.RoomEvent, error) {
				return []*chatv1.RoomEvent{{Id: "ev1"}}, nil
			},
		},
	}
	ctx := lightweightAuthCtx()
	resp, err := chatServer.GetHistory(ctx, connect.NewRequest(&chatv1.GetHistoryRequest{
		RoomId: util.IDString(),
	}))
	require.NoError(t, err)
	require.Len(t, resp.Msg.GetEvents(), 1)
}

func TestGetHistory_WithCursorLimit(t *testing.T) {
	chatServer := &handlers.ChatServer{
		MessageBusiness: &mockMessageBusiness{
			getHistoryFn: func(_ context.Context, _ *chatv1.GetHistoryRequest, _ *commonv1.ContactLink) ([]*chatv1.RoomEvent, error) {
				return []*chatv1.RoomEvent{}, nil
			},
		},
	}
	ctx := lightweightAuthCtx()
	resp, err := chatServer.GetHistory(ctx, connect.NewRequest(&chatv1.GetHistoryRequest{
		RoomId: util.IDString(),
		Cursor: &commonv1.PageCursor{Limit: 10},
	}))
	require.NoError(t, err)
	assert.NotNil(t, resp)
}

func TestGetHistory_CursorLimitExceedsMax(t *testing.T) {
	chatServer := &handlers.ChatServer{
		MessageBusiness: &mockMessageBusiness{
			getHistoryFn: func(_ context.Context, _ *chatv1.GetHistoryRequest, _ *commonv1.ContactLink) ([]*chatv1.RoomEvent, error) {
				return []*chatv1.RoomEvent{}, nil
			},
		},
	}
	ctx := lightweightAuthCtx()
	resp, err := chatServer.GetHistory(ctx, connect.NewRequest(&chatv1.GetHistoryRequest{
		RoomId: util.IDString(),
		Cursor: &commonv1.PageCursor{Limit: 200}, // exceeds MaxBatchSize
	}))
	require.NoError(t, err)
	assert.NotNil(t, resp)
}

// --- CreateRoom business paths ---

func TestCreateRoom_BusinessError(t *testing.T) {
	chatServer := &handlers.ChatServer{
		RoomBusiness: &mockRoomBusiness{
			createRoomFn: func(_ context.Context, _ *chatv1.CreateRoomRequest, _ *commonv1.ContactLink) (*chatv1.Room, error) {
				return nil, errors.New("db error")
			},
		},
	}
	ctx := lightweightAuthCtx()
	_, err := chatServer.CreateRoom(ctx, connect.NewRequest(&chatv1.CreateRoomRequest{
		Name: "Test Room",
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInternal, connect.CodeOf(err))
}

func TestCreateRoom_BusinessSuccess(t *testing.T) {
	chatServer := &handlers.ChatServer{
		RoomBusiness: &mockRoomBusiness{
			createRoomFn: func(_ context.Context, _ *chatv1.CreateRoomRequest, _ *commonv1.ContactLink) (*chatv1.Room, error) {
				return &chatv1.Room{Id: "room-1", Name: "Test Room"}, nil
			},
		},
	}
	ctx := lightweightAuthCtx()
	resp, err := chatServer.CreateRoom(ctx, connect.NewRequest(&chatv1.CreateRoomRequest{
		Name: "Test Room",
	}))
	require.NoError(t, err)
	assert.Equal(t, "room-1", resp.Msg.GetRoom().GetId())
}

// --- SearchRooms business error path ---

func TestSearchRooms_BusinessError(t *testing.T) {
	chatServer := &handlers.ChatServer{
		RoomBusiness: &mockRoomBusiness{
			searchRoomsFn: func(_ context.Context, _ *chatv1.SearchRoomsRequest, _ *commonv1.ContactLink) ([]*chatv1.Room, error) {
				return nil, errors.New("search failed")
			},
		},
	}
	ctx := lightweightAuthCtx()
	err := chatServer.SearchRooms(ctx,
		connect.NewRequest(&chatv1.SearchRoomsRequest{Query: "test"}), nil)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "search failed")
}

func TestSearchRooms_NilMsg(t *testing.T) {
	chatServer := &handlers.ChatServer{}
	ctx := lightweightAuthCtx()
	// SearchRoomsRequest with nil msg - use empty request which is valid Go proto
	err := chatServer.SearchRooms(ctx,
		&connect.Request[chatv1.SearchRoomsRequest]{}, nil)
	require.Error(t, err)
	assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
}

// --- DeleteRoom business paths ---

func TestDeleteRoom_BusinessError(t *testing.T) {
	chatServer := &handlers.ChatServer{
		RoomBusiness: &mockRoomBusiness{
			deleteRoomFn: func(_ context.Context, _ *chatv1.DeleteRoomRequest, _ *commonv1.ContactLink) error {
				return errors.New("delete failed")
			},
		},
	}
	ctx := lightweightAuthCtx()
	_, err := chatServer.DeleteRoom(ctx, connect.NewRequest(&chatv1.DeleteRoomRequest{
		RoomId: util.IDString(),
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInternal, connect.CodeOf(err))
}

func TestDeleteRoom_BusinessSuccess(t *testing.T) {
	chatServer := &handlers.ChatServer{
		RoomBusiness: &mockRoomBusiness{
			deleteRoomFn: func(_ context.Context, _ *chatv1.DeleteRoomRequest, _ *commonv1.ContactLink) error {
				return nil
			},
		},
	}
	ctx := lightweightAuthCtx()
	resp, err := chatServer.DeleteRoom(ctx, connect.NewRequest(&chatv1.DeleteRoomRequest{
		RoomId: util.IDString(),
	}))
	require.NoError(t, err)
	assert.NotNil(t, resp)
}

// --- AddRoomSubscriptions business paths ---

func TestAddRoomSubscriptions_PartialBatchError(t *testing.T) {
	chatServer := &handlers.ChatServer{
		RoomBusiness: &mockRoomBusiness{
			addRoomSubscriptionsFn: func(_ context.Context, _ *chatv1.AddRoomSubscriptionsRequest, _ *commonv1.ContactLink) error {
				return &service.PartialBatchError{
					Succeeded: 1,
					Failed:    1,
					Errors:    []service.ItemError{{Index: 1, ItemID: "member2", Message: "contact not found"}},
				}
			},
		},
	}
	ctx := lightweightAuthCtx()
	resp, err := chatServer.AddRoomSubscriptions(ctx, connect.NewRequest(&chatv1.AddRoomSubscriptionsRequest{
		RoomId: util.IDString(),
		Members: []*chatv1.RoomSubscription{
			{Member: &commonv1.ContactLink{ContactId: "c1"}},
			{Member: &commonv1.ContactLink{ContactId: "c2"}},
		},
	}))
	require.NoError(t, err) // partial batch returns success with error detail
	require.NotNil(t, resp.Msg.GetError())
	assert.Contains(t, resp.Msg.GetError().GetMessage(), "partial batch failure")
}

func TestAddRoomSubscriptions_BusinessError(t *testing.T) {
	chatServer := &handlers.ChatServer{
		RoomBusiness: &mockRoomBusiness{
			addRoomSubscriptionsFn: func(_ context.Context, _ *chatv1.AddRoomSubscriptionsRequest, _ *commonv1.ContactLink) error {
				return errors.New("db error")
			},
		},
	}
	ctx := lightweightAuthCtx()
	_, err := chatServer.AddRoomSubscriptions(ctx, connect.NewRequest(&chatv1.AddRoomSubscriptionsRequest{
		RoomId:  util.IDString(),
		Members: []*chatv1.RoomSubscription{{Member: &commonv1.ContactLink{ContactId: "c1"}}},
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInternal, connect.CodeOf(err))
}

func TestAddRoomSubscriptions_BusinessSuccess(t *testing.T) {
	chatServer := &handlers.ChatServer{
		RoomBusiness: &mockRoomBusiness{
			addRoomSubscriptionsFn: func(_ context.Context, _ *chatv1.AddRoomSubscriptionsRequest, _ *commonv1.ContactLink) error {
				return nil
			},
		},
	}
	ctx := lightweightAuthCtx()
	resp, err := chatServer.AddRoomSubscriptions(ctx, connect.NewRequest(&chatv1.AddRoomSubscriptionsRequest{
		RoomId:  util.IDString(),
		Members: []*chatv1.RoomSubscription{{Member: &commonv1.ContactLink{ContactId: "c1"}}},
	}))
	require.NoError(t, err)
	assert.Nil(t, resp.Msg.GetError())
}

// --- RemoveRoomSubscriptions business paths ---

func TestRemoveRoomSubscriptions_PartialBatchError(t *testing.T) {
	chatServer := &handlers.ChatServer{
		RoomBusiness: &mockRoomBusiness{
			removeRoomSubscriptionsFn: func(_ context.Context, _ *chatv1.RemoveRoomSubscriptionsRequest, _ *commonv1.ContactLink) error {
				return &service.PartialBatchError{
					Succeeded: 1,
					Failed:    1,
					Errors:    []service.ItemError{{Index: 0, ItemID: "sub1", Message: "not found"}},
				}
			},
		},
	}
	ctx := lightweightAuthCtx()
	resp, err := chatServer.RemoveRoomSubscriptions(ctx, connect.NewRequest(&chatv1.RemoveRoomSubscriptionsRequest{
		RoomId:         util.IDString(),
		SubscriptionId: []string{"sub1", "sub2"},
	}))
	require.NoError(t, err)
	require.NotNil(t, resp.Msg.GetError())
	assert.Contains(t, resp.Msg.GetError().GetMessage(), "partial batch failure")
}

func TestRemoveRoomSubscriptions_BusinessError(t *testing.T) {
	chatServer := &handlers.ChatServer{
		RoomBusiness: &mockRoomBusiness{
			removeRoomSubscriptionsFn: func(_ context.Context, _ *chatv1.RemoveRoomSubscriptionsRequest, _ *commonv1.ContactLink) error {
				return errors.New("db error")
			},
		},
	}
	ctx := lightweightAuthCtx()
	_, err := chatServer.RemoveRoomSubscriptions(ctx, connect.NewRequest(&chatv1.RemoveRoomSubscriptionsRequest{
		RoomId:         util.IDString(),
		SubscriptionId: []string{util.IDString()},
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInternal, connect.CodeOf(err))
}

func TestRemoveRoomSubscriptions_BusinessSuccess(t *testing.T) {
	chatServer := &handlers.ChatServer{
		RoomBusiness: &mockRoomBusiness{
			removeRoomSubscriptionsFn: func(_ context.Context, _ *chatv1.RemoveRoomSubscriptionsRequest, _ *commonv1.ContactLink) error {
				return nil
			},
		},
	}
	ctx := lightweightAuthCtx()
	resp, err := chatServer.RemoveRoomSubscriptions(ctx, connect.NewRequest(&chatv1.RemoveRoomSubscriptionsRequest{
		RoomId:         util.IDString(),
		SubscriptionId: []string{util.IDString()},
	}))
	require.NoError(t, err)
	assert.Nil(t, resp.Msg.GetError())
}

// --- UpdateSubscriptionRole business paths ---

func TestUpdateSubscriptionRole_BusinessError(t *testing.T) {
	chatServer := &handlers.ChatServer{
		RoomBusiness: &mockRoomBusiness{
			updateSubscriptionRoleFn: func(_ context.Context, _ *chatv1.UpdateSubscriptionRoleRequest, _ *commonv1.ContactLink) error {
				return errors.New("role update failed")
			},
		},
	}
	ctx := lightweightAuthCtx()
	_, err := chatServer.UpdateSubscriptionRole(ctx, connect.NewRequest(&chatv1.UpdateSubscriptionRoleRequest{
		RoomId:         util.IDString(),
		SubscriptionId: util.IDString(),
		Roles:          []string{"moderator"},
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInternal, connect.CodeOf(err))
}

func TestUpdateSubscriptionRole_BusinessSuccess(t *testing.T) {
	chatServer := &handlers.ChatServer{
		RoomBusiness: &mockRoomBusiness{
			updateSubscriptionRoleFn: func(_ context.Context, _ *chatv1.UpdateSubscriptionRoleRequest, _ *commonv1.ContactLink) error {
				return nil
			},
		},
	}
	ctx := lightweightAuthCtx()
	resp, err := chatServer.UpdateSubscriptionRole(ctx, connect.NewRequest(&chatv1.UpdateSubscriptionRoleRequest{
		RoomId:         util.IDString(),
		SubscriptionId: util.IDString(),
		Roles:          []string{"moderator"},
	}))
	require.NoError(t, err)
	assert.NotNil(t, resp)
}

// --- SearchRoomSubscriptions business paths ---

func TestSearchRoomSubscriptions_BusinessError(t *testing.T) {
	chatServer := &handlers.ChatServer{
		RoomBusiness: &mockRoomBusiness{
			searchRoomSubsFn: func(_ context.Context, _ *chatv1.SearchRoomSubscriptionsRequest, _ *commonv1.ContactLink) ([]*chatv1.RoomSubscription, error) {
				return nil, errors.New("search failed")
			},
		},
	}
	ctx := lightweightAuthCtx()
	_, err := chatServer.SearchRoomSubscriptions(ctx, connect.NewRequest(&chatv1.SearchRoomSubscriptionsRequest{
		RoomId: util.IDString(),
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInternal, connect.CodeOf(err))
}

func TestSearchRoomSubscriptions_BusinessSuccess(t *testing.T) {
	chatServer := &handlers.ChatServer{
		RoomBusiness: &mockRoomBusiness{
			searchRoomSubsFn: func(_ context.Context, _ *chatv1.SearchRoomSubscriptionsRequest, _ *commonv1.ContactLink) ([]*chatv1.RoomSubscription, error) {
				return []*chatv1.RoomSubscription{{Id: "sub1"}}, nil
			},
		},
	}
	ctx := lightweightAuthCtx()
	resp, err := chatServer.SearchRoomSubscriptions(ctx, connect.NewRequest(&chatv1.SearchRoomSubscriptionsRequest{
		RoomId: util.IDString(),
	}))
	require.NoError(t, err)
	require.Len(t, resp.Msg.GetMembers(), 1)
}

// --- ListProposals business paths ---

func TestListProposals_BusinessError(t *testing.T) {
	chatServer := &handlers.ChatServer{
		ProposalManagement: &mockProposalManagement{
			listPendingFn: func(_ context.Context, _ string, _ *commonv1.ContactLink) ([]*models.Proposal, error) {
				return nil, errors.New("query failed")
			},
		},
	}
	ctx := lightweightAuthCtx()
	_, err := chatServer.ListProposals(ctx, connect.NewRequest(&chatv1.ListProposalsRequest{
		RoomId: util.IDString(),
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInternal, connect.CodeOf(err))
}

func TestListProposals_BusinessSuccess(t *testing.T) {
	chatServer := &handlers.ChatServer{
		ProposalManagement: &mockProposalManagement{
			listPendingFn: func(_ context.Context, _ string, _ *commonv1.ContactLink) ([]*models.Proposal, error) {
				return []*models.Proposal{}, nil
			},
		},
	}
	ctx := lightweightAuthCtx()
	resp, err := chatServer.ListProposals(ctx, connect.NewRequest(&chatv1.ListProposalsRequest{
		RoomId: util.IDString(),
	}))
	require.NoError(t, err)
	assert.Empty(t, resp.Msg.GetProposals())
}

// --- SubmitProposal business paths ---

func TestSubmitProposal_RejectSuccess(t *testing.T) {
	chatServer := &handlers.ChatServer{
		ProposalManagement: &mockProposalManagement{
			rejectFn: func(_ context.Context, _, _, _ string, _ *commonv1.ContactLink) error {
				return nil
			},
		},
	}
	ctx := lightweightAuthCtx()
	resp, err := chatServer.SubmitProposal(ctx, connect.NewRequest(&chatv1.SubmitProposalRequest{
		RoomId:     util.IDString(),
		ProposalId: util.IDString(),
		Action:     chatv1.ProposalAction_PROPOSAL_ACTION_REJECT,
		Reason:     strPtr("not appropriate"),
	}))
	require.NoError(t, err)
	assert.Nil(t, resp.Msg.GetError())
}

func TestSubmitProposal_ApproveProposalError(t *testing.T) {
	chatServer := &handlers.ChatServer{
		ProposalManagement: &mockProposalManagement{
			approveFn: func(_ context.Context, _, _ string, _ *commonv1.ContactLink) error {
				return service.ErrProposalNotFound
			},
		},
	}
	ctx := lightweightAuthCtx()
	resp, err := chatServer.SubmitProposal(ctx, connect.NewRequest(&chatv1.SubmitProposalRequest{
		RoomId:     util.IDString(),
		ProposalId: util.IDString(),
		Action:     chatv1.ProposalAction_PROPOSAL_ACTION_APPROVE,
	}))
	// Proposal errors are returned in response error field, not as gRPC error
	require.NoError(t, err)
	require.NotNil(t, resp.Msg.GetError())
	assert.Contains(t, resp.Msg.GetError().GetMessage(), "proposal not found")
}

func TestSubmitProposal_RejectProposalError(t *testing.T) {
	chatServer := &handlers.ChatServer{
		ProposalManagement: &mockProposalManagement{
			rejectFn: func(_ context.Context, _, _, _ string, _ *commonv1.ContactLink) error {
				return service.ErrProposalExpired
			},
		},
	}
	ctx := lightweightAuthCtx()
	resp, err := chatServer.SubmitProposal(ctx, connect.NewRequest(&chatv1.SubmitProposalRequest{
		RoomId:     util.IDString(),
		ProposalId: util.IDString(),
		Action:     chatv1.ProposalAction_PROPOSAL_ACTION_REJECT,
		Reason:     strPtr("test"),
	}))
	require.NoError(t, err)
	require.NotNil(t, resp.Msg.GetError())
	assert.Contains(t, resp.Msg.GetError().GetMessage(), "expired")
}

func TestSubmitProposal_ApproveNonProposalError(t *testing.T) {
	chatServer := &handlers.ChatServer{
		ProposalManagement: &mockProposalManagement{
			approveFn: func(_ context.Context, _, _ string, _ *commonv1.ContactLink) error {
				return errors.New("database down")
			},
		},
	}
	ctx := lightweightAuthCtx()
	_, err := chatServer.SubmitProposal(ctx, connect.NewRequest(&chatv1.SubmitProposalRequest{
		RoomId:     util.IDString(),
		ProposalId: util.IDString(),
		Action:     chatv1.ProposalAction_PROPOSAL_ACTION_APPROVE,
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInternal, connect.CodeOf(err))
}

// --- Live handler: process*State error paths via business mock ---

func TestLive_TypingState_BusinessError(t *testing.T) {
	chatServer := &handlers.ChatServer{
		ConnectBusiness: &mockConnectBusiness{
			updateTypingFn: func(_ context.Context, _ string, _ *commonv1.ContactLink, _ bool) error {
				return errors.New("typing broadcast failed")
			},
		},
	}
	ctx := lightweightSystemCtx()
	// Single state - all fail means gRPC error is returned
	_, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{{
			State: &chatv1.ClientCommand_Typing{
				Typing: &chatv1.TypingEvent{RoomId: util.IDString(), Typing: true},
			},
		}},
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
}

func TestLive_PresenceState_BusinessError(t *testing.T) {
	chatServer := &handlers.ChatServer{
		ConnectBusiness: &mockConnectBusiness{
			updatePresenceFn: func(_ context.Context, _ *chatv1.PresenceEvent) error {
				return errors.New("presence broadcast failed")
			},
		},
	}
	ctx := lightweightSystemCtx()
	_, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{{
			State: &chatv1.ClientCommand_Presence{
				Presence: &chatv1.PresenceEvent{
					Status: chatv1.PresenceStatus_PRESENCE_STATUS_ONLINE,
				},
			},
		}},
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
}

func TestLive_DeliveryReceiptState_BusinessError(t *testing.T) {
	chatServer := &handlers.ChatServer{
		ConnectBusiness: &mockConnectBusiness{
			updateDeliveryReceiptFn: func(_ context.Context, _ string, _ *commonv1.ContactLink, _ ...string) error {
				return errors.New("receipt update failed")
			},
		},
	}
	ctx := lightweightSystemCtx()
	_, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{{
			State: &chatv1.ClientCommand_Receipt{
				Receipt: &chatv1.ReceiptEvent{
					RoomId:  util.IDString(),
					EventId: []string{util.IDString()},
				},
			},
		}},
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
}

func TestLive_ReadMarkerState_BusinessError(t *testing.T) {
	chatServer := &handlers.ChatServer{
		ConnectBusiness: &mockConnectBusiness{
			updateReadMarkerFn: func(_ context.Context, _ string, _ *commonv1.ContactLink, _ string) error {
				return errors.New("read marker update failed")
			},
		},
	}
	ctx := lightweightSystemCtx()
	roomID := util.IDString()
	_, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{{
			State: &chatv1.ClientCommand_ReadMarker{
				ReadMarker: &chatv1.ReadMarker{
					RoomId:      &roomID,
					UpToEventId: util.IDString(),
				},
			},
		}},
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
}

func TestLive_RoomEventState_BusinessError(t *testing.T) {
	chatServer := &handlers.ChatServer{
		MessageBusiness: &mockMessageBusiness{
			sendEventsFn: func(_ context.Context, _ *chatv1.SendEventRequest, _ *commonv1.ContactLink) ([]*chatv1.AckEvent, error) {
				return nil, errors.New("send failed")
			},
		},
	}
	ctx := lightweightSystemCtx()
	_, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{{
			State: &chatv1.ClientCommand_Event{
				Event: &chatv1.RoomEvent{
					RoomId:  util.IDString(),
					Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "test"}}},
				},
			},
		}},
	}))
	require.Error(t, err)
	assert.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err))
}

// --- Live handler: partial failure (some succeed, some fail) ---

func TestLive_PartialFailure(t *testing.T) {
	callCount := 0
	chatServer := &handlers.ChatServer{
		ConnectBusiness: &mockConnectBusiness{
			updateTypingFn: func(_ context.Context, _ string, _ *commonv1.ContactLink, _ bool) error {
				callCount++
				if callCount == 1 {
					return nil // first succeeds
				}
				return errors.New("second failed")
			},
		},
	}
	ctx := lightweightSystemCtx()
	resp, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{
			{State: &chatv1.ClientCommand_Typing{Typing: &chatv1.TypingEvent{RoomId: util.IDString(), Typing: true}}},
			{State: &chatv1.ClientCommand_Typing{Typing: &chatv1.TypingEvent{RoomId: util.IDString(), Typing: false}}},
		},
	}))
	require.NoError(t, err) // partial success returns response, not error
	require.NotNil(t, resp.Msg.GetError())
	assert.Contains(t, resp.Msg.GetError().GetMessage(), "partial batch failure")
}

// --- Live handler: all states succeed ---

func TestLive_AllStatesSucceed(t *testing.T) {
	chatServer := &handlers.ChatServer{
		ConnectBusiness: &mockConnectBusiness{
			updateTypingFn: func(_ context.Context, _ string, _ *commonv1.ContactLink, _ bool) error {
				return nil
			},
		},
	}
	ctx := lightweightSystemCtx()
	resp, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{
			{State: &chatv1.ClientCommand_Typing{Typing: &chatv1.TypingEvent{RoomId: util.IDString(), Typing: true}}},
		},
	}))
	require.NoError(t, err)
	assert.Nil(t, resp.Msg.GetError())
}

// --- Live handler: success paths for each state type ---

func TestLive_PresenceState_Success(t *testing.T) {
	chatServer := &handlers.ChatServer{
		ConnectBusiness: &mockConnectBusiness{
			updatePresenceFn: func(_ context.Context, _ *chatv1.PresenceEvent) error {
				return nil
			},
		},
	}
	ctx := lightweightSystemCtx()
	resp, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{{
			State: &chatv1.ClientCommand_Presence{
				Presence: &chatv1.PresenceEvent{Status: chatv1.PresenceStatus_PRESENCE_STATUS_ONLINE},
			},
		}},
	}))
	require.NoError(t, err)
	assert.Nil(t, resp.Msg.GetError())
}

func TestLive_DeliveryReceiptState_Success(t *testing.T) {
	chatServer := &handlers.ChatServer{
		ConnectBusiness: &mockConnectBusiness{
			updateDeliveryReceiptFn: func(_ context.Context, _ string, _ *commonv1.ContactLink, _ ...string) error {
				return nil
			},
		},
	}
	ctx := lightweightSystemCtx()
	resp, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{{
			State: &chatv1.ClientCommand_Receipt{
				Receipt: &chatv1.ReceiptEvent{
					RoomId:  util.IDString(),
					EventId: []string{util.IDString()},
				},
			},
		}},
	}))
	require.NoError(t, err)
	assert.Nil(t, resp.Msg.GetError())
}

func TestLive_ReadMarkerState_Success(t *testing.T) {
	chatServer := &handlers.ChatServer{
		ConnectBusiness: &mockConnectBusiness{
			updateReadMarkerFn: func(_ context.Context, _ string, _ *commonv1.ContactLink, _ string) error {
				return nil
			},
		},
	}
	ctx := lightweightSystemCtx()
	roomID := util.IDString()
	resp, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{{
			State: &chatv1.ClientCommand_ReadMarker{
				ReadMarker: &chatv1.ReadMarker{
					RoomId:      &roomID,
					UpToEventId: util.IDString(),
				},
			},
		}},
	}))
	require.NoError(t, err)
	assert.Nil(t, resp.Msg.GetError())
}

func TestLive_RoomEventState_Success(t *testing.T) {
	chatServer := &handlers.ChatServer{
		MessageBusiness: &mockMessageBusiness{
			sendEventsFn: func(_ context.Context, _ *chatv1.SendEventRequest, _ *commonv1.ContactLink) ([]*chatv1.AckEvent, error) {
				return []*chatv1.AckEvent{{EventId: []string{"e1"}}}, nil
			},
		},
	}
	ctx := lightweightSystemCtx()
	resp, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{{
			State: &chatv1.ClientCommand_Event{
				Event: &chatv1.RoomEvent{
					RoomId:  util.IDString(),
					Type:    chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE,
					Payload: &chatv1.Payload{Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "hi"}}},
				},
			},
		}},
	}))
	require.NoError(t, err)
	assert.Nil(t, resp.Msg.GetError())
}

// --- Live handler: nil client state in batch ---

func TestLive_NilClientStateInBatch(t *testing.T) {
	chatServer := &handlers.ChatServer{
		ConnectBusiness: &mockConnectBusiness{
			updateTypingFn: func(_ context.Context, _ string, _ *commonv1.ContactLink, _ bool) error {
				return nil
			},
		},
	}
	ctx := lightweightSystemCtx()
	resp, err := chatServer.Live(ctx, connect.NewRequest(&chatv1.LiveRequest{
		ClientStates: []*chatv1.ClientCommand{
			nil, // nil state at index 0
			{State: &chatv1.ClientCommand_Typing{Typing: &chatv1.TypingEvent{RoomId: util.IDString(), Typing: true}}},
		},
	}))
	// One succeeded, one failed (nil) - partial failure
	require.NoError(t, err)
	require.NotNil(t, resp.Msg.GetError())
	assert.Contains(t, resp.Msg.GetError().GetMessage(), "partial batch failure")
}
