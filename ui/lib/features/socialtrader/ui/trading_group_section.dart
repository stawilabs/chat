import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/socialtrader_api.dart';
import '../data/socialtrader_capabilities.dart';
import '../domain/pool_models.dart';

part 'trading_group_section.g.dart';

/// The markets pools can trade.
@riverpod
Future<List<MarketInfo>> markets(Ref ref) =>
    ref.watch(socialTraderApiProvider).listMarkets();

/// What a new trading group asks the service to create its pool with.
@immutable
class TradingGroupDraft {
  const TradingGroupDraft({
    this.enabled = false,
    this.marketId = '',
    this.feePercent = '10',
    this.minLeaderSkinPercent = '0',
    this.maxTvlQuote = '',
  });

  final bool enabled;
  final String marketId;

  /// Performance fee on gains, in percent (10 = 1000 bps).
  final String feePercent;

  /// The least share of the pool the leader must hold, in percent.
  final String minLeaderSkinPercent;

  /// Cap on the pool's value in quote; empty for none.
  final String maxTvlQuote;

  int? get feeBps => _bps(feePercent);
  int? get minLeaderSkinBps => _bps(minLeaderSkinPercent);

  /// Why the draft cannot be sent yet, or null when it can.
  String? get problem {
    if (!enabled) return null;
    if (marketId.isEmpty) return 'Choose a market for the pool.';
    final fee = feeBps;
    if (fee == null || fee > 5000) {
      return 'The performance fee must be between 0% and 50%.';
    }
    final skin = minLeaderSkinBps;
    if (skin == null || skin > 10000) {
      return 'The leader share must be between 0% and 100%.';
    }
    if (maxTvlQuote.isNotEmpty && (double.tryParse(maxTvlQuote) ?? -1) < 0) {
      return 'The value cap must be a number.';
    }
    return null;
  }

  TradingGroupDraft copyWith({
    bool? enabled,
    String? marketId,
    String? feePercent,
    String? minLeaderSkinPercent,
    String? maxTvlQuote,
  }) => TradingGroupDraft(
    enabled: enabled ?? this.enabled,
    marketId: marketId ?? this.marketId,
    feePercent: feePercent ?? this.feePercent,
    minLeaderSkinPercent: minLeaderSkinPercent ?? this.minLeaderSkinPercent,
    maxTvlQuote: maxTvlQuote ?? this.maxTvlQuote,
  );

  static int? _bps(String percent) {
    final value = double.tryParse(percent.trim());
    if (value == null || value < 0) return null;
    return (value * 100).round();
  }
}

/// The "Trading group" toggle of group creation, shown only when the service
/// announces it can create pools; opened, it asks for the market and fees.
class TradingGroupSection extends ConsumerWidget {
  const TradingGroupSection({
    required this.draft,
    required this.onChanged,
    super.key,
  });

  final TradingGroupDraft draft;
  final ValueChanged<TradingGroupDraft> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCreate = ref.watch(canCreatePoolProvider).asData?.value ?? false;
    if (!canCreate) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const Key('create-trading-group'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Trading group'),
          subtitle: const Text(
            'Creates a strategy pool this group commits to. You lead it with '
            'your linked wallet.',
          ),
          value: draft.enabled,
          onChanged: (v) => onChanged(draft.copyWith(enabled: v)),
        ),
        if (draft.enabled) ...[
          const SizedBox(height: 8),
          _MarketField(draft: draft, onChanged: onChanged),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('create-trading-fee'),
                  initialValue: draft.feePercent,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Performance fee %',
                    helperText: 'On gains, paid on redeem',
                  ),
                  onChanged: (v) => onChanged(draft.copyWith(feePercent: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: const Key('create-trading-skin'),
                  initialValue: draft.minLeaderSkinPercent,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Leader share %',
                    helperText: 'Least the leader holds',
                  ),
                  onChanged: (v) =>
                      onChanged(draft.copyWith(minLeaderSkinPercent: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('create-trading-cap'),
            initialValue: draft.maxTvlQuote,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Value cap (quote, optional)',
            ),
            onChanged: (v) => onChanged(draft.copyWith(maxTvlQuote: v)),
          ),
          if (draft.problem case final problem?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                problem,
                key: const Key('create-trading-problem'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _MarketField extends ConsumerWidget {
  const _MarketField({required this.draft, required this.onChanged});

  final TradingGroupDraft draft;
  final ValueChanged<TradingGroupDraft> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markets = ref.watch(marketsProvider);
    return switch (markets) {
      AsyncData(:final value) => DropdownButtonFormField<String>(
        key: const Key('create-trading-market'),
        initialValue: draft.marketId.isEmpty ? null : draft.marketId,
        decoration: const InputDecoration(labelText: 'Market'),
        items: [
          for (final m in value.where((m) => m.active))
            DropdownMenuItem(value: m.marketId, child: Text(m.symbol)),
        ],
        onChanged: (v) => onChanged(draft.copyWith(marketId: v ?? '')),
      ),
      AsyncError() => const Text("Markets couldn't be loaded."),
      _ => const LinearProgressIndicator(),
    };
  }
}
