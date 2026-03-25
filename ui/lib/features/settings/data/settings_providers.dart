import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_providers.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  static const String _keyMessageNotifications = 'message_notifications';
  static const String _keyNotificationPreview = 'notification_preview';
  static const String _keyGroupNotifications = 'group_notifications';
  static const String _keyCallRingtone = 'call_ringtone';
  static const String _keyArchiveChats = 'archive_chats';
  static const String _keyFontSize = 'font_size';
  static const String _keyWallpaper = 'wallpaper';
  static const String _keyMediaAutoDownload = 'media_auto_download';
  static const String _keyCallDataUsage = 'call_data_usage';
  static const String _keyNotificationPermissionPrompted =
      'notification_permission_prompted';

  final _storage = const FlutterSecureStorage();

  @override
  Future<Map<String, dynamic>> build() async => {
    _keyMessageNotifications: await _getBool(_keyMessageNotifications, true),
    _keyNotificationPreview: await _getBool(_keyNotificationPreview, true),
    _keyGroupNotifications: await _getBool(_keyGroupNotifications, true),
    _keyCallRingtone: await _getBool(_keyCallRingtone, true),
    _keyArchiveChats: await _getBool(_keyArchiveChats, false),
    _keyFontSize: await _getString(_keyFontSize, 'Medium'),
    _keyWallpaper: await _getString(_keyWallpaper, 'Default'),
    _keyMediaAutoDownload: await _getString(
      _keyMediaAutoDownload,
      'Wi-Fi only',
    ),
    _keyCallDataUsage: await _getString(_keyCallDataUsage, 'Low data usage'),
    _keyNotificationPermissionPrompted: await _getBool(
      _keyNotificationPermissionPrompted,
      false,
    ),
  };

  Future<bool> _getBool(String key, bool defaultValue) async {
    final value = await _storage.read(key: key);
    return value != null ? value.toLowerCase() == 'true' : defaultValue;
  }

  Future<String> _getString(String key, String defaultValue) async =>
      await _storage.read(key: key) ?? defaultValue;

  Future<void> updateSetting(String key, value) async {
    if (value is bool) {
      await _storage.write(key: key, value: value.toString());
    } else if (value is String) {
      await _storage.write(key: key, value: value);
    }

    // Provider may have been disposed during the async storage write
    if (!ref.mounted) return;

    final currentState = await future;
    state = AsyncValue.data({...currentState, key: value});
  }

  // Convenience methods
  Future<void> toggleMessageNotifications(bool value) =>
      updateSetting(_keyMessageNotifications, value);

  Future<void> toggleNotificationPreview(bool value) =>
      updateSetting(_keyNotificationPreview, value);

  Future<void> toggleGroupNotifications(bool value) =>
      updateSetting(_keyGroupNotifications, value);

  Future<void> toggleCallRingtone(bool value) =>
      updateSetting(_keyCallRingtone, value);

  Future<void> toggleArchiveChats(bool value) =>
      updateSetting(_keyArchiveChats, value);

  Future<void> updateFontSize(String value) =>
      updateSetting(_keyFontSize, value);

  Future<void> updateWallpaper(String value) =>
      updateSetting(_keyWallpaper, value);

  Future<void> updateMediaAutoDownload(String value) =>
      updateSetting(_keyMediaAutoDownload, value);

  Future<void> updateCallDataUsage(String value) =>
      updateSetting(_keyCallDataUsage, value);

  Future<void> markNotificationPermissionPrompted() =>
      updateSetting(_keyNotificationPermissionPrompted, true);

  /// Check if the notification permission dialog has been shown before
  Future<bool> hasNotificationPermissionBeenPrompted() async =>
      _getBool(_keyNotificationPermissionPrompted, false);
}

@riverpod
class CacheManager extends _$CacheManager {
  @override
  Future<int> build() async {
    // Calculate cache size (simplified implementation)
    return 0; // Return cache size in bytes
  }

  Future<void> clearCache() async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }
    } catch (_) {
      // Ignore errors during cache clearing
    }
    // Recalculate cache size
    state = const AsyncValue.data(0);
  }
}
