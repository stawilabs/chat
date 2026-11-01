import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/socialtrader/domain/slippage.dart';

void main() {
  group('previewShares', () {
    test('uses nav and total shares', () {
      // 1000 quote of value, 800 shares: 1 share = 1.25 quote.
      expect(
        previewShares(assets: '250', nav: '1000', totalShares: '800'),
        '200',
      );
      expect(
        previewShares(assets: '1', nav: '3', totalShares: '1'),
        '0.333333333333333333',
      );
    });

    test('an empty pool mints one share per unit of quote', () {
      expect(previewShares(assets: '250', nav: '0', totalShares: '0'), '250');
      expect(previewShares(assets: '250', nav: '', totalShares: ''), '250');
    });

    test('a malformed or non-positive amount previews nothing', () {
      expect(previewShares(assets: 'x', nav: '1', totalShares: '1'), isNull);
      expect(previewShares(assets: '0', nav: '1', totalShares: '1'), isNull);
      expect(previewShares(assets: '-1', nav: '1', totalShares: '1'), isNull);
    });
  });

  group('minimumWithSlippage', () {
    test('takes one percent off', () {
      expect(minimumWithSlippage('200'), '198');
      expect(minimumWithSlippage('12.87'), '12.7413');
      expect(minimumWithSlippage('1', bps: 50), '0.995');
    });

    test('no value means no floor', () {
      expect(minimumWithSlippage(''), '');
      expect(minimumWithSlippage('0'), '');
      expect(minimumWithSlippage('nope'), '');
    });
  });
}
