package business

import (
	"errors"

	chatv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
)

// maxFinanceCardDataEntries mirrors the proto constraint on
// FinanceCardContent.data and is enforced here too, because the server must
// not depend on a client having run validation.
const maxFinanceCardDataEntries = 32

// validateFinanceCardPayload checks a PAYLOAD_TYPE_FINANCE_CARD event before
// it is persisted.
//
// A finance card is a projection of a finance fact into a room: it is
// rendered, never obeyed. Chat carries no authorization, so the card is
// checked only for shape — it can name a proposal or a contribution, but
// tapping it opens the client's signing flow against the owning service, and
// nothing here grants, approves or executes anything.
func validateFinanceCardPayload(reqEvt *chatv1.RoomEvent) error {
	payload := reqEvt.GetPayload()
	if payload.GetType() != chatv1.PayloadType_PAYLOAD_TYPE_FINANCE_CARD {
		return nil
	}

	if reqEvt.GetType() != chatv1.RoomEventType_ROOM_EVENT_TYPE_EVENT {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("finance card event type must be ROOM_EVENT_TYPE_EVENT"),
		)
	}

	card := payload.GetFinanceCard()
	if card == nil {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("finance card payload is required"),
		)
	}

	for name, value := range map[string]string{
		"card_id":  card.GetCardId(),
		"group_id": card.GetGroupId(),
		"kind":     card.GetKind(),
		"title":    card.GetTitle(),
	} {
		if value == "" {
			return connect.NewError(
				connect.CodeInvalidArgument,
				errors.New(name+" is required"),
			)
		}
	}

	if len(card.GetData()) > maxFinanceCardDataEntries {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("finance card data has too many entries"),
		)
	}

	return nil
}
