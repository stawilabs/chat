import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/auth/data/current_user_provider.dart';
import 'package:stawi/features/messages/data/message_providers.dart';
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/rooms/data/room_providers.dart';
import 'package:stawi/features/rooms/domain/room.dart';
import 'package:stawi/features/socialtrader/data/socialtrader_api.dart';
import 'package:stawi/features/socialtrader/data/wallet_service.dart';
import 'package:stawi/features/socialtrader/domain/pool_models.dart';
import 'package:stawi/features/socialtrader/ui/leader_trade_sheet.dart';
import 'package:stawi/features/socialtrader/ui/pool_tab.dart';

import '../support/fake_socialtrader_api.dart';
import '../support/fake_wallet_platform.dart';

const roomId = 'room00000000000000aa';
const poolAddress = '0x00000000000000000000000000000000000000a1';
const leaderWallet = FakeWalletPlatform.defaultAddress;
const otherWallet = '0x2222222222222222222222222222222222222222';

const pool = PoolInfo(
  address: poolAddress,
  marketId: '0x01',
  leader: leaderWallet,
  roomRef: roomId,
  nav: '1000',
  navPerShare: '1.0500',
  memberCount: 3,
  performanceFeeBps: 1000,
  tier: 'finalized',
);

const boundRoom = Room(
  id: roomId,
  name: 'Traders',
  type: 'group',
  metadata: {'socialtrader.pool_id': poolAddress},
);

RoomEvent fillEvent(String id, String side, String price, String size) =>
    RoomEvent(
      id: id,
      roomId: roomId,
      senderId: '',
      type: RoomEventType.text,
      createdAt: 1,
      status: EventStatus.delivered,
      content: {
        'format': 'json',
        'posted_by_service': true,
        'text':
            '{"socialtrader":{"kind":"pool_fill","v":1,"pool":"$poolAddress",'
            '"side":"$side","price":"$price","base_amount":"$size"}}',
      },
    );

const textEvent = RoomEvent(
  id: 'plain',
  roomId: roomId,
  senderId: '',
  type: RoomEventType.text,
  createdAt: 1,
  status: EventStatus.delivered,
  content: {'text': 'hello'},
);

Future<FakeSocialTraderApi> pumpTab(
  WidgetTester tester, {
  String wallet = leaderWallet,
  PoolMembership? membership,
  List<RoomEvent> events = const [],
}) async {
  final api = FakeSocialTraderApi()..pools.add(pool);
  api.performance = const PoolPerformance(
    series: [
      NavPoint(block: 1, at: null, navPerShare: '1.00', nav: '900'),
      NavPoint(block: 2, at: null, navPerShare: '1.02', nav: '950'),
      NavPoint(block: 3, at: null, navPerShare: '1.05', nav: '1000'),
    ],
    returnBps: '500',
    tier: 'finalized',
  );
  if (membership != null) {
    api.memberships['$poolAddress:${wallet.toLowerCase()}'] = membership;
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        socialTraderApiProvider.overrideWithValue(api),
        walletPlatformProvider.overrideWithValue(
          FakeWalletPlatform(address: wallet),
        ),
        currentProfileIdProvider.overrideWith((ref) async => 'p1'),
        roomByIdProvider.overrideWith((ref, id) async => boundRoom),
        paginatedMessagesStreamProvider.overrideWith(
          (ref, args) => Stream.value(events),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: PoolTab(roomId: roomId)),
      ),
    ),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(Scaffold)),
  );
  await container.read(walletControllerProvider.notifier).connect();
  await tester.pumpAndSettle();
  return api;
}

void main() {
  testWidgets('poolTab_showsMembersAndFills', (tester) async {
    await pumpTab(
      tester,
      wallet: otherWallet,
      membership: const PoolMembership(
        pool: poolAddress,
        wallet: otherWallet,
        shares: '10',
        shareBps: '1250',
        valueQuote: '10.5',
        queuedShares: '2',
      ),
      events: [
        fillEvent('f1', 'buy', '2000', '0.5'),
        textEvent,
        fillEvent('f2', 'sell', '2100', '0.25'),
      ],
    );
    expect(find.textContaining('1000'), findsWidgets, reason: 'pool value');
    expect(find.textContaining('+5.00%'), findsOneWidget);
    expect(find.byType(NavSparkline), findsOneWidget);
    expect(find.textContaining('3 members'), findsOneWidget);
    expect(find.textContaining('12.5%'), findsOneWidget, reason: 'my share');
    expect(find.byKey(const Key('pool-fill-f1')), findsOneWidget);
    expect(find.byKey(const Key('pool-fill-f2')), findsOneWidget);
    expect(find.textContaining('Bought 0.5 at 2000'), findsOneWidget);
    expect(find.textContaining('Sold 0.25 at 2100'), findsOneWidget);
    expect(find.textContaining('2 shares queued'), findsOneWidget);
  });

  testWidgets('poolTab_emptyFillsAndNoStake', (tester) async {
    await pumpTab(tester, wallet: otherWallet);
    expect(find.textContaining('No fills yet'), findsOneWidget);
    expect(find.textContaining('You hold no shares'), findsOneWidget);
  });

  testWidgets('poolTab_leaderActionsOnlyForLeader', (tester) async {
    await pumpTab(tester, wallet: otherWallet);
    expect(find.byKey(const Key('pool-leader-actions')), findsNothing);

    await pumpTab(tester);
    final actions = find.byKey(const Key('pool-leader-actions'));
    expect(actions, findsOneWidget);
    await tester.tap(actions);
    await tester.pumpAndSettle();
    expect(find.byType(LeaderTradeSheet), findsOneWidget);
  });

  testWidgets('poolTab_showsErrorWhenServiceFails', (tester) async {
    final api = FakeSocialTraderApi()..failWith = Exception('down');
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          socialTraderApiProvider.overrideWithValue(api),
          walletPlatformProvider.overrideWithValue(FakeWalletPlatform()),
          currentProfileIdProvider.overrideWith((ref) async => 'p1'),
          roomByIdProvider.overrideWith((ref, id) async => boundRoom),
          paginatedMessagesStreamProvider.overrideWith(
            (ref, args) => Stream.value(const []),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PoolTab(roomId: roomId)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining("couldn't"), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
  });
}
