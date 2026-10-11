package queues

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	frevents "github.com/pitabwire/frame/v2/events"
	"github.com/pitabwire/frame/v2/queue"
	"github.com/pitabwire/util"

	"github.com/stawilabs/chat/apps/default/service/business"
)

// headerEventName is the header settlement's relay names each fact with.
const headerEventName = "event_name"

// SubscriptionDriftEventName names the reconciler's drift report.
const SubscriptionDriftEventName = "room.subscription_drift"

// FactReceiver applies one settlement fact.
type FactReceiver interface {
	Receive(ctx context.Context, eventName string, payload []byte) error
}

type stawiFactsHandler struct {
	receiver FactReceiver
}

// NewStawiFactsHandler subscribes chat's chain consumer to settlement's fact
// stream (svc.stawi.settlement.events). Each message is a finance.v1 event
// proto named by its event_name header. An error is returned, and the
// message redelivered, only when the fact could not be applied.
func NewStawiFactsHandler(receiver FactReceiver) queue.SubscribeWorker {
	return &stawiFactsHandler{receiver: receiver}
}

func (h *stawiFactsHandler) Handle(ctx context.Context, headers map[string]string, payload []byte) error {
	name := headers[headerEventName]
	if name == "" {
		name = headers[frevents.EventHeaderName]
	}
	if name == "" {
		util.Log(ctx).Warn("stawi facts: skipping a message without an event name")
		return nil
	}
	return h.receiver.Receive(ctx, name, payload)
}

type stawiDriftPublisher struct {
	queueMan  queue.Manager
	queueName string
}

// NewStawiDriftPublisher publishes room.subscription_drift reports as JSON on
// queueName; an empty name disables publishing (the repair still happens and
// is logged).
func NewStawiDriftPublisher(queueMan queue.Manager, queueName string) business.DriftPublisher {
	return &stawiDriftPublisher{queueMan: queueMan, queueName: queueName}
}

type driftFact struct {
	RoomID              string    `json:"room_id"`
	Restored            int       `json:"restored"`
	Removed             int       `json:"removed"`
	RolesFixed          int       `json:"roles_fixed"`
	PermissionsRepaired int       `json:"permissions_repaired"`
	At                  time.Time `json:"at"`
}

func (p *stawiDriftPublisher) PublishDrift(ctx context.Context, drift business.StawiDrift) error {
	util.Log(ctx).WithFields(map[string]any{
		"room_id": drift.RoomID, "restored": drift.Restored, "removed": drift.Removed,
		"roles_fixed": drift.RolesFixed, "permissions_repaired": drift.PermissionsRepaired,
	}).Warn("stawi reconciler: repaired subscription drift")
	if p.queueName == "" {
		return nil
	}
	body, err := json.Marshal(driftFact(drift))
	if err != nil {
		return err
	}
	publisher, err := p.queueMan.GetPublisher(p.queueName)
	if err != nil {
		return fmt.Errorf("no publisher for %s: %w", p.queueName, err)
	}
	return publisher.Publish(ctx, body, map[string]string{headerEventName: SubscriptionDriftEventName})
}
