import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;

import '../../auth/data/current_user_provider.dart';
import '../../rooms/data/detail_panel_providers.dart';
import '../data/stawi_finance_service.dart';
import '../data/stawi_room_service.dart';
import '../domain/stawi_payloads.dart';
import '../domain/template_rules.dart';
import 'stawi_feedback.dart';

/// Turns a chat room into a Stawi room: the founder picks a constitution
/// template and its rule values, the founders among the room's members and
/// how the room opens, then sends the conversion into the room. Chat prepares
/// the genesis with settlement and posts it as the card founders sign.
class ConvertRoomScreen extends ConsumerStatefulWidget {
  const ConvertRoomScreen({required this.roomId, super.key});

  final String roomId;

  @override
  ConsumerState<ConvertRoomScreen> createState() => _ConvertRoomScreenState();
}

class _ConvertRoomScreenState extends ConsumerState<ConvertRoomScreen> {
  String? _templateId;
  final Map<String, TextEditingController> _rules = {
    for (final rule in templateRules) rule.key: TextEditingController(),
  };
  final Set<String> _founders = {};
  StawiJoinPolicy _joinPolicy = StawiJoinPolicy.private;
  bool _sending = false;

  @override
  void dispose() {
    for (final controller in _rules.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final templateId = _templateId;
    if (templateId == null) return;
    final Map<String, String> ruleValues;
    try {
      ruleValues = ruleValuesFrom({
        for (final e in _rules.entries) e.key: e.value.text,
      });
    } on FormatException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    setState(() => _sending = true);
    final sent = await runStawiAction(
      context,
      () => ref
          .read(stawiRoomServiceProvider)
          .convert(
            roomId: widget.roomId,
            templateId: templateId,
            ruleValues: ruleValues,
            founderSubscriptionIds: _founders.toList(),
            joinPolicy: _joinPolicy,
          ),
      success: 'Conversion sent; founders will see the genesis to sign',
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (sent != null) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(stawiTemplatesProvider);
    final members = ref.watch(roomMembersProvider(widget.roomId));
    final me = ref.watch(currentProfileIdProvider).asData?.value;
    final theme = Theme.of(context);

    final mySubscription = members.asData?.value
        .where((m) => m.profileId != null && m.profileId == me)
        .firstOrNull;
    if (mySubscription != null && !_founders.contains(mySubscription.id)) {
      // The member converting the room is always one of its founders.
      _founders.add(mySubscription.id);
    }
    final canSubmit =
        !_sending && _templateId != null && mySubscription != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Make this a Stawi room')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'The room keeps its chat. Its savings, loans and decisions move '
            'on chain once the founders sign the genesis.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text('Template', style: theme.textTheme.titleMedium),
          templates.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => ListTile(
              leading: const Icon(Icons.error_outline),
              title: Text(stawiErrorMessage(error)),
              trailing: TextButton(
                onPressed: () => ref.invalidate(stawiTemplatesProvider),
                child: const Text('Retry'),
              ),
            ),
            data: (list) => _TemplatePicker(
              templates: list,
              selected: _templateId,
              onChanged: (id) => setState(() => _templateId = id),
            ),
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: const Text('Rules'),
            subtitle: const Text('Leave a rule empty to keep the template’s'),
            children: [
              for (final rule in templateRules)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _RuleField(rule: rule, controller: _rules[rule.key]!),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Founders', style: theme.textTheme.titleMedium),
          members.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text(stawiErrorMessage(error)),
            data: (list) => Column(
              children: [
                for (final member in list.where((m) => m.profileId != null))
                  CheckboxListTile(
                    key: Key('founder-${member.id}'),
                    value: _founders.contains(member.id),
                    title: Text(member.name),
                    subtitle: member.id == mySubscription?.id
                        ? const Text('You')
                        : null,
                    onChanged: member.id == mySubscription?.id
                        ? null
                        : (checked) => setState(() {
                            if (checked ?? false) {
                              _founders.add(member.id);
                            } else {
                              _founders.remove(member.id);
                            }
                          }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Who can join', style: theme.textTheme.titleMedium),
          SegmentedButton<StawiJoinPolicy>(
            segments: const [
              ButtonSegment(
                value: StawiJoinPolicy.private,
                label: Text('By invitation'),
              ),
              ButtonSegment(
                value: StawiJoinPolicy.public,
                label: Text('Anyone, then admitted'),
              ),
            ],
            selected: {_joinPolicy},
            onSelectionChanged: (s) => setState(() => _joinPolicy = s.first),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('stawi-send-conversion'),
            onPressed: canSubmit ? _submit : null,
            child: Text(_sending ? 'Sending…' : 'Send to the founders'),
          ),
          if (mySubscription == null && members.hasValue)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Only a member of this room can convert it.',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _TemplatePicker extends StatelessWidget {
  const _TemplatePicker({
    required this.templates,
    required this.selected,
    required this.onChanged,
  });

  final List<finance.PolicyTemplate> templates;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return const ListTile(title: Text('No templates are available'));
    }
    return RadioGroup<String>(
      groupValue: selected,
      onChanged: onChanged,
      child: Column(
        children: [
          for (final t in templates)
            RadioListTile<String>(
              key: Key('template-${t.templateId}'),
              value: t.templateId,
              title: Text(t.name.isNotEmpty ? t.name : t.templateId),
              subtitle: t.description.isNotEmpty ? Text(t.description) : null,
            ),
        ],
      ),
    );
  }
}

class _RuleField extends StatefulWidget {
  const _RuleField({required this.rule, required this.controller});

  final TemplateRule rule;
  final TextEditingController controller;

  @override
  State<_RuleField> createState() => _RuleFieldState();
}

class _RuleFieldState extends State<_RuleField> {
  @override
  Widget build(BuildContext context) {
    final rule = widget.rule;
    if (rule.kind == TemplateRuleKind.choice) {
      final current = widget.controller.text;
      return DropdownButtonFormField<String>(
        initialValue: current.isEmpty ? null : current,
        decoration: InputDecoration(
          labelText: rule.label,
          helperText: rule.help,
        ),
        items: [
          const DropdownMenuItem(value: '', child: Text('Template default')),
          for (final c in rule.choices)
            DropdownMenuItem(value: c, child: Text(c)),
        ],
        onChanged: (v) => setState(() => widget.controller.text = v ?? ''),
      );
    }
    return TextField(
      controller: widget.controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: rule.label,
        helperText: rule.help,
        errorText: rule.validate(widget.controller.text.trim()),
      ),
      onChanged: (_) => setState(() {}),
    );
  }
}
