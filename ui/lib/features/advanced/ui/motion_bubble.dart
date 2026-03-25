import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_handler.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../messages/domain/room_event.dart';
import '../services/motion_service.dart';

class MotionBubble extends ConsumerStatefulWidget {
  const MotionBubble({required this.event, required this.isMe, super.key});
  final RoomEvent event;
  final bool isMe;

  @override
  ConsumerState<MotionBubble> createState() => _MotionBubbleState();
}

class _MotionBubbleState extends ConsumerState<MotionBubble> {
  bool _isVoting = false;

  Future<void> _handleVote(String option) async {
    if (_isVoting) return;

    setState(() => _isVoting = true);

    try {
      final motionService = await ref.read(motionServiceProvider.future);
      await motionService.castVote(
        roomId: widget.event.roomId,
        motionId: widget.event.id,
        option: option,
      );

      if (mounted) {
        ErrorHandler.showSuccess(context, 'Vote cast for "$option"');
      }
    } catch (e, stack) {
      if (mounted) {
        ErrorHandler.handleError(
          context,
          e,
          stack,
          onRetry: () => _handleVote(option),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVoting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final theme = Theme.of(context);
    final content = event.content;
    final title = content['title'] as String? ?? 'Motion';
    final description = content['description'] as String? ?? '';
    final options =
        (content['options'] as List<dynamic>?)?.cast<String>() ?? [];
    final votes = (content['votes'] as Map<String, dynamic>?) ?? {};
    final deadline = DateTime.fromMillisecondsSinceEpoch(
      content['deadline'] as int? ?? 0,
    );
    final isExpired = DateTime.now().isAfter(deadline);

    // Get current profile ID and their vote
    final currentProfileIdAsync = ref.watch(currentProfileIdProvider);
    final currentProfileId = currentProfileIdAsync.when(
      data: (id) => id,
      loading: () => null,
      error: (_, _) => null,
    );
    final userVote = currentProfileId != null
        ? votes[currentProfileId] as String?
        : null;

    // Calculate votes
    final voteCounts = <String, int>{};
    for (final option in options) {
      voteCounts[option] = 0;
    }
    for (final vote in votes.values) {
      if (voteCounts.containsKey(vote)) {
        voteCounts[vote] = (voteCounts[vote] ?? 0) + 1;
      }
    }
    final totalVotes = votes.length;

    // Check status (either expired or explicitly closed)
    final status = content['status'] as String? ?? 'active';
    final isClosed = isExpired || status == 'closed';

    // Find winner (option with most votes)
    String? winner;
    var maxVotes = 0;
    if (isClosed && totalVotes > 0) {
      for (final entry in voteCounts.entries) {
        if (entry.value > maxVotes) {
          maxVotes = entry.value;
          winner = entry.key;
        }
      }
    }

    return Stack(
      children: [
        Container(
          width: 280,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.how_to_vote, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(description, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              // Show results view if closed, otherwise show voting interface
              if (isClosed) ...[
                // Voting Closed Banner
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Voting Closed',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Winner Display
                if (winner != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Winner: $winner',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                // Results for each option
                ...options.map((option) {
                  final count = voteCounts[option] ?? 0;
                  final percentage = totalVotes > 0 ? count / totalVotes : 0.0;
                  final isWinner = option == winner;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              option,
                              style: TextStyle(
                                fontWeight: isWinner
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            Text(
                              '$count votes (${(percentage * 100).toStringAsFixed(1)}%)',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          color: isWinner
                              ? Colors.green
                              : theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                  );
                }),
              ] else ...[
                // Active voting interface
                ...options.map((option) {
                  final count = voteCounts[option] ?? 0;
                  final percentage = totalVotes > 0 ? count / totalVotes : 0.0;
                  final isSelected = userVote == option;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: _isVoting ? null : () => _handleVote(option),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected
                              ? theme.colorScheme.primaryContainer
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    if (isSelected) ...[
                                      Icon(
                                        Icons.check_circle,
                                        color: theme.colorScheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      option,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                Text('$count votes'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: percentage,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
              if (!isClosed) ...[
                const SizedBox(height: 4),
                Text(
                  'Voting ends: ${_formatDate(deadline)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Loading overlay
        if (_isVoting)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}
