import 'dart:typed_data';

import 'package:connectrpc/connect.dart' as connect;
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/auth/data/current_user_provider.dart';
import 'package:stawi/features/rooms/data/detail_panel_providers.dart';
import 'package:stawi/features/stawi/data/device_key_store.dart';
import 'package:stawi/features/stawi/data/signing_gate.dart';
import 'package:stawi/features/stawi/data/stawi_account_service.dart';
import 'package:stawi/features/stawi/data/stawi_binding.dart';
import 'package:stawi/features/stawi/data/stawi_custody.dart';
import 'package:stawi/features/stawi/data/stawi_finance_service.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi/features/stawi/data/stawi_loan_service.dart';
import 'package:stawi/features/stawi/data/stawi_room_engines.dart';
import 'package:stawi/features/stawi/data/stawi_room_service.dart';
import 'package:stawi/features/stawi/domain/governance_requests.dart';
import 'package:stawi/features/stawi/domain/secret_ballot.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi/features/stawi/ui/governance_sheet.dart';
import 'package:stawi/features/stawi/ui/room_money_screen.dart';
import 'package:stawi/features/stawi/ui/stawi_room_screen.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_api/well_known.dart' as wkt;
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
  // The room as finance indexes it, and Amina's account in it.
  final room = RoomContracts(
    governance: Uint8List(20)..[0] = 0x40,
    custody: Uint8List(20)..[0] = 0x30,
    chainId: BigInt.from(146),
  );
  final amina = Uint8List(20)..[19] = 0x22;

  setUp(() async {
    transport = FakeConnectTransport()
      ..on(
        settlement.RoomService.prepareRoomCall,
        (req) =>
            {
              settlement.RoomCallKind.ROOM_CALL_KIND_COLLECT,
              settlement.RoomCallKind.ROOM_CALL_KIND_SETTLE,
              settlement.RoomCallKind.ROOM_CALL_KIND_QUEUE,
              settlement.RoomCallKind.ROOM_CALL_KIND_EXECUTE,
            }.contains(req.kind)
            ? settlement.PrepareRoomCallResponse(
                callId: 'call0000000000000001',
                call: settlement.RoomCall(chatRoomId: roomId, kind: req.kind),
              )
            : honestRoomCall(
                req,
                room: room,
                signer: account,
                chatRoomId: roomId,
              ),
      )
      ..on(
        settlement.RoomService.submitRoomCall,
        (req) => settlement.SubmitRoomCallResponse(
          call: settlement.RoomCall(callId: req.callId),
        ),
      );
    transport.on(
      settlement.AccountService.getAsset,
      (req) => settlement.GetAssetResponse(asset: usdcInfo),
    );
    await serveDeployedAccount(
      transport,
      GoEngineCallVector.load().first.devicePrivateKey,
    );
    sender = RecordingActSender();
    ballots = MemoryDeviceKeyVault();
  });

  List<Override> overrides() => [
    currentProfileIdProvider.overrideWith((ref) async => 'p1'),
    stawiRoomAssetProvider.overrideWith((ref, id) async => usdc),
    stawiRoomAssetsProvider.overrideWith((ref, id) async => usdcAssets),
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
        keys: DeviceKeyStore(vaultWith('p1', anvilKey), gate: SigningGate.open),
        identity: () async => identityWith('p1', account),
        send: sender.call,
        ballots: SecretBallotStore(ballots),
        contracts: (id) async => id == roomId ? room : null,
        memberAccounts: (id, profileId) async =>
            id == roomId && profileId == 'p2' ? amina : null,
      ),
    ),
  ];

  Future<void> openDialog(
    WidgetTester tester,
    GovernanceAction action, {
    List<Override> extra = const [],
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...overrides(), ...extra],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) =>
                      GovernanceDialog(roomId: roomId, action: action),
                ),
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

  settlement.PrepareRoomCallRequest prepared() =>
      transport.requestsTo(settlement.RoomService.prepareRoomCall).single;

  /// Signs from the dialog: what was checked is reviewed first, and only
  /// confirming it reaches the device key.
  Future<void> signAndConfirm(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('governance-sign')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('money-review')), findsOneWidget);
    expect(find.text(checkedRoomActNote), findsOneWidget);
    expect(sender.sent, isEmpty);
    await tester.tap(find.byKey(const Key('money-review-sign')));
    await tester.pumpAndSettle();
  }

  group('GovernanceDialog', () {
    testWidgets('a secret vote sends only a commitment', (tester) async {
      await openDialog(tester, GovernanceAction.secretVote);
      await tester.enterText(find.byKey(const Key('governance-number')), '9');
      await tester.tap(find.text('Reject'));
      await signAndConfirm(tester);

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
      await signAndConfirm(tester);
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
      await signAndConfirm(tester);

      final role = prepared().params.role;
      expect(
        prepared().kind,
        settlement.RoomCallKind.ROOM_CALL_KIND_ASSIGN_ROLE,
      );
      expect(role.member.account, amina);
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
      await signAndConfirm(tester);
      expect(
        prepared().kind,
        settlement.RoomCallKind.ROOM_CALL_KIND_VOTE_PRINCIPAL_EXIT,
      );
      expect(prepared().params.principalExit.ballotId, Int64(4));
      expect(prepared().params.principalExit.approve, isFalse);
    });

    testWidgets('a principal exit names its spend and is checked', (
      tester,
    ) async {
      final v = GoEngineCallVector.load().first;
      transport.on(settlement.RoomService.prepareRoomCall, (req) {
        final custody = room.custody!;
        final intent = v.intent
          ..account = custody
          ..domain.chainId = Int64(146)
          ..source = finance.ValueLocation(
            kind: finance.LocationKind.LOCATION_KIND_ROOM_CUSTODY,
            address: custody,
            bucket: req.params.principalExit.spend.sourceBucket,
          )
          ..destination = finance.ValueLocation(
            kind: finance.LocationKind.LOCATION_KIND_ROOM_CUSTODY,
            address: custody,
            bucket: req.params.principalExit.spend.bucket,
          )
          ..amount = req.params.principalExit.spend.amount;
        return honestRoomCall(
          req,
          room: room,
          signer: account,
          chatRoomId: roomId,
          exitIntent: intent,
        );
      });
      await openDialog(tester, GovernanceAction.proposeExit);
      await tester.tap(find.byKey(const Key('governance-sign')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('governance-error')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('exit-amount')), '5000');
      await tester.tap(find.text('Bucket'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('governance-text')),
        'reserve',
      );
      await signAndConfirm(tester);
      final spend = prepared().params.principalExit.spend;
      expect(spend.sourceBucket, 'savings');
      expect(spend.amount, '5000000000');
      expect(spend.bucket, 'reserve');
      expect(sender.sent.single.content['kind'], 'PROPOSE_PRINCIPAL_EXIT');
    });

    testWidgets(
      'a proposed invitation names its expiry and its execution applies it',
      (tester) async {
        await openDialog(tester, GovernanceAction.proposeInvite);
        await tester.tap(find.byKey(const Key('governance-member')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Amina').last);
        await tester.pumpAndSettle();
        await signAndConfirm(tester);

        final proposed = prepared();
        expect(proposed.kind, settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE);
        final terms = proposed.params.propose.memberAction;
        expect(
          terms.action,
          finance.RoomMemberAction.ROOM_MEMBER_ACTION_INVITE,
        );
        expect(terms.subject.account, amina);
        expect(terms.arg, isNot(Int64.ZERO), reason: 'never the default');
        final expiry = DateTime.fromMillisecondsSinceEpoch(
          terms.arg.toInt() * 1000,
          isUtc: true,
        );
        final date = inviteExpiryLabel(expiry);
        expect(
          sender.sent.single.content['summary'],
          'Propose inviting Amina (invitation expires $date UTC)',
        );

        transport
          ..calls.clear()
          ..on(
            settlement.RoomService.submitRoomCall,
            (req) => settlement.SubmitRoomCallResponse(
              call: settlement.RoomCall(
                callId: req.callId,
                inviteExpiry: terms.arg,
              ),
            ),
          );
        await tester.pumpWidget(const SizedBox());
        await openDialog(
          tester,
          GovernanceAction.executeInvite,
          extra: [
            stawiProposalByOnchainIdProvider.overrideWith(
              (ref, key) async => key == (roomId, 12)
                  ? finance.Proposal(inviteExpiry: terms.arg)
                  : null,
            ),
          ],
        );
        await tester.tap(find.byKey(const Key('governance-member')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Amina').last);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('governance-number')),
          '12',
        );
        await tester.pumpAndSettle();
        expect(
          find.text('The invitation expires $date UTC, as the proposal named.'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('governance-sign')));
        await tester.pumpAndSettle();

        final executed = prepared();
        expect(executed.kind, settlement.RoomCallKind.ROOM_CALL_KIND_EXECUTE);
        expect(executed.params.execute.onchainProposalId, Int64(12));
        final applied = executed.params.execute.memberAction;
        expect(applied.subject.profileId, 'p2');
        expect(applied.arg, Int64.ZERO, reason: 'settlement applies the vote');
        expect(
          find.text(
            'Invitation sent to the chain; the invitee can accept it '
            'until $date UTC',
          ),
          findsOneWidget,
        );
        expect(
          transport
              .requestsTo(settlement.RoomService.submitRoomCall)
              .single
              .hasSignature(),
          isFalse,
        );
      },
    );

    testWidgets('a passed proposal is queued unsigned', (tester) async {
      await openDialog(tester, GovernanceAction.queueProposal);
      await tester.enterText(find.byKey(const Key('governance-number')), '5');
      await tester.tap(find.byKey(const Key('governance-sign')));
      await tester.pumpAndSettle();
      expect(prepared().kind, settlement.RoomCallKind.ROOM_CALL_KIND_QUEUE);
      expect(prepared().params.execute.onchainProposalId, Int64(5));
      expect(prepared().params.execute.hasMemberAction(), isFalse);
      expect(sender.sent, isEmpty);
    });

    testWidgets('a passed exit is run straight on settlement', (tester) async {
      transport.on(
        settlement.RoomService.prepareRoomCall,
        (req) => settlement.PrepareRoomCallResponse(
          callId: 'call0000000000000002',
          call: settlement.RoomCall(kind: req.kind),
        ),
      );
      await openDialog(tester, GovernanceAction.executeExit);
      await tester.enterText(find.byKey(const Key('governance-number')), '7');
      await tester.tap(find.byKey(const Key('governance-sign')));
      await tester.pumpAndSettle();
      expect(
        prepared().kind,
        settlement.RoomCallKind.ROOM_CALL_KIND_EXECUTE_PRINCIPAL_EXIT,
      );
      expect(prepared().params.principalExit.ballotId, Int64(7));
      expect(
        transport.requestsTo(settlement.RoomService.submitRoomCall),
        hasLength(1),
      );
      expect(sender.sent, isEmpty);
    });
  });

  group('RoomMoneyScreen', () {
    final payoff = GoEngineCallVector.load().firstWhere(
      (v) => v.name == 'loan_payoff',
    );
    final custody = payoff.room;

    // What GetMemberDues answers: a response, or an exception to throw.
    late Object Function() dues;

    setUp(() {
      dues = () => finance.GetMemberDuesResponse(
        dues: finance.MemberDues(memberId: 'mem1', rulesConfigured: false),
      );
      transport
        ..on(
          finance.RoomService.listMembers,
          (req) => finance.ListMembersResponse(
            members: [finance.Member(memberId: 'mem1', profileId: 'p1')],
          ),
        )
        ..on(finance.SavingsService.getMemberDues, (req) {
          final d = dues();
          if (d is Exception) throw d;
          return d as finance.GetMemberDuesResponse;
        });
    });

    Future<void> pump(
      WidgetTester tester, {
      finance.ListMemberBalancesResponse? balances,
      finance.ListRoomProductsResponse? products,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...overrides(),
            roomProductsProvider.overrideWith(
              (ref, id) async => products ?? finance.ListRoomProductsResponse(),
            ),
            roomProtocolFeeProvider.overrideWith(
              (ref, id) async => finance.RoomProtocolFee(incomeFeeBps: 1000),
            ),
            stawiMembersProvider.overrideWith((ref, id) async => []),
            stawiFinanceServiceProvider.overrideWithValue(
              StawiFinanceService(
                rooms: finance.RoomServiceClient(transport),
                treasury: finance.TreasuryServiceClient(transport),
                governance: finance.GovernanceServiceClient(transport),
                savings: finance.SavingsServiceClient(transport),
                loans: finance.LoanServiceClient(transport),
                identity: () async => identityWith('p1', payoff.account),
              ),
            ),
            stawiClockProvider.overrideWithValue(
              () => DateTime.utc(2026, 10, 13),
            ),
            stawiLoanServiceProvider.overrideWithValue(
              StawiLoanService(
                loans: finance.LoanServiceClient(transport),
                identity: () async => identityWith('p1', payoff.account),
              ),
            ),
            stawiEntitlementsProvider.overrideWith(
              (ref, id) async => [
                finance.Entitlement(
                  amount: finance.Money(
                    assetId: 'USDC.146',
                    amount: '75000000',
                  ),
                ),
              ],
            ),
            stawiDistributionsProvider.overrideWith((ref, id) async => []),
            stawiLoansProvider.overrideWith(
              (ref, id) async => [
                finance.Loan(
                  loanId: 'loan1',
                  onchainLoanId: Int64(1),
                  kind: finance.LoanKind.LOAN_KIND_GROUP,
                  state: finance.LoanState.LOAN_STATE_FUNDED,
                  loanBook: List.filled(20, 0x10),
                  pool: custody,
                  borrowerAccount: payoff.account,
                  requested: finance.Money(
                    assetId: 'USDC.146',
                    amount: '900000000',
                  ),
                  repaidInterest: finance.Money(
                    assetId: 'USDC.146',
                    amount: '12500000',
                  ),
                  instalments: 4,
                ),
              ],
            ),
            stawiMemberBalancesProvider.overrideWith(
              (ref, id) async =>
                  balances ??
                  finance.ListMemberBalancesResponse(
                    booksAvailable: true,
                    balances: [
                      finance.MemberBalance(
                        memberId: 'mem1',
                        profileId: 'p2',
                        membershipState: 'ACTIVE',
                        contributed: finance.Money(
                          assetId: 'USDC.146',
                          amount: '1234560000',
                        ),
                        book: finance.MemberBook(
                          credit: finance.Money(
                            assetId: 'USDC.146',
                            amount: '300000000',
                          ),
                          standing: finance
                              .MemberDuesStanding
                              .MEMBER_DUES_STANDING_IN_ARREARS,
                        ),
                        loansOutstanding: finance.Money(
                          assetId: 'USDC.146',
                          amount: '450000000',
                        ),
                      ),
                    ],
                  ),
            ),
            stawiIdentityProvider.overrideWith(
              (ref) async => identityWith('p1', payoff.account),
            ),
            roomCustodyProvider.overrideWith((ref, id) async => custody),
            roomEnginesProvider.overrideWith(
              (ref, id) async => payoff.engines(),
            ),
            stawiAccountServiceProvider.overrideWithValue(
              StawiAccountService(
                roomAssets: testRoomAssets,
                accounts: settlement.AccountServiceClient(transport),
                keys: DeviceKeyStore(
                  vaultWith('p1', payoff.devicePrivateKey),
                  gate: SigningGate.open,
                ),
                proofs: refusingSessionProofs,
                identity: () async => identityWith('p1', payoff.account),
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

    testWidgets('settles dues through the rules engine', (tester) async {
      await pump(tester);
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
      expect(find.text('75.00 USDC'), findsOneWidget);
      await tester.tap(find.byKey(const Key('money-collect')));
      await tester.pumpAndSettle();
      expect(prepared().kind, settlement.RoomCallKind.ROOM_CALL_KIND_COLLECT);
    });

    testWidgets('a payoff shows the quoted ceiling before signing', (
      tester,
    ) async {
      transport
        ..on(
          settlement.AccountService.prepareAccountCall,
          (req) => payoff.prepared(req.kind),
        )
        ..on(
          settlement.AccountService.submitAccountCall,
          (req) => settlement.SubmitAccountCallResponse(
            call: settlement.AccountCall(callId: req.callId),
          ),
        );
      await pump(tester);
      await tester.tap(find.text('Loans'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('my-loan-1')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('loan-1-payoff')));
      await tester.tap(find.byKey(const Key('loan-1-payoff')));
      await tester.pumpAndSettle();

      // No loan-number input: the loan is the one tapped.
      expect(find.byKey(const Key('engine-loan')), findsNothing);
      await tester.tap(find.byKey(const Key('engine-review')));
      await tester.pumpAndSettle();
      final prepare = transport
          .requestsTo(settlement.AccountService.prepareAccountCall)
          .single;
      expect(prepare.params.loanId, Int64(1));
      expect(prepare.params.hasAmount(), isFalse);
      // The credit could not be read, so the dialog says so before the review.
      expect(find.byKey(const Key('payoff-top-up-notice')), findsOneWidget);
      await tester.tap(find.byKey(const Key('engine-continue')));
      await tester.pumpAndSettle();
      expect(find.text('Pays at most'), findsOneWidget);
      expect(find.text('520.00 USDC'), findsOneWidget);
      expect(
        transport.requestsTo(settlement.AccountService.submitAccountCall),
        isEmpty,
      );

      await tester.tap(find.byKey(const Key('money-review-sign')));
      await tester.pumpAndSettle();
      final submit = transport
          .requestsTo(settlement.AccountService.submitAccountCall)
          .single;
      expect(bytesToHex0x(submit.authorization), payoff.signature);
    });

    testWidgets('a payoff asks for what the available credit lacks first', (
      tester,
    ) async {
      transport
        ..on(settlement.AccountService.prepareAccountCall, (req) {
          if (req.kind !=
              settlement.AccountCallKind.ACCOUNT_CALL_KIND_CONTRIBUTE) {
            return payoff.prepared(req.kind);
          }
          return preparedContribution(
            account: req.address,
            custody: req.params.room,
            amount: req.params.amount,
            callId: 'acct00000000000000c1',
          );
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
              state: settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL,
            ),
          ),
        );
      await pump(
        tester,
        balances: finance.ListMemberBalancesResponse(
          booksAvailable: true,
          balances: [
            finance.MemberBalance(
              memberId: 'mem1',
              profileId: 'p1',
              account: payoff.account,
              // 5 USDC of credit against the cycle's 10 USDC of dues and
              // 5 USDC of penalties: none is left for the payoff, and new
              // money pays the 10 USDC the credit lacks for the claims first.
              book: finance.MemberBook(
                credit: finance.Money(assetId: 'USDC.146', amount: '5000000'),
                duesPayable: finance.Money(
                  assetId: 'USDC.146',
                  amount: '10000000',
                ),
                penaltiesOwed: finance.Money(
                  assetId: 'USDC.146',
                  amount: '5000000',
                ),
                creditAvailable: finance.Money(
                  assetId: 'USDC.146',
                  amount: '0',
                ),
              ),
            ),
          ],
        ),
      );
      await tester.tap(find.text('Loans'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('loan-1-payoff')));
      await tester.tap(find.byKey(const Key('loan-1-payoff')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('engine-review')));
      await tester.pumpAndSettle();

      // The payoff's 520 USDC ceiling plus the 10 USDC of claims the credit
      // does not cover.
      expect(
        find.textContaining(
          'Pay in 530.00 USDC first. The payoff takes up to 520.00 USDC and '
          'your credit in the room is 5.00 USDC; a settle takes dues of '
          '10.00 USDC and penalties of 5.00 USDC from it first.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('money-review')), findsNothing);
      await tester.tap(find.byKey(const Key('payoff-top-up')));
      await tester.pumpAndSettle();
      // The top-up is reviewed and signed like any other money.
      await tester.tap(find.byKey(const Key('money-review-sign')));
      await tester.pumpAndSettle();

      final contribute = transport
          .requestsTo(settlement.AccountService.prepareAccountCall)
          .last;
      expect(
        contribute.kind,
        settlement.AccountCallKind.ACCOUNT_CALL_KIND_CONTRIBUTE,
      );
      expect(contribute.params.room, custody);
      expect(contribute.params.amount, '530000000');
      expect(find.textContaining('Top-up received'), findsOneWidget);

      await tester.tap(find.byKey(const Key('engine-continue')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('money-review-sign')));
      await tester.pumpAndSettle();
      final submits = transport.requestsTo(
        settlement.AccountService.submitAccountCall,
      );
      expect(submits, hasLength(2));
      expect(bytesToHex0x(submits.last.authorization), payoff.signature);
    });

    finance.MemberProductDues productDues({
      required int id,
      required String name,
      required int owedNow,
      int? nextAmount,
      int? owedThen,
    }) => finance.MemberProductDues(
      productId: Uint8List.fromList(List.filled(32, id)),
      name: name,
      owedNow: finance.Money(assetId: 'USDC.146', amount: '$owedNow'),
      nextDueAt: nextAmount == null
          ? null
          : wkt.Timestamp.fromDateTime(DateTime.utc(2026, 11, 5, 21)),
      nextDueAmount: nextAmount == null
          ? null
          : finance.Money(assetId: 'USDC.146', amount: '$nextAmount'),
      owedAtNextDue: owedThen == null
          ? null
          : finance.Money(assetId: 'USDC.146', amount: '$owedThen'),
    );

    testWidgets('My dues: each product from GetMemberDues, paid ahead too', (
      tester,
    ) async {
      dues = () => finance.GetMemberDuesResponse(
        dues: finance.MemberDues(
          memberId: 'mem1',
          rulesConfigured: true,
          calendar: finance.RoomCalendar(tzOffsetSeconds: 3 * 3600),
          products: [
            productDues(
              id: 1,
              name: 'Savings',
              owedNow: 20000000,
              nextAmount: 100000000,
              owedThen: 120000000,
            ),
            productDues(
              id: 2,
              name: 'Welfare',
              owedNow: 0,
              nextAmount: 10000000,
              owedThen: 0,
            ),
            productDues(id: 3, name: 'Joining fee', owedNow: 0),
          ],
          penaltiesOwed: finance.Money(assetId: 'USDC.146', amount: '1000000'),
          standing: finance.MemberDuesStanding.MEMBER_DUES_STANDING_IN_ARREARS,
        ),
        assets: [usdcInfo],
      );
      await pump(tester);
      final asked = transport
          .requestsTo(finance.SavingsService.getMemberDues)
          .single;
      expect(asked.roomId, roomId);
      expect(asked.memberId, 'mem1');
      final savings = find.byKey(
        Key('my-dues-${bytesToHex0x(List.filled(32, 1))}'),
      );
      Finder inSavings(String t) =>
          find.descendant(of: savings, matching: find.text(t));
      expect(inSavings('Owed now'), findsOneWidget);
      expect(inSavings('20.00 USDC'), findsOneWidget);
      // 21:00 UTC is the next day in a room three hours ahead.
      expect(inSavings('Next due Nov 6, 2026'), findsOneWidget);
      expect(inSavings('100.00 USDC'), findsOneWidget);
      expect(inSavings('To pay by then'), findsOneWidget);
      expect(inSavings('120.00 USDC'), findsOneWidget);
      final welfare = find.byKey(
        Key('my-dues-${bytesToHex0x(List.filled(32, 2))}'),
      );
      expect(
        find.descendant(of: welfare, matching: find.text('Paid ahead')),
        findsOneWidget,
      );
      expect(find.text('Nothing more falls due'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('my-dues-penalties')),
          matching: find.text('1.00 USDC'),
        ),
        findsOneWidget,
      );
      expect(find.text('You are behind with your dues'), findsOneWidget);
      expect(find.textContaining("The room's next due date"), findsNothing);
    });

    testWidgets('My dues that cannot be read say so, never zero', (
      tester,
    ) async {
      dues = () => connect.ConnectException(
        connect.Code.unavailable,
        'the chain could not be read',
      );
      await pump(tester);
      expect(
        find.descendant(
          of: find.byKey(const Key('my-dues-unavailable')),
          matching: find.text('could not be read just now'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('my-dues')),
          matching: find.textContaining('0.00'),
        ),
        findsNothing,
      );
      dues = () => finance.GetMemberDuesResponse(
        dues: finance.MemberDues(memberId: 'mem1', rulesConfigured: false),
      );
      await tester.tap(find.byKey(const Key('my-dues-retry')));
      await tester.pumpAndSettle();
      expect(find.text('This room has no dues yet'), findsOneWidget);
    });

    testWidgets('a refused check stops before signing', (tester) async {
      final pledge = GoEngineCallVector.load().firstWhere(
        (v) => v.name == 'loan_pledge',
      );
      transport.on(
        settlement.AccountService.prepareAccountCall,
        (req) => pledge.prepared(req.kind),
      );
      await pump(tester);
      await tester.tap(find.text('Savings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('engine-withdrawCredit')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('engine-amount')), '10');
      await tester.tap(find.byKey(const Key('engine-review')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Not signed'), findsOneWidget);
      expect(find.byKey(const Key('money-review')), findsNothing);
    });

    testWidgets('lists members with their balances and books', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Members'));
      await tester.pumpAndSettle();
      // The room's member list names p2; no raw profile id is shown.
      expect(find.text('Amina'), findsOneWidget);
      expect(find.text('p2'), findsNothing);
      expect(find.textContaining('contributed 1,234.56 USDC'), findsOneWidget);
      expect(find.textContaining('in arrears'), findsOneWidget);
      await tester.tap(find.byKey(const Key('member-mem1')));
      await tester.pumpAndSettle();
      expect(find.text('300.00 USDC'), findsOneWidget);
      expect(find.text('450.00 USDC'), findsOneWidget);
      expect(find.byKey(const Key('books-unavailable')), findsNothing);
    });

    testWidgets('says when live books are unavailable', (tester) async {
      await pump(
        tester,
        balances: finance.ListMemberBalancesResponse(
          booksAvailable: false,
          balances: [finance.MemberBalance(memberId: 'mem1', profileId: 'p2')],
        ),
      );
      await tester.tap(find.text('Members'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('books-unavailable')), findsOneWidget);
    });
  });

  group('StawiRoomScreen from the chat binding', () {
    Future<void> pump(WidgetTester tester, StawiBinding? binding) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            stawiBindingProvider.overrideWith((ref, id) async => binding),
            stawiPendingRevealsProvider.overrideWith((ref, id) async => []),
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
