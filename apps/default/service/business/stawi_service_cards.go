package business

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	eventsv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/events/v1"
	"buf.build/go/protovalidate"
	"connectrpc.com/connect/v2"
	"github.com/pitabwire/frame/v3/data"
	"github.com/pitabwire/frame/v3/security"
	"github.com/pitabwire/util"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/pkg/chatutil"
)

const (
	// ServiceNamespace is chat's functional-permission namespace in Keto.
	ServiceNamespace = "service_chat"
	// PermissionStawiCardPost lets a service principal post display-only
	// cards into a Stawi room it is not a member of.
	PermissionStawiCardPost = "stawi_card_post"
	// PermissionSocialTraderCardPost lets the socialtrader service principal
	// post pool cards (JSON text carrying the socialtrader discriminator)
	// into a room bound to a pool.
	PermissionSocialTraderCardPost = "socialtrader_card_post"
	// PermissionSocialTraderRoomBind is the permit a socialtrader principal
	// holds to bind rooms to pools on a leader's behalf; v1 adds no RPC for
	// it, the permit is declared so the OPL and the service agree on its name.
	PermissionSocialTraderRoomBind = "socialtrader_room_bind"
)

// FunctionPermissionChecker checks a functional permission of the caller in
// ctx; frame's authorizer.FunctionChecker satisfies it.
type FunctionPermissionChecker interface {
	Check(ctx context.Context, permission string) error
}

// WithServiceCards enables the service-caller card path, gated by checker.
func WithServiceCards(checker FunctionPermissionChecker) MessageBusinessOption {
	return func(mb *messageBusiness) { mb.cardChecker = checker }
}

// WithSocialTraderBindings lets the card path recognise trading-group rooms
// from their server-side pool binding. Without it every pool card is refused.
func WithSocialTraderBindings(bindings repository.SocialTraderRoomRepository) MessageBusinessOption {
	return func(mb *messageBusiness) { mb.poolBindings = bindings }
}

// SendServiceEvents posts display-only cards (FINANCE_CARD) and TEXT into
// Stawi rooms the chain has, and into people's personal rooms (a DM, or the
// caller's own bot room with a person), for a service principal that is not
// a member of them — finance's service identity rendering room and loan
// facts. The caller must be a service principal (internal-system claims)
// holding stawi_card_post on chat's functional namespace. A card authorizes nothing: it is shown, and
// any action it offers is a signed call the member makes on their device.
func (mb *messageBusiness) SendServiceEvents(
	ctx context.Context, req *chatv1.SendEventRequest,
) ([]*chatv1.AckEvent, error) {
	caller, err := authorizeServicePrincipal(ctx, mb.cardChecker)
	if err != nil {
		return nil, err
	}
	if len(req.GetEvent()) == 0 {
		return nil, connect.NewError(connect.CodeInvalidArgument, "at least one event must be provided")
	}
	// Each card needs the permit of the module it belongs to; a batch is
	// refused whole when the principal lacks any permit it would need.
	checked := map[string]bool{}
	for _, reqEvt := range req.GetEvent() {
		permission := cardPermissionFor(reqEvt.GetPayload())
		if checked[permission] {
			continue
		}
		if err = checkServicePermission(ctx, mb.cardChecker, permission); err != nil {
			return nil, err
		}
		checked[permission] = true
	}

	acks := make([]*chatv1.AckEvent, len(req.GetEvent()))
	events := make([]*models.RoomEvent, 0, len(req.GetEvent()))
	indexByID := map[string]int{}
	payloads := map[string][]byte{}
	for i, reqEvt := range req.GetEvent() {
		event, ackErr := mb.prepareServiceCard(ctx, reqEvt, caller)
		if ackErr != nil {
			acks[i] = ackEventError(reqEvt.GetId(), ackErr)
			continue
		}
		link, linkErr := serviceCardLink(event, caller.profileID)
		if linkErr != nil {
			acks[i] = ackEventError(event.GetID(), linkErr)
			continue
		}
		payloads[event.GetID()] = link
		indexByID[event.GetID()] = i
		events = append(events, event)
	}
	if len(events) == 0 {
		return acks, nil
	}

	if _, saveErr := mb.outboxRepo.SaveEventsWithOutbox(ctx, events, payloads); saveErr != nil {
		for _, event := range events {
			acks[indexByID[event.GetID()]] = ackEventError(event.GetID(),
				connect.NewError(connect.CodeInternal, fmt.Errorf("failed to save event: %w", saveErr).Error()))
		}
		return acks, nil
	}
	for _, event := range events {
		acks[indexByID[event.GetID()]] = &chatv1.AckEvent{EventId: []string{event.GetID()}, AckAt: timestamppb.Now()}
	}
	return acks, nil
}

// serviceCaller is an authorized service principal and the tenancy its
// permission was checked in.
type serviceCaller struct {
	profileID   string
	tenantID    string
	partitionID string
	accessID    string
	partitions  []string
}

// cardPermissionFor names the functional permission a service needs to post
// payload: socialtrader_card_post for a pool card (JSON text whose body is a
// socialtrader card), stawi_card_post for everything else.
func cardPermissionFor(payload *chatv1.Payload) string {
	if isSocialTraderCard(payload) {
		return PermissionSocialTraderCardPost
	}
	return PermissionStawiCardPost
}

// socialTraderCard is the part of a pool card chat reads: its kind and the
// pool it is about. The body is otherwise opaque to chat.
type socialTraderCard struct {
	Kind string `json:"kind"`
	Pool string `json:"pool"`
}

// parseSocialTraderCard returns the pool card in payload: TEXT in the "json"
// format whose body is an object carrying a "socialtrader" object with a
// kind. ok is false for anything else.
func parseSocialTraderCard(payload *chatv1.Payload) (socialTraderCard, bool) {
	text := payload.GetText()
	if text == nil || text.GetFormat() != "json" {
		return socialTraderCard{}, false
	}
	var body struct {
		SocialTrader *socialTraderCard `json:"socialtrader"`
	}
	if err := json.Unmarshal([]byte(text.GetBody()), &body); err != nil {
		return socialTraderCard{}, false
	}
	if body.SocialTrader == nil || body.SocialTrader.Kind == "" {
		return socialTraderCard{}, false
	}
	return *body.SocialTrader, true
}

// isSocialTraderCard reports whether payload is a pool card.
func isSocialTraderCard(payload *chatv1.Payload) bool {
	_, ok := parseSocialTraderCard(payload)
	return ok
}

// authorizeService returns the service principal in ctx holding permission
// on chat's functional namespace, or why it may not act: a person, or a
// principal without a tenancy or the grant, is refused.
func authorizeService(
	ctx context.Context, checker FunctionPermissionChecker, permission string,
) (*serviceCaller, error) {
	caller, err := authorizeServicePrincipal(ctx, checker)
	if err != nil {
		return nil, err
	}
	if err = checkServicePermission(ctx, checker, permission); err != nil {
		return nil, err
	}
	return caller, nil
}

// authorizeServicePrincipal returns the service principal in ctx, or why it
// may not act at all: a person, or a principal without a tenancy, is refused.
// The functional permission is checked separately, per card module.
func authorizeServicePrincipal(ctx context.Context, checker FunctionPermissionChecker) (*serviceCaller, error) {
	claims := security.ClaimsFromContext(ctx)
	if claims == nil || claims.GetProfileID() == "" {
		return nil, connect.NewError(connect.CodeUnauthenticated, "request needs to be authenticated")
	}
	if !claims.IsInternalSystem() {
		return nil, connect.NewError(connect.CodePermissionDenied,
			"only a service principal may post service cards")
	}
	if claims.GetTenantID() == "" || claims.GetPartitionID() == "" {
		return nil, connect.NewError(connect.CodePermissionDenied,
			"a service principal acts only within its own tenant and partition")
	}
	if checker == nil {
		return nil, connect.NewError(connect.CodePermissionDenied, "service cards are not enabled")
	}
	return &serviceCaller{
		profileID:   claims.GetProfileID(),
		tenantID:    claims.GetTenantID(),
		partitionID: claims.GetPartitionID(),
		accessID:    claims.GetAccessID(),
		partitions:  claims.GetPartitionIDs(),
	}, nil
}

// checkServicePermission checks the functional permission at the caller's
// own tenant/partition; the room must then be in that tenancy too.
func checkServicePermission(ctx context.Context, checker FunctionPermissionChecker, permission string) error {
	if err := checker.Check(ctx, permission); err != nil {
		return connect.NewError(connect.CodePermissionDenied,
			fmt.Errorf("the caller does not hold %s: %w", permission, err).Error())
	}
	return nil
}

// owns reports whether a room lies in the caller's tenant and partitions.
func (c *serviceCaller) owns(room *models.Room) bool {
	if room.TenantID == "" || room.TenantID != c.tenantID || room.PartitionID == "" {
		return false
	}
	for _, partition := range c.partitions {
		if partition == room.PartitionID {
			return true
		}
	}
	return false
}

// validateServiceCard holds a service-posted event to the member path's
// validation plus the card path's allowlist: a FINANCE_CARD as an EVENT or a
// TEXT as a MESSAGE, with the declared type exactly the populated content's.
func validateServiceCard(reqEvt *chatv1.RoomEvent) error {
	payload := reqEvt.GetPayload()
	switch payload.GetData().(type) {
	case *chatv1.Payload_FinanceCard:
		if payload.GetType() != chatv1.PayloadType_PAYLOAD_TYPE_FINANCE_CARD ||
			reqEvt.GetType() != chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT {
			return connect.NewError(connect.CodeInvalidArgument,
				"a finance card is a FINANCE_CARD payload in a ROOM_EVENT_TYPE_EVENT")
		}
	case *chatv1.Payload_Text:
		if payload.GetType() != chatv1.PayloadType_PAYLOAD_TYPE_TEXT ||
			reqEvt.GetType() != chatv1.RoomEventType_ROOM_EVENT_TYPE_MESSAGE {
			return connect.NewError(connect.CodeInvalidArgument,
				"text is a TEXT payload in a ROOM_EVENT_TYPE_MESSAGE")
		}
	default:
		return connect.NewError(connect.CodeInvalidArgument,
			"a service may post only FINANCE_CARD and TEXT payloads")
	}
	if err := validateFinanceCardPayload(reqEvt); err != nil {
		return err
	}
	if err := validateStawiPayload(reqEvt); err != nil {
		return err
	}
	if err := protovalidate.Validate(reqEvt); err != nil {
		return connect.NewError(connect.CodeInvalidArgument, err.Error()).WithCause(err)
	}
	return nil
}

func (mb *messageBusiness) prepareServiceCard(
	ctx context.Context, reqEvt *chatv1.RoomEvent, caller *serviceCaller,
) (*models.RoomEvent, error) {
	if reqEvt.GetId() == "" {
		reqEvt.Id = util.IDString()
	} else if !chatutil.IsValidEventID(reqEvt.GetId()) {
		return nil, connect.NewError(connect.CodeInvalidArgument, "event id must be a valid xid")
	}

	if err := validateServiceCard(reqEvt); err != nil {
		return nil, err
	}

	if mb.stawi == nil || mb.stawi.bindings == nil {
		return nil, errStawiNotConfigured
	}
	room, err := mb.stawi.roomRepo.GetByID(ctx, reqEvt.GetRoomId())
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return nil, connect.NewError(connect.CodePermissionDenied,
				"the room is outside the caller's tenant and partition")
		}
		return nil, fmt.Errorf("failed to load the room: %w", err)
	}
	// A service principal's queries are not tenancy-scoped by the database,
	// so the room's tenancy is checked here against the caller's.
	if !caller.owns(room) {
		return nil, connect.NewError(connect.CodePermissionDenied,
			"the room is outside the caller's tenant and partition")
	}

	if card, isPoolCard := parseSocialTraderCard(reqEvt.GetPayload()); isPoolCard {
		err = refuseUnlessPoolRoom(ctx, mb.poolBindings, room, caller, card)
	} else {
		err = refuseUnlessCardRoom(ctx, mb.stawi.bindings, room, caller)
	}
	if err != nil {
		return nil, err
	}

	content, err := mb.payloadConverter.FromProto(reqEvt.GetPayload())
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("failed to convert event: %w", err).Error())
	}
	event := &models.RoomEvent{
		RoomID:     room.GetID(),
		EventType:  int32(reqEvt.GetType()),
		Content:    content,
		Properties: map[string]any{"posted_by_service": caller.profileID},
	}
	event.ID = reqEvt.GetId()
	// The event belongs to the room's tenancy, not the posting service's.
	event.TenantID, event.PartitionID, event.AccessID = room.TenantID, room.PartitionID, room.AccessID
	return event, nil
}

// refusePersonalRoom decides a card for a person's personal room: a DIRECT
// room takes cards from any service of its tenancy holding the permit, not
// only the one that resolved it; a bot room only from the service it belongs
// to, the one its key names. The first result is false for a room that is
// not personal, which the module's own binding then decides.
func refusePersonalRoom(room *models.Room, caller *serviceCaller) (bool, error) {
	if room.DirectKey == "" {
		return false, nil
	}
	switch room.RoomType {
	case models.RoomTypeDirect:
		return true, nil
	case models.RoomTypeBot:
		if rest, isBot := strings.CutPrefix(room.DirectKey, "bot:"); isBot {
			if owner, _, ok := strings.Cut(rest, ":"); ok && owner == caller.profileID {
				return true, nil
			}
		}
		return true, connect.NewError(connect.CodePermissionDenied,
			"a bot room takes cards only from its own service")
	default:
		return false, nil
	}
}

// refuseUnlessCardRoom refuses a card for a room (already known to be in the
// caller's tenancy) that is neither a Stawi room on chain nor a person's
// personal room.
func refuseUnlessCardRoom(
	ctx context.Context, bindings repository.StawiRoomRepository, room *models.Room, caller *serviceCaller,
) error {
	if handled, err := refusePersonalRoom(room, caller); handled {
		return err
	}
	bound, err := bindings.IsBound(ctx, room.GetID())
	if err != nil {
		return fmt.Errorf("failed to check the room binding: %w", err)
	}
	if !bound {
		return connect.NewError(connect.CodeFailedPrecondition,
			"service cards are posted only into Stawi rooms that are on chain and people's personal rooms")
	}
	return nil
}

// refuseUnlessPoolRoom refuses a pool card for a room (already known to be in
// the caller's tenancy) that is neither a trading group nor a person's
// personal room. A trading group is a room with a server-side pool binding
// (socialtrader_room_bindings), never one whose metadata merely names a pool,
// and the card must be about the bound pool.
func refuseUnlessPoolRoom(
	ctx context.Context, bindings repository.SocialTraderRoomRepository,
	room *models.Room, caller *serviceCaller, card socialTraderCard,
) error {
	if handled, err := refusePersonalRoom(room, caller); handled {
		return err
	}
	if bindings == nil {
		return connect.NewError(connect.CodeFailedPrecondition, "trading groups are not enabled")
	}
	binding, err := bindings.GetByRoomID(ctx, room.GetID())
	if err != nil {
		return fmt.Errorf("failed to check the room's pool binding: %w", err)
	}
	if binding == nil {
		return connect.NewError(connect.CodeFailedPrecondition,
			"pool cards are posted only into rooms bound to a socialtrader pool")
	}
	if !strings.EqualFold(card.Pool, binding.PoolID) {
		return connect.NewError(connect.CodePermissionDenied,
			"the card is about a pool the room is not bound to")
	}
	return nil
}

// serviceCardLink is the outbox link of a service-posted event: no sending
// subscription, the service's profile as the source.
func serviceCardLink(event *models.RoomEvent, serviceProfileID string) ([]byte, error) {
	return protojson.Marshal(&eventsv1.Link{
		EventId:   event.GetID(),
		RoomId:    event.RoomID,
		Source:    &eventsv1.Subscription{ContactLink: &commonv1.ContactLink{ProfileId: serviceProfileID}},
		EventType: chatv1.RoomEventType(event.EventType),
		CreatedAt: timestamppb.Now(),
	})
}
