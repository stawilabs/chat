import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/pool_membership.dart';
import '../data/socialtrader_api.dart';
import '../data/wallet_service.dart';
import '../domain/pool_models.dart';
import 'join_pool_sheet.dart'
    show CommitDone, CommitIdle, CommitPreparing, CommitSigning, CommitState;

part 'leave_pool_sheet.g.dart';

/// Redeems all of a member's shares: asks the service for the redeem
/// calldata, then the wallet to sign and send it.
@riverpod
class LeavePoolController extends _$LeavePoolController {
  @override
  CommitState build(String pool) => const CommitIdle();

  Future<void> redeem(String shares) async {
    final wallet = ref.read(walletControllerProvider);
    final receiver = wallet.address;
    if (receiver == null || !wallet.canSign) {
      state = const CommitIdle(error: 'Connect a wallet that can sign first.');
      return;
    }
    state = const CommitPreparing();
    try {
      final tx = await ref
          .read(socialTraderApiProvider)
          .prepareRedeem(pool: pool, shares: shares, receiver: receiver);
      if (!ref.mounted) return;
      state = const CommitSigning();
      final hash = await ref
          .read(walletControllerProvider.notifier)
          .sendPrepared(tx);
      if (!ref.mounted) return;
      ref.invalidate(myMembershipProvider(pool));
      state = CommitDone(hash);
    } on Exception catch (e) {
      if (!ref.mounted) return;
      state = CommitIdle(
        error: switch (e) {
          WalletReadOnlyException(:final message) => message,
          WalletNotConnectedException(:final message) => message,
          WalletUnavailableException(:final message) => message,
          _ => 'Could not redeem: $e',
        },
      );
    }
  }
}

/// Opens the leave sheet for the person's stake in [pool].
Future<void> showLeavePoolSheet(
  BuildContext context, {
  required PoolInfo pool,
  required PoolMembership membership,
}) => showModalBottomSheet<void>(
  context: context,
  builder: (context) => SafeArea(
    child: LeavePoolSheet(pool: pool, membership: membership),
  ),
);

/// Shows what a member holds and what redeeming does, then redeems on a tap.
class LeavePoolSheet extends ConsumerWidget {
  const LeavePoolSheet({
    required this.pool,
    required this.membership,
    super.key,
  });

  final PoolInfo pool;
  final PoolMembership membership;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(leavePoolControllerProvider(pool.address));
    final busy = state is CommitPreparing || state is CommitSigning;
    final error = state is CommitIdle ? state.error : null;
    final feePercent = pool.performanceFeeBps / 100;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Redeem your shares', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'You hold ${membership.shares} shares (${membership.sharePercent} '
            'of the pool), worth about ${membership.valueQuote}.',
          ),
          const SizedBox(height: 4),
          if (membership.hasRedeemPreview)
            Text(
              'Redeeming now pays ${membership.previewAssets} after a '
              'performance fee of ${membership.previewFee.isEmpty ? '0' : membership.previewFee}.',
              key: const Key('leave-pool-preview'),
              style: theme.textTheme.bodySmall,
            )
          else
            Text(
              'A ${feePercent % 1 == 0 ? feePercent.toInt() : feePercent}% '
              'performance fee is taken only on gains above the pool\'s high '
              'water mark, paid when you redeem.',
              style: theme.textTheme.bodySmall,
            ),
          if (membership.hasQueuedRedeem) ...[
            const SizedBox(height: 8),
            Text(
              '${membership.queuedShares} shares are queued: the pool had no '
              'free quote to pay them yet. They settle once the leader sells '
              'inventory or the pool receives quote.',
              key: const Key('leave-pool-queued'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.tertiary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          switch (state) {
            CommitDone(:final txHash) => SelectableText(
              'Redeem sent: $txHash. If the pool lacks free quote your '
              'shares are queued and paid as it comes in.',
              style: theme.textTheme.bodySmall,
            ),
            _ => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      error,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                FilledButton(
                  onPressed: busy || !membership.holdsShares
                      ? null
                      : () => ref
                            .read(
                              leavePoolControllerProvider(pool.address)
                                  .notifier,
                            )
                            .redeem(membership.shares),
                  child: Text(switch (state) {
                    CommitPreparing() => 'Preparing…',
                    CommitSigning() => 'Waiting for your wallet…',
                    _ => 'Redeem',
                  }),
                ),
              ],
            ),
          },
        ],
      ),
    );
  }
}
