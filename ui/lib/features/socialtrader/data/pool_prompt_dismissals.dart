import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';

part 'pool_prompt_dismissals.g.dart';

/// Which trading-group rooms already offered their first-visit join sheet.
/// The sheet is offered once per room; the pool_join_prompt card stays in the
/// timeline for whenever the person is ready.
abstract interface class PoolPromptDismissals {
  Future<bool> dismissed(String roomId);
  Future<void> dismiss(String roomId);
}

/// An in-memory store: forgotten when the app stops.
class MemoryPoolPromptDismissals implements PoolPromptDismissals {
  final Set<String> _rooms = {};

  @override
  Future<bool> dismissed(String roomId) async => _rooms.contains(roomId);

  @override
  Future<void> dismiss(String roomId) async => _rooms.add(roomId);
}

/// The app database's store: survives a restart.
final class DriftPoolPromptDismissals implements PoolPromptDismissals {
  DriftPoolPromptDismissals(this._db);

  final AppDatabase _db;

  @override
  Future<bool> dismissed(String roomId) async {
    final row = await (_db.select(
      _db.poolPromptDismissals,
    )..where((d) => d.roomId.equals(roomId))).getSingleOrNull();
    return row != null;
  }

  @override
  Future<void> dismiss(String roomId) => _db
      .into(_db.poolPromptDismissals)
      .insertOnConflictUpdate(
        PoolPromptDismissalsCompanion.insert(
          roomId: roomId,
          dismissedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
}

@Riverpod(keepAlive: true)
PoolPromptDismissals poolPromptDismissals(Ref ref) =>
    DriftPoolPromptDismissals(AppDatabase.instance);
