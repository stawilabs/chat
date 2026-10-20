import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;

import '../data/stawi_finance_service.dart';
import '../data/stawi_room_service.dart';
import '../domain/decision_progress.dart' show finishesItselfNote;
import '../domain/rule_changes.dart';
import 'decision_progress_screen.dart' show followDecision;
import 'governance_sheet.dart';
import 'stawi_feedback.dart';

/// "Change group rules": the rules a vote may change after genesis, each
/// with its value in force; the person changes some, reads what changes and
/// which open votes it ends, then signs the proposal behind the device lock
/// (settlement compiles the new rules; the device checks them first).
class RuleChangeScreen extends ConsumerStatefulWidget {
  const RuleChangeScreen({required this.roomId, super.key});

  final String roomId;

  @override
  ConsumerState<RuleChangeScreen> createState() => _RuleChangeScreenState();
}

class _RuleChangeScreenState extends ConsumerState<RuleChangeScreen> {
  final Map<GroupRule, TextEditingController> _fields = {};
  final Map<GroupRule, String> _errors = {};
  Map<String, String>? _values;
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _field(GroupRule rule, int? current) =>
      _fields.putIfAbsent(
        rule,
        () => TextEditingController(
          text: current == null ? '' : rule.typed(current),
        ),
      );

  void _next(finance.RoomPolicy inForce) {
    final chosen = <GroupRule, int>{};
    _errors.clear();
    for (final MapEntry(key: rule, value: c) in _fields.entries) {
      // A rule the constitution leaves to its default changes only when a
      // value is typed.
      if (c.text.trim().isEmpty && rule.current(inForce) == null) continue;
      try {
        chosen[rule] = rule.parse(c.text);
      } on FormatException catch (e) {
        _errors[rule] = e.message;
      }
    }
    final values = ruleValuesOf(chosen, inForce);
    setState(() {
      if (_errors.isNotEmpty) {
        _error = null;
      } else if (values.isEmpty) {
        _error = 'Change at least one rule';
      } else {
        _error = null;
        _values = values;
      }
    });
  }

  Future<void> _sign(
    finance.PolicyVersion inForce,
    Map<String, String> values,
  ) async {
    setState(() => _sending = true);
    final service = ref.read(stawiRoomServiceProvider);
    const title = 'Propose new group rules';
    final sent = await signRoomActSent(
      context,
      ref,
      () => service.prepareAct(
        roomId: widget.roomId,
        request: proposeRuleChangeRequest(values: values, inForce: inForce),
      ),
    );
    if (!mounted) return;
    if (sent == null) {
      setState(() => _sending = false);
      return;
    }
    await followDecision(context, widget.roomId, sent, title);
  }

  @override
  Widget build(BuildContext context) {
    final policy = ref.watch(stawiPolicyProvider(widget.roomId));
    return Scaffold(
      appBar: AppBar(title: const Text('Change group rules')),
      body: policy.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(stawiErrorMessage(e))),
        data: (inForce) {
          final values = _values;
          return values == null
              ? _choose(context, inForce.constitution)
              : _confirm(context, inForce, values);
        },
      ),
    );
  }

  Widget _choose(BuildContext context, finance.RoomPolicy inForce) {
    final theme = Theme.of(context);
    final rules = [for (final r in GroupRule.values) (r, r.current(inForce))];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Change what you want; the group votes on the new rules.',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        for (final (rule, now) in rules)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              key: Key('rule-${rule.key}'),
              controller: _field(rule, now),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: rule.label,
                suffixText: switch (rule.unit) {
                  RuleUnit.percent => '%',
                  RuleUnit.days => 'days',
                  RuleUnit.hours => 'hours',
                  RuleUnit.people => 'members',
                },
                helperText: now == null
                    ? '${rule.help}. Now the default: ${rule.defaultWords}.'
                    : '${rule.help}. Now ${rule.show(now)}.',
                helperMaxLines: 3,
                errorText: _errors[rule],
              ),
            ),
          ),
        Text(
          loanThresholdNote,
          key: const Key('rule-loan-threshold-note'),
          style: theme.textTheme.bodySmall,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              key: const Key('rule-error'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('rule-next'),
          onPressed: () => _next(inForce),
          child: const Text('Next'),
        ),
      ],
    );
  }

  Widget _confirm(
    BuildContext context,
    finance.PolicyVersion inForce,
    Map<String, String> values,
  ) {
    final theme = Theme.of(context);
    final open = ref.watch(stawiUndecidedProposalsProvider(widget.roomId));
    final lines = [
      for (final key in values.keys.toList()..sort())
        if (GroupRule.byKey(key) case final rule?)
          ruleChangeLine(
            rule,
            rule.current(inForce.constitution),
            int.parse(values[key]!),
          ),
    ];
    final count = open.asData?.value;
    final warn = count == null || count > 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Propose new group rules', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Text('What will change', style: theme.textTheme.titleSmall),
        for (final (label, change) in lines)
          ListTile(
            key: Key('rule-change-$label'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(label),
            trailing: Text(change),
          ),
        const SizedBox(height: 8),
        Card(
          key: const Key('rule-open-votes'),
          color: warn
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.secondaryContainer,
          child: ListTile(
            leading: Icon(
              Icons.warning_amber,
              color: warn ? theme.colorScheme.onErrorContainer : null,
            ),
            title: open.isLoading
                ? const Text('Counting the open votes…')
                : Text(
                    openVotesWarning(count),
                    style: TextStyle(
                      color: warn ? theme.colorScheme.onErrorContainer : null,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text('What happens next', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        const Text('The group votes on the new rules. $finishesItselfNote'),
        const SizedBox(height: 12),
        Text(
          'Your phone checks the new rules settlement prepares against the '
          'rules in force before you sign, and asks for your screen lock to '
          'sign.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('rule-sign'),
          onPressed: _sending || open.isLoading
              ? null
              : () => _sign(inForce, values),
          child: Text(_sending ? 'Signing…' : 'Review and sign'),
        ),
        TextButton(
          onPressed: _sending ? null : () => setState(() => _values = null),
          child: const Text('Back'),
        ),
      ],
    );
  }
}
