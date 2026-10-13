package business

import (
	"context"
	"fmt"
	"slices"

	commonv1 "buf.build/gen/go/antinvestor/common/protocolbuffers/go/common/v1"
	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"github.com/pitabwire/frame/v2/data"
	"github.com/pitabwire/frame/v2/security"
	"github.com/pitabwire/util"

	"github.com/stawilabs/chat/apps/default/service"
	"github.com/stawilabs/chat/apps/default/service/models"
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
// chat checks the relationship itself first: the caller must be an active
// member of a DIRECT room of their tenancy that holds exactly two active
// members, the two its key names. Every other case is ErrNoDirectPartner,
// whatever the reason, and settlement is not asked. A partner without an
// account is answered with an empty account.
func (rb *roomBusiness) GetDirectPartnerAccount(
	ctx context.Context, roomID string, caller *commonv1.ContactLink,
) (_ *chatv1.GetDirectPartnerAccountResponse, err error) {
	ctx, span := chattel.RoomTracer.Start(ctx, "GetDirectPartnerAccount")
	defer func() { chattel.RoomTracer.End(ctx, span, err) }()

	if err = chatutil.IsValidContactLink(caller); err != nil {
		return nil, err
	}
	partnerID, err := rb.directPartnerOf(ctx, roomID, caller.GetProfileId())
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

// directPartnerOf returns the profile of the other active member of the
// caller's DM, or ErrNoDirectPartner.
func (rb *roomBusiness) directPartnerOf(ctx context.Context, roomID, callerID string) (string, error) {
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
	if room.RoomType != models.RoomTypeDirect || room.DirectKey == "" || !inCallersTenancy(ctx, room) {
		return "", service.ErrNoDirectPartner
	}
	subscriptions, err := rb.subscriptionRepo.GetByRoomID(ctx, roomID, nil)
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
	switch callerID {
	case first:
		return second, nil
	case second:
		return first, nil
	}
	return "", service.ErrNoDirectPartner
}

// inCallersTenancy reports whether room lies in the tenant and partitions
// the caller's claims carry; a context without a tenancy (an internal call
// or a test) is not restricted beyond the repository's own scoping.
func inCallersTenancy(ctx context.Context, room *models.Room) bool {
	claims := security.ClaimsFromContext(ctx)
	if claims == nil || claims.GetTenantID() == "" {
		return true
	}
	return room.TenantID == claims.GetTenantID() && slices.Contains(claims.GetPartitionIDs(), room.PartitionID)
}
