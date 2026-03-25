import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/networking/client.dart';
import '../../onboarding/data/onboarding_repository.dart';
import 'auth_repository.dart';

part 'auth_state_provider.g.dart';

/// Authentication state
enum AuthState { authenticated, unauthenticated, loading }

/// Authentication state notifier that watches auth status
@riverpod
class AuthStateNotifier extends _$AuthStateNotifier {
  @override
  Future<AuthState> build() async {
    final authRepo = ref.watch(authRepositoryProvider);
    final isLoggedIn = await authRepo.isLoggedIn();

    if (isLoggedIn) {
      // Ensure we have a valid access token (will refresh if expired)
      // Use the status-returning version to distinguish between transient and permanent errors
      final result = await authRepo.ensureValidAccessTokenWithStatus();

      if (result.token != null) {
        AppLogger.info('Authentication state: authenticated');
        return AuthState.authenticated;
      }

      // Token is null - check if this is a permanent failure requiring re-login
      if (result.needsRelogin) {
        AppLogger.info(
          'Authentication state: unauthenticated (permanent token failure)',
        );
        return AuthState.unauthenticated;
      }

      // Transient error (network issues, etc.) - user is still authenticated
      // They have valid credentials, just can't refresh right now
      AppLogger.info(
        'Authentication state: authenticated (transient refresh error, keeping session)',
      );
      return AuthState.authenticated;
    }

    AppLogger.info('Authentication state: unauthenticated');
    return AuthState.unauthenticated;
  }

  /// Trigger login
  Future<void> login() async {
    state = const AsyncValue.loading();

    try {
      AppLogger.info('Login initiated');
      final authRepo = ref.read(authRepositoryProvider);

      // Perform authentication
      await authRepo.login();

      // Check if provider is still mounted after async operation
      if (!ref.mounted) return;

      // Verify authentication was successful by checking if we have a token
      final isLoggedIn = await authRepo.isLoggedIn();
      if (!isLoggedIn) {
        AppLogger.warning('Login completed but no token found');
        state = const AsyncValue.data(AuthState.unauthenticated);
        return;
      }

      // CRITICAL: Reload TokenManager from storage after login
      // AuthService saves tokens to secure storage, but TokenManager has its own
      // in-memory cache that needs to be refreshed to pick up the new tokens.
      // Without this, API clients won't have access to the freshly stored tokens.
      final tokenManager = ref.read(tokenManagerProvider);
      await reloadTokenManager(tokenManager);

      state = const AsyncValue.data(AuthState.authenticated);
      AppLogger.info('Login successful, state changed to authenticated');
    } catch (e, stack) {
      AppLogger.error('Login failed', error: e, stackTrace: stack);

      // Always set error state and rethrow first
      // Only skip state update if already unmounted (to avoid Riverpod error)
      // but still rethrow so UI can handle it
      if (ref.mounted) {
        state = AsyncValue.error(e, stack);
      }
      rethrow;
    }
  }

  /// Trigger logout
  Future<void> logout() async {
    state = const AsyncValue.loading();

    try {
      AppLogger.info('Logout initiated');
      final authRepo = ref.read(authRepositoryProvider);
      final onboardingRepo = ref.read(onboardingRepositoryProvider);
      final tokenManager = ref.read(tokenManagerProvider);

      // Clear tokens from both storage and TokenManager's in-memory cache
      await authRepo.logout();
      await tokenManager.clearTokens();
      await onboardingRepo.reset(); // Clear onboarding state for next login

      // Check if provider is still mounted after async operation
      if (!ref.mounted) return;

      state = const AsyncValue.data(AuthState.unauthenticated);
      AppLogger.info('Logout successful, state changed to unauthenticated');
    } catch (e, stack) {
      AppLogger.error('Logout failed', error: e, stackTrace: stack);

      // Only set error state if still mounted (to avoid Riverpod error)
      if (ref.mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  /// Refresh authentication state
  /// This will attempt to refresh the token and update state accordingly
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepo = ref.read(authRepositoryProvider);
      final isLoggedIn = await authRepo.isLoggedIn();

      if (isLoggedIn) {
        // Try to refresh the token and check if re-login is needed
        final result = await authRepo.ensureValidAccessTokenWithStatus(
          maxRetries: 2, // Fewer retries for manual refresh
          retryDelay: const Duration(seconds: 1),
        );

        if (result.needsRelogin) {
          AppLogger.info('Refresh: permanent failure, user needs to re-login');
          return AuthState.unauthenticated;
        }

        // Either we have a token, or it's a transient error - keep authenticated
        return AuthState.authenticated;
      }
      return AuthState.unauthenticated;
    });
  }
}
