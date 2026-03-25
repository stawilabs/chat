import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../data/call_history_repository.dart';
import '../domain/call_history_entry.dart';
import '../services/call_manager.dart';

/// Provider for call history stream
final callHistoryStreamProvider = StreamProvider<List<CallHistoryEntry>>((ref) {
  final repo = ref.watch(callHistoryRepositoryProvider);
  return repo.watchCallHistory();
});

/// Provider for unread missed call count
final missedCallCountProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(callHistoryRepositoryProvider);
  return repo.watchUnreadMissedCallCount();
});

/// Filter options for call history
enum CallHistoryFilter {
  all('All'),
  missed('Missed'),
  incoming('Incoming'),
  outgoing('Outgoing');

  const CallHistoryFilter(this.label);
  final String label;
}

/// Screen displaying the user's call history
///
/// Shows all voice and video calls with ability to filter by type,
/// call back, and delete entries.
class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen> {
  CallHistoryFilter _filter = CallHistoryFilter.all;

  @override
  void initState() {
    super.initState();
    // Mark all calls as read when viewing history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(callHistoryRepositoryProvider).markAllAsRead();
    });
  }

  List<CallHistoryEntry> _filterCalls(List<CallHistoryEntry> calls) {
    switch (_filter) {
      case CallHistoryFilter.all:
        return calls;
      case CallHistoryFilter.missed:
        return calls.where((c) => c.isMissed).toList();
      case CallHistoryFilter.incoming:
        return calls.where((c) => c.isIncoming).toList();
      case CallHistoryFilter.outgoing:
        return calls.where((c) => c.isOutgoing).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final callHistory = ref.watch(callHistoryStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call History'),
        actions: [
          PopupMenuButton<CallHistoryFilter>(
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) => setState(() => _filter = filter),
            itemBuilder: (context) => CallHistoryFilter.values
                .map(
                  (f) => PopupMenuItem(
                    value: f,
                    child: Row(
                      children: [
                        if (f == _filter)
                          const Icon(Icons.check, size: 18)
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 8),
                        Text(f.label),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _showClearHistoryDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep),
                    SizedBox(width: 8),
                    Text('Clear history'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: callHistory.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load call history',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(callHistoryStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (calls) {
          final filteredCalls = _filterCalls(calls);

          if (filteredCalls.isEmpty) {
            return _buildEmptyState(theme);
          }

          return _buildCallList(filteredCalls);
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _filter == CallHistoryFilter.missed
                ? Icons.call_missed
                : Icons.call,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            _filter == CallHistoryFilter.all
                ? 'No call history'
                : 'No ${_filter.label.toLowerCase()} calls',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your calls will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallList(List<CallHistoryEntry> calls) {
    // Group calls by date
    final groupedCalls = _groupCallsByDate(calls);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: groupedCalls.length,
      itemBuilder: (context, index) {
        final group = groupedCalls[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                group.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...group.calls.map(
              (call) => _CallHistoryTile(
                call: call,
                onTap: () => _onCallTap(call),
                onCallBack: () => _callBack(call),
                onDelete: () => _deleteCall(call),
              ),
            ),
          ],
        );
      },
    );
  }

  List<_CallGroup> _groupCallsByDate(List<CallHistoryEntry> calls) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeek = today.subtract(Duration(days: today.weekday - 1));

    final groups = <String, List<CallHistoryEntry>>{};

    for (final call in calls) {
      final callDate = call.startedAtDateTime;
      final callDay = DateTime(callDate.year, callDate.month, callDate.day);

      String label;
      if (callDay == today) {
        label = 'Today';
      } else if (callDay == yesterday) {
        label = 'Yesterday';
      } else if (callDay.isAfter(thisWeek)) {
        label = 'This Week';
      } else if (callDay.month == now.month && callDay.year == now.year) {
        label = 'This Month';
      } else {
        label = '${_monthName(callDay.month)} ${callDay.year}';
      }

      groups.putIfAbsent(label, () => []).add(call);
    }

    // Convert to list maintaining insertion order
    return groups.entries
        .map((e) => _CallGroup(label: e.key, calls: e.value))
        .toList();
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  void _onCallTap(CallHistoryEntry call) {
    // Navigate to the room
    context.push('/chat/${call.roomId}');
  }

  Future<void> _callBack(CallHistoryEntry call) async {
    try {
      final callManager = await ref.read(callManagerProvider.future);
      await callManager.startCall(call.roomId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start call: $e')));
      }
    }
  }

  Future<void> _deleteCall(CallHistoryEntry call) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete call?'),
        content: const Text('This call will be removed from your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && call.id != null) {
      await ref.read(callHistoryRepositoryProvider).deleteCall(call.id!);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Call deleted')));
      }
    }
  }

  Future<void> _showClearHistoryDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear call history?'),
        content: const Text(
          'All calls will be removed from your history. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final count = await ref
          .read(callHistoryRepositoryProvider)
          .clearAllHistory();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Cleared $count calls')));
      }
    }
  }
}

class _CallGroup {
  const _CallGroup({required this.label, required this.calls});
  final String label;
  final List<CallHistoryEntry> calls;
}

/// Individual tile showing a call history entry
class _CallHistoryTile extends StatelessWidget {
  const _CallHistoryTile({
    required this.call,
    required this.onTap,
    required this.onCallBack,
    required this.onDelete,
  });

  final CallHistoryEntry call;
  final VoidCallback onTap;
  final VoidCallback onCallBack;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key('call-${call.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: call.color.withValues(alpha: 0.15),
          child: Icon(call.icon, color: call.color, size: 20),
        ),
        title: Text(
          call.otherPartyName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: call.isMissed && !call.isRead
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              call.callType.icon,
              size: 14,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 4),
            Text(
              call.isIncoming ? 'Incoming' : 'Outgoing',
              style: theme.textTheme.bodySmall?.copyWith(
                color: call.isMissed ? Colors.red : theme.colorScheme.outline,
              ),
            ),
            if (call.wasAnswered && call.duration > 0) ...[
              const SizedBox(width: 8),
              Text(
                call.formattedDuration,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTime(call.startedAtDateTime),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                call.callType == CallType.video ? Icons.videocam : Icons.phone,
                color: AppTheme.primaryGreen,
              ),
              onPressed: onCallBack,
              tooltip: 'Call back',
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final callDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (callDay == today) {
      // Show time for today
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour12:$minute $period';
    } else {
      // Show date for older calls
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
