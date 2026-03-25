// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PendingJob _$PendingJobFromJson(Map<String, dynamic> json) => _PendingJob(
  id: (json['id'] as num).toInt(),
  type: $enumDecode(_$JobTypeEnumMap, json['type']),
  payload: json['payload'] as Map<String, dynamic>,
  createdAt: (json['createdAt'] as num).toInt(),
  retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
  status: json['status'] as String? ?? 'pending',
  nextRetryAt: (json['nextRetryAt'] as num?)?.toInt(),
);

Map<String, dynamic> _$PendingJobToJson(_PendingJob instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$JobTypeEnumMap[instance.type]!,
      'payload': instance.payload,
      'createdAt': instance.createdAt,
      'retryCount': instance.retryCount,
      'status': instance.status,
      'nextRetryAt': instance.nextRetryAt,
    };

const _$JobTypeEnumMap = {
  JobType.sendMessage: 'sendMessage',
  JobType.sendMediaMessage: 'sendMediaMessage',
  JobType.editMessage: 'editMessage',
  JobType.deleteMessage: 'deleteMessage',
  JobType.forwardMessage: 'forwardMessage',
  JobType.uploadFile: 'uploadFile',
  JobType.createRoom: 'createRoom',
  JobType.updateRoom: 'updateRoom',
  JobType.updateRoomAvatar: 'updateRoomAvatar',
  JobType.updateRoomPermissions: 'updateRoomPermissions',
  JobType.deleteRoom: 'deleteRoom',
  JobType.addRoomMembers: 'addRoomMembers',
  JobType.removeRoomMembers: 'removeRoomMembers',
  JobType.changeMemberRole: 'changeMemberRole',
  JobType.leaveRoom: 'leaveRoom',
  JobType.vote: 'vote',
  JobType.syncContacts: 'syncContacts',
  JobType.custom: 'custom',
  JobType.createInviteLink: 'createInviteLink',
  JobType.revokeInviteLink: 'revokeInviteLink',
  JobType.useInviteLink: 'useInviteLink',
  JobType.approveJoinRequest: 'approveJoinRequest',
  JobType.rejectJoinRequest: 'rejectJoinRequest',
};
