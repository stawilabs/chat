import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show bytesToHex0x;

import '../../../core/networking/api_config.dart';
import '../data/stawi_account_service.dart';
import '../domain/stawi_money.dart';
import 'stawi_feedback.dart';

/// The profile's Stawi account: its address, whether it is deployed on chain,
/// and this device's key. Deploying signs the genesis with this device's key;
/// a deployed account can add another device's key from here.
class StawiAccountScreen extends ConsumerWidget {
  StawiAccountScreen({bool? showTestFunds, super.key})
    : showTestFunds = showTestFunds ?? ApiConfig.testFundsEnabled;

  /// Offer the testnet faucet; never in production builds.
  final bool showTestFunds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(stawiAccountStatusProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stawi account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(stawiAccountStatusProvider),
          ),
        ],
      ),
      body: status.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: stawiErrorMessage(error),
          onRetry: () => ref.invalidate(stawiAccountStatusProvider),
        ),
        data: (status) =>
            _AccountView(status: status, showTestFunds: showTestFunds),
      ),
    );
  }
}

class _AccountView extends ConsumerStatefulWidget {
  const _AccountView({required this.status, required this.showTestFunds});

  final StawiAccountStatus status;
  final bool showTestFunds;

  @override
  ConsumerState<_AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends ConsumerState<_AccountView> {
  bool _busy = false;

  Future<void> _deploy() async {
    setState(() => _busy = true);
    final result = await runStawiAction(
      context,
      () => ref.read(stawiAccountServiceProvider).deploy(),
      success: 'Deployment requested',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result != null) ref.invalidate(stawiAccountStatusProvider);
  }

  /// Mints test funds of [asset], the one the faucet names.
  Future<void> _getTestFunds(StawiAsset asset) async {
    final amount = await showDialog<String>(
      context: context,
      builder: (context) => _TestFundsDialog(asset: asset),
    );
    if (amount == null || !mounted) return;
    setState(() => _busy = true);
    final funded = await runStawiAction(
      context,
      () =>
          ref.read(stawiAccountServiceProvider).fundTestAccount(amount, asset),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (funded != null) {
      final minted = funded.hasAsset()
          ? StawiAsset.fromInfo(funded.asset)
          : asset;
      String shown(String units) {
        final n = BigInt.tryParse(units);
        return n == null ? units : formatUnits(n, minted);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Minting ${shown(funded.amount)} '
            '(${shown(funded.mintedToday)} of ${shown(funded.dailyLimit)} '
            'today)',
          ),
        ),
      );
    }
  }

  Future<void> _addKey() async {
    final keyId = await showDialog<String>(
      context: context,
      builder: (context) => const _AddKeyDialog(),
    );
    if (keyId == null || !mounted) return;
    setState(() => _busy = true);
    await runStawiAction(
      context,
      () => ref
          .read(stawiAccountServiceProvider)
          .addDeviceKey(parseKeyAddress(keyId)),
      success: 'Device key submitted; it becomes active after its delay',
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final theme = Theme.of(context);
    final account = status.account;
    final state = status.state;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Account'),
                subtitle: Text(
                  account == null
                      ? 'Your profile has no Stawi account yet'
                      : account.hex,
                ),
                trailing: account == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'Copy address',
                        onPressed: () =>
                            Clipboard.setData(ClipboardData(text: account.hex)),
                      ),
              ),
              if (account != null)
                ListTile(
                  key: const Key('stawi-account-state'),
                  leading: Icon(
                    status.deployed ? Icons.verified : Icons.cloud_off,
                    color: status.deployed
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  title: Text(_deploymentLabel(status)),
                  subtitle: state != null && status.deployed
                      ? Text(
                          'Nonce ${state.nonce} · ${state.keys.length} key(s)'
                          '${state.guardianFrozen || state.frozenAtBlock > 0 ? ' · frozen' : ''}',
                        )
                      : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.key_outlined),
            title: const Text('This device key'),
            subtitle: Text(
              '${status.deviceKey.keyId}\n'
              '${status.deviceRegistered ? 'Registered with your account' : 'Not registered with your account'}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Copy key id',
              onPressed: () => Clipboard.setData(
                ClipboardData(text: status.deviceKey.keyId),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The key never leaves this device. Only its public key id is shared.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        if (account != null && !status.deployed)
          FilledButton.icon(
            key: const Key('stawi-deploy-account'),
            onPressed: _busy || _deploying(status) ? null : _deploy,
            icon: const Icon(Icons.rocket_launch_outlined),
            label: Text(_deploying(status) ? 'Deploying…' : 'Deploy account'),
          ),
        if (status.deployed && status.deviceRegistered)
          OutlinedButton.icon(
            key: const Key('stawi-add-device-key'),
            onPressed: _busy ? null : _addKey,
            icon: const Icon(Icons.add),
            label: const Text('Add another device key'),
          ),
        if (status.deployed && !status.deviceRegistered)
          Text(
            'To sign from this device, add its key id from a device that is '
            'already registered with your account.',
            style: theme.textTheme.bodyMedium,
          ),
        if (widget.showTestFunds && account != null)
          ...?_testFunds(ref.watch(stawiTestAssetProvider).asData?.value),
      ],
    );
  }

  /// The faucet button, when the deployment's faucet is on; it mints the
  /// asset GetAsset names.
  List<Widget>? _testFunds(settlement.GetAssetResponse? faucet) {
    if (faucet == null || !faucet.faucetEnabled || !faucet.hasAsset()) {
      return null;
    }
    final asset = StawiAsset.fromInfo(faucet.asset);
    return [
      const SizedBox(height: 24),
      TextButton.icon(
        key: const Key('stawi-test-funds'),
        onPressed: _busy ? null : () => _getTestFunds(asset),
        icon: const Icon(Icons.science_outlined),
        label: Text('Get test ${asset.symbol} (testnet)'),
      ),
    ];
  }

  static bool _deploying(StawiAccountStatus status) =>
      status.genesisState == 'PENDING' || status.genesisState == 'SUBMITTED';

  static String _deploymentLabel(StawiAccountStatus status) {
    if (status.deployed) return 'Deployed on chain';
    return switch (status.genesisState) {
      'PENDING' || 'SUBMITTED' => 'Deployment in progress',
      'FAILED' => 'Deployment failed; you can try again',
      _ => 'Not deployed yet',
    };
  }
}

class _AddKeyDialog extends StatefulWidget {
  const _AddKeyDialog();

  @override
  State<_AddKeyDialog> createState() => _AddKeyDialogState();
}

class _AddKeyDialogState extends State<_AddKeyDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    try {
      final bytes = parseKeyAddress(_controller.text);
      Navigator.of(context).pop(bytesToHex0x(bytes));
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add device key'),
    content: TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: 'Device key id (0x…)',
        errorText: _error,
      ),
      autofocus: true,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Sign and add')),
    ],
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

class _TestFundsDialog extends StatefulWidget {
  const _TestFundsDialog({required this.asset});

  final StawiAsset asset;

  @override
  State<_TestFundsDialog> createState() => _TestFundsDialogState();
}

class _TestFundsDialogState extends State<_TestFundsDialog> {
  final _controller = TextEditingController(text: '1000');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Get test funds'),
    content: TextField(
      key: const Key('stawi-test-funds-amount'),
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Amount',
        suffixText: widget.asset.symbol,
        helperText: 'Test ${widget.asset.symbol}, minted to your account',
        errorText: _error,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('stawi-test-funds-confirm'),
        onPressed: () {
          final amount = _controller.text.trim();
          try {
            parseAmountInput(amount, widget.asset);
          } on FormatException catch (e) {
            setState(() => _error = e.message);
            return;
          }
          Navigator.of(context).pop(amount);
        },
        child: const Text('Mint'),
      ),
    ],
  );
}
