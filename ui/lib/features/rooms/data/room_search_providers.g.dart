// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for managing room search state

@ProviderFor(RoomSearch)
final roomSearchProvider = RoomSearchProvider._();

/// Provider for managing room search state
final class RoomSearchProvider
    extends $NotifierProvider<RoomSearch, RoomSearchState> {
  /// Provider for managing room search state
  RoomSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomSearchHash();

  @$internal
  @override
  RoomSearch create() => RoomSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RoomSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RoomSearchState>(value),
    );
  }
}

String _$roomSearchHash() => r'62e376a5e9ac589cc77b47b095c8cca705c40630';

/// Provider for managing room search state

abstract class _$RoomSearch extends $Notifier<RoomSearchState> {
  RoomSearchState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RoomSearchState, RoomSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RoomSearchState, RoomSearchState>,
              RoomSearchState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider for filtered rooms based on search state

@ProviderFor(filteredRooms)
final filteredRoomsProvider = FilteredRoomsProvider._();

/// Provider for filtered rooms based on search state

final class FilteredRoomsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RoomWithLastMessage>>,
          List<RoomWithLastMessage>,
          FutureOr<List<RoomWithLastMessage>>
        >
    with
        $FutureModifier<List<RoomWithLastMessage>>,
        $FutureProvider<List<RoomWithLastMessage>> {
  /// Provider for filtered rooms based on search state
  FilteredRoomsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredRoomsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredRoomsHash();

  @$internal
  @override
  $FutureProviderElement<List<RoomWithLastMessage>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RoomWithLastMessage>> create(Ref ref) {
    return filteredRooms(ref);
  }
}

String _$filteredRoomsHash() => r'8ea1db93f74581eff20d3619863a22d4b9c01e77';
