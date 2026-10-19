import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/domain/account_engine_calls.dart';
import 'package:stawi/features/stawi/ui/loan_widgets.dart';
import 'package:stawi/features/stawi/ui/money_review_sheet.dart';
import 'package:stawi/features/stawi/ui/stawi_feedback.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

const _kind = settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_PLEDGE;

void main() {
  final pledge = GoEngineCallVector.load().firstWhere(
    (v) => v.name == 'loan_pledge',
  );
  final pledged = EngineCall.decode(pledge.calldata, path: EnginePath.room);

  testWidgets('the same payment already sent from another device is followed '
      'as the call asked for: its review\'s done is said once it is final '
      '(I3, M4)', (tester) async {
    final transport = FakeConnectTransport()
      ..on(
        settlement.AccountService.prepareAccountCall,
        (req) => pledge.prepared(req.kind),
      )
      ..on(
        settlement.AccountService.listAccountCalls,
        (req) => settlement.ListAccountCallsResponse(
          calls: [
            settlement.AccountCall(
              callId: 'acct-other-device',
              address: pledge.account,
              kind: _kind,
              state: settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED,
              engineTarget: pledge.target,
              engineCalldata: pledge.calldata,
            ),
          ],
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
    await serveDeployedAccount(transport, pledge.devicePrivateKey);
    final gate = RecordingSigningGate();
    final service = StawiAccountService(
      accounts: settlement.AccountServiceClient(transport),
      keys: DeviceKeyStore(
        vaultWith('p1', pledge.devicePrivateKey),
        gate: gate,
      ),
      proofs: refusingSessionProofs,
      identity: () async => identityWith('p1', pledge.account),
      followEvery: Duration.zero,
    );

    late String title;
    late String done;
    settlement.AccountCall? answered;
    settlement.AccountCall? last;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [stawiAccountServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => FilledButton(
                onPressed: () async {
                  // As a pledge screen does: prepare, review and submit,
                  // then follow what it answered until it is final.
                  final container = moneyContainer(context);
                  answered = await runMoneyAction(context, ref, () async {
                    final prepared = await service.prepareEngineCall(
                      AccountEngineRequest(
                        call: AccountEngineCall.loanPledge,
                        custody: pledge.room,
                        amount: pledged.amount.toString(),
                        loanId: pledged.loanId.toInt(),
                      ),
                      engines: pledge.engines(),
                    );
                    title = prepared.review.title;
                    done = prepared.review.done;
                    return prepared;
                  });
                  if (answered != null) {
                    last = await settleThenRefresh(
                      container,
                      service,
                      answered!,
                      const [],
                    );
                  }
                },
                child: const Text('pledge'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('pledge'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('money-review')), findsNothing);
    expect(gate.reasons, isEmpty, reason: 'nothing signed');
    expect(
      transport.requestsTo(settlement.AccountService.submitAccountCall),
      isEmpty,
    );
    expect(answered?.callId, 'acct-other-device');
    expect(last?.state, settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL);
    expect(find.text(alreadySentMessage(title)), findsOneWidget);

    ScaffoldMessenger.of(tester.element(find.text('pledge')))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();
    expect(find.text(done), findsOneWidget, reason: 'the review\'s done');
  });
}
