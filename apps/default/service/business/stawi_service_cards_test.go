package business_test

import (
	"context"
	"fmt"
	"testing"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/pitabwire/frame/v2/frametests/definition"
	"github.com/pitabwire/frame/v2/security"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/service/business"
)

const (
	cardTenant    = "tenant-stawi"
	cardPartition = "partition-stawi"
)

// serviceCtx is the context of a caller authenticated as a service account.
func serviceCtx(ctx context.Context, profileID string, internal bool) context.Context {
	claims := &security.AuthenticationClaims{TenantID: cardTenant, PartitionID: cardPartition}
	claims.Subject = profileID
	if internal {
		claims.Roles = []string{security.ConstantSystemInternalRole}
	}
	return claims.ClaimsToContext(ctx)
}

func (f *stawiFixture) grantCardPost(t *testing.T, profileID string) {
	t.Helper()
	require.NoError(t, f.keto.WriteTuple(f.ctx, security.RelationTuple{
		Object: security.ObjectRef{
			Namespace: business.ServiceNamespace,
			ID:        fmt.Sprintf("%s/%s", cardTenant, cardPartition),
		},
		Relation: "granted_" + business.PermissionStawiCardPost,
		Subject:  security.SubjectRef{Namespace: security.NamespaceProfile, ID: profileID},
	}))
}

func cardEvent(roomID string, payload *chatv1.Payload, eventType chatv1.RoomEventType) *chatv1.SendEventRequest {
	return &chatv1.SendEventRequest{Event: []*chatv1.RoomEvent{{RoomId: roomID, Type: eventType, Payload: payload}}}
}

func financeCard(roomID string) *chatv1.SendEventRequest {
	return cardEvent(roomID, &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_FINANCE_CARD,
		Data: &chatv1.Payload_FinanceCard{FinanceCard: &chatv1.FinanceCardContent{
			CardId: "fact-1", GroupId: roomID, Kind: "CONTRIBUTION", Title: "Contribution received",
		}},
	}, chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT)
}

// TestServiceCardsPostIntoABoundRoomWithoutMembership: finance's service
// identity, holding stawi_card_post, posts cards and text into a Stawi room
// it is not a member of; members see them; nothing else gets through.
func (s *MessageBusinessTestSuite) TestServiceCardsPostIntoABoundRoomWithoutMembership() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		finance := util.IDString()
		f.grantCardPost(t, finance)
		svcCtx := serviceCtx(f.ctx, finance, true)

		// Not on chain yet.
		acks, err := f.mb.SendServiceEvents(svcCtx, financeCard(f.roomID))
		require.NoError(t, err)
		requireAckRefused(t, acks[0], connect.CodeFailedPrecondition)

		f.bind(t)
		acks, err = f.mb.SendServiceEvents(svcCtx, financeCard(f.roomID))
		require.NoError(t, err)
		cardID := requireAckOK(t, acks[0])
		acks, err = f.mb.SendServiceEvents(svcCtx, cardEvent(f.roomID, &chatv1.Payload{
			Type: chatv1.PayloadType_PAYLOAD_TYPE_TEXT,
			Data: &chatv1.Payload_Text{
				Text: &chatv1.TextContent{Body: "Contributions are due Friday", Format: "plain"},
			},
		}, chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE))
		require.NoError(t, err)
		requireAckOK(t, acks[0])

		stored := f.stored(t, cardID)
		require.NotNil(t, stored, "members see the card")
		require.Equal(t, "Contribution received", stored.GetPayload().GetFinanceCard().GetTitle())
		require.Empty(t, stored.GetSubscriptionId(), "the service is not a member")

		// Only cards and text.
		for name, payload := range map[string]*chatv1.Payload{
			"signed call": signedCall("call-1", "INVITE"),
			"motion": {Type: chatv1.PayloadType_PAYLOAD_TYPE_MOTION,
				Data: &chatv1.Payload_Motion{Motion: &chatv1.MotionContent{Id: "m"}}},
			"outcome": {Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_CALL_OUTCOME,
				Data: &chatv1.Payload_StawiCallOutcome{StawiCallOutcome: &chatv1.StawiCallOutcomeContent{CallId: "c"}}},
		} {
			t.Run(name, func(t *testing.T) {
				refused, sendErr := f.mb.SendServiceEvents(svcCtx,
					cardEvent(f.roomID, payload, chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT))
				require.NoError(t, sendErr)
				requireAckRefused(t, refused[0], connect.CodeInvalidArgument)
			})
		}
	})
}

// TestServiceCardsNeedAServicePrincipalWithTheGrant: no grant, a person (not
// a service principal) holding the grant, or no authentication: refused.
func (s *MessageBusinessTestSuite) TestServiceCardsNeedAServicePrincipalWithTheGrant() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		f.bind(t)

		ungranted := util.IDString()
		_, err := f.mb.SendServiceEvents(serviceCtx(f.ctx, ungranted, true), financeCard(f.roomID))
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err))

		person := util.IDString()
		f.grantCardPost(t, person)
		_, err = f.mb.SendServiceEvents(serviceCtx(f.ctx, person, false), financeCard(f.roomID))
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err))

		_, err = f.mb.SendServiceEvents(f.ctx, financeCard(f.roomID))
		require.Equal(t, connect.CodeUnauthenticated, connect.CodeOf(err))

		for _, evt := range f.history(t) {
			require.Nil(t, evt.GetPayload().GetFinanceCard(), "nothing was posted")
		}
	})
}
