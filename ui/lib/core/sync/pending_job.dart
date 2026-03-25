import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_job.freezed.dart';
part 'pending_job.g.dart';

enum JobType {
  sendMessage,
  sendMediaMessage,
  editMessage,
  deleteMessage,
  forwardMessage,
  uploadFile,
  createRoom,
  updateRoom,
  updateRoomAvatar,
  updateRoomPermissions,
  deleteRoom,
  addRoomMembers,
  removeRoomMembers,
  changeMemberRole,
  leaveRoom,
  vote,
  syncContacts,
  custom, // For custom jobs like reports
  createInviteLink,
  revokeInviteLink,
  useInviteLink,
  approveJoinRequest,
  rejectJoinRequest,
}

@freezed
abstract class PendingJob with _$PendingJob {
  const factory PendingJob({
    required int id,
    required JobType type,
    required Map<String, dynamic> payload,
    required int createdAt,
    @Default(0) int retryCount,
    @Default('pending') String status,
    int? nextRetryAt, // Earliest time this job can be retried
  }) = _PendingJob;

  factory PendingJob.fromJson(Map<String, dynamic> json) =>
      _$PendingJobFromJson(json);
}
