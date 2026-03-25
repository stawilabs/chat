import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provider for KeyManager
final keyManagerProvider = Provider<KeyManager>((ref) {
  return KeyManager(const FlutterSecureStorage());
});

/// Simplified KeyManager for device ID and secure storage
class KeyManager {
  KeyManager(this._storage);
  final FlutterSecureStorage _storage;

  // Placeholder for account state
  String? _identityKey;

  Future<void> init() async {
    // Try to load from storage
    final key = await _storage.read(key: 'identity_key');
    if (key != null) {
      _identityKey = key;
    } else {
      // Generate placeholder key
      _identityKey = base64Encode(List.generate(32, (i) => i));
      await _storage.write(key: 'identity_key', value: _identityKey);
    }
  }

  String get identityKey => _identityKey ?? '';

  // Helper to get public bundle to upload
  Map<String, dynamic> getPublicBundle() => {
    'identity_key': _identityKey,
    'curve25519_key': _identityKey,
  };

  // E2EE is not yet implemented — these methods must throw rather than
  // silently returning unencrypted data disguised as ciphertext.
  Future<String> encrypt(String plaintext, String recipientKey) async {
    throw UnimplementedError(
      'E2EE encryption is not yet implemented. '
      'Do not call this method until vodozemac integration is complete.',
    );
  }

  Future<String> decrypt(String ciphertext, String senderKey) async {
    throw UnimplementedError(
      'E2EE decryption is not yet implemented. '
      'Do not call this method until vodozemac integration is complete.',
    );
  }

  Future<String> getDeviceId() async {
    var deviceId = await _storage.read(key: 'device_id');
    if (deviceId == null) {
      deviceId = 'flutter_device_${DateTime.now().millisecondsSinceEpoch}';
      await _storage.write(key: 'device_id', value: deviceId);
    }
    return deviceId;
  }
}
