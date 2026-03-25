import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../features/contacts/data/roster_repository.dart';
import '../../features/messages/data/message_providers.dart';
import '../../features/messages/domain/room_event.dart';
import '../../features/rooms/data/room_subscription_service.dart';

/// Quoted parent message preview with colored left bar (WhatsApp reply style).
///
/// Fetches the parent message by ID and displays sender name + preview text.
class MessageReplyPreview extends ConsumerWidget {
  const MessageReplyPreview({
    required this.parentId,
    required this.isMe,
    super.key,
  });

  final String parentId;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentAsync = ref.watch(parentMessageProvider(parentId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return parentAsync.when(
      data: (parent) {
        if (parent == null) return const SizedBox.shrink();
        return _buildPreview(context, parent, isDark);
      },
      loading: () => _buildLoadingPreview(context, isDark),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  String _resolveSenderName(WidgetRef ref, String senderId) {
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

  Widget _buildPreview(BuildContext context, RoomEvent parent, bool isDark) {
    final barColor = AppTheme.getSenderNameColor(parent.senderId);
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    final previewText = _getPreviewText(parent);

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: barColor, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Consumer(
            builder: (context, ref, _) {
              final senderName = _resolveSenderName(ref, parent.senderId);
              return Text(
                senderName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: barColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            previewText,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.getBubbleTextColor(
                isMe,
                isDark,
              ).withValues(alpha: 0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPreview(BuildContext context, bool isDark) {
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: const Border(left: BorderSide(color: Colors.grey, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      height: 40,
    );
  }

  String _getPreviewText(RoomEvent event) {
    switch (event.type) {
      case RoomEventType.text:
        return event.content['text'] as String? ?? '';
      case RoomEventType.image:
        return '📷 Photo';
      case RoomEventType.video:
        return '🎥 Video';
      case RoomEventType.audio:
        return '🎵 Voice message';
      case RoomEventType.file:
        return '📄 ${event.content['fileName'] ?? 'File'}';
      default:
        return '';
    }
  }
}
