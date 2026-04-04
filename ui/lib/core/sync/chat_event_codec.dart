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
      case domain.RoomEventType.unknown:
        return pb.RoomEventType.ROOM_EVENT_TYPE_UNSPECIFIED;
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
      case domain.RoomEventType.groupCallStageUpdate:
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

    final callPayload = _buildCallPayload(content, localType);
    if (callPayload != null) {
      payload.call = callPayload;
      return payload;
    }

    if (content.isNotEmpty) {
      payload.text = pb.TextContent(body: jsonEncode(content), format: 'json');
    }

    return payload;
  }

  static pb.CallContent? _buildCallPayload(
    Map<String, dynamic> content,
    domain.RoomEventType localType,
  ) {
    if (!_isCallType(localType)) {
      return null;
    }

    final metadata = Map<String, dynamic>.from(content)
      ..remove('callId')
      ..remove('callType')
      ..remove('sdp')
      ..remove('type')
      ..remove('candidate')
      ..remove('iceCandidate');

    final payload = pb.CallContent(
      callId: content['callId'] as String? ?? '',
      type: _callTypeFromContent(content),
      action: _callActionFromLocalType(localType),
    );

    final sdp = content['sdp'] as String?;
    if (sdp != null && sdp.isNotEmpty) {
      payload.sdp = sdp;
    }

    final candidate =
        content['candidate'] as String? ?? content['iceCandidate'] as String?;
    if (candidate != null && candidate.isNotEmpty) {
      payload.iceCandidate = candidate;
    }

    final signalKind = _signalKindFromLocalType(localType);
    if (signalKind != null) {
      metadata['signalKind'] = signalKind;
    }

    if (metadata.isNotEmpty) {
      payload.metadata = _mapToStruct(metadata);
    }

    return payload;
  }

  static bool _isCallType(domain.RoomEventType type) {
    switch (type) {
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
      case domain.RoomEventType.groupCallStageUpdate:
        return true;
      default:
        return false;
    }
  }

  static pb.CallContent_CallAction _callActionFromLocalType(
    domain.RoomEventType type,
  ) {
    switch (type) {
      case domain.RoomEventType.callOffer:
      case domain.RoomEventType.groupCallOffer:
        return pb.CallContent_CallAction.CALL_ACTION_OFFER;
      case domain.RoomEventType.callAnswer:
      case domain.RoomEventType.groupCallAnswer:
        return pb.CallContent_CallAction.CALL_ACTION_ANSWER;
      case domain.RoomEventType.callIce:
      case domain.RoomEventType.groupCallIce:
        return pb.CallContent_CallAction.CALL_ACTION_ICE_CANDIDATE;
      case domain.RoomEventType.callEnd:
      case domain.RoomEventType.groupCallEnd:
        return pb.CallContent_CallAction.CALL_ACTION_END;
      default:
        return pb.CallContent_CallAction.CALL_ACTION_UNSPECIFIED;
    }
  }

  static pb.CallContent_CallType _callTypeFromContent(
    Map<String, dynamic> content,
  ) {
    switch ((content['callType'] as String? ?? '').toLowerCase()) {
      case 'audio':
        return pb.CallContent_CallType.CALL_TYPE_AUDIO;
      case 'screen_share':
      case 'screenshare':
      case 'screen-share':
        return pb.CallContent_CallType.CALL_TYPE_SCREEN_SHARE;
      case 'video':
        return pb.CallContent_CallType.CALL_TYPE_VIDEO;
      default:
        return pb.CallContent_CallType.CALL_TYPE_VIDEO;
    }
  }

  static String? _signalKindFromLocalType(domain.RoomEventType type) {
    switch (type) {
      case domain.RoomEventType.groupCallStart:
        return 'group_start';
      case domain.RoomEventType.groupCallJoin:
        return 'group_join';
      case domain.RoomEventType.groupCallLeave:
        return 'group_leave';
      case domain.RoomEventType.groupCallEnd:
        return 'group_end';
      case domain.RoomEventType.groupCallOffer:
        return 'group_offer';
      case domain.RoomEventType.groupCallAnswer:
        return 'group_answer';
      case domain.RoomEventType.groupCallIce:
        return 'group_ice';
      case domain.RoomEventType.groupCallMuteUpdate:
        return 'group_mute_update';
      case domain.RoomEventType.groupCallStageUpdate:
        return 'group_stage_update';
      default:
        return null;
    }
  }

  static common_types.Struct _mapToStruct(Map<String, dynamic> map) {
    final struct = common_types.Struct();
    for (final entry in map.entries) {
      struct.fields[entry.key] = _objectToValue(entry.value);
    }
    return struct;
  }

  static common_types.Value _objectToValue(Object? obj) {
    final value = common_types.Value();
    if (obj == null) {
      value.nullValue = common_types.NullValue.NULL_VALUE;
    } else if (obj is String) {
      value.stringValue = obj;
    } else if (obj is num) {
      value.numberValue = obj.toDouble();
    } else if (obj is bool) {
      value.boolValue = obj;
    } else if (obj is List) {
      final listValue = common_types.ListValue();
      listValue.values.addAll(obj.map(_objectToValue));
      value.listValue = listValue;
    } else if (obj is Map) {
      value.structValue = _mapToStruct(obj.cast<String, dynamic>());
    }
    return value;
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
