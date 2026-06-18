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
}
