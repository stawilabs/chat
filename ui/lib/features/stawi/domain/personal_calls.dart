import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_api/well_known.dart' as wkt;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' as sdk;

import 'loan_terms.dart';

/// A person's own loan and savings calls: personal loans on the LoanBook
/// (to oneself, or between two people) and the owner's actions on their
/// PersonalVault. Each is a device-signed AccountService call settlement
/// prepares as an ENGINE_CALL intent on the personal path, checked on the
/// device with the SDK (checkedPersonalCall) before it is signed.
enum PersonalCall {
  borrowSelf(
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_BORROW_SELF,
    sdk.EngineAction.borrowSelf,
    'Borrow from my savings',
  ),
  offer(
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_OFFER,
    sdk.EngineAction.offer,
    'Lend',
  ),
  ask(
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_ASK,
    sdk.EngineAction.ask,
    'Ask to borrow',
  ),
  acceptOffer(
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_ACCEPT_OFFER,
    sdk.EngineAction.acceptOffer,
    'Accept',
  ),
  acceptAsk(
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_ACCEPT_ASK,
    sdk.EngineAction.acceptAsk,
    'Lend',
  ),
  pay(
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_PAY,
    sdk.EngineAction.pay,
    'Pay an instalment',
  ),
  cancel(
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_PERSONAL_LOAN_CANCEL,
    sdk.EngineAction.personalCancel,
    'Cancel',
  ),
  payoff(
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_PERSONAL_LOAN_PAYOFF,
    sdk.EngineAction.personalPayoff,
    'Pay off the loan',
  ),
  withdraw(
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_VAULT_WITHDRAW,
    sdk.EngineAction.vaultWithdraw,
    'Withdraw my savings',
  ),
  createGoal(
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_VAULT_CREATE_GOAL,
    sdk.EngineAction.vaultCreateGoal,
    'Start a savings goal',
  ),
  move(
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_VAULT_MOVE,
    sdk.EngineAction.vaultMove,
    'Move my savings',
  );

  const PersonalCall(this.kind, this.action, this.label);

  final settlement.AccountCallKind kind;
  final sdk.EngineAction action;
  final String label;

  /// Whether the call moves or commits an amount the person states (or, for
  /// acceptAsk, the ask's). Only a payoff may leave it to settlement's quote.
  bool get takesAmount => switch (this) {
    cancel || createGoal || acceptOffer => false,
    _ => true,
  };

  /// Whether the call acts on a loan that already exists on a LoanBook.
  bool get onExistingLoan => switch (this) {
    acceptOffer || acceptAsk || pay || cancel || payoff => true,
    _ => false,
  };
}

/// A loan as the LoanBook names it: loan numbers restart per book and per
/// pool, so a loan is (loan book, pool, loan id).
final class LoanRef {
  const LoanRef({
    required this.loanBook,
    required this.pool,
    required this.loanId,
  });

  factory LoanRef.of(finance.Loan loan) => LoanRef(
    loanBook: Uint8List.fromList(loan.loanBook),
    pool: Uint8List.fromList(loan.pool),
    loanId: BigInt.parse(loan.onchainLoanId.toStringUnsigned()),
  );

  final Uint8List loanBook;
  final Uint8List pool;
  final BigInt loanId;

  @override
  bool operator ==(Object other) =>
      other is LoanRef &&
      other.loanId == loanId &&
      _same(other.loanBook, loanBook) &&
      _same(other.pool, pool);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(loanBook), Object.hashAll(pool), loanId);

  @override
  String toString() =>
      'LoanRef(${sdk.bytesToHex0x(loanBook)}, ${sdk.bytesToHex0x(pool)}, '
      '$loanId)';
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// A goal name is at most this many bytes of UTF-8 (SavingsGoalSpec.name).
const int maxGoalNameBytes = 80;

/// One personal call a person asks for. Each named constructor fills the
/// request settlement prepares from ([params]) and the call the SDK compares
/// the prepared calldata with ([expected]) from the same inputs: what the
/// person typed or tapped, or the loan the app showed them. Inputs a call
/// cannot take throw [FormatException] in the person's words.
final class PersonalRequest {
  /// A loan to oneself from one's own vault [pocket] (32 zero bytes: free
  /// savings).
  factory PersonalRequest.borrowSelf({
    required Uint8List pocket,
    required BigInt amount,
    required LoanTerms terms,
  }) {
    _pocket(pocket);
    _amount(amount, uint128: true);
    final t = terms.sdk;
    return PersonalRequest._(
      PersonalCall.borrowSelf,
      params: settlement.AccountCallParams(
        pocket: _pocketParam(pocket),
        amount: amount.toString(),
        terms: terms.proto,
      ),
      expected: sdk.EngineCall(
        action: sdk.EngineAction.borrowSelf,
        pocket: pocket,
        amount: amount,
        terms: t,
      ),
    );
  }

  /// An offer to lend [amount] to [borrower] from [pocket], open until
  /// [expiresAt] (whole seconds; anything finer is dropped).
  factory PersonalRequest.offer({
    required Uint8List borrower,
    required Uint8List pocket,
    required BigInt amount,
    required LoanTerms terms,
    required DateTime expiresAt,
  }) {
    _party(borrower);
    _pocket(pocket);
    _amount(amount, uint128: true);
    final t = terms.sdk;
    final expiry = _seconds(expiresAt);
    return PersonalRequest._(
      PersonalCall.offer,
      params: settlement.AccountCallParams(
        counterparty: borrower,
        pocket: _pocketParam(pocket),
        amount: amount.toString(),
        terms: terms.proto,
        expiresAt: _timestamp(expiry),
      ),
      expected: sdk.EngineCall(
        action: sdk.EngineAction.offer,
        party: borrower,
        pocket: pocket,
        amount: amount,
        terms: t,
        expiresAt: expiry,
      ),
    );
  }

  /// An ask to borrow [amount] from [lender], open until [expiresAt]. The
  /// most the person could repay is the SDK's [sdk.maxRepayable] of the
  /// amount and terms; the SDK checks the prepared call commits exactly it.
  factory PersonalRequest.ask({
    required Uint8List lender,
    required BigInt amount,
    required LoanTerms terms,
    required DateTime expiresAt,
  }) {
    _party(lender);
    _amount(amount, uint128: true);
    final t = terms.sdk;
    final expiry = _seconds(expiresAt);
    return PersonalRequest._(
      PersonalCall.ask,
      params: settlement.AccountCallParams(
        counterparty: lender,
        amount: amount.toString(),
        terms: terms.proto,
        expiresAt: _timestamp(expiry),
      ),
      expected: sdk.EngineCall(
        action: sdk.EngineAction.ask,
        party: lender,
        amount: amount,
        terms: t,
        expiresAt: expiry,
      ),
      maxRepay: _maxRepay(amount, t),
    );
  }

  /// Accepting [offer], the person-to-person offer the app showed: the call
  /// is checked against its pool, loan, lender, amount and terms, and on its
  /// own loan book.
  factory PersonalRequest.acceptOffer({required finance.Loan offer}) {
    if (offer.kind != finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON) {
      throw const FormatException('Only an offer from a person is accepted');
    }
    final ref = _ref(offer);
    _party(offer.lender);
    final amount = _money(offer.requested);
    _amount(amount, uint128: true);
    final t = LoanTerms(offer.terms).sdk;
    return PersonalRequest._(
      PersonalCall.acceptOffer,
      params: settlement.AccountCallParams(
        pool: ref.pool,
        loanId: offer.onchainLoanId,
        loanBook: ref.loanBook,
      ),
      expected: sdk.EngineCall(
        action: sdk.EngineAction.acceptOffer,
        pool: ref.pool,
        loanId: ref.loanId,
      ),
      loan: offer,
      offer: (
        pool: ref.pool,
        loanId: ref.loanId,
        lender: Uint8List.fromList(offer.lender),
        amount: amount,
        terms: t,
      ),
      maxRepay: _maxRepay(amount, t),
    );
  }

  /// Lending what [ask] asked for, from [pocket].
  factory PersonalRequest.acceptAsk({
    required finance.Loan ask,
    required Uint8List pocket,
  }) {
    if (ask.kind != finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON) {
      throw const FormatException('Only an ask from a person is lent to');
    }
    final ref = _ref(ask);
    _party(ask.borrowerAccount);
    _pocket(pocket);
    final amount = _money(ask.requested);
    _amount(amount, uint128: true);
    return PersonalRequest._(
      PersonalCall.acceptAsk,
      params: settlement.AccountCallParams(
        counterparty: ask.borrowerAccount,
        loanId: ask.onchainLoanId,
        amount: amount.toString(),
        pocket: _pocketParam(pocket),
        loanBook: ref.loanBook,
      ),
      expected: sdk.EngineCall(
        action: sdk.EngineAction.acceptAsk,
        party: ask.borrowerAccount,
        loanId: ref.loanId,
        amount: amount,
        pocket: pocket,
      ),
      loan: ask,
    );
  }

  /// Paying [amount] toward [loan].
  factory PersonalRequest.pay({
    required finance.Loan loan,
    required BigInt amount,
  }) {
    final ref = _ref(loan);
    _amount(amount);
    return PersonalRequest._(
      PersonalCall.pay,
      params: settlement.AccountCallParams(
        pool: ref.pool,
        loanId: loan.onchainLoanId,
        amount: amount.toString(),
        loanBook: ref.loanBook,
      ),
      expected: sdk.EngineCall(
        action: sdk.EngineAction.pay,
        pool: ref.pool,
        loanId: ref.loanId,
        amount: amount,
      ),
      loan: loan,
    );
  }

  /// Cancelling (or declining) [loan] before it is accepted.
  factory PersonalRequest.cancel({required finance.Loan loan}) {
    final ref = _ref(loan);
    return PersonalRequest._(
      PersonalCall.cancel,
      params: settlement.AccountCallParams(
        pool: ref.pool,
        loanId: loan.onchainLoanId,
        loanBook: ref.loanBook,
      ),
      expected: sdk.EngineCall(
        action: sdk.EngineAction.personalCancel,
        pool: ref.pool,
        loanId: ref.loanId,
      ),
      loan: loan,
    );
  }

  /// Paying [loan] off, paying at most [ceiling]; without one settlement
  /// quotes the ceiling, which the person sees before signing.
  factory PersonalRequest.payoff({
    required finance.Loan loan,
    BigInt? ceiling,
  }) {
    final ref = _ref(loan);
    if (ceiling != null) _amount(ceiling);
    return PersonalRequest._(
      PersonalCall.payoff,
      params: settlement.AccountCallParams(
        pool: ref.pool,
        loanId: loan.onchainLoanId,
        amount: ceiling?.toString() ?? '',
        loanBook: ref.loanBook,
      ),
      expected: sdk.EngineCall(
        action: sdk.EngineAction.personalPayoff,
        pool: ref.pool,
        loanId: ref.loanId,
        amount: ceiling ?? BigInt.zero,
      ),
      loan: loan,
    );
  }

  /// Withdrawing [amount] from [pocket] back to the person's account.
  factory PersonalRequest.withdraw({
    required Uint8List pocket,
    required BigInt amount,
  }) {
    _pocket(pocket);
    _amount(amount);
    return PersonalRequest._(
      PersonalCall.withdraw,
      params: settlement.AccountCallParams(
        pocket: _pocketParam(pocket),
        amount: amount.toString(),
      ),
      expected: sdk.EngineCall(
        action: sdk.EngineAction.vaultWithdraw,
        pocket: pocket,
        amount: amount,
      ),
    );
  }

  /// A savings goal named [name] (1 to 80 bytes of UTF-8; the chain holds its
  /// keccak256), saving toward [target], withdrawable from [unlockAt].
  factory PersonalRequest.createGoal({
    required String name,
    required BigInt target,
    required DateTime unlockAt,
    required bool loanable,
  }) {
    final bytes = utf8.encode(name);
    if (bytes.isEmpty) throw const FormatException('Name the goal');
    if (bytes.length > maxGoalNameBytes) {
      throw const FormatException('A goal name is at most 80 bytes');
    }
    if (target.isNegative || target > sdk.maxUint128) {
      throw const FormatException('Enter a target amount');
    }
    final unlock = _seconds(unlockAt);
    return PersonalRequest._(
      PersonalCall.createGoal,
      params: settlement.AccountCallParams(
        goal: settlement.SavingsGoalSpec(
          name: name,
          target: target.toString(),
          unlockAt: _timestamp(unlock),
          loanable: loanable,
        ),
      ),
      expected: sdk.EngineCall(
        action: sdk.EngineAction.vaultCreateGoal,
        goalNameHash: sdk.keccak256(bytes),
        goalTarget: target,
        goalUnlockAt: unlock,
        goalLoanable: loanable,
      ),
    );
  }

  /// Moving [amount] from pocket [from] to pocket [to].
  factory PersonalRequest.move({
    required Uint8List from,
    required Uint8List to,
    required BigInt amount,
  }) {
    _pocket(from);
    _pocket(to);
    if (_same(from, to)) {
      throw const FormatException('Choose another pocket to move to');
    }
    _amount(amount);
    return PersonalRequest._(
      PersonalCall.move,
      params: settlement.AccountCallParams(
        pocket: _pocketParam(from),
        toPocket: _pocketParam(to),
        amount: amount.toString(),
      ),
      expected: sdk.EngineCall(
        action: sdk.EngineAction.vaultMove,
        pocket: from,
        toPocket: to,
        amount: amount,
      ),
    );
  }

  PersonalRequest._(
    this.call, {
    required this.params,
    required this.expected,
    this.loan,
    this.offer,
    this.maxRepay,
  }) : assert(expected.action == call.action, 'the call and its action agree'),
       loanBook = loan == null ? null : Uint8List.fromList(loan.loanBook);

  final PersonalCall call;

  /// What settlement prepares from.
  final settlement.AccountCallParams params;

  /// What the SDK compares the calldata with (verifyEngineCallIntent
  /// `expected:`).
  final sdk.EngineCall expected;

  /// The existing loan the call acts on, as the app showed it.
  final finance.Loan? loan;

  /// acceptOffer only: the offer the app showed (verifyEngineCallIntent
  /// `offer:`).
  final sdk.PersonalOffer? offer;

  /// The book an existing loan is on (verifyEngineCallIntent `loanBook:`);
  /// the same bytes go in [params] as `loan_book`.
  final Uint8List? loanBook;

  /// ask and acceptOffer: the SDK's [sdk.maxRepayable] of the loan, what the
  /// review shows as "At most you will repay".
  final BigInt? maxRepay;
}

/// The loan as the LoanBook names it, refusing one the app cannot name.
LoanRef _ref(finance.Loan loan) {
  final ref = LoanRef.of(loan);
  if (ref.loanBook.length != 20 || _zero(ref.loanBook)) {
    throw const FormatException('The loan\'s book is not known');
  }
  if (ref.pool.length != 20 || _zero(ref.pool) || ref.loanId <= BigInt.zero) {
    throw const FormatException('Choose a loan');
  }
  return ref;
}

bool _zero(List<int> b) => b.every((x) => x == 0);

void _pocket(List<int> pocket) {
  if (pocket.length != 32) {
    throw const FormatException('Choose a savings pocket');
  }
}

/// Free savings (the zero pocket) is left unset in the params: settlement
/// reads an empty pocket as the free balance.
Uint8List? _pocketParam(Uint8List pocket) =>
    _zero(pocket) ? null : Uint8List.fromList(pocket);

void _party(List<int> account) {
  if (account.length != 20 || _zero(account)) {
    throw const FormatException('The other person has no Stawi account');
  }
}

void _amount(BigInt amount, {bool uint128 = false}) {
  if (amount <= BigInt.zero) {
    throw const FormatException('Enter an amount greater than zero');
  }
  if (amount.bitLength > (uint128 ? 128 : 256)) {
    throw const FormatException('That amount is too large');
  }
}

BigInt _money(finance.Money m) {
  final v = BigInt.tryParse(m.amount);
  if (v == null) throw const FormatException('The loan amount is not known');
  return v;
}

BigInt _maxRepay(BigInt amount, sdk.PersonalTerms terms) {
  try {
    return sdk.maxRepayable(amount, terms);
  } on sdk.InvalidLoanTermsException {
    throw const FormatException(LoanTerms.unsignableTerms);
  }
}

BigInt _seconds(DateTime t) =>
    BigInt.from(t.toUtc().millisecondsSinceEpoch ~/ 1000);

wkt.Timestamp _timestamp(BigInt seconds) =>
    wkt.Timestamp(seconds: Int64(seconds.toInt()));

/// The GRANT_STANDING params for [loan]'s standing order (automatic payment
/// of each instalment). Only an active loan gets one.
settlement.AccountCallParams standingOrderParams(finance.Loan loan) {
  if (loan.state != finance.LoanState.LOAN_STATE_FUNDED) {
    throw const FormatException(
      'Automatic payment starts once the loan is active',
    );
  }
  final ref = _ref(loan);
  return settlement.AccountCallParams(
    pool: ref.pool,
    loanId: loan.onchainLoanId,
    loanBook: ref.loanBook,
  );
}

/// The REVOKE_STANDING params that stop [loan]'s standing order.
settlement.AccountCallParams standingRevokeParams(finance.Loan loan) {
  final ref = _ref(loan);
  return settlement.AccountCallParams(
    authorizationId: sdk.standingOrderId(ref.loanBook, ref.pool, ref.loanId),
  );
}
