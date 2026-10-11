import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/auth/data/current_user_provider.dart';
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/rooms/data/room_subscription_service.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_room_service.dart';
import 'package:stawi/features/stawi/data/stawi_timeline_providers.dart';
import 'package:stawi/features/stawi/ui/stawi_timeline.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

const roomId = 'room00000000000000aa';

RoomEvent outcomeEvent(
  String state, {
  String kind = 'INVITE',
  String reason = '',
}) => RoomEvent(
  id: 'out-$state',
  roomId: roomId,
  senderId: '',
  type: RoomEventType.stawiCallOutcome,
  createdAt: 1,
  status: EventStatus.delivered,
  content: {'state': state, 'kind': kind, 'reason': reason},
);

Widget host(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  final vectors = GoSignedCallVectors.load();
  final wrapped = vectors.accountWrappedHashes.firstWhere(
    (v) => v['name'] == 'anvil_0/seq' && v['chain_id'] == '146',
  );
  final account = hexToBytes(wrapped['account'] as String);
  final genesisHash = hexToBytes(wrapped['hash'] as String);
  final digest = hexToBytes(wrapped['wrapped'] as String);

  group('StawiActBubble', () {
    const act = RoomEvent(
      id: 'act1',
      roomId: roomId,
      senderId: 'sub-me',
      type: RoomEventType.stawiSignedCall,
      createdAt: 0,
      status: EventStatus.sent,
      content: {'callId': 'c1', 'kind': 'INVITE', 'summary': 'Invite Amina'},
    );

    Future<void> pumpWith(WidgetTester tester, List<RoomEvent> outcomes) =>
        tester.pumpWidget(
          host(
            const StawiTimelineItem(event: act, isMe: true),
            overrides: [
              stawiOutcomesProvider.overrideWith(
                (ref, id) => Stream.value(outcomes),
              ),
            ],
          ),
        );

    testWidgets('shows the act pending until its outcome arrives', (
      tester,
    ) async {
      await pumpWith(tester, const []);
      await tester.pump();
      expect(find.text('Invite Amina'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('shows the chain outcome', (tester) async {
      await pumpWith(tester, [
        outcomeEvent('STAWI_CALL_OUTCOME_STATE_ACCEPTED'),
        outcomeEvent('STAWI_CALL_OUTCOME_STATE_OBSERVED'),
      ]);
      await tester.pump();
      expect(find.text('Confirmed on chain'), findsOneWidget);
    });

    testWidgets('shows why it was refused', (tester) async {
      await pumpWith(tester, [
        outcomeEvent('STAWI_CALL_OUTCOME_STATE_FAILED', reason: 'NotOfficer'),
      ]);
      await tester.pump();
      expect(find.text('Refused: NotOfficer'), findsOneWidget);
    });
  });

  testWidgets('renders a call outcome as a system line', (tester) async {
    await tester.pumpWidget(
      host(
        StawiTimelineItem(
          event: outcomeEvent(
            'STAWI_CALL_OUTCOME_STATE_OBSERVED',
            kind: 'ROOM_ACTIVATED',
          ),
          isMe: false,
        ),
      ),
    );
    expect(find.text('This room is now a Stawi room on chain'), findsOneWidget);
  });

  testWidgets('renders a finance card with its vote action', (tester) async {
    await tester.pumpWidget(
      host(
        const StawiTimelineItem(
          event: RoomEvent(
            id: 'card1',
            roomId: roomId,
            senderId: '',
            type: RoomEventType.financeCard,
            createdAt: 0,
            content: {
              'cardId': 'k1',
              'kind': 'PROPOSAL',
              'title': 'New proposal: buy a tent',
              'body': 'Voting happens in Stawi.',
              'data': {
                'proposal_id': 'prop0000000000000001',
                'action': 'open_signing_flow',
                'payload_hash': '0x01',
              },
            },
          ),
          isMe: false,
        ),
      ),
    );
    expect(find.text('New proposal: buy a tent'), findsOneWidget);
    expect(find.text('Voting happens in Stawi.'), findsOneWidget);
    expect(find.text('prop0000000000000001'), findsOneWidget);
    expect(find.text('0x01'), findsNothing);
    expect(find.byKey(const Key('finance-card-vote')), findsOneWidget);
  });

  group('GenesisCard', () {
    RoomEvent card() => RoomEvent(
      id: 'conv1',
      roomId: roomId,
      senderId: 'sub-owner',
      type: RoomEventType.stawiRoomConversion,
      createdAt: 0,
      status: EventStatus.delivered,
      content: {
        'templateId': 'ug_savings_basic',
        'ruleValues': {'period': 'WEEKLY'},
        'founderSubscriptionIds': ['sub-owner', 'sub-me'],
        'joinPolicy': 'STAWI_JOIN_POLICY_PRIVATE',
        'genesis': {
          'genesisId': 'gen00000000000000001',
          'genesisHash': base64Encode(genesisHash),
          'constitutionHash': base64Encode(Uint8List(32)),
          'founderProfileIds': ['p-owner', 'p1'],
          'expiresAt': DateTime.now()
              .toUtc()
              .add(const Duration(days: 1))
              .toIso8601String(),
        },
      },
    );

    late FakeConnectTransport transport;
    late RecordingActSender sender;
    late DeviceKeyStore keys;

    setUp(() {
      transport = FakeConnectTransport()
        ..on(
          settlement.RoomService.getRoomGenesis,
          (req) => settlement.GetRoomGenesisResponse(
            genesis: settlement.RoomGenesis(
              genesisId: req.genesisId,
              state: settlement.RoomGenesisState.ROOM_GENESIS_STATE_PENDING,
              chainId: Int64(146),
              genesisHash: genesisHash,
              founders: [
                settlement.RoomFounder(
                  profileId: 'p1',
                  account: account,
                  signingDigest: digest,
                ),
              ],
            ),
          ),
        );
      sender = RecordingActSender();
      keys = DeviceKeyStore(vaultWith('p1', anvilKey));
    });

    List<Override> overrides({
      required String profileId,
      List<RoomEvent> outcomes = const [],
      List<RoomEvent> signatures = const [],
    }) => [
      stawiOutcomesProvider.overrideWith((ref, id) => Stream.value(outcomes)),
      stawiGenesisSignaturesProvider.overrideWith(
        (ref, id) => Stream.value(signatures),
      ),
      currentProfileIdProvider.overrideWith((ref) async => profileId),
      currentUserSubscriptionIdProvider.overrideWith(
        (ref, roomId) async => 'sub-me',
      ),
      stawiRoomServiceProvider.overrideWithValue(
        StawiRoomService(
          rooms: settlement.RoomServiceClient(transport),
          keys: keys,
          identity: () async => identityWith(profileId, account),
          send: sender.call,
        ),
      ),
    ];

    testWidgets('a founder signs the genesis from the card', (tester) async {
      await tester.pumpWidget(
        host(
          StawiTimelineItem(event: card(), isMe: false),
          overrides: overrides(profileId: 'p1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Stawi room genesis'), findsOneWidget);
      expect(find.text('ug_savings_basic'), findsOneWidget);
      expect(
        find.textContaining('Awaiting founder signatures'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('genesis-sign')));
      await tester.pumpAndSettle();

      final act = sender.sent.single;
      expect(act.type, RoomEventType.stawiGenesisSignature);
      expect(act.parentId, 'conv1');
      final signature = base64Decode(act.content['signature'] as String);
      expect(
        bytesToHex0x(recoverDeviceAddress(digest, signature)),
        (await keys.load('p1'))!.keyId,
      );
      expect(find.text('Genesis signed'), findsOneWidget);
    });

    testWidgets('a member who is not a founder sees no sign button', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          StawiTimelineItem(event: card(), isMe: false),
          overrides: overrides(profileId: 'p-other'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('genesis-sign')), findsNothing);
    });

    testWidgets('a founder who signed sees no sign button', (tester) async {
      await tester.pumpWidget(
        host(
          StawiTimelineItem(event: card(), isMe: false),
          overrides: overrides(
            profileId: 'p1',
            signatures: [
              const RoomEvent(
                id: 'sig1',
                roomId: roomId,
                senderId: 'sub-me',
                type: RoomEventType.stawiGenesisSignature,
                createdAt: 1,
                status: EventStatus.sent,
                content: {},
                parentId: 'conv1',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('genesis-sign')), findsNothing);
      expect(find.text('You signed'), findsOneWidget);
    });

    testWidgets('shows the room on chain once activated', (tester) async {
      await tester.pumpWidget(
        host(
          StawiTimelineItem(event: card(), isMe: false),
          overrides: overrides(
            profileId: 'p1',
            outcomes: [
              outcomeEvent(
                'STAWI_CALL_OUTCOME_STATE_OBSERVED',
                kind: 'ROOM_ACTIVATED',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('On chain'), findsOneWidget);
      expect(find.byKey(const Key('genesis-sign')), findsNothing);
    });
  });
}
