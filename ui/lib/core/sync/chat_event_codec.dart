import 'dart:convert';

import 'package:antinvestor_api_chat/antinvestor_api_chat.dart' as pb;
import 'package:antinvestor_api_common/antinvestor_api_common.dart'
    as common_types;
import 'package:fixnum/fixnum.dart';

import '../../features/messages/domain/room_event.dart' as domain;

class ChatEventCodec {
  const ChatEventCodec._();

  static pb.RoomEventType mapLocalEventTypeToProto(domain.RoomEventType type) {
    switch (type) {
      case domain.RoomEventType.text:
        return pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE;
      case domain.RoomEventType.image:
      case domain.RoomEventType.video:
      case domain.RoomEventType.audio:
      case domain.RoomEventType.file:
        return pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE;
      case domain.RoomEventType.reaction:
        return pb.RoomEventType.ROOM_EVENT_TYPE_REACTION;
      case domain.RoomEventType.callOffer:
      case domain.RoomEventType.callAnswer:
      case domain.RoomEventType.callIce:
      case domain.RoomEventType.callEnd:
      case domain.RoomEventType.groupCallStart:
      case domain.RoomEventType.groupCallJoin:
      case domain.RoomEventType.groupCallLeave:
      case domain.RoomEventType.groupCallEnd:
      case domain.RoomEventType.groupCallOffer:
      case domain.RoomEventType.groupCallAnswer:
      case domain.RoomEventType.groupCallIce:
      case domain.RoomEventType.groupCallMuteUpdate:
        return pb.RoomEventType.ROOM_EVENT_TYPE_CALL;
      case domain.RoomEventType.motion:
        return pb.RoomEventType.ROOM_EVENT_TYPE_MOTION;
      case domain.RoomEventType.vote:
      case domain.RoomEventType.transaction:
      case domain.RoomEventType.groupConfig:
      case domain.RoomEventType.roomKey:
      case domain.RoomEventType.roomChange:
        return pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE;
    }
  }

  static pb.Payload buildPayload(
    Map<String, dynamic> content,
    domain.RoomEventType localType,
  ) {
    final payload = pb.Payload();

    if (content['encrypted'] == true && content['ciphertext'] != null) {
      payload.encrypted = pb.EncryptedContent(
        algorithm: content['algorithm'] as String? ?? 'megolm.v1',
        ciphertext: base64Decode(content['ciphertext'] as String),
        senderKeyId: content['senderKey'] as String? ?? '',
        sessionId: content['sessionId'] as String? ?? '',
      );
      return payload;
    }

    if (localType == domain.RoomEventType.text ||
        localType == domain.RoomEventType.roomKey) {
      payload.text = pb.TextContent(
        body: content['text'] as String? ?? '',
        format: 'plain',
      );
      return payload;
    }

    if (localType == domain.RoomEventType.image ||
        localType == domain.RoomEventType.video ||
        localType == domain.RoomEventType.audio ||
        localType == domain.RoomEventType.file) {
      final attachmentId = content['attachmentId'] as String?;
      if (attachmentId == null || attachmentId.isEmpty) {
        throw StateError('Missing attachmentId for media message');
      }

      payload.attachment = pb.AttachmentContent(
        attachmentId: attachmentId,
        filename: content['fileName'] as String? ?? '',
        mimeType: content['mimeType'] as String? ?? '',
        sizeBytes: Int64(content['size'] as int? ?? 0),
      );
      return payload;
    }

    if (content.isNotEmpty) {
      payload.text = pb.TextContent(
        body: jsonEncode(content),
        format: 'json',
      );
    }

    return payload;
  }

  static pb.RoomEvent buildRoomEvent({
    required String eventId,
    required String roomId,
    required String subscriptionId,
    required domain.RoomEventType localType,
    required Map<String, dynamic> content,
    required common_types.Timestamp timestamp,
    String? parentId,
  }) {
    final event = pb.RoomEvent(
      id: eventId,
      roomId: roomId,
      subscriptionId: subscriptionId,
      type: mapLocalEventTypeToProto(localType),
      sentAt: timestamp,
      payload: buildPayload(content, localType),
    );

    if (parentId != null && parentId.isNotEmpty) {
      event.parentId = parentId;
    }

    return event;
  }
}
