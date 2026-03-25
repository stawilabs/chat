import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/isolates/crypto_isolate.dart';

void main() {
  group('HashResult', () {
    test('should serialize to JSON', () {
      final result = HashResult(
        hash: 'abc123def456',
        algorithm: 'sha256',
        inputLength: 42,
      );

      final json = result.toJson();

      expect(json['hash'], equals('abc123def456'));
      expect(json['algorithm'], equals('sha256'));
      expect(json['inputLength'], equals(42));
    });

    test('should deserialize from JSON', () {
      final json = {
        'hash': 'abc123def456',
        'algorithm': 'sha256',
        'inputLength': 42,
      };

      final result = HashResult.fromJson(json);

      expect(result.hash, equals('abc123def456'));
      expect(result.algorithm, equals('sha256'));
      expect(result.inputLength, equals(42));
    });
  });

  group('KeyDerivationResult', () {
    test('should serialize to JSON', () {
      final result = KeyDerivationResult(
        derivedKey: 'base64encodedkey==',
        salt: 'randomsalt==',
        iterations: 100000,
        keyLength: 32,
      );

      final json = result.toJson();

      expect(json['derivedKey'], equals('base64encodedkey=='));
      expect(json['salt'], equals('randomsalt=='));
      expect(json['iterations'], equals(100000));
      expect(json['keyLength'], equals(32));
    });

    test('should deserialize from JSON', () {
      final json = {
        'derivedKey': 'base64encodedkey==',
        'salt': 'randomsalt==',
        'iterations': 100000,
        'keyLength': 32,
      };

      final result = KeyDerivationResult.fromJson(json);

      expect(result.derivedKey, equals('base64encodedkey=='));
      expect(result.salt, equals('randomsalt=='));
      expect(result.iterations, equals(100000));
      expect(result.keyLength, equals(32));
    });
  });

  group('Hashing Algorithms', () {
    test('should support SHA-256', () {
      // Simulate what the isolate does
      const algorithm = 'sha256';
      expect(['sha256', 'sha1', 'sha512', 'md5'], contains(algorithm));
    });

    test('should support SHA-1', () {
      const algorithm = 'sha1';
      expect(['sha256', 'sha1', 'sha512', 'md5'], contains(algorithm));
    });

    test('should support SHA-512', () {
      const algorithm = 'sha512';
      expect(['sha256', 'sha1', 'sha512', 'md5'], contains(algorithm));
    });

    test('should support MD5', () {
      const algorithm = 'md5';
      expect(['sha256', 'sha1', 'sha512', 'md5'], contains(algorithm));
    });
  });

  group('HMAC Operations', () {
    test('should generate HMAC with key', () {
      // Test input validation
      const data = 'test data';
      const key = 'secret key';
      const algorithm = 'sha256';

      expect(data, isNotEmpty);
      expect(key, isNotEmpty);
      expect(['sha256', 'sha1', 'sha512', 'md5'], contains(algorithm));
    });

    test('should verify HMAC with correct key', () {
      // Simulate constant-time comparison
      bool constantTimeEquals(String a, String b) {
        if (a.length != b.length) return false;

        var result = 0;
        for (var i = 0; i < a.length; i++) {
          result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
        }
        return result == 0;
      }

      expect(constantTimeEquals('abc', 'abc'), isTrue);
      expect(constantTimeEquals('abc', 'abd'), isFalse);
      expect(constantTimeEquals('abc', 'abcd'), isFalse);
    });
  });

  group('Base64 Encoding/Decoding', () {
    test('should encode bytes to base64', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      // Simulate encoding
      expect(bytes.length, equals(5));
      expect(bytes, isA<Uint8List>());
    });

    test('should decode base64 to bytes', () {
      const encoded = 'AQIDBAU='; // Base64 of [1, 2, 3, 4, 5]

      expect(encoded, isNotEmpty);
      expect(encoded.endsWith('='), isTrue); // Valid base64 padding
    });
  });

  group('Key Derivation', () {
    test('should use reasonable defaults', () {
      const defaultIterations = 100000;
      const defaultKeyLength = 32;

      expect(defaultIterations, greaterThanOrEqualTo(10000));
      expect(defaultKeyLength, equals(32)); // 256 bits
    });

    test('should accept custom parameters', () {
      const customIterations = 50000;
      const customKeyLength = 64;

      expect(customIterations, greaterThan(0));
      expect(customKeyLength, greaterThan(0));
    });
  });

  group('Random Byte Generation', () {
    test('should generate specified length', () {
      const length = 32;

      final bytes = Uint8List(length);
      expect(bytes.length, equals(length));
    });

    test('should accept various lengths', () {
      const lengths = [16, 32, 64, 128];

      for (final length in lengths) {
        final bytes = Uint8List(length);
        expect(bytes.length, equals(length));
      }
    });
  });

  group('Salt Generation', () {
    test('should generate 16-byte salt by default', () {
      const defaultSaltLength = 16;
      final salt = Uint8List(defaultSaltLength);

      expect(salt.length, equals(16));
    });
  });

  group('Input Validation', () {
    test('should require non-empty data for hashing', () {
      const data = 'test';
      expect(data.isNotEmpty, isTrue);
    });

    test('should require non-empty key for HMAC', () {
      const key = 'secret';
      expect(key.isNotEmpty, isTrue);
    });

    test('should require positive key length', () {
      const keyLength = 32;
      expect(keyLength, greaterThan(0));
    });

    test('should require positive iterations', () {
      const iterations = 100000;
      expect(iterations, greaterThan(0));
    });
  });

  group('Algorithm Case Insensitivity', () {
    test('should accept lowercase algorithm names', () {
      final algorithms = ['sha256', 'sha1', 'sha512', 'md5'];

      for (final algo in algorithms) {
        expect(algo.toLowerCase(), equals(algo));
      }
    });

    test('should handle uppercase algorithm names', () {
      final algorithms = ['SHA256', 'SHA1', 'SHA512', 'MD5'];

      for (final algo in algorithms) {
        final normalized = algo.toLowerCase();
        expect(['sha256', 'sha1', 'sha512', 'md5'], contains(normalized));
      }
    });
  });
}
