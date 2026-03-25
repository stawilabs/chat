import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../features/contacts/data/roster_repository.dart';
import '../../features/rooms/data/room_subscription_service.dart';

/// Outer shell for a message bubble: color, radius, shadow, alignment, avatar.
///
/// Handles the WhatsApp-style layout where received messages in groups show
/// an avatar on the left, and sent messages are right-aligned without avatars.
class MessageBubbleContainer extends ConsumerWidget {
  const MessageBubbleContainer({
    required this.isMe,
    required this.removeTail,
    required this.shouldGroupWithPrevious,
    required this.isGroupChat,
    required this.senderId,
    required this.child,
    super.key,
  });

  final bool isMe;
  final bool removeTail;
  final bool shouldGroupWithPrevious;
  final bool isGroupChat;
  final String senderId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = AppTheme.getBubbleColor(isMe, isDark);
    final showAvatar = !isMe && isGroupChat && !shouldGroupWithPrevious;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar for received messages in group chats
            if (!isMe && isGroupChat) ...[
              if (showAvatar)
                _buildAvatar(context, ref)
              else
                const SizedBox(width: 36),
              const SizedBox(width: 6),
            ],
            // Bubble
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: _getBubbleRadius(isMe, removeTail),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, WidgetRef ref) {
    final name = _getSenderName(ref);
    final color = AppTheme.getSenderNameColor(senderId);

    return CircleAvatar(
      radius: 14,
      backgroundColor: color.withValues(alpha: 0.2),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _getSenderName(WidgetRef ref) {
    final profileIdAsync = ref.watch(
      profileIdFromSubscriptionProvider(senderId),
    );
    final profilesAsync = ref.watch(profilesWithContactsStreamProvider);

    final profileId = profileIdAsync.when(
      data: (id) => id,
      loading: () => null,
      error: (_, _) => null,
    );

    return profilesAsync.when(
      data: (profiles) {
        if (profileId != null) {
          final senderProfile = profiles
              .where((p) => p.profile.id == profileId)
              .firstOrNull;
          if (senderProfile != null) {
            return senderProfile.displayName;
          }
        }
        return senderId;
      },
      loading: () => senderId,
      error: (_, _) => senderId,
    );
  }

  BorderRadius _getBubbleRadius(bool isMe, bool removeTail) {
    const radius = Radius.circular(12);
    const tailRadius = Radius.circular(4);

    if (removeTail) {
      return const BorderRadius.all(radius);
    }

    return BorderRadius.only(
      topLeft: radius,
      topRight: radius,
      bottomLeft: isMe ? radius : tailRadius,
      bottomRight: isMe ? tailRadius : radius,
    );
  }
}
