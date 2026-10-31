import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stawi/features/auth/data/current_user_provider.dart';
import 'package:stawi/features/rooms/data/room_providers.dart';
import 'package:stawi/features/rooms/domain/room.dart';
import 'package:stawi/features/socialtrader/data/socialtrader_api.dart';
import 'package:stawi/features/socialtrader/data/wallet_service.dart';
import 'package:stawi/features/socialtrader/domain/pool_models.dart';
import 'package:stawi/features/socialtrader/ui/pool_header_chip.dart';

import '../support/fake_socialtrader_api.dart';
import '../support/fake_wallet_platform.dart';

const roomId = 'room00000000000000aa';
const poolAddress = '0x00000000000000000000000000000000000000a1';
const pool = PoolInfo(
  address: poolAddress,
  marketId: '0x01',
  leader: '0x9999999999999999999999999999999999999999',
  navPerShare: '1.0500',
  memberCount: 3,
);

Room room({bool bound = true}) => Room(
  id: roomId,
  name: 'Traders',
  type: 'group',
  metadata: bound ? const {'socialtrader.pool_id': poolAddress} : null,
);

void main() {
  late FakeSocialTraderApi api;
  String? pushed;

  setUp(() {
    api = FakeSocialTraderApi()..pools.add(pool);
    pushed = null;
  });

  Future<void> pump(WidgetTester tester, {bool bound = true}) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: _Bar(),
            ),
          ),
        ),
        GoRoute(
          path: '/room/:roomId/pool',
          builder: (_, state) {
            pushed = state.uri.path;
            return const Scaffold(body: Text('pool tab'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          socialTraderApiProvider.overrideWithValue(api),
          walletPlatformProvider.overrideWithValue(FakeWalletPlatform()),
          currentProfileIdProvider.overrideWith((ref) async => 'p1'),
          roomByIdProvider.overrideWith((ref, id) async => room(bound: bound)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold)),
    );
    await container.read(walletControllerProvider.notifier).connect();
    await tester.pumpAndSettle();
  }

  testWidgets('headerChip_showsShareAndNav', (tester) async {
    api.memberships['$poolAddress:${FakeWalletPlatform.defaultAddress}'] =
        const PoolMembership(
          pool: poolAddress,
          wallet: FakeWalletPlatform.defaultAddress,
          shares: '10',
          shareBps: '1250',
          valueQuote: '10.5',
        );
    await pump(tester);
    expect(find.byKey(const Key('pool-header-chip')), findsOneWidget);
    expect(find.textContaining('1.0500'), findsOneWidget);
    expect(find.textContaining('12.5%'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pool-header-chip')));
    await tester.pumpAndSettle();
    expect(pushed, '/room/$roomId/pool');
  });

  testWidgets('headerChip_noShareForANonMember', (tester) async {
    await pump(tester);
    expect(find.textContaining('1.0500'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('headerChip_hiddenForAPlainRoom', (tester) async {
    await pump(tester, bound: false);
    expect(find.byKey(const Key('pool-header-chip')), findsNothing);
  });
}

class _Bar extends StatelessWidget {
  const _Bar();

  @override
  Widget build(BuildContext context) => AppBar(
    title: const Text('Traders'),
    actions: const [PoolHeaderChip(roomId: roomId)],
  );
}
