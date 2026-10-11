import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:antinvestor_api_authentication/antinvestor_api_authentication.dart'
    as authentication;
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/data/stawi_binding.dart';
import 'package:stawi/features/stawi/data/stawi_custody.dart';
import 'package:stawi/features/stawi/data/stawi_finance_service.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/data/stawi_room_service.dart';
import 'package:stawi/features/stawi/data/stawi_timeline_providers.dart';
import 'package:stawi/features/stawi/domain/governance_requests.dart';
import 'package:stawi/features/stawi/domain/secret_ballot.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_api_chat/stawi_api_chat.dart' as pb;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

const roomId = 'room00000000000000aa';

void main() {
  late FakeConnectTransport transport;
  setUp(() => transport = FakeConnectTransport());

  test('vote commitments match Go stawi.Commitment', () {
    final vectors =
        (jsonDecode(
                  File(
                    'test/fixtures/stawi/go_vote_commitments.json',
                  ).readAsStringSync(),
                )
                as List)
            .cast<Map<String, dynamic>>();
    expect(vectors, hasLength(5));
    for (final v in vectors) {
      expect(
        bytesToHex0x(
          voteCommitment(
            choice: v['choice'] as int,
            salt: hexToBytes(v['salt'] as String),
            proposalId: BigInt.parse(v['proposal_id'] as String),
            member: hexToBytes(v['member'] as String),
          ),
        ),
        v['commitment'],
      );
    }
  });

  group('secret ballot', () {
    // A digest wrapped for the account by Go (see stawi_services_test).
    final wrapped = GoSignedCallVectors.load().accountWrappedHashes.firstWhere(
      (v) => v['name'] == 'anvil_0/seq' && v['chain_id'] == '146',
    );
    final account = hexToBytes(wrapped['account'] as String);
    late MemoryDeviceKeyVault ballotVault;
    late RecordingActSender sender;

    StawiRoomService service() => StawiRoomService(
      rooms: settlement.RoomServiceClient(transport),
      keys: DeviceKeyStore(vaultWith('p1', anvilKey)),
      identity: () async => identityWith('p1', account),
      send: sender.call,
      ballots: SecretBallotStore(ballotVault),
    );

    setUp(() {
      ballotVault = MemoryDeviceKeyVault();
      sender = RecordingActSender();
      transport.on(
        settlement.RoomService.prepareRoomCall,
        (req) => settlement.PrepareRoomCallResponse(
          callId: 'call0000000000000001',
          digest: hexToBytes(wrapped['wrapped'] as String),
          signer: account,
          call: settlement.RoomCall(
            chainId: Int64(146),
            chatRoomId: roomId,
            kind: req.kind,
            typedHash: hexToBytes(wrapped['hash'] as String),
            requiresSignature: true,
          ),
        ),
      );
    });

    test('commits only the commitment, sealed on the device', () async {
      await service().commitSecretVote(
        roomId: roomId,
        onchainProposalId: 9,
        choice: finance.VoteChoice.VOTE_CHOICE_REJECT,
      );
      final sealed = (await SecretBallotStore(ballotVault).load(roomId, 9))!;
      expect(sealed.choice, finance.VoteChoice.VOTE_CHOICE_REJECT);
      expect(sealed.member, account);

      final prepare = transport
          .requestsTo(settlement.RoomService.prepareRoomCall)
          .single;
      expect(prepare.kind, settlement.RoomCallKind.ROOM_CALL_KIND_COMMIT_VOTE);
      expect(prepare.account, account);
      expect(prepare.params.vote.onchainProposalId, Int64(9));
      expect(
        prepare.params.vote.commitment,
        voteCommitment(
          choice: 2,
          salt: sealed.salt,
          proposalId: BigInt.from(9),
          member: account,
        ),
      );
      expect(prepare.params.vote.hasSalt(), isFalse);
      expect(prepare.params.vote.hasChoice(), isFalse);
      expect(sender.sent.single.content['kind'], 'COMMIT_VOTE');
    });

    test('reveals the sealed choice and salt', () async {
      final sealed = await SecretBallotStore(ballotVault).seal(
        roomId: roomId,
        proposalId: 9,
        choice: finance.VoteChoice.VOTE_CHOICE_APPROVE,
        member: account,
      );
      await service().revealSecretVote(roomId: roomId, onchainProposalId: 9);
      final prepare = transport
          .requestsTo(settlement.RoomService.prepareRoomCall)
          .single;
      expect(prepare.kind, settlement.RoomCallKind.ROOM_CALL_KIND_REVEAL_VOTE);
      expect(prepare.params.vote.salt, sealed.salt);
      expect(
        prepare.params.vote.choice,
        finance.VoteChoice.VOTE_CHOICE_APPROVE,
      );
      expect(sender.sent.single.content['kind'], 'REVEAL_VOTE');
    });

    test('cannot reveal a vote this device never sealed', () async {
      await expectLater(
        service().revealSecretVote(roomId: roomId, onchainProposalId: 9),
        throwsA(isA<StawiUnavailable>()),
      );
      expect(transport.calls, isEmpty);
    });
  });

  group('governance requests', () {
    test('principal exit, freeze and roles carry their terms', () {
      final exit = proposePrincipalExitRequest(
        sourceBucket: 'savings',
        amount: '5000',
        memberProfileId: 'p2',
        memberName: 'Amina',
      );
      expect(
        exit.kind,
        settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE_PRINCIPAL_EXIT,
      );
      expect(exit.params!.principalExit.spend.sourceBucket, 'savings');
      expect(exit.params!.principalExit.spend.amount, '5000');
      expect(exit.params!.principalExit.spend.member.profileId, 'p2');
      expect(
        () => proposePrincipalExitRequest(
          sourceBucket: 'savings',
          amount: '5000',
          memberProfileId: 'p2',
          bucket: 'reserve',
        ),
        throwsArgumentError,
      );
      final expiry = inviteExpiryAfter(
        14,
        now: DateTime.utc(2026, 10, 11, 18, 30),
      );
      expect(expiry, DateTime.utc(2026, 10, 25, 18, 30));
      expect(inviteExpiryLabel(expiry), '2026-10-25 18:30');
      expect(
        inviteExpiryFromSeconds(Int64(expiry.millisecondsSinceEpoch ~/ 1000)),
        expiry,
      );
      expect(inviteExpiryFromSeconds(Int64.ZERO), isNull);
      expect(() => inviteExpiryAfter(0), throwsArgumentError);
      expect(() => inviteExpiryAfter(maxInviteDays), throwsArgumentError);

      final invite = proposeInviteRequest(
        profileId: 'p2',
        name: 'Amina',
        expiresAt: expiry,
      );
      expect(invite.kind, settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE);
      final terms = invite.params!.propose.memberAction;
      expect(terms.action, finance.RoomMemberAction.ROOM_MEMBER_ACTION_INVITE);
      expect(terms.subject.profileId, 'p2');
      expect(terms.arg, Int64(expiry.millisecondsSinceEpoch ~/ 1000));
      expect(invite.summary, contains('2026-10-25 18:30 UTC'));
      settlement.PrepareRoomCallResponse preparedWith(Int64 seconds) =>
          settlement.PrepareRoomCallResponse(
            call: settlement.RoomCall(inviteExpiry: seconds),
          );
      checkProposedInviteExpiry(preparedWith(terms.arg), expiresAt: expiry);
      expect(
        () => checkProposedInviteExpiry(
          preparedWith(terms.arg + 1),
          expiresAt: expiry,
        ),
        throwsA(isA<SigningRefused>()),
      );
      final execute = executeInviteParams(
        onchainProposalId: 3,
        profileId: 'p2',
      ).execute;
      expect(execute.onchainProposalId, Int64(3));
      expect(execute.memberAction.action, terms.action);
      expect(execute.memberAction.subject, terms.subject);
      expect(execute.memberAction.arg, Int64.ZERO, reason: 'the voted expiry');
      expect(
        () => executeInviteParams(onchainProposalId: 0, profileId: 'p2'),
        throwsArgumentError,
      );
      expect(queueProposalParams(3).execute.onchainProposalId, Int64(3));
      expect(queueProposalParams(3).execute.hasMemberAction(), isFalse);

      final cancel = proposeExitCancelRequest(6);
      expect(cancel.params!.principalExit.cancelTarget, Int64(6));
      expect(cancel.params!.principalExit.hasSpend(), isFalse);
      expect(executeExitParams(6).principalExit.ballotId, Int64(6));

      final vote = votePrincipalExitRequest(ballotId: 4, approve: false);
      expect(vote.params!.principalExit.ballotId, Int64(4));
      expect(vote.params!.principalExit.approve, isFalse);

      final freeze = freezeRequest('  treasurer lost phone ');
      expect(freeze.kind, settlement.RoomCallKind.ROOM_CALL_KIND_FREEZE);
      expect(freeze.params!.freeze_7.reason, 'treasurer lost phone');
      expect(() => freezeRequest(' '), throwsArgumentError);

      final assign = assignRoleRequest(
        profileId: 'p2',
        name: 'Amina',
        roleId: 'treasurer',
        roleName: 'Treasurer',
        capabilities: RoomCapability.invite | RoomCapability.lend,
      );
      expect(assign.kind, settlement.RoomCallKind.ROOM_CALL_KIND_ASSIGN_ROLE);
      expect(assign.params!.role.member.profileId, 'p2');
      expect(assign.params!.role.capabilities, 1 | 32);
      expect(assign.params!.role.assign, isTrue);
      expect(assign.summary, 'Propose Amina as Treasurer');

      final revoke = revokeRoleRequest(
        profileId: 'p2',
        name: 'Amina',
        roleId: 'treasurer',
        roleName: 'Treasurer',
      );
      expect(revoke.kind, settlement.RoomCallKind.ROOM_CALL_KIND_REVOKE_ROLE);
      expect(revoke.params!.role.capabilities, 0);
    });
  });

  group('rules-engine calls', () {
    StawiRoomService service() => StawiRoomService(
      rooms: settlement.RoomServiceClient(transport),
      keys: DeviceKeyStore(MemoryDeviceKeyVault()),
      identity: () async => identityWith('p1', Uint8List(20)),
      send: RecordingActSender().call,
    );

    test('are prepared and submitted to settlement unsigned', () async {
      transport
        ..on(
          settlement.RoomService.prepareRoomCall,
          (req) => settlement.PrepareRoomCallResponse(
            callId: 'call000000000000000e',
            call: settlement.RoomCall(kind: req.kind),
          ),
        )
        ..on(
          settlement.RoomService.submitRoomCall,
          (req) => settlement.SubmitRoomCallResponse(
            call: settlement.RoomCall(
              callId: req.callId,
              state: settlement.RoomCallState.ROOM_CALL_STATE_SUBMITTED,
            ),
          ),
        );
      final call = await service().pushEngineCall(
        roomId: roomId,
        kind: settlement.RoomCallKind.ROOM_CALL_KIND_COLLECT,
        memberProfileId: 'p1',
      );
      expect(call.state, settlement.RoomCallState.ROOM_CALL_STATE_SUBMITTED);
      final prepare = transport
          .requestsTo(settlement.RoomService.prepareRoomCall)
          .single;
      expect(prepare.params.engine.member.profileId, 'p1');
      final submit = transport
          .requestsTo(settlement.RoomService.submitRoomCall)
          .single;
      expect(submit.hasSignature(), isFalse);
    });

    test('refuse a call that turns out to need a signature', () async {
      transport.on(
        settlement.RoomService.prepareRoomCall,
        (req) => settlement.PrepareRoomCallResponse(
          callId: 'call000000000000000e',
          call: settlement.RoomCall(kind: req.kind, requiresSignature: true),
        ),
      );
      await expectLater(
        service().pushEngineCall(
          roomId: roomId,
          kind: settlement.RoomCallKind.ROOM_CALL_KIND_SETTLE,
          memberProfileId: 'p1',
        ),
        throwsA(isA<SigningRefused>()),
      );
      expect(
        transport.requestsTo(settlement.RoomService.submitRoomCall),
        isEmpty,
      );
      expect(
        () => service().pushEngineCall(
          roomId: roomId,
          kind: settlement.RoomCallKind.ROOM_CALL_KIND_INVITE,
        ),
        throwsArgumentError,
      );
    });
  });

  group('genesis session proof', () {
    final genesis = GoGenesisVector.load().firstWhere(
      (v) => v.name == 'settlement_default',
    );

    test('is issued for this device key and sent as UTF-8 bytes', () async {
      transport
        ..on(
          authentication.AuthenticationService.issueGenesisSessionProof,
          (req) => authentication.IssueGenesisSessionProofResponse(
            token: 'proof.${req.pubkeyHash}',
          ),
        )
        ..on(
          settlement.AccountService.prepareDeployAccount,
          (req) => genesis.prepared,
        )
        ..on(
          settlement.AccountService.deployAccount,
          (req) => settlement.DeployAccountResponse(genesisState: 'PENDING'),
        );
      final service = StawiAccountService(
        accounts: settlement.AccountServiceClient(transport),
        keys: DeviceKeyStore(vaultWith('p1', genesis.devicePrivateKey)),
        proofs: authenticationSessionProofs(
          authentication.AuthenticationServiceClient(transport),
        ),
        identity: () async => genesis.identity('p1'),
      );
      await service.deploy();

      final issue = transport
          .requestsTo(
            authentication.AuthenticationService.issueGenesisSessionProof,
          )
          .single;
      final pubkeyHash = genesis.json['pubkey_hash'] as String;
      expect(issue.pubkeyHash, pubkeyHash.substring(2));
      expect(issue.deviceKeyId, genesis.json['device']);
      final deploy = transport
          .requestsTo(settlement.AccountService.deployAccount)
          .single;
      expect(
        utf8.decode(deploy.sessionProof),
        'proof.${pubkeyHash.substring(2)}',
      );
      expect(bytesToHex0x(deploy.deviceSignature), genesis.signature);
    });
  });

  group('room binding', () {
    final custody = '0x${'c0' * 20}';

    test('chat Room.stawi drives the phase and the custody', () async {
      transport.on(
        pb.ChatService.getRoom,
        (req) => pb.GetRoomResponse(
          room: pb.Room(
            id: req.roomId,
            stawi: req.roomId == roomId
                ? pb.StawiRoomBinding(
                    state: pb.StawiRoomState.STAWI_ROOM_STATE_BOUND,
                    custodyAddress: custody,
                    chainId: Int64(146),
                  )
                : null,
          ),
        ),
      );
      final read = chatBindingReader(pb.ChatServiceClient(transport));
      final binding = (await read(roomId))!;
      expect(binding.isBound, isTrue);
      expect(binding.chainId, 146);
      expect(phaseOfBinding(binding), StawiRoomPhase.active);
      expect(await read('plainroom000000000000'), isNull);
      expect(phaseOfBinding(null), StawiRoomPhase.chatOnly);

      expect(await bindingCustodySource(read)(roomId), hexToBytes(custody));
      expect(await bindingCustodySource(read)('plainroom000000000000'), isNull);
    });

    test('pending and failed bindings', () {
      expect(
        phaseOfBinding(
          StawiBinding.fromProto(
            pb.StawiRoomBinding(
              state: pb.StawiRoomState.STAWI_ROOM_STATE_PENDING,
              genesisId: 'gen1',
            ),
          ),
        ),
        StawiRoomPhase.awaitingSignatures,
      );
      final failed = StawiBinding.fromProto(
        pb.StawiRoomBinding(state: pb.StawiRoomState.STAWI_ROOM_STATE_FAILED),
      );
      expect(phaseOfBinding(failed), StawiRoomPhase.chatOnly);
      expect(failed.custody, isNull);
    });
  });

  test('finance read model: roles, loans and member balances', () async {
    transport
      ..on(
        finance.RoomService.getPolicy,
        (req) => finance.GetPolicyResponse(
          policyVersion: finance.PolicyVersion(
            constitution: finance.RoomPolicy(
              governance: finance.Governance(
                roles: [finance.RoleCapabilities(roleId: 'chair')],
              ),
            ),
          ),
        ),
      )
      ..on(
        finance.CreditService.listLoans,
        (req) => finance.ListLoansResponse(
          loans: [finance.Loan(loanId: 'loan1', roomId: req.roomId)],
        ),
      )
      ..on(
        finance.SavingsService.listMemberBalances,
        (req) => finance.ListMemberBalancesResponse(
          balances: [
            finance.MemberBalance(
              memberId: 'mem1',
              contributed: finance.Money(assetId: 'USDC.146', amount: '42'),
            ),
          ],
          booksAvailable: true,
        ),
      );
    final service = StawiFinanceService(
      rooms: finance.RoomServiceClient(transport),
      treasury: finance.TreasuryServiceClient(transport),
      governance: finance.GovernanceServiceClient(transport),
      credit: finance.CreditServiceClient(transport),
      savings: finance.SavingsServiceClient(transport),
      identity: () async => const StawiIdentity(profileId: 'p1', accounts: []),
    );
    expect((await service.roles(roomId)).single.roleId, 'chair');
    expect((await service.loans(roomId)).single.loanId, 'loan1');
    final balances = await service.memberBalances(roomId);
    expect(balances.balances.single.contributed.amount, '42');
    expect(balances.booksAvailable, isTrue);
    expect(
      transport
          .requestsTo(finance.SavingsService.listMemberBalances)
          .single
          .roomId,
      roomId,
    );
  });

  test('custody sources keep their order: binding before finance', () async {
    final asked = <String>[];
    final source = firstCustodyOf([
      (id) async {
        asked.add('binding');
        return Uint8List(20);
      },
      (id) async {
        asked.add('finance');
        return null;
      },
    ]);
    await source(roomId);
    expect(asked, ['binding']);
  });
}
