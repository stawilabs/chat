import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'wallet_service.dart';

@JS('ethereum')
external JSAny? get _ethereum;

/// Web: the injected EIP-1193 provider (MetaMask, Rabby, ...). It holds the
/// keys and signs; the app only passes requests and reads results.
WalletPlatform createWalletPlatform() => const _InjectedWalletPlatform();

class _InjectedWalletPlatform implements WalletPlatform {
  const _InjectedWalletPlatform();

  static const _noWallet = WalletUnavailableException(
    'No browser wallet found. Install MetaMask (or another EIP-1193 wallet) '
    'and reload.',
  );

  JSObject get _provider {
    final eth = _ethereum;
    if (eth == null) throw _noWallet;
    return eth as JSObject;
  }

  @override
  bool get canSign => _ethereum != null;

  @override
  String get signerLabel => 'Browser wallet';

  @override
  Future<String> connect() async {
    final result = await _request('eth_requestAccounts');
    final list = (result! as JSArray).toDart;
    if (list.isEmpty) throw const WalletUnavailableException('No accounts');
    return (list.first! as JSString).toDart;
  }

  @override
  Future<String> sendTransaction({
    required String from,
    required PreparedTx tx,
  }) async {
    await _switchChain(tx.chainId);
    final result = await _request('eth_sendTransaction', [
      <String, Object?>{
        'from': from,
        'to': tx.to,
        'data': tx.data,
        'value': tx.value.isEmpty ? '0x0' : tx.value,
      },
    ]);
    return (result! as JSString).toDart;
  }

  @override
  Future<String> personalSign({
    required String from,
    required String message,
  }) async {
    final result = await _request('personal_sign', [message, from]);
    return (result! as JSString).toDart;
  }

  @override
  Future<void> disconnect() async {
    // An injected provider keeps no session of ours to end.
  }

  /// Asks the wallet to be on [chainId] before a transaction, so the signed
  /// call lands on the chain the service prepared it for.
  Future<void> _switchChain(int chainId) async {
    final hex = '0x${chainId.toRadixString(16)}';
    final current = ((await _request('eth_chainId'))! as JSString).toDart;
    if (current.toLowerCase() == hex) return;
    await _request('wallet_switchEthereumChain', [
      <String, Object?>{'chainId': hex},
    ]);
  }

  Future<JSAny?> _request(String method, [List<Object?>? params]) {
    final request = JSObject()..setProperty('method'.toJS, method.toJS);
    if (params != null) request.setProperty('params'.toJS, params.jsify());
    return _provider
        .callMethod<JSPromise<JSAny?>>('request'.toJS, request)
        .toDart;
  }
}
