import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stawi/features/auth/data/auth_service.dart';

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
}

/// Mock implementations for integration testing
class MockAuthServiceImpl extends AuthService {
  MockAuthServiceImpl()
    : super(
        const FlutterSecureStorage(),
        issuerUrl: 'https://mock-oauth.test',
        clientId: 'test-client-id',
      );

  bool _isAuthenticated = false;
  String? _accessToken;

  void setAuthenticated({required bool authenticated, String? token}) {
    _isAuthenticated = authenticated;
    _accessToken = token ?? (authenticated ? 'test-access-token' : null);
  }

  @override
  Future<bool> isAuthenticated() async => _isAuthenticated;

  @override
  Future<bool> hasValidAccessToken() async => _isAuthenticated;

  @override
  Future<void> logout() async {
    _isAuthenticated = false;
    _accessToken = null;
  }

  @override
  Future<({String? token, bool needsRelogin})>
  ensureValidAccessTokenWithStatus({
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    return (token: _accessToken, needsRelogin: !_isAuthenticated);
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
