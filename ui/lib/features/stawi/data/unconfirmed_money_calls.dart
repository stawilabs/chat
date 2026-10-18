import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import 'stawi_account_service.dart';

/// Where a signed money call whose submit got no clear answer is kept until
/// its fate is known: one per profile.
abstract interface class UnconfirmedMoneyCallStore {
  /// The profile's unconfirmed call, if any.
  Future<SignedMoneyCall?> read(String profileId);

  /// Keeps [call] as the profile's unconfirmed call. Holding it again is a
  /// no-op; while another call is held this fails ([anotherCallHeldMessage])
  /// and nothing may be sent, since replacing it would lose that call.
  Future<void> hold(String profileId, SignedMoneyCall call);

  /// Forgets the profile's unconfirmed call when it is [callId].
  Future<void> clear(String profileId, String callId);
}

/// Said when a call cannot be kept because another is still unconfirmed.
const String anotherCallHeldMessage =
    'Another payment is still being checked; wait until it is known';

/// An in-memory store: what is held is lost when the app stops.
final class MemoryUnconfirmedMoneyCallStore
    implements UnconfirmedMoneyCallStore {
  final Map<String, SignedMoneyCall> _calls = {};

  @override
  Future<SignedMoneyCall?> read(String profileId) async => _calls[profileId];

  @override
  Future<void> hold(String profileId, SignedMoneyCall call) async {
    final held = _calls[profileId];
    if (held != null && held.callId != call.callId) {
      throw StateError(anotherCallHeldMessage);
    }
    _calls[profileId] = call;
  }

  @override
  Future<void> clear(String profileId, String callId) async {
    if (_calls[profileId]?.callId == callId) _calls.remove(profileId);
  }
}

/// The app database's store: what is held survives a restart.
final class DriftUnconfirmedMoneyCallStore
    implements UnconfirmedMoneyCallStore {
  DriftUnconfirmedMoneyCallStore(this._db);

  final AppDatabase _db;

  @override
  Future<SignedMoneyCall?> read(String profileId) async {
    final row = await (_db.select(
      _db.unconfirmedMoneyCalls,
    )..where((c) => c.profileId.equals(profileId))).getSingleOrNull();
    if (row == null) return null;
    return SignedMoneyCall(
      callId: row.callId,
      authorization: row.authorization,
      title: row.title,
    );
  }

  @override
  Future<void> hold(String profileId, SignedMoneyCall call) =>
      _db.transaction(() async {
        final held = await read(profileId);
        if (held != null) {
          if (held.callId != call.callId) {
            throw StateError(anotherCallHeldMessage);
          }
          return;
        }
        await _db
            .into(_db.unconfirmedMoneyCalls)
            .insert(
              UnconfirmedMoneyCallsCompanion.insert(
                profileId: profileId,
                callId: call.callId,
                authorization: call.authorization,
                title: call.title,
                createdAt: DateTime.now().millisecondsSinceEpoch,
              ),
            );
      });

  @override
  Future<void> clear(String profileId, String callId) =>
      (_db.delete(_db.unconfirmedMoneyCalls)..where(
            (c) => c.profileId.equals(profileId) & c.callId.equals(callId),
          ))
          .go();
}

/// The app's store: the app database, so an unconfirmed call survives a
/// restart.
final unconfirmedMoneyCallStoreProvider = Provider<UnconfirmedMoneyCallStore>(
  (ref) => DriftUnconfirmedMoneyCallStore(AppDatabase.instance),
);
