import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/socialtrader/data/wallet_platform_stub.dart';
import 'package:stawi/features/socialtrader/data/wallet_service.dart';
import 'package:stawi/features/socialtrader/data/walletconnect/wallet_connect_facade.dart';
import 'package:stawi/features/socialtrader/data/walletconnect/wallet_connect_platform.dart';

import '../support/fake_wallet_connect_facade.dart';

const chain = 14601;
const session = WalletConnectSession(
  address: FakeWalletConnectFacade.defaultAddress,
  chainId: chain,
  topic: 'topic-1',
);
const otherChainSession = WalletConnectSession(
  address: FakeWalletConnectFacade.defaultAddress,
  chainId: 1,
  topic: 'topic-2',
);
const tx = PreparedTx(
  to: '0x2222222222222222222222222222222222222222',
  data: '0xdeadbeef',
  value: '0x0',
  chainId: chain,
);

(ProviderContainer, FakeWalletConnectFacade) harness({
  WalletConnectSession? next = session,
}) {
  final facade = FakeWalletConnectFacade(nextSession: next);
  final container = ProviderContainer(
    overrides: [
      walletPlatformProvider.overrideWithValue(WalletConnectPlatform(facade)),
    ],
  );
  addTearDown(container.dispose);
  return (container, facade);
}

void main() {
  test('walletConnect_connectOpensTheModalAndStoresTheSession', () async {
    final (container, facade) = harness();
    final wallet = container.read(walletControllerProvider.notifier);
    expect(container.read(walletControllerProvider).signerAvailable, isTrue);

    await wallet.connect();

    expect(facade.initCalls, 1);
    expect(facade.modalOpens, 1);
    final state = container.read(walletControllerProvider);
    expect(state.address, FakeWalletConnectFacade.defaultAddress);
    expect(state.canSign, isTrue);
    expect(state.signerLabel, 'WalletConnect');
  });

  test('walletConnect_dismissedModalLeavesDisconnected', () async {
    final (container, facade) = harness(next: null);
    await container.read(walletControllerProvider.notifier).connect();
    expect(facade.modalOpens, 1);
    final state = container.read(walletControllerProvider);
    expect(state.isConnected, isFalse);
    expect(state.error, contains('No wallet was connected'));
  });

  test('walletConnect_reconnectReusesTheSession', () async {
    final (container, facade) = harness();
    final wallet = container.read(walletControllerProvider.notifier);
    await wallet.connect();
    await wallet.connect();
    expect(facade.modalOpens, 1, reason: 'an open session needs no modal');
    expect(facade.initCalls, 1);
  });

  test('walletConnect_sendUsesTheSessionWithoutSwitchOnTheSameChain', () async {
    final (container, facade) = harness();
    final wallet = container.read(walletControllerProvider.notifier);
    await wallet.connect();

    final hash = await wallet.sendPrepared(tx);

    expect(hash, '0xwc1');
    expect(facade.switched, isEmpty);
    expect(facade.sent.single.from, FakeWalletConnectFacade.defaultAddress);
    expect(facade.sent.single.to, tx.to);
    expect(facade.sent.single.data, tx.data);
    expect(facade.sent.single.chainId, chain);
  });

  test('walletConnect_sendSwitchesChainFirstWhenNeeded', () async {
    final (container, facade) = harness(next: otherChainSession);
    final wallet = container.read(walletControllerProvider.notifier);
    await wallet.connect();

    await wallet.sendPrepared(tx);

    expect(facade.switched, [
      chain,
    ], reason: 'switch/add to the prepared chain');
    expect(facade.sent.single.chainId, chain);
  });

  test('walletConnect_failedSwitchSendsNothing', () async {
    final (container, facade) = harness(next: otherChainSession);
    facade.switchFailWith = const WalletUnavailableException('rejected');
    final wallet = container.read(walletControllerProvider.notifier);
    await wallet.connect();

    await expectLater(
      wallet.sendPrepared(tx),
      throwsA(isA<WalletUnavailableException>()),
    );
    expect(facade.sent, isEmpty);
  });

  test('walletConnect_personalSignGoesThroughTheSession', () async {
    final (container, facade) = harness();
    final wallet = container.read(walletControllerProvider.notifier);
    await wallet.connect();
    expect(await wallet.personalSign('link me'), '0xwcsig');
    expect(facade.signed.single.from, FakeWalletConnectFacade.defaultAddress);
    expect(facade.signed.single.message, 'link me');
  });

  test('walletConnect_disconnectClearsTheSession', () async {
    final (container, facade) = harness();
    final wallet = container.read(walletControllerProvider.notifier);
    await wallet.connect();
    wallet.disconnect();
    await Future<void>.delayed(Duration.zero);
    expect(facade.disconnected, isTrue);
    expect(facade.session, isNull);
    expect(container.read(walletControllerProvider).isConnected, isFalse);
    expect(
      () => wallet.sendPrepared(tx),
      throwsA(isA<WalletNotConnectedException>()),
    );
  });

  test('walletConnect_sendWithoutSessionIsNotConnected', () async {
    final (container, _) = harness(next: null);
    final wallet = container.read(walletControllerProvider.notifier);
    expect(
      () => wallet.sendPrepared(tx),
      throwsA(isA<WalletNotConnectedException>()),
    );
  });

  group('createWalletPlatform', () {
    test('noProjectId_fallsBackToReadOnly', () {
      // ignore: avoid_redundant_argument_values, explicit for the reader
      final platform = createWalletPlatform(projectId: '');
      expect(platform.canSign, isFalse);
      expect(platform.signerLabel, 'Read-only');
      expect(
        platform.connect(),
        throwsA(
          isA<WalletUnavailableException>().having(
            (e) => e.message,
            'message',
            contains('WalletConnect'),
          ),
        ),
      );
    });

    test('projectId_buildsTheWalletConnectSigner', () {
      final platform = createWalletPlatform(
        projectId: 'test-project',
        facadeBuilder: (projectId) => FakeWalletConnectFacade(),
      );
      expect(platform, isA<WalletConnectPlatform>());
      expect(platform.canSign, isTrue);
    });
  });
}
