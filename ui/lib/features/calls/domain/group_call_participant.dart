import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_call_participant.freezed.dart';
part 'group_call_participant.g.dart';

/// State of a participant in a group call
///
/// Tracks the participant's connection lifecycle from invitation
/// through connection and eventual disconnection.
enum ParticipantState {
  /// Participant has been invited but hasn't joined yet
  invited,

  /// Participant is in the process of joining
  joining,

  /// Participant is fully connected to the call
  connected,

  /// Participant's connection was lost, attempting to reconnect
  reconnecting,

  /// Participant has left the call voluntarily
  left,

  /// Participant was disconnected (connection lost, not reconnecting)
  disconnected,
}

/// Represents a participant in a group video/audio call
///
/// Contains information about the participant's identity, media state,
/// and connection status within the group call.
///
/// Example:
/// ```dart
/// final participant = GroupCallParticipant(
///   profileId: 'profile-123',
///   displayName: 'John Doe',
///   joinedAt: DateTime.now(),
/// );
/// ```
@freezed
abstract class GroupCallParticipant with _$GroupCallParticipant {
  const factory GroupCallParticipant({
    /// Unique profile ID of the participant
    required String profileId,

    /// Display name shown in the call UI
    required String displayName,

    /// Timestamp when the participant joined the call
    required DateTime joinedAt,

    /// URL to the participant's avatar image
    String? avatarUrl,

    /// Whether the participant's microphone is muted
    @Default(false) bool isAudioMuted,

    /// Whether the participant's camera is turned off
    @Default(false) bool isVideoOff,

    /// Whether the participant is currently speaking
    @Default(false) bool isSpeaking,

    /// Whether this participant is the host of the call
    @Default(false) bool isHost,

    /// Current connection state of the participant
    @Default(ParticipantState.joining) ParticipantState state,
  }) = _GroupCallParticipant;

  const GroupCallParticipant._();

  factory GroupCallParticipant.fromJson(Map<String, dynamic> json) =>
      _$GroupCallParticipantFromJson(json);

  /// Returns true if the participant is actively in the call
  bool get isActive =>
      state == ParticipantState.connected ||
      state == ParticipantState.reconnecting;

  /// Returns true if the participant has media (audio or video) enabled
  bool get hasActiveMedia => !isAudioMuted || !isVideoOff;

  /// Duration since the participant joined
  Duration get callDuration => DateTime.now().difference(joinedAt);
}
