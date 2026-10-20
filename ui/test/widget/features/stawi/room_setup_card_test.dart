import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart'
    show stawiClockProvider;
import 'package:stawi/features/stawi/data/stawi_room_service.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi/features/stawi/ui/room_setup_card.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

const roomId = 'room00000000000000aa';

void main() {
  final vectors = GoSignedCallVectors.load();
  final wrapped = vectors.accountWrappedHashes.firstWhere(
    (v) => v['name'] == 'anvil_0/seq' && v['chain_id'] == '146',
  );
  final account = hexToBytes(wrapped['account'] as String);
  final room = RoomContracts(
    governance: Uint8List(20)..[0] = 0x40,
    custody: Uint8List(20)..[0] = 0x30,
    chainId: BigInt.from(146),
  );
  final now = DateTime.utc(2026, 10, 20, 9);

  late FakeConnectTransport transport;
  late RecordingActSender sender;
  late RecordingSigningGate gate;

  setUp(() {
    transport = FakeConnectTransport();
    sender = RecordingActSender();
    gate = RecordingSigningGate();
  });

  settlement.RoomSetupStep step(
    settlement.RoomSetupStepKind kind,
    settlement.RoomSetupStepState state, {
    int proposal = 0,
    DateTime? closes,
  }) => settlement.RoomSetupStep(
    step: kind,
    state: state,
    onchainProposalId: Int64(proposal),
    votingClosesAt: closes == null ? null : Timestamp.fromDateTime(closes),
  );

  Future<void> pump(WidgetTester tester, settlement.RoomSetup setup) async {
    transport.on(
      settlement.RoomService.getRoomSetup,
      (_) => settlement.GetRoomSetupResponse(setup: setup),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stawiClockProvider.overrideWithValue(() => now),
          stawiRoomServiceProvider.overrideWithValue(
            StawiRoomService(
              rooms: settlement.RoomServiceClient(transport),
              keys: DeviceKeyStore(vaultWith('p1', anvilKey), gate: gate),
              identity: () async => identityWith('p1', account),
              send: sender.call,
              contracts: (id) async => id == roomId ? room : null,
              now: () => now,
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RoomSetupCard(roomId: roomId, roomName: 'Chama'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the vote open now and votes yes in one tap', (
    tester,
  ) async {
    transport.on(
      settlement.RoomService.prepareRoomCall,
      (req) => honestRoomCall(
        req,
        room: room,
        signer: account,
        chatRoomId: roomId,
        now: now,
      ),
    );
    await pump(
      tester,
      settlement.RoomSetup(
        state: settlement.RoomSetupState.ROOM_SETUP_STATE_VOTING,
        steps: [
          step(
            settlement
                .RoomSetupStepKind
                .ROOM_SETUP_STEP_KIND_GRANT_RULES_ENGINE,
            settlement.RoomSetupStepState.ROOM_SETUP_STEP_STATE_VOTING,
            proposal: 11,
            closes: now.add(const Duration(days: 2, hours: 1)),
          ),
          step(
            settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_GRANT_LOAN_ENGINE,
            settlement.RoomSetupStepState.ROOM_SETUP_STEP_STATE_WAITING,
          ),
          step(
            settlement.RoomSetupStepKind.ROOM_SETUP_STEP_KIND_RULES_TEMPLATE,
            settlement.RoomSetupStepState.ROOM_SETUP_STEP_STATE_WAITING,
          ),
        ],
      ),
    );
    expect(
      find.text('Setting up lending: vote 1 of 3, closes in 2 days'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('room-setup-sign')), findsNothing);
    await tester.tap(find.byKey(const Key('room-setup-vote-1')));
    await tester.pumpAndSettle();
    expect(find.text('Vote yes: Turn on the rules engine'), findsWidgets);
    await tester.tap(find.byKey(const Key('money-review-sign')));
    await tester.pumpAndSettle();

    final req = transport
        .requestsTo(settlement.RoomService.prepareRoomCall)
        .single;
    expect(req.kind, settlement.RoomCallKind.ROOM_CALL_KIND_CAST_VOTE);
    expect(req.params.vote.onchainProposalId, Int64(11));
    expect(gate.reasons, ['Vote yes: Turn on the rules engine']);
    final act = sender.sent.single;
    expect(act.type, RoomEventType.stawiSignedCall);
    expect(act.content['kind'], 'CAST_VOTE');
  });

  testWidgets('asks a founder to sign the setup when settlement holds none', (
    tester,
  ) async {
    transport.on(
      settlement.RoomService.submitRoomSetupSignatures,
      (req) => settlement.SubmitRoomSetupSignaturesResponse(),
    );
    await pump(
      tester,
      settlement.RoomSetup(
        governance: room.governance,
        custody: room.custody,
        state: settlement.RoomSetupState.ROOM_SETUP_STATE_AWAITING_SIGNATURE,
        needsSignatures: setupDigestsFor(
          account: account,
          governance: room.governance!,
          custody: room.custody!,
          chainId: room.chainId,
          deadline: now.add(const Duration(days: 7)),
          firstNonce: 2,
        ),
      ),
    );
    expect(
      find.text('Setting up lending: a founder needs to sign the setup'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('room-setup-sign')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('money-review')), findsOneWidget);
    await tester.tap(find.byKey(const Key('money-review-sign')));
    await tester.pumpAndSettle();
    final sent = transport
        .requestsTo(settlement.RoomService.submitRoomSetupSignatures)
        .single;
    expect(sent.chatRoomId, roomId);
    expect(sent.signatures, hasLength(3));
    expect(gate.reasons, ['Propose the room\'s lending setup']);
    expect(base64Encode(sent.signatures.first.signature), isNotEmpty);
  });

  testWidgets('a room without a setup shows nothing', (tester) async {
    await pump(
      tester,
      settlement.RoomSetup(
        state: settlement.RoomSetupState.ROOM_SETUP_STATE_NONE,
      ),
    );
    expect(find.byKey(const Key('room-setup')), findsNothing);
  });

  testWidgets('a ready room says it lends', (tester) async {
    await pump(
      tester,
      settlement.RoomSetup(
        state: settlement.RoomSetupState.ROOM_SETUP_STATE_READY,
      ),
    );
    expect(
      find.text('Lending is set up: the room takes dues and lends'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('room-setup-vote-1')), findsNothing);
  });
}
