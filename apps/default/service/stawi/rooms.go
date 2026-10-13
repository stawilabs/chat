// Package stawi is chat's view of Stawi rooms: the settlement calls chat makes
// to relay room acts, and the account lookups that turn chain addresses into
// profiles.
//
// Settlement is the one chain writer. It builds every digest a device signs,
// relays every signed call and reports what the chain did. Chat never
// computes protocol digests, which keeps this public repository free of the
// private protocol code: everything here is plain data passed to and from
// settlement's RoomService (spec 2026-10-11 §2).
package stawi

import (
	"context"
	"encoding/hex"
	"errors"
	"time"

	"connectrpc.com/connect"
)

// JoinPolicy is how someone may enter a Stawi room once it is on chain.
type JoinPolicy int

const (
	JoinPolicyUnspecified JoinPolicy = iota
	JoinPolicyPrivate
	JoinPolicyPublic
)

// PrepareGenesisRequest asks settlement to compile a room's constitution and
// prepare its genesis for the founders to sign.
type PrepareGenesisRequest struct {
	// ChatRoomID is the room's id, which becomes its on-chain binding.
	ChatRoomID string
	TemplateID string
	RuleValues map[string]string
	// FounderProfileIDs are resolved to accounts by settlement through profile.
	FounderProfileIDs []string
	JoinPolicy        JoinPolicy
	// RequestedBy is the profile that sent the conversion.
	RequestedBy string
}

// Genesis is a prepared room genesis awaiting founder signatures.
type Genesis struct {
	GenesisID         string
	GenesisHash       []byte
	ConstitutionHash  []byte
	ExpiresAt         time.Time
	FounderProfileIDs []string
}

// DeviceSignature is a device's signature over a digest settlement built.
type DeviceSignature struct {
	KeyID string
	// Algorithm is "secp256k1" or "p256-webauthn".
	Algorithm string
	Signature []byte
	// WebAuthn assertion material; empty for secp256k1.
	AuthenticatorData []byte
	ClientDataJSON    []byte
}

// GenesisSignature is one founder's device signature over a genesis.
type GenesisSignature struct {
	GenesisID       string
	SignerProfileID string
	Signature       DeviceSignature
}

// GenesisSignatureResult says how far the genesis is from founding quorum.
type GenesisSignatureResult struct {
	Signed   int
	Required int
	// Submitted is true once quorum was reached and createRoom was sent.
	Submitted bool
}

// CallState is where a relayed room call stands in settlement.
type CallState int

const (
	CallStateUnspecified CallState = iota
	// CallStatePrepared means built and awaiting the device signature.
	CallStatePrepared
	// CallStateSubmitted means signed, simulated and relayed; awaiting a final block.
	CallStateSubmitted
	// CallStateFinal means the chain applied it in a final block.
	CallStateFinal
	// CallStateFailed means refused before relay, reverted or expired.
	CallStateFailed
)

// RoomCall is a governance call settlement prepared for a room.
type RoomCall struct {
	CallID string
	// RoomID is the chat room (the on-chain room binding) the call acts on.
	RoomID string
	Kind   string
	// SignerAddress is the account that must sign the call (0x hex).
	SignerAddress string
	// Nonce is the signer's call nonce; with SignerAddress it names the call
	// in settlement's governance facts.
	Nonce uint64
	// ProfileID is the profile settlement prepared the call for; only that
	// profile may submit it.
	ProfileID string
	// Custody is the room's RoomCustody (0x hex).
	Custody string
	State   CallState
	Reason  string
	TxHash  []byte
}

// CallSubmission is a signed call handed to settlement for relay.
type CallSubmission struct {
	CallID          string
	Signature       DeviceSignature
	SignerProfileID string
}

// Rooms is settlement's RoomService as chat uses it. Every method is
// idempotent on settlement's side: a genesis signature by (genesis, signer),
// a call by its id.
type Rooms interface {
	PrepareRoomGenesis(ctx context.Context, req PrepareGenesisRequest) (*Genesis, error)
	SubmitRoomGenesisSignature(ctx context.Context, sig GenesisSignature) (*GenesisSignatureResult, error)
	SubmitRoomCall(ctx context.Context, sub CallSubmission) (*RoomCall, error)
	GetRoomCall(ctx context.Context, callID string) (*RoomCall, error)
}

// AccountResolver maps chain addresses to the profiles that own them. The
// profile service client (service-profile client/accounts) satisfies it; an
// address no profile owns is absent from the result.
type AccountResolver interface {
	Resolve(ctx context.Context, addresses []string) (map[string]string, error)
}

// ErrNotConfigured is returned when chat runs without a settlement client.
var ErrNotConfigured = connect.NewError(connect.CodeUnavailable,
	errors.New("stawi rooms are not available: settlement is not configured"))

// IsTransient reports whether a settlement error is worth retrying as is:
// settlement could not be reached or did not answer, as opposed to refusing
// the act. A refused act is final and is reported to the room; a transient
// failure is returned to the sender, who retries with the same event id.
func IsTransient(err error) bool {
	if err == nil {
		return false
	}
	if errors.Is(err, context.DeadlineExceeded) || errors.Is(err, context.Canceled) {
		return true
	}
	switch connect.CodeOf(err) {
	case connect.CodeInvalidArgument, connect.CodeNotFound, connect.CodeAlreadyExists,
		connect.CodePermissionDenied, connect.CodeFailedPrecondition, connect.CodeOutOfRange:
		return false
	case connect.CodeUnavailable, connect.CodeDeadlineExceeded, connect.CodeResourceExhausted,
		connect.CodeAborted, connect.CodeInternal, connect.CodeUnknown, connect.CodeCanceled,
		connect.CodeUnimplemented, connect.CodeDataLoss, connect.CodeUnauthenticated:
		return true
	}
	return true
}

// RefusalReason is the reason a refused act is reported with: the message
// settlement gave, without the transport's code prefix.
func RefusalReason(err error) string {
	var connectErr *connect.Error
	if errors.As(err, &connectErr) {
		if msg := connectErr.Message(); msg != "" {
			return msg
		}
	}
	return err.Error()
}

// HexAddress renders a chain address the way chat stores it: lowercase 0x hex.
func HexAddress(b []byte) string {
	if len(b) == 0 {
		return ""
	}
	return "0x" + hex.EncodeToString(b)
}

// ProfileAccount is a profile's primary Stawi account as settlement reports
// it. An empty Account means the profile has none.
type ProfileAccount struct {
	Account []byte
	// Deployed is whether the account has code at the head.
	Deployed bool
}

// ProfileAccounts is settlement's AccountService.GetProfileAccount as chat
// uses it: chat calls it as its own service principal, and only after it has
// itself checked the relationship that entitles a person to the address.
type ProfileAccounts interface {
	GetProfileAccount(ctx context.Context, profileID string) (*ProfileAccount, error)
}
