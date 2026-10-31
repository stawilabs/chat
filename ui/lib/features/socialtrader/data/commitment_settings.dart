import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';

part 'commitment_settings.g.dart';

/// A profile's default commitment: the amount, in a pool's quote asset, that
/// the join sheet pre-fills. It only pre-fills; nothing is committed until the
/// connected wallet signs after a tap.
abstract interface class CommitmentSettings {
  /// The profile's default commitment as a decimal string, or null when none
  /// was saved.
  Future<String?> defaultFor(String profileId);

  /// Remembers [amount] (a positive decimal string) as the profile's default.
  Future<void> save(String profileId, String amount);

  /// Forgets the profile's default.
  Future<void> forget(String profileId);
}

/// Parses a commitment amount, or throws [ArgumentError] when it is not a
/// positive decimal.
String normalizeCommitment(String amount) {
  final normalized = tryNormalizeCommitment(amount);
  if (normalized == null) {
    throw ArgumentError.value(amount, 'amount', 'must be a positive amount');
  }
  return normalized;
}

/// Parses a commitment amount; null when it is not a positive decimal.
String? tryNormalizeCommitment(String amount) {
  final trimmed = amount.trim();
  final value = double.tryParse(trimmed);
  if (value == null || value.isNaN || value.isInfinite || value <= 0) {
    return null;
  }
  return trimmed;
}

/// An in-memory store: what is saved is lost when the app stops.
class MemoryCommitmentSettings implements CommitmentSettings {
  final Map<String, String> _defaults = {};

  @override
  Future<String?> defaultFor(String profileId) async => _defaults[profileId];

  @override
  Future<void> save(String profileId, String amount) async {
    _defaults[profileId] = normalizeCommitment(amount);
  }

  @override
  Future<void> forget(String profileId) async => _defaults.remove(profileId);
}

/// The app database's store: what is saved survives a restart.
final class DriftCommitmentSettings implements CommitmentSettings {
  DriftCommitmentSettings(this._db);

  final AppDatabase _db;

  @override
  Future<String?> defaultFor(String profileId) async {
    final row = await (_db.select(
      _db.tradingSettings,
    )..where((s) => s.profileId.equals(profileId))).getSingleOrNull();
    if (row == null || !row.remember) return null;
    return row.defaultCommitmentQuote;
  }

  @override
  Future<void> save(String profileId, String amount) async {
    final normalized = normalizeCommitment(amount);
    await _db
        .into(_db.tradingSettings)
        .insertOnConflictUpdate(
          TradingSettingsCompanion.insert(
            profileId: profileId,
            defaultCommitmentQuote: normalized,
            remember: const Value(true),
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  @override
  Future<void> forget(String profileId) async {
    await (_db.delete(
      _db.tradingSettings,
    )..where((s) => s.profileId.equals(profileId))).go();
  }
}

@Riverpod(keepAlive: true)
CommitmentSettings commitmentSettings(Ref ref) =>
    DriftCommitmentSettings(AppDatabase.instance);
