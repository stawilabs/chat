package events

import (
	"context"
	"errors"
	"fmt"

	eventsv1 "buf.build/gen/go/stawi/chat/protocolbuffers/go/events/v1"
	frevents "github.com/pitabwire/frame/events"
	"github.com/pitabwire/util"

	"github.com/stawilabs/chat/pkg/chatutil"
	chattel "github.com/stawilabs/chat/pkg/telemetry"
)

const (
	RoomCreatedEventName = "room.created.event"
)

type roomCreatedQueue struct {
	eventsManager frevents.Manager
}

func NewRoomCreatedQueue(
	_ context.Context,
	eventsManager frevents.Manager,
) frevents.EventI {
	return &roomCreatedQueue{
		eventsManager: eventsManager,
	}
}

func (csq *roomCreatedQueue) Name() string {
	return RoomCreatedEventName
}

func (csq *roomCreatedQueue) PayloadType() any {
	return &eventsv1.RoomActionList{}
}

func (csq *roomCreatedQueue) Validate(_ context.Context, payload any) error {
	_, ok := payload.(*eventsv1.RoomActionList)
	if !ok {
		return errors.New("invalid payload type, expected *eventsv1.RoomActionList")
	}
	return nil
}

// Execute return required for deferred tracing.
func (csq *roomCreatedQueue) Execute(ctx context.Context, payload any) error {
	var err error

	ctx, span := chattel.EventTracer.Start(ctx, "Room.Created")
	defer func() { chattel.EventTracer.End(ctx, span, err) }()

	// Unwrap payload
	actionList, ok := payload.(*eventsv1.RoomActionList)
	if !ok {
		return errors.New("invalid payload type")
	}

	util.Log(ctx).WithField("action_count", len(actionList.GetActions())).Debug("RoomCreated processing actions")

	for _, action := range actionList.GetActions() {
		util.Log(ctx).WithFields(map[string]any{
			chatutil.KeyRoomID: action.GetRoomId(),
			"target_count":     len(action.GetTargets()),
		}).Debug("RoomCreated emitting SubscriptionAdd")

		err = csq.eventsManager.Emit(ctx, SubscriptionAddEventName, action)
		if err != nil {
			return fmt.Errorf("failed to emit subscription add event: %w", err)
		}
	}

	return nil
}
