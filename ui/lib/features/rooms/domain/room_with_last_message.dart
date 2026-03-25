import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_with_last_message.freezed.dart';

@freezed
abstract class RoomWithLastMessage with _$RoomWithLastMessage {
  const factory RoomWithLastMessage({
    required String id,
    required String name,
    required String type,
    required int unreadCount,
    String? lastMessageText,
    int? lastMessageTimestamp,
    String? lastMessageSenderId,
    String? lastMessageSenderName,
    bool? isTyping,

    /// Draft message text if the user has an unsent message
    String? draftText,

    /// Mute notifications until this timestamp (milliseconds since epoch)
    /// - null = not muted
    /// - 0 = muted forever
    /// - timestamp = muted until that time
    int? mutedUntil,
  }) = _RoomWithLastMessage;

  const RoomWithLastMessage._();

  /// Whether this room has a draft message
  bool get hasDraft => draftText != null && draftText!.isNotEmpty;

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
}
