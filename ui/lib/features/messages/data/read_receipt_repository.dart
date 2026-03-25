import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';

part 'read_receipt_repository.g.dart';

/// Domain model for a read receipt with reader info
class ReadReceiptInfo {
  const ReadReceiptInfo({
    required this.eventId,
    required this.profileId,
    required this.readAt,
    this.displayName,
  });

  final String eventId;
  final String profileId;
  final int readAt;
  final String? displayName;
}

/// Repository for managing read receipts in the database
class ReadReceiptRepository {
  ReadReceiptRepository(this._db);

  final AppDatabase _db;

  /// Save a read receipt for an event
  ///
  /// Uses INSERT OR REPLACE to handle duplicates automatically.
  Future<void> saveReadReceipt({
    required String eventId,
    required String roomId,
    required String profileId,
    required int readAt,
  }) async {
    // Use raw SQL for UPSERT behavior
    await _db.customStatement(
      '''
      INSERT OR REPLACE INTO read_receipts (event_id, room_id, profile_id, read_at)
      VALUES (?, ?, ?, ?)
      ''',
      [eventId, roomId, profileId, readAt],
    );
  }

  /// Save multiple read receipts at once
  Future<void> saveReadReceipts(
    List<ReadReceiptInfo> receipts,
    String roomId,
  ) async {
    await _db.batch((batch) {
      for (final receipt in receipts) {
        batch.customStatement(
          '''
          INSERT OR REPLACE INTO read_receipts (event_id, room_id, profile_id, read_at)
          VALUES (?, ?, ?, ?)
          ''',
          [receipt.eventId, roomId, receipt.profileId, receipt.readAt],
        );
      }
    });
  }

  /// Get all readers for a specific message
  Future<List<ReadReceiptInfo>> getReadersForMessage(String eventId) async {
    final results = await _db
        .customSelect(
          '''
      SELECT rr.event_id, rr.profile_id, rr.read_at, p.name as display_name
      FROM read_receipts rr
      LEFT JOIN profiles p ON rr.profile_id = p.id
      WHERE rr.event_id = ?
      ORDER BY rr.read_at DESC
      ''',
          variables: [Variable.withString(eventId)],
        )
        .get();

    return results
        .map(
          (row) => ReadReceiptInfo(
            eventId: row.read<String>('event_id'),
            profileId: row.read<String>('profile_id'),
            readAt: row.read<int>('read_at'),
            displayName: row.readNullable<String>('display_name'),
          ),
        )
        .toList();
  }

  /// Watch readers for a specific message (reactive)
  Stream<List<ReadReceiptInfo>> watchReadersForMessage(String eventId) {
    return _db
        .customSelect(
          '''
      SELECT rr.event_id, rr.profile_id, rr.read_at, p.name as display_name
      FROM read_receipts rr
      LEFT JOIN profiles p ON rr.profile_id = p.id
      WHERE rr.event_id = ?
      ORDER BY rr.read_at DESC
      ''',
          variables: [Variable.withString(eventId)],
          readsFrom: {_db.readReceipts, _db.profiles},
        )
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => ReadReceiptInfo(
                  eventId: row.read<String>('event_id'),
                  profileId: row.read<String>('profile_id'),
                  readAt: row.read<int>('read_at'),
                  displayName: row.readNullable<String>('display_name'),
                ),
              )
              .toList(),
        );
  }

  /// Get the count of readers for a message
  Future<int> getReadCount(String eventId) async {
    final result = await _db
        .customSelect(
          'SELECT COUNT(*) as count FROM read_receipts WHERE event_id = ?',
          variables: [Variable.withString(eventId)],
        )
        .getSingle();
    return result.read<int>('count');
  }

  /// Check if a specific user has read a message
  Future<bool> hasUserRead(String eventId, String profileId) async {
    final result = await _db
        .customSelect(
          'SELECT 1 FROM read_receipts WHERE event_id = ? AND profile_id = ? LIMIT 1',
          variables: [
            Variable.withString(eventId),
            Variable.withString(profileId),
          ],
        )
        .getSingleOrNull();
    return result != null;
  }

  /// Delete all read receipts for a room (for cleanup)
  Future<void> deleteReceiptsForRoom(String roomId) async {
    await (_db.delete(
      _db.readReceipts,
    )..where((r) => r.roomId.equals(roomId))).go();
  }

  /// Delete read receipts for specific events
  Future<void> deleteReceiptsForEvents(List<String> eventIds) async {
    await (_db.delete(
      _db.readReceipts,
    )..where((r) => r.eventId.isIn(eventIds))).go();
  }

  /// Mark all messages in a room as read
  ///
  /// This resets the unread count for the room and creates read receipts
  /// for all unread messages. Used when user marks room as read from
  /// notification action.
  Future<void> markRoomAsRead(String roomId) async {
    // Reset unread count in room
    await _db.customStatement(
      'UPDATE rooms SET unread_count = 0 WHERE id = ?',
      [roomId],
    );

    // Note: In a full implementation, we would also:
    // 1. Send read receipts to the server for sync
    // 2. Create individual read receipts for unread messages
    // For now, just reset the local unread count
  }
}

/// Provider for ReadReceiptRepository
@Riverpod(keepAlive: true)
ReadReceiptRepository readReceiptRepository(Ref ref) {
  return ReadReceiptRepository(AppDatabase.instance);
}

/// Provider for watching readers of a specific message
@riverpod
Stream<List<ReadReceiptInfo>> messageReaders(Ref ref, String eventId) {
  final repo = ref.watch(readReceiptRepositoryProvider);
  return repo.watchReadersForMessage(eventId);
}
