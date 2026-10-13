import 'dart:async';
import 'dart:typed_data';

import 'package:connectrpc/connect.dart' as connect;
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stawi/core/networking/client.dart';
import 'package:stawi/features/rooms/data/room_providers.dart';
import 'package:stawi/features/rooms/domain/room.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/data/stawi_loan_service.dart';
import 'package:stawi/features/stawi/data/stawi_vault_service.dart';
import 'package:stawi/features/stawi/domain/loan_terms.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart'
    show bytesEqual;
import 'package:stawi/features/stawi/ui/dm_money_sheet.dart';
import 'package:stawi/features/stawi/ui/loan_detail_screen.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_api/well_known.dart' as wkt;
import 'package:stawi_api_chat/stawi_api_chat.dart' as pb;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

const _offer = settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_OFFER;
const _ask = settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_ASK;

void main() {
  final vectors = {
    for (final v in GoEngineCallVector.load().where((v) => v.personal))
      v.name: v,
  };
  final vault = hexToBytes('0x909192939495969798999a9b9c9d9e9fa0a1a2a3');
  final book = hexToBytes('0x101112131415161718191a1b1c1d1e1f20212223');
  final bob = hexToBytes('0xb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3');
  final me = vectors['offer']!.account;
  final targets = PersonalTargets.fromResponse(vault: vault, loanBooks: [book]);
  final free = Uint8List(32);
  final now = DateTime.utc(2026, 10, 13, 12);

  finance.Money usd(int units) =>
      finance.Money(amount: '$units', assetId: 'USDC.146');

  late FakeConnectTransport transport;
  late FakeConnectTransport chat;
  late RecordingSigningGate gate;

  StawiAccountService serve() {
    gate = RecordingSigningGate();
    chat = FakeConnectTransport()
      ..on(pb.ChatService.getDirectPartnerAccount, (req) {
        switch (req.roomId) {
          case 'dm-bob':
            return pb.GetDirectPartnerAccountResponse(
              profileId: 'p-bob',
              account: bob,
              deployed: true,
            );
          case 'dm-carol':
            return pb.GetDirectPartnerAccountResponse(profileId: 'p-carol');
          default:
            throw connect.ConnectException(
              connect.Code.permissionDenied,
              'not a direct message you share',
            );
        }
      });
    transport = FakeConnectTransport()
      ..on(
        finance.LoanService.listLoans,
        (req) => finance.ListLoansResponse(
          loans: [
            if (bytesEqual(req.lender, bob))
              finance.Loan(
                pool: bob,
                lender: bob,
                borrowerAccount: me,
                offeredBy: bob,
                loanBook: book,
                onchainLoanId: Int64(1),
                requested: usd(120000000),
                kind: finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON,
                state: finance.LoanState.LOAN_STATE_FUNDED,
              ),
          ],
        ),
      )
      ..on(
        finance.LoanService.quoteLoan,
        (req) => finance.QuoteLoanResponse(
          instalments: [
            finance.LoanInstalment(
              index: 0,
              dueAt: wkt.Timestamp.fromDateTime(DateTime.utc(2026, 10, 27)),
              principal: usd(75000000),
              interest: usd(7500000),
              fee: usd(0),
              paid: usd(0),
            ),
          ],
          totalRepayable: usd(330000000),
        ),
      )
      ..on(
        finance.VaultService.getVault,
        (req) => finance.GetVaultResponse(
          pockets: [
            finance.SavingsPocket(
              pocket: free,
              cash: usd(500000000),
              lent: usd(0),
            ),
          ],
        ),
      )
      ..on(
        settlement.AccountService.getAsset,
        (req) => settlement.GetAssetResponse(asset: usdcInfo),
      )
      ..on(settlement.AccountService.prepareAccountCall, (req) {
        final p = req.params;
        final amount = BigInt.parse(p.amount);
        final terms = LoanTerms(p.terms).sdk;
        final expires = BigInt.from(p.expiresAt.seconds.toInt());
        switch (req.kind) {
          case _offer:
            return vectors['offer']!.preparedFor(
              EngineCall(
                action: EngineAction.offer,
                party: p.counterparty,
                pocket: p.hasPocket() ? p.pocket : free,
                amount: amount,
                terms: terms,
                expiresAt: expires,
              ),
              req.kind,
            );
          case _ask:
            return vectors['ask']!.preparedFor(
              EngineCall(
                action: EngineAction.ask,
                party: p.counterparty,
                amount: amount,
                terms: terms,
                expiresAt: expires,
                maxRepay: maxRepayable(amount, terms),
              ),
              req.kind,
            );
          default:
            throw connect.ConnectException(connect.Code.unimplemented, '');
        }
      })
      ..on(
        settlement.AccountService.submitAccountCall,
        (req) => settlement.SubmitAccountCallResponse(
          call: settlement.AccountCall(
            callId: req.callId,
            state: settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED,
          ),
        ),
      )
      ..on(
        settlement.AccountService.getAccountCall,
        (req) => settlement.GetAccountCallResponse(
          call: settlement.AccountCall(
            callId: req.callId,
            state: settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL,
          ),
        ),
      );
    return StawiAccountService(
      accounts: settlement.AccountServiceClient(transport),
      keys: DeviceKeyStore(vaultWith('p1', anvilKey), gate: gate),
      proofs: refusingSessionProofs,
      identity: () async => identityWith('p1', me),
      targets: () async => targets,
      followEvery: const Duration(milliseconds: 10),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  List<Override> overrides(
    StawiAccountService service, {
    Future<StawiIdentity> Function()? who,
  }) {
    Future<StawiIdentity> identity() async => identityWith('p1', me);
    final client = pb.ChatServiceClient(chat);
    return [
      chatServiceClientProvider.overrideWith((ref) async => client),
      stawiIdentityProvider.overrideWith((ref) => (who ?? identity)()),
      stawiAccountServiceProvider.overrideWithValue(service),
      stawiClockProvider.overrideWithValue(() => now),
      stawiLoanServiceProvider.overrideWithValue(
        StawiLoanService(
          loans: finance.LoanServiceClient(transport),
          identity: identity,
        ),
      ),
      stawiVaultServiceProvider.overrideWithValue(
        StawiVaultService(
          vault: finance.VaultServiceClient(transport),
          identity: identity,
        ),
      ),
    ];
  }

  /// Opens the money sheet of the DM [roomId] with [name].
  Future<void> openSheet(
    WidgetTester tester,
    String roomId,
    String name,
  ) async {
    tester.view
      ..physicalSize = const Size(1080, 4000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final service = serve();
    await serveDeployedAccount(transport, anvilKey);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(service),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDmMoneySheet(
                  context,
                  roomId: roomId,
                  partnerName: name,
                ),
                child: const Text('Money'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Money'));
    await settle(tester);
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await settle(tester);
  }

  Future<void> fillTerms(WidgetTester tester) async {
    await tester.enterText(find.byKey(const Key('terms-amount')), '300');
    await tapAndSettle(
      tester,
      find.byKey(const Key('terms-preset-fortnightly4')),
    );
    await tester.enterText(find.byKey(const Key('terms-rate')), '2.5');
    await settle(tester);
  }

  Finder inReview(String text) => find.descendant(
    of: find.byKey(const Key('money-review')),
    matching: find.text(text),
  );

  group('the money button', () {
    Future<void> pumpButton(WidgetTester tester, String type) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              appBar: AppBar(
                actions: const [
                  ChatMoneyButton(roomId: 'r1', roomName: 'Chama'),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/room/:id/stawi',
            builder: (context, state) =>
                Text('stawi room ${state.pathParameters['id']}'),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          // A new scope per room type: the room is read once per scope.
          key: ValueKey(type),
          overrides: [
            roomByIdProvider('r1').overrideWith(
              (ref) async => Room(id: 'r1', name: 'Chama', type: type),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows in a DM and in a group, not in a bot room', (
      tester,
    ) async {
      await pumpButton(tester, 'direct');
      expect(find.byKey(const Key('chat-money')), findsOneWidget);
      expect(find.byTooltip('Money'), findsOneWidget);
      expect(find.byIcon(Icons.payments_outlined), findsOneWidget);

      await pumpButton(tester, 'group');
      expect(find.byKey(const Key('chat-money')), findsOneWidget);

      await pumpButton(tester, 'bot');
      expect(find.byKey(const Key('chat-money')), findsNothing);

      await pumpButton(tester, 'channel');
      expect(find.byKey(const Key('chat-money')), findsNothing);
    });

    testWidgets("in a group it opens the room's Stawi screen", (tester) async {
      await pumpButton(tester, 'group');
      await tester.tap(find.byKey(const Key('chat-money')));
      await tester.pumpAndSettle();
      expect(find.text('stawi room r1'), findsOneWidget);
    });
  });

  group('the DM money sheet', () {
    testWidgets('lists the loans between the two and opens one', (
      tester,
    ) async {
      await openSheet(tester, 'dm-bob', 'Bob');
      expect(find.byKey(const Key('dm-loans')), findsOneWidget);
      expect(find.text('From Bob'), findsOneWidget);
      expect(find.byKey(const Key('dm-lend')), findsOneWidget);
      expect(find.byKey(const Key('dm-ask')), findsOneWidget);
      // Both directions are asked, and only the pair's loans are shown.
      final asked = transport.requestsTo(finance.LoanService.listLoans);
      expect(asked, hasLength(2));

      transport.on(
        finance.LoanService.getLoan,
        (req) => finance.GetLoanResponse(
          loan: finance.Loan(
            pool: bob,
            lender: bob,
            borrowerAccount: me,
            loanBook: book,
            onchainLoanId: Int64(1),
            requested: usd(120000000),
            kind: finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON,
            state: finance.LoanState.LOAN_STATE_FUNDED,
          ),
        ),
      );
      await tapAndSettle(tester, find.text('From Bob'));
      expect(find.byType(LoanDetailScreen), findsOneWidget);
    });

    testWidgets('while who is who loads, the loans show a loader', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(1080, 4000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final service = serve();
      await serveDeployedAccount(transport, anvilKey);
      final never = Completer<StawiIdentity>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(service, who: () => never.future),
          child: const MaterialApp(
            home: Scaffold(
              body: DmMoneySheet(roomId: 'dm-bob', partnerName: 'Bob'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('No loans with Bob yet'), findsNothing);
      expect(find.byKey(const Key('dm-loans-loading')), findsOneWidget);
    });

    testWidgets('a partner without a Stawi account: a line, no buttons', (
      tester,
    ) async {
      await openSheet(tester, 'dm-carol', 'Carol');
      expect(find.text('Carol has no Stawi account yet'), findsOneWidget);
      expect(find.byKey(const Key('dm-lend')), findsNothing);
      expect(find.byKey(const Key('dm-ask')), findsNothing);
    });

    testWidgets('a partner who has not written yet: a line, no buttons', (
      tester,
    ) async {
      await openSheet(tester, 'dm-dave', 'Dave');
      expect(
        find.text('Dave needs to send you a message first'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('dm-lend')), findsNothing);
      expect(find.byKey(const Key('dm-ask')), findsNothing);
    });
  });

  group('lending and asking in a DM', () {
    testWidgets('Lend sends an offer to the partner on the terms typed', (
      tester,
    ) async {
      await openSheet(tester, 'dm-bob', 'Bob');
      await tapAndSettle(tester, find.byKey(const Key('dm-lend')));
      expect(find.byType(DmLoanScreen), findsOneWidget);
      expect(find.text('Offer open for'), findsOneWidget);
      expect(find.byKey(const Key('dm-ask-note')), findsNothing);

      await tapAndSettle(
        tester,
        find.byKey(Key('dm-pocket-${bytesToHexKey(free)}')),
      );
      await fillTerms(tester);
      // 7 days is the default.
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const Key('dm-expiry-7')))
            .selected,
        isTrue,
      );
      await tapAndSettle(tester, find.byKey(const Key('dm-loan-submit')));

      expect(inReview('Lend 300.00 USDC to Bob'), findsOneWidget);
      final req = transport
          .requestsTo(settlement.AccountService.prepareAccountCall)
          .single;
      expect(req.kind, _offer);
      expect(req.params.counterparty, bob);
      expect(req.params.hasPocket(), isFalse);
      expect(req.params.amount, '300000000');
      expect(req.params.terms.instalments, 4);
      expect(req.params.terms.everyDays, 14);
      expect(req.params.terms.rateBps, 250);
      expect(
        req.params.expiresAt.seconds.toInt(),
        now.add(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000,
      );

      await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
      expect(
        transport.requestsTo(settlement.AccountService.submitAccountCall),
        hasLength(1),
      );
      expect(gate.reasons, ['Lend 300.00 USDC to Bob']);
      expect(find.text('Offer sent to Bob'), findsOneWidget);
      expect(find.byType(DmLoanScreen), findsNothing);
    });

    testWidgets('another expiry is the clock plus those days', (tester) async {
      await openSheet(tester, 'dm-bob', 'Bob');
      await tapAndSettle(tester, find.byKey(const Key('dm-lend')));
      await tapAndSettle(
        tester,
        find.byKey(Key('dm-pocket-${bytesToHexKey(free)}')),
      );
      await fillTerms(tester);
      await tapAndSettle(tester, find.byKey(const Key('dm-expiry-3')));
      await tapAndSettle(tester, find.byKey(const Key('dm-loan-submit')));
      final req = transport
          .requestsTo(settlement.AccountService.prepareAccountCall)
          .single;
      expect(
        req.params.expiresAt.seconds.toInt(),
        now.add(const Duration(days: 3)).millisecondsSinceEpoch ~/ 1000,
      );
      await tapAndSettle(tester, find.byKey(const Key('money-review-cancel')));
      expect(
        transport.requestsTo(settlement.AccountService.submitAccountCall),
        isEmpty,
      );
    });

    testWidgets(
      'Ask to borrow sends an ask and states the ceiling and sharing',
      (tester) async {
        await openSheet(tester, 'dm-bob', 'Bob');
        await tapAndSettle(tester, find.byKey(const Key('dm-ask')));
        expect(find.text('Ask open for'), findsOneWidget);
        expect(
          find.text(
            'Asking shares your loan record with Bob until they lend, decline, '
            'or the ask ends.',
          ),
          findsOneWidget,
        );
        expect(find.byType(RadioListTile<String>), findsNothing);
        await fillTerms(tester);
        await tapAndSettle(tester, find.byKey(const Key('dm-loan-submit')));

        final req = transport
            .requestsTo(settlement.AccountService.prepareAccountCall)
            .single;
        expect(req.kind, _ask);
        expect(req.params.counterparty, bob);
        expect(inReview('Ask Bob to lend 300.00 USDC'), findsOneWidget);
        expect(inReview('At most you will repay'), findsOneWidget);
        expect(
          inReview(
            'Asking shares your loan record with Bob until they lend, decline, '
            'or the ask ends.',
          ),
          findsOneWidget,
        );
        await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
        expect(find.text('Request sent to Bob'), findsOneWidget);
      },
    );
  });
}
