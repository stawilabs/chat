import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/socialtrader/data/wallet_service.dart';

import '../support/fake_wallet_platform.dart';

const tx = PreparedTx(
  to: '0x2222222222222222222222222222222222222222',
  data: '0xdeadbeef',
  value: '0x0',
  chainId: 14601,
);

ProviderContainer containerWith(WalletPlatform platform) {
  final container = ProviderContainer(
    overrides: [walletPlatformProvider.overrideWithValue(platform)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('walletService_startsDisconnected', () {
    final container = containerWith(FakeWalletPlatform());
    final state = container.read(walletControllerProvider);
    expect(state.address, isNull);
    expect(state.isConnected, isFalse);
    expect(state.canSign, isFalse);
  });

  test('walletService_connectsAndSends', () async {
    final platform = FakeWalletPlatform();
    final container = containerWith(platform);
    final wallet = container.read(walletControllerProvider.notifier);

    await wallet.connect();
    final state = container.read(walletControllerProvider);
    expect(state.address, FakeWalletPlatform.defaultAddress);
    expect(state.isConnected, isTrue);
    expect(state.canSign, isTrue);
    expect(state.shortAddress, '0x1111…1111');

    final hash = await wallet.sendPrepared(tx);
    expect(hash, '0xhash1');
    expect(platform.sent, [tx]);
  });

  test('walletService_readOnlyCannotSend', () async {
    final container = containerWith(ReadOnlyWalletPlatform());
    final wallet = container.read(walletControllerProvider.notifier);

    wallet.setReadOnlyAddress('0x3333333333333333333333333333333333333333');
    final state = container.read(walletControllerProvider);
    expect(state.isConnected, isTrue);
    expect(state.canSign, isFalse, reason: 'a pasted address only reads');

    expect(
      () => wallet.sendPrepared(tx),
      throwsA(isA<WalletReadOnlyException>()),
    );
    expect(
      () => wallet.personalSign('hello'),
      throwsA(isA<WalletReadOnlyException>()),
    );
  });

  test('walletService_pastedAddressOnASigningPlatformStillReadsOnly', () async {
    final container = containerWith(FakeWalletPlatform());
    final wallet = container.read(walletControllerProvider.notifier);
    wallet.setReadOnlyAddress('0x3333333333333333333333333333333333333333');
    expect(container.read(walletControllerProvider).canSign, isFalse);
    expect(
      () => wallet.sendPrepared(tx),
      throwsA(isA<WalletReadOnlyException>()),
    );
  });

  test('walletService_rejectsAMalformedAddress', () {
    final container = containerWith(FakeWalletPlatform());
    final wallet = container.read(walletControllerProvider.notifier);
    expect(() => wallet.setReadOnlyAddress('0x12'), throwsArgumentError);
    expect(() => wallet.setReadOnlyAddress('nope'), throwsArgumentError);
    expect(container.read(walletControllerProvider).address, isNull);
  });

  test('walletService_disconnectedCannotSend', () {
    final container = containerWith(FakeWalletPlatform());
    final wallet = container.read(walletControllerProvider.notifier);
    expect(
      () => wallet.sendPrepared(tx),
      throwsA(isA<WalletNotConnectedException>()),
    );
  });

  test('walletService_connectFailureIsKeptAsError', () async {
    final platform = FakeWalletPlatform(
      failWith: const WalletUnavailableException('No wallet'),
    );
    final container = containerWith(platform);
    final wallet = container.read(walletControllerProvider.notifier);

    await wallet.connect();
    final state = container.read(walletControllerProvider);
    expect(state.isConnected, isFalse);
    expect(state.connecting, isFalse);
    expect(state.error, contains('No wallet'));
  });

  test('walletService_disconnectClearsEverything', () async {
    final container = containerWith(FakeWalletPlatform());
    final wallet = container.read(walletControllerProvider.notifier);
    await wallet.connect();
    wallet.disconnect();
    final state = container.read(walletControllerProvider);
    expect(state.address, isNull);
    expect(state.error, isNull);
  });

  test('walletService_personalSignUsesTheConnectedAddress', () async {
    final platform = FakeWalletPlatform();
    final container = containerWith(platform);
    final wallet = container.read(walletControllerProvider.notifier);
    await wallet.connect();
    expect(await wallet.personalSign('link me'), '0xsig');
    expect(platform.signed, ['link me']);
  });
}
