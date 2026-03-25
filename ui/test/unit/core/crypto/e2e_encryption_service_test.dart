import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/crypto/e2e_encryption_service.dart';

void main() {
  group('E2EEncryptionService', () {
    group('GroupEncryptedMessage', () {
      test('toJson includes all fields', () {
        final message = GroupEncryptedMessage(
          ciphertext: 'encrypted_text',
          sessionId: 'session_123',
          messageIndex: 5,
          senderKey: 'sender_key_abc',
        );

        final json = message.toJson();

        expect(json['ciphertext'], equals('encrypted_text'));
        expect(json['sessionId'], equals('session_123'));
        expect(json['messageIndex'], equals(5));
        expect(json['senderKey'], equals('sender_key_abc'));
      });

      test('toJson omits null senderKey', () {
        final message = GroupEncryptedMessage(
          ciphertext: 'encrypted_text',
          sessionId: 'session_123',
          messageIndex: 0,
        );

        final json = message.toJson();

        expect(json.containsKey('senderKey'), isFalse);
      });

      test('fromJson creates message with all fields', () {
        final json = {
          'ciphertext': 'encrypted_text',
          'sessionId': 'session_123',
          'messageIndex': 10,
          'senderKey': 'sender_key_xyz',
        };

        final message = GroupEncryptedMessage.fromJson(json);

        expect(message.ciphertext, equals('encrypted_text'));
        expect(message.sessionId, equals('session_123'));
        expect(message.messageIndex, equals(10));
        expect(message.senderKey, equals('sender_key_xyz'));
      });

      test('fromJson handles missing senderKey', () {
        final json = {
          'ciphertext': 'encrypted_text',
          'sessionId': 'session_123',
          'messageIndex': 0,
        };

        final message = GroupEncryptedMessage.fromJson(json);

        expect(message.senderKey, isNull);
      });
    });

    group('EncryptedMessage', () {
      test('toJson returns correct structure', () {
        final message = EncryptedMessage(
          ciphertext: 'cipher',
          messageType: 1,
          sessionId: 'session_abc',
        );

        final json = message.toJson();

        expect(json['ciphertext'], equals('cipher'));
        expect(json['messageType'], equals(1));
        expect(json['sessionId'], equals('session_abc'));
      });

      test('fromJson creates message correctly', () {
        final json = {
          'ciphertext': 'cipher_data',
          'messageType': 2,
          'sessionId': 'session_xyz',
        };

        final message = EncryptedMessage.fromJson(json);

        expect(message.ciphertext, equals('cipher_data'));
        expect(message.messageType, equals(2));
        expect(message.sessionId, equals('session_xyz'));
      });
    });

    group('GroupSessionState', () {
      test('stores session data correctly', () {
        final state = GroupSessionState(
          sessionId: 'session_1',
          sessionKey: 'key_data',
          messageIndex: 42,
        );

        expect(state.sessionId, equals('session_1'));
        expect(state.sessionKey, equals('key_data'));
        expect(state.messageIndex, equals(42));
      });

      test('messageIndex can be updated', () {
        final state = GroupSessionState(
          sessionId: 'session_1',
          sessionKey: 'key_data',
          messageIndex: 0,
        );

        state.messageIndex = 100;

        expect(state.messageIndex, equals(100));
      });
    });

    group('MissingSessionException', () {
      test('stores error details', () {
        final exception = MissingSessionException(
          'Session not found',
          roomId: 'room_123',
          senderKey: 'sender_abc',
        );

        expect(exception.message, equals('Session not found'));
        expect(exception.roomId, equals('room_123'));
        expect(exception.senderKey, equals('sender_abc'));
      });

      test('toString includes message', () {
        final exception = MissingSessionException(
          'No session available',
          roomId: 'room_456',
        );

        expect(exception.toString(), contains('No session available'));
      });
    });

    group('DecryptionException', () {
      test('stores error details', () {
        final exception = DecryptionException(
          'Decryption failed',
          roomId: 'room_789',
        );

        expect(exception.message, equals('Decryption failed'));
        expect(exception.roomId, equals('room_789'));
      });

      test('toString includes message', () {
        final exception = DecryptionException(
          'Invalid ciphertext',
          roomId: 'room_abc',
        );

        expect(exception.toString(), contains('Invalid ciphertext'));
      });
    });

    group('e2eEncryptionServiceProvider', () {
      test('provider is defined', () {
        expect(e2eEncryptionServiceProvider, isNotNull);
      });
    });

    group('e2eInitializedProvider', () {
      test('provider is defined', () {
        expect(e2eInitializedProvider, isNotNull);
      });
    });
  });
}
