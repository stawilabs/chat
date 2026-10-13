import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/stawi_room_engines.dart';
import 'package:stawi/features/stawi/domain/dues_calendar.dart';
import 'package:stawi/features/stawi/ui/protocol_fee_line.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/well_known.dart' as wkt;

import '../../../support/stawi_fakes.dart';

finance.Money usd(String units) =>
    finance.Money(assetId: 'USDC.146', amount: units);

final monthly = finance.RoomCalendar(
  unit: finance.PeriodUnit.PERIOD_UNIT_MONTH,
  length: 1,
);

/// The ASCA template's "normal" loan for a 100 USDC monthly contribution
/// (pkg/rules/templates.go), with the room's interest declining.
finance.RoomLoanProduct normal({
  finance.LoanInterestMethod method =
      finance.LoanInterestMethod.LOAN_INTEREST_METHOD_DECLINING_EQUAL_PRINCIPAL,
}) => finance.RoomLoanProduct(
  name: 'normal',
  productId: Uint8List(32),
  minAmount: usd('1000000'),
  maxAmount: usd('500000000'),
  equityMultipleBps: 30000,
  minInstalments: 1,
  maxInstalments: 12,
  periodsPerInstalment: 1,
  interestMethod: method,
  rateBps: 200,
  rateBasis: finance.LoanRateBasis.LOAN_RATE_BASIS_PER_PERIOD,
  feeBps: 100,
  feeTiming: finance.LoanFeeTiming.LOAN_FEE_TIMING_DEDUCTED,
  autoApproveBelow: usd('100000000'),
  officerApprovals: 2,
  minGuarantors: 1,
);

void main() {
  group('plainLoanType', () {
    test('a template "normal" loan in one sentence', () {
      expect(
        plainLoanType(normal(), usdcAssets, RoomCalendarLabel.of(monthly)),
        'Normal loan — borrow up to 3× your savings, at most 500.00 USDC; '
        'repay over 1 to 12 months; 2% interest a month on what you still '
        'owe; fee 1% taken from the payout; approved by 2 officers above '
        '100.00 USDC; needs 1 guarantor.',
      );
    });

    test('a loan decided by a room vote, flat, for members in good standing', () {
      final p = finance.RoomLoanProduct(
        name: 'group_loan',
        productId: Uint8List(32),
        maxAmount: usd('900000000'),
        minInstalments: 3,
        maxInstalments: 3,
        periodsPerInstalment: 2,
        interestMethod: finance.LoanInterestMethod.LOAN_INTEREST_METHOD_FLAT,
        rateBps: 1250,
        rateBasis: finance.LoanRateBasis.LOAN_RATE_BASIS_PER_YEAR,
        feeFlat: usd('5000000'),
        feeTiming: finance.LoanFeeTiming.LOAN_FEE_TIMING_SPREAD,
        requireGoodStanding: true,
      );
      expect(
        plainLoanType(
          p,
          usdcAssets,
          RoomCalendarLabel.of(
            finance.RoomCalendar(
              unit: finance.PeriodUnit.PERIOD_UNIT_WEEK,
              length: 1,
            ),
          ),
        ),
        'Group loan — borrow up to 900.00 USDC; repay over 6 weeks; 12.5% '
        'interest a year on the amount borrowed; fee 5.00 USDC spread over '
        'the instalments; decided by a room vote; only for members up to date '
        'with their dues.',
      );
    });

    test('says how each fee timing and interest method works', () {
      String with_(finance.LoanFeeTiming t) => plainLoanType(
        normal()..feeTiming = t,
        usdcAssets,
        RoomCalendarLabel.periods,
      );
      expect(
        with_(finance.LoanFeeTiming.LOAN_FEE_TIMING_DEDUCTED),
        contains('fee 1% taken from the payout'),
      );
      expect(
        with_(finance.LoanFeeTiming.LOAN_FEE_TIMING_CAPITALIZED),
        contains('fee 1% added to the loan'),
      );
      expect(
        with_(finance.LoanFeeTiming.LOAN_FEE_TIMING_UPFRONT),
        contains('fee 1% paid before payout'),
      );
      expect(
        plainLoanType(
          normal(
            method: finance.LoanInterestMethod.LOAN_INTEREST_METHOD_AMORTIZED,
          ),
          usdcAssets,
          RoomCalendarLabel.periods,
        ),
        contains('2% interest a period, equal instalments'),
      );
      expect(
        plainLoanType(
          normal()..officerApprovals = 1,
          usdcAssets,
          RoomCalendarLabel.periods,
        ),
        contains('approved by 1 officer above 100.00 USDC'),
      );
    });

    test('names an unnamed form by its id', () {
      final p = finance.RoomLoanProduct(
        productId: Uint8List.fromList([0xab, 0xcd, 0xef, 0x01, 0x23]),
      );
      expect(
        plainLoanType(p, usdcAssets, RoomCalendarLabel.periods),
        startsWith('Product 0xabcdef01 — no interest'),
      );
    });
  });

  group('the Stawi fee line', () {
    test('states the share of the room income', () {
      expect(
        protocolFeeText(finance.RoomProtocolFee(incomeFeeBps: 1000)),
        'Stawi fee 10% of interest, fees and penalties',
      );
      expect(
        protocolFeeText(finance.RoomProtocolFee(incomeFeeBps: 250)),
        'Stawi fee 2.5% of interest, fees and penalties',
      );
    });

    test("adds the agent's share of the income", () {
      expect(
        protocolFeeText(
          finance.RoomProtocolFee(
            incomeFeeBps: 1000,
            agentShareBps: 3000,
            agent: List.filled(20, 7),
          ),
          agentName: 'Amina',
        ),
        'Stawi fee 10% of interest, fees and penalties · 3% to Amina',
      );
      expect(
        protocolFeeText(
          finance.RoomProtocolFee(
            incomeFeeBps: 1000,
            agentShareBps: 3333,
            agent: List.filled(20, 7),
          ),
        ),
        "Stawi fee 10% of interest, fees and penalties · 3.333% to the room's "
        'agent',
      );
    });

    test('a fee that could not be read is never shown as none', () {
      expect(protocolFeeText(null), 'Stawi fee: could not be read just now');
    });
  });

  group('the next dues date', () {
    DateTime at(int y, int m, int d) => DateTime.utc(y, m, d);
    wkt.Timestamp ts(DateTime t) =>
        wkt.Timestamp(seconds: Int64(t.millisecondsSinceEpoch ~/ 1000));

    finance.RoomDuesProduct dues({
      int every = 1,
      int first = 0,
      int last = 0,
      int offset = 0,
      bool active = true,
    }) => finance.RoomDuesProduct(
      everyPeriods: every,
      firstPeriod: first,
      lastPeriod: last,
      dueOffsetSeconds: offset,
      active: active,
    );

    finance.ListRoomProductsResponse room(
      finance.RoomCalendar c,
      List<finance.RoomDuesProduct> products,
    ) => finance.ListRoomProductsResponse(
      rulesConfigured: true,
      calendar: c,
      duesProducts: products,
    );

    test('monthly periods keep the anchor day, clamped to short months', () {
      final c = finance.RoomCalendar(
        unit: finance.PeriodUnit.PERIOD_UNIT_MONTH,
        length: 1,
        anchor: ts(at(2026, 1, 31)),
      );
      expect(periodStart(c, 1), at(2026, 2, 28).millisecondsSinceEpoch ~/ 1000);
      expect(periodStart(c, 2), at(2026, 3, 31).millisecondsSinceEpoch ~/ 1000);
      expect(
        periodStart(c, 13),
        at(2027, 2, 28).millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('the next due after now, with the due offset', () {
      final c = finance.RoomCalendar(
        unit: finance.PeriodUnit.PERIOD_UNIT_MONTH,
        length: 1,
        anchor: ts(at(2026, 1, 1)),
        currentPeriod: 9,
      );
      // Period 9 is October; its due (5 days in) has passed on the 13th.
      expect(
        nextDuesDate(room(c, [dues(offset: 5 * 86400)]), at(2026, 10, 13)),
        at(2026, 11, 6),
      );
      expect(
        nextDuesDate(room(c, [dues(offset: 20 * 86400)]), at(2026, 10, 13)),
        at(2026, 10, 21),
      );
    });

    test('every other period, the earliest product, ended products', () {
      final c = finance.RoomCalendar(
        unit: finance.PeriodUnit.PERIOD_UNIT_WEEK,
        length: 1,
        anchor: ts(at(2026, 10, 5)),
        currentPeriod: 1,
      );
      final now = at(2026, 10, 13);
      // Due in even weeks from week 0: week 2 begins on 19 October.
      expect(nextDuesDate(room(c, [dues(every: 2)]), now), at(2026, 10, 19));
      expect(
        nextDuesDate(room(c, [dues(every: 2), dues(first: 3)]), now),
        at(2026, 10, 19),
      );
      expect(nextDuesDate(room(c, [dues(last: 1)]), now), isNull);
      expect(nextDuesDate(room(c, [dues(active: false)]), now), isNull);
      expect(
        nextDuesDate(
          finance.ListRoomProductsResponse(rulesConfigured: false),
          now,
        ),
        isNull,
      );
    });
  });
}
