import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/auth/data/current_user_provider.dart';
import 'package:stawi/features/rooms/data/room_providers.dart';
import 'package:stawi/features/rooms/domain/room.dart';
import 'package:stawi/features/socialtrader/data/commitment_settings.dart';
import 'package:stawi/features/socialtrader/data/pool_prompt_dismissals.dart';
import 'package:stawi/features/socialtrader/data/socialtrader_api.dart';
import 'package:stawi/features/socialtrader/data/wallet_service.dart';
import 'package:stawi/features/socialtrader/domain/pool_models.dart';
import 'package:stawi/features/socialtrader/ui/join_pool_sheet.dart';

import '../support/fake_socialtrader_api.dart';
import '../support/fake_wallet_platform.dart';

const roomId = 'room00000000000000aa';
const poolAddress = '0x00000000000000000000000000000000000000a1';
const profileId = 'profile-1';

const pool = PoolInfo(
  address: poolAddress,
  marketId: '0x01',
  leader: '0x9999999999999999999999999999999999999999',
  roomRef: roomId,
  navPerShare: '1.05',
  memberCount: 3,
  performanceFeeBps: 1000,
);

const boundRoom = Room(
  id: roomId,
  name: 'Traders',
  type: 'group',
  metadata: {'socialtrader.pool_id': poolAddress},
);

class Harness {
  Harness({WalletPlatform? platform, this.room = boundRoom})
    : platform = platform ?? FakeWalletPlatform();

  final Room room;

  final api = FakeSocialTraderApi()..pools.add(pool);
  final settings = MemoryCommitmentSettings();
  final dismissals = MemoryPoolPromptDismissals();
  final WalletPlatform platform;

  List<Override> get overrides => [
    socialTraderApiProvider.overrideWithValue(api),
    commitmentSettingsProvider.overrideWithValue(settings),
    poolPromptDismissalsProvider.overrideWithValue(dismissals),
    walletPlatformProvider.overrideWithValue(platform),
    currentProfileIdProvider.overrideWith((ref) async => profileId),
    roomByIdProvider.overrideWith((ref, id) async => room),
  ];

  Widget host(Widget child) => ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

Future<void> connectWallet(WidgetTester tester) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(Scaffold).first),
  );
  await container.read(walletControllerProvider.notifier).connect();
  await tester.pump();
}

void main() {
  testWidgets('joinSheet_prefillsDefaultCommitment', (tester) async {
    final h = Harness();
    await h.settings.save(profileId, '250');
    await tester.pumpWidget(
      h.host(const JoinPoolSheet(roomId: roomId, pool: pool)),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const Key('join-pool-amount')),
    );
    expect(field.controller!.text, '250');
    expect(find.textContaining('1.05'), findsOneWidget);
  });

  testWidgets('joinSheet_requiresTapToSign', (tester) async {
    final h = Harness();
    await h.settings.save(profileId, '250');
    await tester.pumpWidget(
      h.host(const JoinPoolSheet(roomId: roomId, pool: pool)),
    );
    await connectWallet(tester);
    await tester.pumpAndSettle();

    final platform = h.platform as FakeWalletPlatform;
    expect(
      h.api.deposits,
      isEmpty,
      reason: 'opening the sheet prepares nothing',
    );
    expect(platform.sent, isEmpty, reason: 'nothing is sent without a tap');

    await tester.tap(find.widgetWithText(FilledButton, 'Commit'));
    await tester.pumpAndSettle();

    expect(h.api.deposits, hasLength(1));
    expect(h.api.deposits.single.pool, poolAddress);
    expect(h.api.deposits.single.assets, '250');
    expect(h.api.deposits.single.receiver, FakeWalletPlatform.defaultAddress);
    expect(platform.sent, [h.api.preparedTx]);
    expect(find.textContaining('0xhash1'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Commit'), findsNothing);
  });

  testWidgets('joinSheet_rememberSavesTheAmount', (tester) async {
    final h = Harness();
    await tester.pumpWidget(
      h.host(const JoinPoolSheet(roomId: roomId, pool: pool)),
    );
    await connectWallet(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('join-pool-amount')), '75');
    await tester.tap(find.byKey(const Key('join-pool-remember')));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Commit'));
    await tester.pumpAndSettle();

    expect(await h.settings.defaultFor(profileId), '75');
  });

  testWidgets('joinSheet_rejectsAnInvalidAmount', (tester) async {
    final h = Harness();
    await tester.pumpWidget(
      h.host(const JoinPoolSheet(roomId: roomId, pool: pool)),
    );
    await connectWallet(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('join-pool-amount')), '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Commit'));
    await tester.pumpAndSettle();

    expect(find.textContaining('positive amount'), findsOneWidget);
    expect(h.api.deposits, isEmpty);
  });

  testWidgets('joinSheet_walletErrorKeepsAmount', (tester) async {
    final h = Harness();
    await tester.pumpWidget(
      h.host(const JoinPoolSheet(roomId: roomId, pool: pool)),
    );
    await connectWallet(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('join-pool-amount')), '120');

    final platform = h.platform as FakeWalletPlatform;
    platform.failWith = const WalletUnavailableException('Wallet disconnected');
    await tester.tap(find.widgetWithText(FilledButton, 'Commit'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Wallet disconnected'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const Key('join-pool-amount')),
    );
    expect(field.controller!.text, '120', reason: 'the amount is kept');
    expect(h.api.deposits, hasLength(1), reason: 'exactly one attempt');
    expect(platform.sent, isEmpty);
    expect(
      find.widgetWithText(FilledButton, 'Commit'),
      findsOneWidget,
      reason: 'the person may try again; nothing retries by itself',
    );
    await tester.pump(const Duration(seconds: 5));
    expect(h.api.deposits, hasLength(1), reason: 'no retry loop');
  });

  testWidgets('joinSheet_readOnlyWalletExplains', (tester) async {
    final h = Harness(platform: ReadOnlyWalletPlatform());
    await tester.pumpWidget(
      h.host(const JoinPoolSheet(roomId: roomId, pool: pool)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('cannot sign'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Commit'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Connect wallet'), findsNothing);
    expect(h.api.deposits, isEmpty);
  });

  testWidgets('joinSheet_offersConnectWhenDisconnected', (tester) async {
    final h = Harness();
    await tester.pumpWidget(
      h.host(const JoinPoolSheet(roomId: roomId, pool: pool)),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Commit'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Connect wallet'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Commit'), findsOneWidget);
    expect(find.textContaining('0x1111…1111'), findsOneWidget);
  });

  group('PoolJoinPromptGate', () {
    Future<void> pumpGate(WidgetTester tester, Harness h) async {
      await tester.pumpWidget(
        h.host(
          const Column(
            children: [
              PoolJoinPromptGate(roomId: roomId),
              Text('timeline'),
            ],
          ),
        ),
      );
      await connectWallet(tester);
      await tester.pumpAndSettle();
    }

    testWidgets('joinSheet_shownOncePerRoomForANewMember', (tester) async {
      final h = Harness();
      await pumpGate(tester, h);
      expect(find.byType(JoinPoolSheet), findsOneWidget);
      expect(h.api.deposits, isEmpty, reason: 'the prompt commits nothing');

      await tester.tap(find.widgetWithText(TextButton, 'Not now'));
      await tester.pumpAndSettle();
      expect(find.byType(JoinPoolSheet), findsNothing);
      expect(await h.dismissals.dismissed(roomId), isTrue);

      await pumpGate(tester, h);
      expect(
        find.byType(JoinPoolSheet),
        findsNothing,
        reason: 'dismissed once, not shown again',
      );
    });

    testWidgets('joinSheet_hiddenWhenMemberHoldsShares', (tester) async {
      final h = Harness();
      h.api.memberships['$poolAddress:${FakeWalletPlatform.defaultAddress}'] =
          const PoolMembership(
            pool: poolAddress,
            wallet: FakeWalletPlatform.defaultAddress,
            shares: '10',
            shareBps: '1250',
            valueQuote: '10.5',
          );
      await pumpGate(tester, h);
      expect(find.byType(JoinPoolSheet), findsNothing);
    });

    testWidgets('joinSheet_hiddenForAPlainRoom', (tester) async {
      final h = Harness(
        room: const Room(id: roomId, name: 'Plain', type: 'group'),
      );
      await pumpGate(tester, h);
      expect(find.byType(JoinPoolSheet), findsNothing);
    });
  });
}
