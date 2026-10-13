package business

import (
	"context"
	"errors"
	"fmt"
	"time"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/pitabwire/frame/v2/data"
	"github.com/pitabwire/frame/v2/security"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/stawilabs/chat/apps/default/service"
	"github.com/stawilabs/chat/apps/default/service/models"
)

// agentInvitationTTL is how long an agent invitation may be accepted, and how
// long an acceptance lets the inviter name the acceptor the room's agent.
const agentInvitationTTL = 7 * 24 * time.Hour

// agentAcceptanceScan bounds how many of a partner's recent acceptances in
// one DM are read when a conversion names them agent.
const agentAcceptanceScan = 20

// agentAcceptanceSkew widens the read window past the TTL: an event's stored
// time comes from its client-chosen id, so the read is generous and the
// server-stamped expiry decides.
const agentAcceptanceSkew = time.Hour

var (
	errAgentInvitationOutsideDM = connect.NewError(connect.CodeFailedPrecondition,
		errors.New("an agent invitation is sent and accepted in a direct message"))
	errAgentInvitationRoom = connect.NewError(connect.CodePermissionDenied,
		errors.New("only the room's owner or an admin may invite its agent"))
	errNoAgentInvitation = invalidStawiPayload(
		errors.New("there is no such agent invitation in this chat"))
	errAgentInvitationNotYours = connect.NewError(connect.CodePermissionDenied,
		errors.New("only the person invited may accept an agent invitation"))
	errAgentInvitationExpired = connect.NewError(connect.CodeFailedPrecondition,
		errors.New("the agent invitation has expired"))
)

// directRoom loads the DM an agent invitation or acceptance is sent in.
func (sr *stawiRelay) directRoom(ctx context.Context, roomID string) (*models.Room, error) {
	dm, err := sr.roomRepo.GetByID(ctx, roomID)
	if err != nil {
		return nil, fmt.Errorf("failed to load the room: %w", err)
	}
	if dm.RoomType != models.RoomTypeDirect || dm.DirectKey == "" {
		return nil, errAgentInvitationOutsideDM
	}
	return dm, nil
}

// relayAgentInvitation stores an owner's or admin's invitation, sent in a DM,
// for the other person to be the Stawi agent of a group room. The room's name
// and the invitation's expiry are chat's, never the client's. Settlement is
// not involved: the invitation is chat's record of the partner's consent.
func (sr *stawiRelay) relayAgentInvitation(
	ctx context.Context, act *stawiAct, content *chatv1.StawiAgentInvitationContent,
) stawiRelayResult {
	dm, err := sr.directRoom(ctx, act.event.RoomID)
	if err != nil {
		return stawiRelayResult{ack: err}
	}

	// The room must be one the sender may convert: a group room of the DM's
	// tenancy they own or administer. Every other case is the same refusal,
	// so the invitation reveals nothing about rooms the sender is not in.
	room, err := sr.roomRepo.GetByID(ctx, content.GetRoomId())
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return stawiRelayResult{ack: errAgentInvitationRoom}
		}
		return stawiRelayResult{ack: fmt.Errorf("failed to load the room: %w", err)}
	}
	if room.TenantID != dm.TenantID {
		return stawiRelayResult{ack: errAgentInvitationRoom}
	}
	admin, err := sr.isRoomAdmin(ctx, room.GetID(), act.sender.ProfileID)
	if err != nil {
		return stawiRelayResult{ack: err}
	}
	if !admin {
		return stawiRelayResult{ack: errAgentInvitationRoom}
	}
	if room.RoomType == models.RoomTypeDirect || room.RoomType == models.RoomTypeBot {
		return stawiRelayResult{ack: service.ErrPersonalRoomNotStawi}
	}
	bound, err := sr.bindings.IsBound(ctx, room.GetID())
	if err != nil {
		return stawiRelayResult{ack: fmt.Errorf("failed to check the room binding: %w", err)}
	}
	if bound {
		return stawiRelayResult{ack: connect.NewError(connect.CodeFailedPrecondition,
			errors.New("the room is already a Stawi room"))}
	}

	content.RoomName = room.Name
	content.ExpiresAt = timestamppb.New(time.Now().Add(agentInvitationTTL))
	return sr.restore(act)
}

// relayAgentAcceptance stores the invited person's acceptance of an agent
// invitation in the same DM. Only the other person in the DM, the one the
// invitation was sent to, may accept it, and only before it expires. The
// acceptance carries the room the invitation names and its own expiry, both
// set by chat.
func (sr *stawiRelay) relayAgentAcceptance(
	ctx context.Context, act *stawiAct, content *chatv1.StawiAgentAcceptanceContent,
) stawiRelayResult {
	if _, err := sr.directRoom(ctx, act.event.RoomID); err != nil {
		return stawiRelayResult{ack: err}
	}
	inviterSub, invitation, err := sr.agentInvitation(ctx, act.event.RoomID, content.GetInvitationEventId())
	if err != nil {
		return stawiRelayResult{ack: err}
	}
	if invitation == nil {
		return stawiRelayResult{ack: errNoAgentInvitation}
	}
	if inviterSub == act.sender.GetID() {
		return stawiRelayResult{ack: errAgentInvitationNotYours}
	}
	now := time.Now()
	if !invitation.GetExpiresAt().IsValid() || !now.Before(invitation.GetExpiresAt().AsTime()) {
		return stawiRelayResult{ack: errAgentInvitationExpired}
	}

	content.RoomId = invitation.GetRoomId()
	content.RoomName = invitation.GetRoomName()
	content.ExpiresAt = timestamppb.New(now.Add(agentInvitationTTL))
	return sr.restore(act)
}

// restore re-encodes an act whose content the relay filled in.
func (sr *stawiRelay) restore(act *stawiAct) stawiRelayResult {
	stored, err := sr.converter.FromProto(act.payload)
	if err != nil {
		return stawiRelayResult{ack: fmt.Errorf("failed to encode the event: %w", err)}
	}
	act.event.Content = stored
	return stawiRelayResult{}
}

// agentInvitation is the agent invitation stored as eventID in the DM, with
// the subscription that sent it; a nil invitation when there is none.
func (sr *stawiRelay) agentInvitation(
	ctx context.Context, dmID, eventID string,
) (string, *chatv1.StawiAgentInvitationContent, error) {
	event, err := sr.eventRepo.GetByEventID(ctx, dmID, eventID)
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return "", nil, nil
		}
		return "", nil, fmt.Errorf("failed to read the agent invitation: %w", err)
	}
	payload, err := sr.converter.ToProto(event.Content)
	if err != nil || payload.GetType() != chatv1.PayloadType_PAYLOAD_TYPE_STAWI_AGENT_INVITATION {
		return "", nil, nil //nolint:nilerr // an undecodable or other event is no invitation
	}
	return event.SenderID, payload.GetStawiAgentInvitation(), nil
}

// isRoomAdmin reports whether the profile holds an active owner or admin
// subscription of the room.
func (sr *stawiRelay) isRoomAdmin(ctx context.Context, roomID, profileID string) (bool, error) {
	subs, err := sr.subRepo.GetByContactLinkAndRooms(ctx, &commonv1.ContactLink{ProfileId: profileID}, roomID)
	if err != nil {
		return false, fmt.Errorf("failed to read the sender's membership: %w", err)
	}
	for _, sub := range subs {
		if sub.IsActive() && sub.ProfileID == profileID && sub.RoomID == roomID &&
			(roleListContains(sub.Role, roleOwner) || roleListContains(sub.Role, roleAdmin)) {
			return true, nil
		}
	}
	return false, nil
}

// mayBeAgent reports whether agentID may be named the room's Stawi agent by
// the converting member: an active member of the room, or the converter's DM
// partner who has accepted, in that DM, the converter's agent invitation for
// exactly this room, while the acceptance holds. The agent is named by
// profile, never by subscription, so the genesis reveals no one's membership
// of a room they are not in.
func (sr *stawiRelay) mayBeAgent(ctx context.Context, room *models.Room, converterID, agentID string) (bool, error) {
	members, err := sr.subRepo.GetByContactLinkAndRooms(ctx, &commonv1.ContactLink{ProfileId: agentID}, room.GetID())
	if err != nil {
		return false, fmt.Errorf("failed to read the agent's membership: %w", err)
	}
	for _, sub := range members {
		if sub.IsActive() && sub.ProfileID == agentID {
			return true, nil
		}
	}
	if agentID == converterID || room.TenantID == "" {
		return false, nil
	}

	// The DM is looked for in the converting room's tenancy only.
	partitions := []string{room.PartitionID}
	if claims := security.ClaimsFromContext(ctx); claims != nil && claims.GetTenantID() == room.TenantID {
		partitions = append(partitions, claims.GetPartitionIDs()...)
	}
	dms, err := sr.roomRepo.DirectRooms(ctx, models.DirectKey(converterID, agentID), room.TenantID, partitions)
	if err != nil {
		return false, fmt.Errorf("failed to read the converter's DMs: %w", err)
	}
	now := time.Now()
	for _, dm := range dms {
		if dm.RoomType != models.RoomTypeDirect {
			continue
		}
		accepted, acceptErr := sr.agentAccepted(ctx, dm, room.GetID(), converterID, agentID, now)
		if acceptErr != nil || accepted {
			return accepted, acceptErr
		}
	}
	return false, nil
}

// agentAccepted reports whether, in the DM, the agent accepted the
// converter's agent invitation for roomID and the acceptance still holds.
// Both must still be active in the DM.
func (sr *stawiRelay) agentAccepted(
	ctx context.Context, dm *models.Room, roomID, converterID, agentID string, now time.Time,
) (bool, error) {
	subs, err := sr.subRepo.GetByRoomID(ctx, dm.GetID(), nil)
	if err != nil {
		return false, fmt.Errorf("failed to read the DM's members: %w", err)
	}
	var converterSub, agentSub string
	for _, sub := range subs {
		if !sub.IsActive() {
			continue
		}
		switch sub.ProfileID {
		case converterID:
			converterSub = sub.GetID()
		case agentID:
			agentSub = sub.GetID()
		}
	}
	if converterSub == "" || agentSub == "" {
		return false, nil
	}

	acceptances, err := sr.eventRepo.AuthoredOfPayloadType(ctx, dm.GetID(), agentSub,
		chatv1.PayloadType_PAYLOAD_TYPE_STAWI_AGENT_ACCEPTANCE,
		now.Add(-agentInvitationTTL-agentAcceptanceSkew), agentAcceptanceScan)
	if err != nil {
		return false, fmt.Errorf("failed to read the partner's agent acceptances: %w", err)
	}
	for _, event := range acceptances {
		payload, decodeErr := sr.converter.ToProto(event.Content)
		acceptance := payload.GetStawiAgentAcceptance()
		if decodeErr != nil || acceptance == nil || acceptance.GetRoomId() != roomID {
			continue
		}
		inviterSub, invitation, invErr := sr.agentInvitation(ctx, dm.GetID(), acceptance.GetInvitationEventId())
		if invErr != nil {
			return false, invErr
		}
		if agentAcceptanceHolds(inviterSub, invitation, acceptance, roomID, converterSub, now) {
			return true, nil
		}
	}
	return false, nil
}

// agentAcceptanceHolds decides one acceptance: it accepts an invitation the
// converter sent for exactly roomID, it came after that invitation and before
// the invitation expired, and it has not itself expired. The times compared
// are the expiries chat stamped when each was sent, never an event's stored
// time, which comes from its client-chosen id.
func agentAcceptanceHolds(
	inviterSub string, invitation *chatv1.StawiAgentInvitationContent,
	acceptance *chatv1.StawiAgentAcceptanceContent, roomID, converterSub string, now time.Time,
) bool {
	if invitation == nil || acceptance == nil || inviterSub == "" || inviterSub != converterSub ||
		invitation.GetRoomId() != roomID || acceptance.GetRoomId() != roomID {
		return false
	}
	if !invitation.GetExpiresAt().IsValid() || !acceptance.GetExpiresAt().IsValid() {
		return false
	}
	invitationExpiry := invitation.GetExpiresAt().AsTime()
	acceptanceExpiry := acceptance.GetExpiresAt().AsTime()
	invitedAt := invitationExpiry.Add(-agentInvitationTTL)
	acceptedAt := acceptanceExpiry.Add(-agentInvitationTTL)
	if !acceptedAt.After(invitedAt) || acceptedAt.After(invitationExpiry) {
		return false
	}
	return now.Before(acceptanceExpiry)
}
