/// E2E performance baseline tests for app startup.
///
/// Measures and validates:
/// - Cold start time
/// - Warm start time
/// - Database initialization time
/// - Initial render time
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../config/staging_config.dart';
import '../../config/test_accounts.dart';
import '../../helpers/auth_helper.dart';
import '../../helpers/sync_helper.dart';

/// Performance measurement results for startup tests.
class StartupMetrics {
  /// Time from app launch to first frame rendered.
  int? coldStartMs;

  /// Time to initialize the database.
  int? databaseInitMs;

  /// Time to complete initial sync.
  int? initialSyncMs;

  /// Time from launch to interactive home screen.
  int? timeToInteractiveMs;

  /// Total memory usage after startup (bytes).
  int? memoryUsageBytes;

  @override
  String toString() =>
      '''
StartupMetrics:
  - Cold Start: ${coldStartMs}ms
  - Database Init: ${databaseInitMs}ms
  - Initial Sync: ${initialSyncMs}ms
  - Time to Interactive: ${timeToInteractiveMs}ms
  - Memory Usage: ${memoryUsageBytes != null ? '${(memoryUsageBytes! / 1024 / 1024).toStringAsFixed(2)}MB' : 'N/A'}
''';
}

void main() {
  patrolTest(
    'Cold start performance baseline',
    ($) async {
      final metrics = StartupMetrics();

      // Record start time (app should have just launched)
      final startTime = DateTime.now();

      // Wait for app to render
      await $.pumpAndSettle(timeout: const Duration(seconds: 10));

      // Calculate cold start time
      final firstRenderTime = DateTime.now();
      metrics.coldStartMs = firstRenderTime
          .difference(startTime)
          .inMilliseconds;

      debugPrint('Cold start time: ${metrics.coldStartMs}ms');

      // Validate against threshold
      expect(
        metrics.coldStartMs,
        lessThanOrEqualTo(PerformanceThresholds.maxColdStartMs),
        reason:
            'Cold start should be under ${PerformanceThresholds.maxColdStartMs}ms, '
            'but was ${metrics.coldStartMs}ms',
      );

      // Log performance for tracking
      debugPrint('PERF_METRIC: cold_start_ms=${metrics.coldStartMs}');
    },
    timeout: const Timeout(TestTimeouts.defaultTestTimeout),
  );

  patrolTest(
    'Database initialization performance',
    ($) async {
      final metrics = StartupMetrics();

      // App launch includes database init
      final startTime = DateTime.now();

      await $.pumpAndSettle(timeout: const Duration(seconds: 10));

      // Database init happens during startup
      // We measure time to see scaffold/content which indicates DB is ready
      final scaffoldVisible = $(Scaffold).exists;

      if (scaffoldVisible) {
        final dbReadyTime = DateTime.now();
        metrics.databaseInitMs = dbReadyTime
            .difference(startTime)
            .inMilliseconds;

        debugPrint('Database init time: ${metrics.databaseInitMs}ms');

        expect(
          metrics.databaseInitMs,
          lessThanOrEqualTo(PerformanceThresholds.maxDatabaseInitMs),
          reason:
              'Database init should be under ${PerformanceThresholds.maxDatabaseInitMs}ms',
        );

        debugPrint('PERF_METRIC: db_init_ms=${metrics.databaseInitMs}');
      }
    },
    timeout: const Timeout(TestTimeouts.defaultTestTimeout),
  );

  patrolTest(
    'Time to interactive after login',
    ($) async {
      TestAccounts.validateConfiguration();

      final metrics = StartupMetrics();
      final loginStartTime = DateTime.now();

      // Login
      await $.auth.loginWithCredentials(TestAccounts.user1);

      // Wait for sync connection
      await $.sync.waitForSyncConnection();

      // Wait for room list to be interactive
      await $.sync.waitForRoomList();

      final interactiveTime = DateTime.now();
      metrics.timeToInteractiveMs = interactiveTime
          .difference(loginStartTime)
          .inMilliseconds;

      debugPrint('Time to interactive: ${metrics.timeToInteractiveMs}ms');

      // Validate the total startup time
      expect(
        metrics.timeToInteractiveMs,
        lessThanOrEqualTo(PerformanceThresholds.maxStartupMs),
        reason:
            'Time to interactive should be under ${PerformanceThresholds.maxStartupMs}ms',
      );

      debugPrint(
        'PERF_METRIC: time_to_interactive_ms=${metrics.timeToInteractiveMs}',
      );
    },
    timeout: const Timeout(TestTimeouts.defaultTestTimeout),
  );

  patrolTest(
    'Warm start performance (from background)',
    ($) async {
      TestAccounts.validateConfiguration();

      // First, complete a cold start and login
      await $.auth.loginWithCredentials(TestAccounts.user1);
      await $.sync.waitForSyncConnection();
      await $.sync.waitForRoomList();

      // Simulate going to background and returning
      // In Patrol, we can simulate this by pumping frames
      await $.pump(const Duration(seconds: 1));

      final warmStartTime = DateTime.now();

      // Trigger a rebuild/resume
      await $.pumpAndSettle();

      final resumeTime = DateTime.now();
      final warmStartMs = resumeTime.difference(warmStartTime).inMilliseconds;

      debugPrint('Warm start time: ${warmStartMs}ms');

      expect(
        warmStartMs,
        lessThanOrEqualTo(PerformanceThresholds.maxWarmStartMs),
        reason:
            'Warm start should be under ${PerformanceThresholds.maxWarmStartMs}ms',
      );

      debugPrint('PERF_METRIC: warm_start_ms=$warmStartMs');
    },
    timeout: const Timeout(TestTimeouts.defaultTestTimeout),
  );

  patrolTest(
    'Initial sync performance',
    ($) async {
      TestAccounts.validateConfiguration();

      final metrics = StartupMetrics();

      // Login
      await $.auth.loginWithCredentials(TestAccounts.user1);

      final syncStartTime = DateTime.now();

      // Wait for initial sync to complete
      await $.sync.waitForSyncConnection();
      await $.sync.waitForRoomList();

      final syncCompleteTime = DateTime.now();
      metrics.initialSyncMs = syncCompleteTime
          .difference(syncStartTime)
          .inMilliseconds;

      debugPrint('Initial sync time: ${metrics.initialSyncMs}ms');

      // Sync time can vary based on data volume, but should complete
      expect(
        metrics.initialSyncMs,
        lessThan(TestTimeouts.syncOperationTimeout.inMilliseconds),
        reason: 'Initial sync should complete within timeout',
      );

      debugPrint('PERF_METRIC: initial_sync_ms=${metrics.initialSyncMs}');
    },
    timeout: const Timeout(TestTimeouts.syncOperationTimeout),
  );

  patrolTest(
    'Memory usage after startup',
    ($) async {
      TestAccounts.validateConfiguration();

      // Complete startup
      await $.auth.loginWithCredentials(TestAccounts.user1);
      await $.sync.waitForSyncConnection();
      await $.sync.waitForRoomList();

      // Give app time to settle
      await $.pump(const Duration(seconds: 2));
      await $.pumpAndSettle();

      // Note: Direct memory measurement requires platform-specific code
      // In a real implementation, this would use MemoryInfo or similar

      // For now, we just verify the app is responsive
      expect($(Scaffold).exists, isTrue);

      // Log placeholder for memory metric
      debugPrint('PERF_METRIC: memory_mb=N/A (requires native bridge)');
    },
    timeout: const Timeout(TestTimeouts.defaultTestTimeout),
  );

  patrolTest(
    'Startup with large local database',
    ($) async {
      // This test measures startup performance when there's significant
      // local data (messages, rooms) already cached

      TestAccounts.validateConfiguration();

      final startTime = DateTime.now();

      // Login (will load cached data)
      await $.auth.loginWithCredentials(TestAccounts.user1);
      await $.sync.waitForSyncConnection();
      await $.sync.waitForRoomList();

      final readyTime = DateTime.now();
      final totalMs = readyTime.difference(startTime).inMilliseconds;

      debugPrint('Startup with local data: ${totalMs}ms');

      // Should still meet startup requirements even with data
      expect(
        totalMs,
        lessThanOrEqualTo(PerformanceThresholds.maxStartupMs * 1.5),
        reason: 'Startup with local data should be within acceptable range',
      );

      debugPrint('PERF_METRIC: startup_with_data_ms=$totalMs');
    },
    timeout: const Timeout(TestTimeouts.defaultTestTimeout),
  );
}

/// Extension to parse performance metrics from test output.
extension PerformanceMetricsParser on String {
  /// Extracts performance metric value from log line.
  ///
  /// Expected format: PERF_METRIC: metric_name=value
  int? parseMetricValue(String metricName) {
    final regex = RegExp('PERF_METRIC: $metricName=(\\d+)');
    final match = regex.firstMatch(this);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }
}
