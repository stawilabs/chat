import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/domain/payoff_top_up.dart';
import 'package:stawi_api/finance_v1.dart' as finance;

finance.Money usdc(int units) =>
    finance.Money(assetId: 'USDC.146', amount: '$units');

finance.RoomDuesProduct weekly(
  int amount, {
  int every = 1,
  int first = 0,
  int last = 0,
  bool active = true,
}) => finance.RoomDuesProduct(
  amount: usdc(amount),
  everyPeriods: every,
  firstPeriod: first,
  lastPeriod: last,
  active: active,
);

finance.ListRoomProductsResponse room({
  required int perCycle,
  required int current,
  required List<finance.RoomDuesProduct> products,
}) => finance.ListRoomProductsResponse(
  rulesConfigured: true,
  calendar: finance.RoomCalendar(
    periodsPerCycle: perCycle,
    currentPeriod: current,
  ),
  duesProducts: products,
);

void main() {
  group('remainingCycleDues', () {
    test('a VSLA cycle takes every due to its end on top of what is owed', () {
      // 52 weekly periods of 5 shares and 1 social fund (the journey's
      // vsla_52_weeks with a 1,000,000 unit); in period 10, periods 10..51
      // are still to come.
      final dues = remainingCycleDues(
        products: room(
          perCycle: 52,
          current: 10,
          products: [weekly(5000000), weekly(1000000)],
        ),
        duesOwed: BigInt.from(3000000),
      );
      expect(dues, BigInt.from(3000000 + 42 * 6000000));
    });

    test('the next cycle starts over at its own end', () {
      final dues = remainingCycleDues(
        products: room(perCycle: 52, current: 53, products: [weekly(100)]),
        duesOwed: BigInt.zero,
      );
      expect(dues, BigInt.from(51 * 100));
    });

    test('counts only the periods a product falls due in', () {
      BigInt dues(finance.RoomDuesProduct p, {int current = 10}) =>
          remainingCycleDues(
            products: room(perCycle: 52, current: current, products: [p]),
            duesOwed: BigInt.zero,
          );
      // Every 4 periods from period 2: 10, 14, ..., 50.
      expect(dues(weekly(1, every: 4, first: 2)), BigInt.from(11));
      // ... and ending at period 30: 10 .. 30.
      expect(dues(weekly(1, every: 4, first: 2, last: 30)), BigInt.from(6));
      // From period 3 on: 11, 15, ..., 51.
      expect(dues(weekly(1, every: 4, first: 3)), BigInt.from(11));
      // Due once, in period 20: still ahead in period 10, past in 25.
      expect(dues(weekly(7, every: 0, first: 20)), BigInt.from(7));
      expect(dues(weekly(7, every: 0, first: 20), current: 25), BigInt.zero);
      expect(dues(weekly(9, active: false)), BigInt.zero);
    });

    test('a room without share-out cycles takes only what is owed now', () {
      final owed = BigInt.from(1234);
      expect(
        remainingCycleDues(
          products: room(perCycle: 0, current: 3, products: [weekly(100)]),
          duesOwed: owed,
        ),
        owed,
      );
      expect(
        remainingCycleDues(
          products: finance.ListRoomProductsResponse(),
          duesOwed: owed,
        ),
        owed,
      );
    });
  });

  group('payoff top-up', () {
    test('is what the credit lacks for the dues and the payoff', () {
      final t = PayoffTopUp(
        payoff: BigInt.from(40),
        credit: BigInt.from(25),
        remainingDues: BigInt.from(300),
      );
      expect(t.topUp, BigInt.from(315));
      expect(t.needed, isTrue);
      final covered = PayoffTopUp(
        payoff: BigInt.from(40),
        credit: BigInt.from(400),
        remainingDues: BigInt.from(300),
      );
      expect(covered.topUp, BigInt.zero);
      expect(covered.needed, isFalse);
    });

    final mine = List<int>.filled(20, 0xaa);
    finance.ListMemberBalancesResponse balances({bool available = true}) =>
        finance.ListMemberBalancesResponse(
          booksAvailable: available,
          balances: [
            finance.MemberBalance(
              account: List<int>.filled(20, 0xbb),
              book: finance.MemberBook(credit: usdc(999999999)),
            ),
            finance.MemberBalance(
              account: mine,
              book: finance.MemberBook(credit: usdc(10), duesOwed: usdc(20)),
            ),
          ],
        );
    final products = room(perCycle: 4, current: 2, products: [weekly(100)]);

    test('is read from the member\'s own live book', () {
      final t = payoffTopUpFor(
        payoff: BigInt.from(500),
        balances: balances(),
        products: products,
        myAccounts: [mine],
      )!;
      expect(t.credit, BigInt.from(10));
      expect(t.remainingDues, BigInt.from(20 + 2 * 100));
      expect(t.topUp, BigInt.from(20 + 200 + 500 - 10));
    });

    test('is unknown without the member\'s live book', () {
      expect(
        payoffTopUpFor(
          payoff: BigInt.one,
          balances: balances(available: false),
          products: products,
          myAccounts: [mine],
        ),
        isNull,
      );
      expect(
        payoffTopUpFor(
          payoff: BigInt.one,
          balances: balances(),
          products: products,
          myAccounts: [List<int>.filled(20, 0xcc)],
        ),
        isNull,
      );
    });
  });
}
