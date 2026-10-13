import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/auth/data/current_user_provider.dart';
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/rooms/data/room_providers.dart';
import 'package:stawi/features/rooms/data/room_subscription_service.dart';
import 'package:stawi/features/rooms/domain/room.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/signing_gate.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart'
    show stawiClockProvider;
import 'package:stawi/features/stawi/data/stawi_agent_invitations.dart';
import 'package:stawi/features/stawi/data/stawi_counterparty.dart';
import 'package:stawi/features/stawi/data/stawi_finance_service.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/data/stawi_room_service.dart';
import 'package:stawi/features/stawi/data/stawi_timeline_providers.dart';
import 'package:stawi/features/stawi/domain/personal_calls.dart';
import 'package:stawi/features/stawi/domain/stawi_payloads.dart';
import 'package:stawi/features/stawi/ui/loan_detail_screen.dart';
import 'package:stawi/features/stawi/ui/stawi_timeline.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
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
                'amount': '2500000000',
                'asset_id': 'USDC.146',
              },
            },
          ),
          isMe: false,
        ),
        overrides: [
          stawiRoomAssetsProvider.overrideWith((ref, id) async => usdcAssets),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('New proposal: buy a tent'), findsOneWidget);
    expect(find.text('Voting happens in Stawi.'), findsOneWidget);
    // An id is the app's, never a line.
    expect(find.textContaining('prop0000000000000001'), findsNothing);
    expect(find.text('0x01'), findsNothing);
    expect(find.text('2,500.00 USDC'), findsOneWidget);
    expect(find.text('USDC.146'), findsNothing);
    expect(find.byKey(const Key('finance-card-vote')), findsOneWidget);
  });

  group('loan cards', () {
    const book = '0x101112131415161718191a1b1c1d1e1f20212223';
    const pool = '0xb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3';

    /// Card data as finance's projection records it (apps/finance/service/
    /// business/projection/loans.go recordCard and renderLoan): the loan's
    /// reference and step, then the card's own fields.
    Map<String, dynamic> loanData(
      String event, [
      Map<String, dynamic> own = const {},
    ]) => {
      'loan_book': book,
      'pool': pool,
      'loan_id': '7',
      'kind': 'PERSON_TO_PERSON',
      'event': event,
      'instalment': '-',
      'action': 'open_loan',
      ...own,
    };

    RoomEvent loanCard({
      String kind = 'LOAN_OFFERED',
      String title = 'Loan offer: 300.00 USDC',
      String body = 'Offered: 4 instalments every two weeks.',
      Map<String, dynamic>? data,
    }) => RoomEvent(
      id: 'card-$kind',
      roomId: roomId,
      senderId: '',
      type: RoomEventType.financeCard,
      createdAt: 0,
      content: {
        'cardId': 'k-$kind',
        'kind': kind,
        'title': title,
        'body': body,
        'data':
            data ??
            loanData('LoanOffered', {
              'amount': '300000000',
              'instalments': '4',
            }),
      },
    );

    /// Every card finance sends that carries data (loans.go renderLoan,
    /// service.go's contribution and proposal cards), as finance words it.
    final realCards = <RoomEvent>[
      loanCard(),
      loanCard(
        kind: 'LOAN_REQUESTED',
        title: 'Loan request: 500.00 USDC',
        body: 'A member asked to borrow 500.00 USDC',
        data: loanData('LoanRequested', {
          'amount': '500000000',
          'member_id': 'mem00000000000000001',
          'record_loans': '3',
          'record_late': '1',
          'record_defaults': '0',
        })..['kind'] = 'GROUP',
      ),
      loanCard(
        kind: 'LOAN_PAID_OUT',
        title: 'Loan paid out: 295.00 USDC',
        body: 'The loan was accepted and 295.00 USDC paid out.',
        data: loanData('LoanDisbursed', {'amount': '295000000'}),
      ),
      loanCard(
        kind: 'LOAN_PAYMENT',
        title: 'Payment received: 77.50 USDC',
        body: '77.50 USDC was paid towards the loan.',
        data: loanData('LoanRepaid', {'amount': '77500000'})
          ..['instalment'] = '0x1234:5',
      ),
      loanCard(
        kind: 'LOAN_LATE',
        title: 'Instalment 2 of 4 is late',
        body: 'The instalment was not paid on time.',
        data: loanData('LoanPenaltyAssessed', {'amount': '3875000'})
          ..['instalment'] = '1',
      ),
      loanCard(
        kind: 'LOAN_RECOVERED',
        title: 'Recovered: 40.00 USDC',
        body: '40.00 USDC was recovered towards the defaulted loan.',
        data: loanData('LoanRecovered', {'amount': '40000000'}),
      ),
      loanCard(
        kind: 'LOAN_CLOSED_UNACCEPTED',
        title: 'Loan offer closed: 300.00 USDC',
        body: 'The offer was withdrawn or expired.',
        data: loanData('PersonalLoanCancelled'),
      ),
      loanCard(
        kind: 'CONTRIBUTION',
        title: 'Contribution received',
        body: '',
        data: {
          'contribution_id': 'con00000000000000001',
          'member_id': 'mem00000000000000001',
          'amount': '25000000',
          'asset_id': 'USDC.146',
        },
      ),
      loanCard(
        kind: 'CONTRIBUTION_FAILED',
        title: 'Contribution not collected',
        body: 'Cause: INSUFFICIENT_FUNDS.',
        data: {
          'contribution_id': 'con00000000000000002',
          'member_id': 'mem00000000000000001',
        },
      ),
      loanCard(
        kind: 'PROPOSAL',
        title: 'New proposal: buy a tent',
        body: 'Voting happens in Stawi.',
        data: {
          'proposal_id': 'prop0000000000000001',
          'payload_hash': '0x01',
          'action': 'open_signing_flow',
        },
      ),
    ];

    testWidgets('no line on a real card shows raw units or an id', (
      tester,
    ) async {
      for (final event in realCards) {
        await tester.pumpWidget(
          host(
            StawiTimelineItem(
              key: ValueKey(event.id),
              event: event,
              isMe: false,
            ),
            overrides: [
              stawiRoomAssetsProvider.overrideWith(
                (ref, id) async => usdcAssets,
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        final data = (event.content['data'] as Map).cast<String, dynamic>();
        for (final MapEntry(:key, :value) in data.entries) {
          // A count of instalments is a number a person reads as it is.
          if (key == 'instalments') continue;
          final raw = '$value';
          if (raw.length < 2) continue;
          expect(
            find.textContaining(raw),
            findsNothing,
            reason: '${event.content['kind']}: $key = $raw',
          );
        }
        for (final label in [
          'member id',
          'contribution id',
          'proposal id',
          'loan id',
          'record loans',
        ]) {
          expect(find.textContaining(label), findsNothing);
        }
      }
      // The contribution's amount, named in its asset, is the one amount line.
      await tester.pumpWidget(
        host(
          StawiTimelineItem(event: realCards[7], isMe: false),
          overrides: [
            stawiRoomAssetsProvider.overrideWith((ref, id) async => usdcAssets),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('25.00 USDC'), findsOneWidget);
    });

    testWidgets('a closed offer has its own icon', (tester) async {
      await tester.pumpWidget(
        host(StawiTimelineItem(event: realCards[6], isMe: false)),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });

    testWidgets('an offer shows its icon, hides the ids and opens the loan', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(StawiTimelineItem(event: loanCard(), isMe: false)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Loan offer: 300.00 USDC'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.byIcon(Icons.volunteer_activism_outlined), findsOneWidget);
      for (final hidden in [
        book,
        pool,
        '7',
        'PERSON_TO_PERSON',
        'LoanOffered',
        'open_loan',
        'loan book',
        'record loans',
      ]) {
        expect(find.textContaining(hidden), findsNothing, reason: hidden);
      }
      final open = find.byKey(const Key('finance-card-open-loan'));
      expect(open, findsOneWidget);
      expect(find.text('Open loan'), findsOneWidget);

      await tester.tap(open);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final screen = tester.widget<LoanDetailScreen>(
        find.byType(LoanDetailScreen),
      );
      expect(
        screen.ref,
        LoanRef(
          loanBook: hexToBytes(book),
          pool: hexToBytes(pool),
          loanId: BigInt.from(7),
        ),
      );
      expect(screen.roomId, roomId);
    });

    testWidgets('the borrower an offer waits for sees Review', (tester) async {
      final me = Uint8List.fromList(List.filled(20, 0x0e));
      final bob = hexToBytes(pool);
      await tester.pumpWidget(
        host(
          StawiTimelineItem(event: loanCard(), isMe: false),
          overrides: [
            stawiIdentityProvider.overrideWith(
              (ref) async => identityWith('p1', me),
            ),
            cardLoanProvider.overrideWith(
              (ref, loanRef) async => finance.Loan(
                loanBook: hexToBytes(book),
                pool: bob,
                lender: bob,
                offeredBy: bob,
                borrowerAccount: me,
                onchainLoanId: Int64(7),
                kind: finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON,
                state: finance.LoanState.LOAN_STATE_PENDING_APPROVAL,
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('finance-card-open-loan')),
          matching: find.text('Review'),
        ),
        findsOneWidget,
      );
      expect(find.text('Open loan'), findsNothing);
    });

    testWidgets('a card whose pool is malformed offers no loan to open', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          StawiTimelineItem(
            event: loanCard(
              data: {
                'loan_book': book,
                'pool': '0xb0b1',
                'loan_id': '7',
                'action': 'open_loan',
              },
            ),
            isMe: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('finance-card-open-loan')), findsNothing);
    });

    testWidgets('a missed contribution has its own card', (tester) async {
      await tester.pumpWidget(
        host(
          StawiTimelineItem(
            event: loanCard(
              kind: 'CONTRIBUTION_FAILED',
              title: 'Contribution not collected',
              data: const {},
            ),
            isMe: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Contribution missed'), findsOneWidget);
      expect(find.text('Contribution not collected'), findsNothing);
      final icon = tester.widget<Icon>(
        find.byKey(const Key('finance-card-icon')),
      );
      expect(icon.icon, Icons.event_busy);
      final context = tester.element(
        find.byKey(const Key('finance-card-icon')),
      );
      expect(icon.color, Theme.of(context).colorScheme.error);
    });

    testWidgets('a late instalment is in the error colour', (tester) async {
      await tester.pumpWidget(
        host(
          StawiTimelineItem(
            event: loanCard(kind: 'LOAN_LATE', title: 'Instalment 2 is late'),
            isMe: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final icon = tester.widget<Icon>(
        find.byKey(const Key('finance-card-icon')),
      );
      expect(icon.icon, Icons.schedule);
      final context = tester.element(
        find.byKey(const Key('finance-card-icon')),
      );
      expect(icon.color, Theme.of(context).colorScheme.error);
    });

    test('a loan reference needs all three, well formed', () {
      FinanceCardView card(Map<String, dynamic> data) =>
          FinanceCardView.fromContent({'kind': 'LOAN_PAYMENT', 'data': data});
      expect(
        card({'loan_book': book, 'pool': pool, 'loan_id': '7'}).loanRef,
        isNotNull,
      );
      expect(card({'loan_book': book, 'pool': pool}).loanRef, isNull);
      expect(
        card({'loan_book': book, 'pool': pool, 'loan_id': '0'}).loanRef,
        isNull,
      );
      expect(
        card({
          'loan_book': book,
          'pool': pool,
          'loan_id': '18446744073709551616',
        }).loanRef,
        isNull,
      );
      expect(
        card({'loan_book': 'nope', 'pool': pool, 'loan_id': '7'}).loanRef,
        isNull,
      );
      expect(
        card({'loan_book': book, 'pool': pool, 'loan_id': '7'}).opensLoan,
        isFalse,
      );
    });
  });

  group('GenesisCard', () {
    // Carol is the agent; the genesis was hashed with her account, and the
    // device recomputes that hash before the founder sees the review.
    final ownerAccount = Uint8List.fromList(List.filled(20, 0xbb));
    final roomGenesis = GoRoomGenesisVectors.named('agent').roomGenesis(
      founderProfileIds: const ['p-owner', 'p1'],
      accounts: [ownerAccount, account],
      agentProfileId: 'p-carol',
    );
    final genesisHash = Uint8List.fromList(roomGenesis.genesisHash);
    final digest = Uint8List.fromList(roomGenesis.founders[1].signingDigest);
    const names = {'p-owner': 'Olive', 'p1': 'Me', 'p-carol': 'Carol'};
    // The account chat answers for Carol, the DM partner: the genesis agent.
    final carolAccount = Uint8List.fromList(roomGenesis.agent);

    RoomEvent card({List<int>? hash}) => RoomEvent(
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
          'genesisHash': base64Encode(hash ?? genesisHash),
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
            genesis: roomGenesis.deepCopy()..genesisId = req.genesisId,
          ),
        );
      sender = RecordingActSender();
      keys = DeviceKeyStore(vaultWith('p1', anvilKey), gate: SigningGate.open);
    });

    List<Override> overrides({
      required String profileId,
      List<RoomEvent> outcomes = const [],
      List<RoomEvent> signatures = const [],
      DmPartnerAccountOf? agentAccounts,
    }) => [
      stawiOutcomesProvider.overrideWith((ref, id) => Stream.value(outcomes)),
      stawiGenesisSignaturesProvider.overrideWith(
        (ref, id) => Stream.value(signatures),
      ),
      currentProfileIdProvider.overrideWith((ref) async => profileId),
      stawiMemberNameProvider.overrideWith(
        (ref, key) async => names[key.profileId] ?? 'Member',
      ),
      currentUserSubscriptionIdProvider.overrideWith(
        (ref, roomId) async => 'sub-me',
      ),
      stawiRoomServiceProvider.overrideWithValue(
        StawiRoomService(
          rooms: settlement.RoomServiceClient(transport),
          keys: keys,
          identity: () async => identityWith(profileId, account),
          send: sender.call,
          agentAccounts:
              agentAccounts ??
              (id) async => id == 'p-carol' ? carolAccount : null,
        ),
      ),
    ];

    testWidgets('a founder reviews the agent and the fee, then signs', (
      tester,
    ) async {
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

      await tester.tap(find.byKey(const Key('genesis-open-review')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('genesis-review')), findsOneWidget);
      expect(find.text('Stawi agent: Carol'), findsOneWidget);
      expect(find.text('Founders: Olive, Me'), findsOneWidget);
      expect(find.text('Who can join: By invitation'), findsOneWidget);
      expect(
        find.text(
          "Stawi takes a fee from the group's interest, fees and penalties; "
          'an agent receives part of it.',
        ),
        findsOneWidget,
      );
      expect(sender.sent, isEmpty, reason: 'nothing is signed before review');

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

    testWidgets('an agent whose address is not theirs cannot be signed', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          StawiTimelineItem(event: card(), isMe: false),
          overrides: overrides(
            profileId: 'p1',
            agentAccounts: (_) async =>
                Uint8List.fromList(List.filled(20, 0x66)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('genesis-open-review')));
      await tester.pumpAndSettle();

      expect(find.text('Stawi agent: Carol'), findsOneWidget);
      expect(
        find.text('The agent could not be confirmed on this device'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('genesis-sign')), findsNothing);
      await tester.tap(find.byKey(const Key('genesis-review-cancel')));
      await tester.pumpAndSettle();
      expect(sender.sent, isEmpty);
    });

    testWidgets('an agent that cannot be resolved cannot be signed', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          StawiTimelineItem(event: card(), isMe: false),
          overrides: overrides(
            profileId: 'p1',
            agentAccounts: (_) async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('genesis-open-review')));
      await tester.pumpAndSettle();
      expect(
        find.text('The agent could not be confirmed on this device'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('genesis-sign')), findsNothing);
    });

    testWidgets('a member agent matches their account in the genesis', (
      tester,
    ) async {
      final olive = GoRoomGenesisVectors.named('agent').roomGenesis(
        founderProfileIds: const ['p-owner', 'p1'],
        accounts: [ownerAccount, account],
        agentAccount: ownerAccount,
        agentProfileId: 'p-owner',
      );
      transport.on(
        settlement.RoomService.getRoomGenesis,
        (req) => settlement.GetRoomGenesisResponse(genesis: olive),
      );
      await tester.pumpWidget(
        host(
          StawiTimelineItem(event: card(hash: olive.genesisHash), isMe: false),
          overrides: overrides(
            profileId: 'p1',
            agentAccounts: (_) async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('genesis-open-review')));
      await tester.pumpAndSettle();
      expect(find.text('Stawi agent: Olive'), findsOneWidget);
      expect(find.byKey(const Key('genesis-agent-unconfirmed')), findsNothing);

      await tester.tap(find.byKey(const Key('genesis-sign')));
      await tester.pumpAndSettle();
      expect(sender.sent.single.type, RoomEventType.stawiGenesisSignature);
    });

    testWidgets('cancelling the review sends no signature', (tester) async {
      await tester.pumpWidget(
        host(
          StawiTimelineItem(event: card(), isMe: false),
          overrides: overrides(profileId: 'p1'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('genesis-open-review')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('genesis-review-cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('genesis-review')), findsNothing);
      expect(sender.sent, isEmpty);
      expect(find.text('Genesis signed'), findsNothing);
      expect(
        find.byKey(const Key('genesis-open-review')),
        findsOneWidget,
        reason: 'the founder can review again',
      );
    });

    testWidgets('a genesis with no agent says so', (tester) async {
      transport.on(
        settlement.RoomService.getRoomGenesis,
        (req) => settlement.GetRoomGenesisResponse(
          genesis: GoRoomGenesisVectors.named('no_agent').roomGenesis(
            founderProfileIds: const ['p-owner', 'p1'],
            accounts: [ownerAccount, account],
          ),
        ),
      );
      await tester.pumpWidget(
        host(
          StawiTimelineItem(
            event: card(
              hash: GoRoomGenesisVectors.named('no_agent')
                  .roomGenesis(accounts: [ownerAccount, account])
                  .genesisHash,
            ),
            isMe: false,
          ),
          overrides: overrides(profileId: 'p1'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('genesis-open-review')));
      await tester.pumpAndSettle();
      expect(find.text('No agent'), findsOneWidget);
      expect(find.textContaining('Stawi agent:'), findsNothing);
    });

    testWidgets('a genesis whose agent was swapped is never shown to sign', (
      tester,
    ) async {
      transport.on(
        settlement.RoomService.getRoomGenesis,
        (req) => settlement.GetRoomGenesisResponse(
          genesis: roomGenesis.deepCopy()
            ..agent = Uint8List.fromList(List.filled(20, 0x66)),
        ),
      );
      await tester.pumpWidget(
        host(
          StawiTimelineItem(event: card(), isMe: false),
          overrides: overrides(profileId: 'p1'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('genesis-open-review')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('genesis-review')), findsNothing);
      expect(
        find.textContaining('the genesis hash does not match its contents'),
        findsOneWidget,
      );
      expect(sender.sent, isEmpty);
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
      expect(find.byKey(const Key('genesis-open-review')), findsNothing);
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
      expect(find.byKey(const Key('genesis-open-review')), findsNothing);
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
      expect(find.byKey(const Key('genesis-open-review')), findsNothing);
    });
  });

  group('agent invitation cards in a DM', () {
    final now = DateTime.utc(2026, 10, 13, 12);
    late RecordingActSender acts;
    late List<RoomEvent> dmEvents;

    setUp(() {
      acts = RecordingActSender();
      dmEvents = [];
    });

    RoomEvent invitation({DateTime? expiresAt}) => RoomEvent(
      id: 'inv1',
      roomId: 'dm-agnes',
      senderId: 'sub-agnes',
      type: RoomEventType.stawiAgentInvitation,
      createdAt: 0,
      status: EventStatus.delivered,
      content: {
        'roomId': 'r-chama',
        'roomName': 'Chama',
        'expiresAt': (expiresAt ?? now.add(const Duration(days: 7)))
            .toIso8601String(),
      },
    );

    Future<void> show(WidgetTester tester, RoomEvent event, bool isMe) =>
        tester.pumpWidget(
          host(
            StawiTimelineItem(event: event, isMe: isMe),
            overrides: [
              roomByIdProvider.overrideWith(
                (ref, id) async => Room(id: id, name: 'Agnes', type: 'direct'),
              ),
              stawiClockProvider.overrideWithValue(() => now),
              agentActSenderProvider.overrideWithValue(acts.call),
              agentEventsSourceProvider.overrideWithValue(
                (dmRoomId) => Stream.value(dmEvents),
              ),
            ],
          ),
        );

    testWidgets('the invited partner accepts it, naming the invitation', (
      tester,
    ) async {
      await show(tester, invitation(), false);
      await tester.pumpAndSettle();
      expect(
        find.text('Agnes invited you to be the Stawi agent of Chama'),
        findsOneWidget,
      );
      expect(find.textContaining('Can be accepted until'), findsOneWidget);
      await tester.tap(find.byKey(const Key('agent-invitation-accept')));
      await tester.pumpAndSettle();
      final sent = acts.sent.single;
      expect(sent.roomId, 'dm-agnes');
      expect(sent.type, RoomEventType.stawiAgentAcceptance);
      expect(
        StawiAgentAcceptanceView.fromContent(sent.content).invitationEventId,
        'inv1',
      );
    });

    testWidgets('its sender sees no Accept', (tester) async {
      await show(tester, invitation(), true);
      await tester.pumpAndSettle();
      expect(
        find.text('You invited Agnes to be the Stawi agent of Chama'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('agent-invitation-accept')), findsNothing);
    });

    testWidgets('an expired or accepted invitation offers no Accept', (
      tester,
    ) async {
      await show(
        tester,
        invitation(expiresAt: now.subtract(const Duration(minutes: 1))),
        false,
      );
      await tester.pumpAndSettle();
      expect(find.text('Expired'), findsOneWidget);
      expect(find.byKey(const Key('agent-invitation-accept')), findsNothing);

      dmEvents = [
        const RoomEvent(
          id: 'acc1',
          roomId: 'dm-agnes',
          senderId: 'sub-me',
          type: RoomEventType.stawiAgentAcceptance,
          createdAt: 1,
          content: {'invitationEventId': 'inv1', 'roomId': 'r-chama'},
        ),
      ];
      await show(tester, invitation(), false);
      await tester.pumpAndSettle();
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.byKey(const Key('agent-invitation-accept')), findsNothing);
    });

    testWidgets('the inviter sees the acceptance and until when it holds', (
      tester,
    ) async {
      await show(
        tester,
        RoomEvent(
          id: 'acc1',
          roomId: 'dm-agnes',
          senderId: 'sub-agnes',
          type: RoomEventType.stawiAgentAcceptance,
          createdAt: 1,
          content: {
            'invitationEventId': 'inv1',
            'roomId': 'r-chama',
            'roomName': 'Chama',
            'expiresAt': now.add(const Duration(days: 7)).toIso8601String(),
          },
        ),
        false,
      );
      await tester.pumpAndSettle();
      expect(find.text('Agnes accepted being agent for Chama'), findsOneWidget);
      expect(find.textContaining('Can be named agent until'), findsOneWidget);
    });
  });
}
