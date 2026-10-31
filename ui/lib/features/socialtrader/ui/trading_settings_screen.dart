import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/current_user_provider.dart';
import '../data/commitment_settings.dart';
import '../data/wallet_link.dart';
import '../data/wallet_service.dart';
import '../domain/pool_models.dart';

/// Trading settings: the wallet the app signs with, its link to the profile
/// (so the service knows which wallet is this person's), and the default
/// commitment the join sheet pre-fills.
class TradingSettingsScreen extends ConsumerStatefulWidget {
  const TradingSettingsScreen({super.key});

  @override
  ConsumerState<TradingSettingsScreen> createState() =>
      _TradingSettingsScreenState();
}

class _TradingSettingsScreenState extends ConsumerState<TradingSettingsScreen> {
  final _address = TextEditingController();
  final _commitment = TextEditingController();
  String? _commitmentNote;
  bool _commitmentError = false;
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
      if (saved != null) _commitment.text = saved;
    });
  }

  @override
  void dispose() {
    _address.dispose();
    _commitment.dispose();
    super.dispose();
  }

  Future<void> _saveCommitment() async {
    final profileId = await ref.read(currentProfileIdProvider.future);
    if (!mounted || profileId == null) return;
    final amount = tryNormalizeCommitment(_commitment.text);
    if (amount == null) {
      setState(() {
        _commitmentNote = 'Enter a positive amount.';
        _commitmentError = true;
      });
      return;
    }
    await ref.read(commitmentSettingsProvider).save(profileId, amount);
    if (!mounted) return;
    setState(() {
      _commitmentNote = 'Saved. The join sheet will pre-fill $amount.';
      _commitmentError = false;
    });
  }

  Future<void> _clearCommitment() async {
    final profileId = await ref.read(currentProfileIdProvider.future);
    if (!mounted || profileId == null) return;
    await ref.read(commitmentSettingsProvider).forget(profileId);
    if (!mounted) return;
    setState(() {
      _commitment.clear();
      _commitmentNote = 'Cleared.';
      _commitmentError = false;
    });
  }

  void _follow() {
    final address = _address.text.trim();
    if (!RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(address)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That is not an EVM address.')),
      );
      return;
    }
    ref.read(walletControllerProvider.notifier).setReadOnlyAddress(address);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wallet = ref.watch(walletControllerProvider);
    final linked = ref.watch(linkedWalletProvider);
    final linkState = ref.watch(walletLinkControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trading')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Wallet',
            child: _WalletSection(
              wallet: wallet,
              address: _address,
              onConnect: () =>
                  ref.read(walletControllerProvider.notifier).connect(),
              onDisconnect: () =>
                  ref.read(walletControllerProvider.notifier).disconnect(),
              onFollow: _follow,
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Linked to your profile',
            child: _LinkSection(
              wallet: wallet,
              linked: linked,
              state: linkState,
              onLink: () =>
                  ref.read(walletLinkControllerProvider.notifier).link(),
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Default commitment',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pre-fills the amount when you are invited to a pool. It '
                  'never commits by itself: every commitment is signed.',
                  style: theme.textTheme.bodySmall,
                ),
                TextField(
                  key: const Key('trading-default-commitment'),
                  controller: _commitment,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount (quote asset)',
                  ),
                ),
                if (_commitmentNote != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _commitmentNote!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _commitmentError
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _clearCommitment,
                      child: const Text('Clear'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saveCommitment,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    ),
  );
}

class _WalletSection extends StatelessWidget {
  const _WalletSection({
    required this.wallet,
    required this.address,
    required this.onConnect,
    required this.onDisconnect,
    required this.onFollow,
  });

  final WalletState wallet;
  final TextEditingController address;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (wallet.isConnected)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              wallet.canSign ? Icons.key : Icons.visibility_outlined,
            ),
            title: Text(wallet.shortAddress),
            subtitle: Text(
              wallet.canSign
                  ? 'Signs with ${wallet.signerLabel}'
                  : 'Read-only: follows the pool, cannot sign',
            ),
            trailing: TextButton(
              onPressed: onDisconnect,
              child: const Text('Forget'),
            ),
          ),
        if (wallet.error != null)
          Text(
            wallet.error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        if (wallet.signerAvailable)
          FilledButton(
            onPressed: wallet.connecting ? null : onConnect,
            child: Text(
              wallet.connecting
                  ? 'Connecting…'
                  : wallet.canSign
                  ? 'Reconnect wallet'
                  : 'Connect wallet',
            ),
          )
        else ...[
          Text(
            'This device cannot sign: open the app on the web with a browser '
            'wallet to commit, trade or link. Paste an address to follow a '
            'pool read-only.',
            style: theme.textTheme.bodySmall,
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('trading-address'),
                  controller: address,
                  decoration: const InputDecoration(labelText: '0x…'),
                ),
              ),
              TextButton(
                onPressed: onFollow,
                child: const Text('Follow address'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LinkSection extends StatelessWidget {
  const _LinkSection({
    required this.wallet,
    required this.linked,
    required this.state,
    required this.onLink,
  });

  final WalletState wallet;
  final AsyncValue<LinkedWallet?> linked;
  final LinkState state;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = linked.asData?.value;
    final alreadyLinked =
        current != null &&
        wallet.address != null &&
        current.wallet.toLowerCase() == wallet.address!.toLowerCase();
    final error = switch (state) {
      LinkIdle(:final error) => error,
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        switch (linked) {
          AsyncData(value: final l?) => ListTile(
            key: const Key('trading-linked-wallet'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.link),
            title: Text(_short(l.wallet)),
            subtitle: const Text(
              'Pools you lead and your stakes are recognised by this wallet.',
            ),
          ),
          AsyncData() => Text(
            'No wallet linked yet. Linking tells the trading service which '
            'wallet is yours; it signs a message, nothing else.',
            style: theme.textTheme.bodySmall,
          ),
          AsyncError() => Text(
            "The linked wallet couldn't be read.",
            style: theme.textTheme.bodySmall,
          ),
          _ => const LinearProgressIndicator(),
        },
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        if (wallet.canSign && !alreadyLinked) ...[
          const SizedBox(height: 8),
          FilledButton(
            onPressed: state is LinkWorking ? null : onLink,
            child: Text(switch (state) {
              LinkWorking(:final step) => step,
              _ => 'Link this wallet',
            }),
          ),
        ],
      ],
    );
  }

  static String _short(String a) =>
      a.length < 10 ? a : '${a.substring(0, 6)}…${a.substring(a.length - 4)}';
}
