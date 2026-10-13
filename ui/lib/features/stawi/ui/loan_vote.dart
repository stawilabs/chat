import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;

import '../data/stawi_room_service.dart';
import 'money_review_sheet.dart';
import 'stawi_feedback.dart';

/// A loan's vote moves the room's money, so it is signed like a money call:
/// the person taps Yes or No, the device prepares the vote with settlement
/// and checks it against the room's GovernanceModule as finance knows it
/// (stawi_finance_sdk verifyRoomVoteCall), shows what it will sign ("Vote Yes
/// on loan request #3 in Chama"), and only then asks the device lock. A
/// secret ballot is committed the same way and revealed from this device.
Future<bool> voteOnLoan(
  BuildContext context,
  WidgetRef ref, {
  required String roomId,
  required String roomName,
  required finance.Proposal proposal,
  required String loanNumber,
  required finance.VoteChoice choice,
}) async {
  final service = ref.read(stawiRoomServiceProvider);
  final secret = proposal.ballot == finance.BallotMode.BALLOT_MODE_SECRET;
  final prepared = await runStawiAction(
    context,
    () => service.prepareVote(
      roomId: roomId,
      onchainProposalId: proposal.onchainProposalId.toInt(),
      choice: choice,
      mode: secret ? RoomVoteMode.secret : RoomVoteMode.open,
      title: loanVoteTitle(choice, loanNumber: loanNumber, roomName: roomName),
      lines: [('Loan request', '#$loanNumber'), ('Room', roomName)],
      revealClosesAt: proposal.hasRevealClosesAt()
          ? proposal.revealClosesAt.toDateTime()
          : null,
    ),
  );
  if (prepared == null || !context.mounted) return false;
  if (!await showMoneyReview(context, prepared.review) || !context.mounted) {
    return false;
  }
  final sent = await runStawiAction(
    context,
    () => service.submitVote(prepared),
    success: secret
        ? 'Secret vote cast; reveal it from this device when voting closes'
        : 'Vote sent',
  );
  return sent != null;
}

/// Reveals the vote this device sealed on [proposal], reviewed first.
Future<bool> revealLoanVote(
  BuildContext context,
  WidgetRef ref, {
  required String roomId,
  required String roomName,
  required finance.Proposal proposal,
  required String loanNumber,
}) async {
  final service = ref.read(stawiRoomServiceProvider);
  final prepared = await runStawiAction(
    context,
    () => service.prepareReveal(
      roomId: roomId,
      onchainProposalId: proposal.onchainProposalId.toInt(),
      title: 'Reveal my vote on loan request #$loanNumber in $roomName',
      lines: [('Loan request', '#$loanNumber'), ('Room', roomName)],
    ),
  );
  if (prepared == null || !context.mounted) return false;
  if (!await showMoneyReview(context, prepared.review) || !context.mounted) {
    return false;
  }
  final sent = await runStawiAction(
    context,
    () => service.submitVote(prepared),
    success: 'Vote revealed',
  );
  if (sent != null) ref.invalidate(stawiPendingRevealsProvider(roomId));
  return sent != null;
}

/// "Vote Yes on loan request #3 in Chama".
String loanVoteTitle(
  finance.VoteChoice choice, {
  required String loanNumber,
  required String roomName,
}) => choice == finance.VoteChoice.VOTE_CHOICE_ABSTAIN
    ? 'Abstain on loan request #$loanNumber in $roomName'
    : 'Vote ${voteChoiceLabel(choice)} on loan request #$loanNumber in '
          '$roomName';

/// Vote yes, vote no and, for a secret ballot this device cast, reveal.
class LoanVoteButtons extends ConsumerStatefulWidget {
  const LoanVoteButtons({
    required this.roomId,
    required this.roomName,
    required this.proposal,
    required this.loanNumber,
    this.onVoted,
    super.key,
  });

  final String roomId;
  final String roomName;
  final finance.Proposal proposal;
  final String loanNumber;

  /// Called once a vote or reveal was sent.
  final VoidCallback? onVoted;

  @override
  ConsumerState<LoanVoteButtons> createState() => _LoanVoteButtonsState();
}

class _LoanVoteButtonsState extends ConsumerState<LoanVoteButtons> {
  bool _busy = false;

  Future<void> _run(Future<bool> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (await action()) widget.onVoted?.call();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _vote(finance.VoteChoice choice) => _run(
    () => voteOnLoan(
      context,
      ref,
      roomId: widget.roomId,
      roomName: widget.roomName,
      proposal: widget.proposal,
      loanNumber: widget.loanNumber,
      choice: choice,
    ),
  );

  Future<void> _reveal() => _run(
    () => revealLoanVote(
      context,
      ref,
      roomId: widget.roomId,
      roomName: widget.roomName,
      proposal: widget.proposal,
      loanNumber: widget.loanNumber,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final n = widget.loanNumber;
    final secret =
        widget.proposal.ballot == finance.BallotMode.BALLOT_MODE_SECRET;
    final id = widget.proposal.onchainProposalId.toInt();
    final sealedHere =
        secret &&
        (ref
                .watch(stawiPendingRevealsProvider(widget.roomId))
                .asData
                ?.value
                .any((r) => r.proposalId == id) ??
            false);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        FilledButton.icon(
          key: Key('loan-$n-vote-yes'),
          icon: const Icon(Icons.thumb_up_outlined),
          label: const Text('Vote yes'),
          onPressed: _busy
              ? null
              : () => _vote(finance.VoteChoice.VOTE_CHOICE_APPROVE),
        ),
        OutlinedButton.icon(
          key: Key('loan-$n-vote-no'),
          icon: const Icon(Icons.thumb_down_outlined),
          label: const Text('Vote no'),
          onPressed: _busy
              ? null
              : () => _vote(finance.VoteChoice.VOTE_CHOICE_REJECT),
        ),
        if (sealedHere)
          TextButton.icon(
            key: Key('loan-$n-vote-reveal'),
            icon: const Icon(Icons.lock_open_outlined),
            label: const Text('Reveal my vote'),
            onPressed: _busy ? null : _reveal,
          ),
      ],
    );
  }
}

/// The vote on a loan opened from a card: the same buttons in a sheet.
Future<void> showLoanVoteSheet(
  BuildContext context, {
  required String roomId,
  required String roomName,
  required finance.Proposal proposal,
  required String loanNumber,
}) => showModalBottomSheet<void>(
  context: context,
  builder: (context) => SafeArea(
    child: Padding(
      key: const Key('loan-vote-sheet'),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Loan request #$loanNumber in $roomName',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          LoanVoteButtons(
            roomId: roomId,
            roomName: roomName,
            proposal: proposal,
            loanNumber: loanNumber,
            onVoted: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    ),
  ),
);
