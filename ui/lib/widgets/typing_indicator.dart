import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Animated typing indicator shown in chat list items.
///
/// Displays "typing..." or "SenderName is typing..." for group chats
/// in green italic text.
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key, this.senderName, this.isGroup = false});

  /// The name of the person typing. Shown as prefix in group chats.
  final String? senderName;

  /// Whether this is a group chat (controls showing sender name prefix).
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    String typingText;
    if (isGroup && senderName != null && senderName!.isNotEmpty) {
      typingText = '$senderName is typing...';
    } else {
      typingText = 'typing...';
    }

    return Text(
      typingText,
      style: AppTheme.bodyText.copyWith(
        fontSize: 14,
        color: AppTheme.brightGreen,
        fontStyle: FontStyle.italic,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
