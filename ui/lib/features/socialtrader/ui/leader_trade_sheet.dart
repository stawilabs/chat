import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/socialtrader_api.dart';
import '../data/wallet_service.dart';
import '../domain/pool_models.dart';
import 'join_pool_sheet.dart'
    show CommitDone, CommitIdle, CommitPreparing, CommitSigning, CommitState;

part 'leader_trade_sheet.g.dart';

/// The order book of [marketId], top levels.
@riverpod
Future<OrderBook> marketBook(Ref ref, String marketId) =>
    ref.watch(socialTraderApiProvider).getBook(marketId);

/// Sends one leader call: asks the service for its calldata, then the wallet
/// to sign and send it. The contract enforces onlyLeader; the sheet is only a
/// convenience for the leader.
@riverpod
class LeaderOrderController extends _$LeaderOrderController {
  @override
  CommitState build(String pool) => const CommitIdle();

  Future<void> send(LeaderOrder order) async {
    final wallet = ref.read(walletControllerProvider);
    if (!wallet.canSign) {
      state = const CommitIdle(error: 'Connect the leader wallet first.');
      return;
    }
    state = const CommitPreparing();
    try {
      final tx = await ref
          .read(socialTraderApiProvider)
          .prepareLeaderOrder(order);
      if (!ref.mounted) return;
      state = const CommitSigning();
      final hash = await ref
          .read(walletControllerProvider.notifier)
          .sendPrepared(tx);
      if (!ref.mounted) return;
      state = CommitDone(hash);
    } on Exception catch (e) {
      if (!ref.mounted) return;
      state = CommitIdle(
        error: switch (e) {
          WalletReadOnlyException(:final message) => message,
          WalletNotConnectedException(:final message) => message,
          WalletUnavailableException(:final message) => message,
          _ => 'Could not send: $e',
        },
      );
    }
  }

  void reset() => state = const CommitIdle();
}

/// Opens the leader's trading sheet for [pool].
Future<void> showLeaderTradeSheet(
  BuildContext context, {
  required PoolInfo pool,
  String queuedShares = '0',
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: LeaderTradeSheet(pool: pool, queuedShares: queuedShares),
      ),
    ),
  ),
);

enum _OrderKind { limit, ioc }

/// How many queued redeems one "Settle queue" call settles (max_levels
/// carries maxItems for KIND_SETTLE_QUEUE).
const int settleQueueBatch = 10;

/// The leader's order entry: limit or IOC, side, price pre-filled from the
/// book's best opposite level, size, a hint price from the book for limit
/// orders; plus cancel by id, claim to free, and selling inventory for queued
/// redeems. Every button prepares one call and asks the wallet to sign.
class LeaderTradeSheet extends ConsumerStatefulWidget {
  const LeaderTradeSheet({
    required this.pool,
    this.queuedShares = '0',
    super.key,
  });

  final PoolInfo pool;

  /// Shares queued for redemption; selling inventory is offered when > 0.
  final String queuedShares;

  @override
  ConsumerState<LeaderTradeSheet> createState() => _LeaderTradeSheetState();
}

class _LeaderTradeSheetState extends ConsumerState<LeaderTradeSheet> {
  _OrderKind _kind = _OrderKind.limit;
  bool _isBid = true;
  final _price = TextEditingController();
  final _size = TextEditingController();
  final _cancelId = TextEditingController();
  String? _formError;
  OrderBook? _book;

  bool get _hasQueue => (double.tryParse(widget.queuedShares) ?? 0) > 0;

  @override
  void dispose() {
    _price.dispose();
    _size.dispose();
    _cancelId.dispose();
    super.dispose();
  }

  /// Pre-fills the price with the best opposite level: a bid takes the best
  /// ask, an ask the best bid.
  void _prefill(OrderBook book) {
    final price = _isBid ? book.bestAsk : book.bestBid;
    _price.text = price.isEmpty ? book.lastTradePrice : price;
  }

  /// The hint for a limit order: the best level on the same side, where the
  /// order is likely to rest.
  String _hint(OrderBook? book) {
    if (book == null || _kind != _OrderKind.limit) return '';
    return _isBid ? book.bestBid : book.bestAsk;
  }

  void _place() {
    final price = _price.text.trim();
    final size = _size.text.trim();
    if ((double.tryParse(size) ?? 0) <= 0) {
      setState(() => _formError = 'Enter a size above zero.');
      return;
    }
    if ((double.tryParse(price) ?? 0) <= 0) {
      setState(() => _formError = 'Enter a price above zero.');
      return;
    }
    setState(() => _formError = null);
    ref
        .read(leaderOrderControllerProvider(widget.pool.address).notifier)
        .send(
          LeaderOrder(
            pool: widget.pool.address,
            kind: _kind == _OrderKind.limit
                ? LeaderOrderKind.limit
                : LeaderOrderKind.ioc,
            isBid: _isBid,
            price: price,
            baseAmount: size,
            hintPrice: _hint(_book),
          ),
        );
  }

  void _cancel() {
    final id = int.tryParse(_cancelId.text.trim());
    if (id == null || id <= 0) {
      setState(() => _formError = 'Enter the order id to cancel.');
      return;
    }
    setState(() => _formError = null);
    ref
        .read(leaderOrderControllerProvider(widget.pool.address).notifier)
        .send(
          LeaderOrder(
            pool: widget.pool.address,
            kind: LeaderOrderKind.cancel,
            orderId: id,
          ),
        );
  }

  /// settleQueue(maxItems) is permissionless: it pays queued redeems from the
  /// pool's free quote, up to [settleQueueBatch] items per call.
  void _settleQueue() {
    setState(() => _formError = null);
    ref
        .read(leaderOrderControllerProvider(widget.pool.address).notifier)
        .send(
          LeaderOrder(
            pool: widget.pool.address,
            kind: LeaderOrderKind.settleQueue,
            maxLevels: settleQueueBatch,
          ),
        );
  }

  void _simple(LeaderOrderKind kind) {
    setState(() => _formError = null);
    ref
        .read(leaderOrderControllerProvider(widget.pool.address).notifier)
        .send(LeaderOrder(pool: widget.pool.address, kind: kind));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookAsync = ref.watch(marketBookProvider(widget.pool.marketId));
    ref.listen(marketBookProvider(widget.pool.marketId), (_, next) {
      final book = next.asData?.value;
      if (book != null && _book == null) {
        setState(() {
          _book = book;
          _prefill(book);
        });
      }
    });
    if (_book == null && bookAsync.hasValue) {
      _book = bookAsync.value;
      _prefill(_book!);
    }
    final state = ref.watch(leaderOrderControllerProvider(widget.pool.address));
    final busy = state is CommitPreparing || state is CommitSigning;
    final error =
        _formError ??
        switch (state) {
          CommitIdle(:final error) => error,
          _ => null,
        };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Trade for the pool', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          _BookLine(book: bookAsync),
          const SizedBox(height: 12),
          SegmentedButton<_OrderKind>(
            segments: const [
              ButtonSegment(
                value: _OrderKind.limit,
                label: Text('Limit', key: Key('leader-kind-limit')),
              ),
              ButtonSegment(
                value: _OrderKind.ioc,
                label: Text('IOC', key: Key('leader-kind-ioc')),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: busy
                ? null
                : (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Buy', key: Key('leader-side-buy')),
              ),
              ButtonSegment(
                value: false,
                label: Text('Sell', key: Key('leader-side-sell')),
              ),
            ],
            selected: {_isBid},
            onSelectionChanged: busy
                ? null
                : (s) => setState(() {
                    _isBid = s.first;
                    if (_book != null) _prefill(_book!);
                  }),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('leader-price'),
            controller: _price,
            enabled: !busy,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Price (quote)'),
          ),
          TextField(
            key: const Key('leader-size'),
            controller: _size,
            enabled: !busy,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Size (base)'),
          ),
          if (_kind == _OrderKind.limit && _hint(_book).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Hint price ${_hint(_book)} (from the book)',
                key: const Key('leader-hint'),
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 12),
          switch (state) {
            CommitDone(:final txHash) => Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(child: SelectableText('Sent: $txHash')),
                TextButton(
                  onPressed: () => ref
                      .read(
                        leaderOrderControllerProvider(widget.pool.address)
                            .notifier,
                      )
                      .reset(),
                  child: const Text('Another'),
                ),
              ],
            ),
            _ => FilledButton(
              onPressed: busy ? null : _place,
              child: Text(switch (state) {
                CommitPreparing() => 'Preparing…',
                CommitSigning() => 'Waiting for your wallet…',
                _ => 'Place order',
              }),
            ),
          },
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('leader-cancel-id'),
                  controller: _cancelId,
                  enabled: !busy,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Order id'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: busy ? null : _cancel,
                child: const Text('Cancel order'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: busy ? null : () => _simple(LeaderOrderKind.claim),
            child: const Text('Claim filled orders to free quote'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('leader-settle-queue'),
            onPressed: busy ? null : _settleQueue,
            child: const Text('Settle queue'),
          ),
          if (_hasQueue) ...[
            const SizedBox(height: 8),
            Text(
              '${widget.queuedShares} shares are queued for redemption.',
              style: theme.textTheme.bodySmall,
            ),
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () => _simple(LeaderOrderKind.sellForRedeems),
              child: const Text('Sell inventory for redeems'),
            ),
          ],
        ],
      ),
    );
  }
}

class _BookLine extends StatelessWidget {
  const _BookLine({required this.book});

  final AsyncValue<OrderBook> book;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return switch (book) {
      AsyncData(:final value) => Text(
        'Book: bid ${value.bestBid.isEmpty ? '—' : value.bestBid} · '
        'ask ${value.bestAsk.isEmpty ? '—' : value.bestAsk}'
        '${value.lastTradePrice.isEmpty ? '' : ' · last ${value.lastTradePrice}'}',
        style: style,
      ),
      AsyncError() => Text("The book couldn't be read.", style: style),
      _ => Text('Reading the book…', style: style),
    };
  }
}
