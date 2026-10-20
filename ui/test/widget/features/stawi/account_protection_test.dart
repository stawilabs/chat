import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/ui/account_protection_screen.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

void main() {
  const add = settlement.AccountCallKind.ACCOUNT_CALL_KIND_ADD_GUARDIAN;
  const remove = settlement.AccountCallKind.ACCOUNT_CALL_KIND_REMOVE_GUARDIAN;
  const contest = settlement.AccountCallKind.ACCOUNT_CALL_KIND_CONTEST_RECOVERY;
  final g1 = hexToBytes('0x3132333435363738393a3b3c3d3e3f4041424344');
  final g2 = hexToBytes('0x6162636465666768696a6b6c6d6e6f7071727374');

  late FakeConnectTransport transport;
  late RecordingSigningGate gate;
  late Uint8List device;
  late settlement.AccountState state;
  late GoGuardianCallVector vector;

  setUp(() async {
    device = await deviceAddressOf(anvilKey);
    transport = FakeConnectTransport();
    gate = RecordingSigningGate();
    transport
      ..on(
        settlement.AccountService.getAccount,
        (req) => settlement.GetAccountResponse(account: state),
      )
      ..on(
        settlement.AccountService.prepareAccountCall,
        (req) => vector.prepared(req.kind),
      )
      ..on(
        settlement.AccountService.submitAccountCall,
        (req) => settlement.SubmitAccountCallResponse(
          call: settlement.AccountCall(
            callId: req.callId,
            state: settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED,
          ),
        ),
      )
      ..on(
        settlement.AccountService.getAccountCall,
        (req) => settlement.GetAccountCallResponse(
          call: settlement.AccountCall(
            callId: req.callId,
            state: settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL,
          ),
        ),
      );
  });

  settlement.AccountState withKey(settlement.AccountState s, {bool? mine}) =>
      s
        ..keys.add(
          settlement.AccountKey(
            key: (mine ?? true) ? device : (Uint8List(20)..[0] = 9),
            active: true,
          ),
        );

  Future<void> open(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1080, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final service = StawiAccountService(
      accounts: settlement.AccountServiceClient(transport),
      keys: DeviceKeyStore(vaultWith('p1', anvilKey), gate: gate),
      proofs: refusingSessionProofs,
      identity: () async => identityWith('p1', vector.account),
      deploymentChainId: vector.chainId,
      followEvery: const Duration(milliseconds: 10),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stawiIdentityProvider.overrideWith(
            (ref) async => identityWith('p1', vector.account),
          ),
          stawiAccountServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(home: AccountProtectionScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> confirmReview(WidgetTester tester) async {
    expect(find.byKey(const Key('money-review')), findsOneWidget);
    expect(
      transport.requestsTo(settlement.AccountService.submitAccountCall),
      isEmpty,
    );
    expect(gate.reasons, isEmpty, reason: 'nothing signed before the review');
    await tester.tap(find.byKey(const Key('money-review-sign')));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  void expectSignedByDevice(Uint8List digest, String reason) {
    final submitted = transport
        .requestsTo(settlement.AccountService.submitAccountCall)
        .single;
    expect(
      recoverDeviceAddress(digest, submitted.authorization),
      device,
      reason: 'the checked digest, signed by this device',
    );
    expect(gate.reasons, [reason], reason: 'one unlock, behind the lock');
  }

  testWidgets('adds a first guardian: checked, reviewed, signed behind the '
      'device lock', (tester) async {
    vector = GoGuardianCallVector.named('add_first_guardian');
    state = withKey(vector.stateWith());
    await open(tester);
    expect(find.textContaining('You have no guardians'), findsOneWidget);
    expect(find.byKey(const Key('guardian-acts-note')), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-guardian')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('guardian-key')),
      bytesToHex0x(g1),
    );
    await tester.tap(find.byKey(const Key('guardian-review')));
    await tester.pumpAndSettle();

    final prepared = transport
        .requestsTo(settlement.AccountService.prepareAccountCall)
        .single;
    expect(prepared.kind, add);
    expect(prepared.address, vector.account);
    expect(prepared.params.guardian, g1);
    expect(prepared.params.guardianThreshold, 1);
    expect(
      find.text('1 of 1 guardians must agree to recover your account'),
      findsOneWidget,
    );

    await confirmReview(tester);
    expectSignedByDevice(vector.digest, 'Add a guardian');
  });

  testWidgets('a second guardian with 2 of 2', (tester) async {
    vector = GoGuardianCallVector.named('add_second_guardian');
    state = withKey(vector.stateWith(guardians: [g1], threshold: 1));
    await open(tester);
    expect(
      find.text('1 of 1 must agree to recover your account.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('add-guardian')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('guardian-key')),
      bytesToHex0x(g2),
    );
    // A majority of two is two.
    expect(find.text('2 of 2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('guardian-review')));
    await tester.pumpAndSettle();
    expect(
      transport
          .requestsTo(settlement.AccountService.prepareAccountCall)
          .single
          .params
          .guardianThreshold,
      2,
    );
    await confirmReview(tester);
    expectSignedByDevice(vector.digest, 'Add a guardian');
  });

  testWidgets('a guardian change settlement altered is not signed', (
    tester,
  ) async {
    vector = GoGuardianCallVector.named('add_second_guardian');
    // The chain shows no guardian yet, so settlement's two-guardian policy
    // is not "the policy in force plus g2".
    state = withKey(vector.stateWith());
    await open(tester);
    await tester.tap(find.byKey(const Key('add-guardian')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('guardian-key')),
      bytesToHex0x(g2),
    );
    await tester.tap(find.byKey(const Key('guardian-review')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('money-review')), findsNothing);
    expect(gate.reasons, isEmpty);
    expect(
      transport.requestsTo(settlement.AccountService.submitAccountCall),
      isEmpty,
    );
  });

  testWidgets('removes the last guardian', (tester) async {
    vector = GoGuardianCallVector.named('remove_last_guardian');
    state = withKey(vector.stateWith(guardians: [g1], threshold: 1));
    await open(tester);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(
      transport
          .requestsTo(settlement.AccountService.prepareAccountCall)
          .single
          .kind,
      remove,
    );
    expect(
      find.text('No guardians: nobody can recover your account'),
      findsOneWidget,
    );
    await confirmReview(tester);
    expectSignedByDevice(vector.digest, 'Remove a guardian');
  });

  testWidgets('a pending recovery is shown and can be contested', (
    tester,
  ) async {
    vector = GoGuardianCallVector.named('contest_recovery');
    state = withKey(
      GoGuardianCallVector.named('contest_recovery').stateWith(
        guardians: [g1, g2],
        threshold: 2,
        recovery: settlement.AccountRecovery(
          state: settlement.AccountRecoveryState.ACCOUNT_RECOVERY_STATE_PENDING,
          newKey: Uint8List(20)..[0] = 0x77,
          approvals: Int64(1),
          approvalsRequired: Int64(2),
          executableAfter: Int64(1760259600),
          expiresAt: Int64(1760864400),
        ),
      ),
    );
    await open(tester);
    expect(
      find.textContaining(
        'Your guardians are recovering your account to a new key: 1 of 2',
      ),
      findsOneWidget,
    );
    // No guardian change while a recovery runs.
    expect(
      tester
          .widget<OutlinedButton>(
            find.ancestor(
              of: find.text('Add a guardian'),
              matching: find.byWidgetPredicate((w) => w is OutlinedButton),
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('contest-recovery')));
    await tester.pumpAndSettle();
    expect(
      transport
          .requestsTo(settlement.AccountService.prepareAccountCall)
          .single
          .kind,
      contest,
    );
    await confirmReview(tester);
    expectSignedByDevice(vector.digest, 'Contest the recovery of my account');
  });

  testWidgets('a phone that is not a key shows its key and signs nothing', (
    tester,
  ) async {
    vector = GoGuardianCallVector.named('add_first_guardian');
    state = withKey(
      vector.stateWith(guardians: [g1], threshold: 1),
      mine: false,
    );
    await open(tester);
    expect(find.byKey(const Key('recovery-this-device')), findsOneWidget);
    expect(
      find.textContaining(bytesToHex0x(device).toLowerCase()),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextButton>(
            find.ancestor(
              of: find.text('Remove'),
              matching: find.byWidgetPredicate((w) => w is TextButton),
            ),
          )
          .onPressed,
      isNull,
    );
  });
}
