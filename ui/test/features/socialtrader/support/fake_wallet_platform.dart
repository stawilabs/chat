import 'package:stawi/features/socialtrader/data/wallet_service.dart';

/// A signer standing in for the browser's injected wallet.
class FakeWalletPlatform implements WalletPlatform {
  FakeWalletPlatform({this.address = defaultAddress, this.failWith});

  static const defaultAddress = '0x1111111111111111111111111111111111111111';

  final String address;
  Exception? failWith;
  final sent = <PreparedTx>[];
  final signed = <String>[];

  @override
  bool get canSign => true;

  @override
  String get signerLabel => 'Fake wallet';

  @override
  Future<String> connect() async {
    if (failWith case final e?) throw e;
    return address;
  }

  @override
  Future<String> sendTransaction({
    required String from,
    required PreparedTx tx,
  }) async {
    if (failWith case final e?) throw e;
    sent.add(tx);
    return '0xhash${sent.length}';
  }

  @override
  Future<String> personalSign({
    required String from,
    required String message,
  }) async {
    if (failWith case final e?) throw e;
    signed.add(message);
    return '0xsig';
  }
}

/// A platform that cannot sign (mobile without WalletConnect).
class ReadOnlyWalletPlatform implements WalletPlatform {
  @override
  bool get canSign => false;

  @override
  String get signerLabel => 'Read-only';

  @override
  Future<String> connect() =>
      throw const WalletUnavailableException('Connect on web to sign');

  @override
  Future<String> sendTransaction({
    required String from,
    required PreparedTx tx,
  }) => throw const WalletUnavailableException('Connect on web to sign');

  @override
  Future<String> personalSign({
    required String from,
    required String message,
  }) => throw const WalletUnavailableException('Connect on web to sign');
}
