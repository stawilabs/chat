import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/auth/data/current_user_provider.dart';
import 'package:stawi/features/rooms/data/detail_panel_providers.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/data/stawi_binding.dart';
import 'package:stawi/features/stawi/data/stawi_custody.dart';
import 'package:stawi/features/stawi/data/stawi_finance_service.dart';
import 'package:stawi/features/stawi/data/stawi_room_service.dart';
import 'package:stawi/features/stawi/domain/secret_ballot.dart';
import 'package:stawi/features/stawi/ui/governance_sheet.dart';
import 'package:stawi/features/stawi/ui/room_money_screen.dart';
import 'package:stawi/features/stawi/ui/stawi_room_screen.dart';
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

  late FakeConnectTransport transport;
  late RecordingActSender sender;
  late MemoryDeviceKeyVault ballots;

  setUp(() {
    transport = FakeConnectTransport()
      ..on(
        settlement.RoomService.prepareRoomCall,
        (req) => settlement.PrepareRoomCallResponse(
          callId: 'call0000000000000001',
          digest: hexToBytes(wrapped['wrapped'] as String),
          signer: account,
          call: settlement.RoomCall(
            chainId: Int64(146),
            chatRoomId: roomId,
            kind: req.kind,
            typedHash: hexToBytes(wrapped['hash'] as String),
            requiresSignature: !{
              settlement.RoomCallKind.ROOM_CALL_KIND_COLLECT,
              settlement.RoomCallKind.ROOM_CALL_KIND_SETTLE,
            }.contains(req.kind),
          ),
        ),
      )
      ..on(
        settlement.RoomService.submitRoomCall,
        (req) => settlement.SubmitRoomCallResponse(
          call: settlement.RoomCall(callId: req.callId),
        ),
      );
    sender = RecordingActSender();
    ballots = MemoryDeviceKeyVault();
  });

  List<Override> overrides() => [
    currentProfileIdProvider.overrideWith((ref) async => 'p1'),
    roomMembersProvider.overrideWith(
      (ref, roomId) async => [
        RoomSubscriptionInfo(
          id: 'sub-me',
          profileId: 'p1',
          contactId: null,
          name: 'Me',
          avatarUrl: null,
          role: 'owner',
          joinedAt: 0,
        ),
        RoomSubscriptionInfo(
          id: 'sub-2',
          profileId: 'p2',
          contactId: null,
          name: 'Amina',
          avatarUrl: null,
          role: 'member',
          joinedAt: 1,
        ),
      ],
    ),
    stawiRolesProvider.overrideWith(
      (ref, roomId) async => [
        finance.RoleCapabilities(roleId: 'treasurer', displayName: 'Treasurer'),
      ],
    ),
    stawiRoomServiceProvider.overrideWithValue(
      StawiRoomService(
        rooms: settlement.RoomServiceClient(transport),
        keys: DeviceKeyStore(vaultWith('p1', anvilKey)),
        identity: () async => identityWith('p1', account),
        send: sender.call,
        ballots: SecretBallotStore(ballots),
      ),
    ),
  ];

  Future<void> openDialog(WidgetTester tester, GovernanceAction action) async {
    tester.view
      ..physicalSize = const Size(1080, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          home: Scaffold(
            body: GovernanceDialog(roomId: roomId, action: action),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  settlement.PrepareRoomCallRequest prepared() =>
      transport.requestsTo(settlement.RoomService.prepareRoomCall).single;

  group('GovernanceDialog', () {
    testWidgets('a secret vote sends only a commitment', (tester) async {
      await openDialog(tester, GovernanceAction.secretVote);
      await tester.enterText(find.byKey(const Key('governance-number')), '9');
      await tester.tap(find.text('Reject'));
      await tester.tap(find.byKey(const Key('governance-sign')));
      await tester.pumpAndSettle();

      expect(
        prepared().kind,
        settlement.RoomCallKind.ROOM_CALL_KIND_COMMIT_VOTE,
      );
      expect(prepared().params.vote.commitment, hasLength(32));
      expect(prepared().params.vote.hasChoice(), isFalse);
      final sealed = (await SecretBallotStore(ballots).load(roomId, 9))!;
      expect(sealed.choice, finance.VoteChoice.VOTE_CHOICE_REJECT);
      expect(sender.sent.single.content['kind'], 'COMMIT_VOTE');
    });

    testWidgets('a freeze needs a reason', (tester) async {
      await openDialog(tester, GovernanceAction.freeze);
      await tester.tap(find.byKey(const Key('governance-sign')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('governance-error')), findsOneWidget);
      expect(transport.calls, isEmpty);

      await tester.enterText(
        find.byKey(const Key('governance-text')),
        'Treasurer device stolen',
      );
      await tester.tap(find.byKey(const Key('governance-sign')));
      await tester.pumpAndSettle();
      expect(prepared().kind, settlement.RoomCallKind.ROOM_CALL_KIND_FREEZE);
      expect(prepared().params.freeze_7.reason, 'Treasurer device stolen');
    });

    testWidgets('a role proposal names the member, role and capabilities', (
      tester,
    ) async {
      await openDialog(tester, GovernanceAction.assignRole);
      await tester.tap(find.byKey(const Key('governance-member')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Amina').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('governance-role')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Treasurer').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('capability-Lend')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('governance-sign')));
      await tester.pumpAndSettle();

      final role = prepared().params.role;
      expect(
        prepared().kind,
        settlement.RoomCallKind.ROOM_CALL_KIND_ASSIGN_ROLE,
      );
      expect(role.member.profileId, 'p2');
      expect(role.roleId, 'treasurer');
      expect(role.capabilities, 32);
      expect(
        sender.sent.single.content['summary'],
        'Propose Amina as Treasurer',
      );
    });

    testWidgets('a principal exit vote carries the ballot and decision', (
      tester,
    ) async {
      await openDialog(tester, GovernanceAction.voteExit);
      await tester.enterText(find.byKey(const Key('governance-number')), '4');
      await tester.tap(find.byKey(const Key('governance-approve')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('governance-sign')));
      await tester.pumpAndSettle();
      expect(
        prepared().kind,
        settlement.RoomCallKind.ROOM_CALL_KIND_VOTE_PRINCIPAL_EXIT,
      );
      expect(prepared().params.principalExit.ballotId, Int64(4));
      expect(prepared().params.principalExit.approve, isFalse);
    });

    testWidgets('a principal exit proposal checks its payload hash', (
      tester,
    ) async {
      await openDialog(tester, GovernanceAction.proposeExit);
      await tester.enterText(find.byKey(const Key('governance-text')), '0x12');
      await tester.tap(find.byKey(const Key('governance-sign')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('governance-error')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('governance-text')),
        '0x${'ab' * 32}',
      );
      await tester.tap(find.byKey(const Key('governance-sign')));
      await tester.pumpAndSettle();
      expect(
        prepared().params.principalExit.payloadHash,
        Uint8List.fromList(List.filled(32, 0xab)),
      );
    });
  });

  group('RoomMoneyScreen', () {
    final custody = Uint8List.fromList(List.filled(20, 0xc0));

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...overrides(),
            stawiObligationsProvider.overrideWith(
              (ref, id) async => [
                finance.Obligation(
                  amount: finance.Money(assetId: 'USDC.146', amount: '500'),
                  settled: finance.Money(assetId: 'USDC.146', amount: '200'),
                ),
              ],
            ),
            stawiPeriodsProvider.overrideWith(
              (ref, id) async => [finance.Period(periodIndex: Int64(3))],
            ),
            stawiEntitlementsProvider.overrideWith(
              (ref, id) async => [
                finance.Entitlement(
                  amount: finance.Money(assetId: 'USDC.146', amount: '75'),
                ),
              ],
            ),
            stawiDistributionsProvider.overrideWith((ref, id) async => []),
            stawiLoansProvider.overrideWith(
              (ref, id) async => [
                finance.Loan(
                  loanId: 'loan1',
                  principal: finance.Money(assetId: 'USDC.146', amount: '900'),
                ),
              ],
            ),
            stawiMembersProvider.overrideWith(
              (ref, id) async => [
                finance.Member(memberId: 'mem1', profileId: 'p2'),
              ],
            ),
            stawiMemberBalancesProvider.overrideWith(
              (ref, key) async => [
                finance.Balances(assetId: 'USDC.146', total: '1234'),
              ],
            ),
            roomCustodyProvider.overrideWith((ref, id) async => custody),
            stawiAccountServiceProvider.overrideWithValue(
              StawiAccountService(
                accounts: settlement.AccountServiceClient(transport),
                keys: DeviceKeyStore(vaultWith('p1', anvilKey)),
                proofs: refusingSessionProofs,
                identity: () async => identityWith('p1', account),
              ),
            ),
          ],
          child: const MaterialApp(
            home: RoomMoneyScreen(roomId: roomId, roomName: 'Chama'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows dues and settles them through the rules engine', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('200 USDC.146 of 500 USDC.146'), findsOneWidget);
      expect(find.text('Period 3'), findsOneWidget);
      await tester.tap(find.byKey(const Key('money-settle')));
      await tester.pumpAndSettle();
      expect(prepared().kind, settlement.RoomCallKind.ROOM_CALL_KIND_SETTLE);
      expect(prepared().params.engine.member.profileId, 'p1');
      expect(
        transport.requestsTo(settlement.RoomService.submitRoomCall),
        hasLength(1),
      );
    });

    testWidgets('collects share-outs', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Share-outs'));
      await tester.pumpAndSettle();
      expect(find.text('75 USDC.146'), findsOneWidget);
      await tester.tap(find.byKey(const Key('money-collect')));
      await tester.pumpAndSettle();
      expect(prepared().kind, settlement.RoomCallKind.ROOM_CALL_KIND_COLLECT);
    });

    testWidgets('loan requests say what the backend still needs', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text('Loans'));
      await tester.pumpAndSettle();
      expect(find.text('900 USDC.146'), findsOneWidget);
      await tester.tap(find.byKey(const Key('engine-loanRequest')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('engine-amount')), '1000');
      await tester.tap(find.byKey(const Key('engine-sign')));
      await tester.pumpAndSettle();
      expect(find.textContaining('stawi_api 0.3.0'), findsOneWidget);
      expect(
        transport.requestsTo(settlement.AccountService.prepareAccountCall),
        isEmpty,
      );
    });

    testWidgets('lists members with their balances', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Members'));
      await tester.pumpAndSettle();
      expect(find.text('p2'), findsOneWidget);
      expect(find.text('1234 USDC.146'), findsOneWidget);
    });
  });

  group('StawiRoomScreen from the chat binding', () {
    Future<void> pump(WidgetTester tester, StawiBinding? binding) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            stawiBindingProvider.overrideWith((ref, id) async => binding),
          ],
          child: const MaterialApp(
            home: StawiRoomScreen(roomId: roomId, roomName: 'Chama'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a bound room offers its money and acts', (tester) async {
      await pump(
        tester,
        const StawiBinding(
          state: StawiBindingState.bound,
          genesisId: 'gen1',
          genesisEventId: 'evt1',
        ),
      );
      expect(find.text('Stawi room'), findsOneWidget);
      expect(find.byKey(const Key('stawi-money')), findsOneWidget);
      expect(find.byKey(const Key('stawi-governance')), findsOneWidget);
    });

    testWidgets('a pending room awaits signatures', (tester) async {
      await pump(
        tester,
        const StawiBinding(
          state: StawiBindingState.pending,
          genesisId: 'gen1',
          genesisEventId: 'evt1',
        ),
      );
      expect(find.text('Awaiting founder signatures'), findsOneWidget);
      expect(find.byKey(const Key('stawi-convert')), findsNothing);
    });

    testWidgets('a plain room can be converted', (tester) async {
      await pump(tester, null);
      expect(find.byKey(const Key('stawi-convert')), findsOneWidget);
    });
  });
}
