import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../domain/signing_checks.dart' show bytesEqual;

/// How an open call settlement lists compares with a call asked for now.
enum OpenCallMatch {
  /// Another account, another kind, or a different target or amount.
  none,

  /// The same account and kind, and nothing settlement lists tells them
  /// apart (a transfer or contribution carries no target or amount on the
  /// listed call). Treated as possibly the same payment.
  sameKind,

  /// The same account, kind, target and amount: the payment asked for again.
  samePayment,
}

/// The payment-defining part of an account call: its account, kind and, for
/// an engine call, the engine and the exact calldata settlement prepared.
typedef IntendedCall = ({
  List<int> account,
  settlement.AccountCallKind kind,
  List<int> engineTarget,
  List<int> engineCalldata,
});

/// Compares [open], one of the account's open calls, with [intended].
///
/// An engine call is compared on what it pays and to whom: the engine, the
/// action, its room, pool, counterparty, loan, product and pockets, and the
/// value it commits. A payoff's value is settlement's quote, which moves as
/// interest accrues, so a payoff of the same loan is the same payment
/// whatever its amount. Calldata the SDK cannot read (a vault deposit's
/// transfer, say) is compared byte for byte. When the listed call says less
/// than that (no engine calldata) only its kind can match, which still
/// counts: an open call that cannot be told apart is not paid again.
OpenCallMatch matchOpenCall(
  settlement.AccountCall open,
  IntendedCall intended,
) {
  if (!bytesEqual(open.address, intended.account) ||
      open.kind != intended.kind) {
    return OpenCallMatch.none;
  }
  if (open.engineCalldata.isEmpty || intended.engineCalldata.isEmpty) {
    return OpenCallMatch.sameKind;
  }
  if (!bytesEqual(open.engineTarget, intended.engineTarget)) {
    return OpenCallMatch.none;
  }
  final path = _enginePath(intended.kind);
  final a = _decode(open.engineCalldata, path);
  final b = _decode(intended.engineCalldata, path);
  if (a == null || b == null) {
    return bytesEqual(open.engineCalldata, intended.engineCalldata)
        ? OpenCallMatch.samePayment
        : OpenCallMatch.sameKind;
  }
  final quoted =
      b.action == EngineAction.loanPayoff ||
      b.action == EngineAction.personalPayoff;
  final same =
      a.action == b.action &&
      bytesEqual(a.room, b.room) &&
      bytesEqual(a.pool, b.pool) &&
      bytesEqual(a.party, b.party) &&
      a.loanId == b.loanId &&
      bytesEqual(a.productId, b.productId) &&
      bytesEqual(a.pocket, b.pocket) &&
      bytesEqual(a.toPocket, b.toPocket) &&
      (quoted || a.committed == b.committed);
  return same ? OpenCallMatch.samePayment : OpenCallMatch.none;
}

/// The room kinds are 23 to 31, the personal ones 32 to 43
/// (settlement.v1 AccountCallKind).
EnginePath? _enginePath(settlement.AccountCallKind kind) =>
    switch (kind.value) {
      >= 23 && <= 31 => EnginePath.room,
      >= 32 && <= 43 => EnginePath.personal,
      _ => null,
    };

EngineCall? _decode(List<int> calldata, EnginePath? path) {
  if (path == null) return null;
  try {
    return EngineCall.decode(calldata, path: path);
  } on Object {
    return null;
  }
}
