import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stawi/core/sync/sync_engine.dart';
import 'package:stawi/features/auth/data/user_info_provider.dart';
import 'package:stawi/features/calls/services/call_manager.dart';
import 'package:stawi/features/rooms/data/room_providers.dart';
import 'package:stawi/features/rooms/data/room_search_providers.dart';
import 'package:stawi/features/rooms/domain/room_with_last_message.dart';
import 'package:stawi/features/rooms/ui/room_list_screen.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/data/stawi_loan_service.dart';
import 'package:stawi/features/stawi/data/stawi_vault_service.dart';
import 'package:stawi/features/stawi/domain/intent_bridge.dart';
import 'package:stawi/features/stawi/domain/loan_terms.dart';
import 'package:stawi/features/stawi/ui/my_money_screen.dart';
import 'package:stawi/features/stawi/ui/savings_sheets.dart' show goalIdOf;
import 'package:stawi/widgets/app_drawer.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_api/well_known.dart' as wkt;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

const _deposit = settlement.AccountCallKind.ACCOUNT_CALL_KIND_VAULT_DEPOSIT;
const _createGoal =
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_VAULT_CREATE_GOAL;
const _borrowSelf =
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_BORROW_SELF;
const _grant = settlement.AccountCallKind.ACCOUNT_CALL_KIND_GRANT_STANDING;

void main() {
  final vectors = {
    for (final v in GoEngineCallVector.load().where((v) => v.personal))
      v.name: v,
  };
  final depositFree = GoVaultVectors.load().deposits.firstWhere(
    (d) => d.name == 'free',
  );
  final selfGrant = GoVaultVectors.load().standingGrants.firstWhere(
    (g) => g.name == 'self_flat_weekly',
  );
  final vaultAddress = hexToBytes('0x909192939495969798999a9b9c9d9e9fa0a1a2a3');
  final book = hexToBytes('0x101112131415161718191a1b1c1d1e1f20212223');
  final bob = hexToBytes('0xb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3');
  final me = vectors['offer']!.account;
  final targets = PersonalTargets.fromResponse(
    vault: vaultAddress,
    loanBooks: [book],
  );
  final schoolId = Uint8List.fromList(List.filled(32, 0x51));
  final carId = Uint8List.fromList(List.filled(32, 0x52));
  // The id the vault gives my third goal: keccak256(abi.encode(me, 2)).
  final newGoalId = goalIdOf(me, 2);
  final otherIds = [
    Uint8List.fromList(List.filled(32, 0x53)),
    Uint8List.fromList(List.filled(32, 0x54)),
  ];

  finance.Money usd(int units) =>
      finance.Money(amount: '$units', assetId: 'USDC.146');
  wkt.Timestamp inDays(int days) =>
      wkt.Timestamp.fromDateTime(DateTime.now().add(Duration(days: days)));

  finance.SavingsPocket freeSavings() => finance.SavingsPocket(
    pocket: Uint8List(32),
    cash: usd(120000000),
    lent: usd(30000000),
  );
  finance.SavingsPocket school() => finance.SavingsPocket(
    pocket: schoolId,
    cash: usd(40000000),
    lent: usd(10000000),
    isGoal: true,
    name: 'School fees',
    target: usd(200000000),
    unlockAt: inDays(30),
    loanable: true,
  );
  finance.SavingsPocket car() => finance.SavingsPocket(
    pocket: carId,
    cash: usd(10000000),
    lent: usd(0),
    isGoal: true,
    name: 'Car',
    target: usd(100000000),
    unlockAt: inDays(365),
  );

  final selfTerms = LoanTerms.preset(
    LoanPreset.weekly4,
    rateBps: 100,
    kind: finance.LoanKind.LOAN_KIND_SELF,
  );

  // The borrow-self vector's terms: 4 weekly, 1% flat, in default after 14
  // days.
  final selfTerms14 = LoanTerms(
    (finance.PersonalLoanTerms()..mergeFromMessage(selfTerms.proto))
      ..defaultAfterDays = 14,
  );

  late FakeConnectTransport transport;
  late RecordingSigningGate gate;
  late List<finance.SavingsPocket> pockets;
  // The ids the created goal shows under (more than one: two look alike).
  late List<Uint8List> createdIds;
  // The self-loan the borrow-self vector makes, once it is made.
  finance.Loan? madeSelfLoan;

  Future<StawiAccountService> serve({
    bool deployed = true,
    String balance = '75000000',
  }) async {
    createdIds = [newGoalId];
    gate = RecordingSigningGate();
    pockets = [freeSavings(), school(), car()];
    madeSelfLoan = null;
    transport = FakeConnectTransport()
      ..on(
        finance.VaultService.getVault,
        (req) =>
            finance.GetVaultResponse(pockets: pockets, vault: vaultAddress),
      )
      ..on(finance.VaultService.nameGoal, (req) => finance.NameGoalResponse())
      ..on(
        finance.VaultService.getVaultStatement,
        (req) => finance.GetVaultStatementResponse(
          entries: [
            finance.VaultStatementEntry(
              event: 'Deposited',
              pocket: Uint8List(32),
              amountIn: usd(100000000),
              at: inDays(-10),
            ),
            finance.VaultStatementEntry(
              event: 'LoanDisbursed',
              pocket: Uint8List(32),
              amountOut: usd(30000000),
              counterparty: bob,
              loanId: Int64(1),
              at: inDays(-5),
            ),
            finance.VaultStatementEntry(
              event: 'LoanRepaid',
              pocket: Uint8List(32),
              amountIn: usd(10000000),
              counterparty: bob,
              loanId: Int64(1),
              at: inDays(-1),
            ),
            finance.VaultStatementEntry(
              event: 'LoanWrittenOff',
              pocket: Uint8List(32),
              counterparty: bob,
              loanId: Int64(2),
              at: inDays(-2),
            ),
          ],
          page: finance.PageResponse(),
        ),
      )
      ..on(
        finance.LoanService.getLoan,
        (req) => finance.GetLoanResponse(loan: madeSelfLoan),
      )
      ..on(
        finance.LoanService.quoteLoan,
        (req) => finance.QuoteLoanResponse(totalRepayable: usd(208000000)),
      )
      ..on(finance.LoanService.listLoans, (req) {
        if (req.borrower.isNotEmpty) {
          return finance.ListLoansResponse(
            loans: [
              ?madeSelfLoan,
              finance.Loan(
                kind: finance.LoanKind.LOAN_KIND_SELF,
                state: finance.LoanState.LOAN_STATE_FUNDED,
                pool: me,
                lender: me,
                borrowerAccount: me,
                loanBook: book,
                onchainLoanId: Int64(4),
                requested: usd(20000000),
                terms: selfTerms.proto,
              ),
            ],
          );
        }
        return finance.ListLoansResponse(
          loans: [
            finance.Loan(
              kind: finance.LoanKind.LOAN_KIND_PERSON_TO_PERSON,
              state: finance.LoanState.LOAN_STATE_PENDING_APPROVAL,
              pool: me,
              lender: me,
              borrowerAccount: bob,
              offeredBy: me,
              loanBook: book,
              onchainLoanId: Int64(5),
              requested: usd(300000000),
            ),
          ],
        );
      })
      ..on(
        finance.LoanService.getCreditRecord,
        (req) => finance.GetCreditRecordResponse(
          own: finance.CreditRecord(loans: 3, onTime: 3),
          others: finance.CreditRecord(loans: 2, onTime: 1, late: 1),
        ),
      )
      ..on(
        settlement.AccountService.getAsset,
        (req) => settlement.GetAssetResponse(asset: usdcInfo),
      )
      ..on(settlement.AccountService.prepareAccountCall, (req) {
        switch (req.kind) {
          case _deposit:
            final i = depositFree.intent..amount = req.params.amount;
            final d = sdkIntentOf(i).digest();
            return depositFree.prepared
              ..intentDigest = d
              ..financialIntent = i
              ..call.intentDigest = d;
          case _createGoal:
            final g = req.params.goal;
            return vectors['vault_create_goal']!.preparedFor(
              EngineCall(
                action: EngineAction.vaultCreateGoal,
                goalNameHash: keccak256(utf8.encode(g.name)),
                goalTarget: BigInt.parse(g.target),
                goalUnlockAt: BigInt.parse(g.unlockAt.seconds.toString()),
                goalLoanable: g.loanable,
              ),
              req.kind,
            );
          case _borrowSelf:
            return vectors['borrow_self']!.prepared(req.kind);
          case _grant:
            return selfGrant.prepared;
          default:
            throw StateError('not faked: ${req.kind}');
        }
      })
      ..on(settlement.AccountService.submitAccountCall, (req) {
        if (req.callId == 'acct00000000000000e1') {
          madeSelfLoan = selfGrant.loan
            ..requested = usd(200000000)
            ..terms = selfTerms14.proto;
        }
        final created = transport
            .requestsTo(settlement.AccountService.prepareAccountCall)
            .where((r) => r.kind == _createGoal);
        if (created.isNotEmpty) {
          final g = created.last.params.goal;
          pockets = [
            ...pockets,
            for (final id in createdIds)
              finance.SavingsPocket(
                pocket: id,
                cash: usd(0),
                isGoal: true,
                target: usd(int.parse(g.target)),
                unlockAt: g.unlockAt,
                loanable: g.loanable,
              ),
          ];
        }
        return settlement.SubmitAccountCallResponse(
          call: settlement.AccountCall(
            callId: req.callId,
            state: settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED,
          ),
        );
      })
      ..on(
        settlement.AccountService.getAccountCall,
        (req) => settlement.GetAccountCallResponse(
          call: settlement.AccountCall(
            callId: req.callId,
            state: settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL,
          ),
        ),
      );
    if (deployed) {
      await serveDeployedAccount(
        transport,
        anvilKey,
        balance: balance,
        policyAsset: selfGrant.asset,
      );
      return StawiAccountService(
        accounts: settlement.AccountServiceClient(transport),
        keys: DeviceKeyStore(vaultWith('p1', anvilKey), gate: gate),
        proofs: refusingSessionProofs,
        identity: () async => identityWith('p1', me),
        targets: () async => targets,
        loan: (r) => finance.LoanServiceClient(transport).getLoan(
          finance.GetLoanRequest(
            pool: r.pool,
            onchainLoanId: Int64.parseInt(r.loanId.toString()),
            loanBook: r.loanBook,
          ),
        ),
        followEvery: const Duration(milliseconds: 10),
      );
    }
    final genesis = GoGenesisVector.load().firstWhere(
      (v) => v.name == 'settlement_default',
    );
    transport
      ..on(
        settlement.AccountService.getAccount,
        (req) => settlement.GetAccountResponse(
          account: settlement.AccountState(
            address: req.address,
            // Once deployment is asked for, settlement reports it under way.
            genesisState:
                transport
                    .requestsTo(settlement.AccountService.deployAccount)
                    .isEmpty
                ? ''
                : 'PENDING',
          ),
        ),
      )
      ..on(
        settlement.AccountService.prepareDeployAccount,
        (req) => genesis.prepared,
      )
      ..on(
        settlement.AccountService.deployAccount,
        (req) => settlement.DeployAccountResponse(genesisState: 'PENDING'),
      );
    return StawiAccountService(
      accounts: settlement.AccountServiceClient(transport),
      keys: DeviceKeyStore(vaultWith('p1', anvilKey), gate: gate),
      proofs: ({required Uint8List deviceAddress}) async =>
          Uint8List.fromList([1, 2, 3]),
      identity: () async => genesis.identity('p1'),
      readyEvery: const Duration(milliseconds: 10),
      readyAttempts: 3,
    );
  }

  List<Override> overrides(StawiAccountService service) {
    Future<StawiIdentity> identity() async => identityWith('p1', me);
    return [
      stawiIdentityProvider.overrideWith((ref) => identity()),
      stawiAccountServiceProvider.overrideWithValue(service),
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

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  void tall(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(1080, 6000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> open(WidgetTester tester, StawiAccountService service) async {
    tall(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(service),
        child: MaterialApp(
          home: MyMoneyScreen(
            showTestFunds: false,
            pollEvery: const Duration(milliseconds: 10),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await settle(tester);
  }

  Finder inReview(String text) => find.descendant(
    of: find.byKey(const Key('money-review')),
    matching: find.text(text),
  );

  List<settlement.PrepareAccountCallRequest> prepared() =>
      transport.requestsTo(settlement.AccountService.prepareAccountCall);

  testWidgets('shows the wallet, savings, goals, loans, record, statements', (
    tester,
  ) async {
    await open(tester, await serve());

    for (final key in [
      'money-wallet',
      'money-free',
      'money-goals',
      'money-borrow-self',
      'money-loans',
      'money-record',
      'money-statements',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    expect(find.byKey(const Key('money-setup')), findsNothing);
    expect(find.text('75.00 USDC'), findsOneWidget);
    expect(find.text('Saved: 120.00 USDC'), findsOneWidget);
    expect(find.text('Lent out: 30.00 USDC'), findsOneWidget);

    expect(find.text('School fees'), findsOneWidget);
    expect(find.text('50.00 of 200.00 USDC'), findsOneWidget);
    expect(find.text('Can be lent'), findsOneWidget);
    expect(find.textContaining('Unlocks '), findsNWidgets(2));

    expect(find.text('From my savings'), findsOneWidget);
    expect(
      find.text('From my own savings: 3 loans, 3 on time'),
      findsOneWidget,
    );
    expect(
      find.text('From others: 2 loans, 1 on time, 1 late'),
      findsOneWidget,
    );
    expect(find.textContaining('Only you see this.'), findsOneWidget);

    await tap(tester, find.byKey(const Key('loans-lent')));
    expect(find.text('To them'), findsOneWidget);

    await tap(tester, find.text('Car'));
    expect(find.byKey(const Key('goal-withdraw')), findsNothing);
    expect(find.textContaining('Locked until '), findsOneWidget);
  });

  testWidgets('an account not set up yet is set up by itself, once', (
    tester,
  ) async {
    tall(tester);
    final service = await serve(deployed: false);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(service),
        child: MaterialApp(home: MyMoneyScreen(showTestFunds: false)),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('money-setup')), findsOneWidget);
    await settle(tester);

    expect(
      transport.requestsTo(settlement.AccountService.deployAccount),
      hasLength(1),
    );
    expect(find.byKey(const Key('money-setup')), findsOneWidget);
    expect(find.byKey(const Key('account-setup-retry')), findsOneWidget);
  });

  testWidgets('adding money to free savings deposits with no pocket', (
    tester,
  ) async {
    await open(tester, await serve());

    await tap(tester, find.byKey(const Key('free-add')));
    await tester.enterText(find.byKey(const Key('amount-field')), '25');
    await tap(tester, find.byKey(const Key('amount-confirm')));

    expect(inReview('Add 25.00 USDC to Free savings'), findsOneWidget);
    await tap(tester, find.byKey(const Key('money-review-sign')));

    final request = prepared().single;
    expect(request.kind, _deposit);
    expect(request.params.hasPocket(), isFalse);
    expect(request.params.amount, '25000000');
    expect(
      transport.requestsTo(settlement.AccountService.submitAccountCall),
      hasLength(1),
    );
  });

  testWidgets('a new goal is started, then named once final', (tester) async {
    await open(tester, await serve());

    await tap(tester, find.byKey(const Key('money-new-goal')));
    await tester.enterText(find.byKey(const Key('goal-name')), 'New bike');
    await tester.enterText(find.byKey(const Key('goal-target')), '300');
    await tap(tester, find.byKey(const Key('goal-loanable')));
    await tap(tester, find.byKey(const Key('goal-create')));

    expect(inReview('Start a savings goal'), findsOneWidget);
    final goal = prepared().single.params.goal;
    expect(goal.name, 'New bike');
    expect(goal.target, '300000000');
    expect(goal.loanable, isTrue);
    expect(transport.requestsTo(finance.VaultService.nameGoal), isEmpty);

    await tap(tester, find.byKey(const Key('money-review-sign')));

    final named = transport.requestsTo(finance.VaultService.nameGoal).single;
    expect(named.name, 'New bike');
    expect(named.goalId, newGoalId);
  });

  testWidgets('a new goal that cannot be told apart is left unnamed', (
    tester,
  ) async {
    final service = await serve();
    createdIds = otherIds;
    await open(tester, service);

    await tap(tester, find.byKey(const Key('money-new-goal')));
    await tester.enterText(find.byKey(const Key('goal-name')), 'New bike');
    await tester.enterText(find.byKey(const Key('goal-target')), '300');
    await tap(tester, find.byKey(const Key('goal-create')));
    await tap(tester, find.byKey(const Key('money-review-sign')));
    // "Sent; waiting for confirmation", then "Savings goal started" once
    // final, then why it is not named.
    final unclear = find.textContaining('which one it is is not clear yet');
    for (var i = 0; i < 12 && unclear.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(seconds: 5));
      await settle(tester);
    }

    expect(transport.requestsTo(finance.VaultService.nameGoal), isEmpty);
    expect(
      find.textContaining('which one it is is not clear yet'),
      findsOneWidget,
    );
  });

  testWidgets('the wallet shows "—" when its balance is unknown', (
    tester,
  ) async {
    await open(tester, await serve(balance: ''));

    expect(
      tester.widget<Text>(find.byKey(const Key('wallet-balance'))).data,
      '—',
    );
  });

  testWidgets('borrowing from savings offers only pockets that may lend', (
    tester,
  ) async {
    await open(tester, await serve());

    await tap(tester, find.byKey(const Key('money-borrow-self')));

    expect(
      find.byKey(Key('borrow-pocket-${bytesToHex(Uint8List(32))}')),
      findsOneWidget,
    );
    expect(
      find.byKey(Key('borrow-pocket-${bytesToHex(schoolId)}')),
      findsOneWidget,
    );
    expect(find.byKey(Key('borrow-pocket-${bytesToHex(carId)}')), findsNothing);
  });

  testWidgets('a loan from my savings, then its automatic payment', (
    tester,
  ) async {
    final service = await serve();
    pockets.first.cash = usd(250000000);
    await open(tester, service);

    await tap(tester, find.byKey(const Key('money-borrow-self')));
    await tap(
      tester,
      find.byKey(Key('borrow-pocket-${bytesToHex(Uint8List(32))}')),
    );
    await tester.enterText(find.byKey(const Key('terms-amount')), '200');
    await tap(tester, find.byKey(const Key('terms-preset-weekly4')));
    await tester.enterText(find.byKey(const Key('terms-rate')), '1');
    await tap(tester, find.byKey(const Key('terms-more')));
    await tester.enterText(find.byKey(const Key('terms-default-days')), '14');
    await settle(tester);
    await tap(tester, find.byKey(const Key('borrow-self-submit')));

    expect(inReview('Borrow 200.00 USDC from my savings'), findsOneWidget);
    await tap(tester, find.byKey(const Key('money-review-sign')));

    expect(inReview('Pay automatically for this loan'), findsOneWidget);
    await tap(tester, find.byKey(const Key('money-review-sign')));

    expect([for (final r in prepared()) r.kind], [_borrowSelf, _grant]);
    expect(
      [
        for (final r in transport.requestsTo(
          settlement.AccountService.submitAccountCall,
        ))
          r.callId,
      ],
      ['acct00000000000000e1', 'acct00000000000000g1'],
    );
    expect(find.byKey(const Key('money-wallet')), findsOneWidget);
  });

  testWidgets('the statement names each movement', (tester) async {
    await open(tester, await serve());

    await tap(tester, find.byKey(const Key('money-statements')));

    expect(find.text('Added'), findsOneWidget);
    expect(find.text('Lent'), findsOneWidget);
    expect(find.text('Repaid to this pocket'), findsOneWidget);
    expect(find.text('LoanWrittenOff'), findsNothing);
    // Newest first.
    final repaid = tester.getTopLeft(find.text('Repaid to this pocket')).dy;
    final added = tester.getTopLeft(find.text('Added')).dy;
    expect(repaid, lessThan(added));
  });

  group('My money is reached', () {
    Future<void> openApp(
      WidgetTester tester,
      StawiAccountService service,
      Widget home,
    ) async {
      tall(tester);
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => home),
          GoRoute(
            path: '/money',
            builder: (_, _) => MyMoneyScreen(showTestFunds: false),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...overrides(service),
            userInfoProvider.overrideWith((ref) async => null),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await settle(tester);
    }

    testWidgets('from the chat list\'s wallet button', (tester) async {
      final service = await serve();
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const RoomListScreen()),
          GoRoute(
            path: '/money',
            builder: (_, _) => MyMoneyScreen(showTestFunds: false),
          ),
        ],
      );
      tester.view
        ..physicalSize = const Size(400, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...overrides(service),
            roomListWithMessagesProvider.overrideWith(_NoRooms.new),
            filteredRoomsProvider.overrideWith((ref) async => const []),
            connectionStateProvider.overrideWith((ref) => const Stream.empty()),
            callManagerProvider.overrideWith(
              (ref) => Completer<CallManager>().future,
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await settle(tester);

      final button = find.byKey(const Key('nav-my-money'));
      expect(button, findsOneWidget);
      expect(find.byTooltip('My money'), findsOneWidget);
      await tester.tap(button);
      await settle(tester);
      expect(find.byKey(const Key('money-wallet')), findsOneWidget);
    });

    testWidgets('from the drawer', (tester) async {
      await openApp(
        tester,
        await serve(),
        Scaffold(appBar: AppBar(), drawer: const AppDrawer()),
      );
      final state = tester.state<ScaffoldState>(find.byType(Scaffold));
      state.openDrawer();
      await settle(tester);

      await tap(tester, find.text('My money'));
      expect(find.byKey(const Key('money-wallet')), findsOneWidget);
    });
  });
}

class _NoRooms extends RoomListWithMessages {
  @override
  Future<List<RoomWithLastMessage>> build() async => const [];
}
