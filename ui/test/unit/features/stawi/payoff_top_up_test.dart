import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/domain/payoff_top_up.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' as sdk;

finance.Money usdc(int units) =>
    finance.Money(assetId: 'USDC.146', amount: '$units');

const asset = sdk.Asset('USDC.146', 6);

void main() {
  group('payoff top-up', () {
    final mine = List<int>.filled(20, 0xaa);
    finance.ListMemberBalancesResponse balances({
      bool available = true,
      finance.Money? creditAvailable,
    }) => finance.ListMemberBalancesResponse(
      booksAvailable: available,
      balances: [
        finance.MemberBalance(
          account: List<int>.filled(20, 0xbb),
          book: finance.MemberBook(creditAvailable: usdc(999999999)),
        ),
        finance.MemberBalance(
          account: mine,
          book: finance.MemberBook(
            credit: usdc(240),
            duesPayable: usdc(220),
            penaltiesOwed: usdc(10),
            creditAvailable: creditAvailable ?? usdc(10),
          ),
        ),
      ],
    );

    test('is what the available credit lacks for the payoff', () {
      final t = payoffTopUpFor(
        payoff: BigInt.from(500),
        asset: asset,
        balances: balances(),
        myAccounts: [mine],
      )!;
      expect(t.creditAvailable.units, BigInt.from(10));
      expect(t.duesPayable, BigInt.from(220));
      expect(t.penaltiesOwed, BigInt.from(10));
      expect(t.topUp, BigInt.from(490));
      expect(t.needed, isTrue);
    });

    test('is nothing when the available credit covers the payoff', () {
      final t = payoffTopUpFor(
        payoff: BigInt.from(500),
        asset: asset,
        balances: balances(creditAvailable: usdc(600)),
        myAccounts: [mine],
      )!;
      expect(t.topUp, BigInt.zero);
      expect(t.needed, isFalse);
    });

    test('is unknown without the member\'s live book in the asset', () {
      expect(
        payoffTopUpFor(
          payoff: BigInt.one,
          asset: asset,
          balances: balances(available: false),
          myAccounts: [mine],
        ),
        isNull,
      );
      expect(
        payoffTopUpFor(
          payoff: BigInt.one,
          asset: asset,
          balances: balances(),
          myAccounts: [List<int>.filled(20, 0xcc)],
        ),
        isNull,
      );
      expect(
        payoffTopUpFor(
          payoff: BigInt.one,
          asset: asset,
          balances: balances(
            creditAvailable: finance.Money(assetId: 'EURC.146', amount: '5'),
          ),
          myAccounts: [mine],
        ),
        isNull,
      );
    });
  });
}
