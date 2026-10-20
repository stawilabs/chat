import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/domain/governance_requests.dart';
import 'package:stawi/features/stawi/domain/guided_governance.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;

void main() {
  finance.Member m(
    String id,
    finance.MemberState state, {
    List<String> roles = const [],
    List<finance.RoomCapability> caps = const [],
  }) => finance.Member(
    profileId: id,
    state: state,
    roleIds: roles,
    capabilities: caps,
  );

  final people = groupPeople(
    [
      (profileId: 'a', name: 'Ann'),
      (profileId: 'b', name: 'Ben'),
      (profileId: 'c', name: 'Cy'),
      (profileId: 'd', name: 'Dee'),
      (profileId: null, name: 'Nobody'),
    ],
    [
      m(
        'a',
        finance.MemberState.MEMBER_STATE_ACTIVE,
        roles: ['treasurer'],
        caps: [
          finance.RoomCapability.ROOM_CAPABILITY_LEND,
          finance.RoomCapability.ROOM_CAPABILITY_FREEZE,
        ],
      ),
      m('b', finance.MemberState.MEMBER_STATE_INVITED),
      m('c', finance.MemberState.MEMBER_STATE_EXITED),
    ],
  );
  GroupPerson p(String id) => people.firstWhere((x) => x.profileId == id);

  test('joins the chat to the chain by profile', () {
    expect(people.map((x) => x.name), ['Ann', 'Ben', 'Cy', 'Dee']);
    expect(p('a').active, isTrue);
    expect(p('d').onChain, isNull);
  });

  test('who can be invited and who removed', () {
    expect(
      [
        for (final x in people)
          if (x.invitable) x.name,
      ],
      ['Cy', 'Dee'],
    );
    expect(
      [
        for (final x in people)
          if (x.removable) x.name,
      ],
      ['Ann'],
    );
  });

  test('capabilities are the chain bits', () {
    expect(capabilityBit(finance.RoomCapability.ROOM_CAPABILITY_INVITE), 1);
    expect(capabilityBit(finance.RoomCapability.ROOM_CAPABILITY_LEND), 32);
    expect(capabilitiesOfHolders('treasurer', people), 32 | 16);
    expect(capabilitiesOfHolders('chair', people), 0);
  });

  test('only an active holder of CAP_INVITE invites alone', () {
    expect(
      mayInviteDirectly(
        m(
          'x',
          finance.MemberState.MEMBER_STATE_ACTIVE,
          caps: [finance.RoomCapability.ROOM_CAPABILITY_INVITE],
        ),
      ),
      isTrue,
    );
    expect(
      mayInviteDirectly(
        m(
          'x',
          finance.MemberState.MEMBER_STATE_SUSPENDED,
          caps: [finance.RoomCapability.ROOM_CAPABILITY_INVITE],
        ),
      ),
      isFalse,
    );
    expect(mayInviteDirectly(null), isFalse);
  });

  group('changes build the act the person confirmed', () {
    final acct = Uint8List(20)..[19] = 7;
    Future<Uint8List> account() async => acct;

    test('an invitation by vote commits to its expiry', () async {
      final now = DateTime.utc(2026, 10, 20, 9, 30);
      final c = inviteChange(
        name: 'Dee',
        direct: false,
        account: account,
        now: now,
      );
      expect(
        c.changes.last,
        'If it passes, the invitation stands until 2026-11-03 09:30 UTC.',
      );
      final r = await c.request();
      expect(r.kind, settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE);
      expect(r.params!.propose.memberAction.subject.account, acct);
      expect(
        r.params!.propose.memberAction.arg.toInt(),
        now.add(const Duration(days: 14)).millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('an officer invites for a week', () async {
      final r = await inviteChange(
        name: 'Dee',
        direct: true,
        account: account,
      ).request();
      expect(r.kind, settlement.RoomCallKind.ROOM_CALL_KIND_INVITE);
      expect(
        r.params!.officer.inviteValidSeconds,
        officerInviteValidity.inSeconds,
      );
    });

    test('a role names its powers in words', () async {
      final c = roleChange(
        name: 'Ann',
        roleId: 'chair',
        roleName: 'Chairperson',
        give: true,
        account: account,
        capabilities: RoomCapability.freeze,
        currentHolders: ['Ben'],
        maxHolders: 1,
      );
      expect(
        c.changes,
        contains(
          'As Chairperson, Ann may: Approve freezing the group in an '
          'emergency.',
        ),
      );
      expect(c.afterwards.first, contains('held by Ben'));
      final r = await c.request();
      expect(r.kind, settlement.RoomCallKind.ROOM_CALL_KIND_ASSIGN_ROLE);
      expect(r.params!.role.capabilities, RoomCapability.freeze);
      expect(r.params!.role.roleId, 'chair');
    });

    test('removal and leaving', () async {
      expect(
        (await removalChange(name: 'Ann', account: account).request()).kind,
        settlement.RoomCallKind.ROOM_CALL_KIND_PROPOSE,
      );
      expect(
        (await leaveChange().request()).kind,
        settlement.RoomCallKind.ROOM_CALL_KIND_LEAVE,
      );
    });
  });
}
