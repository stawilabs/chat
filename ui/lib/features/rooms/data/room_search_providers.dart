import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/room_with_last_message.dart';
import 'room_providers.dart';

part 'room_search_providers.g.dart';

/// Filter types for room search
enum RoomFilterType { all, groups, direct, unread }

/// State class for room search
class RoomSearchState {
  const RoomSearchState({
    this.query = '',
    this.filterType = RoomFilterType.all,
  });

  final String query;
  final RoomFilterType filterType;

  RoomSearchState copyWith({String? query, RoomFilterType? filterType}) =>
      RoomSearchState(
        query: query ?? this.query,
        filterType: filterType ?? this.filterType,
      );

  bool get hasActiveSearch => query.isNotEmpty;
  bool get hasActiveFilter => filterType != RoomFilterType.all;
  bool get isFiltering => hasActiveSearch || hasActiveFilter;
}

/// Provider for managing room search state
@riverpod
class RoomSearch extends _$RoomSearch {
  @override
  RoomSearchState build() => const RoomSearchState();

  /// Update the search query
  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  /// Update the filter type
  void setFilter(RoomFilterType filterType) {
    state = state.copyWith(filterType: filterType);
  }

  /// Clear the search query
  void clearQuery() {
    state = state.copyWith(query: '');
  }

  /// Clear all filters and search
  void clearAll() {
    state = const RoomSearchState();
  }
}

/// Provider for filtered rooms based on search state
@riverpod
Future<List<RoomWithLastMessage>> filteredRooms(Ref ref) async {
  final searchState = ref.watch(roomSearchProvider);
  final roomsAsync = ref.watch(roomListWithMessagesProvider);

  return roomsAsync.when(
    data: (rooms) => _filterRooms(rooms, searchState),
    loading: () => [],
    error: (error, stackTrace) => [],
  );
}

/// Filter rooms based on search state
List<RoomWithLastMessage> _filterRooms(
  List<RoomWithLastMessage> rooms,
  RoomSearchState searchState,
) {
  var filtered = rooms;

  // Apply type filter
  switch (searchState.filterType) {
    case RoomFilterType.all:
      // No filtering needed
      break;
    case RoomFilterType.groups:
      filtered = filtered.where((room) => room.type == 'group').toList();
    case RoomFilterType.direct:
      filtered = filtered.where((room) => room.type == 'direct').toList();
    case RoomFilterType.unread:
      filtered = filtered.where((room) => room.unreadCount > 0).toList();
  }

  // Apply search query
  if (searchState.query.isNotEmpty) {
    final query = searchState.query.toLowerCase();
    filtered = filtered.where((room) {
      // Search by room name
      if (room.name.toLowerCase().contains(query)) {
        return true;
      }
      // Search by last message text
      if (room.lastMessageText?.toLowerCase().contains(query) ?? false) {
        return true;
      }
      return false;
    }).toList();
  }

  return filtered;
}
