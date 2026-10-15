import 'dart:typed_data';

import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' as sdk;

import 'stawi_money.dart';

/// The calls a member's own account makes on a room's engines: loans
/// (LoanBook) and withdrawals and amount choices (RulesEngine). Each is a
/// device-signed AccountService call settlement prepares as an ENGINE_CALL
/// intent, checked on the device with the SDK before it is signed.
enum AccountEngineCall {
  loanRequest(
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_REQUEST,
    sdk.EngineAction.loanRequest,
    'Request a loan',
  ),
  loanApprove(
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_APPROVE,
    sdk.EngineAction.loanApprove,
    'Approve the loan',
  ),
  loanPledge(
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_PLEDGE,
    sdk.EngineAction.loanPledge,
    'Pledge to the loan',
  ),
  loanUnpledge(
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_UNPLEDGE,
    sdk.EngineAction.loanUnpledge,
    'Withdraw my pledge',
  ),
  loanCancel(
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_CANCEL,
    sdk.EngineAction.loanCancel,
    'Cancel my loan request',
  ),
  loanPayoff(
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_PAYOFF,
    sdk.EngineAction.loanPayoff,
    'Pay off the loan',
  ),
  chooseAmount(
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_CHOOSE_AMOUNT,
    sdk.EngineAction.chooseAmount,
    'Choose my amount',
  ),
  withdrawCredit(
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_WITHDRAW_CREDIT,
    sdk.EngineAction.withdrawCredit,
    'Withdraw credit',
  ),
  withdrawEquity(
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_WITHDRAW_EQUITY,
    sdk.EngineAction.withdrawEquity,
    'Withdraw equity',
  );

  const AccountEngineCall(this.kind, this.action, this.label);

  final settlement.AccountCallKind kind;
  final sdk.EngineAction action;
  final String label;

  /// Whether the call names an existing loan.
  bool get takesLoan => switch (this) {
    loanApprove ||
    loanPledge ||
    loanUnpledge ||
    loanCancel ||
    loanPayoff => true,
    _ => false,
  };

  /// Whether the member states an amount. A payoff's is optional: without
  /// one, settlement quotes the ceiling (with headroom) and the member sees
  /// it before signing.
  bool get takesAmount => switch (this) {
    loanRequest ||
    loanPledge ||
    loanPayoff ||
    chooseAmount ||
    withdrawCredit ||
    withdrawEquity => true,
    _ => false,
  };

  bool get amountOptional => this == loanPayoff;

  /// Whether the call names a product (a loan form or a dues product).
  bool get takesProduct => this == loanRequest || this == chooseAmount;
}

final RegExp _positive = RegExp(r'^[1-9][0-9]{0,77}$');

/// One engine call a member asks for.
class AccountEngineRequest {
  AccountEngineRequest({
    required this.call,
    required this.custody,
    this.amount = '',
    this.loanId = 0,
    this.productId,
    this.instalments = 0,
    this.replaces = 0,
    this.asset,
  }) {
    if (custody.length != 20) {
      throw const FormatException('A room custody is a 20-byte address');
    }
    final needsAmount = call.takesAmount && !call.amountOptional;
    if ((needsAmount || amount.isNotEmpty) && !_positive.hasMatch(amount)) {
      throw const FormatException('Enter a whole amount greater than zero');
    }
    if (call.takesLoan && loanId <= 0) {
      throw const FormatException('Choose a loan');
    }
    if (call.takesProduct && (productId == null || productId!.length != 32)) {
      throw const FormatException('Name the loan form or product');
    }
    if (instalments < 0 || instalments > 65535) {
      throw const FormatException('Instalments are 0–65535');
    }
  }

  final AccountEngineCall call;

  /// The room's RoomCustody address.
  final Uint8List custody;

  /// Integer minor units; empty for a payoff settlement quotes.
  final String amount;

  /// The loan's number on the room's LoanBook.
  final int loanId;
  final Uint8List? productId;
  final int instalments;

  /// LOAN_REQUEST: the loan this one tops up (0 for none).
  final int replaces;

  /// The room's asset, to show [amount] in; null shows minor units.
  final StawiAsset? asset;

  /// What the member asked for, as the SDK compares it field for field with
  /// the prepared calldata (verifyEngineCallIntent `expected:`). A payoff
  /// with no amount asks for settlement's quote (amount zero).
  sdk.EngineCall get expected => sdk.EngineCall(
    action: call.action,
    room: custody,
    loanId: call.takesLoan ? BigInt.from(loanId) : null,
    productId: call.takesProduct ? productId : null,
    amount: amount.isEmpty ? BigInt.zero : BigInt.parse(amount),
    instalments: call == AccountEngineCall.loanRequest ? instalments : 0,
    replaces: call == AccountEngineCall.loanRequest
        ? BigInt.from(replaces)
        : null,
  );

  String get _shown => asset == null || amount.isEmpty
      ? amount
      : formatUnits(BigInt.parse(amount), asset!);

  String get summary => switch (call) {
    AccountEngineCall.loanRequest => 'Request a loan of $_shown',
    AccountEngineCall.withdrawCredit => 'Withdraw $_shown of credit',
    AccountEngineCall.withdrawEquity => 'Withdraw $_shown of equity',
    AccountEngineCall.loanPledge => 'Pledge $_shown to loan #$loanId',
    AccountEngineCall.loanPayoff => 'Pay off loan #$loanId',
    _ when call.takesLoan => '${call.label} #$loanId',
    _ => call.label,
  };
}
