import 'package:stawi_api/finance_v1.dart' as finance;

import 'stawi_money.dart' show formatBps;

/// What a withdrawal's review says about its fee, from finance's quote
/// (TreasuryService.QuoteWithdrawal): a fee line exactly when a fee applies,
/// with what arrives when the fee comes out of the amount; otherwise the
/// quote's own reason there is none ("Group withdrawals carry no fee").
/// Without a quote nothing is said about a fee either way. [money] formats
/// an amount in the withdrawal's asset.
({List<(String, String)> lines, List<String> notes}) withdrawalFeeReview(
  finance.QuoteWithdrawalResponse? quote,
  String Function(finance.Money) money,
) {
  if (quote == null) return (lines: const [], notes: const []);
  final basis = quote.basis.trim();
  if (!quote.feeApplies) {
    return (
      lines: const [],
      notes: [if (basis.isEmpty) 'No withdrawal fee applies' else basis],
    );
  }
  final fee = money(quote.fee);
  final rate = quote.withdrawalFeeBps > 0
      ? ' (${formatBps(quote.withdrawalFeeBps)})'
      : '';
  return (
    lines: [
      ('Withdrawal fee', '$fee$rate'),
      if (quote.chargedFrom == 'amount') ('You receive', money(quote.net)),
    ],
    notes: [
      if (quote.chargedFrom == 'room_ops_bucket') feeFromOpsBucketNote,
      if (basis.isNotEmpty) basis,
    ],
  );
}

/// Said when the fee comes out of the room's operations bucket.
const String feeFromOpsBucketNote =
    'The fee is taken from the room\'s operations bucket, not from what you '
    'receive.';
