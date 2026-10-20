import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/domain/withdrawal_fee.dart';
import 'package:stawi_api/finance_v1.dart' as finance;

void main() {
  String money(finance.Money m) => '${m.amount} u';

  test('a fee line exactly when a fee applies, with what arrives', () {
    final review = withdrawalFeeReview(
      finance.QuoteWithdrawalResponse(
        feeApplies: true,
        withdrawalFeeBps: 25,
        fee: finance.Money(amount: '25'),
        net: finance.Money(amount: '9975'),
        chargedFrom: 'amount',
        basis: 'The wallet cash-out rate',
      ),
      money,
    );
    expect(review.lines, [
      ('Withdrawal fee', '25 u (0.25%)'),
      ('You receive', '9975 u'),
    ]);
    expect(review.notes, ['The wallet cash-out rate']);
  });

  test('a fee from the room\'s operations bucket leaves the amount whole', () {
    final review = withdrawalFeeReview(
      finance.QuoteWithdrawalResponse(
        feeApplies: true,
        withdrawalFeeBps: 25,
        fee: finance.Money(amount: '25'),
        net: finance.Money(amount: '10000'),
        chargedFrom: 'room_ops_bucket',
      ),
      money,
    );
    expect(review.lines, [('Withdrawal fee', '25 u (0.25%)')]);
    expect(review.notes, [feeFromOpsBucketNote]);
  });

  test('a fee-free withdrawal shows no fee line and says why', () {
    final review = withdrawalFeeReview(
      finance.QuoteWithdrawalResponse(
        kind: finance.WithdrawalKind.WITHDRAWAL_KIND_MEMBER_CREDIT,
        net: finance.Money(amount: '10000'),
        basis: 'Group withdrawals carry no fee',
      ),
      money,
    );
    expect(review.lines, isEmpty);
    expect(review.notes, ['Group withdrawals carry no fee']);
  });

  test('without a quote nothing is said about a fee', () {
    final review = withdrawalFeeReview(null, money);
    expect(review.lines, isEmpty);
    expect(review.notes, isEmpty);
  });
}
