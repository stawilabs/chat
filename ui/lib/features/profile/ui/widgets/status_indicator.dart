import 'package:flutter/material.dart';

import '../../domain/user_status.dart';

/// A small circular indicator showing user status
///
/// Can be used as an overlay on avatars or standalone to indicate
/// a user's current availability status (online, away, busy, etc.)
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({
    required this.status,
    super.key,
    this.size = 12,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 2,
  });

  /// The user's current status
  final UserStatus status;

  /// Size of the indicator (diameter)
  final double size;

  /// Whether to show a border around the indicator
  final bool showBorder;

  /// Color of the border (defaults to surface color)
  final Color? borderColor;

  /// Width of the border
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor =
        borderColor ?? Theme.of(context).colorScheme.surface;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: status.color,
        border: showBorder
            ? Border.all(color: effectiveBorderColor, width: borderWidth)
            : null,
      ),
    );
  }
}

/// An avatar with a status indicator overlay
///
/// Displays a user avatar with a small status indicator in the bottom-right
/// corner showing their current availability.
class AvatarWithStatus extends StatelessWidget {
  const AvatarWithStatus({
    required this.status,
    super.key,
    this.avatarUrl,
    this.displayName,
    this.radius = 24,
    this.statusIndicatorSize,
    this.backgroundColor,
  });

  /// The user's current status
  final UserStatus status;

  /// URL of the user's avatar image
  final String? avatarUrl;

  /// User's display name (for fallback initials)
  final String? displayName;

  /// Radius of the avatar
  final double radius;

  /// Size of the status indicator (defaults to radius / 3)
  final double? statusIndicatorSize;

  /// Background color when no avatar is available
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final indicatorSize = statusIndicatorSize ?? (radius / 2);
    final theme = Theme.of(context);

    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor:
              backgroundColor ?? theme.colorScheme.primaryContainer,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null
              ? Text(
                  _getInitials(),
                  style: TextStyle(
                    fontSize: radius * 0.7,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                )
              : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: StatusIndicator(
            status: status,
            size: indicatorSize,
            borderColor: theme.colorScheme.surface,
          ),
        ),
      ],
    );
  }

  String _getInitials() {
    if (displayName == null || displayName!.isEmpty) return '?';
    final parts = displayName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName![0].toUpperCase();
  }
}

/// A row displaying user status with icon and text
///
/// Shows the status icon, label, and optional custom status message
class StatusDisplay extends StatelessWidget {
  const StatusDisplay({
    required this.status,
    super.key,
    this.statusMessage,
    this.showIcon = true,
    this.showLabel = true,
    this.style,
  });

  /// The user's current status
  final UserStatus status;

  /// Optional custom status message
  final String? statusMessage;

  /// Whether to show the status icon
  final bool showIcon;

  /// Whether to show the status label
  final bool showLabel;

  /// Text style override
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = style ?? theme.textTheme.bodySmall;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 4),
        ],
        if (showLabel)
          Text(
            statusMessage?.isNotEmpty ?? false ? statusMessage! : status.label,
            style: textStyle?.copyWith(color: status.color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

/// A compact badge showing status (for use in lists)
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, super.key});

  final UserStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: status.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
