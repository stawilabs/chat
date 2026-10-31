// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The platform's signer; tests override it with a fake.

@ProviderFor(walletPlatform)
final walletPlatformProvider = WalletPlatformProvider._();

/// The platform's signer; tests override it with a fake.

final class WalletPlatformProvider
    extends $FunctionalProvider<WalletPlatform, WalletPlatform, WalletPlatform>
    with $Provider<WalletPlatform> {
  /// The platform's signer; tests override it with a fake.
  WalletPlatformProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletPlatformProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletPlatformHash();

  @$internal
  @override
  $ProviderElement<WalletPlatform> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WalletPlatform create(Ref ref) {
    return walletPlatform(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WalletPlatform value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WalletPlatform>(value),
    );
  }
}

String _$walletPlatformHash() => r'41af0ce95e7619882421bfbc78754461242f78f3';

/// The wallet the trading group module signs with. Connecting asks the
/// platform signer for an account; a pasted address reads only. Nothing is
/// ever sent without a call to [sendPrepared], which the UI makes on a tap.

@ProviderFor(WalletController)
final walletControllerProvider = WalletControllerProvider._();

/// The wallet the trading group module signs with. Connecting asks the
/// platform signer for an account; a pasted address reads only. Nothing is
/// ever sent without a call to [sendPrepared], which the UI makes on a tap.
final class WalletControllerProvider
    extends $NotifierProvider<WalletController, WalletState> {
  /// The wallet the trading group module signs with. Connecting asks the
  /// platform signer for an account; a pasted address reads only. Nothing is
  /// ever sent without a call to [sendPrepared], which the UI makes on a tap.
  WalletControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletControllerHash();

  @$internal
  @override
  WalletController create() => WalletController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WalletState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WalletState>(value),
    );
  }
}

String _$walletControllerHash() => r'7ec2cdb8d478fbde9b53e13861c8ad87a35344ba';

/// The wallet the trading group module signs with. Connecting asks the
/// platform signer for an account; a pasted address reads only. Nothing is
/// ever sent without a call to [sendPrepared], which the UI makes on a tap.

abstract class _$WalletController extends $Notifier<WalletState> {
  WalletState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WalletState, WalletState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WalletState, WalletState>,
              WalletState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
