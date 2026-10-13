import 'dart:async';

import 'package:connectrpc/connect.dart' as connect;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api_chat/stawi_api_chat.dart' as pb;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart'
    show bytesToHex0x, hexToBytes;

import '../../../core/networking/client.dart';
import '../../profile/data/profile_providers.dart';
import '../../rooms/data/room_id_remap.dart';
import '../../rooms/data/room_service.dart';
import 'stawi_identity.dart';
import 'stawi_loan_service.dart';

/// Another person's Stawi account: the other member of one of the person's
/// DMs. Only the counterparty lookup ([counterpartyAccountProvider]) builds
/// one, from chat's answer for that DM, so money can be sent to a person the
/// app knows and never to a typed address.
final class StawiContactAccount {
  const StawiContactAccount._(
    this.address, {
    this.profileId,
    this.name,
    this.deployed = false,
  });

  /// Used by tests in place of the lookup.
  @visibleForTesting
  factory StawiContactAccount.forTest(
    Uint8List address, {
    String? profileId,
    String? name,
    bool deployed = false,
  }) => StawiContactAccount._(
    Uint8List.fromList(address),
    profileId: profileId,
    name: name,
    deployed: deployed,
  );

  /// The 20-byte account address.
  final Uint8List address;
  final String? profileId;

  /// How the contact is shown, when known.
  final String? name;

  /// Whether the account is deployed on chain yet.
  final bool deployed;

  /// The same account, shown as [name].
  StawiContactAccount named(String name) => StawiContactAccount._(
    address,
    profileId: profileId,
    name: name,
    deployed: deployed,
  );
}

/// Chat's answer for a DM: the other person and their primary Stawi account
/// (empty when they have none).
final class DirectPartnerAccount {
  const DirectPartnerAccount({
    required this.profileId,
    required this.account,
    this.deployed = false,
  });

  final String profileId;
  final Uint8List account;
  final bool deployed;
}

/// Looks up the other person of the DM [roomId].
///
/// Profile never hands one person's accounts to another, and settlement
/// answers a profile's account only to services. Chat answers it for a DM:
/// it checks that the caller is an active member of that DIRECT room of two
/// people and that the partner has taken part (started the DM or written in
/// it), then asks settlement. A DM is the only way to name a counterparty.
typedef CounterpartyAccounts = Future<DirectPartnerAccount> Function(
  String roomId,
);

/// Chat refused the lookup. It says nothing about why; the usual reason is
/// that the partner has not written in the DM yet (a partner's account is
/// revealed only once they have taken part), so that is what the person is
/// told.
final class DirectPartnerRefused implements Exception {
  const DirectPartnerRefused();

  /// The line shown for the DM partner [name].
  static String messageFor(String name) =>
      '$name needs to send you a message first';

  @override
  String toString() => messageFor('They');
}

/// Chat refused the lookup for now: the person asked for too many partner
/// accounts in the last minute (GetDirectPartnerAccount's per-person limit,
/// RESOURCE_EXHAUSTED). Lookups back off; what is unknown shows as "—".
final class PartnerLookupsExhausted implements Exception {
  const PartnerLookupsExhausted();

  @override
  String toString() => 'Too many lookups; try again in a minute';
}

/// The lookup through chat's GetDirectPartnerAccount.
CounterpartyAccounts chatCounterpartyAccounts(
  Future<pb.ChatServiceClient> Function() chat,
) => (roomId) async {
  final pb.GetDirectPartnerAccountResponse answer;
  try {
    answer = await (await chat()).getDirectPartnerAccount(
      pb.GetDirectPartnerAccountRequest(roomId: roomId),
    );
  } on connect.ConnectException catch (e) {
    throw switch (e.code) {
      connect.Code.permissionDenied ||
      connect.Code.failedPrecondition ||
      connect.Code.notFound => const DirectPartnerRefused(),
      connect.Code.unavailable => const StawiUnavailable(
        'Their Stawi account cannot be read right now; try again shortly',
      ),
      connect.Code.resourceExhausted => const PartnerLookupsExhausted(),
      _ => e,
    };
  }
  return DirectPartnerAccount(
    profileId: answer.profileId,
    account: Uint8List.fromList(answer.account),
    deployed: answer.deployed,
  );
};

/// Where a DM partner's account is looked up: chat, for the DM's room id.
final counterpartyAccountsProvider = Provider<CounterpartyAccounts>(
  (ref) => chatCounterpartyAccounts(
    () => ref.read(chatServiceClientProvider.future),
  ),
);

/// How long a lookup that failed (refused, unreachable) is kept before it is
/// asked again, and how long every lookup waits once chat says too many were
/// asked (RESOURCE_EXHAUSTED).
const Duration partnerLookupRetryAfter = Duration(seconds: 30);
const Duration partnerLookupBackoff = Duration(minutes: 1);

/// When partner lookups may be asked again after chat said too many were
/// asked; null when they may be asked now. Shared by every lookup of the
/// session.
final class PartnerLookupBackoff {
  DateTime? until;

  bool active(DateTime now) => until != null && now.isBefore(until!);
}

final partnerLookupBackoffProvider = Provider<PartnerLookupBackoff>(
  (ref) => PartnerLookupBackoff(),
);

/// The clock partner lookups back off by, so tests can fix it.
final partnerLookupClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Chat's answer for the partner of the DM `roomId`, cached for the session:
/// one GetDirectPartnerAccount per DM, asked only when something needs it (a
/// row being shown, a loan being named), and asked again only when the DM is
/// remapped to the server's id. A refusal or an outage is kept for
/// [partnerLookupRetryAfter] and then asked again; once chat says too many
/// were asked, no lookup is asked for [partnerLookupBackoff] and each reads
/// as [PartnerLookupsExhausted]. Throws [DirectPartnerRefused],
/// [StawiUnavailable] or [PartnerLookupsExhausted].
final partnerLookupProvider = FutureProvider.autoDispose
    .family<DirectPartnerAccount, String>((ref, roomId) async {
      // A DM opened offline adopts the server's room id: the answer for
      // either id is asked again.
      final remaps = roomIdRemaps.listen((r) {
        if (r.oldId == roomId || r.newId == roomId) ref.invalidateSelf();
      });
      ref.onDispose(remaps.cancel);
      final keep = ref.keepAlive();
      void retryLater(Duration after) {
        final timer = Timer(after, keep.close);
        ref.onDispose(timer.cancel);
      }

      final backoff = ref.read(partnerLookupBackoffProvider);
      final now = ref.read(partnerLookupClockProvider);
      if (backoff.active(now())) {
        retryLater(backoff.until!.difference(now()));
        throw const PartnerLookupsExhausted();
      }
      try {
        return await ref.read(counterpartyAccountsProvider)(roomId);
      } on PartnerLookupsExhausted {
        backoff.until = now().add(partnerLookupBackoff);
        retryLater(partnerLookupBackoff);
        rethrow;
      } on Object {
        retryLater(partnerLookupRetryAfter);
        rethrow;
      }
    }, retry: (_, _) => null);

/// The account of the other person in the DM `roomId`, or null when they
/// have none. An answer that is not a 20-byte, non-zero address is refused.
/// Read through the session's [partnerLookupProvider].
final counterpartyAccountProvider = FutureProvider.autoDispose
    .family<StawiContactAccount?, String>((ref, roomId) async {
      final found = await ref.watch(partnerLookupProvider(roomId).future);
      if (found.account.isEmpty) return null;
      if (found.account.length != 20 || found.account.every((b) => b == 0)) {
        throw const StawiUnavailable('That is not a Stawi account');
      }
      return StawiContactAccount._(
        Uint8List.fromList(found.account),
        profileId: found.profileId.isEmpty ? null : found.profileId,
        deployed: found.deployed,
      );
    }, retry: (_, _) => null);

/// One of the person's DMs, as a destination picker lists it before the
/// partner's account is looked up.
final class DirectRoomRef {
  const DirectRoomRef({
    required this.roomId,
    required this.name,
    this.named = true,
  });

  final String roomId;

  /// How the DM is shown (the partner's name).
  final String name;

  /// Whether [name] is the room's own name, not a stand-in for a room that
  /// has none.
  final bool named;
}

/// Lists the person's DMs, newest first.
typedef DirectRoomLister = Future<List<DirectRoomRef>> Function();

/// The person's DMs from the local room store.
final directRoomListerProvider = Provider<DirectRoomLister>(
  (ref) => () async {
    final rooms = await ref.read(roomRepositoryProvider).getAllRooms();
    return [
      for (final room in rooms)
        if (room.type == 'direct')
          DirectRoomRef(
            roomId: room.id,
            name: room.name.isEmpty ? 'Direct message' : room.name,
            named: room.name.isNotEmpty,
          ),
    ];
  },
);

/// The person's DMs, newest first: where money can be sent. Each partner's
/// account is looked up only when its row is shown.
final directRoomsProvider = FutureProvider.autoDispose<List<DirectRoomRef>>(
  (ref) => ref.watch(directRoomListerProvider)(),
);

/// One of the person's DMs with chat's answer for its partner.
final class DmPartner {
  const DmPartner({
    required this.room,
    this.profileId,
    this.account,
    this.refused = false,
  });

  final DirectRoomRef room;

  /// The partner's profile; null when chat did not answer.
  final String? profileId;

  /// The partner's Stawi account; null when they have none or chat did not
  /// answer.
  final Uint8List? account;

  /// Chat refused: the partner has not written in the DM yet.
  final bool refused;

  /// Whether chat named the partner and their 20-byte account: someone this
  /// device can confirm.
  bool get known =>
      (profileId ?? '').isNotEmpty &&
      account != null &&
      account!.length == 20 &&
      account!.any((b) => b != 0);
}

/// One DM's partner as the session's lookup answers it: refused (the
/// partner has not written yet) or unknown (unreachable, or too many
/// lookups) when chat did not name them.
Future<DmPartner> dmPartnerOf(Ref ref, DirectRoomRef room) async {
  try {
    final found = await ref.read(partnerLookupProvider(room.roomId).future);
    return DmPartner(
      room: room,
      profileId: found.profileId.isEmpty ? null : found.profileId,
      account: found.account.isEmpty ? null : Uint8List.fromList(found.account),
    );
  } on DirectPartnerRefused {
    return DmPartner(room: room, refused: true);
  } on Object {
    return DmPartner(room: room);
  }
}

/// Walks the person's DMs, newest first, asking the session's lookup for each
/// partner until [found] is satisfied; a DM chat refuses, cannot answer or
/// answers too often for is skipped, never the end of the walk. Lookups stop
/// once chat says too many were asked.
Future<DmPartner?> findDmPartner(
  Ref ref,
  bool Function(DmPartner partner) found,
) async {
  final rooms = await ref.read(directRoomListerProvider)();
  final backoff = ref.read(partnerLookupBackoffProvider);
  final now = ref.read(partnerLookupClockProvider);
  for (final room in rooms) {
    if (backoff.active(now())) return null;
    final partner = await dmPartnerOf(ref, room);
    if (partner.known && found(partner)) return partner;
  }
  return null;
}

/// The name a DM partner is shown by: the DM's own name, else their profile
/// name when this device has it; null when neither is known.
Future<String?> dmPartnerName(Ref ref, DmPartner p) async {
  final named = p.room.named ? p.room.name.trim() : '';
  if (named.isNotEmpty) return named;
  try {
    final profile = await ref.read(profileByIdProvider(p.profileId!).future);
    final name = profile?.name?.trim() ?? '';
    return name.isEmpty ? null : name;
  } on Object {
    return null;
  }
}

/// How the other person of a loan is shown: by name only when one of the
/// person's DMs has exactly that account as its partner; otherwise by a
/// short address, said not to be one of their chats.
final class CounterpartyName {
  const CounterpartyName({required this.account, this.name});

  final List<int> account;

  /// The DM partner's name; null when no DM's partner has this account.
  final String? name;

  /// "0x1234…abcd".
  String get shortAddress {
    final hex = bytesToHex0x(account).toLowerCase();
    return hex.length <= 14
        ? hex
        : '${hex.substring(0, 6)}…${hex.substring(hex.length - 4)}';
  }

  /// The name, else "0x1234…abcd (not one of your chats)".
  String get label => name ?? '$shortAddress ($notOneOfYourChats)';
}

/// Said of a counterparty no DM of the person's names.
const String notOneOfYourChats = 'not one of your chats';

/// The other person of a loan, named by their account (lowercase 0x hex): a
/// DM's name is used only when chat answers that DM's partner account as
/// exactly this one. Asked lazily, per loan shown, through the session's
/// cached lookups.
final counterpartyNameProvider = FutureProvider.autoDispose
    .family<CounterpartyName, String>((ref, accountHex) async {
      final account = hexToBytes(accountHex);
      final partner = await findDmPartner(
        ref,
        (p) => _same(p.account!, account),
      );
      return CounterpartyName(
        account: account,
        name: partner == null ? null : await dmPartnerName(ref, partner),
      );
    });

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The DM partner whose profile is `profileId`, through the session's cached
/// lookups; null when no DM of the person's has them as its named partner.
final dmPartnerByProfileProvider = FutureProvider.autoDispose
    .family<DmPartner?, String>(
      (ref, profileId) => profileId.isEmpty
          ? Future.value()
          : findDmPartner(ref, (p) => p.profileId == profileId),
    );

/// The person-to-person loans between the person and the other member of the
/// DM `roomId`, either way; empty when the partner has no Stawi account.
final dmPairLoansProvider = FutureProvider.autoDispose
    .family<List<finance.Loan>, String>((ref, roomId) async {
      final partner = await ref.watch(
        counterpartyAccountProvider(roomId).future,
      );
      if (partner == null) return const [];
      final me = (await ref.watch(stawiIdentityProvider.future)).primary;
      if (me == null) return const [];
      return ref
          .watch(stawiLoanServiceProvider)
          .between(me.address, partner.address);
    });

/// The Stawi account chat answers for a profile as one of the person's DM
/// partners, or null when no DM of theirs has that partner, or chat refuses
/// (the partner has not written) for every one that does.
typedef DmPartnerAccountOf = Future<Uint8List?> Function(String profileId);

/// Walks the person's DMs through the session's cached lookups until one's
/// partner is the profile: the answer names the partner, so no DM is taken
/// for theirs on the local store's word. A DM that cannot be answered is
/// skipped.
final dmPartnerAccountOfProvider = Provider<DmPartnerAccountOf>(
  (ref) => (profileId) async {
    if (profileId.isEmpty) return null;
    final partner = await findDmPartner(ref, (p) => p.profileId == profileId);
    final account = partner?.account;
    return account != null && account.length == 20 ? account : null;
  },
);
