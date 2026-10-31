// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_link.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The wallet linked to the signed-in profile, null when none.

@ProviderFor(linkedWallet)
final linkedWalletProvider = LinkedWalletProvider._();

/// The wallet linked to the signed-in profile, null when none.

final class LinkedWalletProvider
    extends
        $FunctionalProvider<
          AsyncValue<LinkedWallet?>,
          LinkedWallet?,
          FutureOr<LinkedWallet?>
        >
    with $FutureModifier<LinkedWallet?>, $FutureProvider<LinkedWallet?> {
  /// The wallet linked to the signed-in profile, null when none.
  LinkedWalletProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'linkedWalletProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$linkedWalletHash();

  @$internal
  @override
  $FutureProviderElement<LinkedWallet?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LinkedWallet?> create(Ref ref) {
    return linkedWallet(ref);
  }
}

String _$linkedWalletHash() => r'93827d4f1d0a0dade1dfa488015af37f573914c3';

/// Links the connected wallet to the profile with Sign-In with Ethereum: the
/// service issues the message, the wallet signs it (personal_sign), the
/// service verifies and records the link. The app sees only the signature.

@ProviderFor(WalletLinkController)
final walletLinkControllerProvider = WalletLinkControllerProvider._();

/// Links the connected wallet to the profile with Sign-In with Ethereum: the
/// service issues the message, the wallet signs it (personal_sign), the
/// service verifies and records the link. The app sees only the signature.
final class WalletLinkControllerProvider
    extends $NotifierProvider<WalletLinkController, LinkState> {
  /// Links the connected wallet to the profile with Sign-In with Ethereum: the
  /// service issues the message, the wallet signs it (personal_sign), the
  /// service verifies and records the link. The app sees only the signature.
  WalletLinkControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletLinkControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletLinkControllerHash();

  @$internal
  @override
  WalletLinkController create() => WalletLinkController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LinkState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LinkState>(value),
    );
  }
}

String _$walletLinkControllerHash() =>
    r'e4f01a6b9f2259b4219b628df08b304662a60afc';

/// Links the connected wallet to the profile with Sign-In with Ethereum: the
/// service issues the message, the wallet signs it (personal_sign), the
/// service verifies and records the link. The app sees only the signature.

abstract class _$WalletLinkController extends $Notifier<LinkState> {
  LinkState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LinkState, LinkState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LinkState, LinkState>,
              LinkState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
