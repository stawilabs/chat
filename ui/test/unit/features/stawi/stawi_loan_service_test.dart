import 'dart:typed_data';

import 'package:connectrpc/connect.dart' as connect;
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/data/stawi_loan_service.dart';
import 'package:stawi/features/stawi/domain/loan_terms.dart';
import 'package:stawi/features/stawi/domain/personal_calls.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

void main() {
  final me = hexToBytes('0xa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3');
  final bob = hexToBytes('0xb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3');
  final eve = hexToBytes('0xe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3');
  final book = hexToBytes('0x101112131415161718191a1b1c1d1e1f20212223');
  late FakeConnectTransport transport;

  StawiLoanService service() => StawiLoanService(
    loans: finance.LoanServiceClient(transport),
    identity: () async => identityWith('p1', me),
  );

  setUp(() => transport = FakeConnectTransport());

  finance.Loan loan({
    required List<int> borrower,
    required List<int> lender,
    int id = 1,
  }) => finance.Loan(
    borrowerAccount: borrower,
    lender: lender,
    pool: lender,
    loanBook: book,
    onchainLoanId: Int64(id),
    kind: finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON,
  );

  test('borrowed() lists the primary account\'s loans as borrower', () async {
    transport.on(
      finance.LoanService.listLoans,
      (req) => finance.ListLoansResponse(),
    );
    await service().borrowed();
    final req = transport.requestsTo(finance.LoanService.listLoans).single;
    expect(req.borrower, me);
    expect(req.hasLender(), isFalse);
  });

  test('lent() asks for the person-to-person loans as lender', () async {
    transport.on(
      finance.LoanService.listLoans,
      (req) => finance.ListLoansResponse(),
    );
    await service().lent();
    final req = transport.requestsTo(finance.LoanService.listLoans).single;
    expect(req.lender, me);
    expect(req.kind, finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON);
  });

  test('roomLoans(roomId) sends the room', () async {
    transport.on(
      finance.LoanService.listLoans,
      (req) => finance.ListLoansResponse(),
    );
    await service().roomLoans('room1');
    expect(
      transport.requestsTo(finance.LoanService.listLoans).single.roomId,
      'room1',
    );
  });

  test(
    'between() keeps only the pair, in both directions, once each',
    () async {
      transport.on(finance.LoanService.listLoans, (req) {
        // The server answers loosely: a stranger's loan comes back too.
        return finance.ListLoansResponse(
          loans: [
            loan(borrower: me, lender: bob),
            loan(borrower: bob, lender: me, id: 2),
            loan(borrower: me, lender: eve, id: 3),
          ],
        );
      });
      final loans = await service().between(me, bob);
      expect({for (final l in loans) l.onchainLoanId.toInt()}, {1, 2});
      expect(loans, hasLength(2));
      expect(transport.requestsTo(finance.LoanService.listLoans), hasLength(2));
    },
  );

  test('loan(ref) names the pool, the loan and its book', () async {
    transport.on(
      finance.LoanService.getLoan,
      (req) => finance.GetLoanResponse(),
    );
    await service().loan(
      LoanRef(loanBook: book, pool: bob, loanId: BigInt.two),
    );
    final req = transport.requestsTo(finance.LoanService.getLoan).single;
    expect(req.pool, bob);
    expect(req.onchainLoanId, Int64(2));
    expect(req.loanBook, book);
  });

  test(
    'quoteGroup sends the room, the form, the amount and instalments',
    () async {
      transport.on(
        finance.LoanService.quoteLoan,
        (req) => finance.QuoteLoanResponse(),
      );
      final product = Uint8List.fromList(List.filled(32, 5));
      await service().quoteGroup(
        roomId: 'room1',
        productId: product,
        amount: BigInt.from(500),
        instalments: 4,
      );
      final req = transport.requestsTo(finance.LoanService.quoteLoan).single;
      expect(req.kind, finance.LoanKind.LOAN_KIND_GROUP);
      expect(req.roomId, 'room1');
      expect(req.productId, product);
      expect(req.amount, '500');
      expect(req.instalments, 4);
    },
  );

  test('quotePersonal sends the amount, terms and kind', () async {
    transport.on(
      finance.LoanService.quoteLoan,
      (req) => finance.QuoteLoanResponse(),
    );
    final terms = LoanTerms.preset(
      LoanPreset.weekly4,
      rateBps: 100,
      kind: finance.LoanKind.LOAN_KIND_SELF,
    );
    await service().quotePersonal(
      amount: BigInt.from(900),
      terms: terms,
      kind: finance.LoanKind.LOAN_KIND_SELF,
    );
    final req = transport.requestsTo(finance.LoanService.quoteLoan).single;
    expect(req.amount, '900');
    expect(req.kind, finance.LoanKind.LOAN_KIND_SELF);
    expect(req.terms.instalments, 4);
  });

  test('a record that is not shared reads as such, not as an error', () async {
    transport.on(
      finance.LoanService.getCreditRecord,
      (req) => throw connect.ConnectException(
        connect.Code.permissionDenied,
        'not shared',
      ),
    );
    await expectLater(
      service().record(bob),
      throwsA(
        isA<StawiUnavailable>().having(
          (e) => e.message,
          'message',
          'Their record is not shared with you',
        ),
      ),
    );
  });

  test('another failure of a record is not hidden', () async {
    transport.on(
      finance.LoanService.getCreditRecord,
      (req) => throw connect.ConnectException(connect.Code.unavailable, 'down'),
    );
    await expectLater(
      service().record(bob),
      throwsA(isA<connect.ConnectException>()),
    );
  });

  test('a profile with no account reads no loans', () async {
    final s = StawiLoanService(
      loans: finance.LoanServiceClient(transport),
      identity: () async => const StawiIdentity(profileId: 'p1', accounts: []),
    );
    await expectLater(s.borrowed(), throwsA(isA<StawiUnavailable>()));
    expect(transport.calls, isEmpty);
  });
}
