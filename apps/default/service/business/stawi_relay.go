package business

import (
	"context"
	"errors"
	"fmt"
	"slices"
	"strings"
	"time"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	eventsv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/events/v1"
	"connectrpc.com/connect/v2"
	"github.com/pitabwire/frame/v3/data"
	"github.com/pitabwire/util"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/stawilabs/chat/apps/default/service"
	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/service/stawi"
	"github.com/stawilabs/chat/pkg/chatutil"
)

// stawiRelay relays the Stawi room acts members send to settlement. It is the
// send path's half of Stawi rooms: it decides nothing about membership or
// roles (those change only from chain facts), it checks that the sender is
// who the act requires, using values settlement and chat's own records hold
// rather than anything the client supplied, and it reports what settlement
// said as a follow-up event in the room.
type stawiRelay struct {
	rooms     stawi.Rooms
	accounts  stawi.AccountResolver
	roomRepo  repository.RoomRepository
	bindings  repository.StawiRoomRepository
	callRepo  repository.StawiRoomCallRepository
	subRepo   repository.RoomSubscriptionRepository
	eventRepo repository.RoomEventRepository
	converter *models.PayloadConverter
}

// StawiDeps are what the send path needs to relay Stawi room acts.
type StawiDeps struct {
	Rooms    stawi.Rooms
	Accounts stawi.AccountResolver
	RoomRepo repository.RoomRepository
	Bindings repository.StawiRoomRepository
	CallRepo repository.StawiRoomCallRepository
}

// WithStawiRooms enables Stawi room acts on the send path. Without it every
// Stawi act is refused as unavailable.
func WithStawiRooms(deps StawiDeps) MessageBusinessOption {
	return func(mb *messageBusiness) {
		mb.stawi = &stawiRelay{
			rooms:     deps.Rooms,
			accounts:  deps.Accounts,
			roomRepo:  deps.RoomRepo,
			bindings:  deps.Bindings,
			callRepo:  deps.CallRepo,
			subRepo:   mb.subRepo,
			eventRepo: mb.eventRepo,
			converter: mb.payloadConverter,
		}
	}
}

// stawiAct is one Stawi act being relayed in a SendEvents batch.
type stawiAct struct {
	event   *models.RoomEvent
	payload *chatv1.Payload
	sender  *models.RoomSubscription
}

// stawiRelayResult is what relaying one act produced: the act's event may have
// been rewritten (a conversion gains its genesis), an outcome may follow it,
// (a relayed call is tracked as it is relayed); or the act is refused back to the sender (ack) and
// nothing is stored.
type stawiRelayResult struct {
	outcome *models.RoomEvent
	ack     error
}

// acceptInvitationKind is settlement's name for the invitee's acceptance.
const acceptInvitationKind = "ACCEPT_INVITATION"

// isAcceptInvitation reports whether an event is a signed call accepting a
// Stawi room invitation: the one act an invitee may send before the chain
// makes them a member.
func isAcceptInvitation(reqEvt *chatv1.RoomEvent) bool {
	return isAcceptInvitationPayload(reqEvt.GetPayload())
}

func isAcceptInvitationPayload(p *chatv1.Payload) bool {
	return p.GetType() == chatv1.PayloadType_PAYLOAD_TYPE_STAWI_SIGNED_CALL &&
		strings.EqualFold(p.GetStawiSignedCall().GetKind(), acceptInvitationKind)
}

// inviteeSubscriptions are the sender's proposed subscriptions of the Stawi
// rooms among roomIDs where they hold no active one: the subscriptions chat
// writes for an invitee from the chain's MemberInvited fact.
func (mb *messageBusiness) inviteeSubscriptions(
	ctx context.Context, sentBy *commonv1.ContactLink, roomIDs []string, active map[string]string,
) map[string]*models.RoomSubscription {
	out := map[string]*models.RoomSubscription{}
	if mb.stawi == nil {
		return out
	}
	for _, roomID := range roomIDs {
		if _, ok := active[roomID]; ok {
			continue
		}
		sub, err := mb.inviteeSubscription(ctx, sentBy, roomID)
		if err != nil {
			// Fail closed: the act is refused as from a non-member.
			util.Log(ctx).WithError(err).WithField(chatutil.KeyRoomID, roomID).
				Warn("stawi relay: could not look up an invitee subscription")
			continue
		}
		if sub != nil {
			out[roomID] = sub
		}
	}
	return out
}

// inviteeSubscription is the sender's proposed subscription of a bound Stawi
// room, or nil.
func (mb *messageBusiness) inviteeSubscription(
	ctx context.Context, sentBy *commonv1.ContactLink, roomID string,
) (*models.RoomSubscription, error) {
	// Active-only lookups do not see a proposed subscription.
	subs, err := mb.subRepo.GetByRoomIDAndContactLinks(
		ctx,
		roomID,
		&commonv1.ContactLink{ProfileId: sentBy.GetProfileId()},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to get subscriptions: %w", err)
	}
	sub := proposedOf(subs, sentBy.GetProfileId())
	if sub == nil {
		return nil, nil //nolint:nilnil // no invitee subscription is not an error
	}
	bound, err := mb.stawi.bindings.IsBound(ctx, roomID)
	if err != nil {
		return nil, fmt.Errorf("failed to check the room binding: %w", err)
	}
	if !bound {
		return nil, nil //nolint:nilnil // an unbound room has no invitees
	}
	return sub, nil
}

// admitInvitee lets an invitee's acceptance through the send path: the event
// is sent as the invitee's proposed subscription, which may send it.
func admitInvitee(
	reqEvt *chatv1.RoomEvent, invitees map[string]*models.RoomSubscription,
	subscriptionMap map[string]*models.RoomSubscription, access map[string]bool,
) (string, bool) {
	invitee, ok := invitees[reqEvt.GetRoomId()]
	if !ok || !isAcceptInvitation(reqEvt) {
		return "", false
	}
	subscriptionMap[invitee.GetID()] = invitee
	access[invitee.GetID()] = true
	return invitee.GetID(), true
}

// proposedOf is the profile's proposed subscription among subs, if any.
func proposedOf(subs []*models.RoomSubscription, profileID string) *models.RoomSubscription {
	for _, sub := range subs {
		if sub.ProfileID == profileID && sub.SubscriptionState == models.RoomSubscriptionStateProposed {
			return sub
		}
	}
	return nil
}

// errStawiNotConfigured is the sender-facing refusal when settlement is absent.
var errStawiNotConfigured = connect.NewError(connect.CodeUnavailable,
	"stawi room acts are not available on this server")

// relay hands one act to settlement. Refusals by settlement are stored and
// reported to the room; problems with the act itself, or with reaching
// settlement, are returned to the sender and nothing is stored.
func (sr *stawiRelay) relay(ctx context.Context, act *stawiAct) stawiRelayResult {
	// The send path has already required an active subscription that Keto
	// lets send into the room — or, for accepting an invitation, the
	// invitee's proposed one; the relay does not rely on it.
	senderMaySend := act.sender != nil && (act.sender.IsActive() ||
		act.sender.SubscriptionState == models.RoomSubscriptionStateProposed && isAcceptInvitationPayload(act.payload))
	if !senderMaySend || act.sender.ProfileID == "" ||
		act.sender.RoomID != "" && act.sender.RoomID != act.event.RoomID {
		return stawiRelayResult{ack: connect.NewError(connect.CodePermissionDenied,
			"stawi room acts need an active member of the room")}
	}
	if sr == nil || sr.rooms == nil {
		return stawiRelayResult{ack: errStawiNotConfigured}
	}

	bound, err := sr.bindings.IsBound(ctx, act.event.RoomID)
	if err != nil {
		return stawiRelayResult{ack: fmt.Errorf("failed to check the room binding: %w", err)}
	}

	switch content := models.StawiContent(act.payload).(type) {
	case *chatv1.StawiRoomConversionContent:
		return sr.relayConversion(ctx, act, content, bound)
	case *chatv1.StawiGenesisSignatureContent:
		return sr.relayGenesisSignature(ctx, act, content, bound)
	case *chatv1.StawiSignedCallContent:
		return sr.relaySignedCall(ctx, act, content, bound)
	case *chatv1.StawiAgentInvitationContent:
		return sr.relayAgentInvitation(ctx, act, content)
	case *chatv1.StawiAgentAcceptanceContent:
		return sr.relayAgentAcceptance(ctx, act, content)
	default:
		return stawiRelayResult{ack: invalidStawiPayload(errors.New("not a Stawi act"))}
	}
}

func (sr *stawiRelay) relayConversion(
	ctx context.Context, act *stawiAct, content *chatv1.StawiRoomConversionContent, bound bool,
) stawiRelayResult {
	if bound {
		return stawiRelayResult{ack: connect.NewError(connect.CodeFailedPrecondition,
			"the room is already a Stawi room")}
	}

	// A DM or a bot room stays personal: person to person money is the
	// personal loan book's, never a Stawi room's.
	room, err := sr.roomRepo.GetByID(ctx, act.event.RoomID)
	if err != nil {
		return stawiRelayResult{ack: fmt.Errorf("failed to load the room: %w", err)}
	}
	if room.RoomType == models.RoomTypeDirect || room.RoomType == models.RoomTypeBot {
		return stawiRelayResult{ack: service.ErrPersonalRoomNotStawi}
	}

	// Only the room's owner or an admin may line the room up for the chain:
	// the genesis prepared here is what a later activation must match.
	if !roleListContains(act.sender.Role, roleOwner) && !roleListContains(act.sender.Role, roleAdmin) {
		return stawiRelayResult{ack: connect.NewError(connect.CodePermissionDenied,
			"only the room's owner or an admin may convert it to a Stawi room")}
	}

	// Another member's pending genesis is theirs until it expires.
	if err = sr.bindings.CheckGenesisClaimable(ctx, act.event.RoomID, act.sender.ProfileID, time.Now()); err != nil {
		return stawiRelayResult{ack: genesisClaimRefusal(err)}
	}

	// Founders are named by subscription; each must be an active subscription
	// of this room, and settlement is given the profiles chat holds for them.
	founderIDs := content.GetFounderSubscriptionIds()
	founders, err := sr.subRepo.GetByIDsInRoom(ctx, act.event.RoomID, founderIDs)
	if err != nil {
		return stawiRelayResult{ack: fmt.Errorf("failed to load founders: %w", err)}
	}
	profileBySub := make(map[string]string, len(founders))
	for _, sub := range founders {
		if sub.IsActive() && sub.ProfileID != "" {
			profileBySub[sub.GetID()] = sub.ProfileID
		}
	}
	founderProfiles := make([]string, 0, len(founderIDs))
	for _, id := range founderIDs {
		profileID, ok := profileBySub[id]
		if !ok {
			return stawiRelayResult{ack: invalidStawiPayload(
				fmt.Errorf("founder %s is not an active member of the room", id))}
		}
		founderProfiles = append(founderProfiles, profileID)
	}

	// Settlement takes the converting admin as one of the founders.
	if !slices.Contains(founderProfiles, act.sender.ProfileID) {
		return stawiRelayResult{ack: invalidStawiPayload(
			errors.New("the member converting the room must be one of its founders"))}
	}

	agentID := content.GetAgentProfileId()
	if err = sr.checkAgent(ctx, room, act.sender.ProfileID, agentID); err != nil {
		return stawiRelayResult{ack: err}
	}

	genesis, err := sr.rooms.PrepareRoomGenesis(ctx, stawi.PrepareGenesisRequest{
		ChatRoomID:        act.event.RoomID,
		TemplateID:        content.GetTemplateId(),
		RuleValues:        content.GetRuleValues(),
		FounderProfileIDs: founderProfiles,
		JoinPolicy:        stawi.JoinPolicy(content.GetJoinPolicy()),
		RequestedBy:       act.sender.ProfileID,
		AgentProfileID:    agentID,
	})
	if err != nil {
		return sr.refusedOrTransient(ctx, act, err, &chatv1.StawiCallOutcomeContent{Kind: "ROOM_CONVERSION"})
	}

	// The stored conversion becomes the genesis card.
	content.Genesis = &chatv1.StawiGenesis{
		GenesisId:         genesis.GenesisID,
		GenesisHash:       genesis.GenesisHash,
		ConstitutionHash:  genesis.ConstitutionHash,
		ExpiresAt:         timestamppb.New(genesis.ExpiresAt),
		FounderProfileIds: genesis.FounderProfileIDs,
	}
	stored, err := sr.converter.FromProto(act.payload)
	if err != nil {
		return stawiRelayResult{ack: fmt.Errorf("failed to encode the genesis card: %w", err)}
	}
	act.event.Content = stored

	// Record the genesis before the card is stored, so a founder who signs as
	// soon as the card arrives finds it. A card that then fails to store leaves
	// a pending genesis the sender's retry replaces.
	if err = sr.bindings.ClaimGenesis(ctx, room, models.StawiGenesisClaim{
		GenesisID:   genesis.GenesisID,
		EventID:     act.event.GetID(),
		RequestedBy: act.sender.ProfileID,
		Founders:    genesis.FounderProfileIDs,
		ExpiresAt:   genesis.ExpiresAt,
	}); err != nil {
		return stawiRelayResult{ack: genesisClaimRefusal(err)}
	}
	return stawiRelayResult{}
}

// checkAgent refuses an agent the converting member may not name; no agent
// is always accepted.
func (sr *stawiRelay) checkAgent(ctx context.Context, room *models.Room, converterID, agentID string) error {
	if agentID == "" {
		return nil
	}
	accepted, err := sr.mayBeAgent(ctx, room, converterID, agentID)
	if err != nil {
		return err
	}
	if !accepted {
		return invalidStawiPayload(errors.New(
			"the agent must be a room member or someone who accepted your agent invitation for this room"))
	}
	return nil
}

func (sr *stawiRelay) relayGenesisSignature(
	ctx context.Context, act *stawiAct, content *chatv1.StawiGenesisSignatureContent, bound bool,
) stawiRelayResult {
	if bound {
		return stawiRelayResult{ack: connect.NewError(connect.CodeFailedPrecondition,
			"the room is already on chain")}
	}

	// The founders are the ones settlement returned for the genesis and chat
	// recorded, never anything the signature payload says.
	binding, err := sr.bindings.GetByID(ctx, act.event.RoomID)
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return stawiRelayResult{ack: connect.NewError(connect.CodeFailedPrecondition,
				"the room has no genesis to sign")}
		}
		return stawiRelayResult{ack: fmt.Errorf("failed to load the room genesis: %w", err)}
	}
	if binding.State != models.StawiRoomStatePending || binding.GenesisID != content.GetGenesisId() {
		return stawiRelayResult{ack: connect.NewError(connect.CodeFailedPrecondition,
			"the genesis is not the room's current genesis")}
	}
	if !binding.IsFounder(act.sender.ProfileID) {
		return stawiRelayResult{ack: connect.NewError(connect.CodePermissionDenied,
			"only a founder of the genesis may sign it")}
	}

	_, err = sr.rooms.SubmitRoomGenesisSignature(ctx, stawi.GenesisSignature{
		GenesisID:       binding.GenesisID,
		SignerProfileID: act.sender.ProfileID,
		Signature: stawi.DeviceSignature{
			KeyID:             content.GetSignerKeyId(),
			Algorithm:         content.GetAlgorithm(),
			Signature:         content.GetSignature(),
			AuthenticatorData: content.GetWebauthnAuthenticatorData(),
			ClientDataJSON:    content.GetWebauthnClientDataJson(),
		},
	})
	outcome := &chatv1.StawiCallOutcomeContent{GenesisId: binding.GenesisID, Kind: "GENESIS_SIGNATURE"}
	if err != nil {
		return sr.refusedOrTransient(ctx, act, err, outcome)
	}
	outcome.State = chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_ACCEPTED
	return sr.withOutcome(ctx, act, outcome)
}

func (sr *stawiRelay) relaySignedCall(
	ctx context.Context, act *stawiAct, content *chatv1.StawiSignedCallContent, bound bool,
) stawiRelayResult {
	if !bound {
		return stawiRelayResult{ack: connect.NewError(connect.CodeFailedPrecondition,
			"room calls need a Stawi room that is on chain")}
	}

	// Who must sign, for which room and what kind of call are settlement's
	// record of the prepared call, not the payload's.
	call, err := sr.rooms.GetRoomCall(ctx, content.GetCallId())
	if err != nil {
		if stawi.IsTransient(err) {
			return stawiRelayResult{ack: err}
		}
		return stawiRelayResult{ack: connect.Errorf(connect.CodeFailedPrecondition,
			"the call cannot be relayed: %s", stawi.RefusalReason(err))}
	}
	if call.RoomID != act.event.RoomID {
		return stawiRelayResult{ack: connect.NewError(connect.CodePermissionDenied,
			"the call was prepared for another room")}
	}
	if !strings.EqualFold(call.Kind, content.GetKind()) {
		return stawiRelayResult{ack: invalidStawiPayload(
			fmt.Errorf("the call is a %s call, not %s", call.Kind, content.GetKind()))}
	}
	if ackErr := sr.checkSigner(ctx, act, call); ackErr != nil {
		return stawiRelayResult{ack: ackErr}
	}

	// A call this room already relayed (an earlier attempt whose event was
	// then lost) is accepted again without a second submission.
	if prior, priorErr := sr.callRepo.GetByID(ctx, call.CallID); priorErr == nil {
		if prior.RoomID != act.event.RoomID || !strings.EqualFold(prior.SignerAddress, call.SignerAddress) ||
			prior.Nonce != call.Nonce {
			return stawiRelayResult{
				ack: connect.NewError(connect.CodeFailedPrecondition, repository.ErrStawiCallConflict.Error()).
					WithCause(repository.ErrStawiCallConflict),
			}
		}
		return sr.withOutcome(ctx, act, &chatv1.StawiCallOutcomeContent{CallId: call.CallID, Kind: call.Kind,
			State: chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_ACCEPTED})
	} else if !data.ErrorIsNoRows(priorErr) {
		return stawiRelayResult{ack: fmt.Errorf("failed to look up the relayed call: %w", priorErr)}
	}

	submitted, err := sr.rooms.SubmitRoomCall(ctx, stawi.CallSubmission{
		CallID: call.CallID,
		Signature: stawi.DeviceSignature{
			KeyID:             content.GetSignerKeyId(),
			Algorithm:         content.GetAlgorithm(),
			Signature:         content.GetSignature(),
			AuthenticatorData: content.GetWebauthnAuthenticatorData(),
			ClientDataJSON:    content.GetWebauthnClientDataJson(),
		},
		SignerProfileID: act.sender.ProfileID,
	})
	outcome := &chatv1.StawiCallOutcomeContent{CallId: call.CallID, Kind: call.Kind}
	if err != nil && connect.CodeOf(err) == connect.CodeAlreadyExists {
		// Settlement already has this call's signature (an earlier attempt):
		// what counts is where it stands now, not that this submit repeated.
		submitted, err = sr.rooms.GetRoomCall(ctx, call.CallID)
	}
	if err != nil {
		return sr.refusedOrTransient(ctx, act, err, outcome)
	}
	if submitted.State == stawi.CallStateFailed {
		return sr.refused(ctx, act, submitted.Reason, outcome)
	}

	tracked := &models.StawiRoomCall{
		RoomID:               act.event.RoomID,
		SourceEventID:        act.event.GetID(),
		SenderSubscriptionID: act.sender.GetID(),
		Kind:                 call.Kind,
		SignerAddress:        call.SignerAddress,
		Nonce:                call.Nonce,
		State:                models.StawiCallStateSubmitted,
	}
	tracked.ID = call.CallID
	tracked.GenID(ctx)
	if err = sr.callRepo.Record(ctx, tracked); err != nil {
		if errors.Is(err, repository.ErrStawiCallConflict) {
			return stawiRelayResult{ack: connect.NewError(connect.CodeFailedPrecondition, err.Error()).WithCause(err)}
		}
		return stawiRelayResult{ack: fmt.Errorf("failed to record the relayed call: %w", err)}
	}
	outcome.State = chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_ACCEPTED
	return sr.withOutcome(ctx, act, outcome)
}

// checkSigner requires the sender's subscription to be the call's signer:
// settlement must have prepared the call for the sender's profile, and the
// account it names as the signer must belong to that profile, as the profile
// service says.
func (sr *stawiRelay) checkSigner(ctx context.Context, act *stawiAct, call *stawi.RoomCall) error {
	if call.ProfileID != "" && call.ProfileID != act.sender.ProfileID {
		return connect.NewError(connect.CodePermissionDenied,
			"the call was prepared for another member")
	}
	if sr.accounts == nil {
		return errStawiNotConfigured
	}
	signer := strings.ToLower(call.SignerAddress)
	owners, err := sr.accounts.Resolve(ctx, []string{signer})
	if err != nil {
		return connect.NewError(
			connect.CodeUnavailable,
			fmt.Errorf("failed to resolve the call's signer: %w", err).Error(),
		)
	}
	if owner := owners[signer]; owner == "" || owner != act.sender.ProfileID {
		return connect.NewError(connect.CodePermissionDenied,
			"the call must be sent by the member who signs it")
	}
	return nil
}

func (sr *stawiRelay) refusedOrTransient(
	ctx context.Context, act *stawiAct, err error, outcome *chatv1.StawiCallOutcomeContent,
) stawiRelayResult {
	if stawi.IsTransient(err) {
		return stawiRelayResult{ack: connect.NewError(connect.CodeUnavailable,
			fmt.Errorf("settlement is unavailable, retry the same event: %w", err).Error())}
	}
	return sr.refused(ctx, act, stawi.RefusalReason(err), outcome)
}

func (sr *stawiRelay) refused(
	ctx context.Context, act *stawiAct, reason string, outcome *chatv1.StawiCallOutcomeContent,
) stawiRelayResult {
	outcome.State = chatv1.StawiCallOutcomeState_STAWI_CALL_OUTCOME_STATE_FAILED
	outcome.Reason = truncateReason(reason)
	return sr.withOutcome(ctx, act, outcome)
}

func (sr *stawiRelay) withOutcome(
	ctx context.Context, act *stawiAct, outcome *chatv1.StawiCallOutcomeContent,
) stawiRelayResult {
	outcome.SourceEventId = act.event.GetID()
	event, err := newOutcomeEvent(ctx, sr.converter, act.event.RoomID, act.event.GetID(), outcome)
	if err != nil {
		return stawiRelayResult{ack: err}
	}
	return stawiRelayResult{outcome: event}
}

// genesisClaimRefusal is the sender-facing refusal when a genesis cannot be
// recorded for them.
func genesisClaimRefusal(err error) error {
	if errors.Is(err, repository.ErrStawiGenesisNotClaimable) {
		return connect.NewError(connect.CodeFailedPrecondition,
			"another member's conversion of this room is pending; it can be replaced once it expires")
	}
	return fmt.Errorf("failed to record the genesis: %w", err)
}

const maxOutcomeReason = 1024

// truncateReason bounds a refusal reason to what an outcome carries.
func truncateReason(s string) string {
	if len(s) <= maxOutcomeReason {
		return s
	}
	return s[:maxOutcomeReason]
}

// newOutcomeEvent builds the server-generated STAWI_CALL_OUTCOME event for a
// room. It has no sending subscription: the room's server posts it.
func newOutcomeEvent(
	ctx context.Context, converter *models.PayloadConverter,
	roomID, parentID string, outcome *chatv1.StawiCallOutcomeContent,
) (*models.RoomEvent, error) {
	content, err := converter.FromProto(&chatv1.Payload{
		Type: chatv1.PayloadType_PAYLOAD_TYPE_STAWI_CALL_OUTCOME,
		Data: &chatv1.Payload_StawiCallOutcome{StawiCallOutcome: outcome},
	})
	if err != nil {
		return nil, fmt.Errorf("failed to encode the call outcome: %w", err)
	}
	event := &models.RoomEvent{
		RoomID:    roomID,
		EventType: int32(chatv1.RoomEventType_ROOM_EVENT_TYPE_SYSTEM),
		Content:   content,
		ParentID:  parentID,
	}
	event.ID = util.IDString()
	event.GenID(ctx)
	return event, nil
}

// serverEventLink is the outbox link for an event the server posts: it has no
// sending subscription.
func serverEventLink(event *models.RoomEvent) ([]byte, error) {
	return protojson.Marshal(&eventsv1.Link{
		EventId:   event.GetID(),
		RoomId:    event.RoomID,
		Source:    &eventsv1.Subscription{},
		ParentId:  event.ParentID,
		EventType: chatv1.RoomEventType(event.EventType),
		CreatedAt: timestamppb.New(event.CreatedAt),
	})
}
