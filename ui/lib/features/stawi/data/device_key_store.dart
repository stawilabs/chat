import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import 'signing_gate.dart';

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

/// The public half of this device's secp256k1 key for one profile: what the
/// account registers and what screens show. It cannot sign; only
/// [DeviceKeyStore.unlock] hands out a [DeviceKeyHandle], behind the device
/// lock.
class DevicePublicKey {
  DevicePublicKey._(DeviceKey key)
    : _address = Uint8List.fromList(key.address),
      _publicKey = Uint8List.fromList(key.publicKey);

  final Uint8List _address;
  final Uint8List _publicKey;

  /// The key's EVM address, keccak256(X ‖ Y)[12:]: the key id the account
  /// registers.
  Uint8List get address => Uint8List.fromList(_address);

  /// 0x04 ‖ X ‖ Y.
  Uint8List get publicKey => Uint8List.fromList(_publicKey);

  /// The key id chat and settlement name the signer by: the lowercase
  /// 0x-prefixed address.
  String get keyId => bytesToHex0x(_address).toLowerCase();
}

/// This device's key for one signature, handed out by [DeviceKeyStore.unlock]
/// once the device lock confirmed it. The private scalar never leaves it.
final class DeviceKeyHandle extends DevicePublicKey {
  DeviceKeyHandle._(this._key) : super._(_key);

  final DeviceKey _key;

  /// The 65-byte r ‖ s ‖ v signature over a 32-byte prepared digest.
  Uint8List sign(List<int> digest) => signPreparedCall(digest, _key.privateKey);
}

/// Generates the device key on first use and keeps it in the platform's
/// secure storage, one per profile signed in on this device. There is no way
/// to read the private key out. [load] and [loadOrCreate] give the public
/// half only; a key that signs comes from [unlock], behind [SigningGate].
/// There is no default gate, so a store cannot be built that signs unasked.
class DeviceKeyStore {
  DeviceKeyStore(this._vault, {required SigningGate gate, Random? random})
    : _gate = gate,
      _random = random;

  final DeviceKeyVault _vault;
  final SigningGate _gate;
  final Random? _random;
  final Map<String, Future<DeviceKey>> _inFlight = {};

  static String _slot(String profileId) => 'stawi.device_key.v1.$profileId';

  Future<DeviceKey?> _stored(String profileId) async {
    final stored = await _vault.read(_slot(profileId));
    if (stored == null || stored.isEmpty) return null;
    return DeviceKey.fromPrivateKey(hexToBytes(stored));
  }

  Future<DeviceKey> _storedOrCreated(String profileId) =>
      _inFlight.putIfAbsent(profileId, () async {
        try {
          final existing = await _stored(profileId);
          if (existing != null) return existing;
          final key = DeviceKey.generate(random: _random);
          await _vault.write(_slot(profileId), bytesToHex(key.privateKey));
          return key;
        } finally {
          unawaited(_inFlight.remove(profileId));
        }
      });

  /// The profile's key on this device, or null if none was generated yet.
  Future<DevicePublicKey?> load(String profileId) async {
    final key = await _stored(profileId);
    return key == null ? null : DevicePublicKey._(key);
  }

  /// The profile's key, generated and stored the first time it is needed.
  Future<DevicePublicKey> loadOrCreate(String profileId) async =>
      DevicePublicKey._(await _storedOrCreated(profileId));

  /// The profile's key for one signature, once the device lock confirms
  /// [reason] (what is about to be signed, in the person's words).
  Future<DeviceKeyHandle> unlock(
    String profileId, {
    required String reason,
  }) async {
    await _gate.confirm(reason);
    return DeviceKeyHandle._(await _storedOrCreated(profileId));
  }
}

final deviceKeyStoreProvider = Provider<DeviceKeyStore>(
  (ref) => DeviceKeyStore(
    const SecureStorageDeviceKeyVault(),
    gate: ref.watch(signingGateProvider),
  ),
);
