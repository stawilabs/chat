import 'package:fixnum/fixnum.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;

/// One signed governance call a member asks for: what settlement prepares and
/// the line the room shows for it.
class GovernanceRequest {
  const GovernanceRequest({
    required this.kind,
    required this.summary,
    this.params,
  });

  final settlement.RoomCallKind kind;
  final settlement.RoomCallParams? params;
  final String summary;
}

settlement.RoomMemberRef _member(String profileId) =>
    settlement.RoomMemberRef(profileId: profileId);

/// An officer invites a member of the chat room onto the Stawi room.
GovernanceRequest inviteRequest({
  required String profileId,
  required String name,
}) => GovernanceRequest(
  kind: settlement.RoomCallKind.ROOM_CALL_KIND_INVITE,
  params: settlement.RoomCallParams(
    officer: settlement.RoomOfficerParams(subject: _member(profileId)),
  ),
  summary: 'Invite $name',
);

/// The invitee accepts the on-chain invitation [inviteId].
GovernanceRequest acceptInvitationRequest(int inviteId) {
  if (inviteId <= 0) {
    throw ArgumentError.value(inviteId, 'inviteId', 'must be positive');
  }
  return GovernanceRequest(
    kind: settlement.RoomCallKind.ROOM_CALL_KIND_ACCEPT_INVITATION,
    params: settlement.RoomCallParams(inviteId: Int64(inviteId)),
    summary: 'Accept invitation #$inviteId',
  );
}

/// A person's own entry into a public room; a member admits them later.
const GovernanceRequest joinRequest = GovernanceRequest(
  kind: settlement.RoomCallKind.ROOM_CALL_KIND_JOIN,
  summary: 'Ask to join the room',
);

/// Admits a self-joined member.
GovernanceRequest admitRequest({
  required String profileId,
  required String name,
}) => GovernanceRequest(
  kind: settlement.RoomCallKind.ROOM_CALL_KIND_ADMIT,
  params: settlement.RoomCallParams(
    officer: settlement.RoomOfficerParams(subject: _member(profileId)),
  ),
  summary: 'Admit $name',
);

/// The member's own departure.
const GovernanceRequest leaveRequest = GovernanceRequest(
  kind: settlement.RoomCallKind.ROOM_CALL_KIND_LEAVE,
  summary: 'Leave the room',
);

/// Proposes removing a member; the members vote on it.
GovernanceRequest proposeRemovalRequest({
  required String profileId,
  required String name,
}) => GovernanceRequest(
  kind: settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE,
  params: settlement.RoomCallParams(
    propose: settlement.RoomProposeParams(
      memberAction: settlement.RoomMemberActionTerms(
        action: finance.RoomMemberAction.ROOM_MEMBER_ACTION_REMOVE,
        subject: _member(profileId),
      ),
    ),
  ),
  summary: 'Propose removing $name',
);

/// An open-ballot vote on the on-chain proposal [onchainProposalId].
GovernanceRequest voteRequest({
  required int onchainProposalId,
  required finance.VoteChoice choice,
}) {
  if (onchainProposalId <= 0) {
    throw ArgumentError.value(
      onchainProposalId,
      'onchainProposalId',
      'must be positive',
    );
  }
  if (choice == finance.VoteChoice.VOTE_CHOICE_UNSPECIFIED) {
    throw ArgumentError.value(choice, 'choice', 'choose a vote');
  }
  final label = switch (choice) {
    finance.VoteChoice.VOTE_CHOICE_APPROVE => 'approve',
    finance.VoteChoice.VOTE_CHOICE_REJECT => 'reject',
    _ => 'abstain',
  };
  return GovernanceRequest(
    kind: settlement.RoomCallKind.ROOM_CALL_KIND_CAST_VOTE,
    params: settlement.RoomCallParams(
      vote: settlement.RoomVoteParams(
        onchainProposalId: Int64(onchainProposalId),
        choice: choice,
      ),
    ),
    summary: 'Vote $label on proposal #$onchainProposalId',
  );
}

/// Delegates the member's votes (every proposal kind) until [until].
GovernanceRequest delegateRequest({
  required String profileId,
  required String name,
  required DateTime until,
}) {
  final seconds = until.toUtc().millisecondsSinceEpoch ~/ 1000;
  if (seconds <= 0) {
    throw ArgumentError.value(until, 'until', 'must be in the future');
  }
  return GovernanceRequest(
    kind: settlement.RoomCallKind.ROOM_CALL_KIND_DELEGATE,
    params: settlement.RoomCallParams(
      delegate: settlement.RoomDelegateParams(
        to: _member(profileId),
        until: Int64(seconds),
      ),
    ),
    summary: 'Delegate votes to $name',
  );
}

const GovernanceRequest revokeDelegationRequest = GovernanceRequest(
  kind: settlement.RoomCallKind.ROOM_CALL_KIND_REVOKE_DELEGATION,
  summary: 'Revoke vote delegation',
);
