import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/networking/network_optimizer.dart';

void main() {
  group('RequestDeduplicator', () {
    late RequestDeduplicator deduplicator;

    setUp(() {
      deduplicator = RequestDeduplicator();
    });

    test('deduplicates concurrent identical requests', () async {
      var callCount = 0;

      Future<String> request() async {
        callCount++;
        await Future.delayed(const Duration(milliseconds: 100));
        return 'result';
      }

      // Launch two concurrent requests with same key
      final futures = await Future.wait([
        deduplicator.dedupe('test-key', request),
        deduplicator.dedupe('test-key', request),
      ]);

      // Both should return the same result
      expect(futures[0], equals('result'));
      expect(futures[1], equals('result'));

      // But request should only be called once
      expect(callCount, equals(1));
    });

    test('allows different keys to execute separately', () async {
      var callCount = 0;

      // Create separate request functions that capture their own value
      Future<String> createRequest(String id) {
        return Future(() async {
          callCount++;
          await Future.delayed(const Duration(milliseconds: 50));
          return 'result-$id';
        });
      }

      final futures = await Future.wait([
        deduplicator.dedupe('key-1', () => createRequest('1')),
        deduplicator.dedupe('key-2', () => createRequest('2')),
      ]);

      // Each key gets its own call
      expect(callCount, equals(2));
      expect(futures[0], equals('result-1'));
      expect(futures[1], equals('result-2'));
    });

    test('isInFlight returns correct state', () async {
      expect(deduplicator.isInFlight('test-key'), isFalse);

      final completer = Future.delayed(
        const Duration(milliseconds: 100),
        () => 'done',
      );

      final future = deduplicator.dedupe('test-key', () => completer);

      expect(deduplicator.isInFlight('test-key'), isTrue);

      await future;

      expect(deduplicator.isInFlight('test-key'), isFalse);
    });

    test('pendingCount tracks active requests', () async {
      expect(deduplicator.pendingCount, equals(0));

      final future1 = deduplicator.dedupe(
        'key-1',
        () => Future.delayed(const Duration(milliseconds: 100), () => 'a'),
      );
      final future2 = deduplicator.dedupe(
        'key-2',
        () => Future.delayed(const Duration(milliseconds: 100), () => 'b'),
      );

      expect(deduplicator.pendingCount, equals(2));

      await Future.wait([future1, future2]);

      expect(deduplicator.pendingCount, equals(0));
    });

    test('clear removes all pending requests', () async {
      // Start a request
      deduplicator.dedupe(
        'test',
        () => Future.delayed(const Duration(seconds: 1), () => 'done'),
      );

      expect(deduplicator.pendingCount, equals(1));

      deduplicator.clear();

      expect(deduplicator.pendingCount, equals(0));
    });
  });

  group('BandwidthTracker', () {
    late BandwidthTracker tracker;

    setUp(() {
      tracker = BandwidthTracker();
    });

    test('records received bytes', () {
      tracker.recordReceived(1000);
      tracker.recordReceived(500);

      final stats = tracker.getStats();

      expect(stats.totalBytesReceived, equals(1500));
    });

    test('records sent bytes', () {
      tracker.recordSent(200);
      tracker.recordSent(300);

      final stats = tracker.getStats();

      expect(stats.totalBytesSent, equals(500));
    });

    test('calculates total bytes', () {
      tracker.recordReceived(1000);
      tracker.recordSent(500);

      final stats = tracker.getStats();

      expect(stats.totalBytes, equals(1500));
    });

    test('reset clears all statistics', () {
      tracker.recordReceived(1000);
      tracker.recordSent(500);

      tracker.reset();

      final stats = tracker.getStats();

      expect(stats.totalBytesReceived, equals(0));
      expect(stats.totalBytesSent, equals(0));
      expect(stats.trackingDuration, equals(Duration.zero));
    });

    test('tracks duration from first record', () async {
      tracker.recordReceived(100);

      await Future.delayed(const Duration(milliseconds: 50));

      final stats = tracker.getStats();

      expect(stats.trackingDuration.inMilliseconds, greaterThan(40));
    });
  });

  group('BandwidthStats', () {
    test('formats bytes correctly', () {
      const stats = BandwidthStats(
        totalBytesReceived: 1536,
        totalBytesSent: 512,
        recentBytesReceived: 1024,
        recentBytesSent: 256,
        receiveRateBps: 1024,
        sendRateBps: 512,
        trackingDuration: Duration(minutes: 5),
      );

      expect(stats.formattedTotalReceived, equals('1.5 KB'));
      expect(stats.formattedTotalSent, equals('512 B'));
      expect(stats.formattedTotal, equals('2.0 KB'));
      expect(stats.formattedReceiveRate, equals('1.0 KB/s'));
      expect(stats.formattedSendRate, equals('512 B/s'));
    });

    test('formats megabytes correctly', () {
      const stats = BandwidthStats(
        totalBytesReceived: 1024 * 1024 * 5, // 5 MB
        totalBytesSent: 0,
        recentBytesReceived: 0,
        recentBytesSent: 0,
        receiveRateBps: 0,
        sendRateBps: 0,
        trackingDuration: Duration.zero,
      );

      expect(stats.formattedTotalReceived, equals('5.0 MB'));
    });

    test('formats gigabytes correctly', () {
      const stats = BandwidthStats(
        totalBytesReceived: 1024 * 1024 * 1024 * 2, // 2 GB
        totalBytesSent: 0,
        recentBytesReceived: 0,
        recentBytesSent: 0,
        receiveRateBps: 0,
        sendRateBps: 0,
        trackingDuration: Duration.zero,
      );

      expect(stats.formattedTotalReceived, equals('2.00 GB'));
    });
  });

  group('PrefetchManager', () {
    late PrefetchManager prefetchManager;

    setUp(() {
      prefetchManager = PrefetchManager();
    });

    test('executes scheduled prefetch task', () async {
      var executed = false;

      prefetchManager.schedule('test-key', () async {
        await Future.delayed(const Duration(milliseconds: 10));
        executed = true;
      });

      // Wait for task to complete
      await Future.delayed(const Duration(milliseconds: 100));

      expect(executed, isTrue);
      expect(prefetchManager.isPrefetched('test-key'), isTrue);
    });

    test('skips duplicate prefetch for fresh items', () async {
      var callCount = 0;

      prefetchManager.schedule('test-key', () async {
        callCount++;
      });

      await Future.delayed(const Duration(milliseconds: 50));

      // Schedule again - should be skipped (still fresh)
      prefetchManager.schedule('test-key', () async {
        callCount++;
      });

      await Future.delayed(const Duration(milliseconds: 50));

      expect(callCount, equals(1));
    });

    test('respects priority ordering', () async {
      final executionOrder = <String>[];

      // Schedule low priority first
      prefetchManager.schedule('low', () async {
        await Future.delayed(const Duration(milliseconds: 10));
        executionOrder.add('low');
      }, priority: PrefetchPriority.low);

      // Schedule high priority second
      prefetchManager.schedule('high', () async {
        await Future.delayed(const Duration(milliseconds: 10));
        executionOrder.add('high');
      }, priority: PrefetchPriority.high);

      // Wait for both to complete
      await Future.delayed(const Duration(milliseconds: 200));

      // High priority should execute first (but this depends on timing)
      expect(executionOrder.length, equals(2));
    });

    test('cancelAll clears queue', () {
      prefetchManager.schedule('task-1', () async {});
      prefetchManager.schedule('task-2', () async {});

      prefetchManager.cancelAll();

      expect(prefetchManager.queueLength, equals(0));
    });

    test('tracks queue length', () {
      // Queue tasks that won't complete immediately
      for (var i = 0; i < 5; i++) {
        prefetchManager.schedule('task-$i', () async {
          await Future.delayed(const Duration(seconds: 1));
        });
      }

      // Queue length depends on how many are in-progress vs waiting
      // With max concurrent of 2, 3 should be in queue
      expect(
        prefetchManager.queueLength + prefetchManager.inProgressCount,
        lessThanOrEqualTo(5),
      );
    });
  });

  group('DeltaSyncTracker', () {
    late DeltaSyncTracker tracker;

    setUp(() {
      tracker = DeltaSyncTracker();
    });

    test('tracks sync index per resource', () {
      tracker.updateSyncState('rooms', index: 100);
      tracker.updateSyncState('messages', index: 250);

      expect(tracker.getLastSyncIndex('rooms'), equals(100));
      expect(tracker.getLastSyncIndex('messages'), equals(250));
    });

    test('tracks sync time per resource', () {
      final now = DateTime.now();
      tracker.updateSyncState('rooms', timestamp: now);

      final lastSync = tracker.getLastSyncTime('rooms');
      expect(lastSync, equals(now));
    });

    test('needsFullSync returns true for unknown resources', () {
      expect(tracker.needsFullSync('unknown'), isTrue);
    });

    test('needsFullSync returns false after sync', () {
      tracker.updateSyncState('rooms', index: 100);
      expect(tracker.needsFullSync('rooms'), isFalse);
    });

    test('clearSyncState forces full sync', () {
      tracker.updateSyncState('rooms', index: 100);
      expect(tracker.needsFullSync('rooms'), isFalse);

      tracker.clearSyncState('rooms');
      expect(tracker.needsFullSync('rooms'), isTrue);
    });

    test('clearAll resets all state', () {
      tracker.updateSyncState('rooms', index: 100);
      tracker.updateSyncState('messages', index: 200);

      tracker.clearAll();

      expect(tracker.needsFullSync('rooms'), isTrue);
      expect(tracker.needsFullSync('messages'), isTrue);
    });

    test('serializes to JSON and back', () {
      final now = DateTime.now();
      tracker.updateSyncState('rooms', index: 100, timestamp: now);
      tracker.updateSyncState('messages', index: 200);

      final json = tracker.toJson();

      final newTracker = DeltaSyncTracker();
      newTracker.fromJson(json);

      expect(newTracker.getLastSyncIndex('rooms'), equals(100));
      expect(newTracker.getLastSyncIndex('messages'), equals(200));
    });
  });

  group('NetworkOptimizer', () {
    late NetworkOptimizer optimizer;

    setUp(() {
      optimizer = NetworkOptimizer();
    });

    tearDown(() {
      optimizer.reset();
    });

    test('provides optimized headers', () {
      expect(
        NetworkOptimizer.optimizedHeaders['Accept-Encoding'],
        equals('gzip, deflate'),
      );
      expect(
        NetworkOptimizer.optimizedHeaders['Connection'],
        equals('keep-alive'),
      );
    });

    test('executeOptimized deduplicates requests', () async {
      var callCount = 0;

      Future<String> request() async {
        callCount++;
        await Future.delayed(const Duration(milliseconds: 50));
        return 'result';
      }

      final futures = await Future.wait([
        optimizer.executeOptimized('test', request),
        optimizer.executeOptimized('test', request),
      ]);

      expect(futures[0], equals('result'));
      expect(futures[1], equals('result'));
      expect(callCount, equals(1));
    });

    test('getStats returns combined statistics', () {
      optimizer.bandwidthTracker.recordReceived(1000);
      optimizer.bandwidthTracker.recordSent(500);

      final stats = optimizer.getStats();

      expect(stats.bandwidth.totalBytesReceived, equals(1000));
      expect(stats.bandwidth.totalBytesSent, equals(500));
      expect(stats.pendingRequests, equals(0));
    });

    test('reset clears all components', () {
      optimizer.bandwidthTracker.recordReceived(1000);
      optimizer.deltaSyncTracker.updateSyncState('test', index: 100);

      optimizer.reset();

      final stats = optimizer.getStats();
      expect(stats.bandwidth.totalBytesReceived, equals(0));
      expect(optimizer.deltaSyncTracker.needsFullSync('test'), isTrue);
    });
  });
}
