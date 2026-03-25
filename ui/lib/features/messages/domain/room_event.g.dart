// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoomEvent _$RoomEventFromJson(Map<String, dynamic> json) => _RoomEvent(
  id: json['id'] as String,
  roomId: json['roomId'] as String,
  senderId: json['senderId'] as String,
  type: $enumDecode(_$RoomEventTypeEnumMap, json['type']),
  content: json['content'] as Map<String, dynamic>,
  createdAt: (json['createdAt'] as num).toInt(),
  senderContactId: json['senderContactId'] as String?,
  parentId: json['parentId'] as String?,
  status:
      $enumDecodeNullable(_$EventStatusEnumMap, json['status']) ??
      EventStatus.pending,
  serverTs: (json['serverTs'] as num?)?.toInt(),
  localId: json['localId'] as String?,
  editedAt: (json['editedAt'] as num?)?.toInt(),
  redacted: json['redacted'] as bool? ?? false,
  redactedAt: (json['redactedAt'] as num?)?.toInt(),
  redactedBy: json['redactedBy'] as String?,
  retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
  errorMessage: json['errorMessage'] as String?,
  forwardedFromRoom: json['forwardedFromRoom'] as String?,
  forwardedFromEvent: json['forwardedFromEvent'] as String?,
  forwardCount: (json['forwardCount'] as num?)?.toInt() ?? 0,
  forwardRestricted: json['forwardRestricted'] as bool? ?? false,
  expiresAt: (json['expiresAt'] as num?)?.toInt(),
  starred: json['starred'] as bool? ?? false,
  starredAt: (json['starredAt'] as num?)?.toInt(),
);

Map<String, dynamic> _$RoomEventToJson(_RoomEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'roomId': instance.roomId,
      'senderId': instance.senderId,
      'type': _$RoomEventTypeEnumMap[instance.type]!,
      'content': instance.content,
      'createdAt': instance.createdAt,
      'senderContactId': instance.senderContactId,
      'parentId': instance.parentId,
      'status': _$EventStatusEnumMap[instance.status]!,
      'serverTs': instance.serverTs,
      'localId': instance.localId,
      'editedAt': instance.editedAt,
      'redacted': instance.redacted,
      'redactedAt': instance.redactedAt,
      'redactedBy': instance.redactedBy,
      'retryCount': instance.retryCount,
      'errorMessage': instance.errorMessage,
      'forwardedFromRoom': instance.forwardedFromRoom,
      'forwardedFromEvent': instance.forwardedFromEvent,
      'forwardCount': instance.forwardCount,
      'forwardRestricted': instance.forwardRestricted,
      'expiresAt': instance.expiresAt,
      'starred': instance.starred,
      'starredAt': instance.starredAt,
    };

const _$RoomEventTypeEnumMap = {
  RoomEventType.text: 'text',
  RoomEventType.image: 'image',
  RoomEventType.video: 'video',
  RoomEventType.audio: 'audio',
  RoomEventType.file: 'file',
  RoomEventType.reaction: 'reaction',
  RoomEventType.callOffer: 'callOffer',
  RoomEventType.callAnswer: 'callAnswer',
  RoomEventType.callIce: 'callIce',
  RoomEventType.callEnd: 'callEnd',
  RoomEventType.groupCallStart: 'groupCallStart',
  RoomEventType.groupCallJoin: 'groupCallJoin',
  RoomEventType.groupCallLeave: 'groupCallLeave',
  RoomEventType.groupCallEnd: 'groupCallEnd',
  RoomEventType.groupCallOffer: 'groupCallOffer',
  RoomEventType.groupCallAnswer: 'groupCallAnswer',
  RoomEventType.groupCallIce: 'groupCallIce',
  RoomEventType.groupCallMuteUpdate: 'groupCallMuteUpdate',
  RoomEventType.motion: 'motion',
  RoomEventType.vote: 'vote',
  RoomEventType.transaction: 'transaction',
  RoomEventType.groupConfig: 'groupConfig',
  RoomEventType.roomKey: 'roomKey',
  RoomEventType.roomChange: 'roomChange',
};

const _$EventStatusEnumMap = {
  EventStatus.pending: 'pending',
  EventStatus.sent: 'sent',
  EventStatus.delivered: 'delivered',
  EventStatus.read: 'read',
  EventStatus.failed: 'failed',
};
