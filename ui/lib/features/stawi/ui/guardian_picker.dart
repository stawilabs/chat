import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show bytesToHex0x;

import '../data/guardian_contacts.dart';
import '../data/stawi_account_service.dart' show parseKeyAddress;
import '../domain/signing_checks.dart' show bytesEqual;
import 'stawi_feedback.dart';

/// A guardian the person chose: a contact's registered key, or a pasted one.
typedef GuardianChoice = ({Uint8List key, String? name});

/// Lets the person choose a guardian: a contact from the Stawi rooms they
/// share, whose registered guardian key settlement's directory answers
/// (LookupGuardianKeys); no key travels as chat text. Pasting a raw key is
/// the advanced fallback. Keys in [exclude] (the current guardians) are not
/// offered. Null when dismissed.
Future<GuardianChoice?> showGuardianPicker(
  BuildContext context, {
  List<Uint8List> exclude = const [],
}) => showModalBottomSheet<GuardianChoice>(
  context: context,
  isScrollControlled: true,
  builder: (_) => SafeArea(child: GuardianPicker(exclude: exclude)),
);

/// How to become someone's guardian, for a contact who has not registered.
const String guardianRegisterHint =
    'Has not registered a guardian key. Ask them to open Stawi account, '
    'People I guard, and register their phone.';

class GuardianPicker extends ConsumerWidget {
  const GuardianPicker({this.exclude = const [], super.key});

  final List<Uint8List> exclude;

  Future<void> _paste(BuildContext context) async {
    final navigator = Navigator.of(context);
    final key = await showDialog<Uint8List>(
      context: context,
      builder: (_) => const _PasteKeyDialog(),
    );
    if (key != null) navigator.pop<GuardianChoice>((key: key, name: null));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(guardianContactsProvider);
    final theme = Theme.of(context);
    return Column(
      key: const Key('guardian-picker'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('Choose a guardian', style: theme.textTheme.titleMedium),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Someone you trust, from one of your Stawi groups or your direct '
            'messages, who registered their phone as a guardian key.',
          ),
        ),
        Flexible(
          child: contacts.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(stawiErrorMessage(e)),
            ),
            data: (list) => list.isEmpty
                ? const Padding(
                    key: Key('guardian-no-contacts'),
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Your guardian is chosen from the members of your '
                      'Stawi groups and the people you message. Message them '
                      'first, or paste their key below.',
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final c in list)
                        _ContactTile(contact: c, exclude: exclude),
                    ],
                  ),
          ),
        ),
        const Divider(),
        ListTile(
          key: const Key('guardian-paste'),
          leading: const Icon(Icons.content_paste),
          title: const Text('Paste a key instead'),
          subtitle: const Text('Advanced: a guardian key you got another way'),
          onTap: () => _paste(context),
        ),
      ],
    );
  }
}

/// One contact: their registered guardian keys as the directory answers
/// them, each one tap to choose.
class _ContactTile extends ConsumerWidget {
  const _ContactTile({required this.contact, required this.exclude});

  final GuardianContact contact;
  final List<Uint8List> exclude;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = ref.watch(guardianKeysOfProvider(contact.lookup));
    final c = contact;
    return keys.when(
      loading: () => ListTile(
        key: Key('guardian-offer-${c.profileId}'),
        leading: const Icon(Icons.person_outline),
        title: Text(c.name),
        subtitle: const Text('Looking up their guardian key…'),
      ),
      error: (e, _) => ListTile(
        key: Key('guardian-offer-${c.profileId}'),
        enabled: false,
        leading: const Icon(Icons.person_outline),
        title: Text(c.name),
        subtitle: Text(stawiErrorMessage(e)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return ListTile(
            key: Key('guardian-offer-${c.profileId}'),
            enabled: false,
            leading: const Icon(Icons.person_outline),
            title: Text(c.name),
            subtitle: const Text(guardianRegisterHint),
            isThreeLine: true,
          );
        }
        return Column(
          children: [
            for (final k in list)
              _keyTile(
                context,
                Uint8List.fromList(k.key),
                multiple: list.length > 1,
              ),
          ],
        );
      },
    );
  }

  Widget _keyTile(
    BuildContext context,
    Uint8List key, {
    required bool multiple,
  }) {
    final already = exclude.any((g) => bytesEqual(g, key));
    final hex = bytesToHex0x(key).toLowerCase();
    return ListTile(
      key: multiple
          ? Key('guardian-offer-${contact.profileId}-$hex')
          : Key('guardian-offer-${contact.profileId}'),
      enabled: !already,
      leading: const Icon(Icons.shield_outlined),
      title: Text(contact.name),
      subtitle: Text(
        already ? 'Already your guardian' : 'Guardian key ${shortHex(hex)}',
      ),
      onTap: already
          ? null
          : () =>
                Navigator.of(context)
                    .pop<GuardianChoice>((key: key, name: contact.name)),
    );
  }
}

class _PasteKeyDialog extends StatefulWidget {
  const _PasteKeyDialog();

  @override
  State<_PasteKeyDialog> createState() => _PasteKeyDialogState();
}

class _PasteKeyDialogState extends State<_PasteKeyDialog> {
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
    title: const Text('Paste a guardian key'),
    content: TextField(
      key: const Key('guardian-key'),
      controller: _controller,
      decoration: InputDecoration(
        labelText: 'Guardian key (0x…)',
        errorText: _error,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('guardian-key-use'),
        onPressed: _submit,
        child: const Text('Use this key'),
      ),
    ],
  );
}

/// Asks how many of [n] guardians must agree, starting at [initial]; null
/// when dismissed.
Future<int?> showGuardianThresholdDialog(
  BuildContext context, {
  required int n,
  required int initial,
}) => showDialog<int>(
  context: context,
  builder: (_) => _ThresholdDialog(n: n, initial: initial),
);

class _ThresholdDialog extends StatefulWidget {
  const _ThresholdDialog({required this.n, required this.initial});

  final int n;
  final int initial;

  @override
  State<_ThresholdDialog> createState() => _ThresholdDialogState();
}

class _ThresholdDialogState extends State<_ThresholdDialog> {
  late int _k = widget.initial.clamp(1, widget.n);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Guardians who must agree'),
    content: DropdownButtonFormField<int>(
      key: const Key('guardian-threshold'),
      initialValue: _k,
      items: [
        for (var k = 1; k <= widget.n; k++)
          DropdownMenuItem(value: k, child: Text('$k of ${widget.n}')),
      ],
      onChanged: (v) => setState(() => _k = v ?? _k),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('guardian-review'),
        onPressed: () => Navigator.of(context).pop(_k),
        child: const Text('Review'),
      ),
    ],
  );
}
