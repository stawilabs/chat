import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/data/stawi_room_service.dart';
import 'package:stawi/features/stawi/domain/governance_requests.dart';
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
  late DeviceKeyHandle key;

  setUp(() async {
    transport = FakeConnectTransport();
    sender = RecordingActSender();
    keys = DeviceKeyStore(vaultWith('p1', anvilKey));
    key = (await keys.load('p1'))!;
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
      expect(signature, isNot(key.sign(otherDigest)));
    });

    test('a founder signs their own digest, not another founder\'s', () async {
      genesisOnSettlement();
      await roomService().signGenesis(card());

      final signature = base64Decode(
        sender.sent.single.content['signature'] as String,
      );
      expect(signature, key.sign(digest));
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
    });
  });
}
