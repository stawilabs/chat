import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rooms/data/detail_panel_providers.dart';
import '../data/stawi_agent_invitations.dart';
import '../data/stawi_counterparty.dart';
import 'stawi_feedback.dart';

/// The room's Stawi agent as chosen when converting it: a profile and how it
/// is shown. A null profileId is "No agent".
typedef StawiAgentChoice = ({String? profileId, String name});

/// No agent: the whole Stawi fee goes to the treasury.
const StawiAgentChoice noStawiAgent = (profileId: null, name: 'No agent');

/// Lets the person converting [members]' room [roomId] name its Stawi
/// agent: no agent, one of the room's members this device can confirm, or
/// one of their DM partners who accepted an agent invitation for this room.
/// [founders] are the members chosen as founders (by subscription id). Null
/// when dismissed.
Future<StawiAgentChoice?> showStawiAgentPicker(
  BuildContext context, {
  required String roomId,
  required List<RoomSubscriptionInfo> members,
  required Set<String> founders,
}) => showModalBottomSheet<StawiAgentChoice>(
  context: context,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: StawiAgentPicker(
      roomId: roomId,
      members: members,
      founders: founders,
    ),
  ),
);

/// Why a member who is neither a founder nor a DM partner who has written
/// cannot be the agent: each founder's device must confirm the agent's
/// account, and it can only for those.
const String agentUnconfirmableReason =
    'Make them a founder, or ask them to message you first, so the founders '
    'can confirm their account';

/// Chat's rule for an agent who is not a member of the room (its refusal,
/// word for word): they must have accepted an agent invitation for it.
const String agentNeedsAcceptance =
    'the agent must be a room member or someone who accepted your agent '
    'invitation for this room';

/// "No agent", the room's members, then the person's DM partners. Only
/// someone each founder's device can confirm, and chat will accept, is
/// offered: a founder (the genesis holds their account), a member who is a
/// DM partner chat names, or a DM partner who accepted an agent invitation
/// for this room. A partner who has not is offered an invitation instead.
/// Each partner is looked up only when their row is built.
class StawiAgentPicker extends ConsumerWidget {
  const StawiAgentPicker({
    required this.roomId,
    required this.members,
    this.founders = const {},
    super.key,
  });

  /// The room being converted.
  final String roomId;
  final List<RoomSubscriptionInfo> members;

  /// The members chosen as founders, by subscription id.
  final Set<String> founders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rooms = ref.watch(directRoomsProvider);
    final named = [
      for (final m in members)
        if (m.profileId != null && m.profileId!.isNotEmpty) m,
    ];
    final memberIds = {for (final m in named) m.profileId!};
    final partnerRows = rooms.asData?.value ?? const <DirectRoomRef>[];
    final head = <Widget>[
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
        _MemberAgentTile(member: m, founder: founders.contains(m.id)),
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
        data: (_) => const [],
      ),
    ];
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: ListView.builder(
        key: const Key('stawi-agent-picker'),
        shrinkWrap: true,
        itemCount: head.length + partnerRows.length,
        itemBuilder: (context, i) => i < head.length
            ? head[i]
            : _PartnerAgentTile(
                room: partnerRows[i - head.length],
                roomId: roomId,
                memberIds: memberIds,
              ),
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

/// A member of the room: a founder can always be confirmed; anyone else
/// only when they are a DM partner chat names (looked up when the row is
/// built). A member needs no invitation.
class _MemberAgentTile extends ConsumerWidget {
  const _MemberAgentTile({required this.member, required this.founder});

  final RoomSubscriptionInfo member;
  final bool founder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partner = founder
        ? null
        : ref.watch(dmPartnerByProfileProvider(member.profileId!));
    final confirmable = founder || (partner?.asData?.value?.known ?? false);
    final checking = partner?.isLoading ?? false;
    return ListTile(
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
}

/// A DM partner: chosen only once they accepted an agent invitation for
/// this room (or are a member of it); otherwise invited from here.
class _PartnerAgentTile extends ConsumerStatefulWidget {
  const _PartnerAgentTile({
    required this.room,
    required this.roomId,
    required this.memberIds,
  });

  final DirectRoomRef room;
  final String roomId;
  final Set<String> memberIds;

  @override
  ConsumerState<_PartnerAgentTile> createState() => _PartnerAgentTileState();
}

class _PartnerAgentTileState extends ConsumerState<_PartnerAgentTile> {
  bool _sending = false;

  Future<void> _invite() async {
    if (_sending) return;
    setState(() => _sending = true);
    await runStawiAction(
      context,
      () => inviteAgent(
        ref.read(agentActSenderProvider),
        dmRoomId: widget.room.roomId,
        roomId: widget.roomId,
      ),
      success:
          'Invitation sent to ${widget.room.name}; they can choose to accept '
          'it in your chat',
    );
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
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
          data: (contact) {
            final profileId = contact?.profileId;
            if (profileId == null) {
              return ListTile(
                key: key,
                enabled: false,
                title: title,
                subtitle: Text('${room.name} has no Stawi account yet'),
              );
            }
            void choose() =>
                Navigator.of(context)
                    .pop((profileId: profileId, name: room.name));
            if (widget.memberIds.contains(profileId)) {
              return ListTile(
                key: key,
                title: title,
                subtitle: const Text('A member of this room'),
                onTap: choose,
              );
            }
            final status = ref
                .watch(
                  agentInviteStatusProvider((
                    dmRoomId: room.roomId,
                    roomId: widget.roomId,
                  )),
                )
                .asData
                ?.value;
            return switch (status) {
              AgentInviteStatus.accepted => ListTile(
                key: key,
                title: title,
                subtitle: const Text('Accepted being agent for this room'),
                onTap: choose,
              ),
              AgentInviteStatus.invited => ListTile(
                key: key,
                enabled: false,
                title: title,
                subtitle: Text('Invited; waiting for ${room.name} to accept'),
              ),
              _ => ListTile(
                key: key,
                enabled: false,
                title: title,
                subtitle: Text(
                  '${agentNeedsAcceptance[0].toUpperCase()}'
                  '${agentNeedsAcceptance.substring(1)}',
                ),
                trailing: TextButton(
                  key: Key('agent-invite-${room.roomId}'),
                  onPressed: _sending || status == null ? null : _invite,
                  child: const Text('Invite as agent'),
                ),
              ),
            };
          },
        );
  }
}
