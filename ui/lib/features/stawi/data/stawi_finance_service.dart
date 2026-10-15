import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;

import '../domain/stawi_money.dart';
import 'stawi_clients.dart';
import 'stawi_identity.dart';

/// Reads from finance, the Stawi read model. A Stawi room's finance id is its
/// chat room id.
class StawiFinanceService {
  StawiFinanceService({
    required this._rooms,
    required this._treasury,
    required this._governance,
    required this._identity,
    this._savings,
    this._loans,
  });

  final finance.SavingsServiceClient? _savings;
  final finance.LoanServiceClient? _loans;

  finance.SavingsServiceClient get _savingsClient =>
      _savings ?? (throw StateError('no savings client'));
  finance.LoanServiceClient get _loansClient =>
      _loans ?? (throw StateError('no loans client'));

  final finance.RoomServiceClient _rooms;
  final finance.TreasuryServiceClient _treasury;
  final finance.GovernanceServiceClient _governance;
  final Future<StawiIdentity> Function() _identity;

  /// The seeded constitution templates a room can be converted with.
  Future<List<finance.PolicyTemplate>> templates() async =>
      (await _rooms.listPolicyTemplates(finance.ListPolicyTemplatesRequest()))
          .templates;

  /// The signed-in member's membership of [roomId], or null when finance has
  /// no member for them there.
  Future<finance.Member?> myMembership(String roomId) async {
    final me = await _identity();
    final members = await _rooms.listMembers(
      finance.ListMembersRequest(roomId: roomId),
    );
    return members.members
        .where((m) => m.profileId == me.profileId)
        .firstOrNull;
  }

  /// The signed-in member's own dues in [roomId], read off the chain at one
  /// block (finance GetMemberDues); null when they are not a member there.
  /// Unavailable when the chain could not be read: never zero.
  Future<finance.GetMemberDuesResponse?> myDues(String roomId) async {
    final member = await myMembership(roomId);
    if (member == null) return null;
    return _savingsClient.getMemberDues(
      finance.GetMemberDuesRequest(roomId: roomId, memberId: member.memberId),
    );
  }

  /// The room's vote on the loan ([loanBook], [pool], [loanId]) still to be
  /// decided: indexed (CREATED) or open; null when none is.
  Future<finance.Proposal?> loanVote(
    String roomId, {
    required List<int> loanBook,
    required List<int> pool,
    required Int64 loanId,
  }) async => (await _governance.listProposals(
    finance.ListProposalsRequest(
      roomId: roomId,
      loan: finance.LoanRef(loanBook: loanBook, pool: pool, loanId: loanId),
      states: const [
        finance.ProposalState.PROPOSAL_STATE_CREATED,
        finance.ProposalState.PROPOSAL_STATE_OPEN,
      ],
    ),
  )).proposals.firstOrNull;

  /// The signed-in member's statement in [roomId].
  Future<finance.Statement> myStatement(String roomId) async {
    final member = await myMembership(roomId);
    if (member == null) {
      throw StateError('You are not a member of this Stawi room yet');
    }
    return (await _treasury.getStatement(
      finance.GetStatementRequest(roomId: roomId, memberId: member.memberId),
    )).statement;
  }

  /// The room's members, as finance indexes them from the chain.
  Future<List<finance.Member>> members(String roomId) async =>
      (await _rooms.listMembers(finance.ListMembersRequest(roomId: roomId)))
          .members;

  /// Every member's money in [roomId]: indexed totals, the live book (when
  /// settlement could read it: books_available) and their loans.
  Future<finance.ListMemberBalancesResponse> memberBalances(String roomId) =>
      _savingsClient.listMemberBalances(
        finance.ListMemberBalancesRequest(roomId: roomId),
      );

  /// The room's share-outs.
  Future<List<finance.DistributionRecord>> distributions(String roomId) async =>
      (await _treasury.listDistributions(
        finance.ListDistributionsRequest(roomId: roomId),
      )).distributions;

  /// The signed-in member's share of each share-out.
  Future<List<finance.Entitlement>> myEntitlements(String roomId) async {
    final member = await myMembership(roomId);
    if (member == null) return const [];
    return (await _treasury.listEntitlements(
      finance.ListEntitlementsRequest(memberId: member.memberId),
    )).entitlements;
  }

  /// The room's loans.
  Future<List<finance.Loan>> loans(String roomId) async =>
      (await _loansClient.listLoans(finance.ListLoansRequest(roomId: roomId)))
          .loans;

  /// The assets the room's amounts name (Room.assets).
  Future<StawiAssets> roomAssets(String roomId) async => StawiAssets(
    (await _rooms.getRoom(finance.GetRoomRequest(roomId: roomId))).room.assets,
  );

  /// The asset the room saves in: its savings bucket's (else the first
  /// bucket's) settlement asset in the constitution, as Room.assets describes
  /// it; null when it has none.
  Future<StawiAsset?> roomAsset(String roomId) async {
    final buckets = (await _rooms.getPolicy(
      finance.GetPolicyRequest(roomId: roomId),
    )).policyVersion.constitution.treasury.buckets;
    final bucket =
        buckets
            .where((b) => b.name == 'savings' && b.assetIds.isNotEmpty)
            .firstOrNull ??
        buckets.where((b) => b.assetIds.isNotEmpty).firstOrNull;
    if (bucket == null) return null;
    return (await roomAssets(roomId)).of(bucket.assetIds.first);
  }

  /// The constitution's roles.
  Future<List<finance.RoleCapabilities>> roles(String roomId) async =>
      (await _rooms.getPolicy(finance.GetPolicyRequest(roomId: roomId)))
          .policyVersion
          .constitution
          .governance
          .roles;

  /// The room's proposal with on-chain number [onchainProposalId], if
  /// finance has indexed it.
  Future<finance.Proposal?> proposalByOnchainId(
    String roomId,
    int onchainProposalId,
  ) async {
    final proposals = (await _governance.listProposals(
      finance.ListProposalsRequest(roomId: roomId),
    )).proposals;
    return proposals
        .where((p) => p.onchainProposalId.toInt() == onchainProposalId)
        .firstOrNull;
  }

  Future<finance.Proposal> proposal(String proposalId) async =>
      (await _governance.getProposal(
        finance.GetProposalRequest(proposalId: proposalId),
      )).proposal;
}

final stawiFinanceServiceProvider = Provider<StawiFinanceService>((ref) {
  return StawiFinanceService(
    rooms: ref.watch(financeRoomsProvider),
    treasury: ref.watch(financeTreasuryProvider),
    governance: ref.watch(financeGovernanceProvider),
    identity: () => ref.read(stawiIdentityProvider.future),
    savings: ref.watch(financeSavingsProvider),
    loans: ref.watch(financeLoansProvider),
  );
});

final stawiTemplatesProvider =
    FutureProvider.autoDispose<List<finance.PolicyTemplate>>(
      (ref) => ref.watch(stawiFinanceServiceProvider).templates(),
    );

final stawiStatementProvider = FutureProvider.autoDispose
    .family<finance.Statement, String>(
      (ref, roomId) =>
          ref.watch(stawiFinanceServiceProvider).myStatement(roomId),
    );

/// Room-scoped finance reads for the money screens.
final stawiDistributionsProvider = FutureProvider.autoDispose
    .family<List<finance.DistributionRecord>, String>(
      (ref, roomId) =>
          ref.watch(stawiFinanceServiceProvider).distributions(roomId),
    );

final stawiEntitlementsProvider = FutureProvider.autoDispose
    .family<List<finance.Entitlement>, String>(
      (ref, roomId) =>
          ref.watch(stawiFinanceServiceProvider).myEntitlements(roomId),
    );

final stawiLoansProvider = FutureProvider.autoDispose
    .family<List<finance.Loan>, String>(
      (ref, roomId) => ref.watch(stawiFinanceServiceProvider).loans(roomId),
    );

final stawiMembersProvider = FutureProvider.autoDispose
    .family<List<finance.Member>, String>(
      (ref, roomId) => ref.watch(stawiFinanceServiceProvider).members(roomId),
    );

/// Every member's balances in a room.
final stawiMemberBalancesProvider = FutureProvider.autoDispose
    .family<finance.ListMemberBalancesResponse, String>(
      (ref, roomId) =>
          ref.watch(stawiFinanceServiceProvider).memberBalances(roomId),
    );

/// A room's proposal by its on-chain number, once finance has indexed it.
final stawiProposalByOnchainIdProvider = FutureProvider.autoDispose
    .family<finance.Proposal?, (String, int)>(
      (ref, key) => ref
          .watch(stawiFinanceServiceProvider)
          .proposalByOnchainId(key.$1, key.$2),
    );

final stawiRolesProvider = FutureProvider.autoDispose
    .family<List<finance.RoleCapabilities>, String>(
      (ref, roomId) => ref.watch(stawiFinanceServiceProvider).roles(roomId),
    );

/// The room's savings asset (symbol and decimals for amounts typed in and
/// shown without one).
final stawiRoomAssetProvider = FutureProvider.autoDispose
    .family<StawiAsset?, String>(
      (ref, roomId) => ref.watch(stawiFinanceServiceProvider).roomAsset(roomId),
    );

/// The assets a room's amounts name, from GetRoom.
final stawiRoomAssetsProvider = FutureProvider.autoDispose
    .family<StawiAssets, String>(
      (ref, roomId) =>
          ref.watch(stawiFinanceServiceProvider).roomAssets(roomId),
    );

/// The room's assets as far as they are known now: unknown while they load
/// or when finance cannot describe them, and amounts then show as "—".
StawiAssets watchRoomAssets(WidgetRef ref, String roomId) =>
    ref.watch(stawiRoomAssetsProvider(roomId)).asData?.value ??
    StawiAssets.loading;

/// The signed-in member's own dues in a room; null when not a member.
final stawiMyDuesProvider = FutureProvider.autoDispose
    .family<finance.GetMemberDuesResponse?, String>(
      (ref, roomId) => ref.watch(stawiFinanceServiceProvider).myDues(roomId),
      // An unreadable chain is said so at once, with a way to read it again.
      retry: (_, _) => null,
    );

/// A group loan's vote still to be decided, keyed by (room, loan); null when
/// the vote has not opened (or the loan has none).
final stawiLoanVoteProvider = FutureProvider.autoDispose
    .family<finance.Proposal?, ({String roomId, finance.Loan loan})>(
      (ref, key) => ref
          .watch(stawiFinanceServiceProvider)
          .loanVote(
            key.roomId,
            loanBook: key.loan.loanBook,
            pool: key.loan.pool,
            loanId: key.loan.onchainLoanId,
          ),
      retry: (_, _) => null,
    );
