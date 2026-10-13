import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:connectrpc/connect.dart' as connect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/signing_gate.dart';
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
      final keys = DeviceKeyStore(
        vaultWith('p1', v.devicePrivateKey),
        gate: SigningGate.open,
      );
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
      final keys = DeviceKeyStore(
        vaultWith('p1', v.devicePrivateKey),
        gate: SigningGate.open,
      );
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
      final keys = DeviceKeyStore(
        vaultWith('p1', v.devicePrivateKey),
        gate: SigningGate.open,
      );
      await expectLater(
        service(keys, v.identity('p1'), proofs: refusingSessionProofs).deploy(),
        throwsA(isA<connect.ConnectException>()),
      );
      expect(
        transport.requestsTo(settlement.AccountService.deployAccount),
        isEmpty,
      );
    });
  });

  group('ensureReady', () {
    final v = genesis.firstWhere((v) => v.name == 'settlement_default');
    late RecordingSigningGate gate;
    late DeviceKeyStore keys;
    late DevicePublicKey key;

    setUp(() async {
      gate = RecordingSigningGate();
      keys = DeviceKeyStore(vaultWith('p1', v.devicePrivateKey), gate: gate);
      key = (await keys.load('p1'))!;
    });

    settlement.AccountState undeployed(String genesisState) =>
        settlement.AccountState(address: v.account, genesisState: genesisState);

    settlement.AccountState deployed({required bool mine}) =>
        settlement.AccountState(
          address: v.account,
          deployed: true,
          genesisState: 'DEPLOYED',
          keys: [
            settlement.AccountKey(
              key: mine ? key.address : Uint8List(20),
              active: true,
            ),
          ],
        );

    /// Settlement answers GetAccount with [states] in turn, repeating the
    /// last. A deploy answers [deployState] (and [duplicate]), and from then
    /// on GetAccount answers [afterDeploy] in turn: the server's contract, in
    /// which a deploy of a FAILED genesis requests a new attempt.
    void chainAnswers(
      List<settlement.AccountState> states, {
      List<settlement.AccountState>? afterDeploy,
      String deployState = 'PENDING',
      bool duplicate = false,
    }) {
      var script = states;
      var reads = 0;
      transport
        ..on(settlement.AccountService.getAccount, (req) {
          final i = reads < script.length ? reads : script.length - 1;
          reads++;
          return settlement.GetAccountResponse(account: script[i]);
        })
        ..on(
          settlement.AccountService.prepareDeployAccount,
          (req) => v.prepared,
        )
        ..on(settlement.AccountService.deployAccount, (req) {
          if (afterDeploy != null) {
            script = afterDeploy;
            reads = 0;
          }
          return settlement.DeployAccountResponse(
            address: req.address,
            genesisState: deployState,
            duplicate: duplicate,
          );
        });
    }

    Future<StawiAccountRef> ready({int attempts = 60}) => service(
      keys,
      v.identity('p1'),
    ).ensureReady(every: Duration.zero, attempts: attempts);

    int reads() =>
        transport.requestsTo(settlement.AccountService.getAccount).length;
    int deploys() =>
        transport.requestsTo(settlement.AccountService.deployAccount).length;

    test(
      'ensureReady deploys an undeployed account once and waits for it',
      () async {
        chainAnswers([
          undeployed(''),
          undeployed('PENDING'),
          deployed(mine: true),
        ]);
        final account = await ready();
        expect(account.address, v.account);
        expect(account.primary, isTrue);
        expect(deploys(), 1);
        expect(reads(), 3);
        expect(gate.reasons, ['Set up your Stawi account']);
        expect(
          bytesToHex0x(
            transport
                .requestsTo(settlement.AccountService.deployAccount)
                .single
                .deviceSignature,
          ),
          v.signature,
        );
      },
    );

    test(
      'a deployed account with this device as a key is ready at once',
      () async {
        chainAnswers([deployed(mine: true)]);
        expect((await ready()).address, v.account);
        expect(deploys(), 0);
        expect(gate.reasons, isEmpty, reason: 'nothing is signed');
      },
    );

    test(
      'a deployment already under way is waited for, not repeated',
      () async {
        chainAnswers([undeployed('SUBMITTED'), deployed(mine: true)]);
        await ready();
        expect(deploys(), 0);
        expect(gate.reasons, isEmpty);
      },
    );

    test(
      'a FAILED genesis is deployed again: PENDING, then DEPLOYED',
      () async {
        chainAnswers(
          [undeployed('FAILED')],
          afterDeploy: [undeployed('PENDING'), deployed(mine: true)],
          duplicate: true,
        );
        expect((await ready()).address, v.account);
        expect(deploys(), 1);
        expect(reads(), 3);
      },
    );

    test(
      'a deployment someone else started that fails is retried once',
      () async {
        chainAnswers(
          [undeployed('PENDING'), undeployed('FAILED')],
          afterDeploy: [undeployed('PENDING'), deployed(mine: true)],
        );
        await ready();
        expect(deploys(), 1);
      },
    );

    test('a FAILED duplicate the server will not retry says so', () async {
      chainAnswers(
        [undeployed('FAILED')],
        deployState: 'FAILED',
        duplicate: true,
      );
      await expectLater(
        ready(),
        throwsA(
          isA<StawiUnavailable>().having(
            (e) => e.message,
            'message',
            allOf(
              accountSetupFailedMessage,
              startsWith('Setting up your Stawi account failed'),
            ),
          ),
        ),
      );
      expect(deploys(), 1);
      expect(reads(), 1);
    });

    test('stops when nobody waits for it any more', () async {
      chainAnswers([undeployed(''), undeployed('PENDING')]);
      var cancel = false;
      final done = service(
        keys,
        v.identity('p1'),
      ).ensureReady(every: Duration.zero, cancelled: () => cancel);
      cancel = true;
      await expectLater(done, throwsA(isA<AccountSetupCancelled>()));
      expect(deploys(), 0, reason: 'cancelled before the deploy');
      expect(reads(), 1);
    });

    test(
      'ensureReady refuses a deployed account this device is not a key of',
      () async {
        chainAnswers([deployed(mine: false)]);
        await expectLater(
          ready(),
          throwsA(
            isA<StawiUnavailable>().having(
              (e) => e.message,
              'message',
              contains('Add this device'),
            ),
          ),
        );
        expect(deploys(), 0);
      },
    );

    test('a refused device lock deploys nothing', () async {
      gate.refuse = true;
      chainAnswers([undeployed('')]);
      await expectLater(ready(), throwsA(isA<SigningRefused>()));
      expect(
        transport.requestsTo(settlement.AccountService.prepareDeployAccount),
        isEmpty,
      );
      expect(deploys(), 0);
    });

    test('a slow chain gives up with a message to try again', () async {
      chainAnswers([undeployed(''), undeployed('PENDING')]);
      await expectLater(
        ready(attempts: 3),
        throwsA(
          isA<StawiUnavailable>().having(
            (e) => e.message,
            'message',
            accountSetupPendingMessage,
          ),
        ),
      );
      expect(reads(), 4);
      expect(deploys(), 1);

      // Trying again picks the pending deployment up without redeploying.
      transport = FakeConnectTransport();
      chainAnswers([undeployed('PENDING'), deployed(mine: true)]);
      await ready();
      expect(deploys(), 0);
    });

    test('a deployment that fails again is not retried in a loop', () async {
      chainAnswers(
        [undeployed('')],
        afterDeploy: [undeployed('PENDING'), undeployed('FAILED')],
      );
      await expectLater(
        ready(),
        throwsA(
          isA<StawiUnavailable>().having(
            (e) => e.message,
            'message',
            accountSetupFailedMessage,
          ),
        ),
      );
      expect(deploys(), 1);
      expect(reads(), 3);
    });

    testWidgets('the ready provider stops its loop once nobody watches', (
      tester,
    ) async {
      chainAnswers([undeployed('PENDING')]);
      final container = ProviderContainer(
        overrides: [
          stawiAccountServiceProvider.overrideWithValue(
            service(keys, v.identity('p1')),
          ),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(stawiAccountReadyProvider, (_, _) {});
      await tester.pump();
      expect(reads(), 1);
      await tester.pump(const Duration(seconds: 3));
      expect(reads(), 2);
      sub.close();
      await tester.pump();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 3));
      }
      expect(reads(), 2, reason: 'no loop left running');
    });

    testWidgets('by default it reads every 3 s and gives up after 3 min', (
      tester,
    ) async {
      chainAnswers([undeployed(''), undeployed('PENDING')]);
      Object? error;
      var done = false;
      unawaited(
        service(keys, v.identity('p1')).ensureReady().then(
          (_) => done = true,
          onError: (Object e) {
            error = e;
            done = true;
          },
        ),
      );
      await tester.pump();
      expect(reads(), 1);
      await tester.pump(const Duration(seconds: 3));
      expect(reads(), 2);
      for (var i = 0; i < 58; i++) {
        await tester.pump(const Duration(seconds: 3));
      }
      expect(done, isFalse, reason: 'still waiting at 2 min 57 s');
      await tester.pump(const Duration(seconds: 3));
      expect(done, isTrue);
      expect(reads(), 61);
      expect(
        error,
        isA<StawiUnavailable>().having(
          (e) => e.message,
          'message',
          accountSetupPendingMessage,
        ),
      );
    });

    test('a profile with no account is not set up', () async {
      chainAnswers([undeployed('')]);
      await expectLater(
        service(
          keys,
          const StawiIdentity(profileId: 'p1', accounts: []),
        ).ensureReady(every: Duration.zero),
        throwsA(isA<StawiUnavailable>()),
      );
      expect(transport.calls, isEmpty);
    });
  });

  group('contribute', () {
    final account = Uint8List.fromList(List.filled(20, 0xac));
    final custody = Uint8List.fromList(List.filled(20, 0xc0));
    final digest = keccak256(Uint8List.fromList([1]));
    late DeviceKeyStore keys;
    late DevicePublicKey key;

    setUp(() async {
      keys = DeviceKeyStore(vaultWith('p1', anvilKey), gate: SigningGate.open);
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
      DeviceKeyStore(MemoryDeviceKeyVault(), gate: SigningGate.open),
      identityWith('p1', account),
    ).fundTestAccount('1,000', usdc);
    expect(funded.amount, '1000000000');
    final request = transport
        .requestsTo(settlement.AccountService.fundTestAccount)
        .single;
    expect(request.address, account);
    expect(request.amount, '1000000000');
  });

  test('the faucet refuses an amount the asset cannot hold', () async {
    final faucet = service(
      DeviceKeyStore(MemoryDeviceKeyVault(), gate: SigningGate.open),
      identityWith('p1', Uint8List(20)),
    );
    for (final bad in ['0', '-1', '1.0000001', 'ten']) {
      await expectLater(
        faucet.fundTestAccount(bad, usdc),
        throwsFormatException,
        reason: bad,
      );
    }
    expect(
      transport.requestsTo(settlement.AccountService.fundTestAccount),
      isEmpty,
    );
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
