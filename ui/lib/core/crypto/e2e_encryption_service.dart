// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as aes;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

import '../db/database.dart';
import '../logging/app_logger.dart';

/// End-to-End Encryption service using Vodozemac (Olm/Megolm)
///
/// Currently provides:
/// - Group encryption using Megolm (ratchet per message)
/// - Automatic session management and key rotation
/// - Key generation and signing for key exchange
///
/// Note: 1-on-1 Olm encryption is not yet implemented. All messages
/// currently use Megolm group sessions, even for direct messages.
/// Olm support will be added in a future release.
class E2EEncryptionService {
  E2EEncryptionService(this._storage, this._database);
  final FlutterSecureStorage _storage;
  // ignore: unused_field - reserved for future session persistence in database
  final AppDatabase _database;
  final Random _random = Random.secure();

  /// Vodozemac Olm account for identity and 1-on-1 sessions
  vod.Account? _olmAccount;

  /// Megolm outbound sessions by room ID
  final Map<String, vod.GroupSession> _outboundGroupSessions = {};

  /// Megolm inbound sessions by roomId -> senderKey -> session
  final Map<String, Map<String, vod.InboundGroupSession>>
  _inboundGroupSessions = {};

  /// Message count per room for session rotation (rotate after 100 messages)
  final Map<String, int> _sessionMessageCounts = {};

  /// Legacy session state for backwards compatibility
  ///
  /// This maintains the old GroupSessionState format alongside Vodozemac sessions
  /// for compatibility with existing stored data. This will be removed in a future
  /// version once migration is complete.
  ///
  // TODO(antinvestor): Remove legacy state once all clients have migrated to Vodozemac sessions
  @Deprecated('Legacy state - will be removed in future version')
  final Map<String, GroupSessionState> _groupSessions = {};

  bool _isInitialized = false;

  /// Max messages before rotating group session
  static const int _sessionRotationThreshold = 100;

  /// Initialize the encryption service
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      AppLogger.info('Initializing E2E encryption service with vodozemac');

      // Initialize vodozemac Rust library if not already done
      // We use try-catch because isInitialized() throws if the library
      // hasn't been touched yet, and init() throws if already initialized
      try {
        if (!vod.isInitialized()) {
          AppLogger.debug('Initializing vodozemac Rust library');
          await vod.init();
          AppLogger.debug('Vodozemac Rust library initialized');
        }
        // ignore: avoid_catching_errors
      } on StateError {
        // Library not initialized yet - this is expected on first run
        AppLogger.debug('Initializing vodozemac Rust library');
        await vod.init();
        AppLogger.debug('Vodozemac Rust library initialized');
      }

      // Try to load existing Olm account from storage
      final pickledAccount = await _storage.read(key: 'olm_account_pickle');
      final pickleKey = await _getOrCreatePickleKeyBytes();

      if (pickledAccount != null) {
        // Restore existing account
        _olmAccount = vod.Account.fromPickleEncrypted(
          pickle: pickledAccount,
          pickleKey: pickleKey,
        );
        AppLogger.debug('Loaded existing Olm account');
      } else {
        // Create new Olm account
        _olmAccount = vod.Account();

        // Generate initial one-time keys
        _olmAccount!.generateOneTimeKeys(10);

        // Save account
        await _saveOlmAccount();
        AppLogger.info('Created new Olm account');
      }

      // Load stored group sessions
      await _loadGroupSessions();

      _isInitialized = true;
      // Log key fingerprints (first 8 chars) rather than full keys for security
      final curve25519 = _olmAccount!.curve25519Key.toBase64();
      final ed25519 = _olmAccount!.ed25519Key.toBase64();
      AppLogger.debug(
        'E2E encryption service initialized',
        data: {
          'curve25519Fingerprint': curve25519.length > 8
              ? curve25519.substring(0, 8)
              : curve25519,
          'ed25519Fingerprint': ed25519.length > 8
              ? ed25519.substring(0, 8)
              : ed25519,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to initialize E2E encryption',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get or create the pickle key for account serialization (as bytes)
  Future<Uint8List> _getOrCreatePickleKeyBytes() async {
    var keyStr = await _storage.read(key: 'olm_pickle_key');
    if (keyStr == null) {
      // Generate 32 random bytes
      final keyBytes = Uint8List.fromList(
        List<int>.generate(32, (_) => _random.nextInt(256)),
      );
      keyStr = base64Encode(keyBytes);
      await _storage.write(key: 'olm_pickle_key', value: keyStr);
    }
    return base64Decode(keyStr);
  }

  /// Save Olm account to secure storage
  Future<void> _saveOlmAccount() async {
    if (_olmAccount == null) return;
    final pickleKey = await _getOrCreatePickleKeyBytes();
    final pickle = _olmAccount!.toPickleEncrypted(pickleKey);
    await _storage.write(key: 'olm_account_pickle', value: pickle);
  }

  /// Get Curve25519 identity key for key exchange
  String get identityKey {
    _ensureInitialized();
    return _olmAccount!.curve25519Key.toBase64();
  }

  /// Get Ed25519 signing key
  String get signingKey {
    _ensureInitialized();
    return _olmAccount!.ed25519Key.toBase64();
  }

  /// Get one-time keys for initial key exchange
  Map<String, String> getOneTimeKeys() {
    _ensureInitialized();
    final keys = _olmAccount!.oneTimeKeys;
    return Map.fromEntries(
      keys.entries.map((e) => MapEntry(e.key, e.value.toBase64())),
    );
  }

  /// Get fallback key if no one-time keys available
  Map<String, String>? getFallbackKey() {
    _ensureInitialized();
    final fallback = _olmAccount!.fallbackKey;
    if (fallback.isEmpty) return null;
    return Map.fromEntries(
      fallback.entries.map((e) => MapEntry(e.key, e.value.toBase64())),
    );
  }

  /// Generate more one-time keys
  Future<void> generateOneTimeKeys(int count) async {
    _ensureInitialized();
    _olmAccount!.generateOneTimeKeys(count);
    await _saveOlmAccount();
    AppLogger.debug('Generated one-time keys', data: {'count': count});
  }

  /// Generate a fallback key
  Future<void> generateFallbackKey() async {
    _ensureInitialized();
    _olmAccount!.generateFallbackKey();
    await _saveOlmAccount();
    AppLogger.debug('Generated fallback key');
  }

  /// Mark one-time keys as published (they shouldn't be reused)
  Future<void> markKeysAsPublished() async {
    _ensureInitialized();
    _olmAccount!.markKeysAsPublished();
    await _saveOlmAccount();
    AppLogger.debug('Marked one-time keys as published');
  }

  /// Sign a message with Ed25519 key
  String sign(String message) {
    _ensureInitialized();
    return _olmAccount!.sign(message).toBase64();
  }

  /// Verify a signature
  bool verify(String message, String signature, String signingKeyBase64) {
    try {
      final key = vod.Ed25519PublicKey.fromBase64(signingKeyBase64);
      final sig = vod.Ed25519Signature.fromBase64(signature);
      key.verify(message: message, signature: sig);
      return true;
    } catch (e) {
      AppLogger.warning('Signature verification failed', data: {'error': '$e'});
      return false;
    }
  }

  /// Create a Megolm group session for room encryption
  Future<String> createGroupSession(String roomId) async {
    _ensureInitialized();

    // Create new Megolm outbound session
    final session = vod.GroupSession();
    final sessionId = session.sessionId;

    _outboundGroupSessions[roomId] = session;
    _sessionMessageCounts[roomId] = 0;

    // Store for backwards compatibility
    _groupSessions[roomId] = GroupSessionState(
      sessionId: sessionId,
      sessionKey: session.sessionKey,
      messageIndex: 0,
    );

    await _saveGroupSession(roomId);
    AppLogger.debug(
      'Created Megolm group session',
      data: {'roomId': roomId, 'sessionId': sessionId},
    );
    return sessionId;
  }

  /// Get or create group session for a room
  Future<GroupSessionState> getOrCreateGroupSession(String roomId) async {
    // Check if we need to rotate the session
    final messageCount = _sessionMessageCounts[roomId] ?? 0;
    if (messageCount >= _sessionRotationThreshold) {
      AppLogger.info(
        'Rotating group session after $_sessionRotationThreshold messages',
        data: {'roomId': roomId},
      );
      await createGroupSession(roomId);
    }

    if (_outboundGroupSessions.containsKey(roomId)) {
      return _groupSessions[roomId]!;
    }

    await createGroupSession(roomId);
    return _groupSessions[roomId]!;
  }

  /// Add an inbound Megolm group session from shared session key
  ///
  /// The [senderKey] is required and should be the sender's Curve25519 identity key.
  /// This ensures proper session mapping and prevents collisions.
  Future<void> addInboundGroupSession(
    String roomId,
    String sessionId,
    String sessionKey, {
    required String senderKey,
  }) async {
    _ensureInitialized();

    if (senderKey.isEmpty) {
      throw ArgumentError('senderKey cannot be empty');
    }

    try {
      final inbound = vod.InboundGroupSession(sessionKey);

      _inboundGroupSessions[roomId] ??= {};
      _inboundGroupSessions[roomId]![senderKey] = inbound;

      // Store for backwards compatibility
      _groupSessions[roomId] = GroupSessionState(
        sessionId: sessionId,
        sessionKey: sessionKey,
        messageIndex: 0,
      );

      await _saveGroupSession(roomId);
      AppLogger.debug(
        'Added inbound Megolm session',
        data: {'roomId': roomId, 'sessionId': sessionId},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to add inbound group session',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Encrypt a message for a room using Megolm
  Future<GroupEncryptedMessage> encryptGroup(
    String roomId,
    String plaintext,
  ) async {
    _ensureInitialized();

    // Get or create outbound session
    await getOrCreateGroupSession(roomId);
    final session = _outboundGroupSessions[roomId]!;

    // Encrypt the message
    final encrypted = session.encrypt(plaintext);
    final messageIndex = session.messageIndex;

    // Increment message count for rotation tracking
    _sessionMessageCounts[roomId] = (_sessionMessageCounts[roomId] ?? 0) + 1;

    // Update legacy state
    if (_groupSessions.containsKey(roomId)) {
      _groupSessions[roomId]!.messageIndex = messageIndex;
    }

    await _saveGroupSession(roomId);

    return GroupEncryptedMessage(
      ciphertext: encrypted,
      sessionId: session.sessionId,
      messageIndex: messageIndex,
      senderKey: identityKey,
    );
  }

  /// Decrypt a group message using Megolm
  ///
  /// The [senderKey] is required and should be the sender's Curve25519 identity key.
  Future<String> decryptGroup(
    String roomId,
    String ciphertext, {
    required String senderKey,
  }) async {
    _ensureInitialized();

    if (senderKey.isEmpty) {
      throw ArgumentError('senderKey cannot be empty');
    }

    final inbound = _inboundGroupSessions[roomId]?[senderKey];

    if (inbound == null) {
      throw MissingSessionException(
        'No inbound session for room $roomId from sender $senderKey',
        roomId: roomId,
        senderKey: senderKey,
      );
    }

    try {
      final result = inbound.decrypt(ciphertext);
      return result.plaintext;
    } catch (e) {
      throw DecryptionException(
        'Failed to decrypt message in room $roomId: $e',
        roomId: roomId,
      );
    }
  }

  /// Get session key to share with room members
  String getGroupSessionKey(String roomId) {
    _ensureInitialized();
    final session = _outboundGroupSessions[roomId];
    if (session == null) {
      throw StateError('No group session for room $roomId');
    }
    return session.sessionKey;
  }

  /// Get session ID for a room
  String? getGroupSessionId(String roomId) {
    return _outboundGroupSessions[roomId]?.sessionId;
  }

  /// Check if we have an outbound session for a room
  bool hasOutboundSession(String roomId) {
    return _outboundGroupSessions.containsKey(roomId);
  }

  /// Check if we have an inbound session from a sender
  ///
  /// The [senderKey] is required and should be the sender's Curve25519 identity key.
  bool hasInboundSession(String roomId, String senderKey) {
    if (senderKey.isEmpty) return false;
    return _inboundGroupSessions[roomId]?.containsKey(senderKey) ?? false;
  }

  /// Encrypt arbitrary data (for file encryption) using AES-256-GCM
  ///
  /// Uses authenticated encryption (AEAD) which provides both confidentiality
  /// and integrity protection. The IV is randomly generated for each encryption.
  ///
  /// Returns [EncryptedData] containing the ciphertext, key, and IV.
  Future<EncryptedData> encryptData(Uint8List data) async {
    _ensureInitialized();

    // Generate random 256-bit key and 96-bit IV for AES-GCM
    final keyBytes = Uint8List.fromList(
      List<int>.generate(32, (_) => _random.nextInt(256)),
    );
    final ivBytes = Uint8List.fromList(
      List<int>.generate(12, (_) => _random.nextInt(256)), // 96-bit IV for GCM
    );

    final key = aes.Key(keyBytes);
    final iv = aes.IV(ivBytes);
    final encrypter = aes.Encrypter(aes.AES(key, mode: aes.AESMode.gcm));

    final encrypted = encrypter.encryptBytes(data, iv: iv);

    AppLogger.debug(
      'Encrypted data with AES-256-GCM',
      data: {'dataSize': data.length, 'encryptedSize': encrypted.bytes.length},
    );

    return EncryptedData(
      data: Uint8List.fromList(encrypted.bytes),
      key: base64Encode(keyBytes),
      iv: base64Encode(ivBytes),
    );
  }

  /// Decrypt arbitrary data using AES-256-GCM
  ///
  /// Uses authenticated decryption which verifies the integrity of the
  /// ciphertext before returning the plaintext.
  ///
  /// Throws [ArgumentError] if decryption fails (e.g., tampered data).
  Future<Uint8List> decryptData(EncryptedData encryptedData) async {
    final keyBytes = base64Decode(encryptedData.key);
    final ivBytes = base64Decode(encryptedData.iv);

    final key = aes.Key(Uint8List.fromList(keyBytes));
    final iv = aes.IV(Uint8List.fromList(ivBytes));
    final encrypter = aes.Encrypter(aes.AES(key, mode: aes.AESMode.gcm));

    try {
      final encrypted = aes.Encrypted(encryptedData.data);
      final decrypted = encrypter.decryptBytes(encrypted, iv: iv);

      AppLogger.debug(
        'Decrypted data with AES-256-GCM',
        data: {
          'encryptedSize': encryptedData.data.length,
          'decryptedSize': decrypted.length,
        },
      );

      return Uint8List.fromList(decrypted);
    } catch (e) {
      AppLogger.error(
        'AES-GCM decryption failed - data may be tampered',
        error: e,
      );
      throw ArgumentError('Decryption failed: data integrity check failed');
    }
  }

  // Private helper methods

  void _ensureInitialized() {
    if (!_isInitialized || _olmAccount == null) {
      throw StateError('E2E encryption service not initialized');
    }
  }

  Future<void> _saveGroupSession(String roomId) async {
    final pickleKey = await _getOrCreatePickleKeyBytes();

    // Save outbound session if exists
    final outbound = _outboundGroupSessions[roomId];
    if (outbound != null) {
      await _storage.write(
        key: 'megolm_outbound_$roomId',
        value: jsonEncode({
          'pickle': outbound.toPickleEncrypted(pickleKey),
          'sessionId': outbound.sessionId,
          'sessionKey': outbound.sessionKey,
          'messageIndex': outbound.messageIndex,
          'messageCount': _sessionMessageCounts[roomId] ?? 0,
        }),
      );
    }

    // Save inbound sessions
    final inbounds = _inboundGroupSessions[roomId];
    if (inbounds != null && inbounds.isNotEmpty) {
      final inboundData = <String, Map<String, dynamic>>{};
      for (final entry in inbounds.entries) {
        inboundData[entry.key] = {
          'pickle': entry.value.toPickleEncrypted(pickleKey),
          'sessionId': entry.value.sessionId,
        };
      }
      await _storage.write(
        key: 'megolm_inbound_$roomId',
        value: jsonEncode(inboundData),
      );
    }

    // Keep legacy format for backwards compatibility
    final session = _groupSessions[roomId];
    if (session != null) {
      await _storage.write(
        key: 'group_session_$roomId',
        value: jsonEncode({
          'sessionId': session.sessionId,
          'sessionKey': session.sessionKey,
          'messageIndex': session.messageIndex,
        }),
      );
    }
  }

  Future<void> _loadGroupSessions() async {
    try {
      final pickleKey = await _getOrCreatePickleKeyBytes();
      final allKeys = await _storage.readAll();

      // Load outbound sessions
      for (final key in allKeys.keys.where(
        (k) => k.startsWith('megolm_outbound_'),
      )) {
        final roomId = key.replaceFirst('megolm_outbound_', '');
        try {
          final data = jsonDecode(allKeys[key]!) as Map<String, dynamic>;
          final session = vod.GroupSession.fromPickleEncrypted(
            pickle: data['pickle'] as String,
            pickleKey: pickleKey,
          );
          _outboundGroupSessions[roomId] = session;
          _sessionMessageCounts[roomId] = data['messageCount'] as int? ?? 0;

          // Populate legacy state
          _groupSessions[roomId] = GroupSessionState(
            sessionId: data['sessionId'] as String,
            sessionKey: data['sessionKey'] as String,
            messageIndex: data['messageIndex'] as int? ?? 0,
          );

          AppLogger.debug('Loaded outbound session', data: {'roomId': roomId});
        } catch (e) {
          AppLogger.warning(
            'Failed to load outbound session',
            data: {'roomId': roomId, 'error': '$e'},
          );
        }
      }

      // Load inbound sessions
      for (final key in allKeys.keys.where(
        (k) => k.startsWith('megolm_inbound_'),
      )) {
        final roomId = key.replaceFirst('megolm_inbound_', '');
        try {
          final data = jsonDecode(allKeys[key]!) as Map<String, dynamic>;
          _inboundGroupSessions[roomId] = {};

          for (final entry in data.entries) {
            final sessionData = entry.value as Map<String, dynamic>;
            final inbound = vod.InboundGroupSession.fromPickleEncrypted(
              pickle: sessionData['pickle'] as String,
              pickleKey: pickleKey,
            );
            _inboundGroupSessions[roomId]![entry.key] = inbound;
          }

          AppLogger.debug(
            'Loaded inbound sessions',
            data: {'roomId': roomId, 'count': data.length},
          );
        } catch (e) {
          AppLogger.warning(
            'Failed to load inbound sessions',
            data: {'roomId': roomId, 'error': '$e'},
          );
        }
      }

      AppLogger.debug(
        'Loaded Megolm sessions',
        data: {
          'outbound': _outboundGroupSessions.length,
          'inboundRooms': _inboundGroupSessions.length,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load group sessions',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clean up resources
  void dispose() {
    _groupSessions.clear();
    _outboundGroupSessions.clear();
    _inboundGroupSessions.clear();
    _sessionMessageCounts.clear();
    _olmAccount = null;
  }

  /// Clear all sessions for a room (on leave)
  Future<void> clearRoomSessions(String roomId) async {
    _outboundGroupSessions.remove(roomId);
    _inboundGroupSessions.remove(roomId);
    _groupSessions.remove(roomId);
    _sessionMessageCounts.remove(roomId);

    await _storage.delete(key: 'megolm_outbound_$roomId');
    await _storage.delete(key: 'megolm_inbound_$roomId');
    await _storage.delete(key: 'group_session_$roomId');

    AppLogger.debug('Cleared room sessions', data: {'roomId': roomId});
  }
}

/// State for a Megolm group session
class GroupSessionState {
  GroupSessionState({
    required this.sessionId,
    required this.sessionKey,
    required this.messageIndex,
  });
  final String sessionId;
  final String sessionKey;
  int messageIndex;
}

/// Encrypted message for 1:1 communication
class EncryptedMessage {
  EncryptedMessage({
    required this.ciphertext,
    required this.messageType,
    required this.sessionId,
  });

  factory EncryptedMessage.fromJson(Map<String, dynamic> json) {
    return EncryptedMessage(
      ciphertext: json['ciphertext'] as String,
      messageType: json['messageType'] as int,
      sessionId: json['sessionId'] as String,
    );
  }
  final String ciphertext;
  final int messageType;
  final String sessionId;

  Map<String, dynamic> toJson() => {
    'ciphertext': ciphertext,
    'messageType': messageType,
    'sessionId': sessionId,
  };
}

/// Encrypted message for group communication (Megolm)
class GroupEncryptedMessage {
  GroupEncryptedMessage({
    required this.ciphertext,
    required this.sessionId,
    required this.messageIndex,
    this.senderKey,
  });

  factory GroupEncryptedMessage.fromJson(Map<String, dynamic> json) {
    return GroupEncryptedMessage(
      ciphertext: json['ciphertext'] as String,
      sessionId: json['sessionId'] as String,
      messageIndex: json['messageIndex'] as int,
      senderKey: json['senderKey'] as String?,
    );
  }
  final String ciphertext;
  final String sessionId;
  final int messageIndex;
  final String? senderKey;

  Map<String, dynamic> toJson() => {
    'ciphertext': ciphertext,
    'sessionId': sessionId,
    'messageIndex': messageIndex,
    if (senderKey != null) 'senderKey': senderKey,
  };
}

/// Encrypted data with key
class EncryptedData {
  EncryptedData({required this.data, required this.key, required this.iv});
  final Uint8List data;
  final String key;
  final String iv;
}

// Provider
final e2eEncryptionServiceProvider = Provider<E2EEncryptionService>((ref) {
  const storage = FlutterSecureStorage();
  return E2EEncryptionService(storage, AppDatabase.instance);
});

final e2eInitializedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(e2eEncryptionServiceProvider);
  await service.initialize();
  return true;
});

/// Exception thrown when a session is missing for decryption
class MissingSessionException implements Exception {
  MissingSessionException(this.message, {required this.roomId, this.senderKey});
  final String message;
  final String roomId;
  final String? senderKey;

  @override
  String toString() => 'MissingSessionException: $message';
}

/// Exception thrown when decryption fails
class DecryptionException implements Exception {
  DecryptionException(this.message, {required this.roomId});
  final String message;
  final String roomId;

  @override
  String toString() => 'DecryptionException: $message';
}
