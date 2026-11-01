import '../../../core/networking/api_config.dart';
import 'wallet_service.dart';
import 'walletconnect/reown_appkit_facade.dart';
import 'walletconnect/wallet_connect_facade.dart';
import 'walletconnect/wallet_connect_platform.dart';

/// Builds the WalletConnect adapter for a project id; the real one is the
/// Reown AppKit adapter, tests pass a fake.
typedef WalletConnectFacadeBuilder = WalletConnectFacade Function(
  String projectId,
);

/// Non-web platforms: with a WalletConnect project id the signer is a wallet
/// app reached through the AppKit modal; without one the wallet is read-only
/// (a pasted address for portfolio views) and the message says so.
WalletPlatform createWalletPlatform({
  String projectId = ApiConfig.walletConnectProjectId,
  WalletConnectFacadeBuilder facadeBuilder = ReownAppKitFacade.new,
}) {
  if (projectId.isEmpty) return const _ReadOnlyWalletPlatform();
  return WalletConnectPlatform(facadeBuilder(projectId));
}

class _ReadOnlyWalletPlatform implements WalletPlatform {
  const _ReadOnlyWalletPlatform();

  static const _message =
      'Signing on this device needs WalletConnect, which this build was not '
      'given a project id for. Paste a wallet address to follow the pool, or '
      'open the app on the web with a browser wallet to sign.';

  @override
  bool get canSign => false;

  @override
  String get signerLabel => 'Read-only';

  @override
  Future<String> connect() async =>
      throw const WalletUnavailableException(_message);

  @override
  Future<String> sendTransaction({
    required String from,
    required PreparedTx tx,
  }) async => throw const WalletUnavailableException(_message);

  @override
  Future<String> personalSign({
    required String from,
    required String message,
  }) async => throw const WalletUnavailableException(_message);

  @override
  Future<void> disconnect() async {}
}
