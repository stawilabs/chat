import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../domain/room_event.dart' as domain;

/// Repository for message and room event operations
///
/// Provides database access for messages including:
/// - Fetching messages for a room with pagination
/// - Inserting and updating messages
/// - Watching message streams for reactive UI updates
/// - Managing message status (sent, delivered, read)
///
/// Example:
/// ```dart
/// final repo = MessageRepository(database);
/// final messages = await repo.getMessagesForRoom('room-123');
/// await repo.insertMessage(newMessage);
/// ```
class MessageRepository {
  MessageRepository(this._database);
  final AppDatabase _database;

  Future<List<domain.RoomEvent>> getMessagesForRoom(
    String roomId, {
    int limit = 50,
  }) async {
    final query = _database.select(_database.roomEvents)
      ..where((t) => t.roomId.equals(roomId))
      ..orderBy([(t) => OrderingTerm.desc(_effectiveTimestamp(t))])
      ..limit(limit);

    final results = await query.get();
    return results.map(_toRoomEvent).toList().reversed.toList();
  }

  /// Get messages for a room before a specific timestamp (for pagination)
  /// Returns messages ordered from oldest to newest
  Future<List<domain.RoomEvent>> getMessagesBeforeTimestamp(
    String roomId, {
    required int beforeTimestamp,
    int limit = 50,
  }) async {
    final query = _database.select(_database.roomEvents)
      ..where(
        (t) =>
            t.roomId.equals(roomId) &
            _effectiveTimestamp(t).isSmallerThanValue(beforeTimestamp),
      )
      ..orderBy([(t) => OrderingTerm.desc(_effectiveTimestamp(t))])
      ..limit(limit);

    final results = await query.get();
    return results.map(_toRoomEvent).toList().reversed.toList();
  }

  /// Get the oldest message timestamp for a room (for pagination cursor)
  Future<int?> getOldestMessageTimestamp(String roomId) async {
    final query = _database.select(_database.roomEvents)
      ..where((t) => t.roomId.equals(roomId))
      ..orderBy([(t) => OrderingTerm.asc(_effectiveTimestamp(t))])
      ..limit(1);

    final result = await query.getSingleOrNull();
    if (result == null) return null;
    return result.serverTs ?? result.createdAt;
  }

  /// Get total message count for a room
  Future<int> getMessageCount(String roomId) async {
    final count =
        await (_database.selectOnly(_database.roomEvents)
              ..addColumns([countAll()])
              ..where(_database.roomEvents.roomId.equals(roomId)))
            .map((row) => row.read(countAll()))
            .getSingle();
    return count ?? 0;
  }

  /// Watch messages for a room - provides reactive updates for instant UI refresh
  Stream<List<domain.RoomEvent>> watchMessagesForRoom(
    String roomId, {
    int limit = 50,
  }) {
    final query = _database.select(_database.roomEvents)
      ..where((t) => t.roomId.equals(roomId))
      ..orderBy([(t) => OrderingTerm.desc(_effectiveTimestamp(t))])
      ..limit(limit);

    return query.watch().map(
      (results) => results.map(_toRoomEvent).toList().reversed.toList(),
    );
  }

  Future<void> insertMessage(domain.RoomEvent event) async {
    await _database
        .into(_database.roomEvents)
        .insertOnConflictUpdate(
          RoomEventsCompanion.insert(
            id: event.id,
            roomId: event.roomId,
            senderId: event.senderId,
            type: event.type.index,
            content: Value(jsonEncode(event.content)),
            parentId: Value(event.parentId),
            status: Value(event.status.index),
            createdAt: Value(event.createdAt),
            serverTs: Value(event.serverTs),
            localId: Value(event.localId),
            editedAt: Value(event.editedAt),
            redacted: Value(event.redacted),
            redactedAt: Value(event.redactedAt),
            redactedBy: Value(event.redactedBy),
            forwardedFromRoom: Value(event.forwardedFromRoom),
            forwardedFromEvent: Value(event.forwardedFromEvent),
            forwardCount: Value(event.forwardCount),
            forwardRestricted: Value(event.forwardRestricted),
            expiresAt: Value(event.expiresAt),
          ),
        );
  }

  /// Set expiration time for a message (for disappearing messages)
  /// Update the id and status of a message row identified by its localId.
  ///
  /// Used after server acknowledgment to replace the client-generated localId
  /// with the server-assigned id, avoiding a duplicate row.
  ///
  /// Handles two cases:
  /// 1. Normal: row has id=localId (ack arrived before echo) → update id to serverId
  /// 2. Race: row has id=serverId already (echo arrived first) → just update status
  Future<void> updateMessageIdAfterAck(
    String localId, {
    required String serverId,
    required String senderId,
    required domain.EventStatus status,
    int? serverTs,
  }) async {
    // Case 1: Normal - row still has id=localId (ack arrived first)
    final rowsUpdated =
        await (_database.update(_database.roomEvents)
              ..where((t) => t.id.equals(localId) & t.localId.equals(localId)))
            .write(
              RoomEventsCompanion(
                id: Value(serverId),
                senderId: Value(senderId),
                status: Value(status.index),
                serverTs: serverTs != null
                    ? Value(serverTs)
                    : const Value.absent(),
              ),
            );

    if (rowsUpdated == 0) {
      // Case 2: Echo arrived first - row already has id=serverId
      // Only update status if it would advance (sent is the ack status,
      // but echo may have already set delivered)
      final existing = await getEventById(serverId);
      if (existing != null && existing.status.index < status.index) {
        await updateMessageStatus(serverId, status);
      }
    }
  }

  Future<void> setMessageExpiry(String messageId, int expiresAt) async {
    await (_database.update(_database.roomEvents)
          ..where((t) => t.id.equals(messageId)))
        .write(RoomEventsCompanion(expiresAt: Value(expiresAt)));
  }

  /// Get all expired messages that should be deleted
  Future<List<domain.RoomEvent>> getExpiredMessages() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final query = _database.select(_database.roomEvents)
      ..where(
        (t) =>
            t.expiresAt.isNotNull() &
            t.expiresAt.isSmallerOrEqualValue(now) &
            t.redacted.equals(false),
      );

    final results = await query.get();
    return results.map(_toRoomEvent).toList();
  }

  /// Delete all expired messages and their associated media
  Future<int> deleteExpiredMessages() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final deleted =
        await (_database.delete(_database.roomEvents)..where(
              (t) =>
                  t.expiresAt.isNotNull() &
                  t.expiresAt.isSmallerOrEqualValue(now),
            ))
            .go();
    return deleted;
  }

  Future<void> updateMessageStatus(
    String messageId,
    domain.EventStatus status,
  ) async {
    await (_database.update(_database.roomEvents)
          ..where((t) => t.id.equals(messageId)))
        .write(RoomEventsCompanion(status: Value(status.index)));
  }

  Future<void> updateMessagesStatus(
    List<String> messageIds,
    domain.EventStatus status,
  ) async {
    if (messageIds.isEmpty) return;
    await (_database.update(_database.roomEvents)
          ..where((t) => t.id.isIn(messageIds)))
        .write(RoomEventsCompanion(status: Value(status.index)));
  }

  /// Update the server timestamp for a message (when echo provides it)
  Future<void> updateServerTimestamp(String messageId, int serverTs) async {
    await (_database.update(_database.roomEvents)
          ..where((t) => t.id.equals(messageId)))
        .write(RoomEventsCompanion(serverTs: Value(serverTs)));
  }

  /// Update the content of an existing message (for editing)
  ///
  /// Stores the original content if this is the first edit,
  /// and updates the editedAt timestamp.
  Future<void> updateMessageContent(
    String messageId,
    Map<String, dynamic> newContent, {
    String? originalContent,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_database.update(
      _database.roomEvents,
    )..where((t) => t.id.equals(messageId))).write(
      RoomEventsCompanion(
        content: Value(jsonEncode(newContent)),
        editedAt: Value(now),
        originalContent: originalContent != null
            ? Value(originalContent)
            : const Value.absent(),
      ),
    );
  }

  /// Check if a message can be edited (within time window and is text type)
  Future<bool> canEditMessage(
    String messageId,
    String currentUserId, {
    Duration editWindow = const Duration(minutes: 15),
  }) async {
    final event = await getEventById(messageId);
    if (event == null) return false;

    // Must be own message
    if (event.senderId != currentUserId) return false;

    // Must be text type
    if (event.type != domain.RoomEventType.text) return false;

    // Must be within edit window
    final messageAge = DateTime.now().millisecondsSinceEpoch - event.createdAt;
    if (messageAge > editWindow.inMilliseconds) return false;

    // Must not be failed or pending
    if (event.status == domain.EventStatus.failed ||
        event.status == domain.EventStatus.pending) {
      return false;
    }

    return true;
  }

  Future<domain.RoomEvent?> getEventById(String eventId) async {
    final query = _database.select(_database.roomEvents)
      ..where((t) => t.id.equals(eventId));

    final result = await query.getSingleOrNull();
    return result != null ? _toRoomEvent(result) : null;
  }

  /// Find an event by its localId column (for race condition handling)
  /// Returns the event if found, null otherwise
  Future<domain.RoomEvent?> getEventByLocalId(String localId) async {
    final query = _database.select(_database.roomEvents)
      ..where((t) => t.localId.equals(localId));

    final result = await query.getSingleOrNull();
    return result != null ? _toRoomEvent(result) : null;
  }

  /// Update the id of an existing message row from localId to serverId.
  /// Used when the server echo arrives before the ack response.
  /// This updates the primary key and advances status to delivered.
  Future<void> updateMessageIdFromEcho(
    String localId, {
    required String serverId,
    required String senderId,
    int? serverTs,
  }) async {
    await (_database.update(
      _database.roomEvents,
    )..where((t) => t.id.equals(localId) & t.localId.equals(localId))).write(
      RoomEventsCompanion(
        id: Value(serverId),
        senderId: Value(senderId),
        status: Value(domain.EventStatus.delivered.index),
        serverTs: serverTs != null ? Value(serverTs) : const Value.absent(),
      ),
    );
  }

  Future<List<domain.RoomEvent>> getReactionsForEvent(String eventId) async {
    final query = _database.select(_database.roomEvents)
      ..where(
        (t) =>
            t.parentId.equals(eventId) &
            t.type.equals(domain.RoomEventType.reaction.index),
      );

    final results = await query.get();
    return results.map(_toRoomEvent).toList();
  }

  /// Delete a message for everyone (marks as redacted)
  ///
  /// Sets the redacted flag and timestamp. The message content
  /// is preserved locally for history but hidden in UI.
  Future<void> deleteMessage(String messageId, {String? deletedBy}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_database.update(
      _database.roomEvents,
    )..where((t) => t.id.equals(messageId))).write(
      RoomEventsCompanion(
        redacted: const Value(true),
        redactedAt: Value(now),
        redactedBy: deletedBy != null ? Value(deletedBy) : const Value.absent(),
      ),
    );
  }

  /// Delete a message locally only (removes from local database)
  ///
  /// This is for "delete for me" functionality where the message
  /// is only removed from the current user's device.
  Future<void> deleteMessageForMe(String messageId) async {
    await (_database.delete(
      _database.roomEvents,
    )..where((t) => t.id.equals(messageId))).go();
  }

  /// Check if a message can be deleted by the current user
  ///
  /// Users can delete their own messages within a time window,
  /// or admins can delete any message.
  Future<bool> canDeleteMessage(
    String messageId,
    String currentUserId, {
    Duration deleteWindow = const Duration(hours: 24),
    bool isAdmin = false,
  }) async {
    final event = await getEventById(messageId);
    if (event == null) return false;

    // Already deleted
    if (event.isDeleted) return false;

    // Admins can delete any message
    if (isAdmin) return true;

    // Must be own message
    if (event.senderId != currentUserId) return false;

    // Must be within delete window
    final messageAge = DateTime.now().millisecondsSinceEpoch - event.createdAt;
    if (messageAge > deleteWindow.inMilliseconds) return false;

    // Cannot delete pending or failed messages (use cancel instead)
    if (event.status == domain.EventStatus.pending ||
        event.status == domain.EventStatus.failed) {
      return false;
    }

    return true;
  }

  /// Increment the forward count for a message
  Future<void> incrementForwardCount(String messageId) async {
    await _database.customStatement(
      'UPDATE room_events SET forward_count = forward_count + 1 WHERE id = ?',
      [messageId],
    );
  }

  // ============== Starred Messages ==============

  /// Star/bookmark a message
  ///
  /// Returns true if the message was successfully starred, false if it was
  /// already starred or doesn't exist.
  Future<bool> starMessage(String messageId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated =
        await (_database.update(_database.roomEvents)
              ..where((t) => t.id.equals(messageId) & t.starred.equals(false)))
            .write(
              RoomEventsCompanion(
                starred: const Value(true),
                starredAt: Value(now),
              ),
            );
    return updated > 0;
  }

  /// Unstar/remove bookmark from a message
  ///
  /// Returns true if the message was successfully unstarred, false if it was
  /// not starred or doesn't exist.
  Future<bool> unstarMessage(String messageId) async {
    final updated =
        await (_database.update(
          _database.roomEvents,
        )..where((t) => t.id.equals(messageId) & t.starred.equals(true))).write(
          const RoomEventsCompanion(
            starred: Value(false),
            starredAt: Value(null),
          ),
        );
    return updated > 0;
  }

  /// Toggle the starred state of a message
  ///
  /// Returns the new starred state of the message.
  Future<bool> toggleStar(String messageId) async {
    return _database.transaction(() async {
      final event = await getEventById(messageId);
      if (event == null) return false;

      if (event.starred) {
        await unstarMessage(messageId);
        return false;
      } else {
        await starMessage(messageId);
        return true;
      }
    });
  }

  /// Get all starred messages across all rooms
  ///
  /// Returns messages ordered by starred time (most recent first).
  Future<List<domain.RoomEvent>> getStarredMessages({int limit = 100}) async {
    final query = _database.select(_database.roomEvents)
      ..where((t) => t.starred.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.starredAt)])
      ..limit(limit);

    final results = await query.get();
    return results.map(_toRoomEvent).toList();
  }

  /// Get starred messages for a specific room
  ///
  /// Returns messages ordered by starred time (most recent first).
  Future<List<domain.RoomEvent>> getStarredMessagesForRoom(
    String roomId, {
    int limit = 100,
  }) async {
    final query = _database.select(_database.roomEvents)
      ..where((t) => t.roomId.equals(roomId) & t.starred.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.starredAt)])
      ..limit(limit);

    final results = await query.get();
    return results.map(_toRoomEvent).toList();
  }

  /// Watch starred messages for reactive UI updates
  Stream<List<domain.RoomEvent>> watchStarredMessages({int limit = 100}) {
    final query = _database.select(_database.roomEvents)
      ..where((t) => t.starred.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.starredAt)])
      ..limit(limit);

    return query.watch().map((rows) => rows.map(_toRoomEvent).toList());
  }

  /// Get the count of starred messages
  Future<int> getStarredMessagesCount() async {
    final count =
        await (_database.selectOnly(_database.roomEvents)
              ..addColumns([countAll()])
              ..where(_database.roomEvents.starred.equals(true)))
            .map((row) => row.read(countAll()))
            .getSingle();
    return count ?? 0;
  }

  /// Clear all starred messages
  Future<int> clearAllStarredMessages() async {
    return (_database.update(
      _database.roomEvents,
    )..where((t) => t.starred.equals(true))).write(
      const RoomEventsCompanion(starred: Value(false), starredAt: Value(null)),
    );
  }

  /// Batch update senderId for messages in a room.
  /// Used to replace a provisional subscription ID with the real one
  /// after the server confirms room creation.
  Future<int> updateSenderIdForRoom(
    String roomId,
    String oldSenderId,
    String newSenderId,
  ) async {
    return (_database.update(_database.roomEvents)..where(
          (t) => t.roomId.equals(roomId) & t.senderId.equals(oldSenderId),
        ))
        .write(RoomEventsCompanion(senderId: Value(newSenderId)));
  }

  domain.RoomEvent _toRoomEvent(RoomEvent row) => domain.RoomEvent(
    id: row.id,
    roomId: row.roomId,
    senderId: row.senderId,
    type: domain.RoomEventType.values[row.type],
    content: row.content != null ? jsonDecode(row.content!) : {},
    parentId: row.parentId,
    status: domain.EventStatus.values[row.status],
    createdAt: row.createdAt ?? 0,
    serverTs: row.serverTs,
    localId: row.localId,
    editedAt: row.editedAt,
    redacted: row.redacted,
    redactedAt: row.redactedAt,
    redactedBy: row.redactedBy,
    forwardedFromRoom: row.forwardedFromRoom,
    forwardedFromEvent: row.forwardedFromEvent,
    forwardCount: row.forwardCount,
    forwardRestricted: row.forwardRestricted,
    expiresAt: row.expiresAt,
    starred: row.starred,
    starredAt: row.starredAt,
    retryCount: row.retryCount,
    errorMessage: row.errorMessage,
  );

  Expression<int> _effectiveTimestamp(RoomEvents table) => ifNull<int>(
    table.serverTs.dartCast<int>(),
    table.createdAt.dartCast<int>(),
  );
}
