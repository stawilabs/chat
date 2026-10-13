import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
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
      accounts: settlement.AccountServiceClient(transport),
      keys: DeviceKeyStore(vaultWith('p1', v.devicePrivateKey)),
      proofs: refusingSessionProofs,
      identity: () async => identityWith('p1', v.account),
    );

    test('every action is checked, shown and signed byte for byte', () async {
      for (final v in vectors) {
        transport = FakeConnectTransport();
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
        expect(prepared.call.action, request.call.action, reason: v.name);
        expect(prepared.call.room, v.room);

        final prepare = transport
            .requestsTo(settlement.AccountService.prepareAccountCall)
            .single;
        expect(prepare.kind, request.call.kind, reason: v.name);
        expect(prepare.params.room, v.room);
        if (request.call.takesLoan) {
          expect(prepare.params.loanId, Int64(request.loanId));
        }

        await s.submitEngineCall(prepared);
        final submit = transport
            .requestsTo(settlement.AccountService.submitAccountCall)
            .single;
        expect(bytesToHex0x(submit.authorization), v.signature, reason: v.name);
      }
    });

    test('a payoff without a ceiling shows the quoted one', () async {
      final v = vectors.firstWhere((v) => v.name == 'loan_payoff');
      transport.on(
        settlement.AccountService.prepareAccountCall,
        (req) => v.prepared(req.kind),
      );
      final prepared = await service(
        v,
      ).prepareEngineCall(requestFor(v, amount: ''), engines: v.engines());
      final prepare = transport
          .requestsTo(settlement.AccountService.prepareAccountCall)
          .single;
      expect(prepare.params.hasAmount(), isFalse);
      expect(prepared.call.amount, BigInt.from(520000000));
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
        await expectLater(
          service(
            pledge,
          ).prepareEngineCall(entry.value, engines: pledge.engines()),
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

    test('refuses an intent that does not bind the calldata', () async {
      final v = vectors.firstWhere((v) => v.name == 'withdraw_credit');
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

    settlement.PrepareRoomCallResponse prepared({List<int>? payloadHash}) =>
        settlement.PrepareRoomCallResponse(
          call: settlement.RoomCall(
            exitIntent: v.intent..amount = '5000',
            payloadHash:
                payloadHash ??
                intentDigestOf(sdkIntentOf(v.intent..amount = '5000')),
          ),
        );

    test('accepts the exit the ballot carries', () {
      checkPrincipalExit(prepared(), amount: '5000');
    });

    test('refuses another amount, a foreign payload hash or no intent', () {
      expect(
        () => checkPrincipalExit(prepared(), amount: '4999'),
        throwsA(isA<SigningRefused>()),
      );
      expect(
        () => checkPrincipalExit(
          prepared(payloadHash: Uint8List(32)),
          amount: '5000',
        ),
        throwsA(isA<SigningRefused>()),
      );
      expect(
        () => checkPrincipalExit(
          settlement.PrepareRoomCallResponse(call: settlement.RoomCall()),
          amount: '5000',
        ),
        throwsA(isA<SigningRefused>()),
      );
    });
  });

  test('secret ballots use the SDK commitment and choice numbers', () {
    final vectors =
        (jsonDecode(
                  File(
                    'test/fixtures/stawi/go_vote_commitments.json',
                  ).readAsStringSync(),
                )
                as List)
            .cast<Map<String, dynamic>>();
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
