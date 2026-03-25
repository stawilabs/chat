import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/last_message_preview.dart';
import '../../../widgets/relative_timestamp.dart';
import '../../../widgets/room_avatar.dart';
import '../../../widgets/typing_indicator.dart';
import '../../../widgets/unread_count_badge.dart';
import '../domain/room_with_last_message.dart';

/// Chat list item for mobile layout.
///
/// Displays a room with avatar, name, last message preview, timestamp,
/// and unread badge. Supports multi-select mode with checkboxes.
class ChatListItem extends StatelessWidget {
  const ChatListItem({
    required this.room,
    required this.onTap,
    super.key,
    this.isSelected = false,
    this.isMultiSelectMode = false,
    this.onLongPress,
    this.onSelectionChanged,
  });

  final RoomWithLastMessage room;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onSelectionChanged;

  bool get _isGroup => room.type == 'group';
  bool get _hasUnread => room.unreadCount > 0;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: ValueKey(room.id),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isMultiSelectMode
              ? () => onSelectionChanged?.call(!isSelected)
              : onTap,
          onLongPress: () {
            if (isMultiSelectMode) {
              onSelectionChanged?.call(!isSelected);
            } else {
              onLongPress?.call();
            }
          },
          borderRadius: BorderRadius.circular(8),
          splashColor: AppTheme.getSubtleColor(context, AppTheme.primaryGreen),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.standardMargin),
            child: Row(
              children: [
                // Avatar with optional selection checkbox
                RoomAvatar(
                  name: room.name,
                  isSelectable: isMultiSelectMode,
                  isSelected: isSelected,
                ),

                const SizedBox(width: AppTheme.elementGap),

                // Content area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and timestamp row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              room.name,
                              style: AppTheme.bodyText.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextColor(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

                      // Last message, typing indicator, or nothing
                      if (room.isTyping ?? false)
                        TypingIndicator(
                          senderName: room.lastMessageSenderName,
                          isGroup: _isGroup,
                        )
                      else if (room.lastMessageText != null)
                        LastMessagePreview(
                          messageText: room.lastMessageText ?? '',
                          senderName: room.lastMessageSenderName,
                          isGroup: _isGroup,
                        ),
                    ],
                  ),
                ),

                // Unread badge
                if (_hasUnread)
                  Column(
                    children: [
                      UnreadCountBadge(count: room.unreadCount),
                      const SizedBox(height: AppTheme.elementGap),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
