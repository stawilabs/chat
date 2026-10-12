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
      finance.Money? credit,
      finance.Money? duesPayable,
      finance.Money? penaltiesOwed,
    }) => finance.ListMemberBalancesResponse(
      booksAvailable: available,
      balances: [
        finance.MemberBalance(
          account: List<int>.filled(20, 0xbb),
          book: finance.MemberBook(credit: usdc(999999999)),
        ),
        finance.MemberBalance(
          account: mine,
          book: finance.MemberBook(
            credit: credit ?? usdc(240),
            duesPayable: duesPayable ?? usdc(220),
            penaltiesOwed: penaltiesOwed ?? usdc(10),
            // Finance's credit less the claims, floored at zero: the top-up
            // must not be read from it.
            creditAvailable: usdc(10),
          ),
        ),
      ],
    );

    test('is what the credit lacks for the payoff after the claims', () {
      final t = payoffTopUpFor(
        payoff: BigInt.from(500),
        asset: asset,
        balances: balances(),
        myAccounts: [mine],
      )!;
      expect(t.credit.units, BigInt.from(240));
      expect(t.duesPayable.units, BigInt.from(220));
      expect(t.penaltiesOwed.units, BigInt.from(10));
      // 500 + 10 + 220 − 240.
      expect(t.topUp, BigInt.from(490));
      expect(t.needed, isTrue);
    });

    test('counts the dues and penalties the credit does not cover', () {
      // Claims of 230 against 20 of credit: credit_available floors at 0, so
      // payoff − credit_available (500) would leave the payoff refused.
      final t = payoffTopUpFor(
        payoff: BigInt.from(500),
        asset: asset,
        balances: balances(credit: usdc(20)),
        myAccounts: [mine],
      )!;
      expect(t.topUp, BigInt.from(710));
    });

    test('pays the dues payable when there is no credit', () {
      // The stawi journey: no credit, 282 USDC of dues payable.
      final t = payoffTopUpFor(
        payoff: BigInt.from(100000000),
        asset: asset,
        balances: balances(
          credit: usdc(0),
          duesPayable: usdc(282000000),
          penaltiesOwed: usdc(0),
        ),
        myAccounts: [mine],
      )!;
      expect(t.topUp, BigInt.from(382000000));
      expect(t.needed, isTrue);
    });

    test('is nothing when the credit covers the payoff and the claims', () {
      final t = payoffTopUpFor(
        payoff: BigInt.from(500),
        asset: asset,
        balances: balances(credit: usdc(730)),
        myAccounts: [mine],
      )!;
      expect(t.topUp, BigInt.zero);
      expect(t.needed, isFalse);
      expect(
        payoffTopUpFor(
          payoff: BigInt.from(500),
          asset: asset,
          balances: balances(credit: usdc(1000)),
          myAccounts: [mine],
        )!.topUp,
        BigInt.zero,
      );
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
            credit: finance.Money(assetId: 'EURC.146', amount: '5'),
          ),
          myAccounts: [mine],
        ),
        isNull,
      );
      expect(
        payoffTopUpFor(
          payoff: BigInt.one,
          asset: asset,
          balances: balances(
            duesPayable: finance.Money(assetId: 'EURC.146', amount: '5'),
          ),
          myAccounts: [mine],
        ),
        isNull,
      );
    });
  });
}
