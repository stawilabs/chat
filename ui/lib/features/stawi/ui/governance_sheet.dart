import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show hexToBytes;

import '../../auth/data/current_user_provider.dart';
import '../../rooms/data/detail_panel_providers.dart';
import '../data/stawi_finance_service.dart';
import '../data/stawi_room_service.dart';
import '../domain/governance_requests.dart';
import '../domain/signing_checks.dart';
import '../domain/stawi_money.dart';
import 'stawi_feedback.dart';

/// Signs [request] on this device and sends it into [roomId]. The act shows in
/// the room as pending until chat posts its outcome.
Future<bool> sendGovernanceRequest(
  BuildContext context,
  WidgetRef ref, {
  required String roomId,
  required GovernanceRequest request,
  void Function(settlement.PrepareRoomCallResponse prepared)? check,
}) => _send(
  context,
  () => ref
      .read(stawiRoomServiceProvider)
      .signedCall(
        roomId: roomId,
        kind: request.kind,
        params: request.params,
        summary: request.summary,
        check: check,
      ),
  'Signed and sent: ${request.summary}',
);

Future<bool> _send<T>(
  BuildContext context,
  Future<T> Function() act,
  String success,
) async => await runStawiAction(context, act, success: success) != null;

/// The governance acts a member can sign from a Stawi room.
enum GovernanceAction {
  invite('Invite a member', Icons.person_add_alt),
  proposeInvite('Propose inviting a member', Icons.group_add_outlined),
  queueProposal('Queue a passed proposal', Icons.queue_outlined),
  executeInvite('Run a passed invitation', Icons.play_arrow_outlined),
  acceptInvitation('Accept an invitation', Icons.mark_email_read_outlined),
  join('Ask to join', Icons.login),
  admit('Admit a member', Icons.how_to_reg_outlined),
  proposeRemoval('Propose removing a member', Icons.person_remove_outlined),
  vote('Vote on a proposal', Icons.how_to_vote_outlined),
  secretVote('Cast a secret vote', Icons.lock_outline),
  revealVote('Reveal my secret vote', Icons.lock_open_outlined),
  assignRole('Propose a role holder', Icons.badge_outlined),
  revokeRole('Propose removing a role holder', Icons.person_off_outlined),
  delegate('Delegate my votes', Icons.forward_outlined),
  revokeDelegation('Revoke my delegation', Icons.undo),
  freeze('Approve freezing the room', Icons.ac_unit),
  proposeExit('Propose a principal exit', Icons.output_outlined),
  proposeExitCancel('Propose cancelling a principal exit', Icons.block),
  voteExit('Vote on a principal exit', Icons.fact_check_outlined),
  executeExit('Run a passed principal exit', Icons.play_circle_outline),
  executeExitCancel(
    'Run a passed exit cancellation',
    Icons.stop_circle_outlined,
  ),
  leave('Leave the room', Icons.exit_to_app);

  const GovernanceAction(this.label, this.icon);

  final String label;
  final IconData icon;

  bool get needsMember => switch (this) {
    invite ||
    proposeInvite ||
    executeInvite ||
    admit ||
    proposeRemoval ||
    delegate ||
    assignRole ||
    revokeRole => true,
    _ => false,
  };

  bool get needsRole => this == assignRole || this == revokeRole;

  /// The number field's label, when the act takes one.
  String? get numberLabel => switch (this) {
    acceptInvitation => 'Invitation number',
    vote ||
    secretVote ||
    revealVote ||
    queueProposal ||
    executeInvite => 'On-chain proposal number',
    voteExit || executeExit || executeExitCancel => 'Exit ballot number',
    proposeExitCancel => 'Exit ballot to cancel',
    _ => null,
  };

  bool get needsChoice => this == vote || this == secretVote;
}

/// Lets the member pick a governance act, fill in what it needs, then signs
/// and sends it.
Future<void> showGovernanceSheet(
  BuildContext context, {
  required String roomId,
}) async {
  final action = await showModalBottomSheet<GovernanceAction>(
    context: context,
    isScrollControlled: true,
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
    this.revealClosesAt,
    super.key,
  });

  final String roomId;
  final GovernanceAction action;

  /// When the secret ballot's reveal window closes, when the caller knows.
  final DateTime? revealClosesAt;

  /// Prefills the proposal for a vote.
  final int? onchainProposalId;

  @override
  ConsumerState<GovernanceDialog> createState() => _GovernanceDialogState();
}

class _GovernanceDialogState extends ConsumerState<GovernanceDialog> {
  String? _memberProfileId;
  String _memberName = '';
  String? _roleId;
  String _roleName = '';
  int _capabilities = 0;
  late final TextEditingController _number = TextEditingController(
    text: widget.onchainProposalId?.toString() ?? '',
  );
  final _text = TextEditingController();
  final _amount = TextEditingController();
  final _sourceBucket = TextEditingController(text: 'savings');
  _ExitTo _exitTo = _ExitTo.member;

  /// The proposed exit amount in minor units, checked against the exit intent.
  String _exitUnits = '';
  finance.VoteChoice _choice = finance.VoteChoice.VOTE_CHOICE_APPROVE;
  bool _approve = true;
  int _days = 30;
  int _inviteDays = 14;

  /// The expiry a proposed invitation commits to, as sent.
  DateTime? _proposedExpiry;
  bool _sending = false;
  String? _error;

  GovernanceAction get _action => widget.action;

  @override
  void dispose() {
    _number.dispose();
    _text.dispose();
    _amount.dispose();
    _sourceBucket.dispose();
    super.dispose();
  }

  int? _parsedNumber({required bool required}) {
    final raw = _number.text.trim();
    if (raw.isEmpty && !required) return 0;
    final n = int.tryParse(raw);
    if (n == null || n <= 0) {
      throw const FormatException('Enter a number greater than zero');
    }
    return n;
  }

  /// The act as a signed call, or null for the secret-ballot acts, which the
  /// room service seals and reveals itself.
  GovernanceRequest? _request() {
    final member = _memberProfileId;
    if (_action.needsMember && member == null) {
      throw const FormatException('Choose a member');
    }
    if (_action.needsRole && _roleId == null) {
      throw const FormatException('Choose a role');
    }
    final number = _action.numberLabel == null
        ? null
        : _parsedNumber(required: true);
    return switch (_action) {
      GovernanceAction.invite => inviteRequest(
        profileId: member!,
        name: _memberName,
      ),
      GovernanceAction.proposeInvite => proposeInviteRequest(
        profileId: member!,
        name: _memberName,
        expiresAt: _proposedExpiry = inviteExpiryAfter(_inviteDays),
      ),
      GovernanceAction.queueProposal => null,
      GovernanceAction.executeInvite => null,
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
      GovernanceAction.secretVote || GovernanceAction.revealVote => null,
      GovernanceAction.assignRole => assignRoleRequest(
        profileId: member!,
        name: _memberName,
        roleId: _roleId!,
        roleName: _roleName,
        capabilities: _capabilities,
      ),
      GovernanceAction.revokeRole => revokeRoleRequest(
        profileId: member!,
        name: _memberName,
        roleId: _roleId!,
        roleName: _roleName,
      ),
      GovernanceAction.delegate => delegateRequest(
        profileId: member!,
        name: _memberName,
        until: DateTime.now().add(Duration(days: _days)),
      ),
      GovernanceAction.revokeDelegation => revokeDelegationRequest,
      GovernanceAction.freeze => freezeRequest(_reason()),
      GovernanceAction.proposeExit => _exitRequest(),
      GovernanceAction.proposeExitCancel => proposeExitCancelRequest(number!),
      GovernanceAction.executeExit ||
      GovernanceAction.executeExitCancel => null,
      GovernanceAction.voteExit => votePrincipalExitRequest(
        ballotId: number!,
        approve: _approve,
      ),
      GovernanceAction.leave => leaveRequest,
    };
  }

  String _reason() {
    final reason = _text.text.trim();
    if (reason.isEmpty || reason.length > 256) {
      throw const FormatException('Give a reason (at most 256 characters)');
    }
    return reason;
  }

  /// The reveal deadline finance indexed for the proposal; null when it is
  /// not known (the reminder then shows no date).
  Future<DateTime?> _revealDeadline(int onchainProposalId) async {
    try {
      final p = await ref
          .read(stawiFinanceServiceProvider)
          .proposalByOnchainId(widget.roomId, onchainProposalId);
      return p != null && p.hasRevealClosesAt()
          ? p.revealClosesAt.toDateTime()
          : null;
    } on Object {
      return null;
    }
  }

  GovernanceRequest _exitRequest() {
    final source = _sourceBucket.text.trim();
    if (source.isEmpty) throw const FormatException('Name the source bucket');
    final asset = ref.read(stawiRoomAssetProvider(widget.roomId)).asData?.value;
    if (asset == null) {
      throw const FormatException('The room’s asset could not be read');
    }
    final amount = parseAmountInput(_amount.text, asset);
    _exitUnits = amount;
    final amountLabel = formatUnits(BigInt.parse(amount), asset);
    switch (_exitTo) {
      case _ExitTo.member:
        if (_memberProfileId == null) {
          throw const FormatException('Choose a member');
        }
        return proposePrincipalExitRequest(
          sourceBucket: source,
          amount: amount,
          amountLabel: amountLabel,
          memberProfileId: _memberProfileId,
          memberName: _memberName,
        );
      case _ExitTo.bucket:
        final bucket = _text.text.trim();
        if (bucket.isEmpty) throw const FormatException('Name the bucket');
        return proposePrincipalExitRequest(
          sourceBucket: source,
          amount: amount,
          amountLabel: amountLabel,
          bucket: bucket,
        );
      case _ExitTo.external:
        Uint8List? to;
        try {
          to = hexToBytes(_text.text.trim());
        } on FormatException {
          to = null;
        }
        if (to == null || to.length != 20) {
          throw const FormatException('The account is a 20-byte address');
        }
        return proposePrincipalExitRequest(
          sourceBucket: source,
          amount: amount,
          amountLabel: amountLabel,
          externalAccount: to,
        );
    }
  }

  Future<void> _submit() async {
    final GovernanceRequest? request;
    final int? proposal;
    try {
      request = _request();
      proposal = request == null ? _parsedNumber(required: true) : null;
    } on FormatException catch (e) {
      setState(() => _error = e.message);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final service = ref.read(stawiRoomServiceProvider);
    final send = switch (_action) {
      GovernanceAction.secretVote => () => _send(
        context,
        () async => service.commitSecretVote(
          roomId: widget.roomId,
          onchainProposalId: proposal!,
          choice: _choice,
          revealClosesAt:
              widget.revealClosesAt ?? await _revealDeadline(proposal),
        ),
        'Secret vote cast; reveal it when voting closes',
      ),
      GovernanceAction.revealVote => () => _send(context, () async {
        final event = await service.revealSecretVote(
          roomId: widget.roomId,
          onchainProposalId: proposal!,
        );
        ref.invalidate(stawiPendingRevealsProvider(widget.roomId));
        return event;
      }, 'Vote revealed'),
      GovernanceAction.queueProposal => () => _send(
        context,
        () => service.pushEngineCall(
          roomId: widget.roomId,
          kind: settlement.RoomCallKind.ROOM_CALL_KIND_QUEUE,
          params: queueProposalParams(proposal!),
        ),
        'Queued; it can run once its timelock passes',
      ),
      GovernanceAction.executeInvite => () => _executeInvite(proposal!),
      GovernanceAction.executeExit ||
      GovernanceAction.executeExitCancel => () => _send(
        context,
        () => service.pushEngineCall(
          roomId: widget.roomId,
          kind: _action == GovernanceAction.executeExit
              ? settlement.RoomCallKind.ROOM_CALL_KIND_EXECUTE_PRINCIPAL_EXIT
              : settlement
                    .RoomCallKind
                    .ROOM_CALL_KIND_EXECUTE_PRINCIPAL_EXIT_CANCEL,
          params: executeExitParams(proposal!),
        ),
        'Submitted to the chain',
      ),
      _ => () => sendGovernanceRequest(
        context,
        ref,
        roomId: widget.roomId,
        request: request!,
        check: switch (_action) {
          GovernanceAction.proposeExit => (prepared) => checkPrincipalExit(
            prepared,
            amount: _exitUnits,
          ),
          GovernanceAction.proposeInvite =>
            (prepared) => checkProposedInviteExpiry(
              prepared,
              expiresAt: _proposedExpiry!,
            ),
          _ => null,
        },
      ),
    };
    final ok = await send();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _sending = false);
    }
  }

  /// Runs the passed invitation; settlement applies the expiry the proposal
  /// carried and reports it.
  Future<bool> _executeInvite(int proposal) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final call = await runStawiAction(
      context,
      () => ref
          .read(stawiRoomServiceProvider)
          .pushEngineCall(
            roomId: widget.roomId,
            kind: settlement.RoomCallKind.ROOM_CALL_KIND_EXECUTE,
            params: executeInviteParams(
              onchainProposalId: proposal,
              profileId: _memberProfileId!,
            ),
          ),
    );
    if (call == null) return false;
    final expiry = inviteExpiryFromSeconds(call.inviteExpiry);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          expiry == null
              ? 'Invitation sent to the chain; the invitee can accept it'
              : 'Invitation sent to the chain; the invitee can accept it '
                    'until ${inviteExpiryLabel(expiry)} UTC',
        ),
      ),
    );
    return true;
  }

  /// The expiry the passed invitation proposal carries, as finance indexed
  /// it.
  Widget _proposedInviteExpiry() {
    final n = int.tryParse(_number.text.trim());
    if (n == null || n <= 0) return const SizedBox.shrink();
    final text = ref
        .watch(stawiProposalByOnchainIdProvider((widget.roomId, n)))
        .when(
          loading: () => 'Reading the proposal…',
          error: (_, _) =>
              'The proposal could not be read; the invitation takes the '
              'expiry it carries.',
          data: (p) {
            final expiry = p == null
                ? null
                : inviteExpiryFromSeconds(p.inviteExpiry);
            return expiry == null
                ? 'The invitation takes the expiry the proposal carries.'
                : 'The invitation expires ${inviteExpiryLabel(expiry)} UTC, '
                      'as the proposal named.';
          },
        );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(text, key: const Key('governance-invite-expiry')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentProfileIdProvider).asData?.value;
    final members = ref.watch(roomMembersProvider(widget.roomId));
    return AlertDialog(
      title: Text(_action.label),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_action.needsMember ||
                (_action == GovernanceAction.proposeExit &&
                    _exitTo == _ExitTo.member))
              members.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text(stawiErrorMessage(error)),
                data: (list) => DropdownButtonFormField<String>(
                  key: const Key('governance-member'),
                  initialValue: _memberProfileId,
                  decoration: const InputDecoration(labelText: 'Member'),
                  items: [
                    for (final m in list.where(
                      (m) =>
                          m.profileId != null &&
                          (m.profileId != me || _action.needsRole),
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
            if (_action.needsRole) _rolePicker(),
            if (_action == GovernanceAction.assignRole) _capabilityPicker(),
            if (_action.numberLabel != null)
              TextField(
                key: const Key('governance-number'),
                controller: _number,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: _action.numberLabel),
                onChanged: _action == GovernanceAction.executeInvite
                    ? (_) => setState(() {})
                    : null,
              ),
            if (_action.needsChoice) _choicePicker(),
            if (_action == GovernanceAction.secretVote)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Only a sealed commitment is sent now. Your choice stays on '
                  'this device, and only this device can reveal it: reveal '
                  'from here after voting closes, before the reveal deadline.',
                  key: Key('secret-vote-device-note'),
                ),
              ),
            if (_action == GovernanceAction.revealVote)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'A secret vote can only be revealed from the device that '
                  'cast it.',
                  key: Key('reveal-device-note'),
                ),
              ),
            if (_action == GovernanceAction.voteExit)
              SwitchListTile(
                key: const Key('governance-approve'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Approve the exit'),
                value: _approve,
                onChanged: (v) => setState(() => _approve = v),
              ),
            if (_action == GovernanceAction.proposeExit) ..._exitFields(),
            if (_action == GovernanceAction.freeze ||
                (_action == GovernanceAction.proposeExit &&
                    _exitTo != _ExitTo.member))
              TextField(
                key: const Key('governance-text'),
                controller: _text,
                maxLength: _action == GovernanceAction.freeze ? 256 : 64,
                decoration: InputDecoration(
                  labelText: _action == GovernanceAction.freeze
                      ? 'Reason'
                      : _exitTo == _ExitTo.bucket
                      ? 'Destination bucket'
                      : 'Destination account (0x…)',
                ),
              ),
            if (_action == GovernanceAction.proposeInvite) ...[
              DropdownButtonFormField<int>(
                key: const Key('governance-invite-days'),
                initialValue: _inviteDays,
                decoration: const InputDecoration(
                  labelText: 'Invitation stands for',
                ),
                items: const [
                  DropdownMenuItem(value: 7, child: Text('7 days')),
                  DropdownMenuItem(value: 14, child: Text('14 days')),
                  DropdownMenuItem(value: 29, child: Text('29 days')),
                ],
                onChanged: (v) => setState(() => _inviteDays = v ?? 14),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'The invitation expires '
                  '${inviteExpiryLabel(inviteExpiryAfter(_inviteDays))} UTC; '
                  'running the passed proposal applies it.',
                  key: const Key('governance-invite-expiry'),
                ),
              ),
            ],
            if (_action == GovernanceAction.executeInvite)
              _proposedInviteExpiry(),
            if (_action == GovernanceAction.delegate)
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
            if (_action == GovernanceAction.leave)
              const Text(
                'You will leave the Stawi room on chain. This is signed with '
                'your device key.',
              ),
            if (_action == GovernanceAction.join)
              const Text(
                'You will ask to join; a member admits you afterwards.',
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  key: const Key('governance-error'),
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

  List<Widget> _exitFields() => [
    TextField(
      key: const Key('exit-source'),
      controller: _sourceBucket,
      decoration: const InputDecoration(labelText: 'From bucket'),
    ),
    TextField(
      key: const Key('exit-amount'),
      controller: _amount,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Amount',
        suffixText: ref
            .watch(stawiRoomAssetProvider(widget.roomId))
            .asData
            ?.value
            ?.symbol,
      ),
    ),
    Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SegmentedButton<_ExitTo>(
        segments: const [
          ButtonSegment(value: _ExitTo.member, label: Text('Member')),
          ButtonSegment(value: _ExitTo.bucket, label: Text('Bucket')),
          ButtonSegment(value: _ExitTo.external, label: Text('Account')),
        ],
        selected: {_exitTo},
        onSelectionChanged: (s) => setState(() => _exitTo = s.first),
      ),
    ),
  ];

  Widget _choicePicker() => Padding(
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
  );

  Widget _rolePicker() => ref
      .watch(stawiRolesProvider(widget.roomId))
      .when(
        loading: () => const LinearProgressIndicator(),
        error: (error, _) => Text(stawiErrorMessage(error)),
        data: (roles) => DropdownButtonFormField<String>(
          key: const Key('governance-role'),
          initialValue: _roleId,
          decoration: const InputDecoration(labelText: 'Role'),
          items: [
            for (final r in roles)
              DropdownMenuItem(
                value: r.roleId,
                child: Text(r.displayName.isEmpty ? r.roleId : r.displayName),
              ),
          ],
          onChanged: (value) => setState(() {
            _roleId = value;
            final role = roles.firstWhere((r) => r.roleId == value);
            _roleName = role.displayName.isEmpty
                ? role.roleId
                : role.displayName;
          }),
        ),
      );

  Widget _capabilityPicker() => Wrap(
    spacing: 6,
    children: [
      for (final entry in RoomCapability.labels.entries)
        FilterChip(
          key: Key('capability-${entry.value}'),
          label: Text(entry.value),
          selected: _capabilities & entry.key != 0,
          onSelected: (on) => setState(
            () => _capabilities = on
                ? _capabilities | entry.key
                : _capabilities & ~entry.key,
          ),
        ),
    ],
  );
}

/// Where a principal exit pays to.
enum _ExitTo { member, bucket, external }
