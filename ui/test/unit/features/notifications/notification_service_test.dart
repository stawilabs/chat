import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/notifications/notification_service.dart';

void main() {
  group('NotificationService', () {
    group('isSupported', () {
      test('returns true on Android', () {
        // On Android, isSupported should return true
        // Note: This test will pass/fail based on the actual platform
        // In a real CI environment, we'd need platform-specific test runs
        final isAndroid = Platform.isAndroid;
        final isIOS = Platform.isIOS;

        final expected = isAndroid || isIOS;
        expect(NotificationService.isSupported, equals(expected));
      });

      test('returns correct value based on platform', () {
        // NotificationService.isSupported should be:
        // - true on Android
        // - true on iOS
        // - false on Linux, macOS, Windows, Web
        final isSupported = NotificationService.isSupported;

        if (Platform.isAndroid || Platform.isIOS) {
          expect(isSupported, isTrue);
        } else {
          expect(isSupported, isFalse);
        }
      });
    });

    group('notificationServiceProvider', () {
      test('provider is available', () {
        // The provider should be available for import
        expect(notificationServiceProvider, isNotNull);
      });
    });

    group('firebaseMessagingBackgroundHandler', () {
      test('function is available', () {
        // The background handler should be available as a top-level function
        // This is required for Firebase Messaging background handling
        expect(firebaseMessagingBackgroundHandler, isA<Function>());
      });
    });
  });

  group('Platform support verification', () {
    test('mobile platforms are supported', () {
      // This documents the expected behavior
      // On actual mobile devices, notifications should be supported
      if (Platform.isAndroid) {
        expect(
          NotificationService.isSupported,
          isTrue,
          reason: 'Android should support notifications',
        );
      }
      if (Platform.isIOS) {
        expect(
          NotificationService.isSupported,
          isTrue,
          reason: 'iOS should support notifications',
        );
      }
    });

    test('desktop platforms are not supported', () {
      // This documents the expected behavior
      // On desktop platforms, Firebase Messaging is not available
      if (Platform.isLinux) {
        expect(
          NotificationService.isSupported,
          isFalse,
          reason: 'Linux should not support FCM notifications',
        );
      }
      if (Platform.isMacOS) {
        expect(
          NotificationService.isSupported,
          isFalse,
          reason: 'macOS should not support FCM notifications',
        );
      }
      if (Platform.isWindows) {
        expect(
          NotificationService.isSupported,
          isFalse,
          reason: 'Windows should not support FCM notifications',
        );
      }
    });
  });
}
