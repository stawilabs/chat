import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;

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
  }) : _rooms = rooms,
       _treasury = treasury,
       _governance = governance,
       _identity = identity;

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
