import 'package:freezed_annotation/freezed_annotation.dart';

import 'group_call_participant.dart';

part 'group_call.freezed.dart';
part 'group_call.g.dart';

/// State of a group call
///
/// Tracks the overall state of the group call from initiation
/// through active conversation to termination.
enum GroupCallState {
  /// Call is being initiated by the host
  initiating,

  /// Call is ringing for invited participants
  ringing,

  /// Call is active with connected participants
  active,

  /// Call has ended
  ended,
}

/// Represents a group video/audio call
///
/// Contains information about the call including the host,
/// participants, and call state.
///
/// Example:
/// ```dart
/// final call = GroupCall(
///   callId: 'call-123',
///   roomId: 'room-456',
///   hostProfileId: 'profile-789',
///   participants: [hostParticipant],
///   startedAt: DateTime.now(),
/// );
/// ```
@freezed
abstract class GroupCall with _$GroupCall {
  const factory GroupCall({
    /// Unique identifier for this call
    required String callId,

    /// Room ID where this call is taking place
    required String roomId,

    /// Profile ID of the user who started the call
    required String hostProfileId,

    /// Timestamp when the call was started
    required DateTime startedAt,

    /// List of participants in the call
    @Default([]) List<GroupCallParticipant> participants,

    /// Current state of the call
    @Default(GroupCallState.initiating) GroupCallState state,

    /// Timestamp when the call ended (null if still active)
    DateTime? endedAt,
  }) = _GroupCall;

  const GroupCall._();

  factory GroupCall.fromJson(Map<String, dynamic> json) =>
      _$GroupCallFromJson(json);

  /// Returns the host participant if present
  GroupCallParticipant? get host =>
      participants.where((p) => p.profileId == hostProfileId).firstOrNull;

  /// Returns true if the call is currently active
  bool get isActive => state == GroupCallState.active;

  /// Returns true if the call has ended
  bool get hasEnded => state == GroupCallState.ended;

  /// Returns the number of connected participants
  int get connectedParticipantCount =>
      participants.where((p) => p.isActive).length;

  /// Returns participants who are actively connected
  List<GroupCallParticipant> get activeParticipants =>
      participants.where((p) => p.isActive).toList();

  /// Returns the duration of the call
  Duration get duration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  /// Returns true if a specific profile is in the call
  bool hasParticipant(String profileId) =>
      participants.any((p) => p.profileId == profileId);

  /// Gets a participant by profile ID
  GroupCallParticipant? getParticipant(String profileId) =>
      participants.where((p) => p.profileId == profileId).firstOrNull;
}
