import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import 'proposal_documents.dart';
import 'secret_ballot.dart';
import 'signing_checks.dart';
import 'stawi_money.dart' show formatBps;

/// Builds the act the person chose as the SDK checks it: from the room's
/// contracts as finance knows them and, for the parts only the chain fixes
/// (an exit intent, an invitation's hash), settlement's prepared call.
typedef ExpectedRoomCall = RoomCallExpected Function(
  RoomContracts room,
  settlement.PrepareRoomCallResponse prepared,
);

/// One signed governance call a member asks for: what settlement prepares,
/// the act the device checks it against before signing, and what the person
/// is shown first.
class GovernanceRequest {
  const GovernanceRequest({
    required this.kind,
    required this.summary,
    required this.expected,
    this.params,
    this.lines = const [],
    this.linesOf,
  });

  final settlement.RoomCallKind kind;
  final settlement.RoomCallParams? params;

  /// The line the room shows and the review's title.
  final String summary;

  /// The act as the person chose it (stawi_finance_sdk RoomCallExpected).
  final ExpectedRoomCall expected;

  /// What the review lists.
  final List<(String, String)> lines;

  /// Review lines read off the checked call (an invitation's expiry).
  final List<(String, String)> Function(
    settlement.PrepareRoomCallResponse prepared,
  )?
  linesOf;
}

settlement.RoomMemberRef _member(Uint8List account) =>
    settlement.RoomMemberRef(account: account);

/// A 20-byte account shown short: 0x1234…abcd.
String shortAccount(List<int> account) {
  final hex = bytesToHex0x(account);
  return hex.length <= 12
      ? hex
      : '${hex.substring(0, 6)}…${hex.substring(hex.length - 4)}';
}

Uint8List _custody(RoomContracts room) =>
    room.custody ?? (throw const SigningRefused(roomContractsUnknownReason));

/// How long an officer's invitation stands.
const Duration officerInviteValidity = Duration(days: 7);

/// How far the expiry settlement fixes from its own clock may drift from
/// the device's.
const Duration inviteClockSlack = Duration(minutes: 10);

BigInt _seconds(DateTime t) =>
    BigInt.from(t.toUtc().millisecondsSinceEpoch ~/ 1000);

/// An officer invites [name] (their account [account]) onto the Stawi room.
/// The invitation stands [officerInviteValidity] from settlement's clock;
/// the device takes an expiry within [inviteClockSlack] of its own.
GovernanceRequest inviteRequest({
  required Uint8List account,
  required String name,
  DateTime? now,
}) {
  final at = (now ?? DateTime.now()).add(officerInviteValidity);
  return GovernanceRequest(
    kind: settlement.RoomCallKind.ROOM_CALL_KIND_INVITE,
    params: settlement.RoomCallParams(
      officer: settlement.RoomOfficerParams(
        subject: _member(account),
        inviteValidSeconds: officerInviteValidity.inSeconds,
      ),
    ),
    summary: 'Invite $name',
    expected: (room, prepared) => RoomCallExpected.invite(
      subject: account,
      expiresNotBefore: _seconds(at.subtract(inviteClockSlack)),
      expiresNotAfter: _seconds(at.add(inviteClockSlack)),
    ),
    lines: [('Member', name), ('Account', shortAccount(account))],
    linesOf: (prepared) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(
        roomCallWord(prepared, 2).toInt() * 1000,
        isUtc: true,
      );
      return [('Invitation expires', '${inviteExpiryLabel(expiry)} UTC')];
    },
  );
}

/// The longest an invitation may stand, in days (settlement's MaxInviteTTL).
const int maxInviteDays = 30;

/// An invitation's expiry [days] days from [now], to the second. The
/// proposal commits to it; executing the passed proposal applies it.
DateTime inviteExpiryAfter(int days, {DateTime? now}) {
  if (days < 1 || days >= maxInviteDays) {
    throw ArgumentError.value(days, 'days', '1 to ${maxInviteDays - 1}');
  }
  final t = (now ?? DateTime.now()).toUtc().add(Duration(days: days));
  return DateTime.fromMillisecondsSinceEpoch(
    t.millisecondsSinceEpoch ~/ 1000 * 1000,
    isUtc: true,
  );
}

/// An invitation expiry as people read it, in UTC: "2026-10-31 18:30".
String inviteExpiryLabel(DateTime expiresAt) {
  final t = expiresAt.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.year}-${two(t.month)}-${two(t.day)} '
      '${two(t.hour)}:${two(t.minute)}';
}

/// The expiry settlement or finance reports (unix seconds); null for 0, which
/// names none.
DateTime? inviteExpiryFromSeconds(Int64 seconds) => seconds <= Int64.ZERO
    ? null
    : DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000, isUtc: true);

Int64 _inviteExpirySeconds(DateTime expiresAt) {
  final seconds = expiresAt.toUtc().millisecondsSinceEpoch ~/ 1000;
  if (seconds <= 0) {
    throw ArgumentError.value(expiresAt, 'expiresAt', 'name the expiry');
  }
  return Int64(seconds);
}

settlement.RoomMemberActionTerms _inviteTerms(
  Uint8List account,
  DateTime expiresAt,
) => settlement.RoomMemberActionTerms(
  action: finance.RoomMemberAction.ROOM_MEMBER_ACTION_INVITE,
  subject: _member(account),
  arg: _inviteExpirySeconds(expiresAt),
);

/// Proposes inviting [name] (their account [account]); the members vote on
/// it. The proposal commits to the invitation's expiry named here.
GovernanceRequest proposeInviteRequest({
  required Uint8List account,
  required String name,
  required DateTime expiresAt,
}) {
  final terms = _inviteTerms(account, expiresAt);
  return GovernanceRequest(
    kind: settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE,
    params: settlement.RoomCallParams(
      propose: settlement.RoomProposeParams(memberAction: terms),
    ),
    summary:
        'Propose inviting $name (invitation expires '
        '${inviteExpiryLabel(expiresAt)} UTC)',
    expected: (room, prepared) => RoomCallExpected.proposeMemberAction(
      custody: _custody(room),
      action: MemberActions.invite,
      subject: account,
      arg: BigInt.from(terms.arg.toInt()),
    ),
    lines: [
      ('Member', name),
      ('Account', shortAccount(account)),
      ('Invitation expires', '${inviteExpiryLabel(expiresAt)} UTC'),
    ],
  );
}

/// Queues the passed proposal [onchainProposalId] for execution once its
/// timelock runs: permissionless, unsigned, straight to settlement.
settlement.RoomCallParams queueProposalParams(int onchainProposalId) {
  if (onchainProposalId <= 0) {
    throw ArgumentError.value(onchainProposalId, 'onchainProposalId', '> 0');
  }
  return settlement.RoomCallParams(
    execute: settlement.RoomExecuteParams(
      onchainProposalId: Int64(onchainProposalId),
    ),
  );
}

/// Executes a passed invitation proposal for the member it named. The expiry
/// is left 0: settlement applies the one the proposal carried.
settlement.RoomCallParams executeInviteParams({
  required int onchainProposalId,
  required String profileId,
}) {
  if (onchainProposalId <= 0) {
    throw ArgumentError.value(onchainProposalId, 'onchainProposalId', '> 0');
  }
  return settlement.RoomCallParams(
    execute: settlement.RoomExecuteParams(
      onchainProposalId: Int64(onchainProposalId),
      memberAction: settlement.RoomMemberActionTerms(
        action: finance.RoomMemberAction.ROOM_MEMBER_ACTION_INVITE,
        subject: settlement.RoomMemberRef(profileId: profileId),
      ),
    ),
  );
}

/// The invitee accepts the on-chain invitation [inviteId]. Its hash is
/// RoomCustody.inviteHash(inviteId): settlement reads it off the chain and
/// the contract recomputes it from its own storage, so it is taken from the
/// call; the act, the invitation and the room are the person's.
GovernanceRequest acceptInvitationRequest(int inviteId) {
  if (inviteId <= 0) {
    throw ArgumentError.value(inviteId, 'inviteId', 'must be positive');
  }
  return GovernanceRequest(
    kind: settlement.RoomCallKind.ROOM_CALL_KIND_ACCEPT_INVITATION,
    params: settlement.RoomCallParams(inviteId: Int64(inviteId)),
    summary: 'Accept invitation #$inviteId',
    expected: (room, prepared) {
      final p = prepared.call.params;
      if (p.length != 64) {
        throw const SigningRefused(
          'settlement prepared something else: not the act you chose',
        );
      }
      return RoomCallExpected.acceptInvitation(
        inviteId: BigInt.from(inviteId),
        inviteHash: p.sublist(32),
      );
    },
    lines: [('Invitation', '#$inviteId')],
  );
}

/// A person's own entry into a public room; a member admits them later.
final GovernanceRequest joinRequest = GovernanceRequest(
  kind: settlement.RoomCallKind.ROOM_CALL_KIND_JOIN,
  summary: 'Ask to join the room',
  expected: (room, prepared) => RoomCallExpected.join(),
);

/// Admits the self-joined [name] (their account [account]).
GovernanceRequest admitRequest({
  required Uint8List account,
  required String name,
}) => GovernanceRequest(
  kind: settlement.RoomCallKind.ROOM_CALL_KIND_ADMIT,
  params: settlement.RoomCallParams(
    officer: settlement.RoomOfficerParams(subject: _member(account)),
  ),
  summary: 'Admit $name',
  expected: (room, prepared) => RoomCallExpected.admit(subject: account),
  lines: [('Member', name), ('Account', shortAccount(account))],
);

/// The member's own departure.
final GovernanceRequest leaveRequest = GovernanceRequest(
  kind: settlement.RoomCallKind.ROOM_CALL_KIND_LEAVE,
  summary: 'Leave the room',
  expected: (room, prepared) => RoomCallExpected.leave(),
);

/// Proposes removing [name] (their account [account]); the members vote on
/// it.
GovernanceRequest proposeRemovalRequest({
  required Uint8List account,
  required String name,
}) => GovernanceRequest(
  kind: settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE,
  params: settlement.RoomCallParams(
    propose: settlement.RoomProposeParams(
      memberAction: settlement.RoomMemberActionTerms(
        action: finance.RoomMemberAction.ROOM_MEMBER_ACTION_REMOVE,
        subject: _member(account),
      ),
    ),
  ),
  summary: 'Propose removing $name',
  expected: (room, prepared) => RoomCallExpected.proposeMemberAction(
    custody: _custody(room),
    action: MemberActions.remove,
    subject: account,
  ),
  lines: [('Member', name), ('Account', shortAccount(account))],
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
  final vote = RoomVote.cast(
    proposalId: BigInt.from(onchainProposalId),
    choice: chainChoiceOf(choice),
  );
  return GovernanceRequest(
    kind: settlement.RoomCallKind.ROOM_CALL_KIND_CAST_VOTE,
    params: settlement.RoomCallParams(
      vote: settlement.RoomVoteParams(
        onchainProposalId: Int64(onchainProposalId),
        choice: choice,
      ),
    ),
    summary: 'Vote $label on proposal #$onchainProposalId',
    expected: (room, prepared) => RoomCallExpected.vote(vote),
  );
}

/// Delegates the member's votes (every proposal kind) to [name] (their
/// account [account]) until [until].
GovernanceRequest delegateRequest({
  required Uint8List account,
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
        to: _member(account),
        until: Int64(seconds),
      ),
    ),
    summary: 'Delegate votes to $name',
    expected: (room, prepared) =>
        RoomCallExpected.delegate(to: account, until: BigInt.from(seconds)),
    lines: [
      ('To', name),
      ('Account', shortAccount(account)),
      (
        'Until',
        '${inviteExpiryLabel(DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true))} UTC',
      ),
    ],
  );
}

final GovernanceRequest revokeDelegationRequest = GovernanceRequest(
  kind: settlement.RoomCallKind.ROOM_CALL_KIND_REVOKE_DELEGATION,
  summary: 'Revoke vote delegation',
  expected: (room, prepared) => RoomCallExpected.revokeDelegation(),
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
  final vote = RoomVote.commit(
    proposalId: BigInt.from(onchainProposalId),
    commitment: commitment,
  );
  return GovernanceRequest(
    kind: settlement.RoomCallKind.ROOM_CALL_KIND_COMMIT_VOTE,
    params: settlement.RoomCallParams(
      vote: settlement.RoomVoteParams(
        onchainProposalId: Int64(onchainProposalId),
        commitment: commitment,
      ),
    ),
    summary: 'Cast a secret vote on proposal #$onchainProposalId',
    expected: (room, prepared) => RoomCallExpected.vote(vote),
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
  final vote = RoomVote.reveal(
    proposalId: BigInt.from(onchainProposalId),
    choice: chainChoiceOf(choice),
    salt: salt,
  );
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
    expected: (room, prepared) => RoomCallExpected.vote(vote),
  );
}

/// Proposes a principal exit: the custody's fallback spend of [amount] from
/// [sourceBucket] to a member (their account [memberAccount]), an approved
/// external account or another bucket (exactly one). Settlement builds the
/// exit intent; the device checks it is this room's spend of [amount] to
/// that destination (checkPrincipalExit), and the ballot it signs carries
/// exactly that intent's digest.
GovernanceRequest proposePrincipalExitRequest({
  required String sourceBucket,
  required String amount,
  Uint8List? memberAccount,
  String memberName = '',
  Uint8List? externalAccount,
  String? bucket,
  String? amountLabel,
}) {
  final destinations = [
    memberAccount,
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
  if (memberAccount != null && memberAccount.length != 20) {
    throw ArgumentError.value(memberAccount, 'memberAccount', '20 bytes');
  }
  final to = memberAccount != null
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
          member: memberAccount == null ? null : _member(memberAccount),
          externalAccount: externalAccount,
          bucket: bucket,
        ),
      ),
    ),
    summary:
        'Propose a principal exit of ${amountLabel ?? amount} from '
        '$sourceBucket to $to',
    expected: (room, prepared) => RoomCallExpected.proposePrincipalExit(
      payloadHash: checkPrincipalExit(
        prepared,
        amount: amount,
        room: room,
        to: memberAccount ?? externalAccount,
      ),
    ),
    lines: [
      ('Amount', amountLabel ?? amount),
      ('From', sourceBucket),
      ('To', to),
      if (memberAccount ?? externalAccount case final a?)
        ('Account', shortAccount(a)),
    ],
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
    expected: (room, prepared) => RoomCallExpected.cancelPrincipalExit(
      chainId: room.chainId,
      custody: _custody(room),
      cancelTarget: BigInt.from(cancelTarget),
    ),
    lines: [('Exit ballot', '#$cancelTarget')],
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
    expected: (room, prepared) => RoomCallExpected.votePrincipalExit(
      ballotId: BigInt.from(ballotId),
      approve: approve,
    ),
    lines: [
      ('Exit ballot', '#$ballotId'),
      ('Your vote', approve ? 'Approve' : 'Reject'),
    ],
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
    expected: (room, prepared) => RoomCallExpected.freeze(reason: trimmed),
    lines: [('Reason', trimmed)],
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

/// Proposes electing [name] (their account [account]) to the constitution's
/// role [roleId]; the members vote on it.
GovernanceRequest assignRoleRequest({
  required Uint8List account,
  required String name,
  required String roleId,
  required String roleName,
  required int capabilities,
  DateTime? validUntil,
}) {
  final until = validUntil == null
      ? 0
      : validUntil.toUtc().millisecondsSinceEpoch ~/ 1000;
  return GovernanceRequest(
    kind: settlement.RoomCallKind.ROOM_CALL_KIND_ASSIGN_ROLE,
    params: settlement.RoomCallParams(
      role: settlement.RoomRoleTerms(
        member: _member(account),
        roleId: roleId,
        capabilities: capabilities,
        validUntil: Int64(until),
        assign: true,
      ),
    ),
    summary: 'Propose $name as $roleName',
    expected: (room, prepared) => RoomCallExpected.assignRole(
      custody: _custody(room),
      member: account,
      roleName: roleId,
      capabilities: capabilities,
      validUntil: BigInt.from(until),
    ),
    lines: [
      ('Member', name),
      ('Account', shortAccount(account)),
      ('Role', roleName),
      (
        'May',
        [
          for (final e in RoomCapability.labels.entries)
            if (capabilities & e.key != 0) e.value,
        ].join(', ').ifEmpty('nothing on chain'),
      ),
    ],
  );
}

/// Proposes removing [name] (their account [account]) from the role
/// [roleId].
GovernanceRequest revokeRoleRequest({
  required Uint8List account,
  required String name,
  required String roleId,
  required String roleName,
}) => GovernanceRequest(
  kind: settlement.RoomCallKind.ROOM_CALL_KIND_REVOKE_ROLE,
  params: settlement.RoomCallParams(
    role: settlement.RoomRoleTerms(member: _member(account), roleId: roleId),
  ),
  summary: 'Propose removing $name as $roleName',
  expected: (room, prepared) => RoomCallExpected.revokeRole(
    custody: _custody(room),
    member: account,
    roleName: roleId,
  ),
  lines: [
    ('Member', name),
    ('Account', shortAccount(account)),
    ('Role', roleName),
  ],
);

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}

BigInt _loanNumber(finance.Loan loan) {
  final id = BigInt.parse(loan.onchainLoanId.toStringUnsigned());
  if (id == BigInt.zero) {
    throw const SigningRefused('the loan is not on chain yet');
  }
  return id;
}

/// The LoanBook a room loan is on, as finance indexes it.
Uint8List _loanBookOf(finance.Loan loan) {
  if (loan.loanBook.length != 20 || loan.loanBook.every((b) => b == 0)) {
    throw const SigningRefused('the loan\'s loan book is not known');
  }
  return Uint8List.fromList(loan.loanBook);
}

/// Opens the room's vote on [loan], a pending request the room decides by
/// vote (PROPOSE loan_approval): the LOAN proposal of LoanBook's approval
/// document for the loan as finance indexes it (its borrower, amount and
/// instalments), on the room's custody. Any member may open it.
GovernanceRequest openLoanVoteRequest(finance.Loan loan, {String? borrower}) {
  final id = _loanNumber(loan);
  final book = _loanBookOf(loan);
  final amount = BigInt.tryParse(loan.requested.amount) ?? BigInt.zero;
  if (amount <= BigInt.zero || loan.borrowerAccount.length != 20) {
    throw const SigningRefused('the loan request could not be read');
  }
  return GovernanceRequest(
    kind: settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE,
    params: settlement.RoomCallParams(
      propose: settlement.RoomProposeParams(loanApproval: loan.onchainLoanId),
    ),
    summary: 'Open the vote on loan request #$id',
    expected: (room, prepared) => RoomCallExpected.propose(
      proposalKind: ProposalKinds.loan,
      payloadHash: payloadHashOf(
        loanApprovalDocument(
          loanBook: book,
          custody: _custody(room),
          loanId: id,
          borrower: loan.borrowerAccount,
          amount: amount,
          instalments: loan.instalments,
        ),
      ),
    ),
    lines: [
      ('Loan request', '#$id'),
      if (borrower != null) ('Borrower', borrower),
      ('Instalments', '${loan.instalments}'),
    ],
  );
}

/// Proposes writing [loan] off: the room stops collecting it and takes the
/// loss (PROPOSE loan_write_off, LoanBook's write-off document).
GovernanceRequest writeOffRequest(finance.Loan loan) {
  final id = _loanNumber(loan);
  final book = _loanBookOf(loan);
  return GovernanceRequest(
    kind: settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE,
    params: settlement.RoomCallParams(
      propose: settlement.RoomProposeParams(loanWriteOff: loan.onchainLoanId),
    ),
    summary: 'Propose writing off loan #$id',
    expected: (room, prepared) => RoomCallExpected.propose(
      proposalKind: ProposalKinds.writeOff,
      payloadHash: payloadHashOf(
        loanWriteOffDocument(
          loanBook: book,
          custody: _custody(room),
          loanId: id,
        ),
      ),
    ),
    lines: [('Loan', '#$id'), ('Decision', 'Write it off')],
  );
}

/// Proposes restructuring [loan]: what is owed repaid over [instalments]
/// from now at [rateBps] interest per instalment (PROPOSE loan_restructure,
/// LoanBook's restructure document).
GovernanceRequest restructureRequest(
  finance.Loan loan, {
  required int instalments,
  required int rateBps,
}) {
  if (instalments < 1 || instalments > 65535) {
    throw ArgumentError.value(instalments, 'instalments', '1 to 65535');
  }
  if (rateBps < 0 || rateBps > 0xffffffff) {
    throw ArgumentError.value(rateBps, 'rateBps', 'a uint32');
  }
  final id = _loanNumber(loan);
  final book = _loanBookOf(loan);
  return GovernanceRequest(
    kind: settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE,
    params: settlement.RoomCallParams(
      propose: settlement.RoomProposeParams(
        loanRestructure: settlement.RoomLoanRestructure(
          loanId: loan.onchainLoanId,
          instalments: instalments,
          rateBps: rateBps,
        ),
      ),
    ),
    summary: 'Propose restructuring loan #$id',
    expected: (room, prepared) => RoomCallExpected.propose(
      proposalKind: ProposalKinds.restructure,
      payloadHash: payloadHashOf(
        loanRestructureDocument(
          loanBook: book,
          custody: _custody(room),
          loanId: id,
          instalments: instalments,
          rateBps: rateBps,
        ),
      ),
    ),
    lines: [
      ('Loan', '#$id'),
      ('New instalments', '$instalments'),
      ('Interest', '${formatBps(rateBps)} each instalment'),
    ],
  );
}
