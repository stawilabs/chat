import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_dues_plan_service.dart';
import 'package:stawi/features/stawi/data/stawi_finance_service.dart';
import 'package:stawi/features/stawi/domain/intent_bridge.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi/features/stawi/ui/dues_autopay_switch.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:xid/xid.dart';

import '../../../support/stawi_fakes.dart';

const roomId = 'room00000000000000aa';

void main() {
  final v = GoEngineCallVector.load().firstWhere(
    (v) => v.name == 'loan_request',
  );
  final custody = Uint8List(20)..[19] = 0x31;
  final room = RoomContracts(
    governance: Uint8List(20)..[19] = 0x30,
    custody: custody,
    chainId: BigInt.parse(v.intent.domain.chainId.toStringUnsigned()),
  );
  final intentId = Xid.fromString('d3m1q8n2v0s4c5k6p7a0');

  finance.FinancialIntent intent(finance.IntentType type) {
    final i = v.intent.deepCopy()
      ..intentId = intentId.toBytes()
      ..type = type
      ..mode = finance.AuthorizationMode.AUTHORIZATION_MODE_DIRECT_SIGNATURE
      ..account = v.account
      ..destination = finance.ValueLocation(
        kind: finance.LocationKind.LOCATION_KIND_ROOM_CUSTODY,
        address: custody,
      )
      ..amount = '0';
    return i..intentDigest = intentDigestOf(sdkIntentOf(i));
  }

  late FakeConnectTransport transport;
  late RecordingSigningGate gate;
  late List<finance.SavingsPlan> plans;

  setUp(() {
    gate = RecordingSigningGate();
    plans = [];
    transport = FakeConnectTransport()
      ..on(
        finance.SavingsService.listPlans,
        (req) => finance.ListPlansResponse(plans: plans),
      )
      ..on(finance.SavingsService.createPlan, (req) {
        plans = [
          finance.SavingsPlan(
            planId: 'plan0000000000000001',
            state: finance.PlanState.PLAN_STATE_PENDING_AUTHORIZATION,
          ),
        ];
        return finance.CreatePlanResponse(
          plan: plans.single,
          authorizationIntent: finance.IntentRecord(
            intent: intent(finance.IntentType.INTENT_TYPE_AUTHORIZATION_GRANT),
          ),
        );
      })
      ..on(finance.SavingsService.cancelPlan, (req) {
        plans = [];
        return finance.CancelPlanResponse(
          revokeIntent: finance.IntentRecord(
            intent: intent(finance.IntentType.INTENT_TYPE_AUTHORIZATION_REVOKE),
          ),
        );
      })
      ..on(
        finance.IntentService.authorizeIntent,
        (req) => finance.AuthorizeIntentResponse(),
      );
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stawiDuesPlanServiceProvider.overrideWithValue(
            StawiDuesPlanService(
              savings: finance.SavingsServiceClient(transport),
              intents: finance.IntentServiceClient(transport),
              keys: DeviceKeyStore(
                vaultWith('p1', v.devicePrivateKey),
                gate: gate,
              ),
              identity: () async => identityWith('p1', v.account),
              membership: (_) async => finance.Member(memberId: 'mem1'),
              contracts: (_) async => room,
            ),
          ),
          stawiMyDuesProvider.overrideWith(
            (ref, id) async => finance.GetMemberDuesResponse(
              dues: finance.MemberDues(
                rulesConfigured: true,
                calendar: finance.RoomCalendar(
                  unit: finance.PeriodUnit.PERIOD_UNIT_WEEK,
                  length: 1,
                ),
                products: [
                  finance.MemberProductDues(
                    nextDueAmount: finance.Money(
                      assetId: 'USDC.146',
                      amount: '2000000',
                    ),
                  ),
                ],
              ),
              assets: [usdcInfo],
            ),
          ),
          stawiRoomAssetsProvider.overrideWith((ref, id) async => usdcAssets),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DuesAutoPaySwitch(roomId: roomId, roomName: 'Chama'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('turning it on plans this period\'s dues and signs the grant', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Pay each period yourself'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dues-autopay')));
    await tester.pumpAndSettle();
    expect(find.text('Pay my dues in Chama automatically'), findsOneWidget);
    expect(gate.reasons, isEmpty, reason: 'the review comes first');
    await tester.tap(find.byKey(const Key('money-review-sign')));
    await tester.pumpAndSettle();

    final create = transport
        .requestsTo(finance.SavingsService.createPlan)
        .single;
    expect(create.amountPerPeriod.amount, '2000000');
    expect(create.cadence, finance.Cadence.CADENCE_WEEKLY);
    expect(gate.reasons, ['Pay my dues in Chama automatically']);
    expect(
      transport.requestsTo(finance.IntentService.authorizeIntent),
      hasLength(1),
    );
    expect(
      find.text('Waiting for your authorization to go through'),
      findsOneWidget,
    );
  });

  testWidgets('cancelling the review signs nothing', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('dues-autopay')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('money-review-cancel')));
    await tester.pumpAndSettle();
    expect(gate.reasons, isEmpty);
    expect(
      transport.requestsTo(finance.IntentService.authorizeIntent),
      isEmpty,
    );
  });

  testWidgets('turning it off revokes the grant', (tester) async {
    plans = [
      finance.SavingsPlan(
        planId: 'plan0000000000000001',
        state: finance.PlanState.PLAN_STATE_ACTIVE,
      ),
    ];
    await pump(tester);
    expect(
      find.text('Each period\'s dues are collected from your wallet'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('dues-autopay')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('money-review-sign')));
    await tester.pumpAndSettle();
    expect(
      transport.requestsTo(finance.SavingsService.cancelPlan).single.planId,
      'plan0000000000000001',
    );
    expect(find.text('Pay each period yourself'), findsOneWidget);
  });
}
