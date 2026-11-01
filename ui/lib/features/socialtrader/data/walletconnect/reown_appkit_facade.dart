import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:reown_appkit/reown_appkit.dart';

import '../../../../core/networking/api_config.dart';
import '../wallet_service.dart';
import 'wallet_connect_facade.dart';

/// The navigator the AppKit modal is shown from; the app's router installs
/// it on its root navigator.
final GlobalKey<NavigatorState> walletConnectNavigatorKey = GlobalKey(
  debugLabel: 'walletconnect',
);

/// The chain the pools live on, as AppKit describes a network.
ReownAppKitModalNetworkInfo stawiNetwork() => const ReownAppKitModalNetworkInfo(
  name: ApiConfig.stawiChainId == 14601 ? 'Sonic Testnet' : 'Stawi chain',
  chainId: '${ApiConfig.stawiChainId}',
  currency: 'S',
  rpcUrl: ApiConfig.stawiRpcUrl,
  explorerUrl: ApiConfig.stawiExplorerUrl,
  isTestNetwork: ApiConfig.stawiChainId == 14601,
);

/// [WalletConnectFacade] over Reown AppKit (WalletConnect v2). The modal is
/// created lazily from the root navigator's context; the project id comes
/// from the build (never from source). Keys never leave the wallet app.
class ReownAppKitFacade implements WalletConnectFacade {
  ReownAppKitFacade(this._projectId, {BuildContext Function()? contextOf})
    : _contextOf = contextOf ?? _rootContext;

  final String _projectId;
  final BuildContext Function() _contextOf;
  ReownAppKitModal? _modal;

  static BuildContext _rootContext() {
    final context = walletConnectNavigatorKey.currentContext;
    if (context == null) {
      throw const WalletUnavailableException(
        'The app is not ready to show the wallet picker yet.',
      );
    }
    return context;
  }

  static const _namespace = 'eip155';

  @override
  Future<void> init() async {
    if (_modal != null) return;
    // Pools live on one chain; the modal offers that chain only.
    ReownAppKitModalNetworks.removeSupportedNetworks(_namespace);
    ReownAppKitModalNetworks.addSupportedNetworks(_namespace, [stawiNetwork()]);
    final modal = ReownAppKitModal(
      context: _contextOf(),
      projectId: _projectId,
      metadata: const PairingMetadata(
        name: 'Stawi',
        description: 'Trading groups in Stawi chat',
        url: 'https://stawi.org',
        icons: ['https://stawi.org/icon.png'],
        redirect: Redirect(
          native: ApiConfig.walletConnectRedirect,
          universal: 'https://stawi.org/wc',
        ),
      ),
      optionalNamespaces: {
        _namespace: const RequiredNamespace(
          chains: ['$_namespace:${ApiConfig.stawiChainId}'],
          methods: [
            'eth_sendTransaction',
            'personal_sign',
            'wallet_switchEthereumChain',
            'wallet_addEthereumChain',
          ],
          events: ['chainChanged', 'accountsChanged'],
        ),
      },
    );
    await modal.init();
    _modal = modal;
  }

  ReownAppKitModal get _ready {
    final modal = _modal;
    if (modal == null) {
      throw const WalletNotConnectedException('WalletConnect is not ready');
    }
    return modal;
  }

  @override
  WalletConnectSession? get session {
    final modal = _modal;
    final live = modal?.session;
    if (modal == null || live == null || !modal.isConnected) return null;
    final address = live.getAddress(_namespace);
    final topic = live.topic;
    if (address == null || address.isEmpty || topic == null) return null;
    final chain = modal.selectedChain?.chainId ?? live.chainId;
    return WalletConnectSession(
      address: address.toLowerCase(),
      chainId: int.tryParse(chain) ?? ApiConfig.stawiChainId,
      topic: topic,
    );
  }

  @override
  Future<WalletConnectSession?> openModal() async {
    final modal = _ready;
    await modal.openModalView();
    // openModalView returns when the sheet closes, connected or not.
    return session;
  }

  @override
  Future<void> switchChain(int chainId) async {
    final modal = _ready;
    final target =
        ReownAppKitModalNetworks.getNetworkInfo(_namespace, '$chainId') ??
        stawiNetwork();
    try {
      // Switches, and adds the chain first when the wallet does not know it.
      await modal.requestSwitchToChain(target);
    } on Exception catch (e) {
      throw WalletUnavailableException(
        'The wallet did not switch to chain $chainId: $e',
      );
    }
  }

  @override
  Future<String> sendTransaction({
    required String from,
    required String to,
    required String data,
    required String value,
    required int chainId,
  }) async {
    final modal = _ready;
    final topic = session?.topic;
    if (topic == null) throw const WalletNotConnectedException();
    final result = await modal.request(
      topic: topic,
      chainId: '$_namespace:$chainId',
      request: SessionRequestParams(
        method: 'eth_sendTransaction',
        params: [
          {'from': from, 'to': to, 'data': data, 'value': value},
        ],
      ),
    );
    return _hexResult(result, 'transaction hash');
  }

  @override
  Future<String> personalSign({
    required String from,
    required String message,
  }) async {
    final modal = _ready;
    final live = session;
    if (live == null) throw const WalletNotConnectedException();
    final result = await modal.request(
      topic: live.topic,
      chainId: '$_namespace:${live.chainId}',
      request: SessionRequestParams(
        method: 'personal_sign',
        params: ['0x${_hex(utf8.encode(message))}', from],
      ),
    );
    return _hexResult(result, 'signature');
  }

  @override
  Future<void> disconnect() async {
    final modal = _modal;
    if (modal == null) return;
    await modal.disconnect();
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static String _hexResult(Object? result, String what) {
    if (result is String && result.startsWith('0x')) return result;
    throw WalletUnavailableException('The wallet returned no $what.');
  }
}
