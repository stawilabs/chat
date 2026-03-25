import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/error/error_tracking_service.dart';

void main() {
  group('ErrorTrackingService', () {
    test('isInitialized returns false before initialization', () {
      // Before any initialization, should be false
      // Note: In a real test, we'd mock Sentry, but for unit tests
      // we just verify the service's internal state tracking
      expect(ErrorTrackingService.isInitialized, isFalse);
    });

    test('enableDebugSend can be called without error', () {
      // Should not throw
      expect(ErrorTrackingService.enableDebugSend, returnsNormally);
    });

    group('without Sentry initialized', () {
      // These tests verify the service handles calls gracefully
      // when Sentry is not configured (empty DSN scenario)

      test('setUser can be called without initialization', () async {
        // Should not throw even without initialization
        // Sentry handles this gracefully internally
        await expectLater(
          ErrorTrackingService.setUser(
            id: 'test-user',
            email: 'test@example.com',
            username: 'testuser',
          ),
          completes,
        );
      });

      test('clearUser can be called without initialization', () async {
        await expectLater(ErrorTrackingService.clearUser(), completes);
      });

      test('addBreadcrumb can be called without initialization', () async {
        await expectLater(
          ErrorTrackingService.addBreadcrumb(
            message: 'Test breadcrumb',
            category: 'test',
            data: {'key': 'value'},
          ),
          completes,
        );
      });

      test('captureException can be called without initialization', () async {
        await expectLater(
          ErrorTrackingService.captureException(
            Exception('Test exception'),
            stackTrace: StackTrace.current,
            extra: {'context': 'test'},
          ),
          completes,
        );
      });

      test('captureMessage can be called without initialization', () async {
        await expectLater(
          ErrorTrackingService.captureMessage(
            'Test message',
            extra: {'key': 'value'},
          ),
          completes,
        );
      });

      test('setTag can be called without initialization', () async {
        await expectLater(
          ErrorTrackingService.setTag('test-key', 'test-value'),
          completes,
        );
      });

      test('setExtra can be called without initialization', () async {
        await expectLater(
          ErrorTrackingService.setExtra('test-key', {'nested': 'value'}),
          completes,
        );
      });
    });
  });
}
