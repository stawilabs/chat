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
  @JsonValue('unknown')
  unknown,

  @JsonValue('text')
  text,

  @JsonValue('image')
  image,

  @JsonValue('video')
  video,

  @JsonValue('audio')
  audio,

  @JsonValue('file')
  file,

  @JsonValue('reaction')
  reaction,

  @JsonValue('callOffer')
  callOffer,

  @JsonValue('callAnswer')
  callAnswer,

  @JsonValue('callIce')
  callIce,

  @JsonValue('callEnd')
  callEnd,

  // Group call event types
  @JsonValue('groupCallStart')
  groupCallStart,

  @JsonValue('groupCallJoin')
  groupCallJoin,

  @JsonValue('groupCallLeave')
  groupCallLeave,

  @JsonValue('groupCallEnd')
  groupCallEnd,

  @JsonValue('groupCallOffer')
  groupCallOffer,

  @JsonValue('groupCallAnswer')
  groupCallAnswer,

  @JsonValue('groupCallIce')
  groupCallIce,

  @JsonValue('groupCallMuteUpdate')
  groupCallMuteUpdate,

  @JsonValue('motion')
  motion,

  @JsonValue('vote')
  vote,

  @JsonValue('transaction')
  transaction,

  @JsonValue('formRequest')
  formRequest,

  @JsonValue('formSubmissionResult')
  formSubmissionResult,

  @JsonValue('groupConfig')
  groupConfig,

  /// Room key sharing for E2EE session keys
  @JsonValue('roomKey')
  roomKey,

  /// Room state change (created, updated, deleted, member changes)
  @JsonValue('roomChange')
  roomChange,

  /// Authoritative video-stage membership update for group calls
  @JsonValue('groupCallStageUpdate')
  groupCallStageUpdate,
}

extension RoomEventTypeStorage on RoomEventType {
  String get wireName {
    switch (this) {
      case RoomEventType.unknown:
        return 'unknown';
      case RoomEventType.text:
        return 'text';
      case RoomEventType.image:
        return 'image';
      case RoomEventType.video:
        return 'video';
      case RoomEventType.audio:
        return 'audio';
      case RoomEventType.file:
        return 'file';
      case RoomEventType.reaction:
        return 'reaction';
      case RoomEventType.callOffer:
        return 'callOffer';
      case RoomEventType.callAnswer:
        return 'callAnswer';
      case RoomEventType.callIce:
        return 'callIce';
      case RoomEventType.callEnd:
        return 'callEnd';
      case RoomEventType.groupCallStart:
        return 'groupCallStart';
      case RoomEventType.groupCallJoin:
        return 'groupCallJoin';
      case RoomEventType.groupCallLeave:
        return 'groupCallLeave';
      case RoomEventType.groupCallEnd:
        return 'groupCallEnd';
      case RoomEventType.groupCallOffer:
        return 'groupCallOffer';
      case RoomEventType.groupCallAnswer:
        return 'groupCallAnswer';
      case RoomEventType.groupCallIce:
        return 'groupCallIce';
      case RoomEventType.groupCallMuteUpdate:
        return 'groupCallMuteUpdate';
      case RoomEventType.motion:
        return 'motion';
      case RoomEventType.vote:
        return 'vote';
      case RoomEventType.transaction:
        return 'transaction';
      case RoomEventType.formRequest:
        return 'formRequest';
      case RoomEventType.formSubmissionResult:
        return 'formSubmissionResult';
      case RoomEventType.groupConfig:
        return 'groupConfig';
      case RoomEventType.roomKey:
        return 'roomKey';
      case RoomEventType.roomChange:
        return 'roomChange';
      case RoomEventType.groupCallStageUpdate:
        return 'groupCallStageUpdate';
    }
  }

  int get storageCode {
    switch (this) {
      case RoomEventType.unknown:
        return 0;
      case RoomEventType.text:
        return 10;
      case RoomEventType.image:
        return 20;
      case RoomEventType.video:
        return 30;
      case RoomEventType.audio:
        return 40;
      case RoomEventType.file:
        return 50;
      case RoomEventType.reaction:
        return 60;
      case RoomEventType.callOffer:
        return 70;
      case RoomEventType.callAnswer:
        return 80;
      case RoomEventType.callIce:
        return 90;
      case RoomEventType.callEnd:
        return 100;
      case RoomEventType.groupCallStart:
        return 110;
      case RoomEventType.groupCallJoin:
        return 120;
      case RoomEventType.groupCallLeave:
        return 130;
      case RoomEventType.groupCallEnd:
        return 140;
      case RoomEventType.groupCallOffer:
        return 150;
      case RoomEventType.groupCallAnswer:
        return 160;
      case RoomEventType.groupCallIce:
        return 170;
      case RoomEventType.groupCallMuteUpdate:
        return 180;
      case RoomEventType.motion:
        return 190;
      case RoomEventType.vote:
        return 200;
      case RoomEventType.transaction:
        return 210;
      case RoomEventType.formRequest:
        return 215;
      case RoomEventType.formSubmissionResult:
        return 217;
      case RoomEventType.groupConfig:
        return 220;
      case RoomEventType.roomKey:
        return 230;
      case RoomEventType.roomChange:
        return 240;
      case RoomEventType.groupCallStageUpdate:
        return 250;
    }
  }
}

RoomEventType roomEventTypeFromStorageCode(int code) {
  switch (code) {
    case 0:
      return RoomEventType.unknown;
    case 10:
      return RoomEventType.text;
    case 20:
      return RoomEventType.image;
    case 30:
      return RoomEventType.video;
    case 40:
      return RoomEventType.audio;
    case 50:
      return RoomEventType.file;
    case 60:
      return RoomEventType.reaction;
    case 70:
      return RoomEventType.callOffer;
    case 80:
      return RoomEventType.callAnswer;
    case 90:
      return RoomEventType.callIce;
    case 100:
      return RoomEventType.callEnd;
    case 110:
      return RoomEventType.groupCallStart;
    case 120:
      return RoomEventType.groupCallJoin;
    case 130:
      return RoomEventType.groupCallLeave;
    case 140:
      return RoomEventType.groupCallEnd;
    case 150:
      return RoomEventType.groupCallOffer;
    case 160:
      return RoomEventType.groupCallAnswer;
    case 170:
      return RoomEventType.groupCallIce;
    case 180:
      return RoomEventType.groupCallMuteUpdate;
    case 190:
      return RoomEventType.motion;
    case 200:
      return RoomEventType.vote;
    case 210:
      return RoomEventType.transaction;
    case 215:
      return RoomEventType.formRequest;
    case 217:
      return RoomEventType.formSubmissionResult;
    case 220:
      return RoomEventType.groupConfig;
    case 230:
      return RoomEventType.roomKey;
    case 240:
      return RoomEventType.roomChange;
    case 250:
      return RoomEventType.groupCallStageUpdate;
    default:
      return RoomEventType.unknown;
  }
}

RoomEventType? tryRoomEventTypeFromWireName(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }

  switch (raw) {
    case 'unknown':
    case 'RoomEventType.unknown':
      return RoomEventType.unknown;
    case 'text':
    case 'RoomEventType.text':
      return RoomEventType.text;
    case 'image':
    case 'RoomEventType.image':
      return RoomEventType.image;
    case 'video':
    case 'RoomEventType.video':
      return RoomEventType.video;
    case 'audio':
    case 'RoomEventType.audio':
      return RoomEventType.audio;
    case 'file':
    case 'RoomEventType.file':
      return RoomEventType.file;
    case 'reaction':
    case 'RoomEventType.reaction':
      return RoomEventType.reaction;
    case 'callOffer':
    case 'RoomEventType.callOffer':
      return RoomEventType.callOffer;
    case 'callAnswer':
    case 'RoomEventType.callAnswer':
      return RoomEventType.callAnswer;
    case 'callIce':
    case 'RoomEventType.callIce':
      return RoomEventType.callIce;
    case 'callEnd':
    case 'RoomEventType.callEnd':
      return RoomEventType.callEnd;
    case 'groupCallStart':
    case 'RoomEventType.groupCallStart':
      return RoomEventType.groupCallStart;
    case 'groupCallJoin':
    case 'RoomEventType.groupCallJoin':
      return RoomEventType.groupCallJoin;
    case 'groupCallLeave':
    case 'RoomEventType.groupCallLeave':
      return RoomEventType.groupCallLeave;
    case 'groupCallEnd':
    case 'RoomEventType.groupCallEnd':
      return RoomEventType.groupCallEnd;
    case 'groupCallOffer':
    case 'RoomEventType.groupCallOffer':
      return RoomEventType.groupCallOffer;
    case 'groupCallAnswer':
    case 'RoomEventType.groupCallAnswer':
      return RoomEventType.groupCallAnswer;
    case 'groupCallIce':
    case 'RoomEventType.groupCallIce':
      return RoomEventType.groupCallIce;
    case 'groupCallMuteUpdate':
    case 'RoomEventType.groupCallMuteUpdate':
      return RoomEventType.groupCallMuteUpdate;
    case 'motion':
    case 'RoomEventType.motion':
      return RoomEventType.motion;
    case 'vote':
    case 'RoomEventType.vote':
      return RoomEventType.vote;
    case 'transaction':
    case 'RoomEventType.transaction':
      return RoomEventType.transaction;
    case 'formRequest':
    case 'RoomEventType.formRequest':
      return RoomEventType.formRequest;
    case 'formSubmissionResult':
    case 'RoomEventType.formSubmissionResult':
      return RoomEventType.formSubmissionResult;
    case 'groupConfig':
    case 'RoomEventType.groupConfig':
      return RoomEventType.groupConfig;
    case 'roomKey':
    case 'RoomEventType.roomKey':
      return RoomEventType.roomKey;
    case 'roomChange':
    case 'RoomEventType.roomChange':
      return RoomEventType.roomChange;
    case 'groupCallStageUpdate':
    case 'RoomEventType.groupCallStageUpdate':
      return RoomEventType.groupCallStageUpdate;
    default:
      return null;
  }
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

extension EventStatusStorage on EventStatus {
  int get storageCode {
    switch (this) {
      case EventStatus.pending:
        return 10;
      case EventStatus.sent:
        return 20;
      case EventStatus.delivered:
        return 30;
      case EventStatus.read:
        return 40;
      case EventStatus.failed:
        return 50;
    }
  }

  bool isAtLeast(EventStatus other) => storageCode >= other.storageCode;
}

EventStatus eventStatusFromStorageCode(int code) {
  switch (code) {
    case 10:
      return EventStatus.pending;
    case 20:
      return EventStatus.sent;
    case 30:
      return EventStatus.delivered;
    case 40:
      return EventStatus.read;
    case 50:
      return EventStatus.failed;
    default:
      return EventStatus.pending;
  }
}

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
