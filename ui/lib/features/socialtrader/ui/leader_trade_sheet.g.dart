// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leader_trade_sheet.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The order book of [marketId], top levels.

@ProviderFor(marketBook)
final marketBookProvider = MarketBookFamily._();

/// The order book of [marketId], top levels.

final class MarketBookProvider
    extends
        $FunctionalProvider<
          AsyncValue<OrderBook>,
          OrderBook,
          FutureOr<OrderBook>
        >
    with $FutureModifier<OrderBook>, $FutureProvider<OrderBook> {
  /// The order book of [marketId], top levels.
  MarketBookProvider._({
    required MarketBookFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'marketBookProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$marketBookHash();

  @override
  String toString() {
    return r'marketBookProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<OrderBook> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<OrderBook> create(Ref ref) {
    final argument = this.argument as String;
    return marketBook(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MarketBookProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$marketBookHash() => r'1cf18080c047530e08ef74c67a1b20cc7e493113';

/// The order book of [marketId], top levels.

final class MarketBookFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<OrderBook>, String> {
  MarketBookFamily._()
    : super(
        retry: null,
        name: r'marketBookProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The order book of [marketId], top levels.

  MarketBookProvider call(String marketId) =>
      MarketBookProvider._(argument: marketId, from: this);

  @override
  String toString() => r'marketBookProvider';
}

/// Sends one leader call: asks the service for its calldata, then the wallet
/// to sign and send it. The contract enforces onlyLeader; the sheet is only a
/// convenience for the leader.

@ProviderFor(LeaderOrderController)
final leaderOrderControllerProvider = LeaderOrderControllerFamily._();

/// Sends one leader call: asks the service for its calldata, then the wallet
/// to sign and send it. The contract enforces onlyLeader; the sheet is only a
/// convenience for the leader.
final class LeaderOrderControllerProvider
    extends $NotifierProvider<LeaderOrderController, CommitState> {
  /// Sends one leader call: asks the service for its calldata, then the wallet
  /// to sign and send it. The contract enforces onlyLeader; the sheet is only a
  /// convenience for the leader.
  LeaderOrderControllerProvider._({
    required LeaderOrderControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'leaderOrderControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$leaderOrderControllerHash();

  @override
  String toString() {
    return r'leaderOrderControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LeaderOrderController create() => LeaderOrderController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommitState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommitState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LeaderOrderControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$leaderOrderControllerHash() =>
    r'adf343e693f62b31dc3f64f0d358c03ea576f3fe';

/// Sends one leader call: asks the service for its calldata, then the wallet
/// to sign and send it. The contract enforces onlyLeader; the sheet is only a
/// convenience for the leader.

final class LeaderOrderControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LeaderOrderController,
          CommitState,
          CommitState,
          CommitState,
          String
        > {
  LeaderOrderControllerFamily._()
    : super(
        retry: null,
        name: r'leaderOrderControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Sends one leader call: asks the service for its calldata, then the wallet
  /// to sign and send it. The contract enforces onlyLeader; the sheet is only a
  /// convenience for the leader.

  LeaderOrderControllerProvider call(String pool) =>
      LeaderOrderControllerProvider._(argument: pool, from: this);

  @override
  String toString() => r'leaderOrderControllerProvider';
}

/// Sends one leader call: asks the service for its calldata, then the wallet
/// to sign and send it. The contract enforces onlyLeader; the sheet is only a
/// convenience for the leader.

abstract class _$LeaderOrderController extends $Notifier<CommitState> {
  late final _$args = ref.$arg as String;
  String get pool => _$args;

  CommitState build(String pool);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CommitState, CommitState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CommitState, CommitState>,
              CommitState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
