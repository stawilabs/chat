import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show bytesToHex0x;

import '../data/stawi_account_service.dart';
import '../domain/account_protection.dart';
import 'loan_widgets.dart' show settleThenRefresh, waitingForCompletion;
import 'money_review_sheet.dart';
import 'stawi_feedback.dart';

/// What a guardian can and cannot do from this app today: the chain takes a
/// guardian's approval only as a key's own signature, and settlement
/// prepares one only for the profile that owns that key.
const String guardianActsNote =
    'Your guardians start and approve a recovery with their own keys. The '
    'Stawi app cannot sign as someone else\'s guardian yet, so a recovery is '
    'started outside the app; when one is under way it shows here, and you '
    'can contest it.';

/// The recovery status of an account, as a banner: a recovery under way, a
/// freeze, or a guardian change waiting. Nothing when there is none.
class AccountProtectionBanner extends StatelessWidget {
  const AccountProtectionBanner({
    required this.state,
    this.thisDevice,
    super.key,
  });

  final settlement.AccountState state;
  final Uint8List? thisDevice;

  @override
  Widget build(BuildContext context) {
    final p = AccountProtection.of(state);
    final line = p.headline(thisDevice: thisDevice);
    if (line == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final alarming = p.recovering || p.frozen || p.guardianFrozen;
    return Card(
      key: const Key('account-protection-banner'),
      color: alarming ? scheme.errorContainer : scheme.secondaryContainer,
      child: ListTile(
        leading: Icon(
          p.recovering
              ? Icons.restore
              : p.frozen || p.guardianFrozen
              ? Icons.ac_unit
              : Icons.schedule,
          color: alarming ? scheme.onErrorContainer : null,
        ),
        title: Text(
          line,
          style: TextStyle(color: alarming ? scheme.onErrorContainer : null),
        ),
      ),
    );
  }
}

/// The account's guardians and any recovery: add or remove a guardian,
/// cancel a guardian change before it applies, and contest a recovery the
/// person did not ask for. Every change is prepared by settlement, checked
/// on this device, reviewed and signed behind the device lock.
class AccountProtectionScreen extends ConsumerStatefulWidget {
  const AccountProtectionScreen({super.key});

  @override
  ConsumerState<AccountProtectionScreen> createState() =>
      _AccountProtectionScreenState();
}

class _AccountProtectionScreenState
    extends ConsumerState<AccountProtectionScreen> {
  bool _busy = false;
  bool _settling = false;

  Future<void> _run(Future<PreparedMoneyCall> Function() prepare) async {
    final container = moneyContainer(context);
    final service = ref.read(stawiAccountServiceProvider);
    setState(() => _busy = true);
    try {
      final call = await runMoneyAction(context, ref, prepare);
      if (call == null) return;
      if (mounted) setState(() => _settling = true);
      await settleThenRefresh(container, service, call, [
        stawiAccountStatusProvider,
      ]);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _settling = false;
        });
      }
    }
  }

  Future<void> _add(settlement.AccountState state) async {
    final choice = await showDialog<(Uint8List, int)>(
      context: context,
      builder: (_) => AddGuardianDialog(current: state.guardians.length),
    );
    if (choice == null || !mounted) return;
    final service = ref.read(stawiAccountServiceProvider);
    await _run(
      () => service.prepareGuardianChange(
        guardian: choice.$1,
        add: true,
        threshold: choice.$2,
      ),
    );
  }

  Future<void> _remove(Uint8List guardian) async {
    final service = ref.read(stawiAccountServiceProvider);
    await _run(
      () => service.prepareGuardianChange(guardian: guardian, add: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(stawiAccountStatusProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Guardians and recovery')),
      body: status.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(stawiErrorMessage(error))),
        data: (status) {
          final state = status.state;
          if (state == null || !status.deployed) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Your account is not on chain yet. Guardians can be added '
                  'once it is.',
                ),
              ),
            );
          }
          return _body(context, status, state);
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    StawiAccountStatus status,
    settlement.AccountState state,
  ) {
    final p = AccountProtection.of(state);
    final service = ref.read(stawiAccountServiceProvider);
    final canSign = status.deviceRegistered && !_busy;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AccountProtectionBanner(
          state: state,
          thisDevice: status.deviceKey.address,
        ),
        if (p.canContest && status.deviceRegistered)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FilledButton.icon(
              key: const Key('contest-recovery'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: canSign
                  ? () => _run(service.prepareContestRecovery)
                  : null,
              icon: const Icon(Icons.report_outlined),
              label: const Text('This was not me: contest the recovery'),
            ),
          ),
        if (!status.deviceRegistered) ...[
          const SizedBox(height: 8),
          Card(
            key: const Key('recovery-this-device'),
            child: ListTile(
              leading: const Icon(Icons.phonelink_lock_outlined),
              title: const Text('This phone is not a key of your account'),
              subtitle: Text(
                'If you still have a phone that is, add this one from it '
                '(Stawi account, Add another device key). If you lost every '
                'phone, your guardians can recover the account to this '
                'phone\'s key:\n${status.deviceKey.keyId}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Copy this phone\'s key',
                onPressed: () => Clipboard.setData(
                  ClipboardData(text: status.deviceKey.keyId),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text('Your guardians', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          p.guardians.isEmpty
              ? 'You have no guardians. Without them, losing every phone '
                    'means losing the account.'
              : '${p.threshold} of ${p.guardians.length} must agree to '
                    'recover your account.',
          key: const Key('guardian-summary'),
        ),
        for (final g in p.guardians)
          ListTile(
            key: Key('guardian-${bytesToHex0x(g).toLowerCase()}'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.shield_outlined),
            title: Text(bytesToHex0x(g).toLowerCase()),
            trailing: TextButton(
              onPressed: canSign && p.pendingChangeAt == null
                  ? () => _remove(g)
                  : null,
              child: const Text('Remove'),
            ),
          ),
        const SizedBox(height: 8),
        if (p.pendingChangeAt != null)
          OutlinedButton.icon(
            key: const Key('cancel-guardian-change'),
            onPressed: canSign
                ? () => _run(service.prepareCancelGuardianChange)
                : null,
            icon: const Icon(Icons.undo),
            label: const Text('Cancel the waiting change'),
          )
        else
          OutlinedButton.icon(
            key: const Key('add-guardian'),
            onPressed: canSign && !p.recovering ? () => _add(state) : null,
            icon: const Icon(Icons.add_moderator_outlined),
            label: const Text('Add a guardian'),
          ),
        if (_settling)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(waitingForCompletion),
          ),
        const SizedBox(height: 16),
        Text(
          'To replace a guardian, remove them and add the new one once the '
          'removal has taken effect (each change waits 24 hours).',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          guardianActsNote,
          key: const Key('guardian-acts-note'),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Asks for a guardian's key (a 20-byte address) and how many guardians must
/// agree once it is added; pops (guardian, threshold).
class AddGuardianDialog extends StatefulWidget {
  const AddGuardianDialog({required this.current, super.key});

  /// How many guardians the account has now.
  final int current;

  @override
  State<AddGuardianDialog> createState() => _AddGuardianDialogState();
}

class _AddGuardianDialogState extends State<AddGuardianDialog> {
  final _controller = TextEditingController();
  late int _threshold = _defaultThreshold(widget.current + 1);
  String? _error;

  /// A majority of the guardians after the change.
  static int _defaultThreshold(int n) => n ~/ 2 + 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    try {
      Navigator.of(context)
          .pop((parseKeyAddress(_controller.text), _threshold));
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.current + 1;
    return AlertDialog(
      title: const Text('Add a guardian'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'A guardian is someone you trust who holds their own key. Paste '
            'the key they give you.',
          ),
          TextField(
            key: const Key('guardian-key'),
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Guardian key (0x…)',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: const Key('guardian-threshold'),
            initialValue: _threshold,
            decoration: const InputDecoration(
              labelText: 'Guardians who must agree',
            ),
            items: [
              for (var k = 1; k <= n; k++)
                DropdownMenuItem(value: k, child: Text('$k of $n')),
            ],
            onChanged: (v) => setState(() => _threshold = v ?? _threshold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('guardian-review'),
          onPressed: _submit,
          child: const Text('Review'),
        ),
      ],
    );
  }
}
