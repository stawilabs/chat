import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/socialtrader/data/socialtrader_api.dart';
import 'package:stawi/features/socialtrader/data/wallet_service.dart';
import 'package:stawi/features/socialtrader/domain/pool_models.dart';
import 'package:stawi/features/socialtrader/ui/leave_pool_sheet.dart';

import '../support/fake_socialtrader_api.dart';
import '../support/fake_wallet_platform.dart';

const poolAddress = '0x00000000000000000000000000000000000000a1';
const pool = PoolInfo(
  address: poolAddress,
  marketId: '0x01',
  leader: '0x9999999999999999999999999999999999999999',
  navPerShare: '1.05',
  performanceFeeBps: 1000,
);

PoolMembership membership({
  String queued = '0',
  String previewAssets = '',
  String previewFee = '',
}) => PoolMembership(
  pool: poolAddress,
  wallet: FakeWalletPlatform.defaultAddress,
  shares: '12.5',
  shareBps: '1250',
  valueQuote: '13.1',
  queuedShares: queued,
  previewAssets: previewAssets,
  previewFee: previewFee,
);

Future<(FakeSocialTraderApi, FakeWalletPlatform)> pumpSheet(
  WidgetTester tester,
  PoolMembership m,
) async {
  final api = FakeSocialTraderApi()..pools.add(pool);
  final platform = FakeWalletPlatform();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        socialTraderApiProvider.overrideWithValue(api),
        walletPlatformProvider.overrideWithValue(platform),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: LeavePoolSheet(pool: pool, membership: m),
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

void main() {
  testWidgets('leaveSheet_showsValueAndFeePreview', (tester) async {
    await pumpSheet(tester, membership());
    expect(find.textContaining('12.5'), findsWidgets);
    expect(find.textContaining('13.1'), findsOneWidget);
    expect(find.textContaining('10%'), findsOneWidget, reason: 'fee preview');
    expect(find.textContaining('queued'), findsNothing);
  });

  testWidgets('leaveSheet_showsQueuedState', (tester) async {
    await pumpSheet(tester, membership(queued: '4'));
    expect(find.textContaining('4'), findsWidgets);
    expect(find.textContaining('queued'), findsOneWidget);
    expect(find.textContaining('leader sells'), findsOneWidget);
  });

  testWidgets('leaveSheet_redeemPreparesAndSignsOnTap', (tester) async {
    final (api, platform) = await pumpSheet(tester, membership());
    expect(api.redeems, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, 'Redeem'));
    await tester.pumpAndSettle();

    expect(api.redeems.single.pool, poolAddress);
    expect(api.redeems.single.shares, '12.5');
    expect(api.redeems.single.receiver, FakeWalletPlatform.defaultAddress);
    expect(api.redeems.single.minAssets, '', reason: 'no preview, no floor');
    expect(platform.sent, [api.preparedTx]);
    expect(find.textContaining('0xhash1'), findsOneWidget);
  });

  testWidgets('leaveSheet_walletErrorIsShown', (tester) async {
    final (api, platform) = await pumpSheet(tester, membership());
    platform.failWith = const WalletUnavailableException('Rejected');
    await tester.tap(find.widgetWithText(FilledButton, 'Redeem'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rejected'), findsOneWidget);
    expect(api.redeems, hasLength(1));
    expect(find.widgetWithText(FilledButton, 'Redeem'), findsOneWidget);
  });

  testWidgets('leaveSheet_showsExactRedeemPreview', (tester) async {
    await pumpSheet(
      tester,
      membership(previewAssets: '12.87', previewFee: '0.23'),
    );
    final preview = tester.widget<Text>(
      find.byKey(const Key('leave-pool-preview')),
    );
    expect(preview.data, contains('12.87'));
    expect(preview.data, contains('0.23'));
    expect(
      find.textContaining('10%'),
      findsNothing,
      reason: 'the exact figure replaces the estimate',
    );
  });

  testWidgets('leaveSheet_redeemFloorsAtNinetyNinePercentOfPreview', (
    tester,
  ) async {
    final (api, _) = await pumpSheet(
      tester,
      membership(previewAssets: '12.87', previewFee: '0.23'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Redeem'));
    await tester.pumpAndSettle();
    expect(api.redeems.single.minAssets, '12.7413');
  });
}
