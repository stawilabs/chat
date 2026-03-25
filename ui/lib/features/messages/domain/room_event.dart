import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_event.freezed.dart';
part 'room_event.g.dart';

/// Types of events that can occur in a chat room
///
/// Includes message types (text, media, files), reactions,
/// call signaling, and group-specific events (motions, votes, transactions).
///
/// Example:
/// ```dart
/// final type = RoomEventType.text;
/// if (type == RoomEventType.image) {
///   // Handle image message
/// }
/// ```
enum RoomEventType {
  text,
  image,
  video,
  audio,
  file,
  reaction,
  callOffer,
  callAnswer,
  callIce,
  callEnd,

  // Group call event types
  groupCallStart,
  groupCallJoin,
  groupCallLeave,
  groupCallEnd,
  groupCallOffer,
  groupCallAnswer,
  groupCallIce,
  groupCallMuteUpdate,

  motion,
  vote,
  transaction,
  groupConfig,

  /// Room key sharing for E2EE session keys
  roomKey,

  /// Room state change (created, updated, deleted, member changes)
  roomChange,
}

/// Status of a message/event in its delivery lifecycle
///
/// Tracks message progression from creation to delivery:
/// - pending: Message created locally, not yet sent
/// - sent: Message sent to server
/// - delivered: Message delivered to recipient
/// - read: Message read by recipient
/// - failed: Message failed to send
///
/// Example:
/// ```dart
/// if (message.status == EventStatus.failed) {
///   showRetryButton();
/// }
/// ```
enum EventStatus { pending, sent, delivered, read, failed }

/// Room event domain model representing messages and events
///
/// A RoomEvent can be a text message, media attachment, reaction,
/// call signal, or other event type. Events are immutable and
/// identified by their ID.
///
/// Example:
/// ```dart
/// final message = RoomEvent(
///   id: 'event-123',
///   roomId: 'room-456',
///   senderId: 'profile-789',
///   type: RoomEventType.text,
///   content: {'text': 'Hello world'},
///   createdAt: DateTime.now().millisecondsSinceEpoch,
/// );
/// ```
/// Maximum number of automatic retry attempts before manual retry is required
const int maxAutoRetries = 5;

@freezed
abstract class RoomEvent with _$RoomEvent {
  const factory RoomEvent({
    // Required parameters first
    required String id,
    required String roomId,
    required String
    senderId, // Subscription ID (room-specific sender identifier)
    required RoomEventType type,
    required Map<String, dynamic> content,
    required int createdAt,
    // Optional parameters
    String? senderContactId, // Contact ID (from ContactLink.contactId)
    String? parentId,
    @Default(EventStatus.pending) EventStatus status,
    int? serverTs,
    String? localId,
    int? editedAt, // Timestamp when message was last edited
    @Default(false) bool redacted, // Whether message is deleted
    int? redactedAt, // Timestamp when message was deleted
    String? redactedBy, // Profile ID of who deleted (for admin deletions)
    @Default(0) int retryCount, // Number of send retry attempts
    String? errorMessage, // Error reason if failed
    // Forwarding fields
    String? forwardedFromRoom, // Room ID this was forwarded from
    String? forwardedFromEvent, // Original event ID this was forwarded from
    @Default(0) int forwardCount, // Times this message has been forwarded
    @Default(false) bool forwardRestricted, // Cannot be forwarded
    // Disappearing messages
    int?
    expiresAt, // Timestamp when message expires (for disappearing messages)
    // Starred messages
    @Default(false) bool starred, // Whether message is starred/bookmarked
    int? starredAt, // Timestamp when message was starred
  }) = _RoomEvent;

  factory RoomEvent.fromJson(Map<String, dynamic> json) =>
      _$RoomEventFromJson(json);
  const RoomEvent._();

  /// Returns true if this message has been edited
  bool get isEdited => editedAt != null;

  /// Returns true if this message has been deleted/redacted
  bool get isDeleted => redacted;

  /// Returns true if this message is a forwarded message
  bool get isForwarded => forwardedFromEvent != null;

  /// Returns true if this message can be forwarded
  bool get canBeForwarded => !forwardRestricted && !isDeleted;

  /// Returns true if manual retry is required (exceeded auto-retry limit)
  bool get requiresManualRetry =>
      status == EventStatus.failed && retryCount >= maxAutoRetries;

  /// Returns true if the message can still auto-retry
  bool get canAutoRetry =>
      status == EventStatus.failed && retryCount < maxAutoRetries;

  /// Returns true if this message is set to disappear
  bool get isDisappearing => expiresAt != null;

  /// Returns true if this message has expired and should be deleted
  bool get hasExpired =>
      expiresAt != null && DateTime.now().millisecondsSinceEpoch > expiresAt!;

  /// Returns true if this message is starred/bookmarked
  bool get isStarred => starred;

  /// Returns true if this message can be starred (not deleted)
  bool get canBeStarred => !isDeleted;
}
