/// Utility for formatting timestamps into human-readable relative strings.
///
/// Used across the app for chat list items, message timestamps, etc.
class TimestampFormatter {
  const TimestampFormatter._();

  /// Format a timestamp (milliseconds since epoch) into a relative string.
  ///
  /// Returns:
  /// - "HH:mm" for today
  /// - "Yesterday" for yesterday
  /// - Day name (e.g., "Mon") for this week
  /// - "d/m" for this year
  /// - "d/m/y" for older dates
  static String formatRelative(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    // Today - show time
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    // Yesterday
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.day == yesterday.day &&
        date.month == yesterday.month &&
        date.year == yesterday.year) {
      return 'Yesterday';
    }

    // This week - show day name
    if (difference.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    }

    // This year - show date without year
    if (date.year == now.year) {
      return '${date.day}/${date.month}';
    }

    // Older - show full date
    return '${date.day}/${date.month}/${date.year}';
  }
}
