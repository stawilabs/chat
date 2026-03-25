import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart' as db;
import 'analytics_event.dart';

/// Repository for storing and retrieving analytics events from local database
///
/// Provides persistence layer for analytics events with batch sync capabilities.
class AnalyticsRepository {
  AnalyticsRepository(this._database);

  final db.AppDatabase _database;

  /// Insert a new analytics event
  Future<int> insertEvent(AnalyticsEvent event) async {
    return _database
        .into(_database.analyticsEvents)
        .insert(
          db.AnalyticsEventsCompanion.insert(
            eventId: event.id,
            eventType: event.type.name,
            eventName: event.name,
            userId: Value(event.userId),
            sessionId: Value(event.sessionId),
            screenName: Value(event.screenName),
            properties: Value(
              event.properties != null ? jsonEncode(event.properties) : null,
            ),
            timestamp: event.timestamp.millisecondsSinceEpoch,
            isSynced: const Value(false),
          ),
        );
  }

  /// Insert multiple analytics events in a batch
  Future<void> insertEvents(List<AnalyticsEvent> events) async {
    await _database.batch((batch) {
      for (final event in events) {
        batch.insert(
          _database.analyticsEvents,
          db.AnalyticsEventsCompanion.insert(
            eventId: event.id,
            eventType: event.type.name,
            eventName: event.name,
            userId: Value(event.userId),
            sessionId: Value(event.sessionId),
            screenName: Value(event.screenName),
            properties: Value(
              event.properties != null ? jsonEncode(event.properties) : null,
            ),
            timestamp: event.timestamp.millisecondsSinceEpoch,
            isSynced: const Value(false),
          ),
        );
      }
    });
  }

  /// Get all unsynced events
  Future<List<AnalyticsEvent>> getUnsyncedEvents({int limit = 100}) async {
    final query = _database.select(_database.analyticsEvents)
      ..where((t) => t.isSynced.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)])
      ..limit(limit);

    final rows = await query.get();
    return rows.map(_rowToEvent).toList();
  }

  /// Mark events as synced
  Future<void> markEventsSynced(List<String> eventIds) async {
    await (_database.update(
      _database.analyticsEvents,
    )..where((t) => t.eventId.isIn(eventIds))).write(
      db.AnalyticsEventsCompanion(
        isSynced: const Value(true),
        syncedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Delete synced events older than the specified duration
  Future<int> deleteSyncedEventsOlderThan(Duration duration) async {
    final cutoff = DateTime.now().subtract(duration).millisecondsSinceEpoch;
    return (_database.delete(_database.analyticsEvents)..where(
          (t) =>
              t.isSynced.equals(true) & t.timestamp.isSmallerThanValue(cutoff),
        ))
        .go();
  }

  /// Delete all synced events
  Future<int> deleteAllSyncedEvents() async {
    return (_database.delete(
      _database.analyticsEvents,
    )..where((t) => t.isSynced.equals(true))).go();
  }

  /// Get count of unsynced events
  Future<int> getUnsyncedEventCount() async {
    final query = _database.selectOnly(_database.analyticsEvents)
      ..where(_database.analyticsEvents.isSynced.equals(false))
      ..addColumns([_database.analyticsEvents.id.count()]);

    final result = await query.getSingle();
    return result.read(_database.analyticsEvents.id.count()) ?? 0;
  }

  /// Get total event count
  Future<int> getTotalEventCount() async {
    final query = _database.selectOnly(_database.analyticsEvents)
      ..addColumns([_database.analyticsEvents.id.count()]);

    final result = await query.getSingle();
    return result.read(_database.analyticsEvents.id.count()) ?? 0;
  }

  /// Get events by session ID
  Future<List<AnalyticsEvent>> getEventsBySession(String sessionId) async {
    final query = _database.select(_database.analyticsEvents)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]);

    final rows = await query.get();
    return rows.map(_rowToEvent).toList();
  }

  /// Get events by type
  Future<List<AnalyticsEvent>> getEventsByType(
    AnalyticsEventType type, {
    int limit = 100,
    int offset = 0,
  }) async {
    final query = _database.select(_database.analyticsEvents)
      ..where((t) => t.eventType.equals(type.name))
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map(_rowToEvent).toList();
  }

  /// Get events in a time range
  Future<List<AnalyticsEvent>> getEventsInRange(
    DateTime start,
    DateTime end, {
    int limit = 1000,
  }) async {
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;

    final query = _database.select(_database.analyticsEvents)
      ..where(
        (t) =>
            t.timestamp.isBiggerOrEqualValue(startMs) &
            t.timestamp.isSmallerOrEqualValue(endMs),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)])
      ..limit(limit);

    final rows = await query.get();
    return rows.map(_rowToEvent).toList();
  }

  /// Clear all analytics events
  Future<int> clearAllEvents() async {
    return _database.delete(_database.analyticsEvents).go();
  }

  /// Convert database row to AnalyticsEvent
  AnalyticsEvent _rowToEvent(db.AnalyticsEvent row) {
    Map<String, dynamic>? properties;
    if (row.properties != null) {
      properties = jsonDecode(row.properties!) as Map<String, dynamic>;
    }

    return AnalyticsEvent(
      id: row.eventId,
      type: AnalyticsEventType.values.firstWhere(
        (t) => t.name == row.eventType,
        orElse: () => AnalyticsEventType.custom,
      ),
      name: row.eventName,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        row.timestamp,
        isUtc: true,
      ),
      userId: row.userId,
      sessionId: row.sessionId,
      screenName: row.screenName,
      properties: properties,
      isSynced: row.isSynced,
    );
  }
}

/// Provider for the analytics repository
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(db.AppDatabase.instance);
});
