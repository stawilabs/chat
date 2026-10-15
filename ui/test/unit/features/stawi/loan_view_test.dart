import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/domain/loan_terms.dart';
import 'package:stawi/features/stawi/domain/loan_view.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' as sdk;

import '../../../support/stawi_fakes.dart';

Uint8List addr(int b) => Uint8List.fromList(List.filled(20, b));

finance.Money money(int units) =>
    finance.Money(amount: '$units', assetId: 'USDC.146');

finance.LoanInstalment instalment(
  int index, {
  int principal = 70,
  int interest = 7,
  int fee = 0,
  int paid = 0,
  bool late = false,
}) => finance.LoanInstalment(
  index: index,
  principal: money(principal),
  interest: money(interest),
  fee: money(fee),
  paid: money(paid),
  late: late,
);

finance.Loan p2p({
  finance.LoanState state = finance.LoanState.LOAN_STATE_PENDING_APPROVAL,
  List<int>? offeredBy,
  finance.Money? recovered,
}) => finance.Loan(
  kind: finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON,
  state: state,
  lender: addr(1),
  borrowerAccount: addr(2),
  offeredBy: offeredBy,
  recovered: recovered,
);

void main() {
  final lender = addr(1);
  final borrower = addr(2);
  final stranger = addr(3);

  test('the role follows the borrower account and the lender', () {
    final loan = p2p();
    expect(LoanView(loan, mine: [borrower]).role, LoanRole.borrower);
    expect(LoanView(loan, mine: [lender]).role, LoanRole.lender);
    expect(LoanView(loan, mine: [stranger]).role, LoanRole.member);
    final group = finance.Loan(
      kind: finance.LoanKind.LOAN_KIND_GROUP,
      pool: addr(9),
      borrowerAccount: borrower,
    );
    expect(LoanView(group, mine: [borrower]).role, LoanRole.borrower);
    expect(LoanView(group, mine: [addr(9)]).role, LoanRole.member);
    expect(LoanView(group, mine: [borrower]).isGroup, isTrue);
  });

  test('personal, self and group kinds', () {
    final self = finance.Loan(kind: finance.LoanKind.LOAN_KIND_SELF);
    final v = LoanView(self, mine: const []);
    expect(v.isSelf, isTrue);
    expect(v.isPersonal, isTrue);
    expect(v.isGroup, isFalse);
  });

  test('an offer or an ask is told by who proposed it', () {
    final offer = LoanView(p2p(offeredBy: lender), mine: [borrower]);
    expect(offer.isOpenOffer, isTrue);
    expect(offer.isOpenAsk, isFalse);
    expect(offer.awaitsMe, isTrue);
    expect(LoanView(p2p(offeredBy: lender), mine: [lender]).awaitsMe, isFalse);

    final ask = LoanView(p2p(offeredBy: borrower), mine: [lender]);
    expect(ask.isOpenAsk, isTrue);
    expect(ask.isOpenOffer, isFalse);
    expect(ask.awaitsMe, isTrue);
    expect(
      LoanView(p2p(offeredBy: borrower), mine: [borrower]).awaitsMe,
      isFalse,
    );

    final active = LoanView(
      p2p(state: finance.LoanState.LOAN_STATE_FUNDED, offeredBy: lender),
      mine: [borrower],
    );
    expect(active.isOpenOffer, isFalse);
    expect(active.awaitsMe, isFalse);
  });

  test('every state has its words', () {
    String label(finance.LoanState s, {finance.Money? recovered}) => LoanView(
      p2p(state: s, recovered: recovered),
      mine: const [],
    ).stateLabel;
    expect(label(finance.LoanState.LOAN_STATE_PENDING_APPROVAL), 'Waiting');
    expect(label(finance.LoanState.LOAN_STATE_APPROVED), 'Approved');
    expect(label(finance.LoanState.LOAN_STATE_FUNDED), 'Active');
    expect(label(finance.LoanState.LOAN_STATE_PAID), 'Repaid');
    expect(
      label(finance.LoanState.LOAN_STATE_PAID, recovered: money(0)),
      'Repaid',
    );
    expect(
      label(finance.LoanState.LOAN_STATE_PAID, recovered: money(25)),
      'Closed after recovery',
    );
    expect(label(finance.LoanState.LOAN_STATE_DEFAULTED), 'In default');
    expect(label(finance.LoanState.LOAN_STATE_WRITTEN_OFF), 'Written off');
    expect(label(finance.LoanState.LOAN_STATE_CANCELLED), 'Cancelled');
    final group = finance.Loan(
      kind: finance.LoanKind.LOAN_KIND_GROUP,
      state: finance.LoanState.LOAN_STATE_PENDING_APPROVAL,
    );
    expect(LoanView(group, mine: const []).stateLabel, 'Waiting for approval');
  });

  test('the next instalment is the first not fully paid, fee included', () {
    final view = LoanView(
      p2p(state: finance.LoanState.LOAN_STATE_FUNDED),
      mine: [borrower],
      instalments: [
        instalment(0, paid: 77),
        instalment(1, fee: 3, paid: 20),
        instalment(2, fee: 3),
      ],
    );
    expect(view.next!.index, 1);
    // 70 + 7 + 3 - 20
    expect(view.nextOwed, BigInt.from(60));
  });

  test('nothing is next when every instalment is paid', () {
    final view = LoanView(
      p2p(state: finance.LoanState.LOAN_STATE_PAID),
      mine: [borrower],
      instalments: [instalment(0, paid: 77), instalment(1, paid: 80)],
    );
    expect(view.next, isNull);
    expect(view.nextOwed, BigInt.zero);
  });

  test('the largest instalment is the SDK\'s for a personal loan', () {
    final g = GoVaultVectors.load().standingGrants.first;
    final view = LoanView(g.loan, mine: [g.account]);
    expect(view.largestInstalment, g.largestInstalment);
    expect(
      view.largestInstalment,
      sdk.largestInstalment(g.amount, LoanTerms(g.loan.terms).sdk),
    );
  });

  test('a group loan\'s largest instalment is read off its schedule', () {
    final group = finance.Loan(
      kind: finance.LoanKind.LOAN_KIND_GROUP,
      state: finance.LoanState.LOAN_STATE_FUNDED,
      onchainLoanId: Int64(4),
    );
    final view = LoanView(
      group,
      mine: const [],
      instalments: [instalment(0), instalment(1, fee: 5)],
    );
    expect(view.largestInstalment, BigInt.from(82));
  });
}
