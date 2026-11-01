import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/socialtrader/data/socialtrader_api.dart';
import 'package:stawi/features/socialtrader/data/wallet_service.dart';
import 'package:stawi/features/socialtrader/domain/pool_models.dart';
import 'package:stawi/features/socialtrader/ui/leader_trade_sheet.dart';

import '../support/fake_socialtrader_api.dart';
import '../support/fake_wallet_platform.dart';

const poolAddress = '0x00000000000000000000000000000000000000a1';
const pool = PoolInfo(
  address: poolAddress,
  marketId: '0x01',
  leader: FakeWalletPlatform.defaultAddress,
  navPerShare: '1.05',
);

Future<(FakeSocialTraderApi, FakeWalletPlatform)> pumpSheet(
  WidgetTester tester, {
  PoolMembership? queued,
}) async {
  final api = FakeSocialTraderApi()..pools.add(pool);
  api.books['0x01'] = const OrderBook(
    bids: [BookLevel(price: '1999', size: '2')],
    asks: [BookLevel(price: '2001', size: '1')],
    bestBid: '1999',
    bestAsk: '2001',
    lastTradePrice: '2000',
  );
  final platform = FakeWalletPlatform();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        socialTraderApiProvider.overrideWithValue(api),
        walletPlatformProvider.overrideWithValue(platform),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LeaderTradeSheet(
              pool: pool,
              queuedShares: queued?.queuedShares ?? '0',
            ),
          ),
        ),
      ),
    ),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(Scaffold)),
  );
  await container.read(walletControllerProvider.notifier).connect();
  await tester.pumpAndSettle();
  return (api, platform);
}

TextField field(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(Key(key)));

void main() {
  testWidgets('leaderSheet_prefillsPriceFromBook', (tester) async {
    await pumpSheet(tester);
    expect(
      field(tester, 'leader-price').controller!.text,
      '2001',
      reason: 'a bid is pre-filled with the best ask',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('leader-hint'))).data,
      contains('1999'),
      reason: 'the hint is the best level on the same side',
    );

    await tester.tap(find.byKey(const Key('leader-side-sell')));
    await tester.pumpAndSettle();
    expect(
      field(tester, 'leader-price').controller!.text,
      '1999',
      reason: 'an ask is pre-filled with the best bid',
    );
  });

  testWidgets('leaderSheet_placesLimitWithHintFromBook', (tester) async {
    final (api, platform) = await pumpSheet(tester);
    await tester.enterText(find.byKey(const Key('leader-size')), '0.5');
    await tester.tap(find.widgetWithText(FilledButton, 'Place order'));
    await tester.pumpAndSettle();

    expect(api.leaderOrders, hasLength(1));
    final order = api.leaderOrders.single;
    expect(order.kind, LeaderOrderKind.limit);
    expect(order.isBid, isTrue);
    expect(order.price, '2001');
    expect(order.baseAmount, '0.5');
    expect(order.hintPrice, '1999', reason: 'the hint is the best bid');
    expect(platform.sent, [api.preparedTx]);
    expect(find.textContaining('0xhash1'), findsOneWidget);
  });

  testWidgets('leaderSheet_iocNeedsNoHint', (tester) async {
    final (api, _) = await pumpSheet(tester);
    await tester.tap(find.byKey(const Key('leader-kind-ioc')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('leader-size')), '1');
    await tester.tap(find.widgetWithText(FilledButton, 'Place order'));
    await tester.pumpAndSettle();
    expect(api.leaderOrders.single.kind, LeaderOrderKind.ioc);
    expect(api.leaderOrders.single.hintPrice, '');
  });

  testWidgets('leaderSheet_cancelByOrderId', (tester) async {
    final (api, _) = await pumpSheet(tester);
    await tester.enterText(find.byKey(const Key('leader-cancel-id')), '42');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel order'));
    await tester.pumpAndSettle();
    expect(api.leaderOrders.single.kind, LeaderOrderKind.cancel);
    expect(api.leaderOrders.single.orderId, 42);
  });

  testWidgets('leaderSheet_sellForRedeemsVisibleWhenQueued', (tester) async {
    await pumpSheet(tester);
    expect(
      find.widgetWithText(OutlinedButton, 'Sell inventory for redeems'),
      findsNothing,
    );

    final (api, _) = await pumpSheet(
      tester,
      queued: const PoolMembership(
        pool: poolAddress,
        wallet: FakeWalletPlatform.defaultAddress,
        queuedShares: '4',
      ),
    );
    final sell = find.widgetWithText(
      OutlinedButton,
      'Sell inventory for redeems',
    );
    expect(sell, findsOneWidget);
    await tester.ensureVisible(sell);
    await tester.tap(sell);
    await tester.pumpAndSettle();
    expect(api.leaderOrders.single.kind, LeaderOrderKind.sellForRedeems);
  });

  testWidgets('leaderSheet_rejectsMissingSize', (tester) async {
    final (api, _) = await pumpSheet(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Place order'));
    await tester.pumpAndSettle();
    expect(find.textContaining('size'), findsWidgets);
    expect(api.leaderOrders, isEmpty);
  });

  testWidgets('leaderSheet_settleQueueSendsBatch', (tester) async {
    final (api, platform) = await pumpSheet(tester);
    await tester.ensureVisible(find.byKey(const Key('leader-settle-queue')));
    await tester.tap(find.byKey(const Key('leader-settle-queue')));
    await tester.pumpAndSettle();
    expect(api.leaderOrders.single.kind, LeaderOrderKind.settleQueue);
    expect(api.leaderOrders.single.maxLevels, settleQueueBatch);
    expect(platform.sent, [api.preparedTx]);
  });
}
