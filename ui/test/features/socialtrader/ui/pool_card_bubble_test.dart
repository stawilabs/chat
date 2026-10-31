import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/socialtrader/data/socialtrader_api.dart';
import 'package:stawi/features/socialtrader/domain/pool_card.dart';
import 'package:stawi/features/socialtrader/domain/pool_models.dart';
import 'package:stawi/features/socialtrader/ui/pool_card_bubble.dart';

import '../support/fake_socialtrader_api.dart';

const roomId = 'room00000000000000aa';
const knownPool = '0x00000000000000000000000000000000000000a1';
const unknownPool = '0x00000000000000000000000000000000000000ff';

RoomEvent cardEvent(String body, {String id = 'card-1'}) => RoomEvent(
  id: id,
  roomId: roomId,
  senderId: '',
  type: RoomEventType.text,
  createdAt: 1,
  status: EventStatus.delivered,
  content: {'text': body, 'format': 'json'},
);

String joinBody(String pool) =>
    '{"socialtrader":{"kind":"pool_join_prompt","v":1,"pool":"$pool",'
    '"market_symbol":"WETH/USDC","nav_per_share":"1.0250","member_count":4}}';

String navBody(String tier) =>
    '{"socialtrader":{"kind":"pool_nav","v":1,"pool":"$knownPool",'
    '"nav":"1000","nav_per_share":"1.05","return_bps":"500","tier":"$tier",'
    '"as_of_block":123}}';

const fillBody =
    '{"socialtrader":{"kind":"pool_fill","v":1,"pool":"$knownPool",'
    '"side":"buy","price":"2000.5","base_amount":"0.5","quote_amount":"1000.25",'
    '"tx_hash":"0xabc","block":124}}';

const leaveBody =
    '{"socialtrader":{"kind":"pool_leave_prompt","v":1,"pool":"$knownPool",'
    '"shares":"12.5","value_quote":"13.1"}}';

const knownPoolInfo = PoolInfo(
  address: knownPool,
  marketId: '0x01',
  leader: '0x1111111111111111111111111111111111111111',
  roomRef: roomId,
  nav: '1000',
  navPerShare: '1.05',
  totalShares: '952',
  memberCount: 4,
  performanceFeeBps: 1000,
  tier: 'finalized',
);

Widget host(Widget child, {required FakeSocialTraderApi api}) => ProviderScope(
  overrides: <Override>[socialTraderApiProvider.overrideWithValue(api)],
  child: MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  late FakeSocialTraderApi api;

  setUp(() {
    api = FakeSocialTraderApi()..pools.add(knownPoolInfo);
  });

  testWidgets('cardBubble_joinPromptShowsCommit', (tester) async {
    PoolCard? committed;
    await tester.pumpWidget(
      host(
        PoolCardBubble(
          event: cardEvent(joinBody(knownPool)),
          isMe: false,
          onCommit: (card) => committed = card,
        ),
        api: api,
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pool-card-card-1')), findsOneWidget);
    expect(find.text('WETH/USDC'), findsOneWidget);
    expect(find.textContaining('1.0250'), findsOneWidget);
    expect(find.textContaining('4 members'), findsOneWidget);
    final commit = find.widgetWithText(FilledButton, 'Commit');
    expect(commit, findsOneWidget);
    expect(committed, isNull, reason: 'nothing happens before a tap');

    await tester.tap(commit);
    await tester.pump();
    expect(committed, isA<JoinPromptCard>());
  });

  testWidgets('cardBubble_leavePromptShowsRedeem', (tester) async {
    PoolCard? redeemed;
    await tester.pumpWidget(
      host(
        PoolCardBubble(
          event: cardEvent(leaveBody),
          isMe: false,
          onRedeem: (card) => redeemed = card,
        ),
        api: api,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('12.5'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Redeem'));
    await tester.pump();
    expect(redeemed, isA<LeavePromptCard>());
  });

  testWidgets('cardBubble_navBadgeGreenOnlyWhenFinalized', (tester) async {
    await tester.pumpWidget(
      host(
        PoolCardBubble(event: cardEvent(navBody('finalized')), isMe: false),
        api: api,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('+5.00%'), findsOneWidget);
    expect(find.textContaining('1.05'), findsOneWidget);
    var badge = tester.widget<TierBadge>(find.byType(TierBadge));
    expect(badge.tier, 'finalized');
    expect(badge.isVerified, isTrue);
    expect(find.text('finalized'), findsOneWidget);

    await tester.pumpWidget(
      host(
        PoolCardBubble(
          event: cardEvent(navBody('pending'), id: 'card-2'),
          isMe: false,
        ),
        api: api,
      ),
    );
    await tester.pumpAndSettle();
    badge = tester.widget<TierBadge>(find.byType(TierBadge));
    expect(badge.tier, 'pending');
    expect(badge.isVerified, isFalse, reason: 'only finalized is green');
    expect(find.text('pending'), findsOneWidget);
  });

  testWidgets('cardBubble_fillShowsSidePriceSize', (tester) async {
    await tester.pumpWidget(
      host(PoolCardBubble(event: cardEvent(fillBody), isMe: false), api: api),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Bought'),
      findsOneWidget,
      reason: 'the title names the side',
    );
    expect(find.text('Bought 0.5 at 2000.5 for 1000.25'), findsOneWidget);
  });

  testWidgets('cardBubble_unknownPoolFallsBackToText', (tester) async {
    await tester.pumpWidget(
      host(
        PoolCardBubble(event: cardEvent(joinBody(unknownPool)), isMe: false),
        api: api,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byKey(const Key('pool-card-card-1')), findsNothing);
    expect(
      find.byKey(const Key('pool-card-fallback-card-1')),
      findsOneWidget,
      reason: 'the body is shown as plain text, never as an interactive card',
    );
    expect(find.textContaining('pool_join_prompt'), findsOneWidget);
  });

  testWidgets('cardBubble_lookupErrorShowsRetry', (tester) async {
    api.failWith = Exception('service down');
    await tester.pumpWidget(
      host(
        PoolCardBubble(event: cardEvent(joinBody(knownPool)), isMe: false),
        api: api,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FilledButton), findsNothing);
    expect(find.textContaining("couldn't"), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);

    api.failWith = null;
    await tester.tap(find.widgetWithText(TextButton, 'Retry'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Commit'), findsOneWidget);
  });
}
