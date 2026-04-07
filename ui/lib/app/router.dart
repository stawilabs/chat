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

/// Notifier that triggers router refresh when auth state changes.
///
/// Also caches the auth and onboarding state so the redirect callback can
/// read them synchronously instead of hitting secure storage on every
/// navigation.
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier(Ref ref) {
    // Seed from current value
    final current = ref.read(authStateProvider);
    _isLoggedIn = current.maybeWhen(
      data: (state) => state == AuthState.authenticated,
      orElse: () => false,
    );

    // Load initial onboarding state
    final onboardingRepo = ref.read(onboardingRepositoryProvider);
    onboardingRepo.isProfileSetupComplete().then((complete) {
      _isProfileSetupComplete = complete;
    });

    // Listen to auth state changes and notify router to re-evaluate redirects
    ref.listen(authStateProvider, (previous, next) {
      _isLoggedIn = next.maybeWhen(
        data: (state) => state == AuthState.authenticated,
        orElse: () => _isLoggedIn,
      );
      // Re-check onboarding state when auth state changes
      onboardingRepo.isProfileSetupComplete().then((complete) {
        if (_isProfileSetupComplete != complete) {
          _isProfileSetupComplete = complete;
          notifyListeners();
        }
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

/// Provider for the auth change notifier
@riverpod
AuthChangeNotifier authChangeNotifier(Ref ref) => AuthChangeNotifier(ref);

@riverpod
GoRouter router(Ref ref) {
  final authChangeNotifier = ref.watch(authChangeProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authChangeNotifier,
    redirect: (context, state) {
      final isLoggedIn = authChangeNotifier.isLoggedIn;
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
        if (!authChangeNotifier.isProfileSetupComplete) {
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
