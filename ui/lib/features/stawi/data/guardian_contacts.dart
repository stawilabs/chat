import 'package:connectrpc/connect.dart' as connect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_api_chat/stawi_api_chat.dart' as pb;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show bytesToHex0x;

import '../../../core/networking/client.dart';
import '../../auth/data/current_user_provider.dart';
import '../../rooms/data/detail_panel_providers.dart';
import '../../rooms/data/room_service.dart';
import 'stawi_binding.dart';
import 'stawi_counterparty.dart';
import 'stawi_finance_service.dart';
import 'stawi_guardian_service.dart';
import 'stawi_identity.dart';
import 'stawi_timeline_providers.dart';

/// Where a contact's guardian keys are looked up.
enum GuardianLookupVia {
  /// Settlement's directory, naming a Stawi room both are ACTIVE in on chain.
  stawiRoom,

  /// Chat's relay (LookupContactGuardianKeys), naming a chat room both are
  /// members of (a DM): chat checks the room, then asks settlement.
  chat,
}

/// Someone the person could name as a guardian: an ACTIVE member of a Stawi
/// room the person is also ACTIVE in, else the other person of one of their
/// DMs. Settlement's guardian directory answers a person only for a contact
/// in a shared Stawi room; chat answers for a DM partner once the partner has
/// taken part in it.
final class GuardianContact {
  const GuardianContact({
    required this.profileId,
    required this.name,
    required this.roomId,
    this.via = GuardianLookupVia.stawiRoom,
  });

  final String profileId;
  final String name;

  /// The room both share: a Stawi room ([GuardianLookupVia.stawiRoom]) or a
  /// DM ([GuardianLookupVia.chat]), the one the lookup names.
  final String roomId;

  final GuardianLookupVia via;

  GuardianLookup get lookup => (profileId: profileId, roomId: roomId, via: via);
}

/// One contact's guardian key lookup.
typedef GuardianLookup = ({
  String profileId,
  String roomId,
  GuardianLookupVia via,
});

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

String _named(String? name, String fallback) =>
    (name ?? '').trim().isEmpty ? fallback : name!.trim();

/// The person's possible guardians, once each, by name: every ACTIVE member
/// of the Stawi rooms the person is ACTIVE in (with the first such room),
/// then the other person of each DM who is in none of them (looked up
/// through chat). The rooms are read together, not one after another. A
/// room that cannot be read just now is left out.
final guardianContactsProvider =
    FutureProvider.autoDispose<List<GuardianContact>>((ref) async {
      final me = await ref.watch(currentProfileIdProvider.future);
      final groups = ref.watch(groupRoomListerProvider)();
      final dms = ref.watch(directRoomListerProvider)();

      Future<List<GuardianContact>> stawiContacts(String room) async {
        try {
          final binding = await ref.watch(stawiBindingProvider(room).future);
          if (phaseOfBinding(binding) != StawiRoomPhase.active) return [];
          final (members, chat) = await (
            ref.watch(stawiMembersProvider(room).future),
            ref.watch(roomMembersProvider(room).future),
          ).wait;
          bool active(finance.Member m) =>
              m.state == finance.MemberState.MEMBER_STATE_ACTIVE;
          if (!members.any((m) => m.profileId == me && active(m))) return [];
          return [
            for (final m in members)
              if (active(m) && m.profileId.isNotEmpty && m.profileId != me)
                GuardianContact(
                  profileId: m.profileId,
                  name: _named(
                    chat
                        .where((c) => c.profileId == m.profileId)
                        .firstOrNull
                        ?.name,
                    'A member',
                  ),
                  roomId: room,
                ),
          ];
        } on Object {
          return [];
        }
      }

      Future<GuardianContact?> dmContact(DirectRoomRef dm) async {
        try {
          final chat = await ref.watch(roomMembersProvider(dm.roomId).future);
          final others = [
            for (final c in chat)
              if ((c.profileId ?? '').isNotEmpty && c.profileId != me) c,
          ];
          if (others.length != 1) return null;
          final partner = others.single;
          return GuardianContact(
            profileId: partner.profileId!,
            name: _named(partner.name, _named(dm.name, 'Your contact')),
            roomId: dm.roomId,
            via: GuardianLookupVia.chat,
          );
        } on Object {
          return null;
        }
      }

      final perRoom = await Future.wait([
        for (final room in await groups) stawiContacts(room),
      ]);
      final out = <String, GuardianContact>{};
      for (final c in perRoom.expand((l) => l)) {
        out.putIfAbsent(c.profileId, () => c);
      }
      final partners = await Future.wait([
        for (final dm in await dms) dmContact(dm),
      ]);
      for (final c in partners.nonNulls) {
        out.putIfAbsent(c.profileId, () => c);
      }
      return out.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });

/// Looks up a contact's guardian keys through chat, for a chat room both
/// share.
typedef ChatGuardianKeys = Future<List<settlement.GuardianKey>> Function({
  required String profileId,
  required String roomId,
});

/// Chat's relay (LookupContactGuardianKeys): chat checks that the contact is
/// another member of the room who has taken part in it, then asks
/// settlement's directory as its own service. Its keys are settlement's
/// GuardianKeys, so a contact reached either way is shown the same.
ChatGuardianKeys chatGuardianKeys(
  Future<pb.ChatServiceClient> Function() chat,
) => ({required profileId, required roomId}) async {
  final pb.LookupContactGuardianKeysResponse answer;
  try {
    answer = await (await chat()).lookupContactGuardianKeys(
      pb.LookupContactGuardianKeysRequest(roomId: roomId, profileId: profileId),
    );
  } on connect.ConnectException catch (e) {
    throw switch (e.code) {
      connect.Code.permissionDenied ||
      connect.Code.failedPrecondition ||
      connect.Code.notFound => const StawiUnavailable(
        'They need to send you a message first',
      ),
      connect.Code.unavailable ||
      connect.Code.unimplemented => const StawiUnavailable(
        'Their guardian key cannot be read right now; try again shortly',
      ),
      connect.Code.resourceExhausted => const PartnerLookupsExhausted(),
      _ => e,
    };
  }
  return [
    for (final k in answer.keys)
      settlement.GuardianKey(
        key: k.key,
        account: k.account,
        registeredAt: k.hasRegisteredAt() ? k.registeredAt : null,
      ),
  ];
};

final chatGuardianKeysProvider = Provider<ChatGuardianKeys>(
  (ref) => chatGuardianKeys(() => ref.read(chatServiceClientProvider.future)),
);

/// A contact's guardian keys that count now: from settlement's directory for
/// a shared Stawi room, else through chat's relay for a shared DM.
final guardianKeysOfProvider = FutureProvider.autoDispose
    .family<List<settlement.GuardianKey>, GuardianLookup>(
      (ref, c) => switch (c.via) {
        GuardianLookupVia.stawiRoom =>
          ref
              .watch(stawiGuardianServiceProvider)
              .lookupGuardianKeys(profileId: c.profileId, chatRoomId: c.roomId),
        GuardianLookupVia.chat => ref.watch(chatGuardianKeysProvider)(
          profileId: c.profileId,
          roomId: c.roomId,
        ),
      },
      retry: (_, _) => null,
    );

/// The contacts' names by the guardian keys they registered (lower-case 0x
/// hex), to name the person's guardians. The contacts are looked up together;
/// one the directory does not answer for is left out.
final guardianNamesProvider = FutureProvider.autoDispose<Map<String, String>>((
  ref,
) async {
  final contacts = await ref.watch(guardianContactsProvider.future);
  final answers = await Future.wait([
    for (final c in contacts)
      ref
          .watch(guardianKeysOfProvider(c.lookup).future)
          .then<List<settlement.GuardianKey>?>((k) => k)
          .catchError((Object _) => null),
  ]);
  final names = <String, String>{};
  for (final (i, keys) in answers.indexed) {
    for (final k in keys ?? const <settlement.GuardianKey>[]) {
      names.putIfAbsent(
        bytesToHex0x(k.key).toLowerCase(),
        () => contacts[i].name,
      );
    }
  }
  return names;
});
