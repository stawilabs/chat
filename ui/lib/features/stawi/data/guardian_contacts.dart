import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../messages/data/message_providers.dart';
import '../../messages/data/message_sending_service.dart';
import '../../rooms/data/room_subscription_service.dart';
import '../domain/guardian_contacts.dart';
import 'stawi_account_service.dart';
import 'stawi_counterparty.dart';

/// One of the person's DMs as a possible guardian: the guardian key its
/// partner shared there, if any.
final class GuardianKeyOffer {
  const GuardianKeyOffer({required this.roomId, required this.name, this.key});

  final String roomId;
  final String name;

  /// The key the partner shared; null when they have not shared one.
  final Uint8List? key;
}

/// How many of a DM's latest messages are read for a shared key.
const int guardianOfferScan = 200;

/// The person's DMs, newest first, each with the guardian key its partner
/// shared there (read from this device's messages).
final guardianKeyOffersProvider =
    FutureProvider.autoDispose<List<GuardianKeyOffer>>((ref) async {
      final rooms = await ref.watch(directRoomsProvider.future);
      final messages = ref.watch(messageRepositoryProvider);
      final myKey = (await ref.watch(stawiAccountStatusProvider.future))
          .deviceKey
          .address;
      return [
        for (final room in rooms)
          GuardianKeyOffer(
            roomId: room.roomId,
            name: room.name,
            key: offeredGuardianKey(
              await messages.getMessagesForRoom(
                room.roomId,
                limit: guardianOfferScan,
              ),
              mySubscriptionId: await ref.watch(
                currentUserSubscriptionIdProvider(room.roomId).future,
              ),
              myKey: myKey,
            ),
          ),
      ];
    });

/// Sends a guardian message into a DM. A guardian key is a public address,
/// and the owner's app reads it from the message, so it is sent as plain
/// text.
typedef GuardianMessageSender = Future<void> Function(
  String roomId,
  String text,
);

final guardianMessageSenderProvider = Provider<GuardianMessageSender>(
  (ref) => (roomId, text) async {
    await ref
        .read(messageSendingServiceProvider)
        .sendTextMessage(roomId: roomId, text: text, encrypt: false);
  },
);
