import 'package:flutter/material.dart';

/// Type of call (audio or video)
enum CallType {
  audio(0, 'Voice Call', Icons.phone),
  video(1, 'Video Call', Icons.videocam);

  const CallType(this.value, this.label, this.icon);

  final int value;
  final String label;
  final IconData icon;

  static CallType fromValue(int value) {
    return CallType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => CallType.audio,
    );
  }
}

/// Direction of the call (incoming or outgoing)
enum CallDirection {
  outgoing(0, 'Outgoing'),
  incoming(1, 'Incoming');

  const CallDirection(this.value, this.label);

  final int value;
  final String label;

  static CallDirection fromValue(int value) {
    return CallDirection.values.firstWhere(
      (d) => d.value == value,
      orElse: () => CallDirection.outgoing,
    );
  }
}

/// Outcome/status of the call
enum CallStatus {
  missed(0, 'Missed', Colors.red),
  answered(1, 'Answered', Colors.green),
  declined(2, 'Declined', Colors.orange),
  busy(3, 'Busy', Colors.orange),
  failed(4, 'Failed', Colors.red);

  const CallStatus(this.value, this.label, this.color);

  final int value;
  final String label;
  final Color color;

  static CallStatus fromValue(int value) {
    return CallStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => CallStatus.missed,
    );
  }
}

/// Represents a single entry in the call history
class CallHistoryEntry {
  const CallHistoryEntry({
    required this.roomId,
    required this.callerId,
    required this.callType,
    required this.direction,
    required this.status,
    required this.startedAt,
    this.id,
    this.recipientId,
    this.answeredAt,
    this.endedAt,
    this.duration = 0,
    this.isRead = false,
    this.isDeleted = false,
    this.callerName,
    this.callerAvatarUrl,
    this.recipientName,
    this.recipientAvatarUrl,
  });

  /// Database ID (null for new entries)
  final int? id;

  /// Room ID where the call occurred
  final String roomId;

  /// Profile ID of the caller (who initiated the call)
  final String callerId;

  /// Profile ID of the recipient (who received the call)
  final String? recipientId;

  /// Type of call (audio/video)
  final CallType callType;

  /// Direction of the call (incoming/outgoing)
  final CallDirection direction;

  /// Outcome of the call
  final CallStatus status;

  /// When the call was initiated
  final int startedAt;

  /// When the call was answered (null if not answered)
  final int? answeredAt;

  /// When the call ended
  final int? endedAt;

  /// Duration of the call in seconds
  final int duration;

  /// Whether this entry has been read/seen
  final bool isRead;

  /// Whether this entry has been deleted
  final bool isDeleted;

  // Display data (populated when fetched with joins)
  final String? callerName;
  final String? callerAvatarUrl;
  final String? recipientName;
  final String? recipientAvatarUrl;

  /// Whether this was a missed call
  bool get isMissed => status == CallStatus.missed;

  /// Whether this was an incoming call
  bool get isIncoming => direction == CallDirection.incoming;

  /// Whether this was an outgoing call
  bool get isOutgoing => direction == CallDirection.outgoing;

  /// Whether the call was answered
  bool get wasAnswered => status == CallStatus.answered;

  /// Get the formatted duration string (e.g., "2:34")
  String get formattedDuration {
    if (duration == 0) return '';
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get the DateTime when the call started
  DateTime get startedAtDateTime =>
      DateTime.fromMillisecondsSinceEpoch(startedAt);

  /// Get the icon for this call
  IconData get icon {
    if (isIncoming) {
      if (isMissed) {
        return Icons.call_missed;
      }
      return callType == CallType.video ? Icons.videocam : Icons.call_received;
    } else {
      return callType == CallType.video ? Icons.videocam : Icons.call_made;
    }
  }

  /// Get the color for this call entry
  Color get color {
    if (isMissed) return Colors.red;
    if (isIncoming) return Colors.blue;
    return Colors.green;
  }

  /// Get display name for the other party
  String get otherPartyName {
    if (isIncoming) {
      return callerName ?? 'Unknown';
    }
    return recipientName ?? 'Unknown';
  }

  /// Get avatar URL for the other party
  String? get otherPartyAvatarUrl {
    if (isIncoming) {
      return callerAvatarUrl;
    }
    return recipientAvatarUrl;
  }

  /// Get profile ID of the other party
  String get otherPartyId {
    if (isIncoming) {
      return callerId;
    }
    return recipientId ?? callerId;
  }

  /// Create a copy with updated fields
  CallHistoryEntry copyWith({
    int? id,
    String? roomId,
    String? callerId,
    String? recipientId,
    CallType? callType,
    CallDirection? direction,
    CallStatus? status,
    int? startedAt,
    int? answeredAt,
    int? endedAt,
    int? duration,
    bool? isRead,
    bool? isDeleted,
    String? callerName,
    String? callerAvatarUrl,
    String? recipientName,
    String? recipientAvatarUrl,
  }) {
    return CallHistoryEntry(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      callerId: callerId ?? this.callerId,
      recipientId: recipientId ?? this.recipientId,
      callType: callType ?? this.callType,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      answeredAt: answeredAt ?? this.answeredAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      callerName: callerName ?? this.callerName,
      callerAvatarUrl: callerAvatarUrl ?? this.callerAvatarUrl,
      recipientName: recipientName ?? this.recipientName,
      recipientAvatarUrl: recipientAvatarUrl ?? this.recipientAvatarUrl,
    );
  }
}
