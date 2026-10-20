import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/auth/data/current_user_provider.dart';
import 'package:stawi/features/rooms/data/detail_panel_providers.dart';
import 'package:stawi/features/stawi/data/guardian_contacts.dart';
import 'package:stawi/features/stawi/data/stawi_binding.dart';
import 'package:stawi/features/stawi/data/stawi_finance_service.dart';
import 'package:stawi_api/finance_v1.dart' as finance;

void main() {
  const active = finance.MemberState.MEMBER_STATE_ACTIVE;
  const suspended = finance.MemberState.MEMBER_STATE_SUSPENDED;

  finance.Member member(String profileId, finance.MemberState state) =>
      finance.Member(profileId: profileId, state: state);

  RoomSubscriptionInfo chat(String profileId, String name) =>
      RoomSubscriptionInfo(
        id: 's-$profileId',
        profileId: profileId,
        contactId: null,
        name: name,
        avatarUrl: null,
        role: 'member',
        joinedAt: 0,
      );

  test('possible guardians are the ACTIVE members of the Stawi rooms I am '
      'ACTIVE in, once each, with the room both share', () async {
    final bindings = {
      'r1': StawiBindingState.bound,
      'r2': StawiBindingState.bound,
      'r3': StawiBindingState.pending,
      'r4': StawiBindingState.bound,
    };
    final members = {
      // I am active with Amina (active) and Chena (suspended).
      'r1': [
        member('me', active),
        member('amina', active),
        member('chena', suspended),
      ],
      // Amina again, and Baraka.
      'r2': [
        member('me', active),
        member('amina', active),
        member('baraka', active),
      ],
      // Not on chain yet.
      'r3': [member('me', active), member('dan', active)],
      // I am suspended here: nobody from it.
      'r4': [member('me', suspended), member('eve', active)],
    };
    final container = ProviderContainer(
      overrides: [
        currentProfileIdProvider.overrideWith((ref) async => 'me'),
        groupRoomListerProvider.overrideWithValue(
          () async => ['r1', 'r2', 'r3', 'r4', 'broken'],
        ),
        stawiBindingProvider.overrideWith(
          (ref, id) async => switch (bindings[id]) {
            final s? => StawiBinding(
              state: s,
              genesisId: 'g-$id',
              genesisEventId: 'e-$id',
            ),
            null => throw StateError('unreadable'),
          },
        ),
        stawiMembersProvider.overrideWith(
          (ref, id) async => members[id] ?? const [],
        ),
        roomMembersProvider.overrideWith(
          (ref, id) async => [
            chat('me', 'Me'),
            chat('amina', 'Amina'),
            chat('baraka', 'Baraka'),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(guardianContactsProvider, (_, _) {});
    addTearDown(sub.close);
    final contacts = await container.read(guardianContactsProvider.future);
    expect(
      [for (final c in contacts) (c.name, c.profileId, c.roomId)],
      [('Amina', 'amina', 'r1'), ('Baraka', 'baraka', 'r2')],
    );
  });
}
