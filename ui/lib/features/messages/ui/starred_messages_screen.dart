import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../rooms/data/room_providers.dart';
import '../data/message_providers.dart';
import '../domain/room_event.dart';

/// Provider for starred messages
final starredMessagesProvider = FutureProvider<List<RoomEvent>>((ref) async {
  final db = ref.watch(messageRepositoryProvider);
  return db.getStarredMessages();
});

/// Provider for starred messages stream (reactive)
final starredMessagesStreamProvider = StreamProvider<List<RoomEvent>>((ref) {
  final db = ref.watch(messageRepositoryProvider);
  return db.watchStarredMessages();
});

/// Screen displaying all starred/bookmarked messages
///
/// Shows starred messages from all rooms, organized by when they were starred.
/// Users can tap a message to navigate to it in its original room, or unstar it.
class StarredMessagesScreen extends ConsumerWidget {
  const StarredMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starredMessages = ref.watch(starredMessagesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Starred Messages'),
        actions: [
          starredMessages.whenOrNull(
                data: (messages) => messages.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.delete_sweep),
                        tooltip: 'Clear all starred',
                        onPressed: () => _showClearAllDialog(context, ref),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: starredMessages.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load starred messages',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(starredMessagesStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (messages) => messages.isEmpty
            ? _buildEmptyState(context)
            : _buildMessageList(context, ref, messages),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_border,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No starred messages',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Star important messages to find them easily later',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    BuildContext context,
    WidgetRef ref,
    List<RoomEvent> messages,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _StarredMessageTile(
          message: message,
          onTap: () => _navigateToMessage(context, message),
          onUnstar: () => _unstarMessage(context, ref, message),
        );
      },
    );
  }

  void _navigateToMessage(BuildContext context, RoomEvent message) {
    // Navigate to the room containing this message
    context.push(
      '/chat/${message.roomId}',
      extra: {'highlightEventId': message.id},
    );
  }

  Future<void> _unstarMessage(
    BuildContext context,
    WidgetRef ref,
    RoomEvent message,
  ) async {
    final repo = ref.read(messageRepositoryProvider);
    await repo.unstarMessage(message.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Message unstarred'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => repo.starMessage(message.id),
          ),
        ),
      );
    }
  }

  Future<void> _showClearAllDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all starred messages?'),
        content: const Text(
          'This will remove the star from all messages. '
          'The messages themselves will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      final repo = ref.read(messageRepositoryProvider);
      final count = await repo.clearAllStarredMessages();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unstarred $count messages')));
      }
    }
  }
}

/// Individual tile showing a starred message
class _StarredMessageTile extends ConsumerWidget {
  const _StarredMessageTile({
    required this.message,
    required this.onTap,
    required this.onUnstar,
  });

  final RoomEvent message;
  final VoidCallback onTap;
  final VoidCallback onUnstar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomByIdProvider(message.roomId));
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room name and star button
              Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: roomAsync.when(
                      data: (room) => Text(
                        room?.name ?? 'Unknown Room',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      loading: () => Text(
                        'Loading...',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      error: (error, stackTrace) => Text(
                        'Unknown Room',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.star, color: Colors.amber),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onUnstar,
                    tooltip: 'Unstar message',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Message content
              _buildMessageContent(context),
              const SizedBox(height: 8),
              // Timestamp
              Text(
                _formatStarredAt(message.starredAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    final theme = Theme.of(context);

    switch (message.type) {
      case RoomEventType.text:
        return Text(
          message.content['text'] as String? ?? '',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium,
        );
      case RoomEventType.image:
        return Row(
          children: [
            Icon(Icons.image, size: 16, color: theme.colorScheme.outline),
            const SizedBox(width: 8),
            Text('Photo', style: theme.textTheme.bodyMedium),
          ],
        );
      case RoomEventType.video:
        return Row(
          children: [
            Icon(Icons.videocam, size: 16, color: theme.colorScheme.outline),
            const SizedBox(width: 8),
            Text('Video', style: theme.textTheme.bodyMedium),
          ],
        );
      case RoomEventType.audio:
        return Row(
          children: [
            Icon(Icons.mic, size: 16, color: theme.colorScheme.outline),
            const SizedBox(width: 8),
            Text('Voice message', style: theme.textTheme.bodyMedium),
          ],
        );
      case RoomEventType.file:
        final fileName = message.content['name'] as String? ?? 'File';
        return Row(
          children: [
            Icon(Icons.attach_file, size: 16, color: theme.colorScheme.outline),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        );
      default:
        return Text(
          'Message',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.outline,
          ),
        );
    }
  }

  String _formatStarredAt(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Starred today';
    } else if (diff.inDays == 1) {
      return 'Starred yesterday';
    } else if (diff.inDays < 7) {
      return 'Starred ${diff.inDays} days ago';
    } else {
      return 'Starred on ${date.month}/${date.day}/${date.year}';
    }
  }
}
