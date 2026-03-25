import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import 'roster_repository.dart';

part 'contact_search_provider.g.dart';

// ============================================================================
// Contact Search Constants
// ============================================================================

/// Debounce duration for search queries
const kSearchDebounceMs = 300;

/// Minimum query length to trigger search
const kMinSearchQueryLength = 1;

// ============================================================================
// Contact Sort Options
// ============================================================================

/// Sorting options for contact search results
enum ContactSortOption {
  /// Sort alphabetically by display name (A-Z)
  alphabeticalAsc,

  /// Sort alphabetically by display name (Z-A)
  alphabeticalDesc,

  /// Sort by most recently synced first
  recentFirst,

  /// Sort by contact type (phone numbers first)
  phoneFirst,

  /// Sort by contact type (emails first)
  emailFirst,
}

extension ContactSortOptionExtension on ContactSortOption {
  String get displayName {
    switch (this) {
      case ContactSortOption.alphabeticalAsc:
        return 'Name (A-Z)';
      case ContactSortOption.alphabeticalDesc:
        return 'Name (Z-A)';
      case ContactSortOption.recentFirst:
        return 'Recently Synced';
      case ContactSortOption.phoneFirst:
        return 'Phone Numbers First';
      case ContactSortOption.emailFirst:
        return 'Emails First';
    }
  }
}

// ============================================================================
// Contact Search State
// ============================================================================

/// State for contact search functionality
class ContactSearchState {
  const ContactSearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
    this.hasSearched = false,
    this.sortOption = ContactSortOption.alphabeticalAsc,
    this.error,
  });

  /// The current search query
  final String query;

  /// Search results
  final List<RosterEntry> results;

  /// Whether a search is currently in progress
  final bool isSearching;

  /// Whether a search has been performed (used for empty state distinction)
  final bool hasSearched;

  /// Current sort option
  final ContactSortOption sortOption;

  /// Error message if search failed
  final String? error;

  ContactSearchState copyWith({
    String? query,
    List<RosterEntry>? results,
    bool? isSearching,
    bool? hasSearched,
    ContactSortOption? sortOption,
    String? error,
  }) => ContactSearchState(
    query: query ?? this.query,
    results: results ?? this.results,
    isSearching: isSearching ?? this.isSearching,
    hasSearched: hasSearched ?? this.hasSearched,
    sortOption: sortOption ?? this.sortOption,
    error: error,
  );

  /// Check if there are no results after a search
  bool get hasNoResults => hasSearched && results.isEmpty && query.isNotEmpty;

  /// Check if search results are available
  bool get hasResults => results.isNotEmpty;
}

// ============================================================================
// Contact Search Notifier
// ============================================================================

/// Notifier for contact search with debouncing
@riverpod
class ContactSearch extends _$ContactSearch {
  Timer? _debounceTimer;

  @override
  ContactSearchState build() {
    // Cleanup timer when provider is disposed
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return const ContactSearchState();
  }

  /// Update search query with debouncing
  void updateQuery(String query) {
    // Cancel any pending search
    _debounceTimer?.cancel();

    // Update query immediately for UI feedback
    state = state.copyWith(query: query, isSearching: query.isNotEmpty);

    // If query is empty, clear results
    if (query.isEmpty) {
      state = state.copyWith(
        results: [],
        isSearching: false,
        hasSearched: false,
      );
      return;
    }

    // Debounce the actual search
    _debounceTimer = Timer(
      const Duration(milliseconds: kSearchDebounceMs),
      () => _performSearch(query),
    );
  }

  /// Perform the actual search
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    AppLogger.debug(
      '[ContactSearch] Performing search',
      data: {'query': query, 'sortOption': state.sortOption.name},
    );

    try {
      // Get the repository
      final repository = await ref.read(rosterRepositoryProvider.future);

      // Search local roster by name, phone, and email
      final results = await repository.searchRoster(query);

      // Sort results
      final sortedResults = _sortResults(results, state.sortOption);

      state = state.copyWith(
        results: sortedResults,
        isSearching: false,
        hasSearched: true,
      );

      AppLogger.debug(
        '[ContactSearch] Search completed',
        data: {'query': query, 'resultCount': sortedResults.length},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '[ContactSearch] Search failed',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        results: [],
        isSearching: false,
        hasSearched: true,
        error: 'Search failed: ${e.toString()}',
      );
    }
  }

  /// Change sort option and re-sort results
  void setSortOption(ContactSortOption option) {
    if (option == state.sortOption) return;

    final sortedResults = _sortResults(state.results, option);
    state = state.copyWith(sortOption: option, results: sortedResults);

    AppLogger.debug(
      '[ContactSearch] Sort option changed',
      data: {'sortOption': option.name, 'resultCount': sortedResults.length},
    );
  }

  /// Sort results based on the selected option
  List<RosterEntry> _sortResults(
    List<RosterEntry> results,
    ContactSortOption option,
  ) {
    final sorted = List<RosterEntry>.from(results);

    switch (option) {
      case ContactSortOption.alphabeticalAsc:
        sorted.sort((a, b) {
          final nameA = (a.displayName ?? a.contactDetail).toLowerCase();
          final nameB = (b.displayName ?? b.contactDetail).toLowerCase();
          return nameA.compareTo(nameB);
        });
      case ContactSortOption.alphabeticalDesc:
        sorted.sort((a, b) {
          final nameA = (a.displayName ?? a.contactDetail).toLowerCase();
          final nameB = (b.displayName ?? b.contactDetail).toLowerCase();
          return nameB.compareTo(nameA);
        });
      case ContactSortOption.recentFirst:
        sorted.sort((a, b) {
          final timeA = a.syncedAt?.millisecondsSinceEpoch ?? 0;
          final timeB = b.syncedAt?.millisecondsSinceEpoch ?? 0;
          return timeB.compareTo(timeA);
        });
      case ContactSortOption.phoneFirst:
        sorted.sort((a, b) {
          final typeA = a.contactType == RosterContactType.msisdn ? 0 : 1;
          final typeB = b.contactType == RosterContactType.msisdn ? 0 : 1;
          if (typeA != typeB) return typeA.compareTo(typeB);
          // Secondary sort by name
          final nameA = (a.displayName ?? a.contactDetail).toLowerCase();
          final nameB = (b.displayName ?? b.contactDetail).toLowerCase();
          return nameA.compareTo(nameB);
        });
      case ContactSortOption.emailFirst:
        sorted.sort((a, b) {
          final typeA = a.contactType == RosterContactType.email ? 0 : 1;
          final typeB = b.contactType == RosterContactType.email ? 0 : 1;
          if (typeA != typeB) return typeA.compareTo(typeB);
          // Secondary sort by name
          final nameA = (a.displayName ?? a.contactDetail).toLowerCase();
          final nameB = (b.displayName ?? b.contactDetail).toLowerCase();
          return nameA.compareTo(nameB);
        });
    }

    return sorted;
  }

  /// Clear search and reset state
  void clearSearch() {
    _debounceTimer?.cancel();
    state = ContactSearchState(sortOption: state.sortOption);
  }
}

// ============================================================================
// Sort Option Provider
// ============================================================================

/// Provider for current sort option (separate for UI controls)
@riverpod
class ContactSortOptionState extends _$ContactSortOptionState {
  @override
  ContactSortOption build() => ContactSortOption.alphabeticalAsc;

  void setOption(ContactSortOption option) {
    state = option;
  }
}
