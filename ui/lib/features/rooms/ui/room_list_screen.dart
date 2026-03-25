import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_error.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/responsive/three_panel_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/skeleton_loader.dart';
import '../../calls/ui/incoming_call_banner.dart';
import '../../messages/ui/chat_screen.dart';
import '../../notifications/mute_service.dart';
import '../data/room_providers.dart';
import '../data/room_search_providers.dart';
import '../data/room_service.dart';
import '../domain/room.dart';
import '../domain/room_with_last_message.dart';
import 'chat_list_item.dart';
import 'new_chat_screen.dart';
import 'room_detail_panel.dart';
import 'room_list_tile.dart';
import 'room_search_bar.dart';
import 'search_empty_state.dart';

class RoomListScreen extends ConsumerStatefulWidget {
  const RoomListScreen({super.key});

  @override
  ConsumerState<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends ConsumerState<RoomListScreen> {
  String? _selectedRoomId;
  String? _selectedRoomName;
  bool _isMultiSelectMode = false;
  final Set<String> _selectedRoomIds = <String>{};

  void _handleMenuAction(String action) {
    switch (action) {
      case 'settings':
        context.go('/settings');
        break;
      case 'select_multiple':
        _toggleMultiSelectMode();
        break;
      case 'mark_all_read':
        _markAllAsRead();
        break;
    }
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedRoomIds.clear();
      }
    });
  }

  Future<void> _markAllAsRead() async {
    final rooms = ref.read(roomListWithMessagesProvider).value ?? [];
    final unreadRooms = rooms.where((room) => room.unreadCount > 0).toList();

    if (unreadRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No unread messages'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final roomRepo = ref.read(roomRepositoryProvider);

      // Mark all rooms as read
      for (final room in unreadRooms) {
        await roomRepo.updateUnreadCount(room.id, 0);
      }

      // Refresh the room list to show updated counts
      ref.read(roomListWithMessagesProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Marked ${unreadRooms.length} conversation${unreadRooms.length == 1 ? '' : 's'} as read',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark messages as read: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _archiveRoom(RoomWithLastMessage room) {
    _showArchiveConfirmationDialog(room);
  }

  void _showArchiveConfirmationDialog(RoomWithLastMessage room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Chat'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to archive this chat?'),
            SizedBox(height: 8),
            Text('Archived chats can be found in the archived section.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performArchiveAction(room);
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  Future<void> _performArchiveAction(RoomWithLastMessage room) async {
    try {
      await ref
          .read(roomListProvider.notifier)
          .updateRoom(roomId: room.id, metadata: {'archived': true});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${room.name} archived'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                await ref
                    .read(roomListProvider.notifier)
                    .updateRoom(roomId: room.id, metadata: {'archived': false});
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to archive: $e')));
      }
    }
  }

  Future<void> _deleteSelectedRooms() async {
    final count = _selectedRoomIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chats'),
        content: Text(
          'Are you sure you want to delete $count chat${count == 1 ? '' : 's'}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      for (final roomId in _selectedRoomIds.toList()) {
        await ref.read(roomListProvider.notifier).deleteRoom(roomId);
      }
      _toggleMultiSelectMode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted $count chat${count == 1 ? '' : 's'}'),
          ),
        );
      }
    }
  }

  Future<void> _markSelectedAsRead() async {
    final roomRepo = ref.read(roomRepositoryProvider);
    for (final roomId in _selectedRoomIds) {
      await roomRepo.updateUnreadCount(roomId, 0);
    }
    ref.read(roomListWithMessagesProvider.notifier).refresh();
    _toggleMultiSelectMode();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Marked as read')));
    }
  }

  Future<void> _muteSelectedRooms() async {
    final muteService = ref.read(muteServiceProvider);
    for (final roomId in _selectedRoomIds) {
      await muteService.muteRoom(roomId, MuteDuration.forever);
    }
    ref.invalidate(roomListWithMessagesProvider);
    _toggleMultiSelectMode();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Muted selected chats')));
    }
  }

  void _clearSearch() {
    ref.read(roomSearchProvider.notifier).clearAll();
  }

  void _navigateToNewChat() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NewChatScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomListWithMessagesProvider);
    final filteredRoomsAsync = ref.watch(filteredRoomsProvider);
    final searchState = ref.watch(roomSearchProvider);
    final width = MediaQuery.of(context).size.width;
    final showDetailPanel = AppBreakpoints.showDetailPanel(width);

    return ResponsiveLayout(
      mobileLayout: _buildMobileLayout(
        roomsAsync,
        filteredRoomsAsync,
        searchState,
      ),
      tabletLayout: _buildTabletLayout(
        roomsAsync,
        filteredRoomsAsync,
        searchState,
      ),
      desktopLayout: _buildDesktopLayout(
        roomsAsync,
        filteredRoomsAsync,
        searchState,
        showDetailPanel,
      ),
    );
  }

  /// Mobile layout: Single-pane with stack navigation
  Widget _buildMobileLayout(
    AsyncValue<List<RoomWithLastMessage>> roomsAsync,
    AsyncValue<List<RoomWithLastMessage>> filteredRoomsAsync,
    RoomSearchState searchState,
  ) => Scaffold(
    body: CustomScrollView(
      slivers: [
        // Seamless app bar — matches scaffold background
        SliverAppBar(
          pinned: true,
          backgroundColor: _isMultiSelectMode
              ? AppTheme.primaryGreen
              : Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: _isMultiSelectMode
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
          scrolledUnderElevation: 0,
          elevation: 0,
          centerTitle: false,
          leading: _isMultiSelectMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _toggleMultiSelectMode,
                )
              : null,
          title: _isMultiSelectMode
              ? Text('${_selectedRoomIds.length} selected')
              : Text(
                  'Chats',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
          actions: _isMultiSelectMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete selected',
                    onPressed: _selectedRoomIds.isEmpty
                        ? null
                        : _deleteSelectedRooms,
                  ),
                  IconButton(
                    icon: const Icon(Icons.mark_email_read_outlined),
                    tooltip: 'Mark as read',
                    onPressed: _selectedRoomIds.isEmpty
                        ? null
                        : _markSelectedAsRead,
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_off_outlined),
                    tooltip: 'Mute selected',
                    onPressed: _selectedRoomIds.isEmpty
                        ? null
                        : _muteSelectedRooms,
                  ),
                ]
              : [
                  // More options menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onSelected: _handleMenuAction,
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'settings',
                        child: Text('Settings'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'select_multiple',
                        child: Text('Select Multiple'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'mark_all_read',
                        child: Text('Mark All Read'),
                      ),
                    ],
                  ),
                ],
        ),

        // Always-visible search bar and filter chips
        const SliverToBoxAdapter(child: RoomSearchBar()),

        // Call banner
        const SliverToBoxAdapter(child: IncomingCallBanner()),

        // Chat list or empty state
        _buildMobileChatList(roomsAsync, filteredRoomsAsync, searchState),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _navigateToNewChat,
      backgroundColor: AppTheme.primaryGreen,
      child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
    ),
  );

  /// Build the chat list for mobile layout
  Widget _buildMobileChatList(
    AsyncValue<List<RoomWithLastMessage>> roomsAsync,
    AsyncValue<List<RoomWithLastMessage>> filteredRoomsAsync,
    RoomSearchState searchState,
  ) {
    return roomsAsync.when(
      data: (allRooms) {
        // Get filtered rooms
        final filteredRooms = filteredRoomsAsync.value ?? allRooms;

        // Show empty state when no rooms exist
        if (allRooms.isEmpty) {
          return SliverFillRemaining(
            child: EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'No conversations yet',
              message: 'Start a new conversation to begin chatting',
              actionLabel: 'New Chat',
              onAction: _navigateToNewChat,
            ),
          );
        }

        // Show search empty state when filtering returns no results
        if (filteredRooms.isEmpty && searchState.isFiltering) {
          return SliverFillRemaining(
            child: SearchEmptyState(
              searchState: searchState,
              onClearSearch: _clearSearch,
            ),
          );
        }

        // Show the list of rooms
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index >= filteredRooms.length) {
              return null;
            }

            final room = filteredRooms[index];
            return Dismissible(
              key: ValueKey(room.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.blue,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.archive, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  _archiveRoom(room);
                }
                return false; // Don't remove from list; archive handles it
              },
              child: RepaintBoundary(
                key: ValueKey(room.id),
                child: ChatListItem(
                  room: room,
                  onTap: () {
                    if (_isMultiSelectMode) {
                      setState(() {
                        if (_selectedRoomIds.contains(room.id)) {
                          _selectedRoomIds.remove(room.id);
                        } else {
                          _selectedRoomIds.add(room.id);
                        }
                      });
                    } else {
                      // Navigate to chat screen for mobile layout
                      context.go(
                        '/chat/${room.id}?name=${Uri.encodeComponent(room.name)}',
                      );
                    }
                  },
                  isSelected: _selectedRoomIds.contains(room.id),
                  isMultiSelectMode: _isMultiSelectMode,
                  onLongPress: () {
                    _toggleMultiSelectMode();
                    setState(() {
                      _selectedRoomIds.add(room.id);
                    });
                  },
                  onSelectionChanged: (isSelected) {
                    setState(() {
                      if (isSelected) {
                        _selectedRoomIds.add(room.id);
                      } else {
                        _selectedRoomIds.remove(room.id);
                      }
                    });
                  },
                ),
              ),
            );
          }, childCount: filteredRooms.length),
        );
      },
      loading: () => SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => const RoomListSkeleton(),
          childCount: 10,
        ),
      ),
      error: (error, stack) {
        final appError = AppError.fromException(error, stack);
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ErrorBanner(
                  error: appError,
                  onRetry: () => ref.refresh(roomListWithMessagesProvider),
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load rooms',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Tablet layout: 2-panel (Rooms | Chat)
  Widget _buildTabletLayout(
    AsyncValue<List<RoomWithLastMessage>> roomsAsync,
    AsyncValue<List<RoomWithLastMessage>> filteredRoomsAsync,
    RoomSearchState searchState,
  ) => Scaffold(
    body: Stack(
      children: [
        Column(
          children: [
            const IncomingCallBanner(),
            Expanded(
              child: ThreePanelLayout(
                leftPanel: _buildRoomListPanel(
                  roomsAsync,
                  filteredRoomsAsync,
                  searchState,
                ),
                centerPanel: _buildChatPanel(),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  /// Desktop layout: 3-panel (Rooms | Chat | Details)
  Widget _buildDesktopLayout(
    AsyncValue<List<RoomWithLastMessage>> roomsAsync,
    AsyncValue<List<RoomWithLastMessage>> filteredRoomsAsync,
    RoomSearchState searchState,
    bool showDetailPanel,
  ) => Scaffold(
    body: Stack(
      children: [
        Column(
          children: [
            const IncomingCallBanner(),
            Expanded(
              child: ThreePanelLayout(
                leftPanel: _buildRoomListPanel(
                  roomsAsync,
                  filteredRoomsAsync,
                  searchState,
                ),
                centerPanel: _buildChatPanel(),
                rightPanel: showDetailPanel ? _buildDetailPanel() : null,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  /// Room list panel for tablet/desktop layouts
  Widget _buildRoomListPanel(
    AsyncValue<List<RoomWithLastMessage>> roomsAsync,
    AsyncValue<List<RoomWithLastMessage>> filteredRoomsAsync,
    RoomSearchState searchState,
  ) => Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      title: Text(
        'Chats',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ),
    drawer: const AppDrawer(),
    floatingActionButton: FloatingActionButton(
      onPressed: _navigateToNewChat,
      tooltip: 'New Chat',
      child: const Icon(Icons.chat_bubble_outline),
    ),
    body: Column(
      children: [
        // Always-visible search bar and filter chips
        const RoomSearchBar(),
        // Room list
        Expanded(
          child: _buildRoomList(
            roomsAsync,
            filteredRoomsAsync,
            searchState,
            isMobile: false,
          ),
        ),
      ],
    ),
  );

  /// Chat panel for tablet/desktop layouts
  Widget _buildChatPanel() {
    if (_selectedRoomId != null) {
      return ChatScreen(
        roomId: _selectedRoomId!,
        roomName: _selectedRoomName ?? 'Chat',
        key: ValueKey(_selectedRoomId),
      );
    } else {
      return const EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'Select a conversation',
        message: 'Choose a room from the list to start chatting',
      );
    }
  }

  /// Detail panel for desktop layout (room info, motions, transactions)
  Widget _buildDetailPanel() {
    if (_selectedRoomId != null && _selectedRoomName != null) {
      return RoomDetailPanel(
        roomId: _selectedRoomId!,
        roomName: _selectedRoomName!,
        key: ValueKey(_selectedRoomId),
      );
    } else {
      return const EmptyState(
        icon: Icons.info_outline,
        title: 'Room details',
        message: 'Select a room to view details',
      );
    }
  }

  Widget _buildRoomList(
    AsyncValue<List<RoomWithLastMessage>> roomsAsync,
    AsyncValue<List<RoomWithLastMessage>> filteredRoomsAsync,
    RoomSearchState searchState, {
    required bool isMobile,
  }) => Column(
    children: [
      Expanded(
        child: roomsAsync.when(
          data: (allRooms) {
            // Get filtered rooms
            final filteredRooms = filteredRoomsAsync.value ?? allRooms;

            // Show empty state when no rooms exist
            if (allRooms.isEmpty) {
              return EmptyState(
                icon: Icons.chat_bubble_outline,
                title: 'No conversations yet',
                message: 'Start a new conversation to begin chatting',
                actionLabel: 'New Chat',
                onAction: _navigateToNewChat,
              );
            }

            // Show search empty state when filtering returns no results
            if (filteredRooms.isEmpty && searchState.isFiltering) {
              return SearchEmptyState(
                searchState: searchState,
                onClearSearch: _clearSearch,
              );
            }

            return ListView.builder(
              itemCount: filteredRooms.length,
              itemBuilder: (context, index) {
                final room = filteredRooms[index];
                final isSelected = !isMobile && room.id == _selectedRoomId;

                return Container(
                  color: isSelected
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : null,
                  child: RoomListTile(
                    room: room,
                    onTap: () {
                      if (isMobile) {
                        // Navigate to chat screen
                        context.go(
                          '/chat/${room.id}?name=${Uri.encodeComponent(room.name)}',
                        );
                      } else {
                        // Update selected room for tablet/desktop
                        setState(() {
                          _selectedRoomId = room.id;
                          _selectedRoomName = room.name;
                        });
                      }
                    },
                  ),
                );
              },
            );
          },
          loading: () => ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) => const RoomListSkeleton(),
          ),
          error: (error, stack) {
            final appError = AppError.fromException(error, stack);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ErrorBanner(
                    error: appError,
                    onRetry: () => ref.refresh(roomListWithMessagesProvider),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load rooms',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}
