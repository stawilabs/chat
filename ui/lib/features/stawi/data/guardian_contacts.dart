import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show bytesToHex0x;

import '../../auth/data/current_user_provider.dart';
import '../../rooms/data/detail_panel_providers.dart';
import '../../rooms/data/room_service.dart';
import 'stawi_binding.dart';
import 'stawi_finance_service.dart';
import 'stawi_guardian_service.dart';
import 'stawi_timeline_providers.dart';

/// Someone the person could name as a guardian: an ACTIVE member of a Stawi
/// room the person is also ACTIVE in. Settlement's guardian directory
/// (LookupGuardianKeys) answers a person only for such a contact, naming
/// the room they share.
final class GuardianContact {
  const GuardianContact({
    required this.profileId,
    required this.name,
    required this.roomId,
  });

  final String profileId;
  final String name;

  /// A Stawi room both are ACTIVE members of: the one the lookup names.
  final String roomId;

  ({String profileId, String roomId}) get lookup =>
      (profileId: profileId, roomId: roomId);
}

/// Lists the person's group rooms (not DMs) by chat room id.
typedef GroupRoomLister = Future<List<String>> Function();

/// The person's group rooms from the local room store.
final groupRoomListerProvider = Provider<GroupRoomLister>(
  (ref) =>
      () async => [
        for (final room in await ref.read(roomRepositoryProvider).getAllRooms())
          if (room.type != 'direct') room.id,
      ],
);

/// The person's possible guardians: every ACTIVE member of the Stawi rooms
/// the person is ACTIVE in, once each (with the first such room), by name.
/// A room finance cannot read just now is left out.
final guardianContactsProvider =
    FutureProvider.autoDispose<List<GuardianContact>>((ref) async {
      final me = await ref.watch(currentProfileIdProvider.future);
      final rooms = await ref.watch(groupRoomListerProvider)();
      final out = <String, GuardianContact>{};
      for (final room in rooms) {
        try {
          final binding = await ref.watch(stawiBindingProvider(room).future);
          if (phaseOfBinding(binding) != StawiRoomPhase.active) continue;
          final members = await ref.watch(stawiMembersProvider(room).future);
          bool active(finance.Member m) =>
              m.state == finance.MemberState.MEMBER_STATE_ACTIVE;
          if (!members.any((m) => m.profileId == me && active(m))) continue;
          final chat = await ref.watch(roomMembersProvider(room).future);
          for (final m in members) {
            if (!active(m) || m.profileId.isEmpty || m.profileId == me) {
              continue;
            }
            if (out.containsKey(m.profileId)) continue;
            final name = chat
                .where((c) => c.profileId == m.profileId)
                .firstOrNull
                ?.name;
            out[m.profileId] = GuardianContact(
              profileId: m.profileId,
              name: (name ?? '').trim().isEmpty ? 'A member' : name!.trim(),
              roomId: room,
            );
          }
        } on Object {
          continue;
        }
      }
      return out.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });

/// A contact's guardian keys that count now, from settlement's directory.
final guardianKeysOfProvider = FutureProvider.autoDispose
    .family<List<settlement.GuardianKey>, ({String profileId, String roomId})>(
      (ref, c) => ref
          .watch(stawiGuardianServiceProvider)
          .lookupGuardianKeys(profileId: c.profileId, chatRoomId: c.roomId),
      retry: (_, _) => null,
    );

/// The contacts' names by the guardian keys they registered (lower-case 0x
/// hex), to name the person's guardians. A contact the directory does not
/// answer for is left out.
final guardianNamesProvider = FutureProvider.autoDispose<Map<String, String>>((
  ref,
) async {
  final contacts = await ref.watch(guardianContactsProvider.future);
  final names = <String, String>{};
  for (final c in contacts) {
    try {
      for (final k in await ref.watch(
        guardianKeysOfProvider(c.lookup).future,
      )) {
        names.putIfAbsent(bytesToHex0x(k.key).toLowerCase(), () => c.name);
      }
    } on Object {
      continue;
    }
  }
  return names;
});
