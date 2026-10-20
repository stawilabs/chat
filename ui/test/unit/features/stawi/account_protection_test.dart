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
  const remove = settlement.AccountCallKind.ACCOUNT_CALL_KIND_REMOVE_GUARDIAN;
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

  group('checkedGuardianChange', () {
    test('signs adding the first guardian', () {
      final v = GoGuardianCallVector.named('add_first_guardian');
      expect(
        checkedGuardianChange(
          prepared: v.prepared(add),
          state: v.stateWith(),
          account: v.account,
          guardian: g1,
          add: true,
          chainId: v.chainId,
        ),
        v.digest,
      );
    });

    test('signs adding a second guardian with 2 of 2', () {
      final v = GoGuardianCallVector.named('add_second_guardian');
      expect(
        checkedGuardianChange(
          prepared: v.prepared(add),
          state: v.stateWith(guardians: [g1], threshold: 1),
          account: v.account,
          guardian: g2,
          add: true,
          threshold: 2,
          chainId: v.chainId,
        ),
        v.digest,
      );
    });

    test('signs removing the last guardian', () {
      final v = GoGuardianCallVector.named('remove_last_guardian');
      expect(
        checkedGuardianChange(
          prepared: v.prepared(remove),
          state: v.stateWith(guardians: [g1], threshold: 1),
          account: v.account,
          guardian: g1,
          add: false,
          chainId: v.chainId,
        ),
        v.digest,
      );
    });

    Matcher refused(String reason) => throwsA(
      isA<SigningRefused>().having((e) => e.reason, 'reason', reason),
    );

    test('refuses another guardian, threshold or policy', () {
      final v = GoGuardianCallVector.named('add_second_guardian');
      final state = v.stateWith(guardians: [g1], threshold: 1);
      Uint8List check(settlement.PrepareAccountCallResponse p, {int t = 2}) =>
          checkedGuardianChange(
            prepared: p,
            state: state,
            account: v.account,
            guardian: g2,
            add: true,
            threshold: t,
            chainId: v.chainId,
          );
      // The person asked for 1 of 2; the op makes it 2 of 2.
      expect(() => check(v.prepared(add), t: 1), refused(notTheGuardianChange));
      // A raised limit slipped into the proposed policy.
      final raised = v.policy!..periodLimit = '999999999999';
      expect(
        () => check(v.prepared(add, opPolicy: raised)),
        refused(notTheGuardianChange),
      );
      // Another guardian than the one typed.
      final other = GoGuardianCallVector.named('add_second_guardian').policy!;
      other.guardians[1] = Uint8List(20)..[19] = 9;
      expect(
        () => check(v.prepared(add, opPolicy: other)),
        refused(notTheGuardianChange),
      );
      // The op is not a policy proposal.
      expect(
        () => check(v.prepared(add, opKind: ProtectionOps.cancelPolicy)),
        refused(notTheGuardianChange),
      );
    });

    test('refuses an intent that binds another op or account', () {
      final v = GoGuardianCallVector.named('add_first_guardian');
      final other = v.intent..authorizationId = Uint8List(32);
      expect(
        () => checkedGuardianChange(
          prepared: v.prepared(add, intent: other),
          state: v.stateWith(),
          account: v.account,
          guardian: g1,
          add: true,
          chainId: v.chainId,
        ),
        refused(notTheGuardianChange),
      );
      final v2 = GoGuardianCallVector.named('add_first_guardian');
      expect(
        () => checkedGuardianChange(
          prepared: v2.prepared(add),
          state: v2.stateWith(),
          account: v2.account,
          guardian: g1,
          add: true,
          chainId: v2.chainId + BigInt.one,
        ),
        refused('the change is for another account'),
      );
      expect(
        () => checkedGuardianChange(
          prepared: v2.prepared(remove),
          state: v2.stateWith(),
          account: v2.account,
          guardian: g1,
          add: true,
          chainId: v2.chainId,
        ),
        refused('settlement prepared another kind of call'),
      );
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
