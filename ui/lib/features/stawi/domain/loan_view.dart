import 'dart:typed_data';

import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' as sdk;

import 'loan_terms.dart';
import 'signing_checks.dart' show bytesEqual;

/// Who the person is in a loan. [member] is someone else's group loan.
enum LoanRole { borrower, lender, member }

BigInt _units(finance.Money m) => BigInt.tryParse(m.amount) ?? BigInt.zero;

/// What an instalment costs in all: principal, interest and its fee.
BigInt instalmentTotal(finance.LoanInstalment i) =>
    _units(i.principal) + _units(i.interest) + _units(i.fee);

/// What is still owed on an instalment; never below zero.
BigInt instalmentOwed(finance.LoanInstalment i) {
  final owed = instalmentTotal(i) - _units(i.paid);
  return owed.isNegative ? BigInt.zero : owed;
}

/// A loan as the person looking at it sees it.
final class LoanView {
  LoanView(
    this.loan, {
    required List<Uint8List> mine,
    this.instalments = const [],
  }) : _mine = mine;

  final finance.Loan loan;
  final List<finance.LoanInstalment> instalments;
  final List<Uint8List> _mine;

  bool _isMine(List<int> account) =>
      account.isNotEmpty && _mine.any((a) => bytesEqual(a, account));

  LoanRole get role {
    if (_isMine(loan.borrowerAccount)) return LoanRole.borrower;
    if (!isGroup && _isMine(loan.lender)) return LoanRole.lender;
    return LoanRole.member;
  }

  bool get isPersonal => loan.kind != finance.LoanKind.LOAN_KIND_GROUP;
  bool get isSelf => loan.kind == finance.LoanKind.LOAN_KIND_SELF;
  bool get isGroup => !isPersonal;

  bool get _pendingP2p =>
      loan.kind == finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON &&
      loan.state == finance.LoanState.LOAN_STATE_PENDING_APPROVAL;

  bool get isOpenOffer =>
      _pendingP2p &&
      loan.offeredBy.isNotEmpty &&
      bytesEqual(loan.offeredBy, loan.lender);

  bool get isOpenAsk =>
      _pendingP2p &&
      loan.offeredBy.isNotEmpty &&
      bytesEqual(loan.offeredBy, loan.borrowerAccount);

  /// An open offer made to me, or an open ask made of me.
  bool get awaitsMe =>
      (isOpenOffer && role == LoanRole.borrower) ||
      (isOpenAsk && role == LoanRole.lender);

  bool get _recovered {
    final v = BigInt.tryParse(loan.recovered.amount);
    return v != null && v > BigInt.zero;
  }

  String get stateLabel => switch (loan.state) {
    finance.LoanState.LOAN_STATE_PENDING_APPROVAL =>
      isPersonal ? 'Waiting' : 'Waiting for approval',
    finance.LoanState.LOAN_STATE_SUBMITTED => 'Waiting for approval',
    finance.LoanState.LOAN_STATE_ELIGIBILITY_FAILED => 'Not eligible',
    finance.LoanState.LOAN_STATE_APPROVED => 'Approved',
    finance.LoanState.LOAN_STATE_REJECTED => 'Not approved',
    finance.LoanState.LOAN_STATE_FUNDED => 'Active',
    finance.LoanState.LOAN_STATE_PAID =>
      _recovered ? 'Closed after recovery' : 'Repaid',
    finance.LoanState.LOAN_STATE_DEFAULTED => 'In default',
    finance.LoanState.LOAN_STATE_RESTRUCTURED => 'Restructured',
    finance.LoanState.LOAN_STATE_WRITTEN_OFF => 'Written off',
    finance.LoanState.LOAN_STATE_CANCELLED => 'Cancelled',
    _ => 'Unknown',
  };

  /// The first instalment not fully paid.
  finance.LoanInstalment? get next {
    for (final i in instalments) {
      if (instalmentOwed(i) > BigInt.zero) return i;
    }
    return null;
  }

  /// What is left on [next]: principal + interest + fee − paid.
  BigInt get nextOwed {
    final n = next;
    return n == null ? BigInt.zero : instalmentOwed(n);
  }

  /// The largest instalment, for the standing order line: the SDK's figure
  /// for a personal loan, the schedule's own for a group loan.
  BigInt get largestInstalment {
    if (isPersonal && loan.hasTerms()) {
      final amount = BigInt.tryParse(loan.requested.amount);
      if (amount != null && amount > BigInt.zero) {
        try {
          return sdk.largestInstalment(amount, LoanTerms(loan.terms).sdk);
        } on FormatException {
          // Fall through to the schedule.
        }
      }
    }
    var largest = BigInt.zero;
    for (final i in instalments) {
      final v = instalmentTotal(i);
      if (v > largest) largest = v;
    }
    return largest;
  }
}
