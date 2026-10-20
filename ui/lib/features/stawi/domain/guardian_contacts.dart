/// How a guardian key travels between people: the guardian shares it in a
/// direct message, and the owner's app reads it from that DM. No API names
/// another person's guardian key, so the DM partner's own message is the
/// source; the owner still reviews the key before signing, the change waits
/// 24 hours and the owner can cancel it.
library;

import 'dart:typed_data';

import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../messages/domain/room_event.dart';
import 'signing_checks.dart' show bytesEqual;

/// The line a shared guardian key is found by.
const String guardianKeyLabel = 'My Stawi guardian key:';

final RegExp _offered = RegExp(
  'My Stawi guardian key: (0x[0-9a-fA-F]{40})(?![0-9a-fA-F])',
);

/// What a guardian sends to offer [key].
String guardianKeyMessage(Uint8List key) =>
    'I can be your Stawi guardian.\n'
    '$guardianKeyLabel ${bytesToHex0x(key).toLowerCase()}\n'
    'In Stawi: Stawi account, Guardians and recovery, Add a guardian, then '
    'choose me.';

/// What an owner sends to ask someone to be their guardian.
const String guardianAskMessage =
    'Would you be my Stawi guardian? In Stawi open Stawi account, People I '
    'guard: register this phone as a guardian key, then share it with me '
    'here.';

/// The guardian key the DM partner offered most recently in [events]: the
/// newest text message not sent by [mySubscriptionId] that names one, and
/// not [myKey] (this phone's own key, offered to someone else). Null when
/// none is offered.
Uint8List? offeredGuardianKey(
  Iterable<RoomEvent> events, {
  required String? mySubscriptionId,
  Uint8List? myKey,
}) {
  final sorted = events.toList()
    ..sort(
      (a, b) =>
          (b.serverTs ?? b.createdAt).compareTo(a.serverTs ?? a.createdAt),
    );
  for (final e in sorted) {
    if (e.type != RoomEventType.text || e.isDeleted) continue;
    if (mySubscriptionId != null && e.senderId == mySubscriptionId) continue;
    final text = e.content['text'];
    if (text is! String) continue;
    final m = _offered.firstMatch(text);
    if (m == null) continue;
    final key = hexToBytes(m.group(1)!);
    if (key.every((b) => b == 0)) continue;
    if (myKey != null && bytesEqual(key, myKey)) continue;
    return key;
  }
  return null;
}
