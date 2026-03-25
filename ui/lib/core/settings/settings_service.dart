import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../logging/app_logger.dart';

/// Provider for SettingsService
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(AppDatabase.instance);
});

/// Provider for settings initialization (call early in app startup)
final settingsInitializedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(settingsServiceProvider);
  await service.initialize();
  return true;
});

/// Typed settings keys
class SettingsKeys {
  // Appearance
  static const themeMode = 'theme_mode';
  static const fontSize = 'font_size';
  static const chatWallpaper = 'chat_wallpaper';
  static const accentColor = 'accent_color';

  // Notifications
  static const notificationSound = 'notification_sound';
  static const notificationVibrate = 'notification_vibrate';
  static const notificationPreviewEnabled = 'notification_preview_enabled';

  // Media
  static const autoDownloadWifi = 'auto_download_wifi';
  static const autoDownloadMobile = 'auto_download_mobile';

  // Privacy
  static const readReceiptsEnabled = 'read_receipts_enabled';
  static const typingIndicatorsEnabled = 'typing_indicators_enabled';
  static const lastSeenVisible = 'last_seen_visible';
  static const profilePhotoVisible = 'profile_photo_visible';
  static const aboutVisible = 'about_visible';
  static const groupsAddPermission = 'groups_add_permission';

  // Security
  static const biometricEnabled = 'biometric_enabled';
  static const lockTimeoutMinutes = 'lock_timeout_minutes';
  static const showNotificationsLocked = 'show_notifications_locked';
  static const fingerprintLockEnabled = 'fingerprint_lock_enabled';

  // Location
  static const liveLocationSharingEnabled = 'live_location_sharing_enabled';

  // Data
  static const backupEnabled = 'backup_enabled';
  static const backupFrequency = 'backup_frequency';

  // Analytics
  static const analyticsEnabled = 'analytics_enabled';

  // Media Cache
  static const mediaCacheSizeBytes = 'media_cache_size_bytes';
  static const perRoomCacheEnabled = 'per_room_cache_enabled';

  // Contact Sync
  static const contactSyncInitialized = 'contact_sync_initialized';
  static const contactPermissionDenied = 'contact_permission_denied';
}

/// Default setting values
class SettingsDefaults {
  static const themeMode = 'system';
  static const fontSize = 'medium';
  static const notificationSound = true;
  static const notificationVibrate = true;
  static const notificationPreviewEnabled = true;
  static const autoDownloadWifi = true;
  static const autoDownloadMobile = false;
  static const readReceiptsEnabled = true;
  static const typingIndicatorsEnabled = true;
  static const lastSeenVisible = 'everyone';
  static const profilePhotoVisible = 'everyone';
  static const aboutVisible = 'everyone';
  static const groupsAddPermission = 'everyone';
  static const biometricEnabled = false;
  static const lockTimeoutMinutes = 1;
  static const showNotificationsLocked = true;
  static const fingerprintLockEnabled = false;
  static const liveLocationSharingEnabled = false;
  static const backupEnabled = false;
  static const backupFrequency = 'weekly';
  static const analyticsEnabled = true;
  // Media Cache (500MB default)
  static const mediaCacheSizeBytes = 500 * 1024 * 1024;
  static const perRoomCacheEnabled = false;
}

/// Service for managing user settings persistence
///
/// Provides typed getters/setters for all application settings
/// with automatic caching and database persistence.
class SettingsService {
  SettingsService(this._database);
  final AppDatabase _database;

  /// In-memory cache of settings
  final Map<String, String> _cache = {};

  /// Whether the service has been initialized
  bool _initialized = false;

  /// Initialize the service by loading all settings from database
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final settings = await _database.select(_database.userSettings).get();
      for (final setting in settings) {
        _cache[setting.key] = setting.value;
      }
      _initialized = true;
      AppLogger.debug('Settings loaded', data: {'count': settings.length});
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load settings',
        error: e,
        stackTrace: stackTrace,
      );
      _initialized = true; // Continue with defaults
    }
  }

  /// Get a string setting value
  String getString(String key, {String? defaultValue}) {
    return _cache[key] ?? defaultValue ?? '';
  }

  /// Get a boolean setting value
  bool getBool(String key, {bool defaultValue = false}) {
    final value = _cache[key];
    if (value == null) return defaultValue;
    return value == 'true' || value == '1';
  }

  /// Get an integer setting value
  int getInt(String key, {int defaultValue = 0}) {
    final value = _cache[key];
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  /// Get a JSON setting value
  Map<String, dynamic>? getJson(String key) {
    final value = _cache[key];
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Set a string setting value
  Future<void> setString(String key, String value) async {
    await _setValue(key, value);
  }

  /// Set a boolean setting value
  Future<void> setBool(String key, bool value) async {
    await _setValue(key, value.toString());
  }

  /// Set an integer setting value
  Future<void> setInt(String key, int value) async {
    await _setValue(key, value.toString());
  }

  /// Set a JSON setting value
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await _setValue(key, jsonEncode(value));
  }

  /// Internal method to set a value
  Future<void> _setValue(String key, String value) async {
    _cache[key] = value;

    try {
      await _database
          .into(_database.userSettings)
          .insertOnConflictUpdate(
            UserSettingsCompanion.insert(
              key: key,
              value: value,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
      AppLogger.debug('Setting saved', data: {'key': key});
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to save setting',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Remove a setting
  Future<void> remove(String key) async {
    _cache.remove(key);
    try {
      await (_database.delete(
        _database.userSettings,
      )..where((s) => s.key.equals(key))).go();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to remove setting',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clear all settings (reset to defaults)
  Future<void> clearAll() async {
    _cache.clear();
    try {
      await _database.delete(_database.userSettings).go();
      AppLogger.info('All settings cleared');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to clear settings',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Export all settings as JSON
  Map<String, String> exportSettings() {
    return Map.from(_cache);
  }

  /// Import settings from JSON
  Future<void> importSettings(Map<String, String> settings) async {
    for (final entry in settings.entries) {
      await _setValue(entry.key, entry.value);
    }
    AppLogger.info('Settings imported', data: {'count': settings.length});
  }

  // ============================================================================
  // Typed Convenience Getters/Setters
  // ============================================================================

  // Theme
  String get themeMode => getString(
    SettingsKeys.themeMode,
    defaultValue: SettingsDefaults.themeMode,
  );
  Future<void> setThemeMode(String value) =>
      setString(SettingsKeys.themeMode, value);

  String get fontSize =>
      getString(SettingsKeys.fontSize, defaultValue: SettingsDefaults.fontSize);
  Future<void> setFontSize(String value) =>
      setString(SettingsKeys.fontSize, value);

  String? get chatWallpaper => _cache[SettingsKeys.chatWallpaper];
  Future<void> setChatWallpaper(String? value) => value != null
      ? setString(SettingsKeys.chatWallpaper, value)
      : remove(SettingsKeys.chatWallpaper);

  String? get accentColor => _cache[SettingsKeys.accentColor];
  Future<void> setAccentColor(String? value) => value != null
      ? setString(SettingsKeys.accentColor, value)
      : remove(SettingsKeys.accentColor);

  // Notifications
  bool get notificationSound => getBool(
    SettingsKeys.notificationSound,
    defaultValue: SettingsDefaults.notificationSound,
  );
  Future<void> setNotificationSound(bool value) =>
      setBool(SettingsKeys.notificationSound, value);

  bool get notificationVibrate => getBool(
    SettingsKeys.notificationVibrate,
    defaultValue: SettingsDefaults.notificationVibrate,
  );
  Future<void> setNotificationVibrate(bool value) =>
      setBool(SettingsKeys.notificationVibrate, value);

  bool get notificationPreviewEnabled => getBool(
    SettingsKeys.notificationPreviewEnabled,
    defaultValue: SettingsDefaults.notificationPreviewEnabled,
  );
  Future<void> setNotificationPreviewEnabled(bool value) =>
      setBool(SettingsKeys.notificationPreviewEnabled, value);

  // Media
  bool get autoDownloadWifi => getBool(
    SettingsKeys.autoDownloadWifi,
    defaultValue: SettingsDefaults.autoDownloadWifi,
  );
  Future<void> setAutoDownloadWifi(bool value) =>
      setBool(SettingsKeys.autoDownloadWifi, value);

  bool get autoDownloadMobile => getBool(SettingsKeys.autoDownloadMobile);
  Future<void> setAutoDownloadMobile(bool value) =>
      setBool(SettingsKeys.autoDownloadMobile, value);

  // Privacy
  bool get readReceiptsEnabled => getBool(
    SettingsKeys.readReceiptsEnabled,
    defaultValue: SettingsDefaults.readReceiptsEnabled,
  );
  Future<void> setReadReceiptsEnabled(bool value) =>
      setBool(SettingsKeys.readReceiptsEnabled, value);

  bool get typingIndicatorsEnabled => getBool(
    SettingsKeys.typingIndicatorsEnabled,
    defaultValue: SettingsDefaults.typingIndicatorsEnabled,
  );
  Future<void> setTypingIndicatorsEnabled(bool value) =>
      setBool(SettingsKeys.typingIndicatorsEnabled, value);

  String get lastSeenVisible => getString(
    SettingsKeys.lastSeenVisible,
    defaultValue: SettingsDefaults.lastSeenVisible,
  );
  Future<void> setLastSeenVisible(String value) =>
      setString(SettingsKeys.lastSeenVisible, value);

  String get profilePhotoVisible => getString(
    SettingsKeys.profilePhotoVisible,
    defaultValue: SettingsDefaults.profilePhotoVisible,
  );
  Future<void> setProfilePhotoVisible(String value) =>
      setString(SettingsKeys.profilePhotoVisible, value);

  String get aboutVisible => getString(
    SettingsKeys.aboutVisible,
    defaultValue: SettingsDefaults.aboutVisible,
  );
  Future<void> setAboutVisible(String value) =>
      setString(SettingsKeys.aboutVisible, value);

  String get groupsAddPermission => getString(
    SettingsKeys.groupsAddPermission,
    defaultValue: SettingsDefaults.groupsAddPermission,
  );
  Future<void> setGroupsAddPermission(String value) =>
      setString(SettingsKeys.groupsAddPermission, value);

  // Security
  bool get biometricEnabled => getBool(SettingsKeys.biometricEnabled);
  Future<void> setBiometricEnabled(bool value) =>
      setBool(SettingsKeys.biometricEnabled, value);

  int get lockTimeoutMinutes => getInt(
    SettingsKeys.lockTimeoutMinutes,
    defaultValue: SettingsDefaults.lockTimeoutMinutes,
  );
  Future<void> setLockTimeoutMinutes(int value) =>
      setInt(SettingsKeys.lockTimeoutMinutes, value);

  bool get showNotificationsLocked => getBool(
    SettingsKeys.showNotificationsLocked,
    defaultValue: SettingsDefaults.showNotificationsLocked,
  );
  Future<void> setShowNotificationsLocked(bool value) =>
      setBool(SettingsKeys.showNotificationsLocked, value);

  // Backup
  bool get backupEnabled => getBool(SettingsKeys.backupEnabled);
  Future<void> setBackupEnabled(bool value) =>
      setBool(SettingsKeys.backupEnabled, value);

  String get backupFrequency => getString(
    SettingsKeys.backupFrequency,
    defaultValue: SettingsDefaults.backupFrequency,
  );
  Future<void> setBackupFrequency(String value) =>
      setString(SettingsKeys.backupFrequency, value);

  // Fingerprint Lock
  bool get fingerprintLockEnabled =>
      getBool(SettingsKeys.fingerprintLockEnabled);
  Future<void> setFingerprintLockEnabled(bool value) =>
      setBool(SettingsKeys.fingerprintLockEnabled, value);

  // Live Location Sharing
  bool get liveLocationSharingEnabled =>
      getBool(SettingsKeys.liveLocationSharingEnabled);
  Future<void> setLiveLocationSharingEnabled(bool value) =>
      setBool(SettingsKeys.liveLocationSharingEnabled, value);

  // Media Cache
  int get mediaCacheSizeBytes => getInt(
    SettingsKeys.mediaCacheSizeBytes,
    defaultValue: SettingsDefaults.mediaCacheSizeBytes,
  );
  Future<void> setMediaCacheSizeBytes(int value) =>
      setInt(SettingsKeys.mediaCacheSizeBytes, value);

  bool get perRoomCacheEnabled => getBool(SettingsKeys.perRoomCacheEnabled);
  Future<void> setPerRoomCacheEnabled(bool value) =>
      setBool(SettingsKeys.perRoomCacheEnabled, value);

  // Analytics
  bool get analyticsEnabled => getBool(
    SettingsKeys.analyticsEnabled,
    defaultValue: SettingsDefaults.analyticsEnabled,
  );
  Future<void> setAnalyticsEnabled(bool value) =>
      setBool(SettingsKeys.analyticsEnabled, value);
}
