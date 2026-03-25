import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/messages/domain/room_event.dart';

/// Long-press bottom sheet with message actions (reply, forward, edit, copy, delete).
class MessageActionMenu {
  MessageActionMenu._();

  /// Show the message action bottom sheet.
  static void show(
    BuildContext context, {
    required RoomEvent message,
    required bool isMe,
    required String text,
    Function(String messageId, String messageText)? onReply,
    Function(String messageId, String currentText)? onEdit,
    bool canEdit = false,
    Function(String messageId, {required bool forEveryone})? onDelete,
    bool canDelete = false,
    Function(RoomEvent message)? onForward,
    bool canForward = false,
  }) {
    final theme = Theme.of(context);

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
              if (onReply != null)
                ListTile(
                  leading: Icon(Icons.reply, color: theme.colorScheme.primary),
                  title: const Text('Reply'),
                  onTap: () {
                    Navigator.pop(context);
                    onReply.call(message.id, text);
                  },
                ),
              if (canForward && onForward != null)
                ListTile(
                  leading: Icon(
                    Icons.shortcut,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Forward'),
                  onTap: () {
                    Navigator.pop(context);
                    onForward.call(message);
                  },
                ),
              if (isMe && canEdit && message.type == RoomEventType.text)
                ListTile(
                  leading: Icon(Icons.edit, color: theme.colorScheme.primary),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit?.call(message.id, text);
                  },
                ),
              if (message.type == RoomEventType.text && text.isNotEmpty)
                ListTile(
                  leading: Icon(Icons.copy, color: theme.colorScheme.primary),
                  title: const Text('Copy'),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              if (onDelete != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.orange,
                  ),
                  title: const Text('Delete for me'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(
                      context,
                      messageId: message.id,
                      onDelete: onDelete,
                      forEveryone: false,
                    );
                  },
                ),
              if (isMe && canDelete && onDelete != null)
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete for everyone'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(
                      context,
                      messageId: message.id,
                      onDelete: onDelete,
                      forEveryone: true,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showDeleteConfirmation(
    BuildContext context, {
    required String messageId,
    required Function(String messageId, {required bool forEveryone}) onDelete,
    required bool forEveryone,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(forEveryone ? 'Delete for everyone?' : 'Delete for me?'),
        content: Text(
          forEveryone
              ? 'This message will be deleted for everyone in this chat. '
                    'Others will see that a message was deleted.'
              : 'This message will be removed from your device only. '
                    'Others will still see it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete(messageId, forEveryone: forEveryone);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
