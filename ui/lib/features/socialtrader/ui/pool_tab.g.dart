// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pool_tab.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A pool's performance series.

@ProviderFor(poolPerformance)
final poolPerformanceProvider = PoolPerformanceFamily._();

/// A pool's performance series.

final class PoolPerformanceProvider
    extends
        $FunctionalProvider<
          AsyncValue<PoolPerformance>,
          PoolPerformance,
          FutureOr<PoolPerformance>
        >
    with $FutureModifier<PoolPerformance>, $FutureProvider<PoolPerformance> {
  /// A pool's performance series.
  PoolPerformanceProvider._({
    required PoolPerformanceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'poolPerformanceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$poolPerformanceHash();

  @override
  String toString() {
    return r'poolPerformanceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PoolPerformance> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PoolPerformance> create(Ref ref) {
    final argument = this.argument as String;
    return poolPerformance(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PoolPerformanceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$poolPerformanceHash() => r'def66c769ad11848f178cb3f2265c2449f17c10a';

/// A pool's performance series.

final class PoolPerformanceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PoolPerformance>, String> {
  PoolPerformanceFamily._()
    : super(
        retry: null,
        name: r'poolPerformanceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A pool's performance series.

  PoolPerformanceProvider call(String pool) =>
      PoolPerformanceProvider._(argument: pool, from: this);

  @override
  String toString() => r'poolPerformanceProvider';
}

/// The pool's recent fills, from the fill cards in the room's timeline,
/// newest first.

@ProviderFor(recentFills)
final recentFillsProvider = RecentFillsFamily._();

/// The pool's recent fills, from the fill cards in the room's timeline,
/// newest first.

final class RecentFillsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<(RoomEvent, FillCard)>>,
          AsyncValue<List<(RoomEvent, FillCard)>>,
          AsyncValue<List<(RoomEvent, FillCard)>>
        >
    with $Provider<AsyncValue<List<(RoomEvent, FillCard)>>> {
  /// The pool's recent fills, from the fill cards in the room's timeline,
  /// newest first.
  RecentFillsProvider._({
    required RecentFillsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recentFillsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recentFillsHash();

  @override
  String toString() {
    return r'recentFillsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<List<(RoomEvent, FillCard)>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<(RoomEvent, FillCard)>> create(Ref ref) {
    final argument = this.argument as String;
    return recentFills(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<(RoomEvent, FillCard)>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<List<(RoomEvent, FillCard)>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RecentFillsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recentFillsHash() => r'9aa0cdc4cbef5e2f4046b4d0476141fb924bddb0';

/// The pool's recent fills, from the fill cards in the room's timeline,
/// newest first.

final class RecentFillsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<List<(RoomEvent, FillCard)>>,
          String
        > {
  RecentFillsFamily._()
    : super(
        retry: null,
        name: r'recentFillsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The pool's recent fills, from the fill cards in the room's timeline,
  /// newest first.

  RecentFillsProvider call(String roomId) =>
      RecentFillsProvider._(argument: roomId, from: this);

  @override
  String toString() => r'recentFillsProvider';
}
