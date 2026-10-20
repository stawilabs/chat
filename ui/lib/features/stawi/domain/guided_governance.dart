import 'dart:typed_data';

import 'package:stawi_api/finance_v1.dart' as finance;

import 'governance_requests.dart';

/// A person in the chat room, with their on-chain membership when finance has
/// indexed one.
final class GroupPerson {
  const GroupPerson({
    required this.profileId,
    required this.name,
    this.onChain,
  });

  final String profileId;
  final String name;
  final finance.Member? onChain;

  finance.MemberState get state =>
      onChain?.state ?? finance.MemberState.MEMBER_STATE_UNSPECIFIED;

  /// An admitted member who takes part in decisions.
  bool get active => state == finance.MemberState.MEMBER_STATE_ACTIVE;

  /// On the room's books in any standing that a removal applies to.
  bool get removable => switch (state) {
    finance.MemberState.MEMBER_STATE_ACTIVE ||
    finance.MemberState.MEMBER_STATE_INACTIVE ||
    finance.MemberState.MEMBER_STATE_SUSPENDED ||
    finance.MemberState.MEMBER_STATE_UNADMITTED => true,
    _ => false,
  };

  /// Not a member on chain, and not already invited or on the way in.
  bool get invitable => switch (state) {
    finance.MemberState.MEMBER_STATE_UNSPECIFIED ||
    finance.MemberState.MEMBER_STATE_EXITED => true,
    _ => false,
  };

  bool holds(String roleId) => onChain?.roleIds.contains(roleId) ?? false;
}

/// The chat room's people joined to finance's members by profile.
List<GroupPerson> groupPeople(
  Iterable<({String? profileId, String name})> chat,
  Iterable<finance.Member> onChain,
) {
  final byProfile = {
    for (final m in onChain)
      if (m.profileId.isNotEmpty) m.profileId: m,
  };
  return [
    for (final c in chat)
      if (c.profileId case final id? when id.isNotEmpty)
        GroupPerson(profileId: id, name: c.name, onChain: byProfile[id]),
  ];
}

/// The RoomMembership.CAP_* bit of a finance capability (its value is the
/// bit's position plus one).
int capabilityBit(finance.RoomCapability c) =>
    c.value <= 0 ? 0 : 1 << (c.value - 1);

/// Whether [me] may invite on their own (an officer holding CAP_INVITE);
/// otherwise an invitation is put to a vote.
bool mayInviteDirectly(finance.Member? me) =>
    me != null &&
    me.state == finance.MemberState.MEMBER_STATE_ACTIVE &&
    me.capabilities.contains(finance.RoomCapability.ROOM_CAPABILITY_INVITE);

/// What the role's current holders may do on chain: the union of their
/// capabilities, a starting point for a new holder.
int capabilitiesOfHolders(String roleId, Iterable<GroupPerson> people) {
  var bits = 0;
  for (final p in people) {
    if (!p.holds(roleId)) continue;
    for (final c in p.onChain!.capabilities) {
      bits |= capabilityBit(c);
    }
  }
  return bits;
}

/// The on-chain powers a role may carry, in plain words.
const Map<int, String> capabilityWords = {
  RoomCapability.invite: 'Invite people into the group',
  RoomCapability.admit: 'Admit people who asked to join',
  RoomCapability.suspend: 'Suspend a member',
  RoomCapability.readmit: 'Readmit a suspended member',
  RoomCapability.freeze: 'Approve freezing the group in an emergency',
  RoomCapability.lend: 'Approve loans as a credit officer',
};

/// One guided decision, ready to confirm: what it is, what will change and
/// what happens afterwards, and how to build the checked act once the person
/// confirms (a member's account is resolved only then).
final class GuidedChange {
  const GuidedChange({
    required this.title,
    required this.changes,
    required this.afterwards,
    required this.request,
  });

  final String title;
  final List<String> changes;
  final List<String> afterwards;
  final Future<GovernanceRequest> Function() request;
}

const String _finishFromAdvanced =
    'When the vote passes, any member finishes it from Advanced: "Queue a passed proposal", then, once its waiting time is over, "Run a passed invitation" (or the role or removal it decided).';

/// Inviting [name]. An officer who may invite does it at once; anyone else
/// proposes it and the group votes.
GuidedChange inviteChange({
  required String name,
  required bool direct,
  required Future<Uint8List> Function() account,
  int inviteDays = 14,
  DateTime? now,
}) {
  if (direct) {
    return GuidedChange(
      title: 'Invite $name',
      changes: [
        '$name is invited to join the group on chain.',
        'The invitation stands for ${officerInviteValidity.inDays} days.',
      ],
      afterwards: [
        '$name accepts the invitation from their own phone; then they save and borrow with the group.',
      ],
      request: () async =>
          inviteRequest(account: await account(), name: name, now: now),
    );
  }
  final expiresAt = inviteExpiryAfter(inviteDays, now: now);
  return GuidedChange(
    title: 'Propose inviting $name',
    changes: [
      'The group votes on inviting $name.',
      'If it passes, the invitation stands until ${inviteExpiryLabel(expiresAt)} UTC.',
    ],
    afterwards: [
      _finishFromAdvanced,
      '$name then accepts the invitation from their own phone.',
    ],
    request: () async => proposeInviteRequest(
      account: await account(),
      name: name,
      expiresAt: expiresAt,
    ),
  );
}

/// Giving [name] the role [roleName] (with [capabilities] on chain), or, with
/// [give] false, taking it away. Either is a vote.
GuidedChange roleChange({
  required String name,
  required String roleId,
  required String roleName,
  required bool give,
  required Future<Uint8List> Function() account,
  int capabilities = 0,
  List<String> currentHolders = const [],
  int maxHolders = 0,
}) {
  final powers = [
    for (final e in capabilityWords.entries)
      if (capabilities & e.key != 0) e.value,
  ];
  final full = give && maxHolders > 0 && currentHolders.length >= maxHolders;
  return GuidedChange(
    title: give
        ? 'Propose $name as $roleName'
        : 'Propose removing $name as $roleName',
    changes: [
      if (give)
        'The group votes on making $name $roleName.'
      else
        'The group votes on $name no longer being $roleName.',
      if (give && powers.isNotEmpty)
        'As $roleName, $name may: ${powers.join('; ')}.',
      if (give && powers.isEmpty) 'The role carries no extra powers on chain.',
      if (!give) '$name keeps their membership and savings.',
    ],
    afterwards: [
      if (full)
        '$roleName has room for $maxHolders and is held by ${currentHolders.join(', ')}: propose removing one of them too, or this cannot take effect.',
      _finishFromAdvanced,
    ],
    request: () async => give
        ? assignRoleRequest(
            account: await account(),
            name: name,
            roleId: roleId,
            roleName: roleName,
            capabilities: capabilities,
          )
        : revokeRoleRequest(
            account: await account(),
            name: name,
            roleId: roleId,
            roleName: roleName,
          ),
  );
}

/// Removing [name] from the group: a vote.
GuidedChange removalChange({
  required String name,
  required Future<Uint8List> Function() account,
}) => GuidedChange(
  title: 'Propose removing $name',
  changes: [
    'The group votes on removing $name.',
    'If it passes, $name stops being a member on chain; what they are owed and what they owe are settled by the group\'s rules.',
  ],
  afterwards: [_finishFromAdvanced],
  request: () async =>
      proposeRemovalRequest(account: await account(), name: name),
);

/// The person leaving the group themselves, at once.
GuidedChange leaveChange() => GuidedChange(
  title: 'Leave the group',
  changes: const [
    'You stop being a member of the group on chain.',
    'What you are owed and what you owe are settled by the group\'s rules.',
  ],
  afterwards: const ['You stay in the chat until someone removes you.'],
  request: () async => leaveRequest,
);
