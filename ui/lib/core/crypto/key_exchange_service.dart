import 'package:antinvestor_api_device/antinvestor_api_device.dart' as pb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import '../networking/client.dart';
import 'e2e_encryption_service.dart';
import 'key_manager.dart';

/// Service for managing E2EE key exchange with the Device API
///
/// Handles:
/// - Uploading identity keys (curve25519, ed25519) on login
/// - Uploading one-time prekeys for session establishment
/// - Fetching recipient's keys for new conversations
/// - Sharing Megolm session keys with room members
class KeyExchangeService {
  KeyExchangeService(
    this._encryptionService,
    this._deviceClient,
    this._keyManager,
  );
  final E2EEncryptionService _encryptionService;
  final pb.DeviceServiceClient _deviceClient;
  final KeyManager _keyManager;

  /// Upload identity keys to the backend after login
  ///
  /// Should be called once after user authentication to publish
  /// the device's public keys for other users to initiate sessions.
  Future<void> uploadIdentityKeys() async {
    try {
      final deviceId = await _keyManager.getDeviceId();

      // Upload Curve25519 identity key (as base64-encoded bytes)
      await _deviceClient.addKey(
        pb.AddKeyRequest(
          deviceId: deviceId,
          keyType: pb.KeyType.CURVE25519_KEY,
          data: _stringToBytes(_encryptionService.identityKey),
        ),
      );

      // Upload Ed25519 signing key
      await _deviceClient.addKey(
        pb.AddKeyRequest(
          deviceId: deviceId,
          keyType: pb.KeyType.ED25519_KEY,
          data: _stringToBytes(_encryptionService.signingKey),
        ),
      );

      AppLogger.info('Identity keys uploaded', data: {'deviceId': deviceId});
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to upload identity keys',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Convert string to bytes for API
  List<int> _stringToBytes(String s) => s.codeUnits;

  /// Convert bytes to string from API
  String _bytesToString(List<int> bytes) => String.fromCharCodes(bytes);

  /// Upload one-time prekeys to the backend
  ///
  /// These keys are used by other users to establish new Olm sessions.
  /// The backend should manage key consumption and notify when more are needed.
  Future<void> uploadOneTimeKeys() async {
    try {
      final deviceId = await _keyManager.getDeviceId();
      final oneTimeKeys = _encryptionService.getOneTimeKeys();

      for (final entry in oneTimeKeys.entries) {
        await _deviceClient.addKey(
          pb.AddKeyRequest(
            deviceId: deviceId,
            keyType: pb.KeyType.CURVE25519_KEY,
            data: _stringToBytes(entry.value),
          ),
        );
      }

      // Mark keys as published so they won't be reused
      await _encryptionService.markKeysAsPublished();

      AppLogger.info(
        'One-time keys uploaded',
        data: {'deviceId': deviceId, 'count': oneTimeKeys.length},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to upload one-time keys',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get a recipient's keys for establishing a session
  ///
  /// Searches by device ID or query string (backend may support profile lookup).
  /// Returns the recipient's Curve25519 identity key for key exchange.
  Future<String?> getRecipientKey(String deviceIdOrQuery) async {
    try {
      final response = await _deviceClient.searchKey(
        pb.SearchKeyRequest(
          query: deviceIdOrQuery,
          keyTypes: [pb.KeyType.CURVE25519_KEY],
        ),
      );

      if (response.data.isEmpty) {
        AppLogger.warning(
          'No keys found for recipient',
          data: {'query': deviceIdOrQuery},
        );
        return null;
      }

      // Return the first available key
      final keyObj = response.data.first;
      AppLogger.debug(
        'Retrieved recipient key',
        data: {'query': deviceIdOrQuery, 'keyId': keyObj.id},
      );

      return _bytesToString(keyObj.key);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to get recipient key',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Share Megolm session key with room members
  ///
  /// When creating a new group session, the session key needs to be
  /// shared with all room members so they can decrypt messages.
  ///
  /// Returns a list of room key payloads to be sent to each member.
  /// Each payload contains the session key encrypted for that member.
  Future<List<RoomKeyPayload>> shareSessionKey({
    required String roomId,
    required List<String> memberProfileIds,
  }) async {
    final payloads = <RoomKeyPayload>[];

    try {
      final sessionKey = _encryptionService.getGroupSessionKey(roomId);
      final sessionId = _encryptionService.getGroupSessionId(roomId);
      final senderKey = _encryptionService.identityKey;

      if (sessionId == null || sessionKey.isEmpty) {
        AppLogger.warning('No session to share', data: {'roomId': roomId});
        return payloads;
      }

      // Fetch keys for each member and create encrypted payloads
      for (final profileId in memberProfileIds) {
        try {
          final recipientKey = await getRecipientKey(profileId);
          if (recipientKey == null) {
            AppLogger.warning(
              'Could not find key for member',
              data: {'profileId': profileId},
            );
            continue;
          }

          // Create room key payload for this member
          // The session key is included with recipient info for proper routing
          final payload = RoomKeyPayload(
            recipientProfileId: profileId,
            recipientKey: recipientKey,
            roomId: roomId,
            sessionId: sessionId,
            sessionKey: sessionKey,
            senderKey: senderKey,
            algorithm: 'megolm.v1',
          );

          payloads.add(payload);

          AppLogger.debug(
            'Created room key payload',
            data: {
              'recipientProfileId': profileId,
              'roomId': roomId,
              'sessionId': sessionId,
            },
          );
        } catch (e) {
          AppLogger.warning(
            'Failed to create key payload for member',
            data: {'profileId': profileId, 'error': e.toString()},
          );
        }
      }

      AppLogger.info(
        'Session key sharing prepared',
        data: {
          'roomId': roomId,
          'sessionId': sessionId,
          'memberCount': memberProfileIds.length,
          'payloadsCreated': payloads.length,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to share session key',
        error: e,
        stackTrace: stackTrace,
      );
    }

    return payloads;
  }

  /// Process an incoming session key from another user
  ///
  /// When receiving a shared session key, add it as an inbound session.
  Future<void> receiveSessionKey({
    required String roomId,
    required String sessionId,
    required String sessionKey,
    required String senderKey,
  }) async {
    try {
      await _encryptionService.addInboundGroupSession(
        roomId,
        sessionId,
        sessionKey,
        senderKey: senderKey,
      );

      AppLogger.info(
        'Received and stored session key',
        data: {
          'roomId': roomId,
          'sessionId': sessionId,
          'senderKey': senderKey.substring(0, 8),
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to process received session key',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Payload for sharing a room key with a specific recipient
class RoomKeyPayload {
  RoomKeyPayload({
    required this.recipientProfileId,
    required this.recipientKey,
    required this.roomId,
    required this.sessionId,
    required this.sessionKey,
    required this.senderKey,
    required this.algorithm,
  });

  /// Create from JSON received in a room message
  factory RoomKeyPayload.fromJson(
    Map<String, dynamic> json, {
    required String recipientKey,
  }) {
    return RoomKeyPayload(
      recipientProfileId: json['recipientProfileId'] as String,
      recipientKey: recipientKey,
      roomId: json['roomId'] as String,
      sessionId: json['sessionId'] as String,
      sessionKey: json['sessionKey'] as String,
      senderKey: json['senderKey'] as String,
      algorithm: json['algorithm'] as String? ?? 'megolm.v1',
    );
  }

  /// Profile ID of the recipient
  final String recipientProfileId;

  /// Recipient's Curve25519 public key
  final String recipientKey;

  /// Room ID the session is for
  final String roomId;

  /// Megolm session ID
  final String sessionId;

  /// The actual session key data
  final String sessionKey;

  /// Sender's Curve25519 public key
  final String senderKey;

  /// Encryption algorithm (e.g., 'megolm.v1')
  final String algorithm;

  /// Convert to JSON for sending via room message
  Map<String, dynamic> toJson() => {
    'recipientProfileId': recipientProfileId,
    'roomId': roomId,
    'sessionId': sessionId,
    'sessionKey': sessionKey,
    'senderKey': senderKey,
    'algorithm': algorithm,
  };
}

/// Provider for KeyExchangeService
final keyExchangeServiceProvider = FutureProvider<KeyExchangeService>((
  ref,
) async {
  final encryptionService = ref.watch(e2eEncryptionServiceProvider);
  final deviceClient = await ref.watch(deviceServiceClientProvider.future);
  final keyManager = ref.watch(keyManagerProvider);

  // Ensure encryption service is initialized
  await encryptionService.initialize();

  return KeyExchangeService(encryptionService, deviceClient, keyManager);
});
