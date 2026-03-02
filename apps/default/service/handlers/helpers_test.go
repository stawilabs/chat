package handlers

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/antinvestor/service-chat/apps/default/service"
	"github.com/antinvestor/service-chat/apps/default/service/models"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"gorm.io/gorm"
)

// --- proposalToAPI tests ---

func TestProposalToAPI_AllFieldsSet(t *testing.T) {
	resolvedAt := time.Date(2026, 1, 15, 10, 0, 0, 0, time.UTC)
	p := &models.Proposal{
		ScopeID:      "room-123",
		ProposalType: models.ProposalTypeUpdateRoom,
		RequestedBy:  "user-1",
		Payload:      map[string]interface{}{"name": "new-name"},
		State:        models.ProposalStateApproved,
		ResolvedBy:   "admin-1",
		ResolvedAt:   &resolvedAt,
		Reason:       "looks good",
		ExpiresAt:    time.Date(2026, 2, 1, 0, 0, 0, 0, time.UTC),
	}
	p.ID = "proposal-1"
	p.CreatedAt = time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)

	result := proposalToAPI(p)

	assert.Equal(t, "proposal-1", result.GetId())
	assert.Equal(t, "room-123", result.GetRoomId())
	assert.Equal(t, chatv1.ProposalType_PROPOSAL_TYPE_UPDATE_ROOM, result.GetType())
	assert.Equal(t, chatv1.ProposalState_PROPOSAL_STATE_APPROVED, result.GetState())
	assert.Equal(t, "user-1", result.GetRequestedBy())
	assert.NotNil(t, result.GetCreatedAt())
	assert.NotNil(t, result.GetExpiresAt())
	assert.NotNil(t, result.GetPayload())
	assert.Equal(t, "new-name", result.GetPayload().GetFields()["name"].GetStringValue())
	require.NotNil(t, result.ResolvedBy)
	assert.Equal(t, "admin-1", result.GetResolvedBy())
	require.NotNil(t, result.GetResolvedAt())
	assert.Equal(t, resolvedAt.Unix(), result.GetResolvedAt().AsTime().Unix())
	require.NotNil(t, result.Reason)
	assert.Equal(t, "looks good", result.GetReason())
}

func TestProposalToAPI_NilPayload(t *testing.T) {
	p := &models.Proposal{
		ScopeID:      "room-1",
		ProposalType: models.ProposalTypeDeleteRoom,
		RequestedBy:  "user-1",
		Payload:      nil,
		State:        models.ProposalStatePending,
		ExpiresAt:    time.Now().Add(time.Hour),
	}
	p.ID = "p-2"

	result := proposalToAPI(p)

	assert.Nil(t, result.GetPayload())
	assert.Equal(t, chatv1.ProposalType_PROPOSAL_TYPE_DELETE_ROOM, result.GetType())
	assert.Equal(t, chatv1.ProposalState_PROPOSAL_STATE_PENDING, result.GetState())
}

func TestProposalToAPI_NonNilPayload(t *testing.T) {
	p := &models.Proposal{
		ScopeID:      "room-1",
		ProposalType: models.ProposalTypeAddSubscriptions,
		RequestedBy:  "user-1",
		Payload:      map[string]interface{}{"key": "value", "count": float64(42)},
		State:        models.ProposalStatePending,
		ExpiresAt:    time.Now().Add(time.Hour),
	}
	p.ID = "p-3"

	result := proposalToAPI(p)

	require.NotNil(t, result.GetPayload())
	assert.Equal(t, "value", result.GetPayload().GetFields()["key"].GetStringValue())
	assert.InDelta(t, float64(42), result.GetPayload().GetFields()["count"].GetNumberValue(), 0.001)
}

func TestProposalToAPI_ResolvedByEmpty(t *testing.T) {
	p := &models.Proposal{
		ScopeID:      "room-1",
		ProposalType: models.ProposalTypeUpdateRoom,
		RequestedBy:  "user-1",
		State:        models.ProposalStatePending,
		ResolvedBy:   "",
		ExpiresAt:    time.Now().Add(time.Hour),
	}
	p.ID = "p-4"

	result := proposalToAPI(p)

	assert.Nil(t, result.ResolvedBy)
}

func TestProposalToAPI_ResolvedBySet(t *testing.T) {
	p := &models.Proposal{
		ScopeID:      "room-1",
		ProposalType: models.ProposalTypeUpdateRoom,
		RequestedBy:  "user-1",
		State:        models.ProposalStateRejected,
		ResolvedBy:   "admin-5",
		ExpiresAt:    time.Now().Add(time.Hour),
	}
	p.ID = "p-5"

	result := proposalToAPI(p)

	require.NotNil(t, result.ResolvedBy)
	assert.Equal(t, "admin-5", result.GetResolvedBy())
}

func TestProposalToAPI_ResolvedAtNil(t *testing.T) {
	p := &models.Proposal{
		ScopeID:      "room-1",
		ProposalType: models.ProposalTypeUpdateRoom,
		RequestedBy:  "user-1",
		State:        models.ProposalStatePending,
		ResolvedAt:   nil,
		ExpiresAt:    time.Now().Add(time.Hour),
	}
	p.ID = "p-6"

	result := proposalToAPI(p)

	assert.Nil(t, result.GetResolvedAt())
}

func TestProposalToAPI_ResolvedAtSet(t *testing.T) {
	ts := time.Date(2026, 3, 1, 12, 0, 0, 0, time.UTC)
	p := &models.Proposal{
		ScopeID:      "room-1",
		ProposalType: models.ProposalTypeUpdateRoom,
		RequestedBy:  "user-1",
		State:        models.ProposalStateApproved,
		ResolvedAt:   &ts,
		ExpiresAt:    time.Now().Add(time.Hour),
	}
	p.ID = "p-7"

	result := proposalToAPI(p)

	require.NotNil(t, result.GetResolvedAt())
	assert.Equal(t, ts.Unix(), result.GetResolvedAt().AsTime().Unix())
}

func TestProposalToAPI_ReasonEmpty(t *testing.T) {
	p := &models.Proposal{
		ScopeID:      "room-1",
		ProposalType: models.ProposalTypeUpdateRoom,
		RequestedBy:  "user-1",
		State:        models.ProposalStatePending,
		Reason:       "",
		ExpiresAt:    time.Now().Add(time.Hour),
	}
	p.ID = "p-8"

	result := proposalToAPI(p)

	assert.Nil(t, result.Reason)
}

func TestProposalToAPI_ReasonSet(t *testing.T) {
	p := &models.Proposal{
		ScopeID:      "room-1",
		ProposalType: models.ProposalTypeUpdateRoom,
		RequestedBy:  "user-1",
		State:        models.ProposalStateRejected,
		Reason:       "not appropriate",
		ExpiresAt:    time.Now().Add(time.Hour),
	}
	p.ID = "p-9"

	result := proposalToAPI(p)

	require.NotNil(t, result.Reason)
	assert.Equal(t, "not appropriate", result.GetReason())
}

// --- proposalTypeToAPI tests ---

func TestProposalTypeToAPI(t *testing.T) {
	tests := []struct {
		name     string
		input    models.ProposalType
		expected chatv1.ProposalType
	}{
		{"UpdateRoom", models.ProposalTypeUpdateRoom, chatv1.ProposalType_PROPOSAL_TYPE_UPDATE_ROOM},
		{"DeleteRoom", models.ProposalTypeDeleteRoom, chatv1.ProposalType_PROPOSAL_TYPE_DELETE_ROOM},
		{"AddSubscriptions", models.ProposalTypeAddSubscriptions, chatv1.ProposalType_PROPOSAL_TYPE_ADD_SUBSCRIPTIONS},
		{
			"RemoveSubscriptions",
			models.ProposalTypeRemoveSubscriptions,
			chatv1.ProposalType_PROPOSAL_TYPE_REMOVE_SUBSCRIPTIONS,
		},
		{
			"UpdateSubscriptionRole",
			models.ProposalTypeUpdateSubscriptionRole,
			chatv1.ProposalType_PROPOSAL_TYPE_UPDATE_SUBSCRIPTION_ROLE,
		},
		{"UnknownDefault", models.ProposalType(999), chatv1.ProposalType_PROPOSAL_TYPE_UNSPECIFIED},
		{"ZeroDefault", models.ProposalType(0), chatv1.ProposalType_PROPOSAL_TYPE_UNSPECIFIED},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			assert.Equal(t, tc.expected, proposalTypeToAPI(tc.input))
		})
	}
}

// --- proposalStateToAPI tests ---

func TestProposalStateToAPI(t *testing.T) {
	tests := []struct {
		name     string
		input    models.ProposalState
		expected chatv1.ProposalState
	}{
		{"Pending", models.ProposalStatePending, chatv1.ProposalState_PROPOSAL_STATE_PENDING},
		{"Approved", models.ProposalStateApproved, chatv1.ProposalState_PROPOSAL_STATE_APPROVED},
		{"Rejected", models.ProposalStateRejected, chatv1.ProposalState_PROPOSAL_STATE_REJECTED},
		{"Expired", models.ProposalStateExpired, chatv1.ProposalState_PROPOSAL_STATE_EXPIRED},
		{"UnknownDefault", models.ProposalState(999), chatv1.ProposalState_PROPOSAL_STATE_UNSPECIFIED},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			assert.Equal(t, tc.expected, proposalStateToAPI(tc.input))
		})
	}
}

// --- isProposalError tests ---

func TestIsProposalError(t *testing.T) {
	tests := []struct {
		name     string
		err      error
		expected bool
	}{
		{"ProposalNotFound", service.ErrProposalNotFound, true},
		{"ProposalNotPending", service.ErrProposalNotPending, true},
		{"ProposalExpired", service.ErrProposalExpired, true},
		{"ProposalApprovalDenied", service.ErrProposalApprovalDenied, true},
		{"WrappedProposalNotFound", fmt.Errorf("wrapped: %w", service.ErrProposalNotFound), true},
		{"GenericError", errors.New("something went wrong"), false},
		{"ProposalRequired", service.ErrProposalRequired, false},
		{"NilError", nil, false},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			assert.Equal(t, tc.expected, isProposalError(tc.err))
		})
	}
}

// --- toAPIError tests ---

func TestToAPIError_NilError(t *testing.T) {
	ps := &ChatServer{}
	result := ps.toAPIError(context.Background(), nil)
	assert.NoError(t, result)
}

func TestToAPIError_GRPCStatusError(t *testing.T) {
	ps := &ChatServer{}
	grpcErr := status.Error(codes.AlreadyExists, "already exists")
	result := ps.toAPIError(context.Background(), grpcErr)

	require.Error(t, result)
	st, ok := status.FromError(result)
	require.True(t, ok)
	assert.Equal(t, codes.AlreadyExists, st.Code())
}

func TestToAPIError_NoRowsError(t *testing.T) {
	ps := &ChatServer{}
	noRowsErr := gorm.ErrRecordNotFound
	result := ps.toAPIError(context.Background(), noRowsErr)

	require.Error(t, result)
	connectErr := new(connect.Error)
	require.ErrorAs(t, result, &connectErr)
	assert.Equal(t, connect.CodeNotFound, connectErr.Code())
}

func TestToAPIError_GenericError(t *testing.T) {
	ps := &ChatServer{}
	genericErr := errors.New("unexpected failure")
	result := ps.toAPIError(context.Background(), genericErr)

	require.Error(t, result)
	connectErr := new(connect.Error)
	require.ErrorAs(t, result, &connectErr)
	assert.Equal(t, connect.CodeInternal, connectErr.Code())
	// The message should be the generic "internal server error", not the original
	assert.Equal(t, "internal server error", connectErr.Message())
}

func TestToAPIError_ConnectError(t *testing.T) {
	ps := &ChatServer{}
	// A connect.Error is recognized and passed through preserving its code.
	inputErr := connect.NewError(connect.CodeInvalidArgument, errors.New("bad input"))
	result := ps.toAPIError(context.Background(), inputErr)

	require.Error(t, result)
	connectErr := new(connect.Error)
	require.ErrorAs(t, result, &connectErr)
	assert.Equal(t, connect.CodeInvalidArgument, connectErr.Code())
	assert.Equal(t, "bad input", connectErr.Message())
}
