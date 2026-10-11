import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;

import '../domain/stawi_money.dart';
import 'stawi_clients.dart';
import 'stawi_identity.dart';

/// Reads from finance, the Stawi read model. A Stawi room's finance id is its
/// chat room id.
class StawiFinanceService {
  StawiFinanceService({
    required finance.RoomServiceClient rooms,
    required finance.TreasuryServiceClient treasury,
    required finance.GovernanceServiceClient governance,
    required Future<StawiIdentity> Function() identity,
    finance.SavingsServiceClient? savings,
    finance.CreditServiceClient? credit,
  }) : _rooms = rooms,
       _treasury = treasury,
       _governance = governance,
       _identity = identity,
       _savings = savings,
       _credit = credit;

  final finance.SavingsServiceClient? _savings;
  final finance.CreditServiceClient? _credit;

  finance.SavingsServiceClient get _savingsClient =>
      _savings ?? (throw StateError('no savings client'));
  finance.CreditServiceClient get _creditClient =>
      _credit ?? (throw StateError('no credit client'));

  final finance.RoomServiceClient _rooms;
  final finance.TreasuryServiceClient _treasury;
  final finance.GovernanceServiceClient _governance;
  final Future<StawiIdentity> Function() _identity;

  /// The seeded constitution templates a room can be converted with.
  Future<List<finance.PolicyTemplate>> templates() async =>
      (await _rooms.listPolicyTemplates(
        finance.ListPolicyTemplatesRequest(),
      )).templates;

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
      (await _rooms.listMembers(
        finance.ListMembersRequest(roomId: roomId),
      )).members;

  /// Every member's money in [roomId]: indexed totals, the live book (when
  /// settlement could read it: books_available) and their loans.
  Future<finance.ListMemberBalancesResponse> memberBalances(String roomId) =>
      _savingsClient.listMemberBalances(
        finance.ListMemberBalancesRequest(roomId: roomId),
      );

  /// The room's contribution periods, newest first as finance lists them.
  Future<List<finance.Period>> periods(String roomId) async =>
      (await _savingsClient.listPeriods(
        finance.ListPeriodsRequest(roomId: roomId),
      )).periods;

  /// What the signed-in member owes, per period.
  Future<List<finance.Obligation>> myObligations(String roomId) async {
    final member = await myMembership(roomId);
    if (member == null) return const [];
    return (await _savingsClient.listObligations(
      finance.ListObligationsRequest(roomId: roomId, memberId: member.memberId),
    )).obligations;
  }

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
      (await _creditClient.listLoans(
        finance.ListLoansRequest(roomId: roomId),
      )).loans;

  /// The asset the room saves in: its savings bucket's (else the first
  /// bucket's) settlement asset in the constitution; null when it has none.
  Future<StawiAsset?> roomAsset(String roomId) async {
    final buckets = (await _rooms.getPolicy(
      finance.GetPolicyRequest(roomId: roomId),
    )).policyVersion.constitution.treasury.buckets;
    final bucket =
        buckets
            .where((b) => b.name == 'savings' && b.assetIds.isNotEmpty)
            .firstOrNull ??
        buckets.where((b) => b.assetIds.isNotEmpty).firstOrNull;
    return bucket == null ? null : StawiAsset.fromId(bucket.assetIds.first);
  }

  /// The constitution's roles.
  Future<List<finance.RoleCapabilities>> roles(String roomId) async =>
      (await _rooms.getPolicy(
        finance.GetPolicyRequest(roomId: roomId),
      )).policyVersion.constitution.governance.roles;

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
    credit: ref.watch(financeCreditProvider),
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
final stawiPeriodsProvider = FutureProvider.autoDispose
    .family<List<finance.Period>, String>(
      (ref, roomId) => ref.watch(stawiFinanceServiceProvider).periods(roomId),
    );

final stawiObligationsProvider = FutureProvider.autoDispose
    .family<List<finance.Obligation>, String>(
      (ref, roomId) =>
          ref.watch(stawiFinanceServiceProvider).myObligations(roomId),
    );

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
