import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';
import 'package:stawi/features/stawi/data/stawi_finance_service.dart';
import 'package:stawi/features/stawi/data/stawi_timeline_providers.dart';
import 'package:stawi/features/stawi/ui/dues_soon_card.dart';
import 'package:stawi_api/finance_v1.dart' as finance;

import '../../../support/stawi_fakes.dart';

const roomId = 'room00000000000000aa';

void main() {
  final now = DateTime.utc(2026, 10, 20, 8);

  finance.MemberProductDues product(
    String name, {
    required Duration dueIn,
    String toPay = '2000000',
  }) => finance.MemberProductDues(
    name: name,
    nextDueAt: Timestamp.fromDateTime(now.add(dueIn)),
    nextDueAmount: finance.Money(assetId: 'USDC.146', amount: '2000000'),
    owedAtNextDue: finance.Money(assetId: 'USDC.146', amount: toPay),
  );

  finance.MemberDues dues(List<finance.MemberProductDues> products) =>
      finance.MemberDues(rulesConfigured: true, products: products);

  group('duesDueSoon', () {
    test('within three days and still to pay, earliest first', () {
      final soon = duesDueSoon(
        dues([
          product('social_fund', dueIn: const Duration(days: 2)),
          product('shares', dueIn: const Duration(hours: 5)),
          product('later', dueIn: const Duration(days: 4)),
          product('paid_ahead', dueIn: const Duration(days: 1), toPay: '0'),
          product('past', dueIn: const Duration(hours: -1)),
        ]),
        now: now,
      );
      expect(soon.map((p) => p.name), ['shares', 'social_fund']);
    });
  });

  Future<void> pump(
    WidgetTester tester, {
    required StawiRoomPhase phase,
    required finance.MemberDues memberDues,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stawiRoomPhaseProvider.overrideWith(
            (ref, id) => AsyncValue.data(phase),
          ),
          stawiMyDuesProvider.overrideWith(
            (ref, id) async => finance.GetMemberDuesResponse(
              dues: memberDues,
              assets: [usdcInfo],
            ),
          ),
          stawiRoomAssetsProvider.overrideWith((ref, id) async => usdcAssets),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DuesSoonCard(
              roomId: roomId,
              roomName: 'Chama',
              now: () => now,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('says what to pay by when, with a way to pay', (tester) async {
    await pump(
      tester,
      phase: StawiRoomPhase.active,
      memberDues: dues([product('shares', dueIn: const Duration(days: 2))]),
    );
    expect(find.text('Dues due soon'), findsOneWidget);
    expect(
      find.textContaining('shares: 2.00 USDC by Thu 22 Oct'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('dues-soon-pay')), findsOneWidget);
  });

  testWidgets('nothing when nothing is due soon or the room is not on '
      'chain', (tester) async {
    await pump(
      tester,
      phase: StawiRoomPhase.active,
      memberDues: dues([product('shares', dueIn: const Duration(days: 6))]),
    );
    expect(find.byKey(const Key('dues-soon-card')), findsNothing);
    await pump(
      tester,
      phase: StawiRoomPhase.chatOnly,
      memberDues: dues([product('shares', dueIn: const Duration(days: 1))]),
    );
    expect(find.byKey(const Key('dues-soon-card')), findsNothing);
  });
}
