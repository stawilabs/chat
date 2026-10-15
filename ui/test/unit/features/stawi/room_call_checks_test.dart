import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/domain/governance_requests.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

const roomId = 'room00000000000000aa';

DateTime _at(String seconds) =>
    DateTime.fromMillisecondsSinceEpoch(int.parse(seconds) * 1000, isUtc: true);

/// The request the app builds for the act a Go vector names, from the
/// vector's inputs as the person would choose them; null for the kinds the
/// app does not offer (the SDK's own tests replay those).
GovernanceRequest? requestFor(GoRoomCallVector v) {
  String i(String k) => v.input(k);
  Uint8List b(String k) => v.inputBytes(k);
  return switch (v.builder) {
    'propose_member_action' when i('action') == '1' => proposeInviteRequest(
      account: b('subject'),
      name: 'Amina',
      expiresAt: _at(i('arg')),
    ),
    'propose_member_action' when i('action') == '5' => proposeRemovalRequest(
      account: b('subject'),
      name: 'Amina',
    ),
    'assign_role' => assignRoleRequest(
      account: b('member'),
      name: 'Amina',
      roleId: i('role_name'),
      roleName: 'Treasurer',
      capabilities: int.parse(i('capabilities')),
      validUntil: _at(i('valid_until')),
    ),
    'revoke_role' => revokeRoleRequest(
      account: b('member'),
      name: 'Amina',
      roleId: i('role_name'),
      roleName: 'Treasurer',
    ),
    'cast_vote' when i('proposal_id') == '1' => voteRequest(
      onchainProposalId: 1,
      choice: finance.VoteChoice.VOTE_CHOICE_APPROVE,
    ),
    'commit_vote' when i('proposal_id') == '1' => commitVoteRequest(
      onchainProposalId: 1,
      commitment: b('commitment'),
    ),
    'reveal_vote' when i('proposal_id') == '1' => revealVoteRequest(
      onchainProposalId: 1,
      choice: finance.VoteChoice.VOTE_CHOICE_REJECT,
      salt: b('salt'),
    ),
    'delegate' when i('scope') == '0' => delegateRequest(
      account: b('to'),
      name: 'Amina',
      until: _at(i('until')),
    ),
    'revoke_delegation' => revokeDelegationRequest,
    'cancel_principal_exit' => proposeExitCancelRequest(
      int.parse(i('cancel_target')),
    ),
    'vote_principal_exit' => votePrincipalExitRequest(
      ballotId: int.parse(i('ballot_id')),
      approve: i('approve') == 'true',
    ),
    'accept_invitation' => acceptInvitationRequest(int.parse(i('invite_id'))),
    'leave' => leaveRequest,
    'join' => joinRequest,
    'freeze' => freezeRequest(i('reason')),
    'invite' => inviteRequest(
      account: b('subject'),
      name: 'Amina',
      now: _at(i('expires_not_after'))
          .subtract(officerInviteValidity - const Duration(minutes: 5)),
    ),
    'admit' => admitRequest(account: b('subject'), name: 'Amina'),
    _ => null,
  };
}

void main() {
  // The extremes environment's chain does not fit the wire's int64.
  final vectors = GoRoomCallVector.load()
      .where((v) => !v.name.startsWith('extremes/'))
      .toList();
  String envOf(GoRoomCallVector v) => v.name.split('/').first;
  Uint8List governanceOf(String env) => vectors
      .firstWhere(
        (v) => envOf(v) == env && v.json['verifier_role'] == 'governance',
      )
      .verifier;
  RoomContracts roomOf(GoRoomCallVector v) => v.room(governanceOf(envOf(v)));
  final before = DateTime.fromMillisecondsSinceEpoch(
    1760000000 * 1000,
    isUtc: true,
  );

  Uint8List check(
    GoRoomCallVector v,
    GovernanceRequest request,
    settlement.PrepareRoomCallResponse prepared, {
    RoomContracts? room,
    bool noRoom = false,
  }) {
    final r = noRoom ? null : room ?? roomOf(v);
    return checkedRoomCall(
      prepared: prepared,
      expected: request.expected(r ?? roomOf(v), prepared),
      chatRoomId: roomId,
      account: v.member,
      room: r,
      now: before,
    );
  }

  final offered = [
    for (final v in vectors)
      if (requestFor(v) case final r?) (v, r),
  ];

  test('every room call the app signs is held to a Go vector', () {
    expect(
      offered.map((e) => e.$2.kind).toSet(),
      containsAll({
        settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE,
        settlement.RoomCallKind.ROOM_CALL_KIND_ASSIGN_ROLE,
        settlement.RoomCallKind.ROOM_CALL_KIND_REVOKE_ROLE,
        settlement.RoomCallKind.ROOM_CALL_KIND_CAST_VOTE,
        settlement.RoomCallKind.ROOM_CALL_KIND_COMMIT_VOTE,
        settlement.RoomCallKind.ROOM_CALL_KIND_REVEAL_VOTE,
        settlement.RoomCallKind.ROOM_CALL_KIND_DELEGATE,
        settlement.RoomCallKind.ROOM_CALL_KIND_REVOKE_DELEGATION,
        settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE_PRINCIPAL_EXIT,
        settlement.RoomCallKind.ROOM_CALL_KIND_VOTE_PRINCIPAL_EXIT,
        settlement.RoomCallKind.ROOM_CALL_KIND_ACCEPT_INVITATION,
        settlement.RoomCallKind.ROOM_CALL_KIND_LEAVE,
        settlement.RoomCallKind.ROOM_CALL_KIND_JOIN,
        settlement.RoomCallKind.ROOM_CALL_KIND_FREEZE,
        settlement.RoomCallKind.ROOM_CALL_KIND_INVITE,
        settlement.RoomCallKind.ROOM_CALL_KIND_ADMIT,
      }),
    );
  });

  group('the act the person chose is accepted as Go builds it', () {
    for (final (v, request) in offered) {
      test(v.name, () {
        expect(check(v, request, v.prepared(roomId)), v.digest);
      });
    }
  });

  group('a call carrying another act or proposal is refused', () {
    for (final (v, request) in offered) {
      test(v.name, () {
        final others = vectors.where(
          (o) =>
              envOf(o) == envOf(v) &&
              bytesToHex(o.typedHash) != bytesToHex(v.typedHash),
        );
        for (final o in others) {
          // Settlement names this act but hands another's call: its params,
          // typed hash and digest, under this call's kind and contract.
          expect(
            () => check(
              v,
              request,
              o.prepared(
                roomId,
                kind: v.json['room_call_kind'] as int,
                verifier: v.verifier,
              ),
            ),
            throwsA(isA<SigningRefused>()),
            reason: '${o.name} as ${v.name}',
          );
          // Or keeps this act's params and slips the other's typed hash in,
          // wrapped for the member.
          expect(
            () => check(
              v,
              request,
              v.prepared(
                roomId,
                typedHash: o.typedHash,
                digest: accountWrappedHash(v.member, v.chainId, o.typedHash),
              ),
            ),
            throwsA(isA<SigningRefused>()),
            reason: '${o.name} typed hash under ${v.name}',
          );
        }
      });
    }
  });

  test('a loan vote (CastVote FOR) under a Leave call is refused', () {
    final leave = vectors.firstWhere((v) => v.name == 'sonic_testnet/leave');
    final vote = vectors.firstWhere(
      (v) => v.name == 'sonic_testnet/cast_vote/1',
    );
    // What the device used to sign: the account wrapping of the vote's typed
    // hash, under a call that says LEAVE.
    final prepared = leave.prepared(
      roomId,
      typedHash: vote.typedHash,
      digest: accountWrappedHash(leave.member, leave.chainId, vote.typedHash),
    );
    expect(
      () => check(leave, leaveRequest, prepared),
      throwsA(
        isA<SigningRefused>().having(
          (e) => e.reason,
          'reason',
          contains('another act'),
        ),
      ),
    );
    // The same vote on the GovernanceModule, called a LEAVE.
    expect(
      () => check(
        leave,
        leaveRequest,
        vote.prepared(roomId, kind: leave.json['room_call_kind'] as int),
      ),
      throwsA(isA<SigningRefused>()),
    );
  });

  group('the room and chain come from finance, not the call', () {
    final leave = vectors.firstWhere((v) => v.name == 'anvil/leave');
    final vote = vectors.firstWhere((v) => v.name == 'anvil/cast_vote/1');
    final voteReq = requestFor(vote)!;

    test('unknown contracts refuse every call', () {
      expect(
        () => check(leave, leaveRequest, leave.prepared(roomId), noRoom: true),
        throwsA(
          isA<SigningRefused>().having(
            (e) => e.reason,
            'reason',
            roomContractsUnknownReason,
          ),
        ),
      );
      expect(
        () => check(
          vote,
          voteReq,
          vote.prepared(roomId),
          room: RoomContracts(custody: leave.custody, chainId: vote.chainId),
        ),
        throwsA(isA<SigningRefused>()),
      );
    });

    test('another room\'s contract or another chain is refused', () {
      expect(
        () => check(
          leave,
          leaveRequest,
          leave.prepared(roomId, verifier: governanceOf('anvil')),
        ),
        throwsA(isA<SigningRefused>()),
      );
      final room = roomOf(leave);
      expect(
        () => check(
          leave,
          leaveRequest,
          leave.prepared(roomId),
          room: RoomContracts(
            governance: room.governance,
            custody: room.custody,
            chainId: BigInt.from(146),
          ),
        ),
        throwsA(isA<SigningRefused>()),
      );
    });

    test('a call for another account or chat room is refused', () {
      final prepared = leave.prepared(roomId)..call.chatRoomId = 'otherroom';
      expect(
        () => check(leave, leaveRequest, prepared),
        throwsA(isA<SigningRefused>()),
      );
      expect(
        () => checkedRoomCall(
          prepared: leave.prepared(roomId),
          expected: RoomCallExpected.leave(),
          chatRoomId: roomId,
          account: Uint8List(20)..[0] = 1,
          room: roomOf(leave),
          now: before,
        ),
        throwsA(isA<SigningRefused>()),
      );
    });

    test('a passed deadline is refused', () {
      expect(
        () => checkedRoomCall(
          prepared: leave.prepared(roomId),
          expected: RoomCallExpected.leave(),
          chatRoomId: roomId,
          account: leave.member,
          room: roomOf(leave),
          now: DateTime.fromMillisecondsSinceEpoch(
            leave.deadline.toInt() * 1000,
            isUtc: true,
          ),
        ),
        throwsA(isA<SigningRefused>()),
      );
    });
  });

  group('an officer invitation', () {
    final v = vectors.firstWhere((v) => v.name == 'sonic_testnet/invite');

    test('shows the expiry the checked call carries', () {
      final request = requestFor(v)!;
      final prepared = v.prepared(roomId);
      check(v, request, prepared);
      expect(request.linesOf!(prepared), [
        ('Invitation expires', '2025-11-01 12:26 UTC'),
      ]);
    });

    test('is refused when settlement fixes an expiry far from now', () {
      final request = inviteRequest(
        account: v.inputBytes('subject'),
        name: 'Amina',
        now: _at(v.input('expires_not_after')),
      );
      expect(
        () => check(v, request, v.prepared(roomId)),
        throwsA(isA<SigningRefused>()),
      );
    });
  });

  group('a principal exit', () {
    final leave = vectors.firstWhere((v) => v.name == 'anvil/leave');
    final room = roomOf(leave);
    final destination = Uint8List(20)..[19] = 0x44;

    finance.FinancialIntent exit({List<int>? to, List<int>? from}) {
      final custody = from ?? room.custody!;
      return GoEngineCallVector.load().first.intent
        ..account = custody
        ..room = custody
        ..domain.chainId = Int64.parseInt(room.chainId.toString())
        ..source = finance.ValueLocation(
          kind: finance.LocationKind.LOCATION_KIND_ROOM_CUSTODY,
          address: custody,
          bucket: 'savings',
        )
        ..destination = finance.ValueLocation(
          kind: finance.LocationKind.LOCATION_KIND_USER_ACCOUNT,
          address: to ?? destination,
        )
        ..amount = '5000';
    }

    final request = proposePrincipalExitRequest(
      sourceBucket: 'savings',
      amount: '5000',
      memberAccount: destination,
      memberName: 'Amina',
    );
    settlement.PrepareRoomCallResponse prepared(finance.FinancialIntent i) =>
        honestRoomCall(
          settlement.PrepareRoomCallRequest(
            chatRoomId: roomId,
            kind: request.kind,
            params: request.params,
          ),
          room: room,
          signer: leave.member,
          chatRoomId: roomId,
          exitIntent: i,
        );

    test('carrying the checked exit intent is accepted', () {
      final p = prepared(exit());
      expect(check(leave, request, p), p.digest);
    });

    test('paying someone else or spending another room is refused', () {
      expect(
        () => check(leave, request, prepared(exit(to: Uint8List(20)..[0] = 9))),
        throwsA(isA<SigningRefused>()),
      );
      expect(
        () =>
            check(leave, request, prepared(exit(from: Uint8List(20)..[0] = 8))),
        throwsA(isA<SigningRefused>()),
      );
    });
  });
}
