package business

import (
	"context"
	"fmt"
	"slices"
	"strings"
	"time"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect/v2"
	"github.com/pitabwire/frame/v3/data"
	"github.com/pitabwire/util"

	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/pkg/chatutil"
	chattel "github.com/stawilabs/chat/pkg/telemetry"
)

// PermissionStawiRoomResolve lets a service principal find or create a
// person's DM with another person, or its own room with one person, without
// being a member of a DM.
const PermissionStawiRoomResolve = "stawi_room_resolve"

const (
	defaultDirectRoomName = "Direct message"
	defaultBotRoomName    = "Stawi notices"
)

// WithPersonalRooms enables ResolvePersonalRoom, gated by checker.
func WithPersonalRooms(checker FunctionPermissionChecker) RoomBusinessOption {
	return func(rb *roomBusiness) { rb.roomResolveChecker = checker }
}

// personalMember is one subscription a personal room must hold.
type personalMember struct {
	profileID string
	contactID string
	// role is the role a new room gives the member.
	role string
	// mustOwn makes an existing room answer only while this member owns it
	// (a bot room's service). A DM's roles are not checked: whoever started
	// it owns it.
	mustOwn bool
}

// keyedRoom is what a personal room resolution looks for, and makes when
// nothing of its key holds exactly its people: the room's type, key and
// tenancy, the subscriptions it must hold (the first is the creating actor
// when actorFirst), and what a new room is called.
type keyedRoom struct {
	roomType    string
	key         string
	want        []personalMember
	actorFirst  bool
	name        string
	description string
	properties  data.JSONMap
	tenantID    string
	partitionID string
	accessID    string
	partitions  []string
}

// ResolvePersonalRoom answers a service's CreateRoom of a DIRECT or BOT room:
// the oldest room of the people's key, in the caller's tenancy, whose active
// members are exactly the people (a BOT room: the person and the caller as
// owner); else a new private room holding them. The caller is never a member
// of a DM. Resolutions of one key are serialised on the primary database, so
// concurrent callers asking for the same people get the same room.
func (rb *roomBusiness) ResolvePersonalRoom(
	ctx context.Context, req *chatv1.CreateRoomRequest,
) (_ *chatv1.Room, err error) {
	ctx, span := chattel.RoomTracer.Start(ctx, "ResolvePersonalRoom")
	defer func() { chattel.RoomTracer.End(ctx, span, err) }()

	caller, err := authorizeService(ctx, rb.roomResolveChecker, PermissionStawiRoomResolve)
	if err != nil {
		return nil, err
	}
	roomType, key, want, err := personalShape(req, caller.profileID)
	if err != nil {
		return nil, err
	}
	for _, member := range want {
		if member.profileID == caller.profileID {
			continue
		}
		if err = rb.checkProfileExists(ctx, member.profileID); err != nil {
			return nil, err
		}
	}

	name := req.GetName()
	if name == "" {
		name = defaultDirectRoomName
		if roomType == models.RoomTypeBot {
			name = defaultBotRoomName
		}
	}
	room, err := rb.resolveKeyedRoom(ctx, &keyedRoom{
		roomType: roomType, key: key, want: want, name: name, description: req.GetDescription(),
		tenantID: caller.tenantID, partitionID: caller.partitionID, accessID: caller.accessID,
		partitions: caller.partitions,
	})
	if err != nil {
		return nil, err
	}
	return room.ToAPI(), nil
}

// resolveKeyedRoom returns the oldest room of spec's key, in its tenancy,
// whose active subscriptions are exactly spec.want, else a new one holding
// them. The lookup and the create run in one primary transaction holding the
// key's advisory lock, so callers resolving the same people at once get the
// same room; an existing room is answered unchanged.
func (rb *roomBusiness) resolveKeyedRoom(ctx context.Context, spec *keyedRoom) (*models.Room, error) {
	var room *models.Room
	err := rb.roomRepo.WithDirectKeyLock(ctx, spec.key, spec.tenantID, spec.partitions,
		func(store repository.KeyedRoomStore) error {
			var lockErr error
			room, lockErr = findPersonalRoom(store, spec.want)
			if lockErr != nil || room != nil {
				return lockErr
			}
			room, lockErr = rb.createKeyedRoom(ctx, store, spec)
			return lockErr
		})
	if err != nil {
		return nil, fmt.Errorf("failed to resolve the personal room: %w", err)
	}
	return room, nil
}

// personalShape validates a service's personal-room request and returns the
// room type, its key and the subscriptions it must hold: DIRECT with exactly
// two distinct people, neither the caller; BOT with exactly one person, not
// the caller, beside the caller as owner. People are named by profile id
// alone, and the request may not name the room's id.
func personalShape(
	req *chatv1.CreateRoomRequest, callerID string,
) (string, string, []personalMember, error) {
	if req.GetId() != "" {
		return "", "", nil, connect.NewError(connect.CodeInvalidArgument,
			"a personal room is found by its people, never by a supplied id")
	}
	if !validPersonalKeyID(callerID) {
		return "", "", nil, connect.NewError(connect.CodeInvalidArgument,
			"the caller's profile id cannot name a personal room")
	}
	people := make([]string, 0, len(req.GetMembers()))
	for _, member := range req.GetMembers() {
		if member == nil || member.GetContactId() != "" || !validPersonalKeyID(member.GetProfileId()) {
			return "", "", nil, connect.NewError(connect.CodeInvalidArgument,
				"a personal room's people are named by a valid profile id alone")
		}
		if member.GetProfileId() == callerID {
			return "", "", nil, connect.NewError(connect.CodeInvalidArgument,
				"the calling service is not one of a personal room's people")
		}
		people = append(people, member.GetProfileId())
	}
	slices.Sort(people)
	if len(slices.Compact(slices.Clone(people))) != len(people) {
		return "", "", nil, connect.NewError(connect.CodeInvalidArgument,
			"a personal room names each person once")
	}

	switch req.GetType() {
	case chatv1.RoomType_ROOM_TYPE_DIRECT:
		if len(people) != 2 { //nolint:mnd // a DM is two people
			return "", "", nil, connect.NewError(connect.CodeInvalidArgument,
				"a DM is exactly two people")
		}
		return models.RoomTypeDirect, models.DirectKey(people[0], people[1]), []personalMember{
			{profileID: people[0], role: roleMember},
			{profileID: people[1], role: roleMember},
		}, nil
	case chatv1.RoomType_ROOM_TYPE_BOT:
		if len(people) != 1 {
			return "", "", nil, connect.NewError(connect.CodeInvalidArgument,
				"a bot room is exactly one person")
		}
		return models.RoomTypeBot, models.BotKey(callerID, people[0]), []personalMember{
			{profileID: callerID, role: roleOwner, mustOwn: true},
			{profileID: people[0], role: roleMember},
		}, nil
	case chatv1.RoomType_ROOM_TYPE_UNSPECIFIED, chatv1.RoomType_ROOM_TYPE_GROUP, chatv1.RoomType_ROOM_TYPE_CHANNEL:
	}
	return "", "", nil, connect.Errorf(connect.CodeInvalidArgument,
		"a service resolves only DIRECT and BOT rooms, not %s", req.GetType())
}

// findPersonalRoom returns the oldest of the key's rooms whose active
// subscriptions are exactly want, or nil. A room that lost a member, gained
// one, holds a contact-only subscription, or (a bot room) whose service is no
// longer its owner is skipped: it is never answered again.
func findPersonalRoom(store repository.KeyedRoomStore, want []personalMember) (*models.Room, error) {
	rooms, err := store.Rooms()
	if err != nil {
		return nil, fmt.Errorf("failed to find the people's room: %w", err)
	}
	for _, room := range rooms {
		subscriptions, subErr := store.ActiveSubscriptions(room.GetID())
		if subErr != nil {
			return nil, fmt.Errorf("failed to read the room's members: %w", subErr)
		}
		if holdsExactly(subscriptions, want) {
			return room, nil
		}
	}
	return nil, nil //nolint:nilnil // no room of the key holds exactly the people.
}

// holdsExactly reports whether subscriptions are exactly one per wanted
// person, and each member that must own the room still does.
func holdsExactly(subscriptions []*models.RoomSubscription, want []personalMember) bool {
	if len(subscriptions) != len(want) {
		return false
	}
	for _, member := range want {
		idx := slices.IndexFunc(subscriptions, func(sub *models.RoomSubscription) bool {
			return sub.IsActive() && sub.ProfileID == member.profileID
		})
		if idx < 0 {
			return false
		}
		if member.mustOwn &&
			!slices.Contains(strings.Split(subscriptions[idx].Role, ","), roleOwner) {
			return false
		}
	}
	return true
}

// createKeyedRoom inserts a new private room of spec's key in spec's
// tenancy, with its subscriptions, its announcement and their
// authorization, all inside the key's lock. Any failure undoes all of it: a
// personal room missing a person is never left for resolution to find.
func (rb *roomBusiness) createKeyedRoom(
	ctx context.Context, store repository.KeyedRoomStore, spec *keyedRoom,
) (*models.Room, error) {
	room := &models.Room{
		RoomType:    spec.roomType,
		Name:        spec.name,
		Description: spec.description,
		IsPublic:    false,
		DirectKey:   spec.key,
		Properties:  spec.properties,
	}
	room.ID = util.IDString()
	room.TenantID, room.PartitionID, room.AccessID = spec.tenantID, spec.partitionID, spec.accessID

	subscriptions := make([]*models.RoomSubscription, 0, len(spec.want))
	for _, member := range spec.want {
		sub := &models.RoomSubscription{
			RoomID:            room.GetID(),
			ProfileID:         member.profileID,
			ContactID:         member.contactID,
			SubscriptionState: models.RoomSubscriptionStateActive,
			Role:              member.role,
		}
		sub.ID = util.IDString()
		sub.TenantID, sub.PartitionID, sub.AccessID = room.TenantID, room.PartitionID, room.AccessID
		subscriptions = append(subscriptions, sub)
	}
	if err := store.Insert(room, subscriptions); err != nil {
		return nil, fmt.Errorf("failed to save the personal room: %w", err)
	}
	actor := ""
	if spec.actorFirst {
		actor = subscriptions[0].GetID()
	}
	if err := announcePersonalRoom(ctx, store, room, actor, subscriptions); err != nil {
		return nil, err
	}
	// Keto is written inside the lock, before the commit: a room another
	// resolution can find is always one its people may already use. The
	// lock is held for these calls at most as long as ctx lives (the
	// handlers bound it at 30s); a cancelled ctx aborts the transaction and
	// releases the lock, and the relations written are removed.
	if err := rb.authorizePersonalMembers(ctx, room.GetID(), subscriptions); err != nil {
		return nil, err
	}
	chattel.RoomsCreatedCounter.Add(ctx, 1)
	return room, nil
}

// authorizePersonalMembers writes each subscription's room relation; on a
// failure it removes the ones written, and the caller's transaction is rolled
// back, so neither the rows nor the relations survive.
func (rb *roomBusiness) authorizePersonalMembers(
	ctx context.Context, roomID string, subscriptions []*models.RoomSubscription,
) error {
	if rb.authzMiddleware == nil {
		return nil
	}
	for i, sub := range subscriptions {
		if err := rb.authzMiddleware.AddRoomMember(ctx, roomID, sub.GetID(), sub.Role); err != nil {
			for _, written := range subscriptions[:i] {
				if rmErr := rb.authzMiddleware.RemoveRoomMember(ctx, roomID, written.GetID()); rmErr != nil {
					util.Log(ctx).WithError(rmErr).WithField(chatutil.KeyRoomID, roomID).
						Warn("failed to remove a personal room member's relation after a failed create")
				}
			}
			return fmt.Errorf("failed to authorize the personal room's members: %w", err)
		}
	}
	return nil
}

// announcePersonalRoom posts the new room's member-added change as a server
// event (actor: the person who started a DM, else none) in the creating
// transaction, so the people's
// devices pick the room up exactly when it exists.
func announcePersonalRoom(
	ctx context.Context, store repository.KeyedRoomStore, room *models.Room, actorSubscriptionID string,
	subscriptions []*models.RoomSubscription,
) error {
	ids := make([]string, 0, len(subscriptions))
	for _, sub := range subscriptions {
		ids = append(ids, sub.GetID())
	}
	content, err := models.NewPayloadConverter().FromProto(&chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_ROOM_CHANGE,
		Data: &chatv1.Payload_RoomChange{RoomChange: &chatv1.RoomChangeContent{
			Action:                chatv1.RoomChangeAction_ROOM_CHANGE_ACTION_MEMBER_ADDED,
			ActorSubscriptionId:   actorSubscriptionID,
			TargetSubscriptionIds: ids,
			Body:                  "Member(s) added to room",
		}},
	})
	if err != nil {
		return fmt.Errorf("failed to build the personal room's announcement: %w", err)
	}
	event := &models.RoomEvent{
		RoomID:    room.GetID(),
		EventType: int32(chatv1.RoomEventType_ROOM_EVENT_TYPE_SYSTEM),
		Content:   content,
	}
	event.ID = util.IDString()
	event.CreatedAt = time.Now()
	event.TenantID, event.PartitionID, event.AccessID = room.TenantID, room.PartitionID, room.AccessID
	link, err := serverEventLink(event)
	if err != nil {
		return fmt.Errorf("failed to build the personal room's announcement: %w", err)
	}
	outbox := &models.RoomOutbox{EventID: event.GetID(), RoomID: room.GetID(), Payload: link}
	outbox.TenantID, outbox.PartitionID, outbox.AccessID = room.TenantID, room.PartitionID, room.AccessID
	outbox.GenID(ctx)
	if err = store.InsertServerEvent(event, outbox); err != nil {
		return fmt.Errorf("failed to save the personal room's announcement: %w", err)
	}
	return nil
}
