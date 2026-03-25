import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';
import '../../../core/logging/app_logger.dart';
import '../data/roster_repository.dart';

part 'block_service.g.dart';

/// Service for managing blocked users
///
/// Provides functionality to:
/// - Block users locally and on server
/// - Unblock users
/// - Check if a user is blocked
/// - Get list of blocked users
/// - Filter messages from blocked users
class BlockService {
  BlockService(this._database, this._rosterRepository);

  final AppDatabase _database;
  final RosterRepository _rosterRepository;

  // ============================================================================
  // Block/Unblock Operations
  // ============================================================================

  /// Block a user by their profile ID
  ///
  /// Sets isBlocked to true in the roster entry.
  /// Blocked users cannot message you and their messages are hidden.
  Future<void> blockUser(String profileId) async {
    try {
      AppLogger.info(
        '[BlockService] Blocking user',
        data: {'profileId': profileId},
      );

      // Update roster entry to blocked
      await (_database.update(_database.roster)
            ..where((t) => t.profileId.equals(profileId)))
          .write(const RosterCompanion(isBlocked: Value(true)));

      AppLogger.info(
        '[BlockService] User blocked successfully',
        data: {'profileId': profileId},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '[BlockService] Failed to block user',
        error: e,
        stackTrace: stackTrace,
        data: {'profileId': profileId},
      );
      rethrow;
    }
  }

  /// Block a user by their roster entry ID
  Future<void> blockUserByRosterId(String rosterId) async {
    try {
      AppLogger.info(
        '[BlockService] Blocking user by roster ID',
        data: {'rosterId': rosterId},
      );

      await _rosterRepository.blockRosterEntry(rosterId);

      AppLogger.info(
        '[BlockService] User blocked successfully',
        data: {'rosterId': rosterId},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '[BlockService] Failed to block user by roster ID',
        error: e,
        stackTrace: stackTrace,
        data: {'rosterId': rosterId},
      );
      rethrow;
    }
  }

  /// Unblock a user by their profile ID
  Future<void> unblockUser(String profileId) async {
    try {
      AppLogger.info(
        '[BlockService] Unblocking user',
        data: {'profileId': profileId},
      );

      await (_database.update(_database.roster)
            ..where((t) => t.profileId.equals(profileId)))
          .write(const RosterCompanion(isBlocked: Value(false)));

      AppLogger.info(
        '[BlockService] User unblocked successfully',
        data: {'profileId': profileId},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '[BlockService] Failed to unblock user',
        error: e,
        stackTrace: stackTrace,
        data: {'profileId': profileId},
      );
      rethrow;
    }
  }

  /// Unblock a user by their roster entry ID
  Future<void> unblockUserByRosterId(String rosterId) async {
    try {
      AppLogger.info(
        '[BlockService] Unblocking user by roster ID',
        data: {'rosterId': rosterId},
      );

      await _rosterRepository.unblockRosterEntry(rosterId);

      AppLogger.info(
        '[BlockService] User unblocked successfully',
        data: {'rosterId': rosterId},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '[BlockService] Failed to unblock user by roster ID',
        error: e,
        stackTrace: stackTrace,
        data: {'rosterId': rosterId},
      );
      rethrow;
    }
  }

  // ============================================================================
  // Query Operations
  // ============================================================================

  /// Check if a user is blocked by their profile ID
  Future<bool> isUserBlocked(String profileId) async {
    final query = _database.select(_database.roster)
      ..where((t) => t.profileId.equals(profileId) & t.isBlocked.equals(true));

    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// Check if a user is blocked by their roster entry ID
  Future<bool> isUserBlockedByRosterId(String rosterId) async {
    final query = _database.select(_database.roster)
      ..where((t) => t.id.equals(rosterId) & t.isBlocked.equals(true));

    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// Get all blocked users
  Future<List<RosterEntry>> getBlockedUsers() async {
    return _rosterRepository.getBlockedEntries();
  }

  /// Watch blocked users as a stream for reactive UI updates
  Stream<List<RosterData>> watchBlockedUsers() {
    final query = _database.select(_database.roster)
      ..where((t) => t.isBlocked.equals(true))
      ..orderBy([(t) => OrderingTerm.asc(t.displayName)]);

    return query.watch();
  }

  /// Get count of blocked users
  Future<int> getBlockedCount() async {
    final query = _database.select(_database.roster)
      ..where((t) => t.isBlocked.equals(true));
    final results = await query.get();
    return results.length;
  }

  /// Get set of blocked profile IDs for efficient filtering
  Future<Set<String>> getBlockedProfileIds() async {
    final query = _database.select(_database.roster)
      ..where((t) => t.isBlocked.equals(true));

    final results = await query.get();
    return results
        .where((r) => r.profileId != null)
        .map((r) => r.profileId!)
        .toSet();
  }

  /// Watch blocked profile IDs as a stream
  Stream<Set<String>> watchBlockedProfileIds() {
    final query = _database.select(_database.roster)
      ..where((t) => t.isBlocked.equals(true));

    return query.watch().map(
      (results) => results
          .where((r) => r.profileId != null)
          .map((r) => r.profileId!)
          .toSet(),
    );
  }
}

// ============================================================================
// Providers
// ============================================================================

@riverpod
Future<BlockService> blockService(Ref ref) async {
  final rosterRepo = await ref.watch(rosterRepositoryProvider.future);
  return BlockService(AppDatabase.instance, rosterRepo);
}

/// Provider for blocked users list
@riverpod
Future<List<RosterEntry>> blockedUsers(Ref ref) async {
  final service = await ref.watch(blockServiceProvider.future);
  return service.getBlockedUsers();
}

/// Stream provider for watching blocked users reactively
final blockedUsersStreamProvider = StreamProvider<List<RosterData>>((ref) {
  final db = AppDatabase.instance;
  final query = db.select(db.roster)
    ..where((t) => t.isBlocked.equals(true))
    ..orderBy([(t) => OrderingTerm.asc(t.displayName)]);

  return query.watch();
});

/// Provider for blocked profile IDs set
@riverpod
Future<Set<String>> blockedProfileIds(Ref ref) async {
  final service = await ref.watch(blockServiceProvider.future);
  return service.getBlockedProfileIds();
}

/// Stream provider for watching blocked profile IDs
final blockedProfileIdsStreamProvider = StreamProvider<Set<String>>((ref) {
  final db = AppDatabase.instance;
  final query = db.select(db.roster)..where((t) => t.isBlocked.equals(true));

  return query.watch().map(
    (results) => results
        .where((r) => r.profileId != null)
        .map((r) => r.profileId!)
        .toSet(),
  );
});

/// Provider to check if a specific user is blocked
@riverpod
Future<bool> isUserBlockedProvider(Ref ref, String profileId) async {
  final service = await ref.watch(blockServiceProvider.future);
  return service.isUserBlocked(profileId);
}
