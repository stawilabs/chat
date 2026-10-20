import 'package:connectrpc/connect.dart' as connect;
import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/auth/data/current_user_provider.dart';
import 'package:stawi/features/rooms/data/detail_panel_providers.dart';
import 'package:stawi/features/stawi/data/guardian_contacts.dart';
import 'package:stawi/features/stawi/data/stawi_binding.dart';
import 'package:stawi/features/stawi/data/stawi_counterparty.dart';
import 'package:stawi/features/stawi/data/stawi_finance_service.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api_chat/stawi_api_chat.dart' as pb;

import '../../../support/stawi_fakes.dart';

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
      'ACTIVE in, once each, with the room both share, then my DM partners '
      'in none of them, looked up through chat', () async {
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
        directRoomListerProvider.overrideWithValue(
          () async => const [
            DirectRoomRef(roomId: 'dm-fay', name: 'Fay'),
            DirectRoomRef(roomId: 'dm-amina', name: 'Amina'),
            DirectRoomRef(roomId: 'dm-broken', name: 'Gus'),
            DirectRoomRef(roomId: 'dm-alone', name: 'Old chat'),
          ],
        ),
        roomMembersProvider.overrideWith(
          (ref, id) async => switch (id) {
            'dm-fay' => [chat('me', 'Me'), chat('fay', 'Fay')],
            'dm-amina' => [chat('me', 'Me'), chat('amina', 'Amina')],
            'dm-broken' => throw StateError('unreadable'),
            'dm-alone' => [chat('me', 'Me')],
            _ => [
              chat('me', 'Me'),
              chat('amina', 'Amina'),
              chat('baraka', 'Baraka'),
            ],
          },
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(guardianContactsProvider, (_, _) {});
    addTearDown(sub.close);
    final contacts = await container.read(guardianContactsProvider.future);
    expect(
      [for (final c in contacts) (c.name, c.profileId, c.roomId, c.via)],
      [
        ('Amina', 'amina', 'r1', GuardianLookupVia.stawiRoom),
        ('Baraka', 'baraka', 'r2', GuardianLookupVia.stawiRoom),
        ('Fay', 'fay', 'dm-fay', GuardianLookupVia.chat),
      ],
    );
  });

  group('chat\'s relay', () {
    late FakeConnectTransport transport;
    late ChatGuardianKeys lookup;

    setUp(() {
      transport = FakeConnectTransport();
      final client = pb.ChatServiceClient(transport);
      lookup = chatGuardianKeys(() async => client);
    });

    test('names the DM and the contact, and returns settlement\'s keys as '
        'chat relays them', () async {
      final key = List<int>.filled(20, 0xf0);
      final account = List<int>.filled(20, 0xf1);
      transport.on(
        pb.ChatService.lookupContactGuardianKeys,
        (req) => pb.LookupContactGuardianKeysResponse(
          profileId: req.profileId,
          keys: [pb.ContactGuardianKey(key: key, account: account)],
          blockNumber: Int64(7),
        ),
      );
      final keys = await lookup(profileId: 'fay', roomId: 'dm-fay');
      expect(keys.single.key, key);
      expect(keys.single.account, account);
      final req = transport
          .requestsTo(pb.ChatService.lookupContactGuardianKeys)
          .single;
      expect((req.roomId, req.profileId), ('dm-fay', 'fay'));
    });

    test('a refusal says the contact has to write first; an outage says '
        'try again', () async {
      transport.on(
        pb.ChatService.lookupContactGuardianKeys,
        (req) => throw connect.ConnectException(
          connect.Code.permissionDenied,
          'this is not a person who has written in a room you share',
        ),
      );
      await expectLater(
        lookup(profileId: 'fay', roomId: 'dm-fay'),
        throwsA(
          isA<StawiUnavailable>().having(
            (e) => e.message,
            'message',
            'They need to send you a message first',
          ),
        ),
      );
      transport.on(
        pb.ChatService.lookupContactGuardianKeys,
        (req) => throw connect.ConnectException(connect.Code.unavailable, ''),
      );
      await expectLater(
        lookup(profileId: 'fay', roomId: 'dm-fay'),
        throwsA(isA<StawiUnavailable>()),
      );
    });
  });
}
