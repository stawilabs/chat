import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Repository for tracking onboarding state
class OnboardingRepository {
  OnboardingRepository(this._storage);
  static const _contactsSyncedKey = 'contacts_synced';
  static const _profileSetupCompleteKey = 'profile_setup_complete';
  final FlutterSecureStorage _storage;

  /// Check if contacts have been synced
  Future<bool> hasContactsSynced() async {
    final value = await _storage.read(key: _contactsSyncedKey);
    return value == 'true';
  }

  /// Mark contacts as synced
  Future<void> markContactsSynced() async {
    await _storage.write(key: _contactsSyncedKey, value: 'true');
  }

  /// Check if the user has completed initial profile setup (set a photo)
  Future<bool> isProfileSetupComplete() async {
    final value = await _storage.read(key: _profileSetupCompleteKey);
    return value == 'true';
  }

  /// Mark profile setup as complete
  Future<void> markProfileSetupComplete() async {
    await _storage.write(key: _profileSetupCompleteKey, value: 'true');
  }

  /// Reset onboarding state (for testing or logout)
  Future<void> reset() async {
    await _storage.delete(key: _contactsSyncedKey);
    await _storage.delete(key: _profileSetupCompleteKey);
  }
}

/// Provider for OnboardingRepository
final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(const FlutterSecureStorage()),
);

/// Provider to check if contacts sync is needed
final needsContactSyncProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(onboardingRepositoryProvider);
  final hasSynced = await repo.hasContactsSynced();
  return !hasSynced;
});
