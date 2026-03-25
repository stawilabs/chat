import 'package:flutter/material.dart';

/// User presence status indicating their current availability
enum UserStatus {
  /// User is offline or status unknown
  offline(0, 'Offline', Colors.grey),

  /// User is online and available
  online(1, 'Online', Colors.green),

  /// User is away from their device
  away(2, 'Away', Colors.orange),

  /// User is busy and may not respond quickly
  busy(3, 'Busy', Colors.red),

  /// User does not want to be disturbed
  doNotDisturb(4, 'Do Not Disturb', Colors.red);

  const UserStatus(this.value, this.label, this.color);

  /// Integer value stored in database
  final int value;

  /// Human-readable label
  final String label;

  /// Color to display for this status
  final Color color;

  /// Get UserStatus from database integer value
  static UserStatus fromValue(int value) {
    return UserStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => UserStatus.offline,
    );
  }

  /// Get the icon for this status
  IconData get icon {
    switch (this) {
      case UserStatus.offline:
        return Icons.circle_outlined;
      case UserStatus.online:
        return Icons.circle;
      case UserStatus.away:
        return Icons.access_time;
      case UserStatus.busy:
        return Icons.remove_circle;
      case UserStatus.doNotDisturb:
        return Icons.do_not_disturb_on;
    }
  }

  /// Whether the user is considered "active" (online or away)
  bool get isActive => this == UserStatus.online || this == UserStatus.away;

  /// Whether the user can receive notifications in this status
  bool get canReceiveNotifications => this != UserStatus.doNotDisturb;
}

/// Extension for working with user profile status
extension UserStatusProfile on UserStatus {
  /// Get a short description for this status
  String get shortDescription {
    switch (this) {
      case UserStatus.offline:
        return 'Not visible to others';
      case UserStatus.online:
        return 'Available to chat';
      case UserStatus.away:
        return 'May be slow to respond';
      case UserStatus.busy:
        return 'Limited availability';
      case UserStatus.doNotDisturb:
        return 'Notifications muted';
    }
  }
}
