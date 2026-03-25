// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for contact search with debouncing

@ProviderFor(ContactSearch)
final contactSearchProvider = ContactSearchProvider._();

/// Notifier for contact search with debouncing
final class ContactSearchProvider
    extends $NotifierProvider<ContactSearch, ContactSearchState> {
  /// Notifier for contact search with debouncing
  ContactSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactSearchHash();

  @$internal
  @override
  ContactSearch create() => ContactSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContactSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContactSearchState>(value),
    );
  }
}

String _$contactSearchHash() => r'9209081af5c9989094c0130bf31a8e20855b8bb7';

/// Notifier for contact search with debouncing

abstract class _$ContactSearch extends $Notifier<ContactSearchState> {
  ContactSearchState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ContactSearchState, ContactSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ContactSearchState, ContactSearchState>,
              ContactSearchState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider for current sort option (separate for UI controls)

@ProviderFor(ContactSortOptionState)
final contactSortOptionStateProvider = ContactSortOptionStateProvider._();

/// Provider for current sort option (separate for UI controls)
final class ContactSortOptionStateProvider
    extends $NotifierProvider<ContactSortOptionState, ContactSortOption> {
  /// Provider for current sort option (separate for UI controls)
  ContactSortOptionStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactSortOptionStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactSortOptionStateHash();

  @$internal
  @override
  ContactSortOptionState create() => ContactSortOptionState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContactSortOption value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContactSortOption>(value),
    );
  }
}

String _$contactSortOptionStateHash() =>
    r'1525fa305515e5d5682016a45f4ce329d30469f4';

/// Provider for current sort option (separate for UI controls)

abstract class _$ContactSortOptionState extends $Notifier<ContactSortOption> {
  ContactSortOption build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ContactSortOption, ContactSortOption>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ContactSortOption, ContactSortOption>,
              ContactSortOption,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
