import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api_chat/stawi_api_chat.dart' as pb;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' show hexToBytes;

import '../../../core/networking/client.dart';

/// Where a room's conversion to a Stawi room stands, as chat records it.
enum StawiBindingState { pending, bound, failed }

/// A chat room's Stawi binding (chat.v1 Room.stawi): every member sees it,
/// including one who joined after the conversion.
class StawiBinding {
  const StawiBinding({
    required this.state,
    required this.genesisId,
    required this.genesisEventId,
    this.custody,
    this.governance,
    this.chainId = 0,
    this.genesisExpiresAt,
  });

  factory StawiBinding.fromProto(pb.StawiRoomBinding b) => StawiBinding(
    state: switch (b.state) {
      pb.StawiRoomState.STAWI_ROOM_STATE_BOUND => StawiBindingState.bound,
      pb.StawiRoomState.STAWI_ROOM_STATE_FAILED => StawiBindingState.failed,
      _ => StawiBindingState.pending,
    },
    genesisId: b.genesisId,
    genesisEventId: b.genesisEventId,
    custody: _address(b.custodyAddress),
    governance: _address(b.governanceAddress),
    chainId: b.chainId.toInt(),
    genesisExpiresAt: b.hasGenesisExpiresAt()
        ? b.genesisExpiresAt.toDateTime()
        : null,
  );

  final StawiBindingState state;
  final String genesisId;

  /// The conversion event that carries the genesis card.
  final String genesisEventId;

  /// RoomCustody and GovernanceModule, set once bound.
  final Uint8List? custody;
  final Uint8List? governance;
  final int chainId;
  final DateTime? genesisExpiresAt;

  bool get isBound => state == StawiBindingState.bound;

  static Uint8List? _address(String hex) {
    if (hex.isEmpty) return null;
    try {
      final bytes = hexToBytes(hex);
      return bytes.length == 20 ? bytes : null;
    } on FormatException {
      return null;
    }
  }
}

/// Reads a room's Stawi binding; null for a plain chat room.
typedef StawiBindingReader = Future<StawiBinding?> Function(String roomId);

/// The binding from chat's GetRoom.
StawiBindingReader chatBindingReader(pb.ChatServiceClient chat) =>
    (roomId) async {
      final room = (await chat.getRoom(pb.GetRoomRequest(roomId: roomId))).room;
      return room.hasStawi() ? StawiBinding.fromProto(room.stawi) : null;
    };

final stawiBindingReaderProvider = FutureProvider<StawiBindingReader>(
  (ref) async =>
      chatBindingReader(await ref.watch(chatServiceClientProvider.future)),
);

/// The room's Stawi binding, live from chat.
final stawiBindingProvider = FutureProvider.autoDispose
    .family<StawiBinding?, String>(
      (ref, roomId) async =>
          (await ref.watch(stawiBindingReaderProvider.future))(roomId),
    );
