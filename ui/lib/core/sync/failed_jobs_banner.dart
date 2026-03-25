import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pending_job.dart';
import 'sync_engine.dart';

/// Banner that displays when there are failed messages that couldn't be sent
///
/// Shows a notification banner with:
/// - Count of failed messages
/// - Option to retry all
/// - Option to view details
class FailedJobsBanner extends ConsumerWidget {
  const FailedJobsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failedCountAsync = ref.watch(failedJobCountProvider);

    return failedCountAsync.when(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();

        return _buildBanner(context, ref, count);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildBanner(BuildContext context, WidgetRef ref, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.red.shade900.withValues(alpha: 0.3)
            : Colors.red.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 20, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count message${count > 1 ? 's' : ''} failed to send',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                  Text(
                    'Tap to retry or dismiss',
                    style: TextStyle(fontSize: 11, color: Colors.red.shade600),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _showFailedJobsSheet(context, ref),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('View'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFailedJobsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const FailedJobsSheet(),
    );
  }
}

/// Bottom sheet showing list of failed jobs with retry/delete options
class FailedJobsSheet extends ConsumerWidget {
  const FailedJobsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failedJobsAsync = ref.watch(recentFailedJobsProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600),
                  const SizedBox(width: 12),
                  Text(
                    'Failed Messages',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _retryAll(ref),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry All'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // List of failed jobs
            Expanded(
              child: failedJobsAsync.when(
                data: (jobs) {
                  if (jobs.isEmpty) {
                    return const Center(child: Text('No failed messages'));
                  }

                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: jobs.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return _FailedJobTile(job: job);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Error loading failed jobs: $e')),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _retryAll(WidgetRef ref) async {
    final jobRepo = ref.read(pendingJobRepositoryProvider);
    final jobs = await jobRepo.getRecentFailedJobs(limit: 100);

    for (final job in jobs) {
      await jobRepo.retryFailedJob(job.id);
    }

    // Refresh the provider
    ref.invalidate(recentFailedJobsProvider);
  }
}

/// Individual tile for a failed job
class _FailedJobTile extends ConsumerWidget {
  const _FailedJobTile({required this.job});
  final PendingJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final jobDescription = _getJobDescription(job);
    final timestamp = DateTime.fromMillisecondsSinceEpoch(job.createdAt);
    final timeAgo = _formatTimeAgo(timestamp);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.red.shade100,
        child: Icon(
          _getJobIcon(job.type),
          color: Colors.red.shade700,
          size: 20,
        ),
      ),
      title: Text(
        jobDescription,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        'Failed $timeAgo • ${job.retryCount} attempts',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _retry(ref),
            tooltip: 'Retry',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(ref),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }

  String _getJobDescription(PendingJob job) {
    switch (job.type) {
      case JobType.sendMessage:
      case JobType.sendMediaMessage:
        final text = job.payload['text'] as String?;
        if (text != null && text.isNotEmpty) {
          return text.length > 50 ? '${text.substring(0, 50)}...' : text;
        }
        return 'Message';
      case JobType.createRoom:
        return 'Create room';
      case JobType.updateRoom:
        return 'Update room';
      case JobType.deleteRoom:
        return 'Delete room';
      case JobType.addRoomMembers:
        return 'Add members';
      case JobType.removeRoomMembers:
        return 'Remove members';
      case JobType.leaveRoom:
        return 'Leave room';
      default:
        return job.type.name;
    }
  }

  IconData _getJobIcon(JobType type) {
    switch (type) {
      case JobType.sendMessage:
        return Icons.message;
      case JobType.sendMediaMessage:
        return Icons.image;
      case JobType.createRoom:
        return Icons.group_add;
      case JobType.updateRoom:
        return Icons.edit;
      case JobType.deleteRoom:
        return Icons.delete;
      case JobType.addRoomMembers:
        return Icons.person_add;
      case JobType.removeRoomMembers:
        return Icons.person_remove;
      case JobType.leaveRoom:
        return Icons.exit_to_app;
      default:
        return Icons.error;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  Future<void> _retry(WidgetRef ref) async {
    final jobRepo = ref.read(pendingJobRepositoryProvider);
    await jobRepo.retryFailedJob(job.id);
    ref.invalidate(recentFailedJobsProvider);
  }

  Future<void> _delete(WidgetRef ref) async {
    final jobRepo = ref.read(pendingJobRepositoryProvider);
    await jobRepo.deleteFailedJob(job.id);
    ref.invalidate(recentFailedJobsProvider);
  }
}
