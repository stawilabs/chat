import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/data/stawi_custody.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

void main() {
  final genesis = GoGenesisVector.load();
  late FakeConnectTransport transport;

  setUp(() => transport = FakeConnectTransport());

  StawiAccountService service(
    DeviceKeyStore keys,
    StawiIdentity identity, {
    GenesisSessionProofs? proofs,
  }) => StawiAccountService(
    accounts: settlement.AccountServiceClient(transport),
    keys: keys,
    proofs:
        proofs ??
        ({required Uint8List deviceAddress}) async =>
            Uint8List.fromList(utf8.encode('proof')),
    identity: () async => identity,
  );

  group('deploy digest check', () {
    test('rebuilds every Go genesis digest before signing it', () {
      for (final v in genesis) {
        final digest = checkedDeployDigest(
          prepared: v.prepared,
          account: v.account,
          identitySaltHash: v.identitySaltHash,
          device: v.device,
        );
        expect(digest, v.digest, reason: v.name);
        expect(accountPolicyFrom(v.policy).hash, v.policyHash, reason: v.name);
      }
    });

    test('refuses a digest, policy hash, salt or device that differs', () {
      final v = genesis.first;
      Object refusal(void Function() f) {
        try {
          f();
        } on SigningRefused catch (e) {
          return e;
        }
        fail('not refused');
      }

      final badDigest = v.prepared..genesisDigest = Uint8List(32);
      expect(
        refusal(
          () => checkedDeployDigest(
            prepared: badDigest,
            account: v.account,
            identitySaltHash: v.identitySaltHash,
            device: v.device,
          ),
        ),
        isA<SigningRefused>(),
      );
      final badHash = v.prepared..initialPolicyHash = Uint8List(32);
      expect(
        refusal(
          () => checkedDeployDigest(
            prepared: badHash,
            account: v.account,
            identitySaltHash: v.identitySaltHash,
            device: v.device,
          ),
        ),
        isA<SigningRefused>(),
      );
      // A policy other than the one hashed: the digest no longer matches.
      final otherPolicy = v.prepared
        ..initialPolicy.periodLimit = '1'
        ..initialPolicyHash = accountPolicyFrom(
          v.policy..periodLimit = '1',
        ).hash;
      expect(
        refusal(
          () => checkedDeployDigest(
            prepared: otherPolicy,
            account: v.account,
            identitySaltHash: v.identitySaltHash,
            device: v.device,
          ),
        ),
        isA<SigningRefused>(),
      );
      for (final salt in [null, Uint8List(32)]) {
        expect(
          refusal(
            () => checkedDeployDigest(
              prepared: v.prepared,
              account: v.account,
              identitySaltHash: salt,
              device: v.device,
            ),
          ),
          isA<SigningRefused>(),
        );
      }
      expect(
        refusal(
          () => checkedDeployDigest(
            prepared: v.prepared,
            account: v.account,
            identitySaltHash: v.identitySaltHash,
            device: Uint8List(20),
          ),
        ),
        isA<SigningRefused>(),
      );
    });
  });

  group('deploy', () {
    final v = genesis.firstWhere((v) => v.name == 'settlement_default');

    void fakeSettlement({settlement.PrepareDeployAccountResponse? prepared}) {
      transport
        ..on(
          settlement.AccountService.prepareDeployAccount,
          (req) => prepared ?? v.prepared,
        )
        ..on(
          settlement.AccountService.deployAccount,
          (req) => settlement.DeployAccountResponse(
            address: req.address,
            genesisState: 'PENDING',
          ),
        );
    }

    test('signs the Go genesis digest byte for byte', () async {
      fakeSettlement();
      final keys = DeviceKeyStore(vaultWith('p1', v.devicePrivateKey));
      final key = (await keys.load('p1'))!;
      final response = await service(keys, v.identity('p1')).deploy();
      expect(response.genesisState, 'PENDING');

      final prepare = transport
          .requestsTo(settlement.AccountService.prepareDeployAccount)
          .single;
      expect(prepare.address, v.account);
      expect(prepare.deviceKey.publicKey, key.publicKey);
      final deploy = transport
          .requestsTo(settlement.AccountService.deployAccount)
          .single;
      expect(bytesToHex0x(deploy.deviceSignature), v.signature);
      expect(deploy.sessionProof, utf8.encode('proof'));
    });

    test('a digest it cannot rebuild is never signed or sent', () async {
      fakeSettlement(prepared: v.prepared..genesisDigest = Uint8List(32));
      final keys = DeviceKeyStore(vaultWith('p1', v.devicePrivateKey));
      await expectLater(
        service(keys, v.identity('p1')).deploy(),
        throwsA(isA<SigningRefused>()),
      );
      expect(
        transport.requestsTo(settlement.AccountService.deployAccount),
        isEmpty,
      );
    });

    test('without a session proof source nothing is deployed', () async {
      fakeSettlement();
      final keys = DeviceKeyStore(vaultWith('p1', v.devicePrivateKey));
      await expectLater(
        service(
          keys,
          v.identity('p1'),
          proofs: unavailableGenesisSessionProof,
        ).deploy(),
        throwsA(isA<StawiUnavailable>()),
      );
      expect(
        transport.requestsTo(settlement.AccountService.deployAccount),
        isEmpty,
      );
    });
  });

  group('contribute', () {
    final account = Uint8List.fromList(List.filled(20, 0xac));
    final custody = Uint8List.fromList(List.filled(20, 0xc0));
    final digest = keccak256(Uint8List.fromList([1]));
    late DeviceKeyStore keys;
    late DeviceKeyHandle key;

    setUp(() async {
      keys = DeviceKeyStore(vaultWith('p1', anvilKey));
      key = (await keys.load('p1'))!;
    });

    void prepares({String? amount, Uint8List? destination}) {
      transport
        ..on(
          settlement.AccountService.prepareAccountCall,
          (req) => settlement.PrepareAccountCallResponse(
            callId: 'acct000000000000000c',
            intentDigest: digest,
            financialIntent: finance.FinancialIntent(
              type: finance.IntentType.INTENT_TYPE_CONTRIBUTION,
              account: req.address,
              destination: finance.ValueLocation(
                kind: finance.LocationKind.LOCATION_KIND_ROOM_CUSTODY,
                address: destination ?? req.params.room,
                bucket: 'SAVINGS',
              ),
              amount: amount ?? req.params.amount,
            ),
            call: settlement.AccountCall(
              callId: 'acct000000000000000c',
              address: req.address,
              kind: req.kind,
              intentDigest: digest,
            ),
          ),
        )
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

    test('prepares a CONTRIBUTE, checks it and signs its digest', () async {
      prepares();
      final call = await service(
        keys,
        identityWith('p1', account),
      ).contribute(custody: custody, amount: '2500000');
      expect(
        call.state,
        settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED,
      );

      final prepare = transport
          .requestsTo(settlement.AccountService.prepareAccountCall)
          .single;
      expect(prepare.address, account);
      expect(
        prepare.kind,
        settlement.AccountCallKind.ACCOUNT_CALL_KIND_CONTRIBUTE,
      );
      expect(prepare.params.room, custody);
      expect(prepare.params.amount, '2500000');

      final submit = transport
          .requestsTo(settlement.AccountService.submitAccountCall)
          .single;
      expect(submit.callId, 'acct000000000000000c');
      expect(
        submit.authorization,
        signPreparedCall(digest, hexToBytes(anvilKey)),
      );
      expect(recoverDeviceAddress(digest, submit.authorization), key.address);
    });

    test('refuses a call for another amount or room', () async {
      for (final setup in [
        () => prepares(amount: '9999999'),
        () => prepares(destination: Uint8List(20)),
      ]) {
        transport = FakeConnectTransport();
        setup();
        await expectLater(
          service(
            keys,
            identityWith('p1', account),
          ).contribute(custody: custody, amount: '2500000'),
          throwsA(isA<SigningRefused>()),
        );
        expect(
          transport.requestsTo(settlement.AccountService.submitAccountCall),
          isEmpty,
        );
      }
    });

    test('refuses a malformed amount before calling settlement', () async {
      for (final amount in ['', '0', '01', '-5', '1.5']) {
        await expectLater(
          service(
            keys,
            identityWith('p1', account),
          ).contribute(custody: custody, amount: amount),
          throwsFormatException,
          reason: amount,
        );
      }
      expect(transport.calls, isEmpty);
    });

    test('follows the call until it is final', () async {
      final states = [
        settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED,
        settlement.AccountCallState.ACCOUNT_CALL_STATE_INCLUDED,
        settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL,
        settlement.AccountCallState.ACCOUNT_CALL_STATE_FAILED,
      ];
      var read = 0;
      transport.on(
        settlement.AccountService.getAccountCall,
        (req) => settlement.GetAccountCallResponse(
          call: settlement.AccountCall(
            callId: req.callId,
            state: states[read++],
          ),
        ),
      );
      final seen = await service(keys, identityWith('p1', account))
          .followAccountCall('acct000000000000000c', every: Duration.zero)
          .map((c) => c.state)
          .toList();
      expect(seen, states.take(3));
    });
  });

  test('the faucet funds the primary account', () async {
    final account = Uint8List.fromList(List.filled(20, 0xac));
    transport.on(
      settlement.AccountService.fundTestAccount,
      (req) => settlement.FundTestAccountResponse(
        amount: req.amount,
        mintedToday: req.amount,
        dailyLimit: '10000000000',
      ),
    );
    final funded = await service(
      DeviceKeyStore(MemoryDeviceKeyVault()),
      identityWith('p1', account),
    ).fundTestAccount('1000000000');
    expect(funded.amount, '1000000000');
    final request = transport
        .requestsTo(settlement.AccountService.fundTestAccount)
        .single;
    expect(request.address, account);
    expect(request.amount, '1000000000');
  });

  group('room custody', () {
    test('finance gives the bound room custody', () async {
      final custody = Uint8List.fromList(List.filled(20, 0xc0));
      transport.on(
        finance.RoomService.getRoom,
        (req) => finance.GetRoomResponse(
          room: finance.Room(roomId: req.roomId, custodyAddress: custody),
        ),
      );
      final source = financeCustodySource(finance.RoomServiceClient(transport));
      expect(await source('room00000000000000aa'), custody);
    });

    test('sources are asked in order until one knows the room', () async {
      final asked = <String>[];
      final custody = Uint8List.fromList(List.filled(20, 1));
      final source = firstCustodyOf([
        (id) async {
          asked.add('binding');
          return null;
        },
        (id) async {
          asked.add('finance');
          return custody;
        },
        (id) async {
          asked.add('never');
          return null;
        },
      ]);
      expect(await source('r'), custody);
      expect(asked, ['binding', 'finance']);
    });
  });
}
