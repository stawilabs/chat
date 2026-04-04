import 'dart:convert';

import 'package:antinvestor_api_common/antinvestor_api_common.dart'
    as common_types;
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/sync/chat_event_codec.dart';
import 'package:stawi/features/messages/domain/room_event.dart' as domain;

void main() {
  group('ChatEventCodec', () {
    test('buildPayload encodes encrypted text correctly', () {
      final payload = ChatEventCodec.buildPayload({
        'encrypted': true,
        'algorithm': 'megolm.v1',
        'ciphertext': base64Encode(utf8.encode('ciphertext')),
        'sessionId': 'session-1',
        'senderKey': 'sender-key-1',
      }, domain.RoomEventType.text);

      expect(payload.hasEncrypted(), isTrue);
      expect(payload.encrypted.algorithm, equals('megolm.v1'));
      expect(
        utf8.decode(payload.encrypted.ciphertext),
        equals('ciphertext'),
      );
      expect(payload.encrypted.sessionId, equals('session-1'));
      expect(payload.encrypted.senderKeyId, equals('sender-key-1'));
    });

    test('buildRoomEvent includes subscription id and parent id', () {
      final event = ChatEventCodec.buildRoomEvent(
        eventId: 'event-1',
        roomId: 'room-1',
        subscriptionId: 'sub-1',
        localType: domain.RoomEventType.text,
        content: {'text': 'hello'},
        timestamp: common_types.Timestamp.fromDateTime(DateTime(2026)),
        parentId: 'parent-1',
      );

      expect(event.id, equals('event-1'));
      expect(event.roomId, equals('room-1'));
      expect(event.subscriptionId, equals('sub-1'));
      expect(event.parentId, equals('parent-1'));
      expect(event.payload.text.body, equals('hello'));
    });
  });
}
