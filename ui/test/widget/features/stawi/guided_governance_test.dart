import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/auth/data/current_user_provider.dart';
import 'package:stawi/features/rooms/data/detail_panel_providers.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_finance_service.dart';
import 'package:stawi/features/stawi/data/stawi_room_service.dart';
import 'package:stawi/features/stawi/domain/secret_ballot.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi/features/stawi/ui/decision_progress_screen.dart';
import 'package:stawi/features/stawi/ui/guided_governance.dart';
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
  final room = RoomContracts(
    governance: Uint8List(20)..[0] = 0x40,
    custody: Uint8List(20)..[0] = 0x30,
    chainId: BigInt.from(146),
  );
  final amina = Uint8List(20)..[19] = 0x22;
  final baraka = Uint8List(20)..[19] = 0x33;
  final chena = Uint8List(20)..[19] = 0x44;

  late FakeConnectTransport transport;
  late RecordingActSender sender;
  late RecordingSigningGate gate;
  late List<finance.Member> onChain;
  settlement.PrepareRoomCallResponse? lastPrepared;

  finance.Member member(
    String profileId, {
    finance.MemberState state = finance.MemberState.MEMBER_STATE_ACTIVE,
    List<String> roles = const [],
    List<finance.RoomCapability> caps = const [],
  }) => finance.Member(
    profileId: profileId,
    state: state,
    roleIds: roles,
    capabilities: caps,
  );

  setUp(() {
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
        ),
      )
      ..on(
        settlement.RoomService.getRoomCall,
        (req) => settlement.GetRoomCallResponse(
          call: settlement.RoomCall(
            callId: req.callId,
            state: settlement.RoomCallState.ROOM_CALL_STATE_SUBMITTED,
          ),
        ),
      );
    // Me (p1) and Baraka (p3, the treasurer who may lend) are members on
    // chain; Amina (p2) is only in the chat; Chena (p4) is suspended.
    onChain = [
      member('p1'),
      member(
        'p3',
        roles: ['treasurer'],
        caps: [finance.RoomCapability.ROOM_CAPABILITY_LEND],
      ),
      member('p4', state: finance.MemberState.MEMBER_STATE_SUSPENDED),
    ];
  });

  RoomSubscriptionInfo chatMember(String id, String profileId, String name) =>
      RoomSubscriptionInfo(
        id: id,
        profileId: profileId,
        contactId: null,
        name: name,
        avatarUrl: null,
        role: 'member',
        joinedAt: 0,
      );

  List<Override> overrides() => [
    currentProfileIdProvider.overrideWith((ref) async => 'p1'),
    roomMembersProvider.overrideWith(
      (ref, roomId) async => [
        chatMember('s1', 'p1', 'Me'),
        chatMember('s2', 'p2', 'Amina'),
        chatMember('s3', 'p3', 'Baraka'),
        chatMember('s4', 'p4', 'Chena'),
      ],
    ),
    stawiMembersProvider.overrideWith((ref, id) async => onChain),
    stawiRolesProvider.overrideWith(
      (ref, roomId) async => [
        finance.RoleCapabilities(
          roleId: 'treasurer',
          displayName: 'Treasurer',
          maxHolders: 2,
        ),
        finance.RoleCapabilities(
          roleId: 'chair',
          displayName: 'Chairperson',
          maxHolders: 1,
        ),
      ],
    ),
    stawiRoomServiceProvider.overrideWithValue(
      StawiRoomService(
        rooms: settlement.RoomServiceClient(transport),
        keys: DeviceKeyStore(vaultWith('p1', anvilKey), gate: gate),
        identity: () async => identityWith('p1', account),
        send: sender.call,
        ballots: SecretBallotStore(MemoryDeviceKeyVault()),
        contracts: (id) async => id == roomId ? room : null,
        memberAccounts: (id, profileId) async => switch (profileId) {
          'p1' => account,
          'p2' => amina,
          'p3' => baraka,
          'p4' => chena,
          _ => null,
        },
      ),
    ),
  ];

  Future<void> openSheet(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1080, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showGroupDecisionsSheet(context, roomId: roomId),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> start(WidgetTester tester, GroupDecision d) async {
    await openSheet(tester);
    await tester.tap(find.byKey(Key('decision-${d.name}')));
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, String profileId) async {
    await tester.tap(find.byKey(Key('guided-person-$profileId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('guided-next')));
    await tester.pumpAndSettle();
  }

  settlement.PrepareRoomCallRequest prepared() =>
      transport.requestsTo(settlement.RoomService.prepareRoomCall).single;

  /// Signs from the confirmation: the checked review comes first, and only
  /// confirming it reaches the device key, once.
  Future<void> signAndConfirm(WidgetTester tester, Object title) async {
    await tester.tap(find.byKey(const Key('guided-sign')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('money-review')), findsOneWidget);
    expect(sender.sent, isEmpty);
    expect(gate.reasons, isEmpty);
    await tester.tap(find.byKey(const Key('money-review-sign')));
    await tester.pumpAndSettle();
    expect(gate.reasons, hasLength(1));
    expect(gate.reasons.single, title);
    final content = sender.sent.single.content;
    expect(content['summary'], title);
    expect(
      recoverDeviceAddress(
        Uint8List.fromList(lastPrepared!.digest),
        base64Decode(content['signature'] as String),
      ),
      await deviceAddressOf(anvilKey),
      reason: 'the checked digest, signed by this device',
    );
  }

  testWidgets('the sheet leads with the guided decisions; the full list is '
      'behind Advanced', (tester) async {
    await openSheet(tester);
    for (final d in GroupDecision.values) {
      expect(find.byKey(Key('decision-${d.name}')), findsOneWidget);
    }
    expect(find.byKey(const Key('governance-vote')), findsNothing);
    await tester.tap(find.byKey(const Key('decision-advanced')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('governance-vote')), findsOneWidget);
    expect(find.byKey(const Key('governance-proposeExit')), findsOneWidget);
  });

  testWidgets('adding a member proposes the invitation when I may not '
      'invite', (tester) async {
    await start(tester, GroupDecision.invite);
    // Only people not yet on chain are offered.
    expect(find.byKey(const Key('guided-person-p2')), findsOneWidget);
    expect(find.byKey(const Key('guided-person-p3')), findsNothing);
    expect(find.byKey(const Key('guided-person-p1')), findsNothing);
    await pick(tester, 'p2');

    expect(find.text('Propose inviting Amina'), findsOneWidget);
    expect(find.text('The group votes on inviting Amina.'), findsOneWidget);
    expect(transport.calls, isEmpty, reason: 'nothing prepared before sign');
    await signAndConfirm(
      tester,
      startsWith('Propose inviting Amina (invitation expires '),
    );
    final req = prepared();
    expect(req.kind, settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE);
    expect(
      req.params.propose.memberAction.action,
      finance.RoomMemberAction.ROOM_MEMBER_ACTION_INVITE,
    );
    expect(req.params.propose.memberAction.subject.account, amina);
    expect(find.byType(GuidedDecisionScreen), findsNothing);
  });

  testWidgets('an officer who may invite invites at once', (tester) async {
    onChain[0] = member(
      'p1',
      caps: [finance.RoomCapability.ROOM_CAPABILITY_INVITE],
    );
    await start(tester, GroupDecision.invite);
    expect(
      find.text('Who should join? You may invite them yourself.'),
      findsOneWidget,
    );
    await pick(tester, 'p2');
    expect(
      find.text('Amina is invited to join the group on chain.'),
      findsOneWidget,
    );
    await signAndConfirm(tester, 'Invite Amina');
    final req = prepared();
    expect(req.kind, settlement.RoomCallKind.ROOM_CALL_KIND_INVITE);
    expect(req.params.officer.subject.account, amina);
    expect(req.params.officer.inviteValidSeconds, 7 * 24 * 3600);
  });

  testWidgets('a role starts from what its holders may do', (tester) async {
    await start(tester, GroupDecision.role);
    await tester.tap(find.byKey(const Key('guided-role')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Treasurer').last);
    await tester.pumpAndSettle();
    // Baraka, the treasurer now, may lend: the new holder starts the same.
    final lend = tester.widget<CheckboxListTile>(
      find.byKey(const Key('guided-power-32')),
    );
    expect(lend.value, isTrue);
    expect(find.text('Holds Treasurer'), findsOneWidget);
    // Only active members are offered.
    expect(find.byKey(const Key('guided-person-p4')), findsNothing);
    await tester.tap(find.byKey(const Key('guided-power-1')));
    await tester.pumpAndSettle();
    await pick(tester, 'p1');
    expect(find.text('Propose Me as Treasurer'), findsOneWidget);
    expect(
      find.text(
        'As Treasurer, Me may: Invite people into the group; Approve loans '
        'as a credit officer.',
      ),
      findsOneWidget,
    );
    await signAndConfirm(tester, 'Propose Me as Treasurer');
    final req = prepared();
    expect(req.kind, settlement.RoomCallKind.ROOM_CALL_KIND_ASSIGN_ROLE);
    expect(req.params.role.member.account, account);
    expect(req.params.role.roleId, 'treasurer');
    expect(req.params.role.capabilities, 1 | 32);
  });

  testWidgets('taking a role away proposes its revocation', (tester) async {
    await start(tester, GroupDecision.role);
    await tester.tap(find.byKey(const Key('guided-role')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Treasurer').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take it away'));
    await tester.pumpAndSettle();
    await pick(tester, 'p3');
    expect(
      find.text('Baraka keeps their membership and savings.'),
      findsOneWidget,
    );
    await signAndConfirm(tester, 'Propose removing Baraka as Treasurer');
    final req = prepared();
    expect(req.kind, settlement.RoomCallKind.ROOM_CALL_KIND_REVOKE_ROLE);
    expect(req.params.role.member.account, baraka);
  });

  testWidgets('a full single-holder role says one must go', (tester) async {
    onChain[1] = member('p3', roles: ['chair']);
    await start(tester, GroupDecision.role);
    await tester.tap(find.byKey(const Key('guided-role')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chairperson').last);
    await tester.pumpAndSettle();
    await pick(tester, 'p1');
    expect(
      find.textContaining('Chairperson has room for 1 and is held by Baraka'),
      findsOneWidget,
    );
  });

  testWidgets('removing a member is a vote on the one chosen', (tester) async {
    await start(tester, GroupDecision.remove);
    expect(find.byKey(const Key('guided-person-p2')), findsNothing);
    expect(find.byKey(const Key('guided-person-p4')), findsOneWidget);
    await tester.tap(find.byKey(const Key('guided-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guided-error')), findsOneWidget);
    await pick(tester, 'p4');
    // Settlement finishes a passed removal itself: nothing to do by hand.
    expect(
      find.textContaining('Stawi carries it out by itself'),
      findsOneWidget,
    );
    expect(find.textContaining('Queue a passed proposal'), findsNothing);
    await signAndConfirm(tester, 'Propose removing Chena');
    // The proposal is followed from here: settlement has not put it on chain
    // in this test, so it is still being sent.
    expect(find.byType(DecisionProgressScreen), findsOneWidget);
    expect(find.byKey(const Key('decision-stage-sending')), findsOneWidget);
    final req = prepared();
    expect(req.kind, settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE);
    expect(
      req.params.propose.memberAction.action,
      finance.RoomMemberAction.ROOM_MEMBER_ACTION_REMOVE,
    );
    expect(req.params.propose.memberAction.subject.account, chena);
  });

  testWidgets('leaving goes straight to what will change', (tester) async {
    await start(tester, GroupDecision.leave);
    expect(
      find.text('You stop being a member of the group on chain.'),
      findsOneWidget,
    );
    await signAndConfirm(tester, 'Leave the room');
    expect(prepared().kind, settlement.RoomCallKind.ROOM_CALL_KIND_LEAVE);
  });

  testWidgets('backing out of the review signs and sends nothing', (
    tester,
  ) async {
    await start(tester, GroupDecision.leave);
    await tester.tap(find.byKey(const Key('guided-sign')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('money-review')), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(gate.reasons, isEmpty);
    expect(sender.sent, isEmpty);
    expect(find.byType(GuidedDecisionScreen), findsOneWidget);
  });
}
