package business_test

import (
	"context"
	"testing"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	"connectrpc.com/connect"
	"github.com/antinvestor/service-chat/apps/default/service/business"
	"github.com/pitabwire/frame/frametests/definition"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/types/known/structpb"
)

func (s *MessageBusinessTestSuite) TestFormSubmissionUnassignedAllowsMultipleMembersButRejectsDuplicatePerSender() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		owner := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		memberOne := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		memberTwo := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}

		room, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{
			Name:    "Shared form room",
			Members: []*commonv1.ContactLink{memberOne, memberTwo},
		}, owner)
		require.NoError(t, err)

		s.WaitForMemberSubscription(ctx, svc, room.GetId(), owner.GetProfileId(), t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), memberOne.GetProfileId(), t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), memberTwo.GetProfileId(), t)
		s.WaitForAuthzAccess(ctx, svc, owner.GetProfileId(), room.GetId(), t)
		s.WaitForAuthzAccess(ctx, svc, memberOne.GetProfileId(), room.GetId(), t)
		s.WaitForAuthzAccess(ctx, svc, memberTwo.GetProfileId(), room.GetId(), t)

		formInstanceID := util.IDString()
		formAck := s.sendFormRequestEvent(t, messageBusiness, room.GetId(), owner, formInstanceID, "")
		formEventID := formAck.GetEventId()[0]

		memberOneAck := s.sendFormSubmissionEvent(
			t,
			messageBusiness,
			room.GetId(),
			formEventID,
			formInstanceID,
			memberOne,
			map[string]any{"full_name": "Member One"},
		)
		require.Nil(t, memberOneAck.GetError())

		duplicateAck := s.sendFormSubmissionEvent(
			t,
			messageBusiness,
			room.GetId(),
			formEventID,
			formInstanceID,
			memberOne,
			map[string]any{"full_name": "Member One Again"},
		)
		require.NotNil(t, duplicateAck.GetError())
		require.Equal(t, int32(connect.CodeAlreadyExists), duplicateAck.GetError().GetCode())

		memberTwoAck := s.sendFormSubmissionEvent(
			t,
			messageBusiness,
			room.GetId(),
			formEventID,
			formInstanceID,
			memberTwo,
			map[string]any{"full_name": "Member Two"},
		)
		require.Nil(t, memberTwoAck.GetError())
	})
}

func (s *MessageBusinessTestSuite) TestFormSubmissionAssignedRestrictsToAssigneeSubscription() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		ctx, svc := s.CreateService(t, dep)
		messageBusiness, roomBusiness := s.setupBusinessLayer(ctx, svc)

		owner := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		assignee := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		otherMember := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}

		room, err := roomBusiness.CreateRoom(ctx, &chatv1.CreateRoomRequest{
			Name:    "Assigned form room",
			Members: []*commonv1.ContactLink{assignee, otherMember},
		}, owner)
		require.NoError(t, err)

		s.WaitForMemberSubscription(ctx, svc, room.GetId(), owner.GetProfileId(), t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), assignee.GetProfileId(), t)
		s.WaitForMemberSubscription(ctx, svc, room.GetId(), otherMember.GetProfileId(), t)
		s.WaitForAuthzAccess(ctx, svc, owner.GetProfileId(), room.GetId(), t)
		s.WaitForAuthzAccess(ctx, svc, assignee.GetProfileId(), room.GetId(), t)
		s.WaitForAuthzAccess(ctx, svc, otherMember.GetProfileId(), room.GetId(), t)

		assigneeSubscriptionID := s.lookupSubscriptionID(
			ctx,
			t,
			roomBusiness,
			room.GetId(),
			owner,
			assignee.GetProfileId(),
		)

		formInstanceID := util.IDString()
		formAck := s.sendFormRequestEvent(
			t,
			messageBusiness,
			room.GetId(),
			owner,
			formInstanceID,
			assigneeSubscriptionID,
		)
		formEventID := formAck.GetEventId()[0]

		deniedAck := s.sendFormSubmissionEvent(
			t,
			messageBusiness,
			room.GetId(),
			formEventID,
			formInstanceID,
			otherMember,
			map[string]any{"full_name": "Not Allowed"},
		)
		require.NotNil(t, deniedAck.GetError())
		require.Equal(t, int32(connect.CodePermissionDenied), deniedAck.GetError().GetCode())

		assigneeAck := s.sendFormSubmissionEvent(
			t,
			messageBusiness,
			room.GetId(),
			formEventID,
			formInstanceID,
			assignee,
			map[string]any{"full_name": "Allowed Assignee"},
		)
		require.Nil(t, assigneeAck.GetError())
	})
}

func (s *MessageBusinessTestSuite) sendFormRequestEvent(
	t *testing.T,
	messageBusiness business.MessageBusiness,
	roomID string,
	sender *commonv1.ContactLink,
	formInstanceID string,
	assigneeSubscriptionID string,
) *chatv1.AckEvent {
	t.Helper()

	req := &chatv1.SendEventRequest{
		Event: []*chatv1.RoomEvent{
			{
				RoomId: roomID,
				Type:   chatv1.RoomEventType_ROOM_EVENT_TYPE_FORM_REQUEST,
				Payload: &chatv1.Payload{
					Type: chatv1.PayloadType_PAYLOAD_TYPE_FORM_REQUEST,
					Data: &chatv1.Payload_FormRequest{
						FormRequest: &chatv1.FormRequestContent{
							FormInstanceId: formInstanceID,
							SchemaId:       "profile_update",
							SchemaVersion:  1,
							Title:          "Profile update",
							Permissions: &chatv1.FormPermissions{
								CanEdit:                true,
								CanSubmit:              true,
								CanSaveDraft:           true,
								CanGoBack:              true,
								AssigneeSubscriptionId: assigneeSubscriptionID,
							},
							Schema: sampleChatFormSchema(),
						},
					},
				},
			},
		},
	}

	acks, err := messageBusiness.SendEvents(t.Context(), req, sender)
	require.NoError(t, err)
	require.Len(t, acks, 1)
	require.Nil(t, acks[0].GetError())
	require.Len(t, acks[0].GetEventId(), 1)

	return acks[0]
}

func (s *MessageBusinessTestSuite) sendFormSubmissionEvent(
	t *testing.T,
	messageBusiness business.MessageBusiness,
	roomID string,
	parentEventID string,
	formInstanceID string,
	sender *commonv1.ContactLink,
	answers map[string]any,
) *chatv1.AckEvent {
	t.Helper()

	answerStruct, err := structpb.NewStruct(answers)
	require.NoError(t, err)

	req := &chatv1.SendEventRequest{
		Event: []*chatv1.RoomEvent{
			{
				RoomId:   roomID,
				ParentId: &parentEventID,
				Type:     chatv1.RoomEventType_ROOM_EVENT_TYPE_FORM_SUBMISSION_RESULT,
				Payload: &chatv1.Payload{
					Type: chatv1.PayloadType_PAYLOAD_TYPE_FORM_SUBMISSION_RESULT,
					Data: &chatv1.Payload_FormSubmissionResult{
						FormSubmissionResult: &chatv1.FormSubmissionResultContent{
							FormInstanceId:  formInstanceID,
							SchemaId:        "profile_update",
							SchemaVersion:   1,
							ReviewConfirmed: true,
							SubmissionSnapshot: &chatv1.FormSubmissionSnapshot{
								Answers: answerStruct,
							},
						},
					},
				},
			},
		},
	}

	acks, err := messageBusiness.SendEvents(t.Context(), req, sender)
	require.NoError(t, err)
	require.Len(t, acks, 1)

	return acks[0]
}

func (s *MessageBusinessTestSuite) lookupSubscriptionID(
	ctx context.Context,
	t *testing.T,
	roomBusiness business.RoomBusiness,
	roomID string,
	requester *commonv1.ContactLink,
	profileID string,
) string {
	t.Helper()

	subs, err := roomBusiness.SearchRoomSubscriptions(
		ctx,
		&chatv1.SearchRoomSubscriptionsRequest{RoomId: roomID},
		requester,
	)
	require.NoError(t, err)

	for _, sub := range subs {
		if sub.GetMember().GetProfileId() == profileID {
			return sub.GetId()
		}
	}

	t.Fatalf("subscription for profile %s not found", profileID)
	return ""
}

func sampleChatFormSchema() *chatv1.FormSchema {
	return &chatv1.FormSchema{
		FormId:      "profile_update",
		FormVersion: 1,
		Title:       "Profile update",
		Steps: []*chatv1.FormStep{
			{
				Id:    "identity",
				Title: "Identity",
				Sections: []*chatv1.FormSection{
					{
						Id:    "basic_details",
						Title: "Basic details",
						Fields: []*chatv1.FormField{
							{
								Key:      "full_name",
								Type:     chatv1.FormFieldType_FORM_FIELD_TYPE_TEXT,
								Label:    "Full name",
								Required: true,
							},
						},
					},
				},
			},
		},
	}
}
