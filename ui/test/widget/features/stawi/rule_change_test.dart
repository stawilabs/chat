import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_finance_service.dart';
import 'package:stawi/features/stawi/data/stawi_room_service.dart';
import 'package:stawi/features/stawi/domain/rule_changes.dart';
import 'package:stawi/features/stawi/domain/secret_ballot.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi/features/stawi/ui/rule_change_screen.dart';
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
  late GoRuleChange vector;
  late RoomContracts room;
  late FakeConnectTransport transport;
  late RecordingActSender sender;
  late RecordingSigningGate gate;
  late settlement.RoomPolicyChange compiled;
  late List<finance.Proposal> undecided;
  late finance.ProposalState proposalState;
  settlement.PrepareRoomCallResponse? lastPrepared;

  setUp(() {
    vector = GoRuleChange.named('quorum_and_minimum');
    compiled = vector.change;
    room = RoomContracts(
      governance: Uint8List(20)..[0] = 0x41,
      custody: vector.custody,
      chainId: BigInt.from(146),
    );
    undecided = [finance.Proposal(), finance.Proposal()];
    proposalState = finance.ProposalState.PROPOSAL_STATE_OPEN;
    lastPrepared = null;
    gate = RecordingSigningGate();
    sender = RecordingActSender();
    transport = FakeConnectTransport()
      ..on(
        settlement.RoomService.prepareRoomCall,
        (req) => lastPrepared = honestRoomCall(
          req,
          room: room,
          signer: account,
          chatRoomId: roomId,
          policyChange: compiled,
          policyPayloadHash: hexToBytes(vector.json['payload_hash'] as String),
        ),
      )
      ..on(
        settlement.RoomService.getRoomCall,
        (req) => settlement.GetRoomCallResponse(
          call: settlement.RoomCall(
            callId: req.callId,
            state: settlement.RoomCallState.ROOM_CALL_STATE_FINAL,
            onchainProposalId: Int64(7),
          ),
        ),
      )
      ..on(
        finance.RoomService.getPolicy,
        (req) => finance.GetPolicyResponse(policyVersion: vector.inForce),
      )
      ..on(
        finance.GovernanceService.listProposals,
        (req) => finance.ListProposalsResponse(
          // Finance counts every undecided proposal over all pages.
          openCount: Int64(undecided.length),
          proposals: req.states.isNotEmpty
              ? undecided.take(1).toList()
              : [
                  finance.Proposal(
                    onchainProposalId: Int64(7),
                    state: proposalState,
                  ),
                ],
        ),
      );
  });

  List<Override> overrides() => [
    stawiFinanceServiceProvider.overrideWithValue(
      StawiFinanceService(
        rooms: finance.RoomServiceClient(transport),
        treasury: finance.TreasuryServiceClient(transport),
        governance: finance.GovernanceServiceClient(transport),
        identity: () async => identityWith('p1', account),
      ),
    ),
    stawiRoomServiceProvider.overrideWithValue(
      StawiRoomService(
        rooms: settlement.RoomServiceClient(transport),
        keys: DeviceKeyStore(vaultWith('p1', anvilKey), gate: gate),
        identity: () async => identityWith('p1', account),
        send: sender.call,
        ballots: SecretBallotStore(MemoryDeviceKeyVault()),
        contracts: (id) async => id == roomId ? room : null,
      ),
    ),
  ];

  Future<void> open(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1080, 3200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: const MaterialApp(home: RuleChangeScreen(roomId: roomId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester) async {
    await tester.enterText(find.byKey(const Key('rule-quorum_bps')), '60');
    await tester.enterText(
      find.byKey(const Key('rule-minimum_active_members')),
      '2',
    );
    await tester.tap(find.byKey(const Key('rule-next')));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the rules in force and says the loan threshold is '
      'fixed', (tester) async {
    await open(tester);
    for (final r in GroupRule.values) {
      expect(find.byKey(Key('rule-${r.key}')), findsOneWidget, reason: r.key);
    }
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('rule-quorum_bps')))
          .controller!
          .text,
      '50',
    );
    expect(find.byKey(const Key('rule-loan-threshold-note')), findsOneWidget);
    await tester.tap(find.byKey(const Key('rule-next')));
    await tester.pumpAndSettle();
    expect(find.text('Change at least one rule'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('rule-quorum_bps')), '5');
    await tester.tap(find.byKey(const Key('rule-next')));
    await tester.pumpAndSettle();
    expect(find.text('At least 10%'), findsOneWidget);
    expect(
      transport.requestsTo(settlement.RoomService.prepareRoomCall),
      isEmpty,
    );
  });

  testWidgets('a rules change warns about the open votes, is checked '
      'against Go\'s compiled policy and signed once behind the lock', (
    tester,
  ) async {
    await open(tester);
    await choose(tester);
    expect(find.text('Quorum'), findsOneWidget);
    expect(find.text('50% → 60%'), findsOneWidget);
    expect(find.text('3 members → 2 members'), findsOneWidget);
    expect(
      find.textContaining(
        '2 open votes in this group will have to be '
        'proposed again',
      ),
      findsOneWidget,
    );
    expect(
      transport.requestsTo(settlement.RoomService.prepareRoomCall),
      isEmpty,
    );

    await tester.tap(find.byKey(const Key('rule-sign')));
    await tester.pumpAndSettle();
    final req = transport
        .requestsTo(settlement.RoomService.prepareRoomCall)
        .single;
    expect(req.kind, settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE);
    expect(Map<String, String>.of(req.params.propose.ruleChanges.ruleValues), {
      'quorum_bps': '6000',
      'minimum_active_members': '2',
    });
    expect(find.byKey(const Key('money-review')), findsOneWidget);
    expect(sender.sent, isEmpty);
    expect(gate.reasons, isEmpty, reason: 'nothing signed before the review');

    await tester.tap(find.byKey(const Key('money-review-sign')));
    await tester.pumpAndSettle();
    expect(gate.reasons, ["Propose changing the group's rules"]);
    final content = sender.sent.single.content;
    expect(
      recoverDeviceAddress(
        Uint8List.fromList(lastPrepared!.digest),
        base64Decode(content['signature'] as String),
      ),
      await deviceAddressOf(anvilKey),
    );
    // The proposal is followed, not finished by hand.
    expect(find.byKey(const Key('decision-stage-voting')), findsOneWidget);
    expect(find.text('Proposal #7'), findsNothing);
    expect(find.textContaining('Queue a passed proposal'), findsNothing);
  });

  testWidgets('a compiled policy that changes another rule is never signed', (
    tester,
  ) async {
    final p = applyRuleValues(vector.previousConstitution, {
      ...vector.values,
      'max_members': '40',
    });
    final doc = utf8.encode(jsonEncode(p.toProto3Json()));
    compiled = vector.change
      ..documents[0] = doc
      ..constitutionHash = keccak256(doc);
    await open(tester);
    await choose(tester);
    await tester.tap(find.byKey(const Key('rule-sign')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('money-review')), findsNothing);
    expect(find.textContaining(notTheRuleChange), findsOneWidget);
    expect(gate.reasons, isEmpty);
    expect(sender.sent, isEmpty);
  });

  testWidgets('with no other vote open it says so', (tester) async {
    undecided = [];
    await open(tester);
    await choose(tester);
    expect(
      find.textContaining('No other vote is open in this group now'),
      findsOneWidget,
    );
  });

  testWidgets('the decision moves to done once settlement carried it out', (
    tester,
  ) async {
    proposalState = finance.ProposalState.PROPOSAL_STATE_EXECUTED;
    await open(tester);
    await choose(tester);
    await tester.tap(find.byKey(const Key('rule-sign')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('money-review-sign')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('decision-stage-done')), findsOneWidget);
  });
}
