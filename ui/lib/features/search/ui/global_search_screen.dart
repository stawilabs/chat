import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../contacts/data/roster_repository.dart';
import '../../rooms/domain/room_with_last_message.dart';
import '../data/global_search_service.dart';
import '../domain/search_result.dart';

/// Global search screen with tabbed results
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late TabController _tabController;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tabController = TabController(
      length: SearchTab.values.length,
      vsync: this,
    );
    _searchFocusNode = FocusNode();

    // Sync tab controller with state
    _tabController.addListener(_onTabChanged);

    // Auto-focus search on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      ref
          .read(globalSearchProvider.notifier)
          .setActiveTab(SearchTab.values[_tabController.index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(globalSearchProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _buildSearchField(theme),
        bottom: searchState.hasSearched
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _buildTabBar(theme, searchState),
              )
            : null,
      ),
      body: searchState.query.isEmpty
          ? _buildRecentSearches(theme, searchState)
          : searchState.isSearching
          ? const Center(child: CircularProgressIndicator())
          : _buildSearchResults(theme, searchState),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        hintText: 'Search messages, chats, contacts...',
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  ref.read(globalSearchProvider.notifier).clearSearch();
                },
              )
            : null,
      ),
      onChanged: (value) {
        ref.read(globalSearchProvider.notifier).updateQuery(value);
      },
      onSubmitted: (value) {
        if (value.isNotEmpty) {
          ref.read(globalSearchProvider.notifier).addToRecentSearches(value);
        }
      },
      textInputAction: TextInputAction.search,
    );
  }

  Widget _buildTabBar(ThemeData theme, GlobalSearchState state) {
    return TabBar(
      controller: _tabController,
      tabs: SearchTab.values.map((tab) {
        final count = state.getTabCount(tab);
        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tab.displayName),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
      isScrollable: true,
      tabAlignment: TabAlignment.start,
    );
  }

  Widget _buildRecentSearches(ThemeData theme, GlobalSearchState state) {
    if (state.recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Search messages, chats, and contacts',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(globalSearchProvider.notifier).clearRecentSearches();
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: state.recentSearches.length,
            itemBuilder: (context, index) {
              final query = state.recentSearches[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(query),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    ref
                        .read(globalSearchProvider.notifier)
                        .removeFromRecentSearches(query);
                  },
                ),
                onTap: () {
                  _searchController.text = query;
                  ref.read(globalSearchProvider.notifier).updateQuery(query);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(ThemeData theme, GlobalSearchState state) {
    if (state.hasNoResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "${state.query}"',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllResults(theme, state),
        _buildMessageResults(theme, state.messageResults),
        _buildChatResults(theme, state.roomResults),
        _buildContactResults(theme, state.contactResults),
      ],
    );
  }

  Widget _buildAllResults(ThemeData theme, GlobalSearchState state) {
    return ListView(
      children: [
        // Messages section
        if (state.messageResults.isNotEmpty) ...[
          _buildSectionHeader(theme, 'Messages', state.messageResults.length),
          ...state.messageResults
              .take(3)
              .map((result) => _buildMessageResultTile(theme, result)),
          if (state.messageResults.length > 3)
            ListTile(
              title: Text(
                'See all ${state.messageResults.length} messages',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _tabController.animateTo(1),
            ),
        ],

        // Chats section
        if (state.roomResults.isNotEmpty) ...[
          _buildSectionHeader(theme, 'Chats', state.roomResults.length),
          ...state.roomResults
              .take(3)
              .map((room) => _buildRoomResultTile(theme, room)),
          if (state.roomResults.length > 3)
            ListTile(
              title: Text(
                'See all ${state.roomResults.length} chats',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _tabController.animateTo(2),
            ),
        ],

        // Contacts section
        if (state.contactResults.isNotEmpty) ...[
          _buildSectionHeader(theme, 'Contacts', state.contactResults.length),
          ...state.contactResults
              .take(3)
              .map((contact) => _buildContactResultTile(theme, contact)),
          if (state.contactResults.length > 3)
            ListTile(
              title: Text(
                'See all ${state.contactResults.length} contacts',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _tabController.animateTo(3),
            ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        '$title ($count)',
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMessageResults(
    ThemeData theme,
    List<MessageSearchResult> results,
  ) {
    if (results.isEmpty) {
      return _buildEmptyState(theme, 'No messages found');
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) =>
          _buildMessageResultTile(theme, results[index]),
    );
  }

  Widget _buildChatResults(ThemeData theme, List<RoomWithLastMessage> results) {
    if (results.isEmpty) {
      return _buildEmptyState(theme, 'No chats found');
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) =>
          _buildRoomResultTile(theme, results[index]),
    );
  }

  Widget _buildContactResults(ThemeData theme, List<RosterEntry> results) {
    if (results.isEmpty) {
      return _buildEmptyState(theme, 'No contacts found');
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) =>
          _buildContactResultTile(theme, results[index]),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String message) {
    return Center(
      child: Text(
        message,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildMessageResultTile(ThemeData theme, MessageSearchResult result) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(
          Icons.message,
          color: theme.colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(result.roomName),
      subtitle: _buildHighlightedText(theme, result.getExcerpt(), result.query),
      trailing: Text(
        result.formattedTimestamp,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: () {
        ref
            .read(globalSearchProvider.notifier)
            .addToRecentSearches(result.query);
        context.push('/room/${result.roomId}');
      },
    );
  }

  Widget _buildRoomResultTile(ThemeData theme, RoomWithLastMessage room) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Text(
          room.name.isNotEmpty ? room.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(room.name),
      subtitle: room.lastMessageText != null
          ? Text(
              room.lastMessageText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: room.unreadCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                room.unreadCount.toString(),
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            )
          : null,
      onTap: () {
        final state = ref.read(globalSearchProvider);
        ref
            .read(globalSearchProvider.notifier)
            .addToRecentSearches(state.query);
        context.push('/room/${room.id}');
      },
    );
  }

  Widget _buildContactResultTile(ThemeData theme, RosterEntry contact) {
    final displayName = contact.displayName ?? contact.contactDetail;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.tertiaryContainer,
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.colorScheme.onTertiaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(displayName),
      subtitle: Text(contact.contactDetail, style: theme.textTheme.bodySmall),
      trailing: Icon(
        contact.contactType == RosterContactType.msisdn
            ? Icons.phone
            : Icons.email,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: () {
        final state = ref.read(globalSearchProvider);
        ref
            .read(globalSearchProvider.notifier)
            .addToRecentSearches(state.query);
        // Navigate to chat if contact is on platform, otherwise show options
        if (contact.profileId != null) {
          final name = contact.displayName ?? contact.contactDetail;
          context.push(
            '/chat/${contact.profileId}?name=${Uri.encodeComponent(name)}',
          );
        } else {
          _showContactOptions(context, contact);
        }
      },
    );
  }

  Widget _buildHighlightedText(ThemeData theme, String text, String query) {
    if (query.isEmpty) {
      return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis);
    }

    final spans = <TextSpan>[];
    final textLower = text.toLowerCase();
    final queryLower = query.toLowerCase();

    var start = 0;
    while (true) {
      final index = textLower.indexOf(queryLower, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            backgroundColor: theme.colorScheme.primaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        children: spans,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _showContactOptions(BuildContext context, RosterEntry contact) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Invite to App'),
              onTap: () {
                Navigator.pop(context);
                SharePlus.instance.share(
                  ShareParams(
                    text:
                        'Join me on Stawi! Download the app: https://stawi.org/invite',
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View Details'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
