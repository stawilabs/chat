// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_link.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InviteLink _$InviteLinkFromJson(Map<String, dynamic> json) => _InviteLink(
  id: json['id'] as String,
  roomId: json['roomId'] as String,
  code: json['code'] as String,
  createdBy: json['createdBy'] as String,
  createdAt: (json['createdAt'] as num).toInt(),
  expiresAt: (json['expiresAt'] as num?)?.toInt(),
  maxUses: (json['maxUses'] as num?)?.toInt(),
  useCount: (json['useCount'] as num?)?.toInt() ?? 0,
  revoked: json['revoked'] as bool? ?? false,
  requiresApproval: json['requiresApproval'] as bool? ?? false,
  name: json['name'] as String?,
);

Map<String, dynamic> _$InviteLinkToJson(_InviteLink instance) =>
    <String, dynamic>{
      'id': instance.id,
      'roomId': instance.roomId,
      'code': instance.code,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt,
      'expiresAt': instance.expiresAt,
      'maxUses': instance.maxUses,
      'useCount': instance.useCount,
      'revoked': instance.revoked,
      'requiresApproval': instance.requiresApproval,
      'name': instance.name,
    };

_InviteLinkJoin _$InviteLinkJoinFromJson(Map<String, dynamic> json) =>
    _InviteLinkJoin(
      id: (json['id'] as num).toInt(),
      inviteLinkId: json['inviteLinkId'] as String,
      profileId: json['profileId'] as String,
      joinedAt: (json['joinedAt'] as num).toInt(),
      status: json['status'] as String? ?? 'approved',
    );

Map<String, dynamic> _$InviteLinkJoinToJson(_InviteLinkJoin instance) =>
    <String, dynamic>{
      'id': instance.id,
      'inviteLinkId': instance.inviteLinkId,
      'profileId': instance.profileId,
      'joinedAt': instance.joinedAt,
      'status': instance.status,
    };
