import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../messages/domain/room_event.dart';
import '../data/pool_membership.dart';
import '../data/socialtrader_api.dart';
import '../domain/pool_binding.dart';
import '../domain/pool_card.dart';
import '../domain/pool_models.dart';

/// What a timeline does when a card's button is tapped. The sheet it opens
/// asks the wallet to sign; the card itself never submits anything.
typedef PoolCardAction = void Function(PoolCard card);

/// Renders a pool card the socialtrader service posted. The card is
/// interactive only for a pool the service lists; a card from an unknown pool
/// falls back to its plain text so nothing in the timeline can pose as one.
class PoolCardBubble extends ConsumerWidget {
  const PoolCardBubble({
    required this.event,
    required this.isMe,
    this.onCommit,
    this.onRedeem,
    super.key,
  });

  final RoomEvent event;
  final bool isMe;
  final PoolCardAction? onCommit;
  final PoolCardAction? onRedeem;

  /// The card body of [event], or null when the event is not a pool card
  /// posted by the socialtrader service. A member's message in the card's
  /// shape (which the server refuses anyway) is never a card.
  static PoolCard? cardOf(RoomEvent event) {
    if (event.type != RoomEventType.text) return null;
    if (event.content['posted_by_service'] != true) return null;
    final format = event.content['format'];
    if (format != null && format != 'json') return null;
    final body = event.content['text'];
    if (body is! String) return null;
    return PoolCard.tryParse(body);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = cardOf(event);
    if (card == null) return _Fallback(event: event);
    // Only a card about the room's own bound pool is a card here.
    final binding = ref.watch(poolBindingProvider(event.roomId));
    if (binding is! AsyncData) return const _Loading();
    if (binding.value?.poolId != card.pool) return _Fallback(event: event);
    final pool = ref.watch(poolByAddressProvider(card.pool));
    return switch (pool) {
      AsyncData(value: null) => _Fallback(event: event),
      AsyncData(value: final info?) => _Card(
        event: event,
        card: card,
        pool: info,
        onCommit: onCommit,
        onRedeem: onRedeem,
      ),
      AsyncError() => _Unavailable(
        event: event,
        onRetry: () => ref.invalidate(knownPoolsProvider),
      ),
      _ => const _Loading(),
    };
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

/// The card's body as plain text: an unknown pool is never a card.
class _Fallback extends StatelessWidget {
  const _Fallback({required this.event});

  final RoomEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: Key('pool-card-fallback-${event.id}'),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SelectableText(
          event.content['text'] as String? ?? '',
          style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.event, required this.onRetry});

  final RoomEvent event;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Card(
      key: Key('pool-card-unavailable-${event.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined),
            const SizedBox(width: 8),
            const Flexible(
              child: Text("The pool couldn't be checked right now."),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    ),
  );
}

/// The verification tier of a NAV figure: green only when finalized.
class TierBadge extends StatelessWidget {
  const TierBadge({required this.tier, super.key});

  final String tier;

  bool get isVerified => tier == 'finalized';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isVerified ? Colors.green.shade700 : scheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified_outlined : Icons.hourglass_empty,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            tier.isEmpty ? 'unverified' : tier,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.event,
    required this.card,
    required this.pool,
    this.onCommit,
    this.onRedeem,
  });

  final RoomEvent event;
  final PoolCard card;
  final PoolInfo pool;
  final PoolCardAction? onCommit;
  final PoolCardAction? onRedeem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          key: Key('pool-card-${event.id}'),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_icon, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_title, style: theme.textTheme.titleMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._body(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData get _icon => switch (card) {
    JoinPromptCard() => Icons.group_add_outlined,
    LeavePromptCard() => Icons.logout,
    NavCard() => Icons.show_chart,
    FillCard() => Icons.swap_horiz,
  };

  String get _title => switch (card) {
    JoinPromptCard() => 'Commit to the pool',
    LeavePromptCard() => 'Redeem your shares',
    NavCard() => 'Pool value',
    FillCard(:final isBuy) => isBuy ? 'Bought' : 'Sold',
  };

  List<Widget> _body(BuildContext context) {
    final theme = Theme.of(context);
    switch (card) {
      case JoinPromptCard(
        :final marketSymbol,
        :final navPerShare,
        :final memberCount,
      ):
        return [
          if (marketSymbol.isNotEmpty)
            Text(marketSymbol, style: theme.textTheme.bodyLarge),
          Text(
            'NAV per share ${navPerShare.isEmpty ? pool.navPerShare : navPerShare}'
            ' · ${memberCount > 0 ? memberCount : pool.memberCount} members',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Committing asks your wallet to sign a deposit. Nothing moves '
            'until you sign.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onCommit == null ? null : () => onCommit!(card),
              child: const Text('Commit'),
            ),
          ),
        ];
      case LeavePromptCard():
        return [
          _OwnPosition(pool: pool.address),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onRedeem == null ? null : () => onRedeem!(card),
              child: const Text('Redeem'),
            ),
          ),
        ];
      case NavCard(
        :final nav,
        :final navPerShare,
        :final returnBps,
        :final tier,
      ):
        final positive = returnBps >= 0;
        return [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Value $nav · NAV/share $navPerShare',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                formatBps(returnBps),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: positive
                      ? Colors.green.shade700
                      : theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TierBadge(tier: tier),
        ];
      case FillCard(
        :final isBuy,
        :final price,
        :final baseAmount,
        :final quoteAmount,
      ):
        return [
          Text(
            '${isBuy ? 'Bought' : 'Sold'} $baseAmount at $price'
            '${quoteAmount.isEmpty ? '' : ' for $quoteAmount'}',
            style: theme.textTheme.bodyMedium,
          ),
        ];
    }
  }
}

/// The viewer's own stake, fetched through the authenticated GetMembership
/// call: a room card never carries a member's position.
class _OwnPosition extends ConsumerWidget {
  const _OwnPosition({required this.pool});

  final String pool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final membership = ref.watch(myMembershipProvider(pool));
    return switch (membership) {
      AsyncData(:final value) when value.holdsShares => Text(
        'You hold ${value.shares} shares, worth about ${value.valueQuote}.',
        key: const Key('pool-card-own-position'),
        style: theme.textTheme.bodyMedium,
      ),
      AsyncData() => Text(
        'Connect your wallet to see your shares.',
        key: const Key('pool-card-own-position'),
        style: theme.textTheme.bodyMedium,
      ),
      AsyncError() => Text(
        "Your shares couldn't be read right now.",
        style: theme.textTheme.bodySmall,
      ),
      _ => const LinearProgressIndicator(),
    };
  }
}
