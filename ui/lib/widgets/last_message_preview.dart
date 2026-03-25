import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Preview of the last message in a room list item.
///
/// For group chats, shows "SenderName: message" with the sender name
/// in a slightly bolder weight. For direct chats, shows just the message text.
class LastMessagePreview extends StatelessWidget {
  const LastMessagePreview({
    required this.messageText,
    super.key,
    this.senderName,
    this.isGroup = false,
    this.hasUnread = false,
    this.maxLines = 1,
  });

  /// The message text to display.
  final String messageText;

  /// Sender name shown as prefix in group chats.
  final String? senderName;

  /// Whether this is a group chat (controls sender name prefix).
  final bool isGroup;

  /// Whether the room has unread messages (applies bolder font).
  final bool hasUnread;

  /// Maximum lines for the message text.
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleColor = theme.colorScheme.onSurfaceVariant;

    if (isGroup && senderName != null && senderName!.isNotEmpty) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$senderName: ',
              style: AppTheme.bodyText.copyWith(
                fontSize: 14,
                color: subtitleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: messageText,
              style: AppTheme.bodyText.copyWith(
                fontSize: 14,
                color: subtitleColor,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      messageText,
      style: AppTheme.bodyText.copyWith(
        fontSize: 14,
        color: subtitleColor,
        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
