import 'package:flutter/material.dart';

/// WhatsApp-style date header pill centered between messages.
class DateHeader extends StatelessWidget {
  const DateHeader({required this.timestamp, super.key});
  final int timestamp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;

    if (messageDate == today) {
      dateText = 'Today';
    } else {
      final yesterday = today.subtract(const Duration(days: 1));
      if (messageDate == yesterday) {
        dateText = 'Yesterday';
      } else {
        final difference = today.difference(messageDate);
        if (difference.inDays < 7) {
          const days = [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ];
          dateText = days[date.weekday - 1];
        } else {
          dateText = '${date.day}/${date.month}/${date.year}';
        }
      }
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1F2C34).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          dateText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
          ),
        ),
      ),
    );
  }
}
