import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../rooms/data/room_providers.dart';
import '../../rooms/domain/room.dart';

part 'pool_binding.g.dart';

/// The room metadata key naming the pool a trading group is bound to. The
/// server validates and records the binding (only the pool leader may set
/// it); for the app the key is the hint that the room is a trading group.
const String poolIdMetadataKey = 'socialtrader.pool_id';

/// A room's binding to a strategy pool, as the room's metadata shows it.
@immutable
class PoolBinding {
  const PoolBinding({required this.poolId});

  /// The pool address, lowercase hex.
  final String poolId;

  /// The binding of [room], or null for a plain chat room. Accepts the flat
  /// key and the nested `{"socialtrader": {"pool_id": ...}}` form.
  static PoolBinding? of(Room? room) {
    final metadata = room?.metadata;
    if (metadata == null) return null;
    var value = metadata[poolIdMetadataKey];
    if (value is! String || value.isEmpty) {
      final nested = metadata['socialtrader'];
      value = nested is Map ? nested['pool_id'] : null;
    }
    if (value is! String || value.isEmpty) return null;
    return PoolBinding(poolId: value.toLowerCase());
  }

  @override
  bool operator ==(Object other) =>
      other is PoolBinding && other.poolId == poolId;

  @override
  int get hashCode => poolId.hashCode;
}

/// The pool binding of a room, null for a plain room.
@riverpod
Future<PoolBinding?> poolBinding(Ref ref, String roomId) async =>
    PoolBinding.of(await ref.watch(roomByIdProvider(roomId).future));
