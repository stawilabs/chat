import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/rooms/data/detail_panel_providers.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_custody.dart';
import 'package:stawi/features/stawi/data/stawi_finance_service.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/data/stawi_room_engines.dart';
import 'package:stawi/features/stawi/data/stawi_room_service.dart';
import 'package:stawi/features/stawi/domain/proposal_documents.dart';
import 'package:stawi/features/stawi/domain/rotation.dart';
import 'package:stawi/features/stawi/domain/secret_ballot.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi/features/stawi/domain/stawi_money.dart';
import 'package:stawi/features/stawi/ui/contribute_screen.dart';
import 'package:stawi/features/stawi/ui/guided_governance.dart';
import 'package:stawi/features/stawi/ui/rotation_screen.dart';
import 'package:stawi/features/stawi/ui/stawi_timeline.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

const roomId = 'room00000000000000aa';
const week = 7 * 86400;
const day = 86400;

void main() {
  final wrapped = GoSignedCallVectors.load().accountWrappedHashes.firstWhere(
    (v) => v['name'] == 'anvil_0/seq' && v['chain_id'] == '146',
  );
  final account = hexToBytes(wrapped['account'] as String);
  final v = GoRotationVector.named('three members');
  final [amina, baraka, chena] = v.order;
  final rotationRoom = RoomContracts(
    governance: Uint8List(20)..[0] = 0x41,
    custody: v.custody,
    chainId: BigInt.from(146),
  );
  var room = rotationRoom;
  final usdc = StawiAsset.fromInfo(
    finance.AssetInfo(assetId: 'USDC.146', symbol: 'USDC', decimals: 6),
  );

  late FakeConnectTransport transport;
  late RecordingActSender sender;
  late RecordingSigningGate gate;
  late int epoch;
  late settlement.RoomRotation prepared;
  late List<finance.RotationCycle> cycles;
  late settlement.RoomSetup setup;
  late finance.RoomModuleBinding? module;
  late bool rulesGranted;
  List<int>? grantPayloadHash;
  settlement.PrepareRoomCallResponse? lastPrepared;

  finance.Member member(String id, String profileId, Uint8List a) =>
      finance.Member(
        memberId: id,
        profileId: profileId,
        accountAddress: a,
        state: finance.MemberState.MEMBER_STATE_ACTIVE,
      );

  RoomSubscriptionInfo chat(String profileId, String name) =>
      RoomSubscriptionInfo(
        id: 's-$profileId',
        profileId: profileId,
        contactId: null,
        name: name,
        avatarUrl: null,
        role: 'member',
        joinedAt: 0,
      );

  finance.PolicyVersion policy() => finance.PolicyVersion(
    constitution: finance.RoomPolicy(
      periodModel: finance.PeriodModel(
        periodSeconds: Int64(week),
        epochStart: Int64(epoch),
      ),
      governance: finance.Governance(
        standard: finance.Threshold(
          votingPeriodSeconds: Int64(3 * day),
          timelockSeconds: Int64(day),
        ),
      ),
      savings: finance.Savings(
        minimum: finance.Money(assetId: 'USDC.146', amount: '10000000'),
      ),
    ),
  );

  setUp(() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // Period 3 is the first to begin once the vote can apply.
    epoch = now + 3 * day + day + 3600 - (2.5 * week).round();
    prepared = v.rotation(epochStart: epoch, periodSeconds: week);
    cycles = [];
    setup = settlement.RoomSetup(
      state: settlement.RoomSetupState.ROOM_SETUP_STATE_READY,
      steps: [
        settlement.RoomSetupStep(
          step: settlement
              .RoomSetupStepKind
              .ROOM_SETUP_STEP_KIND_GRANT_RULES_ENGINE,
        ),
        settlement.RoomSetupStep(
          step:
              settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_GRANT_ROTATION,
        ),
      ],
    );
    lastPrepared = null;
    room = rotationRoom;
    module = rotationModuleBinding(grantActive: true);
    rulesGranted = true;
    grantPayloadHash = null;
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
          rotation: prepared,
          grantPayloadHash: grantPayloadHash,
        ),
      )
      ..on(
        settlement.RoomService.getRoomCall,
        (req) => settlement.GetRoomCallResponse(
          call: settlement.RoomCall(
            callId: req.callId,
            state: settlement.RoomCallState.ROOM_CALL_STATE_FINAL,
            onchainProposalId: Int64(9),
          ),
        ),
      )
      ..on(
        finance.RoomService.getPolicy,
        (req) => finance.GetPolicyResponse(policyVersion: policy()),
      )
      ..on(
        finance.GovernanceService.listProposals,
        (req) => finance.ListProposalsResponse(
          proposals: [
            finance.Proposal(
              onchainProposalId: Int64(9),
              state: finance.ProposalState.PROPOSAL_STATE_OPEN,
            ),
          ],
        ),
      )
      ..on(
        finance.SavingsService.listRotations,
        (req) => finance.ListRotationsResponse(rotations: cycles),
      )
      ..on(
        finance.SavingsService.getRotation,
        (req) => finance.GetRotationResponse(
          rotation: cycles.first,
          assets: [
            finance.AssetInfo(assetId: 'USDC.146', symbol: 'USDC', decimals: 6),
          ],
        ),
      );
  });

  List<Override> overrides() => [
    stawiIdentityProvider.overrideWith(
      (ref) async => identityWith('p1', account),
    ),
    roomMembersProvider.overrideWith(
      (ref, id) async => [
        chat('p1', 'Me'),
        chat('p2', 'Amina'),
        chat('p3', 'Baraka'),
        chat('p4', 'Chena'),
      ],
    ),
    stawiMembersProvider.overrideWith(
      (ref, id) async => [
        member('m1', 'p1', account),
        member('m2', 'p2', amina),
        member('m3', 'p3', baraka),
        member('m4', 'p4', chena),
      ],
    ),
    stawiRoomAssetProvider.overrideWith((ref, id) async => usdc),
    stawiRoomSetupProvider.overrideWith((ref, id) async => setup),
    rotationEnginesSourceProvider.overrideWithValue(
      (id) async => (module: module, rulesGranted: rulesGranted),
    ),
    roomCustodyProvider.overrideWith((ref, id) async => room.custody),
    stawiFinanceServiceProvider.overrideWithValue(
      StawiFinanceService(
        rooms: finance.RoomServiceClient(transport),
        treasury: finance.TreasuryServiceClient(transport),
        governance: finance.GovernanceServiceClient(transport),
        savings: finance.SavingsServiceClient(transport),
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

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view
      ..physicalSize = const Size(1080, 3600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  String turnOf(WidgetTester tester, String memberId) =>
      tester.widget<Text>(find.byKey(Key('rotation-turn-of-$memberId'))).data!;

  group('Start a rotation', () {
    Future<void> chooseGoOrder(WidgetTester tester) async {
      // Everyone is in by default; leaving me out gives Go's order.
      expect(turnOf(tester, 'm1'), 'Turn 1');
      await tester.tap(find.byKey(const Key('rotation-include-m1')));
      await tester.pumpAndSettle();
      expect(turnOf(tester, 'm1'), 'Not in the rotation');
      expect(turnOf(tester, 'm2'), 'Turn 1');
      expect(turnOf(tester, 'm4'), 'Turn 3');
      // Prefilled with the constitution's contribution.
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('rotation-amount')))
            .controller!
            .text,
        '10',
      );
      await tester.tap(find.byKey(const Key('rotation-next')));
      await tester.pumpAndSettle();
    }

    testWidgets('the order, amount and start chosen are checked against '
        'Go\'s cycle and signed once behind the lock', (tester) async {
      await pump(tester, const StartRotationScreen(roomId: roomId));
      await chooseGoOrder(tester);
      expect(
        find.textContaining('each of the 3 members pays 10.00 USDC'),
        findsOneWidget,
      );
      expect(find.textContaining('receives 30.00 USDC'), findsOneWidget);
      expect(
        transport.requestsTo(settlement.RoomService.prepareRoomCall),
        isEmpty,
      );

      await tester.tap(find.byKey(const Key('rotation-sign')));
      await tester.pumpAndSettle();
      final req = transport
          .requestsTo(settlement.RoomService.prepareRoomCall)
          .single;
      expect(req.kind, settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE);
      final terms = req.params.propose.rotation;
      expect([for (final m in terms.members) m.account], v.order);
      expect(terms.contribution, '10000000');
      expect(terms.hasStartsAt(), isFalse);

      // The checked review, before anything is signed.
      expect(find.byKey(const Key('money-review')), findsOneWidget);
      expect(find.text('Amina'), findsWidgets);
      expect(find.text('30.00 USDC'), findsOneWidget);
      expect(find.text('First payout from'), findsOneWidget);
      expect(gate.reasons, isEmpty);
      expect(sender.sent, isEmpty);

      await tester.tap(find.byKey(const Key('money-review-sign')));
      await tester.pumpAndSettle();
      expect(gate.reasons, ['Propose a rotation of 3 members']);
      final params = lastPrepared!.call.params;
      expect(params.sublist(0, 32), bigIntToBytes(BigInt.from(17), 32));
      expect(
        params.sublist(32),
        v.payloadHash,
        reason: 'the DISTRIBUTION proposal of Go\'s openCyclePayloadHash',
      );
      expect(
        recoverDeviceAddress(
          Uint8List.fromList(lastPrepared!.digest),
          base64Decode(sender.sent.single.content['signature'] as String),
        ),
        await deviceAddressOf(anvilKey),
      );
      expect(find.byKey(const Key('decision-stage-voting')), findsOneWidget);
    });

    testWidgets('a cycle in another order is never reviewed or signed', (
      tester,
    ) async {
      prepared = prepared.deepCopy()
        ..order.clear()
        ..order.addAll([baraka, amina, chena]);
      await pump(tester, const StartRotationScreen(roomId: roomId));
      await chooseGoOrder(tester);
      await tester.tap(find.byKey(const Key('rotation-sign')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('money-review')), findsNothing);
      expect(find.textContaining('turn order is not the one'), findsOneWidget);
      expect(gate.reasons, isEmpty);
      expect(sender.sent, isEmpty);
    });

    testWidgets('a cycle starting later than the vote allows is refused', (
      tester,
    ) async {
      prepared = prepared.deepCopy()..firstPeriod = 5;
      await pump(tester, const StartRotationScreen(roomId: roomId));
      await chooseGoOrder(tester);
      await tester.tap(find.byKey(const Key('rotation-sign')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('money-review')), findsNothing);
      expect(gate.reasons, isEmpty);
    });

    testWidgets('drag to reorder, and a shuffle shows its result', (
      tester,
    ) async {
      await pump(
        tester,
        StartRotationScreen(roomId: roomId, random: Random(3)),
      );
      final row = tester.getSize(find.byKey(const Key('rotation-pick-m4')));
      final drag = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('rotation-drag-m4'))),
      );
      for (var i = 0; i < 20; i++) {
        await drag.moveBy(Offset(0, -row.height * 4 / 20));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await drag.up();
      await tester.pumpAndSettle();
      expect(turnOf(tester, 'm4'), 'Turn 1');
      expect(turnOf(tester, 'm1'), 'Turn 2');

      await tester.tap(find.byKey(const Key('rotation-shuffle')));
      await tester.pumpAndSettle();
      final shown = tester
          .widget<Text>(find.byKey(const Key('rotation-shuffled')))
          .data!;
      final turns = {
        for (final id in ['m1', 'm2', 'm3', 'm4']) turnOf(tester, id),
      };
      expect(turns, {'Turn 1', 'Turn 2', 'Turn 3', 'Turn 4'});
      // The note lists the members in the order shown.
      final names = {'m1': 'Me', 'm2': 'Amina', 'm3': 'Baraka', 'm4': 'Chena'};
      final inOrder = [
        for (var t = 1; t <= 4; t++)
          names.entries
              .firstWhere((e) => turnOf(tester, e.key) == 'Turn $t')
              .value,
      ];
      expect(shown, contains(inOrder.join(', ')));
    });

    testWidgets('an amount other than the group\'s dues is warned about', (
      tester,
    ) async {
      await pump(tester, const StartRotationScreen(roomId: roomId));
      await tester.enterText(find.byKey(const Key('rotation-amount')), '12');
      await tester.tap(find.byKey(const Key('rotation-next')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('rotation-dues-differ')), findsOneWidget);
      expect(find.textContaining('receives 48.00 USDC'), findsOneWidget);
    });

    testWidgets('fewer than two members cannot go on', (tester) async {
      await pump(tester, const StartRotationScreen(roomId: roomId));
      for (final id in ['m1', 'm2', 'm3']) {
        await tester.tap(find.byKey(Key('rotation-include-$id')));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rotation-next')));
      await tester.pumpAndSettle();
      expect(find.text('Choose at least two members'), findsOneWidget);
    });

    testWidgets('Group decisions offers it in a merry-go-round room only', (
      tester,
    ) async {
      Future<void> openSheet() async {
        await pump(
          tester,
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showGroupDecisionsSheet(context, roomId: roomId),
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
      }

      await openSheet();
      expect(find.byKey(const Key('decision-rotation')), findsOneWidget);
      await tester.tap(find.byKey(const Key('decision-rotation')));
      await tester.pumpAndSettle();
      expect(find.byType(StartRotationScreen), findsOneWidget);

      // A room that has not granted the RotationModule is offered the vote
      // that adds a rotation instead.
      setup = settlement.RoomSetup(
        state: settlement.RoomSetupState.ROOM_SETUP_STATE_READY,
      );
      module = rotationModuleBinding();
      await tester.pumpWidget(const SizedBox());
      await openSheet();
      expect(find.byKey(const Key('decision-rotation')), findsNothing);
      expect(find.byKey(const Key('decision-add-rotation')), findsOneWidget);

      // A deployment with no RotationModule offers neither.
      module = null;
      await tester.pumpWidget(const SizedBox());
      await openSheet();
      expect(find.byKey(const Key('decision-rotation')), findsNothing);
      expect(find.byKey(const Key('decision-add-rotation')), findsNothing);
    });

    testWidgets('a room that granted the rotation later by vote can start '
        'one, whatever its setup', (tester) async {
      setup = settlement.RoomSetup(
        state: settlement.RoomSetupState.ROOM_SETUP_STATE_NONE,
      );
      await pump(
        tester,
        const RotationScreen(roomId: roomId, roomName: 'Chama'),
      );
      expect(find.byKey(const Key('rotation-start')), findsOneWidget);
    });

    testWidgets('a contribution other than the group\'s dues is refused '
        'before review, and the dues are set in its place', (tester) async {
      prepared = prepared.deepCopy()..memberDues = '12000000';
      await pump(tester, const StartRotationScreen(roomId: roomId));
      await chooseGoOrder(tester);
      await tester.tap(find.byKey(const Key('rotation-sign')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('money-review')), findsNothing);
      expect(gate.reasons, isEmpty);
      expect(sender.sent, isEmpty);
      // Back to the choice, holding exactly the group's dues.
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('rotation-amount')))
            .controller!
            .text,
        '12',
      );
      expect(
        find.text(
          'Each member pays exactly the group\'s dues: 12.00 USDC a period',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a room whose dues are not one fixed amount cannot start '
        'one', (tester) async {
      prepared = prepared.deepCopy()..memberDues = '';
      await pump(tester, const StartRotationScreen(roomId: roomId));
      await chooseGoOrder(tester);
      await tester.tap(find.byKey(const Key('rotation-sign')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('money-review')), findsNothing);
      expect(find.textContaining('not one fixed amount'), findsOneWidget);
      expect(gate.reasons, isEmpty);
    });
  });

  group('Add a rotation to this group', () {
    // stawi's Go grant vector: GrantPayload(custody, module, 1, no limits,
    // no expiry) and its hash.
    final goDocs = jsonDecode(
      File('test/fixtures/stawi/go_proposal_documents.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final goGrant = goDocs['grant'] as Map<String, dynamic>;
    final goCustody = hexToBytes(goDocs['custody'] as String);
    final goPayload = hexToBytes(goGrant['payload_hash'] as String);

    setUp(() {
      setup = settlement.RoomSetup(
        state: settlement.RoomSetupState.ROOM_SETUP_STATE_NONE,
      );
      module = rotationModuleBinding();
      room = RoomContracts(
        governance: Uint8List(20)..[0] = 0x41,
        custody: goCustody,
        chainId: BigInt.from(146),
      );
      grantPayloadHash = goPayload;
    });

    testWidgets('the grant of the protocol\'s RotationModule is rebuilt on '
        'the device, reviewed, then signed once behind the lock', (
      tester,
    ) async {
      await pump(
        tester,
        const RotationScreen(roomId: roomId, roomName: 'Chama'),
      );
      expect(find.byKey(const Key('rotation-start')), findsNothing);
      await tester.tap(find.byKey(const Key('rotation-add')));
      await tester.pumpAndSettle();
      expect(find.byType(AddRotationScreen), findsOneWidget);
      expect(find.byKey(const Key('rotation-add-terms')), findsOneWidget);
      expect(find.textContaining('0xa0a1'), findsOneWidget);
      expect(
        transport.requestsTo(settlement.RoomService.prepareRoomCall),
        isEmpty,
      );

      await tester.tap(find.byKey(const Key('rotation-add-sign')));
      await tester.pumpAndSettle();
      final req = transport
          .requestsTo(settlement.RoomService.prepareRoomCall)
          .single;
      expect(req.kind, settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE);
      expect(
        req.params.propose.engineGrant.engine,
        settlement.RoomEngine.ROOM_ENGINE_ROTATION,
      );
      expect(find.byKey(const Key('money-review')), findsOneWidget);
      expect(find.text('Rotation payouts'), findsOneWidget);
      expect(gate.reasons, isEmpty);

      await tester.tap(find.byKey(const Key('money-review-sign')));
      await tester.pumpAndSettle();
      expect(gate.reasons, ['Add a rotation to this group']);
      final params = lastPrepared!.call.params;
      expect(params.sublist(0, 32), bigIntToBytes(BigInt.from(11), 32));
      expect(
        params.sublist(32),
        goPayload,
        reason: 'the CAPABILITY_GRANT of Go\'s GrantPayloadHash',
      );
      expect(
        recoverDeviceAddress(
          Uint8List.fromList(lastPrepared!.digest),
          base64Decode(sender.sent.single.content['signature'] as String),
        ),
        await deviceAddressOf(anvilKey),
      );
      expect(find.byKey(const Key('decision-stage-voting')), findsOneWidget);
    });

    testWidgets('a grant of another module is never reviewed or signed', (
      tester,
    ) async {
      grantPayloadHash = payloadHashOf(
        engineGrantDocument(
          custody: goCustody,
          module: Uint8List(20)..[0] = 0xee,
        ),
      );
      await pump(tester, const AddRotationScreen(roomId: roomId));
      await tester.tap(find.byKey(const Key('rotation-add-sign')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('money-review')), findsNothing);
      expect(
        find.textContaining('another grant than the rotation module'),
        findsOneWidget,
      );
      expect(gate.reasons, isEmpty);
      expect(sender.sent, isEmpty);
    });

    testWidgets('a module the protocol has not registered is not offered', (
      tester,
    ) async {
      module = rotationModuleBinding(registered: false);
      await pump(
        tester,
        const RotationScreen(roomId: roomId, roomName: 'Chama'),
      );
      expect(find.byKey(const Key('rotation-add')), findsNothing);
      expect(find.byKey(const Key('rotation-unavailable')), findsOneWidget);

      await pump(tester, const AddRotationScreen(roomId: roomId));
      expect(
        find.textContaining('not registered with the protocol'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('rotation-add-sign')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('a room without its dues rules is told rules come first', (
      tester,
    ) async {
      rulesGranted = false;
      await pump(
        tester,
        const RotationScreen(roomId: roomId, roomName: 'Chama'),
      );
      expect(find.byKey(const Key('rotation-needs-rules')), findsOneWidget);
      expect(find.byKey(const Key('rotation-add')), findsNothing);
    });
  });

  group('the rotation screen', () {
    finance.RotationCycle running() => finance.RotationCycle(
      roomId: roomId,
      cycleId: v.cycleId,
      pot: finance.Money(assetId: 'USDC.146', amount: '30000000'),
      firstPeriod: 3,
      state: finance.RotationCycleState.ROTATION_CYCLE_STATE_RUNNING,
      currentTurn: 1,
      shortfall: '10000000',
      turns: [
        finance.RotationTurn(
          turn: 0,
          account: amina,
          state: finance.RotationTurnState.ROTATION_TURN_STATE_PAID,
          paid: finance.Money(assetId: 'USDC.146', amount: '30000000'),
          paidAt: Timestamp.fromDateTime(DateTime.utc(2026, 10, 5)),
        ),
        finance.RotationTurn(
          turn: 1,
          account: account,
          state: finance.RotationTurnState.ROTATION_TURN_STATE_WAITING,
          payableFrom: Timestamp.fromDateTime(DateTime.utc(2026, 10, 12)),
        ),
        finance.RotationTurn(
          turn: 2,
          account: chena,
          state: finance.RotationTurnState.ROTATION_TURN_STATE_UPCOMING,
        ),
      ],
      members: [
        finance.RotationMember(
          account: amina,
          dues: finance.MemberDues(
            standing: finance.MemberDuesStanding.MEMBER_DUES_STANDING_CURRENT,
          ),
        ),
        finance.RotationMember(
          account: account,
          turn: 1,
          dues: finance.MemberDues(
            standing: finance.MemberDuesStanding.MEMBER_DUES_STANDING_CURRENT,
          ),
        ),
        finance.RotationMember(
          account: chena,
          turn: 2,
          late: true,
          lateBy: finance.Money(assetId: 'USDC.146', amount: '10000000'),
          dues: finance.MemberDues(
            standing:
                finance.MemberDuesStanding.MEMBER_DUES_STANDING_IN_ARREARS,
          ),
        ),
      ],
    );

    testWidgets('shows whose turn it is now and next, who paid, who is late '
        'and the payouts made', (tester) async {
      cycles = [running()];
      await pump(
        tester,
        const RotationScreen(roomId: roomId, roomName: 'Chama'),
      );
      expect(find.text('Turn 2 of 3'), findsOneWidget);
      expect(find.text('Now: your turn'), findsOneWidget);
      expect(find.text('Next: Chena'), findsOneWidget);
      expect(find.text('The pot is short by 10.00 USDC'), findsOneWidget);
      expect(find.text('Late by 10.00 USDC'), findsOneWidget);
      expect(find.text('Paid for this period'), findsNWidgets(2));
      expect(find.textContaining('Paid · 30.00 USDC'), findsOneWidget);
      expect(
        find.text(
          '1 of 3 payouts made. Stawi pays each turn by itself '
          'once its period has begun and the pot is whole.',
        ),
        findsOneWidget,
      );
      expect(
        transport
            .requestsTo(finance.SavingsService.getRotation)
            .single
            .includeDues,
        isTrue,
      );
    });

    testWidgets('my contribution is exactly pay_now: prefilled, and any '
        'other amount is blocked', (tester) async {
      final cycle = running();
      cycle.members[1].payNow = finance.Money(
        assetId: 'USDC.146',
        amount: '10500000',
      );
      cycles = [cycle];
      await pump(
        tester,
        const RotationScreen(roomId: roomId, roomName: 'Chama'),
      );
      expect(find.text('You pay 10.50 USDC now'), findsOneWidget);
      await tester.tap(find.byKey(const Key('rotation-pay')));
      await tester.pumpAndSettle();
      expect(find.byType(ContributeScreen), findsOneWidget);
      expect(find.byKey(const Key('contribute-exact')), findsOneWidget);
      TextField amount() =>
          tester.widget<TextField>(find.byKey(const Key('contribute-amount')));
      FilledButton submit() => tester.widget<FilledButton>(
        find.byKey(const Key('contribute-submit')),
      );
      expect(amount().controller!.text, '10.5');
      expect(submit().onPressed, isNotNull);

      await tester.enterText(find.byKey(const Key('contribute-amount')), '10');
      await tester.pumpAndSettle();
      expect(find.textContaining('Pay exactly 10.50 USDC'), findsOneWidget);
      expect(submit().onPressed, isNull, reason: 'blocked, not just warned');

      await tester.enterText(
        find.byKey(const Key('contribute-amount')),
        '10.50',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('contribute-exact-problem')), findsNothing);
      expect(submit().onPressed, isNotNull);
    });

    testWidgets('paid up for the period: nothing to pay', (tester) async {
      final cycle = running();
      cycle.members[1].payNow = finance.Money(assetId: 'USDC.146', amount: '0');
      cycles = [cycle];
      await pump(
        tester,
        const RotationScreen(roomId: roomId, roomName: 'Chama'),
      );
      expect(find.text('You are paid up for this period'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('rotation-pay')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('a rotation contribution whose exact amount cannot be read '
        'is not paid', (tester) async {
      cycles = [running()];
      await pump(
        tester,
        const ContributeScreen(
          roomId: roomId,
          roomName: 'Chama',
          rotation: true,
        ),
      );
      await tester.enterText(find.byKey(const Key('contribute-amount')), '10');
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'exact contribution to the rotation could not be read',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('contribute-submit')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('a merry-go-round room without a rotation offers to start '
        'one', (tester) async {
      await pump(
        tester,
        const RotationScreen(roomId: roomId, roomName: 'Chama'),
      );
      expect(find.byKey(const Key('rotation-none')), findsOneWidget);
      await tester.tap(find.byKey(const Key('rotation-start')));
      await tester.pumpAndSettle();
      expect(find.byType(StartRotationScreen), findsOneWidget);
    });

    testWidgets('the room page card says the turn, now and next', (
      tester,
    ) async {
      cycles = [running()];
      await pump(
        tester,
        const Scaffold(
          body: RotationCard(roomId: roomId, roomName: 'Chama'),
        ),
      );
      expect(find.text('Rotation: turn 2 of 3'), findsOneWidget);
      expect(find.text('Now: You · Next: Chena'), findsOneWidget);
    });
  });

  group('rotation chat cards', () {
    RoomEvent card(String kind, String title, Map<String, String> data) =>
        RoomEvent(
          id: 'card-$kind',
          roomId: roomId,
          senderId: '',
          type: RoomEventType.financeCard,
          createdAt: 0,
          content: {
            'cardId': 'k-$kind',
            'kind': kind,
            'title': title,
            'body': 'body of $kind',
            'data': {...data, 'action': 'open_rotation'},
          },
        );

    String hex(List<int> a) => bytesToHex0x(a).toLowerCase();

    Future<void> show(WidgetTester tester, RoomEvent event) => pump(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: StawiTimelineItem(event: event, isMe: false),
        ),
      ),
    );

    final cases = <(String, String, Map<String, String>, IconData, String)>[
      (
        RotationCards.started,
        'Rotation started',
        {'order': '${hex(amina)},${hex(baraka)}', 'pot': '30000000'},
        Icons.autorenew,
        'Amina, Baraka',
      ),
      (
        RotationCards.turn,
        'Rotation: turn 1 of 3',
        {'recipient': hex(amina), 'pot': '30000000'},
        Icons.redeem_outlined,
        'Amina',
      ),
      (
        RotationCards.late,
        'Rotation waiting on contributions',
        {'recipient': hex(amina), 'late': '${hex(baraka)},${hex(chena)}'},
        Icons.hourglass_bottom,
        'Baraka, Chena',
      ),
      (
        RotationCards.skipped,
        'Rotation: turn 2 of 3 passed over',
        {'recipient': hex(baraka)},
        Icons.skip_next_outlined,
        'Baraka',
      ),
      (
        RotationCards.payout,
        'Rotation payout: 30.00 USDC',
        {'recipient': hex(chena), 'amount': '30000000'},
        Icons.payments_outlined,
        'Chena',
      ),
    ];

    for (final (kind, title, data, icon, named) in cases) {
      testWidgets('$kind names the members and opens the rotation', (
        tester,
      ) async {
        cycles = [];
        await show(tester, card(kind, title, data));
        expect(find.text(title), findsOneWidget);
        expect(
          tester.widget<Icon>(find.byKey(const Key('finance-card-icon'))).icon,
          icon,
        );
        expect(find.text(named), findsOneWidget);
        expect(find.textContaining('0x'), findsNothing);
        await tester.tap(find.byKey(const Key('rotation-card-open')));
        await tester.pumpAndSettle();
        expect(find.byType(RotationScreen), findsOneWidget);
      });
    }

    testWidgets('my turn and my lateness are said to me', (tester) async {
      await show(
        tester,
        card(RotationCards.turn, 'Rotation: turn 2 of 3', {
          'recipient': hex(account),
        }),
      );
      expect(find.byKey(const Key('rotation-card-yours')), findsOneWidget);
      await show(
        tester,
        card(RotationCards.late, 'Rotation waiting on contributions', {
          'recipient': hex(amina),
          'late': hex(account),
        }),
      );
      expect(find.byKey(const Key('rotation-card-me-late')), findsOneWidget);
      expect(find.byKey(const Key('rotation-card-pay')), findsOneWidget);
    });
  });
}
