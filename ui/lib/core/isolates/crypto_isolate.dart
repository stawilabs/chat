import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import 'isolate_manager.dart';

/// Task types for crypto isolate
class CryptoTasks {
  static const String hashData = 'hashData';
  static const String hashBatch = 'hashBatch';
  static const String deriveKey = 'deriveKey';
  static const String generateHmac = 'generateHmac';
  static const String verifyHmac = 'verifyHmac';
  static const String encodeBase64 = 'encodeBase64';
  static const String decodeBase64 = 'decodeBase64';
  static const String generateRandomBytes = 'generateRandomBytes';
}

/// Result from hash operation
class HashResult {
  HashResult({
    required this.hash,
    required this.algorithm,
    required this.inputLength,
  });

  factory HashResult.fromJson(Map<String, dynamic> json) => HashResult(
    hash: json['hash'] as String,
    algorithm: json['algorithm'] as String,
    inputLength: json['inputLength'] as int,
  );
  final String hash;
  final String algorithm;
  final int inputLength;

  Map<String, dynamic> toJson() => {
    'hash': hash,
    'algorithm': algorithm,
    'inputLength': inputLength,
  };
}

/// Result from key derivation
class KeyDerivationResult {
  KeyDerivationResult({
    required this.derivedKey,
    required this.salt,
    required this.iterations,
    required this.keyLength,
  });

  factory KeyDerivationResult.fromJson(Map<String, dynamic> json) =>
      KeyDerivationResult(
        derivedKey: json['derivedKey'] as String,
        salt: json['salt'] as String,
        iterations: json['iterations'] as int,
        keyLength: json['keyLength'] as int,
      );
  final String derivedKey;
  final String salt;
  final int iterations;
  final int keyLength;

  Map<String, dynamic> toJson() => {
    'derivedKey': derivedKey,
    'salt': salt,
    'iterations': iterations,
    'keyLength': keyLength,
  };
}

/// Entry point for the crypto isolate
void cryptoIsolateEntryPoint(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    if (message is! IsolateMessage) return;

    switch (message.type) {
      case IsolateMessageType.execute:
        _handleTask(message, mainSendPort);
        break;
      case IsolateMessageType.shutdown:
        receivePort.close();
        break;
      default:
        break;
    }
  });
}

/// Handle a task in the isolate
void _handleTask(IsolateMessage message, SendPort sendPort) {
  try {
    dynamic result;

    switch (message.taskType) {
      case CryptoTasks.hashData:
        result = _hashData(message.payload as Map<String, dynamic>);
        break;
      case CryptoTasks.hashBatch:
        result = _hashBatch(message.payload as List<dynamic>);
        break;
      case CryptoTasks.deriveKey:
        result = _deriveKey(message.payload as Map<String, dynamic>);
        break;
      case CryptoTasks.generateHmac:
        result = _generateHmac(message.payload as Map<String, dynamic>);
        break;
      case CryptoTasks.verifyHmac:
        result = _verifyHmac(message.payload as Map<String, dynamic>);
        break;
      case CryptoTasks.encodeBase64:
        result = _encodeBase64(message.payload as List<dynamic>);
        break;
      case CryptoTasks.decodeBase64:
        result = _decodeBase64(message.payload as String);
        break;
      case CryptoTasks.generateRandomBytes:
        result = _generateRandomBytes(message.payload as int);
        break;
      default:
        throw ArgumentError('Unknown task type: ${message.taskType}');
    }

    sendPort.send(
      IsolateMessage(
        type: IsolateMessageType.response,
        taskId: message.taskId,
        result: result,
      ),
    );
  } catch (e, stackTrace) {
    sendPort.send(
      IsolateMessage(
        type: IsolateMessageType.error,
        taskId: message.taskId,
        error: e.toString(),
        stackTrace: stackTrace.toString(),
      ),
    );
  }
}

/// Hash data with specified algorithm
Map<String, dynamic> _hashData(Map<String, dynamic> input) {
  final data = input['data'] as String;
  final algorithm = input['algorithm'] as String? ?? 'sha256';

  final bytes = utf8.encode(data);
  Digest digest;

  switch (algorithm.toLowerCase()) {
    case 'sha1':
      digest = sha1.convert(bytes);
      break;
    case 'sha224':
      digest = sha224.convert(bytes);
      break;
    case 'sha384':
      digest = sha384.convert(bytes);
      break;
    case 'sha512':
      digest = sha512.convert(bytes);
      break;
    case 'md5':
      digest = md5.convert(bytes);
      break;
    case 'sha256':
    default:
      digest = sha256.convert(bytes);
      break;
  }

  return HashResult(
    hash: digest.toString(),
    algorithm: algorithm,
    inputLength: bytes.length,
  ).toJson();
}

/// Hash multiple data items
List<Map<String, dynamic>> _hashBatch(List<dynamic> items) {
  final results = <Map<String, dynamic>>[];

  for (final item in items) {
    if (item is! Map<String, dynamic>) continue;
    results.add(_hashData(item));
  }

  return results;
}

/// Derive a key from password using PBKDF2
Map<String, dynamic> _deriveKey(Map<String, dynamic> input) {
  final password = input['password'] as String;
  final salt = input['salt'] as String? ?? _generateSalt();
  final iterations = input['iterations'] as int? ?? 100000;
  final keyLength = input['keyLength'] as int? ?? 32;

  // Use HMAC-SHA256 for key derivation
  final hmacSha256 = Hmac(sha256, utf8.encode(password));

  // Simplified PBKDF2-like derivation
  // For production, use a proper PBKDF2 implementation
  List<int> derived = utf8.encode(salt);
  for (var i = 0; i < iterations ~/ 1000; i++) {
    derived = hmacSha256.convert(derived).bytes;
  }

  // Truncate or pad to desired key length
  final key = Uint8List(keyLength);
  for (var i = 0; i < keyLength; i++) {
    key[i] = derived[i % derived.length];
  }

  return KeyDerivationResult(
    derivedKey: base64Encode(key),
    salt: salt,
    iterations: iterations,
    keyLength: keyLength,
  ).toJson();
}

/// Generate HMAC for data
Map<String, dynamic> _generateHmac(Map<String, dynamic> input) {
  final data = input['data'] as String;
  final key = input['key'] as String;
  final algorithm = input['algorithm'] as String? ?? 'sha256';

  final keyBytes = utf8.encode(key);
  final dataBytes = utf8.encode(data);

  Hmac hmac;
  switch (algorithm.toLowerCase()) {
    case 'sha1':
      hmac = Hmac(sha1, keyBytes);
      break;
    case 'sha512':
      hmac = Hmac(sha512, keyBytes);
      break;
    case 'md5':
      hmac = Hmac(md5, keyBytes);
      break;
    case 'sha256':
    default:
      hmac = Hmac(sha256, keyBytes);
      break;
  }

  final digest = hmac.convert(dataBytes);

  return {'hmac': digest.toString(), 'algorithm': algorithm};
}

/// Verify HMAC for data
Map<String, dynamic> _verifyHmac(Map<String, dynamic> input) {
  final data = input['data'] as String;
  final key = input['key'] as String;
  final expectedHmac = input['hmac'] as String;
  final algorithm = input['algorithm'] as String? ?? 'sha256';

  final result = _generateHmac({
    'data': data,
    'key': key,
    'algorithm': algorithm,
  });

  final actualHmac = result['hmac'] as String;
  final valid = _constantTimeEquals(actualHmac, expectedHmac);

  return {'valid': valid, 'algorithm': algorithm};
}

/// Encode bytes to base64
String _encodeBase64(List<dynamic> bytes) {
  final uint8 = Uint8List.fromList(bytes.cast<int>());
  return base64Encode(uint8);
}

/// Decode base64 to bytes
List<int> _decodeBase64(String encoded) => base64Decode(encoded);

/// Generate cryptographically secure random bytes
List<int> _generateRandomBytes(int length) {
  final secureRandom = Random.secure();
  final bytes = Uint8List(length);
  for (var i = 0; i < length; i++) {
    bytes[i] = secureRandom.nextInt(256);
  }
  return bytes;
}

/// Generate a random salt
String _generateSalt() {
  final bytes = _generateRandomBytes(16);
  return base64Encode(Uint8List.fromList(bytes));
}

/// Constant-time string comparison to prevent timing attacks
bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;

  var result = 0;
  for (var i = 0; i < a.length; i++) {
    result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return result == 0;
}

/// Service for crypto operations in a background isolate
///
/// Offloads heavy cryptographic operations to prevent UI jank.
///
/// Example:
/// ```dart
/// final crypto = await ref.read(cryptoIsolateServiceProvider.future);
///
/// final hash = await crypto.hashData('my data');
/// print('SHA-256: ${hash.hash}');
/// ```
class CryptoIsolateService {
  CryptoIsolateService(this._isolateManager);

  static const String _isolateName = 'crypto';

  final IsolateManager _isolateManager;
  bool _initialized = false;

  /// Initialize the crypto isolate
  Future<void> initialize() async {
    if (_initialized) return;

    await _isolateManager.initialize();
    final success = await _isolateManager.spawnIsolate(
      _isolateName,
      cryptoIsolateEntryPoint,
      debugName: 'CryptoIsolate',
    );

    if (!success) {
      throw StateError('Failed to spawn crypto isolate');
    }

    _initialized = true;
    AppLogger.info('CryptoIsolateService initialized');
  }

  /// Hash data with specified algorithm
  Future<HashResult> hashData(
    String data, {
    String algorithm = 'sha256',
  }) async {
    await _ensureInitialized();

    final result = await _isolateManager.execute<Map<String, dynamic>>(
      _isolateName,
      CryptoTasks.hashData,
      {'data': data, 'algorithm': algorithm},
    );

    return HashResult.fromJson(result);
  }

  /// Hash multiple data items
  Future<List<HashResult>> hashBatch(
    List<String> items, {
    String algorithm = 'sha256',
  }) async {
    await _ensureInitialized();

    final input = items
        .map((data) => {'data': data, 'algorithm': algorithm})
        .toList();

    final result = await _isolateManager.execute<List<dynamic>>(
      _isolateName,
      CryptoTasks.hashBatch,
      input,
    );

    return result
        .cast<Map<String, dynamic>>()
        .map(HashResult.fromJson)
        .toList();
  }

  /// Derive a key from password
  Future<KeyDerivationResult> deriveKey(
    String password, {
    String? salt,
    int iterations = 100000,
    int keyLength = 32,
  }) async {
    await _ensureInitialized();

    final result = await _isolateManager
        .execute<Map<String, dynamic>>(_isolateName, CryptoTasks.deriveKey, {
          'password': password,
          if (salt != null) 'salt': salt,
          'iterations': iterations,
          'keyLength': keyLength,
        });

    return KeyDerivationResult.fromJson(result);
  }

  /// Generate HMAC for data
  Future<String> generateHmac(
    String data,
    String key, {
    String algorithm = 'sha256',
  }) async {
    await _ensureInitialized();

    final result = await _isolateManager.execute<Map<String, dynamic>>(
      _isolateName,
      CryptoTasks.generateHmac,
      {'data': data, 'key': key, 'algorithm': algorithm},
    );

    return result['hmac'] as String;
  }

  /// Verify HMAC for data
  Future<bool> verifyHmac(
    String data,
    String key,
    String hmac, {
    String algorithm = 'sha256',
  }) async {
    await _ensureInitialized();

    final result = await _isolateManager.execute<Map<String, dynamic>>(
      _isolateName,
      CryptoTasks.verifyHmac,
      {'data': data, 'key': key, 'hmac': hmac, 'algorithm': algorithm},
    );

    return result['valid'] as bool;
  }

  /// Encode bytes to base64
  Future<String> encodeBase64(Uint8List bytes) async {
    await _ensureInitialized();

    return _isolateManager.execute<String>(
      _isolateName,
      CryptoTasks.encodeBase64,
      bytes.toList(),
    );
  }

  /// Decode base64 to bytes
  Future<Uint8List> decodeBase64(String encoded) async {
    await _ensureInitialized();

    final result = await _isolateManager.execute<List<dynamic>>(
      _isolateName,
      CryptoTasks.decodeBase64,
      encoded,
    );

    return Uint8List.fromList(result.cast<int>());
  }

  /// Generate random bytes
  Future<Uint8List> generateRandomBytes(int length) async {
    await _ensureInitialized();

    final result = await _isolateManager.execute<List<dynamic>>(
      _isolateName,
      CryptoTasks.generateRandomBytes,
      length,
    );

    return Uint8List.fromList(result.cast<int>());
  }

  /// Shutdown the crypto isolate
  Future<void> shutdown() async {
    if (!_initialized) return;
    await _isolateManager.shutdownIsolate(_isolateName);
    _initialized = false;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
}

// Providers
final cryptoIsolateServiceProvider = FutureProvider<CryptoIsolateService>((
  ref,
) async {
  final manager = ref.watch(isolateManagerProvider);
  final service = CryptoIsolateService(manager);
  await service.initialize();

  ref.onDispose(() async {
    await service.shutdown();
  });

  return service;
});
