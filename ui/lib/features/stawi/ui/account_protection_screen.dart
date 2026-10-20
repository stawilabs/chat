import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show bytesToHex0x;

import '../data/guardian_contacts.dart';
import '../data/stawi_account_service.dart';
import '../domain/account_protection.dart';
import 'guardian_picker.dart';
import 'loan_widgets.dart' show settleThenRefresh, waitingForCompletion;
import 'money_review_sheet.dart';
import 'stawi_feedback.dart';

/// How the person's guardians act: from their own phones.
const String guardianActsNote =
    'Your guardians start and approve a recovery from their own phones '
    '(Stawi account, People I guard), each with their own guardian key. When '
    'one is under way it shows here, and you can contest it.';

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

  /// The guardian set and threshold the change leads to, prepared as one
  /// SET_GUARDIANS.
  Future<void> _set(
    List<Uint8List> guardians,
    int threshold,
    GuardianSetChange change,
  ) async {
    final service = ref.read(stawiAccountServiceProvider);
    await _run(
      () => service.prepareGuardianSet(
        guardians: guardians,
        threshold: threshold,
        change: change,
      ),
    );
  }

  List<Uint8List> _current(settlement.AccountState state) => [
    for (final g in state.guardians) Uint8List.fromList(g),
  ];

  Future<void> _add(settlement.AccountState state) async {
    final current = _current(state);
    final choice = await showGuardianPicker(context, exclude: current);
    if (choice == null || !mounted) return;
    final n = current.length + 1;
    final k = await showGuardianThresholdDialog(
      context,
      n: n,
      initial: n ~/ 2 + 1,
    );
    if (k == null || !mounted) return;
    await _set(
      [...current, choice.key],
      k,
      GuardianAdded(choice.key, name: choice.name),
    );
  }

  Future<void> _replace(settlement.AccountState state, Uint8List old) async {
    final choice = await showGuardianPicker(context, exclude: _current(state));
    if (choice == null || !mounted) return;
    final after = guardianSetReplacing(state, old, choice.key);
    await _set(
      after.guardians,
      after.threshold,
      GuardianReplaced(old, choice.key, name: choice.name),
    );
  }

  Future<void> _remove(settlement.AccountState state, Uint8List g) async {
    final after = guardianSetAfter(state, g, add: false);
    await _set(after.guardians, after.threshold, GuardianRemoved(g));
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
    final canChange = canSign && p.pendingChangeAt == null && !p.recovering;
    final theme = Theme.of(context);
    final names =
        ref.watch(guardianNamesProvider).asData?.value ??
        const <String, String>{};
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
            title: Text(
              names[bytesToHex0x(g).toLowerCase()] ??
                  bytesToHex0x(g).toLowerCase(),
            ),
            subtitle: names.containsKey(bytesToHex0x(g).toLowerCase())
                ? Text(shortHex(bytesToHex0x(g).toLowerCase()))
                : null,
            trailing: Wrap(
              children: [
                TextButton(
                  key: Key('guardian-replace-${bytesToHex0x(g).toLowerCase()}'),
                  onPressed: canChange ? () => _replace(state, g) : null,
                  child: const Text('Replace'),
                ),
                TextButton(
                  key: Key('guardian-remove-${bytesToHex0x(g).toLowerCase()}'),
                  onPressed: canChange ? () => _remove(state, g) : null,
                  child: const Text('Remove'),
                ),
              ],
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
          'Adding, removing or replacing a guardian is one change; it takes '
          'effect after 24 hours, and you can cancel it until then.',
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
