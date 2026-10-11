package business

import (
	"context"
	"errors"
	"fmt"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	eventsv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/events/v1"
	"buf.build/go/protovalidate"
	"connectrpc.com/connect"
	"github.com/pitabwire/frame/v2/security"
	"github.com/pitabwire/util"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/pkg/chatutil"
)

const (
	// ServiceNamespace is chat's functional-permission namespace in Keto.
	ServiceNamespace = "service_chat"
	// PermissionStawiCardPost lets a service principal post display-only
	// cards into a Stawi room it is not a member of.
	PermissionStawiCardPost = "stawi_card_post"
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

// SendServiceEvents posts display-only cards (FINANCE_CARD) and TEXT into
// Stawi rooms the chain has, for a service principal that is not a member of
// them — finance's service identity rendering room facts. The caller must be
// a service principal (internal-system claims) holding stawi_card_post on
// chat's functional namespace. A card authorizes nothing: it is shown, and
// any action it offers is a signed call the member makes on their device.
func (mb *messageBusiness) SendServiceEvents(
	ctx context.Context, req *chatv1.SendEventRequest,
) ([]*chatv1.AckEvent, error) {
	serviceProfileID, err := mb.authorizeServiceCaller(ctx)
	if err != nil {
		return nil, err
	}
	if len(req.GetEvent()) == 0 {
		return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("at least one event must be provided"))
	}

	acks := make([]*chatv1.AckEvent, len(req.GetEvent()))
	events := make([]*models.RoomEvent, 0, len(req.GetEvent()))
	indexByID := map[string]int{}
	payloads := map[string][]byte{}
	for i, reqEvt := range req.GetEvent() {
		event, ackErr := mb.prepareServiceCard(ctx, reqEvt, serviceProfileID)
		if ackErr != nil {
			acks[i] = ackEventError(reqEvt.GetId(), ackErr)
			continue
		}
		link, linkErr := serviceCardLink(event, serviceProfileID)
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
				connect.NewError(connect.CodeInternal, fmt.Errorf("failed to save event: %w", saveErr)))
		}
		return acks, nil
	}
	for _, event := range events {
		acks[indexByID[event.GetID()]] = &chatv1.AckEvent{EventId: []string{event.GetID()}, AckAt: timestamppb.Now()}
	}
	return acks, nil
}

// authorizeServiceCaller returns the service principal's profile id, or why
// the caller may not post cards.
func (mb *messageBusiness) authorizeServiceCaller(ctx context.Context) (string, error) {
	claims := security.ClaimsFromContext(ctx)
	if claims == nil || claims.GetProfileID() == "" {
		return "", connect.NewError(connect.CodeUnauthenticated, errors.New("request needs to be authenticated"))
	}
	if !claims.IsInternalSystem() {
		return "", connect.NewError(connect.CodePermissionDenied,
			errors.New("only a service principal may post cards without being a member"))
	}
	if mb.cardChecker == nil {
		return "", connect.NewError(connect.CodePermissionDenied, errors.New("service cards are not enabled"))
	}
	if err := mb.cardChecker.Check(ctx, PermissionStawiCardPost); err != nil {
		return "", connect.NewError(connect.CodePermissionDenied,
			fmt.Errorf("the caller does not hold %s: %w", PermissionStawiCardPost, err))
	}
	return claims.GetProfileID(), nil
}

func (mb *messageBusiness) prepareServiceCard(
	ctx context.Context, reqEvt *chatv1.RoomEvent, serviceProfileID string,
) (*models.RoomEvent, error) {
	if reqEvt.GetId() == "" {
		reqEvt.Id = util.IDString()
	} else if !chatutil.IsValidEventID(reqEvt.GetId()) {
		return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("event id must be a valid xid"))
	}

	switch reqEvt.GetPayload().GetData().(type) {
	case *chatv1.Payload_FinanceCard:
		if err := validateFinanceCardPayload(reqEvt); err != nil {
			return nil, err
		}
	case *chatv1.Payload_Text:
		if reqEvt.GetPayload().GetType() != chatv1.PayloadType_PAYLOAD_TYPE_TEXT {
			return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("payload type must be TEXT"))
		}
	default:
		return nil, connect.NewError(connect.CodeInvalidArgument,
			errors.New("a service may post only FINANCE_CARD and TEXT payloads"))
	}
	if reqEvt.GetPayload().GetType() == chatv1.PayloadType_PAYLOAD_TYPE_FINANCE_CARD &&
		reqEvt.GetPayload().GetFinanceCard() == nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("finance card payload is required"))
	}
	if err := protovalidate.Validate(reqEvt); err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, err)
	}

	if mb.stawi == nil || mb.stawi.bindings == nil {
		return nil, errStawiNotConfigured
	}
	bound, err := mb.stawi.bindings.IsBound(ctx, reqEvt.GetRoomId())
	if err != nil {
		return nil, fmt.Errorf("failed to check the room binding: %w", err)
	}
	if !bound {
		return nil, connect.NewError(connect.CodeFailedPrecondition,
			errors.New("service cards are posted only into Stawi rooms that are on chain"))
	}
	room, err := mb.stawi.roomRepo.GetByID(ctx, reqEvt.GetRoomId())
	if err != nil {
		return nil, fmt.Errorf("failed to load the room: %w", err)
	}

	content, err := mb.payloadConverter.FromProto(reqEvt.GetPayload())
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("failed to convert event: %w", err))
	}
	event := &models.RoomEvent{
		RoomID:     room.GetID(),
		EventType:  int32(reqEvt.GetType()),
		Content:    content,
		Properties: map[string]any{"posted_by_service": serviceProfileID},
	}
	event.ID = reqEvt.GetId()
	// The event belongs to the room's tenancy, not the posting service's.
	event.TenantID, event.PartitionID, event.AccessID = room.TenantID, room.PartitionID, room.AccessID
	return event, nil
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
