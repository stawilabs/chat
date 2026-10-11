import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

/// Where the device key's private scalar is kept. Production is the platform
/// keystore (Keychain / Keystore); tests use a map.
abstract interface class DeviceKeyVault {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// [DeviceKeyVault] over flutter_secure_storage. The Keychain item is
/// this-device-only and never synchronised, so the key does not leave the
/// device through a backup or iCloud Keychain.
class SecureStorageDeviceKeyVault implements DeviceKeyVault {
  const SecureStorageDeviceKeyVault();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

/// This device's secp256k1 key for one profile. It signs digests and
/// publishes its public half; the private scalar never leaves this object.
class DeviceKeyHandle {
  DeviceKeyHandle._(this._key);

  final DeviceKey _key;

  /// The key's EVM address, keccak256(X ‖ Y)[12:]: the key id the account
  /// registers.
  Uint8List get address => Uint8List.fromList(_key.address);

  /// 0x04 ‖ X ‖ Y.
  Uint8List get publicKey => Uint8List.fromList(_key.publicKey);

  /// The key id chat and settlement name the signer by: the lowercase
  /// 0x-prefixed address.
  String get keyId => bytesToHex0x(_key.address).toLowerCase();

  /// The 65-byte r ‖ s ‖ v signature over a 32-byte prepared digest.
  Uint8List sign(List<int> digest) => signPreparedCall(digest, _key.privateKey);
}

/// Generates the device key on first use and keeps it in the platform's
/// secure storage, one per profile signed in on this device. There is no way
/// to read the private key out: it is used only through [DeviceKeyHandle].
class DeviceKeyStore {
  DeviceKeyStore(this._vault, {Random? random}) : _random = random;

  final DeviceKeyVault _vault;
  final Random? _random;
  final Map<String, Future<DeviceKeyHandle>> _inFlight = {};

  static String _slot(String profileId) => 'stawi.device_key.v1.$profileId';

  /// The profile's key on this device, or null if none was generated yet.
  Future<DeviceKeyHandle?> load(String profileId) async {
    final stored = await _vault.read(_slot(profileId));
    if (stored == null || stored.isEmpty) return null;
    return DeviceKeyHandle._(DeviceKey.fromPrivateKey(hexToBytes(stored)));
  }

  /// The profile's key, generated and stored the first time it is needed.
  Future<DeviceKeyHandle> loadOrCreate(String profileId) =>
      _inFlight.putIfAbsent(profileId, () async {
        try {
          final existing = await load(profileId);
          if (existing != null) return existing;
          final key = DeviceKey.generate(random: _random);
          await _vault.write(_slot(profileId), bytesToHex(key.privateKey));
          return DeviceKeyHandle._(key);
        } finally {
          unawaited(_inFlight.remove(profileId));
        }
      });
}

final deviceKeyStoreProvider = Provider<DeviceKeyStore>(
  (ref) => DeviceKeyStore(const SecureStorageDeviceKeyVault()),
);
