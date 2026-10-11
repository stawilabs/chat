package business_test

import (
	"context"
	"fmt"
	"strings"
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

// placeRoom puts a room in a tenant and partition, as a room created by a
// user of that tenancy would be.
func (f *stawiFixture) placeRoom(t *testing.T, roomID, tenant, partition string) {
	t.Helper()
	require.NoError(t, f.dbPool.DB(f.ctx, false).Table("rooms").Where("id = ?", roomID).
		Updates(map[string]any{"tenant_id": tenant, "partition_id": partition}).Error)
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
		f.placeRoom(t, f.roomID, cardTenant, cardPartition)
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
		f.placeRoom(t, f.roomID, cardTenant, cardPartition)
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

// TestServiceCardsStayInTheCallersTenancy: a service of one tenant, holding
// the permission there, cannot post into another tenant's (or partition's)
// bound Stawi room.
func (s *MessageBusinessTestSuite) TestServiceCardsStayInTheCallersTenancy() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		f.bind(t)
		finance := util.IDString()
		f.grantCardPost(t, finance)
		svcCtx := serviceCtx(f.ctx, finance, true)

		for name, place := range map[string][2]string{
			"another tenant":    {"tenant-other", cardPartition},
			"another partition": {cardTenant, "partition-other"},
			"no tenancy":        {"", ""},
		} {
			t.Run(name, func(t *testing.T) {
				f.placeRoom(t, f.roomID, place[0], place[1])
				acks, err := f.mb.SendServiceEvents(svcCtx, financeCard(f.roomID))
				require.NoError(t, err)
				requireAckRefused(t, acks[0], connect.CodePermissionDenied)
			})
		}
		for _, evt := range f.history(t) {
			require.Nil(t, evt.GetPayload().GetFinanceCard(), "nothing crossed tenants")
		}
	})
}

// TestServiceCardsGetTheMemberPathsValidation: a service gets no shortcut —
// declared type must match the content (no ROOM_CHANGE or outcome spoofing),
// cards and text keep their proto limits, and event types are enforced.
func (s *MessageBusinessTestSuite) TestServiceCardsGetTheMemberPathsValidation() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		f.placeRoom(t, f.roomID, cardTenant, cardPartition)
		f.bind(t)
		finance := util.IDString()
		f.grantCardPost(t, finance)
		svcCtx := serviceCtx(f.ctx, finance, true)

		card := func(mut func(*chatv1.FinanceCardContent)) *chatv1.FinanceCardContent {
			c := &chatv1.FinanceCardContent{CardId: "c-1", GroupId: "g-1", Kind: "CONTRIBUTION", Title: "Paid"}
			mut(c)
			return c
		}
		long := strings.Repeat("x", 4001)
		cases := map[string]*chatv1.SendEventRequest{
			"card declared as room change": cardEvent(f.roomID, &chatv1.Payload{
				Type: chatv1.PayloadType_PAYLOAD_TYPE_ROOM_CHANGE,
				Data: &chatv1.Payload_FinanceCard{FinanceCard: card(func(*chatv1.FinanceCardContent) {})},
			}, chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT),
			"card declared as outcome": cardEvent(f.roomID, &chatv1.Payload{
				Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_CALL_OUTCOME,
				Data: &chatv1.Payload_FinanceCard{FinanceCard: card(func(*chatv1.FinanceCardContent) {})},
			}, chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT),
			"text declared as card": cardEvent(f.roomID, &chatv1.Payload{
				Type: chatv1.PayloadType_PAYLOAD_TYPE_FINANCE_CARD,
				Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "hi", Format: "plain"}},
			}, chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE),
			"room change": cardEvent(f.roomID, &chatv1.Payload{
				Type: chatv1.PayloadType_PAYLOAD_TYPE_ROOM_CHANGE,
				Data: &chatv1.Payload_RoomChange{RoomChange: &chatv1.RoomChangeContent{Body: "x joined"}},
			}, chatv1.RoomEventType_ROOM_EVENT_TYPE_SYSTEM),
			"oversized card body": cardEvent(f.roomID, &chatv1.Payload{
				Type: chatv1.PayloadType_PAYLOAD_TYPE_FINANCE_CARD,
				Data: &chatv1.Payload_FinanceCard{
					FinanceCard: card(func(c *chatv1.FinanceCardContent) { c.Body = long }),
				},
			}, chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT),
			"card without id": cardEvent(f.roomID, &chatv1.Payload{
				Type: chatv1.PayloadType_PAYLOAD_TYPE_FINANCE_CARD,
				Data: &chatv1.Payload_FinanceCard{
					FinanceCard: card(func(c *chatv1.FinanceCardContent) { c.CardId = "" }),
				},
			}, chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT),
			"card as a message": cardEvent(f.roomID, &chatv1.Payload{
				Type: chatv1.PayloadType_PAYLOAD_TYPE_FINANCE_CARD,
				Data: &chatv1.Payload_FinanceCard{FinanceCard: card(func(*chatv1.FinanceCardContent) {})},
			}, chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE),
			"empty text": cardEvent(f.roomID, &chatv1.Payload{
				Type: chatv1.PayloadType_PAYLOAD_TYPE_TEXT,
				Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "", Format: "plain"}},
			}, chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE),
			"oversized text": cardEvent(f.roomID, &chatv1.Payload{
				Type: chatv1.PayloadType_PAYLOAD_TYPE_TEXT,
				Data: &chatv1.Payload_Text{
					Text: &chatv1.TextContent{Body: strings.Repeat("y", 10001), Format: "plain"},
				},
			}, chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE),
			"text as a system event": cardEvent(f.roomID, &chatv1.Payload{
				Type: chatv1.PayloadType_PAYLOAD_TYPE_TEXT,
				Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: "hi", Format: "plain"}},
			}, chatv1.RoomEventType_ROOM_EVENT_TYPE_SYSTEM),
		}
		for name, req := range cases {
			t.Run(name, func(t *testing.T) {
				acks, err := f.mb.SendServiceEvents(svcCtx, req)
				require.NoError(t, err)
				requireAckRefused(t, acks[0], connect.CodeInvalidArgument)
			})
		}
		for _, evt := range f.history(t) {
			require.Nil(t, evt.GetPayload().GetFinanceCard(), "nothing malformed was stored")
		}
	})
}
