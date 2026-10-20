import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/domain/account_protection.dart';
import 'package:stawi/features/stawi/domain/intent_bridge.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

void main() {
  const add = settlement.AccountCallKind.ACCOUNT_CALL_KIND_ADD_GUARDIAN;
  const contest = settlement.AccountCallKind.ACCOUNT_CALL_KIND_CONTEST_RECOVERY;
  const cancel = settlement.AccountCallKind.ACCOUNT_CALL_KIND_CANCEL_POLICY;
  final g1 = hexToBytes('0x3132333435363738393a3b3c3d3e3f4041424344');
  final g2 = hexToBytes('0x6162636465666768696a6b6c6d6e6f7071727374');

  group('managementOpHash matches stawi v0.2.5', () {
    for (final v in GoGuardianCallVector.load()) {
      test(v.name, () {
        final p = v.policy;
        expect(
          managementOpHash(
            kind: v.kind,
            policy: p == null ? null : accountPolicyFrom(p),
          ),
          v.opHash,
        );
        expect(v.intent.authorizationId, v.opHash);
        expect(intentDigestOf(sdkIntentOf(v.intent)), v.digest);
      });
    }
  });

  group('guardianSetAfter', () {
    final v = GoGuardianCallVector.named('add_second_guardian');
    test('keeps the threshold, clamped to the set', () {
      final s = v.stateWith(guardians: [g1, g2], threshold: 2);
      final after = guardianSetAfter(s, g2, add: false);
      expect(after.guardians, [g1]);
      expect(after.threshold, 1);
      expect(guardianSetAfter(s, g1, add: false).guardians, [g2]);
    });
    test('the first guardian is 1 of 1; none left is 0', () {
      final none = v.stateWith();
      expect(guardianSetAfter(none, g1, add: true).threshold, 1);
      final one = v.stateWith(guardians: [g1], threshold: 1);
      expect(guardianSetAfter(one, g1, add: false).threshold, 0);
      expect(guardianSetAfter(one, g2, add: true, requested: 9).threshold, 2);
    });
    test('refuses a guardian twice, an unknown one and the account', () {
      final one = v.stateWith(guardians: [g1], threshold: 1);
      expect(() => guardianSetAfter(one, g1, add: true), throwsFormatException);
      expect(
        () => guardianSetAfter(one, g2, add: false),
        throwsFormatException,
      );
      expect(
        () => guardianSetAfter(one, v.account, add: true),
        throwsFormatException,
      );
      expect(
        () => guardianSetAfter(one, Uint8List(20), add: true),
        throwsFormatException,
      );
    });
  });

  group('checkedGuardianSet (SET_GUARDIANS)', () {
    const set = settlement.AccountCallKind.ACCOUNT_CALL_KIND_SET_GUARDIANS;
    test('signs the guardian sets Go builds', () {
      // stawi v0.2.5's add/remove vectors propose the same op as the whole
      // set would.
      for (final (name, before, k, after, threshold) in [
        ('add_first_guardian', <Uint8List>[], 0, [g1], 1),
        ('add_second_guardian', [g1], 1, [g1, g2], 2),
        ('remove_last_guardian', [g1], 1, <Uint8List>[], 0),
      ]) {
        final v = GoGuardianCallVector.named(name);
        expect(
          checkedGuardianSet(
            prepared: v.prepared(set),
            state: v.stateWith(guardians: before, threshold: k),
            account: v.account,
            guardians: after,
            threshold: threshold,
            chainId: v.chainId,
          ),
          v.digest,
          reason: name,
        );
      }
      // stawi v0.2.6: two guardians replaced by two others, and all removed.
      for (final v in GoGovernanceVectors.setGuardians()) {
        final before = v.before;
        expect(
          checkedGuardianSet(
            prepared: v.prepared(set),
            state: v.stateWith(
              guardians: before.guardians,
              threshold: before.threshold,
            ),
            account: v.account,
            guardians: v.after.guardians,
            threshold: v.after.threshold,
            chainId: v.chainId,
          ),
          v.digest,
          reason: v.name,
        );
      }
    });

    Matcher refused(String reason) => throwsA(
      isA<SigningRefused>().having((e) => e.reason, 'reason', reason),
    );

    test('refuses another set, threshold or policy', () {
      final v = GoGuardianCallVector.named('add_second_guardian');
      final state = v.stateWith(guardians: [g1], threshold: 1);
      Uint8List check(
        settlement.PrepareAccountCallResponse p, {
        List<Uint8List>? guardians,
        int t = 2,
      }) => checkedGuardianSet(
        prepared: p,
        state: state,
        account: v.account,
        guardians: guardians ?? [g1, g2],
        threshold: t,
        chainId: v.chainId,
      );
      // The person asked for 1 of 2; the op makes it 2 of 2.
      expect(() => check(v.prepared(set), t: 1), refused(notTheGuardianChange));
      // Another order of the same guardians is another policy.
      expect(
        () => check(v.prepared(set), guardians: [g2, g1]),
        refused(notTheGuardianChange),
      );
      // A raised limit slipped into the proposed policy.
      final raised = v.policy!..periodLimit = '999999999999';
      expect(
        () => check(v.prepared(set, opPolicy: raised)),
        refused(notTheGuardianChange),
      );
      // The op is not a policy proposal.
      expect(
        () => check(v.prepared(set, opKind: ProtectionOps.cancelPolicy)),
        refused(notTheGuardianChange),
      );
      // A set the account would refuse is never signed.
      expect(
        () => check(v.prepared(set), guardians: [g1, g1]),
        refused(notTheGuardianChange),
      );
    });

    test('refuses an intent that binds another op, chain or kind', () {
      final v = GoGuardianCallVector.named('add_first_guardian');
      final other = v.intent..authorizationId = Uint8List(32);
      Uint8List check(
        settlement.PrepareAccountCallResponse p, {
        BigInt? chainId,
      }) => checkedGuardianSet(
        prepared: p,
        state: v.stateWith(),
        account: v.account,
        guardians: [g1],
        threshold: 1,
        chainId: chainId ?? v.chainId,
      );
      expect(
        () => check(v.prepared(set, intent: other)),
        refused(notTheGuardianChange),
      );
      final v2 = GoGuardianCallVector.named('add_first_guardian');
      expect(
        () => checkedGuardianSet(
          prepared: v2.prepared(set),
          state: v2.stateWith(),
          account: v2.account,
          guardians: [g1],
          threshold: 1,
          chainId: v2.chainId + BigInt.one,
        ),
        refused('the change is for another account'),
      );
      expect(
        () => checkedGuardianSet(
          prepared: v2.prepared(add),
          state: v2.stateWith(),
          account: v2.account,
          guardians: [g1],
          threshold: 1,
          chainId: v2.chainId,
        ),
        refused('settlement prepared another kind of call'),
      );
    });
  });

  group('guardian sets', () {
    final v = GoGuardianCallVector.named('add_second_guardian');
    test('replacing keeps the threshold, clamped', () {
      final s = v.stateWith(guardians: [g1, g2], threshold: 2);
      final g3 = Uint8List(20)..[19] = 3;
      final after = guardianSetReplacing(s, g1, g3);
      expect(after.guardians, [g3, g2]);
      expect(after.threshold, 2);
      expect(
        () => guardianSetReplacing(s, g1, g2),
        throwsFormatException,
        reason: 'a guardian twice',
      );
      expect(
        () => guardianSetReplacing(s, g3, g1),
        throwsFormatException,
        reason: 'not a guardian',
      );
    });
    test('the account refuses itself, zero and a bad threshold', () {
      final s = v.stateWith();
      expect(() => checkGuardianSet(s, [v.account], 1), throwsFormatException);
      expect(
        () => checkGuardianSet(s, [Uint8List(20)], 1),
        throwsFormatException,
      );
      expect(() => checkGuardianSet(s, [g1], 2), throwsFormatException);
      expect(() => checkGuardianSet(s, [g1], 0), throwsFormatException);
      expect(() => checkGuardianSet(s, [], 1), throwsFormatException);
      checkGuardianSet(s, [], 0);
      checkGuardianSet(s, [g1, g2], 1);
    });
  });

  group('checkedPlainManagementCall', () {
    test('signs a contest and a cancel as Go builds them', () {
      final c = GoGuardianCallVector.named('contest_recovery');
      expect(
        checkedPlainManagementCall(
          prepared: c.prepared(contest),
          kind: contest,
          account: c.account,
          chainId: c.chainId,
        ),
        c.digest,
      );
      final p = GoGuardianCallVector.named('cancel_policy');
      expect(
        checkedPlainManagementCall(
          prepared: p.prepared(cancel),
          kind: cancel,
          account: p.account,
          chainId: p.chainId,
        ),
        p.digest,
      );
    });

    test('refuses a cancel dressed as a contest', () {
      final p = GoGuardianCallVector.named('cancel_policy');
      expect(
        () => checkedPlainManagementCall(
          prepared: p.prepared(contest),
          kind: contest,
          account: p.account,
          chainId: p.chainId,
        ),
        throwsA(isA<SigningRefused>()),
      );
    });
  });

  group('AccountProtection', () {
    final v = GoGuardianCallVector.named('add_second_guardian');
    final device = Uint8List(20)..[0] = 0xde;
    test('a pending recovery to this phone says so', () {
      final p = AccountProtection.of(
        v.stateWith(
          guardians: [g1, g2],
          threshold: 2,
          recovery: settlement.AccountRecovery(
            state:
                settlement.AccountRecoveryState.ACCOUNT_RECOVERY_STATE_PENDING,
            newKey: device,
            approvals: Int64(1),
            approvalsRequired: Int64(2),
            executableAfter: Int64(1760259600),
            expiresAt: Int64(1760864400),
          ),
        ),
      );
      expect(p.canContest, isTrue);
      expect(
        p.headline(thisDevice: device),
        'Your guardians are moving your account to this phone: 1 of 2 '
        'approved. It can take over from 2025-10-12 09:00 UTC and lapses '
        '2025-10-19 09:00 UTC.',
      );
      expect(p.headline(), startsWith('Your guardians are recovering'));
    });

    test('a contested recovery is frozen and cannot be contested again', () {
      final p = AccountProtection.of(
        v.stateWith(
          guardianFrozen: true,
          recovery: settlement.AccountRecovery(
            state: settlement
                .AccountRecoveryState
                .ACCOUNT_RECOVERY_STATE_CONTESTED,
            approvals: Int64.ZERO,
            approvalsRequired: Int64(3),
          ),
        ),
      );
      expect(p.canContest, isFalse);
      expect(p.headline(), contains('frozen while your guardians decide'));
    });

    test('a guardian freeze and a quiet account', () {
      expect(
        AccountProtection.of(v.stateWith(guardianFrozen: true)).headline(),
        startsWith('Your guardians froze this account'),
      );
      expect(AccountProtection.of(v.stateWith()).headline(), isNull);
    });
  });
}
