package business

import (
	"context"
	"fmt"
	"slices"
	"strings"
	"time"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/pitabwire/frame/v2/data"
	"github.com/pitabwire/frame/v2/security"
	"github.com/pitabwire/util"

	"github.com/stawilabs/chat/apps/default/service"
	"github.com/stawilabs/chat/apps/default/service/models"
	"github.com/stawilabs/chat/apps/default/service/repository"
	"github.com/stawilabs/chat/apps/default/service/stawi"
	"github.com/stawilabs/chat/pkg/chatutil"
	chattel "github.com/stawilabs/chat/pkg/telemetry"
)

// WithProfileAccounts enables GetDirectPartnerAccount: settlement's profile
// account lookup, called with chat's service credentials. Without it every
// lookup by an entitled member is answered Unavailable.
func WithProfileAccounts(accounts stawi.ProfileAccounts) RoomBusinessOption {
	return func(rb *roomBusiness) { rb.profileAccounts = accounts }
}

// GetDirectPartnerAccount answers the Stawi account of the other person in
// the caller's DM. Settlement answers any profile's account to a service, so
// chat checks the relationship itself first:
//   - the caller is a person (not an internal or service principal) whose
//     claims carry a tenancy;
//   - the room is a DIRECT room of that tenancy holding exactly two active
//     members, the two its key names, one of them the caller;
//   - the partner has taken part: they started the DM, or authored a
//     message or event in it. Anyone may start a DM with any profile, so
//     membership alone would let a stranger read anyone's account.
//
// Each person may look up at most defaultPartnerLookupsPerWindow partners'
// accounts a minute (ResourceExhausted beyond), since every lookup costs
// settlement a profile lookup and chain reads.
//
// Every other case is ErrNoDirectPartner, whatever the reason, and settlement
// is not asked. A partner without an account is answered with an empty
// account.
func (rb *roomBusiness) GetDirectPartnerAccount(
	ctx context.Context, roomID string, caller *commonv1.ContactLink,
) (_ *chatv1.GetDirectPartnerAccountResponse, err error) {
	ctx, span := chattel.RoomTracer.Start(ctx, "GetDirectPartnerAccount")
	defer func() { chattel.RoomTracer.End(ctx, span, err) }()

	if err = chatutil.IsValidContactLink(caller); err != nil {
		return nil, err
	}
	claims, err := personCaller(ctx, caller)
	if err != nil {
		return nil, err
	}
	if !rb.partnerLookups.allow(claims.GetProfileID(), time.Now()) {
		return nil, service.ErrPartnerLookupsExhausted
	}
	partnerID, err := rb.directPartnerOf(ctx, claims, roomID, caller.GetProfileId())
	if err != nil {
		return nil, err
	}
	if rb.profileAccounts == nil {
		return nil, service.ErrPartnerAccountUnavailable
	}
	account, err := rb.profileAccounts.GetProfileAccount(ctx, partnerID)
	if err != nil {
		if connect.CodeOf(err) == connect.CodeNotFound {
			// Settlement knows no such profile: it has no account either.
			return &chatv1.GetDirectPartnerAccountResponse{ProfileId: partnerID}, nil
		}
		util.Log(ctx).WithError(err).WithField(chatutil.KeyRoomID, roomID).
			Warn("settlement could not answer a DM partner's account")
		return nil, service.ErrPartnerAccountUnavailable
	}
	return &chatv1.GetDirectPartnerAccountResponse{
		ProfileId: partnerID,
		Account:   account.Account,
		Deployed:  len(account.Account) > 0 && account.Deployed,
	}, nil
}

// personCaller returns the claims of a person calling for themselves, or
// ErrNoDirectPartner. Only the handler reaches this path, always for a
// person, so there is no internal exemption: claims without a tenancy, an
// internal or service principal, or claims of another profile are refused.
func personCaller(ctx context.Context, caller *commonv1.ContactLink) (*security.AuthenticationClaims, error) {
	claims := security.ClaimsFromContext(ctx)
	if claims == nil || claims.GetTenantID() == "" || claims.GetPartitionID() == "" ||
		claims.IsInternalSystem() || claims.GetServiceName() != "" ||
		claims.GetProfileID() == "" || claims.GetProfileID() != caller.GetProfileId() {
		return nil, service.ErrNoDirectPartner
	}
	return claims, nil
}

// directPartnerOf returns the profile of the other active member of the
// caller's DM, once that member has taken part in it, or ErrNoDirectPartner.
func (rb *roomBusiness) directPartnerOf(
	ctx context.Context, claims *security.AuthenticationClaims, roomID, callerID string,
) (string, error) {
	if roomID == "" || callerID == "" {
		return "", service.ErrNoDirectPartner
	}
	room, err := rb.roomRepo.GetByID(ctx, roomID)
	if err != nil {
		if data.ErrorIsNoRows(err) {
			return "", service.ErrNoDirectPartner
		}
		return "", fmt.Errorf("failed to load the room: %w", err)
	}
	if room.RoomType != models.RoomTypeDirect || room.DirectKey == "" ||
		room.TenantID != claims.GetTenantID() || !slices.Contains(claims.GetPartitionIDs(), room.PartitionID) {
		return "", service.ErrNoDirectPartner
	}
	return consentingPartner(ctx, rb.subscriptionRepo, rb.eventRepo, room, callerID)
}

// consentingPartner returns the profile of the other active member of the
// caller's DM room, once that member has taken part in it, or
// ErrNoDirectPartner. The caller has already checked the room's type and
// tenancy.
func consentingPartner(
	ctx context.Context, subRepo repository.RoomSubscriptionRepository, eventRepo repository.RoomEventRepository,
	room *models.Room, callerID string,
) (string, error) {
	if room.RoomType != models.RoomTypeDirect || room.DirectKey == "" || callerID == "" {
		return "", service.ErrNoDirectPartner
	}
	subscriptions, err := subRepo.GetByRoomID(ctx, room.GetID(), nil)
	if err != nil {
		return "", fmt.Errorf("failed to read the room's members: %w", err)
	}
	var active []*models.RoomSubscription
	for _, sub := range subscriptions {
		if sub.IsActive() {
			active = append(active, sub)
		}
	}
	if len(active) != 2 { //nolint:mnd // a DM is two people
		return "", service.ErrNoDirectPartner
	}
	first, second := active[0].ProfileID, active[1].ProfileID
	if first == "" || second == "" || first == second || models.DirectKey(first, second) != room.DirectKey {
		return "", service.ErrNoDirectPartner
	}
	var partner *models.RoomSubscription
	switch callerID {
	case first:
		partner = active[1]
	case second:
		partner = active[0]
	default:
		return "", service.ErrNoDirectPartner
	}
	tookPart, err := partnerTookPart(ctx, eventRepo, room.GetID(), partner)
	if err != nil {
		return "", err
	}
	if !tookPart {
		return "", service.ErrNoDirectPartner
	}
	return partner.ProfileID, nil
}

// partnerTookPart reports whether the partner consented to the DM by taking
// part in it: they started it (a person's DM makes its starter the owner, and
// a DM's roles never change), or authored a message or event in it.
func partnerTookPart(
	ctx context.Context, eventRepo repository.RoomEventRepository, roomID string, partner *models.RoomSubscription,
) (bool, error) {
	if slices.Contains(strings.Split(partner.Role, ","), roleOwner) {
		return true, nil
	}
	authored, err := eventRepo.HasAuthoredInRoom(ctx, roomID, partner.GetID())
	if err != nil {
		return false, fmt.Errorf("failed to read whether the partner took part: %w", err)
	}
	return authored, nil
}
