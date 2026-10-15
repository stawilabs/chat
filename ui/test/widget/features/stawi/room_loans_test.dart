import 'dart:typed_data';

import 'package:connectrpc/connect.dart' as connect;
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/rooms/data/detail_panel_providers.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/data/stawi_custody.dart';
import 'package:stawi/features/stawi/data/stawi_finance_service.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/data/stawi_loan_service.dart';
import 'package:stawi/features/stawi/data/stawi_room_engines.dart';
import 'package:stawi/features/stawi/data/stawi_room_service.dart';
import 'package:stawi/features/stawi/domain/secret_ballot.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart'
    show RoomContracts;
import 'package:stawi/features/stawi/ui/group_loan_request_screen.dart';
import 'package:stawi/features/stawi/ui/room_loans_tab.dart';
import 'package:stawi/features/stawi/ui/room_money_screen.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

const roomId = 'room00000000000000aa';
const _contribute = settlement.AccountCallKind.ACCOUNT_CALL_KIND_CONTRIBUTE;

void main() {
  final vectors = {
    for (final v in GoEngineCallVector.load().where((v) => !v.personal))
      v.name: v,
  };
  final request = vectors['loan_request']!;
  final me = request.account;
  final custody = request.room;
  final productId = hexToBytes(request.json['product_id'] as String);
  final amina = Uint8List.fromList(List.filled(20, 0xa1));
  final book = Uint8List.fromList(List.filled(20, 0x10));

  finance.Money usd(int units) =>
      finance.Money(assetId: 'USDC.146', amount: '$units');

  final normal = finance.RoomLoanProduct(
    name: 'normal',
    productId: productId,
    minAmount: usd(1000000),
    maxAmount: usd(900000000),
    equityMultipleBps: 30000,
    minInstalments: 1,
    maxInstalments: 12,
    periodsPerInstalment: 1,
    interestMethod: finance
        .LoanInterestMethod
        .LOAN_INTEREST_METHOD_DECLINING_EQUAL_PRINCIPAL,
    rateBps: 200,
    rateBasis: finance.LoanRateBasis.LOAN_RATE_BASIS_PER_PERIOD,
    feeBps: 100,
    feeTiming: finance.LoanFeeTiming.LOAN_FEE_TIMING_DEDUCTED,
    officerApprovals: 2,
  );

  finance.Loan groupLoan({
    required int id,
    required List<int> borrower,
    required finance.LoanState state,
    int amount = 300000000,
  }) => finance.Loan(
    loanId: 'loan$id',
    onchainLoanId: Int64(id),
    kind: finance.LoanKind.LOAN_KIND_GROUP,
    state: state,
    loanBook: book,
    pool: custody,
    productId: productId,
    borrowerAccount: borrower,
    requested: usd(amount),
  );

  late FakeConnectTransport transport;
  late RecordingSigningGate gate;
  // The person's chain-granted capabilities; whether members can be read;
  // the loan votes finance lists.
  late List<finance.RoomCapability> caps;
  late bool membersFail;
  late List<finance.Proposal> votes;
  late finance.RoomLoanProduct product;
  // Whether submitted calls read FINAL yet; how often the room's loans and
  // its fee were read.
  late bool finalNow;
  late int loanReads;
  late List<finance.RoomProtocolFee?> fees;
  late Object Function() quote;
  // The room's governance as finance indexes it; the votes sent; the
  // choice settlement prepares (null: the one asked for).
  final governance = Uint8List.fromList(List.filled(20, 0x60));
  late RecordingActSender votesSent;
  late finance.VoteChoice? preparedChoice;

  setUp(() async {
    gate = RecordingSigningGate();
    caps = [
      finance.RoomCapability.ROOM_CAPABILITY_INVITE,
      finance.RoomCapability.ROOM_CAPABILITY_LEND,
    ];
    membersFail = false;
    votes = [];
    votesSent = RecordingActSender();
    preparedChoice = null;
    product = normal;
    finalNow = true;
    loanReads = 0;
    fees = [finance.RoomProtocolFee(incomeFeeBps: 1000)];
    quote = () => finance.QuoteLoanResponse(
      instalments: [
        for (var i = 0; i < 4; i++)
          finance.LoanInstalment(
            index: i,
            principal: usd(125000000),
            interest: usd(2500000),
            fee: usd(0),
            paid: usd(0),
          ),
      ],
      totalRepayable: usd(510000000),
      paidOut: usd(495000000),
      totalFees: usd(5000000),
      protocolFeeBps: 1000,
      protocolFeeOnInterest: usd(1500000),
    );
    transport = FakeConnectTransport()
      ..on(finance.LoanService.quoteLoan, (req) {
        final q = quote();
        if (q is Exception) throw q;
        return q as finance.QuoteLoanResponse;
      })
      ..on(
        finance.LoanService.getLoan,
        (req) => finance.GetLoanResponse(
          loan: groupLoan(
            id: req.onchainLoanId.toInt(),
            borrower: me,
            // Loan 9 is a request still waiting; the others are active.
            state: req.onchainLoanId.toInt() == 9
                ? finance.LoanState.LOAN_STATE_PENDING_APPROVAL
                : finance.LoanState.LOAN_STATE_FUNDED,
          ),
          instalments: [
            finance.LoanInstalment(
              index: 0,
              principal: usd(75000000),
              interest: usd(2500000),
              fee: usd(0),
              paid: usd(77500000),
            ),
            finance.LoanInstalment(
              index: 1,
              principal: usd(75000000),
              interest: usd(2500000),
              fee: usd(0),
              paid: usd(0),
            ),
          ],
        ),
      )
      ..on(
        finance.LoanService.getCreditRecord,
        (req) => finance.GetCreditRecordResponse(
          own: finance.CreditRecord(),
          others: finance.CreditRecord(loans: 2, onTime: 2),
        ),
      )
      ..on(
        settlement.AccountService.getAsset,
        (req) => settlement.GetAssetResponse(asset: usdcInfo),
      )
      ..on(settlement.AccountService.prepareAccountCall, (req) {
        switch (req.kind) {
          case _contribute:
            return preparedContribution(
              account: req.address,
              custody: req.params.room,
              amount: req.params.amount,
              callId: 'acct00000000000000c1',
            );
          case settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_REQUEST:
            return request.prepared(req.kind);
          case settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_APPROVE:
            return vectors['loan_approve']!.prepared(req.kind);
          case settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_PLEDGE:
            return vectors['loan_pledge']!.prepared(req.kind);
          case settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_CANCEL:
            return vectors['loan_cancel']!.prepared(req.kind);
          case settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_PAYOFF:
            return vectors['loan_payoff']!.prepared(req.kind);
          default:
            throw connect.ConnectException(connect.Code.unimplemented, '');
        }
      })
      ..on(
        settlement.AccountService.submitAccountCall,
        (req) => settlement.SubmitAccountCallResponse(
          call: settlement.AccountCall(callId: req.callId),
        ),
      )
      ..on(
        settlement.AccountService.getAccountCall,
        (req) => settlement.GetAccountCallResponse(
          call: settlement.AccountCall(
            callId: req.callId,
            state: finalNow
                ? settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL
                : settlement.AccountCallState.ACCOUNT_CALL_STATE_SUBMITTED,
          ),
        ),
      );
    transport
      ..on(finance.RoomService.listMembers, (req) {
        if (membersFail) {
          throw connect.ConnectException(connect.Code.unavailable, 'down');
        }
        return finance.ListMembersResponse(
          members: [
            finance.Member(
              memberId: 'mem1',
              profileId: 'p1',
              accountAddress: me,
              roleIds: const ['officer'],
              capabilities: caps,
            ),
            finance.Member(
              memberId: 'mem2',
              profileId: 'p2',
              accountAddress: amina,
            ),
          ],
        );
      })
      ..on(
        finance.GovernanceService.listProposals,
        (req) => finance.ListProposalsResponse(proposals: votes),
      )
      // Settlement's CAST_VOTE, built for the choice it was asked (or
      // [preparedChoice]) on the room's governance at chain 146.
      ..on(settlement.RoomService.prepareRoomCall, (req) {
        final choice = preparedChoice ?? req.params.vote.choice;
        final vote = RoomVote.cast(
          proposalId: BigInt.from(req.params.vote.onchainProposalId.toInt()),
          choice: chainChoiceOf(choice),
        );
        final deadline = BigInt.from(4102444800);
        final typed = roomVoteTypedHash(
          vote,
          verifier: governance,
          chainId: BigInt.from(146),
          member: req.account,
          nonce: BigInt.zero,
          deadline: deadline,
        );
        final digest = accountWrappedHash(req.account, BigInt.from(146), typed);
        return settlement.PrepareRoomCallResponse(
          callId: 'call0000000000000001',
          digest: digest,
          signer: req.account,
          call: settlement.RoomCall(
            callId: 'call0000000000000001',
            chainId: Int64(146),
            chatRoomId: roomId,
            kind: req.kind,
            verifier: governance,
            signer: req.account,
            deadline: Int64(deadline.toInt()),
            params: vote.params,
            typedHash: typed,
            digest: digest,
            requiresSignature: true,
          ),
        );
      });
    await serveDeployedAccount(transport, request.devicePrivateKey);
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await settle(tester);
  }

  Future<void> open(
    WidgetTester tester, {
    List<finance.Loan> loans = const [],
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 5000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Future<StawiIdentity> identity() async => identityWith('p1', me);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stawiIdentityProvider.overrideWith((ref) => identity()),
          stawiRoomAssetProvider.overrideWith((ref, id) async => usdc),
          stawiRoomAssetsProvider.overrideWith((ref, id) async => usdcAssets),
          roomProductsProvider.overrideWith(
            (ref, id) async => finance.ListRoomProductsResponse(
              rulesConfigured: true,
              calendar: finance.RoomCalendar(
                unit: finance.PeriodUnit.PERIOD_UNIT_MONTH,
                length: 1,
              ),
              loanProducts: [product],
            ),
          ),
          roomProtocolFeeProvider.overrideWith(
            (ref, id) async => fees.length > 1 ? fees.removeAt(0) : fees.first,
          ),
          stawiLoansProvider.overrideWith((ref, id) async {
            loanReads++;
            return loans;
          }),
          stawiFinanceServiceProvider.overrideWithValue(
            StawiFinanceService(
              rooms: finance.RoomServiceClient(transport),
              treasury: finance.TreasuryServiceClient(transport),
              governance: finance.GovernanceServiceClient(transport),
              savings: finance.SavingsServiceClient(transport),
              loans: finance.LoanServiceClient(transport),
              identity: identity,
            ),
          ),
          roomMembersProvider.overrideWith(
            (ref, id) async => [
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
          stawiMemberBalancesProvider.overrideWith(
            (ref, id) async => finance.ListMemberBalancesResponse(),
          ),
          roomCustodyProvider.overrideWith((ref, id) async => custody),
          stawiRoomServiceProvider.overrideWithValue(
            StawiRoomService(
              rooms: settlement.RoomServiceClient(transport),
              keys: DeviceKeyStore(
                vaultWith('p1', request.devicePrivateKey),
                gate: gate,
              ),
              identity: identity,
              send: votesSent.call,
              ballots: SecretBallotStore(MemoryDeviceKeyVault()),
              contracts: (id) async => RoomContracts(
                governance: governance,
                chainId: BigInt.from(146),
              ),
            ),
          ),
          roomEnginesProvider.overrideWith(
            (ref, id) async => request.engines(),
          ),
          stawiLoanServiceProvider.overrideWithValue(
            StawiLoanService(
              loans: finance.LoanServiceClient(transport),
              identity: identity,
            ),
          ),
          stawiAccountServiceProvider.overrideWithValue(
            StawiAccountService(
              roomAssets: testRoomAssets,
              accounts: settlement.AccountServiceClient(transport),
              keys: DeviceKeyStore(
                vaultWith('p1', request.devicePrivateKey),
                gate: gate,
              ),
              proofs: refusingSessionProofs,
              identity: identity,
              // Slow enough that a call held SUBMITTED is still followed
              // while the test looks; a FINAL call ends at its first read.
              followEvery: const Duration(milliseconds: 300),
            ),
          ),
        ],
        child: const MaterialApp(
          home: RoomMoneyScreen(
            roomId: roomId,
            roomName: 'Chama',
            initialTab: RoomMoneyScreen.loansTab,
          ),
        ),
      ),
    );
    await settle(tester);
  }

  List<settlement.PrepareAccountCallRequest> prepared() =>
      transport.requestsTo(settlement.AccountService.prepareAccountCall);

  List<settlement.SubmitAccountCallRequest> submitted() =>
      transport.requestsTo(settlement.AccountService.submitAccountCall);

  Finder inReview(String text) => find.descendant(
    of: find.byKey(const Key('money-review')),
    matching: find.text(text),
  );

  test('the vectors are one member account on one room', () {
    expect(vectors['loan_approve']!.account, me);
    expect(vectors['loan_pledge']!.account, me);
    expect(vectors['loan_approve']!.room, custody);
  });

  testWidgets('lists the loan types in plain words, each to request', (
    tester,
  ) async {
    await open(tester);
    final types = find.byKey(const Key('loans-types'));
    expect(
      find.descendant(
        of: types,
        matching: find.text(
          'Normal loan — borrow up to 3× your savings, at most 900.00 USDC; '
          'repay over 1 to 12 months; 2% interest a month on what you still '
          'owe; fee 1% taken from the payout; approved by 2 officers.',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(Key('loan-type-request-${bytesToHex0x(productId)}')),
      findsOneWidget,
    );
    expect(
      find.text('Stawi fee 10% of interest, fees and penalties'),
      findsOneWidget,
    );
  });

  testWidgets('a request is quoted with the Stawi fee, reviewed and signed', (
    tester,
  ) async {
    await open(tester);
    await tapAndSettle(
      tester,
      find.byKey(Key('loan-type-request-${bytesToHex0x(productId)}')),
    );
    expect(find.byType(GroupLoanRequestScreen), findsOneWidget);
    expect(find.text(groupRecordNote), findsOneWidget);
    await tester.enterText(find.byKey(const Key('group-loan-amount')), '500');
    await tester.enterText(
      find.byKey(const Key('group-loan-instalments')),
      '4',
    );
    await settle(tester);

    final q = transport.requestsTo(finance.LoanService.quoteLoan).last;
    expect(q.kind, finance.LoanKind.LOAN_KIND_GROUP);
    expect(q.roomId, roomId);
    expect(q.productId, productId);
    expect(q.amount, '500000000');
    expect(q.instalments, 4);
    final quoted = find.byKey(const Key('group-quote'));
    expect(
      find.descendant(
        of: quoted,
        matching: find.text('Stawi fee 10% of interest, fees and penalties'),
      ),
      findsOneWidget,
    );
    expect(
      find.text('Of the interest and fees, 1.50 USDC goes to Stawi'),
      findsOneWidget,
    );
    expect(
      find.text(
        '1: 125.00 USDC principal · 2.50 USDC interest · 0.00 USDC fee',
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('group-quote-total')),
        matching: find.text('510.00 USDC'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('group-quote-paid-out')),
        matching: find.text('495.00 USDC'),
      ),
      findsOneWidget,
    );

    await tapAndSettle(tester, find.byKey(const Key('group-loan-submit')));
    final p = prepared().single;
    expect(p.kind, settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_REQUEST);
    expect(p.params.productId, productId);
    expect(p.params.amount, '500000000');
    expect(p.params.instalments, 4);
    expect(inReview('Request a loan of 500.00 USDC'), findsOneWidget);
    expect(inReview('Stawi fee'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('money-review')),
        matching: find.textContaining('an estimate'),
      ),
      findsOneWidget,
    );
    await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
    expect(bytesToHex0x(submitted().single.authorization), request.signature);
    expect(gate.reasons, ['Request a loan of 500.00 USDC']);
    expect(find.byType(GroupLoanRequestScreen), findsNothing);
  });

  testWidgets('a quote that cannot be read offers to try again', (
    tester,
  ) async {
    quote = () => connect.ConnectException(
      connect.Code.unavailable,
      'the protocol fee could not be read',
    );
    await open(tester);
    await tapAndSettle(
      tester,
      find.byKey(Key('loan-type-request-${bytesToHex0x(productId)}')),
    );
    await tester.enterText(find.byKey(const Key('group-loan-amount')), '500');
    await tester.enterText(
      find.byKey(const Key('group-loan-instalments')),
      '4',
    );
    await settle(tester);
    expect(find.byKey(const Key('group-quote-retry')), findsOneWidget);
    expect(find.textContaining('Stawi fee 0%'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('group-loan-submit')))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    "an officer sees a request with the borrower's record, approves",
    (tester) async {
      await open(
        tester,
        loans: [
          groupLoan(
            id: 3,
            borrower: amina,
            state: finance.LoanState.LOAN_STATE_PENDING_APPROVAL,
          ),
        ],
      );
      final pending = find.byKey(const Key('pending-loan-3'));
      expect(
        find.descendant(
          of: pending,
          matching: find.text('Amina asks for 300.00 USDC'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: pending,
          matching: find.text(
            "Amina's record: 2 loans from others (2 on time); no loans from "
            'their own savings.',
          ),
        ),
        findsOneWidget,
      );
      expect(
        transport
            .requestsTo(finance.LoanService.getCreditRecord)
            .single
            .borrower,
        amina,
      );
      expect(find.byKey(const Key('loan-3-guarantee')), findsNothing);
      await tapAndSettle(tester, find.byKey(const Key('loan-3-approve')));
      expect(
        prepared().single.kind,
        settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_APPROVE,
      );
      expect(prepared().single.params.loanId, Int64(3));
      await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
      expect(
        bytesToHex0x(submitted().single.authorization),
        vectors['loan_approve']!.signature,
      );
    },
  );

  group('a request the room decides by vote', () {
    setUp(() {
      product = finance.RoomLoanProduct()
        ..mergeFromMessage(normal)
        ..officerApprovals = 0;
    });

    final pending = [
      groupLoan(
        id: 3,
        borrower: amina,
        state: finance.LoanState.LOAN_STATE_PENDING_APPROVAL,
      ),
    ];

    testWidgets('opens its vote with the proposal finance names, fixed', (
      tester,
    ) async {
      votes = [
        finance.Proposal(
          proposalId: 'prop0000000000000001',
          onchainProposalId: Int64(12),
          ballot: finance.BallotMode.BALLOT_MODE_OPEN,
          state: finance.ProposalState.PROPOSAL_STATE_CREATED,
        ),
      ];
      await open(tester, loans: pending);
      expect(find.text('Decided by a room vote'), findsOneWidget);
      expect(find.byKey(const Key('loan-3-approve')), findsNothing);
      final asked = transport
          .requestsTo(finance.GovernanceService.listProposals)
          .single;
      expect(asked.roomId, roomId);
      expect(asked.loan.loanBook, book);
      expect(asked.loan.pool, custody);
      expect(asked.loan.loanId, Int64(3));
      expect(
        asked.states,
        containsAll([
          finance.ProposalState.PROPOSAL_STATE_CREATED,
          finance.ProposalState.PROPOSAL_STATE_OPEN,
        ]),
      );

      expect(find.byKey(const Key('loan-3-vote')), findsOneWidget);
      // Yes: settlement's vote on proposal 12 is checked against the room's
      // governance, reviewed, then signed behind the lock.
      await tapAndSettle(tester, find.byKey(const Key('loan-3-vote-yes')));
      final req = transport
          .requestsTo(settlement.RoomService.prepareRoomCall)
          .single;
      expect(req.kind, settlement.RoomCallKind.ROOM_CALL_KIND_CAST_VOTE);
      expect(req.params.vote.onchainProposalId, Int64(12));
      expect(req.params.vote.choice, finance.VoteChoice.VOTE_CHOICE_APPROVE);
      expect(inReview('Vote Yes on loan request #3 in Chama'), findsOneWidget);
      expect(gate.reasons, isEmpty, reason: 'the review comes first');
      await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
      expect(gate.reasons, ['Vote Yes on loan request #3 in Chama']);
      expect(votesSent.sent.single.content['kind'], 'CAST_VOTE');
    });

    testWidgets('a No turned into a Yes by settlement is never shown or '
        'signed', (tester) async {
      votes = [
        finance.Proposal(
          proposalId: 'prop0000000000000001',
          onchainProposalId: Int64(12),
          ballot: finance.BallotMode.BALLOT_MODE_OPEN,
        ),
      ];
      preparedChoice = finance.VoteChoice.VOTE_CHOICE_APPROVE;
      await open(tester, loans: pending);
      await tapAndSettle(tester, find.byKey(const Key('loan-3-vote-no')));
      expect(find.byKey(const Key('money-review')), findsNothing);
      expect(find.textContaining('Not signed:'), findsOneWidget);
      expect(gate.reasons, isEmpty);
      expect(votesSent.sent, isEmpty);
    });

    testWidgets("says the vote hasn't opened yet when there is none", (
      tester,
    ) async {
      await open(tester, loans: pending);
      expect(find.text("The vote hasn't opened yet"), findsOneWidget);
      expect(find.byKey(const Key('loan-3-vote')), findsNothing);
      expect(find.byKey(const Key('governance-number')), findsNothing);
    });
  });

  testWidgets('Approve only for CAP_LEND: a member without it guarantees', (
    tester,
  ) async {
    caps = [finance.RoomCapability.ROOM_CAPABILITY_INVITE];
    await open(
      tester,
      loans: [
        groupLoan(
          id: 3,
          borrower: amina,
          state: finance.LoanState.LOAN_STATE_PENDING_APPROVAL,
        ),
      ],
    );
    expect(find.byKey(const Key('loan-3-approve')), findsNothing);
    expect(find.byKey(const Key('loan-3-guarantee')), findsOneWidget);
  });

  testWidgets('members that cannot be read: neither button, a retry', (
    tester,
  ) async {
    membersFail = true;
    await open(
      tester,
      loans: [
        groupLoan(
          id: 3,
          borrower: amina,
          state: finance.LoanState.LOAN_STATE_PENDING_APPROVAL,
        ),
      ],
    );
    expect(find.byKey(const Key('loan-3-approve')), findsNothing);
    expect(find.byKey(const Key('loan-3-guarantee')), findsNothing);
    expect(
      find.text('Who may approve could not be read just now'),
      findsOneWidget,
    );
    membersFail = false;
    await tapAndSettle(tester, find.byKey(const Key('loan-3-roles-retry')));
    expect(find.byKey(const Key('loan-3-approve')), findsOneWidget);
  });

  testWidgets('a member without CAP_LEND guarantees part of a request', (
    tester,
  ) async {
    caps = [finance.RoomCapability.ROOM_CAPABILITY_INVITE];
    await open(
      tester,
      loans: [
        groupLoan(
          id: 3,
          borrower: amina,
          state: finance.LoanState.LOAN_STATE_PENDING_APPROVAL,
        ),
      ],
    );
    expect(find.byKey(const Key('loan-3-approve')), findsNothing);
    await tester.enterText(
      find.byKey(const Key('loan-3-guarantee-amount')),
      '150',
    );
    await tapAndSettle(tester, find.byKey(const Key('loan-3-guarantee')));
    final p = prepared().single;
    expect(p.kind, settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_PLEDGE);
    expect(p.params.amount, '150000000');
    expect(inReview('Pledge 150.00 USDC to loan #3'), findsOneWidget);
  });

  testWidgets('my active loan: its schedule, and an instalment is a '
      'contribution', (tester) async {
    await open(
      tester,
      loans: [
        groupLoan(
          id: 1,
          borrower: me,
          state: finance.LoanState.LOAN_STATE_FUNDED,
        ),
      ],
    );
    final mine = find.byKey(const Key('loans-mine'));
    expect(
      find.descendant(
        of: mine,
        matching: find.byKey(const Key('loan-1-schedule')),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('schedule-paid-0')), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('loan-1-pay')));
    expect(inReview('Pay 77.50 USDC toward loan #1 in Chama'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('money-review')),
        matching: find.text(groupInstalmentNote),
      ),
      findsOneWidget,
    );
    await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
    final p = prepared().single;
    expect(p.kind, _contribute);
    expect(p.params.room, custody);
    expect(p.params.amount, '77500000');
    expect(submitted(), hasLength(1));
  });

  /// Holds submitted calls SUBMITTED, runs [act] (which ends signed), checks
  /// that nothing is read again and [waiting] shows until the call is FINAL,
  /// then lets it be final and checks the room's loans are read again.
  Future<void> followedToFinal(
    WidgetTester tester,
    Future<void> Function() act, {
    Finder? waiting,
  }) async {
    finalNow = false;
    await act();
    final before = loanReads;
    await settle(tester);
    expect(submitted(), isNotEmpty);
    expect(loanReads, before, reason: 'read again before the call was final');
    if (waiting != null) expect(waiting, findsOneWidget);
    finalNow = true;
    for (var i = 0; i < 4; i++) {
      await settle(tester);
    }
    expect(loanReads, greaterThan(before));
  }

  group('each action is followed to FINAL before the loans are read again', () {
    testWidgets('a request', (tester) async {
      await open(tester);
      await followedToFinal(tester, () async {
        await tapAndSettle(
          tester,
          find.byKey(Key('loan-type-request-${bytesToHex0x(productId)}')),
        );
        await tester.enterText(
          find.byKey(const Key('group-loan-amount')),
          '500',
        );
        await tester.enterText(
          find.byKey(const Key('group-loan-instalments')),
          '4',
        );
        await settle(tester);
        await tapAndSettle(tester, find.byKey(const Key('group-loan-submit')));
        await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
        // Still open, its button off, until the request is final.
        expect(find.byType(GroupLoanRequestScreen), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('group-loan-submit')))
              .onPressed,
          isNull,
        );
      });
      expect(find.byType(GroupLoanRequestScreen), findsNothing);
    });

    testWidgets('an approval', (tester) async {
      await open(
        tester,
        loans: [
          groupLoan(
            id: 3,
            borrower: amina,
            state: finance.LoanState.LOAN_STATE_PENDING_APPROVAL,
          ),
        ],
      );
      await followedToFinal(tester, () async {
        await tapAndSettle(tester, find.byKey(const Key('loan-3-approve')));
        await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
      }, waiting: find.byKey(const Key('pending-settling')));
    });

    testWidgets('a pledge', (tester) async {
      caps = [finance.RoomCapability.ROOM_CAPABILITY_INVITE];
      await open(
        tester,
        loans: [
          groupLoan(
            id: 3,
            borrower: amina,
            state: finance.LoanState.LOAN_STATE_PENDING_APPROVAL,
          ),
        ],
      );
      await followedToFinal(tester, () async {
        await tester.enterText(
          find.byKey(const Key('loan-3-guarantee-amount')),
          '150',
        );
        await tapAndSettle(tester, find.byKey(const Key('loan-3-guarantee')));
        await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
      }, waiting: find.byKey(const Key('pending-settling')));
    });

    testWidgets('a cancelled request', (tester) async {
      await open(
        tester,
        loans: [
          groupLoan(
            id: 9,
            borrower: me,
            state: finance.LoanState.LOAN_STATE_PENDING_APPROVAL,
          ),
        ],
      );
      await followedToFinal(tester, () async {
        await tapAndSettle(tester, find.byKey(const Key('loan-9-cancel')));
        expect(
          prepared().single.kind,
          settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_CANCEL,
        );
        await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
      }, waiting: find.byKey(const Key('loan-settling')));
    });

    testWidgets('an instalment', (tester) async {
      await open(
        tester,
        loans: [
          groupLoan(
            id: 1,
            borrower: me,
            state: finance.LoanState.LOAN_STATE_FUNDED,
          ),
        ],
      );
      await followedToFinal(tester, () async {
        await tapAndSettle(tester, find.byKey(const Key('loan-1-pay')));
        await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
      }, waiting: find.byKey(const Key('loan-settling')));
    });

    testWidgets('a payoff: nothing else is paid until it completes', (
      tester,
    ) async {
      await open(
        tester,
        loans: [
          groupLoan(
            id: 1,
            borrower: me,
            state: finance.LoanState.LOAN_STATE_FUNDED,
          ),
        ],
      );
      final loanReadsBefore = transport
          .requestsTo(finance.LoanService.getLoan)
          .length;
      VoidCallback? pay() => tester
          .widget<FilledButton>(find.byKey(const Key('loan-1-pay')))
          .onPressed;
      VoidCallback? payoff() => tester
          .widget<OutlinedButton>(find.byKey(const Key('loan-1-payoff')))
          .onPressed;
      await followedToFinal(tester, () async {
        await tapAndSettle(tester, find.byKey(const Key('loan-1-payoff')));
        await tapAndSettle(tester, find.byKey(const Key('engine-review')));
        await tapAndSettle(tester, find.byKey(const Key('engine-continue')));
        await tapAndSettle(tester, find.byKey(const Key('money-review-sign')));
        expect(
          prepared().last.kind,
          settlement.AccountCallKind.ACCOUNT_CALL_KIND_LOAN_PAYOFF,
        );
        // The payoff is under way: neither it nor an instalment can be paid.
        expect(pay(), isNull);
        expect(payoff(), isNull);
      }, waiting: find.byKey(const Key('loan-settling')));
      expect(pay(), isNotNull);
      expect(
        transport.requestsTo(finance.LoanService.getLoan).length,
        greaterThan(loanReadsBefore),
      );
    });
  });

  testWidgets('a Stawi fee that could not be read can be read again', (
    tester,
  ) async {
    fees = [null, finance.RoomProtocolFee(incomeFeeBps: 1000)];
    await open(tester);
    expect(find.text('Stawi fee: could not be read just now'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('protocol-fee-retry')));
    expect(
      find.text('Stawi fee 10% of interest, fees and penalties'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('protocol-fee-retry')), findsNothing);
  });
}
