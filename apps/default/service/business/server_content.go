package business

import (
	"context"
	"errors"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
)

type serverOriginKey struct{}

// withServerOrigin marks ctx as the server sending its own event (a room
// change). The key is unexported, so nothing a client sends can set it.
func withServerOrigin(ctx context.Context) context.Context {
	return context.WithValue(ctx, serverOriginKey{}, true)
}

func isServerOrigin(ctx context.Context) bool {
	origin, _ := ctx.Value(serverOriginKey{}).(bool)
	return origin
}

// serverOnlyPayloadTypes are what only the server, or for cards the service
// card path, produces: they read as official, so a member may not send them.
//
//nolint:gochecknoglobals,exhaustive // immutable lookup table over the server-only types
var serverOnlyPayloadTypes = map[chatv1.PayloadType]struct{}{
	chatv1.PayloadType_PAYLOAD_TYPE_ROOM_CHANGE:        {},
	chatv1.PayloadType_PAYLOAD_TYPE_FINANCE_CARD:       {},
	chatv1.PayloadType_PAYLOAD_TYPE_STAWI_CALL_OUTCOME: {},
	chatv1.PayloadType_PAYLOAD_TYPE_MOTION_TALLY:       {},
	chatv1.PayloadType_PAYLOAD_TYPE_VOTE_TALLY:         {},
}

func isServerOnlyContent(payload *chatv1.Payload) bool {
	if _, ok := serverOnlyPayloadTypes[payload.GetType()]; ok {
		return true
	}
	switch payload.GetData().(type) {
	case *chatv1.Payload_RoomChange, *chatv1.Payload_FinanceCard, *chatv1.Payload_StawiCallOutcome,
		*chatv1.Payload_MotionTally, *chatv1.Payload_VoteTally:
		return true
	default:
		return false
	}
}

// refuseSpoofedContent refuses, on every client ingress path, content that
// would pass for the server's or for another member's: server-only payloads
// (whatever type they are declared under), system events, and an event or a
// moderation that names a subscription other than the sender's. The stored
// sender is always the caller's subscription.
func refuseSpoofedContent(ctx context.Context, reqEvt *chatv1.RoomEvent, senderSubscriptionID string) error {
	if !isServerOrigin(ctx) {
		if isServerOnlyContent(reqEvt.GetPayload()) {
			return connect.NewError(connect.CodePermissionDenied,
				errors.New("this content is posted by the server or a service, not by members"))
		}
		if reqEvt.GetType() == chatv1.RoomEventType_ROOM_EVENT_TYPE_SYSTEM {
			return connect.NewError(connect.CodePermissionDenied, errors.New("system events are posted by the server"))
		}
	}
	if id := reqEvt.GetSubscriptionId(); id != "" && id != senderSubscriptionID {
		return connect.NewError(connect.CodePermissionDenied,
			errors.New("an event can only be sent as the caller's own subscription"))
	}
	if actor := reqEvt.GetPayload().GetModeration().GetActorSubscriptionId(); actor != "" &&
		actor != senderSubscriptionID {
		return connect.NewError(connect.CodePermissionDenied,
			errors.New("a moderation's actor must be the caller's own subscription"))
	}
	return nil
}
