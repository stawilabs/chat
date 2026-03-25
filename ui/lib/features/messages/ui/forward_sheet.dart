import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/message_forwarding_service.dart';
import '../domain/room_event.dart';
import 'room_picker.dart';

/// Shows the forward sheet as a modal bottom sheet
///
/// Returns the list of room IDs the message was forwarded to,
/// or null if the user cancelled.
Future<List<String>?> showForwardSheet({
  required BuildContext context,
  required RoomEvent message,
  String? currentRoomId,
}) => showModalBottomSheet<List<String>>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  builder: (context) =>
      ForwardSheet(message: message, currentRoomId: currentRoomId),
);

/// A bottom sheet for forwarding a message to selected rooms
class ForwardSheet extends ConsumerStatefulWidget {
  const ForwardSheet({required this.message, this.currentRoomId, super.key});

  /// The message to forward
  final RoomEvent message;

  /// The current room ID to exclude from the list
  final String? currentRoomId;

  @override
  ConsumerState<ForwardSheet> createState() => _ForwardSheetState();
}

class _ForwardSheetState extends ConsumerState<ForwardSheet> {
  List<String> _selectedRoomIds = [];
  bool _isForwarding = false;

  Future<void> _forwardMessage() async {
    if (_selectedRoomIds.isEmpty || _isForwarding) return;

    setState(() => _isForwarding = true);

    try {
      final forwardingService = ref.read(messageForwardingServiceProvider);
      final results = await forwardingService.forwardMessage(
        originalEvent: widget.message,
        destinationRoomIds: _selectedRoomIds,
      );

      final successCount = results.where((r) => r.success).length;
      final failCount = results.where((r) => !r.success).length;

      if (mounted) {
        // Show result
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failCount == 0
                  ? 'Message forwarded to $successCount chat${successCount > 1 ? 's' : ''}'
                  : 'Forwarded to $successCount chat${successCount > 1 ? 's' : ''}, $failCount failed',
            ),
            backgroundColor: failCount == 0 ? AppTheme.primaryGreen : null,
          ),
        );

        // Return the list of room IDs that were successfully forwarded to
        Navigator.of(context).pop(
          results
              .where((r) => r.success)
              .map((r) => r.destinationRoomId)
              .toList(),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isForwarding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to forward message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final excludeRoomIds = widget.currentRoomId != null
        ? [widget.currentRoomId!]
        : <String>[];

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Forward to...',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Forward button
                FilledButton.icon(
                  onPressed: _selectedRoomIds.isNotEmpty && !_isForwarding
                      ? _forwardMessage
                      : null,
                  icon: _isForwarding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, size: 18),
                  label: Text(
                    _selectedRoomIds.isEmpty
                        ? 'Forward'
                        : 'Forward (${_selectedRoomIds.length})',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    disabledBackgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Message preview
          _MessagePreview(message: widget.message),

          const Divider(height: 1),

          // Room picker
          Expanded(
            child: RoomPicker(
              excludeRoomIds: excludeRoomIds,
              onSelectionChanged: (selectedRoomIds) {
                setState(() => _selectedRoomIds = selectedRoomIds);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A preview of the message being forwarded
class _MessagePreview extends StatelessWidget {
  const _MessagePreview({required this.message});

  final RoomEvent message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get message preview text
    String previewText;
    IconData? previewIcon;

    switch (message.type) {
      case RoomEventType.text:
        previewText = message.content['text'] as String? ?? '';
        break;
      case RoomEventType.image:
        previewText = message.content['caption'] as String? ?? 'Photo';
        previewIcon = Icons.image;
        break;
      case RoomEventType.video:
        previewText = message.content['caption'] as String? ?? 'Video';
        previewIcon = Icons.videocam;
        break;
      case RoomEventType.audio:
        previewText = 'Voice message';
        previewIcon = Icons.mic;
        break;
      case RoomEventType.file:
        previewText = message.content['fileName'] as String? ?? 'File';
        previewIcon = Icons.insert_drive_file;
        break;
      case RoomEventType.motion:
        previewText = 'Motion';
        previewIcon = Icons.how_to_vote;
        break;
      case RoomEventType.transaction:
        previewText = 'Transaction';
        previewIcon = Icons.payment;
        break;
      default:
        previewText = 'Message';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppTheme.primaryGreen, width: 4),
        ),
      ),
      child: Row(
        children: [
          if (previewIcon != null) ...[
            Icon(
              previewIcon,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.isForwarded)
                  Row(
                    children: [
                      Icon(
                        Icons.shortcut,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Forwarded',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                Text(
                  previewText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
