import '../../core/logging/app_logger.dart';
import '../messages/domain/room_event.dart';

/// Maximum length for notification text preview
const int maxNotificationTextLength = 100;

/// Formatted notification content for display
class NotificationContent {
  const NotificationContent({
    required this.title,
    required this.body,
    this.imageUrl,
    this.isGroupMessage = false,
  });

  /// The notification title (sender name or group name)
  final String title;

  /// The notification body (message preview)
  final String body;

  /// Optional image URL for media messages
  final String? imageUrl;

  /// Whether this is a group message
  final bool isGroupMessage;

  @override
  String toString() =>
      'NotificationContent(title: $title, body: $body, imageUrl: $imageUrl, '
      'isGroupMessage: $isGroupMessage)';
}

/// Service for formatting notification content based on message type
///
/// Handles different message types:
/// - Text: Shows truncated preview
/// - Image: Shows "Photo" with optional thumbnail
/// - Video: Shows "Video"
/// - Audio/Voice: Shows duration if available
/// - File: Shows filename
/// - Reaction: Shows emoji
/// - Motion: Shows motion title
/// - Transaction: Shows transaction description
class NotificationContentFormatter {
  /// Format a room event into notification content
  ///
  /// [event] - The room event to format
  /// [senderName] - The display name of the sender
  /// [roomName] - The name of the room (for group messages)
  /// [hideContent] - Whether to hide the actual content (privacy mode)
  NotificationContent format({
    required RoomEvent event,
    required String senderName,
    String? roomName,
    bool hideContent = false,
  }) {
    final isGroupMessage = roomName != null && roomName.isNotEmpty;

    // Build title: "Sender" for DM, "Sender @ Group" for group messages
    final title = isGroupMessage ? '$senderName @ $roomName' : senderName;

    // If privacy mode is enabled, show generic message
    if (hideContent) {
      return NotificationContent(
        title: title,
        body: _getPrivateBody(event.type),
        isGroupMessage: isGroupMessage,
      );
    }

    // Format body based on message type
    final (body, imageUrl) = _formatContent(event);

    return NotificationContent(
      title: title,
      body: body,
      imageUrl: imageUrl,
      isGroupMessage: isGroupMessage,
    );
  }

  /// Get a privacy-preserving body text based on message type
  String _getPrivateBody(RoomEventType type) {
    switch (type) {
      case RoomEventType.text:
        return 'New message';
      case RoomEventType.image:
        return 'New photo';
      case RoomEventType.video:
        return 'New video';
      case RoomEventType.audio:
        return 'New voice message';
      case RoomEventType.file:
        return 'New file';
      case RoomEventType.reaction:
        return 'New reaction';
      case RoomEventType.motion:
        return 'New motion';
      case RoomEventType.vote:
        return 'New vote';
      case RoomEventType.transaction:
        return 'New transaction';
      case RoomEventType.callOffer:
      case RoomEventType.callAnswer:
      case RoomEventType.callIce:
      case RoomEventType.callEnd:
        return 'Call activity';
      case RoomEventType.groupCallStart:
      case RoomEventType.groupCallJoin:
      case RoomEventType.groupCallLeave:
      case RoomEventType.groupCallEnd:
      case RoomEventType.groupCallOffer:
      case RoomEventType.groupCallAnswer:
      case RoomEventType.groupCallIce:
      case RoomEventType.groupCallMuteUpdate:
        return 'Group call activity';
      case RoomEventType.groupConfig:
        return 'Finance settings updated';
      case RoomEventType.roomKey:
        return 'Security update';
      case RoomEventType.roomChange:
        return 'Group update';
    }
  }

  /// Format the content and extract image URL if applicable
  (String body, String? imageUrl) _formatContent(RoomEvent event) {
    try {
      switch (event.type) {
        case RoomEventType.text:
          return (_formatTextMessage(event.content), null);

        case RoomEventType.image:
          return (
            _formatImageMessage(event.content),
            _extractImageUrl(event.content),
          );

        case RoomEventType.video:
          return (
            _formatVideoMessage(event.content),
            _extractThumbnailUrl(event.content),
          );

        case RoomEventType.audio:
          return (_formatAudioMessage(event.content), null);

        case RoomEventType.file:
          return (_formatFileMessage(event.content), null);

        case RoomEventType.reaction:
          return (_formatReactionMessage(event.content), null);

        case RoomEventType.motion:
          return (_formatMotionMessage(event.content), null);

        case RoomEventType.vote:
          return (_formatVoteMessage(event.content), null);

        case RoomEventType.transaction:
          return (_formatTransactionMessage(event.content), null);

        case RoomEventType.callOffer:
          return ('Incoming call', null);

        case RoomEventType.callAnswer:
          return ('Call answered', null);

        case RoomEventType.callEnd:
          return ('Call ended', null);

        case RoomEventType.callIce:
        case RoomEventType.roomKey:
        case RoomEventType.groupCallOffer:
        case RoomEventType.groupCallAnswer:
        case RoomEventType.groupCallIce:
        case RoomEventType.groupCallMuteUpdate:
          // These are internal events, shouldn't normally be shown
          return ('', null);

        case RoomEventType.groupCallStart:
          return ('Group call started', null);

        case RoomEventType.groupCallJoin:
          return ('Someone joined the call', null);

        case RoomEventType.groupCallLeave:
          return ('Someone left the call', null);

        case RoomEventType.groupCallEnd:
          return ('Group call ended', null);

        case RoomEventType.groupConfig:
          return ('Finance settings updated', null);

        case RoomEventType.roomChange:
          final body =
              event.content['body'] as String? ??
              event.content['text'] as String? ??
              'Group updated';
          return (body, null);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error formatting notification content',
        error: e,
        stackTrace: stackTrace,
        data: {'eventType': event.type.name, 'eventId': event.id},
      );
      return ('New message', null);
    }
  }

  /// Format text message with truncation
  String _formatTextMessage(Map<String, dynamic> content) {
    final text = content['text'] as String? ?? '';
    return _truncate(text, maxNotificationTextLength);
  }

  /// Format image message
  String _formatImageMessage(Map<String, dynamic> content) {
    final caption = content['caption'] as String?;
    if (caption != null && caption.isNotEmpty) {
      return 'Photo: ${_truncate(caption, maxNotificationTextLength - 7)}';
    }
    return 'Photo';
  }

  /// Format video message
  String _formatVideoMessage(Map<String, dynamic> content) {
    final caption = content['caption'] as String?;
    if (caption != null && caption.isNotEmpty) {
      return 'Video: ${_truncate(caption, maxNotificationTextLength - 7)}';
    }
    return 'Video';
  }

  /// Format audio/voice message with duration
  String _formatAudioMessage(Map<String, dynamic> content) {
    final durationMs = content['duration'] as int?;
    if (durationMs != null && durationMs > 0) {
      final duration = _formatDuration(durationMs);
      return 'Voice message ($duration)';
    }
    return 'Voice message';
  }

  /// Format file message with filename
  String _formatFileMessage(Map<String, dynamic> content) {
    final filename =
        content['filename'] as String? ?? content['name'] as String?;
    if (filename != null && filename.isNotEmpty) {
      return 'File: ${_truncate(filename, maxNotificationTextLength - 6)}';
    }
    return 'File';
  }

  /// Format reaction message
  String _formatReactionMessage(Map<String, dynamic> content) {
    final emoji = content['emoji'] as String? ?? content['reaction'] as String?;
    if (emoji != null && emoji.isNotEmpty) {
      return 'Reacted with $emoji';
    }
    return 'Reacted to a message';
  }

  /// Format motion message
  String _formatMotionMessage(Map<String, dynamic> content) {
    final title = content['title'] as String? ?? content['subject'] as String?;
    if (title != null && title.isNotEmpty) {
      return 'Motion: ${_truncate(title, maxNotificationTextLength - 8)}';
    }
    return 'New motion proposed';
  }

  /// Format vote message
  String _formatVoteMessage(Map<String, dynamic> content) {
    final vote = content['vote'] as String? ?? content['choice'] as String?;
    if (vote != null && vote.isNotEmpty) {
      return 'Voted: $vote';
    }
    return 'Cast a vote';
  }

  /// Format transaction message
  String _formatTransactionMessage(Map<String, dynamic> content) {
    final amount = content['amount'];
    final currency = content['currency'] as String? ?? '';
    final description = content['description'] as String?;

    if (amount != null) {
      final amountStr = '$currency $amount'.trim();
      if (description != null && description.isNotEmpty) {
        return 'Transaction: $amountStr - ${_truncate(description, 50)}';
      }
      return 'Transaction: $amountStr';
    }

    if (description != null && description.isNotEmpty) {
      return 'Transaction: ${_truncate(description, maxNotificationTextLength - 13)}';
    }

    return 'New transaction';
  }

  /// Extract image URL for thumbnail display
  String? _extractImageUrl(Map<String, dynamic> content) {
    return content['url'] as String? ??
        content['thumbnailUrl'] as String? ??
        content['thumbnail'] as String?;
  }

  /// Extract thumbnail URL for video
  String? _extractThumbnailUrl(Map<String, dynamic> content) {
    return content['thumbnailUrl'] as String? ??
        content['thumbnail'] as String? ??
        content['posterUrl'] as String?;
  }

  /// Format duration from milliseconds to human-readable string
  String _formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).round();
    if (seconds < 60) {
      return '${seconds}s';
    }
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) {
      return '${minutes}m';
    }
    return '${minutes}m ${remainingSeconds}s';
  }

  /// Truncate text to maximum length with ellipsis
  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength - 3)}...';
  }
}
