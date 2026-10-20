import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/profile/data/profile_providers.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/data/stawi_guardian_service.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/domain/guardian_acts.dart';
import 'package:stawi/features/stawi/ui/guarded_accounts_screen.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

void main() {
  const request = settlement.AccountCallKind.ACCOUNT_CALL_KIND_REQUEST_RECOVERY;
  const approve = settlement.AccountCallKind.ACCOUNT_CALL_KIND_APPROVE_RECOVERY;
  // The guardian's own account: the device key is a key of it.
  final mine = Uint8List.fromList(List.generate(20, (i) => 0x91 + i));

  late FakeConnectTransport transport;
  late RecordingSigningGate gate;
  late Uint8List device;
  late settlement.DeviceKeyAlgorithm algorithm;
  late List<settlement.GuardedAccount> guarded;
  late GoGuardianActVector act;
  late List<settlement.GuardianKeyStatus> registered;
  settlement.PrepareAccountCallResponse? preparedOverride;

  setUp(() async {
    device = await deviceAddressOf(anvilKey);
    gate = RecordingSigningGate();
    algorithm = settlement.DeviceKeyAlgorithm.DEVICE_KEY_ALGORITHM_SECP256K1;
    guarded = [];
    registered = [];
    preparedOverride = null;
    act = GoGovernanceVectors.guardianAct('request_recovery');
    transport = FakeConnectTransport()
      ..on(
        settlement.AccountService.getAccount,
        (req) => settlement.GetAccountResponse(
          account: settlement.AccountState(
            address: mine,
            deployed: true,
            keys: [
              settlement.AccountKey(
                key: device,
                active: true,
                algorithm: algorithm,
              ),
            ],
          ),
        ),
      )
      ..on(settlement.AccountService.registerGuardianKey, (req) {
        final key = settlement.GuardianKey(key: req.key, account: req.account);
        registered = [
          settlement.GuardianKeyStatus(guardianKey: key, active: true),
        ];
        return settlement.RegisterGuardianKeyResponse(guardianKey: key);
      })
      ..on(
        settlement.AccountService.listGuardianKeys,
        (req) => settlement.ListGuardianKeysResponse(keys: registered),
      )
      ..on(
        settlement.AccountService.listGuardedAccounts,
        (req) => settlement.ListGuardedAccountsResponse(accounts: guarded),
      )
      ..on(
        settlement.AccountService.getGuardedAccount,
        (req) => settlement.GetGuardedAccountResponse(account: guarded.single),
      )
      ..on(
        settlement.AccountService.prepareAccountCall,
        (req) => preparedOverride ?? act.prepared(req.kind),
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
  });

  Future<void> open(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1080, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final keys = DeviceKeyStore(vaultWith('p1', anvilKey), gate: gate);
    final accounts = StawiAccountService(
      accounts: settlement.AccountServiceClient(transport),
      keys: keys,
      proofs: refusingSessionProofs,
      identity: () async => identityWith('p1', mine),
      deploymentChainId: act.chainId,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stawiIdentityProvider.overrideWith(
            (ref) async => identityWith('p1', mine),
          ),
          stawiAccountServiceProvider.overrideWithValue(accounts),
          stawiGuardianServiceProvider.overrideWithValue(
            StawiGuardianService(
              accounts: settlement.AccountServiceClient(transport),
              keys: keys,
              identity: () async => identityWith('p1', mine),
              status: accounts.status,
              deploymentChainId: act.chainId,
            ),
          ),
          profileByIdProvider.overrideWith((ref, id) async => null),
        ],
        child: const MaterialApp(home: GuardedAccountsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> confirmReview(WidgetTester tester) async {
    expect(find.byKey(const Key('money-review')), findsOneWidget);
    expect(gate.reasons, isEmpty, reason: 'nothing signed before the review');
    expect(
      transport.requestsTo(settlement.AccountService.submitAccountCall),
      isEmpty,
    );
    await tester.tap(find.byKey(const Key('money-review-sign')));
    await tester.pumpAndSettle();
  }

  void expectSignedByDevice(Uint8List digest, String reason) {
    final submitted = transport
        .requestsTo(settlement.AccountService.submitAccountCall)
        .single;
    expect(recoverDeviceAddress(digest, submitted.authorization), device);
    expect(gate.reasons, [reason], reason: 'one unlock, behind the lock');
  }

  String hex(List<int> a) => bytesToHex0x(a).toLowerCase();

  testWidgets('registers this phone as a guardian key with a proof signed '
      'behind the lock; settlement\'s directory then says Registered', (
    tester,
  ) async {
    await open(tester);
    expect(
      transport.requestsTo(settlement.AccountService.listGuardianKeys),
      isNotEmpty,
    );
    expect(find.byKey(const Key('guarded-none')), findsOneWidget);
    expect(find.text(hex(device)), findsOneWidget);
    await tester.tap(find.byKey(const Key('guardian-register')));
    await tester.pumpAndSettle();

    final req = transport
        .requestsTo(settlement.AccountService.registerGuardianKey)
        .single;
    expect(req.account, mine);
    expect(req.key, device);
    expect(
      recoverDeviceAddress(
        guardianKeyProofDigest(
          chainId: act.chainId,
          account: mine,
          key: device,
          profileId: 'p1',
        ),
        req.signature,
      ),
      device,
      reason: 'the proof over the SDK digest (Go-pinned), by this phone',
    );
    expect(gate.reasons, ['Register this phone as a guardian key']);

    expect(
      find.textContaining('Registered: members of your Stawi'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('guardian-register')), findsNothing);
    // No key is shared as chat text any more.
    expect(find.byKey(const Key('guardian-share')), findsNothing);
  });

  testWidgets('a key settlement already lists as registered shows Registered '
      'without registering again', (tester) async {
    registered = [
      settlement.GuardianKeyStatus(
        guardianKey: settlement.GuardianKey(key: device, account: mine),
        active: true,
      ),
    ];
    await open(tester);
    expect(
      find.textContaining('Registered: members of your Stawi'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('guardian-register')), findsNothing);
    expect(
      transport.requestsTo(settlement.AccountService.registerGuardianKey),
      isEmpty,
    );
  });

  testWidgets('a registered key that no longer counts says why and offers '
      'registering again', (tester) async {
    registered = [
      settlement.GuardianKeyStatus(
        guardianKey: settlement.GuardianKey(key: device, account: mine),
        inactiveReason: 'the account is no longer the caller\'s',
      ),
    ];
    await open(tester);
    expect(
      find.textContaining('it no longer counts: the account is no longer'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('guardian-register')), findsOneWidget);
  });

  testWidgets('a passkey phone is told it cannot guard', (tester) async {
    algorithm = settlement.DeviceKeyAlgorithm.DEVICE_KEY_ALGORITHM_P256;
    guarded = [act.guarded()];
    await open(tester);
    expect(find.byKey(const Key('guardian-passkey')), findsOneWidget);
    expect(find.text(p256CannotGuardNote), findsOneWidget);
    expect(find.byKey(const Key('guardian-register')), findsNothing);
    final start = find.byKey(Key('guarded-request-${hex(act.account)}'));
    expect(tester.widget<OutlinedButton>(start).onPressed, isNull);
  });

  testWidgets('starts a recovery to the owner\'s new key: checked against '
      'Go\'s guardian act and signed once by this phone', (tester) async {
    guarded = [act.guarded()];
    await open(tester);
    expect(
      find.textContaining('No recovery under way. 2 of 2 guardians'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('guardian-cannot-cancel')), findsOneWidget);
    await tester.tap(find.byKey(Key('guarded-request-${hex(act.account)}')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('recovery-new-key')),
      hex(act.newKey),
    );
    await tester.tap(find.byKey(const Key('recovery-new-key-review')));
    await tester.pumpAndSettle();

    final req = transport
        .requestsTo(settlement.AccountService.prepareAccountCall)
        .single;
    expect(req.kind, request);
    expect(req.address, act.account);
    expect(req.params.guardian, device);
    expect(req.params.key, act.newKey);
    await confirmReview(tester);
    expectSignedByDevice(act.digest, 'Start a recovery as guardian');
  });

  testWidgets('approves a pending recovery', (tester) async {
    act = GoGovernanceVectors.guardianAct('approve_recovery');
    guarded = [act.guarded(pending: true)];
    await open(tester);
    expect(find.textContaining('1 of 2 approved'), findsOneWidget);
    expect(
      find.byKey(Key('guarded-request-${hex(act.account)}')),
      findsNothing,
    );
    await tester.tap(find.byKey(Key('guarded-approve-${hex(act.account)}')));
    await tester.pumpAndSettle();
    expect(
      transport
          .requestsTo(settlement.AccountService.prepareAccountCall)
          .single
          .kind,
      approve,
    );
    await confirmReview(tester);
    expectSignedByDevice(act.digest, 'Approve the recovery');
  });

  testWidgets('an approval settlement altered is never signed', (tester) async {
    act = GoGovernanceVectors.guardianAct('approve_recovery');
    guarded = [act.guarded(pending: true)];
    // Settlement binds the recovery request's op (round 0) instead.
    preparedOverride = GoGovernanceVectors.guardianAct('request_recovery')
        .prepared(approve);
    await open(tester);
    await tester.tap(find.byKey(Key('guarded-approve-${hex(act.account)}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('money-review')), findsNothing);
    expect(gate.reasons, isEmpty);
    expect(
      transport.requestsTo(settlement.AccountService.submitAccountCall),
      isEmpty,
    );
  });
}
