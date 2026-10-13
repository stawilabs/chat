import 'dart:typed_data';

import 'package:connectrpc/connect.dart' as connect;
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/domain/account_engine_calls.dart';
import 'package:stawi/features/stawi/domain/intent_bridge.dart';
import 'package:stawi/features/stawi/domain/loan_terms.dart';
import 'package:stawi/features/stawi/domain/personal_calls.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi/features/stawi/ui/stawi_feedback.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

Matcher refusedWith(Object reason) =>
    throwsA(isA<SigningRefused>().having((e) => e.reason, 'reason', reason));

void main() {
  final vectors = {
    for (final v in GoEngineCallVector.load().where((v) => v.personal))
      v.name: v,
  };
  final vault = hexToBytes('0x909192939495969798999a9b9c9d9e9fa0a1a2a3');
  final book = hexToBytes('0x101112131415161718191a1b1c1d1e1f20212223');
  final otherBook = hexToBytes('0x303132333435363738393a3b3c3d3e3f40414243');
  final targets = PersonalTargets.fromResponse(vault: vault, loanBooks: [book]);
  final peer = hexToBytes('0xb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3');
  final me = vectors['offer']!.account;
  final goalPocket = hexToBytes(
    '0x606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f',
  );
  final free = Uint8List(32);
  LoanTerms termsOf(String vector) {
    final t = vectors[vector]!.json['terms'] as Map<String, dynamic>;
    return LoanTerms.fromSdk(
      PersonalTerms(
        n: t['n'] as int,
        everyDays: t['every_days'] as int,
        method: t['method'] as int,
        rateBps: t['rate_bps'] as int,
        lateMethod: t['late_method'] as int,
        lateBps: t['late_bps'] as int,
        lateFlat: BigInt.parse(t['late_flat'] as String),
        defaultAfterDays: t['default_after_days'] as int,
      ),
    );
  }

  final expiry = DateTime.fromMillisecondsSinceEpoch(
    1760000000 * 1000,
    isUtc: true,
  );

  /// Bob's offer to me (and, once accepted, the loan I pay).
  finance.Loan offered({int loanId = 1}) => finance.Loan(
    pool: peer,
    lender: peer,
    borrowerAccount: me,
    loanBook: book,
    onchainLoanId: Int64(loanId),
    requested: finance.Money(amount: '300000000'),
    terms: termsOf('offer').proto,
    kind: finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON,
    offeredBy: peer,
  );

  /// Bob's ask of me.
  finance.Loan asked() => finance.Loan(
    pool: me,
    lender: me,
    borrowerAccount: peer,
    loanBook: book,
    onchainLoanId: Int64(1),
    requested: finance.Money(amount: '300000000'),
    terms: termsOf('ask').proto,
    kind: finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON,
    offeredBy: peer,
  );

  final cases = <String, PersonalRequest Function()>{
    'borrow_self': () => PersonalRequest.borrowSelf(
      pocket: free,
      amount: BigInt.from(200000000),
      terms: termsOf('borrow_self'),
    ),
    'offer': () => PersonalRequest.offer(
      borrower: peer,
      pocket: free,
      amount: BigInt.from(300000000),
      terms: termsOf('offer'),
      expiresAt: expiry,
    ),
    'ask': () => PersonalRequest.ask(
      lender: peer,
      amount: BigInt.from(300000000),
      terms: termsOf('ask'),
      expiresAt: expiry,
    ),
    'accept_offer': () => PersonalRequest.acceptOffer(offer: offered()),
    'accept_ask': () =>
        PersonalRequest.acceptAsk(ask: asked(), pocket: goalPocket),
    'pay': () =>
        PersonalRequest.pay(loan: offered(), amount: BigInt.from(52000000)),
    'personal_cancel': () => PersonalRequest.cancel(loan: offered(loanId: 2)),
    // The vector's ceiling is the largest uint256: one the person set.
    'personal_payoff': () => PersonalRequest.payoff(
      loan: offered(),
      ceiling: BigInt.parse(
        vectors['personal_payoff']!.json['amount'] as String,
      ),
    ),
    'vault_withdraw': () =>
        PersonalRequest.withdraw(pocket: free, amount: BigInt.from(100000000)),
    'vault_create_goal': () => PersonalRequest.createGoal(
      name: 'school',
      target: BigInt.from(500000000),
      unlockAt: DateTime.fromMillisecondsSinceEpoch(
        1790000000 * 1000,
        isUtc: true,
      ),
      loanable: true,
    ),
    'vault_move': () => PersonalRequest.move(
      from: free,
      to: goalPocket,
      amount: BigInt.from(100000000),
    ),
  };

  ({Uint8List digest, EngineCall call}) check(
    String vector,
    PersonalRequest request, {
    PersonalTargets? personal,
    bool noTargets = false,
    Uint8List? account,
  }) {
    final v = vectors[vector]!;
    return checkedPersonalCall(
      prepared: v.prepared(request.call.kind),
      request: request,
      account: account ?? v.account,
      personal: noTargets ? null : (personal ?? targets),
    );
  }

  group('the prepared call is the one asked for', () {
    test('every personal vector has a case', () {
      expect(cases.keys.toSet(), vectors.keys.toSet());
    });

    for (final MapEntry(key: name, value: build) in cases.entries) {
      test(name, () {
        final v = vectors[name]!;
        final request = build();
        final checked = check(name, request);
        expect(checked.digest, v.digest);
        expect(checked.call.action, request.call.action);
        expect(checked.call.calldata, v.calldata);
        expect(request.expected.action, request.call.action);
      });
    }

    test('a payoff with the ceiling shown is checked against it', () {
      final ceiling = BigInt.parse(
        vectors['personal_payoff']!.json['amount'] as String,
      );
      final r = PersonalRequest.payoff(loan: offered(), ceiling: ceiling);
      expect(r.params.amount, ceiling.toString());
      expect(check('personal_payoff', r).call.amount, ceiling);
      expect(
        () => check(
          'personal_payoff',
          PersonalRequest.payoff(
            loan: offered(),
            ceiling: ceiling - BigInt.one,
          ),
        ),
        refusedWith(
          'settlement prepared something else: not the call you asked for',
        ),
      );
    });

    test('a payoff without a ceiling asks settlement to quote one', () {
      final r = PersonalRequest.payoff(loan: offered());
      expect(r.params.amount, isEmpty);
      expect(r.expected.amount, BigInt.zero);
      expect(r.maxRepay, BigInt.from(637500000));
    });

    /// The payoff vector's call with settlement's quote [q] as the ceiling,
    /// its intent and digest made to match.
    settlement.PrepareAccountCallResponse quoted(BigInt q) {
      final v = vectors['personal_payoff']!;
      final calldata = EngineCall(
        action: EngineAction.personalPayoff,
        pool: peer,
        loanId: BigInt.one,
        amount: q,
      ).calldata;
      final intent = v.intent
        ..amount = q.toString()
        ..authorizationId = engineCallHash(v.target, calldata);
      final digest = sdkIntentOf(intent).digest();
      return v.prepared(PersonalCall.payoff.kind)
        ..intentDigest = digest
        ..financialIntent = intent
        ..call.intentDigest = digest
        ..call.engineCalldata = calldata;
    }

    test('a quoted payoff up to the most the loan could cost is shown', () {
      final r = PersonalRequest.payoff(loan: offered());
      for (final q in [BigInt.from(260000000), r.maxRepay!]) {
        final checked = checkedPersonalCall(
          prepared: quoted(q),
          request: r,
          account: me,
          personal: targets,
        );
        expect(checked.call.amount, q);
      }
    });

    test('a quoted payoff above the most the loan could cost is refused', () {
      final r = PersonalRequest.payoff(loan: offered());
      for (final q in [
        r.maxRepay! + BigInt.one,
        BigInt.parse(vectors['personal_payoff']!.json['amount'] as String),
      ]) {
        expect(
          () => checkedPersonalCall(
            prepared: quoted(q),
            request: r,
            account: me,
            personal: targets,
          ),
          refusedWith(payoffQuoteTooHigh),
        );
      }
    });
  });

  group('what settlement is asked to prepare', () {
    test('every call on an existing loan names its loan book', () {
      for (final MapEntry(key: name, value: build) in cases.entries) {
        final r = build();
        if (r.call.onExistingLoan) {
          expect(r.loanBook, book, reason: name);
          expect(r.params.loanBook, book, reason: name);
        } else {
          expect(r.loanBook, isNull, reason: name);
          expect(r.params.hasLoanBook(), isFalse, reason: name);
        }
      }
    });

    test('free savings is left unset; a goal pocket is named', () {
      expect(cases['borrow_self']!().params.hasPocket(), isFalse);
      expect(cases['offer']!().params.hasPocket(), isFalse);
      expect(cases['accept_ask']!().params.pocket, goalPocket);
      final move = cases['vault_move']!();
      expect(move.params.hasPocket(), isFalse);
      expect(move.params.toPocket, goalPocket);
      expect(move.expected.pocket, free);
    });

    test('an offer carries its counterparty, terms and expiry', () {
      final p = cases['offer']!().params;
      expect(p.counterparty, peer);
      expect(p.amount, '300000000');
      expect(p.terms, termsOf('offer').proto);
      expect(p.expiresAt.seconds, Int64(1760000000));
    });

    test('a goal carries its name, target, unlock time and lending', () {
      final g = cases['vault_create_goal']!().params.goal;
      expect(g.name, 'school');
      expect(g.target, '500000000');
      expect(g.unlockAt.seconds, Int64(1790000000));
      expect(g.loanable, isTrue);
    });

    test('labels are the plain words', () {
      expect(PersonalCall.values.map((c) => c.label), [
        'Borrow from my savings',
        'Lend',
        'Ask to borrow',
        'Accept',
        'Lend',
        'Pay an instalment',
        'Cancel',
        'Pay off the loan',
        'Withdraw my savings',
        'Start a savings goal',
        'Move my savings',
      ]);
    });
  });

  group('a call prepared for anything else is refused', () {
    const mismatch =
        'settlement prepared something else: not the call you asked for';
    final t = termsOf('offer');
    final terms5 = LoanTerms(
      finance.PersonalLoanTerms()
        ..mergeFromMessage(t.proto)
        ..instalments = 5,
    );
    PersonalRequest offer({
      Uint8List? borrower,
      Uint8List? pocket,
      int amount = 300000000,
      LoanTerms? terms,
      DateTime? expiresAt,
    }) => PersonalRequest.offer(
      borrower: borrower ?? peer,
      pocket: pocket ?? free,
      amount: BigInt.from(amount),
      terms: terms ?? t,
      expiresAt: expiresAt ?? expiry,
    );

    final wrong = <String, (String, PersonalRequest Function())>{
      'an offer to another borrower': (
        'offer',
        () => offer(borrower: Uint8List(20)..[19] = 9),
      ),
      'an offer of another amount': ('offer', () => offer(amount: 300000001)),
      'an offer from another pocket': (
        'offer',
        () => offer(pocket: Uint8List(32)..[31] = 1),
      ),
      'an offer on other terms': ('offer', () => offer(terms: terms5)),
      'an offer open longer': (
        'offer',
        () => offer(expiresAt: expiry.add(const Duration(days: 1))),
      ),
      'an ask of another lender': (
        'ask',
        () => PersonalRequest.ask(
          lender: Uint8List(20)..[0] = 1,
          amount: BigInt.from(300000000),
          terms: t,
          expiresAt: expiry,
        ),
      ),
      'an ask of another amount': (
        'ask',
        () => PersonalRequest.ask(
          lender: peer,
          amount: BigInt.from(299999999),
          terms: t,
          expiresAt: expiry,
        ),
      ),
      'an ask on other terms': (
        'ask',
        () => PersonalRequest.ask(
          lender: peer,
          amount: BigInt.from(300000000),
          terms: terms5,
          expiresAt: expiry,
        ),
      ),
      'an ask open longer': (
        'ask',
        () => PersonalRequest.ask(
          lender: peer,
          amount: BigInt.from(300000000),
          terms: t,
          expiresAt: expiry.add(const Duration(seconds: 1)),
        ),
      ),
      'a self loan from another pocket': (
        'borrow_self',
        () => PersonalRequest.borrowSelf(
          pocket: goalPocket,
          amount: BigInt.from(200000000),
          terms: termsOf('borrow_self'),
        ),
      ),
      'a self loan of another amount': (
        'borrow_self',
        () => PersonalRequest.borrowSelf(
          pocket: free,
          amount: BigInt.from(200000001),
          terms: termsOf('borrow_self'),
        ),
      ),
      'a self loan on other terms': (
        'borrow_self',
        () => PersonalRequest.borrowSelf(
          pocket: free,
          amount: BigInt.from(200000000),
          terms: LoanTerms.preset(
            LoanPreset.weekly4,
            rateBps: 101,
            kind: finance.LoanKind.LOAN_KIND_SELF,
          ),
        ),
      ),
      'lending to an ask from another pocket': (
        'accept_ask',
        () => PersonalRequest.acceptAsk(ask: asked(), pocket: free),
      ),
      'lending to another ask': (
        'accept_ask',
        () => PersonalRequest.acceptAsk(
          ask: asked()..onchainLoanId = Int64(2),
          pocket: goalPocket,
        ),
      ),
      'lending to an ask of another borrower': (
        'accept_ask',
        () => PersonalRequest.acceptAsk(
          ask: asked()..borrowerAccount = (Uint8List(20)..[0] = 5),
          pocket: goalPocket,
        ),
      ),
      'lending another amount to an ask': (
        'accept_ask',
        () => PersonalRequest.acceptAsk(
          ask: asked()..requested = finance.Money(amount: '300000001'),
          pocket: goalPocket,
        ),
      ),
      'moving from another pocket': (
        'vault_move',
        () => PersonalRequest.move(
          from: Uint8List(32)..[0] = 2,
          to: goalPocket,
          amount: BigInt.from(100000000),
        ),
      ),
      'moving another amount': (
        'vault_move',
        () => PersonalRequest.move(
          from: free,
          to: goalPocket,
          amount: BigInt.from(100000001),
        ),
      ),
      'a goal of another target': (
        'vault_create_goal',
        () => PersonalRequest.createGoal(
          name: 'school',
          target: BigInt.from(500000001),
          unlockAt: DateTime.fromMillisecondsSinceEpoch(
            1790000000 * 1000,
            isUtc: true,
          ),
          loanable: true,
        ),
      ),
      'a goal unlocking at another time': (
        'vault_create_goal',
        () => PersonalRequest.createGoal(
          name: 'school',
          target: BigInt.from(500000000),
          unlockAt: DateTime.fromMillisecondsSinceEpoch(
            1790000001 * 1000,
            isUtc: true,
          ),
          loanable: true,
        ),
      ),
      'cancelling with another lender': (
        'personal_cancel',
        () => PersonalRequest.cancel(
          loan: offered(loanId: 2)
            ..pool = (Uint8List(20)..[0] = 7)
            ..lender = (Uint8List(20)..[0] = 7),
        ),
      ),
      'paying off another lender': (
        'personal_payoff',
        () => PersonalRequest.payoff(
          loan: offered()
            ..pool = (Uint8List(20)..[0] = 7)
            ..lender = (Uint8List(20)..[0] = 7),
          ceiling: BigInt.parse(
            vectors['personal_payoff']!.json['amount'] as String,
          ),
        ),
      ),
      'paying off another loan': (
        'personal_payoff',
        () => PersonalRequest.payoff(
          loan: offered(loanId: 2),
          ceiling: BigInt.parse(
            vectors['personal_payoff']!.json['amount'] as String,
          ),
        ),
      ),
      'paying another amount': (
        'pay',
        () => PersonalRequest.pay(loan: offered(), amount: BigInt.from(1)),
      ),
      'paying another loan': (
        'pay',
        () => PersonalRequest.pay(
          loan: offered(loanId: 3),
          amount: BigInt.from(52000000),
        ),
      ),
      'paying another lender': (
        'pay',
        () => PersonalRequest.pay(
          loan: offered()
            ..pool = (Uint8List(20)..[0] = 7)
            ..lender = (Uint8List(20)..[0] = 7),
          amount: BigInt.from(52000000),
        ),
      ),
      'cancelling another loan': (
        'personal_cancel',
        () => PersonalRequest.cancel(loan: offered()),
      ),
      'withdrawing from another pocket': (
        'vault_withdraw',
        () => PersonalRequest.withdraw(
          pocket: goalPocket,
          amount: BigInt.from(100000000),
        ),
      ),
      'withdrawing another amount': (
        'vault_withdraw',
        () => PersonalRequest.withdraw(pocket: free, amount: BigInt.from(100)),
      ),
      'moving to another pocket': (
        'vault_move',
        () => PersonalRequest.move(
          from: free,
          to: Uint8List(32)..[0] = 1,
          amount: BigInt.from(100000000),
        ),
      ),
      'a goal of another name': (
        'vault_create_goal',
        () => PersonalRequest.createGoal(
          name: 'School',
          target: BigInt.from(500000000),
          unlockAt: DateTime.fromMillisecondsSinceEpoch(
            1790000000 * 1000,
            isUtc: true,
          ),
          loanable: true,
        ),
      ),
      'a goal not to be lent': (
        'vault_create_goal',
        () => PersonalRequest.createGoal(
          name: 'school',
          target: BigInt.from(500000000),
          unlockAt: DateTime.fromMillisecondsSinceEpoch(
            1790000000 * 1000,
            isUtc: true,
          ),
          loanable: false,
        ),
      ),
    };

    for (final MapEntry(key: what, value: (vector, build)) in wrong.entries) {
      test(what, () {
        expect(() => check(vector, build()), refusedWith(mismatch));
      });
    }

    test('an offer on other terms is a request mismatch, not a quirk', () {
      expect(() => check('offer', offer(terms: terms5)), refusedWith(mismatch));
    });

    test('a prepared call of another kind is refused', () {
      final v = vectors['pay']!;
      expect(
        () => checkedPersonalCall(
          prepared: v.prepared(PersonalCall.payoff.kind),
          request: cases['pay']!(),
          account: v.account,
          personal: targets,
        ),
        refusedWith('settlement prepared another kind of call'),
      );
    });

    test('a call for another account is refused', () {
      expect(
        () =>
            check('vault_withdraw', cases['vault_withdraw']!(), account: peer),
        throwsA(isA<SigningRefused>()),
      );
    });

    test('a counterparty that is a known room is refused', () {
      expect(
        () => checkedPersonalCall(
          prepared: vectors['offer']!.prepared(PersonalCall.offer.kind),
          request: cases['offer']!(),
          account: me,
          personal: targets,
          roomCustodies: [peer],
        ),
        refusedWith('the other person is not a person\'s account'),
      );
    });

    test('a loan that is not mine to pay is refused', () {
      expect(
        () => check(
          'pay',
          PersonalRequest.pay(
            loan: offered()..borrowerAccount = (Uint8List(20)..[0] = 5),
            amount: BigInt.from(52000000),
          ),
        ),
        refusedWith('this loan is not yours to act on'),
      );
    });
  });

  group('accepting an offer', () {
    test('an offer other than the one shown is refused', () {
      const maxRepay = 'the most you could repay is not what the terms give';
      const notShown = 'this is not the offer you were shown';
      for (final (shown, reason) in <(finance.Loan, String)>[
        (offered()..requested = finance.Money(amount: '250000000'), maxRepay),
        (offered()..terms = termsOf('borrow_self').proto, maxRepay),
        (offered(loanId: 2), notShown),
        (offered()..lender = (Uint8List(20)..[0] = 4), notShown),
      ]) {
        expect(
          () =>
              check('accept_offer', PersonalRequest.acceptOffer(offer: shown)),
          refusedWith(reason),
        );
      }
    });

    test('another amount gives another most-repaid: refused in words', () {
      expect(
        () => check(
          'accept_offer',
          PersonalRequest.acceptOffer(
            offer: offered()..requested = finance.Money(amount: '250000000'),
          ),
        ),
        refusedWith('the most you could repay is not what the terms give'),
      );
    });

    test('"At most you will repay" is the SDK\'s maxRepayable', () {
      final r = PersonalRequest.acceptOffer(offer: offered());
      final checked = check('accept_offer', r);
      expect(
        r.maxRepay,
        maxRepayable(BigInt.from(300000000), termsOf('offer').sdk),
      );
      expect(r.maxRepay, BigInt.from(637500000));
      expect(checked.call.maxRepay, r.maxRepay);
      expect(r.offer!.lender, peer);
      expect(cases['ask']!().maxRepay, BigInt.from(637500000));
    });

    test('only an offer from a person is accepted', () {
      expect(
        () => PersonalRequest.acceptOffer(
          offer: offered()..kind = finance.LoanKind.LOAN_KIND_GROUP,
        ),
        throwsFormatException,
      );
    });
  });

  group('the targets', () {
    test('no personal targets, no signature', () {
      expect(
        () => check('pay', cases['pay']!(), noTargets: true),
        refusedWith(personalTargetsUnknownReason),
      );
    });

    test('a call to a book that is not admitted is refused', () {
      expect(
        () => check(
          'pay',
          cases['pay']!(),
          personal: PersonalTargets.fromResponse(
            vault: vault,
            loanBooks: [otherBook],
          ),
        ),
        refusedWith(
          'the call goes to a contract that is not your vault or this '
          'loan\'s book',
        ),
      );
    });

    test('a call through another vault is refused', () {
      expect(
        () => check(
          'vault_withdraw',
          cases['vault_withdraw']!(),
          personal: PersonalTargets.fromResponse(
            vault: otherBook,
            loanBooks: [book],
          ),
        ),
        throwsA(isA<SigningRefused>()),
      );
    });

    test('a loan on another admitted book is refused', () {
      expect(
        () => check(
          'pay',
          PersonalRequest.pay(
            loan: offered()..loanBook = otherBook,
            amount: BigInt.from(52000000),
          ),
          personal: PersonalTargets.fromResponse(
            vault: vault,
            loanBooks: [book, otherBook],
          ),
        ),
        throwsA(isA<SigningRefused>()),
      );
    });

    test('a loan whose book is unknown cannot be asked about', () {
      expect(
        () => PersonalRequest.pay(
          loan: offered()..loanBook = <int>[],
          amount: BigInt.one,
        ),
        throwsFormatException,
      );
    });
  });

  group('empty amounts', () {
    final zero = BigInt.zero;
    final t = termsOf('offer');
    test('a zero amount on any call but a payoff is refused', () {
      for (final build in <PersonalRequest Function()>[
        () => PersonalRequest.borrowSelf(pocket: free, amount: zero, terms: t),
        () => PersonalRequest.offer(
          borrower: peer,
          pocket: free,
          amount: zero,
          terms: t,
          expiresAt: expiry,
        ),
        () => PersonalRequest.ask(
          lender: peer,
          amount: zero,
          terms: t,
          expiresAt: expiry,
        ),
        () => PersonalRequest.acceptAsk(
          ask: asked()..requested = finance.Money(amount: '0'),
          pocket: free,
        ),
        () => PersonalRequest.acceptAsk(
          ask: asked()..requested = finance.Money(),
          pocket: free,
        ),
        () => PersonalRequest.acceptOffer(
          offer: offered()..requested = finance.Money(),
        ),
        () => PersonalRequest.pay(loan: offered(), amount: zero),
        () => PersonalRequest.withdraw(pocket: free, amount: zero),
        () => PersonalRequest.move(from: free, to: goalPocket, amount: zero),
        () => PersonalRequest.payoff(loan: offered(), ceiling: zero),
      ]) {
        expect(build, throwsFormatException);
      }
      expect(
        () => PersonalRequest.pay(loan: offered(), amount: -BigInt.one),
        throwsFormatException,
      );
    });

    test('only a payoff leaves its amount to the quote', () {
      expect(PersonalRequest.payoff(loan: offered()).expected.amount, zero);
    });

    test('a room call with an empty or zero amount is refused, but a '
        'payoff', () {
      final custody = Uint8List(20)..[0] = 1;
      for (final call in AccountEngineCall.values.where(
        (c) => c.takesAmount && !c.amountOptional,
      )) {
        for (final amount in ['', '0']) {
          expect(
            () => AccountEngineRequest(
              call: call,
              custody: custody,
              amount: amount,
              loanId: 1,
              productId: Uint8List(32),
            ),
            throwsFormatException,
            reason: '${call.name} "$amount"',
          );
        }
      }
      expect(
        AccountEngineRequest(
          call: AccountEngineCall.loanPayoff,
          custody: custody,
          loanId: 1,
        ).expected.amount,
        zero,
      );
    });
  });

  group('goals', () {
    DateTime unlock() => DateTime.utc(2027);
    test('a name over 80 bytes of UTF-8, an empty name or a zero target is '
        'refused', () {
      expect(
        () => PersonalRequest.createGoal(
          name: '€' * 27,
          target: BigInt.one,
          unlockAt: unlock(),
          loanable: false,
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'A goal name is at most 80 bytes',
          ),
        ),
      );
      final ok = PersonalRequest.createGoal(
        name: '€' * 26,
        target: BigInt.one,
        unlockAt: unlock(),
        loanable: false,
      );
      expect(ok.expected.goalNameHash, keccak256Utf8('€' * 26));
      expect(
        () => PersonalRequest.createGoal(
          name: 'school',
          target: BigInt.zero,
          unlockAt: unlock(),
          loanable: false,
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'Enter a target greater than zero',
          ),
        ),
      );
      expect(
        () => PersonalRequest.createGoal(
          name: '',
          target: BigInt.one,
          unlockAt: unlock(),
          loanable: false,
        ),
        throwsFormatException,
      );
    });
  });

  group('standing orders', () {
    final grants = GoVaultVectors.load().standingGrants;
    test('the vectors cover self and person-to-person loans', () {
      expect(grants, hasLength(3));
    });

    for (final g in grants) {
      ({Uint8List digest, StandingGrant grant}) grant(
        settlement.PrepareAccountCallResponse prepared, {
        finance.Loan? loan,
        List<int>? policyAsset,
      }) => checkedStandingGrant(
        prepared: prepared,
        account: g.account,
        loan: loan ?? g.loan,
        personal: g.targets,
        policyAsset: policyAsset ?? g.asset,
      );

      test('${g.name}: the grant is the loan\'s', () {
        final checked = grant(g.prepared);
        expect(checked.digest, g.digest);
        expect(checked.grant.maxPerPeriod, g.largestInstalment);
        expect(
          checked.grant.periodSeconds,
          BigInt.from(g.terms.everyDays * 86400),
        );
      });

      test('${g.name}: the op hash is the account\'s', () {
        final s = g.standing;
        final sg = StandingGrant(
          authorizationId: s.authorizationId,
          target: s.target,
          selector: s.selector,
          asset: s.asset,
          maxPerPeriod: BigInt.parse(s.maxPerPeriod),
          periodSeconds: BigInt.parse(s.periodSeconds.toStringUnsigned()),
          epochStart: BigInt.parse(s.epochStart.toStringUnsigned()),
          validAfter: BigInt.parse(s.validAfter.toStringUnsigned()),
          validUntil: BigInt.parse(s.validUntil.toStringUnsigned()),
        );
        expect(sg.opHash, g.opHash);
      });

      test('${g.name}: another ceiling is refused', () {
        expect(
          () => grant(
            g.preparedWith(maxPerPeriod: g.largestInstalment + BigInt.one),
          ),
          refusedWith(notTheLoansStandingOrder),
        );
      });

      test('${g.name}: another period is refused', () {
        expect(
          () => grant(
            g.preparedWith(
              periodSeconds: BigInt.from(g.terms.everyDays * 86400 + 1),
            ),
          ),
          refusedWith(notTheLoansStandingOrder),
        );
      });

      test('${g.name}: another target is refused', () {
        expect(
          () => grant(g.preparedWith(target: Uint8List(20)..[0] = 0x42)),
          refusedWith(notTheLoansStandingOrder),
        );
      });

      test('${g.name}: another id is refused', () {
        expect(
          () => grant(
            g.preparedWith(
              authorizationId: standingOrderId(
                g.book,
                g.pool,
                g.loanId + BigInt.one,
              ),
            ),
          ),
          refusedWith(notTheLoansStandingOrder),
        );
      });

      test('${g.name}: an intent that does not bind the grant is refused', () {
        final p = g.prepared;
        p.managementOp.auth.maxPerPeriod = '1';
        expect(
          () => grant(p),
          refusedWith(
            'the signature would not cover the automatic payment shown',
          ),
        );
      });
    }

    final g = grants.first;
    test('a loan not yet active gets no standing order', () {
      for (final state in [
        finance.LoanState.LOAN_STATE_PENDING_APPROVAL,
        finance.LoanState.LOAN_STATE_APPROVED,
        finance.LoanState.LOAN_STATE_PAID,
        finance.LoanState.LOAN_STATE_CANCELLED,
      ]) {
        final loan = g.loan..state = state;
        expect(
          () => checkedStandingGrant(
            prepared: g.prepared,
            account: g.account,
            loan: loan,
            personal: g.targets,
            policyAsset: g.asset,
          ),
          refusedWith('a standing order starts once the loan is active'),
        );
        expect(() => standingOrderParams(loan), throwsFormatException);
      }
    });

    test('an active loan asks for its own standing order', () {
      final p = standingOrderParams(g.loan);
      expect(p.pool, g.pool);
      expect(p.loanId, Int64(g.loanId.toInt()));
      expect(p.loanBook, g.book);
    });

    test('someone else\'s loan, another asset, no op or no targets: '
        'refused', () {
      expect(
        () => checkedStandingGrant(
          prepared: g.prepared,
          account: g.account,
          loan: g.loan..borrowerAccount = peer,
          personal: g.targets,
          policyAsset: g.asset,
        ),
        refusedWith(notTheLoansStandingOrder),
      );
      expect(
        () => checkedStandingGrant(
          prepared: g.prepared,
          account: g.account,
          loan: g.loan,
          personal: g.targets,
          policyAsset: Uint8List(20)..[0] = 1,
        ),
        throwsA(isA<SigningRefused>()),
      );
      expect(
        () => checkedStandingGrant(
          prepared: g.prepared..clearManagementOp(),
          account: g.account,
          loan: g.loan,
          personal: g.targets,
          policyAsset: g.asset,
        ),
        refusedWith(notTheLoansStandingOrder),
      );
      expect(
        () => checkedStandingGrant(
          prepared: g.prepared,
          account: g.account,
          loan: g.loan,
          personal: null,
          policyAsset: g.asset,
        ),
        refusedWith(personalTargetsUnknownReason),
      );
    });
  });

  group('turning a standing order off', () {
    final revokes = GoVaultVectors.load().standingRevokes;
    test(
      'the vectors cover self, person-to-person and the largest loan id',
      () {
        expect(revokes, hasLength(3));
      },
    );
    const wrong =
        'this would stop something other than your loan\'s automatic payment';

    for (final r in revokes) {
      Uint8List revoke(
        settlement.PrepareAccountCallResponse p, {
        finance.Loan? loan,
        List<int>? policyAsset,
      }) => checkedStandingRevoke(
        prepared: p,
        account: r.account,
        loan: loan ?? r.loan,
        policyAsset: policyAsset ?? r.asset,
      );

      test('${r.name}: the loan\'s own order is revoked', () {
        expect(revoke(r.prepared()), r.digest);
        expect(standingOrderRevokeOpHash(r.authorizationId), r.opHash);
        expect(standingRevokeParams(r.loan).authorizationId, r.authorizationId);
      });

      test('${r.name}: another id in the op is refused', () {
        expect(
          () => revoke(r.prepared(opId: Uint8List(32)..[0] = 1)),
          refusedWith(wrong),
        );
      });

      test('${r.name}: an intent revoking another order is refused', () {
        final other = standingOrderId(r.book, r.pool, r.loanId - BigInt.one);
        expect(
          () => revoke(
            r.prepared(
              opId: other,
              intentAuthorizationId: standingOrderRevokeOpHash(other),
            ),
          ),
          refusedWith(wrong),
        );
        expect(
          () => revoke(r.prepared(intentAuthorizationId: Uint8List(32))),
          refusedWith(wrong),
        );
      });

      test('${r.name}: another loan or asset is refused', () {
        expect(
          () => revoke(r.prepared(), loan: r.loan..onchainLoanId = Int64(2)),
          refusedWith(wrong),
        );
        expect(
          () => revoke(r.prepared(), policyAsset: Uint8List(20)..[0] = 1),
          refusedWith(wrong),
        );
      });
    }
  });

  group('deposits', () {
    final deposits = GoVaultVectors.load().deposits;
    test('the vectors cover free savings and goals', () {
      expect(deposits, hasLength(3));
    });
    for (final d in deposits) {
      test('${d.name}: into the pocket chosen', () {
        expect(
          checkedVaultDeposit(
            prepared: d.prepared,
            account: d.account,
            pocket: d.pocket,
            amount: d.amount,
            personal: d.targets,
          ),
          d.digest,
        );
      });

      test('${d.name}: another pocket is refused', () {
        expect(
          () => checkedVaultDeposit(
            prepared: d.prepared,
            account: d.account,
            pocket: Uint8List(32)..[0] = 0xff,
            amount: d.amount,
            personal: d.targets,
          ),
          refusedWith('the deposit goes to another pocket or vault'),
        );
      });

      test('${d.name}: another amount or vault, or no targets, is '
          'refused', () {
        expect(
          () => checkedVaultDeposit(
            prepared: d.prepared,
            account: d.account,
            pocket: d.pocket,
            amount: d.amount - BigInt.one,
            personal: d.targets,
          ),
          throwsA(isA<SigningRefused>()),
        );
        expect(
          () => checkedVaultDeposit(
            prepared: d.prepared,
            account: d.account,
            pocket: d.pocket,
            amount: d.amount,
            personal: PersonalTargets.fromResponse(
              vault: otherBook,
              loanBooks: [book],
            ),
          ),
          refusedWith('the deposit goes to another pocket or vault'),
        );
        expect(
          () => checkedVaultDeposit(
            prepared: d.prepared,
            account: d.account,
            pocket: d.pocket,
            amount: d.amount,
            personal: null,
          ),
          refusedWith(personalTargetsUnknownReason),
        );
      });
    }
  });

  group('sending out of the wallet', () {
    final d = GoVaultVectors.load().deposits.first;
    final to = Uint8List(20)..[19] = 0x77;
    settlement.PrepareAccountCallResponse transfer({
      List<int>? dest,
      finance.LocationKind kind =
          finance.LocationKind.LOCATION_KIND_USER_ACCOUNT,
    }) {
      final intent = d.intent
        ..destination = finance.ValueLocation(kind: kind, address: dest ?? to);
      final digest = sdkIntentOf(intent).digest();
      return settlement.PrepareAccountCallResponse(
        intentDigest: digest,
        financialIntent: intent,
        call: settlement.AccountCall(
          address: d.account,
          kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_TRANSFER,
          intentDigest: digest,
        ),
      );
    }

    test('exactly the address and amount given are signed', () {
      final p = transfer();
      expect(
        checkedTransferOut(
          prepared: p,
          account: d.account,
          to: to,
          amount: d.amount,
        ),
        p.intentDigest,
      );
    });

    test('another address, place or amount is refused', () {
      for (final (p, amount) in [
        (transfer(dest: Uint8List(20)..[19] = 0x78), d.amount),
        (
          transfer(kind: finance.LocationKind.LOCATION_KIND_PERSONAL_VAULT),
          d.amount,
        ),
        (transfer(), d.amount + BigInt.one),
        (transfer(), BigInt.zero),
      ]) {
        expect(
          () => checkedTransferOut(
            prepared: p,
            account: d.account,
            to: to,
            amount: amount,
          ),
          throwsA(isA<SigningRefused>()),
        );
      }
    });
  });

  group('contributions', () {
    final d = GoVaultVectors.load().deposits.first;
    final custody = Uint8List(20)..[0] = 0x50;
    settlement.PrepareAccountCallResponse contribution() {
      final intent = d.intent
        ..type = finance.IntentType.INTENT_TYPE_CONTRIBUTION
        ..destination = finance.ValueLocation(
          kind: finance.LocationKind.LOCATION_KIND_ROOM_CUSTODY,
          address: custody,
        );
      final digest = sdkIntentOf(intent).digest();
      return settlement.PrepareAccountCallResponse(
        intentDigest: digest,
        financialIntent: intent,
        call: settlement.AccountCall(
          address: d.account,
          kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_CONTRIBUTE,
          intentDigest: digest,
        ),
      );
    }

    test('returns the amount it checked', () {
      final checked = checkedContribution(
        prepared: contribution(),
        account: d.account,
        custody: custody,
        amount: d.amount.toString(),
      );
      expect(checked.amount, d.amount);
      expect(checked.digest, contribution().intentDigest);
    });

    test('an empty or zero amount is refused', () {
      for (final amount in ['', '0']) {
        expect(
          () => checkedContribution(
            prepared: contribution(),
            account: d.account,
            custody: custody,
            amount: amount,
          ),
          refusedWith('no amount was asked for'),
        );
      }
    });

    test('a digest that is not the checked intent\'s is refused', () {
      // A harmless "contribute to this room" intent next to the digest of a
      // transfer of the wallet to another address.
      final shown = contribution();
      final transfer = d.intent
        ..type = finance.IntentType.INTENT_TYPE_TRANSFER
        ..destination = finance.ValueLocation(
          kind: finance.LocationKind.LOCATION_KIND_USER_ACCOUNT,
          address: Uint8List(20)..[19] = 0x66,
        );
      final other = sdkIntentOf(transfer).digest();
      final p = shown.deepCopy()
        ..intentDigest = other
        ..call.intentDigest = other;
      expect(
        () => checkedContribution(
          prepared: p,
          account: d.account,
          custody: custody,
          amount: d.amount.toString(),
        ),
        refusedWith('the digest is not the prepared intent\'s'),
      );
    });

    test('an intent with no account, or another, is refused', () {
      for (final from in [<int>[], Uint8List(20)..[0] = 0x01]) {
        final intent = contribution().financialIntent.deepCopy()
          ..account = from;
        // An intent with no account has no digest of its own; it rides next
        // to the shown one.
        final digest = from.isEmpty
            ? contribution().intentDigest
            : sdkIntentOf(intent).digest();
        final p = settlement.PrepareAccountCallResponse(
          intentDigest: digest,
          financialIntent: intent,
          call: settlement.AccountCall(
            address: d.account,
            kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_CONTRIBUTE,
            intentDigest: digest,
          ),
        );
        expect(
          () => checkedContribution(
            prepared: p,
            account: d.account,
            custody: custody,
            amount: d.amount.toString(),
          ),
          throwsA(isA<SigningRefused>()),
        );
      }
    });
  });

  group('settlement asks to retry', () {
    test('an account being brought up to date is a plain retry message', () {
      final e = connect.ConnectException(
        connect.Code.unavailable,
        "settlement: the member's account in this room is being brought up "
        'to date; try again shortly (SettleAgain())',
      );
      expect(isAccountCatchingUp(e), isTrue);
      expect(stawiErrorMessage(e), accountCatchingUpMessage);
      expect(
        accountCatchingUpMessage,
        'Your account is being brought up to date; try again shortly',
      );
    });

    test('other unavailable answers stay unreachable', () {
      final e = connect.ConnectException(connect.Code.unavailable, 'down');
      expect(isAccountCatchingUp(e), isFalse);
      expect(stawiErrorMessage(e), 'Stawi is unreachable; try again shortly');
    });
  });
}
