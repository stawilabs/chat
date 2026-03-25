// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_search_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for global search functionality

@ProviderFor(GlobalSearch)
final globalSearchProvider = GlobalSearchProvider._();

/// Notifier for global search functionality
final class GlobalSearchProvider
    extends $NotifierProvider<GlobalSearch, GlobalSearchState> {
  /// Notifier for global search functionality
  GlobalSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalSearchHash();

  @$internal
  @override
  GlobalSearch create() => GlobalSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlobalSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlobalSearchState>(value),
    );
  }
}

String _$globalSearchHash() => r'e765e272cdc523be8af4aff8692919c63fc28eeb';

/// Notifier for global search functionality

abstract class _$GlobalSearch extends $Notifier<GlobalSearchState> {
  GlobalSearchState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<GlobalSearchState, GlobalSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GlobalSearchState, GlobalSearchState>,
              GlobalSearchState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
