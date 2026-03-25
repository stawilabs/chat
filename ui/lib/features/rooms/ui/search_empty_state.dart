import 'package:flutter/material.dart';

import '../data/room_search_providers.dart';

/// Empty state widget for when search/filter returns no results
class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({
    required this.searchState,
    super.key,
    this.onClearSearch,
  });

  final RoomSearchState searchState;
  final VoidCallback? onClearSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String title;
    final String message;
    final IconData icon;

    if (searchState.hasActiveSearch) {
      // No results for search query
      title = 'No chats found';
      message = 'No chats match "${searchState.query}"';
      icon = Icons.search_off;
    } else {
      // No results for filter
      switch (searchState.filterType) {
        case RoomFilterType.groups:
          title = 'No group chats';
          message = 'You have no group conversations yet';
          icon = Icons.group_off_outlined;
        case RoomFilterType.direct:
          title = 'No direct chats';
          message = 'You have no direct conversations yet';
          icon = Icons.person_off_outlined;
        case RoomFilterType.unread:
          title = 'All caught up!';
          message = 'You have no unread messages';
          icon = Icons.mark_chat_read_outlined;
        case RoomFilterType.all:
          title = 'No conversations';
          message = 'Start a new chat to begin messaging';
          icon = Icons.chat_bubble_outline;
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (searchState.isFiltering && onClearSearch != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onClearSearch,
                icon: const Icon(Icons.clear),
                label: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
