import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' as sdk;

/// What a member must pay into the room before a loan payoff can go through.
///
/// A payoff spends the borrower's credit in the room, and a settle first takes
/// penalties and the dues it claims (in a room with share-out cycles, the rest
/// of the cycle in advance) out of that credit. Finance reads all three from
/// the chain (RulesEngine.creditClaims): MemberBook.credit, penalties_owed and
/// dues_payable. A payoff of X goes through once
/// max(0, X + penalties_owed + dues_payable − credit) is paid in
/// (stawi_finance_sdk payoffTopUp, Go rules.CreditClaims.TopUp).
/// MemberBook.credit_available floors at zero, so X − credit_available
/// understates the top-up whenever the claims exceed the credit.
///
/// The figure is not meaningful in a room whose rules sweep excess credit
/// into an excess product: there a settle moves what is left into that
/// product, so no top-up stays as credit for the payoff. Finance does not yet
/// say whether a room's rules name one (no template does), so the figure is
/// taken as it comes; the chain refuses a payoff the credit cannot cover.
class PayoffTopUp {
  const PayoffTopUp({
    required this.payoff,
    required this.credit,
    required this.duesPayable,
    required this.penaltiesOwed,
  });

  /// The most the payoff takes (settlement's quote, or the member's ceiling).
  final sdk.Amount payoff;

  /// The member's credit in the room (MemberBook.credit).
  final sdk.Amount credit;

  /// Dues a settle takes from credit first (MemberBook.dues_payable).
  final sdk.Amount duesPayable;

  /// Penalties a settle takes from credit first (MemberBook.penalties_owed).
  final sdk.Amount penaltiesOwed;

  /// What to pay in first; zero when the credit covers the payoff and the
  /// penalties and dues a settle takes first.
  BigInt get topUp => sdk
      .payoffTopUp(
        payoff,
        credit: credit,
        penaltiesOwed: penaltiesOwed,
        duesPayable: duesPayable,
      )
      .units;

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
  final book = mine.book;
  final figures = [book.credit, book.penaltiesOwed, book.duesPayable];
  if (figures.any((m) => m.assetId.isNotEmpty && m.assetId != asset.id)) {
    return null;
  }
  return PayoffTopUp(
    payoff: sdk.Amount(asset, payoff),
    credit: sdk.Amount(asset, _units(book.credit)),
    penaltiesOwed: sdk.Amount(asset, _units(book.penaltiesOwed)),
    duesPayable: sdk.Amount(asset, _units(book.duesPayable)),
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
