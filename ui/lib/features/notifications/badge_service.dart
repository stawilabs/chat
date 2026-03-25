// ignore_for_file: unused_field

import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/logging/app_logger.dart';
import '../../core/settings/settings_service.dart';

/// Setting key for badge muted chat preference
const String kBadgeIncludeMutedChats = 'badge_include_muted_chats';

/// Default value for including muted chats in badge count
const bool kBadgeIncludeMutedChatsDefault = true;

/// Provider for BadgeService
final badgeServiceProvider = Provider<BadgeService>((ref) {
  final database = AppDatabase.instance;
  final settingsService = ref.watch(settingsServiceProvider);
  return BadgeService(database, settingsService);
});

/// Provider for initializing the badge service (call during app startup)
final badgeServiceInitializedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(badgeServiceProvider);
  await service.initialize();
  return true;
});

/// Service for managing app icon badge count
///
/// Provides real-time badge updates based on unread message counts:
/// - Listens to room unread count changes from the database
/// - Updates the app icon badge using flutter_app_badger
/// - Clears badge when all messages are read
/// - Optionally respects muted chat settings
///
/// Example:
/// ```dart
/// final badgeService = ref.read(badgeServiceProvider);
/// await badgeService.initialize();
/// // Badge will now update automatically based on unread counts
/// ```
class BadgeService {
  BadgeService(this._database, this._settingsService);

  final AppDatabase _database;
  final SettingsService _settingsService;
  StreamSubscription<int>? _unreadCountSubscription;
  bool _initialized = false;
  int _lastBadgeCount = 0;

  /// Whether the badge service has been initialized
  bool get isInitialized => _initialized;

  /// Current badge count (last known value)
  int get currentBadgeCount => _lastBadgeCount;

  /// Initialize the badge service
  ///
  /// Sets up a listener on the database to watch for unread count changes
  /// and updates the app icon badge accordingly.
  Future<void> initialize() async {
    if (_initialized) {
      AppLogger.debug('BadgeService already initialized');
      return;
    }

    if (!isSupported) {
      AppLogger.debug('BadgeService not supported on this platform');
      _initialized = true;
      return;
    }

    try {
      // Check if app badging is supported on this device
      final supported = await AppBadgePlus.isSupported();
      if (!supported) {
        AppLogger.warning('App badge not supported on this device');
        _initialized = true;
        return;
      }

      // Start listening to unread count changes
      _startListening();

      _initialized = true;
      AppLogger.info('BadgeService initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to initialize BadgeService',
        error: e,
        stackTrace: stackTrace,
      );
      // Mark as initialized even on error to prevent repeated attempts
      _initialized = true;
    }
  }

  /// Start listening to unread count changes from the database
  void _startListening() {
    // Watch for changes and update badge
    _unreadCountSubscription = _createUnreadCountQuery()
        .watchSingle()
        .map((row) {
          final sum = row.read(_database.rooms.unreadCount.sum());
          return sum ?? 0;
        })
        .listen(
          _onUnreadCountChanged,
          onError: (Object error, StackTrace stackTrace) {
            AppLogger.error(
              'Error watching unread count',
              error: error,
              stackTrace: stackTrace,
            );
          },
        );
  }

  /// Create a query that sums all unread counts from rooms
  JoinedSelectStatement<HasResultSet, dynamic> _createUnreadCountQuery() {
    return _database.selectOnly(_database.rooms)
      ..addColumns([_database.rooms.unreadCount.sum()]);
  }

  /// Handle unread count changes
  Future<void> _onUnreadCountChanged(int totalUnread) async {
    // TODO(antinvestor): When muted chats feature is implemented, filter based on setting:
    // final includeMutedChats = _settingsService.getBool(
    //   kBadgeIncludeMutedChats,
    //   defaultValue: kBadgeIncludeMutedChatsDefault,
    // );
    // For now, we use the total unread count
    final badgeCount = totalUnread;

    await _updateBadge(badgeCount);
  }

  /// Update the app icon badge
  Future<void> _updateBadge(int count) async {
    if (count == _lastBadgeCount) {
      return; // No change needed
    }

    _lastBadgeCount = count;

    try {
      if (count <= 0) {
        await AppBadgePlus.updateBadge(0);
        AppLogger.debug('Badge cleared');
      } else {
        await AppBadgePlus.updateBadge(count);
        AppLogger.debug('Badge updated', data: {'count': count});
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to update badge',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Manually refresh the badge count
  ///
  /// This can be called after background sync to ensure badge is up to date.
  /// Works independently of initialization state, making it safe for background tasks.
  Future<void> refreshBadge() async {
    if (!isSupported) {
      return;
    }

    try {
      // Check device support if not already initialized
      if (!_initialized) {
        final supported = await AppBadgePlus.isSupported();
        if (!supported) {
          AppLogger.warning(
            'App badge not supported on this device, skipping refresh.',
          );
          return;
        }
      }

      final row = await _createUnreadCountQuery().getSingle();
      final totalUnread = row.read(_database.rooms.unreadCount.sum()) ?? 0;

      await _onUnreadCountChanged(totalUnread);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to refresh badge',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clear the badge (e.g., when user logs out)
  Future<void> clearBadge() async {
    if (!isSupported) {
      return;
    }

    try {
      await AppBadgePlus.updateBadge(0);
      _lastBadgeCount = 0;
      AppLogger.debug('Badge cleared manually');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to clear badge',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Dispose of the service and stop listening
  void dispose() {
    _unreadCountSubscription?.cancel();
    _unreadCountSubscription = null;
    _initialized = false;
    AppLogger.debug('BadgeService disposed');
  }

  /// Check if badges are supported on the current platform
  static bool get isSupported {
    // Web doesn't support app badges and dart:io Platform throws on web
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }
}
