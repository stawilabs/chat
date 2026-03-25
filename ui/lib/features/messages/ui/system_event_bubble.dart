import 'package:flutter/material.dart';

import '../domain/room_event.dart';

/// System event bubble for displaying room changes and system messages
///
/// Renders events like:
/// - Member added/removed
/// - Room created/updated
/// - Role changes
/// - Security events (encryption enabled, etc.)
class SystemEventBubble extends StatelessWidget {
  const SystemEventBubble({required this.event, super.key});
  final RoomEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Parse the event content
    final content = event.content;
    final action = content['action'] as String? ?? '';
    final body =
        content['body'] as String? ??
        content['text'] as String? ??
        _getDefaultText(action);

    // Get icon and color based on action
    final (icon, color) = _getIconAndColor(action);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? color.withValues(alpha: 0.9) : color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _getIconAndColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATED':
        return (Icons.celebration, Colors.green.shade600);
      case 'UPDATED':
        return (Icons.edit, Colors.blue.shade600);
      case 'DELETED':
        return (Icons.delete, Colors.red.shade600);
      case 'MEMBER_ADDED':
        return (Icons.person_add, Colors.green.shade600);
      case 'MEMBER_REMOVED':
        return (Icons.person_remove, Colors.orange.shade600);
      case 'ROLE_CHANGED':
        return (Icons.admin_panel_settings, Colors.purple.shade600);
      case 'ENCRYPTION_ENABLED':
        return (Icons.lock, Colors.green.shade600);
      case 'ENCRYPTION_DISABLED':
        return (Icons.lock_open, Colors.orange.shade600);
      default:
        return (Icons.info_outline, Colors.grey.shade600);
    }
  }

  String _getDefaultText(String action) {
    switch (action.toUpperCase()) {
      case 'CREATED':
        return 'Group created';
      case 'UPDATED':
        return 'Group updated';
      case 'DELETED':
        return 'Group deleted';
      case 'MEMBER_ADDED':
        return 'Member added to group';
      case 'MEMBER_REMOVED':
        return 'Member removed from group';
      case 'ROLE_CHANGED':
        return 'Member role changed';
      case 'ENCRYPTION_ENABLED':
        return 'Encryption enabled';
      case 'ENCRYPTION_DISABLED':
        return 'Encryption disabled';
      default:
        return 'System event';
    }
  }
}

/// Vote confirmation bubble for displaying vote events
///
/// Shows when a user casts a vote on a motion
class VoteBubble extends StatelessWidget {
  const VoteBubble({required this.event, required this.isMe, super.key});
  final RoomEvent event;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final content = event.content;
    final option = content['option'] as String? ?? 'Unknown';

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.purple.shade900.withValues(alpha: 0.3)
              : Colors.purple.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_vote, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isMe ? 'You voted: $option' : 'Voted: $option',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
