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
import 'package:stawi/features/stawi/data/unconfirmed_money_calls.dart';
import 'package:stawi/features/stawi/domain/money_review.dart';
import 'package:stawi/features/stawi/ui/contribute_screen.dart';
import 'package:stawi/features/stawi/ui/money_review_sheet.dart';
import 'package:stawi/features/stawi/ui/stawi_feedback.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';
import '../../../test_helpers/test_database.dart';

const roomId = 'room00000000000000aa';

void main() {
  final wrapped = GoSignedCallVectors.load().accountWrappedHashes.firstWhere(
    (v) => v['name'] == 'anvil_0/seq' && v['chain_id'] == '146',
  );
  final account = hexToBytes(wrapped['account'] as String);
  final custody = Uint8List.fromList(List.filled(20, 0xc0));

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
      settlement.SubmitAccountCallResponse Function(
        settlement.SubmitAccountCallRequest req,
        int n,
      )?
      onSubmit,
      settlement.GetAccountCallResponse Function(
        settlement.GetAccountCallRequest req,
        int n,
      )?
      onGetCall,
      UnconfirmedMoneyCallStore? unconfirmed,
      settlement.ListAccountCallsResponse Function(
        settlement.ListAccountCallsRequest req,
        int n,
      )?
      onList,
    }) async {
      var prepares = 0;
      var submitted = 0;
      var reads = 0;
      var lists = 0;
      transport = FakeConnectTransport();
      if (onList != null) {
        // Settlement's open calls, or the error it answers.
        transport.on(
          settlement.AccountService.listAccountCalls,
          (req) => onList(req, lists++),
        );
      }
      transport
        ..on(settlement.AccountService.prepareAccountCall, (req) {
          if (catchingUp) {
            throw connect.ConnectException(
              connect.Code.unavailable,
              'your account is being brought up to date',
            );
          }
          // Each prepare is a new call, as settlement's are.
          prepares++;
          return preparedContribution(
            account: req.address,
            custody: req.params.room,
            amount: req.params.amount,
            callId: 'acct${'$prepares'.padLeft(16, '0')}',
          );
        })
        ..on(
          settlement.AccountService.submitAccountCall,
          // As settlement answers a submit it took.
          (req) =>
              onSubmit?.call(req, submitted++) ??
              settlement.SubmitAccountCallResponse(
                call: settlement.AccountCall(
                  callId: req.callId,
                  state:
                      settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED,
                ),
              ),
        )
        ..on(
          settlement.AccountService.getAccountCall,
          (req) =>
              onGetCall?.call(req, reads++) ??
              settlement.GetAccountCallResponse(
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
        roomAssets: testRoomAssets,
        accounts: settlement.AccountServiceClient(transport),
        keys: DeviceKeyStore(vaultWith('p1', anvilKey), gate: gate),
        proofs: refusingSessionProofs,
        identity: () async => identityWith('p1', account),
        followEvery: Duration.zero,
        unconfirmed: unconfirmed,
      );
    }

    Future<void> openAndSubmit(
      WidgetTester tester,
      StawiAccountService service, {
      bool tap = true,
    }) async {
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
      if (!tap) return;
      await tester.tap(find.byKey(const Key('contribute-submit')));
      await tester.pumpAndSettle();
    }

    List<settlement.SubmitAccountCallRequest> submitted() =>
        transport.requestsTo(settlement.AccountService.submitAccountCall);

    int submits() => submitted().length;

    int prepares() => transport
        .requestsTo(settlement.AccountService.prepareAccountCall)
        .length;

    Future<void> sign(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('money-review-sign')));
      await tester.pumpAndSettle();
    }

    settlement.GetAccountCallResponse callIn(
      settlement.GetAccountCallRequest req,
      settlement.AccountCallState state,
    ) => settlement.GetAccountCallResponse(
      call: settlement.AccountCall(callId: req.callId, state: state),
    );

    Never lost(connect.Code code) =>
        throw connect.ConnectException(code, 'the response was lost');

    group('a submit with no clear answer is followed, never prepared again', () {
      testWidgets('a call settlement took is followed, not submitted again', (
        tester,
      ) async {
        final service = await serve(
          gate: SigningGate.open,
          onSubmit: (req, n) => lost(connect.Code.unavailable),
          onGetCall: (req, n) => callIn(
            req,
            n == 0
                ? settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED
                : settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL,
          ),
        );
        await openAndSubmit(tester, service);
        await sign(tester);

        expect(submits(), 1);
        expect(prepares(), 1);
        expect(find.byKey(const Key('contribute-state')), findsOneWidget);
        expect(
          find.text('Stawi is unreachable; try again shortly'),
          findsNothing,
        );
      });

      testWidgets('a call settlement did not take is submitted again with the '
          'same signature', (tester) async {
        final gate = RecordingSigningGate();
        final service = await serve(
          gate: gate,
          onSubmit: (req, n) => n == 0
              ? lost(connect.Code.deadlineExceeded)
              : settlement.SubmitAccountCallResponse(
                  call: settlement.AccountCall(
                    callId: req.callId,
                    state: settlement
                        .AccountCallState
                        .ACCOUNT_CALL_STATE_SUBMITTED,
                  ),
                ),
          onGetCall: (req, n) => callIn(
            req,
            n == 0
                ? settlement.AccountCallState.ACCOUNT_CALL_STATE_PREPARED
                : settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL,
          ),
        );
        await openAndSubmit(tester, service);
        await sign(tester);

        expect(prepares(), 1);
        expect(submits(), 2);
        final [first, second] = submitted();
        expect(second.callId, first.callId);
        expect(second.authorization, first.authorization);
        expect(gate.reasons, hasLength(1), reason: 'signed once, not again');
        expect(find.byKey(const Key('contribute-state')), findsOneWidget);
      });

      testWidgets('an answer that never comes says so honestly and blocks '
          'another payment until it is known', (tester) async {
        var reachable = false;
        final service = await serve(
          gate: SigningGate.open,
          onSubmit: (req, n) => reachable
              ? settlement.SubmitAccountCallResponse(
                  call: settlement.AccountCall(callId: req.callId),
                )
              : lost(connect.Code.unavailable),
          onGetCall: (req, n) => reachable
              ? callIn(
                  req,
                  settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED,
                )
              : lost(connect.Code.unavailable),
        );
        await openAndSubmit(tester, service);
        await sign(tester);

        expect(find.text(notConfirmedSubmitMessage), findsOneWidget);
        expect(find.byKey(const Key('contribute-state')), findsNothing);
        final firstCall = submitted().first.callId;

        // Tapping again does not prepare and pay a second time: the earlier
        // call is checked first.
        ScaffoldMessenger.of(tester.element(find.byType(ContributeScreen)))
            .removeCurrentSnackBar();
        reachable = true;
        await tester.tap(find.byKey(const Key('contribute-submit')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('money-review')), findsNothing);
        expect(submitted().map((r) => r.callId).toSet(), {
          firstCall,
        }, reason: 'no new call was submitted');
        expect(prepares(), 1, reason: 'nor prepared');
        expect(
          find.text(earlierCallSentMessage('Pay 500.00 USDC into Chama')),
          findsOneWidget,
        );

        // Once it is known, a new payment goes through as usual.
        ScaffoldMessenger.of(tester.element(find.byType(ContributeScreen)))
            .removeCurrentSnackBar();
        await tester.tap(find.byKey(const Key('contribute-submit')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('money-review')), findsOneWidget);
      });

      testWidgets('a call whose fate was not known is still checked after the '
          'app restarts, and submitted again as signed', (tester) async {
        final db = createTestDatabase();
        addTearDown(db.close);

        // Before the restart: the submit's answer never comes.
        await openAndSubmit(
          tester,
          await serve(
            gate: SigningGate.open,
            unconfirmed: DriftUnconfirmedMoneyCallStore(db),
            onSubmit: (req, n) => lost(connect.Code.unavailable),
            onGetCall: (req, n) => lost(connect.Code.unavailable),
          ),
        );
        await sign(tester);
        expect(find.text(notConfirmedSubmitMessage), findsOneWidget);
        final before = submitted().first;

        // The app restarts: a new provider container and service, the same
        // database. Settlement never took the call.
        await tester.pumpWidget(const SizedBox());
        final restarted = await serve(
          gate: SigningGate.open,
          unconfirmed: DriftUnconfirmedMoneyCallStore(db),
          onGetCall: (req, n) => callIn(
            req,
            settlement.AccountCallState.ACCOUNT_CALL_STATE_PREPARED,
          ),
        );
        await openAndSubmit(tester, restarted, tap: false);
        await tester.tap(find.byKey(const Key('contribute-submit')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('money-review')), findsNothing);
        expect(prepares(), 0, reason: 'nothing new is prepared');
        final [again] = submitted();
        expect(again.callId, before.callId);
        expect(again.authorization, before.authorization);
        expect(
          find.text(earlierCallSentMessage('Pay 500.00 USDC into Chama')),
          findsOneWidget,
        );
        expect(
          await DriftUnconfirmedMoneyCallStore(db).read('p1'),
          isNull,
          reason: 'cleared once settlement took it',
        );
      });

      testWidgets('a read that is refused says nothing of the call: it stays '
          'held and is followed again', (tester) async {
        var answer = false;
        final service = await serve(
          gate: SigningGate.open,
          onSubmit: (req, n) => lost(connect.Code.unavailable),
          onGetCall: (req, n) {
            if (answer) {
              return callIn(
                req,
                settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED,
              );
            }
            // An expired token, a rate limit, a gateway: answers about the
            // read, not the call.
            throw connect.ConnectException(switch (n % 3) {
              0 => connect.Code.unauthenticated,
              1 => connect.Code.resourceExhausted,
              _ => connect.Code.permissionDenied,
            }, 'the read was refused');
          },
        );
        await openAndSubmit(tester, service);
        await sign(tester);

        expect(find.text(notConfirmedSubmitMessage), findsOneWidget);
        final held = await service.unconfirmedCall();
        expect(held?.callId, submitted().single.callId, reason: 'still held');

        ScaffoldMessenger.of(tester.element(find.byType(ContributeScreen)))
            .removeCurrentSnackBar();
        answer = true;
        await tester.tap(find.byKey(const Key('contribute-submit')));
        await tester.pumpAndSettle();
        expect(
          find.text(earlierCallSentMessage('Pay 500.00 USDC into Chama')),
          findsOneWidget,
        );
        expect(prepares(), 1);
        expect(await service.unconfirmedCall(), isNull);
      });

      testWidgets('a gateway refusing the re-send says nothing of the call: it '
          'stays held', (tester) async {
        final service = await serve(
          gate: SigningGate.open,
          // The first submit's answer is lost; each re-send is refused by an
          // interceptor or the gateway, which describes that request only.
          onSubmit: (req, n) => n == 0
              ? lost(connect.Code.unavailable)
              : throw connect.ConnectException(switch (n % 3) {
                  1 => connect.Code.unauthenticated,
                  2 => connect.Code.resourceExhausted,
                  _ => connect.Code.unimplemented,
                }, 'refused at the gateway'),
          onGetCall: (req, n) => callIn(
            req,
            settlement.AccountCallState.ACCOUNT_CALL_STATE_PREPARED,
          ),
        );
        await openAndSubmit(tester, service);
        await sign(tester);

        expect(submits(), 4, reason: 'the first submit and three re-sends');
        expect(submitted().map((r) => r.callId).toSet(), hasLength(1));
        expect(find.text(notConfirmedSubmitMessage), findsOneWidget);
        expect(
          (await service.unconfirmedCall())?.callId,
          submitted().first.callId,
          reason: 'still held',
        );
      });

      testWidgets('a record that cannot be cleared is followed again, not '
          'lost', (tester) async {
        final store = _ClearFailsOnce();
        final service = await serve(gate: SigningGate.open, unconfirmed: store);
        await openAndSubmit(tester, service);
        await sign(tester);

        // Sent: the failed clear is not the person's problem.
        expect(find.byKey(const Key('contribute-state')), findsOneWidget);
        expect(find.text(sentWaitingMessage), findsOneWidget);
        expect(
          (await store.read('p1'))?.callId,
          submitted().single.callId,
          reason: 'kept, since it could not be cleared',
        );

        // The next attempt follows it, finds it final and clears it.
        ScaffoldMessenger.of(tester.element(find.byType(ContributeScreen)))
            .removeCurrentSnackBar();
        await tester.pumpWidget(const SizedBox());
        await openAndSubmit(tester, service);
        expect(find.byKey(const Key('money-review')), findsNothing);
        expect(
          find.text(earlierCallSentMessage('Pay 500.00 USDC into Chama')),
          findsOneWidget,
        );
        expect(await store.read('p1'), isNull);
      });

      testWidgets('AlreadyExists from the submit means it was taken', (
        tester,
      ) async {
        final service = await serve(
          gate: SigningGate.open,
          onSubmit: (req, n) => throw connect.ConnectException(
            connect.Code.alreadyExists,
            'call was already submitted with another signature',
          ),
          onGetCall: (req, n) => callIn(
            req,
            n == 0
                ? settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED
                : settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL,
          ),
        );
        await openAndSubmit(tester, service);
        await sign(tester);

        expect(find.byKey(const Key('contribute-state')), findsOneWidget);
        expect(submits(), 1);
        expect(await service.unconfirmedCall(), isNull);
      });

      for (final (name, state, failure, message) in [
        (
          'an expired call',
          settlement.AccountCallState.ACCOUNT_CALL_STATE_EXPIRED,
          '',
          'It expired before it went through; nothing was paid',
        ),
        (
          'a failed call',
          settlement.AccountCallState.ACCOUNT_CALL_STATE_FAILED,
          'insufficient funds',
          'Not done: insufficient funds; nothing was paid',
        ),
      ]) {
        testWidgets('$name is not paid, not sent', (tester) async {
          final service = await serve(
            gate: SigningGate.open,
            onSubmit: (req, n) => lost(connect.Code.unavailable),
            onGetCall: (req, n) => settlement.GetAccountCallResponse(
              call: settlement.AccountCall(
                callId: req.callId,
                state: state,
                failureReason: failure,
              ),
            ),
          );
          await openAndSubmit(tester, service);
          await sign(tester);

          expect(find.text(message), findsOneWidget);
          expect(find.text(sentWaitingMessage), findsNothing);
          expect(find.byKey(const Key('contribute-state')), findsNothing);
          expect(await service.unconfirmedCall(), isNull, reason: 'known');
        });
      }

      testWidgets('a call settlement no longer knows is not paid', (
        tester,
      ) async {
        final service = await serve(
          gate: SigningGate.open,
          onSubmit: (req, n) => lost(connect.Code.unavailable),
          onGetCall: (req, n) => throw connect.ConnectException(
            connect.Code.notFound,
            'no such call',
          ),
        );
        await openAndSubmit(tester, service);
        await sign(tester);

        expect(
          find.text('It did not go through; nothing was paid'),
          findsOneWidget,
        );
        expect(await service.unconfirmedCall(), isNull);
      });

      testWidgets('an earlier call that expired is named, and nothing new is '
          'prepared', (tester) async {
        final db = createTestDatabase();
        addTearDown(db.close);
        final store = DriftUnconfirmedMoneyCallStore(db);
        await store.hold(
          'p1',
          SignedMoneyCall(
            callId: 'acct-earlier',
            authorization: Uint8List(65),
            title: 'Pay 200.00 USDC into Chama',
          ),
        );
        await openAndSubmit(
          tester,
          await serve(
            gate: SigningGate.open,
            unconfirmed: store,
            onGetCall: (req, n) => callIn(
              req,
              settlement.AccountCallState.ACCOUNT_CALL_STATE_EXPIRED,
            ),
          ),
        );

        expect(find.byKey(const Key('money-review')), findsNothing);
        expect(prepares(), 0);
        expect(
          find.text(
            '“Pay 200.00 USDC into Chama” was not sent: It expired before it '
            'went through; nothing was paid',
          ),
          findsOneWidget,
        );
        expect(await store.read('p1'), isNull);
      });

      testWidgets('a clear refusal says why and leaves nothing pending', (
        tester,
      ) async {
        final service = await serve(
          gate: SigningGate.open,
          onSubmit: (req, n) => n == 0
              ? throw connect.ConnectException(
                  connect.Code.failedPrecondition,
                  'insufficient balance',
                )
              : settlement.SubmitAccountCallResponse(
                  call: settlement.AccountCall(callId: req.callId),
                ),
        );
        await openAndSubmit(tester, service);
        await sign(tester);

        expect(submits(), 1);
        expect(
          transport.requestsTo(settlement.AccountService.getAccountCall),
          isEmpty,
        );
        expect(find.text('insufficient balance'), findsOneWidget);

        ScaffoldMessenger.of(tester.element(find.byType(ContributeScreen)))
            .removeCurrentSnackBar();
        await tester.tap(find.byKey(const Key('contribute-submit')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('money-review')), findsOneWidget);
      });
    });

    group('settlement\'s open calls are checked before the review', () {
      const title = 'Pay 500.00 USDC into Chama';

      /// A contribution settlement lists as open on the account: sent from
      /// another device, or before a reinstall.
      settlement.ListAccountCallsResponse openContribution({List<int>? from}) =>
          settlement.ListAccountCallsResponse(
            calls: [
              settlement.AccountCall(
                callId: 'acct-other-device',
                address: from ?? account,
                kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_CONTRIBUTE,
                state: settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED,
              ),
            ],
          );

      List<settlement.ListAccountCallsRequest> lists() =>
          transport.requestsTo(settlement.AccountService.listAccountCalls);

      void dismissSnack(WidgetTester tester) =>
          ScaffoldMessenger.of(tester.element(find.byType(ContributeScreen)))
              .removeCurrentSnackBar();

      testWidgets('an open call is followed and nothing new is signed', (
        tester,
      ) async {
        final gate = RecordingSigningGate();
        final service = await serve(
          gate: gate,
          onList: (req, n) => openContribution(),
        );
        await openAndSubmit(tester, service);

        expect(find.byKey(const Key('money-review')), findsNothing);
        expect(gate.reasons, isEmpty, reason: 'nothing signed');
        expect(submits(), 0, reason: 'nothing sent');
        expect(prepares(), 1, reason: 'only the unsigned call this tap made');
        expect(lists().single.address, account);
        expect(
          find.textContaining('A payment like this one is still going through'),
          findsOneWidget,
        );
        expect(await service.unconfirmedCall(), isNull);

        // The open call is followed until it ends, and that is said.
        dismissSnack(tester);
        await tester.pumpAndSettle();
        expect(find.text('The earlier payment is done'), findsOneWidget);
        expect(
          transport
              .requestsTo(settlement.AccountService.getAccountCall)
              .map((r) => r.callId),
          contains('acct-other-device'),
        );
      });

      testWidgets('with no open call the payment goes ahead as usual', (
        tester,
      ) async {
        final service = await serve(
          gate: SigningGate.open,
          onList: (req, n) => settlement.ListAccountCallsResponse(),
        );
        await openAndSubmit(tester, service);

        expect(lists().single.address, account, reason: 'read first');
        expect(find.byKey(const Key('money-review')), findsOneWidget);
        await sign(tester);
        expect(submits(), 1);
        expect(prepares(), 1);
        expect(find.byKey(const Key('contribute-state')), findsOneWidget);
      });

      testWidgets('another account\'s open call does not hold it back', (
        tester,
      ) async {
        final service = await serve(
          gate: SigningGate.open,
          onList: (req, n) =>
              openContribution(from: Uint8List.fromList(List.filled(20, 7))),
        );
        await openAndSubmit(tester, service);
        expect(find.byKey(const Key('money-review')), findsOneWidget);
      });

      for (final code in [
        connect.Code.unauthenticated,
        connect.Code.resourceExhausted,
        connect.Code.unavailable,
      ]) {
        testWidgets('a list that fails (${code.name}) sends nothing new and '
            'holds the payment back until settlement can say', (tester) async {
          var failing = true;
          final gate = RecordingSigningGate();
          final service = await serve(
            gate: gate,
            onList: (req, n) => failing
                ? throw connect.ConnectException(code, 'the list was refused')
                : settlement.ListAccountCallsResponse(),
          );
          await openAndSubmit(tester, service);

          expect(find.byKey(const Key('money-review')), findsNothing);
          expect(gate.reasons, isEmpty);
          expect(submits(), 0);
          expect(find.textContaining(openCallsUnknownMessage), findsOneWidget);
          expect(await service.unconfirmedCall(), isNull);

          // Still failing: still held back.
          dismissSnack(tester);
          await tester.tap(find.byKey(const Key('contribute-submit')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('money-review')), findsNothing);
          expect(submits(), 0);

          // Once settlement answers, the person may go on.
          dismissSnack(tester);
          failing = false;
          await tester.tap(find.byKey(const Key('contribute-submit')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('money-review')), findsOneWidget);
        });
      }

      testWidgets('a second device with no record of the call still finds it '
          'and does not pay again', (tester) async {
        // This device's database is empty: the call was sent from another
        // device (or before a reinstall or cleared app data).
        final db = createTestDatabase();
        addTearDown(db.close);
        final store = DriftUnconfirmedMoneyCallStore(db);
        expect(await store.read('p1'), isNull);
        final gate = RecordingSigningGate();
        final service = await serve(
          gate: gate,
          unconfirmed: store,
          onList: (req, n) => openContribution(),
        );
        await openAndSubmit(tester, service);

        expect(find.byKey(const Key('money-review')), findsNothing);
        expect(gate.reasons, isEmpty);
        expect(submits(), 0);
        expect(await store.read('p1'), isNull, reason: 'nothing was signed');
      });

      testWidgets('an earlier call found taken says its outcome once it ends '
          '(M4)', (tester) async {
        var reachable = false;
        final service = await serve(
          gate: SigningGate.open,
          onSubmit: (req, n) => lost(connect.Code.unavailable),
          onGetCall: (req, n) => reachable
              ? callIn(
                  req,
                  settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL,
                )
              : lost(connect.Code.unavailable),
        );
        await openAndSubmit(tester, service);
        await sign(tester);
        expect(find.text(notConfirmedSubmitMessage), findsOneWidget);

        dismissSnack(tester);
        reachable = true;
        await tester.tap(find.byKey(const Key('contribute-submit')));
        await tester.pumpAndSettle();
        expect(find.text(earlierCallSentMessage(title)), findsOneWidget);
        expect(prepares(), 1, reason: 'nothing new prepared');

        // Not reset silently: its own outcome follows once it is final.
        dismissSnack(tester);
        await tester.pumpAndSettle();
        expect(find.text('Done: “$title”'), findsOneWidget);
      });
    });

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

/// A store whose first clear fails, as a database error would.
final class _ClearFailsOnce extends MemoryUnconfirmedMoneyCallStore {
  var _failed = false;

  @override
  Future<void> clear(String profileId, String callId) async {
    if (!_failed) {
      _failed = true;
      throw StateError('database is locked');
    }
    await super.clear(profileId, callId);
  }
}
