# Product Requirements Document
# Chat Application - Complete Feature Build-Out

**Version:** 1.0
**Date:** January 2026
**Status:** Ready for Development
**Target Team Size:** 100 Engineers
**Target Timeline:** 8 Weeks to Production

---

## Table of Contents

1. [Executive Overview](#1-executive-overview)
2. [System Architecture](#2-system-architecture)
3. [API Reference](#3-api-reference)
4. [Work Stream Organization](#4-work-stream-organization)
5. [Phase 1: Core Messaging Completion](#5-phase-1-core-messaging-completion)
6. [Phase 2: Security & Privacy](#6-phase-2-security--privacy)
7. [Phase 3: Notifications & Real-Time](#7-phase-3-notifications--real-time)
8. [Phase 4: Media & Attachments](#8-phase-4-media--attachments)
9. [Phase 5: Group Features](#9-phase-5-group-features)
10. [Phase 6: Contacts & Identity](#10-phase-6-contacts--identity)
11. [Phase 7: Search & Discovery](#11-phase-7-search--discovery)
12. [Phase 8: Calls & Real-Time Communication](#12-phase-8-calls--real-time-communication)
13. [Phase 9: Settings & Preferences](#13-phase-9-settings--preferences)
14. [Phase 10: Performance & Optimization](#14-phase-10-performance--optimization)
15. [Phase 11: Testing & Quality](#15-phase-11-testing--quality)
16. [Phase 12: DevOps & Observability](#16-phase-12-devops--observability)
17. [Dependency Graph](#17-dependency-graph)
18. [Definition of Done](#18-definition-of-done)

---

## 1. Executive Overview

### 1.1 Product Vision

Build a production-ready, WhatsApp-class messaging application that enables secure real-time communication with integrated financial features (credit & savings automation for groups/chamas).

### 1.2 Current State

| Metric | Value |
|--------|-------|
| Feature Completion | 53% |
| Partial Features | 20% |
| Missing Features | 27% |
| Test Coverage | <5% |
| Production Readiness | MVP |

### 1.3 Target State

| Metric | Target |
|--------|--------|
| Feature Completion | 95% |
| Test Coverage | 80% |
| Production Readiness | Production |
| WhatsApp Parity | 90% |

### 1.4 Team Organization

| Work Stream | Engineers | Lead Focus |
|-------------|-----------|------------|
| WS1: Core Messaging | 15 | Message lifecycle, delivery states |
| WS2: Security | 12 | E2EE, authentication, privacy |
| WS3: Notifications | 8 | Push, in-app, badges |
| WS4: Media | 12 | Upload, download, processing |
| WS5: Groups | 10 | Group management, permissions |
| WS6: Contacts | 8 | Roster, discovery, blocking |
| WS7: Search | 8 | Full-text, filters, indexing |
| WS8: Calls | 10 | WebRTC, group calls, screen share |
| WS9: Settings | 5 | Preferences, storage, account |
| WS10: Performance | 6 | Optimization, caching, memory |
| WS11: Testing | 4 | Unit, integration, E2E |
| WS12: DevOps | 2 | CI/CD, monitoring, logging |

---

## 2. System Architecture

### 2.1 Client Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER APPLICATION                       │
├─────────────────────────────────────────────────────────────┤
│  PRESENTATION LAYER                                          │
│  ├── Screens (UI)                                           │
│  ├── Widgets (Reusable Components)                          │
│  └── State Management (Riverpod 3.0)                        │
├─────────────────────────────────────────────────────────────┤
│  FEATURE LAYER                                               │
│  ├── Auth        ├── Messages    ├── Rooms                  │
│  ├── Contacts    ├── Calls       ├── Notifications          │
│  ├── Settings    ├── Search      ├── Advanced (Motions)     │
├─────────────────────────────────────────────────────────────┤
│  CORE LAYER                                                  │
│  ├── Database (Drift/SQLite)                                │
│  ├── Networking (Connect RPC)                               │
│  ├── Sync Engine (Real-time)                                │
│  ├── Crypto (Vodozemac E2EE)                                │
│  ├── Storage (Secure + Local)                               │
│  └── Cache (LRU Media Cache)                                │
├─────────────────────────────────────────────────────────────┤
│  INFRASTRUCTURE LAYER                                        │
│  ├── API Clients (Chat, Profile, Files, Device, Notification)│
│  ├── Token Manager (JWT + Refresh)                          │
│  └── Platform Adapters (iOS, Android, Web, Desktop)         │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Backend Services (Antinvestor APIs)

| Service | Endpoint | Purpose |
|---------|----------|---------|
| Gateway | `gateway.antinvestor.com` | Real-time WebSocket streaming |
| Chat | `chat.antinvestor.com` | Message operations, rooms |
| Profile | `profile.antinvestor.com` | User management, roster |
| Files | `files.antinvestor.com` | Media upload/download |
| Device | `device.antinvestor.com` | Device registration, FCM |
| Notification | `notification.antinvestor.com` | Push delivery |

### 2.3 Data Flow

```
User Action → UI Widget → Provider → Service → Repository →
    ↓
Database (Local) → PendingJob Queue → SyncEngine →
    ↓
API Client → Backend Service → Response →
    ↓
Repository → Provider → UI Update
```

---

## 3. API Reference

### 3.1 Chat API Methods

| Method | Request | Response | Use Case |
|--------|---------|----------|----------|
| `sendEvent` | `SendEventRequest` | `SendEventResponse` | Send messages |
| `getHistory` | `GetHistoryRequest` | `GetHistoryResponse` | Fetch messages |
| `createRoom` | `CreateRoomRequest` | `CreateRoomResponse` | Create room |
| `updateRoom` | `UpdateRoomRequest` | `UpdateRoomResponse` | Edit room info |
| `deleteRoom` | `DeleteRoomRequest` | `DeleteRoomResponse` | Delete room |
| `searchRooms` | `SearchRoomsRequest` | `Stream<SearchRoomsResponse>` | Find rooms |
| `addRoomSubscriptions` | `AddRoomSubscriptionsRequest` | `AddRoomSubscriptionsResponse` | Add members |
| `removeRoomSubscriptions` | `RemoveRoomSubscriptionsRequest` | `RemoveRoomSubscriptionsResponse` | Remove members |
| `updateSubscriptionRole` | `UpdateSubscriptionRoleRequest` | `UpdateSubscriptionRoleResponse` | Change role |
| `searchRoomSubscriptions` | `SearchRoomSubscriptionsRequest` | `SearchRoomSubscriptionsResponse` | List members |
| `live` | `LiveRequest` | `LiveResponse` | Presence update |

### 3.2 Gateway API (Real-Time)

| Method | Type | Use Case |
|--------|------|----------|
| `stream` | Bidirectional | Real-time messaging |

**Stream Events:**
- `RoomEvent` - Messages, reactions, system events
- `PresenceEvent` - Online/offline status
- `ReceiptEvent` - Delivery confirmations
- `ReadMarker` - Read receipts
- `TypingEvent` - Typing indicators

### 3.3 Profile API Methods

| Method | Request | Response | Use Case |
|--------|---------|----------|----------|
| `getById` | `GetByIdRequest` | `GetByIdResponse` | Get profile |
| `getByContact` | `GetByContactRequest` | `GetByContactResponse` | Find by email/phone |
| `search` | `SearchRequest` | `Stream<SearchResponse>` | Search profiles |
| `create` | `CreateRequest` | `CreateResponse` | Create profile |
| `update` | `UpdateRequest` | `UpdateResponse` | Update profile |
| `addContact` | `AddContactRequest` | `AddContactResponse` | Add contact method |
| `createContactVerification` | `CreateContactVerificationRequest` | `CreateContactVerificationResponse` | Start verification |
| `checkVerification` | `CheckVerificationRequest` | `CheckVerificationResponse` | Verify code |
| `searchRoster` | `SearchRosterRequest` | `Stream<SearchRosterResponse>` | Search contacts |
| `addRoster` | `AddRosterRequest` | `AddRosterResponse` | Add to roster |
| `removeRoster` | `RemoveRosterRequest` | `RemoveRosterResponse` | Remove contact |

### 3.4 Files API Methods

| Method | Request | Response | Use Case |
|--------|---------|----------|----------|
| `uploadContent` | `Stream<UploadContentRequest>` | `UploadContentResponse` | Upload file |
| `createContent` | `CreateContentRequest` | `CreateContentResponse` | Reserve MXC URI |
| `getContent` | `GetContentRequest` | `GetContentResponse` | Download file |
| `getContentThumbnail` | `GetContentThumbnailRequest` | `GetContentThumbnailResponse` | Get thumbnail |
| `getUrlPreview` | `GetUrlPreviewRequest` | `GetUrlPreviewResponse` | Link preview |
| `getConfig` | `GetConfigRequest` | `GetConfigResponse` | Upload limits |
| `searchMedia` | `SearchMediaRequest` | `SearchMediaResponse` | Find media |

### 3.5 Device API Methods

| Method | Request | Response | Use Case |
|--------|---------|----------|----------|
| `create` | `CreateRequest` | `CreateResponse` | Register device |
| `update` | `UpdateRequest` | `UpdateResponse` | Update device |
| `link` | `LinkRequest` | `LinkResponse` | Link to user |
| `registerKey` | `RegisterKeyRequest` | `RegisterKeyResponse` | Register FCM token |
| `deRegisterKey` | `DeRegisterKeyRequest` | `DeRegisterKeyResponse` | Remove FCM token |
| `notify` | `NotifyRequest` | `NotifyResponse` | Send push |
| `updatePresence` | `UpdatePresenceRequest` | `UpdatePresenceResponse` | Set status |
| `addKey` | `AddKeyRequest` | `AddKeyResponse` | Store E2EE key |
| `searchKey` | `SearchKeyRequest` | `SearchKeyResponse` | Find keys |

### 3.6 Notification API Methods

| Method | Request | Response | Use Case |
|--------|---------|----------|----------|
| `send` | `SendRequest` | `Stream<SendResponse>` | Queue notification |
| `release` | `ReleaseRequest` | `Stream<ReleaseResponse>` | Trigger delivery |
| `receive` | `ReceiveRequest` | `Stream<ReceiveResponse>` | Acknowledge receipt |
| `search` | `SearchRequest` | `Stream<SearchResponse>` | Find notifications |
| `status` | `StatusRequest` | `StatusResponse` | Check status |

---

## 4. Work Stream Organization

### 4.1 Parallel Execution Strategy

All work streams can execute in parallel with defined integration points:

```
Week 1-2: Foundation (All streams start)
    ├── WS1: Message editing/deletion
    ├── WS2: E2EE enablement
    ├── WS3: Push notification setup
    ├── WS4: Media compression
    ├── WS5: Group permissions
    ├── WS6: Contact blocking UI
    ├── WS7: Search indexing
    ├── WS8: TURN server setup
    ├── WS9: Settings persistence
    ├── WS10: Cache implementation
    ├── WS11: Test infrastructure
    └── WS12: CI/CD pipeline

Week 3-4: Core Features
    ├── WS1: Read receipts UI
    ├── WS2: Certificate pinning
    ├── WS3: Rich notifications
    ├── WS4: Thumbnail generation
    ├── WS5: Admin controls
    ├── WS6: Contact sync
    ├── WS7: Message search
    ├── WS8: 1:1 call stability
    ├── WS9: Theme system
    ├── WS10: Memory optimization
    ├── WS11: Unit tests (70%)
    └── WS12: Error tracking

Week 5-6: Advanced Features
    ├── WS1: Message forwarding
    ├── WS2: Biometric lock
    ├── WS3: Notification grouping
    ├── WS4: Background upload
    ├── WS5: Group invites
    ├── WS6: User status
    ├── WS7: Chat search
    ├── WS8: Group calls
    ├── WS9: Storage management
    ├── WS10: Network optimization
    ├── WS11: Integration tests
    └── WS12: Analytics

Week 7-8: Polish & Launch
    ├── All streams: Bug fixes
    ├── All streams: Performance tuning
    ├── WS11: E2E tests
    └── WS12: Production deployment
```

---

## 5. Phase 1: Core Messaging Completion

### Feature 1.1: Message Editing

**ID:** MSG-EDIT-001
**Priority:** P0
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Allow users to edit sent messages within a configurable time window (default: 15 minutes).

#### API Integration
```dart
// Use existing sendEvent with edit flag
final request = pb.SendEventRequest(
  event: [
    pb.RoomEvent(
      id: existingEventId,  // Original message ID
      roomId: roomId,
      type: pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE,
      edited: true,  // Mark as edit
      payload: pb.Payload(
        text: pb.TextContent(body: newText),
      ),
    ),
  ],
);
await chatClient.sendEvent(request);
```

#### Database Changes
```sql
-- Add to RoomEvents table
ALTER TABLE room_events ADD COLUMN edited_at INTEGER;
ALTER TABLE room_events ADD COLUMN original_content TEXT;
```

#### Acceptance Criteria
- [ ] User can long-press own message to reveal edit option
- [ ] Edit option only available within 15-minute window
- [ ] Edit option only available for text messages
- [ ] Edited messages show "(edited)" indicator
- [ ] Original content preserved in database
- [ ] Edit propagates to all recipients in real-time
- [ ] Offline edits queue and sync when online
- [ ] Edit history viewable by tapping "(edited)"

#### UI Components
| Component | File | Changes |
|-----------|------|---------|
| MessageBubble | `message_bubble.dart` | Add edit indicator, long-press menu |
| EditMessageSheet | `edit_message_sheet.dart` | New file - edit input UI |
| MessageRepository | `message_repository.dart` | Add updateMessage method |

#### Test Cases
```dart
testWidgets('can edit own message within time window', ...);
testWidgets('cannot edit message after 15 minutes', ...);
testWidgets('edit indicator displays correctly', ...);
testWidgets('edit syncs to recipients', ...);
test('offline edit queues correctly', ...);
```

---

### Feature 1.2: Message Deletion (Remote)

**ID:** MSG-DEL-001
**Priority:** P0
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Allow users to delete messages for everyone or just themselves.

#### API Integration
```dart
// Delete for everyone (redact)
final request = pb.SendEventRequest(
  event: [
    pb.RoomEvent(
      id: targetEventId,
      roomId: roomId,
      type: pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE,
      redacted: true,  // Mark as deleted
    ),
  ],
);
await chatClient.sendEvent(request);
```

#### Database Changes
```sql
ALTER TABLE room_events ADD COLUMN redacted INTEGER DEFAULT 0;
ALTER TABLE room_events ADD COLUMN redacted_at INTEGER;
ALTER TABLE room_events ADD COLUMN redacted_by TEXT;
```

#### Acceptance Criteria
- [ ] Long-press reveals delete options: "Delete for me" / "Delete for everyone"
- [ ] "Delete for everyone" only available within 1 hour
- [ ] "Delete for everyone" only available for own messages
- [ ] Deleted messages show "This message was deleted" placeholder
- [ ] Media files cleaned up on deletion
- [ ] Deletion propagates in real-time
- [ ] Admins can delete any message in groups

#### UI Components
| Component | File | Changes |
|-----------|------|---------|
| DeleteMessageDialog | `delete_message_dialog.dart` | New file |
| MessageBubble | `message_bubble.dart` | Handle redacted state |
| MessageRepository | `message_repository.dart` | Add deleteMessage method |

---

### Feature 1.3: Message Forwarding

**ID:** MSG-FWD-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 4 days

#### Description
Forward messages to other chats with attribution.

#### API Integration
```dart
// Forward creates new message with forward metadata
final request = pb.SendEventRequest(
  event: [
    pb.RoomEvent(
      roomId: targetRoomId,
      type: originalEvent.type,
      payload: originalEvent.payload,
      // Add forward metadata in extras
    ),
  ],
);
```

#### Database Changes
```sql
ALTER TABLE room_events ADD COLUMN forwarded_from_room TEXT;
ALTER TABLE room_events ADD COLUMN forwarded_from_event TEXT;
ALTER TABLE room_events ADD COLUMN forward_count INTEGER DEFAULT 0;
```

#### Acceptance Criteria
- [ ] Long-press reveals "Forward" option
- [ ] Forward opens room/contact picker
- [ ] Can select multiple destinations (max 5)
- [ ] Forwarded messages show "Forwarded" label
- [ ] Media forwarding shares same file (no re-upload)
- [ ] Forward count tracks viral spread
- [ ] Cannot forward restricted messages

#### UI Components
| Component | File | Changes |
|-----------|------|---------|
| ForwardSheet | `forward_sheet.dart` | New file - destination picker |
| MessageBubble | `message_bubble.dart` | Show forward indicator |
| RoomPicker | `room_picker.dart` | New file - multi-select rooms |

---

### Feature 1.4: Starred Messages

**ID:** MSG-STAR-001
**Priority:** P2
**Complexity:** Low
**Engineers:** 1
**Duration:** 2 days

#### Description
Bookmark important messages for quick access.

#### Database Changes
```sql
CREATE TABLE starred_messages (
  id TEXT PRIMARY KEY,
  event_id TEXT NOT NULL REFERENCES room_events(id),
  room_id TEXT NOT NULL,
  starred_at INTEGER NOT NULL,
  note TEXT
);
```

#### Acceptance Criteria
- [ ] Long-press reveals "Star" option
- [ ] Starred messages show star icon
- [ ] "Starred Messages" screen accessible from settings
- [ ] Starred messages grouped by room
- [ ] Tap starred message jumps to context
- [ ] Can add note to starred message
- [ ] Unstar removes from list

#### UI Components
| Component | File | Changes |
|-----------|------|---------|
| StarredMessagesScreen | `starred_messages_screen.dart` | New file |
| MessageBubble | `message_bubble.dart` | Show star indicator |
| StarRepository | `star_repository.dart` | New file |

---

### Feature 1.5: Read Receipts UI (Groups)

**ID:** MSG-READ-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Show who has read messages in group chats.

#### API Integration
```dart
// Listen for ReceiptEvent in gateway stream
final receiptEvent = response.receiptEvent;
// receiptEvent contains: event_id[], subscription_id
```

#### Database Changes
```sql
CREATE TABLE read_receipts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_id TEXT NOT NULL,
  room_id TEXT NOT NULL,
  profile_id TEXT NOT NULL,
  read_at INTEGER NOT NULL,
  UNIQUE(event_id, profile_id)
);
```

#### Acceptance Criteria
- [ ] Own messages show read receipt indicator
- [ ] Single check = sent, double check = delivered, blue = read
- [ ] In groups, tap indicator shows who read
- [ ] "Seen by X, Y, and Z" format
- [ ] Shows time each person read
- [ ] Updates in real-time
- [ ] Privacy setting to disable read receipts

#### UI Components
| Component | File | Changes |
|-----------|------|---------|
| ReadReceiptIndicator | `read_receipt_indicator.dart` | New file |
| ReadReceiptSheet | `read_receipt_sheet.dart` | New file - list readers |
| MessageBubble | `message_bubble.dart` | Integrate indicator |

---

### Feature 1.6: Typing Indicators (Enhanced)

**ID:** MSG-TYPE-001
**Priority:** P1
**Complexity:** Low
**Engineers:** 1
**Duration:** 2 days

#### Description
Show who is typing in real-time with debouncing.

#### API Integration
```dart
// Send typing via gateway stream
final typingEvent = pb.TypingEvent(
  subscriptionId: subscriptionId,
  roomId: roomId,
  typing: true,
  since: timestamp,
);
final command = pb.ClientCommand(typing: typingEvent);
final request = pb.StreamRequest(command: command);
gatewayClient.stream(Stream.value(request));
```

#### Acceptance Criteria
- [ ] Typing indicator appears within 500ms
- [ ] Shows "User is typing..." for 1:1
- [ ] Shows "User1, User2 are typing..." for groups (max 3)
- [ ] Shows "Several people are typing..." for 4+
- [ ] Typing auto-clears after 5 seconds of inactivity
- [ ] Debounced sending (every 3 seconds while typing)
- [ ] Animation (three dots pulse)

#### UI Components
| Component | File | Changes |
|-----------|------|---------|
| TypingIndicator | `typing_indicator.dart` | Enhance animation |
| TypingProvider | `typing_provider.dart` | Add debouncing |

---

### Feature 1.7: Draft Messages Persistence

**ID:** MSG-DRAFT-001
**Priority:** P2
**Complexity:** Low
**Engineers:** 1
**Duration:** 1 day

#### Description
Persist unsent messages across app restarts.

#### Database Changes
```sql
CREATE TABLE drafts (
  room_id TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  reply_to_id TEXT,
  updated_at INTEGER NOT NULL
);
```

#### Acceptance Criteria
- [ ] Draft saves automatically as user types
- [ ] Draft restored when returning to chat
- [ ] Draft indicator shown in room list
- [ ] Draft cleared on send
- [ ] Draft includes reply context
- [ ] Drafts sync across devices (optional)

---

### Feature 1.8: Message Retry Enhancement

**ID:** MSG-RETRY-001
**Priority:** P1
**Complexity:** Low
**Engineers:** 1
**Duration:** 2 days

#### Description
Improve failed message handling with manual retry.

#### Acceptance Criteria
- [ ] Failed messages show error icon
- [ ] Tap error icon shows retry/delete options
- [ ] Retry attempts visible (1/5, 2/5, etc.)
- [ ] After 5 failures, manual retry only
- [ ] Error reason displayed
- [ ] Bulk retry all failed messages option
- [ ] Failed media shows thumbnail with error overlay

---

## 6. Phase 2: Security & Privacy

### Feature 2.1: Enable E2EE by Default

**ID:** SEC-E2E-001
**Priority:** P0
**Complexity:** High
**Engineers:** 4
**Duration:** 5 days

#### Description
Enable end-to-end encryption using Vodozemac (Olm/Megolm) for all messages.

#### API Integration
```dart
// Store E2EE keys via Device API
final request = DeviceAddKeyRequest(
  deviceId: deviceId,
  keyType: KeyType.CURVE25519_KEY,
  keyMaterial: publicKey,
);
await deviceClient.addKey(request);

// Exchange keys with room members
final keysRequest = DeviceSearchKeyRequest(
  profileId: recipientProfileId,
  keyType: KeyType.CURVE25519_KEY,
);
final keys = await deviceClient.searchKey(keysRequest);
```

#### Implementation Details
```dart
// In message_sending_service.dart
Future<RoomEvent> sendTextMessage({
  required String roomId,
  required String text,
  bool encrypt = true,  // CHANGE: Default to true
}) async {
  if (encrypt) {
    final encrypted = await _encryptionService.encryptGroup(roomId, text);
    // ... encryption logic
  }
}
```

#### Acceptance Criteria
- [ ] All new messages encrypted by default
- [ ] Key exchange happens automatically on room join
- [ ] Session keys rotate every 100 messages
- [ ] Decrypt fails gracefully with "Unable to decrypt" message
- [ ] Key backup option for account recovery
- [ ] Encryption indicator (lock icon) on all messages
- [ ] Device verification flow for security-conscious users
- [ ] Performance: <50ms encryption overhead

#### Database Changes
```sql
-- Already exists: Sessions, Prekeys tables
-- Add key backup table
CREATE TABLE key_backup (
  id TEXT PRIMARY KEY,
  encrypted_key BLOB NOT NULL,
  version INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);
```

#### Test Cases
```dart
test('messages encrypt by default', ...);
test('key exchange on room join', ...);
test('session rotation after 100 messages', ...);
test('decrypt failure shows placeholder', ...);
test('encryption performance under 50ms', ...);
```

---

### Feature 2.2: Certificate Pinning

**ID:** SEC-PIN-001
**Priority:** P0
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Pin TLS certificates to prevent MITM attacks.

#### Implementation
```dart
// In networking/client.dart
class PinnedHttpClient extends http.BaseClient {
  final List<String> _pinnedCertHashes = [
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
  ];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Verify certificate hash matches pinned values
  }
}
```

#### Acceptance Criteria
- [ ] All API calls use certificate pinning
- [ ] Pinning works on iOS, Android, and desktop
- [ ] Backup pins for certificate rotation
- [ ] Clear error when pin validation fails
- [ ] Pin bypass for debug builds only
- [ ] Certificate update mechanism without app update

---

### Feature 2.3: Biometric Lock

**ID:** SEC-BIO-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Optional biometric authentication to access the app.

#### Dependencies
```yaml
local_auth: ^2.1.6
```

#### Acceptance Criteria
- [ ] Setting to enable biometric lock
- [ ] Supports fingerprint and face ID
- [ ] Lock after X minutes of inactivity (configurable)
- [ ] Fallback to device PIN/password
- [ ] Lock screen shows app icon only
- [ ] Notifications still visible when locked (configurable)
- [ ] Quick reply from notification bypasses lock

#### Database Changes
```sql
-- In settings preferences
INSERT INTO settings (key, value) VALUES
  ('biometric_enabled', 'false'),
  ('lock_timeout_minutes', '1'),
  ('show_notifications_locked', 'true');
```

---

### Feature 2.4: Screenshot Prevention

**ID:** SEC-SCREEN-001
**Priority:** P2
**Complexity:** Low
**Engineers:** 1
**Duration:** 2 days

#### Description
Prevent screenshots in sensitive screens.

#### Implementation
```dart
// Android: In MainActivity.kt
window.setFlags(
  WindowManager.LayoutParams.FLAG_SECURE,
  WindowManager.LayoutParams.FLAG_SECURE
)

// iOS: In AppDelegate.swift
// Overlay secure text field
```

#### Acceptance Criteria
- [ ] Chat screens protected by default
- [ ] Setting to disable protection
- [ ] Works on Android and iOS
- [ ] Screen recording also blocked
- [ ] Indicator when screenshot attempted

---

### Feature 2.5: Disappearing Messages

**ID:** SEC-DISAPPEAR-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 4 days

#### Description
Messages auto-delete after configurable time.

#### Database Changes
```sql
ALTER TABLE rooms ADD COLUMN disappearing_timeout INTEGER; -- seconds, NULL = disabled
ALTER TABLE room_events ADD COLUMN expires_at INTEGER;
```

#### Acceptance Criteria
- [ ] Room setting: Off, 24 hours, 7 days, 90 days
- [ ] Setting change notified to all members
- [ ] Timer starts when message read
- [ ] Deleted from all devices
- [ ] Media also deleted
- [ ] Timer icon on disappearing messages
- [ ] Background job checks expiry every hour

#### UI Components
| Component | File | Changes |
|-----------|------|---------|
| DisappearingSettingsSheet | `disappearing_settings_sheet.dart` | New file |
| MessageBubble | `message_bubble.dart` | Timer indicator |
| ExpiryService | `expiry_service.dart` | New file - cleanup job |

---

### Feature 2.6: Block/Report Users

**ID:** SEC-BLOCK-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Block and report problematic users.

#### API Integration
```dart
// Block via Profile API (update roster)
final request = ProfileRemoveRosterRequest(
  profileId: currentUserId,
  contactId: blockedUserId,
);
await profileClient.removeRoster(request);

// Then add to blocked list
await rosterRepository.setBlocked(blockedUserId, true);
```

#### Acceptance Criteria
- [ ] Block option in contact profile
- [ ] Blocked users can't message you
- [ ] Blocked users see single check only
- [ ] You don't see blocked user's messages
- [ ] Blocked users list in settings
- [ ] Unblock option available
- [ ] Report sends abuse report to backend
- [ ] Report categories: spam, harassment, inappropriate content

#### Database Changes
```sql
CREATE TABLE reports (
  id TEXT PRIMARY KEY,
  reported_user_id TEXT NOT NULL,
  reason TEXT NOT NULL,
  details TEXT,
  evidence_event_ids TEXT, -- JSON array
  reported_at INTEGER NOT NULL,
  status TEXT DEFAULT 'pending'
);
```

---

### Feature 2.7: Two-Factor Authentication

**ID:** SEC-2FA-001
**Priority:** P2
**Complexity:** Medium
**Engineers:** 2
**Duration:** 4 days

#### Description
Optional 2FA for account security.

#### Acceptance Criteria
- [ ] Enable 2FA in security settings
- [ ] Supports TOTP (Google Authenticator compatible)
- [ ] Backup codes generated (10 codes)
- [ ] Required on new device login
- [ ] Can disable with current 2FA code
- [ ] Recovery via email if codes lost

---

## 7. Phase 3: Notifications & Real-Time

### Feature 3.1: Push Notifications (Enable)

**ID:** NOTIF-PUSH-001
**Priority:** P0
**Complexity:** Medium
**Engineers:** 3
**Duration:** 4 days

#### Description
Enable Firebase Cloud Messaging for push notifications.

#### API Integration
```dart
// Register FCM token via Device API
final request = DeviceRegisterKeyRequest(
  deviceId: deviceId,
  keyType: KeyType.FCM_TOKEN,
  keyMaterial: fcmToken,
);
await deviceClient.registerKey(request);

// Backend sends notifications via Notification API
// Client receives via FCM
```

#### Implementation
```dart
// In main.dart - uncomment and implement
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle notification
}
```

#### Acceptance Criteria
- [ ] FCM token registered on app start
- [ ] Token refreshed when changed
- [ ] Foreground notifications shown as banner
- [ ] Background notifications wake app
- [ ] Killed app receives notifications
- [ ] Tap notification opens correct chat
- [ ] Notification permission requested on first launch
- [ ] Works on iOS and Android

#### Platform Configuration
| Platform | File | Changes |
|----------|------|---------|
| Android | `AndroidManifest.xml` | FCM service declaration |
| iOS | `AppDelegate.swift` | APNS setup |
| iOS | `Info.plist` | Background modes |

---

### Feature 3.2: Rich Notifications

**ID:** NOTIF-RICH-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Show message preview and media thumbnails in notifications.

#### Acceptance Criteria
- [ ] Text messages show preview (truncated at 100 chars)
- [ ] Image messages show thumbnail
- [ ] Voice messages show duration
- [ ] Sender name and avatar shown
- [ ] Group name shown for group messages
- [ ] Reply action from notification
- [ ] Mark as read action from notification
- [ ] Privacy setting to hide content

---

### Feature 3.3: Notification Grouping

**ID:** NOTIF-GROUP-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Group notifications by chat.

#### Acceptance Criteria
- [ ] Multiple messages from same chat grouped
- [ ] Group shows "X new messages" summary
- [ ] Expand to see individual messages
- [ ] Android: Notification channels per chat
- [ ] iOS: Thread identifiers
- [ ] Group notification clears all on tap

---

### Feature 3.4: Mute Chat

**ID:** NOTIF-MUTE-001
**Priority:** P1
**Complexity:** Low
**Engineers:** 1
**Duration:** 2 days

#### Description
Mute notifications for specific chats.

#### Database Changes
```sql
ALTER TABLE rooms ADD COLUMN muted_until INTEGER; -- NULL = not muted, 0 = forever
```

#### Acceptance Criteria
- [ ] Mute options: 8 hours, 1 week, Always
- [ ] Muted indicator in chat list
- [ ] Muted chats don't send notifications
- [ ] Muted chats still show in chat list
- [ ] Unmute from chat info screen
- [ ] Quick unmute from room list (long press)

---

### Feature 3.5: Badge Counts

**ID:** NOTIF-BADGE-001
**Priority:** P1
**Complexity:** Low
**Engineers:** 1
**Duration:** 2 days

#### Description
App icon badge shows unread count.

#### Implementation
```dart
// Using flutter_app_badger
FlutterAppBadger.updateBadgeCount(unreadCount);
```

#### Acceptance Criteria
- [ ] Badge updates in real-time
- [ ] Badge clears when all read
- [ ] Badge respects muted chats (optional setting)
- [ ] Works on iOS and Android
- [ ] Badge updates from background

---

### Feature 3.6: Notification Settings Per Chat

**ID:** NOTIF-PERCHAT-001
**Priority:** P2
**Complexity:** Medium
**Engineers:** 1
**Duration:** 2 days

#### Description
Customize notification settings per chat.

#### Database Changes
```sql
CREATE TABLE room_notification_settings (
  room_id TEXT PRIMARY KEY,
  enabled INTEGER DEFAULT 1,
  sound TEXT,
  vibrate INTEGER DEFAULT 1,
  show_preview INTEGER DEFAULT 1,
  custom_tone TEXT
);
```

#### Acceptance Criteria
- [ ] Per-chat sound selection
- [ ] Per-chat vibration toggle
- [ ] Per-chat preview toggle
- [ ] Custom notification tone
- [ ] Inherit from global settings by default

---

## 8. Phase 4: Media & Attachments

### Feature 4.1: Media Compression

**ID:** MEDIA-COMP-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 4 days

#### Description
Compress images and videos before upload.

#### Dependencies
```yaml
flutter_image_compress: ^2.0.4
video_compress: ^3.1.2
```

#### Implementation
```dart
Future<File> compressImage(File file, {int quality = 80}) async {
  final result = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,
    targetPath,
    quality: quality,
    minWidth: 1920,
    minHeight: 1080,
  );
  return result!;
}
```

#### Acceptance Criteria
- [ ] Images compressed to max 1920x1080
- [ ] JPEG quality: 80% (configurable)
- [ ] Videos compressed to 720p
- [ ] Original quality option available
- [ ] Compression happens before upload
- [ ] Progress indicator during compression
- [ ] Estimated size shown before send

---

### Feature 4.2: Thumbnail Generation

**ID:** MEDIA-THUMB-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Generate thumbnails for media messages.

#### API Integration
```dart
// Use Files API thumbnail endpoint
final request = GetContentThumbnailRequest(
  serverName: serverName,
  mediaId: mediaId,
  width: 300,
  height: 300,
  method: 'crop',
);
final thumbnail = await filesClient.getContentThumbnail(request);
```

#### Acceptance Criteria
- [ ] Thumbnails generated client-side for preview
- [ ] Thumbnails uploaded alongside media
- [ ] Thumbnail shown while full media loads
- [ ] Blur hash for instant preview
- [ ] Video thumbnails from first frame
- [ ] Thumbnail max size: 300x300

---

### Feature 4.3: Progressive Upload

**ID:** MEDIA-UPLOAD-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 4 days

#### Description
Upload large files with progress and resume capability.

#### API Integration
```dart
// Stream upload via Files API
final metadataRequest = UploadContentRequest(
  metadata: UploadMetadata(
    filename: filename,
    contentType: mimeType,
    fileSizeBytes: Int64(fileSize),
  ),
);

// Stream chunks
Stream<UploadContentRequest> uploadStream() async* {
  yield metadataRequest;
  await for (final chunk in file.openRead()) {
    yield UploadContentRequest(
      chunk: UploadChunk(chunk: chunk),
    );
  }
}

final response = await filesClient.uploadContent(uploadStream());
```

#### Acceptance Criteria
- [ ] Upload progress shown (percentage + MB)
- [ ] Upload speed shown
- [ ] Time remaining estimate
- [ ] Cancel upload button
- [ ] Resume failed uploads
- [ ] Chunk size: 256KB
- [ ] Retry individual chunks on failure

---

### Feature 4.4: Background Upload/Download

**ID:** MEDIA-BG-001
**Priority:** P2
**Complexity:** High
**Engineers:** 3
**Duration:** 5 days

#### Description
Continue media transfers when app backgrounded.

#### Implementation
```dart
// Using flutter_background_service
final service = FlutterBackgroundService();
await service.configure(
  androidConfiguration: AndroidConfiguration(
    onStart: onStart,
    autoStart: false,
    isForegroundMode: true,
  ),
  iosConfiguration: IosConfiguration(
    autoStart: false,
    onForeground: onStart,
    onBackground: onIosBackground,
  ),
);
```

#### Acceptance Criteria
- [ ] Uploads continue in background
- [ ] Downloads continue in background
- [ ] Foreground notification shows progress
- [ ] Battery optimization handling
- [ ] Resume after app killed
- [ ] Queue multiple transfers
- [ ] Priority: pending sends first

---

### Feature 4.5: Media Cache Management

**ID:** MEDIA-CACHE-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Efficient media caching with eviction.

#### Implementation
```dart
class MediaCacheManager {
  static const maxCacheSize = 500 * 1024 * 1024; // 500MB

  Future<void> evictOldest() async {
    final files = await cacheDir.list().toList();
    files.sort((a, b) => a.statSync().accessed.compareTo(b.statSync().accessed));
    // Remove oldest until under limit
  }
}
```

#### Acceptance Criteria
- [ ] Default cache size: 500MB
- [ ] Configurable cache size
- [ ] LRU eviction policy
- [ ] Clear cache button in settings
- [ ] Cache stats shown (size used)
- [ ] Auto-eviction when storage low
- [ ] Cache per-room option

---

### Feature 4.6: Voice Message Recording

**ID:** MEDIA-VOICE-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Record and send voice messages.

#### Current State
Already implemented in `voice_recording_service.dart`, needs UI polish.

#### Acceptance Criteria
- [ ] Hold mic button to record
- [ ] Slide to cancel
- [ ] Waveform visualization while recording
- [ ] Max duration: 5 minutes
- [ ] Lock for hands-free recording
- [ ] Playback before send option
- [ ] Delete before send option
- [ ] Shows duration in message

---

### Feature 4.7: Link Preview

**ID:** MEDIA-LINK-001
**Priority:** P2
**Complexity:** Low
**Engineers:** 1
**Duration:** 2 days

#### Description
Show OpenGraph preview for URLs in messages.

#### API Integration
```dart
final request = GetUrlPreviewRequest(
  url: url,
);
final preview = await filesClient.getUrlPreview(request);
// preview contains: title, description, image, siteName
```

#### Acceptance Criteria
- [ ] Detect URLs in message text
- [ ] Fetch OpenGraph metadata
- [ ] Show title, description, image
- [ ] Cache previews locally
- [ ] Timeout: 5 seconds
- [ ] Fallback to just URL on failure

---

## 9. Phase 5: Group Features

### Feature 5.1: Group Admin Controls

**ID:** GROUP-ADMIN-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 4 days

#### Description
Full admin capabilities for group management.

#### API Integration
```dart
// Update member role
final request = UpdateSubscriptionRoleRequest(
  roomId: roomId,
  subscriptionId: memberId,
  role: 'admin', // or 'moderator', 'member'
);
await chatClient.updateSubscriptionRole(request);
```

#### Acceptance Criteria
- [ ] Roles: Owner (1), Admin (many), Moderator (many), Member
- [ ] Owner can promote/demote admins
- [ ] Admins can promote/demote moderators
- [ ] Admins can remove members
- [ ] Admins can edit group info
- [ ] Moderators can remove messages
- [ ] Role changes notified to group
- [ ] Transfer ownership option

---

### Feature 5.2: Group Invite Links

**ID:** GROUP-INVITE-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 4 days

#### Description
Shareable links to join groups.

#### API Integration
```dart
// Create invite link (stored in room metadata)
final request = UpdateRoomRequest(
  roomId: roomId,
  metadata: Struct(fields: {
    'invite_link': Value(stringValue: 'https://chat.antinvestor.com/join/abc123'),
    'invite_expires': Value(numberValue: expiryTimestamp),
  }),
);
```

#### Database Changes
```sql
CREATE TABLE invite_links (
  id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL REFERENCES rooms(id),
  code TEXT NOT NULL UNIQUE,
  created_by TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  expires_at INTEGER,
  max_uses INTEGER,
  use_count INTEGER DEFAULT 0,
  revoked INTEGER DEFAULT 0
);
```

#### Acceptance Criteria
- [ ] Generate shareable link
- [ ] QR code for link
- [ ] Expiring links option
- [ ] Max uses limit option
- [ ] Revoke link option
- [ ] See who joined via link
- [ ] Admin approval mode option
- [ ] Link format: `chat.app/join/{code}`

---

### Feature 5.3: Group Description & Settings

**ID:** GROUP-DESC-001
**Priority:** P2
**Complexity:** Low
**Engineers:** 1
**Duration:** 2 days

#### Description
Comprehensive group information management.

#### Acceptance Criteria
- [ ] Group name (max 100 chars)
- [ ] Group description (max 500 chars)
- [ ] Group avatar upload
- [ ] Who can edit info setting
- [ ] Who can send messages setting
- [ ] Who can add members setting
- [ ] Changes logged as system messages

---

### Feature 5.4: Admin-Only Announcements

**ID:** GROUP-ANNOUNCE-001
**Priority:** P2
**Complexity:** Low
**Engineers:** 1
**Duration:** 2 days

#### Description
Announcement mode where only admins can post.

#### Database Changes
```sql
ALTER TABLE rooms ADD COLUMN announcement_mode INTEGER DEFAULT 0;
```

#### Acceptance Criteria
- [ ] Toggle announcement mode (admin only)
- [ ] Members see disabled input in announcement mode
- [ ] Members can still react
- [ ] System message when mode changes
- [ ] "Only admins can send messages" indicator

---

### Feature 5.5: Group Member Limits

**ID:** GROUP-LIMIT-001
**Priority:** P2
**Complexity:** Low
**Engineers:** 1
**Duration:** 1 day

#### Description
Enforce maximum group size.

#### Acceptance Criteria
- [ ] Default max: 256 members
- [ ] Error when limit reached
- [ ] Show current/max in group info
- [ ] Admin can request limit increase

---

## 10. Phase 6: Contacts & Identity

### Feature 6.1: Contact Sync Enhancement

**ID:** CONTACT-SYNC-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Improved device contact synchronization.

#### API Integration
```dart
// Batch sync contacts via Profile API
final request = AddRosterRequest(
  profileId: currentUserId,
  contacts: phoneContacts.map((c) => ContactInfo(
    type: ContactType.PHONE,
    value: c.normalizedPhone,
    displayName: c.displayName,
  )).toList(),
);
final response = await profileClient.addRoster(request);
```

#### Acceptance Criteria
- [ ] Sync all phone contacts on permission grant
- [ ] Incremental sync (only changes)
- [ ] Sync in background (every 24 hours)
- [ ] Show "New on Chat" section
- [ ] Privacy: only hashes sent to server
- [ ] Manual sync button
- [ ] Sync status indicator

---

### Feature 6.2: User Status/Bio

**ID:** CONTACT-STATUS-001
**Priority:** P2
**Complexity:** Low
**Engineers:** 1
**Duration:** 2 days

#### Description
User status text and custom bios.

#### API Integration
```dart
// Update profile with status
final request = ProfileUpdateRequest(
  profileId: profileId,
  properties: Struct(fields: {
    'status': Value(stringValue: 'Available'),
    'bio': Value(stringValue: 'Hello, I am using Chat!'),
  }),
);
await profileClient.update(request);
```

#### Acceptance Criteria
- [ ] Status options: Available, Busy, Do Not Disturb, custom
- [ ] Bio text (max 139 chars, like WhatsApp)
- [ ] Status visible in contact info
- [ ] Last seen timestamp
- [ ] Privacy setting for status visibility

---

### Feature 6.3: Contact Verification

**ID:** CONTACT-VERIFY-001
**Priority:** P2
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Verify contact identity via QR code.

#### Implementation
```dart
// Generate QR with public key fingerprint
final qrData = jsonEncode({
  'profileId': profileId,
  'keyFingerprint': keyFingerprint,
  'timestamp': DateTime.now().millisecondsSinceEpoch,
});
```

#### Acceptance Criteria
- [ ] Generate QR code for your identity
- [ ] Scan contact's QR code
- [ ] Show verification checkmark
- [ ] Warning if keys don't match
- [ ] Verification persists locally
- [ ] Re-verify if keys change

---

### Feature 6.4: Profile Editing

**ID:** CONTACT-PROFILE-001
**Priority:** P1
**Complexity:** Low
**Engineers:** 1
**Duration:** 2 days

#### Description
Edit own profile information.

#### Acceptance Criteria
- [ ] Edit display name
- [ ] Change profile photo
- [ ] Edit bio/about
- [ ] Add/remove email
- [ ] Add/remove phone
- [ ] Changes sync to all contacts
- [ ] Photo crop/resize before upload

---

## 11. Phase 7: Search & Discovery

### Feature 7.1: Message Search

**ID:** SEARCH-MSG-001
**Priority:** P0
**Complexity:** High
**Engineers:** 3
**Duration:** 5 days

#### Description
Full-text search across all messages.

#### Database Changes (Drift FTS5)
```dart
// Add FTS virtual table
@DriftDatabase(tables: [RoomEvents, RoomEventsFts])
class AppDatabase extends _$AppDatabase {
  // Create FTS index
  Future<void> createFtsIndex() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS room_events_fts
      USING fts5(content, content=room_events, content_rowid=rowid);
    ''');
  }

  // Search method
  Future<List<RoomEvent>> searchMessages(String query) async {
    return customSelect('''
      SELECT room_events.* FROM room_events_fts
      JOIN room_events ON room_events_fts.rowid = room_events.rowid
      WHERE room_events_fts MATCH ?
      ORDER BY rank
    ''', variables: [Variable.withString(query)]).get();
  }
}
```

#### Acceptance Criteria
- [ ] Search bar in main screen
- [ ] Real-time results as typing
- [ ] Results grouped by chat
- [ ] Highlight matching text
- [ ] Tap result jumps to message in context
- [ ] Search filters: date range, sender, chat
- [ ] Recent searches saved
- [ ] Search within specific chat option

#### UI Components
| Component | File | Changes |
|-----------|------|---------|
| SearchScreen | `search_screen.dart` | New file |
| SearchResultTile | `search_result_tile.dart` | New file |
| SearchProvider | `search_provider.dart` | New file |

---

### Feature 7.2: Chat Search

**ID:** SEARCH-CHAT-001
**Priority:** P1
**Complexity:** Low
**Engineers:** 1
**Duration:** 2 days

#### Description
Filter and search chat list.

#### Acceptance Criteria
- [ ] Search by chat name
- [ ] Search by participant name
- [ ] Filter: All, Groups, Direct
- [ ] Filter: Unread only
- [ ] Real-time filtering
- [ ] Clear search button
- [ ] Empty state when no results

---

### Feature 7.3: Contact Search

**ID:** SEARCH-CONTACT-001
**Priority:** P1
**Complexity:** Low
**Engineers:** 1
**Duration:** 2 days

#### Description
Search through contacts.

#### API Integration
```dart
final request = SearchRosterRequest(
  profileId: currentUserId,
  query: searchQuery,
  cursor: PageCursor(limit: 20),
);
final results = await profileClient.searchRoster(request);
```

#### Acceptance Criteria
- [ ] Search by name
- [ ] Search by phone number
- [ ] Search by email
- [ ] Results from local and server
- [ ] Debounced search (300ms)
- [ ] Alphabetical sorting option

---

### Feature 7.4: Global Search

**ID:** SEARCH-GLOBAL-001
**Priority:** P2
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Unified search across messages, chats, and contacts.

#### Acceptance Criteria
- [ ] Single search input
- [ ] Tabbed results: Messages, Chats, Contacts
- [ ] Tab shows result count
- [ ] Recent searches
- [ ] Voice search option (speech-to-text)

---

## 12. Phase 8: Calls & Real-Time Communication

### Feature 8.1: TURN Server Configuration

**ID:** CALL-TURN-001
**Priority:** P0
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Configure TURN servers for reliable call connectivity.

#### Implementation
```dart
// In call_manager.dart
final config = {
  'iceServers': [
    {'urls': 'stun:stun.antinvestor.com:3478'},
    {
      'urls': 'turn:turn.antinvestor.com:3478',
      'username': turnUsername,
      'credential': turnCredential,
    },
    {
      'urls': 'turns:turn.antinvestor.com:5349',
      'username': turnUsername,
      'credential': turnCredential,
    },
  ],
};
```

#### Acceptance Criteria
- [ ] TURN servers configured
- [ ] Credentials fetched dynamically
- [ ] Credential rotation support
- [ ] Fallback to STUN if TURN unavailable
- [ ] Call quality metrics collected
- [ ] Works behind strict corporate firewalls

---

### Feature 8.2: Call Quality Improvements

**ID:** CALL-QUALITY-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 4 days

#### Description
Improve call stability and quality.

#### Acceptance Criteria
- [ ] Adaptive bitrate based on network
- [ ] Audio-only fallback on poor connection
- [ ] Quality indicator during call
- [ ] "Poor connection" warning
- [ ] Automatic reconnection (up to 30s)
- [ ] Call stats: packet loss, jitter, latency
- [ ] Background call continues (app minimized)

---

### Feature 8.3: Group Calls

**ID:** CALL-GROUP-001
**Priority:** P1
**Complexity:** High
**Engineers:** 4
**Duration:** 7 days

#### Description
Multi-party voice and video calls.

#### Architecture
```
                    ┌─────────────┐
                    │  SFU Server │
                    └──────┬──────┘
              ┌────────────┼────────────┐
              │            │            │
         ┌────▼────┐  ┌────▼────┐  ┌────▼────┐
         │ Client1 │  │ Client2 │  │ Client3 │
         └─────────┘  └─────────┘  └─────────┘
```

#### Acceptance Criteria
- [ ] Support up to 8 participants
- [ ] Grid layout for video
- [ ] Active speaker highlight
- [ ] Mute/unmute individual
- [ ] Video on/off per participant
- [ ] Participant list during call
- [ ] Join ongoing call
- [ ] Leave without ending call
- [ ] Host can end call for all
- [ ] Ringing all participants

---

### Feature 8.4: Screen Sharing

**ID:** CALL-SCREEN-001
**Priority:** P2
**Complexity:** Medium
**Engineers:** 2
**Duration:** 4 days

#### Description
Share screen during calls.

#### Dependencies
```yaml
flutter_webrtc: ^1.2.1  # Already included, supports screen capture
```

#### Acceptance Criteria
- [ ] Share full screen
- [ ] Share specific app (desktop)
- [ ] Audio sharing option
- [ ] "You are sharing" indicator
- [ ] Stop sharing button
- [ ] Participants see screen
- [ ] Automatic quality reduction for screen share
- [ ] Works on desktop and tablets

---

### Feature 8.5: Call History

**ID:** CALL-HISTORY-001
**Priority:** P2
**Complexity:** Low
**Engineers:** 1
**Duration:** 2 days

#### Description
View past call records.

#### Database Changes
```sql
CREATE TABLE call_history (
  id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL,
  type TEXT NOT NULL, -- 'voice', 'video', 'group'
  direction TEXT NOT NULL, -- 'incoming', 'outgoing'
  status TEXT NOT NULL, -- 'answered', 'missed', 'declined'
  started_at INTEGER,
  ended_at INTEGER,
  duration_seconds INTEGER,
  participants TEXT -- JSON array
);
```

#### Acceptance Criteria
- [ ] Calls tab in main navigation
- [ ] List all calls with type icon
- [ ] Show call duration
- [ ] Missed calls highlighted
- [ ] Tap to call back
- [ ] Delete call record option
- [ ] Filter: All, Missed, Incoming, Outgoing

---

## 13. Phase 9: Settings & Preferences

### Feature 9.1: Settings Persistence

**ID:** SET-PERSIST-001
**Priority:** P1
**Complexity:** Low
**Engineers:** 1
**Duration:** 2 days

#### Description
Persist all user settings locally.

#### Database Changes
```sql
CREATE TABLE user_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);
```

#### Settings Keys
```dart
const settingsKeys = [
  'theme_mode',           // 'system', 'light', 'dark'
  'font_size',            // 'small', 'medium', 'large'
  'notification_sound',
  'notification_vibrate',
  'auto_download_wifi',
  'auto_download_mobile',
  'read_receipts_enabled',
  'typing_indicators_enabled',
  'last_seen_visible',
  'profile_photo_visible', // 'everyone', 'contacts', 'nobody'
  'about_visible',
  'groups_add_permission', // 'everyone', 'contacts'
  'biometric_enabled',
  'lock_timeout_minutes',
];
```

#### Acceptance Criteria
- [ ] All settings persist across restarts
- [ ] Settings sync to new devices (optional)
- [ ] Default values on fresh install
- [ ] Migration for new settings
- [ ] Export settings backup

---

### Feature 9.2: Theme System

**ID:** SET-THEME-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Comprehensive theme customization.

#### Acceptance Criteria
- [ ] Light/Dark/System theme toggle
- [ ] Chat wallpaper selection
- [ ] Custom wallpaper upload
- [ ] Accent color options
- [ ] Font size: Small/Medium/Large
- [ ] Theme preview before applying
- [ ] Per-chat wallpaper option

---

### Feature 9.3: Storage Management

**ID:** SET-STORAGE-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
View and manage app storage usage.

#### Acceptance Criteria
- [ ] Total storage used breakdown
- [ ] Per-chat storage usage
- [ ] Clear cache option
- [ ] Delete old media (>30 days) option
- [ ] Auto-delete setting
- [ ] Storage warning when low
- [ ] Export chat data option

---

### Feature 9.4: Privacy Settings Screen

**ID:** SET-PRIVACY-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Comprehensive privacy controls.

#### Acceptance Criteria
- [ ] Last seen visibility
- [ ] Profile photo visibility
- [ ] About/bio visibility
- [ ] Groups add permission
- [ ] Read receipts toggle
- [ ] Live location sharing
- [ ] Blocked contacts list
- [ ] Fingerprint lock option

---

### Feature 9.5: Account Management

**ID:** SET-ACCOUNT-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Account settings and actions.

#### Acceptance Criteria
- [ ] Change phone number
- [ ] Add/change email
- [ ] Two-factor authentication
- [ ] Request account data
- [ ] Delete account (with warning)
- [ ] Logout option
- [ ] Linked devices list
- [ ] Active sessions management

---

## 14. Phase 10: Performance & Optimization

### Feature 10.1: Image/Widget Caching

**ID:** PERF-CACHE-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Implement efficient caching strategies.

#### Implementation
```dart
class LRUCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap();

  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value; // Move to end
    }
    return value;
  }

  void put(K key, V value) {
    _cache.remove(key);
    _cache[key] = value;
    if (_cache.length > maxSize) {
      _cache.remove(_cache.keys.first);
    }
  }
}
```

#### Acceptance Criteria
- [ ] LRU cache for profile images
- [ ] LRU cache for media thumbnails
- [ ] Memory limit: 50MB for images
- [ ] Disk cache for offline access
- [ ] Cache invalidation on update
- [ ] Preload visible items

---

### Feature 10.2: List Virtualization

**ID:** PERF-VIRTUAL-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Efficient rendering for long lists.

#### Implementation
```dart
ListView.builder(
  itemCount: messages.length,
  itemBuilder: (context, index) {
    return RepaintBoundary(
      child: MessageBubble(message: messages[index]),
    );
  },
  // Add caching
  addRepaintBoundaries: true,
  addAutomaticKeepAlives: false,
)
```

#### Acceptance Criteria
- [ ] Smooth scrolling at 60fps
- [ ] Handle 10,000+ messages
- [ ] Memory stable during scroll
- [ ] Fast initial render (<100ms)
- [ ] No jank when loading more
- [ ] RepaintBoundary on complex widgets

---

### Feature 10.3: Background Isolates

**ID:** PERF-ISOLATE-001
**Priority:** P1
**Complexity:** High
**Engineers:** 2
**Duration:** 4 days

#### Description
Move heavy operations off main thread.

#### Implementation
```dart
// For E2EE operations
final encryptedData = await compute(_encryptMessage, {
  'plaintext': message,
  'sessionKey': sessionKey,
});

static Future<Map> _encryptMessage(Map params) async {
  // Heavy crypto operations
}
```

#### Acceptance Criteria
- [ ] E2EE in isolate
- [ ] JSON parsing in isolate
- [ ] Image compression in isolate
- [ ] Database migrations in isolate
- [ ] No UI jank during heavy ops
- [ ] Proper isolate lifecycle management

---

### Feature 10.4: Network Optimization

**ID:** PERF-NETWORK-001
**Priority:** P2
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Reduce network usage and improve efficiency.

#### Acceptance Criteria
- [ ] Request batching where possible
- [ ] Response compression (gzip)
- [ ] Delta sync for updates
- [ ] Prefetch likely next data
- [ ] Connection pooling
- [ ] Request deduplication
- [ ] Bandwidth usage stats

---

### Feature 10.5: Startup Optimization

**ID:** PERF-STARTUP-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 3 days

#### Description
Minimize app startup time.

#### Acceptance Criteria
- [ ] Cold start < 2 seconds
- [ ] Warm start < 500ms
- [ ] Lazy load features
- [ ] Splash screen optimization
- [ ] Defer non-critical initialization
- [ ] Database warmup in background
- [ ] Measure and log startup time

---

## 15. Phase 11: Testing & Quality

### Feature 11.1: Unit Test Infrastructure

**ID:** TEST-UNIT-001
**Priority:** P0
**Complexity:** Medium
**Engineers:** 2
**Duration:** 5 days

#### Description
Comprehensive unit test coverage.

#### Test Structure
```
test/
├── unit/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── auth_repository_test.dart
│   │   │   └── auth_service_test.dart
│   │   ├── messages/
│   │   │   ├── message_repository_test.dart
│   │   │   └── message_sending_service_test.dart
│   │   └── ...
│   └── core/
│       ├── sync/
│       │   └── sync_engine_test.dart
│       └── crypto/
│           └── e2e_encryption_test.dart
├── widget/
│   ├── message_bubble_test.dart
│   └── chat_input_test.dart
└── integration/
    └── message_flow_test.dart
```

#### Acceptance Criteria
- [ ] Unit tests for all repositories
- [ ] Unit tests for all services
- [ ] Mock all external dependencies
- [ ] Test coverage > 70%
- [ ] Tests run in CI
- [ ] Test failure blocks merge

---

### Feature 11.2: Widget Tests

**ID:** TEST-WIDGET-001
**Priority:** P1
**Complexity:** Medium
**Engineers:** 2
**Duration:** 4 days

#### Description
Test UI components in isolation.

#### Example Test
```dart
testWidgets('MessageBubble displays text correctly', (tester) async {
  final event = RoomEvent(
    id: '1',
    roomId: 'room1',
    senderId: 'user1',
    type: RoomEventType.text,
    content: {'text': 'Hello World'},
    status: EventStatus.sent,
    createdAt: DateTime.now().millisecondsSinceEpoch,
  );

  await tester.pumpWidget(
    MaterialApp(
      home: MessageBubble(event: event, isMine: true),
    ),
  );

  expect(find.text('Hello World'), findsOneWidget);
  expect(find.byIcon(Icons.done), findsOneWidget); // Sent indicator
});
```

#### Acceptance Criteria
- [ ] Test all custom widgets
- [ ] Test user interactions
- [ ] Test loading states
- [ ] Test error states
- [ ] Test dark/light themes
- [ ] Golden image tests for visual regression

---

### Feature 11.3: Integration Tests

**ID:** TEST-INT-001
**Priority:** P1
**Complexity:** High
**Engineers:** 2
**Duration:** 5 days

#### Description
Test feature flows end-to-end.

#### Test Scenarios
```dart
// test/integration/message_flow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Send and receive message flow', (tester) async {
    // Login
    await tester.pumpWidget(MyApp());
    await tester.tap(find.byType(LoginButton));
    await tester.pumpAndSettle();

    // Navigate to chat
    await tester.tap(find.text('Test Room'));
    await tester.pumpAndSettle();

    // Send message
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    // Verify message appears
    expect(find.text('Hello'), findsOneWidget);
  });
}
```

#### Acceptance Criteria
- [ ] Test login flow
- [ ] Test message send/receive
- [ ] Test media upload
- [ ] Test call initiation
- [ ] Test group creation
- [ ] Test offline/online transition
- [ ] Run on real devices in CI

---

### Feature 11.4: E2E Tests

**ID:** TEST-E2E-001
**Priority:** P2
**Complexity:** High
**Engineers:** 2
**Duration:** 5 days

#### Description
Full end-to-end tests against staging backend.

#### Acceptance Criteria
- [ ] Test against staging environment
- [ ] Test multi-device sync
- [ ] Test message delivery
- [ ] Test push notifications
- [ ] Test call connectivity
- [ ] Nightly test runs
- [ ] Performance baseline tests

---

## 16. Phase 12: DevOps & Observability

### Feature 12.1: Error Tracking

**ID:** DEVOPS-ERROR-001
**Priority:** P0
**Complexity:** Low
**Engineers:** 1
**Duration:** 2 days

#### Description
Integrate crash reporting.

#### Dependencies
```yaml
sentry_flutter: ^7.14.0
```

#### Implementation
```dart
// In main.dart
await SentryFlutter.init(
  (options) {
    options.dsn = 'https://xxx@sentry.io/xxx';
    options.tracesSampleRate = 0.2;
    options.environment = kReleaseMode ? 'production' : 'development';
  },
  appRunner: () => runApp(MyApp()),
);
```

#### Acceptance Criteria
- [ ] All crashes reported
- [ ] User ID attached to reports
- [ ] Breadcrumbs for debugging
- [ ] Performance tracing
- [ ] Release health dashboard
- [ ] Alert on spike in errors

---

### Feature 12.2: Analytics

**ID:** DEVOPS-ANALYTICS-001
**Priority:** P2
**Complexity:** Low
**Engineers:** 1
**Duration:** 2 days

#### Description
Track user engagement and app usage.

#### Tracked Events
```dart
const analyticsEvents = [
  'app_open',
  'message_sent',
  'media_uploaded',
  'call_started',
  'call_ended',
  'group_created',
  'contact_added',
  'search_performed',
  'settings_changed',
];
```

#### Acceptance Criteria
- [ ] Track key user actions
- [ ] Respect privacy settings
- [ ] No PII in analytics
- [ ] Daily/weekly/monthly dashboards
- [ ] Funnel analysis
- [ ] Retention metrics

---

### Feature 12.3: CI/CD Pipeline

**ID:** DEVOPS-CICD-001
**Priority:** P0
**Complexity:** Medium
**Engineers:** 1
**Duration:** 3 days

#### Description
Automated build and deployment pipeline.

#### Pipeline Stages
```yaml
# .github/workflows/ci.yml
stages:
  - lint:
      - flutter analyze
      - dart format --check
  - test:
      - flutter test --coverage
      - upload coverage report
  - build:
      - flutter build apk --release
      - flutter build ios --release
      - flutter build web --release
  - deploy:
      - deploy to TestFlight (iOS)
      - deploy to Play Store internal (Android)
      - deploy to Firebase Hosting (Web)
```

#### Acceptance Criteria
- [ ] Automated on PR merge
- [ ] Tests must pass to merge
- [ ] Build artifacts archived
- [ ] Version auto-increment
- [ ] Changelog generation
- [ ] Slack/Teams notifications

---

### Feature 12.4: Logging Infrastructure

**ID:** DEVOPS-LOG-001
**Priority:** P1
**Complexity:** Low
**Engineers:** 1
**Duration:** 2 days

#### Description
Centralized logging for debugging.

#### Implementation
```dart
// Already exists: app_logger.dart
// Enhance with remote logging
class RemoteLogger {
  static void log(LogLevel level, String message, {Map? data}) {
    AppLogger.log(level, message, data: data);

    if (level.index >= LogLevel.warning.index) {
      // Send to remote logging service
      _sendToRemote(level, message, data);
    }
  }
}
```

#### Acceptance Criteria
- [ ] Log levels: debug, info, warning, error
- [ ] Remote logging for warnings+
- [ ] Log rotation (max 10MB local)
- [ ] Export logs for support
- [ ] No sensitive data in logs
- [ ] Correlation IDs for tracing

---

## 17. Dependency Graph

### Critical Path (Must complete in order)

```
Enable E2EE (SEC-E2E-001)
    └── Certificate Pinning (SEC-PIN-001)

Push Notifications (NOTIF-PUSH-001)
    └── Rich Notifications (NOTIF-RICH-001)
    └── Notification Grouping (NOTIF-GROUP-001)

Message Search (SEARCH-MSG-001)
    └── FTS Index Creation
    └── Global Search (SEARCH-GLOBAL-001)

TURN Server (CALL-TURN-001)
    └── Call Quality (CALL-QUALITY-001)
    └── Group Calls (CALL-GROUP-001)

Unit Tests (TEST-UNIT-001)
    └── Widget Tests (TEST-WIDGET-001)
    └── Integration Tests (TEST-INT-001)
```

### Parallel Tracks (No dependencies)

```
Track A: Messaging
├── Message Editing (MSG-EDIT-001)
├── Message Deletion (MSG-DEL-001)
├── Message Forwarding (MSG-FWD-001)
└── Starred Messages (MSG-STAR-001)

Track B: Security
├── Biometric Lock (SEC-BIO-001)
├── Screenshot Prevention (SEC-SCREEN-001)
├── Disappearing Messages (SEC-DISAPPEAR-001)
└── Block/Report (SEC-BLOCK-001)

Track C: Groups
├── Admin Controls (GROUP-ADMIN-001)
├── Invite Links (GROUP-INVITE-001)
├── Group Settings (GROUP-DESC-001)
└── Announcements (GROUP-ANNOUNCE-001)

Track D: Media
├── Compression (MEDIA-COMP-001)
├── Thumbnails (MEDIA-THUMB-001)
├── Progressive Upload (MEDIA-UPLOAD-001)
└── Background Transfer (MEDIA-BG-001)

Track E: UX
├── Settings Persistence (SET-PERSIST-001)
├── Theme System (SET-THEME-001)
├── Storage Management (SET-STORAGE-001)
└── Privacy Settings (SET-PRIVACY-001)
```

---

## 18. Definition of Done

### Feature Complete Checklist

- [ ] Code implemented and compiles without warnings
- [ ] Unit tests written and passing (>80% coverage for new code)
- [ ] Widget tests for all new UI components
- [ ] API integration tested against staging
- [ ] Error handling implemented
- [ ] Logging added for debugging
- [ ] Performance acceptable (no frame drops)
- [ ] Memory leaks checked
- [ ] Accessibility verified (screen reader, contrast)
- [ ] Dark mode verified
- [ ] Offline behavior tested
- [ ] Code reviewed and approved
- [ ] Documentation updated
- [ ] Changelog entry added
- [ ] QA sign-off

### Release Checklist

- [ ] All P0 features complete
- [ ] All P1 features complete or deferred with justification
- [ ] Test coverage >70%
- [ ] No critical bugs
- [ ] Performance benchmarks met
- [ ] Security audit passed
- [ ] Privacy review completed
- [ ] Localization complete (if applicable)
- [ ] App store assets ready
- [ ] Release notes written

---

## Appendix A: Database Schema (Complete)

```sql
-- Core Tables
CREATE TABLE profiles (
  id TEXT PRIMARY KEY,
  name TEXT,
  avatar_url TEXT,
  updated_at INTEGER,
  metadata TEXT
);

CREATE TABLE roster (
  id TEXT PRIMARY KEY,
  roster_id TEXT,
  profile_id TEXT,
  contact_id TEXT,
  contact_type INTEGER DEFAULT 0,
  contact_detail TEXT NOT NULL,
  is_verified INTEGER DEFAULT 0,
  display_name TEXT,
  is_blocked INTEGER DEFAULT 0,
  synced_at INTEGER,
  created_at INTEGER
);

CREATE TABLE rooms (
  id TEXT PRIMARY KEY,
  name TEXT,
  type TEXT,
  last_event_id TEXT,
  last_event_index INTEGER,
  unread_count INTEGER DEFAULT 0,
  metadata TEXT,
  -- New fields
  muted_until INTEGER,
  pinned INTEGER DEFAULT 0,
  archived INTEGER DEFAULT 0,
  disappearing_timeout INTEGER,
  announcement_mode INTEGER DEFAULT 0
);

CREATE TABLE room_members (
  subscription_id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL REFERENCES rooms(id),
  profile_id TEXT,
  contact_id TEXT,
  role TEXT,
  joined_at INTEGER
);

CREATE TABLE room_events (
  id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL REFERENCES rooms(id),
  sender_id TEXT NOT NULL,
  sender_contact_id TEXT,
  type INTEGER NOT NULL,
  content TEXT,
  parent_id TEXT,
  status INTEGER DEFAULT 0,
  created_at INTEGER,
  server_ts INTEGER,
  local_id TEXT,
  -- New fields
  edited INTEGER DEFAULT 0,
  edited_at INTEGER,
  original_content TEXT,
  redacted INTEGER DEFAULT 0,
  redacted_at INTEGER,
  redacted_by TEXT,
  forwarded_from_room TEXT,
  forwarded_from_event TEXT,
  forward_count INTEGER DEFAULT 0,
  expires_at INTEGER
);

-- E2EE Tables
CREATE TABLE sessions (
  session_id TEXT PRIMARY KEY,
  profile_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  ratchet_state BLOB,
  created_at INTEGER
);

CREATE TABLE prekeys (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  public_key TEXT,
  private_key TEXT,
  is_signed INTEGER DEFAULT 0
);

CREATE TABLE key_backup (
  id TEXT PRIMARY KEY,
  encrypted_key BLOB NOT NULL,
  version INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);

-- Sync Tables
CREATE TABLE pending_jobs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  payload TEXT,
  created_at INTEGER,
  retry_count INTEGER DEFAULT 0,
  status TEXT DEFAULT 'pending'
);

CREATE TABLE sync_metadata (
  key TEXT PRIMARY KEY,
  value TEXT,
  updated_at INTEGER
);

-- New Tables
CREATE TABLE drafts (
  room_id TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  reply_to_id TEXT,
  updated_at INTEGER NOT NULL
);

CREATE TABLE starred_messages (
  id TEXT PRIMARY KEY,
  event_id TEXT NOT NULL REFERENCES room_events(id),
  room_id TEXT NOT NULL,
  starred_at INTEGER NOT NULL,
  note TEXT
);

CREATE TABLE read_receipts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_id TEXT NOT NULL,
  room_id TEXT NOT NULL,
  profile_id TEXT NOT NULL,
  read_at INTEGER NOT NULL,
  UNIQUE(event_id, profile_id)
);

CREATE TABLE invite_links (
  id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL REFERENCES rooms(id),
  code TEXT NOT NULL UNIQUE,
  created_by TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  expires_at INTEGER,
  max_uses INTEGER,
  use_count INTEGER DEFAULT 0,
  revoked INTEGER DEFAULT 0
);

CREATE TABLE call_history (
  id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL,
  type TEXT NOT NULL,
  direction TEXT NOT NULL,
  status TEXT NOT NULL,
  started_at INTEGER,
  ended_at INTEGER,
  duration_seconds INTEGER,
  participants TEXT
);

CREATE TABLE room_notification_settings (
  room_id TEXT PRIMARY KEY,
  enabled INTEGER DEFAULT 1,
  sound TEXT,
  vibrate INTEGER DEFAULT 1,
  show_preview INTEGER DEFAULT 1,
  custom_tone TEXT
);

CREATE TABLE user_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE reports (
  id TEXT PRIMARY KEY,
  reported_user_id TEXT NOT NULL,
  reason TEXT NOT NULL,
  details TEXT,
  evidence_event_ids TEXT,
  reported_at INTEGER NOT NULL,
  status TEXT DEFAULT 'pending'
);

CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL REFERENCES rooms(id),
  amount TEXT,
  currency TEXT,
  status TEXT,
  initiator_id TEXT
);

-- FTS Index
CREATE VIRTUAL TABLE room_events_fts USING fts5(
  content,
  content=room_events,
  content_rowid=rowid
);

-- Indexes
CREATE INDEX idx_room_events_room ON room_events(room_id);
CREATE INDEX idx_room_events_sender ON room_events(sender_id);
CREATE INDEX idx_room_events_status ON room_events(status);
CREATE INDEX idx_room_members_room ON room_members(room_id);
CREATE INDEX idx_roster_profile ON roster(profile_id);
CREATE INDEX idx_read_receipts_event ON read_receipts(event_id);
```

---

## Appendix B: API Error Codes

| Code | Name | Description | Action |
|------|------|-------------|--------|
| 401 | UNAUTHENTICATED | Token invalid/expired | Refresh token |
| 403 | PERMISSION_DENIED | Not authorized | Show error |
| 404 | NOT_FOUND | Resource doesn't exist | Handle gracefully |
| 409 | ALREADY_EXISTS | Duplicate resource | Update instead |
| 429 | RESOURCE_EXHAUSTED | Rate limited | Backoff and retry |
| 500 | INTERNAL | Server error | Retry with backoff |
| 503 | UNAVAILABLE | Service down | Retry with backoff |
| 504 | DEADLINE_EXCEEDED | Timeout | Retry once |

---

## Appendix C: Feature Priority Matrix

| Priority | Definition | SLA |
|----------|------------|-----|
| P0 | Critical - App unusable without | Week 1-2 |
| P1 | High - Core functionality | Week 3-4 |
| P2 | Medium - Important but not blocking | Week 5-6 |
| P3 | Low - Nice to have | Week 7-8 or backlog |

### P0 Features (12)
- Enable E2EE (SEC-E2E-001)
- Certificate Pinning (SEC-PIN-001)
- Push Notifications (NOTIF-PUSH-001)
- Message Search (SEARCH-MSG-001)
- Message Editing (MSG-EDIT-001)
- Message Deletion (MSG-DEL-001)
- TURN Server (CALL-TURN-001)
- Unit Tests (TEST-UNIT-001)
- Error Tracking (DEVOPS-ERROR-001)
- CI/CD Pipeline (DEVOPS-CICD-001)
- Media Compression (MEDIA-COMP-001)
- Settings Persistence (SET-PERSIST-001)

### P1 Features (25)
- All remaining core features
- Group management
- Call quality
- Search enhancements
- Privacy settings
- Widget tests

### P2 Features (15)
- Advanced features
- Nice-to-have UX
- Performance optimizations
- E2E tests

---

*Document End*

*Total Features: 68*
*Estimated Team: 100 Engineers*
*Estimated Duration: 8 Weeks*
