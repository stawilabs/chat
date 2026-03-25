# Chat - Cross-Platform Messaging Application

## Overview

Chat is a production-ready, cross-platform mobile and desktop application that provides secure, real-time group communication with integrated credit & savings automation features. Built with Flutter/Dart, the app runs on iOS, Android, Web, macOS, Linux, and Windows, offering a unified messaging experience across all devices.

**Tagline**: "Automated and secure group credit & savings"

## Architecture

```
┌────────────────────────────────────────────────────┐
│              FLUTTER APPLICATION                    │
│                                                     │
│  ┌──────────────────────────────────────────────┐ │
│  │           PRESENTATION LAYER (UI)             │ │
│  │  - Riverpod State Management                  │ │
│  │  - GoRouter Navigation                        │ │
│  │  - Material Design 3                          │ │
│  │  - Responsive Layouts                         │ │
│  └──────────┬───────────────────────────────────┘ │
│             │                                      │
│  ┌──────────▼───────────────────────────────────┐ │
│  │         FEATURES (Domain Logic)               │ │
│  │  - Messages    - Rooms      - Auth           │ │
│  │  - Contacts    - Calls      - Transactions   │ │
│  │  - Notifications            - Advanced       │ │
│  └──────────┬───────────────────────────────────┘ │
│             │                                      │
│  ┌──────────▼───────────────────────────────────┐ │
│  │            CORE SERVICES                      │ │
│  │  - Sync Engine (Real-time)                   │ │
│  │  - Database (Drift/SQLite)                   │ │
│  │  - Networking (Connect/gRPC)                 │ │
│  │  - Crypto (E2EE with Vodozemac)              │ │
│  │  - Storage (Secure & Local)                  │ │
│  └──────────┬───────────────────────────────────┘ │
└─────────────┼────────────────────────────────────┘
              │
              │ HTTPS/gRPC
              ▼
┌─────────────────────────────────────────────────┐
│         BACKEND SERVICES                         │
│  - Gateway Service (WebSocket/Streaming)        │
│  - Default Service (Business Logic)             │
│  - Auth Service (OAuth2/OIDC)                   │
│  - Profile Service (User Management)            │
│  - Device Service (Device Registration)         │
│  - Files Service (Media Upload/Download)        │
└─────────────────────────────────────────────────┘
```

## Application Purpose

The Chat app serves as a comprehensive communication platform that combines:

1. **Real-Time Messaging**: Instant, reliable message delivery across devices
2. **Group Coordination**: Automated credit & savings group management (chamas, ROSCAs)
3. **Financial Features**: Transaction tracking, voting, and motion proposals within groups
4. **Secure Communication**: End-to-end encryption (E2EE) support via Vodozemac
5. **Multi-Device Sync**: Seamless experience across mobile, web, and desktop
6. **Offline-First**: Local database with background synchronization
7. **Rich Media**: Support for text, images, videos, audio, files, and reactions
8. **Voice/Video Calls**: WebRTC-based calling within rooms

## Technology Stack

### Core Technologies
- **Framework**: Flutter 3.9+ (Dart 3.9+)
- **State Management**: Riverpod 3.0 with code generation
- **Navigation**: GoRouter 17.0 with deep linking
- **Database**: Drift 2.30 (SQLite wrapper with type-safe queries)
- **Networking**: Connect (gRPC-compatible protocol over HTTP)
- **Encryption**: flutter_vodozemac 0.4 (Olm/Megolm E2EE)
- **Auth**: OpenID Connect (openid_client 0.4)
- **Calls**: flutter_webrtc 1.2

### Supporting Libraries
- **Storage**: flutter_secure_storage (credentials), path_provider (files)
- **Serialization**: freezed, json_serializable (immutable models)
- **Background Tasks**: workmanager 0.9 (background sync)
- **Push Notifications**: firebase_messaging 16.0
- **Contacts**: flutter_contacts 1.1
- **Media**: image_picker, file_picker
- **Phone Numbers**: libphonenumber_plugin (validation)
- **Deep Links**: app_links 7.0

## Features

### 1. Authentication (`features/auth/`)
**Purpose**: Secure user authentication and session management

**Capabilities**:
- OAuth2/OIDC login flow
- JWT token management with automatic refresh
- Secure credential storage
- Multi-device authentication
- Biometric authentication support (fingerprint, face ID)
- Session persistence across app restarts

**Key Components**:
- `AuthRepository`: Manages authentication state and tokens
- `AuthService`: Handles OAuth flows and token refresh
- Platform-specific implementations (Web vs Mobile/Desktop)

### 2. Messages (`features/messages/`)
**Purpose**: Core messaging functionality with real-time sync

**Capabilities**:
- Send/receive text messages
- Rich media attachments (images, videos, audio, files)
- Message reactions (emoji)
- Reply to messages (threaded conversations)
- Message history with pagination
- Typing indicators
- Read receipts
- Message forwarding
- Local draft messages
- Offline message queuing

**Key Components**:
- `MessageRepository`: Database operations for messages
- `MessageSendingService`: Handles outgoing messages
- `MessageForwardingService`: Forward messages to other rooms
- `ChatScreen`: Main chat UI with message list and input
- `MessageBubble`: Individual message rendering

**Data Model**:
```dart
@freezed
class RoomEvent {
  String id;                    // Unique event ID
  String roomId;                // Room identifier
  String senderId;              // Sender profile ID
  String? senderContactId;      // Sender contact ID
  RoomEventType type;           // text, image, video, audio, file, reaction, call
  Map<String, dynamic> content; // Message payload
  String? parentId;             // Reply-to message ID
  EventStatus status;           // pending, sent, delivered, read, failed
  int createdAt;                // Client timestamp
  int? serverTs;                // Server timestamp
  String? localId;              // Temp ID before server confirmation
}
```

### 3. Rooms (`features/rooms/`)
**Purpose**: Group and direct message room management

**Capabilities**:
- Create private and group rooms
- Search rooms by name/criteria
- Update room metadata (name, description, avatar)
- Delete rooms
- Room member management
- Role-based permissions (admin, moderator, member)
- Room discovery
- Unread message counts
- Last message preview

**Key Components**:
- `RoomRepository`: Room CRUD operations
- `RoomScreen`: Room list and search UI
- `RoomDetailsScreen`: Room settings and members

**Data Model**:
```dart
class Room {
  String id;
  String? name;
  String? type;              // direct, group, channel
  String? lastEventId;
  int? lastEventIndex;
  int unreadCount;
  Map<String, dynamic>? metadata;
}
```

### 4. Contacts (`features/contacts/`)
**Purpose**: Local contact integration and roster management

**Capabilities**:
- Import device contacts
- Phone number validation and formatting
- Contact synchronization with backend
- Search contacts
- Contact verification status
- Blocked users management
- Off-platform contact tracking (email/phone)

**Key Components**:
- `RosterRepository`: Contact roster operations
- `ContactsScreen`: Contact list and search UI
- Phone number normalization (libphonenumber)

**Data Model**:
```dart
class Roster {
  String id;                 // Roster entry ID
  String profileId;          // On-platform profile ID
  String? contactId;         // Contact ID (email/phone hash)
  int contactType;           // 0=email, 1=phone
  String contactDetail;      // Actual email/phone
  bool isVerified;           // Contact verified by user
  String? displayName;       // Custom name
  bool isBlocked;            // Blocked status
  int? syncedAt;
  int? createdAt;
}
```

### 5. Calls (`features/calls/`)
**Purpose**: WebRTC-based voice and video calling

**Capabilities**:
- 1-on-1 voice calls
- 1-on-1 video calls
- In-room calling (future: group calls)
- Call signaling via chat messages
- Call state management
- Screen sharing (desktop)
- Microphone/camera controls

**Key Components**:
- `CallManager`: Manages active calls and WebRTC connections
- `SignalingService`: Handles call signaling (offer/answer/ICE)
- `CallScreen`: Call UI with controls
- WebRTC peer connection management

**Call Flow**:
```
1. User initiates call → Send CALL_OFFER message
2. Recipient receives offer → Show incoming call UI
3. Recipient accepts → Send CALL_ANSWER message
4. ICE candidate exchange → CALL_ICE messages
5. WebRTC connection established → Media streams
6. Call ends → Send CALL_END message
```

### 6. Advanced Features (`features/advanced/`)
**Purpose**: Group automation features (credit & savings)

**Capabilities**:
- **Motions**: Proposals and voting within groups
  - Create motion proposals
  - Vote on motions (yes/no/abstain)
  - Track voting results
  - Automated tallying

- **Transactions**: Financial tracking
  - Record group transactions
  - Transaction history
  - Balance tracking
  - Payment confirmations

**Key Components**:
- `MotionService`: Motion creation and voting
- `TransactionService`: Transaction management
- `MotionBubble`: UI for motion messages
- `TransactionBubble`: UI for transaction messages

**Use Case**: Enable groups (chamas) to propose, vote on, and track financial decisions within chat.

### 7. Notifications (`features/notifications/`)
**Purpose**: Push notifications and in-app alerts

**Capabilities**:
- Firebase Cloud Messaging (FCM) integration
- Background notification handling
- Notification tapping (deep links to rooms)
- Badge count updates
- Notification channels (Android)
- Notification grouping

**Key Components**:
- `NotificationService`: FCM setup and handling
- Background message handler
- Deep link routing

### 8. Onboarding (`features/onboarding/`)
**Purpose**: First-time user experience and setup

**Capabilities**:
- Welcome screens
- Permission requests (contacts, notifications, camera, microphone)
- Initial profile setup
- Feature tutorials

## Core Services

### 1. Sync Engine (`core/sync/`)
**Purpose**: Real-time bidirectional synchronization with backend

**Architecture**:
```dart
class SyncEngine {
  // Bidirectional stream with gateway
  Stream<ServerEvent> connect();

  // Download messages from server
  Future<void> getHistory(String roomId);

  // Upload pending messages
  Future<void> uploadPendingJobs();

  // Connection state tracking
  Stream<SyncConnectionState> get connectionState;
}
```

**Features**:
- WebSocket-like streaming via Connect protocol
- Automatic reconnection with exponential backoff
- Token refresh on 401 errors
- Event deduplication
- Pending job queue for offline operations
- Background synchronization via WorkManager
- Typing event streaming
- Receipt event handling

**Background Sync**:
- `background_sync_task.dart`: WorkManager task for periodic sync
- Runs every 15 minutes when app is backgrounded
- Uploads pending messages and jobs
- Downloads recent room history

**Connection States**:
- `disconnected`: No active connection
- `connecting`: Attempting to connect
- `connected`: Active bidirectional stream

### 2. Database (`core/db/`)
**Purpose**: Local data persistence with Drift (SQLite)

**Schema**:
```dart
// Tables
- Profiles: User profile data
- Roster: Contacts and roster entries
- Rooms: Chat room metadata
- RoomMembers: On-platform room members
- RoomOffPlatformMembers: Off-platform contacts in rooms
- RoomEvents: Messages and events
- Sessions: E2EE session state (Olm)
- Prekeys: E2EE prekeys for new sessions
- OutboxMessages: Pending outgoing messages
```

**Features**:
- Type-safe queries with code generation
- Migration support
- Transaction support
- Reactive streams (watch queries)
- Full-text search
- Efficient indexing

**Database Instance**:
```dart
final db = AppDatabase.instance;
await db.roomEvents.insertOne(event);
final messages = await db.roomEvents.getByRoom(roomId).get();
```

### 3. Networking (`core/networking/`)
**Purpose**: HTTP/gRPC API communication

**Architecture**:
```dart
// Connect clients for each service
final gatewayClient = GatewayServiceClient(http, baseUrl);
final chatClient = ChatServiceClient(http, baseUrl);
final profileClient = ProfileServiceClient(http, baseUrl);
final deviceClient = DeviceServiceClient(http, baseUrl);
final filesClient = FilesServiceClient(http, baseUrl);
```

**Features**:
- Authenticated transport with JWT tokens
- Automatic token refresh interceptor
- Request/response logging
- Error handling and retry logic
- Connection pooling
- gRPC-Web compatible (Connect protocol)

**API Configuration**:
```dart
class ApiConfig {
  static const gatewayUrl = 'https://gateway.example.com';
  static const chatUrl = 'https://chat.example.com';
  static const profileUrl = 'https://profile.example.com';
}
```

### 4. Crypto (`core/crypto/`)
**Purpose**: End-to-end encryption (E2EE) with Vodozemac

**Status**: Currently disabled, planned for future release

**Capabilities (When Enabled)**:
- Olm: 1-on-1 encrypted messaging
- Megolm: Group encrypted messaging
- Key management and rotation
- Session persistence
- Device verification

**Implementation**:
```dart
class E2EEncryptionService {
  // Encrypt outgoing messages
  Future<EncryptedContent> encrypt(String roomId, String plaintext);

  // Decrypt incoming messages
  Future<String> decrypt(String roomId, EncryptedContent ciphertext);

  // Manage E2EE sessions
  Future<void> createSession(String profileId, String deviceId);
}
```

### 5. Storage (`core/storage/`)
**Purpose**: Local file and credential storage

**Types**:
- **Secure Storage**: Credentials, tokens, keys (flutter_secure_storage)
- **Local Storage**: Media files, attachments, cache (path_provider)

**Key Manager**:
```dart
class KeyManager {
  // Device identity
  Future<String> getDeviceId();

  // Secure credential storage
  Future<void> setAccessToken(String token);
  Future<String?> getAccessToken();

  // E2EE keys (when enabled)
  Future<void> saveIdentityKey(Uint8List key);
}
```

## Data Flow

### Sending a Message

```
1. User types message in ChatScreen
   ↓
2. MessageSendingService.sendTextMessage()
   ↓
3. Create RoomEvent with localId (temp ID)
   ↓
4. Save to local DB with status=pending
   ↓
5. UI updates immediately (optimistic update)
   ↓
6. Create PendingJob for background upload
   ↓
7. SyncEngine uploads when connected
   ↓
8. Server returns ack with server-assigned ID
   ↓
9. Update local DB: localId → serverId, status=sent
   ↓
10. UI refreshes with final ID and status
```

### Receiving a Message

```
1. SyncEngine receives ServerEvent from gateway
   ↓
2. Extract RoomEvent from event
   ↓
3. Extract sender ContactLink (profileId, contactId)
   ↓
4. Extract typed content (text, attachment, etc.)
   ↓
5. Map to domain RoomEvent model
   ↓
6. Save to local DB with status=delivered
   ↓
7. Notify UI via Riverpod state update
   ↓
8. ChatScreen rebuilds with new message
   ↓
9. Send read receipt (when message is visible)
```

## State Management (Riverpod)

### Providers Structure

```dart
// Auth state
final authRepositoryProvider = Provider<AuthRepository>(...);
final currentUserProvider = FutureProvider<Profile?>(...);

// Messaging
final messageRepositoryProvider = Provider<MessageRepository>(...);
final roomMessagesProvider = StreamProvider.family<List<RoomEvent>, String>(...);

// Rooms
final roomRepositoryProvider = Provider<RoomRepository>(...);
final roomsProvider = StreamProvider<List<Room>>(...);

// Sync
final syncEngineProvider = FutureProvider<SyncEngine>(...);
final connectionStateProvider = StreamProvider<SyncConnectionState>(...);

// UI state
final selectedRoomProvider = StateProvider<String?>(...);
final typingUsersProvider = StateNotifierProvider.family<Set<String>, String>(...);
```

### Code Generation

Riverpod uses code generation for type safety:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Navigation (GoRouter)

### Route Structure

```dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => HomeScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => OnboardingScreen()),
    GoRoute(path: '/rooms', builder: (_, __) => RoomsScreen()),
    GoRoute(
      path: '/room/:roomId',
      builder: (_, state) => ChatScreen(roomId: state.params['roomId']!),
    ),
    GoRoute(path: '/contacts', builder: (_, __) => ContactsScreen()),
    GoRoute(path: '/settings', builder: (_, __) => SettingsScreen()),
  ],
  redirect: (context, state) {
    // Auth guard: redirect to login if not authenticated
    final isAuthenticated = /* check auth state */;
    if (!isAuthenticated) return '/onboarding';
    return null;
  },
);
```

### Deep Links

App links configuration for opening rooms from notifications:
```
chat://room/{roomId}
https://chat.example.com/room/{roomId}
```

## UI/UX

### Design System
- **Material Design 3**: Modern, adaptive UI
- **Theme**: Light and dark mode support
- **Responsive**: Adapts to phone, tablet, desktop
- **Accessibility**: Screen reader support, sufficient contrast

### Key Screens

1. **HomeScreen**: App entry point with bottom navigation
2. **RoomsScreen**: List of rooms with search and unread counts
3. **ChatScreen**: Main messaging UI
   - Message list (reverse scrolling)
   - Text input with emoji picker
   - Attachment button (camera, gallery, files)
   - Reply UI for threaded messages
4. **ContactsScreen**: Contact list with import and search
5. **CallScreen**: Active call UI with controls
6. **SettingsScreen**: App settings and profile management

### Message Bubble Rendering

```dart
// Different bubble types based on message type
MessageBubble(
  event: roomEvent,
  isMine: event.senderId == currentUserId,
  showSenderName: isGroupChat,
  showAvatar: isGroupChat,
  onReply: () => setReplyTo(event),
  onReact: () => showReactionPicker(event),
)

// Specialized bubbles
if (event.type == RoomEventType.motion) {
  return MotionBubble(event: event);
} else if (event.type == RoomEventType.transaction) {
  return TransactionBubble(event: event);
}
```

## Platform Support

### Mobile (iOS & Android)
- Push notifications (FCM)
- Contact access
- Camera and gallery access
- Biometric authentication
- Background sync (WorkManager)

### Web
- Progressive Web App (PWA)
- OAuth redirect flow
- IndexedDB for storage
- Service workers for notifications

### Desktop (macOS, Linux, Windows)
- Native window management
- System tray integration
- Desktop notifications
- File system access

## Configuration

### Environment Variables

Set via build args or runtime config:
```bash
# API endpoints
GATEWAY_URL=https://gateway.example.com
CHAT_URL=https://chat.example.com
PROFILE_URL=https://profile.example.com

# OAuth
OAUTH2_ISSUER=https://auth.example.com
OAUTH2_CLIENT_ID=chat_mobile
```

### Build Configurations

```bash
# Development
flutter run --dart-define=ENV=dev

# Staging
flutter run --dart-define=ENV=staging

# Production
flutter run --dart-define=ENV=production
```

## Development

### Prerequisites
- Flutter SDK 3.9+
- Dart SDK 3.9+
- Android Studio / Xcode (for mobile)
- VS Code or Android Studio

### Setup

```bash
# Clone repository
git clone https://github.com/antinvestor/chat.git
cd chat

# Install dependencies
flutter pub get

# Run code generation
flutter pub run build_runner build --delete-conflicting-outputs

# Run on device/simulator
flutter run

# Run on specific platform
flutter run -d chrome           # Web
flutter run -d macos            # macOS
flutter run -d android          # Android
flutter run -d ios              # iOS
```

### Code Generation

Required for:
- Riverpod providers
- Freezed models
- JSON serialization
- Drift database

```bash
# Watch mode (auto-rebuild on file changes)
flutter pub run build_runner watch

# One-time build
flutter pub run build_runner build --delete-conflicting-outputs
```

### Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/
```

## Build & Deployment

### Android

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Release App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS

```bash
# Debug build
flutter build ios --debug

# Release build
flutter build ios --release

# Then open in Xcode to archive and upload to App Store
```

### Web

```bash
# Build for web
flutter build web --release

# Deploy to hosting
# Output is in build/web/
```

### Desktop

```bash
# macOS
flutter build macos --release

# Linux
flutter build linux --release

# Windows
flutter build windows --release
```

## Performance

### Optimizations
- **Lazy Loading**: Message history loaded on demand
- **Image Caching**: Cached network images
- **List Virtualization**: Efficient scrolling for long message lists
- **Incremental Builds**: Drift queries are compiled
- **Worker Isolates**: Heavy operations (crypto) in separate isolates

### Memory Management
- Message pagination (50 messages at a time)
- Image compression for uploads
- Database vacuuming
- Cache size limits

## Security

### Authentication
- OAuth2/OIDC login
- JWT access tokens (short-lived)
- Refresh tokens (long-lived, stored securely)
- Biometric login support

### Data Protection
- Secure storage for credentials (flutter_secure_storage)
- TLS for all network communication
- Optional E2EE for messages (Vodozemac)
- No plaintext credential logging

### Privacy
- Contact permission required
- No automatic contact upload without consent
- User can control blocked contacts
- Local data deletion on logout

## Troubleshooting

### Common Issues

1. **Build runner fails**: Delete generated files and rebuild
   ```bash
   flutter clean
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Database migration errors**: Clear app data or uninstall/reinstall

3. **Push notifications not working**: Check FCM configuration and permissions

4. **WebRTC calls failing**: Verify STUN/TURN server configuration

## Agent Workflow Guidelines

### Reference Files

Before acting on any task, agents should always reference:

1. **CLAUDE.md (This File - Required)**: Contains project-specific instructions, architecture, technology stack, feature documentation, code patterns, and development setup
2. **Agents.md (Required)**: Comprehensive multi-agent development practices including:
   - Branch strategy (trunk-based development with worktrees)
   - Issue workflow (states, commands)
   - Pull request process (templates, size guidelines, review feedback policy)
   - Quality gates (pre-merge requirements)
   - Code review guidelines (for authors and reviewers)
   - Testing requirements (unit 80%, widget 70% coverage targets)
   - CI/CD pipeline (lint, test, build stages)
   - Sprint execution (structure, priority order)
   - Communication protocols (commit message format)
3. **agents.md**: Simplified workflow guidelines for concurrent task management

### Concurrent Task Management

When working on multiple tasks (features, bug fixes, PRs), agents should:

#### Task Limits
- **Work on 3-5 tasks concurrently** - This ensures focused attention while maximizing throughput
- Never exceed 5 concurrent tasks to maintain quality and avoid context switching overhead
- Prioritize completing existing tasks before starting new ones

#### Git Worktrees
- **Always use git worktrees** for concurrent development
- Each task/feature branch should have its own worktree
- Worktrees provide isolated working directories that share the same git repository

#### Worktree Structure
```
/home/j/code/antinvestor/chat                    # Main worktree (main branch)
/home/j/code/antinvestor/sprint1-worktrees/      # Sprint 1 feature worktrees
/home/j/code/antinvestor/sprint2-worktrees/      # Sprint 2 feature worktrees
```

#### Worktree Commands
```bash
# List all worktrees
git worktree list

# Add a new worktree for a feature branch
git worktree add ../sprint-worktrees/feature-name feature/FEATURE-001

# Remove a worktree when done
git worktree remove ../sprint-worktrees/feature-name
```

#### Benefits of Worktrees
1. **Isolation** - Each feature has its own directory, avoiding conflicts
2. **Parallel work** - Run tests, builds, or development in multiple features simultaneously
3. **Clean context switching** - No need to stash changes when switching tasks
4. **Shared history** - All worktrees share the same git objects and references

### PR Workflow with Worktrees

1. Create/checkout worktree for the feature branch
2. Make changes in the worktree directory
3. Run tests and formatting in the worktree
4. Commit and push from the worktree
5. Create/update PR
6. After merge, remove the worktree

### Auto-merge Strategy

- Enable auto-merge for PRs that pass all CI checks
- Only enable auto-merge after confirming:
  - All tests pass
  - All formatting checks pass
  - All review feedback is addressed

### Review Feedback Policy (CRITICAL)

All PR review feedback must be addressed before proceeding to work on other issues:
- Prevents accumulation of unresolved issues
- Ensures code quality before moving forward
- Maintains clean PR history
- Avoids context-switching overhead later

**When to proceed to next issue:**
- All review comments marked as resolved
- No pending "Changes Requested" status
- CI checks passing
- PR merged OR explicitly paused with documented reason

### Quality Gates

All PRs must pass these gates before merging:
- `dart format .` produces no changes
- `flutter analyze` has no errors or warnings
- `flutter test` passes all tests
- Test coverage >= 70%
- No TODO comments without issue references
- No commented-out code
- No debug print statements
- API keys/secrets not hardcoded

### Definition of Done

A feature is "done" when:
- Code implemented and self-reviewed
- Unit tests written (>80% coverage for new code)
- Widget tests for new UI components
- All CI checks pass
- PR approved by reviewer
- No unresolved comments
- Documentation updated (if applicable)
- Issue closed via PR merge

## Future Enhancements

- [ ] End-to-end encryption (E2EE) enabled by default
- [ ] Group voice/video calls
- [ ] Message search across all rooms
- [ ] Voice messages
- [ ] Message editing
- [ ] Message pinning
- [ ] Custom emoji reactions
- [ ] Polls and surveys
- [ ] Location sharing
- [ ] Calendar integration for group events
- [ ] Advanced group admin controls
- [ ] Message translation
- [ ] GIF support

## License

Proprietary - Antinvestor

## Support

For issues, questions, or feature requests, contact the Antinvestor platform team.

---

**Last Updated**: January 2026
**Flutter Version**: 3.9+
**Minimum iOS**: 12.0
**Minimum Android**: 21 (Android 5.0)
