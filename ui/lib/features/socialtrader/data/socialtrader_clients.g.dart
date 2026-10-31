// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'socialtrader_clients.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The generated socialtrader clients (vendored from the socialtrader
/// repository's protos into `gen/`), each over the app's runtime transport:
/// every call carries the signed-in session's token, like the chat and Stawi
/// clients. Reads and prepares are public on the service; wallet linking
/// needs the session.

@ProviderFor(poolService)
final poolServiceProvider = PoolServiceProvider._();

/// The generated socialtrader clients (vendored from the socialtrader
/// repository's protos into `gen/`), each over the app's runtime transport:
/// every call carries the signed-in session's token, like the chat and Stawi
/// clients. Reads and prepares are public on the service; wallet linking
/// needs the session.

final class PoolServiceProvider
    extends
        $FunctionalProvider<
          PoolServiceClient,
          PoolServiceClient,
          PoolServiceClient
        >
    with $Provider<PoolServiceClient> {
  /// The generated socialtrader clients (vendored from the socialtrader
  /// repository's protos into `gen/`), each over the app's runtime transport:
  /// every call carries the signed-in session's token, like the chat and Stawi
  /// clients. Reads and prepares are public on the service; wallet linking
  /// needs the session.
  PoolServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'poolServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$poolServiceHash();

  @$internal
  @override
  $ProviderElement<PoolServiceClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PoolServiceClient create(Ref ref) {
    return poolService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PoolServiceClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PoolServiceClient>(value),
    );
  }
}

String _$poolServiceHash() => r'1079ada1375fabcb6d81bad2819bb35e704caf9c';

@ProviderFor(linkService)
final linkServiceProvider = LinkServiceProvider._();

final class LinkServiceProvider
    extends
        $FunctionalProvider<
          LinkServiceClient,
          LinkServiceClient,
          LinkServiceClient
        >
    with $Provider<LinkServiceClient> {
  LinkServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'linkServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$linkServiceHash();

  @$internal
  @override
  $ProviderElement<LinkServiceClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LinkServiceClient create(Ref ref) {
    return linkService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LinkServiceClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LinkServiceClient>(value),
    );
  }
}

String _$linkServiceHash() => r'106c4e726add17c7703fbf15cdd2181abe392d3b';

@ProviderFor(marketService)
final marketServiceProvider = MarketServiceProvider._();

final class MarketServiceProvider
    extends
        $FunctionalProvider<
          MarketServiceClient,
          MarketServiceClient,
          MarketServiceClient
        >
    with $Provider<MarketServiceClient> {
  MarketServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'marketServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$marketServiceHash();

  @$internal
  @override
  $ProviderElement<MarketServiceClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MarketServiceClient create(Ref ref) {
    return marketService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarketServiceClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarketServiceClient>(value),
    );
  }
}

String _$marketServiceHash() => r'306c4f146fae4339c015fe4993976c65bdd6b908';
