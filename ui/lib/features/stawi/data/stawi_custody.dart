import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;

import 'stawi_clients.dart';

/// Finds a bound chat room's RoomCustody address, or null when the source
/// does not know the room (yet).
typedef RoomCustodySource = Future<Uint8List?> Function(String chatRoomId);

/// The custody from finance's read model: a Stawi room's finance id is its
/// chat room id.
RoomCustodySource financeCustodySource(finance.RoomServiceClient rooms) =>
    (chatRoomId) async {
      final room = (await rooms.getRoom(
        finance.GetRoomRequest(roomId: chatRoomId),
      )).room;
      return room.custodyAddress.length == 20
          ? Uint8List.fromList(room.custodyAddress)
          : null;
    };

/// Asks each source in turn and returns the first custody found.
RoomCustodySource firstCustodyOf(List<RoomCustodySource> sources) =>
    (chatRoomId) async {
      for (final source in sources) {
        final custody = await source(chatRoomId);
        if (custody != null) return custody;
      }
      return null;
    };

/// Where custody addresses come from, in order. The chat Room's own Stawi
/// binding (room.stawi, chat#33) goes first once the chat SDK has it; the
/// activation outcome carries no custody, so finance is the source until then.
final roomCustodySourceProvider = Provider<RoomCustodySource>(
  (ref) =>
      firstCustodyOf([financeCustodySource(ref.watch(financeRoomsProvider))]),
);

/// The room's custody address; null while no source knows it.
final roomCustodyProvider = FutureProvider.autoDispose
    .family<Uint8List?, String>(
      (ref, chatRoomId) => ref.watch(roomCustodySourceProvider)(chatRoomId),
    );
