import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/navigation_helper.dart';
import '../../messages/domain/room_event.dart';
import '../../notifications/mute_service.dart';
import '../data/detail_panel_providers.dart';
import '../data/room_providers.dart';
import '../data/room_service.dart';
import '../domain/room.dart';
import 'member_action_sheet.dart';

/// Whether a room of [type] offers group actions (Stawi, Add Members): not a
/// DM or a bot room, whose members are fixed and which are never converted,
/// and not a room whose type is not known yet.
bool offersGroupActions(String? type) =>
    type != null && type != 'direct' && type != 'bot';

/// Room detail panel showing room information and media
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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Kept loaded: the settings sheet offers group actions by its type.
    ref.watch(roomByIdProvider(widget.roomId));

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
            Tab(text: 'Media', icon: Icon(Icons.photo_library, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildInfoTab(), _buildMediaTab()],
      ),
    );
  }

  void _showSettingsMenu(BuildContext context) {
    final muteStateAsync = ref.watch(roomMuteStateProvider(widget.roomId));
    final roomType = ref
        .read(roomByIdProvider(widget.roomId))
        .asData
        ?.value
        ?.type;
    final grouped = offersGroupActions(roomType);

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
            // A DM's and a bot's members are fixed and neither is ever
            // converted: the server refuses both, so neither is offered.
            if (grouped)
              ListTile(
                key: const Key('room-settings-stawi'),
                leading: const Icon(Icons.savings_outlined),
                title: const Text('Stawi'),
                subtitle: const Text('Savings room on chain'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.navigateToStawiRoom(
                    roomId: widget.roomId,
                    roomName: widget.roomName,
                  );
                },
              ),
            if (grouped)
              ListTile(
                key: const Key('room-settings-add-members'),
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
                backgroundColor: Theme.of(context).colorScheme.primary
                    .withValues(alpha: 0.2),
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
                      color: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.1),
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

  Future<void> _leaveRoom(BuildContext context, WidgetRef ref) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Leaving room...')));

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
