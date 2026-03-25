import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/calls/services/turn_credentials_service.dart';

// Simple fake DeviceServiceClient for testing
class FakeDeviceServiceClient {
  // No-op client - service doesn't use it yet
}

void main() {
  group('TurnCredentials', () {
    group('isExpired', () {
      test('returns false for future expiry', () {
        final credentials = TurnCredentials(
          url: 'turn:example.com:3478',
          username: 'user',
          credential: 'pass',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        expect(credentials.isExpired, isFalse);
      });

      test('returns true for past expiry', () {
        final credentials = TurnCredentials(
          url: 'turn:example.com:3478',
          username: 'user',
          credential: 'pass',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        expect(credentials.isExpired, isTrue);
      });

      test('returns true when expiring within 5 minutes', () {
        final credentials = TurnCredentials(
          url: 'turn:example.com:3478',
          username: 'user',
          credential: 'pass',
          expiresAt: DateTime.now().add(const Duration(minutes: 3)),
        );

        expect(credentials.isExpired, isTrue);
      });
    });

    group('toIceServer', () {
      test('returns full config with credentials', () {
        final credentials = TurnCredentials(
          url: 'turn:example.com:3478',
          username: 'user',
          credential: 'pass',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        final config = credentials.toIceServer();

        expect(config['urls'], equals('turn:example.com:3478'));
        expect(config['username'], equals('user'));
        expect(config['credential'], equals('pass'));
      });

      test('returns URL-only config without credentials', () {
        final credentials = TurnCredentials(
          url: 'stun:stun.example.com:3478',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        final config = credentials.toIceServer();

        expect(config['urls'], equals('stun:stun.example.com:3478'));
        expect(config.containsKey('username'), isFalse);
        expect(config.containsKey('credential'), isFalse);
      });
    });
  });

  group('TurnCredentialsService', () {
    group('turnCredentialsServiceProvider', () {
      test('provider is available', () {
        expect(turnCredentialsServiceProvider, isNotNull);
      });
    });

    // Note: Full service tests require a mock DeviceServiceClient.
    // Since the service currently returns STUN-only configuration
    // (TURN API not yet implemented), these tests verify the core behavior.
    // When the TURN API is implemented, add proper mock-based tests.
  });
}
