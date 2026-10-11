import 'dart:typed_data';

/// The calls a member's own account makes to a room's engines: loans and
/// withdrawals. Each is a device-signed AccountService call, like CONTRIBUTE.
// TODO(stawilabs): stawi branch feat/account-engine-calls. settlement.v1 adds these
// as AccountCallKind 23–31, with AccountCallParams.loan_id (12),
// product_id (13), instalments (14) and replaces (15), in stawi_api 0.3.0.
// Until the app is on 0.3.0, AccountCallKind.valueOf(code) is null for them
// and StawiAccountService.engineCall refuses with a clear message. The
// follow-up is: bump stawi_api, and set the four params in
// StawiAccountService.engineCall where its TODO says.
enum AccountEngineCall {
  loanRequest(23, 'Request a loan'),
  loanApprove(24, 'Approve a loan'),
  loanPledge(25, 'Pledge to a loan'),
  loanUnpledge(26, 'Withdraw a pledge'),
  loanCancel(27, 'Cancel a loan request'),
  loanPayoff(28, 'Pay off a loan'),
  chooseAmount(29, 'Choose an amount'),
  withdrawCredit(30, 'Withdraw credit'),
  withdrawEquity(31, 'Withdraw equity');

  const AccountEngineCall(this.code, this.label);

  /// settlement.v1 AccountCallKind number.
  final int code;
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

  /// Whether the call moves an amount.
  bool get takesAmount => switch (this) {
    loanRequest ||
    loanPledge ||
    loanPayoff ||
    chooseAmount ||
    withdrawCredit ||
    withdrawEquity => true,
    _ => false,
  };
}

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
  }) {
    if (custody.length != 20) {
      throw const FormatException('A room custody is a 20-byte address');
    }
    if (call.takesAmount && !RegExp(r'^[1-9][0-9]{0,77}$').hasMatch(amount)) {
      throw const FormatException('Enter a whole amount greater than zero');
    }
    if (call.takesLoan && loanId <= 0) {
      throw const FormatException('Enter the loan number');
    }
    if (productId != null && productId!.length != 32) {
      throw const FormatException('A loan product id is 32 bytes');
    }
    if (instalments < 0 || instalments > 65535) {
      throw const FormatException('Instalments are 0–65535');
    }
  }

  final AccountEngineCall call;

  /// The room's RoomCustody address.
  final Uint8List custody;

  /// Integer minor units of the room's asset.
  final String amount;

  /// The on-chain loan id.
  final int loanId;

  /// LOAN_REQUEST: the constitution's loan product.
  final Uint8List? productId;
  final int instalments;

  /// LOAN_REQUEST: the loan this one refinances.
  final int replaces;

  String get summary => switch (call) {
    AccountEngineCall.loanRequest => 'Request a loan of $amount',
    AccountEngineCall.withdrawCredit => 'Withdraw $amount of credit',
    AccountEngineCall.withdrawEquity => 'Withdraw $amount of equity',
    AccountEngineCall.loanPledge => 'Pledge $amount to loan #$loanId',
    AccountEngineCall.loanPayoff => 'Pay off loan #$loanId',
    _ when call.takesLoan => '${call.label} #$loanId',
    _ => call.label,
  };
}
