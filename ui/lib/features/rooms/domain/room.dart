import 'package:freezed_annotation/freezed_annotation.dart';

part 'room.freezed.dart';
part 'room.g.dart';

/// Mute duration options for chat rooms
enum MuteDuration {
  /// Mute for 8 hours
  eightHours,

  /// Mute for 1 week
  oneWeek,

  /// Mute forever (until manually unmuted)
  forever,
}

/// Extension methods for MuteDuration
extension MuteDurationExtension on MuteDuration {
  /// Get the duration in milliseconds from now
  /// Returns 0 for forever (special case)
  int get durationMs {
    switch (this) {
      case MuteDuration.eightHours:
        return 8 * 60 * 60 * 1000; // 8 hours in ms
      case MuteDuration.oneWeek:
        return 7 * 24 * 60 * 60 * 1000; // 7 days in ms
      case MuteDuration.forever:
        return 0; // 0 = muted forever
    }
  }

  /// Get the timestamp until which the room should be muted
  /// Returns 0 for forever (special case)
  int getMutedUntilTimestamp() {
    if (this == MuteDuration.forever) {
      return 0;
    }
    return DateTime.now().millisecondsSinceEpoch + durationMs;
  }

  /// Get human-readable label for the duration
  String get label {
    switch (this) {
      case MuteDuration.eightHours:
        return '8 hours';
      case MuteDuration.oneWeek:
        return '1 week';
      case MuteDuration.forever:
        return 'Forever';
    }
  }
}

/// Chat room domain model
///
/// Represents a chat room which can be either a direct message (1:1)
/// or a group conversation. Rooms track their last message for
/// ordering and display purposes.
///
/// Example:
/// ```dart
/// final room = Room(
///   id: 'room-123',
///   name: 'Team Chat',
///   type: 'group',
///   unreadCount: 5,
/// );
/// ```
/// Default member limit for groups
const int defaultMemberLimit = 256;

@freezed
abstract class Room with _$Room {
  const factory Room({
    required String id,
    required String name,
    required String type, // 'direct' or 'group'
    String? lastEventId,
    @Default(0) int lastEventIndex,
    @Default(0) int unreadCount,
    Map<String, dynamic>? metadata,

    /// Disappearing messages timeout in seconds (null = disabled)
    /// Supported values: null (off), 86400 (24h), 604800 (7d), 7776000 (90d)
    int? disappearingTimeout,

    /// Mute notifications until this timestamp (milliseconds since epoch)
    /// - null = not muted
    /// - 0 = muted forever
    /// - timestamp = muted until that time
    int? mutedUntil,

    /// Maximum number of members allowed (null = default 256)
    int? memberLimit,

    /// Whether member limit is enforced
    @Default(true) bool memberLimitEnabled,
  }) = _Room;
  const Room._();

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);

  /// Check if the room is currently muted
  ///
  /// Returns true if:
  /// - mutedUntil is 0 (muted forever)
  /// - mutedUntil is a future timestamp
  bool get isMuted {
    if (mutedUntil == null) return false;
    if (mutedUntil == 0) return true; // Muted forever
    return mutedUntil! > DateTime.now().millisecondsSinceEpoch;
  }

  /// Get the remaining mute time as a human-readable string
  /// Returns null if not muted
  String? get muteTimeRemaining {
    if (!isMuted) return null;
    if (mutedUntil == 0) return 'Forever';

    final remaining = mutedUntil! - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) return null;

    final duration = Duration(milliseconds: remaining);
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  /// Get the effective member limit (uses default if not set)
  int get effectiveMemberLimit => memberLimit ?? defaultMemberLimit;

  /// Check if this is a group room
  bool get isGroup => type == 'group';

  /// Check if this is a direct message room
  bool get isDirect => type == 'direct';

  /// Check if the room can accept more members
  bool canAddMembers(int currentMemberCount) {
    if (!memberLimitEnabled) return true;
    return currentMemberCount < effectiveMemberLimit;
  }

  /// Get remaining member slots
  int getRemainingSlots(int currentMemberCount) {
    if (!memberLimitEnabled) return defaultMemberLimit;
    final limit = effectiveMemberLimit;
    return (limit - currentMemberCount).clamp(0, limit);
  }
}
