// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_optimizer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(networkOptimizer)
final networkOptimizerProvider = NetworkOptimizerProvider._();

final class NetworkOptimizerProvider
    extends
        $FunctionalProvider<
          NetworkOptimizer,
          NetworkOptimizer,
          NetworkOptimizer
        >
    with $Provider<NetworkOptimizer> {
  NetworkOptimizerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkOptimizerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkOptimizerHash();

  @$internal
  @override
  $ProviderElement<NetworkOptimizer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NetworkOptimizer create(Ref ref) {
    return networkOptimizer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetworkOptimizer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NetworkOptimizer>(value),
    );
  }
}

String _$networkOptimizerHash() => r'b56ba499708e91e296b27ec53745166ec0913f4f';

/// Stream of bandwidth statistics updated every 5 seconds

@ProviderFor(bandwidthStats)
final bandwidthStatsProvider = BandwidthStatsProvider._();

/// Stream of bandwidth statistics updated every 5 seconds

final class BandwidthStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<BandwidthStats>,
          BandwidthStats,
          Stream<BandwidthStats>
        >
    with $FutureModifier<BandwidthStats>, $StreamProvider<BandwidthStats> {
  /// Stream of bandwidth statistics updated every 5 seconds
  BandwidthStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bandwidthStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bandwidthStatsHash();

  @$internal
  @override
  $StreamProviderElement<BandwidthStats> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<BandwidthStats> create(Ref ref) {
    return bandwidthStats(ref);
  }
}

String _$bandwidthStatsHash() => r'894b66af382ef0072e8465b290be87eb1b7820ac';
