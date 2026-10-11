import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;

import '../../auth/data/current_user_provider.dart';
import '../../rooms/data/detail_panel_providers.dart';
import '../data/stawi_room_service.dart';
import '../domain/governance_requests.dart';
import 'stawi_feedback.dart';

/// Signs [request] on this device and sends it into [roomId]. The act shows in
/// the room as pending until chat posts its outcome.
Future<bool> sendGovernanceRequest(
  BuildContext context,
  WidgetRef ref, {
  required String roomId,
  required GovernanceRequest request,
}) async {
  final sent = await runStawiAction(
    context,
    () => ref
        .read(stawiRoomServiceProvider)
        .signedCall(
          roomId: roomId,
          kind: request.kind,
          params: request.params,
          summary: request.summary,
        ),
    success: 'Signed and sent: ${request.summary}',
  );
  return sent != null;
}

/// The governance acts a member can sign from a Stawi room.
enum GovernanceAction {
  invite('Invite a member', Icons.person_add_alt),
  acceptInvitation('Accept an invitation', Icons.mark_email_read_outlined),
  join('Ask to join', Icons.login),
  admit('Admit a member', Icons.how_to_reg_outlined),
  proposeRemoval('Propose removing a member', Icons.person_remove_outlined),
  vote('Vote on a proposal', Icons.how_to_vote_outlined),
  delegate('Delegate my votes', Icons.forward_outlined),
  revokeDelegation('Revoke my delegation', Icons.undo),
  leave('Leave the room', Icons.exit_to_app);

  const GovernanceAction(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Lets the member pick a governance act, fill in what it needs, then signs
/// and sends it.
Future<void> showGovernanceSheet(
  BuildContext context, {
  required String roomId,
}) async {
  final action = await showModalBottomSheet<GovernanceAction>(
    context: context,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final action in GovernanceAction.values)
            ListTile(
              key: Key('governance-${action.name}'),
              leading: Icon(action.icon),
              title: Text(action.label),
              onTap: () => Navigator.of(context).pop(action),
            ),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => GovernanceDialog(roomId: roomId, action: action),
  );
}

/// The form for one governance act.
class GovernanceDialog extends ConsumerStatefulWidget {
  const GovernanceDialog({
    required this.roomId,
    required this.action,
    this.onchainProposalId,
    super.key,
  });

  final String roomId;
  final GovernanceAction action;

  /// Prefills the proposal for [GovernanceAction.vote].
  final int? onchainProposalId;

  @override
  ConsumerState<GovernanceDialog> createState() => _GovernanceDialogState();
}

class _GovernanceDialogState extends ConsumerState<GovernanceDialog> {
  String? _memberProfileId;
  String _memberName = '';
  late final TextEditingController _number = TextEditingController(
    text: widget.onchainProposalId?.toString() ?? '',
  );
  finance.VoteChoice _choice = finance.VoteChoice.VOTE_CHOICE_APPROVE;
  int _days = 30;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  bool get _needsMember => switch (widget.action) {
    GovernanceAction.invite ||
    GovernanceAction.admit ||
    GovernanceAction.proposeRemoval ||
    GovernanceAction.delegate => true,
    _ => false,
  };

  bool get _needsNumber =>
      widget.action == GovernanceAction.acceptInvitation ||
      widget.action == GovernanceAction.vote;

  GovernanceRequest _request() {
    final member = _memberProfileId;
    if (_needsMember && member == null) {
      throw const FormatException('Choose a member');
    }
    final number = int.tryParse(_number.text.trim());
    if (_needsNumber && (number == null || number <= 0)) {
      throw const FormatException('Enter a number greater than zero');
    }
    return switch (widget.action) {
      GovernanceAction.invite => inviteRequest(
        profileId: member!,
        name: _memberName,
      ),
      GovernanceAction.acceptInvitation => acceptInvitationRequest(number!),
      GovernanceAction.join => joinRequest,
      GovernanceAction.admit => admitRequest(
        profileId: member!,
        name: _memberName,
      ),
      GovernanceAction.proposeRemoval => proposeRemovalRequest(
        profileId: member!,
        name: _memberName,
      ),
      GovernanceAction.vote => voteRequest(
        onchainProposalId: number!,
        choice: _choice,
      ),
      GovernanceAction.delegate => delegateRequest(
        profileId: member!,
        name: _memberName,
        until: DateTime.now().add(Duration(days: _days)),
      ),
      GovernanceAction.revokeDelegation => revokeDelegationRequest,
      GovernanceAction.leave => leaveRequest,
    };
  }

  Future<void> _submit() async {
    final GovernanceRequest request;
    try {
      request = _request();
    } on FormatException catch (e) {
      setState(() => _error = e.message);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final ok = await sendGovernanceRequest(
      context,
      ref,
      roomId: widget.roomId,
      request: request,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentProfileIdProvider).asData?.value;
    final members = ref.watch(roomMembersProvider(widget.roomId));
    return AlertDialog(
      title: Text(widget.action.label),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_needsMember)
              members.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text(stawiErrorMessage(error)),
                data: (list) => DropdownButtonFormField<String>(
                  key: const Key('governance-member'),
                  initialValue: _memberProfileId,
                  decoration: const InputDecoration(labelText: 'Member'),
                  items: [
                    for (final m in list.where(
                      (m) => m.profileId != null && m.profileId != me,
                    ))
                      DropdownMenuItem(value: m.profileId, child: Text(m.name)),
                  ],
                  onChanged: (value) => setState(() {
                    _memberProfileId = value;
                    _memberName = list
                        .firstWhere((m) => m.profileId == value)
                        .name;
                  }),
                ),
              ),
            if (_needsNumber)
              TextField(
                key: const Key('governance-number'),
                controller: _number,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: widget.action == GovernanceAction.vote
                      ? 'On-chain proposal number'
                      : 'Invitation number',
                ),
              ),
            if (widget.action == GovernanceAction.vote)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SegmentedButton<finance.VoteChoice>(
                  segments: const [
                    ButtonSegment(
                      value: finance.VoteChoice.VOTE_CHOICE_APPROVE,
                      label: Text('Approve'),
                    ),
                    ButtonSegment(
                      value: finance.VoteChoice.VOTE_CHOICE_REJECT,
                      label: Text('Reject'),
                    ),
                    ButtonSegment(
                      value: finance.VoteChoice.VOTE_CHOICE_ABSTAIN,
                      label: Text('Abstain'),
                    ),
                  ],
                  selected: {_choice},
                  onSelectionChanged: (s) => setState(() => _choice = s.first),
                ),
              ),
            if (widget.action == GovernanceAction.delegate)
              DropdownButtonFormField<int>(
                initialValue: _days,
                decoration: const InputDecoration(labelText: 'For'),
                items: const [
                  DropdownMenuItem(value: 7, child: Text('7 days')),
                  DropdownMenuItem(value: 30, child: Text('30 days')),
                  DropdownMenuItem(value: 90, child: Text('90 days')),
                ],
                onChanged: (v) => setState(() => _days = v ?? 30),
              ),
            if (!_needsMember && !_needsNumber)
              Text(switch (widget.action) {
                GovernanceAction.leave =>
                  'You will leave the Stawi room on chain. This is signed '
                      'with your device key.',
                GovernanceAction.join =>
                  'You will ask to join; a member admits you afterwards.',
                _ => 'This is signed with your device key.',
              }),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('governance-sign'),
          onPressed: _sending ? null : _submit,
          child: Text(_sending ? 'Signing…' : 'Sign and send'),
        ),
      ],
    );
  }
}
