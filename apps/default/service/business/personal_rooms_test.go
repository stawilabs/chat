package business_test

import (
	"fmt"
	"sync"
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

func (f *stawiFixture) grantRoomResolve(t *testing.T, profileID string) {
	t.Helper()
	require.NoError(t, f.keto.WriteTuple(f.ctx, security.RelationTuple{
		Object: security.ObjectRef{
			Namespace: business.ServiceNamespace,
			ID:        fmt.Sprintf("%s/%s", cardTenant, cardPartition),
		},
		Relation: "granted_" + business.PermissionStawiRoomResolve,
		Subject:  security.SubjectRef{Namespace: security.NamespaceProfile, ID: profileID},
	}))
}

// activeProfiles is the profile ids of a room's active subscriptions.
func (f *stawiFixture) activeProfiles(t *testing.T, roomID string) []string {
	t.Helper()
	subs, err := f.subRepo.GetByRoomID(f.ctx, roomID, nil)
	require.NoError(t, err)
	profiles := make([]string, 0, len(subs))
	for _, sub := range subs {
		profiles = append(profiles, sub.ProfileID)
	}
	return profiles
}

// roleOf is the role of a profile's active subscription in a room.
func (f *stawiFixture) roleOf(t *testing.T, roomID, profileID string) string {
	t.Helper()
	subs, err := f.subRepo.GetByContactLinkAndRooms(f.ctx, &commonv1.ContactLink{ProfileId: profileID}, roomID)
	require.NoError(t, err)
	require.Len(t, subs, 1)
	return subs[0].Role
}

// leave deactivates a person's subscription to a room, as leaving does.
func (f *stawiFixture) leave(t *testing.T, roomID string, member *commonv1.ContactLink) {
	t.Helper()
	subs, err := f.subRepo.GetByContactLinkAndRooms(f.ctx,
		&commonv1.ContactLink{ProfileId: member.GetProfileId()}, roomID)
	require.NoError(t, err)
	require.Len(t, subs, 1)
	require.NoError(t, f.subRepo.Deactivate(f.ctx, subs[0].GetID()))
}

// keyedRooms is the rooms of a key in the card tenancy.
func (f *stawiFixture) keyedRooms(t *testing.T, key string) []*models.Room {
	t.Helper()
	rooms, err := f.roomRepo.DirectRooms(f.ctx, key, cardTenant, []string{cardPartition})
	require.NoError(t, err)
	return rooms
}

func directRequest(people ...string) *chatv1.CreateRoomRequest {
	members := make([]*commonv1.ContactLink, 0, len(people))
	for _, p := range people {
		members = append(members, &commonv1.ContactLink{ProfileId: p})
	}
	return &chatv1.CreateRoomRequest{Name: "Direct message", Type: chatv1.RoomType_ROOM_TYPE_DIRECT, Members: members}
}

func botRequest(person string) *chatv1.CreateRoomRequest {
	return &chatv1.CreateRoomRequest{Type: chatv1.RoomType_ROOM_TYPE_BOT,
		Members: []*commonv1.ContactLink{{ProfileId: person}}}
}

// TestAServiceResolvesThePairsRealDM: finance's service identity, holding
// stawi_room_resolve, gets the DM the two people already chat in (the oldest
// of that pair whose members are exactly the two), not a room of its own; a
// DM someone left is skipped; with none, one is created holding the two.
func (s *MessageBusinessTestSuite) TestAServiceResolvesThePairsRealDM() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		finance := util.IDString()
		f.grantRoomResolve(t, finance)
		svcCtx := serviceCtx(f.ctx, finance, true)
		alice := &commonv1.ContactLink{ProfileId: util.IDString(), ContactId: util.IDString()}
		bob := &commonv1.ContactLink{ProfileId: util.IDString()}
		dm := func() *chatv1.CreateRoomRequest {
			return directRequest(alice.GetProfileId(), bob.GetProfileId())
		}

		theirs, err := f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{
			Name: "Bob", Type: chatv1.RoomType_ROOM_TYPE_DIRECT, Members: []*commonv1.ContactLink{bob},
		}, alice)
		require.NoError(t, err)
		f.placeRoom(t, theirs.GetId(), cardTenant, cardPartition)
		// A newer DM of the same pair is not the answer: the oldest is.
		newer, err := f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{
			Name: "Alice", Type: chatv1.RoomType_ROOM_TYPE_DIRECT,
			Members: []*commonv1.ContactLink{{ProfileId: alice.GetProfileId()}},
		},
			&commonv1.ContactLink{ProfileId: bob.GetProfileId(), ContactId: util.IDString()})
		require.NoError(t, err)
		f.placeRoom(t, newer.GetId(), cardTenant, cardPartition)
		// The same pair's DM in another tenancy is never answered.
		foreign, err := f.rb.CreateRoom(f.ctx, &chatv1.CreateRoomRequest{Name: "Elsewhere",
			Type: chatv1.RoomType_ROOM_TYPE_DIRECT, Members: []*commonv1.ContactLink{bob}}, alice)
		require.NoError(t, err)
		f.placeRoom(t, foreign.GetId(), "tenant-other", cardPartition)

		got, err := f.rb.ResolvePersonalRoom(svcCtx, dm())
		require.NoError(t, err)
		require.Equal(t, theirs.GetId(), got.GetId(), "the people's own DM")
		require.Equal(t, chatv1.RoomType_ROOM_TYPE_DIRECT, got.GetType())
		require.Len(t, f.activeProfiles(t, got.GetId()), 2, "finance is not a member")

		// Bob leaves both: neither holds exactly the two any more.
		f.leave(t, theirs.GetId(), bob)
		f.leave(t, newer.GetId(), bob)
		fresh, err := f.rb.ResolvePersonalRoom(svcCtx, dm())
		require.NoError(t, err)
		require.NotEqual(t, theirs.GetId(), fresh.GetId())
		require.NotEqual(t, newer.GetId(), fresh.GetId())
		require.NotEqual(t, foreign.GetId(), fresh.GetId())
		require.Equal(t, chatv1.RoomType_ROOM_TYPE_DIRECT, fresh.GetType())
		require.True(t, fresh.GetIsPrivate())
		require.Equal(t, "Direct message", fresh.GetName())
		require.ElementsMatch(t, []string{alice.GetProfileId(), bob.GetProfileId()}, f.activeProfiles(t, fresh.GetId()))
		require.ElementsMatch(t, []string{alice.GetProfileId()}, f.activeProfiles(t, theirs.GetId()),
			"the room someone left gains no one")
		stored, err := f.roomRepo.GetByID(f.ctx, fresh.GetId())
		require.NoError(t, err)
		require.Equal(t, models.DirectKey(alice.GetProfileId(), bob.GetProfileId()), stored.DirectKey)
		require.Equal(t, cardTenant, stored.TenantID, "the room is in the caller's tenancy")
		require.Equal(t, cardPartition, stored.PartitionID)

		again, err := f.rb.ResolvePersonalRoom(svcCtx, directRequest(bob.GetProfileId(), alice.GetProfileId()))
		require.NoError(t, err)
		require.Equal(t, fresh.GetId(), again.GetId(), "resolved once, reused, in either order")

		// Both people can use the new DM as soon as it is answered.
		for _, person := range []string{alice.GetProfileId(), bob.GetProfileId()} {
			subs, subErr := f.subRepo.GetByContactLinkAndRooms(f.ctx,
				&commonv1.ContactLink{ProfileId: person}, fresh.GetId())
			require.NoError(t, subErr)
			require.Len(t, subs, 1)
			require.NoError(t, f.authz.CanRoomView(f.ctx, subs[0].GetID(), fresh.GetId()))
		}
	})
}

// TestAServicesNoticesRoomIsItsAndThePersons: BOT with one person is created
// once, holding the person (member) and the calling service (owner), and
// returned after; another service's room with the same person is its own.
func (s *MessageBusinessTestSuite) TestAServicesNoticesRoomIsItsAndThePersons() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		finance, other := util.IDString(), util.IDString()
		f.grantRoomResolve(t, finance)
		f.grantRoomResolve(t, other)
		alice := util.IDString()

		notices, err := f.rb.ResolvePersonalRoom(serviceCtx(f.ctx, finance, true), botRequest(alice))
		require.NoError(t, err)
		require.Equal(t, chatv1.RoomType_ROOM_TYPE_BOT, notices.GetType())
		require.Equal(t, "Stawi notices", notices.GetName())
		require.True(t, notices.GetIsPrivate())
		require.ElementsMatch(t, []string{alice, finance}, f.activeProfiles(t, notices.GetId()))
		require.Equal(t, "owner", f.roleOf(t, notices.GetId(), finance))
		require.Equal(t, "member", f.roleOf(t, notices.GetId(), alice))

		again, err := f.rb.ResolvePersonalRoom(serviceCtx(f.ctx, finance, true), botRequest(alice))
		require.NoError(t, err)
		require.Equal(t, notices.GetId(), again.GetId())
		require.Len(t, f.keyedRooms(t, models.BotKey(finance, alice)), 1)

		theirs, err := f.rb.ResolvePersonalRoom(serviceCtx(f.ctx, other, true), botRequest(alice))
		require.NoError(t, err)
		require.NotEqual(t, notices.GetId(), theirs.GetId(), "another service's room is its own")
		require.ElementsMatch(t, []string{alice, other}, f.activeProfiles(t, theirs.GetId()))

		// Alice leaves: the next notice goes to a new room with her.
		f.leave(t, notices.GetId(), &commonv1.ContactLink{ProfileId: alice})
		renewed, err := f.rb.ResolvePersonalRoom(serviceCtx(f.ctx, finance, true), botRequest(alice))
		require.NoError(t, err)
		require.NotEqual(t, notices.GetId(), renewed.GetId())
		require.ElementsMatch(t, []string{alice, finance}, f.activeProfiles(t, renewed.GetId()))
	})
}

// TestPersonalRoomResolutionIsAServicesAndShaped: only a service principal
// holding the grant resolves, and only a well-formed DIRECT or BOT request;
// nothing is created by a refused call.
func (s *MessageBusinessTestSuite) TestPersonalRoomResolutionIsAServicesAndShaped() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		finance := util.IDString()
		f.grantRoomResolve(t, finance)
		svcCtx := serviceCtx(f.ctx, finance, true)
		alice, bob, carol := util.IDString(), util.IDString(), util.IDString()

		ungranted := util.IDString()
		_, err := f.rb.ResolvePersonalRoom(serviceCtx(f.ctx, ungranted, true), directRequest(alice, bob))
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err))
		cardOnly := util.IDString()
		f.grantCardPost(t, cardOnly)
		_, err = f.rb.ResolvePersonalRoom(serviceCtx(f.ctx, cardOnly, true), directRequest(alice, bob))
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err), "stawi_card_post is not the grant")
		person := util.IDString()
		f.grantRoomResolve(t, person)
		_, err = f.rb.ResolvePersonalRoom(serviceCtx(f.ctx, person, false), directRequest(alice, bob))
		require.Equal(t, connect.CodePermissionDenied, connect.CodeOf(err), "a person is not a service")
		_, err = f.rb.ResolvePersonalRoom(f.ctx, directRequest(alice, bob))
		require.Equal(t, connect.CodeUnauthenticated, connect.CodeOf(err))

		withID := directRequest(alice, bob)
		withID.Id = util.IDString()
		withContact := directRequest(alice, bob)
		withContact.Members[0].ContactId = util.IDString()
		group := directRequest(alice, bob)
		group.Type = chatv1.RoomType_ROOM_TYPE_GROUP
		unspecified := directRequest(alice, bob)
		unspecified.Type = chatv1.RoomType_ROOM_TYPE_UNSPECIFIED
		botWithID := botRequest(alice)
		botWithID.Id = util.IDString()
		for name, req := range map[string]*chatv1.CreateRoomRequest{
			"DM of one":                 directRequest(alice),
			"DM of three":               directRequest(alice, bob, carol),
			"DM of one person twice":    directRequest(alice, alice),
			"DM with the caller":        directRequest(alice, finance),
			"DM naming a contact":       withContact,
			"DM with a supplied id":     withID,
			"DM with an empty member":   directRequest(alice, ""),
			"DM with a separator in id": directRequest(alice, "x:y"),
			"DM with an overlong id":    directRequest(alice, fmt.Sprintf("%047d", 1)),
			"GROUP":                     group,
			"UNSPECIFIED":               unspecified,
			"BOT of none":               {Type: chatv1.RoomType_ROOM_TYPE_BOT},
			"BOT of two":                directRequestAs(chatv1.RoomType_ROOM_TYPE_BOT, alice, bob),
			"BOT of the caller":         botRequest(finance),
			"BOT with a supplied id":    botWithID,
		} {
			_, err = f.rb.ResolvePersonalRoom(svcCtx, req)
			require.Equal(t, connect.CodeInvalidArgument, connect.CodeOf(err), name)
		}

		for _, key := range []string{
			models.DirectKey(alice, bob), models.DirectKey(alice, finance), models.DirectKey(alice, alice),
			models.BotKey(finance, alice), models.BotKey(ungranted, alice), models.BotKey(person, alice),
		} {
			require.Empty(t, f.keyedRooms(t, key), "nothing was created for %s", key)
		}
	})
}

func directRequestAs(roomType chatv1.RoomType, people ...string) *chatv1.CreateRoomRequest {
	req := directRequest(people...)
	req.Type = roomType
	return req
}

// TestConcurrentResolutionsAnswerOneRoom: many resolutions of the same pair
// at once all answer the same room, and exactly one room is created.
func (s *MessageBusinessTestSuite) TestConcurrentResolutionsAnswerOneRoom() {
	s.WithTestDependencies(s.T(), func(t *testing.T, dep *definition.DependencyOption) {
		f := s.newStawiFixture(t, dep)
		finance := util.IDString()
		f.grantRoomResolve(t, finance)
		svcCtx := serviceCtx(f.ctx, finance, true)
		alice, bob := util.IDString(), util.IDString()

		const callers = 12
		ids := make([]string, callers)
		errs := make([]error, callers)
		var wg sync.WaitGroup
		start := make(chan struct{})
		for i := range callers {
			wg.Add(1)
			go func() {
				defer wg.Done()
				<-start
				req := directRequest(alice, bob)
				if i%2 == 1 {
					req = directRequest(bob, alice)
				}
				room, err := f.rb.ResolvePersonalRoom(svcCtx, req)
				errs[i] = err
				ids[i] = room.GetId()
			}()
		}
		close(start)
		wg.Wait()

		for i := range callers {
			require.NoError(t, errs[i], "caller %d", i)
			require.Equal(t, ids[0], ids[i], "caller %d answered another room", i)
		}
		rooms := f.keyedRooms(t, models.DirectKey(alice, bob))
		require.Len(t, rooms, 1, "exactly one room created")
		require.Equal(t, ids[0], rooms[0].GetID())
		require.ElementsMatch(t, []string{alice, bob}, f.activeProfiles(t, ids[0]))
	})
}
