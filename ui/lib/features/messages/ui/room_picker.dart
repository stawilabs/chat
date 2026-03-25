import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../rooms/data/room_providers.dart';
import '../../rooms/domain/room_with_last_message.dart';
import '../data/message_forwarding_service.dart';

/// A multi-select room picker for forwarding messages
///
/// Allows users to select up to [maxForwardDestinations] rooms
/// to forward a message to.
class RoomPicker extends ConsumerStatefulWidget {
  const RoomPicker({
    required this.onSelectionChanged,
    this.excludeRoomIds = const [],
    this.maxSelections = maxForwardDestinations,
    this.initialSelection = const [],
    super.key,
  });

  /// Callback when selection changes
  final void Function(List<String> selectedRoomIds) onSelectionChanged;

  /// Room IDs to exclude from the list (e.g., current room)
  final List<String> excludeRoomIds;

  /// Maximum number of rooms that can be selected
  final int maxSelections;

  /// Initially selected room IDs
  final List<String> initialSelection;

  @override
  ConsumerState<RoomPicker> createState() => _RoomPickerState();
}

class _RoomPickerState extends ConsumerState<RoomPicker> {
  final Set<String> _selectedRoomIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedRoomIds.addAll(widget.initialSelection);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleRoom(String roomId) {
    setState(() {
      if (_selectedRoomIds.contains(roomId)) {
        _selectedRoomIds.remove(roomId);
      } else if (_selectedRoomIds.length < widget.maxSelections) {
        _selectedRoomIds.add(roomId);
      }
    });
    widget.onSelectionChanged(_selectedRoomIds.toList());
  }

  List<RoomWithLastMessage> _filterRooms(List<RoomWithLastMessage> rooms) {
    // Filter out excluded rooms
    var filtered = rooms
        .where((room) => !widget.excludeRoomIds.contains(room.id))
        .toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((room) => room.name.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roomsAsync = ref.watch(roomListWithMessagesProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search chats...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),

        // Selection count indicator
        if (_selectedRoomIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_selectedRoomIds.length} of ${widget.maxSelections} selected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Room list
        Expanded(
          child: roomsAsync.when(
            data: (rooms) {
              final filteredRooms = _filterRooms(rooms);

              if (filteredRooms.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchQuery.isNotEmpty
                            ? Icons.search_off
                            : Icons.chat_bubble_outline,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No chats match "$_searchQuery"'
                            : 'No chats available',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredRooms.length,
                itemBuilder: (context, index) {
                  final room = filteredRooms[index];
                  final isSelected = _selectedRoomIds.contains(room.id);
                  final canSelect =
                      _selectedRoomIds.length < widget.maxSelections ||
                      isSelected;

                  return _RoomPickerTile(
                    room: room,
                    isSelected: isSelected,
                    canSelect: canSelect,
                    onTap: () => _toggleRoom(room.id),
                  );
                },
              );
            },
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
                    'Failed to load chats',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.refresh(roomListWithMessagesProvider),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomPickerTile extends StatelessWidget {
  const _RoomPickerTile({
    required this.room,
    required this.isSelected,
    required this.canSelect,
    required this.onTap,
  });

  final RoomWithLastMessage room;
  final bool isSelected;
  final bool canSelect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: canSelect ? onTap : null,
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: isSelected
                ? AppTheme.primaryGreen
                : AppTheme.primaryGreen.withValues(alpha: 0.7),
            child: Text(
              room.name.isNotEmpty ? room.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
      title: Text(
        room.name,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: canSelect
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      subtitle: room.lastMessageText != null
          ? Text(
              room.lastMessageText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: canSelect
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            )
          : null,
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen)
          : canSelect
          ? Icon(Icons.circle_outlined, color: theme.colorScheme.outline)
          : Icon(
              Icons.circle_outlined,
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
    );
  }
}
