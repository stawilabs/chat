package business_test

import (
	"context"
	"fmt"
	"strings"
	"testing"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/pitabwire/frame/v2/frametests/definition"
	"github.com/pitabwire/frame/v2/security"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/service/business"
	"github.com/stawilabs/chat/apps/default/service/models"
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

// TestServiceCardBatchIsCheckedPerEvent: one batch mixing an allowed card with
// a card for a room in another tenancy, a type-spoofed card and an unbound
// room: each event is gated on its own room and payload, so only the allowed
// one is written.
func (s *MessageBusinessTestSuite) TestServiceCardBatchIsCheckedPerEvent() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		f.placeRoom(t, f.roomID, cardTenant, cardPartition)
		f.bind(t)
		finance := util.IDString()
		f.grantCardPost(t, finance)

		foreign, err := f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{Name: "Foreign"}, f.alice)
		require.NoError(t, err)
		f.placeRoom(t, foreign.GetId(), "tenant-other", cardPartition)
		foreignBinding := &models.StawiRoom{State: models.StawiRoomStateBound}
		foreignBinding.ID = foreign.GetId()
		require.NoError(t, f.bindings.Create(f.ctx, foreignBinding))

		unbound, err := f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{Name: "Unbound"}, f.alice)
		require.NoError(t, err)
		f.placeRoom(t, unbound.GetId(), cardTenant, cardPartition)

		good := financeCard(f.roomID).GetEvent()[0]
		toForeign := financeCard(foreign.GetId()).GetEvent()[0]
		spoofed := financeCard(f.roomID).GetEvent()[0]
		spoofed.Payload.Type = chatv1.PayloadType_PAYLOAD_TYPE_ROOM_CHANGE
		toUnbound := financeCard(unbound.GetId()).GetEvent()[0]

		acks, err := f.mb.SendServiceEvents(serviceCtx(f.ctx, finance, true), &chatv1.SendEventRequest{
			Event: []*chatv1.RoomEvent{good, toForeign, spoofed, toUnbound},
		})
		require.NoError(t, err)
		require.Len(t, acks, 4)
		requireAckOK(t, acks[0])
		requireAckRefused(t, acks[1], connect.CodePermissionDenied)
		requireAckRefused(t, acks[2], connect.CodeInvalidArgument)
		requireAckRefused(t, acks[3], connect.CodeFailedPrecondition)

		for _, roomID := range []string{foreign.GetId(), unbound.GetId()} {
			events, histErr := f.mb.GetHistory(f.ctx, &chatv1.GetHistoryRequest{RoomId: roomID}, f.alice)
			require.NoError(t, histErr)
			for _, evt := range events {
				require.Nil(t, evt.GetPayload().GetFinanceCard(), "nothing written to %s", roomID)
			}
		}
	})
}

// TestServiceCardsPostIntoAPersonalRoom: a resolved DM takes a service's card
// (stored, from no subscription); a service's bot room takes cards from that
// service only; a plain group room the chain does not have is still refused.
func (s *MessageBusinessTestSuite) TestServiceCardsPostIntoAPersonalRoom() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		finance, other := util.IDString(), util.IDString()
		for _, svc := range []string{finance, other} {
			f.grantRoomResolve(t, svc)
			f.grantCardPost(t, svc)
		}
		svcCtx := serviceCtx(f.ctx, finance, true)
		alice, bob := util.IDString(), util.IDString()

		dm, err := f.rb.ResolvePersonalRoom(svcCtx, directRequest(alice, bob))
		require.NoError(t, err)
		acks, err := f.mb.SendServiceEvents(svcCtx, financeCard(dm.GetId()))
		require.NoError(t, err)
		cardID := requireAckOK(t, acks[0])
		events, err := f.mb.GetHistory(f.ctx, &chatv1.GetHistoryRequest{RoomId: dm.GetId()},
			&commonv1.ContactLink{ProfileId: alice, ContactId: util.IDString()})
		require.NoError(t, err)
		var stored *chatv1.RoomEvent
		for _, evt := range events {
			if evt.GetId() == cardID {
				stored = evt
			}
		}
		require.NotNil(t, stored, "the people see the card")
		require.Equal(t, "Contribution received", stored.GetPayload().GetFinanceCard().GetTitle())
		require.Empty(t, stored.GetSubscriptionId(), "the service is not a member")
		acks, err = f.mb.SendServiceEvents(serviceCtx(f.ctx, other, true), financeCard(dm.GetId()))
		require.NoError(t, err)
		requireAckOK(t, acks[0])

		notices, err := f.rb.ResolvePersonalRoom(svcCtx, botRequest(alice))
		require.NoError(t, err)
		acks, err = f.mb.SendServiceEvents(svcCtx, financeCard(notices.GetId()))
		require.NoError(t, err)
		requireAckOK(t, acks[0])
		acks, err = f.mb.SendServiceEvents(serviceCtx(f.ctx, other, true), financeCard(notices.GetId()))
		require.NoError(t, err)
		requireAckRefused(t, acks[0], connect.CodePermissionDenied)

		group, err := f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{Name: "Plain group"}, f.alice)
		require.NoError(t, err)
		f.placeRoom(t, group.GetId(), cardTenant, cardPartition)
		acks, err = f.mb.SendServiceEvents(svcCtx, financeCard(group.GetId()))
		require.NoError(t, err)
		requireAckRefused(t, acks[0], connect.CodeFailedPrecondition)

		// A DM in another tenancy stays out of reach.
		f.placeRoom(t, dm.GetId(), "tenant-other", cardPartition)
		acks, err = f.mb.SendServiceEvents(svcCtx, financeCard(dm.GetId()))
		require.NoError(t, err)
		requireAckRefused(t, acks[0], connect.CodePermissionDenied)
	})
}
