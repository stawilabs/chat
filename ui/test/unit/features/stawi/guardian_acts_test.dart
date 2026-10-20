import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/stawi/domain/guardian_acts.dart';
import 'package:stawi/features/stawi/domain/guardian_contacts.dart';
import 'package:stawi/features/stawi/domain/intent_bridge.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

void main() {
  const request = settlement.AccountCallKind.ACCOUNT_CALL_KIND_REQUEST_RECOVERY;
  const approve = settlement.AccountCallKind.ACCOUNT_CALL_KIND_APPROVE_RECOVERY;

  group('guardian ops match stawi v0.2.6', () {
    for (final v in GoGovernanceVectors.guardianActs()) {
      test(v.name, () {
        expect(
          guardianOpHash(
            kind: v.opKind,
            newKey: v.newKey,
            round: BigInt.from(v.round),
            algorithm: v.algorithm,
          ),
          v.opHash,
        );
        expect(v.intent.authorizationId, v.opHash);
        expect(intentDigestOf(sdkIntentOf(v.intent)), v.digest);
      });
    }
  });

  test('the guardian key proof is Go\'s', () {
    final p = GoGovernanceVectors.guardianKeyProof;
    expect(
      bytesToHex0x(
        guardianKeyProofDigest(
          chainId: BigInt.from(p['chain_id'] as int),
          account: hexToBytes(p['account'] as String),
          key: hexToBytes(p['key'] as String),
          profileId: p['profile_id'] as String,
        ),
      ),
      p['digest'],
    );
  });

  group('checkedGuardianAct', () {
    final req = GoGovernanceVectors.guardianAct('request_recovery');
    final appr = GoGovernanceVectors.guardianAct('approve_recovery');

    test('signs a recovery request and an approval as Go builds them', () {
      expect(
        checkedGuardianAct(
          prepared: req.prepared(request),
          kind: request,
          guarded: req.guarded(),
          guardianKey: req.guardian,
          chainId: req.chainId,
          newKey: req.newKey,
        ),
        req.digest,
      );
      expect(
        checkedGuardianAct(
          prepared: appr.prepared(approve),
          kind: approve,
          guarded: appr.guarded(pending: true),
          guardianKey: appr.guardian,
          chainId: appr.chainId,
        ),
        appr.digest,
      );
    });

    Matcher refused() => throwsA(isA<SigningRefused>());

    test('refuses another key, account, signer, round or chain', () {
      Uint8List check(
        settlement.PrepareAccountCallResponse p, {
        settlement.GuardedAccount? guarded,
        Uint8List? newKey,
        Uint8List? guardianKey,
        BigInt? chainId,
        settlement.AccountCallKind kind = request,
      }) => checkedGuardianAct(
        prepared: p,
        kind: kind,
        guarded: guarded ?? req.guarded(),
        guardianKey: guardianKey ?? req.guardian,
        chainId: chainId ?? req.chainId,
        newKey: newKey ?? req.newKey,
      );
      // Another new key than the one the owner gave.
      expect(
        () => check(req.prepared(request), newKey: Uint8List(20)..[0] = 1),
        refused(),
      );
      // Another round (the op settlement binds is for round 0).
      expect(
        () => check(
          req.prepared(request),
          guarded: req.guarded()..recovery.round = Int64(3),
        ),
        refused(),
      );
      // Signed by another key than this phone's.
      expect(
        () => check(req.prepared(request, signer: Uint8List(20)..[0] = 9)),
        refused(),
      );
      // This phone's key is not the account's guardian.
      expect(
        () => check(req.prepared(request), guardianKey: Uint8List(20)..[0] = 9),
        refused(),
      );
      // Another chain.
      expect(
        () => check(req.prepared(request), chainId: req.chainId + BigInt.one),
        refused(),
      );
      // The intent binds another op.
      expect(
        () => check(
          req.prepared(
            request,
            intent: req.intent..authorizationId = Uint8List(32),
          ),
        ),
        refused(),
      );
      // Another kind than the one asked for.
      expect(() => check(req.prepared(approve)), refused());
      // An approval with no recovery pending.
      expect(
        () => check(
          appr.prepared(approve),
          guarded: appr.guarded(),
          kind: approve,
        ),
        refused(),
      );
    });
  });

  group('GuardedView', () {
    final v = GoGovernanceVectors.guardianAct('approve_recovery');
    test('a quiet account may have a recovery started', () {
      final g = GuardedView(v.guarded());
      expect(g.canRequest, isTrue);
      expect(g.canApprove, isFalse);
      expect(g.headline(), contains('2 of 2 guardians must agree'));
    });
    test('a pending recovery short of approvals may be approved', () {
      final g = GuardedView(v.guarded(pending: true));
      expect(g.canRequest, isFalse);
      expect(g.canApprove, isTrue);
      expect(g.newKey, v.newKey);
      expect(g.headline(), startsWith('Recovery to 0xe0e1…f2f3: 1 of 2'));
      expect(
        GuardedView(v.guarded(pending: true, approvals: 2)).canApprove,
        isFalse,
      );
    });
  });

  group('shared guardian keys', () {
    final key = hexToBytes('0x3132333435363738393a3b3c3d3e3f4041424344');
    final mine = hexToBytes('0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266');
    RoomEvent text(String id, String sender, String body, int at) => RoomEvent(
      id: id,
      roomId: 'dm',
      senderId: sender,
      type: RoomEventType.text,
      content: {'text': body},
      createdAt: at,
    );

    test('the partner\'s newest shared key is found, not mine', () {
      final events = [
        text('1', 'them', guardianKeyMessage(Uint8List(20)..[0] = 5), 1),
        text('2', 'me', guardianKeyMessage(mine), 3),
        text('3', 'them', guardianKeyMessage(key), 2),
      ];
      expect(
        offeredGuardianKey(events, mySubscriptionId: 'me', myKey: mine),
        key,
      );
    });

    test('nothing offered, or only my own key, is null', () {
      expect(
        offeredGuardianKey(
          [
            text('1', 'them', 'hello', 1),
            text('2', 'them', guardianAskMessage, 2),
            text('3', 'x', guardianKeyMessage(mine), 3),
          ],
          mySubscriptionId: 'me',
          myKey: mine,
        ),
        isNull,
      );
    });
  });
}
