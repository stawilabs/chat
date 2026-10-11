package models

import (
	"strings"
	"time"

	"github.com/pitabwire/frame/v2/data"
)

// Stawi room binding states.
const (
	// StawiRoomStatePending: a genesis was prepared and awaits founder
	// signatures; the room is not yet on chain.
	StawiRoomStatePending = "pending"
	// StawiRoomStateBound: settlement observed the room's custody on chain
	// (room.activated). From here membership, roles and deletion follow the
	// chain only.
	StawiRoomStateBound = "bound"
)

// StawiRoom binds a chat room to its on-chain custody. Its ID is the chat room
// id, which is also the room's on-chain binding: one identifier names the room
// in chat, in finance and on chain.
type StawiRoom struct {
	data.BaseModel
	State string `gorm:"type:varchar(16);index"`
	// GenesisID is the latest genesis prepared for the room.
	GenesisID string `gorm:"type:varchar(64);index"`
	// GenesisEventID is the conversion event that carries the genesis card.
	GenesisEventID string `gorm:"type:varchar(50)"`
	// Founders is the comma-separated founder profile ids of the genesis.
	Founders          string `gorm:"type:text"`
	ChainID           uint64
	CustodyAddress    string `gorm:"type:varchar(42);index"`
	GovernanceAddress string `gorm:"type:varchar(42)"`
	PolicyEpoch       uint64
	BoundAt           *time.Time
}

// TableName returns the database table name for StawiRoom.
func (*StawiRoom) TableName() string { return "stawi_rooms" }

// IsBound reports whether the chain has the room.
func (r *StawiRoom) IsBound() bool { return r != nil && r.State == StawiRoomStateBound }

// FounderProfileIDs returns the founders of the room's latest genesis.
func (r *StawiRoom) FounderProfileIDs() []string {
	if r == nil || r.Founders == "" {
		return nil
	}
	return strings.Split(r.Founders, ",")
}

// IsFounder reports whether profileID founds the room's latest genesis.
func (r *StawiRoom) IsFounder(profileID string) bool {
	for _, founder := range r.FounderProfileIDs() {
		if founder == profileID {
			return true
		}
	}
	return false
}

// Stawi room call states, as chat tracks a relayed call until its outcome.
const (
	StawiCallStateSubmitted = "submitted"
	StawiCallStateFailed    = "failed"
	StawiCallStateObserved  = "observed"
)

// StawiRoomCall is a signed governance call chat relayed to settlement. Its ID
// is settlement's call id. It lets an observed chain fact, which names the
// signer and nonce, be reported against the chat event that carried the call.
type StawiRoomCall struct {
	data.BaseModel
	RoomID               string `gorm:"type:varchar(50);index:idx_stawi_call_signer,priority:1"`
	SourceEventID        string `gorm:"type:varchar(50)"`
	SenderSubscriptionID string `gorm:"type:varchar(50)"`
	Kind                 string `gorm:"type:varchar(64)"`
	SignerAddress        string `gorm:"type:varchar(42);index:idx_stawi_call_signer,priority:2"`
	Nonce                uint64 `gorm:"index:idx_stawi_call_signer,priority:3"`
	State                string `gorm:"type:varchar(16);index"`
}

// TableName returns the database table name for StawiRoomCall.
func (*StawiRoomCall) TableName() string { return "stawi_room_calls" }

// StawiChainFact is the consumer inbox for settlement's chain facts. FactKey
// is the log's identity on chain, (chain_id, tx_hash, log_index), so a fact
// delivered twice, or replayed, is recorded once. Facts are applied per room
// in (block, log_index) order; one that cannot be placed yet (its room is not
// known) stays unapplied until it can.
type StawiChainFact struct {
	data.BaseModel
	FactKey        string `gorm:"type:varchar(120);uniqueIndex:idx_stawi_chain_fact_key"`
	EventName      string `gorm:"type:varchar(64)"`
	RoomID         string `gorm:"type:varchar(50);index:idx_stawi_chain_fact_room_pos,priority:1"`
	CustodyAddress string `gorm:"type:varchar(42);index"`
	ChainID        uint64
	BlockNumber    uint64 `gorm:"index:idx_stawi_chain_fact_room_pos,priority:2"`
	LogIndex       uint64 `gorm:"index:idx_stawi_chain_fact_room_pos,priority:3"`
	Payload        []byte `gorm:"type:bytea;not null"`
	Applied        bool   `gorm:"index"`
	AppliedAt      *time.Time
	// OutcomeEventID is the id of the room event the fact posts, minted before
	// it is posted so a re-application posts the same event once.
	OutcomeEventID string `gorm:"type:varchar(50)"`
}

// TableName returns the database table name for StawiChainFact.
func (*StawiChainFact) TableName() string { return "stawi_chain_facts" }

// StawiMemberState mirrors the chain's member state (finance.v1 RoomMemberState).
type StawiMemberState int32

const (
	StawiMemberStateNone       StawiMemberState = 0
	StawiMemberStateActive     StawiMemberState = 1
	StawiMemberStateSuspended  StawiMemberState = 2
	StawiMemberStateExited     StawiMemberState = 3
	StawiMemberStateUnadmitted StawiMemberState = 4
	// StawiMemberStateInvited is chat's own: an open invitation, before the
	// invitee's consent makes them a member.
	StawiMemberStateInvited StawiMemberState = 100
)

// StawiRoomMember is chat's record of one account's membership of a Stawi
// room as the chain reports it: the facts history, folded. It is what the
// room's subscriptions are derived from and what the reconciler compares them
// against. Each part remembers the chain position that last set it, so a
// fact delivered out of order never overwrites a newer one.
type StawiRoomMember struct {
	data.BaseModel
	RoomID         string `gorm:"type:varchar(50);uniqueIndex:idx_stawi_member_room_address,priority:1"`
	Address        string `gorm:"type:varchar(42);uniqueIndex:idx_stawi_member_room_address,priority:2"`
	ProfileID      string `gorm:"type:varchar(50);index"`
	SubscriptionID string `gorm:"type:varchar(50)"`
	State          StawiMemberState
	StateBlock     uint64
	StateLogIndex  uint64
	// Roles maps a role id (hex) to {"assigned": bool, "block": n, "log": n}.
	Roles data.JSONMap
}

// TableName returns the database table name for StawiRoomMember.
func (*StawiRoomMember) TableName() string { return "stawi_room_members" }

// ChainPosition orders chain facts: by block, then by log index.
type ChainPosition struct {
	Block    uint64
	LogIndex uint64
}

// After reports whether p is strictly later on chain than other.
func (p ChainPosition) After(other ChainPosition) bool {
	if p.Block != other.Block {
		return p.Block > other.Block
	}
	return p.LogIndex > other.LogIndex
}

// StatePosition is where the member's state was last set.
func (m *StawiRoomMember) StatePosition() ChainPosition {
	return ChainPosition{Block: m.StateBlock, LogIndex: m.StateLogIndex}
}

// RoleEntry is one role's last-known assignment.
type RoleEntry struct {
	Assigned bool
	Position ChainPosition
}

// Role returns the member's last-known assignment of roleID.
func (m *StawiRoomMember) Role(roleID string) (RoleEntry, bool) {
	raw, ok := m.Roles[roleID].(map[string]any)
	if !ok {
		return RoleEntry{}, false
	}
	assigned, _ := raw["assigned"].(bool)
	return RoleEntry{
		Assigned: assigned,
		Position: ChainPosition{Block: jsonUint(raw["block"]), LogIndex: jsonUint(raw["log"])},
	}, true
}

// SetRole records roleID's assignment at pos.
func (m *StawiRoomMember) SetRole(roleID string, entry RoleEntry) {
	if m.Roles == nil {
		m.Roles = data.JSONMap{}
	}
	m.Roles[roleID] = map[string]any{
		"assigned": entry.Assigned,
		"block":    entry.Position.Block,
		"log":      entry.Position.LogIndex,
	}
}

// HoldsAnyRole reports whether any role is currently assigned to the member.
func (m *StawiRoomMember) HoldsAnyRole() bool {
	for roleID := range m.Roles {
		if entry, ok := m.Role(roleID); ok && entry.Assigned {
			return true
		}
	}
	return false
}

func jsonUint(v any) uint64 {
	switch n := v.(type) {
	case float64:
		if n < 0 {
			return 0
		}
		return uint64(n)
	case uint64:
		return n
	case int64:
		if n < 0 {
			return 0
		}
		return uint64(n)
	case int:
		if n < 0 {
			return 0
		}
		return uint64(n)
	default:
		return 0
	}
}
