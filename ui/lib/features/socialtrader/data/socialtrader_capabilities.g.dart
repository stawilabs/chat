// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'socialtrader_capabilities.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The HTTP client the capabilities probe uses; tests override it.

@ProviderFor(capabilitiesHttpClient)
final capabilitiesHttpClientProvider = CapabilitiesHttpClientProvider._();

/// The HTTP client the capabilities probe uses; tests override it.

final class CapabilitiesHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  /// The HTTP client the capabilities probe uses; tests override it.
  CapabilitiesHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'capabilitiesHttpClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$capabilitiesHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return capabilitiesHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$capabilitiesHttpClientHash() =>
    r'0d7c85d7db317b9b31b2b9570bd3f8fd5156b637';

/// What the socialtrader service says it can do. A service that does not
/// answer (older build, offline) announces nothing, so every gated feature
/// stays hidden rather than failing later.

@ProviderFor(socialTraderCapabilities)
final socialTraderCapabilitiesProvider = SocialTraderCapabilitiesProvider._();

/// What the socialtrader service says it can do. A service that does not
/// answer (older build, offline) announces nothing, so every gated feature
/// stays hidden rather than failing later.

final class SocialTraderCapabilitiesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          FutureOr<Set<String>>
        >
    with $FutureModifier<Set<String>>, $FutureProvider<Set<String>> {
  /// What the socialtrader service says it can do. A service that does not
  /// answer (older build, offline) announces nothing, so every gated feature
  /// stays hidden rather than failing later.
  SocialTraderCapabilitiesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'socialTraderCapabilitiesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$socialTraderCapabilitiesHash();

  @$internal
  @override
  $FutureProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Set<String>> create(Ref ref) {
    return socialTraderCapabilities(ref);
  }
}

String _$socialTraderCapabilitiesHash() =>
    r'380a84ca3ab4fdbdb5b490a594142c28e474fd06';

/// Whether the service can create a pool for a new trading group.

@ProviderFor(canCreatePool)
final canCreatePoolProvider = CanCreatePoolProvider._();

/// Whether the service can create a pool for a new trading group.

final class CanCreatePoolProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the service can create a pool for a new trading group.
  CanCreatePoolProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'canCreatePoolProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$canCreatePoolHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return canCreatePool(ref);
  }
}

String _$canCreatePoolHash() => r'243f83b0ad458bc09787b01081de438cd869243e';
