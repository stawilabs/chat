import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../messages/data/message_providers.dart';
import '../../messages/domain/room_event.dart';
import '../data/pool_membership.dart';
import '../data/socialtrader_api.dart';
import '../domain/pool_binding.dart';
import '../domain/pool_card.dart';
import '../domain/pool_models.dart';
import 'leader_trade_sheet.dart';
import 'leave_pool_sheet.dart';
import 'pool_card_bubble.dart';

part 'pool_tab.g.dart';

/// How many of the room's latest messages are scanned for fill cards.
const int _fillScanLimit = 200;

/// A pool's performance series.
@riverpod
Future<PoolPerformance> poolPerformance(Ref ref, String pool) =>
    ref.watch(socialTraderApiProvider).getPerformance(pool);

/// The pool's recent fills, from the fill cards in the room's timeline,
/// newest first.
@riverpod
AsyncValue<List<(RoomEvent, FillCard)>> recentFills(Ref ref, String roomId) =>
    ref
        .watch(
          paginatedMessagesStreamProvider((
            roomId: roomId,
            limit: _fillScanLimit,
          )),
        )
        .whenData(
          (events) => [
            for (final event in events)
              if (PoolCardBubble.cardOf(event) case final FillCard card)
                (event, card),
          ],
        );

/// The Pool tab as its own page (/room/:roomId/pool), from the header chip.
class PoolScreen extends StatelessWidget {
  const PoolScreen({required this.roomId, required this.roomName, super.key});

  final String roomId;
  final String roomName;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('$roomName · Pool')),
    body: PoolTab(roomId: roomId),
  );
}

/// Everything the Pool tab shows about a trading group: value, NAV series,
/// members, the person's stake, recent fills and queued redeems, and the
/// leader's actions when the connected wallet leads the pool.
class PoolTab extends ConsumerWidget {
  const PoolTab({required this.roomId, super.key});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final binding = ref.watch(poolBindingProvider(roomId));
    return switch (binding) {
      AsyncData(value: final b?) => _PoolBody(roomId: roomId, poolId: b.poolId),
      AsyncData() => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('This room is not a trading group.'),
        ),
      ),
      AsyncError() => _Problem(
        onRetry: () => ref.invalidate(poolBindingProvider(roomId)),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _PoolBody extends ConsumerWidget {
  const _PoolBody({required this.roomId, required this.poolId});

  final String roomId;
  final String poolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pool = ref.watch(poolByAddressProvider(poolId));
    return switch (pool) {
      AsyncData(value: final info?) => _Details(roomId: roomId, pool: info),
      AsyncData() => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('The pool is not known to the trading service.'),
        ),
      ),
      AsyncError() => _Problem(
        onRetry: () => ref.invalidate(knownPoolsProvider),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40),
          const SizedBox(height: 8),
          const Text("The pool couldn't be loaded right now."),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

class _Details extends ConsumerWidget {
  const _Details({required this.roomId, required this.pool});

  final String roomId;
  final PoolInfo pool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final performance = ref.watch(poolPerformanceProvider(pool.address));
    final membership = ref.watch(myMembershipProvider(pool.address));
    final fills = ref.watch(recentFillsProvider(roomId));
    final wallet = ref.watch(memberWalletProvider).asData?.value;
    final isLeader = pool.isLeader(wallet);
    final mine = membership.asData?.value;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Pool value', style: theme.textTheme.labelLarge),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(pool.nav, style: theme.textTheme.headlineMedium),
            const SizedBox(width: 12),
            Text(
              'NAV/share ${pool.navPerShare}',
              style: theme.textTheme.bodyMedium,
            ),
            const Spacer(),
            TierBadge(tier: pool.tier),
          ],
        ),
        const SizedBox(height: 12),
        switch (performance) {
          AsyncData(:final value) => _PerformanceCard(performance: value),
          AsyncError() => Text(
            'Performance unavailable',
            style: theme.textTheme.bodySmall,
          ),
          _ => const LinearProgressIndicator(),
        },
        const SizedBox(height: 16),
        Text('Members', style: theme.textTheme.labelLarge),
        Text(
          '${pool.memberCount} members · leader ${_short(pool.leader)}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        _MyStake(pool: pool, membership: membership),
        const SizedBox(height: 16),
        Text('Recent fills', style: theme.textTheme.labelLarge),
        switch (fills) {
          AsyncData(value: final list) when list.isEmpty => Text(
            'No fills yet.',
            style: theme.textTheme.bodyMedium,
          ),
          AsyncData(value: final list) => Column(
            children: [
              for (final (event, fill) in list.take(20))
                ListTile(
                  key: Key('pool-fill-${event.id}'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    fill.isBuy ? Icons.call_received : Icons.call_made,
                    color: fill.isBuy
                        ? Colors.green.shade700
                        : theme.colorScheme.error,
                  ),
                  title: Text(
                    '${fill.isBuy ? 'Bought' : 'Sold'} ${fill.baseAmount} '
                    'at ${fill.price}',
                  ),
                  subtitle: fill.block > 0 ? Text('Block ${fill.block}') : null,
                ),
            ],
          ),
          _ => const LinearProgressIndicator(),
        },
        if (isLeader) ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('pool-leader-actions'),
            onPressed: () => showLeaderTradeSheet(
              context,
              pool: pool,
              queuedShares: mine?.queuedShares ?? '0',
            ),
            icon: const Icon(Icons.candlestick_chart_outlined),
            label: const Text('Leader actions'),
          ),
        ],
      ],
    );
  }

  static String _short(String address) => address.length < 10
      ? address
      : '${address.substring(0, 6)}…${address.substring(address.length - 4)}';
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({required this.performance});

  final PoolPerformance performance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final returnBps = double.tryParse(performance.returnBps) ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Return', style: theme.textTheme.labelMedium),
                const Spacer(),
                Text(
                  formatBps(returnBps),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: returnBps >= 0
                        ? Colors.green.shade700
                        : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: NavSparkline(series: performance.series),
            ),
            if (performance.maxDrawdownBps != '0')
              Text(
                'Max drawdown ${formatBps(double.tryParse(performance.maxDrawdownBps) ?? 0)}',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _MyStake extends StatelessWidget {
  const _MyStake({required this.pool, required this.membership});

  final PoolInfo pool;
  final AsyncValue<PoolMembership> membership;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return switch (membership) {
      AsyncData(:final value) when value.holdsShares => Card(
        child: ListTile(
          title: Text(
            'You hold ${value.sharePercent} · ${value.shares} shares',
          ),
          subtitle: Text(
            'Worth about ${value.valueQuote}'
            '${value.hasQueuedRedeem ? ' · ${value.queuedShares} shares queued for redemption' : ''}',
          ),
          trailing: TextButton(
            onPressed: () =>
                showLeavePoolSheet(context, pool: pool, membership: value),
            child: const Text('Redeem'),
          ),
        ),
      ),
      AsyncData() => Text(
        'You hold no shares in this pool.',
        style: theme.textTheme.bodyMedium,
      ),
      AsyncError() => Text(
        'Your stake could not be read.',
        style: theme.textTheme.bodySmall,
      ),
      _ => const LinearProgressIndicator(),
    };
  }
}

/// A line of NAV per share over the series, drawn without a chart library.
class NavSparkline extends StatelessWidget {
  const NavSparkline({required this.series, super.key});

  final List<NavPoint> series;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _SparklinePainter(
      values: [for (final p in series) ?double.tryParse(p.navPerShare)],
      color: Theme.of(context).colorScheme.primary,
    ),
    size: Size.infinite,
  );
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final span = max - min == 0 ? 1 : max - min;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - size.height * (values[i] - min) / span;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}
