import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/stawi_timeline_providers.dart';
import 'contribute_screen.dart';
import 'convert_room_screen.dart';
import 'governance_sheet.dart';
import 'pending_reveals_card.dart';
import 'room_money_screen.dart';
import 'statement_screen.dart';
import 'stawi_account_screen.dart';
import 'stawi_feedback.dart';

/// A room's Stawi page: where the room stands, and what the member can do
/// from here — convert it, sign governance acts, read their statement.
class StawiRoomScreen extends ConsumerWidget {
  const StawiRoomScreen({
    required this.roomId,
    required this.roomName,
    super.key,
  });

  final String roomId;
  final String roomName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(stawiRoomPhaseProvider(roomId));
    return Scaffold(
      appBar: AppBar(title: Text('Stawi · $roomName')),
      body: phase.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(stawiErrorMessage(error))),
        data: (phase) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PhaseCard(phase: phase),
            const SizedBox(height: 16),
            ..._actions(context, phase),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('My Stawi account'),
              subtitle: const Text('Device key and account deployment'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => StawiAccountScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context, StawiRoomPhase phase) {
    switch (phase) {
      case StawiRoomPhase.chatOnly:
        return [
          FilledButton.icon(
            key: const Key('stawi-convert'),
            icon: const Icon(Icons.savings_outlined),
            label: const Text('Make this a Stawi room'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<bool>(
                builder: (_) => ConvertRoomScreen(roomId: roomId),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Only the room owner or an admin can convert it. You will choose '
            'the founders, who each sign the genesis.',
          ),
        ];
      case StawiRoomPhase.preparing:
      case StawiRoomPhase.awaitingSignatures:
        return const [
          Text(
            'Founders sign the genesis from its card in the chat. The room '
            'goes on chain once enough of them have signed.',
          ),
        ];
      case StawiRoomPhase.active:
        return [
          PendingRevealsCard(roomId: roomId),
          FilledButton.icon(
            key: const Key('stawi-governance'),
            icon: const Icon(Icons.gavel_outlined),
            label: const Text('Sign a room act'),
            onPressed: () => showGovernanceSheet(context, roomId: roomId),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            key: const Key('stawi-contribute'),
            icon: const Icon(Icons.savings_outlined),
            label: const Text('Contribute'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    ContributeScreen(roomId: roomId, roomName: roomName),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('stawi-money'),
            icon: const Icon(Icons.account_balance_outlined),
            label: const Text('Savings, share-outs, loans and members'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    RoomMoneyScreen(roomId: roomId, roomName: roomName),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('stawi-statement'),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('My statement'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    StatementScreen(roomId: roomId, roomName: roomName),
              ),
            ),
          ),
        ];
    }
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({required this.phase});

  final StawiRoomPhase phase;

  @override
  Widget build(BuildContext context) {
    final (icon, title, body) = switch (phase) {
      StawiRoomPhase.chatOnly => (
        Icons.chat_bubble_outline,
        'Chat room',
        'This room is not a Stawi room.',
      ),
      StawiRoomPhase.preparing => (
        Icons.hourglass_top,
        'Conversion sent',
        'Waiting for the genesis to be prepared.',
      ),
      StawiRoomPhase.awaitingSignatures => (
        Icons.draw_outlined,
        'Awaiting founder signatures',
        'The genesis card is in the chat.',
      ),
      StawiRoomPhase.active => (
        Icons.verified_outlined,
        'Stawi room',
        'Custody and governance are on chain.',
      ),
    };
    return Card(
      child: ListTile(
        key: const Key('stawi-phase'),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(body),
      ),
    );
  }
}
