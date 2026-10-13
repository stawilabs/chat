import 'package:connectrpc/connect.dart' as connect;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api_chat/stawi_api_chat.dart' as pb;

import '../../../core/networking/client.dart';
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

/// The account of the other person in the DM `roomId`, or null when they
/// have none. An answer that is not a 20-byte, non-zero address is refused.
final counterpartyAccountProvider = FutureProvider.autoDispose
    .family<StawiContactAccount?, String>((ref, roomId) async {
      final found = await ref.watch(counterpartyAccountsProvider)(roomId);
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
  const DirectRoomRef({required this.roomId, required this.name});

  final String roomId;

  /// How the DM is shown (the partner's name).
  final String name;
}

/// The person's DMs, newest first: where money can be sent. Each partner's
/// account is looked up only when its row is shown.
final directRoomsProvider = FutureProvider.autoDispose<List<DirectRoomRef>>((
  ref,
) async {
  final rooms = await ref.watch(roomRepositoryProvider).getAllRooms();
  return [
    for (final room in rooms)
      if (room.type == 'direct')
        DirectRoomRef(
          roomId: room.id,
          name: room.name.isEmpty ? 'Direct message' : room.name,
        ),
  ];
});

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
