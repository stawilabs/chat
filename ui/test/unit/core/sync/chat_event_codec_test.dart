import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/sync/chat_event_codec.dart';
import 'package:stawi/features/messages/domain/room_event.dart' as domain;
import 'package:stawi_api_chat/stawi_api_chat.dart' as pb;

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
      expect(utf8.decode(payload.encrypted.ciphertext), equals('ciphertext'));
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
        timestamp: pb.Timestamp.fromDateTime(DateTime(2026)),
        parentId: 'parent-1',
      );

      expect(event.id, equals('event-1'));
      expect(event.roomId, equals('room-1'));
      expect(event.subscriptionId, equals('sub-1'));
      expect(event.parentId, equals('parent-1'));
      expect(event.payload.text.body, equals('hello'));
    });

    test('buildPayload encodes typed direct call payload correctly', () {
      final payload = ChatEventCodec.buildPayload({
        'callId': 'call-1',
        'callType': 'video',
        'topology': 'p2p',
        'senderProfileId': 'profile-1',
        'targetProfileId': 'profile-2',
        'sdp': 'offer-sdp',
        'type': 'offer',
      }, domain.RoomEventType.callOffer);

      expect(payload.hasCall(), isTrue);
      expect(payload.call.callId, equals('call-1'));
      expect(
        payload.call.action,
        equals(pb.CallContent_CallAction.CALL_ACTION_OFFER),
      );
      expect(
        payload.call.type,
        equals(pb.CallContent_CallType.CALL_TYPE_VIDEO),
      );
      expect(payload.call.sdp, equals('offer-sdp'));
      expect(
        payload.call.metadata.fields['targetProfileId']?.stringValue,
        equals('profile-2'),
      );
      expect(
        payload.call.metadata.fields['topology']?.stringValue,
        equals('p2p'),
      );
    });

    test('buildPayload encodes typed group call payload correctly', () {
      final payload = ChatEventCodec.buildPayload({
        'callId': 'call-2',
        'callType': 'video',
        'topology': 'mesh',
        'targetProfileId': 'profile-2',
        'candidate': 'candidate-1',
      }, domain.RoomEventType.groupCallIce);

      expect(payload.hasCall(), isTrue);
      expect(
        payload.call.action,
        equals(pb.CallContent_CallAction.CALL_ACTION_ICE_CANDIDATE),
      );
      expect(payload.call.iceCandidate, equals('candidate-1'));
      expect(
        payload.call.metadata.fields['signalKind']?.stringValue,
        equals('group_ice'),
      );
      expect(
        payload.call.metadata.fields['targetProfileId']?.stringValue,
        equals('profile-2'),
      );
    });

    test('buildPayload encodes authoritative group stage updates', () {
      final payload = ChatEventCodec.buildPayload({
        'callId': 'call-3',
        'callType': 'video',
        'topology': 'mesh',
        'maxVideoPublishers': 5,
        'activeVideoProfileIds': ['profile-1', 'profile-2'],
      }, domain.RoomEventType.groupCallStageUpdate);

      expect(payload.hasCall(), isTrue);
      expect(
        payload.call.metadata.fields['signalKind']?.stringValue,
        equals('group_stage_update'),
      );
      expect(
        payload.call.metadata.fields['maxVideoPublishers']?.numberValue,
        equals(5),
      );
      expect(
        payload.call.metadata.fields['activeVideoProfileIds']?.listValue.values
            .map((value) => value.stringValue)
            .toList(),
        equals(['profile-1', 'profile-2']),
      );
    });
  });

  group('decrypted content is data, never presentation control', () {
    test('a member cannot mark an encrypted message as a room change', () {
      final content = ChatEventCodec.decryptedContent(
        jsonEncode({
          'isRoomChange': true,
          'isModeration': true,
          'type': 'roomChange',
          'action': 'ROOM_CHANGE_ACTION_ROLE_CHANGED',
          'actorSubscriptionId': 'sub-owner',
          'targetSubscriptionIds': ['sub-x'],
          'stawiType': 'financeCard',
          'stawiCard': {'kind': 'loan'},
          'text': 'Treasurer: loan approved, send 500 fee to 07xx',
        }),
      );

      expect(content['text'], 'Treasurer: loan approved, send 500 fee to 07xx');
      for (final key in [
        'isRoomChange',
        'isModeration',
        'type',
        'action',
        'actorSubscriptionId',
        'targetSubscriptionIds',
        'stawiType',
        'stawiCard',
      ]) {
        expect(content.containsKey(key), isFalse, reason: key);
      }
      expect(content['encrypted'], isTrue);
      expect(content['decrypted'], isTrue);
    });

    test('a member cannot claim the decryption flags', () {
      final content = ChatEventCodec.decryptedContent(
        jsonEncode({'text': 'hi', 'encrypted': false, 'decrypted': false}),
      );
      expect(content['encrypted'], isTrue);
      expect(content['decrypted'], isTrue);
    });

    test('structured media content survives decryption', () {
      final content = ChatEventCodec.decryptedContent(
        jsonEncode({
          'mediaId': 'm-1',
          'fileName': 'a.jpg',
          'mimeType': 'image/jpeg',
          'caption': 'look',
        }),
      );
      expect(content['mediaId'], 'm-1');
      expect(content['fileName'], 'a.jpg');
      expect(content['mimeType'], 'image/jpeg');
      expect(content['caption'], 'look');
    });

    test('plain text and non-object JSON decrypt to text', () {
      expect(ChatEventCodec.decryptedContent('hello')['text'], 'hello');
      expect(ChatEventCodec.decryptedContent('[1,2]')['text'], '[1,2]');
      expect(ChatEventCodec.decryptedContent('42')['text'], '42');
    });
  });

  group('only a server-authored payload renders as a system line', () {
    test('a room change payload is a system line', () {
      expect(
        ChatEventCodec.isSystemPayload(
          pb.Payload(roomChange: pb.RoomChangeContent(body: 'x joined')),
        ),
        isTrue,
      );
    });

    test('a moderation payload is the sender\'s own message', () {
      // Chat lets a member send a moderation naming themselves as actor, so
      // it reads as theirs, not as the room's.
      expect(
        ChatEventCodec.isSystemPayload(
          pb.Payload(moderation: pb.ModerationContent(body: 'x removed')),
        ),
        isFalse,
      );
    });

    test('an encrypted or text payload is never a system line', () {
      expect(
        ChatEventCodec.isSystemPayload(
          pb.Payload(encrypted: pb.EncryptedContent(sessionId: 's')),
        ),
        isFalse,
      );
      expect(
        ChatEventCodec.isSystemPayload(
          pb.Payload(text: pb.TextContent(body: '{"isRoomChange":true}')),
        ),
        isFalse,
      );
      expect(ChatEventCodec.isSystemPayload(null), isFalse);
    });
  });
}
