import 'dart:math';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/domain/rotation.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi/features/stawi/domain/stawi_money.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

void main() {
  const week = 7 * 86400;
  const day = 86400;

  group('the SDK\'s rotation documents are Go\'s (stawi v0.2.7)', () {
    for (final v in GoRotationVector.load()) {
      test(v.name, () {
        final args = (
          custody: v.custody,
          cycleId: v.cycleId,
          order: v.order,
          pot: v.pot,
          firstPeriod: v.firstPeriod,
        );
        expect(
          openCyclePayload(
            custody: args.custody,
            cycleId: args.cycleId,
            order: args.order,
            pot: args.pot,
            firstPeriod: args.firstPeriod,
          ),
          v.payload,
        );
        expect(
          openCyclePayloadHash(
            custody: args.custody,
            cycleId: args.cycleId,
            order: args.order,
            pot: args.pot,
            firstPeriod: args.firstPeriod,
          ),
          v.payloadHash,
        );
        for (final (k, id) in v.turnIds.indexed) {
          expect(rotationTurnId(cycleId: v.cycleId, turn: k), id);
        }
      });
    }
  });

  group('checkedRotation', () {
    final v = GoRotationVector.named('three members');
    // A weekly clock on which period 3 is the first to begin once a vote of
    // 3 days, a 1-day timelock and settlement's hour can apply.
    final now = DateTime.utc(2026, 10, 20, 12);
    final nowS = now.millisecondsSinceEpoch ~/ 1000;
    const lead = 3 * day + day + 3600;
    final epoch = nowS + lead - (2.5 * week).round();
    finance.RoomPolicy policy({int? epochStart, int periodSeconds = week}) =>
        finance.RoomPolicy(
          periodModel: finance.PeriodModel(
            periodSeconds: Int64(periodSeconds),
            epochStart: Int64(epochStart ?? epoch),
          ),
          governance: finance.Governance(
            standard: finance.Threshold(
              votingPeriodSeconds: Int64(3 * day),
              timelockSeconds: Int64(day),
            ),
          ),
        );
    settlement.PrepareRoomCallResponse prepared(settlement.RoomRotation r) =>
        settlement.PrepareRoomCallResponse(
          call: settlement.RoomCall(rotation: r),
        );
    final rotation = v.rotation(epochStart: epoch, periodSeconds: week);
    final contribution = BigInt.from(10000000);

    test('Go\'s cycle is the one chosen: order, pot, room clock, first turn '
        'once the vote can apply', () {
      final r = checkedRotation(
        prepared: prepared(rotation),
        order: v.order,
        contribution: contribution,
        inForce: policy(),
        now: now,
      );
      expect(r.firstPeriod, 3);
      expect(
        openCyclePayloadHash(
          custody: v.custody,
          cycleId: r.cycleId,
          order: r.order,
          pot: BigInt.parse(r.pot),
          firstPeriod: r.firstPeriod,
        ),
        v.payloadHash,
      );
      expect(
        rotationTurnStarts(r, 0),
        DateTime.fromMillisecondsSinceEpoch(
          (epoch + 3 * week) * 1000,
          isUtc: true,
        ),
      );
    });

    test('a chosen start date: the first period at or after it', () {
      final startsAt = DateTime.fromMillisecondsSinceEpoch(
        (epoch + 2 * week + 1) * 1000,
        isUtc: true,
      );
      expect(
        checkedRotation(
          prepared: prepared(rotation),
          order: v.order,
          contribution: contribution,
          inForce: policy(),
          now: now,
          startsAt: startsAt,
        ).firstPeriod,
        3,
      );
      // Period 3 is not the first on or after the start of period 3 - 1.
      expect(
        () => checkedRotation(
          prepared: prepared(rotation),
          order: v.order,
          contribution: contribution,
          inForce: policy(),
          now: now,
          startsAt: DateTime.fromMillisecondsSinceEpoch(
            (epoch + week) * 1000,
            isUtc: true,
          ),
        ),
        throwsA(isA<SigningRefused>()),
      );
    });

    test('refuses another order, pot, clock, start or no cycle', () {
      void refused(
        settlement.PrepareRoomCallResponse p, {
        List<Uint8List>? order,
        BigInt? c,
        finance.RoomPolicy? inForce,
      }) => expect(
        () => checkedRotation(
          prepared: p,
          order: order ?? v.order,
          contribution: c ?? contribution,
          inForce: inForce ?? policy(),
          now: now,
        ),
        throwsA(isA<SigningRefused>()),
      );

      refused(prepared(rotation), order: v.order.reversed.toList());
      refused(prepared(rotation), order: v.order.sublist(0, 2));
      refused(prepared(rotation), c: BigInt.from(9000000));
      refused(prepared(rotation), inForce: policy(periodSeconds: day));
      refused(prepared(rotation), inForce: policy(epochStart: epoch + 1));
      refused(prepared(rotation.deepCopy()..firstPeriod = 4));
      refused(prepared(rotation.deepCopy()..firstPeriod = 2));
      refused(prepared(rotation.deepCopy()..cycleId = Uint8List(32)));
      refused(settlement.PrepareRoomCallResponse());
      // Dues of 9 a member, but a pot of 30 for three: the pot is refused.
      refused(
        prepared(rotation.deepCopy()..memberDues = '9000000'),
        c: BigInt.from(9000000),
      );
    });

    test('the contribution is exactly the group\'s dues as settlement read '
        'them (member_dues); with no fixed dues there is no rotation', () {
      settlement.RoomRotation dues(String d) =>
          rotation.deepCopy()..memberDues = d;
      final usdc = StawiAsset.fromInfo(
        finance.AssetInfo(assetId: 'USDC.146', symbol: 'USDC', decimals: 6),
      );
      expect(
        () => checkedRotation(
          prepared: prepared(dues('12000000')),
          order: v.order,
          contribution: contribution,
          inForce: policy(),
          now: now,
          format: (u) => formatUnits(u, usdc),
        ),
        throwsA(
          isA<RotationDuesMismatch>()
              .having((e) => e.memberDues, 'memberDues', BigInt.from(12000000))
              .having((e) => e.reason, 'reason', contains('12.00')),
        ),
      );
      for (final empty in ['', '0', 'x']) {
        expect(
          () => checkedRotation(
            prepared: prepared(dues(empty)),
            order: v.order,
            contribution: contribution,
            inForce: policy(),
            now: now,
          ),
          throwsA(
            isA<SigningRefused>()
                .having(
                  (e) => e,
                  'not a mismatch',
                  isNot(isA<RotationDuesMismatch>()),
                )
                .having((e) => e.reason, 'reason', contains('not one fixed')),
          ),
          reason: 'member_dues "$empty"',
        );
      }
    });
  });

  group('the exact contribution (GetRotation pay_now)', () {
    final usdc = StawiAsset.fromInfo(
      finance.AssetInfo(assetId: 'USDC.146', symbol: 'USDC', decimals: 6),
    );
    final me = Uint8List(20)..[0] = 1;
    final other = Uint8List(20)..[0] = 2;
    finance.RotationMember m(Uint8List a, String? payNow) =>
        finance.RotationMember(
          account: a,
          payNow: payNow == null
              ? null
              : finance.Money(assetId: 'USDC.146', amount: payNow),
        );

    test('is my own member row\'s pay_now', () {
      final cycle = finance.RotationCycle(
        members: [m(other, '1'), m(me, '10500000')],
      );
      expect(rotationPayNow(cycle, [me]), BigInt.from(10500000));
      expect(rotationPayNow(cycle, [Uint8List(20)]), isNull);
      expect(
        rotationPayNow(finance.RotationCycle(members: [m(me, null)]), [me]),
        isNull,
        reason: 'not read (include_dues)',
      );
    });

    test('anything but exactly pay_now is refused, and nothing when paid '
        'up', () {
      final exact = BigInt.from(10500000);
      expect(exactContributionProblem(exact, exact, usdc), isNull);
      expect(
        exactContributionProblem(BigInt.from(10000000), exact, usdc),
        contains('Pay exactly 10.50 USDC'),
      );
      expect(
        exactContributionProblem(BigInt.from(11000000), exact, usdc),
        contains('Pay exactly'),
      );
      expect(
        exactContributionProblem(BigInt.one, BigInt.zero, usdc),
        contains('paid up'),
      );
    });
  });

  test('the rotation proposal names the members in order, their '
      'contribution and no start', () {
    final v = GoRotationVector.named('three members');
    final picks = [
      for (final (i, a) in v.order.indexed)
        RotationPick(
          memberId: 'm$i',
          profileId: 'p$i',
          name: ['Amina', 'Baraka', 'Chena'][i],
          account: a,
        ),
    ];
    final asset = StawiAsset.fromInfo(
      finance.AssetInfo(assetId: 'USDC.146', symbol: 'USDC', decimals: 6),
    );
    final req = proposeRotationRequest(
      order: picks,
      contribution: BigInt.from(10000000),
      inForce: finance.PolicyVersion(),
      asset: asset,
    );
    expect(req.kind, settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE);
    final terms = req.params!.propose.rotation;
    expect([for (final m in terms.members) m.account], v.order);
    expect(terms.contribution, '10000000');
    expect(terms.pot, isEmpty);
    expect(terms.hasStartsAt(), isFalse);
    expect(req.lines, contains(('Each turn receives', '30.00 USDC')));
    expect(req.lines, contains(('Turn 2', 'Baraka')));
    expect(
      () => proposeRotationRequest(
        order: picks.sublist(0, 1),
        contribution: BigInt.one,
        inForce: finance.PolicyVersion(),
        asset: asset,
      ),
      throwsArgumentError,
    );
  });

  test('candidates are ACTIVE members with an account, by chat name', () {
    final a = Uint8List(20)..[19] = 1;
    final picks = rotationCandidates(
      [(profileId: 'p1', name: 'Amina')],
      [
        finance.Member(
          memberId: 'm1',
          profileId: 'p1',
          accountAddress: a,
          state: finance.MemberState.MEMBER_STATE_ACTIVE,
        ),
        finance.Member(
          memberId: 'm2',
          profileId: 'p2',
          accountAddress: Uint8List(20)..[19] = 2,
          state: finance.MemberState.MEMBER_STATE_SUSPENDED,
        ),
        finance.Member(
          memberId: 'm3',
          profileId: 'p3',
          state: finance.MemberState.MEMBER_STATE_ACTIVE,
        ),
      ],
    );
    expect([for (final p in picks) (p.memberId, p.name)], [('m1', 'Amina')]);
  });

  test('a shuffle keeps every member once', () {
    final order = List.generate(10, (i) => i);
    final shuffled = shuffledOrder(order, Random(7));
    expect(shuffled.toSet(), order.toSet());
    expect(shuffled, isNot(order));
  });

  test('RotationStatus: now, next, payouts, late and paid up', () {
    final a = Uint8List(20)..[19] = 1;
    final b = Uint8List(20)..[19] = 2;
    final c = Uint8List(20)..[19] = 3;
    final s = RotationStatus(
      finance.RotationCycle(
        state: finance.RotationCycleState.ROTATION_CYCLE_STATE_RUNNING,
        currentTurn: 1,
        turns: [
          finance.RotationTurn(
            turn: 0,
            account: a,
            state: finance.RotationTurnState.ROTATION_TURN_STATE_PAID,
          ),
          finance.RotationTurn(
            turn: 1,
            account: b,
            state: finance.RotationTurnState.ROTATION_TURN_STATE_WAITING,
          ),
          finance.RotationTurn(
            turn: 2,
            account: c,
            state: finance.RotationTurnState.ROTATION_TURN_STATE_UPCOMING,
          ),
        ],
        members: [
          finance.RotationMember(
            account: a,
            dues: finance.MemberDues(
              standing: finance.MemberDuesStanding.MEMBER_DUES_STANDING_CURRENT,
            ),
          ),
          finance.RotationMember(account: b, turn: 1, late: true),
        ],
      ),
    );
    expect(s.current!.account, b);
    expect(s.next!.account, c);
    expect(s.payouts.single.account, a);
    expect(s.late.single.account, b);
    expect(s.paidUp(s.cycle.members.first), isTrue);
    expect(s.paidUp(s.cycle.members.last), isFalse);
    expect(turnStateWords(s.current!), 'Waiting on late contributions');
  });

  test('periods in words', () {
    finance.PeriodModel m(int s) =>
        finance.PeriodModel(periodSeconds: Int64(s));
    expect(periodWords(m(week)), 'week');
    expect(periodWords(m(2 * week)), '2 weeks');
    expect(periodWords(m(day)), 'day');
    expect(periodWords(m(30 * day)), '30 days');
  });

  test('a card\'s accounts are read from its data', () {
    final a = '0x${'ab' * 20}';
    final b = '0x${'cd' * 20}';
    expect(accountsOfList('$a,$b,nonsense').length, 2);
    expect(accountOf(a), hexToBytes(a));
    expect(accountOf('0x12'), isNull);
  });
}
