import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// "Forwarded" italic label with arrow icon (WhatsApp style).
class MessageForwardedLabel extends StatelessWidget {
  const MessageForwardedLabel({required this.isMe, super.key});

  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppTheme.getTimestampColor(isMe, isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shortcut, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            'Forwarded',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
