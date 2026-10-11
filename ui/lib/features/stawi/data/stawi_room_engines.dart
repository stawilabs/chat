import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

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
    loanEngine: e.loanEngine.address,
    loanCallable: e.loanEngine.callable,
  );
}

/// Reads a room's engines.
typedef RoomEngineSource = Future<RoomEngineTargets?> Function(String roomId);

/// Reads a room's products (dues and loan forms) as its rules engines hold them.
typedef RoomProductSource =
    Future<finance.ListRoomProductsResponse> Function(String roomId);

final roomEngineSourceProvider = Provider<RoomEngineSource>((ref) {
  final rooms = ref.watch(financeRoomsProvider);
  return (roomId) async => engineTargetsOf(
    (await rooms.getRoom(finance.GetRoomRequest(roomId: roomId))).room,
  );
});

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

String _money(finance.Money m) => m.amount.isEmpty
    ? '0'
    : '${m.amount}${m.assetId.isEmpty ? '' : ' ${m.assetId}'}';

String _bps(int bps) {
  final whole = bps ~/ 100;
  final frac = bps % 100;
  return frac == 0 ? '$whole%' : '$whole.${frac.toString().padLeft(2, '0')}%';
}

String _basis(finance.LoanRateBasis b) => switch (b) {
  finance.LoanRateBasis.LOAN_RATE_BASIS_PER_PERIOD => ' per period',
  finance.LoanRateBasis.LOAN_RATE_BASIS_PER_YEAR => ' a year',
  _ => '',
};

/// The key terms of a loan form, for its picker entry.
String loanProductTerms(finance.RoomLoanProduct p) {
  final parts = <String>[
    if (p.hasMaxAmount() && p.maxAmount.amount.isNotEmpty)
      'up to ${_money(p.maxAmount)}',
    if (p.rateBps > 0) '${_bps(p.rateBps)}${_basis(p.rateBasis)}',
    if (p.rateBps == 0) 'no interest',
    if (p.maxInstalments > 0)
      p.minInstalments == p.maxInstalments
          ? '${p.maxInstalments} instalments'
          : '${p.minInstalments}–${p.maxInstalments} instalments',
    if (p.feeBps > 0) 'fee ${_bps(p.feeBps)}',
    if (p.minGuarantors > 0) '${p.minGuarantors} guarantors',
  ];
  return parts.join(' · ');
}

/// The key terms of a dues product, for its picker entry.
String duesProductTerms(finance.RoomDuesProduct p) {
  final parts = <String>[
    if (p.hasAmount() && p.amount.amount.isNotEmpty) _money(p.amount),
    if (p.everyPeriods > 1) 'every ${p.everyPeriods} periods',
    if (p.everyPeriods == 1) 'every period',
    if (p.memberChoice)
      'you choose ${_money(p.minAmount)}–${_money(p.maxAmount)}'
    else
      'fixed by the room',
    if (!p.active) 'inactive',
  ];
  return parts.join(' · ');
}
