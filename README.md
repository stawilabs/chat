# Real-Time Message Flow Architecture

## Overview

The chat service implements a scalable, queue-based architecture for real-time message delivery to end users. Messages flow from sender → default service → queue → gateway → device streams.

## Complete Flow

```
┌──────────┐
│  Sender  │
│  Device  │
└────┬─────┘
     │ 1. SendEvent (HTTP/gRPC)
     ▼
┌─────────────────────────────────────────────────────────┐
│              DEFAULT SERVICE                             │
│  ┌────────────────────────────────────────────────┐    │
│  │ MessageBusiness.SendEvents()                    │    │
│  │  - Validates room access                        │    │
│  │  - Saves RoomEvent + room_outbox row in ONE     │    │
│  │    transaction (nothing is emitted inline)      │    │
│  └──────────────────┬──────────────────────────────┘    │
│                     ▼                                    │
│  ┌────────────────────────────────────────────────┐    │
│  │ OutboxRelay (Background Consumer)               │    │
│  │  - Sole publisher: drains room_outbox           │    │
│  │  - Emits "room.outbox.logging.event" (Link)     │    │
│  │  - For rooms whose metadata carries             │    │
│  │    stawi.group_id, also publishes the durable   │    │
│  │    "chat.room.event.published" fact             │    │
│  └──────────────────┬──────────────────────────────┘    │
│                     ▼                                    │
│  ┌────────────────────────────────────────────────┐    │
│  │ RoomOutboxLoggingQueue (Event Handler)          │    │
│  │  - Pages active room subscribers (1000/batch)   │    │
│  │  - Emits "room.message.fanout.event" with       │    │
│  │    Broadcast (event + destinations + payload)   │    │
│  └──────────────────┬──────────────────────────────┘    │
│                     ▼                                    │
│  ┌────────────────────────────────────────────────┐    │
│  │ FanoutEventHandler (Event Handler)              │    │
│  │  - Builds a Delivery per destination            │    │
│  │  - Publishes to "device.event.delivery" queue   │    │
│  └──────────────────┬──────────────────────────────┘    │
└────────────────────┼──────────────────────────────────┘
                     │
                     ▼
         ┌────────────────────────┐
         │  QUEUE INFRASTRUCTURE  │
         │ (device.event.delivery)│
         └──────────┬──────────────┘
                    │
                    ▼
┌───────────────────────────────────────────────────────────┐
│  HotPathDeliveryQueueHandler (Queue Subscriber)            │
│   - Queries device service for the recipient's devices    │
│   - For each device:                                      │
│     - Online: publishes to the device's gateway shard     │
│       queue with headers:                                 │
│         * profile_id: {recipient_id}                      │
│         * device_id: {device_id}                          │
│     - Offline: hands off to "offline.event.delivery"      │
│   - Exhausted retries go to "dead.letter.queue"           │
└───────────────────┬───────────────────────────────────────┘
                    │
                    ▼
         ┌────────────────────────┐
         │  QUEUE INFRASTRUCTURE  │
         │ (gateway.event.delivery│
         │   .N, header filters)  │
         └──────────┬──────────────┘
                    │
                    ├──────────────┐ ┌──────────────┐
                    ▼              ▼ ▼              ▼
            ┌─────────────┐    ┌─────────────┐  ┌─────────────┐
            │  Gateway 1  │    │  Gateway 2  │  │  Gateway N  │
            │             │    │             │  │             │
            │ Device A    │    │ Device B    │  │ Device C    │
            │ (filtered)  │    │ (filtered)  │  │ (filtered)  │
            └─────┬───────┘    └─────┬───────┘  └─────┬───────┘
                  │                   │                 │
                  │ ServerEvent       │ ServerEvent     │ ServerEvent
                  ▼                   ▼                 ▼
            ┌─────────────┐    ┌─────────────┐  ┌─────────────┐
            │  Device A   │    │  Device B   │  │  Device C   │
            │  (Mobile)   │    │  (Web)      │  │  (Desktop)  │
            └─────────────┘    └─────────────┘  └─────────────┘
```

## Key Components

### Default Service

#### 1. MessageBusiness (`apps/default/service/business/message_business.go`)
- **SendEvents()**: Entry point for sending messages
- Validates sender has room access
- Saves the event and its outbox row in a single transaction
- Emits nothing inline: the outbox relay is the sole publisher

#### 2. OutboxRelay (`apps/default/service/events/outbox_relay.go`)
- Background consumer draining `room_outbox` (one row per event)
- Emits "room.outbox.logging.event" (`events.v1.Link`), then marks the row dispatched
- Publishes the durable `chat.room.event.published` fact for rooms whose
  metadata carries `stawi.group_id`, in outbox order and at least once
- Delivery is at-least-once; downstream consumers must be idempotent

#### 3. RoomOutboxLoggingQueue (`apps/default/service/events/messages_distribution.go`)
- Event handler for "room.outbox.logging.event"
- Pages active room subscribers and emits "room.message.fanout.event"
  (`events.v1.Broadcast`) per batch, with the event payload pre-fetched once
- Re-emits itself with a cursor to continue fan-out for large rooms

#### 4. FanoutEventHandler (`apps/default/service/events/messages_fanout.go`)
- Event handler for "room.message.fanout.event"
- Builds an `events.v1.Delivery` per destination
- Publishes to the "device.event.delivery" queue

#### 5. HotPathDeliveryQueueHandler (`apps/default/service/queues/online_delivery.go`)
- Queue subscriber for "device.event.delivery"
- Queries device service for recipient's devices
- For each device:
  - Publishes to the gateway shard queue **with header filters** (profile_id, device_id)
  - Headers enable queue-level routing to specific devices
- Offline devices fall through to "offline.event.delivery"
  (`apps/default/service/queues/offline_delivery.go`); deliveries that exhaust
  their retries go to "dead.letter.queue"

### Durable room fact: `chat.room.event.published`

Rooms opt in by carrying `stawi.group_id` in their room metadata; rooms without
that key publish nothing. For a marked room the outbox relay publishes one JSON
fact per durable, non-encrypted event, in outbox order and at least once
(consumers must be idempotent on `event_id`). Encrypted payloads are never
projected, and the fact carries no role, claim, token, permission or signature:
it is a signal a consumer may render or draft from, never an authorization.

```json
{
  "event_id": "...", "room_id": "...", "group_id": "...",
  "subscription_id": "...", "profile_id": "...", "parent_id": "...",
  "room_event_type": "ROOM_EVENT_TYPE_EVENT",
  "payload_type": "PAYLOAD_TYPE_VOTE",
  "sent_at": "RFC3339", "published_at": "RFC3339",
  "vote": {"motion_id": "...", "choice_id": "..."},
  "room_change": {"action": "...", "actor_subscription_id": "...", "target_subscription_ids": ["..."]},
  "form_submission_result": {"form_instance_id": "...", "schema_id": "...", "schema_version": 1, "source_event_id": "...", "state": "..."},
  "payload": { "...": "verbatim payload in protojson form" }
}
```

Configure the stream with `QUEUE_ROOM_EVENT_PUBLISHED_NAME` /
`QUEUE_ROOM_EVENT_PUBLISHED_URI`; an empty name disables it.

### Stawi rooms

A Stawi room is a chat room whose money and governance live on chain
(spec: stawi `docs/superpowers/specs/2026-10-11-chat-stawi-rooms-design.md`).
Settlement is the one chain writer; chat relays acts and follows the chain.

**Acts are payloads** (`proto/chat/v1/payload_type.proto`):

| Payload | Sent by | Chat checks, then |
|---|---|---|
| `STAWI_ROOM_CONVERSION` (41) | the room's owner or an admin | founders are active subscriptions; calls `PrepareRoomGenesis`; stores the event with the genesis filled in (the genesis card) |
| `STAWI_GENESIS_SIGNATURE` (42) | a founder of the room's current genesis | calls `SubmitRoomGenesisSignature` with the sender's profile |
| `STAWI_SIGNED_CALL` (43) | the call's signer (settlement's record, resolved through profile) | room is bound; call is for this room and kind; calls `SubmitRoomCall` |
| `STAWI_CALL_OUTCOME` (44) | server only | ACCEPTED / FAILED(reason) after relay; OBSERVED from chain facts |

An act refused by these checks, or that cannot reach settlement, is refused to
the sender and not stored. An act settlement refuses is stored with a FAILED
outcome. Nothing about subscriptions changes on send.

**Chain facts** drive a bound room's subscriptions, roles and outcomes. Chat
subscribes to settlement's facts — finance.v1 event protos on
`svc.stawi.settlement.events` (stream `svc_stawi_facts`), headers `event_name`
and `event_id` — and applies `room.activated` (bound only when its `genesis_id` and
`chat_room_id` are the genesis chat recorded for that room),
`room.membership_observed`, `governance.call_observed`,
`governance.call_failed`, `room.call_final` and `room.call_failed` (the
relayed call's OBSERVED/FAILED outcome) and `room.genesis_failed` (FAILED on
the genesis card; the room may be converted again), idempotent by
`(chain_id, tx_hash, log_index)`, per room in `(block, log_index)` order. A
fact acts on the room bound to the contract that emitted the log. A room is
bound only if chat prepared its genesis. A reconciler repairs drift between
subscriptions/Keto and the chain's membership and emits
`room.subscription_drift`.

A member's facts apply in chain order; one that fails holds back that
member's later facts (others' are independent), is retried on a doubling
backoff and, after `MaxFactAttempts`, quarantined
(`chat.stawi.facts.quarantined`). Re-driving quarantined facts is an internal
method (`StawiChain.Redrive`) with no RPC or HTTP route; an operator runs it
from inside the service. Refused activations are acknowledged and kept with
the dead letters (`chat.stawi.activations.refused`).

For a bound room `AddRoomSubscriptions`, `RemoveRoomSubscriptions`,
`UpdateSubscriptionRole`, `DeleteRoom`, chat-native proposals and
MOTION/VOTE payloads are refused (FailedPrecondition).

**Service cards.** Finance's service identity posts `FINANCE_CARD` (as an
EVENT) and `TEXT` (as a MESSAGE) into a bound Stawi room of its own
tenant/partition without being a member, through `SendEvent`. It must be an
internal-system principal holding `stawi_card_post` on `service_chat`. Grant
it to finance's service profile only:

```
# Keto tuple (functional plane, per tenancy)
service_chat:<tenant_id>/<partition_id>#granted_stawi_card_post@profile_user:<finance-service-profile-id>
```

`stawi_card_post` is also bound to `ROLE_SERVICE`, so a service account
holding the `service` relation on `service_chat` for that tenancy has it; no
human role grants it.

**Configuration**

| Variable | Default | Notes |
|---|---|---|
| `SETTLEMENT_SERVICE_URI` | empty | settlement's RoomService (`settlement.v1`, buf.build/stawi/finance); required in staging/production |
| `SETTLEMENT_SERVICE_WORKLOAD_API_TARGET_PATH` | `/ns/stawi/sa/service-settlement` | |
| `PROFILE_SERVICE_URI` | `127.0.0.1:7003` | resolves chain addresses (needs `account_resolve`, ROLE_SERVICE) |
| `QUEUE_STAWI_FACTS_NAME` / `_URI` | `stawi.settlement.facts` / `mem://…` | durable subscription required in staging/production, e.g. `nats://…?jetstream=true&stream_name=svc_stawi_facts&consumer_durable_name=svc_chat_stawi_facts&consumer_filter_subject=svc.stawi.settlement.events&consumer_ack_policy=explicit&consumer_deliver_policy=all&consumer_max_deliver=5` |
| `QUEUE_STAWI_DRIFT_NAME` / `_URI` | `chat.room.subscription_drift` / `mem://…` | durable in staging/production; empty name disables |
| `STAWI_RECONCILE_INTERVAL_SECONDS` | `300` | |

Only settlement's NATS credentials may publish on
`svc.stawi.settlement.events`.

### Gateway Service

#### 1. GatewayServer.Connect() (`apps/gateway/service/handlers/gateway.go`)
- **Each device connection creates its own queue subscription**
- Sets header filters: `profile_id={user}` and `device_id={device}`
- **Pull-based model**: Connection actively pulls from queue
- Two goroutines:
  1. **Queue → Device**: Pulls messages from filtered subscription, converts to ServerEvent, sends to device
  2. **Device → Gateway**: Receives heartbeats, acks, and other device requests

#### 2. ConnectionManager (`apps/gateway/service/business/connection.go`)
- **Register()**: Registers connection metadata in Redis cache
- Enables cross-gateway coordination
- Tracks active connections for monitoring

### Queue Architecture

```
┌──────────────────────────────────────────────────────┐
│          gateway.event.delivery.N Queues              │
│                                                        │
│  Messages published with headers:                     │
│    - profile_id: user123                              │
│    - device_id: device456                             │
│                                                        │
│  Subscribers filter by headers:                       │
│    Gateway1: profile_id=user123 AND device_id=device1 │
│    Gateway2: profile_id=user123 AND device_id=device2 │
│    Gateway3: profile_id=user456 AND device_id=device3 │
│                                                        │
│  ✓ Each device stream only receives its own messages │
│  ✓ Multiple gateways can handle different devices    │
│  ✓ Horizontal scaling without coordination overhead  │
└──────────────────────────────────────────────────────┘
```

## Scalability Features

### 1. **Pull-Based Subscriptions**
- Each device stream creates its own filtered queue subscription
- No need to push to connections - they pull their own messages
- Streams naturally backpressure based on their consumption rate

### 2. **Header-Based Routing**
- Queue infrastructure routes messages using headers
- profile_id + device_id ensures messages reach correct device
- No application-level routing logic needed

### 3. **Horizontal Scaling**
- Gateway instances don't need to coordinate
- Each handles its own set of device connections
- Redis cache tracks connection metadata for monitoring
- New gateway instances can be added without coordination

### 4. **Asynchronous Processing**
- Message sending returns immediately after database write
- Outbox processing happens asynchronously via events
- Queue delivery decoupled from message sending

### 5. **Backpressure Handling**
- Slow devices only affect their own stream
- Queue buffers messages per device
- Fast devices aren't slowed by slow ones

## Message Proto Definitions

### Delivery (`proto/events/v1/events.proto`)
```protobuf
message Delivery {
  Link event = 1;                // The chat event
  Subscription destination = 2;  // Recipient info
  Subscription source = 3;
  chat.v1.Payload payload = 5;   // Message content
  bool is_compressed = 10;
  int32 retry_count = 11;
  string device_id = 12;
}
```

### Broadcast
```protobuf
message Broadcast {
  Link event = 1;                        // The chat event
  repeated Subscription destinations = 2;  // Recipients in this batch
  Priority priority = 3;
  chat.v1.Payload payload = 4;           // Pre-fetched payload
}
```

## Configuration

### Default Service (`apps/default/config/config.go`)
```go
QueueDeviceEventDeliveryName  string   `envDefault:"device.event.delivery"`
QueueDeviceEventDeliveryURI   string   `envDefault:"mem://device.event.delivery"`
QueueGatewayEventDeliveryName string   `envDefault:"gateway.event.delivery.%d"`
QueueGatewayEventDeliveryURI  []string `envDefault:"mem://gateway.event.delivery.0"`
QueueRoomEventPublishedName   string   `envDefault:"chat.room.event.published"`
QueueRoomEventPublishedURI    string   `envDefault:"mem://chat.room.event.published"`
```

### Gateway Service (`apps/gateway/config/config.go`)
```go
QueueGatewayEventDeliveryName string   `envDefault:"gateway.event.delivery.%d"`
QueueGatewayEventDeliveryURI  []string `envDefault:"mem://gateway.event.delivery.0"`
CacheURI  string `envDefault:"redis://localhost:6379"`
```

## Future Enhancements

1. **Device Online Detection**: Query gateway cache to check if device is connected before publishing
2. **Push Notifications**: Integrate notification service for offline devices
3. **Message Acknowledgments**: Track delivery and read receipts
4. **Priority Queues**: Support high-priority messages (e.g., @mentions)
5. **Message Compression**: Compress large message payloads
6. **Retry Logic**: Automatic retry for failed deliveries
7. **Dead Letter Queue**: Handle permanently failed messages
8. **Metrics & Monitoring**: Track queue depths, delivery latency, connection counts

## Testing

### Local Development
Both services can use in-memory queues (`mem://`) for development:
```bash
# Default service
QUEUE_DEVICE_EVENT_DELIVERY_URI=mem://device.event.delivery

# Gateway service
QUEUE_GATEWAY_EVENT_DELIVERY_URI=mem://gateway.event.delivery.0
```

### Production
Use a distributed queue system (Redis, RabbitMQ, Kafka, etc.):
```bash
# Both services point to same queue infrastructure
QUEUE_GATEWAY_EVENT_DELIVERY_URI=redis://redis:6379/gateway.event.delivery.0
```

## Summary

This architecture achieves:
- ✅ **Real-time delivery** via bidirectional streams
- ✅ **Horizontal scalability** through pull-based subscriptions  
- ✅ **Device isolation** via header-filtered queues
- ✅ **Backpressure handling** per device
- ✅ **Decoupled services** via queue infrastructure
- ✅ **Reliable delivery** with database-backed outbox pattern
- ✅ **Multi-device support** for each user
- ✅ **Gateway independence** - no cross-gateway coordination needed

## Development Setup

### Git Hooks

This repository includes a pre-commit hook that automatically runs `make format` before each commit to ensure consistent code formatting.

**Enable the hook:**
```bash
git config core.hooksPath .githooks
```

**What it does:**
- Detects staged `.go` files
- Runs `make format` to apply gofmt/goimports
- If formatting changes any files, the commit is blocked
- You must review and stage the formatted files before committing again

**To disable temporarily:**
```bash
git commit --no-verify
```
