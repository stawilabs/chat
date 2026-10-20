import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;

import '../data/stawi_account_service.dart' show stawiClockProvider;
import '../data/stawi_room_service.dart';
import '../domain/room_setup.dart';
import 'money_review_sheet.dart';
import 'stawi_feedback.dart';

/// Where the room's lending setup stands (settlement GetRoomSetup): "Setting
/// up lending: vote 1 of 3, closes in 2 days", each step, a one-tap "Vote
/// yes" for every vote open now, and, while settlement holds no founder's
/// signatures, a founder's "Sign the lending setup". Nothing when the room
/// has no setup.
class RoomSetupCard extends ConsumerStatefulWidget {
  const RoomSetupCard({
    required this.roomId,
    required this.roomName,
    super.key,
  });

  final String roomId;
  final String roomName;

  @override
  ConsumerState<RoomSetupCard> createState() => _RoomSetupCardState();
}

class _RoomSetupCardState extends ConsumerState<RoomSetupCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        ref.invalidate(stawiRoomSetupProvider(widget.roomId));
      }
    }
  }

  Future<void> _sign() => _run(() async {
    final service = ref.read(stawiRoomServiceProvider);
    final prepared = await runStawiAction(
      context,
      () => service.prepareSetupSignatures(widget.roomId),
    );
    if (prepared == null || !mounted) return;
    if (!await showMoneyReview(context, prepared.review) || !mounted) return;
    await runStawiAction(
      context,
      () => service.submitSetupSignatures(prepared),
      success: prepared.review.done,
    );
  });

  Future<void> _voteYes(settlement.RoomSetupStep step) => _run(() async {
    final service = ref.read(stawiRoomServiceProvider);
    final title = setupStepTitle(step);
    final prepared = await runStawiAction(
      context,
      () => service.prepareVote(
        roomId: widget.roomId,
        onchainProposalId: step.onchainProposalId.toInt(),
        choice: finance.VoteChoice.VOTE_CHOICE_APPROVE,
        mode: RoomVoteMode.open,
        title: 'Vote yes: $title',
        lines: [
          ('Room', widget.roomName),
          ('Proposal', '#${step.onchainProposalId}'),
        ],
      ),
    );
    if (prepared == null || !mounted) return;
    if (!await showMoneyReview(context, prepared.review) || !mounted) return;
    await runStawiAction(
      context,
      () => service.submitAct(prepared),
      success: 'Vote sent',
    );
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = ref.watch(stawiClockProvider)();
    return ref
        .watch(stawiRoomSetupProvider(widget.roomId))
        .when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Card(
            key: const Key('room-setup-unavailable'),
            child: ListTile(
              title: const Text('The lending setup could not be read'),
              subtitle: Text(stawiErrorMessage(e)),
              trailing: TextButton(
                key: const Key('room-setup-retry'),
                onPressed: () =>
                    ref.invalidate(stawiRoomSetupProvider(widget.roomId)),
                child: const Text('Try again'),
              ),
            ),
          ),
          data: (setup) {
            final progress = RoomSetupProgress(setup);
            if (!progress.shown) return const SizedBox.shrink();
            return Card(
              key: const Key('room-setup'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          progress.ready
                              ? Icons.verified_outlined
                              : Icons.construction_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            progress.headline(now),
                            key: const Key('room-setup-headline'),
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    if (!progress.ready)
                      for (final step in setup.steps)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text(setupStepTitle(step))),
                              Text(
                                setupStepStateLabel(step, now),
                                key: Key('room-setup-step-${step.step.value}'),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                    if (progress.asksMe) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Settlement holds no founder\'s signature for the '
                        'setup. As a founder you can sign it now; the members '
                        'then vote on each step.',
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        key: const Key('room-setup-sign'),
                        icon: const Icon(Icons.draw_outlined),
                        label: const Text('Sign the lending setup'),
                        onPressed: _busy ? null : _sign,
                      ),
                    ],
                    for (final step in progress.voting) ...[
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        key: Key('room-setup-vote-${step.step.value}'),
                        icon: const Icon(Icons.thumb_up_outlined),
                        label: Text('Vote yes: ${setupStepTitle(step)}'),
                        onPressed: _busy ? null : () => _voteYes(step),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
  }
}
