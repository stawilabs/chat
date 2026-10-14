import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/signing_gate.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/domain/account_engine_calls.dart';
import 'package:stawi/features/stawi/domain/intent_bridge.dart';
import 'package:stawi/features/stawi/domain/secret_ballot.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

AccountEngineCall callFor(String action) => switch (action) {
  'request' => AccountEngineCall.loanRequest,
  'approve' => AccountEngineCall.loanApprove,
  'pledge' => AccountEngineCall.loanPledge,
  'unpledge' => AccountEngineCall.loanUnpledge,
  'cancel' => AccountEngineCall.loanCancel,
  'payoff' => AccountEngineCall.loanPayoff,
  'chooseAmount' => AccountEngineCall.chooseAmount,
  'withdrawCredit' => AccountEngineCall.withdrawCredit,
  'withdrawEquity' => AccountEngineCall.withdrawEquity,
  _ => throw ArgumentError(action),
};

/// The request a member makes for a vector's call.
AccountEngineRequest requestFor(GoEngineCallVector v, {String? amount}) {
  final call = callFor(v.action);
  final json = v.json;
  return AccountEngineRequest(
    call: call,
    custody: v.room,
    amount: amount ?? (call.takesAmount ? json['amount'] as String : ''),
    loanId: json['loan_id'] as int,
    productId: call.takesProduct
        ? hexToBytes(json['product_id'] as String)
        : null,
    instalments: json['instalments'] as int,
    replaces: json['replaces'] as int,
  );
}

void main() {
  final vectors = GoEngineCallVector.load().where((v) => !v.personal).toList();
  late FakeConnectTransport transport;

  setUp(() => transport = FakeConnectTransport());

  test('the intent bridge reproduces every Go engine-call digest', () {
    expect(vectors, hasLength(11));
    for (final v in vectors) {
      expect(intentDigestOf(sdkIntentOf(v.intent)), v.digest, reason: v.name);
    }
  });

  group('engine calls', () {
    StawiAccountService service(GoEngineCallVector v) => StawiAccountService(
      roomAssets: testRoomAssets,
      accounts: settlement.AccountServiceClient(transport),
      keys: DeviceKeyStore(
        vaultWith('p1', v.devicePrivateKey),
        gate: SigningGate.open,
      ),
      proofs: refusingSessionProofs,
      identity: () async => identityWith('p1', v.account),
    );

    test('every action is checked, shown and signed byte for byte', () async {
      for (final v in vectors) {
        transport = FakeConnectTransport();
        await serveDeployedAccount(transport, v.devicePrivateKey);
        final request = requestFor(v);
        transport
          ..on(
            settlement.AccountService.prepareAccountCall,
            (req) => v.prepared(req.kind),
          )
          ..on(
            settlement.AccountService.submitAccountCall,
            (req) => settlement.SubmitAccountCallResponse(
              call: settlement.AccountCall(callId: req.callId),
            ),
          );
        final s = service(v);
        final prepared = await s.prepareEngineCall(
          request,
          engines: v.engines(),
        );
        expect(prepared.call!.action, request.call.action, reason: v.name);
        expect(prepared.call!.room, v.room);

        final prepare = transport
            .requestsTo(settlement.AccountService.prepareAccountCall)
            .single;
        expect(prepare.kind, request.call.kind, reason: v.name);
        expect(prepare.params.room, v.room);
        if (request.call.takesLoan) {
          expect(prepare.params.loanId, Int64(request.loanId));
        }

        await s.submit(prepared);
        final submit = transport
            .requestsTo(settlement.AccountService.submitAccountCall)
            .single;
        expect(bytesToHex0x(submit.authorization), v.signature, reason: v.name);
      }
    });

    test('a refused device lock submits no engine call', () async {
      final v = vectors.first;
      await serveDeployedAccount(transport, v.devicePrivateKey);
      transport
        ..on(
          settlement.AccountService.prepareAccountCall,
          (req) => v.prepared(req.kind),
        )
        ..on(
          settlement.AccountService.submitAccountCall,
          (req) => settlement.SubmitAccountCallResponse(
            call: settlement.AccountCall(callId: req.callId),
          ),
        );
      final gate = RecordingSigningGate(refuse: true);
      final s = StawiAccountService(
        roomAssets: testRoomAssets,
        accounts: settlement.AccountServiceClient(transport),
        keys: DeviceKeyStore(vaultWith('p1', v.devicePrivateKey), gate: gate),
        proofs: refusingSessionProofs,
        identity: () async => identityWith('p1', v.account),
      );
      final request = requestFor(v);
      final prepared = await s.prepareEngineCall(request, engines: v.engines());
      expect(gate.reasons, isEmpty, reason: 'preparing signs nothing');
      await expectLater(s.submit(prepared), throwsA(isA<SigningRefused>()));
      expect(gate.reasons, [request.summary]);
      expect(
        transport.requestsTo(settlement.AccountService.submitAccountCall),
        isEmpty,
      );
    });

    test('a payoff without a ceiling shows the quoted one', () async {
      final v = vectors.firstWhere((v) => v.name == 'loan_payoff');
      await serveDeployedAccount(transport, v.devicePrivateKey);
      transport.on(
        settlement.AccountService.prepareAccountCall,
        (req) => v.prepared(req.kind),
      );
      final prepared = await service(v)
          .prepareEngineCall(requestFor(v, amount: ''), engines: v.engines());
      final prepare = transport
          .requestsTo(settlement.AccountService.prepareAccountCall)
          .single;
      expect(prepare.params.hasAmount(), isFalse);
      expect(prepared.call!.amount, BigInt.from(520000000));
    });

    test('refuses a call other than the one asked for', () async {
      final pledge = vectors.firstWhere((v) => v.name == 'loan_pledge');
      final cases = <String, AccountEngineRequest>{
        'another amount': requestFor(pledge, amount: '1'),
        'another loan': AccountEngineRequest(
          call: AccountEngineCall.loanPledge,
          custody: pledge.room,
          amount: '150000000',
          loanId: 4,
        ),
        'another room': AccountEngineRequest(
          call: AccountEngineCall.loanPledge,
          custody: Uint8List(20),
          amount: '150000000',
          loanId: 3,
        ),
        'another action': AccountEngineRequest(
          call: AccountEngineCall.loanPayoff,
          custody: pledge.room,
          amount: '150000000',
          loanId: 3,
        ),
      };
      for (final entry in cases.entries) {
        transport = FakeConnectTransport()
          ..on(
            settlement.AccountService.prepareAccountCall,
            (req) => pledge.prepared(req.kind),
          );
        await serveDeployedAccount(transport, pledge.devicePrivateKey);
        await expectLater(
          service(pledge)
              .prepareEngineCall(entry.value, engines: pledge.engines()),
          throwsA(isA<SigningRefused>()),
          reason: entry.key,
        );
      }
    });

    test('a room call prepared for another amount than asked is refused', () {
      final v = GoEngineCallVector.load().firstWhere(
        (v) => v.name == 'loan_request',
      );
      final request = AccountEngineRequest(
        call: AccountEngineCall.loanRequest,
        custody: v.room,
        amount: '400000000', // the vector requests 500000000
        productId: hexToBytes(v.json['product_id'] as String),
        instalments: 4,
      );
      expect(
        () => checkedEngineCall(
          prepared: v.prepared(AccountEngineCall.loanRequest.kind),
          request: request,
          account: v.account,
          engines: v.engines(),
        ),
        throwsA(
          isA<SigningRefused>().having(
            (e) => e.reason,
            'reason',
            contains('not the call you asked for'),
          ),
        ),
      );
    });

    test('without an account of our own the call is refused, even when the '
        'prepared call names none', () {
      final v = GoEngineCallVector.load().firstWhere(
        (v) => v.name == 'loan_request',
      );
      final request = AccountEngineRequest(
        call: AccountEngineCall.loanRequest,
        custody: v.room,
        amount: '500000000',
        productId: hexToBytes(v.json['product_id'] as String),
        instalments: 4,
      );
      final nobody = v.prepared(AccountEngineCall.loanRequest.kind)
        ..call.address = <int>[]
        ..financialIntent.account = <int>[];
      for (final account in [Uint8List(0), Uint8List(20)]) {
        for (final p in [
          v.prepared(AccountEngineCall.loanRequest.kind),
          nobody,
        ]) {
          expect(
            () => checkedEngineCall(
              prepared: p,
              request: request,
              account: account,
              engines: v.engines(),
            ),
            throwsA(
              isA<SigningRefused>().having(
                (e) => e.reason,
                'reason',
                noAccountReason,
              ),
            ),
          );
        }
      }
    });

    test('refuses an intent that does not bind the calldata', () async {
      final v = vectors.firstWhere((v) => v.name == 'withdraw_credit');
      await serveDeployedAccount(transport, v.devicePrivateKey);
      transport.on(
        settlement.AccountService.prepareAccountCall,
        (req) =>
            v.prepared(req.kind)
              ..call.engineTarget = Uint8List.fromList(List.filled(20, 9)),
      );
      await expectLater(
        service(v).prepareEngineCall(requestFor(v), engines: v.engines()),
        throwsA(isA<SigningRefused>()),
      );
    });

    test('refuses a digest that is not the intent\'s', () async {
      final v = vectors.firstWhere((v) => v.name == 'withdraw_equity');
      final bad = Uint8List.fromList(v.digest)..[0] ^= 1;
      await serveDeployedAccount(transport, v.devicePrivateKey);
      transport.on(
        settlement.AccountService.prepareAccountCall,
        (req) => v.prepared(req.kind)
          ..intentDigest = bad
          ..call.intentDigest = bad,
      );
      await expectLater(
        service(v).prepareEngineCall(requestFor(v), engines: v.engines()),
        throwsA(isA<SigningRefused>()),
      );
    });
  });

  group('principal exit check', () {
    final v = vectors.first;
    final custody = Uint8List(20)..[0] = 0x30;
    final to = Uint8List(20)..[19] = 0x44;
    final room = RoomContracts(custody: custody, chainId: BigInt.from(146));

    finance.FinancialIntent exit() => v.intent
      ..account = custody
      ..domain.chainId = Int64(146)
      ..source = finance.ValueLocation(
        kind: finance.LocationKind.LOCATION_KIND_ROOM_CUSTODY,
        address: custody,
      )
      ..destination = finance.ValueLocation(
        kind: finance.LocationKind.LOCATION_KIND_USER_ACCOUNT,
        address: to,
      )
      ..amount = '5000';

    settlement.PrepareRoomCallResponse prepared({
      List<int>? payloadHash,
      finance.FinancialIntent? intent,
    }) {
      final i = intent ?? exit();
      return settlement.PrepareRoomCallResponse(
        call: settlement.RoomCall(
          exitIntent: i,
          payloadHash: payloadHash ?? intentDigestOf(sdkIntentOf(i)),
        ),
      );
    }

    test('accepts the exit the ballot carries and returns its digest', () {
      expect(
        checkPrincipalExit(prepared(), amount: '5000', room: room, to: to),
        intentDigestOf(sdkIntentOf(exit())),
      );
    });

    test('refuses another amount, a foreign payload hash or no intent', () {
      expect(
        () =>
            checkPrincipalExit(prepared(), amount: '4999', room: room, to: to),
        throwsA(isA<SigningRefused>()),
      );
      expect(
        () => checkPrincipalExit(
          prepared(payloadHash: Uint8List(32)),
          amount: '5000',
          room: room,
          to: to,
        ),
        throwsA(isA<SigningRefused>()),
      );
      expect(
        () => checkPrincipalExit(
          settlement.PrepareRoomCallResponse(call: settlement.RoomCall()),
          amount: '5000',
          room: room,
          to: to,
        ),
        throwsA(isA<SigningRefused>()),
      );
    });

    test('refuses another room, chain or destination', () {
      for (final intent in [
        exit()..account = (Uint8List(20)..[0] = 0x31),
        exit()..domain.chainId = Int64(147),
        exit()..destination.address = (Uint8List(20)..[19] = 0x45),
      ]) {
        expect(
          () => checkPrincipalExit(
            prepared(intent: intent),
            amount: '5000',
            room: room,
            to: to,
          ),
          throwsA(isA<SigningRefused>()),
        );
      }
      // A bucket move stays in the room's custody.
      expect(
        () => checkPrincipalExit(prepared(), amount: '5000', room: room),
        throwsA(isA<SigningRefused>()),
      );
    });
  });

  test('secret ballots use the SDK commitment and choice numbers', () {
    final vectors = (jsonDecode(
      File('test/fixtures/stawi/go_vote_commitments.json').readAsStringSync(),
    ) as List).cast<Map<String, dynamic>>();
    final v = vectors[1];
    final sealed = SealedVote(
      choice: finance.VoteChoice.valueOf(v['choice'] as int)!,
      salt: hexToBytes(v['salt'] as String),
      member: hexToBytes(v['member'] as String),
    );
    expect(
      bytesToHex0x(sealed.commitment(int.parse(v['proposal_id'] as String))),
      v['commitment'],
    );
    expect(
      chainChoiceOf(finance.VoteChoice.VOTE_CHOICE_APPROVE),
      voteChoiceFor,
    );
    expect(
      chainChoiceOf(finance.VoteChoice.VOTE_CHOICE_REJECT),
      voteChoiceAgainst,
    );
    expect(
      chainChoiceOf(finance.VoteChoice.VOTE_CHOICE_ABSTAIN),
      voteChoiceAbstain,
    );
  });
}
