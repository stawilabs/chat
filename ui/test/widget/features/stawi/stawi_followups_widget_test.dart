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
import 'package:stawi/features/stawi/data/stawi_finance_service.dart';
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
    final productId = hexToBytes(request.json['product_id'] as String);

    Future<FakeConnectTransport> pump(
      WidgetTester tester,
      finance.ListRoomProductsResponse products, {
      AccountEngineCall call = AccountEngineCall.loanRequest,
      RoomEngineTargets? engines,
      bool enginesKnown = true,
    }) async {
      tester.view
        ..physicalSize = const Size(1080, 3000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
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
              (ref, id) async =>
                  enginesKnown ? (engines ?? request.engines()) : null,
            ),
            roomCustodyProvider.overrideWith((ref, id) async => request.room),
            stawiRoomAssetProvider.overrideWith((ref, id) async => usdc),
            stawiAccountServiceProvider.overrideWithValue(
              StawiAccountService(
                accounts: settlement.AccountServiceClient(transport),
                keys: DeviceKeyStore(vaultWith('p1', request.devicePrivateKey)),
                proofs: refusingSessionProofs,
                identity: () async => identityWith('p1', request.account),
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AccountEngineDialog(roomId: roomId, call: call),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return transport;
    }

    final products = finance.ListRoomProductsResponse(
      rulesConfigured: true,
      loanProducts: [
        finance.RoomLoanProduct(
          name: 'Emergency loan',
          productId: productId,
          maxAmount: finance.Money(assetId: 'USDC.146', amount: '900000000'),
          rateBps: 300,
          rateBasis: finance.LoanRateBasis.LOAN_RATE_BASIS_PER_PERIOD,
          minInstalments: 1,
          maxInstalments: 6,
        ),
        finance.RoomLoanProduct(
          productId: Uint8List.fromList([
            0xab,
            0xcd,
            0xef,
            0x01,
            ...List.filled(28, 0),
          ]),
        ),
      ],
      duesProducts: [
        finance.RoomDuesProduct(
          name: 'Monthly dues',
          productId: Uint8List(32),
          amount: finance.Money(assetId: 'USDC.146', amount: '10000000'),
          everyPeriods: 1,
          memberChoice: true,
          minAmount: finance.Money(assetId: 'USDC.146', amount: '5000000'),
          maxAmount: finance.Money(assetId: 'USDC.146', amount: '50000000'),
          active: true,
        ),
        finance.RoomDuesProduct(
          name: 'Joining fee',
          productId: Uint8List.fromList(List.filled(32, 1)),
          active: true,
        ),
      ],
    );

    testWidgets('picks a loan form with its terms and passes its id', (
      tester,
    ) async {
      final transport = await pump(tester, products);
      expect(find.text('Emergency loan'), findsOneWidget);
      expect(
        find.text('up to 900.00 USDC · 3% per period · 1–6 instalments'),
        findsOneWidget,
      );
      expect(find.text('Product 0xabcdef01'), findsOneWidget);
      expect(find.text('Monthly dues'), findsNothing);

      await tester.tap(find.text('Emergency loan'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('engine-amount')), '500');
      await tester.enterText(find.byKey(const Key('engine-instalments')), '4');
      await tester.tap(find.byKey(const Key('engine-review')));
      await tester.pumpAndSettle();

      final prepare = transport
          .requestsTo(settlement.AccountService.prepareAccountCall)
          .single;
      expect(prepare.params.productId, productId);
      expect(find.textContaining('on the room’s own engine'), findsOneWidget);
      expect(find.byKey(const Key('engine-sign')), findsOneWidget);
    });

    testWidgets('offers only the dues a member may choose', (tester) async {
      await pump(tester, products, call: AccountEngineCall.chooseAmount);
      expect(find.text('Monthly dues'), findsOneWidget);
      expect(
        find.text(
          '10.00 USDC · every period · you choose 5.00 USDC–50.00 USDC',
        ),
        findsOneWidget,
      );
      expect(find.text('Joining fee'), findsNothing);
      expect(find.text('Emergency loan'), findsNothing);
    });

    testWidgets('says so when the room offers no loans', (tester) async {
      await pump(
        tester,
        finance.ListRoomProductsResponse(rulesConfigured: true),
      );
      expect(find.byKey(const Key('engine-no-products')), findsOneWidget);
    });

    testWidgets('signs nothing when the room’s engines are unknown', (
      tester,
    ) async {
      final transport = await pump(tester, products, enginesKnown: false);
      await tester.tap(find.text('Emergency loan'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('engine-amount')), '500');
      await tester.tap(find.byKey(const Key('engine-review')));
      await tester.pumpAndSettle();
      expect(find.textContaining('engines could not be read'), findsOneWidget);
      expect(find.byKey(const Key('engine-sign')), findsNothing);
      expect(transport.calls, isEmpty);
    });
  });
}
