// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_pool_sheet.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Commits funds to a pool: asks the service for the deposit calldata, then
/// the wallet to sign and send it.

@ProviderFor(JoinPoolController)
final joinPoolControllerProvider = JoinPoolControllerFamily._();

/// Commits funds to a pool: asks the service for the deposit calldata, then
/// the wallet to sign and send it.
final class JoinPoolControllerProvider
    extends $NotifierProvider<JoinPoolController, CommitState> {
  /// Commits funds to a pool: asks the service for the deposit calldata, then
  /// the wallet to sign and send it.
  JoinPoolControllerProvider._({
    required JoinPoolControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'joinPoolControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$joinPoolControllerHash();

  @override
  String toString() {
    return r'joinPoolControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  JoinPoolController create() => JoinPoolController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommitState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommitState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is JoinPoolControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$joinPoolControllerHash() =>
    r'99d4df82d70fde5d096c0796d7bc8995b7bfa660';

/// Commits funds to a pool: asks the service for the deposit calldata, then
/// the wallet to sign and send it.

final class JoinPoolControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          JoinPoolController,
          CommitState,
          CommitState,
          CommitState,
          String
        > {
  JoinPoolControllerFamily._()
    : super(
        retry: null,
        name: r'joinPoolControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Commits funds to a pool: asks the service for the deposit calldata, then
  /// the wallet to sign and send it.

  JoinPoolControllerProvider call(String pool) =>
      JoinPoolControllerProvider._(argument: pool, from: this);

  @override
  String toString() => r'joinPoolControllerProvider';
}

/// Commits funds to a pool: asks the service for the deposit calldata, then
/// the wallet to sign and send it.

abstract class _$JoinPoolController extends $Notifier<CommitState> {
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
