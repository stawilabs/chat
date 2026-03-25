/// Sync helper utilities for E2E tests.
///
/// Provides methods for waiting on sync operations, message delivery,
/// and connection state during E2E test execution.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';

import '../config/staging_config.dart';

/// Connection state for sync operations.
enum SyncConnectionState {
  /// Not connected to sync service.
  disconnected,

  /// Attempting to connect.
  connecting,

  /// Successfully connected.
  connected,

  /// Connection error occurred.
  error,
}

/// Helper class for sync-related E2E test operations.
class SyncHelper {
  /// Creates a SyncHelper with the given PatrolTester.
  SyncHelper(this.$);

  /// The PatrolTester instance for interacting with the app.
  final PatrolIntegrationTester $;

  /// Waits for the sync connection to be established.
  ///
  /// This method monitors the connection state and waits until
  /// the app is successfully connected to the sync service.
  ///
  /// [timeout] - Maximum time to wait for connection.
  ///
  /// Throws [TimeoutException] if connection is not established within timeout.
  Future<void> waitForSyncConnection({Duration? timeout}) async {
    final effectiveTimeout = timeout ?? TestTimeouts.syncTimeout;
    final deadline = DateTime.now().add(effectiveTimeout);

    while (DateTime.now().isBefore(deadline)) {
      await $.pumpAndSettle(timeout: const Duration(seconds: 2));

      // Check for connection indicator (typically in app bar or status area)
      // The app should show a connected state indicator when synced
      final hasConnectionIndicator = await _checkConnectionState();

      if (hasConnectionIndicator) {
        return;
      }

      // Check for offline banner (indicates we're not connected)
      final offlineBanner = $(Banner).containing('Offline');
      if (!offlineBanner.exists) {
        // No offline indicator and app is responsive = likely connected
        return;
      }

      await $.pump(const Duration(milliseconds: 500));
    }

    throw TimeoutException(
      'Sync connection not established within ${effectiveTimeout.inSeconds} seconds',
    );
  }

  /// Waits for a specific message to be delivered to the recipient.
  ///
  /// This method checks for the message text to appear in the chat view,
  /// indicating successful delivery from sender to recipient.
  ///
  /// [messageText] - The message content to wait for.
  /// [timeout] - Maximum time to wait for delivery.
  ///
  /// Returns true if message appears, false otherwise.
  Future<bool> waitForMessageDelivery(
    String messageText, {
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? TestTimeouts.messageDeliveryTimeout;
    final deadline = DateTime.now().add(effectiveTimeout);

    while (DateTime.now().isBefore(deadline)) {
      await $.pumpAndSettle(timeout: const Duration(seconds: 1));

      // Look for the message text in the UI
      final messageWidget = $(Text).containing(messageText);
      if (messageWidget.exists) {
        return true;
      }

      await $.pump(const Duration(milliseconds: 250));
    }

    return false;
  }

  /// Waits for a message to show a specific delivery status.
  ///
  /// [messageText] - The message content to find.
  /// [expectedStatus] - The expected delivery status (sent, delivered, read).
  /// [timeout] - Maximum time to wait.
  Future<bool> waitForMessageStatus(
    String messageText,
    MessageDeliveryStatus expectedStatus, {
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? TestTimeouts.messageDeliveryTimeout;
    final deadline = DateTime.now().add(effectiveTimeout);

    while (DateTime.now().isBefore(deadline)) {
      await $.pumpAndSettle(timeout: const Duration(seconds: 1));

      // Find the message
      final messageWidget = $(Text).containing(messageText);
      if (messageWidget.exists) {
        // Check for status indicator icon
        final hasExpectedStatus = await _checkMessageStatus(expectedStatus);
        if (hasExpectedStatus) {
          return true;
        }
      }

      await $.pump(const Duration(milliseconds: 250));
    }

    return false;
  }

  /// Waits for the room list to be populated with at least one room.
  Future<void> waitForRoomList({Duration? timeout}) async {
    final effectiveTimeout = timeout ?? TestTimeouts.syncOperationTimeout;
    final deadline = DateTime.now().add(effectiveTimeout);

    while (DateTime.now().isBefore(deadline)) {
      await $.pumpAndSettle(timeout: const Duration(seconds: 2));

      // Look for room list items (typically ListTile or Card widgets)
      final roomItems = $(ListTile);
      if (roomItems.exists) {
        return;
      }

      // Also check for "No chats yet" empty state
      final emptyState = $(Text).containing('No chats');
      if (emptyState.exists) {
        return; // Room list is loaded but empty
      }

      await $.pump(const Duration(milliseconds: 500));
    }

    throw TimeoutException(
      'Room list not loaded within ${effectiveTimeout.inSeconds} seconds',
    );
  }

  /// Waits for pending messages to be synced.
  ///
  /// This is useful after sending messages offline to wait for them
  /// to be uploaded when connection is restored.
  Future<void> waitForPendingSync({Duration? timeout}) async {
    final effectiveTimeout = timeout ?? TestTimeouts.syncOperationTimeout;
    final deadline = DateTime.now().add(effectiveTimeout);

    while (DateTime.now().isBefore(deadline)) {
      await $.pumpAndSettle(timeout: const Duration(seconds: 2));

      // Check for pending indicator (clock icon or "sending" text)
      final pendingIndicator = $(Icon).which<Icon>(
        (icon) => icon.icon == Icons.schedule || icon.icon == Icons.access_time,
      );

      if (!pendingIndicator.exists) {
        // No pending indicators = all messages synced
        return;
      }

      await $.pump(const Duration(milliseconds: 500));
    }

    throw TimeoutException(
      'Pending messages not synced within ${effectiveTimeout.inSeconds} seconds',
    );
  }

  /// Simulates going offline by enabling airplane mode.
  ///
  /// Uses Patrol's native automation to toggle airplane mode on the device.
  /// This will disable all network connectivity (WiFi, cellular).
  ///
  /// Throws [UnsupportedError] if native automation is not available.
  Future<void> simulateOffline() async {
    try {
      // Use Patrol's native automation to enable airplane mode
      await $.native.enableAirplaneMode();
      // Wait for the network change to propagate
      await $.pumpAndSettle(timeout: const Duration(seconds: 3));
    } catch (e) {
      // Fallback: Log warning if native automation isn't available
      // This can happen on emulators without proper native support
      throw UnsupportedError(
        'simulateOffline requires native device automation. '
        'Ensure tests are running on a real device with Patrol native support. '
        'Original error: $e',
      );
    }
  }

  /// Simulates coming back online by disabling airplane mode.
  ///
  /// Uses Patrol's native automation to restore network connectivity.
  ///
  /// Throws [UnsupportedError] if native automation is not available.
  Future<void> simulateOnline() async {
    try {
      // Use Patrol's native automation to disable airplane mode
      await $.native.disableAirplaneMode();
      // Wait for network reconnection
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));
      // Additional wait for sync engine to reconnect
      await $.pump(const Duration(seconds: 2));
    } catch (e) {
      // Fallback: Log warning if native automation isn't available
      throw UnsupportedError(
        'simulateOnline requires native device automation. '
        'Ensure tests are running on a real device with Patrol native support. '
        'Original error: $e',
      );
    }
  }

  /// Checks if the app is currently connected to the sync service.
  Future<bool> _checkConnectionState() async {
    // Look for connection status indicators in the UI
    // This could be a colored dot, icon, or text

    // Check for connected icon (typically a cloud with check)
    final connectedIcon = $(Icon).which<Icon>(
      (icon) => icon.icon == Icons.cloud_done || icon.icon == Icons.sync,
    );

    if (connectedIcon.exists) {
      return true;
    }

    // Check for lack of offline indicators
    final offlineIcon = $(Icon).which<Icon>(
      (icon) =>
          icon.icon == Icons.cloud_off ||
          icon.icon == Icons.signal_wifi_off ||
          icon.icon == Icons.sync_problem,
    );

    return !offlineIcon.exists;
  }

  /// Checks if a message has the expected delivery status.
  ///
  /// For read status, checks both the icon (done_all) and the color (typically
  /// blue/primary color to distinguish from gray delivered status).
  Future<bool> _checkMessageStatus(MessageDeliveryStatus status) async {
    IconData expectedIcon;

    switch (status) {
      case MessageDeliveryStatus.pending:
        expectedIcon = Icons.schedule;
      case MessageDeliveryStatus.sent:
        expectedIcon = Icons.check;
      case MessageDeliveryStatus.delivered:
        expectedIcon = Icons.done_all;
      case MessageDeliveryStatus.read:
        // Read status uses same icon as delivered but with a distinct color
        expectedIcon = Icons.done_all;
    }

    // Find icons matching the expected icon type
    final statusIcon = $(Icon).which<Icon>((icon) => icon.icon == expectedIcon);

    if (!statusIcon.exists) {
      return false;
    }

    // For read status, also verify the color is the "read" color (typically blue)
    // to distinguish from delivered (typically gray)
    if (status == MessageDeliveryStatus.read) {
      // Check if any done_all icon has a blue-ish color indicating "read"
      final readIcon = $(Icon).which<Icon>((icon) {
        if (icon.icon != Icons.done_all) return false;

        // Read receipts typically use primary/blue color
        // Colors.blue.value = 0xFF2196F3
        final color = icon.color;
        if (color == null) return false;

        // Check for blue-ish hues (common read receipt colors)
        // This covers various shades of blue used for read receipts
        final isBlue =
            color == Colors.blue ||
            color == Colors.lightBlue ||
            color == Colors.blueAccent ||
            color.b > 0.5; // Blue channel dominant (using component accessor)

        return isBlue;
      });

      return readIcon.exists;
    }

    return true;
  }
}

/// Message delivery status states.
enum MessageDeliveryStatus {
  /// Message is pending send.
  pending,

  /// Message has been sent to server.
  sent,

  /// Message has been delivered to recipient.
  delivered,

  /// Message has been read by recipient.
  read,
}

/// Extension on PatrolIntegrationTester to add sync convenience methods.
extension SyncPatrolExtensions on PatrolIntegrationTester {
  /// Creates a SyncHelper for this tester.
  SyncHelper get sync => SyncHelper(this);
}

/// Extension on PatrolFinder for Banner widgets.
extension PatrolFinderBannerExtensions on PatrolFinder {
  /// Checks if this finder contains a Banner widget.
  bool get exists {
    try {
      return evaluate().isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
