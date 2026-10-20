package service

import (
	"errors"
	"fmt"
	"strings"

	"connectrpc.com/connect/v2"
)

// PartialBatchError represents an error where some items in a batch
// succeeded while others failed. This allows callers to distinguish
// between total failures and partial successes.
type PartialBatchError struct {
	Succeeded int
	Failed    int
	Errors    []ItemError
}

// ItemError describes a failure for a specific item in a batch operation.
type ItemError struct {
	Index   int
	ItemID  string
	Message string
}

func (e *PartialBatchError) Error() string {
	var sb strings.Builder
	fmt.Fprintf(&sb, "partial batch failure: %d succeeded, %d failed", e.Succeeded, e.Failed)
	for _, ie := range e.Errors {
		fmt.Fprintf(&sb, "; item %d (%s): %s", ie.Index, ie.ItemID, ie.Message)
	}
	return sb.String()
}

// IsPartialBatchError checks whether err is a PartialBatchError.
func IsPartialBatchError(err error) (*PartialBatchError, bool) {
	var pbe *PartialBatchError
	if errors.As(err, &pbe) {
		return pbe, true
	}
	return nil, false
}

var (
	ErrUnspecifiedID      = connect.NewError(connect.CodeInvalidArgument, "no id was supplied")
	ErrEmptyValueSupplied = connect.NewError(connect.CodeInvalidArgument, "empty value supplied")
	ErrItemExist          = connect.NewError(connect.CodeAlreadyExists, "specified item already exists")
	ErrItemDoesNotExist   = connect.NewError(connect.CodeNotFound, "specified item does not exist")

	// ErrRoomNameRequired is returned when room name is not provided.
	ErrRoomNameRequired = connect.NewError(connect.CodeInvalidArgument, "room name is required")
	ErrRoomIDRequired   = connect.NewError(connect.CodeInvalidArgument, "room ID is required")
	// ErrRoomIDInvalid is returned when a caller supplies a room ID that is not
	// the platform's identifier format. A room's id is one value shared by chat,
	// the finance service and the chain, so chat may accept an id it did not
	// mint but never one it could not have minted.
	ErrRoomIDInvalid = connect.NewError(
		connect.CodeInvalidArgument,
		"room ID must be a valid identifier",
	)
	// ErrRoomIDTaken is returned when a caller supplies a room ID that is already
	// in use by a room this caller cannot be shown, so the creation can neither
	// proceed nor be answered idempotently.
	ErrRoomIDTaken = connect.NewError(
		connect.CodeAlreadyExists,
		"room ID is already in use",
	)
	ErrRoomMembersRequired = connect.NewError(
		connect.CodeInvalidArgument,
		"at least one member is required",
	)
	ErrRoomNotFound     = connect.NewError(connect.CodeNotFound, "room not found")
	ErrRoomAccessDenied = connect.NewError(
		connect.CodePermissionDenied,
		"you don't have access to this room",
	)
	ErrRoomUpdateDenied = connect.NewError(
		connect.CodePermissionDenied,
		"only room admins can update the room",
	)
	ErrRoomDeleteDenied = connect.NewError(
		connect.CodePermissionDenied,
		"only room owners can delete the room",
	)
	ErrRoomAddMembersDenied = connect.NewError(
		connect.CodePermissionDenied,
		"you don't have permission to add members to this room",
	)
	ErrRoomRemoveMembersDenied = connect.NewError(
		connect.CodePermissionDenied,
		"you don't have permission to remove members from this room",
	)
	ErrRoomUpdateRoleDenied = connect.NewError(
		connect.CodePermissionDenied,
		"you don't have permission to update member roles",
	)
	// ErrRoleGrantDenied is returned when adding members would grant a role
	// above the adder's own (an admin cannot make anyone an owner).
	ErrRoleGrantDenied = connect.NewError(
		connect.CodePermissionDenied,
		"you cannot grant a role above your own",
	)
	// ErrRoleRemoveDenied is returned when removing members would remove
	// someone ranked above the remover (an admin cannot remove an owner).
	ErrRoleRemoveDenied = connect.NewError(
		connect.CodePermissionDenied,
		"you cannot remove someone whose role is above your own",
	)
	ErrRoomMemberNotFound = connect.NewError(connect.CodeNotFound, "member not found in room")

	// ErrCannotRemoveLastOwner is returned when an operation would leave a room
	// with no owner (removing or demoting the last owner), which would orphan
	// the room and make it permanently unmanageable.
	ErrCannotRemoveLastOwner = connect.NewError(
		connect.CodeFailedPrecondition,
		"cannot remove or demote the last owner of a room",
	)

	// ErrInvalidRole is returned when a role string is not one of the recognised
	// roles (owner, admin, member, guest).
	ErrInvalidRole = connect.NewError(
		connect.CodeInvalidArgument,
		"invalid role: must be one of owner, admin, member, guest",
	)

	// ErrMessageRoomIDRequired is returned when message room ID is not provided.
	ErrMessageRoomIDRequired  = connect.NewError(connect.CodeInvalidArgument, "room ID is required")
	ErrMessageContentRequired = connect.NewError(connect.CodeInvalidArgument, "message content is required")
	ErrMessageNotFound        = connect.NewError(connect.CodeNotFound, "message not found")
	ErrMessageAccessDenied    = connect.NewError(
		connect.CodePermissionDenied,
		"you don't have access to this message",
	)
	ErrMessageDeleteDenied = connect.NewError(
		connect.CodePermissionDenied,
		"you don't have permission to delete this message",
	)
	ErrMessageSendDenied = connect.NewError(
		connect.CodePermissionDenied,
		"you don't have permission to send messages to this room",
	)

	// ErrProfileIDsRequired is returned when profile IDs are not provided.
	ErrProfileIDsRequired = connect.NewError(
		connect.CodeInvalidArgument,
		"at least one profile ID is required",
	)
	ErrRoleRequired         = connect.NewError(connect.CodeInvalidArgument, "subscription Role is required")
	ErrSubscriptionNotFound = connect.NewError(connect.CodeNotFound, "subscription not found")

	// ErrProposalNotFound is returned when a proposal is not found.
	ErrProposalNotFound   = connect.NewError(connect.CodeNotFound, "proposal not found")
	ErrProposalNotPending = connect.NewError(
		connect.CodeFailedPrecondition,
		"proposal is not in pending state",
	)
	ErrProposalExpired = connect.NewError(
		connect.CodeFailedPrecondition,
		"proposal has expired",
	)
	ErrProposalApprovalDenied = connect.NewError(
		connect.CodePermissionDenied,
		"you don't have permission to approve or reject proposals",
	)
	// ErrDirectRoomMembers refuses a DM that is not between its creator and
	// exactly one other person on Stawi (a profile), never the creator themself.
	ErrDirectRoomMembers = connect.NewError(connect.CodeInvalidArgument,
		"a direct room is between you and exactly one other person on Stawi")
	// ErrPersonalRoomID refuses a supplied id on a DM or a bot room: a personal
	// room is found by its people, never by an id the caller names.
	ErrPersonalRoomID = connect.NewError(connect.CodeInvalidArgument,
		"a direct or bot room's id is chosen by chat")
	// ErrBotRoomByPerson refuses a person's bot room: only a service creates one.
	ErrBotRoomByPerson = connect.NewError(connect.CodeInvalidArgument, "a bot room is created by a service")
	// ErrDirectRoomMembership refuses a membership change in a DM or a bot room:
	// their members are fixed; no one joins and roles do not change.
	ErrDirectRoomMembership = connect.NewError(
		connect.CodeFailedPrecondition,
		"a direct room's members are fixed",
	)
	// ErrNoDirectPartner refuses a DM partner lookup the caller is not
	// entitled to. It is the one answer for every reason (no such room, not a
	// member, not a DM, someone left), so it says nothing about the room.
	ErrNoDirectPartner = connect.NewError(connect.CodePermissionDenied,
		"this is not a direct message you share with one other person")
	// ErrPartnerAccountUnavailable is a DM partner lookup settlement could not
	// answer; the caller may retry.
	ErrPartnerAccountUnavailable = connect.NewError(connect.CodeUnavailable,
		"the partner's Stawi account cannot be read right now")
	// ErrPartnerLookupsExhausted refuses a caller who looked up DM partners'
	// accounts too often; each lookup costs settlement a profile lookup and
	// chain reads. The caller may retry shortly.
	ErrPartnerLookupsExhausted = connect.NewError(connect.CodeResourceExhausted,
		"too many partner account lookups; try again in a minute")
	// ErrNoSharedContact refuses a contact's guardian key lookup the caller is
	// not entitled to. It is the one answer for every reason (no such room,
	// not a member, the contact not a member or silent in it), so it says
	// nothing about the room.
	ErrNoSharedContact = connect.NewError(connect.CodePermissionDenied,
		"this is not a person who has written in a room you share")
	// ErrContactKeysUnavailable is a contact's guardian key lookup settlement
	// could not answer; the caller may retry.
	ErrContactKeysUnavailable = connect.NewError(connect.CodeUnavailable,
		"the contact's guardian keys cannot be read right now")
	// ErrPersonalRoomNotStawi refuses a conversion of a DM or a bot room: neither
	// is ever a Stawi room (person to person money is the personal loan book's).
	ErrPersonalRoomNotStawi = connect.NewError(connect.CodeFailedPrecondition,
		"a direct or bot room is never a Stawi room")
	// ErrStawiRoomChainManaged refuses the chat-native ways of changing a Stawi
	// room that is on chain: its membership, roles, proposals and existence
	// follow the chain only.
	ErrStawiRoomChainManaged = connect.NewError(
		connect.CodeFailedPrecondition,
		"this is a Stawi room: its members, roles, proposals and existence change only on chain; "+
			"prepare the call through settlement, sign it on the device and send it as a STAWI_SIGNED_CALL payload",
	)

	ErrProposalRequired = connect.NewError(
		connect.CodeFailedPrecondition,
		"this operation requires approval; a proposal has been created",
	)
)
