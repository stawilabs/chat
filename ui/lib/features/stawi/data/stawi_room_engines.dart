import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A room's bound rules engines: the LoanEngine and RulesEngine its custody
/// is wired to. The device compares a prepared engine call's target with
/// them, so a call aimed at another contract is never signed.
class RoomEngines {
  const RoomEngines({required this.loanEngine, required this.rulesEngine});

  final Uint8List loanEngine;
  final Uint8List rulesEngine;
}

/// Reads a room's engines; null when they cannot be known yet.
typedef RoomEngineSource = Future<RoomEngines?> Function(String roomId);

/// One product a room's rules define: a loan form, or a dues product a member
/// chooses an amount for.
class RoomProduct {
  const RoomProduct({required this.id, required this.name, required this.kind});

  /// The 32-byte product id the engines take.
  final Uint8List id;
  final String name;
  final RoomProductKind kind;
}

enum RoomProductKind { loan, dues }

/// Reads a room's products; null when they cannot be listed yet (the member
/// then names the product as the room's rules do).
typedef RoomProductSource = Future<List<RoomProduct>?> Function(String roomId);

// TODO(stawilabs): stawi 0.4.0 adds the room's engine addresses and its
// products. Then point roomEngineSourceProvider at that read (settlement or
// finance, as 0.4.0 names it) and roomProductSourceProvider at the products
// list; the engine check and the product pickers already use them.
final roomEngineSourceProvider = Provider<RoomEngineSource>(
  (ref) =>
      (roomId) async => null,
);

final roomProductSourceProvider = Provider<RoomProductSource>(
  (ref) =>
      (roomId) async => null,
);

final roomEnginesProvider = FutureProvider.autoDispose
    .family<RoomEngines?, String>(
      (ref, roomId) => ref.watch(roomEngineSourceProvider)(roomId),
    );

final roomProductsProvider = FutureProvider.autoDispose
    .family<List<RoomProduct>?, String>(
      (ref, roomId) => ref.watch(roomProductSourceProvider)(roomId),
    );
