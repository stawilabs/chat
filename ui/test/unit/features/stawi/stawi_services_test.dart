import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/signing_gate.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/data/stawi_counterparty.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/data/stawi_room_service.dart';
import 'package:stawi/features/stawi/domain/governance_requests.dart';
import 'package:stawi/features/stawi/domain/intent_bridge.dart';
import 'package:stawi/features/stawi/domain/loan_terms.dart';
import 'package:stawi/features/stawi/domain/personal_calls.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi/features/stawi/domain/stawi_payloads.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

const roomId = 'room00000000000000aa';

void main() {
  final vectors = GoSignedCallVectors.load();
  // A StawiAccount (anvil_0 here) on chain 146 and a typed hash; the
  // digest the device signs is Go's AccountWrappedHash of the two.
  final wrapped = vectors.accountWrappedHashes.firstWhere(
    (v) => v['name'] == 'anvil_0/seq' && v['chain_id'] == '146',
  );
  final account = hexToBytes(wrapped['account'] as String);
  final typedHash = hexToBytes(wrapped['hash'] as String);
  final digest = hexToBytes(wrapped['wrapped'] as String);

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

  StawiRoomService roomService() => StawiRoomService(
    rooms: settlement.RoomServiceClient(transport),
    keys: keys,
    identity: () async => identityWith('p1', account),
    send: sender.call,
  );

  group('signed room calls', () {
    void preparesInvite({List<int>? digestOverride}) {
      transport.on(settlement.RoomService.prepareRoomCall, (req) {
        expect(req.chatRoomId, roomId);
        return settlement.PrepareRoomCallResponse(
          callId: 'call0000000000000001',
          digest: digestOverride ?? digest,
          signer: account,
          call: settlement.RoomCall(
            callId: 'call0000000000000001',
            chainId: Int64(146),
            chatRoomId: roomId,
            kind: req.kind,
            signer: account,
            typedHash: typedHash,
            requiresSignature: true,
          ),
        );
      });
    }

    test(
      'prepares, signs the checked digest and sends STAWI_SIGNED_CALL',
      () async {
        preparesInvite();
        final request = inviteRequest(profileId: 'p2', name: 'Amina');

        await roomService().signedCall(
          roomId: roomId,
          kind: request.kind,
          params: request.params,
          summary: request.summary,
        );

        final prepared = transport
            .requestsTo(settlement.RoomService.prepareRoomCall)
            .single;
        expect(prepared.kind, settlement.RoomCallKind.ROOM_CALL_KIND_INVITE);
        expect(prepared.params.officer.subject.profileId, 'p2');

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
        expect(recoverDeviceAddress(digest, signature), key.address);
      },
    );

    test('never signs or sends a substituted digest', () async {
      preparesInvite(digestOverride: Uint8List(32));
      await expectLater(
        roomService().signedCall(
          roomId: roomId,
          kind: settlement.RoomCallKind.ROOM_CALL_KIND_INVITE,
          summary: 'Invite',
        ),
        throwsA(isA<SigningRefused>()),
      );
      expect(sender.sent, isEmpty);
    });

    test('a vote carries the proposal and choice', () async {
      preparesInvite();
      final request = voteRequest(
        onchainProposalId: 7,
        choice: finance.VoteChoice.VOTE_CHOICE_REJECT,
      );
      await roomService().signedCall(
        roomId: roomId,
        kind: request.kind,
        params: request.params,
        summary: request.summary,
      );
      final prepared = transport
          .requestsTo(settlement.RoomService.prepareRoomCall)
          .single;
      expect(prepared.params.vote.onchainProposalId, Int64(7));
      expect(
        prepared.params.vote.choice,
        finance.VoteChoice.VOTE_CHOICE_REJECT,
      );
      expect(sender.sent.single.content['kind'], 'CAST_VOTE');
      expect(gate.reasons, [request.summary]);
    });

    test('the device lock is asked with the call summary first', () async {
      preparesInvite();
      final request = inviteRequest(profileId: 'p2', name: 'Amina');
      await roomService().signedCall(
        roomId: roomId,
        kind: request.kind,
        params: request.params,
        summary: request.summary,
      );
      expect(gate.reasons, ['Invite Amina']);
    });

    test('a refused device lock signs and sends nothing', () async {
      preparesInvite();
      gate.refuse = true;
      await expectLater(
        roomService().signedCall(
          roomId: roomId,
          kind: settlement.RoomCallKind.ROOM_CALL_KIND_INVITE,
          summary: 'Invite Amina',
        ),
        throwsA(isA<SigningRefused>()),
      );
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
          'genesisHash': base64Encode(typedHash),
          'constitutionHash': base64Encode(Uint8List(32)),
          'founderProfileIds': founders,
        },
      },
    );

    // Another founder's account and its own wrapping of the genesis hash:
    // every founder signs their own digest, never a shared one.
    final otherAccount = Uint8List.fromList(List.filled(20, 0xbb));
    final otherDigest = keccak256(Uint8List.fromList([9, 9, 9]));

    void genesisOnSettlement() {
      transport.on(
        settlement.RoomService.getRoomGenesis,
        (req) => settlement.GetRoomGenesisResponse(
          genesis: settlement.RoomGenesis(
            genesisId: req.genesisId,
            chatRoomId: roomId,
            state: settlement.RoomGenesisState.ROOM_GENESIS_STATE_PENDING,
            chainId: Int64(146),
            genesisHash: typedHash,
            founders: [
              settlement.RoomFounder(
                profileId: 'p2',
                account: otherAccount,
                signingDigest: otherDigest,
              ),
              settlement.RoomFounder(
                profileId: 'p1',
                account: account,
                signingDigest: digest,
              ),
            ],
          ),
        ),
      );
    }

    test('a founder signs the account-wrapped genesis hash', () async {
      genesisOnSettlement();
      await roomService().signGenesis(card());

      final act = sender.sent.single;
      expect(act.type, RoomEventType.stawiGenesisSignature);
      expect(act.parentId, 'conv1');
      expect(act.content['genesisId'], 'gen00000000000000001');
      expect(act.content['signerKeyId'], key.keyId);
      final signature = base64Decode(act.content['signature'] as String);
      expect(recoverDeviceAddress(digest, signature), key.address);
      expect(signature, isNot(signer.sign(otherDigest)));
    });

    test('the device lock names the room being founded', () async {
      genesisOnSettlement();
      await roomService().signGenesis(card(), roomName: 'Kampala Savers');
      expect(gate.reasons, ['Found Kampala Savers on Stawi']);
      expect(sender.sent, hasLength(1));
    });

    test('a refused device lock sends no genesis signature', () async {
      genesisOnSettlement();
      gate.refuse = true;
      await expectLater(
        roomService().signGenesis(card()),
        throwsA(isA<SigningRefused>()),
      );
      expect(gate.reasons, ['Found this room on Stawi']);
      expect(sender.sent, isEmpty);
    });

    test('a founder signs their own digest, not another founder\'s', () async {
      genesisOnSettlement();
      await roomService().signGenesis(card());

      final signature = base64Decode(
        sender.sent.single.content['signature'] as String,
      );
      expect(signature, signer.sign(digest));
      expect(recoverDeviceAddress(otherDigest, signature), isNot(key.address));
    });

    test('a member who is not a founder cannot sign', () async {
      genesisOnSettlement();
      await expectLater(
        roomService().signGenesis(card(founders: const ['p2'])),
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

    test('adding a device key signs the prepared intent digest', () async {
      final newKey = Uint8List.fromList(List.filled(20, 0x42));
      transport.on(
        settlement.AccountService.prepareAccountCall,
        (req) => settlement.PrepareAccountCallResponse(
          callId: 'acct000000000000000a',
          intentDigest: digest,
          call: settlement.AccountCall(
            callId: 'acct000000000000000a',
            address: req.address,
            kind: req.kind,
            intentDigest: digest,
          ),
        ),
      );
      transport.on(
        settlement.AccountService.submitAccountCall,
        (req) => settlement.SubmitAccountCallResponse(
          call: settlement.AccountCall(
            callId: req.callId,
            state: settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED,
          ),
        ),
      );

      final call = await accountService().addDeviceKey(newKey);
      expect(
        call.state,
        settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED,
      );

      final prepare = transport
          .requestsTo(settlement.AccountService.prepareAccountCall)
          .single;
      expect(
        prepare.kind,
        settlement.AccountCallKind.ACCOUNT_CALL_KIND_ADD_KEY,
      );
      expect(prepare.params.key, newKey);
      final submit = transport
          .requestsTo(settlement.AccountService.submitAccountCall)
          .single;
      expect(recoverDeviceAddress(digest, submit.authorization), key.address);
      expect(gate.reasons, ['Add a device to your Stawi account']);
    });

    test('a refused device lock adds no key', () async {
      gate.refuse = true;
      await expectLater(
        accountService().addDeviceKey(Uint8List(20)),
        throwsA(isA<SigningRefused>()),
      );
      expect(
        transport.requestsTo(settlement.AccountService.submitAccountCall),
        isEmpty,
      );
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
