package business_test

import (
	"fmt"
	"strings"
	"testing"
	"time"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect/v2"
	"github.com/pitabwire/frame/v3/frametests/definition"
	"github.com/pitabwire/frame/v3/security"
	"github.com/pitabwire/util"
	"github.com/stretchr/testify/require"

	"github.com/stawilabs/chat/apps/default/service/business"
	"github.com/stawilabs/chat/apps/default/service/events"
	"github.com/stawilabs/chat/apps/default/service/models"
)

const testPoolAddress = "0x00000000000000000000000000000000000000c3"

// grantPermission grants permission on chat's functional namespace to a
// profile in the card tenancy.
func (f *stawiFixture) grantPermission(t *testing.T, profileID, permission string) {
	t.Helper()
	require.NoError(t, f.keto.WriteTuple(f.ctx, security.RelationTuple{
		Object: security.ObjectRef{
			Namespace: business.ServiceNamespace,
			ID:        fmt.Sprintf("%s/%s", cardTenant, cardPartition),
		},
		Relation: "granted_" + permission,
		Subject:  security.SubjectRef{Namespace: security.NamespaceProfile, ID: profileID},
	}))
}

// bindPool marks a room as a trading group by recording its server-side
// pool binding, as a validated CreateRoom/UpdateRoom by the pool leader does.
func (f *stawiFixture) bindPool(t *testing.T, roomID, pool string) {
	t.Helper()
	require.NoError(t, f.poolBindings.Upsert(f.ctx, &models.SocialTraderRoomBinding{
		RoomID: roomID, PoolID: pool, LeaderProfileID: "leader", BoundAt: time.Now(),
	}))
}

// claimPoolInMetadata writes the pool metadata hint without any binding, as
// any room owner could through UpdateRoom before validation existed.
func (f *stawiFixture) claimPoolInMetadata(t *testing.T, roomID, pool string) {
	t.Helper()
	room, err := f.roomRepo.GetByID(f.ctx, roomID)
	require.NoError(t, err)
	if room.Properties == nil {
		room.Properties = map[string]any{}
	}
	room.Properties[events.SocialTraderPoolMetadataKey] = pool
	_, err = f.roomRepo.Update(f.ctx, room)
	require.NoError(t, err)
}

func poolCard(roomID, kind string) *chatv1.SendEventRequest {
	return poolCardFor(roomID, kind, testPoolAddress)
}

func poolCardFor(roomID, kind, pool string) *chatv1.SendEventRequest {
	body := fmt.Sprintf(`{"socialtrader":{"kind":%q,"v":1,"pool":%q}}`, kind, pool)
	return cardEvent(roomID, &chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_TEXT,
		Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: body, Format: "json"}},
	}, chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE)
}

// TestServiceCards_SocialTraderCardNeedsItsPermission: a pool card (JSON text
// with the socialtrader discriminator) is gated by socialtrader_card_post,
// not stawi_card_post, and goes only into a room bound to a pool; a finance
// card keeps needing stawi_card_post.
func (s *MessageBusinessTestSuite) TestServiceCards_SocialTraderCardNeedsItsPermission() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		f.placeRoom(t, f.roomID, cardTenant, cardPartition)
		f.bindPool(t, f.roomID, testPoolAddress)

		finance, trader := util.IDString(), util.IDString()
		f.grantPermission(t, finance, business.PermissionStawiCardPost)
		f.grantPermission(t, trader, business.PermissionSocialTraderCardPost)

		// stawi_card_post alone does not post pool cards.
		_, err := f.mb.SendServiceEvents(serviceCtx(f.ctx, finance, true), poolCard(f.roomID, "pool_join_prompt"))
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err), "%v", err)

		// socialtrader_card_post posts them into the pool-bound room.
		acks, err := f.mb.SendServiceEvents(serviceCtx(f.ctx, trader, true), poolCard(f.roomID, "pool_join_prompt"))
		require.NoError(t, err)
		cardID := requireAckOK(t, acks[0])
		stored := f.stored(t, cardID)
		require.NotNil(t, stored, "members see the card")
		require.Equal(t, "json", stored.GetPayload().GetText().GetFormat())
		require.Contains(t, stored.GetPayload().GetText().GetBody(), `"pool_join_prompt"`)

		// socialtrader_card_post alone does not post finance cards.
		_, err = f.mb.SendServiceEvents(serviceCtx(f.ctx, trader, true), financeCard(f.roomID))
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err), "%v", err)

		// A pool card into a room that is not a trading group is refused.
		plain, err := f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{Name: "Plain"}, f.alice)
		require.NoError(t, err)
		f.placeRoom(t, plain.GetId(), cardTenant, cardPartition)
		acks, err = f.mb.SendServiceEvents(serviceCtx(f.ctx, trader, true), poolCard(plain.GetId(), "pool_nav"))
		require.NoError(t, err)
		requireAckRefused(t, acks[0], connect.CodeFailedPrecondition)

		// Plain JSON text that is not a pool card is still a finance text card.
		notACard := cardEvent(f.roomID, &chatv1.Payload{
			Type: chatv1.PayloadType_PAYLOAD_TYPE_TEXT,
			Data: &chatv1.Payload_Text{Text: &chatv1.TextContent{Body: `{"hello":1}`, Format: "json"}},
		}, chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE)
		_, err = f.mb.SendServiceEvents(serviceCtx(f.ctx, trader, true), notACard)
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err), "%v", err)
	})
}

// TestServiceCards_PoolCardRejectedWithoutBindingRow: a room whose metadata
// names a pool but has no server-side binding is not a trading group; the
// pool card is refused.
func (s *MessageBusinessTestSuite) TestServiceCards_PoolCardRejectedWithoutBindingRow() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		f.placeRoom(t, f.roomID, cardTenant, cardPartition)
		f.claimPoolInMetadata(t, f.roomID, testPoolAddress)
		trader := util.IDString()
		f.grantPermission(t, trader, business.PermissionSocialTraderCardPost)

		acks, err := f.mb.SendServiceEvents(serviceCtx(f.ctx, trader, true), poolCard(f.roomID, "pool_join_prompt"))
		require.NoError(t, err)
		requireAckRefused(t, acks[0], connect.CodeFailedPrecondition)
		for _, evt := range f.history(t) {
			require.NotEqual(t, "json", evt.GetPayload().GetText().GetFormat(), "nothing was posted")
		}
	})
}

// TestServiceCards_PoolCardRejectedWhenPoolMismatchesBinding: a card about a
// pool other than the one the room is bound to is refused; the bound pool's
// card, in any address case, is accepted.
func (s *MessageBusinessTestSuite) TestServiceCards_PoolCardRejectedWhenPoolMismatchesBinding() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		f.placeRoom(t, f.roomID, cardTenant, cardPartition)
		f.bindPool(t, f.roomID, testPoolAddress)
		trader := util.IDString()
		f.grantPermission(t, trader, business.PermissionSocialTraderCardPost)
		svcCtx := serviceCtx(f.ctx, trader, true)

		other := "0x00000000000000000000000000000000000000e5"
		acks, err := f.mb.SendServiceEvents(svcCtx, poolCardFor(f.roomID, "pool_nav", other))
		require.NoError(t, err)
		requireAckRefused(t, acks[0], connect.CodePermissionDenied)

		acks, err = f.mb.SendServiceEvents(svcCtx, poolCardFor(f.roomID, "pool_nav", strings.ToUpper(testPoolAddress)))
		require.NoError(t, err)
		requireAckOK(t, acks[0])
	})
}
