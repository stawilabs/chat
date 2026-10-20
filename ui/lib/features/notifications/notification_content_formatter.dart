import '../../core/logging/app_logger.dart';
import '../messages/domain/room_event.dart';
import '../stawi/domain/stawi_payloads.dart';

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

/// A finance card notification's title, by the card's kind: what happened.
String financeCardNotificationTitle(String kind) => switch (kind) {
  'LOAN_OFFERED' => 'Loan offer',
  'LOAN_REQUESTED' => 'Loan request',
  'LOAN_PAID_OUT' => 'Loan paid out',
  'LOAN_PAYMENT' => 'Payment received',
  'LOAN_LATE' => 'Instalment late',
  'LOAN_DEFAULTED' => 'Loan in default',
  'LOAN_RECOVERED' => 'Recovered',
  'LOAN_REPAID' => 'Loan repaid',
  'LOAN_CLOSED' || 'LOAN_CLOSED_UNACCEPTED' => 'Loan closed',
  'CONTRIBUTION_FAILED' => 'Contribution missed',
  'CONTRIBUTION' => 'Contribution received',
  'DUES_DUE' => 'Dues due',
  'WITHDRAWAL' => 'Withdrawal',
  'SHARE_OUT_COLLECTED' => 'Share-out collected',
  'MONEY_RECEIVED' => 'Money received',
  'DEPOSIT' => 'Money saved',
  'ROOM_SETUP' => 'Lending setup',
  _ => 'Stawi update',
};

/// Service for formatting notification content based on message type
///
/// Handles different message types:
/// - Text: Shows truncated preview
/// - Image: Shows "Photo" with optional thumbnail
/// - Video: Shows "Video"
/// - Audio/Voice: Shows duration if available
/// - File: Shows filename
/// - Reaction: Shows emoji
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

    // A finance card is titled by what happened (and, in a group, where);
    // its body is the card's own title.
    if (event.type == RoomEventType.financeCard) {
      final card = FinanceCardView.fromContent(event.content);
      final what = financeCardNotificationTitle(card.kind);
      return NotificationContent(
        title: isGroupMessage ? '$what @ $roomName' : what,
        body: _truncate(card.title, maxNotificationTextLength),
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
      case RoomEventType.unknown:
        return 'New update';
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
      case RoomEventType.vote:
        return 'New vote';
      case RoomEventType.formRequest:
        return 'New form';
      case RoomEventType.formSubmissionResult:
        return 'Form submitted';
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
      case RoomEventType.groupCallStageUpdate:
        return 'Group call activity';
      case RoomEventType.motion:
      case RoomEventType.transaction:
      case RoomEventType.groupConfig:
        return 'Message no longer supported';
      case RoomEventType.roomKey:
        return 'Security update';
      case RoomEventType.roomChange:
        return 'Group update';
      case RoomEventType.stawiRoomConversion:
      case RoomEventType.stawiGenesisSignature:
      case RoomEventType.stawiSignedCall:
      case RoomEventType.stawiCallOutcome:
      case RoomEventType.financeCard:
      case RoomEventType.stawiAgentInvitation:
      case RoomEventType.stawiAgentAcceptance:
        return 'Stawi update';
    }
  }

  /// Format the content and extract image URL if applicable
  (String body, String? imageUrl) _formatContent(RoomEvent event) {
    try {
      switch (event.type) {
        case RoomEventType.text:
          return (_formatTextMessage(event.content), null);

        case RoomEventType.unknown:
          return ('New update', null);

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

        case RoomEventType.vote:
          return (_formatVoteMessage(event.content), null);

        case RoomEventType.formRequest:
          final schema = event.content['schema'] as Map?;
          return (
            event.content['title'] as String? ??
                schema?['title'] as String? ??
                'New form',
            null,
          );

        case RoomEventType.formSubmissionResult:
          return ('Form submitted', null);

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
        case RoomEventType.groupCallStageUpdate:
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

        case RoomEventType.motion:
        case RoomEventType.transaction:
        case RoomEventType.groupConfig:
          return ('Message no longer supported', null);

        case RoomEventType.roomChange:
          final body =
              event.content['body'] as String? ??
              event.content['text'] as String? ??
              'Group updated';
          return (body, null);

        case RoomEventType.stawiRoomConversion:
          return ('Proposed turning this room into a Stawi room', null);

        case RoomEventType.stawiGenesisSignature:
          return ('Signed the Stawi room genesis', null);

        case RoomEventType.stawiSignedCall:
          final call = StawiSignedCallView.fromContent(event.content);
          return (call.summary.isNotEmpty ? call.summary : call.kind, null);

        case RoomEventType.stawiCallOutcome:
          return (
            describeOutcome(StawiOutcomeView.fromContent(event.content)),
            null,
          );

        case RoomEventType.financeCard:
          return (FinanceCardView.fromContent(event.content).title, null);

        case RoomEventType.stawiAgentInvitation:
          return ("Invited you to be a Stawi room's agent", null);

        case RoomEventType.stawiAgentAcceptance:
          return ("Accepted being a Stawi room's agent", null);
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

  /// Format vote message
  String _formatVoteMessage(Map<String, dynamic> content) {
    final vote = content['vote'] as String? ?? content['choice'] as String?;
    if (vote != null && vote.isNotEmpty) {
      return 'Voted: $vote';
    }
    return 'Cast a vote';
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
