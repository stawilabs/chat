import 'dart:typed_data';

import 'package:connectrpc/connect.dart' as connect;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/signing_gate.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/data/stawi_custody.dart';
import 'package:stawi/features/stawi/data/stawi_finance_service.dart';
import 'package:stawi/features/stawi/domain/money_review.dart';
import 'package:stawi/features/stawi/ui/contribute_screen.dart';
import 'package:stawi/features/stawi/ui/money_review_sheet.dart';
import 'package:stawi/features/stawi/ui/stawi_feedback.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

const roomId = 'room00000000000000aa';

void main() {
  final wrapped = GoSignedCallVectors.load().accountWrappedHashes.firstWhere(
    (v) => v['name'] == 'anvil_0/seq' && v['chain_id'] == '146',
  );
  final account = hexToBytes(wrapped['account'] as String);
  final custody = Uint8List.fromList(List.filled(20, 0xc0));
  final digest = keccak256(Uint8List.fromList([7]));

  testWidgets('the review shows what will be signed and signs nothing when '
      'dismissed', (tester) async {
    bool? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async => confirmed = await showMoneyReview(
              context,
              const MoneyReview(
                title: 'Lend 300.00 USDC to Bob',
                lines: [
                  ('Amount', '300.00 USDC'),
                  ('Instalments', '4 every two weeks'),
                ],
                notes: ['Offer open until 9 Oct 2025'],
                signLabel: 'Confirm and sign',
                done: 'Offer sent to Bob',
              ),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Lend 300.00 USDC to Bob'), findsOneWidget);
    expect(find.text('4 every two weeks'), findsOneWidget);
    expect(find.text('Offer open until 9 Oct 2025'), findsOneWidget);
    await tester.tap(find.byKey(const Key('money-review-cancel')));
    await tester.pumpAndSettle();
    expect(confirmed, isFalse);
  });

  group('a contribution is reviewed before it is signed', () {
    late FakeConnectTransport transport;

    Future<StawiAccountService> serve({
      required SigningGate gate,
      bool catchingUp = false,
    }) async {
      transport = FakeConnectTransport()
        ..on(settlement.AccountService.prepareAccountCall, (req) {
          if (catchingUp) {
            throw connect.ConnectException(
              connect.Code.unavailable,
              'your account is being brought up to date',
            );
          }
          return settlement.PrepareAccountCallResponse(
            callId: 'acct000000000000000c',
            intentDigest: digest,
            financialIntent: finance.FinancialIntent(
              type: finance.IntentType.INTENT_TYPE_CONTRIBUTION,
              destination: finance.ValueLocation(
                kind: finance.LocationKind.LOCATION_KIND_ROOM_CUSTODY,
                address: req.params.room,
              ),
              amount: req.params.amount,
            ),
            call: settlement.AccountCall(
              callId: 'acct000000000000000c',
              address: req.address,
              kind: req.kind,
            ),
          );
        })
        ..on(
          settlement.AccountService.submitAccountCall,
          (req) => settlement.SubmitAccountCallResponse(
            call: settlement.AccountCall(callId: req.callId),
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
        )
        ..on(
          settlement.AccountService.getAsset,
          (req) => settlement.GetAssetResponse(asset: usdcInfo),
        );
      await serveDeployedAccount(transport, anvilKey);
      return StawiAccountService(
        accounts: settlement.AccountServiceClient(transport),
        keys: DeviceKeyStore(vaultWith('p1', anvilKey), gate: gate),
        proofs: refusingSessionProofs,
        identity: () async => identityWith('p1', account),
      );
    }

    Future<void> openAndSubmit(
      WidgetTester tester,
      StawiAccountService service,
    ) async {
      final overrides = [
        roomCustodyProvider.overrideWith((ref, id) async => custody),
        stawiRoomAssetProvider.overrideWith((ref, id) async => usdc),
        stawiRoomAssetsProvider.overrideWith((ref, id) async => usdcAssets),
        stawiAccountServiceProvider.overrideWithValue(service),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: const MaterialApp(
            home: ContributeScreen(roomId: roomId, roomName: 'Chama'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('contribute-amount')), '500');
      await tester.tap(find.byKey(const Key('contribute-submit')));
      await tester.pumpAndSettle();
    }

    int submits() => transport
        .requestsTo(settlement.AccountService.submitAccountCall)
        .length;

    testWidgets('confirming signs and submits once', (tester) async {
      final gate = RecordingSigningGate();
      await openAndSubmit(tester, await serve(gate: gate));
      expect(find.byKey(const Key('money-review')), findsOneWidget);
      expect(find.text('Pay 500.00 USDC into Chama'), findsOneWidget);
      expect(submits(), 0);
      expect(gate.reasons, isEmpty);
      await tester.tap(find.byKey(const Key('money-review-sign')));
      await tester.pumpAndSettle();
      expect(submits(), 1);
      expect(gate.reasons, ['Pay 500.00 USDC into Chama']);
    });

    testWidgets('cancelling the review signs and submits nothing', (
      tester,
    ) async {
      final gate = RecordingSigningGate();
      await openAndSubmit(tester, await serve(gate: gate));
      await tester.tap(find.byKey(const Key('money-review-cancel')));
      await tester.pumpAndSettle();
      expect(submits(), 0);
      expect(gate.reasons, isEmpty);
      expect(find.byKey(const Key('contribute-state')), findsNothing);
    });

    testWidgets('a refused device lock submits nothing', (tester) async {
      final gate = RecordingSigningGate(refuse: true);
      await openAndSubmit(tester, await serve(gate: gate));
      await tester.tap(find.byKey(const Key('money-review-sign')));
      await tester.pumpAndSettle();
      expect(gate.reasons, ['Pay 500.00 USDC into Chama']);
      expect(submits(), 0);
      expect(find.textContaining('Not signed'), findsOneWidget);
    });

    testWidgets('an account being brought up to date says to try again', (
      tester,
    ) async {
      await openAndSubmit(
        tester,
        await serve(gate: SigningGate.open, catchingUp: true),
      );
      expect(find.byKey(const Key('money-review')), findsNothing);
      expect(find.text(accountCatchingUpMessage), findsOneWidget);
      expect(find.textContaining('try again shortly'), findsOneWidget);
      expect(submits(), 0);
    });
  });

  test('a contribution review names the room and the amount', () {
    final review = MoneyReview.contribution(
      amount: BigInt.from(500000000),
      roomName: 'Chama',
      asset: usdc,
    );
    expect(review.title, 'Pay 500.00 USDC into Chama');
    expect(review.lines, contains(('To', 'Chama')));
  });

  test('a worded contribution title states the same amount as its line', () {
    final review = MoneyReview.contribution(
      amount: BigInt.from(77500000),
      roomName: 'Chama',
      asset: usdc,
      title: (amount) => 'Contribute $amount to Chama',
    );
    expect(review.title, 'Contribute 77.50 USDC to Chama');
    expect(review.lines, contains(('Amount', '77.50 USDC')));
    expect(review.title, isNot(contains('77500000')));
  });
}
