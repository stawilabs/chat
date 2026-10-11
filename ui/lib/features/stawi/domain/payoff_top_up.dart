import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' as sdk;

/// What a member must pay into the room before a loan payoff can go through.
///
/// A payoff spends the borrower's credit in the room, and a settle first takes
/// penalties and the dues it claims (in a room with share-out cycles, the rest
/// of the cycle in advance). Finance reads both from the chain
/// (RulesEngine.creditClaims): MemberBook.dues_payable, and
/// credit_available, the credit a payoff can spend once they are met. A payoff
/// of X goes through once max(0, X − credit_available) is paid in.
///
/// credit_available is not meaningful in a room whose rules sweep excess
/// credit into an excess product: there a settle moves what is left into that
/// product, so no top-up stays as credit for the payoff. Finance does not yet
/// say whether a room's rules name one (no template does), so the figure is
/// taken as it comes; the chain refuses a payoff the credit cannot cover.
class PayoffTopUp {
  const PayoffTopUp({
    required this.payoff,
    required this.creditAvailable,
    required this.duesPayable,
    required this.penaltiesOwed,
  });

  /// The most the payoff takes (settlement's quote, or the member's ceiling).
  final sdk.Amount payoff;

  /// Credit a payoff can spend now (MemberBook.credit_available).
  final sdk.Amount creditAvailable;

  /// Dues a settle takes from credit first (MemberBook.dues_payable).
  final BigInt duesPayable;

  /// Penalties a settle takes from credit first.
  final BigInt penaltiesOwed;

  /// What to pay in first; zero when the available credit covers the payoff.
  BigInt get topUp => sdk.payoffTopUp(payoff, creditAvailable).units;

  bool get needed => topUp > BigInt.zero;
}

/// The top-up for a payoff of at most [payoff] units of [asset], from the
/// signed-in member's live book in [balances]; null when it cannot be read
/// (finance could not reach the chain, the member has no book, or the book is
/// in another asset), and then nothing can be said about it.
PayoffTopUp? payoffTopUpFor({
  required BigInt payoff,
  required sdk.Asset asset,
  required finance.ListMemberBalancesResponse balances,
  required List<List<int>> myAccounts,
}) {
  if (!balances.booksAvailable) return null;
  final mine = balances.balances
      .where((b) => b.hasBook() && myAccounts.any((a) => _same(a, b.account)))
      .firstOrNull;
  if (mine == null) return null;
  final available = mine.book.creditAvailable;
  if (available.assetId.isNotEmpty && available.assetId != asset.id) {
    return null;
  }
  return PayoffTopUp(
    payoff: sdk.Amount(asset, payoff),
    creditAvailable: sdk.Amount(asset, _units(available)),
    duesPayable: _units(mine.book.duesPayable),
    penaltiesOwed: _units(mine.book.penaltiesOwed),
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
