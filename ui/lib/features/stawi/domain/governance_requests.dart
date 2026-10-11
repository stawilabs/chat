import 'dart:typed_data';

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

/// Commits a secret-ballot vote: only the commitment goes on chain; the
/// choice and salt stay on this device until the reveal.
GovernanceRequest commitVoteRequest({
  required int onchainProposalId,
  required Uint8List commitment,
}) {
  if (commitment.length != 32) {
    throw ArgumentError.value(commitment.length, 'commitment', 'must be 32');
  }
  return GovernanceRequest(
    kind: settlement.RoomCallKind.ROOM_CALL_KIND_COMMIT_VOTE,
    params: settlement.RoomCallParams(
      vote: settlement.RoomVoteParams(
        onchainProposalId: Int64(onchainProposalId),
        commitment: commitment,
      ),
    ),
    summary: 'Cast a secret vote on proposal #$onchainProposalId',
  );
}

/// Reveals a committed secret-ballot vote.
GovernanceRequest revealVoteRequest({
  required int onchainProposalId,
  required finance.VoteChoice choice,
  required Uint8List salt,
}) {
  if (salt.length != 32) {
    throw ArgumentError.value(salt.length, 'salt', 'must be 32 bytes');
  }
  return GovernanceRequest(
    kind: settlement.RoomCallKind.ROOM_CALL_KIND_REVEAL_VOTE,
    params: settlement.RoomCallParams(
      vote: settlement.RoomVoteParams(
        onchainProposalId: Int64(onchainProposalId),
        choice: choice,
        salt: salt,
      ),
    ),
    summary: 'Reveal my vote on proposal #$onchainProposalId',
  );
}

/// Proposes a principal exit: the custody's fallback spend of [amount] from
/// [sourceBucket] to a member, an approved external account or another
/// bucket (exactly one). Settlement builds the exit intent; the ballot's
/// payload hash is its digest, which the device checks before signing.
GovernanceRequest proposePrincipalExitRequest({
  required String sourceBucket,
  required String amount,
  String? memberProfileId,
  String memberName = '',
  Uint8List? externalAccount,
  String? bucket,
}) {
  final destinations = [
    memberProfileId,
    externalAccount,
    bucket,
  ].where((d) => d != null).length;
  if (destinations != 1) {
    throw ArgumentError('choose exactly one destination');
  }
  if (!RegExp(r'^[1-9][0-9]{0,77}$').hasMatch(amount)) {
    throw ArgumentError.value(amount, 'amount', 'a whole amount above zero');
  }
  if (externalAccount != null && externalAccount.length != 20) {
    throw ArgumentError.value(externalAccount, 'externalAccount', '20 bytes');
  }
  final to = memberProfileId != null
      ? memberName
      : externalAccount != null
      ? 'an external account'
      : 'the $bucket bucket';
  return GovernanceRequest(
    kind: settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE_PRINCIPAL_EXIT,
    params: settlement.RoomCallParams(
      principalExit: settlement.RoomPrincipalExitParams(
        spend: settlement.RoomExitSpend(
          sourceBucket: sourceBucket,
          amount: amount,
          member: memberProfileId == null ? null : _member(memberProfileId),
          externalAccount: externalAccount,
          bucket: bucket,
        ),
      ),
    ),
    summary: 'Propose a principal exit of $amount from $sourceBucket to $to',
  );
}

/// Proposes cancelling the principal exit ballot [cancelTarget].
GovernanceRequest proposeExitCancelRequest(int cancelTarget) {
  if (cancelTarget <= 0) {
    throw ArgumentError.value(cancelTarget, 'cancelTarget', 'positive');
  }
  return GovernanceRequest(
    kind: settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE_PRINCIPAL_EXIT,
    params: settlement.RoomCallParams(
      principalExit: settlement.RoomPrincipalExitParams(
        cancelTarget: Int64(cancelTarget),
      ),
    ),
    summary: 'Propose cancelling principal exit #$cancelTarget',
  );
}

/// Runs a passed exit (or exit-cancellation) ballot once its timelock has
/// run: permissionless, unsigned, straight to settlement.
settlement.RoomCallParams executeExitParams(int ballotId) =>
    settlement.RoomCallParams(
      principalExit: settlement.RoomPrincipalExitParams(
        ballotId: Int64(ballotId),
      ),
    );

/// Votes on the principal-exit ballot [ballotId].
GovernanceRequest votePrincipalExitRequest({
  required int ballotId,
  required bool approve,
}) {
  if (ballotId <= 0) {
    throw ArgumentError.value(ballotId, 'ballotId', 'must be positive');
  }
  return GovernanceRequest(
    kind: settlement.RoomCallKind.ROOM_CALL_KIND_VOTE_PRINCIPAL_EXIT,
    params: settlement.RoomCallParams(
      principalExit: settlement.RoomPrincipalExitParams(
        ballotId: Int64(ballotId),
        approve: approve,
      ),
    ),
    summary:
        '${approve ? 'Approve' : 'Reject'} principal exit ballot #$ballotId',
  );
}

/// An officer's approval to freeze the room.
GovernanceRequest freezeRequest(String reason) {
  final trimmed = reason.trim();
  if (trimmed.isEmpty || trimmed.length > 256) {
    throw ArgumentError.value(reason, 'reason', 'give a reason (≤ 256)');
  }
  return GovernanceRequest(
    kind: settlement.RoomCallKind.ROOM_CALL_KIND_FREEZE,
    params: settlement.RoomCallParams(
      freeze_7: settlement.RoomFreezeParams(reason: trimmed),
    ),
    summary: 'Approve freezing the room: $trimmed',
  );
}

/// RoomMembership.CAP_* bits a role may carry.
abstract final class RoomCapability {
  static const int invite = 1 << 0;
  static const int suspend = 1 << 1;
  static const int readmit = 1 << 2;
  static const int admit = 1 << 3;
  static const int freeze = 1 << 4;
  static const int lend = 1 << 5;

  static const Map<int, String> labels = {
    invite: 'Invite',
    suspend: 'Suspend',
    readmit: 'Readmit',
    admit: 'Admit',
    freeze: 'Freeze',
    lend: 'Lend',
  };
}

/// Proposes electing [name] to the constitution's role [roleId]; the members
/// vote on it.
GovernanceRequest assignRoleRequest({
  required String profileId,
  required String name,
  required String roleId,
  required String roleName,
  required int capabilities,
  DateTime? validUntil,
}) => GovernanceRequest(
  kind: settlement.RoomCallKind.ROOM_CALL_KIND_ASSIGN_ROLE,
  params: settlement.RoomCallParams(
    role: settlement.RoomRoleTerms(
      member: _member(profileId),
      roleId: roleId,
      capabilities: capabilities,
      validUntil: Int64(
        validUntil == null
            ? 0
            : validUntil.toUtc().millisecondsSinceEpoch ~/ 1000,
      ),
      assign: true,
    ),
  ),
  summary: 'Propose $name as $roleName',
);

/// Proposes removing [name] from the role [roleId].
GovernanceRequest revokeRoleRequest({
  required String profileId,
  required String name,
  required String roleId,
  required String roleName,
}) => GovernanceRequest(
  kind: settlement.RoomCallKind.ROOM_CALL_KIND_REVOKE_ROLE,
  params: settlement.RoomCallParams(
    role: settlement.RoomRoleTerms(member: _member(profileId), roleId: roleId),
  ),
  summary: 'Propose removing $name as $roleName',
);
