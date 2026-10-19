import 'dart:typed_data';

import 'package:connectrpc/connect.dart' as connect;
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/money_call_fate.dart';
import 'package:stawi/features/stawi/data/open_money_calls.dart';
import 'package:stawi/features/stawi/data/signing_gate.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/domain/account_engine_calls.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

const _pledgeKind = settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_PLEDGE;

void main() {
  final vectors = GoEngineCallVector.load();
  final pledge = vectors.firstWhere((v) => v.name == 'loan_pledge');
  final payoff = vectors.firstWhere((v) => v.name == 'loan_payoff');
  final pledged = EngineCall.decode(pledge.calldata, path: EnginePath.room);

  IntendedCall intended(
    GoEngineCallVector v,
    settlement.AccountCallKind kind, {
    List<int>? calldata,
  }) => (
    account: v.account,
    kind: kind,
    engineTarget: v.target,
    engineCalldata: calldata ?? v.calldata,
  );

  settlement.AccountCall open(
    GoEngineCallVector v,
    settlement.AccountCallKind kind, {
    List<int>? account,
    List<int>? calldata,
    List<int>? target,
    settlement.AccountCallState state =
        settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED,
    String callId = 'acct0000000000000ff1',
  }) => settlement.AccountCall(
    callId: callId,
    address: account ?? v.account,
    kind: kind,
    state: state,
    engineTarget: target ?? v.target,
    engineCalldata: calldata ?? v.calldata,
  );

  group('an open call matches the payment asked for', () {
    test('on the same account, kind, target and amount', () {
      expect(
        matchOpenCall(open(pledge, _pledgeKind), intended(pledge, _pledgeKind)),
        OpenCallMatch.samePayment,
      );
    });

    test('not on another account, another kind or another engine', () {
      final other = Uint8List.fromList(List.filled(20, 0x42));
      final i = intended(pledge, _pledgeKind);
      expect(
        matchOpenCall(open(pledge, _pledgeKind, account: other), i),
        OpenCallMatch.none,
      );
      expect(
        matchOpenCall(
          open(
            pledge,
            settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_UNPLEDGE,
          ),
          i,
        ),
        OpenCallMatch.none,
      );
      expect(
        matchOpenCall(open(pledge, _pledgeKind, target: other), i),
        OpenCallMatch.none,
      );
    });

    test('not for another amount or another loan', () {
      final more = EngineCall(
        action: pledged.action,
        room: pledged.room,
        loanId: pledged.loanId,
        amount: pledged.amount + BigInt.one,
      ).calldata;
      final otherLoan = EngineCall(
        action: pledged.action,
        room: pledged.room,
        loanId: pledged.loanId + BigInt.one,
        amount: pledged.amount,
      ).calldata;
      final i = intended(pledge, _pledgeKind);
      expect(
        matchOpenCall(open(pledge, _pledgeKind, calldata: more), i),
        OpenCallMatch.none,
      );
      expect(
        matchOpenCall(open(pledge, _pledgeKind, calldata: otherLoan), i),
        OpenCallMatch.none,
      );
    });

    test('a payoff of the same loan whatever settlement quoted', () {
      const kind = settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_PAYOFF;
      final c = EngineCall.decode(payoff.calldata, path: EnginePath.room);
      final requoted = EngineCall(
        action: c.action,
        room: c.room,
        loanId: c.loanId,
        amount: c.amount + BigInt.from(1000),
      ).calldata;
      expect(
        matchOpenCall(
          open(payoff, kind, calldata: requoted),
          intended(payoff, kind),
        ),
        OpenCallMatch.samePayment,
      );
    });

    test('by kind alone when the listed call carries no target or amount', () {
      const kind = settlement.AccountCallKind.ACCOUNT_CALL_KIND_CONTRIBUTE;
      final listed = settlement.AccountCall(
        address: pledge.account,
        kind: kind,
      );
      expect(
        matchOpenCall(listed, (
          account: pledge.account,
          kind: kind,
          engineTarget: const <int>[],
          engineCalldata: const <int>[],
        )),
        OpenCallMatch.sameKind,
      );
    });

    test('calldata the SDK cannot read only when it is the same bytes', () {
      const kind = settlement.AccountCallKind.ACCOUNT_CALL_KIND_VAULT_DEPOSIT;
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final i = intended(pledge, kind, calldata: bytes);
      expect(
        matchOpenCall(open(pledge, kind, calldata: bytes), i),
        OpenCallMatch.samePayment,
      );
      expect(
        matchOpenCall(open(pledge, kind, calldata: [9, 9, 9, 9, 9]), i),
        OpenCallMatch.sameKind,
        reason: 'not told apart, so not paid again',
      );
    });
  });

  group('refuseOpenCalls', () {
    late FakeConnectTransport transport;

    Future<(StawiAccountService, PreparedMoneyCall)> prepared({
      settlement.ListAccountCallsResponse Function(
        settlement.ListAccountCallsRequest req,
        int n,
      )?
      onList,
    }) async {
      var lists = 0;
      transport = FakeConnectTransport()
        ..on(
          settlement.AccountService.prepareAccountCall,
          (req) => pledge.prepared(req.kind),
        );
      if (onList != null) {
        transport.on(
          settlement.AccountService.listAccountCalls,
          (req) => onList(req, lists++),
        );
      }
      await serveDeployedAccount(transport, pledge.devicePrivateKey);
      final service = StawiAccountService(
        accounts: settlement.AccountServiceClient(transport),
        keys: DeviceKeyStore(
          vaultWith('p1', pledge.devicePrivateKey),
          gate: SigningGate.open,
        ),
        proofs: refusingSessionProofs,
        identity: () async => identityWith('p1', pledge.account),
      );
      final call = await service.prepareEngineCall(
        AccountEngineRequest(
          call: AccountEngineCall.loanPledge,
          custody: pledge.room,
          amount: pledged.amount.toString(),
          loanId: pledged.loanId.toInt(),
        ),
        engines: pledge.engines(),
      );
      return (service, call);
    }

    List<settlement.ListAccountCallsRequest> lists() =>
        transport.requestsTo(settlement.AccountService.listAccountCalls);

    test('reads only the account the call is made from', () async {
      final (service, call) = await prepared();
      await service.refuseOpenCalls(call);
      final [req] = lists();
      expect(req.address, pledge.account);
      expect(req.cursor, isEmpty);
    });

    test('an open call of the same payment is named, taken', () async {
      final (service, call) = await prepared(
        onList: (req, n) => settlement.ListAccountCallsResponse(
          calls: [open(pledge, _pledgeKind)],
        ),
      );
      OpenMoneyCall? refused;
      try {
        await service.refuseOpenCalls(call);
      } on OpenMoneyCall catch (e) {
        refused = e;
      }
      expect(refused, isNotNull);
      expect(refused!.samePayment, isTrue);
      expect(refused.call.callId, 'acct0000000000000ff1');
      expect(refused.fate, isA<CallTaken>());
    });

    test('a signed call settlement has not sent is not known yet', () async {
      final (service, call) = await prepared(
        onList: (req, n) => settlement.ListAccountCallsResponse(
          calls: [
            open(
              pledge,
              _pledgeKind,
              state: settlement.AccountCallState.ACCOUNT_CALL_STATE_PREPARED,
            ),
          ],
        ),
      );
      await expectLater(
        service.refuseOpenCalls(call),
        throwsA(
          isA<OpenMoneyCall>().having(
            (o) => o.fate,
            'fate',
            isA<CallUnknown>(),
          ),
        ),
      );
    });

    test('a later page is read', () async {
      final (service, call) = await prepared(
        onList: (req, n) => n == 0
            ? settlement.ListAccountCallsResponse(nextCursor: 'acct01')
            : settlement.ListAccountCallsResponse(
                calls: [open(pledge, _pledgeKind)],
              ),
      );
      await expectLater(
        service.refuseOpenCalls(call),
        throwsA(isA<OpenMoneyCall>()),
      );
      expect(lists().map((r) => r.cursor), ['', 'acct01']);
    });

    test('another account\'s, another payment\'s and an ended call do not '
        'hold it back', () async {
      final other = Uint8List.fromList(List.filled(20, 0x42));
      final more = EngineCall(
        action: pledged.action,
        room: pledged.room,
        loanId: pledged.loanId,
        amount: pledged.amount * BigInt.two,
      ).calldata;
      final (service, call) = await prepared(
        onList: (req, n) => settlement.ListAccountCallsResponse(
          calls: [
            open(pledge, _pledgeKind, account: other),
            open(pledge, _pledgeKind, calldata: more),
            open(
              pledge,
              _pledgeKind,
              state: settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL,
            ),
          ],
        ),
      );
      await service.refuseOpenCalls(call);
    });

    for (final code in [
      connect.Code.unauthenticated,
      connect.Code.resourceExhausted,
      connect.Code.unavailable,
      connect.Code.permissionDenied,
      connect.Code.unimplemented,
    ]) {
      test('a list that fails (${code.name}) holds the call back', () async {
        final (service, call) = await prepared(
          onList: (req, n) => throw connect.ConnectException(code, 'refused'),
        );
        await expectLater(
          service.refuseOpenCalls(call),
          throwsA(
            isA<OpenCallsUnknown>().having(
              (u) => (u.error! as connect.ConnectException).code,
              'code',
              code,
            ),
          ),
        );
      });
    }

    test('more open calls than are read hold the call back', () async {
      final (service, call) = await prepared(
        onList: (req, n) =>
            settlement.ListAccountCallsResponse(nextCursor: 'acct$n'),
      );
      await expectLater(
        service.refuseOpenCalls(call),
        throwsA(isA<OpenCallsUnknown>()),
      );
    });
  });
}
