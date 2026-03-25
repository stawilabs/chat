import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../features/messages/domain/room_event.dart';
import '../../features/messages/ui/read_receipt_indicator.dart';

/// Inline timestamp + "edited" label + read receipt indicator.
///
/// Positioned at the bottom-right of a message bubble (WhatsApp style).
class MessageTimestampRow extends StatelessWidget {
  const MessageTimestampRow({
    required this.message,
    required this.isMe,
    required this.isGroupChat,
    super.key,
  });

  final RoomEvent message;
  final bool isMe;
  final bool isGroupChat;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppTheme.getTimestampColor(isMe, isDark);
    final timestamp = _formatTimestamp(message.createdAt);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.isEdited) ...[
          Text(
            'edited',
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
        ],
        Text(timestamp, style: TextStyle(fontSize: 11, color: color)),
        if (isMe) ...[
          const SizedBox(width: 3),
          ReadReceiptIndicator(
            event: message,
            isGroupChat: isGroupChat,
            sentColor: color,
            readColor: AppTheme.readReceiptBlue,
          ),
        ],
      ],
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
