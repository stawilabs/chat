import 'package:stawi/features/socialtrader/data/walletconnect/wallet_connect_facade.dart';

/// An AppKit standing in for the real modal: the modal "connects" to
/// [nextSession] when opened, requests are recorded, and any step can be made
/// to fail.
class FakeWalletConnectFacade implements WalletConnectFacade {
  FakeWalletConnectFacade({this.nextSession});

  static const defaultAddress = '0x4444444444444444444444444444444444444444';

  WalletConnectSession? nextSession;
  WalletConnectSession? _session;
  int initCalls = 0;
  int modalOpens = 0;
  final switched = <int>[];
  final sent =
      <({String from, String to, String data, String value, int chainId})>[];
  final signed = <({String from, String message})>[];
  bool disconnected = false;
  Exception? failWith;
  Exception? switchFailWith;

  void _maybeFail() {
    if (failWith case final e?) throw e;
  }

  @override
  Future<void> init() async {
    initCalls++;
  }

  @override
  WalletConnectSession? get session => _session;

  @override
  Future<WalletConnectSession?> openModal() async {
    _maybeFail();
    modalOpens++;
    return _session = nextSession;
  }

  @override
  Future<void> switchChain(int chainId) async {
    if (switchFailWith case final e?) throw e;
    switched.add(chainId);
    final s = _session;
    if (s != null) {
      _session = WalletConnectSession(
        address: s.address,
        chainId: chainId,
        topic: s.topic,
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
    _maybeFail();
    sent.add((from: from, to: to, data: data, value: value, chainId: chainId));
    return '0xwc${sent.length}';
  }

  @override
  Future<String> personalSign({
    required String from,
    required String message,
  }) async {
    _maybeFail();
    signed.add((from: from, message: message));
    return '0xwcsig';
  }

  @override
  Future<void> disconnect() async {
    disconnected = true;
    _session = null;
  }
}
