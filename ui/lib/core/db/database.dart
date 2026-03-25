import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:sqlite3/common.dart' show SqliteException;

part 'database.g.dart';

// Table definitions

/// User profile information stored locally
///
/// Contains basic profile data synced from the server including
/// display name, avatar, and metadata.
///
/// Example:
/// ```dart
/// final profile = await db.profiles.select().getSingle();
/// print(profile.name);
/// ```
class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  IntColumn get updatedAt => integer().nullable()();
  TextColumn get metadata => text().nullable()();

  /// User's presence status (0=offline, 1=online, 2=away, 3=busy, 4=doNotDisturb)
  IntColumn get status => integer().withDefault(const Constant(0))();

  /// Custom status message (e.g., "In a meeting", "On vacation")
  TextColumn get statusMessage => text().nullable()();

  /// Timestamp when status was last updated
  IntColumn get statusUpdatedAt => integer().nullable()();

  /// User's bio/about text
  TextColumn get bio => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Roster table stores contact information with stable local IDs and separate server roster IDs.
/// - id: Stable local UUID identifier (never changes)
/// - rosterId: Server roster entry identifier (synced from server, nullable)
/// - profileId: Foreign key to profiles table (nullable - null if user hasn't logged in)
/// - contactId: Contact's unique identifier from server (available after successful sync)
/// - contactDetail: Email/phone number as stored locally for display
class Roster extends Table {
  TextColumn get id => text()(); // Stable local UUID
  TextColumn get rosterId =>
      text().nullable()(); // Server roster entry ID (synced)
  TextColumn get profileId =>
      text().nullable()(); // Null if user hasn't logged in yet
  TextColumn get contactId =>
      text().nullable()(); // Contact's unique ID from server
  IntColumn get contactType => integer().withDefault(const Constant(0))();
  TextColumn get contactDetail => text()();
  BoolColumn get isVerified => boolean().withDefault(const Constant(false))();
  TextColumn get displayName => text().nullable()();
  BoolColumn get isBlocked => boolean().withDefault(const Constant(false))();
  IntColumn get syncedAt => integer().nullable()();
  IntColumn get createdAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Chat room table storing room metadata and state
///
/// Rooms can be direct messages (1:1) or group chats.
/// Tracks last event for sync and unread message counts.
///
/// Example:
/// ```dart
/// final rooms = await db.rooms.select().get();
/// for (final room in rooms) {
///   print('${room.name}: ${room.unreadCount} unread');
/// }
/// ```
class Rooms extends Table {
  /// Unique room identifier from server
  TextColumn get id => text()();

  /// Display name for the room (null for direct messages)
  TextColumn get name => text().nullable()();

  /// Room type: 'direct', 'group', or 'channel'
  TextColumn get type => text().nullable()();

  /// ID of the last event received in this room
  TextColumn get lastEventId => text().nullable()();

  /// Index of the last event for ordering
  IntColumn get lastEventIndex => integer().nullable()();

  /// Count of unread messages in this room
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();

  /// JSON-encoded room metadata (avatar, description, etc.)
  TextColumn get metadata => text().nullable()();

  /// Disappearing messages timeout in seconds (null = disabled)
  /// Supported values: null (off), 86400 (24h), 604800 (7d), 7776000 (90d)
  IntColumn get disappearingTimeout => integer().nullable()();

  /// Mute notifications until this epoch timestamp (null = not muted)
  IntColumn get mutedUntil => integer().nullable()();

  /// Maximum number of members allowed in this room (null = default 256)
  IntColumn get memberLimit => integer().nullable()();

  /// Whether member limit is enforced (only applicable for groups)
  BoolColumn get memberLimitEnabled =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Room subscriptions table - represents a profile's presence in a room
/// Uses subscription ID from API as primary key (room-specific presence)
///
/// ID Types Clarified:
/// - id: Room-specific presence/subscription ID (primary key) - UNIQUE per room per profile
/// - profileId: Global profile identity (from JWT 'sub' claim) - SAME across all rooms for user
///           - Can be null initially for anonymous/provisional subscriptions
///           - Can be updated later when user identity is established
/// - contactId: Contact method used (phone, email, etc.) - HOW the profile was reached
/// - roomId: Room identifier - WHICH room the subscription belongs to
class RoomSubscriptions extends Table {
  TextColumn get id => text()(); // Primary key from API
  TextColumn get roomId => text().references(Rooms, #id)();
  TextColumn get profileId => text()
      .nullable()(); // Global profile identity (from JWT) - nullable for anonymous subscriptions
  TextColumn get contactId =>
      text().nullable()(); // Contact method (phone/email/etc)
  TextColumn get role => text().nullable()();
  IntColumn get joinedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Messages and events within chat rooms
///
/// Stores all types of room events including text messages, media,
/// reactions, calls, and system events. Events are ordered by server
/// timestamp for consistent ordering across devices.
///
/// Example:
/// ```dart
/// final messages = await (db.roomEvents.select()
///   ..where((e) => e.roomId.equals(roomId))
///   ..orderBy([(e) => OrderingTerm.desc(e.serverTs)])
/// ).get();
/// ```
class RoomEvents extends Table {
  /// Unique event identifier (server-assigned or local UUID)
  TextColumn get id => text()();

  /// Room this event belongs to (foreign key)
  TextColumn get roomId => text().references(Rooms, #id)();

  /// Subscription ID of the sender (room-specific identifier)
  /// Use RoomSubscriptions table to look up the profile ID from this subscription ID
  TextColumn get senderId => text()();

  /// Contact ID of the sender (nullable, for additional context)
  TextColumn get senderContactId => text().nullable()();

  /// Event type as integer (text=0, image=1, video=2, etc.)
  IntColumn get type => integer()();

  /// JSON-encoded event content (message text, attachment info, etc.)
  TextColumn get content => text().nullable()();

  /// Parent event ID for replies/threads
  TextColumn get parentId => text().nullable()();

  /// Event status (pending=0, sent=1, delivered=2, read=3, failed=4)
  IntColumn get status => integer().withDefault(const Constant(0))();

  /// Client-side creation timestamp
  IntColumn get createdAt => integer().nullable()();

  /// Server-assigned timestamp for consistent ordering
  IntColumn get serverTs => integer().nullable()();

  /// Temporary local ID before server confirmation
  TextColumn get localId => text().nullable()();

  /// Timestamp when message was last edited (null if never edited)
  IntColumn get editedAt => integer().nullable()();

  /// Original message content before editing (preserved for history)
  TextColumn get originalContent => text().nullable()();

  /// Whether the message has been deleted/redacted
  BoolColumn get redacted => boolean().withDefault(const Constant(false))();

  /// Timestamp when message was redacted
  IntColumn get redactedAt => integer().nullable()();

  /// Profile ID of who redacted the message (for admin deletions)
  TextColumn get redactedBy => text().nullable()();

  /// Number of retry attempts for failed messages
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Error message if send failed
  TextColumn get errorMessage => text().nullable()();

  /// Room ID this message was forwarded from (null if not forwarded)
  TextColumn get forwardedFromRoom => text().nullable()();

  /// Event ID this message was forwarded from (null if not forwarded)
  TextColumn get forwardedFromEvent => text().nullable()();

  /// Number of times this message has been forwarded
  IntColumn get forwardCount => integer().withDefault(const Constant(0))();

  /// Whether this message is restricted from being forwarded
  BoolColumn get forwardRestricted =>
      boolean().withDefault(const Constant(false))();

  /// Timestamp when this message should be deleted (for disappearing messages)
  /// Null means the message does not expire
  IntColumn get expiresAt => integer().nullable()();

  /// Whether this message is starred/bookmarked by the user
  BoolColumn get starred => boolean().withDefault(const Constant(false))();

  /// Timestamp when the message was starred (for sorting starred messages)
  IntColumn get starredAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// End-to-end encryption sessions for secure messaging
///
/// Stores Olm/Megolm session state for encrypted communication.
/// Each session represents a cryptographic channel with a specific
/// user device pair.
///
/// Example:
/// ```dart
/// final session = await db.sessions.select()
///   .where((s) => s.profileId.equals(userId))
///   .getSingleOrNull();
/// ```
class Sessions extends Table {
  /// Unique session identifier
  TextColumn get sessionId => text()();

  /// Profile ID of the session peer
  TextColumn get profileId => text()();

  /// Device ID of the session peer
  TextColumn get deviceId => text()();

  /// Serialized ratchet state for session continuity
  BlobColumn get ratchetState => blob().nullable()();

  /// Session creation timestamp
  IntColumn get createdAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {sessionId};
}

/// Pre-keys for establishing encrypted sessions
///
/// Stores asymmetric key pairs used in the Double Ratchet algorithm
/// for initiating new encrypted sessions with other users.
///
/// Example:
/// ```dart
/// final prekeys = await db.prekeys.select().get();
/// final signedKey = prekeys.firstWhere((k) => k.isSigned);
/// ```
class Prekeys extends Table {
  /// Auto-incrementing prekey identifier
  IntColumn get id => integer().autoIncrement()();

  /// Base64-encoded public key for sharing
  TextColumn get publicKey => text().nullable()();

  /// Base64-encoded private key (securely stored)
  TextColumn get privateKey => text().nullable()();

  /// Whether this is a signed prekey (identity verification)
  BoolColumn get isSigned => boolean().withDefault(const Constant(false))();
}

/// Queue of pending operations for offline-first support
///
/// Stores operations that need to be synced with the server,
/// including message sends, reads, and other actions performed
/// while offline.
///
/// Example:
/// ```dart
/// final pendingCount = await db.pendingJobs.count()
///   .where((j) => j.status.equals('pending'))
///   .getSingle();
/// ```
class PendingJobs extends Table {
  /// Auto-incrementing job identifier
  IntColumn get id => integer().autoIncrement()();

  /// Job type identifier (e.g., 'send_message', 'mark_read')
  TextColumn get type => text()();

  /// JSON-encoded job payload with operation details
  TextColumn get payload => text().nullable()();

  /// Job creation timestamp
  IntColumn get createdAt => integer().nullable()();

  /// Number of retry attempts made
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Job status: 'pending', 'processing', 'completed', 'failed'
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Earliest time this job can be retried (for exponential backoff)
  /// Null means job can be processed immediately
  IntColumn get nextRetryAt => integer().nullable()();

  /// Job priority level (0=critical, 1=high, 2=normal, 3=low)
  /// Lower values are processed first
  IntColumn get priority => integer().withDefault(const Constant(2))();

  /// JSON-encoded last error information for debugging
  /// Contains error message, code, and timestamp
  TextColumn get lastError => text().nullable()();
}

/// Financial transactions within group savings (chama) rooms
///
/// Tracks monetary transactions including contributions, withdrawals,
/// and payments within credit and savings groups.
///
/// Example:
/// ```dart
/// final transactions = await (db.transactions.select()
///   ..where((t) => t.roomId.equals(roomId))
/// ).get();
/// final total = transactions.fold(0.0, (sum, t) => sum + double.parse(t.amount ?? '0'));
/// ```
class Transactions extends Table {
  /// Unique transaction identifier
  TextColumn get id => text()();

  /// Room this transaction belongs to (foreign key)
  TextColumn get roomId => text().references(Rooms, #id)();

  /// Transaction amount as decimal string
  TextColumn get amount => text().nullable()();

  /// Currency code (e.g., 'KES', 'USD')
  TextColumn get currency => text().nullable()();

  /// Transaction status: 'pending', 'completed', 'cancelled'
  TextColumn get status => text().nullable()();

  /// Profile ID of the transaction initiator
  TextColumn get initiatorId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Key-value store for sync state and metadata
///
/// Tracks synchronization state including last sync timestamps,
/// cursor positions, and other sync-related metadata.
///
/// Example:
/// ```dart
/// final lastSync = await db.syncMetadata.select()
///   .where((m) => m.key.equals('last_sync_timestamp'))
///   .getSingleOrNull();
/// ```
class SyncMetadata extends Table {
  /// Unique key identifier
  TextColumn get key => text()();

  /// Stored value (can be JSON for complex data)
  TextColumn get value => text().nullable()();

  /// Last update timestamp
  IntColumn get updatedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

/// User settings persistence table
///
/// Stores all user preferences as key-value pairs with timestamps.
/// Settings are loaded on app startup and cached in memory.
///
/// Example:
/// ```dart
/// final theme = await db.userSettings.select()
///   .where((s) => s.key.equals('theme_mode'))
///   .getSingleOrNull();
/// ```
class UserSettings extends Table {
  /// Setting key (e.g., 'theme_mode', 'font_size')
  TextColumn get key => text()();

  /// Setting value (stored as string, can be JSON for complex values)
  TextColumn get value => text()();

  /// Last update timestamp (milliseconds since epoch)
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Draft messages persistence table
///
/// Stores unsent message drafts for each room, allowing users to continue
/// composing messages after navigating away or restarting the app.
///
/// Example:
/// ```dart
/// final draft = await db.drafts.select()
///   .where((d) => d.roomId.equals(roomId))
///   .getSingleOrNull();
/// if (draft != null) {
///   textController.text = draft.content;
/// }
/// ```
class Drafts extends Table {
  /// Room ID this draft belongs to (primary key)
  TextColumn get roomId => text()();

  /// Draft message content
  TextColumn get content => text()();

  /// Optional parent message ID for reply drafts
  TextColumn get replyToId => text().nullable()();

  /// Last update timestamp (milliseconds since epoch)
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {roomId};
}

/// Read receipts for tracking who has read messages in group chats
///
/// Stores individual read events for messages, allowing the UI to
/// display "seen by X, Y, and Z" in groups with timestamps.
///
/// Example:
/// ```dart
/// final readers = await (db.readReceipts.select()
///   ..where((r) => r.eventId.equals(messageId))
///   ..orderBy([(r) => OrderingTerm.desc(r.readAt)])
/// ).get();
/// ```
class ReadReceipts extends Table {
  /// Auto-incrementing primary key
  IntColumn get id => integer().autoIncrement()();

  /// Event/message ID that was read
  TextColumn get eventId => text()();

  /// Room ID for efficient querying
  TextColumn get roomId => text()();

  /// Profile ID of the reader
  TextColumn get profileId => text()();

  /// Timestamp when the message was read (milliseconds since epoch)
  IntColumn get readAt => integer()();
}

/// User reports for abuse/spam/harassment
///
/// Stores reports submitted by users about other users.
/// Reports are sent to the backend for review and action.
///
/// Example:
/// ```dart
/// final reports = await db.reports.select().get();
/// ```
class Reports extends Table {
  /// Unique report identifier
  TextColumn get id => text()();

  /// Profile ID of the user being reported
  TextColumn get reportedUserId => text()();

  /// Report reason category (spam, harassment, inappropriate_content, other)
  TextColumn get reason => text()();

  /// Additional details provided by the reporter
  TextColumn get details => text().nullable()();

  /// JSON array of event IDs used as evidence
  TextColumn get evidenceEventIds => text().nullable()();

  /// Timestamp when the report was created (milliseconds since epoch)
  IntColumn get reportedAt => integer()();

  /// Report status: pending, reviewed, resolved, dismissed
  TextColumn get status => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Invite links for group room joining
///
/// Stores shareable invite links that allow users to join rooms
/// via a unique code. Links can have expiration times, max uses,
/// and can be revoked by admins.
///
/// Example:
/// ```dart
/// final link = await db.inviteLinks.select()
///   .where((l) => l.code.equals('abc123'))
///   .getSingleOrNull();
/// if (link != null && !link.revoked) {
///   // Process invite
/// }
/// ```
class InviteLinks extends Table {
  /// Unique invite link identifier
  TextColumn get id => text()();

  /// Room this invite links to (foreign key)
  TextColumn get roomId => text().references(Rooms, #id)();

  /// Unique invite code for URL (e.g., chat.app/join/{code})
  TextColumn get code => text().unique()();

  /// Profile ID of the user who created this link
  TextColumn get createdBy => text()();

  /// Creation timestamp (milliseconds since epoch)
  IntColumn get createdAt => integer()();

  /// Optional expiration timestamp (milliseconds since epoch, null = never expires)
  IntColumn get expiresAt => integer().nullable()();

  /// Optional maximum number of uses (null = unlimited)
  IntColumn get maxUses => integer().nullable()();

  /// Current number of times this link has been used
  IntColumn get useCount => integer().withDefault(const Constant(0))();

  /// Whether this link has been revoked by an admin
  BoolColumn get revoked => boolean().withDefault(const Constant(false))();

  /// Whether joining via this link requires admin approval
  BoolColumn get requiresApproval =>
      boolean().withDefault(const Constant(false))();

  /// Optional custom name/label for the link
  TextColumn get name => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tracks users who joined via invite links
///
/// Records each use of an invite link for analytics and
/// "see who joined" functionality.
///
/// Example:
/// ```dart
/// final joins = await (db.inviteLinkJoins.select()
///   ..where((j) => j.inviteLinkId.equals(linkId))
/// ).get();
/// ```
class InviteLinkJoins extends Table {
  /// Auto-incrementing primary key
  IntColumn get id => integer().autoIncrement()();

  /// The invite link that was used
  TextColumn get inviteLinkId => text().references(InviteLinks, #id)();

  /// Profile ID of the user who joined
  TextColumn get profileId => text()();

  /// Timestamp when the user joined (milliseconds since epoch)
  IntColumn get joinedAt => integer()();

  /// Approval status: 'approved', 'pending', 'rejected'
  TextColumn get status => text().withDefault(const Constant('approved'))();
}

/// Tracks chunk progress for resumable uploads
///
/// Stores upload state to allow resuming interrupted uploads.
/// Each chunk is recorded separately for precise resume points.
///
/// Example:
/// ```dart
/// final chunks = await (db.uploadChunks.select()
///   ..where((c) => c.localId.equals(messageLocalId))
///   ..orderBy([(c) => OrderingTerm.asc(c.chunkIndex)])
/// ).get();
/// ```
class UploadChunks extends Table {
  /// Auto-incrementing primary key
  IntColumn get id => integer().autoIncrement()();

  /// Local message ID this upload is associated with
  TextColumn get localId => text()();

  /// Server-assigned upload ID for resumable uploads
  TextColumn get uploadId => text().nullable()();

  /// Index of this chunk (0-based, -1 for metadata row)
  IntColumn get chunkIndex => integer().withDefault(const Constant(-1))();

  /// Size of this chunk in bytes
  IntColumn get chunkSize => integer().withDefault(const Constant(0))();

  /// Timestamp when this chunk was uploaded (milliseconds since epoch)
  IntColumn get createdAt => integer()();
}

/// Tracks chunk progress for resumable downloads
///
/// Stores download state to allow resuming interrupted downloads.
/// Each chunk is recorded separately for precise resume points.
///
/// Example:
/// ```dart
/// final chunks = await (db.downloadChunks.select()
///   ..where((c) => c.downloadId.equals(downloadId))
///   ..orderBy([(c) => OrderingTerm.asc(c.chunkIndex)])
/// ).get();
/// ```
class DownloadChunks extends Table {
  /// Auto-incrementing primary key
  IntColumn get id => integer().autoIncrement()();

  /// Unique download identifier for tracking
  TextColumn get downloadId => text()();

  /// Remote file URL being downloaded
  TextColumn get fileUrl => text()();

  /// Local file path where download is being saved
  TextColumn get localPath => text()();

  /// Total file size in bytes
  IntColumn get totalSize => integer()();

  /// Index of this chunk (0-based, -1 for metadata row)
  IntColumn get chunkIndex => integer().withDefault(const Constant(-1))();

  /// Size of this chunk in bytes
  IntColumn get chunkSize => integer().withDefault(const Constant(0))();

  /// Bytes downloaded for this chunk
  IntColumn get bytesDownloaded => integer().withDefault(const Constant(0))();

  /// ETag for HTTP caching and resume validation
  TextColumn get etag => text().nullable()();

  /// Timestamp when this chunk was created (milliseconds since epoch)
  IntColumn get createdAt => integer()();

  /// Timestamp when this chunk was last updated
  IntColumn get updatedAt => integer().nullable()();
}

/// Transfer jobs table for unified upload/download queue management
///
/// Stores both upload and download jobs in a single queue with priority ordering.
/// Uploads are typically given higher priority than downloads.
///
/// Example:
/// ```dart
/// final pendingJobs = await (db.transferJobs.select()
///   ..where((t) => t.status.equals('pending'))
///   ..orderBy([
///     (t) => OrderingTerm.asc(t.priority),
///     (t) => OrderingTerm.asc(t.createdAt),
///   ])
/// ).get();
/// ```
class TransferJobs extends Table {
  /// Auto-incrementing primary key
  IntColumn get id => integer().autoIncrement()();

  /// Transfer type: 'upload' or 'download'
  TextColumn get transferType => text()();

  /// Reference ID (localId for uploads, downloadId for downloads)
  TextColumn get referenceId => text()();

  /// Room ID associated with this transfer
  TextColumn get roomId => text()();

  /// File URL (destination for uploads, source for downloads)
  TextColumn get fileUrl => text()();

  /// Local file path (source for uploads, destination for downloads)
  TextColumn get localPath => text()();

  /// File name for display purposes
  TextColumn get fileName => text()();

  /// Total file size in bytes
  IntColumn get totalSize => integer()();

  /// Bytes transferred so far
  IntColumn get transferredSize => integer().withDefault(const Constant(0))();

  /// MIME type of the file
  TextColumn get mimeType => text().nullable()();

  /// Priority level (0=critical, 1=high, 2=normal, 3=low)
  /// Uploads default to priority 1, downloads to priority 2
  IntColumn get priority => integer().withDefault(const Constant(2))();

  /// Job status: 'pending', 'active', 'paused', 'completed', 'failed'
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Number of retry attempts
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Last error message if failed
  TextColumn get lastError => text().nullable()();

  /// Timestamp when job was created (milliseconds since epoch)
  IntColumn get createdAt => integer()();

  /// Timestamp when job was last updated
  IntColumn get updatedAt => integer().nullable()();

  /// Earliest time this job can be retried (for exponential backoff)
  IntColumn get nextRetryAt => integer().nullable()();
}

/// Analytics events table for local event storage
///
/// Stores analytics events locally before batch upload to backend.
/// Events are marked as synced after successful upload.
///
/// Example:
/// ```dart
/// final pendingEvents = await (db.analyticsEvents.select()
///   ..where((t) => t.isSynced.equals(false))
/// ).get();
/// ```
class AnalyticsEvents extends Table {
  /// Auto-incrementing primary key
  IntColumn get id => integer().autoIncrement()();

  /// Unique event identifier (UUID)
  TextColumn get eventId => text()();

  /// Event type (e.g., 'screen_view', 'message_sent')
  TextColumn get eventType => text()();

  /// Event name for custom events
  TextColumn get eventName => text()();

  /// User ID associated with the event (nullable for anonymous)
  TextColumn get userId => text().nullable()();

  /// Session ID for grouping events
  TextColumn get sessionId => text().nullable()();

  /// Screen name where event occurred
  TextColumn get screenName => text().nullable()();

  /// JSON-encoded event properties
  TextColumn get properties => text().nullable()();

  /// Timestamp when event occurred (milliseconds since epoch)
  IntColumn get timestamp => integer()();

  /// Whether the event has been synced to backend
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Timestamp when event was synced
  IntColumn get syncedAt => integer().nullable()();
}

/// Call history table storing records of voice and video calls
///
/// Tracks all calls made or received, including duration, type,
/// and outcome (answered, missed, declined).
///
/// Example:
/// ```dart
/// final history = await db.callHistory.select()
///   ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
///   ..limit(50)
/// ).get();
/// ```
class CallHistory extends Table {
  /// Auto-incrementing primary key
  IntColumn get id => integer().autoIncrement()();

  /// Room ID where the call occurred
  TextColumn get roomId => text()();

  /// Profile ID of the caller (who initiated the call)
  TextColumn get callerId => text()();

  /// Profile ID of the recipient (who received the call)
  TextColumn get recipientId => text().nullable()();

  /// Call type: 0=audio, 1=video
  IntColumn get callType => integer().withDefault(const Constant(0))();

  /// Call direction: 0=outgoing, 1=incoming
  IntColumn get direction => integer().withDefault(const Constant(0))();

  /// Call status: 0=missed, 1=answered, 2=declined, 3=busy, 4=failed
  IntColumn get status => integer().withDefault(const Constant(0))();

  /// Timestamp when call started (milliseconds since epoch)
  IntColumn get startedAt => integer()();

  /// Timestamp when call was answered (milliseconds since epoch)
  IntColumn get answeredAt => integer().nullable()();

  /// Timestamp when call ended (milliseconds since epoch)
  IntColumn get endedAt => integer().nullable()();

  /// Duration of the call in seconds (0 if not answered)
  IntColumn get duration => integer().withDefault(const Constant(0))();

  /// Whether this entry has been read/seen by the user
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  /// Whether the call has been deleted by the user
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

/// Main application database using Drift (SQLite)
///
/// Provides type-safe access to all local data including profiles,
/// rooms, messages, contacts, and sync state. Uses a singleton pattern
/// for consistent database access across the app.
///
/// Example:
/// ```dart
/// final db = AppDatabase.instance;
/// final rooms = await db.rooms.select().get();
/// ```
@DriftDatabase(
  tables: [
    Profiles,
    Roster,
    Rooms,
    RoomSubscriptions,
    RoomEvents,
    Sessions,
    Prekeys,
    PendingJobs,
    Transactions,
    SyncMetadata,
    UserSettings,
    Drafts,
    ReadReceipts,
    Reports,
    InviteLinks,
    InviteLinkJoins,
    UploadChunks,
    DownloadChunks,
    TransferJobs,
    CallHistory,
    AnalyticsEvents,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  /// Constructor for testing with custom executor (e.g., in-memory database)
  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  static final AppDatabase instance = AppDatabase._();

  @override
  int get schemaVersion => 18;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // Create FTS5 virtual table for message search on new databases
      // Uses IF NOT EXISTS for idempotency
      await _createFtsTable();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from <= 1) {
        // Migration from v1 to v2: Add rosterId column and convert existing IDs to stable local UUIDs
        // For now, we'll handle this in beforeOpen instead
      }
      if (from <= 2) {
        // Migration from v2 to v3: Add message editing columns
        await m.addColumn(roomEvents, roomEvents.editedAt);
        await m.addColumn(roomEvents, roomEvents.originalContent);
      }
      if (from <= 3) {
        // Migration from v3 to v4: Add message deletion columns
        await m.addColumn(roomEvents, roomEvents.redacted);
        await m.addColumn(roomEvents, roomEvents.redactedAt);
        await m.addColumn(roomEvents, roomEvents.redactedBy);
      }
      if (from <= 4) {
        // Migration from v4 to v5: Add FTS5 for full-text message search
        await _createFtsTable();
        // Populate FTS index with existing text messages
        await _populateFtsFromExistingMessages();
      }
      if (from <= 5) {
        // Migration from v5 to v6: Add user settings table
        await m.createTable(userSettings);
      }
      if (from <= 6) {
        // Migration from v6 to v7: Add retry tracking columns for messages
        await m.addColumn(roomEvents, roomEvents.retryCount);
        await m.addColumn(roomEvents, roomEvents.errorMessage);
        // Migration from v6 to v7: Add drafts table for message draft persistence
        await m.createTable(drafts);
      }
      if (from <= 7) {
        // Migration from v7 to v8: Add read receipts table
        await m.createTable(readReceipts);
        // Create index for efficient querying by eventId
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_read_receipts_event_id
          ON read_receipts(event_id)
        ''');
        // Create unique constraint to prevent duplicate receipts
        await customStatement('''
          CREATE UNIQUE INDEX IF NOT EXISTS idx_read_receipts_unique
          ON read_receipts(event_id, profile_id)
        ''');
      }
      if (from <= 8) {
        // Migration from v8 to v9: Add message forwarding columns
        await m.addColumn(roomEvents, roomEvents.forwardedFromRoom);
        await m.addColumn(roomEvents, roomEvents.forwardedFromEvent);
        await m.addColumn(roomEvents, roomEvents.forwardCount);
        await m.addColumn(roomEvents, roomEvents.forwardRestricted);
        // Migration from v8 to v9: Add reports table for user reports
        await m.createTable(reports);
        // Create index for efficient querying by reported user
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_reports_reported_user_id
          ON reports(reported_user_id)
        ''');
        // Migration from v8 to v9: Add invite links tables
        await m.createTable(inviteLinks);
        await m.createTable(inviteLinkJoins);
        // Create index for efficient querying by room
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_invite_links_room_id
          ON invite_links(room_id)
        ''');
        // Create index for efficient querying by code
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_invite_links_code
          ON invite_links(code)
        ''');
        // Create index for efficient querying joins by link
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_invite_link_joins_link_id
          ON invite_link_joins(invite_link_id)
        ''');
        // Add disappearing messages support
        await m.addColumn(rooms, rooms.disappearingTimeout);
        await m.addColumn(roomEvents, roomEvents.expiresAt);
        // Create index for efficient expiry checking
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_room_events_expires_at
          ON room_events(expires_at)
          WHERE expires_at IS NOT NULL
        ''');
      }
      if (from <= 9) {
        // Migration from v9 to v10: Add starred messages support
        // Add mute notifications support
        await m.addColumn(rooms, rooms.mutedUntil);
        await m.addColumn(roomEvents, roomEvents.starred);
        await m.addColumn(roomEvents, roomEvents.starredAt);
        // Create index for efficient starred message querying
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_room_events_starred
          ON room_events(starred, starred_at)
          WHERE starred = 1
        ''');
      }
      if (from <= 10) {
        // Migration from v10 to v11: Add user status and bio fields
        await m.addColumn(profiles, profiles.status);
        await m.addColumn(profiles, profiles.statusMessage);
        await m.addColumn(profiles, profiles.statusUpdatedAt);
        await m.addColumn(profiles, profiles.bio);
      }
      if (from <= 11) {
        // Migration from v11 to v12: Add call history table
        await m.createTable(callHistory);
        // Create index for efficient querying by room
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_call_history_room_id
          ON call_history(room_id)
        ''');
        // Create index for efficient querying by time
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_call_history_started_at
          ON call_history(started_at DESC)
        ''');
        // Create index for filtering unread/deleted calls
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_call_history_status
          ON call_history(is_read, is_deleted)
          WHERE is_deleted = 0
        ''');
      }
      if (from <= 12) {
        // Migration from v12 to v13: Add group member limit columns
        await m.addColumn(rooms, rooms.memberLimit);
        await m.addColumn(rooms, rooms.memberLimitEnabled);
      }
      if (from <= 13) {
        // Migration from v13 to v14: Add analytics events table
        await m.createTable(analyticsEvents);
        // Create index for querying unsynced events
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_analytics_events_synced
          ON analytics_events(is_synced)
          WHERE is_synced = 0
        ''');
        // Create index for querying by timestamp
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_analytics_events_timestamp
          ON analytics_events(timestamp DESC)
        ''');
        // Create unique index on event_id
        await customStatement('''
          CREATE UNIQUE INDEX IF NOT EXISTS idx_analytics_events_event_id
          ON analytics_events(event_id)
        ''');
      }
      if (from <= 14) {
        // Migration from v14 to v15: Add upload chunks table for resumable uploads
        await m.createTable(uploadChunks);
        // Create index for efficient querying by localId
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_upload_chunks_local_id
          ON upload_chunks(local_id)
        ''');
      }
      if (from <= 15) {
        // Migration from v15 to v16: Add job queue priority and error tracking
        await m.addColumn(pendingJobs, pendingJobs.priority);
        await m.addColumn(pendingJobs, pendingJobs.lastError);
        // Create index for efficient priority-based job retrieval
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_pending_jobs_priority
          ON pending_jobs(priority ASC, created_at ASC)
          WHERE status = 'pending'
        ''');
      }
      if (from <= 16) {
        // Migration from v16 to v17: Add download chunks and transfer jobs tables
        //   (v17 to v18 handled below)
        await m.createTable(downloadChunks);
        await m.createTable(transferJobs);

        // Create index for efficient querying by downloadId
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_download_chunks_download_id
          ON download_chunks(download_id)
        ''');

        // Create index for efficient querying pending transfer jobs by priority
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_transfer_jobs_priority
          ON transfer_jobs(priority ASC, created_at ASC)
          WHERE status = 'pending'
        ''');

        // Create index for querying transfer jobs by reference ID
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_transfer_jobs_reference_id
          ON transfer_jobs(reference_id)
        ''');

        // Create index for querying transfer jobs by room ID
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_transfer_jobs_room_id
          ON transfer_jobs(room_id)
        ''');
      }
      if (from <= 17) {
        // Migration from v17 to v18: Rename room_members → room_subscriptions
        // and subscription_id → id
        await customStatement(
          'ALTER TABLE room_members RENAME TO room_subscriptions',
        );
        await customStatement(
          'ALTER TABLE room_subscriptions RENAME COLUMN subscription_id TO id',
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');

      // Handle data migration after schema changes
      if (details.hadUpgrade) {
        final currentVersion = await customSelect(
          'SELECT user_version FROM pragma_user_version()',
        ).getSingle();
        if (currentVersion.data['user_version'] == 2) {
          // Add rosterId column if it doesn't exist
          await customStatement('''
              ALTER TABLE roster ADD COLUMN rosterId TEXT
            ''');

          // Copy existing IDs to rosterId column (they were server IDs)
          await customStatement('''
              UPDATE roster SET rosterId = id WHERE rosterId IS NULL
            ''');

          // Generate new stable UUIDs for local id column using xid
          await customStatement('''
              UPDATE roster SET id = substr(lower(hex(randomblob(8))), 1, 8) || '-' ||
                                 substr(lower(hex(randomblob(4))), 1, 4) || '-4' ||
                                 substr(lower(hex(randomblob(4))), 1, 4) || '-' ||
                                 substr('89ab', (abs(random()) % 4) + 1, 1) ||
                                 substr(lower(hex(randomblob(4))), 1, 4) || '-' ||
                                 substr(lower(hex(randomblob(12))), 1, 12)
              WHERE id NOT LIKE '%-%-%-%-%'
            ''');
        }
      }
    },
  );

  /// Create the FTS5 virtual table for full-text message search
  Future<void> _createFtsTable() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS room_events_fts USING fts5(
        event_id,
        room_id,
        content,
        tokenize='porter unicode61'
      )
    ''');

    // Create triggers to keep FTS index in sync with room_events table

    // Trigger for new text messages
    await customStatement(r'''
      CREATE TRIGGER IF NOT EXISTS room_events_ai AFTER INSERT ON room_events
      WHEN new.type = 0 AND new.content IS NOT NULL
      BEGIN
        INSERT INTO room_events_fts(event_id, room_id, content)
        VALUES (new.id, new.room_id, json_extract(new.content, '$.text'));
      END
    ''');

    // Trigger for updated messages (editing)
    await customStatement(r'''
      CREATE TRIGGER IF NOT EXISTS room_events_au AFTER UPDATE ON room_events
      WHEN new.type = 0 AND new.content IS NOT NULL
      BEGIN
        DELETE FROM room_events_fts WHERE event_id = old.id;
        INSERT INTO room_events_fts(event_id, room_id, content)
        VALUES (new.id, new.room_id, json_extract(new.content, '$.text'));
      END
    ''');

    // Trigger for deleted messages
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS room_events_ad AFTER DELETE ON room_events
      BEGIN
        DELETE FROM room_events_fts WHERE event_id = old.id;
      END
    ''');
  }

  /// Populate FTS index from existing text messages
  Future<void> _populateFtsFromExistingMessages() async {
    await customStatement(r'''
      INSERT INTO room_events_fts(event_id, room_id, content)
      SELECT id, room_id, json_extract(content, '$.text')
      FROM room_events
      WHERE type = 0 AND content IS NOT NULL
        AND json_extract(content, '$.text') IS NOT NULL
    ''');
  }

  // ============================================================================
  // Full-Text Search Methods
  // ============================================================================

  /// Map a QueryRow to a RoomEvent
  ///
  /// Helper method to reduce duplication in search methods.
  RoomEvent _mapQueryRowToRoomEvent(QueryRow row) => RoomEvent(
    id: row.read<String>('id'),
    roomId: row.read<String>('room_id'),
    senderId: row.read<String>('sender_id'),
    senderContactId: row.readNullable<String>('sender_contact_id'),
    type: row.read<int>('type'),
    content: row.readNullable<String>('content'),
    parentId: row.readNullable<String>('parent_id'),
    status: row.read<int>('status'),
    createdAt: row.readNullable<int>('created_at'),
    serverTs: row.readNullable<int>('server_ts'),
    localId: row.readNullable<String>('local_id'),
    editedAt: row.readNullable<int>('edited_at'),
    originalContent: row.readNullable<String>('original_content'),
    redacted: row.read<bool>('redacted'),
    redactedAt: row.readNullable<int>('redacted_at'),
    redactedBy: row.readNullable<String>('redacted_by'),
    retryCount: row.readNullable<int>('retry_count') ?? 0,
    errorMessage: row.readNullable<String>('error_message'),
    forwardedFromRoom: row.readNullable<String>('forwarded_from_room'),
    forwardedFromEvent: row.readNullable<String>('forwarded_from_event'),
    forwardCount: row.readNullable<int>('forward_count') ?? 0,
    forwardRestricted: row.readNullable<bool>('forward_restricted') ?? false,
    starred: row.readNullable<bool>('starred') ?? false,
    starredAt: row.readNullable<int>('starred_at'),
  );

  /// Search messages by text content across all rooms
  ///
  /// Returns messages matching the search query, ordered by relevance.
  ///
  /// Parameters:
  /// - [query]: The search query (supports FTS5 syntax)
  /// - `limit`: Maximum number of results (default 50)
  ///
  /// Example:
  /// ```dart
  /// final results = await db.searchMessages('hello world', limit: 20);
  /// ```
  /// Sanitize a search query for safe FTS5 usage.
  ///
  /// Each word is individually quoted to prevent FTS5 syntax injection
  /// while allowing multi-word queries to match documents containing
  /// all words (implicit AND). For example, 'quick fox' becomes
  /// '"quick" "fox"' which matches documents containing both words.
  static String _sanitizeFtsQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return '';

    // Split into words and quote each one individually.
    // This prevents FTS5 syntax injection (", *, ^, NOT, OR, AND, parens)
    // while supporting multi-word search (each quoted word is AND-ed).
    return trimmed
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((word) => '"${word.replaceAll('"', '""')}"')
        .join(' ');
  }

  Future<List<RoomEvent>> searchMessages(String query, {int limit = 50}) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final safeQuery = _sanitizeFtsQuery(query);

    try {
      final results = await customSelect(
        '''
        SELECT re.*
        FROM room_events re
        INNER JOIN room_events_fts fts ON re.id = fts.event_id
        WHERE room_events_fts MATCH ?
        ORDER BY rank
        LIMIT ?
        ''',
        variables: [Variable.withString(safeQuery), Variable.withInt(limit)],
        readsFrom: {roomEvents},
      ).get();

      return results.map(_mapQueryRowToRoomEvent).toList();
    } on SqliteException {
      // Guard against any remaining FTS5 syntax edge cases
      return [];
    }
  }

  /// Search messages within a specific room
  ///
  /// Returns messages matching the search query in the specified room.
  ///
  /// Parameters:
  /// - [roomId]: The room to search in
  /// - [query]: The search query (supports FTS5 syntax)
  /// - [limit]: Maximum number of results (default 50)
  Future<List<RoomEvent>> searchMessagesInRoom(
    String roomId,
    String query, {
    int limit = 50,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final safeQuery = _sanitizeFtsQuery(query);

    try {
      final results = await customSelect(
        '''
        SELECT re.*
        FROM room_events re
        INNER JOIN room_events_fts fts ON re.id = fts.event_id
        WHERE fts.room_id = ? AND room_events_fts MATCH ?
        ORDER BY rank
        LIMIT ?
        ''',
        variables: [
          Variable.withString(roomId),
          Variable.withString(safeQuery),
          Variable.withInt(limit),
        ],
        readsFrom: {roomEvents},
      ).get();

      return results.map(_mapQueryRowToRoomEvent).toList();
    } on SqliteException {
      // Guard against any remaining FTS5 syntax edge cases
      return [];
    }
  }

  /// Rebuild the FTS index from scratch
  ///
  /// Use this if the index becomes corrupted or out of sync.
  Future<void> rebuildFtsIndex() async {
    await customStatement('DELETE FROM room_events_fts');
    await _populateFtsFromExistingMessages();
  }

  static QueryExecutor _openConnection() => driftDatabase(name: 'chat_v1.db');
}
