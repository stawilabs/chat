import 'package:stawi_api/finance_v1.dart' as finance;

/// What a member must pay into the room before a loan payoff can go through.
///
/// A payoff spends the borrower's credit in the room, and new money is first
/// applied to dues: in a room with share-out cycles the rules engine takes the
/// rest of the cycle's dues in advance (DuesMath.payableAt) before anything is
/// left as credit. A borrower who has not prepaid the cycle therefore needs
/// the remaining dues on top of the payoff, or the chain refuses the payoff.
class PayoffTopUp {
  const PayoffTopUp({
    required this.payoff,
    required this.credit,
    required this.remainingDues,
  });

  /// The most the payoff takes (settlement's quote, or the member's ceiling).
  final BigInt payoff;

  /// The member's unallocated credit in the room now.
  final BigInt credit;

  /// The dues new money pays before the loan: what is owed now and, in a room
  /// with share-out cycles, the rest of the current cycle.
  final BigInt remainingDues;

  /// What to pay in first; zero when the credit already covers both.
  BigInt get topUp {
    final short = remainingDues + payoff - credit;
    return short > BigInt.zero ? short : BigInt.zero;
  }

  bool get needed => topUp > BigInt.zero;
}

/// The dues a member's new money pays before a loan: [duesOwed] (owed now,
/// from the member's book) plus, when the room shares out by cycle, every
/// due of its products from the current period to the cycle's last.
///
/// The current period is counted even when part of it may already be in
/// [duesOwed], and a member-chosen amount is taken at the product's default:
/// the estimate errs high, and any excess stays the member's credit.
BigInt remainingCycleDues({
  required finance.ListRoomProductsResponse products,
  required BigInt duesOwed,
}) {
  if (!products.rulesConfigured || !products.hasCalendar()) return duesOwed;
  final perCycle = products.calendar.periodsPerCycle;
  if (perCycle <= 0) return duesOwed;
  final current = products.calendar.currentPeriod;
  final cycleEnd = (current ~/ perCycle + 1) * perCycle - 1;
  var total = duesOwed;
  for (final p in products.duesProducts) {
    if (!p.active || !p.hasAmount()) continue;
    final amount = BigInt.tryParse(p.amount.amount) ?? BigInt.zero;
    if (amount <= BigInt.zero) continue;
    total += amount * BigInt.from(_duesIn(p, current, cycleEnd));
  }
  return total;
}

/// Due periods of [p] in [from, to] (DuesMath.countDue from its first period).
int _duesIn(finance.RoomDuesProduct p, int from, int to) {
  final first = p.firstPeriod;
  final last = p.lastPeriod == 0 ? to : (p.lastPeriod < to ? p.lastPeriod : to);
  final a = from > first ? from : first;
  if (last < a) return 0;
  if (p.everyPeriods == 0) return a == first ? 1 : 0;
  final every = p.everyPeriods;
  final start = first + ((a - first) + every - 1) ~/ every * every;
  if (start > last) return 0;
  return (last - start) ~/ every + 1;
}

/// The top-up for a payoff of at most [payoff], from the room's member
/// [balances] and [products]; null when the member's live book cannot be
/// read (finance could not reach the chain, or the member has none), and
/// then nothing can be said about it.
PayoffTopUp? payoffTopUpFor({
  required BigInt payoff,
  required finance.ListMemberBalancesResponse balances,
  required finance.ListRoomProductsResponse products,
  required List<List<int>> myAccounts,
}) {
  if (!balances.booksAvailable) return null;
  final mine = balances.balances
      .where((b) => b.hasBook() && myAccounts.any((a) => _same(a, b.account)))
      .firstOrNull;
  if (mine == null) return null;
  return PayoffTopUp(
    payoff: payoff,
    credit: _units(mine.book.credit),
    remainingDues: remainingCycleDues(
      products: products,
      duesOwed: _units(mine.book.duesOwed),
    ),
  );
}

BigInt _units(finance.Money money) =>
    BigInt.tryParse(money.amount.isEmpty ? '0' : money.amount) ?? BigInt.zero;

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length || a.isEmpty) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
