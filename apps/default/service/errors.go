package service

import (
	"errors"
	"fmt"
	"strings"

	"connectrpc.com/connect"
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
	ErrUnspecifiedID      = connect.NewError(connect.CodeInvalidArgument, errors.New("no id was supplied"))
	ErrEmptyValueSupplied = connect.NewError(connect.CodeInvalidArgument, errors.New("empty value supplied"))
	ErrItemExist          = connect.NewError(connect.CodeAlreadyExists, errors.New("specified item already exists"))
	ErrItemDoesNotExist   = connect.NewError(connect.CodeNotFound, errors.New("specified item does not exist"))

	// ErrRoomNameRequired is returned when room name is not provided.
	ErrRoomNameRequired = connect.NewError(connect.CodeInvalidArgument, errors.New("room name is required"))
	ErrRoomIDRequired   = connect.NewError(connect.CodeInvalidArgument, errors.New("room ID is required"))
	// ErrRoomIDInvalid is returned when a caller supplies a room ID that is not
	// the platform's identifier format. A room's id is one value shared by chat,
	// the finance service and the chain, so chat may accept an id it did not
	// mint but never one it could not have minted.
	ErrRoomIDInvalid = connect.NewError(
		connect.CodeInvalidArgument,
		errors.New("room ID must be a valid identifier"),
	)
	// ErrRoomIDTaken is returned when a caller supplies a room ID that is already
	// in use by a room this caller cannot be shown, so the creation can neither
	// proceed nor be answered idempotently.
	ErrRoomIDTaken = connect.NewError(
		connect.CodeAlreadyExists,
		errors.New("room ID is already in use"),
	)
	ErrRoomMembersRequired = connect.NewError(
		connect.CodeInvalidArgument,
		errors.New("at least one member is required"),
	)
	ErrRoomNotFound     = connect.NewError(connect.CodeNotFound, errors.New("room not found"))
	ErrRoomAccessDenied = connect.NewError(
		connect.CodePermissionDenied,
		errors.New("you don't have access to this room"),
	)
	ErrRoomUpdateDenied = connect.NewError(
		connect.CodePermissionDenied,
		errors.New("only room admins can update the room"),
	)
	ErrRoomDeleteDenied = connect.NewError(
		connect.CodePermissionDenied,
		errors.New("only room owners can delete the room"),
	)
	ErrRoomAddMembersDenied = connect.NewError(
		connect.CodePermissionDenied,
		errors.New("you don't have permission to add members to this room"),
	)
	ErrRoomRemoveMembersDenied = connect.NewError(
		connect.CodePermissionDenied,
		errors.New("you don't have permission to remove members from this room"),
	)
	ErrRoomUpdateRoleDenied = connect.NewError(
		connect.CodePermissionDenied,
		errors.New("you don't have permission to update member roles"),
	)
	ErrRoomMemberNotFound = connect.NewError(connect.CodeNotFound, errors.New("member not found in room"))

	// ErrCannotRemoveLastOwner is returned when an operation would leave a room
	// with no owner (removing or demoting the last owner), which would orphan
	// the room and make it permanently unmanageable.
	ErrCannotRemoveLastOwner = connect.NewError(
		connect.CodeFailedPrecondition,
		errors.New("cannot remove or demote the last owner of a room"),
	)

	// ErrInvalidRole is returned when a role string is not one of the recognised
	// roles (owner, admin, member, guest).
	ErrInvalidRole = connect.NewError(
		connect.CodeInvalidArgument,
		errors.New("invalid role: must be one of owner, admin, member, guest"),
	)

	// ErrMessageRoomIDRequired is returned when message room ID is not provided.
	ErrMessageRoomIDRequired  = connect.NewError(connect.CodeInvalidArgument, errors.New("room ID is required"))
	ErrMessageContentRequired = connect.NewError(connect.CodeInvalidArgument, errors.New("message content is required"))
	ErrMessageNotFound        = connect.NewError(connect.CodeNotFound, errors.New("message not found"))
	ErrMessageAccessDenied    = connect.NewError(
		connect.CodePermissionDenied,
		errors.New("you don't have access to this message"),
	)
	ErrMessageDeleteDenied = connect.NewError(
		connect.CodePermissionDenied,
		errors.New("you don't have permission to delete this message"),
	)
	ErrMessageSendDenied = connect.NewError(
		connect.CodePermissionDenied,
		errors.New("you don't have permission to send messages to this room"),
	)

	// ErrProfileIDsRequired is returned when profile IDs are not provided.
	ErrProfileIDsRequired = connect.NewError(
		connect.CodeInvalidArgument,
		errors.New("at least one profile ID is required"),
	)
	ErrRoleRequired         = connect.NewError(connect.CodeInvalidArgument, errors.New("subscription Role is required"))
	ErrSubscriptionNotFound = connect.NewError(connect.CodeNotFound, errors.New("subscription not found"))

	// ErrProposalNotFound is returned when a proposal is not found.
	ErrProposalNotFound   = connect.NewError(connect.CodeNotFound, errors.New("proposal not found"))
	ErrProposalNotPending = connect.NewError(
		connect.CodeFailedPrecondition,
		errors.New("proposal is not in pending state"),
	)
	ErrProposalExpired = connect.NewError(
		connect.CodeFailedPrecondition,
		errors.New("proposal has expired"),
	)
	ErrProposalApprovalDenied = connect.NewError(
		connect.CodePermissionDenied,
		errors.New("you don't have permission to approve or reject proposals"),
	)
	// ErrDirectRoomMembers refuses a DM that is not between its creator and
	// exactly one other person on Stawi (a profile), never the creator themself.
	ErrDirectRoomMembers = connect.NewError(connect.CodeInvalidArgument,
		errors.New("a direct room is between you and exactly one other person on Stawi"))
	// ErrPersonalRoomID refuses a supplied id on a DM or a bot room: a personal
	// room is found by its people, never by an id the caller names.
	ErrPersonalRoomID = connect.NewError(connect.CodeInvalidArgument,
		errors.New("a direct or bot room's id is chosen by chat"))
	// ErrBotRoomByPerson refuses a person's bot room: only a service creates one.
	ErrBotRoomByPerson = connect.NewError(connect.CodeInvalidArgument, errors.New("a bot room is created by a service"))
	// ErrDirectRoomMembership refuses a membership change in a DM or a bot room:
	// their members are fixed; no one joins and roles do not change.
	ErrDirectRoomMembership = connect.NewError(
		connect.CodeFailedPrecondition,
		errors.New("a direct room's members are fixed"),
	)
	// ErrPersonalRoomNotStawi refuses a conversion of a DM or a bot room: neither
	// is ever a Stawi room (person to person money is the personal loan book's).
	ErrPersonalRoomNotStawi = connect.NewError(connect.CodeFailedPrecondition,
		errors.New("a direct or bot room is never a Stawi room"))
	// ErrStawiRoomChainManaged refuses the chat-native ways of changing a Stawi
	// room that is on chain: its membership, roles, proposals and existence
	// follow the chain only.
	ErrStawiRoomChainManaged = connect.NewError(
		connect.CodeFailedPrecondition,
		errors.New("this is a Stawi room: its members, roles, proposals and existence change only on chain; "+
			"prepare the call through settlement, sign it on the device and send it as a STAWI_SIGNED_CALL payload"),
	)

	ErrProposalRequired = connect.NewError(
		connect.CodeFailedPrecondition,
		errors.New("this operation requires approval; a proposal has been created"),
	)
)
