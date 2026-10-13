import 'dart:typed_data';

import 'package:connectrpc/connect.dart' as connect;
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/navigation/navigation_helper.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/data/stawi_loan_service.dart';
import 'package:stawi/features/stawi/data/stawi_vault_service.dart';
import 'package:stawi/features/stawi/domain/loan_terms.dart';
import 'package:stawi/features/stawi/domain/personal_calls.dart';
import 'package:stawi/features/stawi/ui/loan_detail_screen.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_api/well_known.dart' as wkt;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

const _acceptOffer =
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_ACCEPT_OFFER;
const _acceptAsk = settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_ACCEPT_ASK;
const _grant = settlement.AccountCallKind.ACCOUNT_CALL_KIND_GRANT_STANDING;
const _pay = settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_PAY;
const _cancel =
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_PERSONAL_LOAN_CANCEL;

void main() {
  final vectors = {
    for (final v in GoEngineCallVector.load().where((v) => v.personal))
      v.name: v,
  };
  final vault = hexToBytes('0x909192939495969798999a9b9c9d9e9fa0a1a2a3');
  final book = hexToBytes('0x101112131415161718191a1b1c1d1e1f20212223');
  final bob = hexToBytes('0xb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3');
  final me = vectors['offer']!.account;
  final targets = PersonalTargets.fromResponse(vault: vault, loanBooks: [book]);
  final grant = GoVaultVectors.load().standingGrants.firstWhere(
    (g) => g.name == 'p2p_declining_fortnightly',
  );
  final goalPocket = hexToBytes(
    '0x606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f',
  );
  final free = Uint8List(32);

  final offerTerms = () {
    final t = vectors['offer']!.json['terms'] as Map<String, dynamic>;
    return LoanTerms.fromSdk(
      PersonalTerms(
        n: t['n'] as int,
        everyDays: t['every_days'] as int,
        method: t['method'] as int,
        rateBps: t['rate_bps'] as int,
        lateMethod: t['late_method'] as int,
        lateBps: t['late_bps'] as int,
        lateFlat: BigInt.parse(t['late_flat'] as String),
        defaultAfterDays: t['default_after_days'] as int,
      ),
    );
  }();

  finance.Money usd(int units) =>
      finance.Money(amount: '$units', assetId: 'USDC.146');

  /// A person-to-person loan of 300 USDC on the offer vector's terms.
  finance.Loan p2p({
    required List<int> lender,
    required List<int> borrower,
    required List<int> offeredBy,
    finance.LoanState state = finance.LoanState.LOAN_STATE_PENDING_APPROVAL,
  }) => finance.Loan(
    pool: lender,
    lender: lender,
    borrowerAccount: borrower,
    offeredBy: offeredBy,
    loanBook: book,
    onchainLoanId: Int64(1),
    requested: usd(300000000),
    terms: offerTerms.proto,
    kind: finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON,
    state: state,
  );

  finance.Loan offerToMe() => p2p(lender: bob, borrower: me, offeredBy: bob);
  finance.Loan askOfMe() => p2p(lender: me, borrower: bob, offeredBy: bob);
  finance.Loan myOffer() => p2p(lender: me, borrower: bob, offeredBy: me);

  finance.SavingsPocket pocket(
    Uint8List id,
    int cash, {
    String name = '',
    bool loanable = false,
  }) => finance.SavingsPocket(
    pocket: id,
    cash: usd(cash),
    lent: usd(0),
    isGoal: !id.every((b) => b == 0),
    name: name,
    loanable: loanable,
    target: usd(1000000000),
    unlockAt: wkt.Timestamp.fromDateTime(DateTime.utc(2027)),
  );

  late FakeConnectTransport transport;
  late RecordingSigningGate gate;
  late finance.Loan served;
  late List<finance.LoanInstalment> instalments;
  late List<finance.GetVaultResponse> vaults;
  late Object? record;

  Future<StawiAccountService> serve({
    List<List<int>> authorizationIds = const [],
  }) async {
    gate = RecordingSigningGate();
    instalments = const [];
    vaults = [];
    record = finance.GetCreditRecordResponse(
      own: finance.CreditRecord(loans: 1, onTime: 1),
      others: finance.CreditRecord(loans: 2, onTime: 2),
    );
    transport = FakeConnectTransport()
      ..on(
        finance.LoanService.getLoan,
        (req) =>
            finance.GetLoanResponse(loan: served, instalments: instalments),
      )
      ..on(finance.LoanService.getCreditRecord, (req) {
        final r = record;
        if (r is Exception) throw r;
        return r! as finance.GetCreditRecordResponse;
      })
      ..on(
        finance.LoanService.quoteLoan,
        (req) => finance.QuoteLoanResponse(
          instalments: [
            finance.LoanInstalment(
              index: 0,
              dueAt: wkt.Timestamp.fromDateTime(DateTime.utc(2026, 10, 27)),
              principal: usd(75000000),
              interest: usd(7500000),
              fee: usd(0),
              paid: usd(0),
            ),
          ],
          totalRepayable: usd(318750000),
        ),
      )
      ..on(
        finance.VaultService.getVault,
        (req) => vaults.length > 1 ? vaults.removeAt(0) : vaults.first,
      )
      ..on(
        settlement.AccountService.getAsset,
        (req) => settlement.GetAssetResponse(asset: usdcInfo),
      )
      ..on(settlement.AccountService.prepareAccountCall, (req) {
        switch (req.kind) {
          case _acceptOffer:
            return vectors['accept_offer']!.prepared(req.kind);
          case _acceptAsk:
            return vectors['accept_ask']!.preparedFor(
              EngineCall(
                action: EngineAction.acceptAsk,
                party: bob,
                loanId: BigInt.one,
                amount: BigInt.from(300000000),
                pocket: req.params.hasPocket()
                    ? Uint8List.fromList(req.params.pocket)
                    : free,
              ),
              req.kind,
            );
          case _pay:
            return vectors['pay']!.prepared(req.kind);
          case _cancel:
            return vectors['personal_cancel']!.preparedFor(
              EngineCall(
                action: EngineAction.personalCancel,
                pool: Uint8List.fromList(req.params.pool),
                loanId: BigInt.one,
              ),
              req.kind,
            );
          case _grant:
            return grant.preparedWith(
              authorizationId: standingOrderId(book, bob, BigInt.one),
              maxPerPeriod: largestInstalment(
                BigInt.from(300000000),
                offerTerms.sdk,
              ),
            );
          default:
            throw connect.ConnectException(connect.Code.unimplemented, '');
        }
      })
      ..on(settlement.AccountService.submitAccountCall, (req) {
        if (req.callId == 'acct00000000000000e1' &&
            served.state == finance.LoanState.LOAN_STATE_PENDING_APPROVAL) {
          // The accepted offer pays out.
          served = (finance.Loan()..mergeFromMessage(served))
            ..state = finance.LoanState.LOAN_STATE_FUNDED;
        }
        return settlement.SubmitAccountCallResponse(
          call: settlement.AccountCall(
            callId: req.callId,
            state: settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED,
          ),
        );
      })
      ..on(
        settlement.AccountService.getAccountCall,
        (req) => settlement.GetAccountCallResponse(
          call: settlement.AccountCall(
            callId: req.callId,
            state: settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL,
          ),
        ),
      );
    await serveDeployedAccount(
      transport,
      anvilKey,
      policyAsset: grant.asset,
      authorizationIds: authorizationIds,
    );
    return StawiAccountService(
      accounts: settlement.AccountServiceClient(transport),
      keys: DeviceKeyStore(vaultWith('p1', anvilKey), gate: gate),
      proofs: refusingSessionProofs,
      identity: () async => identityWith('p1', me),
      targets: () async => targets,
      loan: (r) => finance.LoanServiceClient(transport).getLoan(
        finance.GetLoanRequest(
          pool: r.pool,
          onchainLoanId: Int64.parseInt(r.loanId.toString()),
          loanBook: r.loanBook,
        ),
      ),
      followEvery: const Duration(milliseconds: 10),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> open(WidgetTester tester, StawiAccountService service) async {
    tester.view
      ..physicalSize = const Size(1080, 4000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Future<StawiIdentity> identity() async => identityWith('p1', me);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stawiIdentityProvider.overrideWith((ref) => identity()),
          stawiAccountServiceProvider.overrideWithValue(service),
          stawiLoanServiceProvider.overrideWithValue(
            StawiLoanService(
              loans: finance.LoanServiceClient(transport),
              identity: identity,
            ),
          ),
          stawiVaultServiceProvider.overrideWithValue(
            StawiVaultService(
              vault: finance.VaultServiceClient(transport),
              identity: identity,
            ),
          ),
        ],
        child: MaterialApp(
          home: LoanDetailScreen(
            ref: LoanRef.of(served),
            counterpartyName: 'Bob',
          ),
        ),
      ),
    );
    await settle(tester);
  }

  List<settlement.AccountCallKind> prepared() => [
    for (final r in transport.requestsTo(
      settlement.AccountService.prepareAccountCall,
    ))
      r.kind,
  ];

  List<String> submitted() => [
    for (final r in transport.requestsTo(
      settlement.AccountService.submitAccountCall,
    ))
      r.callId,
  ];

  Finder inReview(String text) => find.descendant(
    of: find.byKey(const Key('money-review')),
    matching: find.text(text),
  );

  Future<void> tapAndSettle(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await settle(tester);
  }

  group('an offer to me', () {
    testWidgets('accepting asks for the automatic payment once it is active', (
      tester,
    ) async {
      final service = await serve();
      served = offerToMe();
      await open(tester, service);

      expect(find.byKey(const Key('loan-accept')), findsOneWidget);
      expect(find.byKey(const Key('loan-decline')), findsOneWidget);
      expect(find.byKey(const Key('record-summary')), findsNothing);
      expect(
        transport.requestsTo(finance.LoanService.getCreditRecord),
        isEmpty,
      );
      expect(find.text('Expected to repay'), findsOneWidget);
      expect(find.text('318.75 USDC'), findsWidgets);
      expect(find.text('At most you will repay'), findsOneWidget);

      await tapAndSettle(tester, find.byKey(const Key('loan-accept')));
      expect(inReview('Accept a loan of 300.00 USDC from Bob'), findsOneWidget);
      expect(inReview('At most you will repay'), findsOneWidget);
      expect(inReview('637.50 USDC'), findsOneWidget);
      expect(inReview('Expected to repay'), findsOneWidget);

      await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
      expect(submitted(), ['acct00000000000000e1']);
      expect(inReview('Pay automatically for this loan'), findsOneWidget);

      await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
      expect(prepared(), [_acceptOffer, _grant]);
      expect(submitted(), ['acct00000000000000e1', 'acct00000000000000g1']);
      expect(gate.reasons, [
        'Accept a loan of 300.00 USDC from Bob',
        'Pay automatically for this loan',
      ]);
    });

    testWidgets('with the switch off, no automatic payment is asked', (
      tester,
    ) async {
      final service = await serve();
      served = offerToMe();
      await open(tester, service);

      await tapAndSettle(tester, find.byKey(const Key('loan-accept-autopay')));
      await tapAndSettle(tester, find.byKey(const Key('loan-accept')));
      await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));

      expect(submitted(), ['acct00000000000000e1']);
      expect(find.byKey(const Key('money-review')), findsNothing);
      expect(prepared(), [_acceptOffer]);
    });

    testWidgets('declining cancels the offer', (tester) async {
      final service = await serve();
      served = offerToMe();
      await open(tester, service);

      await tapAndSettle(tester, find.byKey(const Key('loan-decline')));
      expect(prepared(), [_cancel]);
      expect(find.byKey(const Key('money-review')), findsOneWidget);
    });
  });

  group('an ask of me', () {
    testWidgets('shows the borrower\'s record', (tester) async {
      final service = await serve();
      served = askOfMe();
      await open(tester, service);

      expect(
        find.textContaining("Bob's record: 2 loans from others (2 on time)"),
        findsOneWidget,
      );
      expect(find.byKey(const Key('loan-lend')), findsOneWidget);
      expect(find.byKey(const Key('loan-decline')), findsOneWidget);
    });

    testWidgets('a goal that no longer holds enough is refused', (
      tester,
    ) async {
      final service = await serve();
      served = askOfMe();
      vaults = [
        finance.GetVaultResponse(
          pockets: [
            pocket(free, 0),
            pocket(goalPocket, 400000000, name: 'Holiday fund', loanable: true),
          ],
        ),
        finance.GetVaultResponse(
          pockets: [
            pocket(free, 0),
            pocket(goalPocket, 100000000, name: 'Holiday fund', loanable: true),
          ],
        ),
      ];
      await open(tester, service);

      await tapAndSettle(tester, find.byKey(const Key('loan-lend')));
      await tapAndSettle(tester, find.text('Holiday fund'));

      expect(find.text('Not enough in Holiday fund'), findsOneWidget);
      expect(prepared(), isEmpty);
    });

    testWidgets('a goal that cannot be lent is not offered', (tester) async {
      final service = await serve();
      served = askOfMe();
      vaults = [
        finance.GetVaultResponse(
          pockets: [
            pocket(free, 500000000),
            pocket(goalPocket, 400000000, name: 'Holiday fund'),
          ],
        ),
      ];
      await open(tester, service);

      await tapAndSettle(tester, find.byKey(const Key('loan-lend')));
      expect(find.text('Free savings'), findsOneWidget);
      expect(find.text('Holiday fund'), findsNothing);
    });

    testWidgets('lending from free savings prepares ACCEPT_ASK from it', (
      tester,
    ) async {
      final service = await serve();
      served = askOfMe();
      vaults = [
        finance.GetVaultResponse(pockets: [pocket(free, 500000000)]),
      ];
      await open(tester, service);

      await tapAndSettle(tester, find.byKey(const Key('loan-lend')));
      await tapAndSettle(tester, find.text('Free savings'));

      final requests = transport.requestsTo(
        settlement.AccountService.prepareAccountCall,
      );
      expect(requests.single.kind, _acceptAsk);
      expect(requests.single.params.hasPocket(), isFalse);
      expect(inReview('Lend 300.00 USDC to Bob'), findsOneWidget);
    });

    testWidgets('a record not shared says so and leaves the actions', (
      tester,
    ) async {
      final service = await serve();
      served = askOfMe();
      record = connect.ConnectException(connect.Code.permissionDenied, 'no');
      await open(tester, service);

      expect(find.text('Their record is not shared with you'), findsOneWidget);
      expect(find.byKey(const Key('loan-lend')), findsOneWidget);
      expect(find.byKey(const Key('loan-decline')), findsOneWidget);
    });
  });

  testWidgets('my own offer: no record, waiting, cancel my offer', (
    tester,
  ) async {
    final service = await serve();
    served = myOffer();
    await open(tester, service);

    expect(find.byKey(const Key('record-summary')), findsNothing);
    expect(transport.requestsTo(finance.LoanService.getCreditRecord), isEmpty);
    expect(find.text('Waiting for Bob'), findsWidgets);
    expect(find.text('Cancel my offer'), findsOneWidget);
    expect(find.byKey(const Key('loan-accept')), findsNothing);
    expect(find.text('At most you will repay'), findsNothing);
  });

  testWidgets('my own ask: waiting, cancel my request', (tester) async {
    final service = await serve();
    served = p2p(lender: bob, borrower: me, offeredBy: me);
    await open(tester, service);

    expect(find.byKey(const Key('record-summary')), findsNothing);
    expect(find.text('Cancel my request'), findsOneWidget);
  });

  group('an active loan I borrowed', () {
    finance.LoanInstalment due(int paid) => finance.LoanInstalment(
      index: 0,
      dueAt: wkt.Timestamp.fromDateTime(DateTime.utc(2026, 10, 27)),
      principal: usd(50000000),
      interest: usd(2000000),
      fee: usd(0),
      paid: usd(paid),
    );

    testWidgets('paying an instalment prepares LOAN_PAY of what is owed', (
      tester,
    ) async {
      final service = await serve(
        authorizationIds: [standingOrderId(book, bob, BigInt.one)],
      );
      served = offerToMe()..state = finance.LoanState.LOAN_STATE_FUNDED;
      instalments = [due(0)];
      await open(tester, service);

      final toggle = find.descendant(
        of: find.byKey(const Key('loan-standing-switch')),
        matching: find.byType(Switch),
      );
      expect(tester.widget<Switch>(toggle).value, isTrue);
      expect(find.byKey(const Key('loan-autopay-banner')), findsNothing);

      await tapAndSettle(tester, find.byKey(const Key('loan-pay')));
      await tapAndSettle(tester, find.byKey(const Key('pay-confirm')));

      final requests = transport.requestsTo(
        settlement.AccountService.prepareAccountCall,
      );
      expect(requests.single.kind, _pay);
      expect(requests.single.params.amount, '52000000');
      expect(inReview('Pay an instalment'), findsOneWidget);
    });

    testWidgets('without an automatic payment it offers one', (tester) async {
      final service = await serve();
      served = offerToMe()..state = finance.LoanState.LOAN_STATE_FUNDED;
      instalments = [due(0)];
      await open(tester, service);

      final toggle = find.descendant(
        of: find.byKey(const Key('loan-standing-switch')),
        matching: find.byType(Switch),
      );
      expect(tester.widget<Switch>(toggle).value, isFalse);
      await tapAndSettle(tester, find.byKey(const Key('loan-autopay-on')));
      expect(inReview('Pay automatically for this loan'), findsOneWidget);
      expect(prepared(), [_grant]);
    });

    testWidgets('its lender sees no actions', (tester) async {
      final service = await serve();
      served = myOffer()..state = finance.LoanState.LOAN_STATE_FUNDED;
      instalments = [due(52000000)];
      await open(tester, service);

      expect(find.byKey(const Key('loan-pay')), findsNothing);
      expect(find.byKey(const Key('loan-came-back')), findsOneWidget);
      expect(find.byKey(const Key('record-summary')), findsNothing);
    });
  });

  group('followUntilActive', () {
    test('waits for the loan to be paid out', () async {
      final service = await serve();
      served = offerToMe();
      var reads = 0;
      transport.on(finance.LoanService.getLoan, (req) {
        reads++;
        return finance.GetLoanResponse(
          loan: reads < 3
              ? served
              : ((finance.Loan()..mergeFromMessage(served))
                  ..state = finance.LoanState.LOAN_STATE_FUNDED),
        );
      });
      final loan = await service.followUntilActive(
        LoanRef.of(served),
        callId: 'acct00000000000000e1',
      );
      expect(loan.state, finance.LoanState.LOAN_STATE_FUNDED);
      expect(reads, 3);
    });

    test('gives up with the loan as it stands', () async {
      final service = await serve();
      served = offerToMe();
      final loan = await service.followUntilActive(
        LoanRef.of(served),
        attempts: 3,
      );
      expect(loan.state, finance.LoanState.LOAN_STATE_PENDING_APPROVAL);
      expect(transport.requestsTo(finance.LoanService.getLoan), hasLength(3));
    });

    test('refuses another loan', () async {
      final service = await serve();
      served = offerToMe()..onchainLoanId = Int64(9);
      expect(
        () => service.followUntilActive(LoanRef.of(offerToMe())),
        throwsA(isA<StawiUnavailable>()),
      );
    });

    test('a failed call is not followed', () async {
      final service = await serve();
      served = offerToMe();
      transport.on(
        settlement.AccountService.getAccountCall,
        (req) => settlement.GetAccountCallResponse(
          call: settlement.AccountCall(
            callId: req.callId,
            state: settlement.AccountCallState.ACCOUNT_CALL_STATE_FAILED,
            failureReason: 'offer expired',
          ),
        ),
      );
      await expectLater(
        service.followUntilActive(LoanRef.of(served), callId: 'c1'),
        throwsA(isA<StawiUnavailable>()),
      );
      expect(transport.requestsTo(finance.LoanService.getLoan), isEmpty);
    });
  });

  test('a /loan link names the loan it was made for', () {
    final r = LoanRef.of(offerToMe());
    final parsed = NavigationHelper.loanRefFrom({
      'book': bytesToHex0x(r.loanBook),
      'pool': bytesToHex0x(r.pool),
      'id': '1',
    });
    expect(parsed, r);
    expect(NavigationHelper.loanRefFrom({'book': '0x01', 'id': '1'}), isNull);
    expect(
      NavigationHelper.loanRefFrom({
        'book': bytesToHex0x(r.loanBook),
        'pool': bytesToHex0x(r.pool),
        'id': '0',
      }),
      isNull,
    );
  });
}
