import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/db/database.dart' show Profile;
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/rooms/data/detail_panel_providers.dart';
import 'package:stawi/features/stawi/data/stawi_counterparty.dart'
    show notOneOfYourChats;
import 'package:stawi/features/stawi/domain/intent_bridge.dart'
    show sdkIntentOf;
import 'package:stawi/features/stawi/domain/loan_terms.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart'
    show bytesEqual;
import 'package:stawi/features/stawi/domain/stawi_payloads.dart';
import 'package:stawi/features/stawi/ui/agent_picker.dart';
import 'package:stawi/features/stawi/ui/loan_detail_screen.dart'
    show autoPayTitle;
import 'package:stawi/features/stawi/ui/money_review_sheet.dart';
import 'package:stawi/features/stawi/ui/room_loans_tab.dart'
    show groupInstalmentNote;
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_api/well_known.dart' as wkt;
import 'package:stawi_api_chat/stawi_api_chat.dart' as pb;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../support/stawi_fakes.dart';
import 'journey_harness.dart';

const _offer = settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_OFFER;
const _ask = settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_ASK;
const _acceptOffer =
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_ACCEPT_OFFER;
const _acceptAsk = settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_ACCEPT_ASK;
const _borrowSelf =
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_BORROW_SELF;
const _grant = settlement.AccountCallKind.ACCOUNT_CALL_KIND_GRANT_STANDING;
const _loanRequest = settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_REQUEST;
const _contribute = settlement.AccountCallKind.ACCOUNT_CALL_KIND_CONTRIBUTE;
const _transfer = settlement.AccountCallKind.ACCOUNT_CALL_KIND_TRANSFER;

final Uint8List _free = Uint8List(32);
final Uint8List _goal = hexToBytes(
  '0x606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f',
);

/// The offer's terms (the `offer`, `ask` and `accept_offer` vectors): 4
/// instalments every 14 days at 2.5% on what is left, a flat late charge of
/// 1 USDC, in default 30 days after a missed due date.
finance.PersonalLoanTerms _offerTerms() => finance.PersonalLoanTerms(
  instalments: 4,
  everyDays: 14,
  method:
      finance.LoanInterestMethod.LOAN_INTEREST_METHOD_DECLINING_EQUAL_PRINCIPAL,
  rateBps: 250,
  latePenalty: finance.PenaltyMethod.PENALTY_METHOD_FLAT,
  lateFlat: '1000000',
  defaultAfterDays: 30,
);

/// A person-to-person loan of 300 USDC on the offer's terms, on the
/// vectors' book.
finance.Loan _p2p({
  required Uint8List lender,
  required Uint8List borrower,
  required Uint8List offeredBy,
  required int loanId,
  finance.LoanState state = finance.LoanState.LOAN_STATE_PENDING_APPROVAL,
}) => finance.Loan(
  loanBook: loanBook,
  pool: lender,
  lender: lender,
  borrowerAccount: borrower,
  offeredBy: offeredBy,
  onchainLoanId: Int64(loanId),
  requested: usdUnits(300000000),
  terms: _offerTerms(),
  kind: finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON,
  state: state,
);

/// A finance card's data naming [loan], with the button that opens it.
Map<String, String> _loanCardData(finance.Loan loan) => {
  'loan_book': bytesToHex0x(loan.loanBook),
  'pool': bytesToHex0x(loan.pool),
  'loan_id': '${loan.onchainLoanId}',
  'action': 'open_loan',
  'asset_id': 'USDC.146',
  'amount': loan.requested.amount,
};

/// A call settlement prepares from [base]'s intent with [change] applied;
/// its digest is the changed intent's own, so only the device's checks can
/// refuse it. For the calls no Go vector covers: a contribution, a transfer.
settlement.PrepareAccountCallResponse _preparedFrom(
  finance.FinancialIntent base,
  settlement.AccountCallKind kind,
  void Function(finance.FinancialIntent intent) change,
) {
  final intent = base.deepCopy();
  change(intent);
  final digest = sdkIntentOf(intent).digest();
  return settlement.PrepareAccountCallResponse(
    callId: 'acct00000000000000x1',
    intentDigest: digest,
    financialIntent: intent,
    call: settlement.AccountCall(
      callId: 'acct00000000000000x1',
      address: intent.account,
      kind: kind,
      intentDigest: digest,
    ),
  );
}

RoomSubscriptionInfo _member(String id, String profileId, String name) =>
    RoomSubscriptionInfo(
      id: id,
      profileId: profileId,
      contactId: null,
      name: name,
      avatarUrl: null,
      role: 'member',
      joinedAt: 0,
    );

void main() {
  /// A DM with Bob, who has written: chat names his account. The vault
  /// holds 500 USDC of free savings and a loanable goal with 400.
  JourneyHarness withBob() => JourneyHarness()
    ..addDm(
      'dm-bob',
      'Bob',
      partnerProfileId: 'p-bob',
      partnerAccount: bobAccount,
    )
    ..pockets = [
      finance.SavingsPocket(
        pocket: _free,
        cash: usdUnits(500000000),
        lent: usdUnits(0),
      ),
      finance.SavingsPocket(
        pocket: _goal,
        isGoal: true,
        name: 'School fees',
        loanable: true,
        cash: usdUnits(400000000),
        lent: usdUnits(0),
        target: usdUnits(1000000000),
      ),
    ];

  /// Types the offer's terms: 300 over 4 fortnightly instalments at 2.5%,
  /// interest on what is left, a flat late charge of 1, default after 30
  /// days.
  Future<void> typeOfferTerms(WidgetTester tester) async {
    await tester.enterText(find.byKey(const Key('terms-amount')), '300');
    await tapAndSettle(
      tester,
      find.byKey(const Key('terms-preset-fortnightly4')),
    );
    await tester.enterText(find.byKey(const Key('terms-rate')), '2.5');
    await tapAndSettle(tester, find.byKey(const Key('terms-more')));
    await tapAndSettle(tester, find.byKey(const Key('terms-method-declining')));
    await tapAndSettle(tester, find.byKey(const Key('terms-late-flat')));
    await tester.enterText(
      find.byKey(const Key('terms-late-flat-amount')),
      '1',
    );
    await tester.enterText(find.byKey(const Key('terms-default-days')), '30');
    await settle(tester);
  }

  /// The self-loan from My money up to its review: Free savings, 200 over 4
  /// weekly instalments at 1%, in default 14 days after a missed due date.
  Future<void> borrowFromSavings(WidgetTester tester) async {
    await tapAndSettle(tester, find.byKey(const Key('money-borrow-self')));
    await tapAndSettle(
      tester,
      find.byKey(Key('borrow-pocket-${bytesToHex(_free)}')),
    );
    await tester.enterText(find.byKey(const Key('terms-amount')), '200');
    await tapAndSettle(tester, find.byKey(const Key('terms-preset-weekly4')));
    await tester.enterText(find.byKey(const Key('terms-rate')), '1');
    await tapAndSettle(tester, find.byKey(const Key('terms-more')));
    await tester.enterText(find.byKey(const Key('terms-default-days')), '14');
    await settle(tester);
    await tapAndSettle(tester, find.byKey(const Key('borrow-self-submit')));
  }

  /// The self-loan's fakes: settlement prepares the `borrow_self` vector,
  /// then the `self_flat_weekly` grant; finance lists the new loan (the
  /// grant vector's, active) once the borrow is submitted.
  JourneyHarness selfLoan() {
    final h = withBob();
    final borrow = engineVector('borrow_self');
    final grant = grantVector('self_flat_weekly');
    finance.Loan made() => grant.loan..requested = usdUnits(grant.amount);
    return h
      ..prepare = ((req) => switch (req.kind) {
        _borrowSelf => borrow.prepared(req.kind),
        _grant => grant.prepared,
        _ => throw StateError('unexpected ${req.kind}'),
      })
      ..listLoans = ((req) =>
          bytesEqual(req.borrower, myAccount) && h.submitted.isNotEmpty
          ? [made()]
          : const [])
      ..getLoan = ((req) => finance.GetLoanResponse(loan: made()));
  }

  testWidgets(
    '1. self-loan: My money to the borrow, then its automatic payment',
    (tester) async {
      final h = selfLoan();
      final borrow = engineVector('borrow_self');
      final grant = grantVector('self_flat_weekly');
      await h.pumpApp(tester, '/money');

      await borrowFromSavings(tester);
      expect(inReview('Borrow 200.00 USDC from my savings'), findsOneWidget);
      expect(reviewLine(tester, 'From'), 'Free savings');
      expect(reviewLine(tester, 'Instalments'), '4 every week');
      expect(h.submitted, isEmpty, reason: 'the review comes first');
      expect(h.prepared.single.kind, _borrowSelf);

      await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
      expect(
        bytesToHex0x(h.submitted.single.authorization),
        borrow.signature,
        reason: "the borrow is the Go vector's signature",
      );

      // Followed until FUNDED, then the automatic payment, reviewed alone.
      expect(inReview(autoPayTitle), findsOneWidget);
      expect(h.submitted, hasLength(1));
      await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
      expect(h.prepared.map((p) => p.kind), [_borrowSelf, _grant]);
      expect(h.submitted[1].authorization, h.signatureOver(grant.digest));
      expect(h.gate.reasons, [
        'Borrow 200.00 USDC from my savings',
        autoPayTitle,
      ]);

      // Back in My money, the loan reads active.
      expect(find.text('From my savings'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    },
  );

  testWidgets(
    '2. person to person, offered: from the DM to the offer signature',
    (tester) async {
      final h = withBob();
      final vector = engineVector('offer');
      h.prepare = (req) => vector.prepared(req.kind);
      await h.pumpApp(tester, '/chat/dm-bob');

      await tapAndSettle(tester, find.byKey(const Key('chat-money')));
      await tapAndSettle(tester, find.byKey(const Key('dm-lend')));
      await tapAndSettle(
        tester,
        find.byKey(Key('dm-pocket-${bytesToHex(_free)}')),
      );
      await typeOfferTerms(tester);
      await tapAndSettle(tester, find.byKey(const Key('dm-expiry-7')));
      await tapAndSettle(tester, find.byKey(const Key('dm-loan-submit')));

      expect(inReview('Lend 300.00 USDC to Bob'), findsOneWidget);
      expect(reviewLine(tester, 'From'), 'Free savings');
      expect(reviewLine(tester, 'Instalments'), '4 every two weeks');
      expect(h.submitted, isEmpty, reason: 'the review comes first');
      final req = h.prepared.single;
      expect(req.kind, _offer);
      expect(req.params.counterparty, bobAccount);
      expect(req.params.expiresAt.seconds.toInt(), 1760000000);

      await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
      expect(h.gate.reasons, ['Lend 300.00 USDC to Bob']);
      expect(bytesToHex0x(h.submitted.single.authorization), vector.signature);
      // Sent at submit; "Offer sent" once the call is final.
      expect(find.text(sentWaitingMessage), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await settle(tester);
      expect(find.text('Offer sent to Bob'), findsOneWidget);
    },
  );

  testWidgets('3. person to person, accepted: the offer card in the DM to '
      'the acceptance and its automatic payment', (tester) async {
    final h = withBob();
    final accept = engineVector('accept_offer');
    final grant = grantVector('p2p_declining_fortnightly');
    final offer = _p2p(
      lender: bobAccount,
      borrower: myAccount,
      offeredBy: bobAccount,
      loanId: 1,
    );
    final funded = offer.deepCopy()
      ..state = finance.LoanState.LOAN_STATE_FUNDED;
    h
      ..getLoan = ((req) =>
          finance.GetLoanResponse(loan: h.submitted.isEmpty ? offer : funded))
      ..prepare = ((req) => switch (req.kind) {
        _acceptOffer => accept.prepared(req.kind),
        // The p2p grant vector is loan 7 of 300000003; the offer accepted
        // here (the accept_offer vector's) is loan 1 of 300: the same grant,
        // keyed to it. The device refuses a grant for another loan.
        _grant => grant.preparedWith(
          authorizationId: standingOrderId(loanBook, bobAccount, BigInt.one),
          maxPerPeriod: largestInstalment(BigInt.from(300000000), grant.terms),
        ),
        _ => throw StateError('unexpected ${req.kind}'),
      })
      ..post(
        h.card(
          'dm-bob',
          id: 'card-offer',
          kind: 'LOAN_OFFERED',
          title: 'Bob offers you a loan of 300.00 USDC',
          data: _loanCardData(offer),
        ),
      );
    await h.pumpApp(tester, '/chat/dm-bob');

    final open = find.byKey(const Key('finance-card-open-loan'));
    expect(
      find.descendant(of: open, matching: find.text('Review')),
      findsOneWidget,
    );
    await tapAndSettle(tester, open);

    // The loan's page: what it costs on time, and the ceiling signed (the
    // SDK's maxRepayable, the accept_offer vector's max_repay).
    final ceiling = maxRepayable(
      BigInt.from(300000000),
      LoanTerms(_offerTerms()).sdk,
    );
    expect(ceiling, BigInt.parse(accept.json['max_repay'] as String));
    final terms = find.byKey(const Key('loan-terms'));
    expect(
      find.descendant(of: terms, matching: find.text('637.50 USDC')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: terms, matching: find.text('Expected to repay')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('loan-accept-autopay')))
          .value,
      isTrue,
    );

    await tapAndSettle(tester, find.byKey(const Key('loan-accept')));
    expect(inReview('Accept a loan of 300.00 USDC from Bob'), findsOneWidget);
    expect(reviewLine(tester, 'At most you will repay'), '637.50 USDC');
    expect(reviewLine(tester, 'Expected to repay'), '318.75 USDC');
    expect(h.submitted, isEmpty, reason: 'the review comes first');

    await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
    expect(bytesToHex0x(h.submitted.single.authorization), accept.signature);

    // Followed until FUNDED, then the standing order, reviewed alone.
    expect(inReview(autoPayTitle), findsOneWidget);
    expect(h.submitted, hasLength(1));
    await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
    expect(h.prepared.map((p) => p.kind), [_acceptOffer, _grant]);
    expect(
      h.submitted[1].authorization,
      h.signatureOver(h.preparedAnswers[1].intentDigest),
    );
    expect(h.gate.reasons, [
      'Accept a loan of 300.00 USDC from Bob',
      autoPayTitle,
    ]);
  });

  testWidgets('4. person to person, asked and lent: I ask Bob, then Bob asks '
      'me and I lend from a goal', (tester) async {
    final h = withBob();
    final ask = engineVector('ask');
    final acceptAsk = engineVector('accept_ask');
    final bobsAsk = _p2p(
      lender: myAccount,
      borrower: bobAccount,
      offeredBy: bobAccount,
      loanId: 1,
    );
    h
      ..prepare = ((req) => switch (req.kind) {
        _ask => ask.prepared(req.kind),
        _acceptAsk => acceptAsk.prepared(req.kind),
        _ => throw StateError('unexpected ${req.kind}'),
      })
      ..getLoan = ((req) => finance.GetLoanResponse(loan: bobsAsk));
    await h.pumpApp(tester, '/chat/dm-bob');

    // I ask Bob, on the offer's terms.
    await tapAndSettle(tester, find.byKey(const Key('chat-money')));
    await tapAndSettle(tester, find.byKey(const Key('dm-ask')));
    await typeOfferTerms(tester);
    await tapAndSettle(tester, find.byKey(const Key('dm-loan-submit')));
    expect(inReview('Ask Bob to lend 300.00 USDC'), findsOneWidget);
    expect(
      inReview(
        'Asking shares your loan record with Bob until they lend, decline, '
        'or the ask ends.',
      ),
      findsOneWidget,
    );
    expect(reviewLine(tester, 'At most you will repay'), '637.50 USDC');
    expect(h.submitted, isEmpty, reason: 'the review comes first');
    await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
    expect(bytesToHex0x(h.submitted.single.authorization), ask.signature);
    expect(find.text(sentWaitingMessage), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await settle(tester);
    expect(find.text('Request sent to Bob'), findsOneWidget);

    // Bob asks me: his card reaches the DM.
    h.post(
      h.card(
        'dm-bob',
        id: 'card-ask',
        kind: 'LOAN_REQUESTED',
        title: 'Bob asks to borrow 300.00 USDC',
        data: _loanCardData(bobsAsk),
      ),
    );
    await settle(tester);
    final open = find.byKey(const Key('finance-card-open-loan'));
    expect(
      find.descendant(of: open, matching: find.text('Review')),
      findsOneWidget,
    );
    await tapAndSettle(tester, open);
    expect(
      find.text(
        "Bob's record: 2 loans from others (2 on time); 1 loan from their "
        'own savings (1 on time).',
      ),
      findsOneWidget,
    );

    await tapAndSettle(tester, find.byKey(const Key('loan-lend')));
    await tapAndSettle(
      tester,
      find.byKey(Key('lend-pocket-${bytesToHex(_goal)}')),
    );
    expect(inReview('Lend 300.00 USDC to Bob'), findsOneWidget);
    expect(reviewLine(tester, 'From'), 'School fees');
    expect(h.submitted, hasLength(1), reason: 'the review comes first');
    await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
    expect(h.prepared.map((p) => p.kind), [_ask, _acceptAsk]);
    expect(bytesToHex0x(h.submitted[1].authorization), acceptAsk.signature);
    expect(h.gate.reasons, [
      'Ask Bob to lend 300.00 USDC',
      'Lend 300.00 USDC to Bob',
    ]);
  });

  testWidgets('5. group: the room money button to a loan request, then an '
      'instalment paid as a contribution', (tester) async {
    final request = engineVector('loan_request');
    final custody = request.room;
    final engines = request.engines();
    final productId = hexToBytes(request.json['product_id'] as String);
    final h = withBob()
      ..addRoom(
        'r-chama',
        'Chama',
        type: 'group',
        roomMembers: [_member('sub-me', 'p-me', 'Me')],
      );
    h.bindings['r-chama'] = pb.StawiRoomBinding(
      state: pb.StawiRoomState.STAWI_ROOM_STATE_BOUND,
      custodyAddress: bytesToHex0x(custody),
      chainId: Int64(146),
    );
    h.financeRooms['r-chama'] = finance.Room(
      roomId: 'r-chama',
      custodyAddress: custody,
      assets: [usdcInfo],
      engines: finance.RoomEngines(
        rulesEngine: finance.RoomEngineBinding(
          address: engines.rulesEngine,
          callable: true,
        ),
        loanBook: finance.RoomEngineBinding(
          address: engines.loanBook,
          callable: true,
        ),
        protocolFee: finance.RoomProtocolFee(incomeFeeBps: 1000),
      ),
    );
    h.financeMembers['r-chama'] = [
      finance.Member(
        memberId: 'm-me',
        profileId: 'p-me',
        accountAddress: myAccount,
        state: finance.MemberState.MEMBER_STATE_ACTIVE,
      ),
    ];
    h.loanProducts['r-chama'] = [
      finance.RoomLoanProduct(
        name: 'Normal loan',
        productId: productId,
        minAmount: usdUnits(10000000),
        maxAmount: usdUnits(1000000000),
        minInstalments: 1,
        maxInstalments: 12,
        rateBps: 250,
        officerApprovals: 1,
      ),
    ];
    // Once requested (and approved), the loan is mine in the room.
    final myLoan = finance.Loan(
      loanBook: engines.loanBook,
      pool: custody,
      borrowerAccount: myAccount,
      onchainLoanId: Int64(1),
      requested: usdUnits(500000000),
      kind: finance.LoanKind.LOAN_KIND_GROUP,
      state: finance.LoanState.LOAN_STATE_FUNDED,
    );
    h
      ..listLoans = ((req) => req.roomId == 'r-chama' && h.submitted.isNotEmpty
          ? [myLoan]
          : const [])
      ..getLoan = ((req) => finance.GetLoanResponse(
        loan: myLoan,
        instalments: [
          for (var i = 0; i < 4; i++)
            finance.LoanInstalment(
              index: i,
              dueAt: wkt.Timestamp.fromDateTime(
                journeyNow.add(Duration(days: 30 * (i + 1))),
              ),
              principal: usdUnits(125000000),
              interest: usdUnits(12500000),
              fee: usdUnits(0),
              paid: usdUnits(0),
            ),
        ],
      ))
      ..prepare = ((req) => switch (req.kind) {
        _loanRequest => request.prepared(req.kind),
        _contribute => _preparedFrom(request.intent, req.kind, (i) {
          i
            ..type = finance.IntentType.INTENT_TYPE_CONTRIBUTION
            ..destination = finance.ValueLocation(
              kind: finance.LocationKind.LOCATION_KIND_ROOM_CUSTODY,
              address: custody,
            )
            ..amount = req.params.amount;
        }),
        _ => throw StateError('unexpected ${req.kind}'),
      });
    await h.pumpApp(tester, '/chat/r-chama');

    await tapAndSettle(tester, find.byKey(const Key('chat-money')));
    expect(find.text('Stawi · Chama'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('stawi-loans')));
    await tapAndSettle(
      tester,
      find.byKey(Key('loan-type-request-${bytesToHex0x(productId)}')),
    );
    await tester.enterText(find.byKey(const Key('group-loan-amount')), '500');
    await tester.enterText(
      find.byKey(const Key('group-loan-instalments')),
      '4',
    );
    await settle(tester);
    expect(
      find.text('Of the interest and fees, 5.00 USDC goes to Stawi'),
      findsOneWidget,
    );
    final quoted = h.financeApi.requestsTo(finance.LoanService.quoteLoan).last;
    expect(quoted.kind, finance.LoanKind.LOAN_KIND_GROUP);

    await tapAndSettle(tester, find.byKey(const Key('group-loan-submit')));
    expect(inReview('Request a loan of 500.00 USDC'), findsOneWidget);
    expect(reviewLine(tester, 'Instalments'), '4');
    expect(reviewLine(tester, 'Stawi fee'), contains('an estimate'));
    expect(h.submitted, isEmpty, reason: 'the review comes first');
    await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
    expect(bytesToHex0x(h.submitted.single.authorization), request.signature);

    // My loans in this room: an instalment is paid as a contribution.
    expect(find.byKey(const Key('my-loan-1')), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('loan-1-pay')));
    expect(inReview('Pay 137.50 USDC toward loan #1 in Chama'), findsOneWidget);
    expect(inReview(groupInstalmentNote), findsOneWidget);
    expect(h.submitted, hasLength(1), reason: 'the review comes first');
    await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
    expect(h.prepared.map((p) => p.kind), [_loanRequest, _contribute]);
    expect(h.prepared[1].params.amount, '137500000');
    expect(
      h.submitted[1].authorization,
      h.signatureOver(h.preparedAnswers[1].intentDigest),
    );
    expect(h.gate.reasons, [
      'Request a loan of 500.00 USDC',
      'Pay 137.50 USDC toward loan #1 in Chama',
    ]);
  });

  group('6. refusals', () {
    testWidgets('an offer settlement prepared as something else is never '
        'shown or signed', (tester) async {
      final h = withBob();
      // Settlement answers the offer with the ask vector.
      h.prepare = (req) => engineVector('ask').prepared(_offer);
      await h.pumpApp(tester, '/chat/dm-bob');

      await tapAndSettle(tester, find.byKey(const Key('chat-money')));
      await tapAndSettle(tester, find.byKey(const Key('dm-lend')));
      await tapAndSettle(
        tester,
        find.byKey(Key('dm-pocket-${bytesToHex(_free)}')),
      );
      await typeOfferTerms(tester);
      await tapAndSettle(tester, find.byKey(const Key('dm-loan-submit')));

      expect(find.byKey(const Key('money-review')), findsNothing);
      expect(
        find.text(
          'Not signed: settlement prepared something else: not the call you '
          'asked for',
        ),
        findsOneWidget,
      );
      expect(h.submitted, isEmpty);
      expect(h.gate.reasons, isEmpty);
    });

    testWidgets('a self-loan the device lock refuses submits nothing', (
      tester,
    ) async {
      final h = selfLoan();
      h.gate.refuse = true;
      await h.pumpApp(tester, '/money');

      await borrowFromSavings(tester);
      expect(inReview('Borrow 200.00 USDC from my savings'), findsOneWidget);
      await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
      expect(h.gate.reasons, ['Borrow 200.00 USDC from my savings']);
      expect(h.submitted, isEmpty);
      expect(
        find.text('Not signed: not confirmed on this device'),
        findsOneWidget,
      );
    });
  });

  testWidgets('7. genesis: a room converted with a DM partner as its agent; '
      "the founder's device checks the genesis and the agent, then signs", (
    tester,
  ) async {
    final vector = GoRoomGenesisVectors.named('agent');
    final member = hexToBytes(
      (vector.json['initial_members'] as List).first as String,
    );
    final agent = hexToBytes(vector.json['agent'] as String);
    // The Go case's genesis, its one initial member the founder (me).
    final genesis = vector.roomGenesis(founderProfileIds: const ['p-me']);
    final h = JourneyHarness(account: member)
      ..addRoom(
        'r-chama',
        'Chama',
        type: 'group',
        roomMembers: [
          _member('sub-me', 'p-me', 'Me'),
          _member('sub-amina', 'p-amina', 'Amina'),
        ],
      )
      ..addDm(
        'dm-agnes',
        'Agnes',
        partnerProfileId: 'p-agent',
        partnerAccount: agent,
      )
      ..addDm('dm-dan', 'Dan')
      ..templates = [
        finance.PolicyTemplate(
          templateId: 'ug_savings_basic',
          name: 'Uganda savings room',
          policy: finance.RoomPolicy(
            governance: finance.Governance(foundingQuorum: 1),
          ),
        ),
      ];
    h.profiles['p-agent'] = const Profile(
      id: 'p-agent',
      name: 'Agnes',
      status: 0,
    );
    h.settlementApi.on(
      settlement.RoomService.getRoomGenesis,
      (req) => settlement.GetRoomGenesisResponse(genesis: genesis),
    );
    await h.pumpApp(tester, '/chat/r-chama');

    // The room's money button opens its Stawi page: a chat room still.
    await tapAndSettle(tester, find.byKey(const Key('chat-money')));
    await tapAndSettle(tester, find.byKey(const Key('stawi-convert')));
    await tapAndSettle(
      tester,
      find.byKey(const Key('template-ug_savings_basic')),
    );

    // Only someone this device can confirm is offered as the agent.
    await tapAndSettle(tester, find.byKey(const Key('stawi-agent')));
    bool enabled(String key) =>
        tester.widget<ListTile>(find.byKey(Key(key))).enabled;
    expect(enabled('agent-member-sub-me'), isTrue);
    expect(enabled('agent-member-sub-amina'), isFalse);
    expect(find.text(agentUnconfirmableReason), findsOneWidget);
    // Agnes has written but is not a member: she is invited into her DM
    // first, and offered only once she accepted for this room.
    expect(enabled('agent-dm-dm-agnes'), isFalse);
    expect(enabled('agent-dm-dm-dan'), isFalse);
    await tapAndSettle(tester, find.byKey(const Key('agent-invite-dm-agnes')));
    final invitation = h.acts.sent.single;
    expect(invitation.roomId, 'dm-agnes');
    expect(invitation.type, RoomEventType.stawiAgentInvitation);
    expect(
      StawiAgentInvitationView.fromContent(invitation.content).roomId,
      'r-chama',
    );
    h.post(
      RoomEvent(
        id: 'inv1',
        roomId: 'dm-agnes',
        senderId: 'sub-me',
        type: RoomEventType.stawiAgentInvitation,
        createdAt: 0,
        status: EventStatus.read,
        content: {...invitation.content, 'roomName': 'Chama'},
      ),
    );
    await settle(tester);
    expect(find.text('Invited; waiting for Agnes to accept'), findsOneWidget);
    expect(enabled('agent-dm-dm-agnes'), isFalse);

    // Agnes accepts in the DM; chat stamps the room and the expiry.
    h.post(
      RoomEvent(
        id: 'acc1',
        roomId: 'dm-agnes',
        senderId: 'sub-agnes',
        type: RoomEventType.stawiAgentAcceptance,
        createdAt: 1,
        status: EventStatus.read,
        content: {
          'invitationEventId': 'inv1',
          'roomId': 'r-chama',
          'roomName': 'Chama',
          'expiresAt': DateTime.now()
              .toUtc()
              .add(const Duration(days: 7))
              .toIso8601String(),
        },
      ),
    );
    await settle(tester);
    expect(enabled('agent-dm-dm-agnes'), isTrue);
    await tapAndSettle(tester, find.byKey(const Key('agent-dm-dm-agnes')));
    await tapAndSettle(tester, find.byKey(const Key('stawi-send-conversion')));

    final conversion = h.acts.sent[1];
    expect(conversion.type, RoomEventType.stawiRoomConversion);
    final view = StawiConversionView.fromContent(conversion.content);
    expect(view.agentProfileId, 'p-agent');
    expect(view.founderSubscriptionIds, ['sub-me']);

    // Chat prepares the genesis and turns the conversion into its card.
    h.post(
      RoomEvent(
        id: 'conv1',
        roomId: 'r-chama',
        senderId: 'sub-me',
        type: RoomEventType.stawiRoomConversion,
        createdAt: 0,
        status: EventStatus.read,
        content: {
          ...conversion.content,
          'genesis': {
            'genesisId': genesis.genesisId,
            'genesisHash': base64Encode(genesis.genesisHash),
            'constitutionHash': base64Encode(genesis.constitutionHash),
            'founderProfileIds': ['p-me'],
            'expiresAt': DateTime.now()
                .toUtc()
                .add(const Duration(days: 1))
                .toIso8601String(),
          },
        },
      ),
    );
    await tapAndSettle(tester, find.byTooltip('Back'));
    expect(find.byKey(const Key('genesis-card-conv1')), findsOneWidget);

    final before = h.chatApi
        .requestsTo(pb.ChatService.getDirectPartnerAccount)
        .length;
    await tapAndSettle(tester, find.byKey(const Key('genesis-open-review')));
    // The agent's address is confirmed with chat's answer for Agnes's DM,
    // the one the picker asked for: lookups are kept for the session.
    final lookups = h.chatApi.requestsTo(
      pb.ChatService.getDirectPartnerAccount,
    );
    expect(lookups.map((r) => r.roomId), contains('dm-agnes'));
    expect(lookups.skip(before), isEmpty, reason: 'asked once a session');
    expect(find.byKey(const Key('genesis-review')), findsOneWidget);
    expect(find.text('Stawi agent: Agnes'), findsOneWidget);
    expect(find.byKey(const Key('genesis-agent-unconfirmed')), findsNothing);
    expect(h.acts.sent, hasLength(2), reason: 'nothing is signed first');

    await tapAndSettle(tester, find.byKey(const Key('genesis-sign')));
    final signed = h.acts.sent[2];
    expect(signed.type, RoomEventType.stawiGenesisSignature);
    expect(signed.parentId, 'conv1');
    // The founder signs their account's wrapping of the Go genesis hash.
    final digest = accountWrappedHash(
      member,
      BigInt.from(vector.json['chain_id'] as int),
      vector.genesisHash,
    );
    expect(genesis.founders.single.signingDigest, digest);
    expect(
      base64Decode(signed.content['signature'] as String),
      h.signatureOver(digest),
    );
    expect(h.gate.reasons, ['Found Chama on Stawi']);
    expect(find.text('Genesis signed'), findsOneWidget);
  });

  testWidgets('8. send from My money to a DM partner; loans name the other '
      'person', (tester) async {
    final unknown = Uint8List.fromList(List.filled(20, 0xdd));
    final deposit = GoVaultVectors.load().deposits.first;
    final h = withBob()
      ..addDm('dm-dan', 'Dan')
      ..addRoom('r-chama', 'Chama', type: 'group')
      ..listLoans = ((req) => bytesEqual(req.borrower, myAccount)
          ? [
              _p2p(
                lender: bobAccount,
                borrower: myAccount,
                offeredBy: bobAccount,
                loanId: 1,
                state: finance.LoanState.LOAN_STATE_FUNDED,
              ),
              _p2p(
                lender: unknown,
                borrower: myAccount,
                offeredBy: unknown,
                loanId: 2,
                state: finance.LoanState.LOAN_STATE_FUNDED,
              ),
            ]
          : const [])
      ..prepare = ((req) => _preparedFrom(deposit.intent, _transfer, (i) {
        i
          ..destination = finance.ValueLocation(
            kind: finance.LocationKind.LOCATION_KIND_USER_ACCOUNT,
            address: req.params.destination.address,
          )
          ..amount = req.params.amount
          ..mode =
              finance.AuthorizationMode.AUTHORIZATION_MODE_DIRECT_SIGNATURE;
      }));
    await h.pumpApp(tester, '/money');

    // A loan names the DM partner whose account it is with; one with an
    // account none of the person's DMs has is a short address.
    expect(find.text('From Bob'), findsOneWidget);
    expect(find.text('From 0xdddd…dddd ($notOneOfYourChats)'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(const Key('wallet-send')));
    expect(find.byKey(const Key('dm-partner-picker')), findsOneWidget);
    expect(find.byKey(const Key('dm-partner-r-chama')), findsNothing);
    expect(
      tester
          .widget<ListTile>(find.byKey(const Key('dm-partner-dm-dan')))
          .enabled,
      isFalse,
    );
    expect(find.text('Dan needs to send you a message first'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('dm-partner-dm-dan')));
    expect(find.byKey(const Key('dm-partner-picker')), findsOneWidget);

    await tapAndSettle(tester, find.byKey(const Key('dm-partner-dm-bob')));
    await tester.enterText(find.byKey(const Key('amount-field')), '50');
    await settle(tester);
    await tapAndSettle(tester, find.byKey(const Key('amount-confirm')));

    expect(inReview('Send 50.00 USDC to Bob'), findsOneWidget);
    expect(h.submitted, isEmpty, reason: 'the review comes first');
    final req = h.prepared.single;
    expect(req.kind, _transfer);
    expect(req.params.destination.address, bobAccount);
    expect(req.params.amount, '50000000');
    await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
    expect(
      h.submitted.single.authorization,
      h.signatureOver(h.preparedAnswers.single.intentDigest),
    );
    expect(h.gate.reasons, ['Send 50.00 USDC to Bob']);
  });
}
