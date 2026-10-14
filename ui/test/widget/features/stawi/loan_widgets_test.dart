import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/domain/loan_view.dart';
import 'package:stawi/features/stawi/domain/stawi_money.dart';
import 'package:stawi/features/stawi/ui/loan_widgets.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_api/well_known.dart' as wkt;

import '../../../support/stawi_fakes.dart';

Uint8List addr(int b) => Uint8List.fromList(List.filled(20, b));

finance.Money money(int units) =>
    finance.Money(amount: '$units', assetId: 'USDC.146');

wkt.Timestamp noon(int month, int day) =>
    wkt.Timestamp.fromDateTime(DateTime.utc(2026, month, day, 12));

finance.LoanInstalment instalment(
  int index, {
  int principal = 70000000,
  int interest = 7500000,
  int paid = 0,
  bool late = false,
  bool dated = true,
}) => finance.LoanInstalment(
  index: index,
  dueAt: dated ? noon(10, 27) : null,
  principal: money(principal),
  interest: money(interest),
  fee: money(0),
  paid: money(paid),
  late: late,
);

Future<void> show(WidgetTester tester, Widget child) => tester.pumpWidget(
  ProviderScope(
    child: MaterialApp(home: Scaffold(body: child)),
  ),
);

void main() {
  final me = addr(2);
  final bob = addr(1);

  finance.Loan loan({
    finance.LoanKind kind = finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON,
    finance.LoanState state = finance.LoanState.LOAN_STATE_FUNDED,
  }) => finance.Loan(
    kind: kind,
    state: state,
    lender: bob,
    borrowerAccount: me,
    requested: money(300000000),
  );

  group('LoanCard', () {
    testWidgets('says who, how much, what is next and where it stands', (
      tester,
    ) async {
      await show(
        tester,
        LoanCard(
          view: LoanView(
            loan(),
            mine: [me],
            instalments: [instalment(0, paid: 77500000), instalment(1)],
          ),
          assets: usdcAssets,
          counterpartyName: 'Bob',
        ),
      );
      expect(find.text('From Bob'), findsOneWidget);
      expect(find.text('300.00 USDC'), findsOneWidget);
      expect(find.text('Next: 27 Oct · 77.50 USDC'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('while the asset loads, amounts are "—", not minor units', (
      tester,
    ) async {
      await show(
        tester,
        LoanCard(
          view: LoanView(
            loan(),
            mine: [me],
            instalments: [instalment(0, paid: 77500000), instalment(1)],
          ),
          assets: StawiAssets.loading,
          counterpartyName: 'Bob',
        ),
      );
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Next: 27 Oct · —'), findsOneWidget);
      expect(find.textContaining('300000000'), findsNothing);
      expect(find.textContaining('77500000'), findsNothing);
      expect(find.textContaining('USDC.146'), findsNothing);
    });

    testWidgets('a lender sees "To Bob"; a waiting loan names who', (
      tester,
    ) async {
      await show(
        tester,
        LoanCard(
          view: LoanView(
            loan(state: finance.LoanState.LOAN_STATE_PENDING_APPROVAL),
            mine: [bob],
          ),
          assets: usdcAssets,
          counterpartyName: 'Bob',
        ),
      );
      expect(find.text('To Bob'), findsOneWidget);
      expect(find.text('Waiting for Bob'), findsOneWidget);
      expect(find.byKey(const Key('loan-next')), findsNothing);
    });

    testWidgets('a loan to oneself comes from my savings', (tester) async {
      await show(
        tester,
        LoanCard(
          view: LoanView(
            loan(kind: finance.LoanKind.LOAN_KIND_SELF),
            mine: [me],
          ),
          assets: usdcAssets,
        ),
      );
      expect(find.text('From my savings'), findsOneWidget);
    });
  });

  group('ScheduleView', () {
    testWidgets('marks late and paid instalments', (tester) async {
      await show(
        tester,
        ScheduleView(
          assets: usdcAssets,
          instalments: [
            instalment(0, paid: 77500000),
            instalment(1, late: true),
            instalment(2),
          ],
        ),
      );
      expect(find.byKey(const Key('schedule-paid-0')), findsOneWidget);
      expect(find.byKey(const Key('schedule-late-1')), findsOneWidget);
      expect(find.byKey(const Key('schedule-late-2')), findsNothing);
      expect(find.byKey(const Key('schedule-paid-2')), findsNothing);
      expect(find.text('Instalment 2 · 27 Oct'), findsOneWidget);
    });

    testWidgets('a group quote has no dates', (tester) async {
      await show(
        tester,
        ScheduleView(
          assets: usdcAssets,
          instalments: [
            instalment(0, dated: false),
            instalment(1, dated: false),
          ],
        ),
      );
      expect(
        find.text('1 of 2, each one room period apart after payout'),
        findsOneWidget,
      );
    });

    testWidgets('with no instalments it shows the empty text', (tester) async {
      await show(
        tester,
        ScheduleView(
          assets: usdcAssets,
          instalments: const [],
          emptyText: 'No schedule yet',
        ),
      );
      expect(find.text('No schedule yet'), findsOneWidget);
    });
  });

  group('StandingOrderSwitch', () {
    final g = GoVaultVectors.load().standingGrants.firstWhere(
      (v) => v.name == 'self_flat_weekly',
    );
    late FakeConnectTransport transport;
    late RecordingSigningGate gate;

    Future<StawiAccountService> serve() async {
      gate = RecordingSigningGate();
      transport = FakeConnectTransport()
        ..on(settlement.AccountService.prepareAccountCall, (req) => g.prepared)
        ..on(
          settlement.AccountService.submitAccountCall,
          (req) => settlement.SubmitAccountCallResponse(
            call: settlement.AccountCall(callId: req.callId),
          ),
        )
        ..on(
          settlement.AccountService.getAsset,
          (req) => settlement.GetAssetResponse(asset: usdcInfo),
        );
      await serveDeployedAccount(transport, anvilKey, policyAsset: g.asset);
      return StawiAccountService(
        accounts: settlement.AccountServiceClient(transport),
        keys: DeviceKeyStore(vaultWith('p1', anvilKey), gate: gate),
        proofs: refusingSessionProofs,
        identity: () async => identityWith('p1', g.account),
        targets: () async => g.targets,
      );
    }

    Future<void> open(WidgetTester tester, finance.Loan l) async {
      final service = await serve();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [stawiAccountServiceProvider.overrideWithValue(service)],
          child: MaterialApp(
            home: Scaffold(body: StandingOrderSwitch(loan: l)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('turning it on prepares, reviews and submits once', (
      tester,
    ) async {
      await open(tester, g.loan);
      await tester.tap(find.byKey(const Key('standing-order-switch')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('money-review')), findsOneWidget);
      expect(
        transport.requestsTo(settlement.AccountService.submitAccountCall),
        isEmpty,
      );
      await tester.tap(find.byKey(const Key('money-review-sign')));
      await tester.pumpAndSettle();
      expect(
        transport.requestsTo(settlement.AccountService.submitAccountCall),
        hasLength(1),
      );
      expect(
        transport
            .requestsTo(settlement.AccountService.prepareAccountCall)
            .single
            .kind,
        settlement.AccountCallKind.ACCOUNT_CALL_KIND_GRANT_STANDING,
      );
    });

    testWidgets('cancelling the review submits nothing', (tester) async {
      await open(tester, g.loan);
      await tester.tap(find.byKey(const Key('standing-order-switch')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('money-review-cancel')));
      await tester.pumpAndSettle();
      expect(
        transport.requestsTo(settlement.AccountService.submitAccountCall),
        isEmpty,
      );
    });

    testWidgets('a loan that is not active cannot have one', (tester) async {
      await open(
        tester,
        g.loan..state = finance.LoanState.LOAN_STATE_PENDING_APPROVAL,
      );
      expect(find.text('Starts once the loan is active'), findsOneWidget);
      await tester.tap(find.byKey(const Key('standing-order-switch')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('money-review')), findsNothing);
      expect(
        transport.requestsTo(settlement.AccountService.prepareAccountCall),
        isEmpty,
      );
    });
  });
}
