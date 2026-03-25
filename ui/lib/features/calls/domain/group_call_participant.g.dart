// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_call_participant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroupCallParticipant _$GroupCallParticipantFromJson(
  Map<String, dynamic> json,
) => _GroupCallParticipant(
  profileId: json['profileId'] as String,
  displayName: json['displayName'] as String,
  joinedAt: DateTime.parse(json['joinedAt'] as String),
  avatarUrl: json['avatarUrl'] as String?,
  isAudioMuted: json['isAudioMuted'] as bool? ?? false,
  isVideoOff: json['isVideoOff'] as bool? ?? false,
  isSpeaking: json['isSpeaking'] as bool? ?? false,
  isHost: json['isHost'] as bool? ?? false,
  state:
      $enumDecodeNullable(_$ParticipantStateEnumMap, json['state']) ??
      ParticipantState.joining,
);

Map<String, dynamic> _$GroupCallParticipantToJson(
  _GroupCallParticipant instance,
) => <String, dynamic>{
  'profileId': instance.profileId,
  'displayName': instance.displayName,
  'joinedAt': instance.joinedAt.toIso8601String(),
  'avatarUrl': instance.avatarUrl,
  'isAudioMuted': instance.isAudioMuted,
  'isVideoOff': instance.isVideoOff,
  'isSpeaking': instance.isSpeaking,
  'isHost': instance.isHost,
  'state': _$ParticipantStateEnumMap[instance.state]!,
};

const _$ParticipantStateEnumMap = {
  ParticipantState.invited: 'invited',
  ParticipantState.joining: 'joining',
  ParticipantState.connected: 'connected',
  ParticipantState.reconnecting: 'reconnecting',
  ParticipantState.left: 'left',
  ParticipantState.disconnected: 'disconnected',
};
