import 'dart:typed_data';

import 'package:connectrpc/connect.dart' as connect;
import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../domain/loan_terms.dart';
import '../domain/personal_calls.dart';
import '../domain/signing_checks.dart';
import 'stawi_clients.dart';
import 'stawi_identity.dart';

/// Loans as finance reads them off the LoanBook: the person's own, those
/// between two people, a room's, and quotes before anything is signed.
class StawiLoanService {
  StawiLoanService({
    required finance.LoanServiceClient loans,
    required Future<StawiIdentity> Function() identity,
  }) : _loans = loans,
       _identity = identity;

  final finance.LoanServiceClient _loans;
  final Future<StawiIdentity> Function() _identity;

  Future<Uint8List> _account() async {
    final account = (await _identity()).primary;
    if (account == null) {
      throw const StawiUnavailable('Your profile has no Stawi account yet');
    }
    return account.address;
  }

  /// Loans the person borrowed.
  Future<List<finance.Loan>> borrowed() async => (await _loans.listLoans(
    finance.ListLoansRequest(borrower: await _account()),
  )).loans;

  /// Loans the person lent to another person.
  Future<List<finance.Loan>> lent() async => (await _loans.listLoans(
    finance.ListLoansRequest(
      lender: await _account(),
      kind: finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON,
    ),
  )).loans;

  /// A room's loans.
  Future<List<finance.Loan>> roomLoans(String roomId) async =>
      (await _loans.listLoans(finance.ListLoansRequest(roomId: roomId))).loans;

  /// The person-to-person loans between [me] and [other], either way.
  Future<List<finance.Loan>> between(Uint8List me, Uint8List other) async {
    final both = await Future.wait([
      _loans.listLoans(
        finance.ListLoansRequest(
          borrower: me,
          lender: other,
          kind: finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON,
        ),
      ),
      _loans.listLoans(
        finance.ListLoansRequest(
          borrower: other,
          lender: me,
          kind: finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON,
        ),
      ),
    ]);
    // The filter is repeated here: a pair is only ever these two accounts,
    // whatever the server returned.
    bool pair(finance.Loan l) =>
        (bytesEqual(l.borrowerAccount, me) && bytesEqual(l.lender, other)) ||
        (bytesEqual(l.borrowerAccount, other) && bytesEqual(l.lender, me));
    final seen = <LoanRef>{};
    return [
      for (final response in both)
        for (final l in response.loans)
          if (pair(l) && seen.add(LoanRef.of(l))) l,
    ];
  }

  Future<finance.GetLoanResponse> loan(LoanRef ref) => _loans.getLoan(
    finance.GetLoanRequest(
      pool: ref.pool,
      onchainLoanId: _int64(ref.loanId),
      loanBook: ref.loanBook,
    ),
  );

  /// What a personal loan of [amount] on [terms] costs.
  Future<finance.QuoteLoanResponse> quotePersonal({
    required BigInt amount,
    required LoanTerms terms,
    required finance.LoanKind kind,
  }) => _loans.quoteLoan(
    finance.QuoteLoanRequest(
      amount: amount.toString(),
      terms: terms.proto,
      kind: kind,
    ),
  );

  /// What a room's loan product costs for [amount] over [instalments].
  Future<finance.QuoteLoanResponse> quoteGroup({
    required String roomId,
    required Uint8List productId,
    required BigInt amount,
    required int instalments,
  }) => _loans.quoteLoan(
    finance.QuoteLoanRequest(
      amount: amount.toString(),
      kind: finance.LoanKind.LOAN_KIND_GROUP,
      roomId: roomId,
      productId: productId,
      instalments: instalments,
    ),
  );

  /// [borrower]'s credit record. A record they do not share is a plain
  /// [StawiUnavailable], not an error.
  Future<finance.GetCreditRecordResponse> record(Uint8List borrower) async {
    try {
      return await _loans.getCreditRecord(
        finance.GetCreditRecordRequest(borrower: borrower),
      );
    } on connect.ConnectException catch (e) {
      if (e.code == connect.Code.permissionDenied) {
        throw const StawiUnavailable('Their record is not shared with you');
      }
      rethrow;
    }
  }
}

Int64 _int64(BigInt v) => Int64.parseInt(v.toString());

final stawiLoanServiceProvider = Provider<StawiLoanService>(
  (ref) => StawiLoanService(
    loans: ref.watch(financeLoansProvider),
    identity: () => ref.read(stawiIdentityProvider.future),
  ),
);

final myBorrowedLoansProvider = FutureProvider.autoDispose<List<finance.Loan>>(
  (ref) => ref.watch(stawiLoanServiceProvider).borrowed(),
);

final myLentLoansProvider = FutureProvider.autoDispose<List<finance.Loan>>(
  (ref) => ref.watch(stawiLoanServiceProvider).lent(),
);

final roomLoansProvider = FutureProvider.autoDispose
    .family<List<finance.Loan>, String>(
      (ref, roomId) => ref.watch(stawiLoanServiceProvider).roomLoans(roomId),
    );

final loanProvider = FutureProvider.autoDispose
    .family<finance.GetLoanResponse, LoanRef>(
      (ref, loanRef) => ref.watch(stawiLoanServiceProvider).loan(loanRef),
    );

final creditRecordProvider = FutureProvider.autoDispose
    .family<finance.GetCreditRecordResponse, String>(
      (ref, borrowerHex) =>
          ref.watch(stawiLoanServiceProvider).record(hexToBytes(borrowerHex)),
      // A record that is not shared stays not shared; do not ask again.
      retry: (_, _) => null,
    );
