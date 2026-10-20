import 'dart:convert';
import 'dart:typed_data';

import 'package:connectrpc/connect.dart' as connect;
import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/money_call_fate.dart';
import 'package:stawi/features/stawi/data/signing_gate.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/data/stawi_counterparty.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/data/stawi_room_service.dart';
import 'package:stawi/features/stawi/data/unconfirmed_money_calls.dart';
import 'package:stawi/features/stawi/domain/governance_requests.dart';
import 'package:stawi/features/stawi/domain/intent_bridge.dart';
import 'package:stawi/features/stawi/domain/loan_terms.dart';
import 'package:stawi/features/stawi/domain/personal_calls.dart';
import 'package:stawi/features/stawi/domain/room_setup.dart'
    show rotationModuleUnknownReason;
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi/features/stawi/domain/stawi_payloads.dart';
import 'package:stawi/features/stawi/ui/stawi_feedback.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

const roomId = 'room00000000000000aa';

void main() {
  final vectors = GoSignedCallVectors.load();
  // A StawiAccount (anvil_0 here) on chain 146.
  final wrapped = vectors.accountWrappedHashes.firstWhere(
    (v) => v['name'] == 'anvil_0/seq' && v['chain_id'] == '146',
  );
  final account = hexToBytes(wrapped['account'] as String);

  late FakeConnectTransport transport;
  late RecordingActSender sender;
  late DeviceKeyStore keys;
  late DevicePublicKey key;
  // The same key, unlocked without a prompt, to compute expected signatures.
  late DeviceKeyHandle signer;
  late RecordingSigningGate gate;

  setUp(() async {
    gate = RecordingSigningGate();
    transport = FakeConnectTransport();
    sender = RecordingActSender();
    keys = DeviceKeyStore(vaultWith('p1', anvilKey), gate: gate);
    key = (await keys.load('p1'))!;
    signer = await DeviceKeyStore(
      vaultWith('p1', anvilKey),
      gate: SigningGate.open,
    ).unlock('p1', reason: 'expected signature');
  });

  // The Go vector's agent, answered by chat as the DM partner p-agent's.
  final vectorAgent = hexToBytes(
    GoRoomGenesisVectors.named('agent').json['agent'] as String,
  );

  // The room as finance indexes it, and a member's account it knows.
  final room = RoomContracts(
    governance: Uint8List(20)..[0] = 0x40,
    custody: Uint8List(20)..[0] = 0x30,
    chainId: BigInt.from(146),
  );
  final amina = Uint8List(20)..[19] = 0x22;
  final now = DateTime.utc(2026, 10, 14, 9);

  StawiRoomService roomService({
    DmPartnerAccountOf? agentAccounts,
    RotationModuleOf? rotationModules,
  }) => StawiRoomService(
    rooms: settlement.RoomServiceClient(transport),
    keys: keys,
    identity: () async => identityWith('p1', account),
    send: sender.call,
    agentAccounts:
        agentAccounts ??
        (profileId) async => profileId == 'p-agent' ? vectorAgent : null,
    contracts: (id) async => id == roomId ? room : null,
    memberAccounts: (id, profileId) async =>
        id == roomId && profileId == 'p2' ? amina : null,
    rotationModules: rotationModules,
    now: () => now,
  );

  group('signed room calls', () {
    void prepares({List<int>? digestOverride}) {
      transport.on(settlement.RoomService.prepareRoomCall, (req) {
        expect(req.chatRoomId, roomId);
        final p = honestRoomCall(
          req,
          room: room,
          signer: account,
          chatRoomId: roomId,
          now: now,
        );
        if (digestOverride != null) {
          p
            ..digest = digestOverride
            ..call.digest = digestOverride;
        }
        return p;
      });
    }

    Future<GovernanceRequest> invite() async => inviteRequest(
      account: await roomService().memberAccount(roomId, 'p2', name: 'Amina'),
      name: 'Amina',
      now: now,
    );

    test('prepares and checks, reviews, then signs and sends '
        'STAWI_SIGNED_CALL', () async {
      prepares();
      final s = roomService();
      final prepared = await s.prepareAct(
        roomId: roomId,
        request: await invite(),
      );
      // Nothing is signed while the person reviews what was checked.
      expect(gate.reasons, isEmpty);
      expect(sender.sent, isEmpty);
      expect(prepared.review.title, 'Invite Amina');
      expect(prepared.review.lines, [
        ('Member', 'Amina'),
        ('Account', shortAccount(amina)),
        ('Invitation expires', '2026-10-21 09:00 UTC'),
      ]);
      expect(prepared.review.notes, [checkedRoomActNote]);

      final request = transport
          .requestsTo(settlement.RoomService.prepareRoomCall)
          .single;
      expect(request.kind, settlement.RoomCallKind.ROOM_CALL_KIND_INVITE);
      expect(request.account, account);
      expect(request.params.officer.subject.account, amina);
      expect(
        request.params.officer.inviteValidSeconds,
        officerInviteValidity.inSeconds,
      );

      await s.submitAct(prepared);
      expect(gate.reasons, ['Invite Amina']);
      final act = sender.sent.single;
      expect(act.roomId, roomId);
      expect(act.type, RoomEventType.stawiSignedCall);
      expect(act.content['callId'], 'call0000000000000001');
      expect(act.content['kind'], 'INVITE');
      expect(act.content['algorithm'], 'secp256k1');
      expect(act.content['signerKeyId'], key.keyId);
      expect(act.content['summary'], 'Invite Amina');
      final signature = base64Decode(act.content['signature'] as String);
      expect(signature, hasLength(65));
      expect(recoverDeviceAddress(prepared.digest, signature), key.address);
    });

    group('loan decisions', () {
      final loanBook = Uint8List(20)..[19] = 0x5b;
      final borrower = Uint8List(20)..[19] = 0x22;
      final loan = finance.Loan(
        onchainLoanId: Int64(7),
        loanBook: loanBook,
        borrowerAccount: borrower,
        requested: finance.Money(assetId: 'usdc', amount: '250000000'),
        instalments: 6,
        state: finance.LoanState.LOAN_STATE_DEFAULTED,
      );
      void preparesLoan({
        List<int>? book,
        ({List<int> borrower, BigInt amount, int instalments})? pending,
      }) => transport.on(
        settlement.RoomService.prepareRoomCall,
        (req) => honestRoomCall(
          req,
          room: room,
          signer: account,
          chatRoomId: roomId,
          now: now,
          loanBook: book ?? loanBook,
          pendingLoan:
              pending ??
              (
                borrower: borrower,
                amount: BigInt.from(250000000),
                instalments: 6,
              ),
        ),
      );

      test('opening a by-vote loan\'s vote proposes its approval', () async {
        preparesLoan();
        final prepared = await roomService().prepareAct(
          roomId: roomId,
          request: openLoanVoteRequest(loan, borrower: 'Amina'),
        );
        expect(prepared.review.title, 'Open the vote on loan request #7');
        final req = transport
            .requestsTo(settlement.RoomService.prepareRoomCall)
            .single;
        expect(req.kind, settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE);
        expect(req.params.propose.loanApproval, Int64(7));
      });

      test('a vote on another amount is refused', () async {
        preparesLoan(
          pending: (
            borrower: borrower,
            amount: BigInt.from(900000000),
            instalments: 6,
          ),
        );
        await expectLater(
          roomService().prepareAct(
            roomId: roomId,
            request: openLoanVoteRequest(loan),
          ),
          throwsA(isA<SigningRefused>()),
        );
      });

      test('a write-off and a restructure are checked documents', () async {
        preparesLoan();
        final s = roomService();
        final off = await s.prepareAct(
          roomId: roomId,
          request: writeOffRequest(loan),
        );
        expect(off.review.title, 'Propose writing off loan #7');
        final re = await s.prepareAct(
          roomId: roomId,
          request: restructureRequest(loan, instalments: 12, rateBps: 250),
        );
        expect(re.review.lines, [
          ('Loan', '#7'),
          ('New instalments', '12'),
          ('Interest', '2.5% each instalment'),
        ]);
        final sent = transport
            .requestsTo(settlement.RoomService.prepareRoomCall)
            .last;
        expect(sent.params.propose.loanRestructure.instalments, 12);
        expect(sent.params.propose.loanRestructure.rateBps, 250);
      });

      test('a write-off on another loan book is refused', () async {
        preparesLoan(book: Uint8List(20)..[19] = 0x99);
        await expectLater(
          roomService().prepareAct(
            roomId: roomId,
            request: writeOffRequest(loan),
          ),
          throwsA(isA<SigningRefused>()),
        );
        expect(gate.reasons, isEmpty);
      });
    });

    test('never signs or sends a substituted digest', () async {
      prepares(digestOverride: Uint8List(32));
      await expectLater(
        roomService().prepareAct(roomId: roomId, request: await invite()),
        throwsA(isA<SigningRefused>()),
      );
      expect(gate.reasons, isEmpty);
      expect(sender.sent, isEmpty);
    });

    test('a member this device cannot confirm is refused before '
        'settlement is asked', () async {
      await expectLater(
        roomService().memberAccount(roomId, 'p9', name: 'Baraka'),
        throwsA(
          isA<SigningRefused>().having(
            (e) => e.reason,
            'reason',
            contains('Baraka'),
          ),
        ),
      );
      expect(transport.calls, isEmpty);
    });

    test('the room\'s contracts unread refuse the act', () async {
      prepares();
      await expectLater(
        roomService().prepareAct(
          roomId: 'room00000000000000bb',
          request: leaveRequest,
        ),
        throwsA(
          isA<SigningRefused>().having(
            (e) => e.reason,
            'reason',
            roomContractsUnknownReason,
          ),
        ),
      );
      expect(transport.calls, isEmpty);
    });

    test('a vote carries the proposal and choice', () async {
      prepares();
      final s = roomService();
      final prepared = await s.prepareVote(
        roomId: roomId,
        onchainProposalId: 7,
        choice: finance.VoteChoice.VOTE_CHOICE_REJECT,
        mode: RoomVoteMode.open,
      );
      final request = transport
          .requestsTo(settlement.RoomService.prepareRoomCall)
          .single;
      expect(request.params.vote.onchainProposalId, Int64(7));
      expect(request.params.vote.choice, finance.VoteChoice.VOTE_CHOICE_REJECT);
      expect(prepared.review.title, 'Vote reject on proposal #7');
      expect(prepared.review.lines, [('Proposal', '#7'), ('Your vote', 'No')]);
      await s.submitAct(prepared);
      expect(sender.sent.single.content['kind'], 'CAST_VOTE');
      expect(gate.reasons, ['Vote reject on proposal #7']);
    });

    test(
      'every act the governance sheet offers is checked and signed',
      () async {
        prepares();
        final s = roomService();
        for (final request in [
          await invite(),
          proposeInviteRequest(
            account: amina,
            name: 'Amina',
            expiresAt: inviteExpiryAfter(14, now: now),
          ),
          acceptInvitationRequest(5),
          joinRequest,
          admitRequest(account: amina, name: 'Amina'),
          leaveRequest,
          proposeRemovalRequest(account: amina, name: 'Amina'),
          delegateRequest(
            account: amina,
            name: 'Amina',
            until: now.add(const Duration(days: 30)),
          ),
          revokeDelegationRequest,
          proposeExitCancelRequest(6),
          votePrincipalExitRequest(ballotId: 4, approve: false),
          freezeRequest('treasurer lost phone'),
          assignRoleRequest(
            account: amina,
            name: 'Amina',
            roleId: 'treasurer',
            roleName: 'Treasurer',
            capabilities: RoomCapability.invite | RoomCapability.lend,
          ),
          revokeRoleRequest(
            account: amina,
            name: 'Amina',
            roleId: 'treasurer',
            roleName: 'Treasurer',
          ),
        ]) {
          final prepared = await s.prepareAct(roomId: roomId, request: request);
          await s.submitAct(prepared);
          expect(
            sender.sent.last.content['kind'],
            roomCallKindName(request.kind),
          );
        }
        expect(sender.sent, hasLength(14));
      },
    );

    test('a refused device lock signs and sends nothing', () async {
      prepares();
      final s = roomService();
      final prepared = await s.prepareAct(
        roomId: roomId,
        request: leaveRequest,
      );
      gate.refuse = true;
      await expectLater(s.submitAct(prepared), throwsA(isA<SigningRefused>()));
      expect(sender.sent, isEmpty);
    });
  });

  group('room conversion and genesis', () {
    test('conversion sends the template, rules, founders and policy', () async {
      await roomService().convert(
        roomId: roomId,
        templateId: 'ug_savings_basic',
        ruleValues: const {'contribution_amount': '5000', 'period': 'WEEKLY'},
        founderSubscriptionIds: const ['sub-me', 'sub-2'],
        joinPolicy: StawiJoinPolicy.private,
      );
      final act = sender.sent.single;
      expect(act.type, RoomEventType.stawiRoomConversion);
      final view = StawiConversionView.fromContent(act.content);
      expect(view.templateId, 'ug_savings_basic');
      expect(view.ruleValues, {
        'contribution_amount': '5000',
        'period': 'WEEKLY',
      });
      expect(view.founderSubscriptionIds, ['sub-me', 'sub-2']);
      expect(view.joinPolicy, StawiJoinPolicy.private);
      expect(view.genesis, isNull);
    });

    test('conversion refuses a founding quorum above the founders', () {
      expect(
        () => roomService().convert(
          roomId: roomId,
          templateId: 'ug_savings_basic',
          ruleValues: const {'founding_quorum': '3'},
          founderSubscriptionIds: const ['sub-me', 'sub-2'],
          joinPolicy: StawiJoinPolicy.private,
        ),
        throwsArgumentError,
      );
      expect(sender.sent, isEmpty);
    });

    // Another founder's account. Every founder signs their own wrapping of
    // the genesis hash, never a shared digest.
    final otherAccount = Uint8List.fromList(List.filled(20, 0xbb));
    final roomGenesis = GoRoomGenesisVectors.named('agent').roomGenesis(
      founderProfileIds: const ['p2', 'p1'],
      accounts: [otherAccount, account],
    );
    final genesisHash = Uint8List.fromList(roomGenesis.genesisHash);
    final genesisDigest = Uint8List.fromList(
      roomGenesis.founders[1].signingDigest,
    );
    final otherDigest = Uint8List.fromList(
      roomGenesis.founders[0].signingDigest,
    );

    RoomEvent card({List<String> founders = const ['p1', 'p2']}) => RoomEvent(
      id: 'conv1',
      roomId: roomId,
      senderId: 'sub-2',
      type: RoomEventType.stawiRoomConversion,
      createdAt: 0,
      status: EventStatus.delivered,
      content: {
        'templateId': 'ug_savings_basic',
        'founderSubscriptionIds': ['sub-me', 'sub-2'],
        'joinPolicy': 'STAWI_JOIN_POLICY_PRIVATE',
        'genesis': {
          'genesisId': 'gen00000000000000001',
          'genesisHash': base64Encode(genesisHash),
          'constitutionHash': base64Encode(Uint8List(32)),
          'founderProfileIds': founders,
        },
      },
    );

    void genesisOnSettlement() {
      transport.on(
        settlement.RoomService.getRoomGenesis,
        (req) => settlement.GetRoomGenesisResponse(
          genesis: roomGenesis.deepCopy()
            ..genesisId = req.genesisId
            ..chatRoomId = roomId,
        ),
      );
    }

    Future<RoomEvent> signGenesis(
      RoomEvent conversion, {
      String? roomName,
    }) async {
      final service = roomService();
      final prepared = await service.prepareGenesisSignature(conversion);
      return (roomName == null
              ? await service.submitGenesisSignature(prepared)
              : await service.submitGenesisSignature(
                  prepared,
                  roomName: roomName,
                ))
          .event;
    }

    // The room's contracts as the factory will deploy them, and the founder's
    // setup proposals at nonces 0 to 2 on them.
    final setupGovernance = Uint8List(20)..[19] = 0x60;
    final setupCustody = Uint8List(20)..[19] = 0x61;
    final setupDigests = setupDigestsFor(
      account: account,
      governance: setupGovernance,
      custody: setupCustody,
      chainId: BigInt.parse(roomGenesis.chainId.toStringUnsigned()),
      deadline: now.add(const Duration(days: 14)),
    );

    void genesisWithSetupOnSettlement({
      List<settlement.RoomSetupDigest>? digests,
      bool signed = false,
    }) {
      transport.on(settlement.RoomService.getRoomGenesis, (req) {
        final g = roomGenesis.deepCopy()
          ..genesisId = req.genesisId
          ..chatRoomId = roomId
          ..setup = settlement.RoomSetup(
            chatRoomId: roomId,
            governance: setupGovernance,
            custody: setupCustody,
            state: settlement.RoomSetupState.ROOM_SETUP_STATE_AWAITING_GENESIS,
          );
        g.founders[1]
          ..setupDigests.addAll(digests ?? setupDigests)
          ..setupSigned = signed;
        return settlement.GetRoomGenesisResponse(genesis: g);
      });
    }

    test('conversion names the agent by profile', () async {
      await roomService().convert(
        roomId: roomId,
        templateId: 'ug_savings_basic',
        ruleValues: const {},
        founderSubscriptionIds: const ['sub-me'],
        joinPolicy: StawiJoinPolicy.private,
        agentProfileId: 'carol0000000000000001',
      );
      final content = sender.sent.single.content;
      expect(content['agentProfileId'], 'carol0000000000000001');
      expect(
        StawiConversionView.fromContent(content).agentProfileId,
        'carol0000000000000001',
      );
    });

    test('conversion without an agent sends none', () async {
      await roomService().convert(
        roomId: roomId,
        templateId: 'ug_savings_basic',
        ruleValues: const {},
        founderSubscriptionIds: const ['sub-me'],
        joinPolicy: StawiJoinPolicy.private,
      );
      expect(sender.sent.single.content.containsKey('agentProfileId'), isFalse);
    });

    test('preparing checks the genesis and signs nothing', () async {
      genesisOnSettlement();
      final prepared = await roomService().prepareGenesisSignature(card());
      expect(prepared.digest, genesisDigest);
      expect(prepared.genesis.agentProfileId, 'p-agent');
      expect(
        gate.reasons,
        isEmpty,
        reason: 'the key is not unlocked to prepare',
      );
      expect(sender.sent, isEmpty);
    });

    test(
      'a DM partner agent is confirmed by the account chat answers',
      () async {
        genesisOnSettlement();
        final prepared = await roomService().prepareGenesisSignature(card());
        expect(prepared.agentConfirmed, isTrue);
      },
    );

    test(
      'an agent at another address is not confirmed and not signed',
      () async {
        genesisOnSettlement();
        final service = roomService(
          agentAccounts: (_) async => Uint8List.fromList(List.filled(20, 0x66)),
        );
        final prepared = await service.prepareGenesisSignature(card());
        expect(prepared.agentConfirmed, isFalse);
        await expectLater(
          service.submitGenesisSignature(prepared),
          throwsA(
            isA<SigningRefused>().having(
              (e) => e.reason,
              'reason',
              'The agent could not be confirmed on this device',
            ),
          ),
        );
        expect(gate.reasons, isEmpty, reason: 'the key is never unlocked');
        expect(sender.sent, isEmpty);
      },
    );

    test('an agent that cannot be resolved is not confirmed', () async {
      genesisOnSettlement();
      for (final resolver in <DmPartnerAccountOf>[
        (_) async => null,
        (_) async => throw const DirectPartnerRefused(),
      ]) {
        final prepared = await roomService(agentAccounts: resolver)
            .prepareGenesisSignature(card());
        expect(prepared.agentConfirmed, isFalse);
      }
    });

    test('a genesis whose contents differ from its hash is refused', () async {
      transport.on(
        settlement.RoomService.getRoomGenesis,
        (req) => settlement.GetRoomGenesisResponse(
          genesis: roomGenesis.deepCopy()
            ..agentProfileId = 'p-mallory'
            ..agent = Uint8List.fromList(List.filled(20, 0x66)),
        ),
      );
      await expectLater(
        roomService().prepareGenesisSignature(card()),
        throwsA(
          isA<SigningRefused>().having(
            (e) => e.reason,
            'reason',
            'the genesis hash does not match its contents',
          ),
        ),
      );
      expect(gate.reasons, isEmpty);
      expect(sender.sent, isEmpty);
    });

    test('a founder signs the account-wrapped genesis hash', () async {
      genesisOnSettlement();
      await signGenesis(card());

      final act = sender.sent.single;
      expect(act.type, RoomEventType.stawiGenesisSignature);
      expect(act.parentId, 'conv1');
      expect(act.content['genesisId'], 'gen00000000000000001');
      expect(act.content['signerKeyId'], key.keyId);
      final signature = base64Decode(act.content['signature'] as String);
      expect(recoverDeviceAddress(genesisDigest, signature), key.address);
      expect(signature, isNot(signer.sign(otherDigest)));
    });

    test('the device lock names the room being founded', () async {
      genesisOnSettlement();
      await signGenesis(card(), roomName: 'Kampala Savers');
      expect(gate.reasons, ['Found Kampala Savers on Stawi']);
      expect(sender.sent, hasLength(1));
    });

    test('a refused device lock sends no genesis signature', () async {
      genesisOnSettlement();
      gate.refuse = true;
      await expectLater(signGenesis(card()), throwsA(isA<SigningRefused>()));
      expect(gate.reasons, ['Found this room on Stawi']);
      expect(sender.sent, isEmpty);
    });

    test('a founder signs their own digest, not another founder\'s', () async {
      genesisOnSettlement();
      await signGenesis(card());

      final signature = base64Decode(
        sender.sent.single.content['signature'] as String,
      );
      expect(signature, signer.sign(genesisDigest));
      expect(recoverDeviceAddress(otherDigest, signature), isNot(key.address));
    });

    group('the setup proposals beside the genesis', () {
      test(
        'are signed under the one unlock and sent to settlement first',
        () async {
          genesisWithSetupOnSettlement();
          transport.on(
            settlement.RoomService.submitRoomSetupSignatures,
            (req) => settlement.SubmitRoomSetupSignaturesResponse(),
          );
          final service = roomService();
          final prepared = await service.prepareGenesisSignature(card());
          expect(prepared.setupDigests, [
            for (final d in setupDigests) d.digest,
          ]);
          final signed = await service.submitGenesisSignature(prepared);

          expect(signed.setupSigned, isTrue);
          expect(gate.reasons, hasLength(1), reason: 'one unlock for all four');
          final sent = transport
              .requestsTo(settlement.RoomService.submitRoomSetupSignatures)
              .single;
          expect(sent.chatRoomId, roomId);
          expect(sent.signatures, hasLength(3));
          for (var i = 0; i < 3; i++) {
            expect(sent.signatures[i].deviceKeyId, key.keyId);
            expect(sent.signatures[i].algorithm, 'secp256k1');
            expect(
              recoverDeviceAddress(
                setupDigests[i].digest,
                sent.signatures[i].signature,
              ),
              key.address,
            );
          }
          // The setup reaches settlement before the genesis signature can
          // complete the founding quorum.
          expect(
            transport.calls.last.$1,
            settlement.RoomService.submitRoomSetupSignatures.procedure,
          );
          expect(sender.sent.single.type, RoomEventType.stawiGenesisSignature);
        },
      );

      test('a refused setup still sends the genesis signature', () async {
        genesisWithSetupOnSettlement();
        transport.on(
          settlement.RoomService.submitRoomSetupSignatures,
          (_) => throw connect.ConnectException(
            connect.Code.failedPrecondition,
            'no setup now',
          ),
        );
        final service = roomService();
        final signed = await service.submitGenesisSignature(
          await service.prepareGenesisSignature(card()),
        );
        expect(signed.setupSigned, isFalse);
        expect(signed.setupError, isA<connect.ConnectException>());
        expect(sender.sent.single.type, RoomEventType.stawiGenesisSignature);
      });

      test('a setup that fails the device check is not signed', () async {
        final forged = setupDigestsFor(
          account: account,
          governance: setupGovernance,
          custody: setupCustody,
          chainId: BigInt.parse(roomGenesis.chainId.toStringUnsigned()),
          deadline: now.add(const Duration(days: 14)),
        )..[2].payloadHash = Uint8List(32);
        genesisWithSetupOnSettlement(digests: forged);
        final service = roomService();
        final prepared = await service.prepareGenesisSignature(card());
        expect(prepared.setupDigests, isEmpty);
        expect(
          prepared.setupProblem,
          'a setup step\'s document is not the one it proposes',
        );
        final signed = await service.submitGenesisSignature(prepared);
        expect(signed.setupSigned, isFalse);
        expect(
          transport.requestsTo(
            settlement.RoomService.submitRoomSetupSignatures,
          ),
          isEmpty,
        );
        expect(sender.sent, hasLength(1));
      });

      test('a merry-go-round founder signs the rotation grant beside the '
          'genesis only once finance names the RotationModule', () async {
        List<settlement.RoomSetupDigest> rotationDigests() => setupDigestsFor(
          account: account,
          governance: setupGovernance,
          custody: setupCustody,
          chainId: BigInt.parse(roomGenesis.chainId.toStringUnsigned()),
          deadline: now.add(const Duration(days: 14)),
          steps: const [
            settlement
                .RoomSetupStepKind
                .ROOM_SETUP_STEP_KIND_GRANT_RULES_ENGINE,
            settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_GRANT_ROTATION,
            settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_RULES_TEMPLATE,
          ],
        );
        genesisWithSetupOnSettlement(digests: rotationDigests());
        final named = await roomService(
          rotationModules: (id) async => rotationModuleBinding(),
        ).prepareGenesisSignature(card());
        expect(named.setupDigests, hasLength(3));
        expect(named.setupProblem, isNull);

        // Before the room is on chain finance may name no module: the
        // genesis is still signed, the setup later.
        final unnamed = await roomService(
          rotationModules: (id) async =>
              throw connect.ConnectException(connect.Code.notFound, 'no room'),
        ).prepareGenesisSignature(card());
        expect(unnamed.setupDigests, isEmpty);
        expect(unnamed.setupProblem, rotationModuleUnknownReason);
        expect(unnamed.digest, named.digest);
      });

      test(
        'a founder who already signed the setup signs only the genesis',
        () async {
          genesisWithSetupOnSettlement(signed: true);
          final service = roomService();
          final prepared = await service.prepareGenesisSignature(card());
          expect(prepared.setupDigests, isEmpty);
          expect(prepared.setupProblem, isNull);
        },
      );
    });

    group('a setup awaiting a founder\'s signature', () {
      settlement.RoomSetup awaiting({
        int firstNonce = 3,
      }) => settlement.RoomSetup(
        chatRoomId: roomId,
        governance: room.governance,
        custody: room.custody,
        state: settlement.RoomSetupState.ROOM_SETUP_STATE_AWAITING_SIGNATURE,
        needsSignatures: setupDigestsFor(
          account: account,
          governance: room.governance!,
          custody: room.custody!,
          chainId: room.chainId,
          deadline: now.add(const Duration(days: 7)),
          firstNonce: firstNonce,
          steps: const [
            settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_GRANT_LOAN_ENGINE,
            settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_RULES_TEMPLATE,
          ],
        ),
      );

      test(
        'is checked against the room\'s contracts and signed once',
        () async {
          transport
            ..on(
              settlement.RoomService.getRoomSetup,
              (_) => settlement.GetRoomSetupResponse(setup: awaiting()),
            )
            ..on(
              settlement.RoomService.submitRoomSetupSignatures,
              (req) => settlement.SubmitRoomSetupSignaturesResponse(
                setup: settlement.RoomSetup(
                  state: settlement.RoomSetupState.ROOM_SETUP_STATE_PROPOSING,
                ),
              ),
            );
          final service = roomService();
          final prepared = await service.prepareSetupSignatures(roomId);
          expect(gate.reasons, isEmpty);
          expect(prepared.review.lines.map((l) => l.$2), [
            'Turn on the loan book',
            'Adopt the room\'s dues and loan rules',
          ]);
          final after = await service.submitSetupSignatures(prepared);
          expect(
            after.state,
            settlement.RoomSetupState.ROOM_SETUP_STATE_PROPOSING,
          );
          expect(gate.reasons, [prepared.review.title]);
          final sent = transport
              .requestsTo(settlement.RoomService.submitRoomSetupSignatures)
              .single;
          expect(sent.signatures, hasLength(2));
        },
      );

      test('a merry-go-round\'s rotation grant is signed only for the '
          'protocol\'s RotationModule as finance names it', () async {
        final rotationSetup = awaiting()
          ..needsSignatures.clear()
          ..needsSignatures.addAll(
            setupDigestsFor(
              account: account,
              governance: room.governance!,
              custody: room.custody!,
              chainId: room.chainId,
              deadline: now.add(const Duration(days: 7)),
              firstNonce: 3,
              steps: const [
                settlement
                    .RoomSetupStepKind
                    .ROOM_SETUP_STEP_KIND_GRANT_ROTATION,
                settlement
                    .RoomSetupStepKind
                    .ROOM_SETUP_STEP_KIND_RULES_TEMPLATE,
              ],
            ),
          );
        transport.on(
          settlement.RoomService.getRoomSetup,
          (_) => settlement.GetRoomSetupResponse(setup: rotationSetup),
        );
        final asked = <String>[];
        final prepared = await roomService(
          rotationModules: (id) async {
            asked.add(id);
            return rotationModuleBinding();
          },
        ).prepareSetupSignatures(roomId);
        expect(asked, [roomId]);
        expect(
          prepared.review.lines.map((l) => l.$2).first,
          'Turn on the rotation payouts',
        );

        await expectLater(
          roomService(
            rotationModules: (id) async =>
                rotationModuleBinding(address: Uint8List(20)..[0] = 0xee),
          ).prepareSetupSignatures(roomId),
          throwsA(
            isA<SigningRefused>().having(
              (e) => e.reason,
              'reason',
              contains('another module than the protocol\'s rotation module'),
            ),
          ),
        );
        await expectLater(
          roomService(
            rotationModules: (id) async =>
                rotationModuleBinding(registered: false),
          ).prepareSetupSignatures(roomId),
          throwsA(
            isA<SigningRefused>().having(
              (e) => e.reason,
              'reason',
              contains('not registered'),
            ),
          ),
        );
        await expectLater(
          roomService().prepareSetupSignatures(roomId),
          throwsA(isA<SigningRefused>()),
        );
      });

      test('naming other contracts than the room\'s is refused', () async {
        transport.on(
          settlement.RoomService.getRoomSetup,
          (_) => settlement.GetRoomSetupResponse(
            setup: awaiting()..governance = (Uint8List(20)..[0] = 9),
          ),
        );
        await expectLater(
          roomService().prepareSetupSignatures(roomId),
          throwsA(
            isA<SigningRefused>().having(
              (e) => e.reason,
              'reason',
              'the setup names other contracts than the room\'s',
            ),
          ),
        );
      });
    });

    test('a member who is not a founder cannot sign', () async {
      genesisOnSettlement();
      await expectLater(
        signGenesis(card(founders: const ['p2'])),
        throwsA(isA<SigningRefused>()),
      );
      expect(transport.calls, isEmpty);
      expect(sender.sent, isEmpty);
    });
  });

  group('account flows', () {
    StawiAccountService accountService({
      GenesisSessionProofs? proofs,
      StawiIdentity? identity,
    }) => StawiAccountService(
      roomAssets: testRoomAssets,
      accounts: settlement.AccountServiceClient(transport),
      keys: keys,
      proofs:
          proofs ??
          ({required Uint8List deviceAddress}) async =>
              Uint8List.fromList(utf8.encode('proof')),
      identity: () async => identity ?? identityWith('p1', account),
    );

    test('a profile with no account cannot deploy', () async {
      await expectLater(
        accountService(
          identity: const StawiIdentity(profileId: 'p1', accounts: []),
        ).deploy(),
        throwsA(isA<StawiUnavailable>()),
      );
      expect(transport.calls, isEmpty);
    });

    test('status reports whether this device key is registered', () async {
      transport.on(
        settlement.AccountService.getAccount,
        (req) => settlement.GetAccountResponse(
          account: settlement.AccountState(
            address: req.address,
            deployed: true,
            keys: [settlement.AccountKey(key: key.address, active: true)],
          ),
        ),
      );
      final status = await accountService().status();
      expect(status.deployed, isTrue);
      expect(status.deviceRegistered, isTrue);
      expect(status.account!.address, account);
    });

    group('adding a device key', () {
      final v = GoVaultVectors.load().addKeys.firstWhere((k) => !k.p256);
      // The deployment's chain, from the app's configuration.
      final chain = BigInt.parse(v.intent.domain.chainId.toStringUnsigned());
      StawiAccountService service({
        BigInt? deploymentChainId,
        UnconfirmedMoneyCallStore? unconfirmed,
      }) => StawiAccountService(
        roomAssets: testRoomAssets,
        accounts: settlement.AccountServiceClient(transport),
        keys: keys,
        proofs: ({required Uint8List deviceAddress}) async => Uint8List(0),
        identity: () async => identityWith('p1', v.account),
        deploymentChainId: deploymentChainId ?? chain,
        followEvery: Duration.zero,
        unconfirmed: unconfirmed,
      );
      void prepares(settlement.PrepareAccountCallResponse prepared) {
        transport
          ..on(settlement.AccountService.prepareAccountCall, (req) => prepared)
          ..on(
            settlement.AccountService.submitAccountCall,
            (req) => settlement.SubmitAccountCallResponse(
              call: settlement.AccountCall(
                callId: req.callId,
                state: settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED,
              ),
            ),
          );
      }

      test('prepares, checks, reviews, then signs behind the lock', () async {
        prepares(v.prepared());
        final prepared = await service().prepareAddKey(v.key);
        // Nothing is signed while the person reviews it.
        expect(gate.reasons, isEmpty);
        expect(prepared.digest, v.digest);
        expect(prepared.review.title, 'Add a device to your Stawi account');
        expect(prepared.review.lines, [
          ('Device key', bytesToHex0x(v.key).toLowerCase()),
          ('Becomes active', 'after 24 hours'),
        ]);
        final request = transport
            .requestsTo(settlement.AccountService.prepareAccountCall)
            .single;
        expect(
          request.kind,
          settlement.AccountCallKind.ACCOUNT_CALL_KIND_ADD_KEY,
        );
        expect(request.params.key, v.key);

        final call = await service().submit(prepared);
        expect(
          call.state,
          settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED,
        );
        final submit = transport
            .requestsTo(settlement.AccountService.submitAccountCall)
            .single;
        expect(
          recoverDeviceAddress(v.digest, submit.authorization),
          key.address,
        );
        expect(gate.reasons, ['Add a device to your Stawi account']);
      });

      final other = Uint8List(20)..[19] = 0x99;
      final cases = <String, settlement.PrepareAccountCallResponse Function()>{
        'the op adds another key': () => v.prepared(opKey: other),
        'the op is not an add-key': () => v.prepared(opKind: opAddKeyP256),
        'no op is returned': () => v.prepared(withOp: false),
        'the intent binds another op': () =>
            v.prepared(intent: v.intent..authorizationId = addKeyOpHash(other)),
        'the digest is not the intent\'s': () =>
            v.prepared(digestOverride: Uint8List(32)..[0] = 1),
        'the intent is for another account': () =>
            v.prepared(intent: v.intent..account = other),
        'the intent moves money': () =>
            v.prepared(intent: v.intent..amount = '1'),
      };
      for (final MapEntry(key: name, value: build) in cases.entries) {
        test('refused when $name; nothing is signed', () async {
          prepares(build());
          await expectLater(
            service().prepareAddKey(v.key),
            throwsA(isA<SigningRefused>()),
          );
          expect(gate.reasons, isEmpty);
          expect(
            transport.requestsTo(settlement.AccountService.submitAccountCall),
            isEmpty,
          );
        });
      }

      test('refused when the intent is for another chain than the '
          'deployment\'s; nothing is signed', () async {
        // Settlement's intent names its own chain consistently (the digest
        // is the intent's own); the device holds it to the configured one.
        prepares(v.prepared());
        await expectLater(
          service(deploymentChainId: chain + BigInt.one).prepareAddKey(v.key),
          throwsA(isA<SigningRefused>()),
        );
        final other = v.intent..domain.chainId += 1;
        prepares(v.prepared(intent: other));
        await expectLater(
          service().prepareAddKey(v.key),
          throwsA(isA<SigningRefused>()),
        );
        expect(gate.reasons, isEmpty);
      });

      test('a refused device lock adds no key', () async {
        prepares(v.prepared());
        final prepared = await service().prepareAddKey(v.key);
        gate.refuse = true;
        await expectLater(
          service().submit(prepared),
          throwsA(isA<SigningRefused>()),
        );
        expect(
          transport.requestsTo(settlement.AccountService.submitAccountCall),
          isEmpty,
        );
      });

      group('waits while a payment is unconfirmed', () {
        Future<EarlierMoneyCall> heldBack(
          settlement.GetAccountCallResponse Function() read,
        ) async {
          final store = MemoryUnconfirmedMoneyCallStore();
          await store.hold(
            'p1',
            SignedMoneyCall(
              callId: 'acct-earlier',
              authorization: Uint8List(65),
              title: 'Pay 500.00 USDC into Chama',
            ),
          );
          prepares(v.prepared());
          transport.on(
            settlement.AccountService.getAccountCall,
            (req) => read(),
          );
          try {
            await service(unconfirmed: store).prepareAddKey(v.key);
          } on EarlierMoneyCall catch (e) {
            expect(e.heldBack, HeldBack.keyChange);
            expect(
              transport.requestsTo(
                settlement.AccountService.prepareAccountCall,
              ),
              isEmpty,
              reason: 'nothing is prepared while it waits',
            );
            return e;
          }
          fail('the key change was not held back');
        }

        test(
          'an unknown payment: the device is added once it is known',
          () async {
            final e = await heldBack(
              () => throw connect.ConnectException(
                connect.Code.unavailable,
                'down',
              ),
            );
            expect(
              stawiErrorMessage(e),
              'Could not confirm “Pay 500.00 USDC into Chama” went through; a '
              'device can be added once it is known. Check again shortly',
            );
          },
        );

        test(
          'a payment found sent is named, and the key change waits',
          () async {
            final e = await heldBack(
              () => settlement.GetAccountCallResponse(
                call: settlement.AccountCall(
                  callId: 'acct-earlier',
                  state:
                      settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED,
                ),
              ),
            );
            expect(
              stawiErrorMessage(e),
              '“Pay 500.00 USDC into Chama” was sent and is being confirmed. '
              'Add the device once it is; try again shortly',
            );
          },
        );

        test('a payment found not paid frees the key change', () async {
          final e = await heldBack(
            () => settlement.GetAccountCallResponse(
              call: settlement.AccountCall(
                callId: 'acct-earlier',
                state: settlement.AccountCallState.ACCOUNT_CALL_STATE_EXPIRED,
              ),
            ),
          );
          expect(
            stawiErrorMessage(e),
            '“Pay 500.00 USDC into Chama” was not sent: It expired before it '
            'went through; nothing was paid. You can add the device now',
          );
        });
      });

      test('a malformed key id is never prepared', () async {
        await expectLater(
          service().prepareAddKey(Uint8List(20)),
          throwsA(isA<FormatException>()),
        );
        expect(transport.calls, isEmpty);
      });
    });

    test('a refused device lock deploys nothing', () async {
      gate.refuse = true;
      await expectLater(
        accountService().deploy(),
        throwsA(isA<SigningRefused>()),
      );
      expect(gate.reasons, ['Set up your Stawi account']);
      expect(
        transport.requestsTo(settlement.AccountService.deployAccount),
        isEmpty,
      );
    });
  });

  group('personal money calls', () {
    final personal = {
      for (final v in GoEngineCallVector.load().where((v) => v.personal))
        v.name: v,
    };
    final pay = personal['pay']!;
    final vault = hexToBytes('0x909192939495969798999a9b9c9d9e9fa0a1a2a3');
    final book = hexToBytes('0x101112131415161718191a1b1c1d1e1f20212223');
    final pool = hexToBytes('0xb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3');
    final targets = PersonalTargets.fromResponse(
      vault: vault,
      loanBooks: [book],
    );
    late RecordingSigningGate payGate;
    late FakeConnectTransport t;

    finance.Loan payable() => finance.Loan(
      pool: pool,
      lender: pool,
      borrowerAccount: pay.account,
      loanBook: book,
      onchainLoanId: Int64(1),
      requested: finance.Money(amount: '300000000'),
      kind: finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON,
      state: finance.LoanState.LOAN_STATE_FUNDED,
    );

    StawiAccountService service({Future<PersonalTargets> Function()? read}) =>
        StawiAccountService(
          roomAssets: testRoomAssets,
          accounts: settlement.AccountServiceClient(t),
          keys: DeviceKeyStore(
            vaultWith('p1', pay.devicePrivateKey),
            gate: payGate,
          ),
          proofs: refusingSessionProofs,
          identity: () async => identityWith('p1', pay.account),
          targets: read ?? () async => targets,
          readyEvery: Duration.zero,
          readyAttempts: 2,
        );

    setUp(() async {
      payGate = RecordingSigningGate();
      t = FakeConnectTransport()
        ..on(
          settlement.AccountService.prepareAccountCall,
          (req) => pay.prepared(req.kind),
        )
        ..on(
          settlement.AccountService.getAsset,
          (req) => settlement.GetAssetResponse(asset: usdcInfo),
        )
        ..on(
          settlement.AccountService.submitAccountCall,
          (req) => settlement.SubmitAccountCallResponse(
            call: settlement.AccountCall(callId: req.callId),
          ),
        );
      await serveDeployedAccount(t, pay.devicePrivateKey);
    });

    test(
      'pays an instalment: checked, reviewed, signed as the vector',
      () async {
        final s = service();
        final prepared = await s.preparePersonal(
          PersonalRequest.pay(loan: payable(), amount: BigInt.from(52000000)),
        );
        expect(prepared.review.title, 'Pay an instalment');
        expect(prepared.review.lines, contains(('Amount', '52.00 USDC')));
        expect(prepared.digest, pay.digest);
        expect(payGate.reasons, isEmpty, reason: 'preparing signs nothing');

        final sent = t
            .requestsTo(settlement.AccountService.prepareAccountCall)
            .single;
        expect(
          sent.kind,
          settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_PAY,
        );
        expect(sent.params.loanBook, book);

        await s.submit(prepared);
        // The device lock showed the plain title, never a kind name.
        expect(payGate.reasons, ['Pay an instalment']);
        final submit = t
            .requestsTo(settlement.AccountService.submitAccountCall)
            .single;
        expect(bytesToHex0x(submit.authorization), pay.signature);
      },
    );

    test('an offer is titled with the person and the amount', () async {
      final offer = personal['offer']!;
      t.on(
        settlement.AccountService.prepareAccountCall,
        (req) => offer.prepared(req.kind),
      );
      final terms = offer.json['terms'] as Map<String, dynamic>;
      final s = service();
      final prepared = await s.preparePersonal(
        PersonalRequest.offer(
          borrower: pool,
          pocket: Uint8List(32),
          amount: BigInt.from(300000000),
          terms: LoanTerms.fromSdk(
            PersonalTerms(
              n: terms['n'] as int,
              everyDays: terms['every_days'] as int,
              method: terms['method'] as int,
              rateBps: terms['rate_bps'] as int,
              lateMethod: terms['late_method'] as int,
              lateBps: terms['late_bps'] as int,
              lateFlat: BigInt.parse(terms['late_flat'] as String),
              defaultAfterDays: terms['default_after_days'] as int,
            ),
          ),
          expiresAt: DateTime.fromMillisecondsSinceEpoch(
            1760000000 * 1000,
            isUtc: true,
          ),
        ),
        counterpartyName: 'Amina',
      );
      expect(prepared.review.title, 'Lend 300.00 USDC to Amina');
      await s.submit(prepared);
      expect(payGate.reasons, ['Lend 300.00 USDC to Amina']);
    });

    test(
      'an account that is not ready is brought up before anything',
      () async {
        t.on(
          settlement.AccountService.getAccount,
          (req) => settlement.GetAccountResponse(
            account: settlement.AccountState(address: req.address),
          ),
        );
        t.on(
          settlement.AccountService.prepareDeployAccount,
          (req) => throw StateError('deploy attempted'),
        );
        await expectLater(
          service().preparePersonal(
            PersonalRequest.pay(loan: payable(), amount: BigInt.from(52000000)),
          ),
          throwsA(anything),
        );
        expect(
          t.requestsTo(settlement.AccountService.prepareAccountCall),
          isEmpty,
        );
      },
    );

    test('a refused check submits nothing', () async {
      final other = personal['personal_cancel']!;
      t.on(
        settlement.AccountService.prepareAccountCall,
        (req) => other.prepared(req.kind),
      );
      await expectLater(
        service().preparePersonal(
          PersonalRequest.pay(loan: payable(), amount: BigInt.from(52000000)),
        ),
        throwsA(isA<SigningRefused>()),
      );
      expect(
        t.requestsTo(settlement.AccountService.submitAccountCall),
        isEmpty,
      );
    });

    test('unreadable personal targets refuse the call', () async {
      await expectLater(
        service(
          read: () async => throw StateError('finance down'),
        ).preparePersonal(
          PersonalRequest.pay(loan: payable(), amount: BigInt.from(52000000)),
        ),
        throwsA(isA<SigningRefused>()),
      );
    });

    test('a refused device lock submits nothing', () async {
      final s = service();
      final prepared = await s.preparePersonal(
        PersonalRequest.pay(loan: payable(), amount: BigInt.from(52000000)),
      );
      payGate.refuse = true;
      await expectLater(s.submit(prepared), throwsA(isA<SigningRefused>()));
      expect(
        t.requestsTo(settlement.AccountService.submitAccountCall),
        isEmpty,
      );
    });

    test(
      'the wallet balance is the account\'s, and unknown when empty',
      () async {
        await serveDeployedAccount(
          t,
          pay.devicePrivateKey,
          balance: '12500000',
        );
        expect(await service().walletBalance(), BigInt.from(12500000));
        await serveDeployedAccount(t, pay.devicePrivateKey);
        expect(await service().walletBalance(), isNull);
      },
    );

    test('a standing order is on when the account holds its id', () async {
      final loan = payable();
      final ref = LoanRef.of(loan);
      final id = standingOrderId(ref.loanBook, ref.pool, ref.loanId);
      await serveDeployedAccount(
        t,
        pay.devicePrivateKey,
        authorizationIds: [id],
      );
      expect(await service().standingOrderOn(loan), isTrue);
      await serveDeployedAccount(
        t,
        pay.devicePrivateKey,
        authorizationIds: [Uint8List(32)],
      );
      expect(await service().standingOrderOn(loan), isFalse);
    });

    test('a deposit is checked against the pocket and signed', () async {
      final d = GoVaultVectors.load().deposits.first;
      t.on(settlement.AccountService.prepareAccountCall, (req) => d.prepared);
      final s = StawiAccountService(
        roomAssets: testRoomAssets,
        accounts: settlement.AccountServiceClient(t),
        keys: DeviceKeyStore(
          vaultWith('p1', pay.devicePrivateKey),
          gate: payGate,
        ),
        proofs: refusingSessionProofs,
        identity: () async => identityWith('p1', d.account),
        targets: () async => d.targets,
      );
      await serveDeployedAccount(t, pay.devicePrivateKey);
      final prepared = await s.prepareDeposit(
        pocket: d.pocket,
        amount: d.amount,
      );
      expect(prepared.digest, d.digest);
      expect(prepared.review.title, 'Add 50.00 USDC to Free savings');
      // Another pocket than the one asked for is refused.
      await expectLater(
        s.prepareDeposit(pocket: Uint8List(32)..[0] = 7, amount: d.amount),
        throwsA(isA<SigningRefused>()),
      );
    });

    test('a standing order is granted only after the SDK check', () async {
      final g = GoVaultVectors.load().standingGrants.first;
      t.on(settlement.AccountService.prepareAccountCall, (req) => g.prepared);
      await serveDeployedAccount(t, pay.devicePrivateKey, policyAsset: g.asset);
      final s = StawiAccountService(
        roomAssets: testRoomAssets,
        accounts: settlement.AccountServiceClient(t),
        keys: DeviceKeyStore(
          vaultWith('p1', pay.devicePrivateKey),
          gate: payGate,
        ),
        proofs: refusingSessionProofs,
        identity: () async => identityWith('p1', g.account),
        targets: () async => g.targets,
      );
      final prepared = await s.prepareStandingOrder(g.loan, on: true);
      expect(prepared.digest, g.digest);
      expect(prepared.review.title, 'Pay automatically');
      final sent = t
          .requestsTo(settlement.AccountService.prepareAccountCall)
          .single;
      expect(
        sent.kind,
        settlement.AccountCallKind.ACCOUNT_CALL_KIND_GRANT_STANDING,
      );
      // A loan that is not active gets none.
      await expectLater(
        s.prepareStandingOrder(
          g.loan..state = finance.LoanState.LOAN_STATE_PAID,
          on: true,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('a standing order is revoked by its loan\'s id', () async {
      final r = GoVaultVectors.load().standingRevokes.first;
      t.on(settlement.AccountService.prepareAccountCall, (req) => r.prepared());
      await serveDeployedAccount(t, pay.devicePrivateKey, policyAsset: r.asset);
      final s = StawiAccountService(
        roomAssets: testRoomAssets,
        accounts: settlement.AccountServiceClient(t),
        keys: DeviceKeyStore(
          vaultWith('p1', pay.devicePrivateKey),
          gate: payGate,
        ),
        proofs: refusingSessionProofs,
        identity: () async => identityWith('p1', r.account),
        targets: () async => targets,
      );
      final prepared = await s.prepareStandingOrder(r.loan, on: false);
      expect(prepared.digest, r.digest);
      expect(prepared.review.title, 'Stop paying automatically');
      final sent = t
          .requestsTo(settlement.AccountService.prepareAccountCall)
          .single;
      expect(sent.params.authorizationId, r.authorizationId);
    });

    test(
      'a retryable readiness failure is a plain, retryable message',
      () async {
        t.on(
          settlement.AccountService.getAccount,
          (req) => settlement.GetAccountResponse(
            account: settlement.AccountState(
              address: req.address,
              genesisState: 'PENDING',
            ),
          ),
        );
        await expectLater(
          service().preparePersonal(
            PersonalRequest.pay(loan: payable(), amount: BigInt.from(52000000)),
          ),
          throwsA(
            isA<StawiUnavailable>().having(
              (e) => e.message,
              'message',
              accountSetupPendingMessage,
            ),
          ),
        );
        expect(
          t.requestsTo(settlement.AccountService.prepareAccountCall),
          isEmpty,
        );
      },
    );

    test(
      'a standing order is refused when the policy asset is unknown',
      () async {
        final g = GoVaultVectors.load().standingGrants.first;
        final r = GoVaultVectors.load().standingRevokes.first;
        // serveDeployedAccount in setUp names no policy asset.
        final s = service();
        await expectLater(
          s.prepareStandingOrder(g.loan, on: true),
          throwsA(isA<SigningRefused>()),
        );
        await expectLater(
          s.prepareStandingOrder(r.loan, on: false),
          throwsA(isA<SigningRefused>()),
        );
        expect(
          t.requestsTo(settlement.AccountService.prepareAccountCall),
          isEmpty,
        );
      },
    );

    group('withdrawing to a contact', () {
      final d = GoVaultVectors.load().deposits.first;
      final bea = StawiContactAccount.forTest(
        Uint8List.fromList(List.filled(20, 0xbe)),
        name: 'Bea',
      );

      /// A TRANSFER prepared from the deposit vector's intent, sent to
      /// [to] for [amount].
      settlement.PrepareAccountCallResponse transfer(
        List<int> to,
        BigInt amount,
      ) {
        final i = d.intent
          ..destination = finance.ValueLocation(
            kind: finance.LocationKind.LOCATION_KIND_USER_ACCOUNT,
            address: to,
          )
          ..amount = amount.toString();
        final digest = sdkIntentOf(i).digest();
        return settlement.PrepareAccountCallResponse(
          callId: 'acct00000000000000t1',
          intentDigest: digest,
          financialIntent: i,
          call: settlement.AccountCall(
            callId: 'acct00000000000000t1',
            address: d.account,
            kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_TRANSFER,
            intentDigest: digest,
          ),
        );
      }

      StawiAccountService withdrawer() => StawiAccountService(
        roomAssets: testRoomAssets,
        accounts: settlement.AccountServiceClient(t),
        keys: DeviceKeyStore(
          vaultWith('p1', pay.devicePrivateKey),
          gate: payGate,
        ),
        proofs: refusingSessionProofs,
        identity: () async => identityWith('p1', d.account),
        readyEvery: Duration.zero,
        readyAttempts: 2,
      );

      test('goes to the contact\'s account, checked, then signed', () async {
        final amount = BigInt.from(5000000);
        final answer = transfer(bea.address, amount);
        t.on(settlement.AccountService.prepareAccountCall, (req) => answer);
        final s = withdrawer();
        final prepared = await s.prepareTransferOut(to: bea, amount: amount);
        final sent = t
            .requestsTo(settlement.AccountService.prepareAccountCall)
            .single;
        expect(
          sent.kind,
          settlement.AccountCallKind.ACCOUNT_CALL_KIND_TRANSFER,
        );
        expect(sent.params.destination.address, bea.address);
        expect(
          sent.params.destination.kind,
          finance.LocationKind.LOCATION_KIND_USER_ACCOUNT,
        );
        expect(sent.params.amount, '5000000');
        expect(prepared.review.title, 'Send 5.00 USDC to Bea');
        await s.submit(prepared);
        final submit = t
            .requestsTo(settlement.AccountService.submitAccountCall)
            .single;
        expect(
          recoverDeviceAddress(answer.intentDigest, submit.authorization),
          await deviceAddressOf(pay.devicePrivateKey),
        );
        expect(payGate.reasons, ['Send 5.00 USDC to Bea']);
      });

      test('refuses another destination or another amount', () async {
        final amount = BigInt.from(5000000);
        for (final answer in [
          transfer(Uint8List.fromList(List.filled(20, 0xee)), amount),
          transfer(bea.address, amount + BigInt.one),
        ]) {
          t.on(settlement.AccountService.prepareAccountCall, (req) => answer);
          await expectLater(
            withdrawer().prepareTransferOut(to: bea, amount: amount),
            throwsA(isA<SigningRefused>()),
          );
        }
        expect(
          t.requestsTo(settlement.AccountService.submitAccountCall),
          isEmpty,
        );
      });

      test('refuses no amount', () async {
        t.on(
          settlement.AccountService.prepareAccountCall,
          (req) => transfer(bea.address, BigInt.zero),
        );
        await expectLater(
          withdrawer().prepareTransferOut(to: bea, amount: BigInt.zero),
          throwsA(isA<SigningRefused>()),
        );
      });

      test(
        'the lookup builds no contact from a zero or short address',
        () async {
          for (final bad in [Uint8List(20), Uint8List(5)]) {
            final container = ProviderContainer(
              overrides: [
                counterpartyAccountsProvider.overrideWithValue(
                  (roomId) async =>
                      DirectPartnerAccount(profileId: 'p2', account: bad),
                ),
              ],
            );
            addTearDown(container.dispose);
            final sub = container.listen(
              counterpartyAccountProvider('dm-1'),
              (_, _) {},
            );
            addTearDown(sub.close);
            await expectLater(
              container.read(counterpartyAccountProvider('dm-1').future),
              throwsA(isA<StawiUnavailable>()),
            );
          }
        },
      );
    });
  });
}
