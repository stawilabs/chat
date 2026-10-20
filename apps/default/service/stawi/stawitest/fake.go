// Package stawitest provides in-memory stand-ins for settlement's RoomService
// and the profile account lookup, for tests of chat's Stawi room paths.
package stawitest

import (
	"context"
	"strings"
	"sync"
	"time"

	"connectrpc.com/connect/v2"
	"github.com/pitabwire/util"

	"github.com/stawilabs/chat/apps/default/service/stawi"
)

// Rooms is a fake settlement RoomService. Calls registered with AddCall are
// served by GetRoomCall and SubmitRoomCall; Refuse makes the next calls of a
// method fail with the given error.
type Rooms struct {
	mu sync.Mutex

	geneses    map[string]*stawi.Genesis
	signatures map[string][]stawi.GenesisSignature
	calls      map[string]*stawi.RoomCall

	// Prepared records every PrepareRoomGenesis request.
	Prepared []stawi.PrepareGenesisRequest
	// Submitted records every SubmitRoomCall.
	Submitted []stawi.CallSubmission

	errs map[string]error

	// GenesisTTL is how long a prepared genesis stays signable (default 1h;
	// a negative value prepares geneses that have already expired).
	GenesisTTL time.Duration
}

// NewRooms returns an empty fake RoomService.
func NewRooms() *Rooms {
	return &Rooms{
		geneses:    map[string]*stawi.Genesis{},
		signatures: map[string][]stawi.GenesisSignature{},
		calls:      map[string]*stawi.RoomCall{},
		errs:       map[string]error{},
	}
}

// Method names accepted by Refuse.
const (
	MethodPrepareRoomGenesis         = "PrepareRoomGenesis"
	MethodSubmitRoomGenesisSignature = "SubmitRoomGenesisSignature"
	MethodSubmitRoomCall             = "SubmitRoomCall"
	MethodGetRoomCall                = "GetRoomCall"
)

// Refuse makes method fail with err until Refuse is called with a nil error.
func (r *Rooms) Refuse(method string, err error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if err == nil {
		delete(r.errs, method)
		return
	}
	r.errs[method] = err
}

// Refusal is a settlement refusal as the chain would give it.
func Refusal(reason string) error {
	return connect.NewError(connect.CodeFailedPrecondition, reason)
}

// AddCall registers a prepared call, as if the app had called PrepareRoomCall.
func (r *Rooms) AddCall(call stawi.RoomCall) {
	r.mu.Lock()
	defer r.mu.Unlock()
	c := call
	if c.State == stawi.CallStateUnspecified {
		c.State = stawi.CallStatePrepared
	}
	r.calls[c.CallID] = &c
}

// SetCallState moves a registered call, as the chain would.
func (r *Rooms) SetCallState(callID string, state stawi.CallState, reason string) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if c, ok := r.calls[callID]; ok {
		c.State = state
		c.Reason = reason
	}
}

// Signatures returns the signatures received for a genesis.
func (r *Rooms) Signatures(genesisID string) []stawi.GenesisSignature {
	r.mu.Lock()
	defer r.mu.Unlock()
	return append([]stawi.GenesisSignature(nil), r.signatures[genesisID]...)
}

func (r *Rooms) genesisTTL() time.Duration {
	if r.GenesisTTL == 0 {
		return time.Hour
	}
	return r.GenesisTTL
}

func (r *Rooms) refusal(method string) error {
	return r.errs[method]
}

func (r *Rooms) PrepareRoomGenesis(_ context.Context, req stawi.PrepareGenesisRequest) (*stawi.Genesis, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if err := r.refusal(MethodPrepareRoomGenesis); err != nil {
		return nil, err
	}
	r.Prepared = append(r.Prepared, req)
	g := &stawi.Genesis{
		GenesisID:         util.IDString(),
		GenesisHash:       []byte("genesis-hash-" + req.ChatRoomID),
		ConstitutionHash:  []byte("constitution-" + req.TemplateID),
		ExpiresAt:         time.Now().Add(r.genesisTTL()).UTC().Truncate(time.Second),
		FounderProfileIDs: append([]string(nil), req.FounderProfileIDs...),
	}
	r.geneses[g.GenesisID] = g
	return g, nil
}

func (r *Rooms) SubmitRoomGenesisSignature(
	_ context.Context, sig stawi.GenesisSignature,
) (*stawi.GenesisSignatureResult, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if err := r.refusal(MethodSubmitRoomGenesisSignature); err != nil {
		return nil, err
	}
	g, ok := r.geneses[sig.GenesisID]
	if !ok {
		return nil, connect.Errorf(connect.CodeNotFound, "genesis %s not found", sig.GenesisID)
	}
	for _, existing := range r.signatures[sig.GenesisID] {
		if existing.SignerProfileID == sig.SignerProfileID {
			return &stawi.GenesisSignatureResult{
				Signed: len(r.signatures[sig.GenesisID]), Required: len(g.FounderProfileIDs),
			}, nil
		}
	}
	r.signatures[sig.GenesisID] = append(r.signatures[sig.GenesisID], sig)
	signed := len(r.signatures[sig.GenesisID])
	return &stawi.GenesisSignatureResult{
		Signed: signed, Required: len(g.FounderProfileIDs), Submitted: signed == len(g.FounderProfileIDs),
	}, nil
}

func (r *Rooms) SubmitRoomCall(_ context.Context, sub stawi.CallSubmission) (*stawi.RoomCall, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if err := r.refusal(MethodSubmitRoomCall); err != nil {
		return nil, err
	}
	c, ok := r.calls[sub.CallID]
	if !ok {
		return nil, connect.Errorf(connect.CodeNotFound, "call %s not found", sub.CallID)
	}
	r.Submitted = append(r.Submitted, sub)
	if c.State == stawi.CallStatePrepared {
		c.State = stawi.CallStateSubmitted
	}
	out := *c
	return &out, nil
}

func (r *Rooms) GetRoomCall(_ context.Context, callID string) (*stawi.RoomCall, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if err := r.refusal(MethodGetRoomCall); err != nil {
		return nil, err
	}
	c, ok := r.calls[callID]
	if !ok {
		return nil, connect.Errorf(connect.CodeNotFound, "call %s not found", callID)
	}
	out := *c
	return &out, nil
}

// Accounts is a fake profile account lookup.
type Accounts struct {
	mu     sync.Mutex
	owners map[string]string
	err    error
	// Calls counts Resolve calls.
	Calls int
}

// NewAccounts returns an empty fake account lookup.
func NewAccounts() *Accounts { return &Accounts{owners: map[string]string{}} }

// Own records that profileID owns address.
func (a *Accounts) Own(address, profileID string) {
	a.mu.Lock()
	defer a.mu.Unlock()
	a.owners[strings.ToLower(address)] = profileID
}

// Fail makes Resolve fail with err (nil restores it).
func (a *Accounts) Fail(err error) {
	a.mu.Lock()
	defer a.mu.Unlock()
	a.err = err
}

func (a *Accounts) Resolve(_ context.Context, addresses []string) (map[string]string, error) {
	a.mu.Lock()
	defer a.mu.Unlock()
	a.Calls++
	if a.err != nil {
		return nil, a.err
	}
	out := make(map[string]string, len(addresses))
	for _, addr := range addresses {
		if p, ok := a.owners[strings.ToLower(addr)]; ok {
			out[strings.ToLower(addr)] = p
		}
	}
	return out, nil
}

// ProfileAccounts is a fake settlement GetProfileAccount: a profile without a
// registered account answers empty, as settlement does.
type ProfileAccounts struct {
	mu       sync.Mutex
	accounts map[string]stawi.ProfileAccount
	err      error
	// Asked records every profile looked up.
	Asked []string
}

// NewProfileAccounts returns a fake lookup that knows no accounts.
func NewProfileAccounts() *ProfileAccounts {
	return &ProfileAccounts{accounts: map[string]stawi.ProfileAccount{}}
}

// Set records profileID's primary account.
func (p *ProfileAccounts) Set(profileID string, account []byte, deployed bool) {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.accounts[profileID] = stawi.ProfileAccount{Account: account, Deployed: deployed}
}

// Fail makes every lookup fail with err (nil restores it).
func (p *ProfileAccounts) Fail(err error) {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.err = err
}

func (p *ProfileAccounts) GetProfileAccount(_ context.Context, profileID string) (*stawi.ProfileAccount, error) {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.Asked = append(p.Asked, profileID)
	if p.err != nil {
		return nil, p.err
	}
	account := p.accounts[profileID]
	return &account, nil
}

// GuardianKeys is a fake settlement LookupGuardianKeys: a profile with no
// registered keys answers none, as settlement does.
type GuardianKeys struct {
	mu   sync.Mutex
	keys map[string][]stawi.GuardianKey
	err  error
	// Head is the block every answer names.
	Head uint64
	// Asked records every profile looked up.
	Asked []string
}

// NewGuardianKeys returns a fake directory that knows no keys.
func NewGuardianKeys() *GuardianKeys {
	return &GuardianKeys{keys: map[string][]stawi.GuardianKey{}, Head: 1}
}

// Set records profileID's guardian keys.
func (g *GuardianKeys) Set(profileID string, keys ...stawi.GuardianKey) {
	g.mu.Lock()
	defer g.mu.Unlock()
	g.keys[profileID] = keys
}

// Fail makes every lookup fail with err (nil restores it).
func (g *GuardianKeys) Fail(err error) {
	g.mu.Lock()
	defer g.mu.Unlock()
	g.err = err
}

func (g *GuardianKeys) LookupGuardianKeys(_ context.Context, profileID string) ([]stawi.GuardianKey, uint64, error) {
	g.mu.Lock()
	defer g.mu.Unlock()
	g.Asked = append(g.Asked, profileID)
	if g.err != nil {
		return nil, 0, g.err
	}
	return g.keys[profileID], g.Head, nil
}
