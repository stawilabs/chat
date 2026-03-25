import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/timestamp_formatter.dart';

/// Displays a timestamp as a relative time string (e.g., "14:30", "Yesterday").
///
/// Optionally highlights in green when there are unread messages.
class RelativeTimestamp extends StatelessWidget {
  const RelativeTimestamp({
    required this.timestamp,
    super.key,
    this.hasUnread = false,
  });

  /// Timestamp in milliseconds since epoch.
  final int timestamp;

  /// When true, displays the timestamp in green to indicate unread messages.
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      TimestampFormatter.formatRelative(timestamp),
      style: AppTheme.metadataText.copyWith(
        color: hasUnread
            ? AppTheme.brightGreen
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
