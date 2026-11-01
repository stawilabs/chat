import '../wallet_service.dart';
import 'wallet_connect_facade.dart';

/// The non-web signer: a wallet app reached over WalletConnect through the
/// AppKit modal. Connecting opens the modal (or reuses the live session);
/// sending switches the wallet to the prepared transaction's chain first when
/// it is elsewhere; nothing is sent without a call from a tap.
class WalletConnectPlatform implements WalletPlatform {
  WalletConnectPlatform(this._facade);

  final WalletConnectFacade _facade;
  bool _initialised = false;

  @override
  bool get canSign => true;

  @override
  String get signerLabel => 'WalletConnect';

  Future<void> _ensureInit() async {
    if (_initialised) return;
    await _facade.init();
    _initialised = true;
  }

  @override
  Future<String> connect() async {
    await _ensureInit();
    final live = _facade.session;
    if (live != null) return live.address;
    final session = await _facade.openModal();
    if (session == null) {
      throw const WalletUnavailableException(
        'No wallet was connected. Open the modal again and approve the '
        'connection in your wallet.',
      );
    }
    return session.address;
  }

  WalletConnectSession _requireSession() {
    final session = _facade.session;
    if (session == null) throw const WalletNotConnectedException();
    return session;
  }

  @override
  Future<String> sendTransaction({
    required String from,
    required PreparedTx tx,
  }) async {
    await _ensureInit();
    var session = _requireSession();
    if (session.chainId != tx.chainId) {
      await _facade.switchChain(tx.chainId);
      session = _requireSession();
    }
    return _facade.sendTransaction(
      from: from,
      to: tx.to,
      data: tx.data,
      value: tx.value.isEmpty ? '0x0' : tx.value,
      chainId: tx.chainId,
    );
  }

  @override
  Future<String> personalSign({
    required String from,
    required String message,
  }) async {
    await _ensureInit();
    _requireSession();
    return _facade.personalSign(from: from, message: message);
  }

  @override
  Future<void> disconnect() => _facade.disconnect();
}
