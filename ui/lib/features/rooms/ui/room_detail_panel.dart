import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/navigation_helper.dart';
import '../../advanced/domain/group_finance_config.dart';
import '../../advanced/services/group_config_service.dart';
import '../../advanced/ui/group_finance_config_screen.dart';
import '../../messages/domain/room_event.dart';
import '../../notifications/mute_service.dart';
import '../data/detail_panel_providers.dart';
import '../data/room_providers.dart';
import '../data/room_service.dart';
import '../domain/room.dart';
import 'member_action_sheet.dart';

/// Room detail panel showing room information, motions, transactions, and media
/// Displayed in the right panel on desktop layouts
class RoomDetailPanel extends ConsumerStatefulWidget {
  const RoomDetailPanel({
    required this.roomId,
    required this.roomName,
    super.key,
  });
  final String roomId;
  final String roomName;

  @override
  ConsumerState<RoomDetailPanel> createState() => _RoomDetailPanelState();
}

class _RoomDetailPanelState extends ConsumerState<RoomDetailPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Details', style: TextStyle(fontSize: 16)),
            Text(
              widget.roomName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsMenu(context),
            tooltip: 'Room Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Info', icon: Icon(Icons.info_outline, size: 18)),
            Tab(text: 'Motions', icon: Icon(Icons.how_to_vote, size: 18)),
            Tab(
              text: 'Transactions',
              icon: Icon(Icons.account_balance, size: 18),
            ),
            Tab(text: 'Media', icon: Icon(Icons.photo_library, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildMotionsTab(),
          _buildTransactionsTab(),
          _buildMediaTab(),
        ],
      ),
    );
  }

  void _showSettingsMenu(BuildContext context) {
    final muteStateAsync = ref.watch(roomMuteStateProvider(widget.roomId));

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Room Info'),
              onTap: () {
                Navigator.pop(sheetContext);
                // Navigate to group settings screen
                context.navigateToGroupSettings(
                  roomId: widget.roomId,
                  roomName: widget.roomName,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Finance Settings'),
              onTap: () {
                Navigator.pop(sheetContext);
                _openFinanceSettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Add Members'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.navigateToContactSelection();
              },
            ),
            // Mute/Unmute option
            muteStateAsync.when(
              data: (isMuted) => ListTile(
                leading: Icon(
                  isMuted ? Icons.notifications : Icons.notifications_off,
                ),
                title: Text(
                  isMuted ? 'Unmute Notifications' : 'Mute Notifications',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (isMuted) {
                    _unmuteRoom();
                  } else {
                    _showMuteDurationPicker(context);
                  }
                },
              ),
              loading: () => const ListTile(
                leading: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                title: Text('Loading Mute State...'),
              ),
              error: (_, _) => const ListTile(
                leading: Icon(Icons.error_outline, color: Colors.grey),
                title: Text('Mute Notifications'),
                subtitle: Text('Unable to load mute state'),
                enabled: false,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notification Settings'),
              onTap: () {
                Navigator.pop(sheetContext);
                // Navigate to notification settings
                context.navigateToNotificationSettings();
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.red.shade600),
              title: Text(
                'Leave Room',
                style: TextStyle(color: Colors.red.shade600),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmLeaveRoom(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFinanceSettings() async {
    // Read existing config from room metadata
    GroupFinanceConfig? existing;
    try {
      final room = await ref.read(roomByIdProvider(widget.roomId).future);
      final configJson = room?.metadata?['financeConfig'];
      if (configJson is Map<String, dynamic>) {
        existing = GroupFinanceConfig.fromJson(configJson);
      }
    } catch (_) {
      // No existing config
    }

    if (!mounted) return;
    final result = await Navigator.of(context).push<GroupFinanceConfig>(
      MaterialPageRoute(
        builder: (_) => GroupFinanceConfigScreen(initialConfig: existing),
      ),
    );

    if (result != null && mounted) {
      try {
        final service = await ref.read(groupConfigServiceProvider.future);
        await service.sendGroupConfig(widget.roomId, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Finance settings updated')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update finance settings: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Show the mute duration picker dialog
  void _showMuteDurationPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mute Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose how long to mute this chat:'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('8 hours'),
              onTap: () {
                Navigator.pop(dialogContext);
                _muteRoom(MuteDuration.eightHours);
              },
            ),
            ListTile(
              title: const Text('1 week'),
              onTap: () {
                Navigator.pop(dialogContext);
                _muteRoom(MuteDuration.oneWeek);
              },
            ),
            ListTile(
              title: const Text('Forever'),
              onTap: () {
                Navigator.pop(dialogContext);
                _muteRoom(MuteDuration.forever);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Mute the room with the specified duration
  Future<void> _muteRoom(MuteDuration duration) async {
    try {
      await ref
          .read(roomMuteStateProvider(widget.roomId).notifier)
          .mute(duration);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notifications muted for ${duration.label}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mute notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Unmute the room
  Future<void> _unmuteRoom() async {
    try {
      await ref.read(roomMuteStateProvider(widget.roomId).notifier).unmute();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notifications unmuted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unmute notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmLeaveRoom(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Room'),
        content: Text('Are you sure you want to leave "${widget.roomName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement leave room functionality
              _leaveRoom(context, ref);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    final membersAsync = ref.watch(roomMembersProvider(widget.roomId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Room avatar and name header
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
                child: Text(
                  widget.roomName.isNotEmpty
                      ? widget.roomName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.roomName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              membersAsync.when(
                data: (members) => Text(
                  '${members.length} ${members.length == 1 ? 'member' : 'members'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Room info section
        _buildSectionHeader('Room Information'),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, _) {
            final roomAsync = ref.watch(roomByIdProvider(widget.roomId));
            final roomType = roomAsync.when(
              data: (room) {
                switch (room?.type) {
                  case 'direct':
                    return 'Direct Message';
                  case 'group':
                    return 'Group Chat';
                  case 'channel':
                    return 'Channel';
                  default:
                    return room?.type ?? 'Chat';
                }
              },
              loading: () => 'Loading...',
              error: (_, _) => 'Unknown',
            );
            return _buildInfoTile(
              icon: Icons.group,
              title: 'Room Type',
              subtitle: roomType,
            );
          },
        ),
        const SizedBox(height: 24),

        // Members section
        _buildSectionHeader('Members'),
        const SizedBox(height: 8),
        _buildMembersList(membersAsync),
      ],
    );
  }

  Widget _buildMotionsTab() {
    final motionsAsync = ref.watch(activeMotionsProvider(widget.roomId));

    return motionsAsync.when(
      data: (motions) {
        if (motions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.how_to_vote,
            title: 'No active motions',
            subtitle: 'Admins can create motions for voting',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: motions.length,
          itemBuilder: (context, index) {
            final motion = motions[index];
            final content = motion.content;
            final title = content['title'] ?? 'Motion';
            final description = content['description'] ?? '';
            final deadline = content['deadline'] != null
                ? DateTime.fromMillisecondsSinceEpoch(
                    content['deadline'] as int,
                  )
                : null;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.how_to_vote)),
                title: Text(title.toString()),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (description.toString().isNotEmpty)
                      Text(
                        description.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (deadline != null)
                      Text(
                        'Ends: ${_formatDate(deadline)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
                isThreeLine: description.toString().isNotEmpty,
                onTap: () {
                  // Navigate to motion details
                  _showMotionDetails(context, motion.content);
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading motions: $e')),
    );
  }

  Widget _buildTransactionsTab() {
    final transactionsAsync = ref.watch(
      roomTransactionsProvider(widget.roomId),
    );

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.account_balance,
            title: 'No transactions yet',
            subtitle: 'Group transactions will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final content = transaction.content;
            final amount = content['amount'] ?? 0;
            final currency = content['currency'] ?? 'KES';
            final description = content['description'] ?? 'Transaction';
            final transactionType = content['type'] ?? 'payment';

            final isCredit =
                transactionType == 'deposit' || transactionType == 'credit';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCredit
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  child: Icon(
                    isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isCredit ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(description.toString()),
                subtitle: Text(
                  _formatDate(
                    DateTime.fromMillisecondsSinceEpoch(transaction.createdAt),
                  ),
                ),
                trailing: Text(
                  '${isCredit ? '+' : '-'}$currency $amount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCredit ? Colors.green : Colors.red,
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading transactions: $e')),
    );
  }

  Widget _buildMediaTab() {
    final mediaAsync = ref.watch(roomMediaProvider(widget.roomId));

    return mediaAsync.when(
      data: (mediaList) {
        if (mediaList.isEmpty) {
          return _buildEmptyState(
            icon: Icons.photo_library,
            title: 'No shared media',
            subtitle: 'Photos and videos shared in chat will appear here',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: mediaList.length,
          itemBuilder: (context, index) {
            final media = mediaList[index];
            final content = media.content;
            final isVideo = media.type == RoomEventType.video;
            final thumbnailUrl =
                content['thumbnailUrl'] as String? ?? content['url'] as String?;

            return GestureDetector(
              onTap: () => _openMediaViewer(context, mediaList, index),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail
                    if (thumbnailUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            isVideo ? Icons.videocam : Icons.image,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    else
                      Icon(
                        isVideo ? Icons.videocam : Icons.image,
                        color: Colors.grey,
                      ),
                    // Video indicator
                    if (isVideo)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading media: $e')),
    );
  }

  void _openMediaViewer(
    BuildContext context,
    List<RoomEvent> mediaList,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _MediaViewerScreen(
          mediaList: mediaList,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    ),
  );

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) => ListTile(
    leading: Icon(icon, size: 20),
    title: Text(title, style: const TextStyle(fontSize: 14)),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  );

  Widget _buildMembersList(
    AsyncValue<List<RoomSubscriptionInfo>> membersAsync,
  ) => membersAsync.when(
    data: (members) {
      if (members.isEmpty) {
        return const Text('No members found');
      }

      return Column(
        children: members.map((member) {
          final color = _getColorForName(member.name);
          final isAdmin = member.role.toLowerCase() == 'admin';

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    member.name,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(member.role, style: const TextStyle(fontSize: 12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            onTap: () => _openMemberProfile(context, member),
          );
        }).toList(),
      );
    },
    loading: () => const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
    ),
    error: (e, _) => Text('Error loading members: $e'),
  );

  void _openMemberProfile(BuildContext context, RoomSubscriptionInfo member) {
    // Show member action sheet with admin controls
    showMemberActionSheet(
      context: context,
      roomId: widget.roomId,
      member: member,
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Color _getColorForName(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];
    final index = name.isEmpty ? 0 : name.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateFromValue(value) {
    if (value is DateTime) return _formatDate(value);
    if (value is int) {
      return _formatDate(DateTime.fromMillisecondsSinceEpoch(value));
    }
    return 'N/A';
  }

  Future<void> _leaveRoom(BuildContext context, WidgetRef ref) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Leaving room...')));

      // Leave room (marks as left locally, queues for server sync)
      final service = await ref.read(roomServiceProvider.future);
      await service.leaveRoom(widget.roomId);

      // Navigate back to room list
      if (context.mounted) {
        context.navigateBack('/');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave room: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMotionDetails(BuildContext context, Map<String, dynamic> motion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Motion Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${motion['title'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Description: ${motion['description'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Created: ${_formatDateFromValue(motion['createdAt'])}'),
            if (motion['deadline'] != null) ...[
              const SizedBox(height: 8),
              Text('Deadline: ${_formatDateFromValue(motion['deadline'])}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Full-screen media viewer with swipe navigation
class _MediaViewerScreen extends StatefulWidget {
  const _MediaViewerScreen({
    required this.mediaList,
    required this.initialIndex,
  });
  final List<RoomEvent> mediaList;
  final int initialIndex;

  @override
  State<_MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<_MediaViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text('${_currentIndex + 1} of ${widget.mediaList.length}'),
    ),
    body: PageView.builder(
      controller: _pageController,
      itemCount: widget.mediaList.length,
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
      },
      itemBuilder: (context, index) {
        final media = widget.mediaList[index];
        final content = media.content;
        final url = content['url'] as String?;
        final isVideo = media.type == RoomEventType.video;

        if (url == null) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
          );
        }

        if (isVideo) {
          // Show video placeholder with play button
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Video playback',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          );
        }

        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Center(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.white,
                  ),
                );
              },
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.broken_image, color: Colors.white54),
            ),
          ),
        );
      },
    ),
  );
}
