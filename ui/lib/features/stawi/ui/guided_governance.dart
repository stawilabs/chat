import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;

import '../../auth/data/current_user_provider.dart';
import '../../rooms/data/detail_panel_providers.dart';
import '../data/stawi_finance_service.dart';
import '../data/stawi_room_service.dart';
import '../domain/guided_governance.dart';
import 'decision_progress_screen.dart';
import 'governance_sheet.dart';
import 'rule_change_screen.dart';
import 'stawi_feedback.dart';

/// The decisions a member makes most, each a guided flow.
enum GroupDecision {
  invite('Add a member', 'Invite someone from this chat', Icons.person_add),
  role(
    'Choose a role holder',
    'Treasurer, chairperson, secretary…',
    Icons.badge_outlined,
  ),
  remove(
    'Remove a member',
    'The group votes on it',
    Icons.person_remove_outlined,
  ),
  rules(
    'Change group rules',
    'Quorum, voting time, members, fees…',
    Icons.rule,
  ),
  leave('Leave the group', 'Stop being a member', Icons.exit_to_app);

  const GroupDecision(this.label, this.hint, this.icon);

  final String label;
  final String hint;
  final IconData icon;
}

/// The group's decisions: the guided flows first, and every act the chain
/// supports behind "Advanced".
Future<void> showGroupDecisionsSheet(
  BuildContext context, {
  required String roomId,
}) async {
  final choice = await showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final d in GroupDecision.values)
            ListTile(
              key: Key('decision-${d.name}'),
              leading: Icon(d.icon),
              title: Text(d.label),
              subtitle: Text(d.hint),
              onTap: () => Navigator.of(context).pop(d),
            ),
          const Divider(),
          ListTile(
            key: const Key('decision-advanced'),
            leading: const Icon(Icons.tune),
            title: const Text('Advanced'),
            subtitle: const Text('Every room act: votes, exits, freezes…'),
            onTap: () => Navigator.of(context).pop(#advanced),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted) return;
  if (choice == #advanced) {
    await showGovernanceSheet(context, roomId: roomId);
  } else if (choice == GroupDecision.rules) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => RuleChangeScreen(roomId: roomId)),
    );
  } else if (choice is GroupDecision) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GuidedDecisionScreen(roomId: roomId, decision: choice),
      ),
    );
  }
}

/// One guided decision: choose who (and which role), read what will change,
/// then sign behind the device lock through the checked room-act path.
class GuidedDecisionScreen extends ConsumerStatefulWidget {
  const GuidedDecisionScreen({
    required this.roomId,
    required this.decision,
    super.key,
  });

  final String roomId;
  final GroupDecision decision;

  @override
  ConsumerState<GuidedDecisionScreen> createState() =>
      _GuidedDecisionScreenState();
}

class _GuidedDecisionScreenState extends ConsumerState<GuidedDecisionScreen> {
  GroupPerson? _person;
  finance.RoleCapabilities? _role;
  bool _give = true;
  int? _capabilities;
  GuidedChange? _change;
  bool _sending = false;
  String? _error;

  GroupDecision get _decision => widget.decision;

  @override
  void initState() {
    super.initState();
    if (_decision == GroupDecision.leave) _change = leaveChange();
  }

  String _roleName(finance.RoleCapabilities r) =>
      r.displayName.isEmpty ? r.roleId : r.displayName;

  void _next(List<GroupPerson> people, finance.Member? me) {
    final person = _person;
    if (person == null) {
      setState(() => _error = 'Choose a member');
      return;
    }
    final service = ref.read(stawiRoomServiceProvider);
    Future<Uint8List> account() => service.memberAccount(
      widget.roomId,
      person.profileId,
      name: person.name,
    );
    final GuidedChange change;
    switch (_decision) {
      case GroupDecision.invite:
        change = inviteChange(
          name: person.name,
          direct: mayInviteDirectly(me),
          account: account,
        );
      case GroupDecision.role:
        final role = _role;
        if (role == null) {
          setState(() => _error = 'Choose a role');
          return;
        }
        change = roleChange(
          name: person.name,
          roleId: role.roleId,
          roleName: _roleName(role),
          give: _give,
          account: account,
          capabilities: _capabilities ?? 0,
          currentHolders: [
            for (final p in people)
              if (p.holds(role.roleId) && p.profileId != person.profileId)
                p.name,
          ],
          maxHolders: role.maxHolders,
        );
      case GroupDecision.remove:
        change = removalChange(name: person.name, account: account);
      case GroupDecision.leave || GroupDecision.rules:
        change = leaveChange();
    }
    setState(() {
      _change = change;
      _error = null;
    });
  }

  Future<void> _sign(GuidedChange change) async {
    setState(() => _sending = true);
    final service = ref.read(stawiRoomServiceProvider);
    final sent = await signRoomActSent(
      context,
      ref,
      () async => service.prepareAct(
        roomId: widget.roomId,
        request: await change.request(),
      ),
    );
    if (!mounted) return;
    if (sent == null) {
      setState(() => _sending = false);
      return;
    }
    ref.invalidate(stawiMembersProvider(widget.roomId));
    await followDecision(context, widget.roomId, sent, change.title);
  }

  @override
  Widget build(BuildContext context) {
    final change = _change;
    return Scaffold(
      appBar: AppBar(title: Text(_decision.label)),
      body: change != null ? _confirm(context, change) : _choose(context),
    );
  }

  Widget _choose(BuildContext context) {
    final me = ref.watch(currentProfileIdProvider).asData?.value;
    final chat = ref.watch(roomMembersProvider(widget.roomId));
    final onChain = ref.watch(stawiMembersProvider(widget.roomId));
    if (chat.hasError || onChain.hasError) {
      return Center(
        child: Text(stawiErrorMessage(chat.error ?? onChain.error!)),
      );
    }
    final chatList = chat.asData?.value;
    final chainList = onChain.asData?.value;
    if (chatList == null || chainList == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final people = groupPeople([
      for (final m in chatList) (profileId: m.profileId, name: m.name),
    ], chainList);
    final mine = people.where((p) => p.profileId == me).firstOrNull;
    final others = people.where((p) => p.profileId != me);
    final choices = switch (_decision) {
      GroupDecision.invite => others.where((p) => p.invitable).toList(),
      GroupDecision.remove => others.where((p) => p.removable).toList(),
      GroupDecision.role => people.where((p) => p.active).toList(),
      GroupDecision.leave || GroupDecision.rules => <GroupPerson>[],
    };
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(switch (_decision) {
          GroupDecision.invite =>
            mayInviteDirectly(mine?.onChain)
                ? 'Who should join? You may invite them yourself.'
                : 'Who should join? The group votes on your proposal.',
          GroupDecision.role => 'Which role, and who? The group votes on it.',
          GroupDecision.remove =>
            'Who should be removed? The group votes on it.',
          GroupDecision.leave || GroupDecision.rules => '',
        }, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        if (_decision == GroupDecision.role) ..._roleFields(people),
        if (choices.isEmpty)
          Text(
            _decision == GroupDecision.invite
                ? 'Everyone in this chat is already a member or invited. Add '
                      'the person to the chat first.'
                : 'Nobody to choose.',
            key: const Key('guided-nobody'),
          ),
        RadioGroup<String>(
          groupValue: _person?.profileId,
          onChanged: (id) => setState(() {
            _person = choices.firstWhere((p) => p.profileId == id);
            _error = null;
          }),
          child: Column(
            children: [
              for (final p in choices)
                RadioListTile<String>(
                  key: Key('guided-person-${p.profileId}'),
                  value: p.profileId,
                  title: Text(p.profileId == me ? '${p.name} (you)' : p.name),
                  subtitle: _role != null && p.holds(_role!.roleId)
                      ? Text('Holds ${_roleName(_role!)}')
                      : null,
                ),
            ],
          ),
        ),
        if (_error != null)
          Text(
            _error!,
            key: const Key('guided-error'),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('guided-next'),
          onPressed: () => _next(people, mine?.onChain),
          child: const Text('Next'),
        ),
      ],
    );
  }

  List<Widget> _roleFields(List<GroupPerson> people) {
    final roles = ref.watch(stawiRolesProvider(widget.roomId));
    return [
      roles.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text(stawiErrorMessage(e)),
        data: (list) => DropdownButtonFormField<String>(
          key: const Key('guided-role'),
          initialValue: _role?.roleId,
          decoration: const InputDecoration(labelText: 'Role'),
          items: [
            for (final r in list)
              DropdownMenuItem(value: r.roleId, child: Text(_roleName(r))),
          ],
          onChanged: (id) => setState(() {
            _role = list.firstWhere((r) => r.roleId == id);
            _capabilities = capabilitiesOfHolders(id!, people);
          }),
        ),
      ),
      const SizedBox(height: 8),
      SegmentedButton<bool>(
        key: const Key('guided-give'),
        segments: const [
          ButtonSegment(value: true, label: Text('Give the role')),
          ButtonSegment(value: false, label: Text('Take it away')),
        ],
        selected: {_give},
        onSelectionChanged: (s) => setState(() => _give = s.first),
      ),
      if (_give && _role != null) ...[
        const SizedBox(height: 8),
        const Text('What may they do on chain?'),
        for (final e in capabilityWords.entries)
          CheckboxListTile(
            key: Key('guided-power-${e.key}'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(e.value),
            value: (_capabilities ?? 0) & e.key != 0,
            onChanged: (on) => setState(
              () => _capabilities = on ?? false
                  ? (_capabilities ?? 0) | e.key
                  : (_capabilities ?? 0) & ~e.key,
            ),
          ),
      ],
      const SizedBox(height: 8),
    ];
  }

  Widget _confirm(BuildContext context, GuidedChange change) {
    final theme = Theme.of(context);
    Widget bullets(String heading, List<String> items, Key key) => Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        for (final i in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(child: Text(i)),
              ],
            ),
          ),
      ],
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          change.title,
          key: const Key('guided-title'),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        bullets(
          'What will change',
          change.changes,
          const Key('guided-changes'),
        ),
        const SizedBox(height: 12),
        bullets(
          'What happens next',
          change.afterwards,
          const Key('guided-afterwards'),
        ),
        const SizedBox(height: 12),
        Text(
          'Your phone checks the act before you sign it, and asks for your '
          'screen lock to sign.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('guided-sign'),
          onPressed: _sending ? null : () => _sign(change),
          child: Text(_sending ? 'Signing…' : 'Review and sign'),
        ),
        if (_decision != GroupDecision.leave)
          TextButton(
            onPressed: _sending ? null : () => setState(() => _change = null),
            child: const Text('Back'),
          ),
      ],
    );
  }
}
