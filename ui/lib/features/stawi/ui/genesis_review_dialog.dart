import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;

import '../data/stawi_room_service.dart' show agentNotConfirmed;
import '../domain/stawi_payloads.dart';

/// What a founder is told about the Stawi fee before signing.
const String genesisFeeSentence =
    'Stawi takes a fee from the group\'s interest, fees and penalties; an '
    'agent receives part of it.';

/// Shows [GenesisReviewDialog]; true only when the founder chose to sign.
Future<bool> showGenesisReview(
  BuildContext context, {
  required settlement.RoomGenesis genesis,
  required StawiGenesisView card,
  required String roomName,
  required List<String> founderNames,
  required bool agentConfirmed,
  String? agentName,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => GenesisReviewDialog(
        genesis: genesis,
        card: card,
        roomName: roomName,
        founderNames: founderNames,
        agentConfirmed: agentConfirmed,
        agentName: agentName,
      ),
    ) ??
    false;

/// What a founder signs, shown before the device key is unlocked: the room,
/// its founders, who can join, the room's Stawi agent and the Stawi fee. The
/// genesis was already checked on this device (its hash recomputed from these
/// contents), so this is what the signature commits to.
class GenesisReviewDialog extends StatelessWidget {
  const GenesisReviewDialog({
    required this.genesis,
    required this.card,
    required this.roomName,
    required this.founderNames,
    required this.agentConfirmed,
    this.agentName,
    super.key,
  });

  final settlement.RoomGenesis genesis;
  final StawiGenesisView card;
  final String roomName;

  /// The founders' names, in the genesis' order.
  final List<String> founderNames;

  /// The agent's name; null when the genesis names no agent.
  final String? agentName;

  /// Whether this device confirmed the agent's address belongs to the person
  /// named. Without it the genesis cannot be signed from here.
  final bool agentConfirmed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAgent = genesis.agent.isNotEmpty;
    final joining =
        genesis.joinPolicy == finance.RoomJoinPolicy.ROOM_JOIN_POLICY_PUBLIC
        ? 'Anyone, then admitted'
        : 'By invitation';
    return AlertDialog(
      key: const Key('genesis-review'),
      title: Text('Found $roomName on Stawi'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Room: $roomName'),
            const SizedBox(height: 8),
            Text(
              'Founders: ${founderNames.join(', ')}',
              key: const Key('genesis-review-founders'),
            ),
            const SizedBox(height: 8),
            Text('Who can join: $joining'),
            const SizedBox(height: 8),
            Text(
              hasAgent ? 'Stawi agent: ${agentName ?? 'Member'}' : 'No agent',
              key: const Key('genesis-review-agent'),
            ),
            if (card.expiresAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Sign by: '
                '${DateFormat.yMMMd().add_jm().format(card.expiresAt!.toLocal())}',
              ),
            ],
            const SizedBox(height: 12),
            Text(genesisFeeSentence, style: theme.textTheme.bodySmall),
            if (!agentConfirmed) ...[
              const SizedBox(height: 12),
              Text(
                agentNotConfirmed,
                key: const Key('genesis-agent-unconfirmed'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('genesis-review-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        if (agentConfirmed)
          FilledButton(
            key: const Key('genesis-sign'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign as a founder'),
          ),
      ],
    );
  }
}
