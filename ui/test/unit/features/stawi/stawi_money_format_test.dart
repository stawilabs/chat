import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:stawi/features/stawi/data/stawi_finance_service.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/data/stawi_room_engines.dart';
import 'package:stawi/features/stawi/domain/stawi_money.dart';
import 'package:stawi_api/finance_v1.dart' as finance;

import '../../../support/stawi_fakes.dart';

finance.Money usdcMoney(String units) =>
    finance.Money(assetId: 'USDC.146', amount: units);

void main() {
  setUpAll(initializeDateFormatting);

  group('amounts from minor units', () {
    test('USDC has 6 decimals and shows its symbol', () {
      expect(usdc.symbol, 'USDC');
      expect(usdc.decimals, 6);
      expect(formatMoney(usdcMoney('900000000'), usdcAssets), '900.00 USDC');
      expect(formatMoney(usdcMoney('1234560000'), usdcAssets), '1,234.56 USDC');
      expect(formatMoney(usdcMoney('1234567'), usdcAssets), '1.234567 USDC');
      expect(formatMoney(usdcMoney('500000'), usdcAssets), '0.50 USDC');
      expect(formatMoney(usdcMoney('1'), usdcAssets), '0.000001 USDC');
      expect(formatMoney(usdcMoney(''), usdcAssets), '—');
      expect(formatUnits(BigInt.from(-2500000), usdc), '-2.50 USDC');
    });

    test('is localized', () {
      expect(
        formatMoney(usdcMoney('1234560000'), usdcAssets, locale: 'de'),
        '1.234,56 USDC',
      );
    });

    test('an asset finance does not describe shows whole minor units', () {
      expect(
        formatMoney(
          finance.Money(assetId: 'XYZ.146', amount: '1234567'),
          usdcAssets,
        ),
        '1,234,567 XYZ.146',
      );
      expect(
        formatMoney(usdcMoney('1234567'), StawiAssets.empty),
        '1,234,567 USDC.146',
      );
    });

    test('takes symbol and decimals from the asset details', () {
      final assets = usdcAssets.withAll([
        finance.AssetInfo(assetId: 'KES.1', symbol: 'KES', decimals: 2),
      ]);
      expect(
        formatMoney(finance.Money(assetId: 'KES.1', amount: '12345'), assets),
        '123.45 KES',
      );
      expect(formatMoney(usdcMoney('500000'), assets), '0.50 USDC');
      expect(
        StawiAsset.fromInfo(
          finance.AssetInfo(assetId: 'ODD.1', symbol: 'ODD', decimals: 300),
        ).known,
        isFalse,
      );
    });

    test('typed amounts become minor units', () {
      expect(parseAmountInput('900', usdc), '900000000');
      expect(parseAmountInput('12.5', usdc), '12500000');
      expect(parseAmountInput('1,234.56', usdc), '1234560000');
      expect(() => parseAmountInput('0.0000001', usdc), throwsFormatException);
      expect(() => parseAmountInput('0', usdc), throwsFormatException);
      expect(() => parseAmountInput('abc', usdc), throwsFormatException);
    });
  });

  group('rates', () {
    test('basis points as percent', () {
      expect(formatBps(300), '3%');
      expect(formatBps(250), '2.5%');
      expect(formatBps(5), '0.05%');
      expect(formatBps(10000), '100%');
    });

    test('with their basis', () {
      expect(
        formatRate(300, finance.LoanRateBasis.LOAN_RATE_BASIS_PER_PERIOD),
        '3% per period',
      );
      expect(
        formatRate(1200, finance.LoanRateBasis.LOAN_RATE_BASIS_PER_YEAR),
        '12% a year',
      );
    });
  });

  test('the loan picker label', () {
    expect(
      plainLoanType(
        finance.RoomLoanProduct(
          maxAmount: usdcMoney('900000000'),
          rateBps: 300,
          rateBasis: finance.LoanRateBasis.LOAN_RATE_BASIS_PER_PERIOD,
          minInstalments: 1,
          maxInstalments: 6,
          feeBps: 50,
          officerApprovals: 1,
        ),
        usdcAssets,
        RoomCalendarLabel.periods,
      ),
      'Product — borrow up to 900.00 USDC; repay over 1 to 6 periods; 3% '
      'interest a period; fee 0.5%; approved by 1 officer.',
    );
  });

  test('the room asset is its savings bucket asset', () async {
    final transport = FakeConnectTransport()
      ..on(
        finance.RoomService.getPolicy,
        (req) => finance.GetPolicyResponse(
          policyVersion: finance.PolicyVersion(
            constitution: finance.RoomPolicy(
              treasury: finance.Treasury(
                buckets: [
                  finance.Bucket(
                    name: 'ops_sponsorship',
                    assetIds: ['EURC.146'],
                  ),
                  finance.Bucket(name: 'savings', assetIds: ['USDC.146']),
                ],
              ),
            ),
          ),
        ),
      )
      ..on(
        finance.RoomService.getRoom,
        (req) => finance.GetRoomResponse(
          room: finance.Room(roomId: req.roomId, assets: [usdcInfo]),
        ),
      );
    final asset = await StawiFinanceService(
      rooms: finance.RoomServiceClient(transport),
      treasury: finance.TreasuryServiceClient(transport),
      governance: finance.GovernanceServiceClient(transport),
      identity: () async => const StawiIdentity(profileId: 'p1', accounts: []),
    ).roomAsset('room00000000000000aa');
    expect(asset!.id, 'USDC.146');
    expect(asset.symbol, 'USDC');
    expect(asset.decimals, 6);
  });
}
