import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Provider for KeyManager
final keyManagerProvider = Provider<KeyManager>((ref) => KeyManager());

/// Manages secure storage of keys and device identifiers
///
/// Handles:
/// - Device ID generation and storage
/// - Secure storage of sensitive data
class KeyManager {
  static const _deviceIdKey = 'device_id';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Get or create a unique device ID
  ///
  /// The device ID is generated once and stored securely.
  /// It persists across app reinstalls on iOS (keychain) but not on Android.
  Future<String> getDeviceId() async {
    var deviceId = await _storage.read(key: _deviceIdKey);

    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await _storage.write(key: _deviceIdKey, value: deviceId);
    }

    return deviceId;
  }

  /// Delete all stored keys (call on logout/account deletion)
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Read a string value from secure storage
  Future<String?> getString(String key) async {
    return _storage.read(key: key);
  }

  /// Write a string value to secure storage
  Future<void> setString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Read a boolean value from secure storage
  Future<bool?> getBool(String key) async {
    final value = await _storage.read(key: key);
    if (value == null) return null;
    return value == 'true';
  }

  /// Write a boolean value to secure storage
  Future<void> setBool(String key, bool value) async {
    await _storage.write(key: key, value: value.toString());
  }

  /// Delete a specific key from secure storage
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
}
