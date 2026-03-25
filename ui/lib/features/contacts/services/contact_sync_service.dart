import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/settings/settings_service.dart';
import '../data/roster_repository.dart';

part 'contact_sync_service.g.dart';

/// Interface for contact sync operations
///
/// This allows for easy mocking in tests while providing a clear contract
/// for what the sync service needs from the roster repository.
abstract class ContactSyncRepository {
  /// Check if contacts have changed since last sync (hash-based)
  Future<bool> needsSync();

  /// Sync all contacts with the server
  Future<List<RosterEntry>> syncContacts({
    SyncProgressCallback? progressCallback,
  });
}

/// Settings keys for contact sync
class ContactSyncSettings {
  /// Whether automatic contact sync is enabled
  static const autoSyncEnabled = 'contact_auto_sync_enabled';

  /// Last successful sync timestamp (milliseconds since epoch)
  static const lastSyncTime = 'contact_last_sync_time';

  /// Sync interval in hours (default 24)
  static const syncIntervalHours = 'contact_sync_interval_hours';

  /// Whether to sync only on Wi-Fi
  static const syncOnlyOnWifi = 'contact_sync_only_wifi';
}

/// Default values for contact sync settings
class ContactSyncDefaults {
  static const autoSyncEnabled = true;
  static const syncIntervalHours = 24;
  static const syncOnlyOnWifi = false;

  /// Minimum allowed sync interval in hours
  static const minSyncIntervalHours = 1;

  /// Maximum allowed sync interval in hours (1 week)
  static const maxSyncIntervalHours = 168;
}

/// Result of a contact sync operation
class ContactSyncResult {
  const ContactSyncResult({
    required this.success,
    required this.syncedCount,
    required this.foundOnPlatform,
    this.error,
    this.isIncremental = false,
    this.duration,
  });

  /// Whether the sync completed successfully
  final bool success;

  /// Number of contacts synced
  final int syncedCount;

  /// Number of contacts found on the platform
  final int foundOnPlatform;

  /// Error message if sync failed
  final String? error;

  /// Whether this was an incremental sync (only changes)
  final bool isIncremental;

  /// Duration of the sync operation
  final Duration? duration;

  @override
  String toString() =>
      'ContactSyncResult('
      'success: $success, '
      'syncedCount: $syncedCount, '
      'foundOnPlatform: $foundOnPlatform, '
      'isIncremental: $isIncremental, '
      'duration: ${duration?.inMilliseconds}ms'
      '${error != null ? ", error: $error" : ""}'
      ')';
}

/// Service for managing contact synchronization
///
/// Features:
/// - Full sync on permission grant (syncs all phone contacts)
/// - Incremental sync (only syncs changes based on hash)
/// - Background sync every 24 hours using Workmanager
/// - Settings for enabling/disabling auto-sync
/// - Tracks last sync time
class ContactSyncService {
  ContactSyncService({
    required ContactSyncRepository syncRepository,
    required SettingsService settingsService,
  }) : _syncRepository = syncRepository,
       _settingsService = settingsService;

  final ContactSyncRepository _syncRepository;
  final SettingsService _settingsService;

  // Sync state tracking
  bool _isSyncing = false;
  Completer<ContactSyncResult>? _syncCompleter;

  /// Whether a sync is currently in progress
  bool get isSyncing => _isSyncing;

  // ============================================================================
  // Settings Management
  // ============================================================================

  /// Whether automatic contact sync is enabled
  bool get isAutoSyncEnabled => _settingsService.getBool(
    ContactSyncSettings.autoSyncEnabled,
    defaultValue: ContactSyncDefaults.autoSyncEnabled,
  );

  /// Enable or disable automatic contact sync
  Future<void> setAutoSyncEnabled(bool enabled) async {
    await _settingsService.setBool(
      ContactSyncSettings.autoSyncEnabled,
      enabled,
    );
    AppLogger.info(
      '[ContactSyncService] Auto sync ${enabled ? "enabled" : "disabled"}',
    );
  }

  /// Get the last sync timestamp
  DateTime? get lastSyncTime {
    final timestamp = _settingsService.getInt(ContactSyncSettings.lastSyncTime);
    if (timestamp == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Update the last sync timestamp
  Future<void> _updateLastSyncTime() async {
    await _settingsService.setInt(
      ContactSyncSettings.lastSyncTime,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Get the sync interval in hours
  int get syncIntervalHours => _settingsService.getInt(
    ContactSyncSettings.syncIntervalHours,
    defaultValue: ContactSyncDefaults.syncIntervalHours,
  );

  /// Set the sync interval in hours
  Future<void> setSyncIntervalHours(int hours) async {
    final clampedHours = hours.clamp(
      ContactSyncDefaults.minSyncIntervalHours,
      ContactSyncDefaults.maxSyncIntervalHours,
    );
    await _settingsService.setInt(
      ContactSyncSettings.syncIntervalHours,
      clampedHours,
    );
    AppLogger.debug(
      '[ContactSyncService] Sync interval set to $clampedHours hours',
    );
  }

  /// Whether to sync only on Wi-Fi
  bool get syncOnlyOnWifi =>
      _settingsService.getBool(ContactSyncSettings.syncOnlyOnWifi);

  /// Set whether to sync only on Wi-Fi
  Future<void> setSyncOnlyOnWifi(bool wifiOnly) async {
    await _settingsService.setBool(
      ContactSyncSettings.syncOnlyOnWifi,
      wifiOnly,
    );
    AppLogger.debug('[ContactSyncService] Sync only on Wi-Fi: $wifiOnly');
  }

  // ============================================================================
  // Sync Operations
  // ============================================================================

  /// Check if a sync is due based on the last sync time and interval
  bool isSyncDue() {
    final lastSync = lastSyncTime;
    if (lastSync == null) {
      AppLogger.debug('[ContactSyncService] No previous sync, sync is due');
      return true;
    }

    final now = DateTime.now();
    final intervalDuration = Duration(hours: syncIntervalHours);
    final nextSyncTime = lastSync.add(intervalDuration);

    final isDue = now.isAfter(nextSyncTime);
    AppLogger.debug(
      '[ContactSyncService] Sync due check',
      data: {
        'lastSync': lastSync.toIso8601String(),
        'nextSyncTime': nextSyncTime.toIso8601String(),
        'isDue': isDue,
      },
    );

    return isDue;
  }

  /// Perform a full sync of all contacts
  ///
  /// This syncs all phone contacts regardless of whether they've changed.
  /// Used when permission is first granted or when user explicitly requests.
  Future<ContactSyncResult> performFullSync({
    SyncProgressCallback? progressCallback,
  }) async {
    // If a sync is already in progress, wait for it to complete
    if (_isSyncing && _syncCompleter != null) {
      AppLogger.debug(
        '[ContactSyncService] Full sync already in progress, waiting...',
      );
      return _syncCompleter!.future;
    }

    // Mark sync as in progress and create completer for coalescing
    _isSyncing = true;
    _syncCompleter = Completer<ContactSyncResult>();
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.info('[ContactSyncService] Starting full contact sync');

      final syncedEntries = await _syncRepository.syncContacts(
        progressCallback: progressCallback,
      );

      stopwatch.stop();

      final result = ContactSyncResult(
        success: true,
        syncedCount: syncedEntries.length,
        foundOnPlatform: syncedEntries.where((e) => e.profileId != null).length,
        duration: stopwatch.elapsed,
      );

      await _updateLastSyncTime();

      AppLogger.info(
        '[ContactSyncService] Full sync completed',
        data: {
          'syncedCount': result.syncedCount,
          'foundOnPlatform': result.foundOnPlatform,
          'durationMs': stopwatch.elapsedMilliseconds,
        },
      );

      _syncCompleter?.complete(result);
      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();

      AppLogger.error(
        '[ContactSyncService] Full sync failed',
        error: e,
        stackTrace: stackTrace,
      );

      final result = ContactSyncResult(
        success: false,
        syncedCount: 0,
        foundOnPlatform: 0,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );

      _syncCompleter?.complete(result);
      return result;
    } finally {
      _isSyncing = false;
      _syncCompleter = null;
    }
  }

  /// Perform an incremental sync (only changes)
  ///
  /// Uses hash-based change detection to only sync when contacts have changed.
  /// More efficient for regular background syncs.
  Future<ContactSyncResult> performIncrementalSync({
    SyncProgressCallback? progressCallback,
  }) async {
    // If a sync is already in progress, wait for it to complete
    if (_isSyncing && _syncCompleter != null) {
      AppLogger.debug(
        '[ContactSyncService] Incremental sync already in progress, waiting...',
      );
      return _syncCompleter!.future;
    }

    // Mark sync as in progress and create completer for coalescing
    _isSyncing = true;
    _syncCompleter = Completer<ContactSyncResult>();
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.info('[ContactSyncService] Starting incremental contact sync');

      // Check if sync is needed (hash-based change detection)
      final needsSync = await _syncRepository.needsSync();
      if (!needsSync) {
        stopwatch.stop();

        AppLogger.info(
          '[ContactSyncService] No changes detected, skipping sync',
        );

        // Still update last sync time as we successfully checked
        await _updateLastSyncTime();

        final result = ContactSyncResult(
          success: true,
          syncedCount: 0,
          foundOnPlatform: 0,
          isIncremental: true,
          duration: stopwatch.elapsed,
        );

        _syncCompleter?.complete(result);
        return result;
      }

      // Changes detected, perform sync
      final syncedEntries = await _syncRepository.syncContacts(
        progressCallback: progressCallback,
      );

      stopwatch.stop();

      final result = ContactSyncResult(
        success: true,
        syncedCount: syncedEntries.length,
        foundOnPlatform: syncedEntries.where((e) => e.profileId != null).length,
        isIncremental: true,
        duration: stopwatch.elapsed,
      );

      await _updateLastSyncTime();

      AppLogger.info(
        '[ContactSyncService] Incremental sync completed',
        data: {
          'syncedCount': result.syncedCount,
          'foundOnPlatform': result.foundOnPlatform,
          'durationMs': stopwatch.elapsedMilliseconds,
        },
      );

      _syncCompleter?.complete(result);
      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();

      AppLogger.error(
        '[ContactSyncService] Incremental sync failed',
        error: e,
        stackTrace: stackTrace,
      );

      final result = ContactSyncResult(
        success: false,
        syncedCount: 0,
        foundOnPlatform: 0,
        error: e.toString(),
        isIncremental: true,
        duration: stopwatch.elapsed,
      );

      _syncCompleter?.complete(result);
      return result;
    } finally {
      _isSyncing = false;
      _syncCompleter = null;
    }
  }

  /// Perform background sync
  ///
  /// Called by the background task scheduler. Only syncs if:
  /// - Auto sync is enabled
  /// - Sync is due (based on interval)
  /// - Uses incremental sync (only changes)
  Future<ContactSyncResult> performBackgroundSync() async {
    AppLogger.info('[ContactSyncService] Background sync triggered');

    // Check if auto sync is enabled
    if (!isAutoSyncEnabled) {
      AppLogger.debug(
        '[ContactSyncService] Auto sync is disabled, skipping background sync',
      );
      return const ContactSyncResult(
        success: true,
        syncedCount: 0,
        foundOnPlatform: 0,
      );
    }

    // Check if sync is due
    if (!isSyncDue()) {
      AppLogger.debug(
        '[ContactSyncService] Sync not due yet, skipping background sync',
      );
      return const ContactSyncResult(
        success: true,
        syncedCount: 0,
        foundOnPlatform: 0,
      );
    }

    // Perform incremental sync
    return performIncrementalSync();
  }

  /// Sync contacts on permission grant
  ///
  /// Called when the user grants contact permission for the first time.
  /// Performs a full sync of all contacts.
  Future<ContactSyncResult> syncOnPermissionGrant({
    SyncProgressCallback? progressCallback,
  }) async {
    AppLogger.info(
      '[ContactSyncService] Contact permission granted, starting full sync',
    );

    // Enable auto sync by default when permission is granted
    await setAutoSyncEnabled(true);

    // Perform full sync
    return performFullSync(progressCallback: progressCallback);
  }

  /// Get sync status information
  ContactSyncStatus getStatus() => ContactSyncStatus(
    isAutoSyncEnabled: isAutoSyncEnabled,
    lastSyncTime: lastSyncTime,
    syncIntervalHours: syncIntervalHours,
    syncOnlyOnWifi: syncOnlyOnWifi,
    isSyncing: _isSyncing,
    isSyncDue: isSyncDue(),
  );
}

/// Status information for contact sync
class ContactSyncStatus {
  const ContactSyncStatus({
    required this.isAutoSyncEnabled,
    required this.lastSyncTime,
    required this.syncIntervalHours,
    required this.syncOnlyOnWifi,
    required this.isSyncing,
    required this.isSyncDue,
  });

  final bool isAutoSyncEnabled;
  final DateTime? lastSyncTime;
  final int syncIntervalHours;
  final bool syncOnlyOnWifi;
  final bool isSyncing;
  final bool isSyncDue;

  /// Get a human-readable description of when the next sync will occur
  String get nextSyncDescription {
    if (!isAutoSyncEnabled) return 'Auto sync disabled';
    if (lastSyncTime == null) return 'Never synced';

    final nextSync = lastSyncTime!.add(Duration(hours: syncIntervalHours));
    final now = DateTime.now();

    if (now.isAfter(nextSync)) return 'Sync pending';

    final remaining = nextSync.difference(now);
    if (remaining.inHours > 0) {
      return 'Next sync in ${remaining.inHours}h ${remaining.inMinutes % 60}m';
    } else if (remaining.inMinutes > 0) {
      return 'Next sync in ${remaining.inMinutes}m';
    } else {
      return 'Next sync soon';
    }
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Provider for ContactSyncService
@riverpod
Future<ContactSyncService> contactSyncService(Ref ref) async {
  final rosterRepo = await ref.watch(rosterRepositoryProvider.future);
  final settingsService = ref.watch(settingsServiceProvider);

  return ContactSyncService(
    syncRepository: rosterRepo,
    settingsService: settingsService,
  );
}

/// Provider for contact sync status
@riverpod
Future<ContactSyncStatus> contactSyncStatus(Ref ref) async {
  final service = await ref.watch(contactSyncServiceProvider.future);
  return service.getStatus();
}

/// Provider to check if auto sync is enabled
@riverpod
Future<bool> contactAutoSyncEnabled(Ref ref) async {
  final service = await ref.watch(contactSyncServiceProvider.future);
  return service.isAutoSyncEnabled;
}

/// Provider to check if sync is due
@riverpod
Future<bool> contactSyncDue(Ref ref) async {
  final service = await ref.watch(contactSyncServiceProvider.future);
  return service.isSyncDue();
}
