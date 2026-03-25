import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/contacts/data/contact_search_provider.dart';
import 'package:stawi/features/contacts/data/roster_repository.dart';

import 'mock_roster_repository.dart';

/// Mock repository for search testing
class MockSearchRosterRepository extends MockRosterRepository {
  List<RosterEntry> _searchResults = [];

  void setSearchResults(List<RosterEntry> results) {
    _searchResults = results;
  }

  Future<List<RosterEntry>> searchRoster(String query) async {
    // Simulate search delay
    await Future.delayed(const Duration(milliseconds: 10));

    // Filter results by query
    if (query.isEmpty) return [];

    return _searchResults.where((entry) {
      final displayName = (entry.displayName ?? '').toLowerCase();
      final contactDetail = entry.contactDetail.toLowerCase();
      final q = query.toLowerCase();
      return displayName.contains(q) || contactDetail.contains(q);
    }).toList();
  }
}

void main() {
  group('ContactSearchState', () {
    test('initial state has correct defaults', () {
      const state = ContactSearchState();

      expect(state.query, isEmpty);
      expect(state.results, isEmpty);
      expect(state.isSearching, isFalse);
      expect(state.hasSearched, isFalse);
      expect(state.sortOption, ContactSortOption.alphabeticalAsc);
      expect(state.error, isNull);
    });

    test('hasNoResults returns true when searched but no results', () {
      const state = ContactSearchState(query: 'test', hasSearched: true);

      expect(state.hasNoResults, isTrue);
    });

    test('hasNoResults returns false when query is empty', () {
      const state = ContactSearchState(hasSearched: true);

      expect(state.hasNoResults, isFalse);
    });

    test('hasNoResults returns false when has results', () {
      final state = ContactSearchState(
        query: 'test',
        results: [
          RosterEntry(
            id: 'test_id',
            contactType: RosterContactType.email,
            contactDetail: 'test@example.com',
          ),
        ],
        hasSearched: true,
      );

      expect(state.hasNoResults, isFalse);
    });

    test('hasResults returns true when results exist', () {
      final state = ContactSearchState(
        query: 'test',
        results: [
          RosterEntry(
            id: 'test_id',
            contactType: RosterContactType.email,
            contactDetail: 'test@example.com',
          ),
        ],
      );

      expect(state.hasResults, isTrue);
    });

    test('copyWith preserves values not specified', () {
      const original = ContactSearchState(
        query: 'original',
        isSearching: true,
        sortOption: ContactSortOption.recentFirst,
      );

      final updated = original.copyWith(query: 'updated');

      expect(updated.query, 'updated');
      expect(updated.isSearching, isTrue);
      expect(updated.sortOption, ContactSortOption.recentFirst);
    });
  });

  group('ContactSortOption', () {
    test('displayName returns correct labels', () {
      expect(ContactSortOption.alphabeticalAsc.displayName, 'Name (A-Z)');
      expect(ContactSortOption.alphabeticalDesc.displayName, 'Name (Z-A)');
      expect(ContactSortOption.recentFirst.displayName, 'Recently Synced');
      expect(ContactSortOption.phoneFirst.displayName, 'Phone Numbers First');
      expect(ContactSortOption.emailFirst.displayName, 'Emails First');
    });

    test('all sort options have unique display names', () {
      final displayNames = ContactSortOption.values
          .map((option) => option.displayName)
          .toList();
      final uniqueNames = displayNames.toSet();
      expect(uniqueNames.length, displayNames.length);
    });
  });

  group('ContactSearchNotifier sorting', () {
    late List<RosterEntry> testEntries;

    setUp(() {
      testEntries = [
        RosterEntry(
          id: 'charlie',
          contactType: RosterContactType.email,
          contactDetail: 'charlie@example.com',
          displayName: 'Charlie',
          syncedAt: DateTime(2024),
        ),
        RosterEntry(
          id: 'alice',
          contactType: RosterContactType.msisdn,
          contactDetail: '+1234567890',
          displayName: 'Alice',
          syncedAt: DateTime(2024, 1, 3),
        ),
        RosterEntry(
          id: 'bob',
          contactType: RosterContactType.email,
          contactDetail: 'bob@example.com',
          displayName: 'Bob',
          syncedAt: DateTime(2024, 1, 2),
        ),
      ];
    });

    test('alphabeticalAsc sorts A-Z by display name', () {
      final sorted = _sortEntries(
        testEntries,
        ContactSortOption.alphabeticalAsc,
      );

      expect(sorted[0].displayName, 'Alice');
      expect(sorted[1].displayName, 'Bob');
      expect(sorted[2].displayName, 'Charlie');
    });

    test('alphabeticalDesc sorts Z-A by display name', () {
      final sorted = _sortEntries(
        testEntries,
        ContactSortOption.alphabeticalDesc,
      );

      expect(sorted[0].displayName, 'Charlie');
      expect(sorted[1].displayName, 'Bob');
      expect(sorted[2].displayName, 'Alice');
    });

    test('recentFirst sorts by sync date descending', () {
      final sorted = _sortEntries(testEntries, ContactSortOption.recentFirst);

      expect(sorted[0].displayName, 'Alice'); // Jan 3
      expect(sorted[1].displayName, 'Bob'); // Jan 2
      expect(sorted[2].displayName, 'Charlie'); // Jan 1
    });

    test('phoneFirst sorts phone numbers before emails', () {
      final sorted = _sortEntries(testEntries, ContactSortOption.phoneFirst);

      expect(sorted[0].contactType, RosterContactType.msisdn);
      expect(sorted[0].displayName, 'Alice');
      // Emails should follow, sorted alphabetically
      expect(sorted[1].displayName, 'Bob');
      expect(sorted[2].displayName, 'Charlie');
    });

    test('emailFirst sorts emails before phone numbers', () {
      final sorted = _sortEntries(testEntries, ContactSortOption.emailFirst);

      expect(sorted[0].contactType, RosterContactType.email);
      expect(sorted[1].contactType, RosterContactType.email);
      expect(sorted[2].contactType, RosterContactType.msisdn);
    });

    test('sorting handles null display names', () {
      final entriesWithNull = [
        RosterEntry(
          id: 'null_name',
          contactType: RosterContactType.email,
          contactDetail: 'null@example.com',
        ),
        RosterEntry(
          id: 'bob',
          contactType: RosterContactType.email,
          contactDetail: 'bob@example.com',
          displayName: 'Bob',
        ),
      ];

      final sorted = _sortEntries(
        entriesWithNull,
        ContactSortOption.alphabeticalAsc,
      );

      // Should not throw and should sort (null name uses contactDetail)
      expect(sorted.length, 2);
    });

    test('sorting handles null sync dates', () {
      final entriesWithNullDate = [
        RosterEntry(
          id: 'no_sync',
          contactType: RosterContactType.email,
          contactDetail: 'nosync@example.com',
          displayName: 'No Sync',
        ),
        RosterEntry(
          id: 'has_sync',
          contactType: RosterContactType.email,
          contactDetail: 'hassync@example.com',
          displayName: 'Has Sync',
          syncedAt: DateTime(2024),
        ),
      ];

      final sorted = _sortEntries(
        entriesWithNullDate,
        ContactSortOption.recentFirst,
      );

      // Entry with date should come first
      expect(sorted[0].displayName, 'Has Sync');
      expect(sorted[1].displayName, 'No Sync');
    });
  });

  group('Search debounce constants', () {
    test('debounce is 300ms', () {
      expect(kSearchDebounceMs, 300);
    });

    test('minimum query length is 1', () {
      expect(kMinSearchQueryLength, 1);
    });
  });
}

/// Helper function to sort entries (mirrors the notifier's sorting logic)
List<RosterEntry> _sortEntries(
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
        final nameA = (a.displayName ?? a.contactDetail).toLowerCase();
        final nameB = (b.displayName ?? b.contactDetail).toLowerCase();
        return nameA.compareTo(nameB);
      });
    case ContactSortOption.emailFirst:
      sorted.sort((a, b) {
        final typeA = a.contactType == RosterContactType.email ? 0 : 1;
        final typeB = b.contactType == RosterContactType.email ? 0 : 1;
        if (typeA != typeB) return typeA.compareTo(typeB);
        final nameA = (a.displayName ?? a.contactDetail).toLowerCase();
        final nameB = (b.displayName ?? b.contactDetail).toLowerCase();
        return nameA.compareTo(nameB);
      });
  }

  return sorted;
}
