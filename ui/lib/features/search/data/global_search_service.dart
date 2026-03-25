import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/db/database.dart';
import '../../../core/logging/app_logger.dart';
import '../../contacts/data/roster_repository.dart';
import '../../rooms/data/room_providers.dart';
import '../../rooms/domain/room_with_last_message.dart';
import '../domain/search_result.dart';

part 'global_search_service.g.dart';

/// Search debounce duration
const kGlobalSearchDebounceMs = 300;

/// Maximum number of results per category
const kMaxResultsPerCategory = 20;

/// Maximum recent searches to store
const kMaxRecentSearches = 10;

/// SharedPreferences key for recent searches
const kRecentSearchesKey = 'global_search_recent_searches';

// ============================================================================
// Search Tab Enum
// ============================================================================

/// Tabs for global search results
enum SearchTab { all, messages, chats, contacts }

extension SearchTabExtension on SearchTab {
  String get displayName {
    switch (this) {
      case SearchTab.all:
        return 'All';
      case SearchTab.messages:
        return 'Messages';
      case SearchTab.chats:
        return 'Chats';
      case SearchTab.contacts:
        return 'Contacts';
    }
  }
}

// ============================================================================
// Global Search State
// ============================================================================

/// State for global search
class GlobalSearchState {
  const GlobalSearchState({
    this.query = '',
    this.activeTab = SearchTab.all,
    this.isSearching = false,
    this.hasSearched = false,
    this.messageResults = const [],
    this.roomResults = const [],
    this.contactResults = const [],
    this.recentSearches = const [],
    this.error,
  });

  final String query;
  final SearchTab activeTab;
  final bool isSearching;
  final bool hasSearched;
  final List<MessageSearchResult> messageResults;
  final List<RoomWithLastMessage> roomResults;
  final List<RosterEntry> contactResults;
  final List<String> recentSearches;
  final String? error;

  GlobalSearchState copyWith({
    String? query,
    SearchTab? activeTab,
    bool? isSearching,
    bool? hasSearched,
    List<MessageSearchResult>? messageResults,
    List<RoomWithLastMessage>? roomResults,
    List<RosterEntry>? contactResults,
    List<String>? recentSearches,
    String? error,
  }) => GlobalSearchState(
    query: query ?? this.query,
    activeTab: activeTab ?? this.activeTab,
    isSearching: isSearching ?? this.isSearching,
    hasSearched: hasSearched ?? this.hasSearched,
    messageResults: messageResults ?? this.messageResults,
    roomResults: roomResults ?? this.roomResults,
    contactResults: contactResults ?? this.contactResults,
    recentSearches: recentSearches ?? this.recentSearches,
    error: error,
  );

  /// Total result count
  int get totalCount =>
      messageResults.length + roomResults.length + contactResults.length;

  /// Check if there are any results
  bool get hasResults => totalCount > 0;

  /// Check if search is empty after searching
  bool get hasNoResults => hasSearched && !hasResults && query.isNotEmpty;

  /// Get result count for a specific tab
  int getTabCount(SearchTab tab) {
    switch (tab) {
      case SearchTab.all:
        return totalCount;
      case SearchTab.messages:
        return messageResults.length;
      case SearchTab.chats:
        return roomResults.length;
      case SearchTab.contacts:
        return contactResults.length;
    }
  }
}

// ============================================================================
// Global Search Notifier
// ============================================================================

/// Notifier for global search functionality
@riverpod
class GlobalSearch extends _$GlobalSearch {
  Timer? _debounceTimer;

  @override
  GlobalSearchState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    // Load recent searches on init
    _loadRecentSearches();

    return const GlobalSearchState();
  }

  /// Update search query with debouncing
  void updateQuery(String query) {
    _debounceTimer?.cancel();

    state = state.copyWith(query: query, isSearching: query.isNotEmpty);

    if (query.isEmpty) {
      state = state.copyWith(
        messageResults: [],
        roomResults: [],
        contactResults: [],
        isSearching: false,
        hasSearched: false,
      );
      return;
    }

    _debounceTimer = Timer(
      const Duration(milliseconds: kGlobalSearchDebounceMs),
      () => _performSearch(query),
    );
  }

  /// Change active tab
  void setActiveTab(SearchTab tab) {
    state = state.copyWith(activeTab: tab);
  }

  /// Perform unified search across all categories
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    AppLogger.debug('[GlobalSearch] Performing search', data: {'query': query});

    try {
      // Run searches in parallel
      final results = await Future.wait([
        _searchMessages(query),
        _searchRooms(query),
        _searchContacts(query),
      ]);

      state = state.copyWith(
        messageResults: results[0] as List<MessageSearchResult>,
        roomResults: results[1] as List<RoomWithLastMessage>,
        contactResults: results[2] as List<RosterEntry>,
        isSearching: false,
        hasSearched: true,
      );

      AppLogger.debug(
        '[GlobalSearch] Search completed',
        data: {
          'query': query,
          'messages': state.messageResults.length,
          'rooms': state.roomResults.length,
          'contacts': state.contactResults.length,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '[GlobalSearch] Search failed',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isSearching: false,
        hasSearched: true,
        error: 'Search failed: ${e.toString()}',
      );
    }
  }

  /// Search messages in local database using FTS5 for efficient full-text search
  Future<List<MessageSearchResult>> _searchMessages(String query) async {
    try {
      final db = AppDatabase.instance;

      // Use the optimized FTS5 search method from the database
      final events = await db.searchMessages(
        query,
        limit: kMaxResultsPerCategory,
      );

      if (events.isEmpty) {
        return [];
      }

      // Fetch all necessary room data in a single query to avoid N+1
      final roomIds = events.map((e) => e.roomId).toSet();
      final rooms = await (db.select(
        db.rooms,
      )..where((r) => r.id.isIn(roomIds))).get();
      final roomsById = {for (final room in rooms) room.id: room};

      // Convert to search results with room info
      final results = <MessageSearchResult>[];
      for (final event in events) {
        final room = roomsById[event.roomId];

        if (room != null) {
          // Parse content JSON string to get text
          var text = '';
          try {
            final contentStr = event.content;
            if (contentStr == null || contentStr.isEmpty) continue;

            // Content is stored as JSON string, parse it
            final content = jsonDecode(contentStr) as Map<String, dynamic>?;
            if (content != null && content.containsKey('text')) {
              text = content['text']?.toString() ?? '';
            } else {
              continue; // Not a text message or no text content
            }
          } catch (_) {
            continue;
          }

          results.add(
            MessageSearchResult(
              messageId: event.id,
              roomId: event.roomId,
              roomName: room.name ?? 'Unknown',
              text: text,
              senderId: event.senderId,
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                event.createdAt ?? 0,
              ),
              query: query,
            ),
          );
        }
      }

      return results;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[GlobalSearch] Message search failed',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Search rooms
  Future<List<RoomWithLastMessage>> _searchRooms(String query) async {
    try {
      final roomsAsync = ref.read(roomListWithMessagesProvider);
      final rooms = roomsAsync.when(
        data: (data) => data,
        loading: () => <RoomWithLastMessage>[],
        error: (e, s) => <RoomWithLastMessage>[],
      );
      final queryLower = query.toLowerCase();

      return rooms
          .where(
            (room) =>
                room.name.toLowerCase().contains(queryLower) ||
                (room.lastMessageText?.toLowerCase().contains(queryLower) ??
                    false),
          )
          .take(kMaxResultsPerCategory)
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error(
        '[GlobalSearch] Room search failed',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Search contacts
  Future<List<RosterEntry>> _searchContacts(String query) async {
    try {
      final repository = await ref.read(rosterRepositoryProvider.future);
      final results = await repository.searchRoster(query);
      return results.take(kMaxResultsPerCategory).toList();
    } catch (e, stackTrace) {
      AppLogger.error(
        '[GlobalSearch] Contact search failed',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Add to recent searches
  Future<void> addToRecentSearches(String query) async {
    if (query.trim().isEmpty) return;

    final recent = List<String>.from(state.recentSearches);

    // Remove if already exists
    recent.remove(query);

    // Add to front
    recent.insert(0, query);

    // Trim to max size
    while (recent.length > kMaxRecentSearches) {
      recent.removeLast();
    }

    state = state.copyWith(recentSearches: recent);

    // Persist to preferences
    await _saveRecentSearches(recent);
  }

  /// Remove from recent searches
  Future<void> removeFromRecentSearches(String query) async {
    final recent = List<String>.from(state.recentSearches);
    recent.remove(query);
    state = state.copyWith(recentSearches: recent);
    await _saveRecentSearches(recent);
  }

  /// Clear all recent searches
  Future<void> clearRecentSearches() async {
    state = state.copyWith(recentSearches: []);
    await _saveRecentSearches([]);
  }

  /// Load recent searches from storage
  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searchesJson = prefs.getStringList(kRecentSearchesKey);

      if (searchesJson != null && searchesJson.isNotEmpty) {
        state = state.copyWith(recentSearches: searchesJson);
        AppLogger.debug(
          '[GlobalSearch] Loaded recent searches',
          data: {'count': searchesJson.length},
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '[GlobalSearch] Failed to load recent searches',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Save recent searches to storage
  Future<void> _saveRecentSearches(List<String> searches) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(kRecentSearchesKey, searches);

      AppLogger.debug(
        '[GlobalSearch] Saved recent searches',
        data: {'count': searches.length},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '[GlobalSearch] Failed to save recent searches',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clear search and reset state
  void clearSearch() {
    _debounceTimer?.cancel();
    state = GlobalSearchState(
      activeTab: state.activeTab,
      recentSearches: state.recentSearches,
    );
  }
}
