package business

import (
	"context"
	"errors"
	"fmt"
	"slices"
	"time"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"github.com/pitabwire/frame/v3/data"
	"github.com/pitabwire/frame/v3/security"
	"github.com/pitabwire/util"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/stawilabs/chat/apps/default/service"
	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/stawi"
	"github.com/stawilabs/chat/pkg/chatutil"
	chattel "github.com/stawilabs/chat/pkg/telemetry"
)

// WithGuardianKeys enables LookupContactGuardianKeys: settlement's guardian
// key directory, called with chat's service credentials. Without it every
// lookup by an entitled member is answered Unavailable.
func WithGuardianKeys(keys stawi.GuardianKeys) RoomBusinessOption {
	return func(rb *roomBusiness) { rb.guardianKeys = keys }
}

// LookupContactGuardianKeys answers the guardian keys a contact registered
// with Stawi. Settlement answers a person only for a contact in a Stawi room
// both are ACTIVE in on chain, and answers a service for any profile, so chat
// checks the relationship itself first, for any room it holds:
//   - the caller is a person (not an internal or service principal) whose
//     claims carry a tenancy;
//   - the room is of that tenancy, and the caller and the contact are two
//     different active members of it; a DM must also be a well-formed DM of
//     exactly those two;
//   - the contact has taken part: they authored a message or event in the
//     room, or started the DM. Anyone may add anyone to a room or start a DM
//     with them, so membership alone would let a stranger read anyone's keys.
//
// Lookups share the per-person limit of DM partner account lookups
// (ResourceExhausted beyond), since each costs settlement chain reads.
//
// Every other case is ErrNoSharedContact, whatever the reason, and settlement
// is not asked. A settlement failure is ErrContactKeysUnavailable.
func (rb *roomBusiness) LookupContactGuardianKeys(
	ctx context.Context, roomID, contactID string, caller *commonv1.ContactLink,
) (_ *chatv1.LookupContactGuardianKeysResponse, err error) {
	ctx, span := chattel.RoomTracer.Start(ctx, "LookupContactGuardianKeys")
	defer func() { chattel.RoomTracer.End(ctx, span, err) }()

	if err = chatutil.IsValidContactLink(caller); err != nil {
		return nil, err
	}
	claims, err := personCaller(ctx, caller)
	if err != nil {
		return nil, service.ErrNoSharedContact
	}
	if !rb.partnerLookups.allow(claims.GetProfileID(), time.Now()) {
		return nil, service.ErrPartnerLookupsExhausted
	}
	if err = rb.sharedContact(ctx, claims, roomID, caller.GetProfileId(), contactID); err != nil {
		return nil, err
	}
	if rb.guardianKeys == nil {
		return nil, service.ErrContactKeysUnavailable
	}
	keys, head, err := rb.guardianKeys.LookupGuardianKeys(ctx, contactID)
	if err != nil {
		util.Log(ctx).WithError(err).WithField(chatutil.KeyRoomID, roomID).
			Warn("settlement could not answer a contact's guardian keys")
		return nil, service.ErrContactKeysUnavailable
	}
	out := &chatv1.LookupContactGuardianKeysResponse{ProfileId: contactID, BlockNumber: head}
	for _, k := range keys {
		key := &chatv1.ContactGuardianKey{Key: k.Key, Account: k.Account}
		if !k.RegisteredAt.IsZero() {
			key.RegisteredAt = timestamppb.New(k.RegisteredAt)
		}
		out.Keys = append(out.Keys, key)
	}
	return out, nil
}

// sharedContact checks that contactID is another active member of the
// caller's room roomID, of the caller's tenancy, who has taken part in it,
// else ErrNoSharedContact.
func (rb *roomBusiness) sharedContact(
	ctx context.Context, claims *security.AuthenticationClaims, roomID, callerID, contactID string,
) error {
	if roomID == "" || contactID == "" || contactID == callerID {
		return service.ErrNoSharedContact
	}
	room, err := rb.roomRepo.GetByID(ctx, roomID)
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return service.ErrNoSharedContact
		}
		return fmt.Errorf("failed to load the room: %w", err)
	}
	if room.TenantID != claims.GetTenantID() || !slices.Contains(claims.GetPartitionIDs(), room.PartitionID) {
		return service.ErrNoSharedContact
	}
	if room.RoomType == models.RoomTypeDirect {
		return rb.directContact(ctx, room, callerID, contactID)
	}
	return rb.groupContact(ctx, roomID, callerID, contactID)
}

// directContact checks that contactID is the consenting partner of the
// caller's DM room.
func (rb *roomBusiness) directContact(ctx context.Context, room *models.Room, callerID, contactID string) error {
	partner, err := consentingPartner(ctx, rb.subscriptionRepo, rb.eventRepo, room, callerID)
	if errors.Is(err, service.ErrNoDirectPartner) {
		return service.ErrNoSharedContact
	}
	if err != nil {
		return err
	}
	if partner != contactID {
		return service.ErrNoSharedContact
	}
	return nil
}

// groupContact checks that the caller and contactID are both active members
// of the group room roomID and that the contact has written in it. A group's
// roles can be changed by its officers, so only the contact's own message
// counts as taking part (a DM's starter consented by starting it, and a DM's
// roles never change).
func (rb *roomBusiness) groupContact(ctx context.Context, roomID, callerID, contactID string) error {
	subs, err := rb.subscriptionRepo.GetByRoomIDAndContactLinks(ctx, roomID,
		&commonv1.ContactLink{ProfileId: callerID}, &commonv1.ContactLink{ProfileId: contactID})
	if err != nil {
		return fmt.Errorf("failed to read the room's members: %w", err)
	}
	var mine, theirs *models.RoomSubscription
	for _, sub := range subs {
		switch {
		case !sub.IsActive():
		case sub.ProfileID == callerID:
			mine = sub
		case sub.ProfileID == contactID:
			theirs = sub
		}
	}
	if mine == nil || theirs == nil {
		return service.ErrNoSharedContact
	}
	authored, err := rb.eventRepo.HasAuthoredInRoom(ctx, roomID, theirs.GetID())
	if err != nil {
		return fmt.Errorf("failed to read whether the contact took part: %w", err)
	}
	if !authored {
		return service.ErrNoSharedContact
	}
	return nil
}
