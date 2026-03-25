// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Room _$RoomFromJson(Map<String, dynamic> json) => _Room(
  id: json['id'] as String,
  name: json['name'] as String,
  type: json['type'] as String,
  lastEventId: json['lastEventId'] as String?,
  lastEventIndex: (json['lastEventIndex'] as num?)?.toInt() ?? 0,
  unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
  metadata: json['metadata'] as Map<String, dynamic>?,
  disappearingTimeout: (json['disappearingTimeout'] as num?)?.toInt(),
  mutedUntil: (json['mutedUntil'] as num?)?.toInt(),
  memberLimit: (json['memberLimit'] as num?)?.toInt(),
  memberLimitEnabled: json['memberLimitEnabled'] as bool? ?? true,
);

Map<String, dynamic> _$RoomToJson(_Room instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': instance.type,
  'lastEventId': instance.lastEventId,
  'lastEventIndex': instance.lastEventIndex,
  'unreadCount': instance.unreadCount,
  'metadata': instance.metadata,
  'disappearingTimeout': instance.disappearingTimeout,
  'mutedUntil': instance.mutedUntil,
  'memberLimit': instance.memberLimit,
  'memberLimitEnabled': instance.memberLimitEnabled,
};
