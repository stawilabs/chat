import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/auth/data/current_user_provider.dart';
import 'package:stawi/features/rooms/data/detail_panel_providers.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/data/stawi_custody.dart';
import 'package:stawi/features/stawi/data/stawi_room_engines.dart';
import 'package:stawi/features/stawi/data/stawi_room_service.dart';
import 'package:stawi/features/stawi/domain/account_engine_calls.dart';
import 'package:stawi/features/stawi/domain/secret_ballot.dart';
import 'package:stawi/features/stawi/ui/governance_sheet.dart';
import 'package:stawi/features/stawi/ui/pending_reveals_card.dart';
import 'package:stawi/features/stawi/ui/room_money_screen.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

const roomId = 'room00000000000000aa';

void main() {
  final member = Uint8List.fromList(List.filled(20, 7));
  SealedVote vote(DateTime? closes) => SealedVote(
    choice: finance.VoteChoice.VOTE_CHOICE_APPROVE,
    salt: Uint8List(32),
    member: member,
    revealClosesAt: closes,
  );

  group('PendingRevealsCard', () {
    final now = DateTime.utc(2026, 10, 12, 12);

    Future<void> pump(
      WidgetTester tester,
      List<PendingReveal> pending, {
      StawiRoomService? service,
    }) => tester.pumpWidget(
      ProviderScope(
        overrides: [
          stawiPendingRevealsProvider.overrideWith((ref, id) async => pending),
          if (service != null)
            stawiRoomServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PendingRevealsCard(roomId: roomId, now: now),
          ),
        ),
      ),
    );

    testWidgets('is hidden with nothing to reveal', (tester) async {
      await pump(tester, const []);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pending-reveals')), findsNothing);
    });

    testWidgets('reminds the voter of each deadline on this device', (
      tester,
    ) async {
      await pump(tester, [
        (proposalId: 3, vote: vote(DateTime.utc(2026, 10, 13))),
        (proposalId: 4, vote: vote(DateTime.utc(2026, 10, 20))),
        (proposalId: 5, vote: vote(DateTime.utc(2026, 10, 11))),
        (proposalId: 6, vote: vote(null)),
      ]);
      await tester.pumpAndSettle();
      expect(find.textContaining('sealed on this device'), findsOneWidget);
      expect(find.textContaining('Reveal now: closes'), findsOneWidget);
      expect(find.textContaining('Reveal by'), findsOneWidget);
      expect(find.textContaining('The reveal window closed'), findsOneWidget);
      expect(find.text('Reveal after voting closes'), findsOneWidget);
      expect(find.byKey(const Key('reveal-5')), findsNothing);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('reveals from the card', (tester) async {
      final wrapped = GoSignedCallVectors.load().accountWrappedHashes
          .firstWhere(
            (v) => v['name'] == 'anvil_0/seq' && v['chain_id'] == '146',
          );
      final account = hexToBytes(wrapped['account'] as String);
      final ballots = MemoryDeviceKeyVault();
      await SecretBallotStore(ballots).seal(
        roomId: roomId,
        proposalId: 3,
        choice: finance.VoteChoice.VOTE_CHOICE_REJECT,
        member: account,
      );
      final transport = FakeConnectTransport()
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
              requiresSignature: true,
            ),
          ),
        );
      final sender = RecordingActSender();
      await pump(
        tester,
        [(proposalId: 3, vote: vote(DateTime.utc(2026, 10, 20)))],
        service: StawiRoomService(
          rooms: settlement.RoomServiceClient(transport),
          keys: DeviceKeyStore(vaultWith('p1', anvilKey)),
          identity: () async => identityWith('p1', account),
          send: sender.call,
          ballots: SecretBallotStore(ballots),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reveal-3')));
      await tester.pumpAndSettle();
      expect(sender.sent.single.content['kind'], 'REVEAL_VOTE');
      expect(
        (await SecretBallotStore(ballots).load(roomId, 3))!.revealed,
        isTrue,
      );
    });
  });

  testWidgets('the reveal dialog says it must be the voting device', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentProfileIdProvider.overrideWith((ref) async => 'p1'),
          roomMembersProvider.overrideWith((ref, id) async => []),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: GovernanceDialog(
              roomId: roomId,
              action: GovernanceAction.revealVote,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reveal-device-note')), findsOneWidget);
  });

  group('product picker', () {
    final request = GoEngineCallVector.load().firstWhere(
      (v) => v.name == 'loan_request',
    );

    Future<FakeConnectTransport> pump(
      WidgetTester tester,
      List<RoomProduct>? products,
    ) async {
      final transport = FakeConnectTransport()
        ..on(
          settlement.AccountService.prepareAccountCall,
          (req) => request.prepared(req.kind),
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomProductsProvider.overrideWith((ref, id) async => products),
            roomEnginesProvider.overrideWith(
              (ref, id) async => RoomEngines(
                loanEngine: request.target,
                rulesEngine: Uint8List(20),
              ),
            ),
            roomCustodyProvider.overrideWith((ref, id) async => request.room),
            stawiAccountServiceProvider.overrideWithValue(
              StawiAccountService(
                accounts: settlement.AccountServiceClient(transport),
                keys: DeviceKeyStore(vaultWith('p1', request.devicePrivateKey)),
                proofs: refusingSessionProofs,
                identity: () async => identityWith('p1', request.account),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AccountEngineDialog(
                roomId: roomId,
                call: AccountEngineCall.loanRequest,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return transport;
    }

    testWidgets('names the room’s loan forms when they can be listed', (
      tester,
    ) async {
      final transport = await pump(tester, [
        RoomProduct(
          id: hexToBytes(request.json['product_id'] as String),
          name: 'Emergency loan',
          kind: RoomProductKind.loan,
        ),
        RoomProduct(
          id: Uint8List(32),
          name: 'Monthly dues',
          kind: RoomProductKind.dues,
        ),
      ]);
      expect(find.byKey(const Key('engine-product')), findsNothing);
      await tester.tap(find.byKey(const Key('engine-product-picker')));
      await tester.pumpAndSettle();
      expect(find.text('Monthly dues'), findsNothing);
      await tester.tap(find.text('Emergency loan').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('engine-amount')),
        request.json['amount'] as String,
      );
      await tester.enterText(find.byKey(const Key('engine-instalments')), '4');
      await tester.tap(find.byKey(const Key('engine-review')));
      await tester.pumpAndSettle();

      final prepare = transport
          .requestsTo(settlement.AccountService.prepareAccountCall)
          .single;
      expect(
        prepare.params.productId,
        hexToBytes(request.json['product_id'] as String),
      );
      expect(find.textContaining('on the room’s own engine'), findsOneWidget);
      expect(find.byKey(const Key('engine-sign')), findsOneWidget);
    });

    testWidgets('falls back to a typed name until products can be listed', (
      tester,
    ) async {
      await pump(tester, null);
      expect(find.byKey(const Key('engine-product')), findsOneWidget);
      expect(find.byKey(const Key('engine-product-picker')), findsNothing);
    });
  });
}
