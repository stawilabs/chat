import 'dart:async';

import 'package:antinvestor_auth_runtime/antinvestor_auth_runtime.dart'
    as runtime;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../../onboarding/data/onboarding_repository.dart';

part 'auth_state_provider.g.dart';

/// Authentication state exposed to the chat app tree.
///
/// Mirrors the legacy tri-state enum so existing consumers (router,
/// login screen, drawer) continue to compile unchanged. The underlying
/// source of truth is [runtime.AuthRuntime.authStateStream] — the
/// runtime owns all OAuth + refresh logic.
enum AuthState { authenticated, unauthenticated, loading }

AuthState _map(runtime.AuthState s) {
  switch (s) {
    case runtime.AuthState.authenticated:
      return AuthState.authenticated;
    case runtime.AuthState.unauthenticated:
      return AuthState.unauthenticated;
    case runtime.AuthState.initializing:
    case runtime.AuthState.refreshing:
      return AuthState.loading;
    case runtime.AuthState.error:
      return AuthState.unauthenticated;
  }
}

/// Chat-level auth state notifier. Delegates to the runtime but keeps
/// the `login()` / `logout()` / `refresh()` surface expected by
/// existing UI call sites.
@riverpod
class AuthStateNotifier extends _$AuthStateNotifier {
  StreamSubscription<runtime.AuthState>? _sub;

  @override
  Future<AuthState> build() async {
    final rt = ref.watch(runtime.authRuntimeProvider);

    // Keep the notifier's state in sync with the runtime's stream for
    // the lifetime of this provider.
    _sub?.cancel();
    _sub = rt.authStateStream.listen((rs) {
      if (!ref.mounted) return;
      state = AsyncValue.data(_map(rs));
    });
    ref.onDispose(() {
      _sub?.cancel();
      _sub = null;
    });

    return _map(rt.state);
  }

  /// Trigger login via the runtime.
  Future<void> login() async {
    state = const AsyncValue.loading();
    try {
      AppLogger.info('Login initiated');
      final rt = ref.read(runtime.authRuntimeProvider);
      await rt.ensureAuthenticated();
      if (!ref.mounted) return;
      state = AsyncValue.data(_map(rt.state));
      AppLogger.info('Login complete, state=${rt.state}');
    } catch (e, stack) {
      AppLogger.error('Login failed', error: e, stackTrace: stack);
      if (ref.mounted) {
        state = AsyncValue.error(e, stack);
      }
      rethrow;
    }
  }

  /// Trigger logout via the runtime.
  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      AppLogger.info('Logout initiated');
      final rt = ref.read(runtime.authRuntimeProvider);
      final onboardingRepo = ref.read(onboardingRepositoryProvider);
      await rt.logout();
      await onboardingRepo.reset();
      if (!ref.mounted) return;
      state = const AsyncValue.data(AuthState.unauthenticated);
      AppLogger.info('Logout complete');
    } catch (e, stack) {
      AppLogger.error('Logout failed', error: e, stackTrace: stack);
      if (ref.mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  /// Re-evaluate the runtime's current state. The runtime handles its
  /// own refresh loop internally, so this is just a state snapshot.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(_map(ref.read(runtime.authRuntimeProvider).state));
  }
}
