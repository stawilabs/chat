// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_call.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroupCall _$GroupCallFromJson(Map<String, dynamic> json) => _GroupCall(
  callId: json['callId'] as String,
  roomId: json['roomId'] as String,
  hostProfileId: json['hostProfileId'] as String,
  startedAt: DateTime.parse(json['startedAt'] as String),
  participants:
      (json['participants'] as List<dynamic>?)
          ?.map((e) => GroupCallParticipant.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  state:
      $enumDecodeNullable(_$GroupCallStateEnumMap, json['state']) ??
      GroupCallState.initiating,
  endedAt: json['endedAt'] == null
      ? null
      : DateTime.parse(json['endedAt'] as String),
);

Map<String, dynamic> _$GroupCallToJson(_GroupCall instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'roomId': instance.roomId,
      'hostProfileId': instance.hostProfileId,
      'startedAt': instance.startedAt.toIso8601String(),
      'participants': instance.participants,
      'state': _$GroupCallStateEnumMap[instance.state]!,
      'endedAt': instance.endedAt?.toIso8601String(),
    };

const _$GroupCallStateEnumMap = {
  GroupCallState.initiating: 'initiating',
  GroupCallState.ringing: 'ringing',
  GroupCallState.active: 'active',
  GroupCallState.ended: 'ended',
};
