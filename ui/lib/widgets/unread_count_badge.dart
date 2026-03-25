import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A badge displaying unread message count.
///
/// Shows the count in a colored circle/pill. Caps display at "99+".
/// Supports both circular and rounded rectangle shapes.
class UnreadCountBadge extends StatelessWidget {
  const UnreadCountBadge({
    required this.count,
    super.key,
    this.shape = UnreadBadgeShape.circle,
  });

  /// The unread count to display.
  final int count;

  /// Visual shape of the badge.
  final UnreadBadgeShape shape;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final text = count > 99 ? '99+' : count.toString();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.elementGap,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: shape == UnreadBadgeShape.circle
            ? AppTheme.brightGreen
            : AppTheme.primaryGreen,
        shape: shape == UnreadBadgeShape.circle
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius: shape == UnreadBadgeShape.rounded
            ? BorderRadius.circular(12)
            : null,
      ),
      constraints: BoxConstraints(
        minWidth: shape == UnreadBadgeShape.circle ? 24 : 24,
        minHeight: shape == UnreadBadgeShape.circle ? 24 : 24,
      ),
      child: Text(
        text,
        style: AppTheme.metadataText.copyWith(
          fontSize: shape == UnreadBadgeShape.circle ? 10 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Shape variants for the unread count badge.
enum UnreadBadgeShape {
  /// Small circular badge (used in mobile chat list).
  circle,

  /// Rounded rectangle badge (used in tablet/desktop room list).
  rounded,
}
