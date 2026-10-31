import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/data/current_user_provider.dart';
import '../data/commitment_settings.dart';
import '../data/pool_membership.dart';
import '../data/pool_prompt_dismissals.dart';
import '../data/socialtrader_api.dart';
import '../data/wallet_service.dart';
import '../domain/pool_binding.dart';
import '../domain/pool_models.dart';

part 'join_pool_sheet.g.dart';

/// Where a commitment stands. Every step after idle follows one tap on
/// Commit; a failure returns to idle with its message so the person decides
/// whether to try again. Nothing retries by itself.
sealed class CommitState {
  const CommitState();
}

class CommitIdle extends CommitState {
  const CommitIdle({this.error});
  final String? error;
}

class CommitPreparing extends CommitState {
  const CommitPreparing();
}

class CommitSigning extends CommitState {
  const CommitSigning();
}

class CommitDone extends CommitState {
  const CommitDone(this.txHash);
  final String txHash;
}

/// Commits funds to a pool: asks the service for the deposit calldata, then
/// the wallet to sign and send it.
@riverpod
class JoinPoolController extends _$JoinPoolController {
  @override
  CommitState build(String pool) => const CommitIdle();

  Future<void> commit({required String amount, required bool remember}) async {
    final assets = tryNormalizeCommitment(amount);
    if (assets == null) {
      state = const CommitIdle(error: 'Enter a positive amount to commit.');
      return;
    }
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
          .prepareDeposit(pool: pool, assets: assets, receiver: receiver);
      if (!ref.mounted) return;
      state = const CommitSigning();
      final hash = await ref
          .read(walletControllerProvider.notifier)
          .sendPrepared(tx);
      if (!ref.mounted) return;
      // The deposit is sent once the wallet returned a hash: whatever happens
      // after that (remembering the amount) must never report it as failed,
      // or the person would commit twice.
      state = CommitDone(hash);
      ref.invalidate(myMembershipProvider(pool));
      if (remember) await _remember(assets);
    } on Exception catch (e) {
      if (!ref.mounted) return;
      state = CommitIdle(error: _describe(e));
    }
  }

  /// Saves the default; a failure here is logged by being ignored: the
  /// commitment already happened and the amount is only a convenience.
  Future<void> _remember(String assets) async {
    try {
      final profileId = await ref.read(currentProfileIdProvider.future);
      if (profileId != null) {
        await ref.read(commitmentSettingsProvider).save(profileId, assets);
      }
    } on Exception {
      // The commitment stands; the default simply was not saved.
    }
  }

  static String _describe(Exception e) => switch (e) {
    WalletReadOnlyException(:final message) => message,
    WalletNotConnectedException(:final message) => message,
    WalletUnavailableException(:final message) => message,
    _ => 'Could not commit: $e',
  };
}

/// Opens the join sheet for [pool] in [roomId].
Future<void> showJoinPoolSheet(
  BuildContext context, {
  required String roomId,
  required PoolInfo pool,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: JoinPoolSheet(roomId: roomId, pool: pool),
    ),
  ),
);

/// The sheet a new member commits from: an amount (pre-filled from the saved
/// default), the wallet to sign with, and one Commit button. It never sends
/// anything by itself.
class JoinPoolSheet extends ConsumerStatefulWidget {
  const JoinPoolSheet({
    required this.roomId,
    required this.pool,
    this.onDismiss,
    super.key,
  });

  final String roomId;
  final PoolInfo pool;

  /// Called when the person chooses "Not now" (the first-visit prompt).
  final VoidCallback? onDismiss;

  @override
  ConsumerState<JoinPoolSheet> createState() => _JoinPoolSheetState();
}

class _JoinPoolSheetState extends ConsumerState<JoinPoolSheet> {
  final _amount = TextEditingController();
  bool _remember = false;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final profileId = await ref.read(currentProfileIdProvider.future);
    if (!mounted || profileId == null) return;
    final saved = await ref
        .read(commitmentSettingsProvider)
        .defaultFor(profileId);
    if (!mounted || _prefilled) return;
    setState(() {
      _prefilled = true;
      if (saved != null && _amount.text.isEmpty) {
        _amount.text = saved;
        _remember = true;
      }
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wallet = ref.watch(walletControllerProvider);
    final state = ref.watch(joinPoolControllerProvider(widget.pool.address));
    final pool = widget.pool;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Commit to the pool', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'NAV per share ${pool.navPerShare} · ${pool.memberCount} members'
            ' · ${pool.performanceFeeBps / 100}% performance fee on gains',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          switch (state) {
            CommitDone(:final txHash) => _Done(txHash: txHash),
            _ => _Form(
              amount: _amount,
              remember: _remember,
              onRemember: (v) => setState(() => _remember = v),
              wallet: wallet,
              state: state,
              onConnect: () =>
                  ref.read(walletControllerProvider.notifier).connect(),
              onCommit: () => ref
                  .read(joinPoolControllerProvider(pool.address).notifier)
                  .commit(amount: _amount.text, remember: _remember),
            ),
          },
          if (widget.onDismiss != null && state is! CommitDone)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: widget.onDismiss,
                child: const Text('Not now'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.amount,
    required this.remember,
    required this.onRemember,
    required this.wallet,
    required this.state,
    required this.onConnect,
    required this.onCommit,
  });

  final TextEditingController amount;
  final bool remember;
  final ValueChanged<bool> onRemember;
  final WalletState wallet;
  final CommitState state;
  final VoidCallback onConnect;
  final VoidCallback onCommit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = state is CommitPreparing || state is CommitSigning;
    final error = switch (state) {
      CommitIdle(:final error) => error,
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('join-pool-amount'),
          controller: amount,
          enabled: !busy,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount to commit (quote asset)',
          ),
        ),
        CheckboxListTile(
          key: const Key('join-pool-remember'),
          value: remember,
          onChanged: busy ? null : (v) => onRemember(v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Remember this amount'),
        ),
        const SizedBox(height: 8),
        _WalletLine(wallet: wallet, onConnect: onConnect),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error,
            key: const Key('join-pool-error'),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        if (wallet.canSign)
          FilledButton(
            onPressed: busy ? null : onCommit,
            child: Text(switch (state) {
              CommitPreparing() => 'Preparing…',
              CommitSigning() => 'Waiting for your wallet…',
              _ => 'Commit',
            }),
          ),
      ],
    );
  }
}

class _WalletLine extends StatelessWidget {
  const _WalletLine({required this.wallet, required this.onConnect});

  final WalletState wallet;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (wallet.canSign) {
      return Text(
        'Signing with ${wallet.shortAddress}',
        style: theme.textTheme.bodySmall,
      );
    }
    if (!wallet.signerAvailable) {
      return Text(
        'This device cannot sign: open the app on the web with a browser '
        'wallet to commit. A pasted address only follows the pool.',
        key: const Key('join-pool-read-only'),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }
    if (wallet.isConnected && wallet.readOnly) {
      return Text(
        'This address was pasted and cannot sign. Connect the wallet to '
        'commit.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }
    final unavailable = wallet.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (unavailable != null)
          Text(
            unavailable,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          )
        else
          Text(
            'Connect the wallet that will hold your shares.',
            style: theme.textTheme.bodySmall,
          ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: wallet.connecting ? null : onConnect,
          child: Text(wallet.connecting ? 'Connecting…' : 'Connect wallet'),
        ),
      ],
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.txHash});

  final String txHash;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700),
          const SizedBox(width: 8),
          const Text('Commitment sent'),
        ],
      ),
      const SizedBox(height: 8),
      SelectableText(
        'Transaction $txHash. Your shares appear once it is mined.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.tonal(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Done'),
        ),
      ),
    ],
  );
}

/// Offers the join sheet once when a trading group is opened by a member who
/// holds no shares yet and has not dismissed it. It renders nothing itself.
class PoolJoinPromptGate extends ConsumerStatefulWidget {
  const PoolJoinPromptGate({required this.roomId, super.key});

  final String roomId;

  @override
  ConsumerState<PoolJoinPromptGate> createState() => _PoolJoinPromptGateState();
}

class _PoolJoinPromptGateState extends ConsumerState<PoolJoinPromptGate> {
  bool _offered = false;

  @override
  Widget build(BuildContext context) {
    final binding = ref.watch(poolBindingProvider(widget.roomId)).asData?.value;
    if (binding == null || _offered) return const SizedBox.shrink();
    final pool = ref.watch(poolByAddressProvider(binding.poolId)).asData?.value;
    final membership = ref
        .watch(myMembershipProvider(binding.poolId))
        .asData
        ?.value;
    if (pool == null || membership == null || membership.holdsShares) {
      return const SizedBox.shrink();
    }
    _offered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _offer(pool));
    return const SizedBox.shrink();
  }

  Future<void> _offer(PoolInfo pool) async {
    final dismissals = ref.read(poolPromptDismissalsProvider);
    if (await dismissals.dismissed(widget.roomId) || !mounted) return;
    // Recorded before the sheet opens: leaving the room mid-sheet, or the app
    // dying, still counts as the one offer.
    await dismissals.dismiss(widget.roomId);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: JoinPoolSheet(
          roomId: widget.roomId,
          pool: pool,
          onDismiss: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    );
  }
}
