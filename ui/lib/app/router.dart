import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/data/auth_state_provider.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/calls/ui/call_history_screen.dart';
import '../features/calls/ui/call_screen.dart';
import '../features/contacts/ui/contacts_screen.dart';
import '../features/messages/ui/chat_screen.dart';
import '../features/messages/ui/starred_messages_screen.dart';
import '../features/onboarding/data/onboarding_repository.dart';
import '../features/profile/ui/profile_edit_screen.dart';
import '../features/profile/ui/profile_screen.dart';
import '../features/profile/ui/profile_setup_screen.dart';
import '../features/rooms/ui/group_settings_screen.dart';
import '../features/rooms/ui/room_detail_screen.dart';
import '../features/rooms/ui/room_list_screen.dart';
import '../features/search/ui/global_search_screen.dart';
import '../features/settings/ui/account_settings_screen.dart';
import '../features/settings/ui/cache_settings_screen.dart';
import '../features/settings/ui/chat_settings_screen.dart';
import '../features/settings/ui/linked_devices_screen.dart';
import '../features/settings/ui/media_compression_settings_screen.dart';
import '../features/settings/ui/notification_settings_screen.dart';
import '../features/settings/ui/privacy_settings_screen.dart';
import '../features/settings/ui/security_settings_screen.dart';
import '../features/settings/ui/settings_screen.dart';
import '../features/settings/ui/storage_settings_screen.dart';
import '../features/settings/ui/theme_settings_screen.dart';
import '../features/settings/ui/two_factor_setup_screen.dart';

part 'router.g.dart';

/// Thin [ChangeNotifier] that re-triggers `GoRouter` redirects whenever
/// the runtime-sourced [authStateProvider] fires a new value.
///
/// Also caches onboarding completion so the synchronous `redirect`
/// callback can decide whether to send the user to `/profile/setup`
/// without touching secure storage on every navigation. A transient
/// [AuthState.loading] (e.g. silent refresh) preserves the last known
/// login status so the user isn't bounced to `/login` mid-refresh.
class AuthRouterRefreshListenable extends ChangeNotifier {
  AuthRouterRefreshListenable(Ref ref) {
    // Seed login status synchronously so the first redirect pass sees a
    // stable value instead of an indeterminate `loading`.
    final seed = ref.read(authStateProvider);
    _isLoggedIn = seed.maybeWhen(
      data: (s) => s == AuthState.authenticated,
      orElse: () => false,
    );

    // Load initial onboarding state (async — redirect will re-evaluate
    // once the value lands and we call [notifyListeners]).
    final onboardingRepo = ref.read(onboardingRepositoryProvider);
    onboardingRepo.isProfileSetupComplete().then((complete) {
      if (_isProfileSetupComplete != complete) {
        _isProfileSetupComplete = complete;
        notifyListeners();
      }
    });

    // Re-run redirects whenever the runtime's auth state changes; also
    // re-check onboarding since its value depends on the logged-in user.
    ref.listen(authStateProvider, (previous, next) {
      _isLoggedIn = next.maybeWhen(
        data: (s) => s == AuthState.authenticated,
        // Preserve previous value during transient loading states
        // (e.g. runtime refresh) to avoid bouncing the user to /login.
        orElse: () => _isLoggedIn,
      );
      onboardingRepo.isProfileSetupComplete().then((complete) {
        if (_isProfileSetupComplete != complete) {
          _isProfileSetupComplete = complete;
        }
        notifyListeners();
      });
      notifyListeners();
    });
  }

  bool _isLoggedIn = false;
  bool _isProfileSetupComplete = false;

  /// Cached login status, updated reactively via [authStateProvider].
  bool get isLoggedIn => _isLoggedIn;

  /// Cached profile setup status, updated when auth state changes.
  bool get isProfileSetupComplete => _isProfileSetupComplete;
}

/// Provider for the router refresh listenable.
@riverpod
AuthRouterRefreshListenable authRouterRefreshListenable(Ref ref) =>
    AuthRouterRefreshListenable(ref);

@riverpod
GoRouter router(Ref ref) {
  final refreshListenable = ref.watch(authRouterRefreshListenableProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      // Source auth state directly from the chat-level provider, which
      // re-exports the runtime's authoritative state. During transient
      // `loading`/`refreshing` states we fall back to the refresh
      // listener's cached login value so the user isn't bounced to
      // `/login` during silent token refresh.
      final authAsync = ref.read(authStateProvider);
      final isLoggedIn = authAsync.maybeWhen(
        data: (s) => s == AuthState.authenticated,
        orElse: () => refreshListenable.isLoggedIn,
      );
      final location = state.matchedLocation;
      final isLoginRoute = location == '/login';
      final isSetupRoute = location == '/profile/setup';

      // If not logged in and not on login page, redirect to login
      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      // If logged in and on login page, go to home
      if (isLoggedIn && isLoginRoute) {
        return '/';
      }

      // If logged in, check if profile setup is complete
      if (isLoggedIn && !isSetupRoute && !isLoginRoute) {
        if (!refreshListenable.isProfileSetupComplete) {
          return '/profile/setup';
        }
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/', builder: (context, state) => const RoomListScreen()),
      GoRoute(
        path: '/profile/setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/contacts/select',
        builder: (context, state) => const ContactsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/account',
        builder: (context, state) => const AccountSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/privacy',
        builder: (context, state) => const PrivacySettingsScreen(),
      ),
      GoRoute(
        path: '/settings/chats',
        builder: (context, state) => const ChatSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/storage',
        builder: (context, state) => const StorageSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/security',
        builder: (context, state) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: '/settings/storage/compression',
        builder: (context, state) => const MediaCompressionSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/storage/cache',
        builder: (context, state) => const CacheSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/account/devices',
        builder: (context, state) => const LinkedDevicesScreen(),
      ),
      GoRoute(
        path: '/settings/security/2fa',
        builder: (context, state) => const TwoFactorSetupScreen(),
      ),
      GoRoute(
        path: '/settings/theme',
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      GoRoute(
        path: '/chat/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final roomName = state.uri.queryParameters['name'] ?? 'Chat';
          return ChatScreen(roomId: roomId, roomName: roomName);
        },
      ),
      GoRoute(
        path: '/room/:roomId/details',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final roomName = state.uri.queryParameters['name'] ?? 'Room Details';
          return RoomDetailScreen(roomId: roomId, roomName: roomName);
        },
      ),
      GoRoute(
        path: '/room/:roomId/settings',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final roomName =
              state.uri.queryParameters['name'] ?? 'Group Settings';
          return GroupSettingsScreen(roomId: roomId, roomName: roomName);
        },
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/profile/:profileId',
        builder: (context, state) {
          final profileId = state.pathParameters['profileId']!;
          return ProfileScreen(profileId: profileId);
        },
      ),
      GoRoute(
        path: '/messages/starred',
        builder: (context, state) => const StarredMessagesScreen(),
      ),
      GoRoute(
        path: '/call/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final roomName = state.uri.queryParameters['name'] ?? 'Call';
          return CallScreen(roomId: roomId, roomName: roomName);
        },
      ),
      GoRoute(
        path: '/calls/history',
        builder: (context, state) => const CallHistoryScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const GlobalSearchScreen(),
      ),
    ],
  );
}
