# Flutter Chat Application Architecture Blueprint

## 1. Executive Summary
This document defines the architecture for a production-grade, offline-first, end-to-end encrypted (E2EE) chat application built with Flutter. The system is designed to be modular, scalable, and compliant with the Ant Investor Chat API (`chat.v1`). It targets Android, iOS, Web, and Desktop platforms with a responsive design.

## 2. Technology Stack

### Core Framework
*   **Flutter**: Latest stable channel (Material 3).
*   **Dart**: Latest stable SDK.

### Key Dependencies
*   **Networking**: `connectrpc` (Connect RPC client), `http` (for OIDC).
*   **Database**: Drift + SQLite (`drift`, `sqlite3_flutter_libs`) as the production ORM for reactive queries and migrations.
*   **Encryption**: `vodozemac` (v0.4.1) for Olm/Megolm implementation.
*   **Authentication**: `openid_client` for OIDC/PKCE.
*   **State Management**: `flutter_riverpod` (v2.x) with `riverpod_annotation`.
*   **Notifications**: `firebase_messaging`.
*   **Background Processing**: `workmanager` or custom isolates for sync.
*   **DI/Service Locator**: `riverpod` providers serve as the DI system.

## 3. High-Level Architecture

The application follows a **Clean Architecture** approach, separated into three main layers:
1.  **Data Layer**: Repositories, Data Sources (API, DB), DTOs.
2.  **Domain Layer**: Entities, Use Cases (Interactors), Repository Interfaces.
3.  **Presentation Layer**: UI (Widgets, Screens), State Holders (Notifiers/Controllers).

### Data Flow
`UI` -> `Controller (Riverpod)` -> `Use Case` -> `Repository` -> `Data Source (Local/Remote)`

## 4. Folder Structure

```
lib/
├── app/
│   ├── config.dart          # Environment config (API URLs, OIDC clients)
│   ├── router.dart          # GoRouter configuration
│   ├── theme.dart           # Material 3 theme definitions
│   └── constants.dart       # App-wide constants
├── core/
│   ├── crypto/              # E2EE logic (Vodozemac wrappers)
│   │   ├── key_manager.dart # Identity/Prekey management
│   │   ├── session_manager.dart # Double Ratchet session handling
│   │   └── protocol.dart    # Encryption/Decryption helpers
│   ├── db/                  # Raw SQLite implementation
│   │   ├── database.dart    # Database connection & migration logic
│   │   ├── schema.dart      # Table definitions (SQL)
│   │   └── transactions.dart# Transaction helpers
│   ├── networking/          # Connect RPC setup
│   │   ├── client.dart      # ConnectClient configuration
│   │   ├── interceptors.dart# Auth & Logging interceptors
│   │   └── connectivity.dart# Network status monitoring
│   ├── sync/                # Synchronization Engine
│   │   ├── sync_engine.dart # Main sync loop
│   │   ├── queue.dart       # Operation queue
│   │   └── conflict.dart    # Conflict resolution logic
│   └── utils/               # Helpers (Date, String, Logger)
├── features/
│   ├── auth/                # Authentication Module
│   │   ├── data/            # OIDC implementation
│   │   ├── domain/          # Auth state & user entities
│   │   └── ui/              # Login screens
│   ├── contacts/            # Contact Discovery
│   │   ├── data/            # Phone book access & hashing
│   │   └── ui/              # Contact list & invite
│   ├── messages/            # Messaging Core
│   │   ├── data/            # Message repository & DB ops
│   │   ├── domain/          # Message entities & sending logic
│   │   └── ui/              # Chat screen, bubbles, input
│   ├── notifications/       # FCM Handling
│   │   └── handler.dart     # Background message handler
│   ├── rooms/               # Room Management
│   │   ├── data/            # Room repository
│   │   └── ui/              # Room list, creation, settings
│   └── transactions/        # Financial Features
│       ├── data/            # Transaction repository
│       └── ui/              # Transaction bubbles, history
└── ui/
    ├── layout/              # Responsive scaffolds (SplitView, etc.)
    ├── screens/             # Top-level screens (Home, Settings)
    └── widgets/             # Shared UI components (Avatar, Buttons)
```

## 5. Database Schema (SQLite)

The app uses `sqlite3` directly. All tables use `TEXT` for IDs (UUIDs).

### Tables

#### `profiles`
| Column | Type | Description |
|---|---|---|
| `id` | TEXT PRIMARY KEY | Profile ID |
| `name` | TEXT | Display Name |
| `avatar_url` | TEXT | |
| `updated_at` | INTEGER | Timestamp |
| `metadata` | TEXT | JSON blob |

#### `contacts`
| Column | Type | Description |
|---|---|---|
| `id` | TEXT PRIMARY KEY | Contact ID (UUID) |
| `profile_id` | TEXT | FK -> profiles.id |
| `display_name` | TEXT | Local display name override |
| `phone_hash` | TEXT | Hashed phone number for discovery |
| `is_blocked` | INTEGER | 0 or 1 |
| `created_at` | INTEGER | |

#### `rooms`
| Column | Type | Description |
|---|---|---|
| `id` | TEXT PRIMARY KEY | Room ID |
| `name` | TEXT | Room Name |
| `type` | TEXT | 'direct', 'group' |
| `last_event_id` | TEXT | ID of last applied event |
| `last_event_index` | INTEGER | Sequence number for ordering |
| `unread_count` | INTEGER | |
| `metadata` | TEXT | JSON blob |

#### `room_members`
| Column | Type | Description |
|---|---|---|
| `room_id` | TEXT | FK -> rooms.id |
| `profile_id` | TEXT | FK -> profiles.id |
| `role` | TEXT | 'admin', 'member' |
| `joined_at` | INTEGER | |
| PRIMARY KEY | (room_id, profile_id) | |

#### `room_events` (Stores ALL RoomEvents)
| Column | Type | Description |
|---|---|---|
| `id` | TEXT PRIMARY KEY | Event ID (Server or Local UUID) |
| `room_id` | TEXT | FK -> rooms.id |
| `sender_id` | TEXT | FK -> profiles.id |
| `type` | INTEGER | Maps to `RoomEventType` (Text, Image, Reaction, Call, Motion) |
| `content` | TEXT | Decrypted JSON payload |
| `parent_id` | TEXT | ID of the event being replied to, reacted to, or voted on |
| `status` | INTEGER | 0=Pending, 1=Sent, 2=Delivered, 3=Read, 4=Failed |
| `created_at` | INTEGER | Local timestamp |
| `server_ts` | INTEGER | Server timestamp |
| `local_id` | TEXT | Temporary ID for pending events |

#### `sessions` (E2EE)
| Column | Type | Description |
|---|---|---|
| `session_id` | TEXT PRIMARY KEY | Unique Session ID |
| `profile_id` | TEXT | Profile ID of the peer |
| `device_id` | TEXT | Device ID of the peer |
| `ratchet_state` | BLOB | Serialized Vodozemac session state |
| `created_at` | INTEGER | |

#### `prekeys` (E2EE)
| Column | Type | Description |
|---|---|---|
| `id` | INTEGER PRIMARY KEY | Prekey ID |
| `public_key` | TEXT | Base64 encoded public key |
| `private_key` | TEXT | Encrypted private key |
| `is_signed` | INTEGER | 1 if signed prekey |

#### `pending_jobs` (Sync)
| Column | Type | Description |
|---|---|---|
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | |
| `type` | TEXT | 'send_message', 'update_room', 'vote' |
| `payload` | TEXT | JSON payload |
| `created_at` | INTEGER | |
| `retry_count` | INTEGER | |
| `status` | TEXT | 'pending', 'processing', 'failed' |

#### `motions` (Optional - or just query messages)
*Can be derived from `messages` table where `type=MOTION`, but a separate table for quick aggregation is useful.*
| Column | Type | Description |
|---|---|---|
| `id` | TEXT PRIMARY KEY | Motion ID (linked to message_id) |
| `room_id` | TEXT | FK |
| `title` | TEXT | |
| `options` | TEXT | JSON array of options |
| `status` | TEXT | 'open', 'closed' |
| `results` | TEXT | JSON aggregated results |

#### `transactions`
| Column | Type | Description |
|---|---|---|
| `id` | TEXT PRIMARY KEY | Transaction ID |
| `room_id` | TEXT | FK |
| `amount` | TEXT | Decimal string |
| `currency` | TEXT | ISO code |
| `status` | TEXT | 'pending', 'completed', 'failed' |
| `initiator_id` | TEXT | |

## 6. Authentication Module

### Flow
1.  **Discovery**: App fetches OIDC configuration from provider.
2.  **Login**: Uses `openid_client` to launch system browser for PKCE flow.
3.  **Token Exchange**: Code exchanged for Access Token + Refresh Token.
4.  **Storage**: Tokens stored in `FlutterSecureStorage`.
5.  **Refresh**: Interceptor checks token expiry. If expired, uses Refresh Token to get new Access Token. If Refresh fails, logout user.

## 7. Encryption Module (Vodozemac)

### Setup
1.  **Install**: Generate Identity Key Pair (IKP) and Signed Prekey (SPK) on first launch.
2.  **Upload**: Publish IKP public key + SPK + batch of One-Time Prekeys (OTPK) to server (via `UpdateClientState` or dedicated Key API).

### Session Management
*   **Session Creation**: When sending to a new peer, fetch their bundle. Use `vodozemac` to build a session.
*   **Double Ratchet**: Used for all message encryption.
*   **Persistence**: Session state serialized and stored in `sessions` table after every ratchet step.

### Message Envelope
```json
{
  "ciphertext": "<base64>",
  "session_id": "<uuid>",
  "type": 1, // 1=PreKey, 2=Message
  "iv": "<base64>"
}
```
This payload is embedded in the `RoomEvent.payload` with `type=ROOM_EVENT_TYPE_ENCRYPTED`.

## 8. Synchronization Engine

The engine ensures eventual consistency between local DB and server.

### Components
1.  **Upload Loop**: Watches `pending_jobs`. Picks oldest 'pending' job. Executes RPC. On success, delete job + update local entity status. On failure, increment retry + backoff.
2.  **Download Loop**: Connects to `GatewayService.Connect`. Streams `ConnectResponse`.
    *   **RoomEvent**: Decrypt (if needed), Insert to `room_events`, Update `rooms.last_event_index`.
    *   **ReceiptEvent**: Update `room_events.status`.
3.  **Gap Detection**: If `ConnectResponse` sequence > `local_last_index + 1`, trigger `GetHistory` to fill gap.

## 9. Feature Specifications

### 9.1 Notification Handling (FCM)

The app handles FCM messages based on the app state (Foreground, Background, Terminated).

#### Payload Structure
```json
{
  "type": "NEW_EVENT",
  "room_id": "uuid",
  "event_id": "uuid",
  "sender_id": "uuid",
  "click_action": "FLUTTER_NOTIFICATION_CLICK"
}
```

#### State Mapping
1.  **Foreground**:
    *   **Action**: Ignore FCM data payload for UI updates (rely on `Connect` stream).
    *   **UI**: Do NOT show system notification. Optionally show in-app toast if not in that room.
2.  **Background / Terminated**:
    *   **Action**: `FirebaseMessaging.onBackgroundMessage` triggers.
    *   **Logic**:
        1.  Check `type`.
        2.  If `NEW_EVENT`:
            *   Insert "Fetch Job" to `pending_jobs` (high priority).
            *   Wake up Sync Engine (via `workmanager` or isolate).
            *   Sync Engine calls `GetHistory` or `GetEvent`.
            *   Decrypt content.
            *   **Show Local Notification**: "New message from Alice".
3.  **Tap Action**:
    *   Opens app -> `Router` parses payload -> Navigates to `ChatScreen(roomId)`.

### 9.2 Messaging Pipeline
1.  **Compose**: User types -> `SendMessageUseCase`.
2.  **Local Save**: Create `RoomEvent` with `status=pending`, `local_id`. Insert to DB. UI updates immediately (Optimistic UI).
3.  **Job Creation**: Add `send_message` job to `pending_jobs`.
4.  **Process**: Sync Engine picks job.
    *   **Encrypt**: For each recipient device in room, encrypt content.
    *   **RPC**: Call `ChatService.SendEvent`.
    *   **Success**: Update `RoomEvent` with server `id`, set `status=sent`.

### 9.3 Motions (Voting)
**Unified Event Model**: Motions and Votes are standard `RoomEvent`s.
1.  **Create Motion**: User creates a motion.
    *   Event Type: `ROOM_EVENT_TYPE_EVENT` (or custom `MOTION`).
    *   Payload: `{"title": "Lunch?", "options": ["Yes", "No"]}`.
    *   Stored in `room_events` table.
2.  **Vote**: User votes.
    *   Event Type: `ROOM_EVENT_TYPE_REACTION` (or custom `VOTE`).
    *   `parent_id`: ID of the Motion event.
    *   Payload: `{"option": "Yes"}`.
3.  **Aggregation**:
    *   UI watches `room_events` table for all events where `parent_id == motion_id`.
    *   Aggregates counts locally to display results.
4.  **Close**: Creator sends an update event or a specific "Close" event referencing the motion.

### 9.4 Reactions & Replies
*   **Replies**: Standard Text/Image event with `parent_id` set to the original event ID. UI renders this as a "Reply" bubble.
*   **Reactions**: Event Type `ROOM_EVENT_TYPE_REACTION`. `parent_id` = target event. Payload = `{"emoji": "👍"}`.
    *   UI aggregates reactions by querying `room_events` where `parent_id` matches.

### 9.5 Call Signaling
Voice/Video calls use `RoomEvent`s for signaling (WebRTC).
*   **Offer**: `ROOM_EVENT_TYPE_CALL_OFFER`. Payload: SDP.
*   **Answer**: `ROOM_EVENT_TYPE_CALL_ANSWER`. Payload: SDP. `parent_id` = Offer ID.
*   **ICE Candidate**: `ROOM_EVENT_TYPE_CALL_ICE`. Payload: Candidate data. `parent_id` = Offer ID.
*   **End**: `ROOM_EVENT_TYPE_CALL_END`.
*   **UI**: These events trigger the Call Overlay/Screen but are also stored in history (e.g., "Call started", "Call ended 5m 23s").

### 9.6 Financial Transactions
1.  **Request**: User A sends "Payment Request" (Event).
2.  **View**: User B sees "Pay 100 USD". Taps "Pay".
3.  **Process**: App initiates transaction via Financial API (separate from Chat API, but linked).
4.  **Confirm**: System sends "Transaction Completed" event to room. Bubble updates to "Paid".

## 10. UI/UX Strategy

### Responsive Layout
*   **Mobile**: Bottom Navigation (Chats, Contacts, Settings). Chat screen pushes on stack.
*   **Tablet/Desktop**: `Row` layout.
    *   Left: Navigation Rail.
    *   Middle: Room List (300px).
    *   Right: Chat View (Expanded).
    *   Far Right: Room Details (Optional, collapsible).

### State Management (Riverpod)
*   **Repositories**: Return `Future` or `Stream`.
*   **Notifiers**: `AsyncNotifier` for async data (RoomList, MessageList).
*   **Optimization**: `select` used to listen to specific parts of state.

### Components
*   **MessageBubble**: Handles text, image, motion, transaction variants. Swipe-to-reply.
*   **RoomTile**: Shows avatar, name, last message, unread badge, typing indicator.

## 11. Connect RPC Integration

**NO gRPC Codegen**. Use `connectrpc` package.

```dart
// Example Client Setup
final client = ConnectClient(
  baseUrl: 'https://api.antinvestor.com',
  httpClient: createHttpClient(), // With interceptors
);

// Service Definition (Manual or via protoc-gen-connect-dart if allowed, else manual wrapper)
// Since "No grpc codegen" is specified, we assume we use the connect-dart generator 
// OR manually construct requests if strictly no codegen is allowed (which is rare for Connect).
// Assuming standard Connect usage:
final chatService = ChatServiceClient(client);
```

## 12. Security Considerations
*   **Database**: Encrypt `sqlite` file using SQLCipher (optional but recommended) or at least encrypt sensitive columns (keys) using `flutter_secure_storage` key wrapping.
*   **Network**: TLS 1.3 enforced. Certificate pinning recommended.
*   **Memory**: Clear sensitive keys from memory when not in use (hard in Dart, but best effort).


* Device & device key management utilizes the devices api at : https://github.com/antinvestor/apis/blob/main/proto/device/device/v1/device.proto
