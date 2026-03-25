/// Authentication helper utilities for E2E tests.
///
/// Provides methods for logging in, logging out, and managing
/// authentication state during E2E test execution.
library;

import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:stawi/core/error/error_handler.dart' show TimeoutException;

import '../config/staging_config.dart';
import '../config/test_accounts.dart';

/// Helper class for authentication-related E2E test operations.
class AuthHelper {
  /// Creates an AuthHelper with the given PatrolTester.
  AuthHelper(this.$);

  /// The PatrolTester instance for interacting with the app.
  final PatrolIntegrationTester $;

  /// Logs in with the provided test account credentials.
  ///
  /// This method navigates through the login flow, enters credentials,
  /// and waits for successful authentication.
  ///
  /// [account] - The test account to use for login.
  /// [timeout] - Optional timeout for the login operation.
  ///
  /// Throws [TimeoutException] if login takes longer than the timeout.
  Future<void> loginWithCredentials(
    TestAccount account, {
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? TestTimeouts.authTimeout;

    // Wait for login screen to be visible
    await $.pumpAndSettle(timeout: effectiveTimeout);

    // Find and tap the login button to initiate OAuth flow
    final loginButton = $(ElevatedButton).containing('Login');
    if (loginButton.exists) {
      await loginButton.tap();
    } else {
      // Try alternative login button patterns
      final signInButton = $(ElevatedButton).containing('Sign In');
      if (signInButton.exists) {
        await signInButton.tap();
      }
    }

    await $.pumpAndSettle();

    // Wait for OAuth login form (email field)
    final emailField = $(TextField).withHint('Email');
    if (emailField.exists) {
      await emailField.enterText(account.email);
      await $.pumpAndSettle();
    }

    // Enter password
    final passwordField = $(TextField).withHint('Password');
    if (passwordField.exists) {
      await passwordField.enterText(account.password);
      await $.pumpAndSettle();
    }

    // Submit login form
    final submitButton = $(ElevatedButton).containing('Continue');
    if (submitButton.exists) {
      await submitButton.tap();
    } else {
      // Try alternative submit patterns
      final loginSubmit = $(ElevatedButton).containing('Sign In');
      if (loginSubmit.exists) {
        await loginSubmit.tap();
      }
    }

    // Wait for authentication to complete and home screen to appear
    await waitForHomeScreen(timeout: effectiveTimeout);
  }

  /// Ensures the user is logged out before starting a test.
  ///
  /// If the user is currently logged in, this method navigates to
  /// settings and performs a logout. If already logged out, it does nothing.
  Future<void> ensureLoggedOut({Duration? timeout}) async {
    final effectiveTimeout = timeout ?? TestTimeouts.authTimeout;

    await $.pumpAndSettle(timeout: effectiveTimeout);

    // Check if we're on the home screen (logged in)
    final settingsIcon = $(Icons.settings);
    if (settingsIcon.exists) {
      // Navigate to settings
      await settingsIcon.tap();
      await $.pumpAndSettle();

      // Find and tap logout button
      final logoutButton = $(ListTile).containing('Logout');
      if (logoutButton.exists) {
        await logoutButton.tap();
        await $.pumpAndSettle();

        // Confirm logout if dialog appears
        final confirmButton = $(ElevatedButton).containing('Confirm');
        if (confirmButton.exists) {
          await confirmButton.tap();
        } else {
          final yesButton = $(ElevatedButton).containing('Yes');
          if (yesButton.exists) {
            await yesButton.tap();
          }
        }

        await $.pumpAndSettle();
      }
    }

    // Verify we're on the login screen
    await _waitForLoginScreen(timeout: effectiveTimeout);
  }

  /// Waits for the home screen to be displayed after authentication.
  ///
  /// The home screen typically contains the room list or main navigation.
  Future<void> waitForHomeScreen({Duration? timeout}) async {
    final effectiveTimeout = timeout ?? TestTimeouts.authTimeout;

    // Wait for common home screen elements
    // Look for bottom navigation or room list
    await $.pumpAndSettle(timeout: effectiveTimeout);

    // Check for room list screen indicators
    final roomListExists = $(Scaffold).exists;

    if (!roomListExists) {
      // If scaffold doesn't exist yet, wait longer
      await $.pump(const Duration(seconds: 2));
      await $.pumpAndSettle(timeout: effectiveTimeout);
    }
  }

  /// Waits for the login screen to be displayed.
  Future<void> _waitForLoginScreen({Duration? timeout}) async {
    final effectiveTimeout = timeout ?? TestTimeouts.authTimeout;

    await $.pumpAndSettle(timeout: effectiveTimeout);

    // Look for login button or sign in text
    final hasLoginIndicator =
        $(ElevatedButton).containing('Login').exists ||
        $(ElevatedButton).containing('Sign In').exists;

    if (!hasLoginIndicator) {
      await $.pump(const Duration(seconds: 1));
      await $.pumpAndSettle(timeout: effectiveTimeout);
    }
  }

  /// Checks if the user is currently logged in.
  ///
  /// Returns true if home screen elements are visible, false otherwise.
  Future<bool> isLoggedIn() async {
    await $.pumpAndSettle();

    // Check for elements that only appear when logged in
    // such as the main navigation or settings icon
    return $(BottomNavigationBar).exists || $(NavigationBar).exists;
  }

  /// Performs a quick login check and re-authenticates if necessary.
  ///
  /// Useful for tests that need to ensure authentication state at the start.
  Future<void> ensureLoggedIn(TestAccount account, {Duration? timeout}) async {
    final loggedIn = await isLoggedIn();
    if (!loggedIn) {
      await loginWithCredentials(account, timeout: timeout);
    }
  }
}

/// Extension on PatrolIntegrationTester to add auth convenience methods.
extension AuthPatrolExtensions on PatrolIntegrationTester {
  /// Creates an AuthHelper for this tester.
  AuthHelper get auth => AuthHelper(this);
}

/// Extension on PatrolFinder to add hint-based text field finding.
extension PatrolFinderTextFieldExtensions on PatrolFinder {
  /// Finds a TextField with the given hint text.
  PatrolFinder withHint(String hint) {
    return which<TextField>((widget) {
      final decoration = widget.decoration;
      return decoration?.hintText?.contains(hint) ?? false;
    });
  }
}
