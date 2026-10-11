// Package settlement adapts settlement's generated settlement.v1 RoomService
// client to stawi.Rooms, the room service as chat uses it.
package settlement

import (
	"context"
	"errors"
	"strings"
	"time"

	"buf.build/gen/go/stawi/finance/connectrpc/go/settlement/v1/settlementv1connect"
	financev1 "buf.build/gen/go/stawi/finance/protocolbuffers/go/finance/v1"
	settlementv1 "buf.build/gen/go/stawi/finance/protocolbuffers/go/settlement/v1"
	"connectrpc.com/connect"

	"github.com/stawilabs/chat/apps/default/service/stawi"
)

type rooms struct {
	client settlementv1connect.RoomServiceClient
}

// NewRooms wraps settlement's RoomService client. Chat calls it as its own
// service principal and always names the member it acts for: the converting
// admin on PrepareRoomGenesis, the signing founder on
// SubmitRoomGenesisSignature and the call's member on SubmitRoomCall.
// Settlement's errors are returned unchanged, so their connect codes decide
// whether chat reports a refusal or asks the sender to retry.
func NewRooms(client settlementv1connect.RoomServiceClient) stawi.Rooms {
	return &rooms{client: client}
}

func (r *rooms) PrepareRoomGenesis(ctx context.Context, req stawi.PrepareGenesisRequest) (*stawi.Genesis, error) {
	if len(req.RuleValues) > 0 {
		// Settlement takes a seeded template or a full constitution; rule
		// values over a template are compiled client-side into a constitution.
		return nil, connect.NewError(connect.CodeInvalidArgument,
			errors.New("rule values cannot be applied to a template here; send the template's own rules"))
	}
	resp, err := r.client.PrepareRoomGenesis(ctx, connect.NewRequest(&settlementv1.PrepareRoomGenesisRequest{
		ChatRoomId:         req.ChatRoomID,
		ConstitutionSource: &settlementv1.PrepareRoomGenesisRequest_TemplateId{TemplateId: req.TemplateID},
		FounderProfileIds:  req.FounderProfileIDs,
		JoinPolicy:         joinPolicy(req.JoinPolicy),
		ProfileId:          req.RequestedBy,
	}))
	if err != nil {
		return nil, err
	}
	return genesisOf(resp.Msg.GetGenesis()), nil
}

func (r *rooms) SubmitRoomGenesisSignature(
	ctx context.Context, sig stawi.GenesisSignature,
) (*stawi.GenesisSignatureResult, error) {
	resp, err := r.client.SubmitRoomGenesisSignature(ctx, connect.NewRequest(
		&settlementv1.SubmitRoomGenesisSignatureRequest{
			GenesisId: sig.GenesisID,
			Signature: deviceSignature(sig.Signature),
			ProfileId: sig.SignerProfileID,
		}))
	if err != nil {
		return nil, err
	}
	return &stawi.GenesisSignatureResult{
		Signed:    int(resp.Msg.GetGenesis().GetSignaturesCollected()),
		Required:  int(resp.Msg.GetGenesis().GetSignaturesRequired()),
		Submitted: resp.Msg.GetSubmitted(),
	}, nil
}

func (r *rooms) SubmitRoomCall(ctx context.Context, sub stawi.CallSubmission) (*stawi.RoomCall, error) {
	resp, err := r.client.SubmitRoomCall(ctx, connect.NewRequest(&settlementv1.SubmitRoomCallRequest{
		CallId:    sub.CallID,
		Signature: deviceSignature(sub.Signature),
		ProfileId: sub.SignerProfileID,
	}))
	if err != nil {
		return nil, err
	}
	return roomCallOf(resp.Msg.GetCall()), nil
}

func (r *rooms) GetRoomCall(ctx context.Context, callID string) (*stawi.RoomCall, error) {
	resp, err := r.client.GetRoomCall(ctx, connect.NewRequest(&settlementv1.GetRoomCallRequest{CallId: callID}))
	if err != nil {
		return nil, err
	}
	return roomCallOf(resp.Msg.GetCall()), nil
}

func joinPolicy(p stawi.JoinPolicy) financev1.RoomJoinPolicy {
	switch p {
	case stawi.JoinPolicyPublic:
		return financev1.RoomJoinPolicy_ROOM_JOIN_POLICY_PUBLIC
	case stawi.JoinPolicyPrivate:
		return financev1.RoomJoinPolicy_ROOM_JOIN_POLICY_PRIVATE
	case stawi.JoinPolicyUnspecified:
	}
	return financev1.RoomJoinPolicy_ROOM_JOIN_POLICY_UNSPECIFIED
}

func deviceSignature(s stawi.DeviceSignature) *financev1.DeviceSignature {
	return &financev1.DeviceSignature{
		DeviceKeyId:               s.KeyID,
		Algorithm:                 s.Algorithm,
		Signature:                 s.Signature,
		WebauthnAuthenticatorData: s.AuthenticatorData,
		WebauthnClientDataJson:    s.ClientDataJSON,
	}
}

func genesisOf(g *settlementv1.RoomGenesis) *stawi.Genesis {
	founders := make([]string, 0, len(g.GetFounders()))
	for _, f := range g.GetFounders() {
		founders = append(founders, f.GetProfileId())
	}
	var expires time.Time
	if g.GetExpiresAt() != nil {
		expires = g.GetExpiresAt().AsTime()
	}
	return &stawi.Genesis{
		GenesisID:         g.GetGenesisId(),
		GenesisHash:       g.GetGenesisHash(),
		ConstitutionHash:  g.GetConstitutionHash(),
		ExpiresAt:         expires,
		FounderProfileIDs: founders,
	}
}

func roomCallOf(c *settlementv1.RoomCall) *stawi.RoomCall {
	return &stawi.RoomCall{
		CallID:        c.GetCallId(),
		RoomID:        c.GetChatRoomId(),
		Kind:          strings.TrimPrefix(c.GetKind().String(), "ROOM_CALL_KIND_"),
		SignerAddress: stawi.HexAddress(c.GetSigner()),
		Nonce:         c.GetNonce(),
		ProfileID:     c.GetProfileId(),
		Custody:       stawi.HexAddress(c.GetCustody()),
		State:         callState(c.GetState()),
		Reason:        c.GetFailureReason(),
		TxHash:        c.GetTxHash(),
	}
}

func callState(s settlementv1.RoomCallState) stawi.CallState {
	switch s {
	case settlementv1.RoomCallState_ROOM_CALL_STATE_PREPARED:
		return stawi.CallStatePrepared
	case settlementv1.RoomCallState_ROOM_CALL_STATE_SUBMITTED, settlementv1.RoomCallState_ROOM_CALL_STATE_INCLUDED:
		return stawi.CallStateSubmitted
	case settlementv1.RoomCallState_ROOM_CALL_STATE_FINAL:
		return stawi.CallStateFinal
	case settlementv1.RoomCallState_ROOM_CALL_STATE_FAILED, settlementv1.RoomCallState_ROOM_CALL_STATE_EXPIRED:
		return stawi.CallStateFailed
	case settlementv1.RoomCallState_ROOM_CALL_STATE_UNSPECIFIED:
	}
	return stawi.CallStateUnspecified
}
