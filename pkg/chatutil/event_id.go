package chatutil

import "github.com/rs/xid"

// isValidID reports whether id is a well-formed xid string, which is the
// identifier format the platform mints everywhere (frame's util.IDString).
func isValidID(id string) bool {
	_, err := xid.FromString(id)
	return err == nil
}

// IsValidEventID reports whether id is a well-formed xid string.
//
// Event ordering and keyset (cursor) pagination across the messaging layer rely
// on event IDs being xids: lexicographically time-sortable and machine-unique.
// Accepting an arbitrary client-supplied string would let a caller pin a message
// to the top or bottom of a room's timeline forever and poison NextCursor /
// PrevCursor for every member, so non-xid IDs must be rejected at the edge.
func IsValidEventID(id string) bool {
	return isValidID(id)
}

// IsValidRoomID reports whether id is a well-formed xid string.
//
// A room is the entity, and there is exactly one identifier for it: the same
// value names the room in chat, in the finance service and on chain. A room may
// therefore be created under an id its caller supplies rather than one chat
// mints, and the id chat accepts must still be the format every other holder of
// that value mints and stores, or the three records can no longer be joined.
// Chat validates the shape only; it does not thereby own, authorise or attest
// anything about the room the id names.
func IsValidRoomID(id string) bool {
	return isValidID(id)
}
