import 'package:connectrpc/connect.dart' as connect;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/stawi_loan_service.dart';
import 'package:stawi/features/stawi/domain/loan_terms.dart';
import 'package:stawi/features/stawi/ui/terms_entry.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/well_known.dart' as wkt;

import '../../../support/stawi_fakes.dart';

finance.Money usdcUnits(int units) =>
    finance.Money(amount: '$units', assetId: 'USDC.146');

finance.QuoteLoanResponse quote() => finance.QuoteLoanResponse(
  instalments: [
    for (var i = 0; i < 4; i++)
      finance.LoanInstalment(
        index: i,
        dueAt: wkt.Timestamp.fromDateTime(DateTime.utc(2026, 10, 27, 12)),
        principal: usdcUnits(75000000),
        interest: usdcUnits(2500000),
        fee: usdcUnits(0),
      ),
  ],
  principal: usdcUnits(300000000),
  totalInterest: usdcUnits(10000000),
  totalRepayable: usdcUnits(310000000),
  maxRepayable: usdcUnits(600000000),
);

void main() {
  late FakeConnectTransport transport;
  BigInt? amount;
  LoanTerms? terms;
  finance.QuoteLoanResponse? quoted;

  Future<void> open(
    WidgetTester tester, {
    finance.LoanKind kind = finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON,
    Exception? quoteFails,
    BigInt? maxAmount,
  }) async {
    amount = null;
    terms = null;
    quoted = null;
    transport = FakeConnectTransport()
      ..on(finance.LoanService.quoteLoan, (req) {
        if (quoteFails != null) throw quoteFails;
        return quote();
      });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stawiLoanServiceProvider.overrideWithValue(
            StawiLoanService(
              loans: finance.LoanServiceClient(transport),
              identity: () async => throw StateError('not needed'),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TermsEntry(
                kind: kind,
                asset: usdc,
                maxAmount: maxAmount,
                onChanged: (a, t, q) {
                  amount = a;
                  terms = t;
                  quoted = q;
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> settleQuote(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();
  }

  Future<void> fill(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('terms-preset-fortnightly4')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('terms-rate')), '2.5');
    await tester.enterText(find.byKey(const Key('terms-amount')), '300');
    await settleQuote(tester);
  }

  testWidgets('a preset, a rate and an amount issue one quote and show it', (
    tester,
  ) async {
    await open(tester);
    await fill(tester);
    final sent = transport.requestsTo(finance.LoanService.quoteLoan);
    expect(sent, hasLength(1));
    expect(sent.single.terms.instalments, 4);
    expect(sent.single.terms.everyDays, 14);
    expect(sent.single.terms.rateBps, 250);
    expect(sent.single.amount, '300000000');
    expect(
      find.text(
        'First of 4 instalments: 77.50 USDC on 27 Oct · 310.00 USDC in all',
      ),
      findsOneWidget,
    );
    expect(find.text('At most you will repay 660.00 USDC'), findsOneWidget);
    expect(find.textContaining('Stawi fee'), findsNothing);
    expect(amount, BigInt.from(300000000));
    expect(terms!.proto.rateBps, 250);
    expect(quoted, isNotNull);
  });

  testWidgets('edits in quick succession quote once, after the last', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('terms-preset-fortnightly4')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('terms-amount')), '3');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byKey(const Key('terms-amount')), '30');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byKey(const Key('terms-amount')), '300');
    expect(transport.requestsTo(finance.LoanService.quoteLoan), isEmpty);
    await settleQuote(tester);
    expect(transport.requestsTo(finance.LoanService.quoteLoan), hasLength(1));
  });

  testWidgets('interest above the amount is explained and not quoted', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('terms-preset-fortnightly4')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('terms-rate')), '30');
    await tester.enterText(find.byKey(const Key('terms-amount')), '300');
    await settleQuote(tester);
    expect(find.text('Interest would be more than the amount'), findsOneWidget);
    expect(transport.requestsTo(finance.LoanService.quoteLoan), isEmpty);
    expect(terms, isNull);
  });

  testWidgets('a rate with more than two decimals is refused', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('terms-preset-fortnightly4')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('terms-rate')), '2.555');
    await tester.enterText(find.byKey(const Key('terms-amount')), '300');
    await settleQuote(tester);
    expect(find.byKey(const Key('terms-error')), findsOneWidget);
    expect(transport.requestsTo(finance.LoanService.quoteLoan), isEmpty);
  });

  testWidgets('an amount above the limit is refused', (tester) async {
    await open(tester, maxAmount: BigInt.from(100000000));
    await tester.tap(find.byKey(const Key('terms-preset-fortnightly4')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('terms-amount')), '300');
    await settleQuote(tester);
    expect(find.text('That is more than 100.00 USDC'), findsOneWidget);
    expect(transport.requestsTo(finance.LoanService.quoteLoan), isEmpty);
  });

  testWidgets('a loan to oneself has no late-charge choices', (tester) async {
    await open(tester, kind: finance.LoanKind.LOAN_KIND_SELF);
    await tester.tap(find.byKey(const Key('terms-more')));
    await tester.pump();
    expect(find.byKey(const Key('terms-method-flat')), findsOneWidget);
    expect(find.byKey(const Key('terms-late-none')), findsNothing);
    expect(find.byKey(const Key('terms-late-flat')), findsNothing);
    expect(find.byKey(const Key('terms-late-percent')), findsNothing);
  });

  testWidgets('a loan between people offers late-charge choices', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('terms-more')));
    await tester.pump();
    expect(find.byKey(const Key('terms-late-none')), findsOneWidget);
    expect(find.byKey(const Key('terms-late-flat')), findsOneWidget);
    expect(find.byKey(const Key('terms-late-percent')), findsOneWidget);
    await tester.tap(find.byKey(const Key('terms-late-none')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('terms-method-amortized')));
    await tester.pump();
    await fill(tester);
    expect(terms!.hasLateCharge, isFalse);
    expect(
      terms!.proto.method,
      finance.LoanInterestMethod.LOAN_INTEREST_METHOD_AMORTIZED,
    );
  });

  testWidgets('a quote that cannot be read offers a retry', (tester) async {
    await open(
      tester,
      quoteFails: connect.ConnectException(
        connect.Code.unavailable,
        'the Stawi fee could not be read',
      ),
    );
    await fill(tester);
    expect(find.byKey(const Key('terms-quote-retry')), findsOneWidget);
    expect(find.textContaining('First of'), findsNothing);
    await tester.tap(find.byKey(const Key('terms-quote-retry')));
    await tester.pump();
    await tester.pump();
    expect(transport.requestsTo(finance.LoanService.quoteLoan), hasLength(2));
  });

  test('percent to basis points without floating point', () {
    expect(parsePercentBps('2.5'), 250);
    expect(parsePercentBps('30'), 3000);
    expect(parsePercentBps('0.05'), 5);
    expect(parsePercentBps(''), 0);
    expect(parsePercentBps('2.555'), isNull);
    expect(parsePercentBps('-1'), isNull);
    expect(parsePercentBps('abc'), isNull);
  });
}
