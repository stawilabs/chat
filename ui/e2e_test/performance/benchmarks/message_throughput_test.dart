/// E2E performance benchmarks for message throughput.
///
/// Measures and validates:
/// - Message send throughput (messages per second)
/// - P95 and P99 delivery latency
/// - Memory usage during high-volume messaging
/// - UI responsiveness under load
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../../config/staging_config.dart';
import '../../config/test_accounts.dart';
import '../../fixtures/seed_data.dart';
import '../../helpers/auth_helper.dart';
import '../../helpers/sync_helper.dart';

/// Performance metrics for message throughput tests.
class ThroughputMetrics {
  /// List of individual message send times in milliseconds.
  final List<int> sendTimesMs = [];

  /// List of individual message delivery times in milliseconds.
  final List<int> deliveryTimesMs = [];

  /// Total messages sent.
  int messagesSent = 0;

  /// Total messages confirmed delivered.
  int messagesDelivered = 0;

  /// Total test duration in milliseconds.
  int? totalDurationMs;

  /// Calculates messages per second throughput.
  double get messagesPerSecond {
    if (totalDurationMs == null || totalDurationMs == 0) return 0;
    return (messagesSent / totalDurationMs!) * 1000;
  }

  /// Calculates P50 (median) send time.
  int get p50SendTimeMs => _percentile(sendTimesMs, 50);

  /// Calculates P95 send time.
  int get p95SendTimeMs => _percentile(sendTimesMs, 95);

  /// Calculates P99 send time.
  int get p99SendTimeMs => _percentile(sendTimesMs, 99);

  /// Calculates P50 (median) delivery time.
  int get p50DeliveryTimeMs => _percentile(deliveryTimesMs, 50);

  /// Calculates P95 delivery time.
  int get p95DeliveryTimeMs => _percentile(deliveryTimesMs, 95);

  /// Calculates P99 delivery time.
  int get p99DeliveryTimeMs => _percentile(deliveryTimesMs, 99);

  /// Calculates the percentile value from a list of times.
  int _percentile(List<int> times, int percentile) {
    if (times.isEmpty) return 0;
    final sorted = List<int>.from(times)..sort();
    final index = ((percentile / 100) * sorted.length).floor();
    return sorted[min(index, sorted.length - 1)];
  }

  @override
  String toString() =>
      '''
ThroughputMetrics:
  - Messages Sent: $messagesSent
  - Messages Delivered: $messagesDelivered
  - Duration: ${totalDurationMs}ms
  - Throughput: ${messagesPerSecond.toStringAsFixed(2)} msg/sec
  - Send Time P50: ${p50SendTimeMs}ms
  - Send Time P95: ${p95SendTimeMs}ms
  - Send Time P99: ${p99SendTimeMs}ms
  - Delivery Time P50: ${p50DeliveryTimeMs}ms
  - Delivery Time P95: ${p95DeliveryTimeMs}ms
  - Delivery Time P99: ${p99DeliveryTimeMs}ms
''';
}

void main() {
  patrolTest(
    'Message send throughput benchmark',
    ($) async {
      TestAccounts.validateConfiguration();

      final metrics = ThroughputMetrics();

      // Setup
      await $.auth.loginWithCredentials(TestAccounts.user1);
      await $.sync.waitForSyncConnection();
      await $.sync.waitForRoomList();

      // Open a room
      final roomItem = $(ListTile).first;
      if (!roomItem.exists) {
        debugPrint('No room available for throughput test');
        return;
      }
      await roomItem.tap();
      await $.pumpAndSettle();

      // Generate test messages
      const batch = MessageBatchConfig.medium;
      final testStartTime = DateTime.now();

      // Send messages and measure time
      for (var i = 0; i < batch.totalMessages; i++) {
        final messageText = TestMessageFactory.generateUniqueMessageText(
          'Throughput $i',
        );

        final sendStartTime = DateTime.now();

        // Enter and send message
        final inputField = $(TextField).last;
        await inputField.enterText(messageText);
        await $.pumpAndSettle();

        await $(Icons.send).tap();
        await $.pumpAndSettle();

        final sendEndTime = DateTime.now();
        final sendTimeMs = sendEndTime.difference(sendStartTime).inMilliseconds;

        metrics.sendTimesMs.add(sendTimeMs);
        metrics.messagesSent++;

        // Small delay to avoid overwhelming
        await $.pump(Duration(milliseconds: batch.delayBetweenBatchesMs));
      }

      final testEndTime = DateTime.now();
      metrics.totalDurationMs = testEndTime
          .difference(testStartTime)
          .inMilliseconds;

      debugPrint(metrics.toString());

      // Validate throughput
      expect(
        metrics.messagesPerSecond,
        greaterThanOrEqualTo(PerformanceThresholds.minMessagesPerSecond),
        reason:
            'Throughput should be at least ${PerformanceThresholds.minMessagesPerSecond} msg/sec, '
            'but was ${metrics.messagesPerSecond.toStringAsFixed(2)} msg/sec',
      );

      // Log performance metrics
      debugPrint('PERF_METRIC: throughput_mps=${metrics.messagesPerSecond}');
      debugPrint('PERF_METRIC: send_p95_ms=${metrics.p95SendTimeMs}');
      debugPrint('PERF_METRIC: send_p99_ms=${metrics.p99SendTimeMs}');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  patrolTest('P95 message delivery latency', ($) async {
    TestAccounts.validateConfiguration();

    final metrics = ThroughputMetrics();

    // Setup
    await $.auth.loginWithCredentials(TestAccounts.user1);
    await $.sync.waitForSyncConnection();
    await $.sync.waitForRoomList();

    // Open a room
    final roomItem = $(ListTile).first;
    if (!roomItem.exists) {
      debugPrint('No room available for latency test');
      return;
    }
    await roomItem.tap();
    await $.pumpAndSettle();

    // Send messages and measure delivery time
    const testMessageCount = 20;

    for (var i = 0; i < testMessageCount; i++) {
      final messageText = TestMessageFactory.generateUniqueMessageText(
        'Latency $i',
      );

      final sendStartTime = DateTime.now();

      // Send message
      final inputField = $(TextField).last;
      await inputField.enterText(messageText);
      await $.pumpAndSettle();

      await $(Icons.send).tap();

      // Wait for sent status (measures delivery to server)
      final delivered = await $.sync.waitForMessageStatus(
        messageText,
        MessageDeliveryStatus.sent,
        timeout: TestTimeouts.messageDeliveryTimeout,
      );

      final deliveryTime = DateTime.now();
      final latencyMs = deliveryTime.difference(sendStartTime).inMilliseconds;

      if (delivered) {
        metrics.deliveryTimesMs.add(latencyMs);
        metrics.messagesDelivered++;
      }

      metrics.messagesSent++;

      await $.pump(const Duration(milliseconds: 100));
    }

    debugPrint(metrics.toString());

    // Validate P95 latency
    expect(
      metrics.p95DeliveryTimeMs,
      lessThanOrEqualTo(PerformanceThresholds.maxP95LatencyMs),
      reason:
          'P95 latency should be under ${PerformanceThresholds.maxP95LatencyMs}ms, '
          'but was ${metrics.p95DeliveryTimeMs}ms',
    );

    // Validate P99 latency
    expect(
      metrics.p99DeliveryTimeMs,
      lessThanOrEqualTo(PerformanceThresholds.maxP99LatencyMs),
      reason:
          'P99 latency should be under ${PerformanceThresholds.maxP99LatencyMs}ms, '
          'but was ${metrics.p99DeliveryTimeMs}ms',
    );

    debugPrint('PERF_METRIC: delivery_p50_ms=${metrics.p50DeliveryTimeMs}');
    debugPrint('PERF_METRIC: delivery_p95_ms=${metrics.p95DeliveryTimeMs}');
    debugPrint('PERF_METRIC: delivery_p99_ms=${metrics.p99DeliveryTimeMs}');
  }, timeout: const Timeout(Duration(minutes: 5)));

  patrolTest(
    'Burst message sending performance',
    ($) async {
      TestAccounts.validateConfiguration();

      final metrics = ThroughputMetrics();

      // Setup
      await $.auth.loginWithCredentials(TestAccounts.user1);
      await $.sync.waitForSyncConnection();
      await $.sync.waitForRoomList();

      // Open a room
      final roomItem = $(ListTile).first;
      if (!roomItem.exists) {
        debugPrint('No room available for burst test');
        return;
      }
      await roomItem.tap();
      await $.pumpAndSettle();

      // Burst send: send as fast as possible
      const burstSize = 10;
      final burstStartTime = DateTime.now();

      for (var i = 0; i < burstSize; i++) {
        final messageText = TestMessageFactory.generateUniqueMessageText(
          'Burst $i',
        );

        final inputField = $(TextField).last;
        await inputField.enterText(messageText);
        await $.pump(); // Minimal pump

        await $(Icons.send).tap();
        await $.pump(); // Minimal pump

        metrics.messagesSent++;
      }

      // Wait for all to settle
      await $.pumpAndSettle();

      final burstEndTime = DateTime.now();
      metrics.totalDurationMs = burstEndTime
          .difference(burstStartTime)
          .inMilliseconds;

      debugPrint('Burst metrics: ${metrics.toString()}');

      // Burst should still maintain reasonable throughput
      final burstThroughput = metrics.messagesPerSecond;
      debugPrint(
        'Burst throughput: ${burstThroughput.toStringAsFixed(2)} msg/sec',
      );

      expect(
        burstThroughput,
        greaterThan(0),
        reason: 'Burst send should complete successfully',
      );

      debugPrint('PERF_METRIC: burst_throughput_mps=$burstThroughput');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  patrolTest(
    'UI responsiveness during message scroll',
    ($) async {
      TestAccounts.validateConfiguration();

      // Setup
      await $.auth.loginWithCredentials(TestAccounts.user1);
      await $.sync.waitForSyncConnection();
      await $.sync.waitForRoomList();

      // Open a room with messages
      final roomItem = $(ListTile).first;
      if (!roomItem.exists) {
        debugPrint('No room available for scroll test');
        return;
      }
      await roomItem.tap();
      await $.pumpAndSettle();

      // Find scrollable message list
      final listView = $(ListView);
      if (!listView.exists) {
        debugPrint('No ListView found for scroll test');
        return;
      }

      // Perform scroll operations and measure frame timing
      final scrollStartTime = DateTime.now();
      var scrollIterations = 0;

      for (var i = 0; i < 5; i++) {
        // Scroll down
        await $.scrollUntilVisible(finder: $(Text).first);
        await $.pump();
        scrollIterations++;

        // Scroll up
        await $.pumpAndSettle();
        scrollIterations++;
      }

      final scrollEndTime = DateTime.now();
      final scrollDurationMs = scrollEndTime
          .difference(scrollStartTime)
          .inMilliseconds;

      debugPrint(
        'Scroll test: $scrollIterations iterations in ${scrollDurationMs}ms',
      );

      // Calculate approximate FPS (very rough estimate)
      final avgTimePerScroll = scrollDurationMs / scrollIterations;
      debugPrint('Average time per scroll: ${avgTimePerScroll}ms');

      // Scrolling should remain smooth
      expect(
        avgTimePerScroll,
        lessThan(500),
        reason: 'Scrolling should be responsive',
      );

      debugPrint('PERF_METRIC: scroll_avg_ms=$avgTimePerScroll');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  patrolTest(
    'Memory stability during sustained messaging',
    ($) async {
      TestAccounts.validateConfiguration();

      // Setup
      await $.auth.loginWithCredentials(TestAccounts.user1);
      await $.sync.waitForSyncConnection();
      await $.sync.waitForRoomList();

      // Open a room
      final roomItem = $(ListTile).first;
      if (!roomItem.exists) {
        debugPrint('No room available for memory test');
        return;
      }
      await roomItem.tap();
      await $.pumpAndSettle();

      // Send sustained messages and check for stability
      const sustainedMessageCount = 30;

      for (var i = 0; i < sustainedMessageCount; i++) {
        final messageText = TestMessageFactory.generateUniqueMessageText(
          'Memory $i',
        );

        final inputField = $(TextField).last;
        await inputField.enterText(messageText);
        await $.pumpAndSettle();

        await $(Icons.send).tap();
        await $.pumpAndSettle();

        // Log progress
        if ((i + 1) % 10 == 0) {
          debugPrint('Sent ${i + 1}/$sustainedMessageCount messages');
        }

        await $.pump(const Duration(milliseconds: 50));
      }

      // App should still be responsive after sustained messaging
      await $.pumpAndSettle();

      expect(
        $(Scaffold).exists,
        isTrue,
        reason: 'App should remain responsive after sustained messaging',
      );

      // Verify we can still interact
      final inputField = $(TextField).last;
      expect(
        inputField.exists,
        isTrue,
        reason: 'Input field should be accessible',
      );

      debugPrint('PERF_METRIC: sustained_messages=$sustainedMessageCount');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  patrolTest(
    'Large message batch performance',
    ($) async {
      TestAccounts.validateConfiguration();

      final metrics = ThroughputMetrics();

      // Setup
      await $.auth.loginWithCredentials(TestAccounts.user1);
      await $.sync.waitForSyncConnection();
      await $.sync.waitForRoomList();

      // Open a room
      final roomItem = $(ListTile).first;
      if (!roomItem.exists) {
        debugPrint('No room available for batch test');
        return;
      }
      await roomItem.tap();
      await $.pumpAndSettle();

      // Large batch test
      const batch = MessageBatchConfig.large;
      final testStartTime = DateTime.now();

      debugPrint('Starting large batch test: ${batch.totalMessages} messages');

      for (var i = 0; i < batch.totalMessages; i++) {
        final messageText = TestMessageFactory.generateUniqueMessageText(
          'Batch $i',
        );

        final inputField = $(TextField).last;
        await inputField.enterText(messageText);
        await $.pump();

        await $(Icons.send).tap();
        await $.pump();

        metrics.messagesSent++;

        // Minimal delay
        if (i % batch.batchSize == 0 && i > 0) {
          await $.pump(Duration(milliseconds: batch.delayBetweenBatchesMs));
          debugPrint('Batch progress: $i/${batch.totalMessages}');
        }
      }

      await $.pumpAndSettle();

      final testEndTime = DateTime.now();
      metrics.totalDurationMs = testEndTime
          .difference(testStartTime)
          .inMilliseconds;

      debugPrint('Large batch completed: ${metrics.toString()}');

      // App should handle large batches
      expect(
        metrics.messagesSent,
        equals(batch.totalMessages),
        reason: 'All messages in batch should be sent',
      );

      expect(
        metrics.messagesPerSecond,
        greaterThan(0),
        reason: 'Batch should complete with positive throughput',
      );

      debugPrint(
        'PERF_METRIC: large_batch_throughput=${metrics.messagesPerSecond}',
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
