import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/data/stawi_room_engines.dart';
import 'package:stawi/features/stawi/data/stawi_room_service.dart';
import 'package:stawi/features/stawi/domain/account_engine_calls.dart';
import 'package:stawi/features/stawi/domain/secret_ballot.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

const roomId = 'room00000000000000aa';

void main() {
  group('sealed votes', () {
    final member = Uint8List.fromList(List.filled(20, 7));

    test('are listed until revealed, soonest deadline first', () async {
      final store = SecretBallotStore(MemoryDeviceKeyVault());
      await store.seal(
        roomId: roomId,
        proposalId: 1,
        choice: finance.VoteChoice.VOTE_CHOICE_APPROVE,
        member: member,
      );
      await store.seal(
        roomId: roomId,
        proposalId: 2,
        choice: finance.VoteChoice.VOTE_CHOICE_REJECT,
        member: member,
        revealClosesAt: DateTime.utc(2026, 10, 20),
      );
      await store.seal(
        roomId: roomId,
        proposalId: 3,
        choice: finance.VoteChoice.VOTE_CHOICE_ABSTAIN,
        member: member,
        revealClosesAt: DateTime.utc(2026, 10, 13),
      );
      expect((await store.pending(roomId)).map((p) => p.proposalId), [3, 2, 1]);
      await store.markRevealed(roomId, 3);
      expect((await store.pending(roomId)).map((p) => p.proposalId), [2, 1]);
      expect(await store.pending('otherroom00000000000'), isEmpty);
    });

    test('urgency follows the reveal deadline', () {
      final now = DateTime.utc(2026, 10, 12, 12);
      SealedVote at(DateTime? t) => SealedVote(
        choice: finance.VoteChoice.VOTE_CHOICE_APPROVE,
        salt: Uint8List(32),
        member: member,
        revealClosesAt: t,
      );
      expect(revealUrgency(at(null), now), RevealUrgency.unknown);
      expect(
        revealUrgency(at(DateTime.utc(2026, 10, 15)), now),
        RevealUrgency.open,
      );
      expect(
        revealUrgency(at(DateTime.utc(2026, 10, 13)), now),
        RevealUrgency.closingSoon,
      );
      expect(
        revealUrgency(at(DateTime.utc(2026, 10, 12)), now),
        RevealUrgency.closed,
      );
    });

    test('a reveal marks the vote revealed; another device cannot', () async {
      final wrapped = GoSignedCallVectors.load().accountWrappedHashes
          .firstWhere(
            (v) => v['name'] == 'anvil_0/seq' && v['chain_id'] == '146',
          );
      final account = hexToBytes(wrapped['account'] as String);
      final transport = FakeConnectTransport()
        ..on(
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
      StawiRoomService device(MemoryDeviceKeyVault ballots) => StawiRoomService(
        rooms: settlement.RoomServiceClient(transport),
        keys: DeviceKeyStore(vaultWith('p1', anvilKey)),
        identity: () async => identityWith('p1', account),
        send: RecordingActSender().call,
        ballots: SecretBallotStore(ballots),
      );
      final voting = MemoryDeviceKeyVault();
      await device(voting).commitSecretVote(
        roomId: roomId,
        onchainProposalId: 5,
        choice: finance.VoteChoice.VOTE_CHOICE_APPROVE,
        revealClosesAt: DateTime.utc(2026, 10, 20),
      );
      expect(await device(voting).pendingReveals(roomId), hasLength(1));
      expect(
        (await device(
          voting,
        ).pendingReveals(roomId)).single.vote.revealClosesAt,
        DateTime.utc(2026, 10, 20),
      );

      await expectLater(
        device(
          MemoryDeviceKeyVault(),
        ).revealSecretVote(roomId: roomId, onchainProposalId: 5),
        throwsA(
          isA<StawiUnavailable>().having(
            (e) => e.message,
            'message',
            revealElsewhereMessage,
          ),
        ),
      );

      await device(
        voting,
      ).revealSecretVote(roomId: roomId, onchainProposalId: 5);
      expect(await device(voting).pendingReveals(roomId), isEmpty);
    });
  });

  group('room engine check', () {
    final vectors = GoEngineCallVector.load()
        .where((v) => !v.personal)
        .toList();
    late FakeConnectTransport transport;

    Future<PreparedEngineCall> prepare(
      GoEngineCallVector v,
      RoomEngineTargets? engines,
    ) {
      transport = FakeConnectTransport()
        ..on(
          settlement.AccountService.prepareAccountCall,
          (req) => v.prepared(req.kind),
        );
      return StawiAccountService(
        accounts: settlement.AccountServiceClient(transport),
        keys: DeviceKeyStore(vaultWith('p1', v.devicePrivateKey)),
        proofs: refusingSessionProofs,
        identity: () async => identityWith('p1', v.account),
      ).prepareEngineCall(
        AccountEngineRequest(
          call: v.action == 'pledge'
              ? AccountEngineCall.loanPledge
              : AccountEngineCall.withdrawEquity,
          custody: v.room,
          amount: v.json['amount'] as String,
          loanId: v.json['loan_id'] as int,
        ),
        engines: engines,
      );
    }

    final pledge = vectors.firstWhere((v) => v.name == 'loan_pledge');
    final equity = vectors.firstWhere((v) => v.name == 'withdraw_equity');

    test('accepts the room’s own active engine for each action', () async {
      expect(
        (await prepare(pledge, pledge.engines())).call.action.target,
        EngineTarget.loanBook,
      );
      expect(
        (await prepare(equity, equity.engines())).call.action.target,
        EngineTarget.rulesEngine,
      );
    });

    test('refuses another engine, or one whose grant is not active', () async {
      for (final engines in [
        // Right address, wrong engine: a pledge runs on the LoanBook.
        RoomEngineTargets(
          rulesEngine: pledge.target,
          rulesCallable: true,
          loanBook: Uint8List(20),
          loanCallable: true,
        ),
        pledge.engines(callable: false),
      ]) {
        await expectLater(
          prepare(pledge, engines),
          throwsA(
            isA<SigningRefused>().having(
              (e) => e.reason,
              'reason',
              contains('not this room’s active engine'),
            ),
          ),
        );
      }
    });

    test('refuses to prepare anything when the engines are unknown', () async {
      await expectLater(
        prepare(pledge, null),
        throwsA(
          isA<SigningRefused>().having(
            (e) => e.reason,
            'reason',
            enginesUnknownReason,
          ),
        ),
      );
      expect(transport.calls, isEmpty);
    });

    test('engine targets come from finance Room.engines', () {
      expect(engineTargetsOf(finance.Room()), isNull);
      final targets = engineTargetsOf(
        finance.Room(
          engines: finance.RoomEngines(
            rulesEngine: finance.RoomEngineBinding(
              address: Uint8List.fromList(List.filled(20, 1)),
              callable: true,
            ),
            loanBook: finance.RoomEngineBinding(
              address: Uint8List.fromList(List.filled(20, 2)),
            ),
          ),
        ),
      )!;
      expect(targets.rulesEngine, List.filled(20, 1));
      expect(targets.rulesCallable, isTrue);
      expect(targets.loanBook, List.filled(20, 2));
      expect(targets.loanCallable, isFalse);
    });
  });

  group('product terms', () {
    test('label unnamed products by their id', () {
      expect(productLabel('Emergency loan', Uint8List(32)), 'Emergency loan');
      expect(
        productLabel('', Uint8List.fromList([0xab, 0xcd, 0xef, 0x01, 0x23])),
        'Product 0xabcdef01',
      );
    });

    test('summarise loan and dues terms', () {
      final loan = finance.RoomLoanProduct(
        maxAmount: finance.Money(assetId: 'USDC.146', amount: '50000000000'),
        rateBps: 250,
        rateBasis: finance.LoanRateBasis.valueOf(1),
        minInstalments: 1,
        maxInstalments: 6,
      );
      final terms = loanProductTerms(loan, usdcAssets);
      expect(terms, contains('up to 50,000.00 USDC'));
      expect(terms, contains('2.5% per period'));
      expect(terms, contains('1–6 instalments'));

      final dues = finance.RoomDuesProduct(
        amount: finance.Money(assetId: 'USDC.146', amount: '1000000'),
        everyPeriods: 1,
        memberChoice: true,
        minAmount: finance.Money(assetId: 'USDC.146', amount: '500000'),
        maxAmount: finance.Money(assetId: 'USDC.146', amount: '5000000'),
        active: true,
      );
      expect(
        duesProductTerms(dues, usdcAssets),
        '1.00 USDC · every period · you choose 0.50 USDC–5.00 USDC',
      );
    });
  });
}
