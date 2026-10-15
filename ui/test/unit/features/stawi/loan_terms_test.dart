import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/domain/loan_terms.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

const _self = finance.LoanKind.LOAN_KIND_SELF;
const _p2p = finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON;

PersonalTerms _chain(Map<String, dynamic> t) => PersonalTerms(
  n: t['n'] as int,
  everyDays: t['every_days'] as int,
  method: t['method'] as int,
  rateBps: t['rate_bps'] as int,
  lateMethod: t['late_method'] as int,
  lateBps: t['late_bps'] as int,
  lateFlat: BigInt.parse(t['late_flat'] as String),
  defaultAfterDays: t['default_after_days'] as int,
);

void main() {
  final vectors =
      ((jsonDecode(
                File('test/fixtures/stawi/go_personal_terms.json')
                    .readAsStringSync(),
              ) as Map<String, dynamic>)['terms']
              as List)
          .cast<Map<String, dynamic>>();

  test('every preset gives the instalments and spacing it names', () {
    const want = {
      LoanPreset.weekly4: (4, 7),
      LoanPreset.fortnightly2: (2, 14),
      LoanPreset.fortnightly4: (4, 14),
      LoanPreset.monthly3: (3, 30),
      LoanPreset.monthly6: (6, 30),
      LoanPreset.monthly12: (12, 30),
    };
    expect(want.keys, LoanPreset.values);
    for (final MapEntry(key: p, value: (n, every)) in want.entries) {
      for (final kind in [_self, _p2p]) {
        final t = LoanTerms.preset(p, rateBps: 100, kind: kind);
        expect((t.instalments, t.everyDays), (n, every), reason: p.name);
        expect(t.sdk.n, n);
        expect(t.sdk.everyDays, every);
        expect(t.sdk.method, 0, reason: 'flat');
        expect(t.sdk.rateBps, 100);
      }
    }
  });

  test('a loan to oneself carries no late charge', () {
    final t = LoanTerms.preset(LoanPreset.weekly4, rateBps: 100, kind: _self);
    expect(t.proto.latePenalty, finance.PenaltyMethod.PENALTY_METHOD_NONE);
    expect(t.sdk.lateMethod, 0);
    expect(t.sdk.lateBps, 0);
    expect(t.hasLateCharge, isFalse);
    expect(t.validate(BigInt.from(200000000), _self), isNull);
  });

  test('a loan between people is 5% of the shortfall late, default after 30 '
      'days', () {
    final t = LoanTerms.preset(
      LoanPreset.fortnightly4,
      rateBps: 250,
      kind: _p2p,
    );
    expect(
      t.proto.latePenalty,
      finance.PenaltyMethod.PENALTY_METHOD_PERCENT_OF_SHORTFALL,
    );
    expect(t.sdk.lateMethod, 2);
    expect(t.sdk.lateBps, 500);
    expect(t.sdk.defaultAfterDays, 30);
    expect(t.validate(BigInt.from(300000000), _p2p), isNull);
  });

  test('interest beyond the amount is refused', () {
    final t = LoanTerms.preset(LoanPreset.monthly12, rateBps: 900, kind: _p2p);
    expect(
      t.validate(BigInt.from(100), _p2p),
      'Interest would be more than the amount',
    );
    expect(() => t.sdk, throwsFormatException);
  });

  test('what the LoanBook refuses is named before anything is prepared', () {
    final p2p = LoanTerms.preset(LoanPreset.weekly4, rateBps: 100, kind: _p2p);
    expect(p2p.validate(BigInt.zero, _p2p), 'Enter an amount');
    expect(
      p2p.validate(BigInt.from(100), _self),
      'A loan to yourself carries no late charge',
    );
    final flat = LoanTerms(
      finance.PersonalLoanTerms()
        ..mergeFromMessage(p2p.proto)
        ..latePenalty = finance.PenaltyMethod.PENALTY_METHOD_FLAT
        ..lateFlat = '26',
    );
    expect(
      flat.validate(BigInt.from(100), _p2p),
      'The late charge is more than one instalment',
    );
    expect(flat.validate(BigInt.from(104), _p2p), isNull);
    final every = LoanTerms(
      finance.PersonalLoanTerms()
        ..mergeFromMessage(p2p.proto)
        ..everyDays = 10,
    );
    expect(every.validate(BigInt.from(100), _p2p), isNotNull);
  });

  test('terms convert to and from the SDK as Go converts them', () {
    var compared = 0;
    for (final v in vectors) {
      final proto = finance.PersonalLoanTerms()
        ..mergeFromProto3Json(v['proto']);
      final chain = v['chain'] as Map<String, dynamic>?;
      if (chain == null) {
        expect(
          () => LoanTerms(proto).sdk,
          throwsFormatException,
          reason: v['name'] as String,
        );
        continue;
      }
      final x = _chain(chain);
      expect(LoanTerms(proto).sdk, x, reason: v['name'] as String);
      expect(LoanTerms.fromSdk(x).sdk, x, reason: v['name'] as String);
      expect(
        LoanTerms.fromSdk(x).proto.toProto3Json(),
        v['round_trip'],
        reason: v['name'] as String,
      );
      compared++;
    }
    expect(compared, greaterThanOrEqualTo(5));
  });

  test('the late rule never calls the day after the due date free', () {
    for (final kind in [_self, _p2p]) {
      final rule = LoanTerms.preset(
        LoanPreset.monthly3,
        rateBps: 100,
        kind: kind,
      ).lateRule;
      expect(rule.toLowerCase(), isNot(contains('free')));
      expect(rule, contains('within a day of its due date is late'));
      expect(rule, contains('30 days after a missed due date'));
    }
    expect(
      LoanTerms.preset(LoanPreset.monthly3, rateBps: 100, kind: _p2p).lateRule,
      contains('the late charge counts from the due date'),
    );
    expect(
      LoanTerms.preset(LoanPreset.monthly3, rateBps: 100, kind: _self).lateRule,
      contains('no late charge'),
    );
  });
}
