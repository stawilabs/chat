// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_pool_sheet.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Redeems all of a member's shares: asks the service for the redeem
/// calldata, then the wallet to sign and send it.

@ProviderFor(LeavePoolController)
final leavePoolControllerProvider = LeavePoolControllerFamily._();

/// Redeems all of a member's shares: asks the service for the redeem
/// calldata, then the wallet to sign and send it.
final class LeavePoolControllerProvider
    extends $NotifierProvider<LeavePoolController, CommitState> {
  /// Redeems all of a member's shares: asks the service for the redeem
  /// calldata, then the wallet to sign and send it.
  LeavePoolControllerProvider._({
    required LeavePoolControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'leavePoolControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$leavePoolControllerHash();

  @override
  String toString() {
    return r'leavePoolControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LeavePoolController create() => LeavePoolController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommitState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommitState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LeavePoolControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$leavePoolControllerHash() =>
    r'53696275937007969f7d3ebd313e238ea1f59d88';

/// Redeems all of a member's shares: asks the service for the redeem
/// calldata, then the wallet to sign and send it.

final class LeavePoolControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LeavePoolController,
          CommitState,
          CommitState,
          CommitState,
          String
        > {
  LeavePoolControllerFamily._()
    : super(
        retry: null,
        name: r'leavePoolControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Redeems all of a member's shares: asks the service for the redeem
  /// calldata, then the wallet to sign and send it.

  LeavePoolControllerProvider call(String pool) =>
      LeavePoolControllerProvider._(argument: pool, from: this);

  @override
  String toString() => r'leavePoolControllerProvider';
}

/// Redeems all of a member's shares: asks the service for the redeem
/// calldata, then the wallet to sign and send it.

abstract class _$LeavePoolController extends $Notifier<CommitState> {
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
