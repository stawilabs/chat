import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stawi/features/contacts/data/roster_repository.dart';
import 'package:stawi/features/rooms/data/group_room_creator.dart';
import 'package:stawi/features/rooms/domain/room.dart';
import 'package:stawi/features/rooms/ui/group_details_screen.dart';
import 'package:stawi/features/socialtrader/data/socialtrader_api.dart';
import 'package:stawi/features/socialtrader/data/socialtrader_capabilities.dart';
import 'package:stawi/features/socialtrader/domain/pool_models.dart';

import '../support/fake_socialtrader_api.dart';

final amina = RosterEntry(
  id: '1',
  contactId: 'c-1',
  profileId: 'p-1',
  contactType: RosterContactType.msisdn,
  contactDetail: '+256700000001',
  displayName: 'Amina',
);

class RecordingCreator {
  final requests = <GroupRoomRequest>[];
  Future<Room> call(GroupRoomRequest request) async {
    requests.add(request);
    return Room(
      id: request.id ?? 'generated',
      name: request.name,
      type: 'group',
    );
  }
}

Future<(FakeSocialTraderApi, RecordingCreator)> pump(
  WidgetTester tester, {
  required Set<String> capabilities,
}) async {
  final api = FakeSocialTraderApi()
    ..markets.add(
      const MarketInfo(
        id: 'm1',
        marketId: '0x01',
        symbol: 'WETH/USDC',
        baseSymbol: 'WETH',
        quoteSymbol: 'USDC',
      ),
    );
  final creator = RecordingCreator();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => GroupDetailsScreen(selectedContacts: [amina]),
      ),
      GoRoute(
        path: '/chat/:roomId',
        builder: (_, state) =>
            Scaffold(body: Text('chat ${state.pathParameters['roomId']}')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        socialTraderApiProvider.overrideWithValue(api),
        socialTraderCapabilitiesProvider.overrideWith(
          (ref) async => capabilities,
        ),
        createGroupRoomProvider.overrideWithValue(creator.call),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return (api, creator);
}

void main() {
  testWidgets('createRoom_tradingGroupToggleHiddenWithoutCapability', (
    tester,
  ) async {
    await pump(tester, capabilities: const {});
    expect(find.byKey(const Key('create-trading-group')), findsNothing);
    expect(find.text('Trading group'), findsNothing);
  });

  testWidgets('createRoom_tradingGroupToggleShownWithCapability', (
    tester,
  ) async {
    await pump(tester, capabilities: const {createPoolCapability});
    expect(find.byKey(const Key('create-trading-group')), findsOneWidget);
    expect(find.byKey(const Key('create-trading-market')), findsNothing);

    await tester.tap(find.byKey(const Key('create-trading-group')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('create-trading-market')), findsOneWidget);
    expect(find.byKey(const Key('create-trading-fee')), findsOneWidget);
  });

  testWidgets('createRoom_plainGroupCreatesNoPool', (tester) async {
    final (api, creator) = await pump(
      tester,
      capabilities: const {createPoolCapability},
    );
    await tester.enterText(find.byKey(const Key('group-name')), 'Friends');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-group')));
    await tester.pumpAndSettle();

    expect(api.createPools, isEmpty);
    expect(creator.requests.single.metadata, isNull);
    expect(find.textContaining('chat '), findsOneWidget);
  });

  testWidgets('createRoom_tradingGroupCreatesPoolThenBoundRoom', (
    tester,
  ) async {
    final (api, creator) = await pump(
      tester,
      capabilities: const {createPoolCapability},
    );
    await tester.enterText(find.byKey(const Key('group-name')), 'Traders');
    await tester.tap(find.byKey(const Key('create-trading-group')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-trading-market')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WETH/USDC').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('create-trading-fee')), '12.5');
    await tester.tap(find.byKey(const Key('create-group')));
    await tester.pumpAndSettle();

    expect(api.createPools, hasLength(1));
    final created = api.createPools.single;
    expect(created.marketId, '0x01');
    expect(created.feeBps, 1250);
    final request = creator.requests.single;
    expect(
      request.id,
      created.roomRef,
      reason: 'the pool is created for the very room id the room gets',
    );
    expect(request.metadata?['socialtrader.pool_id'], api.created.pool);
    expect(find.textContaining('chat ${request.id}'), findsOneWidget);
  });

  testWidgets('createRoom_tradingGroupNeedsAMarket', (tester) async {
    final (api, creator) = await pump(
      tester,
      capabilities: const {createPoolCapability},
    );
    await tester.enterText(find.byKey(const Key('group-name')), 'Traders');
    await tester.tap(find.byKey(const Key('create-trading-group')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-group')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Choose a market'), findsWidgets);
    expect(api.createPools, isEmpty);
    expect(creator.requests, isEmpty);
  });

  testWidgets('createRoom_poolFailureCreatesNoRoom', (tester) async {
    final (api, creator) = await pump(
      tester,
      capabilities: const {createPoolCapability},
    );
    await tester.enterText(find.byKey(const Key('group-name')), 'Traders');
    await tester.tap(find.byKey(const Key('create-trading-group')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-trading-market')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WETH/USDC').last);
    await tester.pumpAndSettle();
    api.failWith = Exception('creator key unavailable');
    await tester.tap(find.byKey(const Key('create-group')));
    await tester.pumpAndSettle();

    expect(creator.requests, isEmpty, reason: 'no room without its pool');
    expect(find.textContaining('creator key unavailable'), findsOneWidget);
  });
}
