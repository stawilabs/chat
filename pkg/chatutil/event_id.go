package chatutil

import "github.com/rs/xid"

// IsValidEventID reports whether id is a well-formed xid string.
//
// Event ordering and keyset (cursor) pagination across the messaging layer rely
// on event IDs being xids: lexicographically time-sortable and machine-unique.
// Accepting an arbitrary client-supplied string would let a caller pin a message
// to the top or bottom of a room's timeline forever and poison NextCursor /
// PrevCursor for every member, so non-xid IDs must be rejected at the edge.
func IsValidEventID(id string) bool {
	_, err := xid.FromString(id)
	return err == nil
}
