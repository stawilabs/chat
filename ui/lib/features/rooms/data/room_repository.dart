import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/database.dart';
import '../domain/room.dart' as domain;
import '../domain/room_with_last_message.dart';

/// Repository for chat room operations
///
/// Provides database access for room management including:
/// - Fetching all rooms with optional filtering
/// - Getting rooms with their last message for display
/// - Creating, updating, and deleting rooms
/// - Managing unread message counts
///
/// Example:
/// ```dart
/// final repo = RoomRepository(database);
/// final rooms = await repo.getRoomsWithLastMessage();
/// final room = await repo.getRoomById('room-123');
/// ```
class RoomRepository {
  RoomRepository(this._database);
  final AppDatabase _database;

  Future<List<domain.Room>> getAllRooms() async {
    final query = _database.select(_database.rooms)
      ..orderBy([(t) => OrderingTerm.desc(t.lastEventIndex)]);
    final results = await query.get();

    return results.map(_toRoom).toList();
  }

  Future<List<RoomWithLastMessage>> getRoomsWithLastMessage({
    String? currentProfileId,
  }) async {
    final query = _database.customSelect(
      '''
      SELECT
        r.id,
        r.name,
        r.type,
        r.unread_count,
        r.muted_until,
        e.content as last_message_content,
        e.created_at as last_message_timestamp,
        e.sender_id as last_message_sender_id,
        CASE
          WHEN rs.profile_id = ? THEN 'You'
          ELSE COALESCE(ro.display_name, ro.contact_detail)
        END as last_message_sender_name
      FROM rooms r
      LEFT JOIN room_events e ON r.last_event_id = e.id
      LEFT JOIN room_subscriptions rs ON e.sender_id = rs.id
      LEFT JOIN roster ro ON rs.profile_id = ro.profile_id
      ORDER BY COALESCE(e.created_at, 0) DESC
    ''',
      variables: [Variable<String>(currentProfileId ?? '')],
      readsFrom: {
        _database.rooms,
        _database.roomEvents,
        _database.roomSubscriptions,
        _database.roster,
      },
    );

    final results = await query.get();

    return results.map((row) {
      String? lastMessageText;
      final content = row.read<String?>('last_message_content');
      if (content != null) {
        final decoded = jsonDecode(content) as Map<String, dynamic>;
        lastMessageText = decoded['text'] as String?;
      }

      return RoomWithLastMessage(
        id: row.read<String>('id'),
        name: row.read<String?>('name') ?? '',
        type: row.read<String?>('type') ?? '',
        unreadCount: row.read<int?>('unread_count') ?? 0,
        lastMessageText: lastMessageText,
        lastMessageTimestamp: row.read<int?>('last_message_timestamp'),
        lastMessageSenderId: row.read<String?>('last_message_sender_id'),
        lastMessageSenderName: row.read<String?>('last_message_sender_name'),
        mutedUntil: row.read<int?>('muted_until'),
      );
    }).toList();
  }

  Future<domain.Room?> getRoomById(String roomId) async {
    final query = _database.select(_database.rooms)
      ..where((t) => t.id.equals(roomId));
    final result = await query.getSingleOrNull();

    if (result == null) return null;
    return _toRoom(result);
  }

  Future<void> insertRoom(domain.Room room) async {
    await _database
        .into(_database.rooms)
        .insertOnConflictUpdate(
          RoomsCompanion.insert(
            id: room.id,
            name: Value(room.name),
            type: Value(room.type),
            lastEventId: Value(room.lastEventId),
            lastEventIndex: Value(room.lastEventIndex),
            unreadCount: Value(room.unreadCount),
            metadata: Value(
              room.metadata != null ? jsonEncode(room.metadata) : null,
            ),
            disappearingTimeout: Value(room.disappearingTimeout),
            mutedUntil: Value(room.mutedUntil),
            memberLimit: Value(room.memberLimit),
            memberLimitEnabled: Value(room.memberLimitEnabled),
          ),
        );
  }

  /// Update disappearing messages timeout for a room
  Future<void> updateDisappearingTimeout(String roomId, int? timeout) async {
    await (_database.update(_database.rooms)..where((t) => t.id.equals(roomId)))
        .write(RoomsCompanion(disappearingTimeout: Value(timeout)));
  }

  /// Update member limit for a room
  ///
  /// [memberLimit] The new member limit (null = default 256)
  /// [enabled] Whether the limit is enforced
  Future<void> updateMemberLimit(
    String roomId, {
    int? memberLimit,
    bool? enabled,
  }) async {
    await (_database.update(
      _database.rooms,
    )..where((t) => t.id.equals(roomId))).write(
      RoomsCompanion(
        memberLimit: memberLimit != null
            ? Value(memberLimit)
            : const Value.absent(),
        memberLimitEnabled: enabled != null
            ? Value(enabled)
            : const Value.absent(),
      ),
    );
  }

  Future<void> updateUnreadCount(String roomId, int count) async {
    await (_database.update(_database.rooms)..where((t) => t.id.equals(roomId)))
        .write(RoomsCompanion(unreadCount: Value(count)));
  }

  /// Update room name from server-pushed change
  Future<void> updateRoomName(String roomId, String name) async {
    await (_database.update(_database.rooms)..where((t) => t.id.equals(roomId)))
        .write(RoomsCompanion(name: Value(name)));
  }

  /// Update room metadata from server-pushed change (merges with existing).
  /// Uses a transaction to prevent TOCTOU races with concurrent updates.
  Future<void> updateRoomMetadata(
    String roomId,
    Map<String, dynamic> newMetadata,
  ) async {
    await _database.transaction(() async {
      final existing = await getRoomById(roomId);
      if (existing == null) return;

      final merged = {...?existing.metadata, ...newMetadata};

      await (_database.update(_database.rooms)
            ..where((t) => t.id.equals(roomId)))
          .write(RoomsCompanion(metadata: Value(jsonEncode(merged))));
    });
  }

  /// Update sync cursor metadata atomically.
  /// Uses a transaction to prevent concurrent history/stream sync from
  /// overwriting each other's cursor values.
  Future<void> updateSyncMetadata(
    String roomId, {
    String? historyBackwardCursor,
    String? historyForwardCursor,
  }) async {
    await _database.transaction(() async {
      final existing = await getRoomById(roomId);
      if (existing == null) return;

      final merged = <String, dynamic>{...?existing.metadata};

      if (historyBackwardCursor != null) {
        if (historyBackwardCursor.isEmpty) {
          merged.remove('historyBackwardCursor');
        } else {
          merged['historyBackwardCursor'] = historyBackwardCursor;
        }
      }

      if (historyForwardCursor != null) {
        if (historyForwardCursor.isEmpty) {
          merged.remove('historyForwardCursor');
        } else {
          merged['historyForwardCursor'] = historyForwardCursor;
        }
      }

      await (_database.update(_database.rooms)
            ..where((t) => t.id.equals(roomId)))
          .write(RoomsCompanion(metadata: Value(jsonEncode(merged))));
    });
  }

  Future<void> updateLastEventId(String roomId, String eventId) async {
    // Atomic compare-and-swap: only update if eventId is greater than the
    // current value. Avoids TOCTOU race when stream and history sync both
    // call this concurrently for the same room.
    //
    // NOTE: The lexicographic string comparison (last_event_id < ?) assumes
    // XID format (time-sortable, lexicographically ordered). If the ID format
    // changes, this ordering logic must be revisited.
    await _database.customStatement(
      'UPDATE rooms SET last_event_id = ? '
      'WHERE id = ? AND (last_event_id IS NULL OR last_event_id < ?)',
      [eventId, roomId, eventId],
    );
  }

  Future<void> incrementUnreadCount(String roomId) async {
    await _database.customStatement(
      'UPDATE rooms SET unread_count = unread_count + 1 WHERE id = ?',
      [roomId],
    );
  }

  /// Mark room as deleted from server-pushed change
  Future<void> markRoomDeleted(String roomId) async {
    final existing = await getRoomById(roomId);
    if (existing == null) return;

    final metadata = {...?existing.metadata, 'deleted': true};

    await (_database.update(_database.rooms)..where((t) => t.id.equals(roomId)))
        .write(RoomsCompanion(metadata: Value(jsonEncode(metadata))));
  }

  /// Update the muted_until timestamp for a room
  ///
  /// - null = not muted
  /// - 0 = muted forever
  /// - timestamp = muted until that time (milliseconds since epoch)
  Future<void> updateMutedUntil(String roomId, int? mutedUntil) async {
    await (_database.update(_database.rooms)..where((t) => t.id.equals(roomId)))
        .write(RoomsCompanion(mutedUntil: Value(mutedUntil)));
  }

  /// Check if a room is currently muted
  ///
  /// Returns true if:
  /// - mutedUntil is 0 (muted forever)
  /// - mutedUntil is a future timestamp
  Future<bool> isRoomMuted(String roomId) async {
    final room = await getRoomById(roomId);
    if (room == null) return false;
    return room.isMuted;
  }

  /// Get the muted_until value for a room
  Future<int?> getMutedUntil(String roomId) async {
    final query = _database.select(_database.rooms)
      ..where((t) => t.id.equals(roomId));
    final result = await query.getSingleOrNull();
    return result?.mutedUntil;
  }

  domain.Room _toRoom(Room row) => domain.Room(
    id: row.id,
    name: row.name ?? '',
    type: row.type ?? '',
    lastEventId: row.lastEventId,
    lastEventIndex: row.lastEventIndex ?? 0,
    unreadCount: row.unreadCount,
    metadata: row.metadata != null ? jsonDecode(row.metadata!) : null,
    disappearingTimeout: row.disappearingTimeout,
    mutedUntil: row.mutedUntil,
    memberLimit: row.memberLimit,
    memberLimitEnabled: row.memberLimitEnabled,
  );
}
