import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../domain/stawi_money.dart';
import 'stawi_clients.dart';

/// The room's bound engines as stawi_finance_sdk checks an engine call
/// against them, from finance's live Room.engines; null when finance could not
/// read them (settlement unreachable), and then no engine call is signed.
RoomEngineTargets? engineTargetsOf(finance.Room room) {
  if (!room.hasEngines()) return null;
  final e = room.engines;
  return RoomEngineTargets(
    rulesEngine: e.rulesEngine.address,
    rulesCallable: e.rulesEngine.callable,
    loanBook: e.loanBook.address,
    loanCallable: e.loanBook.callable,
  );
}

/// Reads a room's engines.
typedef RoomEngineSource = Future<RoomEngineTargets?> Function(String roomId);

/// Reads a room's products (dues and loan forms) as its rules engines hold them.
typedef RoomProductSource = Future<finance.ListRoomProductsResponse> Function(
  String roomId,
);

final roomEngineSourceProvider = Provider<RoomEngineSource>((ref) {
  final rooms = ref.watch(financeRoomsProvider);
  return (roomId) async => engineTargetsOf(
    (await rooms.getRoom(finance.GetRoomRequest(roomId: roomId))).room,
  );
});

/// What a room's rotation runs on, from one GetRoom read of its engines: the
/// RotationModule binding (null when finance names none: the deployment has
/// no RotationModule, or the engines could not be read) and whether the
/// room's RulesEngine grant is ACTIVE (a rotation's contributions are its
/// dues, so a rotation needs it).
typedef RotationEngines = ({
  finance.RoomModuleBinding? module,
  bool rulesGranted,
});

/// Reads a room's [RotationEngines].
typedef RotationEnginesSource = Future<RotationEngines> Function(String roomId);

final rotationEnginesSourceProvider = Provider<RotationEnginesSource>((ref) {
  final rooms = ref.watch(financeRoomsProvider);
  return (roomId) async {
    final room = (await rooms.getRoom(finance.GetRoomRequest(roomId: roomId)))
        .room;
    final e = room.hasEngines() ? room.engines : null;
    return (
      module: e != null && e.hasRotationModule() ? e.rotationModule : null,
      rulesGranted: e != null && e.rulesEngine.grantActive,
    );
  };
});

/// The room's [RotationEngines], read fresh for each screen.
final rotationEnginesProvider = FutureProvider.autoDispose
    .family<RotationEngines, String>(
      (ref, roomId) => ref.watch(rotationEnginesSourceProvider)(roomId),
      retry: (_, _) => null,
    );

final roomProductSourceProvider = Provider<RoomProductSource>((ref) {
  final savings = ref.watch(financeSavingsProvider);
  return (roomId) =>
      savings.listRoomProducts(finance.ListRoomProductsRequest(roomId: roomId));
});

final roomEnginesProvider = FutureProvider.autoDispose
    .family<RoomEngineTargets?, String>(
      (ref, roomId) => ref.watch(roomEngineSourceProvider)(roomId),
    );

final roomProductsProvider = FutureProvider.autoDispose
    .family<finance.ListRoomProductsResponse, String>(
      (ref, roomId) => ref.watch(roomProductSourceProvider)(roomId),
    );

/// A product's name, or a stable short label when the product was voted
/// outside the templates and has none: "Product 0x1a2b3c4d".
String productLabel(String name, List<int> productId) {
  if (name.trim().isNotEmpty) return name.trim();
  final head = productId.take(4).toList();
  return head.isEmpty ? 'Product' : 'Product ${bytesToHex0x(head)}';
}

/// How a room's calendar names its periods in plain words: "months" for a
/// room of one-month periods, "periods" for anything less plain.
final class RoomCalendarLabel {
  const RoomCalendarLabel(this.singular, this.plural);

  factory RoomCalendarLabel.of(finance.RoomCalendar? c) {
    if (c == null || c.length != 1) return periods;
    return switch (c.unit) {
      finance.PeriodUnit.PERIOD_UNIT_DAY => const RoomCalendarLabel(
        'day',
        'days',
      ),
      finance.PeriodUnit.PERIOD_UNIT_WEEK => const RoomCalendarLabel(
        'week',
        'weeks',
      ),
      finance.PeriodUnit.PERIOD_UNIT_MONTH => const RoomCalendarLabel(
        'month',
        'months',
      ),
      _ => periods,
    };
  }

  static const RoomCalendarLabel periods = RoomCalendarLabel(
    'period',
    'periods',
  );

  final String singular;
  final String plural;

  /// "1 month", "12 months".
  String count(int n) => n == 1 ? '1 $singular' : '$n $plural';
}

BigInt _units(finance.Money m) => BigInt.tryParse(m.amount) ?? BigInt.zero;

/// A loan form's name as a person reads it: "normal" is "Normal loan",
/// "group_loan" "Group loan"; an unnamed form is named by its id.
String loanTypeName(finance.RoomLoanProduct p) {
  final words = p.name.trim().replaceAll('_', ' ');
  if (words.isEmpty) return productLabel('', p.productId);
  final named = words[0].toUpperCase() + words.substring(1);
  return named.toLowerCase().endsWith('loan') ? named : '$named loan';
}

/// A multiple in basis points as "3×" or "1.5×"; no floating point.
String _times(int bps) {
  final whole = bps ~/ 10000;
  final frac = (bps % 10000)
      .toString()
      .padLeft(4, '0')
      .replaceFirst(RegExp(r'0+$'), '');
  return frac.isEmpty ? '$whole×' : '$whole.$frac×';
}

/// A room's loan form in one plain sentence: what may be borrowed, over how
/// long, the interest and fee, who approves it and who may borrow, its
/// amounts in the [assets] they name and its periods as [cal] names them.
/// "Normal loan — borrow up to 3× your savings, at most 500.00 USDC; repay
/// over 1 to 12 months; 2% interest a month on what you still owe; fee 1%
/// taken from the payout; approved by 2 officers above 100.00 USDC; needs 1
/// guarantor."
String plainLoanType(
  finance.RoomLoanProduct p,
  StawiAssets assets,
  RoomCalendarLabel cal,
) {
  final parts = <String>[];

  final multiple = p.equityMultipleBps > 0
      ? 'up to ${_times(p.equityMultipleBps)} your savings'
      : null;
  final max = p.hasMaxAmount() && _units(p.maxAmount) > BigInt.zero
      ? formatMoney(p.maxAmount, assets)
      : null;
  if (multiple != null && max != null) {
    parts.add('borrow $multiple, at most $max');
  } else if (multiple != null) {
    parts.add('borrow $multiple');
  } else if (max != null) {
    parts.add('borrow up to $max');
  }

  if (p.maxInstalments > 0) {
    final per = p.periodsPerInstalment > 0 ? p.periodsPerInstalment : 1;
    final lo = (p.minInstalments > 0 ? p.minInstalments : 1) * per;
    final hi = p.maxInstalments * per;
    parts.add(
      lo >= hi
          ? 'repay over ${cal.count(hi)}'
          : 'repay over $lo to $hi ${cal.plural}',
    );
  }

  if (p.rateBps == 0) {
    parts.add('no interest');
  } else {
    final basis = switch (p.rateBasis) {
      finance.LoanRateBasis.LOAN_RATE_BASIS_PER_YEAR => ' a year',
      _ => ' a ${cal.singular}',
    };
    final how = switch (p.interestMethod) {
      finance.LoanInterestMethod.LOAN_INTEREST_METHOD_FLAT =>
        ' on the amount borrowed',
      finance
          .LoanInterestMethod
          .LOAN_INTEREST_METHOD_DECLINING_EQUAL_PRINCIPAL =>
        ' on what you still owe',
      finance.LoanInterestMethod.LOAN_INTEREST_METHOD_AMORTIZED =>
        ', equal instalments',
      finance.LoanInterestMethod.LOAN_INTEREST_METHOD_INTEREST_ONLY =>
        ', the amount borrowed repaid at the end',
      finance.LoanInterestMethod.LOAN_INTEREST_METHOD_BULLET =>
        ', all repaid at the end',
      _ => '',
    };
    parts.add('${formatBps(p.rateBps)} interest$basis$how');
  }

  final flat = p.hasFeeFlat() && _units(p.feeFlat) > BigInt.zero
      ? formatMoney(p.feeFlat, assets)
      : null;
  if (p.feeBps > 0 || flat != null) {
    final amount = [if (p.feeBps > 0) formatBps(p.feeBps), ?flat].join(' + ');
    final when = switch (p.feeTiming) {
      finance.LoanFeeTiming.LOAN_FEE_TIMING_DEDUCTED =>
        ' taken from the payout',
      finance.LoanFeeTiming.LOAN_FEE_TIMING_SPREAD =>
        ' spread over the instalments',
      finance.LoanFeeTiming.LOAN_FEE_TIMING_CAPITALIZED => ' added to the loan',
      finance.LoanFeeTiming.LOAN_FEE_TIMING_UPFRONT => ' paid before payout',
      _ => '',
    };
    parts.add('fee $amount$when');
  }

  final auto =
      p.hasAutoApproveBelow() && _units(p.autoApproveBelow) > BigInt.zero
      ? ' above ${formatMoney(p.autoApproveBelow, assets)}'
      : '';
  final n = p.officerApprovals;
  parts.add(
    n == 0
        ? 'decided by a room vote$auto'
        : 'approved by ${n == 1 ? '1 officer' : '$n officers'}$auto',
  );

  final g = p.minGuarantors;
  if (g > 0) parts.add('needs ${g == 1 ? '1 guarantor' : '$g guarantors'}');
  if (p.requireGoodStanding) {
    parts.add('only for members up to date with their dues');
  }
  return '${loanTypeName(p)} — ${parts.join('; ')}.';
}

/// Reads a room's protocol fee (GetRoom's Room.engines.protocol_fee); null
/// when finance names none (its engines could not be read).
typedef RoomProtocolFeeSource = Future<finance.RoomProtocolFee?> Function(
  String roomId,
);

final roomProtocolFeeSourceProvider = Provider<RoomProtocolFeeSource>((ref) {
  final rooms = ref.watch(financeRoomsProvider);
  return (roomId) async {
    final room = (await rooms.getRoom(finance.GetRoomRequest(roomId: roomId)))
        .room;
    return room.hasEngines() && room.engines.hasProtocolFee()
        ? room.engines.protocolFee
        : null;
  };
});

/// The Stawi fee on a room's income, and its agent's share; null when it
/// could not be read (shown so, never as no fee).
final roomProtocolFeeProvider = FutureProvider.autoDispose
    .family<finance.RoomProtocolFee?, String>(
      (ref, roomId) => ref.watch(roomProtocolFeeSourceProvider)(roomId),
    );

/// The key terms of a dues product, for its picker entry, its amounts in the
/// [assets] they name.
String duesProductTerms(finance.RoomDuesProduct p, StawiAssets assets) {
  final parts = <String>[
    if (p.hasAmount() && p.amount.amount.isNotEmpty)
      formatMoney(p.amount, assets),
    if (p.everyPeriods > 1) 'every ${p.everyPeriods} periods',
    if (p.everyPeriods == 1) 'every period',
    if (p.memberChoice)
      'you choose ${formatMoney(p.minAmount, assets)}–${formatMoney(p.maxAmount, assets)}'
    else
      'fixed by the room',
    if (!p.active) 'inactive',
  ];
  return parts.join(' · ');
}
