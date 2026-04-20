import 'package:antinvestor_auth_runtime/antinvestor_auth_runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// The legacy `MockAuthServiceImpl` fixture was removed as part of the
// auth-runtime migration; integration tests now inject a
// [MockAuthRuntime] via `authRuntimeProvider`.
import '../test/support/mock_auth_runtime.dart';

export '../test/support/mock_auth_runtime.dart';

/// Integration test configuration and utilities
class IntegrationTestConfig {
  /// Initialize integration test bindings
  static void ensureInitialized() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  }

  /// Default timeout for integration test operations
  static const defaultTimeout = Duration(seconds: 30);

  /// Short timeout for quick operations
  static const shortTimeout = Duration(seconds: 5);

  /// Long timeout for network operations
  static const longTimeout = Duration(minutes: 2);

  /// Build a [MockAuthRuntime] in the requested [state] with a minimal
  /// set of default claims/roles so widgets that read claims don't
  /// crash.
  static MockAuthRuntime buildAuthRuntime({
    AuthState state = AuthState.authenticated,
  }) {
    return MockAuthRuntime(
      initialState: state,
      claimsMap: const <String, dynamic>{
        'sub': 'test-user',
        'contact_id': 'test-contact',
      },
      roles: const <String>['user'],
    );
  }
}

/// Test helper extensions
extension IntegrationTestExtensions on WidgetTester {
  /// Wait for widget and settle
  Future<void> waitAndSettle() async {
    await pumpAndSettle();
  }

  /// Find and tap a widget by key
  Future<void> tapByKey(Key key) async {
    await tap(find.byKey(key));
    await pumpAndSettle();
  }

  /// Find and tap a widget by icon
  Future<void> tapIcon(IconData icon) async {
    await tap(find.byIcon(icon));
    await pumpAndSettle();
  }

  /// Enter text and submit
  Future<void> enterTextAndSubmit(Finder finder, String text) async {
    await enterText(finder, text);
    await testTextInput.receiveAction(TextInputAction.done);
    await pumpAndSettle();
  }

  /// Scroll until widget is visible
  Future<void> scrollUntilVisible(
    Finder finder, {
    double delta = 100,
    int maxScrolls = 50,
  }) async {
    var scrolls = 0;
    while (!finder.evaluate().isNotEmpty && scrolls < maxScrolls) {
      await drag(find.byType(Scrollable).first, Offset(0, -delta));
      await pumpAndSettle();
      scrolls++;
    }
  }
}
