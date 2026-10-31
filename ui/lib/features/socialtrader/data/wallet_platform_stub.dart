import 'wallet_service.dart';

/// Non-web platforms: there is no injected provider, and the WalletConnect
/// signer is not bundled in this build, so the wallet is read-only (a pasted
/// address for portfolio views). The message tells the person where to sign.
WalletPlatform createWalletPlatform() => const _ReadOnlyWalletPlatform();

class _ReadOnlyWalletPlatform implements WalletPlatform {
  const _ReadOnlyWalletPlatform();

  static String get _message => walletConnectProjectId.isEmpty
      ? 'Signing on this device needs WalletConnect, which this build does '
            'not carry. Paste a wallet address to follow the pool, or open '
            'the app on the web with a browser wallet to sign.'
      : 'WalletConnect is configured but its signer is not bundled in this '
            'build yet. Open the app on the web with a browser wallet to sign.';

  @override
  bool get canSign => false;

  @override
  String get signerLabel => 'Read-only';

  @override
  Future<String> connect() async => throw WalletUnavailableException(_message);

  @override
  Future<String> sendTransaction({
    required String from,
    required PreparedTx tx,
  }) async => throw WalletUnavailableException(_message);

  @override
  Future<String> personalSign({
    required String from,
    required String message,
  }) async => throw WalletUnavailableException(_message);
}
