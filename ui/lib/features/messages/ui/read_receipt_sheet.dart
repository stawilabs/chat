import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/read_receipt_repository.dart';

/// Bottom sheet showing who has read a message in a group chat
///
/// Displays a list of readers with their names and the time they read.
/// Format: "Seen by X, Y, and Z" with individual timestamps.
class ReadReceiptSheet extends ConsumerWidget {
  const ReadReceiptSheet({
    required this.eventId,
    required this.roomId,
    super.key,
  });

  final String eventId;
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readersAsync = ref.watch(messageReadersProvider(eventId));
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.done_all,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Read by',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Readers list
            Expanded(
              child: readersAsync.when(
                data: (readers) {
                  if (readers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility_off_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No read receipts yet',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: readers.length,
                    itemBuilder: (context, index) {
                      final reader = readers[index];
                      return _ReaderTile(reader: reader);
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Failed to load readers',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Individual reader tile showing name and read time
class _ReaderTile extends StatelessWidget {
  const _ReaderTile({required this.reader});

  final ReadReceiptInfo reader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readTime = DateTime.fromMillisecondsSinceEpoch(reader.readAt);
    final now = DateTime.now();
    final isToday =
        readTime.day == now.day &&
        readTime.month == now.month &&
        readTime.year == now.year;
    final isYesterday =
        readTime.day == now.day - 1 &&
        readTime.month == now.month &&
        readTime.year == now.year;

    String timeString;
    if (isToday) {
      timeString = 'Today, ${DateFormat.jm().format(readTime)}';
    } else if (isYesterday) {
      timeString = 'Yesterday, ${DateFormat.jm().format(readTime)}';
    } else {
      timeString = DateFormat('MMM d, h:mm a').format(readTime);
    }

    final displayName = reader.displayName ?? reader.profileId.substring(0, 8);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(
        displayName,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        timeString,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: Icon(
        Icons.done_all,
        size: 18,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

/// Helper function to format "Seen by X, Y, and Z" text
String formatReadersText(List<ReadReceiptInfo> readers) {
  if (readers.isEmpty) return '';

  final names = readers
      .map((r) => r.displayName ?? r.profileId.substring(0, 8))
      .toList();

  switch (names.length) {
    case 1:
      return 'Seen by ${names[0]}';
    case 2:
      return 'Seen by ${names[0]} and ${names[1]}';
    case 3:
      return 'Seen by ${names[0]}, ${names[1]}, and ${names[2]}';
    default:
      return 'Seen by ${names[0]}, ${names[1]}, and ${names.length - 2} others';
  }
}
