import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show bytesToHex0x;

import '../../profile/data/profile_providers.dart';
import '../data/stawi_account_service.dart'
    show deviceNotAKeyMessage, parseKeyAddress;
import '../data/stawi_guardian_service.dart';
import '../domain/guardian_acts.dart';
import '../domain/signing_checks.dart' show bytesEqual;
import 'money_review_sheet.dart';
import 'stawi_feedback.dart';

/// "People I guard": this phone as a guardian key (register it, share it
/// with someone), the accounts it guards with their recovery state, and the
/// guardian's acts on them (start or approve a recovery), each checked on
/// the device and signed with this phone's key behind the device lock.
class GuardedAccountsScreen extends ConsumerStatefulWidget {
  const GuardedAccountsScreen({super.key});

  @override
  ConsumerState<GuardedAccountsScreen> createState() =>
      _GuardedAccountsScreenState();
}

class _GuardedAccountsScreenState extends ConsumerState<GuardedAccountsScreen> {
  bool _registered = false;
  bool _busy = false;

  Future<void> _register() async {
    setState(() => _busy = true);
    final done = await runStawiAction(
      context,
      () => ref.read(stawiGuardianServiceProvider).registerGuardianKey(),
      success: 'This phone is your guardian key',
    );
    if (!mounted) return;
    if (done != null) ref.invalidate(stawiMyGuardianKeysProvider);
    setState(() {
      _busy = false;
      _registered = _registered || done != null;
    });
  }

  Future<void> _act(
    settlement.GuardedAccount account,
    settlement.AccountCallKind kind,
  ) async {
    Uint8List? newKey;
    if (kind == settlement.AccountCallKind.ACCOUNT_CALL_KIND_REQUEST_RECOVERY) {
      newKey = await showDialog<Uint8List>(
        context: context,
        builder: (_) => const _NewKeyDialog(),
      );
      if (newKey == null || !mounted) return;
    }
    setState(() => _busy = true);
    final service = ref.read(stawiGuardianServiceProvider);
    try {
      final prepared = await runStawiAction(
        context,
        () => service.prepareAct(
          address: Uint8List.fromList(account.address),
          kind: kind,
          newKey: newKey,
        ),
      );
      if (prepared == null || !mounted) return;
      if (!await showMoneyReview(context, prepared.review) || !mounted) return;
      await runStawiAction(
        context,
        () => service.submitAct(prepared),
        success: prepared.review.done,
      );
      ref.invalidate(stawiGuardedAccountsProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(stawiGuardianKeyStatusProvider);
    final guarded = ref.watch(stawiGuardedAccountsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('People I guard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          status.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(stawiErrorMessage(e)),
            data: (s) => _keyCard(context, s, guarded.asData?.value),
          ),
          const SizedBox(height: 16),
          Text('Accounts you guard', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          guarded.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(stawiErrorMessage(e)),
            data: (list) => list.isEmpty
                ? const Text(
                    'Nobody has named this phone as their guardian yet.',
                    key: Key('guarded-none'),
                  )
                : Column(
                    children: [
                      for (final a in list)
                        _GuardedCard(
                          account: a,
                          busy:
                              _busy ||
                              status.asData?.value.state !=
                                  GuardianKeyState.ready,
                          onAct: (kind) => _act(a, kind),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            guardianCannotCancelNote,
            key: const Key('guardian-cannot-cancel'),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _keyCard(
    BuildContext context,
    GuardianKeyStatus s,
    List<settlement.GuardedAccount>? guarded,
  ) {
    final hex = bytesToHex0x(s.key).toLowerCase();
    final inUse = guarded?.any((a) => bytesEqual(a.guardian, s.key)) ?? false;
    final mine = ref
        .watch(stawiMyGuardianKeysProvider)
        .asData
        ?.value
        .where((k) => bytesEqual(k.guardianKey.key, s.key))
        .firstOrNull;
    switch (s.state) {
      case GuardianKeyState.noAccount:
        return const Card(
          key: Key('guardian-no-account'),
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(
              'Set up your Stawi account first: your guardian key is this '
              'phone\'s key on your own account.',
            ),
          ),
        );
      case GuardianKeyState.notAKey:
        return const Card(
          key: Key('guardian-not-a-key'),
          child: ListTile(
            leading: Icon(Icons.phonelink_lock_outlined),
            title: Text(deviceNotAKeyMessage),
          ),
        );
      case GuardianKeyState.passkey:
        return Card(
          key: const Key('guardian-passkey'),
          color: Theme.of(context).colorScheme.errorContainer,
          child: const ListTile(
            leading: Icon(Icons.block),
            title: Text('Guarding is not available on this phone'),
            subtitle: Text(p256CannotGuardNote),
            isThreeLine: true,
          ),
        );
      case GuardianKeyState.ready:
        // Settlement's record of the person's guardian keys says whether
        // this phone is registered and still counts.
        final registered =
            (mine?.active ?? false) || inUse || (mine == null && _registered);
        final lapsed = mine != null && !mine.active && !inUse;
        return Card(
          key: const Key('guardian-key-card'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'This phone as a guardian key',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(hex, key: const Key('guardian-key-id')),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy this phone\'s guardian key',
                      onPressed: () =>
                          Clipboard.setData(ClipboardData(text: hex)),
                    ),
                  ],
                ),
                Text(
                  registered
                      ? 'Registered: members of your Stawi groups can now '
                            'choose you as their guardian.'
                      : lapsed
                      ? 'Registered, but it no longer counts: '
                            '${mine.inactiveReason.isEmpty ? 'register it again' : mine.inactiveReason}.'
                      : 'Register it to guard someone: your phone signs a '
                            'proof that it holds this key.',
                  key: const Key('guardian-registration'),
                ),
                const SizedBox(height: 8),
                if (!registered)
                  FilledButton.icon(
                    key: const Key('guardian-register'),
                    onPressed: _busy ? null : _register,
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Register this phone as a guardian key'),
                  ),
              ],
            ),
          ),
        );
    }
  }
}

class _GuardedCard extends ConsumerWidget {
  const _GuardedCard({
    required this.account,
    required this.busy,
    required this.onAct,
  });

  final settlement.GuardedAccount account;
  final bool busy;
  final void Function(settlement.AccountCallKind kind) onAct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = GuardedView(account);
    final hex = bytesToHex0x(account.address).toLowerCase();
    final owner = account.ownerProfileId.isEmpty
        ? null
        : ref.watch(profileByIdProvider(account.ownerProfileId)).asData?.value;
    final name = owner?.name?.trim() ?? '';
    final key = view.newKey;
    return Card(
      key: Key('guarded-$hex'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              name.isEmpty ? shortHex(hex) : '$name (${shortHex(hex)})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(view.headline(), key: Key('guarded-state-$hex')),
            const SizedBox(height: 8),
            if (view.canRequest)
              OutlinedButton.icon(
                key: Key('guarded-request-$hex'),
                onPressed: busy
                    ? null
                    : () => onAct(
                        settlement
                            .AccountCallKind
                            .ACCOUNT_CALL_KIND_REQUEST_RECOVERY,
                      ),
                icon: const Icon(Icons.restore),
                label: const Text('Start a recovery for them'),
              ),
            if (view.canApprove && key != null)
              FilledButton.icon(
                key: Key('guarded-approve-$hex'),
                onPressed: busy
                    ? null
                    : () => onAct(
                        settlement
                            .AccountCallKind
                            .ACCOUNT_CALL_KIND_APPROVE_RECOVERY,
                      ),
                icon: const Icon(Icons.how_to_reg_outlined),
                label: Text(
                  'Approve moving it to '
                  '${shortHex(bytesToHex0x(key).toLowerCase())}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Asks the guardian for the owner's new key: the key the owner's new phone
/// shows (Guardians and recovery, on a phone that is not a key of the
/// account).
class _NewKeyDialog extends StatefulWidget {
  const _NewKeyDialog();

  @override
  State<_NewKeyDialog> createState() => _NewKeyDialogState();
}

class _NewKeyDialogState extends State<_NewKeyDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    try {
      Navigator.of(context).pop(parseKeyAddress(_controller.text));
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Their new phone\'s key'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Their new phone shows its key under Stawi account, Guardians and '
          'recovery. Check it with them in person or on a call.',
        ),
        TextField(
          key: const Key('recovery-new-key'),
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'New key (0x…)',
            errorText: _error,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('recovery-new-key-review'),
        onPressed: _submit,
        child: const Text('Review'),
      ),
    ],
  );
}
