import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/room_providers.dart';
import '../data/room_search_providers.dart';

/// Search bar widget for filtering rooms
///
/// Features:
/// - Text search field with clear button
/// - Filter chips for All, Groups, Direct, Unread
/// - Real-time filtering as user types
class RoomSearchBar extends ConsumerStatefulWidget {
  const RoomSearchBar({super.key, this.onSearchChanged});

  /// Optional callback when search changes
  final ValueChanged<String>? onSearchChanged;

  @override
  ConsumerState<RoomSearchBar> createState() => _RoomSearchBarState();
}

class _RoomSearchBarState extends ConsumerState<RoomSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize controller with current search state
    final searchState = ref.read(roomSearchProvider);
    _searchController.text = searchState.query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(roomSearchProvider.notifier).setQuery(value);
    widget.onSearchChanged?.call(value);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(roomSearchProvider.notifier).clearQuery();
    widget.onSearchChanged?.call('');
    _focusNode.unfocus();
  }

  void _onFilterSelected(RoomFilterType filter) {
    ref.read(roomSearchProvider.notifier).setFilter(filter);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(roomSearchProvider);

    // Compute total unread count for the "Unread" chip label
    final roomsAsync = ref.watch(roomListWithMessagesProvider);
    final totalUnread =
        roomsAsync.whenOrNull(
          data: (rooms) =>
              rooms.fold<int>(0, (sum, room) => sum + room.unreadCount),
        ) ??
        0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search or start new chat...',
              prefixIcon: Icon(
                Icons.search,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              suffixIcon: searchState.hasActiveSearch
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                      tooltip: 'Clear search',
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
          ),
        ),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                isSelected: searchState.filterType == RoomFilterType.all,
                onSelected: () => _onFilterSelected(RoomFilterType.all),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Groups',
                isSelected: searchState.filterType == RoomFilterType.groups,
                onSelected: () => _onFilterSelected(RoomFilterType.groups),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Direct',
                isSelected: searchState.filterType == RoomFilterType.direct,
                onSelected: () => _onFilterSelected(RoomFilterType.direct),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: totalUnread > 0 ? 'Unread $totalUnread' : 'Unread',
                isSelected: searchState.filterType == RoomFilterType.unread,
                onSelected: () => _onFilterSelected(RoomFilterType.unread),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Individual filter chip widget — text-only, pill-shaped
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.transparent,
      selectedColor: AppTheme.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      checkmarkColor: Colors.white,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected
              ? AppTheme.primaryGreen
              : theme.colorScheme.outlineVariant,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// Compact search bar for use in app bar
class CompactRoomSearchBar extends ConsumerStatefulWidget {
  const CompactRoomSearchBar({super.key, this.onClose});

  /// Callback when search is closed
  final VoidCallback? onClose;

  @override
  ConsumerState<CompactRoomSearchBar> createState() =>
      _CompactRoomSearchBarState();
}

class _CompactRoomSearchBarState extends ConsumerState<CompactRoomSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final searchState = ref.read(roomSearchProvider);
    _searchController.text = searchState.query;
    // Auto-focus when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(roomSearchProvider.notifier).setQuery(value);
  }

  void _clearAndClose() {
    ref.read(roomSearchProvider.notifier).clearAll();
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(roomSearchProvider);

    return TextField(
      controller: _searchController,
      focusNode: _focusNode,
      onChanged: _onSearchChanged,
      style: TextStyle(color: theme.appBarTheme.foregroundColor),
      cursorColor: theme.appBarTheme.foregroundColor,
      decoration: InputDecoration(
        hintText: 'Search chats...',
        hintStyle: TextStyle(
          color: theme.appBarTheme.foregroundColor?.withValues(alpha: 0.6),
        ),
        border: InputBorder.none,
        suffixIcon: searchState.hasActiveSearch
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: theme.appBarTheme.foregroundColor,
                ),
                onPressed: () {
                  _searchController.clear();
                  ref.read(roomSearchProvider.notifier).clearQuery();
                },
              )
            : IconButton(
                icon: Icon(
                  Icons.close,
                  color: theme.appBarTheme.foregroundColor,
                ),
                onPressed: _clearAndClose,
              ),
      ),
    );
  }
}
