import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/auth/data/auth_repository.dart';
import 'package:stawi/features/auth/ui/login_screen.dart';
import 'package:stawi/features/rooms/ui/room_list_screen.dart';

import 'test_config.dart';

void main() {
  IntegrationTestConfig.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    /// Helper to build auth-aware widget with routing logic
    Widget buildAuthAwareWidget(AuthRepository authRepo) {
      return ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(authRepo)],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return FutureBuilder<bool>(
                future: authRepo.isLoggedIn(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final isLoggedIn = snapshot.data ?? false;
                  if (isLoggedIn) {
                    return const RoomListScreen();
                  }
                  return const LoginScreen();
                },
              );
            },
          ),
        ),
      );
    }

    testWidgets('displays login screen when not authenticated', (
      WidgetTester tester,
    ) async {
      final mockAuthService = MockAuthServiceImpl();
      mockAuthService.setAuthenticated(authenticated: false);
      final mockAuthRepo = AuthRepository(mockAuthService);

      await tester.pumpWidget(buildAuthAwareWidget(mockAuthRepo));
      await tester.pumpAndSettle();

      // Verify login screen is displayed
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('navigates to room list after successful authentication', (
      WidgetTester tester,
    ) async {
      final mockAuthService = MockAuthServiceImpl();
      mockAuthService.setAuthenticated(
        authenticated: true,
        token: 'test-token',
      );
      final mockAuthRepo = AuthRepository(mockAuthService);

      await tester.pumpWidget(buildAuthAwareWidget(mockAuthRepo));
      await tester.pumpAndSettle();

      // Verify room list screen is displayed
      expect(find.byType(RoomListScreen), findsOneWidget);
    });

    testWidgets('login button is visible and tappable', (
      WidgetTester tester,
    ) async {
      final mockAuthService = MockAuthServiceImpl();
      mockAuthService.setAuthenticated(authenticated: false);
      final mockAuthRepo = AuthRepository(mockAuthService);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Find login button
      final loginButton = find.byType(ElevatedButton);
      expect(loginButton, findsWidgets);

      // Verify button is enabled
      final button = tester.widget<ElevatedButton>(loginButton.first);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows loading indicator during authentication check', (
      WidgetTester tester,
    ) async {
      final mockAuthService = MockAuthServiceImpl();
      final mockAuthRepo = AuthRepository(mockAuthService);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return FutureBuilder<bool>(
                  future: Future.delayed(
                    const Duration(milliseconds: 500),
                    mockAuthRepo.isLoggedIn,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        key: Key('loading-indicator'),
                        child: CircularProgressIndicator(),
                      );
                    }
                    return const Text('Done');
                  },
                );
              },
            ),
          ),
        ),
      );

      // Should show loading initially
      expect(find.byKey(const Key('loading-indicator')), findsOneWidget);

      // Wait for future to complete
      await tester.pumpAndSettle();

      // Loading should be gone
      expect(find.byKey(const Key('loading-indicator')), findsNothing);
    });

    testWidgets('handles logout correctly', (WidgetTester tester) async {
      final mockAuthService = MockAuthServiceImpl();
      mockAuthService.setAuthenticated(
        authenticated: true,
        token: 'test-token',
      );
      final mockAuthRepo = AuthRepository(mockAuthService);

      var isLoggedOut = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepo)],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  key: const Key('logout-button'),
                  onPressed: () async {
                    await mockAuthRepo.logout();
                    isLoggedOut = true;
                  },
                  child: const Text('Logout'),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap logout button
      await tester.tap(find.byKey(const Key('logout-button')));
      await tester.pumpAndSettle();

      // Verify logout was called
      expect(isLoggedOut, isTrue);
    });
  });
}
