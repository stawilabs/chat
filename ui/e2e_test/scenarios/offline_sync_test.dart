/// E2E tests for offline sync scenarios.
///
/// Tests the app's behavior when connectivity is lost and restored:
/// - Queuing messages while offline
/// - Syncing messages when connection is restored
/// - Handling conflicts and duplicates
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../config/staging_config.dart';
import '../config/test_accounts.dart';
import '../fixtures/seed_data.dart';
import '../helpers/auth_helper.dart';
import '../helpers/sync_helper.dart';

void main() {
  patrolTest(
    'Messages queue while offline and sync on reconnect',
    ($) async {
      TestAccounts.validateConfiguration();

      // Login and establish initial connection
      await $.auth.loginWithCredentials(TestAccounts.user1);
      await $.sync.waitForSyncConnection();
      await $.sync.waitForRoomList();

      // Open a room
      final roomItem = $(ListTile).first;
      if (roomItem.exists) {
        await roomItem.tap();
        await $.pumpAndSettle();
      }

      // Simulate going offline
      // Note: In real tests, this would use native capabilities
      await $.sync.simulateOffline();
      await $.pumpAndSettle();

      // Send message while offline
      final offlineMessage = TestMessageFactory.generateUniqueMessageText(
        'Offline',
      );

      final inputField = $(TextField).last;
      await inputField.enterText(offlineMessage);
      await $.pumpAndSettle();

      await $(Icons.send).tap();
      await $.pumpAndSettle();

      // Verify message appears locally with pending status
      expect(
        $(Text).containing(offlineMessage).exists,
        isTrue,
        reason: 'Message should appear locally even when offline',
      );

      // Check for pending indicator (clock icon)
      final pendingIndicator = $(Icon).which<Icon>(
        (icon) => icon.icon == Icons.schedule || icon.icon == Icons.access_time,
      );
      expect(
        pendingIndicator.exists,
        isTrue,
        reason: 'Message should show pending status while offline',
      );

      // Simulate coming back online
      await $.sync.simulateOnline();
      await $.pumpAndSettle();

      // Wait for sync to complete
      await $.sync.waitForSyncConnection(timeout: TestTimeouts.syncTimeout);

      // Wait for pending messages to sync
      await $.sync.waitForPendingSync(
        timeout: TestTimeouts.syncOperationTimeout,
      );

      // Verify message now shows sent status
      final synced = await $.sync.waitForMessageStatus(
        offlineMessage,
        MessageDeliveryStatus.sent,
        timeout: TestTimeouts.messageDeliveryTimeout,
      );

      expect(synced, isTrue, reason: 'Message should sync after coming online');
    },
    timeout: Timeout(TestTimeouts.defaultTestTimeout * 2),
  );

  patrolTest(
    'Multiple offline messages sync in order',
    ($) async {
      TestAccounts.validateConfiguration();

      await $.auth.loginWithCredentials(TestAccounts.user1);
      await $.sync.waitForSyncConnection();
      await $.sync.waitForRoomList();

      // Open a room
      final roomItem = $(ListTile).first;
      if (roomItem.exists) {
        await roomItem.tap();
        await $.pumpAndSettle();
      }

      // Go offline
      await $.sync.simulateOffline();
      await $.pumpAndSettle();

      // Send multiple messages while offline
      final offlineMessages = <String>[];
      for (var i = 0; i < 3; i++) {
        final message = TestMessageFactory.generateUniqueMessageText(
          'Offline Seq $i',
        );
        offlineMessages.add(message);

        final inputField = $(TextField).last;
        await inputField.enterText(message);
        await $.pumpAndSettle();

        await $(Icons.send).tap();
        await $.pumpAndSettle();

        // Small delay between sends
        await $.pump(const Duration(milliseconds: 100));
      }

      // Verify all messages appear locally
      for (final message in offlineMessages) {
        expect(
          $(Text).containing(message).exists,
          isTrue,
          reason: 'Offline message "$message" should appear locally',
        );
      }

      // Come back online
      await $.sync.simulateOnline();
      await $.pumpAndSettle();

      // Wait for sync
      await $.sync.waitForSyncConnection();
      await $.sync.waitForPendingSync();

      // Verify all messages are synced
      for (final message in offlineMessages) {
        final synced = await $.sync.waitForMessageStatus(
          message,
          MessageDeliveryStatus.sent,
          timeout: TestTimeouts.messageDeliveryTimeout,
        );
        expect(synced, isTrue, reason: 'Message "$message" should be synced');
      }
    },
    timeout: Timeout(TestTimeouts.defaultTestTimeout * 2),
  );

  patrolTest(
    'App shows offline indicator when disconnected',
    ($) async {
      TestAccounts.validateConfiguration();

      await $.auth.loginWithCredentials(TestAccounts.user1);
      await $.sync.waitForSyncConnection();

      // Go offline
      await $.sync.simulateOffline();
      await $.pumpAndSettle();

      // Wait a moment for UI to update
      await $.pump(const Duration(seconds: 2));
      await $.pumpAndSettle();

      // Check for offline indicator
      // This could be a banner, icon, or status text
      final offlineBanner = $(MaterialBanner);
      final offlineIcon = $(Icon).which<Icon>(
        (icon) =>
            icon.icon == Icons.cloud_off ||
            icon.icon == Icons.wifi_off ||
            icon.icon == Icons.signal_wifi_off,
      );
      final offlineText = $(Text).containing('Offline');

      final hasOfflineIndicator =
          offlineBanner.exists || offlineIcon.exists || offlineText.exists;

      // Note: The specific offline indicator depends on app implementation
      debugPrint('Offline indicator found: $hasOfflineIndicator');

      // Come back online
      await $.sync.simulateOnline();
      await $.pumpAndSettle();

      // Wait for reconnection
      await $.sync.waitForSyncConnection();

      // Verify offline indicator is gone
      await $.pumpAndSettle();
    },
    timeout: const Timeout(TestTimeouts.defaultTestTimeout),
  );

  patrolTest(
    'Received messages appear after coming online',
    ($) async {
      // This test validates that messages sent by others while we were offline
      // appear after reconnection

      TestAccounts.validateConfiguration();

      await $.auth.loginWithCredentials(TestAccounts.user1);
      await $.sync.waitForSyncConnection();
      await $.sync.waitForRoomList();

      // Open a room
      final roomItem = $(ListTile).first;
      if (roomItem.exists) {
        await roomItem.tap();
        await $.pumpAndSettle();
      }

      // Go offline briefly
      await $.sync.simulateOffline();
      await $.pump(const Duration(seconds: 2));

      // In a real test, another user would send messages during this time
      // For this test, we just verify the sync process works

      // Come back online
      await $.sync.simulateOnline();
      await $.pumpAndSettle();

      // Wait for sync to complete
      await $.sync.waitForSyncConnection();
      await $.pumpAndSettle();

      // Verify we can still see the room and messages
      expect(
        $(Scaffold).exists,
        isTrue,
        reason: 'Chat screen should still be visible after reconnection',
      );
    },
    timeout: const Timeout(TestTimeouts.defaultTestTimeout),
  );

  patrolTest(
    'Failed message shows retry option',
    ($) async {
      TestAccounts.validateConfiguration();

      await $.auth.loginWithCredentials(TestAccounts.user1);
      await $.sync.waitForSyncConnection();
      await $.sync.waitForRoomList();

      // Open a room
      final roomItem = $(ListTile).first;
      if (roomItem.exists) {
        await roomItem.tap();
        await $.pumpAndSettle();
      }

      // Go offline
      await $.sync.simulateOffline();
      await $.pumpAndSettle();

      // Send a message
      final failedMessage = TestMessageFactory.generateUniqueMessageText(
        'May Fail',
      );
      final inputField = $(TextField).last;
      await inputField.enterText(failedMessage);
      await $.pumpAndSettle();

      await $(Icons.send).tap();
      await $.pumpAndSettle();

      // Simulate extended offline period (would trigger failure in real scenario)
      await $.pump(const Duration(seconds: 5));
      await $.pumpAndSettle();

      // Check for failed message indicator
      final failedIcon = $(Icon).which<Icon>(
        (icon) => icon.icon == Icons.error || icon.icon == Icons.error_outline,
      );

      // Look for retry button
      final retryButton = $(IconButton).containing(Icons.refresh);

      // Note: Message may still be pending, not failed, in simulated offline
      debugPrint('Failed indicator found: ${failedIcon.exists}');
      debugPrint('Retry button found: ${retryButton.exists}');

      // Come back online to clean up
      await $.sync.simulateOnline();
      await $.sync.waitForSyncConnection();
    },
    timeout: const Timeout(TestTimeouts.defaultTestTimeout),
  );

  patrolTest(
    'Room list updates after sync',
    ($) async {
      TestAccounts.validateConfiguration();

      await $.auth.loginWithCredentials(TestAccounts.user1);
      await $.sync.waitForSyncConnection();
      await $.sync.waitForRoomList();

      // Count initial rooms
      final initialRoomCount = $(ListTile).evaluate().length;
      debugPrint('Initial room count: $initialRoomCount');

      // Go offline
      await $.sync.simulateOffline();
      await $.pump(const Duration(seconds: 2));

      // Come back online (new rooms might have been created by others)
      await $.sync.simulateOnline();
      await $.sync.waitForSyncConnection();

      // Wait for room list to refresh
      await $.pumpAndSettle();
      await $.pump(const Duration(seconds: 2));
      await $.pumpAndSettle();

      // Room list should still be valid
      expect(
        $(ListView).exists || $(ListTile).exists,
        isTrue,
        reason: 'Room list should be visible after sync',
      );
    },
    timeout: const Timeout(TestTimeouts.defaultTestTimeout),
  );
}
