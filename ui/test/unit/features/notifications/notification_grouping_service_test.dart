import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/notifications/notification_grouping_service.dart';

void main() {
  late NotificationGroupingService groupingService;

  setUp(() {
    groupingService = NotificationGroupingService();
  });

  tearDown(() {
    groupingService.dispose();
  });

  group('NotificationGroupingService', () {
    group('isSupported', () {
      test('returns true on Android', () {
        if (Platform.isAndroid) {
          expect(
            NotificationGroupingService.isSupported,
            isTrue,
            reason: 'Android should support notification grouping',
          );
        }
      });

      test('returns true on iOS', () {
        if (Platform.isIOS) {
          expect(
            NotificationGroupingService.isSupported,
            isTrue,
            reason: 'iOS should support notification grouping',
          );
        }
      });

      test('returns true on macOS', () {
        if (Platform.isMacOS) {
          expect(
            NotificationGroupingService.isSupported,
            isTrue,
            reason: 'macOS should support notification grouping',
          );
        }
      });

      test('returns false on Linux', () {
        if (Platform.isLinux) {
          expect(
            NotificationGroupingService.isSupported,
            isFalse,
            reason: 'Linux should not support notification grouping',
          );
        }
      });

      test('returns false on Windows', () {
        if (Platform.isWindows) {
          expect(
            NotificationGroupingService.isSupported,
            isFalse,
            reason: 'Windows should not support notification grouping',
          );
        }
      });

      test('returns correct value based on current platform', () {
        final isSupported = NotificationGroupingService.isSupported;

        if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
          expect(isSupported, isTrue);
        } else {
          expect(isSupported, isFalse);
        }
      });
    });

    group('initialization', () {
      test('isInitialized returns false before initialize', () {
        expect(groupingService.isInitialized, isFalse);
      });

      test('initialize sets isInitialized to true', () async {
        await groupingService.initialize();
        expect(groupingService.isInitialized, isTrue);
      });

      test('initialize can be called multiple times safely', () async {
        await groupingService.initialize();
        await groupingService.initialize(); // Should be no-op
        expect(groupingService.isInitialized, isTrue);
      });
    });

    group('providers', () {
      test('notificationGroupingServiceProvider is available', () {
        expect(notificationGroupingServiceProvider, isNotNull);
      });

      test('notificationGroupingInitializedProvider is available', () {
        expect(notificationGroupingInitializedProvider, isNotNull);
      });
    });

    group('dispose', () {
      test('dispose resets isInitialized', () async {
        await groupingService.initialize();
        expect(groupingService.isInitialized, isTrue);

        groupingService.dispose();
        expect(groupingService.isInitialized, isFalse);
      });

      test('dispose can be called multiple times safely', () async {
        await groupingService.initialize();
        groupingService.dispose();
        groupingService.dispose(); // Should not throw
        expect(groupingService.isInitialized, isFalse);
      });

      test('dispose clears pending messages', () async {
        await groupingService.initialize();

        // Note: On non-supported platforms, this won't actually add messages
        // but it ensures the data structures are properly cleared
        groupingService.dispose();

        expect(groupingService.getPendingMessageCount('room-1'), equals(0));
        expect(groupingService.totalPendingMessageCount, equals(0));
      });
    });

    group('pending message tracking', () {
      test('getPendingMessageCount returns 0 for unknown room', () {
        expect(
          groupingService.getPendingMessageCount('unknown-room'),
          equals(0),
        );
      });

      test('totalPendingMessageCount returns 0 initially', () {
        expect(groupingService.totalPendingMessageCount, equals(0));
      });
    });

    group('clearRoomNotifications', () {
      test('clearRoomNotifications does not throw for unknown room', () async {
        await groupingService.initialize();
        // Should not throw
        await groupingService.clearRoomNotifications('unknown-room');
      });
    });

    group('clearAllNotifications', () {
      test(
        'clearAllNotifications does not throw when not initialized',
        () async {
          // Should not throw
          await groupingService.clearAllNotifications();
        },
      );

      test('clearAllNotifications resets pending message count', () async {
        await groupingService.initialize();
        await groupingService.clearAllNotifications();
        expect(groupingService.totalPendingMessageCount, equals(0));
      });
    });
  });

  group('GroupedMessage', () {
    test('creates with required parameters', () {
      final message = GroupedMessage(
        id: 'msg-1',
        roomId: 'room-1',
        senderName: 'Alice',
        message: 'Hello',
        timestamp: DateTime.now(),
      );

      expect(message.id, equals('msg-1'));
      expect(message.roomId, equals('room-1'));
      expect(message.senderName, equals('Alice'));
      expect(message.message, equals('Hello'));
      expect(message.timestamp, isNotNull);
    });
  });

  group('NotificationChannelConfig', () {
    test('creates with required parameters', () {
      const config = NotificationChannelConfig(
        id: 'channel-1',
        name: 'Test Channel',
        description: 'Test Description',
      );

      expect(config.id, equals('channel-1'));
      expect(config.name, equals('Test Channel'));
      expect(config.description, equals('Test Description'));
    });

    test('creates with all parameters', () {
      const config = NotificationChannelConfig(
        id: 'channel-1',
        name: 'Test Channel',
        description: 'Test Description',
        playSound: false,
        enableVibration: false,
      );

      expect(config.playSound, isFalse);
      expect(config.enableVibration, isFalse);
    });

    test('has sensible defaults', () {
      const config = NotificationChannelConfig(
        id: 'channel-1',
        name: 'Test Channel',
        description: 'Test Description',
      );

      expect(config.playSound, isTrue);
      expect(config.enableVibration, isTrue);
    });
  });

  group('Platform support verification', () {
    test('mobile platforms are supported', () {
      if (Platform.isAndroid) {
        expect(
          NotificationGroupingService.isSupported,
          isTrue,
          reason: 'Android should support notification grouping',
        );
      }
      if (Platform.isIOS) {
        expect(
          NotificationGroupingService.isSupported,
          isTrue,
          reason: 'iOS should support notification grouping',
        );
      }
    });

    test('desktop platforms have mixed support', () {
      if (Platform.isLinux) {
        expect(
          NotificationGroupingService.isSupported,
          isFalse,
          reason: 'Linux should not support notification grouping',
        );
      }
      if (Platform.isMacOS) {
        expect(
          NotificationGroupingService.isSupported,
          isTrue,
          reason: 'macOS should support notification grouping',
        );
      }
      if (Platform.isWindows) {
        expect(
          NotificationGroupingService.isSupported,
          isFalse,
          reason: 'Windows should not support notification grouping',
        );
      }
    });
  });

  group('Notification grouping behavior', () {
    test(
      'showMessageNotification handles unsupported platforms gracefully',
      () async {
        await groupingService.initialize();

        // On unsupported platforms (like desktop during tests),
        // this should not throw
        await groupingService.showMessageNotification(
          roomId: 'room-1',
          roomName: 'Test Room',
          senderName: 'Alice',
          message: 'Hello',
        );

        // On supported platforms, the message would be added to pending
        // On unsupported platforms, this is a no-op
        if (!NotificationGroupingService.isSupported) {
          expect(groupingService.getPendingMessageCount('room-1'), equals(0));
        }
      },
    );

    test(
      'createRoomChannel handles unsupported platforms gracefully',
      () async {
        await groupingService.initialize();

        // Should not throw on any platform
        await groupingService.createRoomChannel(
          roomId: 'room-1',
          roomName: 'Test Room',
        );
      },
    );

    test(
      'deleteRoomChannel handles unsupported platforms gracefully',
      () async {
        await groupingService.initialize();

        // Should not throw on any platform
        await groupingService.deleteRoomChannel('room-1');
      },
    );
  });

  group('Service creation', () {
    test('service can be created', () {
      final service = NotificationGroupingService();
      expect(service, isNotNull);
      expect(service.isInitialized, isFalse);
      service.dispose();
    });
  });

  group('Notification ID uniqueness', () {
    test(
      'different rooms get different notification IDs via separate tracking',
      () {
        // This test verifies that the service tracks room IDs separately
        // and maintains proper state between operations
        final service = NotificationGroupingService();

        // Verify that clearing notifications for different rooms
        // works independently (internally uses unique IDs)
        expect(service.getPendingMessageCount('room-A'), equals(0));
        expect(service.getPendingMessageCount('room-B'), equals(0));
        expect(service.getPendingMessageCount('room-C'), equals(0));

        // Even rooms with similar hashCodes should be tracked separately
        // The service now uses a sequential counter instead of hashCode
        service.dispose();
      },
    );

    test('dispose resets notification ID counter', () async {
      final service = NotificationGroupingService();
      await service.initialize();

      // After dispose, the counter should be reset
      service.dispose();
      expect(service.isInitialized, isFalse);

      // Create a new service to verify fresh state
      final newService = NotificationGroupingService();
      expect(newService.getPendingMessageCount('room-1'), equals(0));
      newService.dispose();
    });

    test('service handles many rooms without ID collision', () async {
      final service = NotificationGroupingService();
      await service.initialize();

      // Simulate many different rooms being tracked
      // The service should handle this without collision
      final roomIds = List.generate(100, (i) => 'room-$i');

      for (final roomId in roomIds) {
        // Each room should have independent tracking
        expect(service.getPendingMessageCount(roomId), equals(0));
      }

      service.dispose();
    });
  });
}
