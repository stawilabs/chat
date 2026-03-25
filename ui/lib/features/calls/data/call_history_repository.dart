import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../domain/call_history_entry.dart';

/// Provider for CallHistoryRepository
final callHistoryRepositoryProvider = Provider<CallHistoryRepository>((ref) {
  return CallHistoryRepository(AppDatabase.instance);
});

/// Repository for managing call history records
///
/// Provides methods for recording calls, fetching history,
/// and managing call records (mark as read, delete, etc.)
class CallHistoryRepository {
  CallHistoryRepository(this._db);

  final AppDatabase _db;

  /// Record a new call in history
  Future<int> recordCall(CallHistoryEntry entry) async {
    final companion = CallHistoryCompanion.insert(
      roomId: entry.roomId,
      callerId: entry.callerId,
      recipientId: Value(entry.recipientId),
      callType: Value(entry.callType.value),
      direction: Value(entry.direction.value),
      status: Value(entry.status.value),
      startedAt: entry.startedAt,
      answeredAt: Value(entry.answeredAt),
      endedAt: Value(entry.endedAt),
      duration: Value(entry.duration),
      isRead: Value(entry.isRead),
      isDeleted: const Value(false),
    );

    return _db.into(_db.callHistory).insert(companion);
  }

  /// Update an existing call record (e.g., when call ends)
  Future<void> updateCall({
    required int callId,
    CallStatus? status,
    int? answeredAt,
    int? endedAt,
    int? duration,
  }) async {
    await (_db.update(
      _db.callHistory,
    )..where((t) => t.id.equals(callId))).write(
      CallHistoryCompanion(
        status: status != null ? Value(status.value) : const Value.absent(),
        answeredAt: answeredAt != null
            ? Value(answeredAt)
            : const Value.absent(),
        endedAt: endedAt != null ? Value(endedAt) : const Value.absent(),
        duration: duration != null ? Value(duration) : const Value.absent(),
      ),
    );
  }

  /// Get all call history entries (excluding deleted)
  Future<List<CallHistoryEntry>> getCallHistory({
    int limit = 100,
    int offset = 0,
  }) async {
    final query = _db.select(_db.callHistory)
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
      ..limit(limit, offset: offset);

    final results = await query.get();
    return results.map(_toCallHistoryEntry).toList();
  }

  /// Get call history for a specific room
  Future<List<CallHistoryEntry>> getCallHistoryForRoom(
    String roomId, {
    int limit = 50,
  }) async {
    final query = _db.select(_db.callHistory)
      ..where((t) => t.roomId.equals(roomId) & t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
      ..limit(limit);

    final results = await query.get();
    return results.map(_toCallHistoryEntry).toList();
  }

  /// Get only missed calls
  Future<List<CallHistoryEntry>> getMissedCalls({int limit = 50}) async {
    final query = _db.select(_db.callHistory)
      ..where(
        (t) =>
            t.status.equals(CallStatus.missed.value) &
            t.isDeleted.equals(false),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
      ..limit(limit);

    final results = await query.get();
    return results.map(_toCallHistoryEntry).toList();
  }

  /// Get count of unread missed calls
  Future<int> getUnreadMissedCallCount() async {
    final query = _db.select(_db.callHistory)
      ..where(
        (t) =>
            t.status.equals(CallStatus.missed.value) &
            t.isRead.equals(false) &
            t.isDeleted.equals(false),
      );

    final results = await query.get();
    return results.length;
  }

  /// Watch call history for reactive updates
  Stream<List<CallHistoryEntry>> watchCallHistory({int limit = 100}) {
    final query = _db.select(_db.callHistory)
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
      ..limit(limit);

    return query.watch().map(
      (results) => results.map(_toCallHistoryEntry).toList(),
    );
  }

  /// Watch missed calls count for badge updates
  Stream<int> watchUnreadMissedCallCount() {
    final query = _db.select(_db.callHistory)
      ..where(
        (t) =>
            t.status.equals(CallStatus.missed.value) &
            t.isRead.equals(false) &
            t.isDeleted.equals(false),
      );

    return query.watch().map((results) => results.length);
  }

  /// Mark a call as read
  Future<void> markAsRead(int callId) async {
    await (_db.update(_db.callHistory)..where((t) => t.id.equals(callId)))
        .write(const CallHistoryCompanion(isRead: Value(true)));
  }

  /// Mark all calls as read
  Future<int> markAllAsRead() async {
    return (_db.update(_db.callHistory)..where((t) => t.isRead.equals(false)))
        .write(const CallHistoryCompanion(isRead: Value(true)));
  }

  /// Delete a call from history (soft delete)
  Future<void> deleteCall(int callId) async {
    await (_db.update(_db.callHistory)..where((t) => t.id.equals(callId)))
        .write(const CallHistoryCompanion(isDeleted: Value(true)));
  }

  /// Clear all call history (soft delete)
  Future<int> clearAllHistory() async {
    return (_db.update(_db.callHistory)
          ..where((t) => t.isDeleted.equals(false)))
        .write(const CallHistoryCompanion(isDeleted: Value(true)));
  }

  /// Permanently delete old call records (for storage management)
  Future<int> purgeOldRecords({
    Duration olderThan = const Duration(days: 90),
  }) async {
    final cutoffTime = DateTime.now()
        .subtract(olderThan)
        .millisecondsSinceEpoch;
    return (_db.delete(
      _db.callHistory,
    )..where((t) => t.startedAt.isSmallerThanValue(cutoffTime))).go();
  }

  /// Get a single call by ID
  Future<CallHistoryEntry?> getCallById(int callId) async {
    final query = _db.select(_db.callHistory)
      ..where((t) => t.id.equals(callId));

    final result = await query.getSingleOrNull();
    return result != null ? _toCallHistoryEntry(result) : null;
  }

  /// Get the most recent call for a room
  Future<CallHistoryEntry?> getLastCallForRoom(String roomId) async {
    final query = _db.select(_db.callHistory)
      ..where((t) => t.roomId.equals(roomId) & t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
      ..limit(1);

    final result = await query.getSingleOrNull();
    return result != null ? _toCallHistoryEntry(result) : null;
  }

  /// Convert database row to domain model
  CallHistoryEntry _toCallHistoryEntry(CallHistoryData row) {
    return CallHistoryEntry(
      id: row.id,
      roomId: row.roomId,
      callerId: row.callerId,
      recipientId: row.recipientId,
      callType: CallType.fromValue(row.callType),
      direction: CallDirection.fromValue(row.direction),
      status: CallStatus.fromValue(row.status),
      startedAt: row.startedAt,
      answeredAt: row.answeredAt,
      endedAt: row.endedAt,
      duration: row.duration,
      isRead: row.isRead,
      isDeleted: row.isDeleted,
    );
  }
}
