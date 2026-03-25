import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Displays a "Draft: message" indicator for unsent messages.
///
/// Shows "Draft:" in red followed by the draft text in the subtitle color.
class DraftIndicator extends StatelessWidget {
  const DraftIndicator({required this.draftText, super.key, this.maxLines = 1});

  /// The draft message text.
  final String draftText;

  /// Maximum lines for the draft text.
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          'Draft: ',
          style: AppTheme.bodyText.copyWith(
            fontSize: 14,
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            draftText,
            style: AppTheme.bodyText.copyWith(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
