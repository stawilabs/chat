import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show bytesToHex0x;

import '../data/guardian_contacts.dart';
import '../data/stawi_account_service.dart' show parseKeyAddress;
import '../domain/guardian_contacts.dart';
import '../domain/signing_checks.dart' show bytesEqual;
import 'stawi_feedback.dart';

/// A guardian the person chose: a contact's shared key, or a pasted one.
typedef GuardianChoice = ({Uint8List key, String? name});

/// Lets the person choose a guardian: one of their contacts who shared a
/// guardian key in their DM, or (to ask one who has not) a message asking
/// them to. Pasting a raw key is the advanced fallback. Keys in [exclude]
/// (the current guardians) are not offered. Null when dismissed.
Future<GuardianChoice?> showGuardianPicker(
  BuildContext context, {
  List<Uint8List> exclude = const [],
}) => showModalBottomSheet<GuardianChoice>(
  context: context,
  isScrollControlled: true,
  builder: (_) => SafeArea(child: GuardianPicker(exclude: exclude)),
);

class GuardianPicker extends ConsumerWidget {
  const GuardianPicker({this.exclude = const [], super.key});

  final List<Uint8List> exclude;

  Future<void> _ask(
    BuildContext context,
    WidgetRef ref,
    GuardianKeyOffer o,
  ) async {
    await runStawiAction(
      context,
      () =>
          ref.read(guardianMessageSenderProvider)(o.roomId, guardianAskMessage),
      success:
          'Asked ${o.name}. Once they share their guardian key in your '
          'chat, choose them here.',
    );
  }

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
    final offers = ref.watch(guardianKeyOffersProvider);
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
            'Someone you trust who uses Stawi. They register their phone as '
            'a guardian key and share it with you in your chat.',
          ),
        ),
        Flexible(
          child: offers.when(
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
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Start a direct message with someone to ask them to be '
                      'your guardian.',
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [for (final o in list) _tile(context, ref, o)],
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

  Widget _tile(BuildContext context, WidgetRef ref, GuardianKeyOffer o) {
    final key = o.key;
    final already = key != null && exclude.any((g) => bytesEqual(g, key));
    if (key == null) {
      return ListTile(
        key: Key('guardian-offer-${o.roomId}'),
        leading: const Icon(Icons.person_outline),
        title: Text(o.name),
        subtitle: const Text('Has not shared a guardian key'),
        trailing: TextButton(
          key: Key('guardian-ask-${o.roomId}'),
          onPressed: () => _ask(context, ref, o),
          child: const Text('Ask'),
        ),
      );
    }
    return ListTile(
      key: Key('guardian-offer-${o.roomId}'),
      enabled: !already,
      leading: const Icon(Icons.shield_outlined),
      title: Text(o.name),
      subtitle: Text(
        already
            ? 'Already your guardian'
            : 'Guardian key ${shortHex(bytesToHex0x(key).toLowerCase())}',
      ),
      onTap: already
          ? null
          : () =>
                Navigator.of(context)
                    .pop<GuardianChoice>((key: key, name: o.name)),
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
