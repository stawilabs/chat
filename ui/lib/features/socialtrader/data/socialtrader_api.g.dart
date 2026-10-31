// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'socialtrader_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(socialTraderApi)
final socialTraderApiProvider = SocialTraderApiProvider._();

final class SocialTraderApiProvider
    extends
        $FunctionalProvider<SocialTraderApi, SocialTraderApi, SocialTraderApi>
    with $Provider<SocialTraderApi> {
  SocialTraderApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'socialTraderApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$socialTraderApiHash();

  @$internal
  @override
  $ProviderElement<SocialTraderApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SocialTraderApi create(Ref ref) {
    return socialTraderApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SocialTraderApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SocialTraderApi>(value),
    );
  }
}

String _$socialTraderApiHash() => r'7c471e12172612f6951e9417733978c3928f6117';

/// Every pool the service knows, by lowercase address. Cards from a pool not
/// in it render as plain text.

@ProviderFor(knownPools)
final knownPoolsProvider = KnownPoolsProvider._();

/// Every pool the service knows, by lowercase address. Cards from a pool not
/// in it render as plain text.

final class KnownPoolsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, PoolInfo>>,
          Map<String, PoolInfo>,
          FutureOr<Map<String, PoolInfo>>
        >
    with
        $FutureModifier<Map<String, PoolInfo>>,
        $FutureProvider<Map<String, PoolInfo>> {
  /// Every pool the service knows, by lowercase address. Cards from a pool not
  /// in it render as plain text.
  KnownPoolsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'knownPoolsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$knownPoolsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, PoolInfo>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, PoolInfo>> create(Ref ref) {
    return knownPools(ref);
  }
}

String _$knownPoolsHash() => r'd852f9da6d9f4c8317ef92a1ef8910ce7e07d17c';

/// The pool at [address], or null when the service does not know it.

@ProviderFor(poolByAddress)
final poolByAddressProvider = PoolByAddressFamily._();

/// The pool at [address], or null when the service does not know it.

final class PoolByAddressProvider
    extends
        $FunctionalProvider<
          AsyncValue<PoolInfo?>,
          PoolInfo?,
          FutureOr<PoolInfo?>
        >
    with $FutureModifier<PoolInfo?>, $FutureProvider<PoolInfo?> {
  /// The pool at [address], or null when the service does not know it.
  PoolByAddressProvider._({
    required PoolByAddressFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'poolByAddressProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$poolByAddressHash();

  @override
  String toString() {
    return r'poolByAddressProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PoolInfo?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PoolInfo?> create(Ref ref) {
    final argument = this.argument as String;
    return poolByAddress(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PoolByAddressProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$poolByAddressHash() => r'4476ce587663e396bb19a5098759c08a74dcf8cb';

/// The pool at [address], or null when the service does not know it.

final class PoolByAddressFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PoolInfo?>, String> {
  PoolByAddressFamily._()
    : super(
        retry: null,
        name: r'poolByAddressProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The pool at [address], or null when the service does not know it.

  PoolByAddressProvider call(String address) =>
      PoolByAddressProvider._(argument: address, from: this);

  @override
  String toString() => r'poolByAddressProvider';
}
