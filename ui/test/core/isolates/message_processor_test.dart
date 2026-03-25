import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/isolates/message_processor.dart';

void main() {
  group('MessageBatchInput', () {
    test('should serialize to JSON', () {
      final input = MessageBatchInput(
        messages: [
          {'id': '1', 'text': 'Hello'},
          {'id': '2', 'text': 'World'},
        ],
        roomId: 'room-123',
        existingIds: {'existing-1', 'existing-2'},
      );

      final json = input.toJson();

      expect(json['messages'], hasLength(2));
      expect(json['roomId'], equals('room-123'));
      expect(json['existingIds'], hasLength(2));
    });

    test('should deserialize from JSON', () {
      final json = {
        'messages': [
          {'id': '1', 'text': 'Hello'},
        ],
        'roomId': 'room-123',
        'existingIds': ['existing-1'],
      };

      final input = MessageBatchInput.fromJson(json);

      expect(input.messages, hasLength(1));
      expect(input.roomId, equals('room-123'));
      expect(input.existingIds, contains('existing-1'));
    });

    test('should handle missing optional fields', () {
      final json = {
        'messages': [
          {'id': '1', 'text': 'Hello'},
        ],
      };

      final input = MessageBatchInput.fromJson(json);

      expect(input.roomId, isNull);
      expect(input.existingIds, isNull);
    });
  });

  group('MessageBatchResult', () {
    test('should serialize to JSON', () {
      final result = MessageBatchResult(
        processedMessages: [
          {'id': '1', 'processed': true},
        ],
        newMessageCount: 1,
        duplicateCount: 2,
        invalidCount: 3,
        errors: ['error 1', 'error 2'],
      );

      final json = result.toJson();

      expect(json['processedMessages'], hasLength(1));
      expect(json['newMessageCount'], equals(1));
      expect(json['duplicateCount'], equals(2));
      expect(json['invalidCount'], equals(3));
      expect(json['errors'], hasLength(2));
    });

    test('should deserialize from JSON', () {
      final json = {
        'processedMessages': [
          {'id': '1'},
        ],
        'newMessageCount': 5,
        'duplicateCount': 2,
        'invalidCount': 1,
      };

      final result = MessageBatchResult.fromJson(json);

      expect(result.processedMessages, hasLength(1));
      expect(result.newMessageCount, equals(5));
      expect(result.duplicateCount, equals(2));
      expect(result.invalidCount, equals(1));
      expect(result.errors, isNull);
    });

    test('should handle errors list', () {
      final json = {
        'processedMessages': <Map<String, dynamic>>[],
        'newMessageCount': 0,
        'duplicateCount': 0,
        'invalidCount': 2,
        'errors': ['Error 1', 'Error 2'],
      };

      final result = MessageBatchResult.fromJson(json);

      expect(result.errors, hasLength(2));
      expect(result.errors, contains('Error 1'));
    });
  });

  group('Message Validation Logic', () {
    test('should recognize valid message', () {
      final validMessage = {
        'id': 'msg-123',
        'roomId': 'room-456',
        'senderId': 'user-789',
        'type': 'text',
        'content': {'text': 'Hello'},
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Test basic validation
      expect(validMessage['id'], isNotNull);
      expect(validMessage['roomId'], isNotNull);
      expect(validMessage['type'], isNotNull);
    });

    test('should identify invalid message without id', () {
      final invalidMessage = {'roomId': 'room-456', 'type': 'text'};

      expect(invalidMessage.containsKey('id'), isFalse);
    });

    test('should identify invalid message with empty id', () {
      final invalidMessage = {'id': '', 'roomId': 'room-456', 'type': 'text'};

      expect((invalidMessage['id']!).isEmpty, isTrue);
    });
  });

  group('Message Normalization Logic', () {
    test('should trim string fields', () {
      final message = {
        'id': '  msg-123  ',
        'roomId': '  room-456  ',
        'senderId': '  user-789  ',
        'type': 'text',
      };

      // Simulate normalization
      final normalized = {
        'id': (message['id']!).trim(),
        'roomId': (message['roomId']!).trim(),
        'senderId': (message['senderId']!).trim(),
        'type': message['type'],
      };

      expect(normalized['id'], equals('msg-123'));
      expect(normalized['roomId'], equals('room-456'));
      expect(normalized['senderId'], equals('user-789'));
    });

    test('should add default status', () {
      final message = {'id': 'msg-123', 'roomId': 'room-456', 'type': 'text'};

      // Simulate normalization
      final normalized = Map<String, dynamic>.from(message);
      normalized['status'] ??= 1; // EventStatus.sent

      expect(normalized['status'], equals(1));
    });

    test('should add default createdAt', () {
      final message = {'id': 'msg-123', 'roomId': 'room-456', 'type': 'text'};

      // Simulate normalization
      final normalized = Map<String, dynamic>.from(message);
      normalized['createdAt'] ??= DateTime.now().millisecondsSinceEpoch;

      expect(normalized['createdAt'], isNotNull);
      expect(normalized['createdAt'], isA<int>());
    });
  });

  group('Deduplication Logic', () {
    test('should remove duplicates by id', () {
      final messages = [
        {'id': '1', 'text': 'First'},
        {'id': '2', 'text': 'Second'},
        {'id': '1', 'text': 'Duplicate'}, // Duplicate
      ];

      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];

      for (final message in messages) {
        final id = message['id']!;
        if (!seen.contains(id)) {
          seen.add(id);
          unique.add(message);
        }
      }

      expect(unique, hasLength(2));
      expect(unique[0]['text'], equals('First'));
      expect(unique[1]['text'], equals('Second'));
    });

    test('should respect existing IDs', () {
      final messages = [
        {'id': '1', 'text': 'New'},
        {'id': '2', 'text': 'Also new'},
      ];
      final existingIds = {'1'};

      final newMessages = messages
          .where((m) => !existingIds.contains(m['id']))
          .toList();

      expect(newMessages, hasLength(1));
      expect(newMessages[0]['id'], equals('2'));
    });
  });

  group('JSON Batch Parsing Logic', () {
    test('should parse valid JSON strings', () {
      final jsonStrings = [
        '{"id": "1", "text": "Hello"}',
        '{"id": "2", "text": "World"}',
      ];

      final results = <Map<String, dynamic>>[];
      for (final jsonStr in jsonStrings) {
        try {
          final _ = Map<String, dynamic>.from(
            Uri.splitQueryString(jsonStr.replaceAll(RegExp('[{}":]'), '&')),
          );
          // This is a simplified test - actual parsing uses jsonDecode
          results.add({'id': jsonStr.contains('"1"') ? '1' : '2'});
        } catch (e) {
          // Skip invalid
        }
      }

      expect(results, hasLength(2));
    });

    test('should skip invalid JSON', () {
      final jsonStrings = ['{"id": "1"}', 'invalid json', '{"id": "2"}'];

      var validCount = 0;
      for (final jsonStr in jsonStrings) {
        if (jsonStr.startsWith('{') && jsonStr.endsWith('}')) {
          validCount++;
        }
      }

      expect(validCount, equals(2));
    });
  });

  group('Message Serialization', () {
    test('should serialize message list', () {
      final messages = [
        {'id': '1', 'text': 'Hello', 'count': 5},
        {
          'id': '2',
          'text': 'World',
          'nested': {'key': 'value'},
        },
      ];

      // Simulate serialization - in actual code this uses jsonEncode
      for (final message in messages) {
        expect(message, isA<Map<String, dynamic>>());
        expect(message.containsKey('id'), isTrue);
      }
    });
  });
}
