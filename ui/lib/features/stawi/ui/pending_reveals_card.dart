import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/stawi_room_service.dart';
import '../domain/secret_ballot.dart';
import 'stawi_feedback.dart';

/// Reminds the voter of the secret votes this device cast in the room and
/// has not revealed, with each reveal deadline. Only this device holds their
/// sealed choice, so only it can reveal them.
class PendingRevealsCard extends ConsumerWidget {
  const PendingRevealsCard({required this.roomId, this.now, super.key});

  final String roomId;

  /// For tests; defaults to the clock.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending =
        ref.watch(stawiPendingRevealsProvider(roomId)).asData?.value ??
        const <PendingReveal>[];
    if (pending.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final clock = now ?? DateTime.now();
    final dates = DateFormat.yMMMd().add_jm();
    return Card(
      key: const Key('pending-reveals'),
      color: theme.colorScheme.secondaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            leading: Icon(Icons.lock_clock_outlined),
            title: Text('Secret votes to reveal'),
            subtitle: Text(
              'Your choices are sealed on this device. Reveal them from here '
              'before each deadline, or they will not count.',
            ),
          ),
          for (final p in pending)
            ListTile(
              key: Key('pending-reveal-${p.proposalId}'),
              title: Text('Proposal #${p.proposalId}'),
              subtitle: Text(switch (revealUrgency(p.vote, clock)) {
                RevealUrgency.closed =>
                  'The reveal window closed ${dates.format(p.vote.revealClosesAt!.toLocal())}',
                RevealUrgency.closingSoon =>
                  'Reveal now: closes ${dates.format(p.vote.revealClosesAt!.toLocal())}',
                RevealUrgency.open =>
                  'Reveal by ${dates.format(p.vote.revealClosesAt!.toLocal())}',
                RevealUrgency.unknown => 'Reveal after voting closes',
              }),
              leading: revealUrgency(p.vote, clock) == RevealUrgency.closingSoon
                  ? Icon(Icons.warning_amber, color: theme.colorScheme.error)
                  : null,
              trailing: revealUrgency(p.vote, clock) == RevealUrgency.closed
                  ? null
                  : TextButton(
                      key: Key('reveal-${p.proposalId}'),
                      onPressed: () async {
                        await runStawiAction(
                          context,
                          () => ref
                              .read(stawiRoomServiceProvider)
                              .revealSecretVote(
                                roomId: roomId,
                                onchainProposalId: p.proposalId,
                              ),
                          success: 'Vote revealed',
                        );
                        ref.invalidate(stawiPendingRevealsProvider(roomId));
                      },
                      child: const Text('Reveal'),
                    ),
            ),
        ],
      ),
    );
  }
}
