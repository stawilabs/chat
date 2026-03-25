import 'package:flutter/material.dart';

import '../../../core/navigation/navigation_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/draft_indicator.dart';
import '../../../widgets/last_message_preview.dart';
import '../../../widgets/relative_timestamp.dart';
import '../../../widgets/room_avatar.dart';
import '../../../widgets/typing_indicator.dart';
import '../../../widgets/unread_count_badge.dart';
import '../domain/room_with_last_message.dart';

/// Room list tile for tablet/desktop layouts.
///
/// Similar to `ChatListItem` but with additional features like
/// draft indicators, muted icon, and room details navigation on avatar tap.
class RoomListTile extends StatelessWidget {
  const RoomListTile({required this.room, required this.onTap, super.key});

  final RoomWithLastMessage room;
  final VoidCallback onTap;

  bool get _isGroup => room.type == 'group';
  bool get _hasUnread => room.unreadCount > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Chat with ${room.name}',
      value: _hasUnread ? '${room.unreadCount} unread messages' : null,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          splashColor: AppTheme.getSubtleColor(context, AppTheme.primaryGreen),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.standardMargin),
            child: Row(
              children: [
                // Avatar — tapping navigates to room details
                RoomAvatar(
                  name: room.name,
                  size: AppTheme.minTouchTarget,
                  onTap: () => context.navigateToRoomDetails(
                    roomId: room.id,
                    roomName: room.name,
                  ),
                ),

                const SizedBox(width: AppTheme.elementGap),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Room name and timestamp
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    room.name,
                                    style: AppTheme.bodyText.copyWith(
                                      fontWeight: _hasUnread
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Muted indicator
                                if (room.isMuted) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.notifications_off,
                                    size: 16,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (room.lastMessageTimestamp != null) ...[
                            const SizedBox(width: AppTheme.elementGap),
                            RelativeTimestamp(
                              timestamp: room.lastMessageTimestamp!,
                              hasUnread: _hasUnread,
                            ),
                          ],
                        ],
                      ),

                      // Typing indicator, draft, or last message
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppTheme.elementGap,
                        ),
                        child: _buildSubtitle(),
                      ),
                    ],
                  ),
                ),

                // Unread count badge
                if (_hasUnread)
                  Padding(
                    padding: const EdgeInsets.only(left: AppTheme.elementGap),
                    child: UnreadCountBadge(
                      count: room.unreadCount,
                      shape: UnreadBadgeShape.rounded,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build the subtitle line: typing > draft > last message.
  Widget _buildSubtitle() {
    if (room.isTyping ?? false) {
      return TypingIndicator(
        senderName: room.lastMessageSenderName,
        isGroup: _isGroup,
      );
    }

    if (room.hasDraft) {
      return DraftIndicator(draftText: room.draftText!);
    }

    if (room.lastMessageText != null) {
      return LastMessagePreview(
        messageText: room.lastMessageText ?? '',
        senderName: room.lastMessageSenderName,
        isGroup: _isGroup,
        hasUnread: _hasUnread,
        maxLines: 2,
      );
    }

    return const SizedBox.shrink();
  }
}
