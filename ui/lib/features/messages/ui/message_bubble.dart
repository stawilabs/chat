import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/message/message_action_menu.dart';
import '../../../widgets/message/message_bubble_container.dart';
import '../../../widgets/message/message_content_audio.dart';
import '../../../widgets/message/message_content_file.dart';
import '../../../widgets/message/message_content_image.dart';
import '../../../widgets/message/message_content_text.dart';
import '../../../widgets/message/message_content_video.dart';
import '../../../widgets/message/message_forwarded_label.dart';
import '../../../widgets/message/message_reply_preview.dart';
import '../../../widgets/message/message_sender_name.dart';
import '../../../widgets/message/message_swipe_wrapper.dart';
import '../../../widgets/message/message_timestamp_row.dart';
import '../domain/room_event.dart';

/// WhatsApp-style message bubble — composition root.
///
/// Composes reusable sub-components from `lib/widgets/message/`:
/// - [MessageSwipeWrapper] for swipe-to-reply
/// - [MessageBubbleContainer] for color, radius, shadow, avatar
/// - [MessageSenderName] for per-user colored name in groups
/// - [MessageForwardedLabel] for forwarded indicator
/// - [MessageReplyPreview] for quoted parent message
/// - Content widgets: text, image, video, audio, file
/// - [MessageTimestampRow] for inline timestamp + read receipt
/// - [MessageActionMenu] for long-press actions
class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    required this.message,
    required this.isMe,
    super.key,
    this.shouldGroupWithPrevious = false,
    this.removeTail = false,
    this.isGroupChat = false,
    this.onReply,
    this.onRetry,
    this.onEdit,
    this.canEdit = false,
    this.onDelete,
    this.canDelete = false,
    this.onForward,
    this.canForward = false,
    this.onCancelUpload,
    this.onRetryUpload,
  });

  final RoomEvent message;
  final bool isMe;
  final bool shouldGroupWithPrevious;
  final bool removeTail;
  final bool isGroupChat;
  final Function(String messageId, String messageText)? onReply;
  final VoidCallback? onRetry;
  final Function(String messageId, String currentText)? onEdit;
  final bool canEdit;
  final Function(String messageId, {required bool forEveryone})? onDelete;
  final bool canDelete;
  final Function(RoomEvent message)? onForward;
  final bool canForward;
  final Function(String localId)? onCancelUpload;
  final Function(String localId)? onRetryUpload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = message.content['text'] as String? ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (message.isDeleted) {
      return _buildDeletedMessage(context, isDark);
    }

    return RepaintBoundary(
      key: ValueKey(message.id),
      child: MessageSwipeWrapper(
        messageId: message.id,
        onSwipeReply: onReply != null
            ? () => onReply!.call(message.id, text)
            : null,
        child: GestureDetector(
          onLongPress: () => MessageActionMenu.show(
            context,
            message: message,
            isMe: isMe,
            text: text,
            onReply: onReply,
            onEdit: onEdit,
            canEdit: canEdit,
            onDelete: onDelete,
            canDelete: canDelete,
            onForward: onForward,
            canForward: canForward,
          ),
          child: MessageBubbleContainer(
            isMe: isMe,
            removeTail: removeTail,
            shouldGroupWithPrevious: shouldGroupWithPrevious,
            isGroupChat: isGroupChat,
            senderId: message.senderId,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender name (groups, received only, not grouped)
                if (!isMe && isGroupChat && !shouldGroupWithPrevious)
                  MessageSenderName(senderId: message.senderId),

                // Forwarded label
                if (message.isForwarded) MessageForwardedLabel(isMe: isMe),

                // Reply preview
                if (message.parentId != null)
                  MessageReplyPreview(parentId: message.parentId!, isMe: isMe),

                // Content + inline timestamp
                Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        12,
                        _hasHeaderAbove ? 0 : 8,
                        12,
                        6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildContent(context, ref),
                          const SizedBox(height: 16), // Space for timestamp
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 8,
                      child: MessageTimestampRow(
                        message: message,
                        isMe: isMe,
                        isGroupChat: isGroupChat,
                      ),
                    ),
                  ],
                ),

                // Retry button for failed messages
                if (isMe && message.status == EventStatus.failed)
                  _buildRetryButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasHeaderAbove => message.isForwarded || message.parentId != null;

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final isEncrypted = message.content['encrypted'] == true;

    if (isEncrypted) {
      return _buildEncryptedContent(context);
    }

    switch (message.type) {
      case RoomEventType.image:
        return MessageContentImage(
          message: message,
          isMe: isMe,
          onCancelUpload: onCancelUpload,
          onRetryUpload: onRetryUpload,
        );
      case RoomEventType.video:
        return MessageContentVideo(
          message: message,
          isMe: isMe,
          onCancelUpload: onCancelUpload,
          onRetryUpload: onRetryUpload,
        );
      case RoomEventType.audio:
        return MessageContentAudio(
          message: message,
          isMe: isMe,
          onCancelUpload: onCancelUpload,
          onRetryUpload: onRetryUpload,
        );
      case RoomEventType.file:
        return MessageContentFile(
          message: message,
          isMe: isMe,
          onCancelUpload: onCancelUpload,
          onRetryUpload: onRetryUpload,
        );
      case RoomEventType.reaction:
        final emoji = message.content['emoji'] as String? ?? '\u{1F44D}';
        return Text(emoji, style: const TextStyle(fontSize: 24));
      default:
        return MessageContentText(
          text: message.content['text'] as String? ?? '',
          isMe: isMe,
        );
    }
  }

  Widget _buildEncryptedContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, size: 14, color: Colors.green.shade700),
            const SizedBox(width: 4),
            Text(
              'Encrypted message',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          message.content['text'] as String? ?? '[Encrypted]',
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: AppTheme.getBubbleTextColor(isMe, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildDeletedMessage(BuildContext context, bool isDark) {
    final timestamp = _formatTimestamp(message.createdAt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.grey.shade800.withValues(alpha: 0.5)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block,
              size: 16,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              isMe ? 'You deleted this message' : 'This message was deleted',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              timestamp,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    final retryCount = message.retryCount;
    final errorMsg = message.errorMessage;
    final requiresManual = message.requiresManualRetry;

    return GestureDetector(
      onTap: () => _showRetryOptions(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.red.shade600),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    requiresManual
                        ? 'Failed after $retryCount attempts. Tap for options'
                        : 'Not sent${retryCount > 0 ? " ($retryCount/$maxAutoRetries)" : ""}. Tap for options',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (errorMsg != null && errorMsg.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                errorMsg,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red.shade400,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRetryOptions(BuildContext context) {
    final theme = Theme.of(context);
    final retryCount = message.retryCount;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Message not sent',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (retryCount > 0)
                            Text(
                              'Attempted $retryCount time${retryCount > 1 ? "s" : ""}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.refresh, color: theme.colorScheme.primary),
                title: const Text('Retry sending'),
                subtitle: const Text('Try to send the message again'),
                onTap: () {
                  Navigator.pop(context);
                  onRetry?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete message'),
                subtitle: const Text('Remove this unsent message'),
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call(message.id, forEveryone: false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
