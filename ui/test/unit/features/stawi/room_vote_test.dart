import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_room_service.dart';
import 'package:stawi/features/stawi/domain/secret_ballot.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

const roomId = 'room00000000000000aa';

/// One Go-produced room vote (CAST_VOTE, COMMIT_VOTE or REVEAL_VOTE) from
/// pkg/evm/stawi Call.TypedHash.
class _Vote {
  _Vote(this.json);

  final Map<String, dynamic> json;

  int get kind => json['kind'] as int;
  String get name => json['name'] as String;
  Uint8List get verifier => hexToBytes(json['verifier'] as String);
  BigInt get chainId => BigInt.parse(json['chain_id'] as String);
  Uint8List get member => hexToBytes(json['member'] as String);
  int get proposalId => int.parse(json['proposal_id'] as String);
  int get choice => json['choice'] as int;
  Uint8List get salt => hexToBytes(json['salt'] as String);
  Uint8List get params => hexToBytes(json['params'] as String);
  Uint8List get typedHash => hexToBytes(json['typed_hash'] as String);
  Uint8List get digest => hexToBytes(json['digest'] as String);
  BigInt get deadline => BigInt.parse(json['deadline'] as String);

  finance.VoteChoice get voteChoice => switch (choice) {
    1 => finance.VoteChoice.VOTE_CHOICE_APPROVE,
    2 => finance.VoteChoice.VOTE_CHOICE_REJECT,
    _ => finance.VoteChoice.VOTE_CHOICE_ABSTAIN,
  };

  /// Settlement's answer for this vote; [verifier], [params] and [digest]
  /// replace the vector's.
  settlement.PrepareRoomCallResponse prepared({
    List<int>? verifier,
    List<int>? params,
    List<int>? typedHash,
    List<int>? digest,
  }) => settlement.PrepareRoomCallResponse(
    callId: 'call0000000000000001',
    digest: digest ?? this.digest,
    signer: member,
    call: settlement.RoomCall(
      callId: 'call0000000000000001',
      chainId: Int64.parseInt(chainId.toString()),
      chatRoomId: roomId,
      kind: settlement.RoomCallKind.valueOf(kind),
      verifier: verifier ?? this.verifier,
      signer: member,
      nonce: Int64.parseInt(json['nonce'] as String),
      deadline: Int64.parseInt(deadline.toString()),
      params: params ?? this.params,
      typedHash: typedHash ?? this.typedHash,
      digest: digest ?? this.digest,
      requiresSignature: true,
    ),
  );
}

void main() {
  final votes = [
    for (final v
        in (jsonDecode(
              File('test/fixtures/stawi/go_room_votes.json').readAsStringSync(),
            ) as Map<String, dynamic>)['room_votes']
            as List)
      _Vote(v as Map<String, dynamic>),
  ];
  _Vote vote(int kind, int choice) => votes.firstWhere(
    (v) =>
        v.name == 'sonic_testnet' &&
        v.kind == kind &&
        v.proposalId == 1 &&
        (kind == 3 || v.choice == choice),
  );

  late FakeConnectTransport transport;
  late RecordingSigningGate gate;
  late RecordingActSender sender;
  late MemoryDeviceKeyVault ballots;
  late DateTime now;
  RoomGovernance? governance;

  setUp(() {
    transport = FakeConnectTransport();
    gate = RecordingSigningGate();
    sender = RecordingActSender();
    ballots = MemoryDeviceKeyVault();
    // Before every vector's deadline.
    now = DateTime.fromMillisecondsSinceEpoch(1760000000 * 1000, isUtc: true);
    final v = vote(2, 1);
    governance = RoomGovernance(address: v.verifier, chainId: v.chainId);
  });

  StawiRoomService service(Uint8List member) => StawiRoomService(
    rooms: settlement.RoomServiceClient(transport),
    keys: DeviceKeyStore(vaultWith('p1', anvilKey), gate: gate),
    identity: () async => identityWith('p1', member),
    send: sender.call,
    ballots: SecretBallotStore(ballots),
    governance: (id) async => id == roomId ? governance : null,
    now: () => now,
  );

  List<settlement.PrepareRoomCallRequest> prepares() =>
      transport.requestsTo(settlement.RoomService.prepareRoomCall);

  Future<PreparedRoomVote> castYes(_Vote v) => service(v.member).prepareVote(
    roomId: roomId,
    onchainProposalId: v.proposalId,
    choice: v.voteChoice,
    mode: RoomVoteMode.open,
    title: 'Vote Yes on loan request #3 in Chama',
    lines: const [('Loan request', '#3'), ('Room', 'Chama')],
  );

  group('an open vote', () {
    test('is the Go vector: reviewed, then signed behind the lock', () async {
      final v = vote(2, 1);
      transport.on(
        settlement.RoomService.prepareRoomCall,
        (req) => v.prepared(),
      );
      final prepared = await castYes(v);
      expect(prepared.digest, v.digest);
      expect(prepared.review.title, 'Vote Yes on loan request #3 in Chama');
      expect(prepared.review.lines, [
        ('Loan request', '#3'),
        ('Room', 'Chama'),
        ('Your vote', 'Yes'),
      ]);
      final req = prepares().single;
      expect(req.kind, settlement.RoomCallKind.ROOM_CALL_KIND_CAST_VOTE);
      expect(req.params.vote.onchainProposalId, Int64(1));
      expect(req.params.vote.choice, finance.VoteChoice.VOTE_CHOICE_APPROVE);
      expect(req.account, v.member);
      expect(gate.reasons, isEmpty, reason: 'nothing signed before review');

      await service(v.member).submitVote(prepared);
      expect(gate.reasons, ['Vote Yes on loan request #3 in Chama']);
      final act = sender.sent.single;
      expect(act.content['kind'], 'CAST_VOTE');
      expect(
        recoverDeviceAddress(
          v.digest,
          base64Decode(act.content['signature'] as String),
        ),
        (await DeviceKeyStore(
          vaultWith('p1', anvilKey),
          gate: gate,
        ).load('p1'))!.address,
      );
    });

    final refusals = <String, settlement.PrepareRoomCallResponse Function()>{
      // Settlement turns the No into a Yes, or names another proposal.
      'another choice': () => vote(2, 2).prepared(),
      'another proposal': () => votes
          .firstWhere(
            (v) =>
                v.name == 'sonic_testnet' &&
                v.kind == 2 &&
                v.proposalId == 42 &&
                v.choice == 1,
          )
          .prepared(),
      'another governance module': () =>
          vote(2, 1).prepared(verifier: Uint8List(20)..[19] = 9),
      'a digest that is not the vote\'s': () =>
          vote(2, 1).prepared(digest: Uint8List(32)..[0] = 1),
      'a commit in place of the vote': () => vote(3, 0).prepared(),
    };
    for (final MapEntry(key: name, value: answer) in refusals.entries) {
      test('refused when settlement prepares $name', () async {
        transport.on(settlement.RoomService.prepareRoomCall, (req) => answer());
        await expectLater(castYes(vote(2, 1)), throwsA(isA<SigningRefused>()));
        expect(gate.reasons, isEmpty);
        expect(sender.sent, isEmpty);
      });
    }

    test('refused once its deadline has passed', () async {
      final v = vote(2, 1);
      transport.on(
        settlement.RoomService.prepareRoomCall,
        (req) => v.prepared(),
      );
      now = DateTime.fromMillisecondsSinceEpoch(
        v.deadline.toInt() * 1000,
        isUtc: true,
      );
      await expectLater(castYes(v), throwsA(isA<SigningRefused>()));
    });

    test('refused when the room\'s governance cannot be read', () async {
      governance = null;
      final v = vote(2, 1);
      transport.on(
        settlement.RoomService.prepareRoomCall,
        (req) => v.prepared(),
      );
      await expectLater(
        castYes(v),
        throwsA(
          isA<SigningRefused>().having(
            (e) => e.reason,
            'reason',
            governanceUnknownReason,
          ),
        ),
      );
      expect(prepares(), isEmpty);
    });
  });

  group('a secret ballot', () {
    test('commits the sealed choice, kept only once it is sent', () async {
      final v = vote(3, 0);
      // Settlement builds the call from the commitment the device asked for.
      transport.on(settlement.RoomService.prepareRoomCall, (req) {
        final expected = RoomVote.commit(
          proposalId: BigInt.from(v.proposalId),
          commitment: req.params.vote.commitment,
        );
        final typed = roomVoteTypedHash(
          expected,
          verifier: v.verifier,
          chainId: v.chainId,
          member: v.member,
          nonce: BigInt.zero,
          deadline: v.deadline,
        );
        return v.prepared(
          params: expected.params,
          typedHash: typed,
          digest: accountWrappedHash(v.member, v.chainId, typed),
        );
      });
      final s = service(v.member);
      final prepared = await s.prepareVote(
        roomId: roomId,
        onchainProposalId: v.proposalId,
        choice: finance.VoteChoice.VOTE_CHOICE_REJECT,
        mode: RoomVoteMode.secret,
        title: 'Vote No on loan request #3 in Chama',
      );
      final req = prepares().single;
      expect(req.kind, settlement.RoomCallKind.ROOM_CALL_KIND_COMMIT_VOTE);
      expect(
        await SecretBallotStore(ballots).load(roomId, v.proposalId),
        isNull,
        reason: 'not kept before the person confirms',
      );
      await s.submitVote(prepared);
      final kept = await SecretBallotStore(ballots).load(roomId, v.proposalId);
      expect(kept!.choice, finance.VoteChoice.VOTE_CHOICE_REJECT);
      expect(
        voteCommitment(
          choice: voteChoiceAgainst,
          salt: kept.salt,
          proposalId: BigInt.from(v.proposalId),
          member: v.member,
        ),
        req.params.vote.commitment,
      );
      expect(sender.sent.single.content['kind'], 'COMMIT_VOTE');
    });

    test('a commitment of another choice is refused', () async {
      final v = vote(3, 0);
      // The Go vector's commitment, not the one this device sealed.
      transport.on(
        settlement.RoomService.prepareRoomCall,
        (req) => v.prepared(),
      );
      await expectLater(
        service(v.member).prepareVote(
          roomId: roomId,
          onchainProposalId: v.proposalId,
          choice: finance.VoteChoice.VOTE_CHOICE_APPROVE,
          mode: RoomVoteMode.secret,
          title: 'Vote Yes',
        ),
        throwsA(isA<SigningRefused>()),
      );
      expect(await SecretBallotStore(ballots).pending(roomId), isEmpty);
    });

    test('reveals the vote this device sealed: the Go vector', () async {
      final v = vote(4, 1);
      await SecretBallotStore(ballots).keep(
        roomId,
        v.proposalId,
        SealedVote(choice: v.voteChoice, salt: v.salt, member: v.member),
      );
      transport.on(
        settlement.RoomService.prepareRoomCall,
        (req) => v.prepared(),
      );
      final s = service(v.member);
      final prepared = await s.prepareReveal(
        roomId: roomId,
        onchainProposalId: v.proposalId,
        title: 'Reveal my vote on loan request #3 in Chama',
      );
      expect(prepared.digest, v.digest);
      expect(prepared.review.lines.last, ('Your vote', 'Yes'));
      await s.submitVote(prepared);
      expect(sender.sent.single.content['kind'], 'REVEAL_VOTE');
      expect(await SecretBallotStore(ballots).pending(roomId), isEmpty);
    });

    test('a reveal of another choice is refused', () async {
      final v = vote(4, 1);
      await SecretBallotStore(ballots).keep(
        roomId,
        v.proposalId,
        SealedVote(choice: v.voteChoice, salt: v.salt, member: v.member),
      );
      transport.on(
        settlement.RoomService.prepareRoomCall,
        (req) => vote(4, 2).prepared(),
      );
      await expectLater(
        service(v.member).prepareReveal(
          roomId: roomId,
          onchainProposalId: v.proposalId,
          title: 'Reveal',
        ),
        throwsA(isA<SigningRefused>()),
      );
      expect(sender.sent, isEmpty);
    });
  });
}
