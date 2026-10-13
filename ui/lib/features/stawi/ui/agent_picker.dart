import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rooms/data/detail_panel_providers.dart';
import '../data/stawi_counterparty.dart';
import 'stawi_feedback.dart';

/// The room's Stawi agent as chosen when converting it: a profile and how it
/// is shown. A null profileId is "No agent".
typedef StawiAgentChoice = ({String? profileId, String name});

/// No agent: the whole Stawi fee goes to the treasury.
const StawiAgentChoice noStawiAgent = (profileId: null, name: 'No agent');

/// Lets the person converting [members]' room name its Stawi agent: no
/// agent, one of the room's members this device can confirm, or one of their
/// DM partners who has written to them. [founders] are the members chosen as
/// founders (by subscription id). Null when dismissed.
Future<StawiAgentChoice?> showStawiAgentPicker(
  BuildContext context, {
  required List<RoomSubscriptionInfo> members,
  required Set<String> founders,
}) => showModalBottomSheet<StawiAgentChoice>(
  context: context,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: StawiAgentPicker(members: members, founders: founders),
  ),
);

/// Why a member who is neither a founder nor a DM partner who has written
/// cannot be the agent: each founder's device must confirm the agent's
/// account, and it can only for those.
const String agentUnconfirmableReason =
    'Make them a founder, or ask them to message you first, so the founders '
    'can confirm their account';

/// "No agent", the room's members, then the person's DM partners. Only
/// someone each founder's device can confirm is offered, so the genesis
/// review does not refuse it later: a founder (the genesis holds their
/// account) or a DM partner chat names (one who has written in the DM, or
/// started it). Anyone else is shown and cannot be chosen.
class StawiAgentPicker extends ConsumerWidget {
  const StawiAgentPicker({
    required this.members,
    this.founders = const {},
    super.key,
  });

  final List<RoomSubscriptionInfo> members;

  /// The members chosen as founders, by subscription id.
  final Set<String> founders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rooms = ref.watch(directRoomsProvider);
    final partners = ref.watch(dmPartnersProvider);
    final partnerIds = {
      for (final p in partners.asData?.value ?? const <DmPartner>[])
        if (p.known) p.profileId!,
    };
    final named = [
      for (final m in members)
        if (m.profileId != null && m.profileId!.isNotEmpty) m,
    ];
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: ListView(
        key: const Key('stawi-agent-picker'),
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Stawi agent', style: theme.textTheme.titleMedium),
          ),
          ListTile(
            key: const Key('agent-none'),
            title: const Text('No agent'),
            onTap: () => Navigator.of(context).pop(noStawiAgent),
          ),
          if (named.isNotEmpty) const _Heading('Members of this room'),
          for (final m in named)
            _MemberAgentTile(
              member: m,
              confirmable:
                  founders.contains(m.id) || partnerIds.contains(m.profileId),
              checking: partners.isLoading,
            ),
          const _Heading('People who message you'),
          ...rooms.when(
            loading: () => const [
              Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (error, _) => [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(stawiErrorMessage(error)),
              ),
            ],
            data: (rooms) => [
              for (final room in rooms) _PartnerAgentTile(room: room),
            ],
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge),
  );
}

class _MemberAgentTile extends StatelessWidget {
  const _MemberAgentTile({
    required this.member,
    required this.confirmable,
    required this.checking,
  });

  final RoomSubscriptionInfo member;
  final bool confirmable;

  /// The DM partners are still being looked up.
  final bool checking;

  @override
  Widget build(BuildContext context) => ListTile(
    key: Key('agent-member-${member.id}'),
    title: Text(member.name),
    enabled: confirmable,
    subtitle: confirmable
        ? null
        : Text(checking ? 'Checking…' : agentUnconfirmableReason),
    onTap: confirmable
        ? () =>
              Navigator.of(context)
                  .pop((profileId: member.profileId, name: member.name))
        : null,
  );
}

class _PartnerAgentTile extends ConsumerWidget {
  const _PartnerAgentTile({required this.room});

  final DirectRoomRef room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = Key('agent-dm-${room.roomId}');
    final title = Text(room.name);
    return ref
        .watch(counterpartyAccountProvider(room.roomId))
        .when(
          loading: () => ListTile(
            key: key,
            enabled: false,
            title: title,
            subtitle: const Text('Checking…'),
          ),
          error: (error, _) => ListTile(
            key: key,
            enabled: false,
            title: title,
            subtitle: Text(
              error is DirectPartnerRefused
                  ? DirectPartnerRefused.messageFor(room.name)
                  : stawiErrorMessage(error),
            ),
          ),
          data: (contact) => contact?.profileId == null
              ? ListTile(
                  key: key,
                  enabled: false,
                  title: title,
                  subtitle: Text('${room.name} has no Stawi account yet'),
                )
              : ListTile(
                  key: key,
                  title: title,
                  onTap: () => Navigator.of(context)
                      .pop((profileId: contact!.profileId, name: room.name)),
                ),
        );
  }
}
