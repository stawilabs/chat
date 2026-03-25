import 'dart:async';
import 'dart:collection';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../logging/app_logger.dart';

part 'network_optimizer.g.dart';

// ============================================================================
// Request Deduplication
// ============================================================================

/// Deduplicates concurrent identical requests
///
/// When multiple components request the same data simultaneously,
/// this ensures only one network call is made and the result is shared.
class RequestDeduplicator {
  final Map<String, Future<dynamic>> _pendingRequests = {};
  final Map<String, DateTime> _requestTimestamps = {};

  /// Minimum time between duplicate requests (prevents rapid-fire calls)
  static const Duration _minRequestInterval = Duration(milliseconds: 500);

  /// Execute a request with deduplication
  ///
  /// If an identical request is already in-flight, returns that future.
  /// If the same request was made recently, waits for the interval.
  Future<T> dedupe<T>(String key, Future<T> Function() request) async {
    // Check if request is already in-flight
    if (_pendingRequests.containsKey(key)) {
      AppLogger.debug('[Dedup] Reusing in-flight request: $key');
      return await _pendingRequests[key] as T;
    }

    // Check if we should throttle
    final lastRequest = _requestTimestamps[key];
    if (lastRequest != null) {
      final elapsed = DateTime.now().difference(lastRequest);
      if (elapsed < _minRequestInterval) {
        final waitTime = _minRequestInterval - elapsed;
        AppLogger.debug(
          '[Dedup] Throttling request $key for ${waitTime.inMilliseconds}ms',
        );
        await Future.delayed(waitTime);
      }
    }

    // Execute and cache the request
    final future = request();
    _pendingRequests[key] = future;
    _requestTimestamps[key] = DateTime.now();

    try {
      final result = await future;
      return result;
    } finally {
      _pendingRequests.remove(key);

      // Clear old timestamps periodically
      if (_requestTimestamps.length > 100) {
        _cleanupTimestamps();
      }
    }
  }

  void _cleanupTimestamps() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(minutes: 5));
    _requestTimestamps.removeWhere((_, time) => time.isBefore(cutoff));
  }

  /// Cancel all pending requests
  void clear() {
    _pendingRequests.clear();
    _requestTimestamps.clear();
  }

  /// Check if a request is currently in-flight
  bool isInFlight(String key) => _pendingRequests.containsKey(key);

  /// Get count of pending requests
  int get pendingCount => _pendingRequests.length;
}

// ============================================================================
// Bandwidth Tracking
// ============================================================================

/// Tracks network bandwidth usage
class BandwidthTracker {
  final Queue<_BandwidthSample> _samples = Queue();
  int _totalBytesReceived = 0;
  int _totalBytesSent = 0;
  DateTime? _trackingStartTime;

  static const int _maxSamples = 100;
  static const Duration _sampleWindow = Duration(seconds: 60);

  /// Record bytes received
  void recordReceived(int bytes) {
    _trackingStartTime ??= DateTime.now();
    _totalBytesReceived += bytes;
    _addSample(bytes, 0);
  }

  /// Record bytes sent
  void recordSent(int bytes) {
    _trackingStartTime ??= DateTime.now();
    _totalBytesSent += bytes;
    _addSample(0, bytes);
  }

  void _addSample(int received, int sent) {
    _samples.addLast(
      _BandwidthSample(
        timestamp: DateTime.now(),
        bytesReceived: received,
        bytesSent: sent,
      ),
    );

    // Trim old samples
    while (_samples.length > _maxSamples) {
      _samples.removeFirst();
    }
  }

  /// Get current bandwidth statistics
  BandwidthStats getStats() {
    final now = DateTime.now();
    final cutoff = now.subtract(_sampleWindow);

    // Filter recent samples
    final recentSamples = _samples
        .where((s) => s.timestamp.isAfter(cutoff))
        .toList();

    var recentReceived = 0;
    var recentSent = 0;
    for (final sample in recentSamples) {
      recentReceived += sample.bytesReceived;
      recentSent += sample.bytesSent;
    }

    // Calculate rates (bytes per second)
    final windowSeconds = _sampleWindow.inSeconds;
    final receiveRate = recentReceived / windowSeconds;
    final sendRate = recentSent / windowSeconds;

    return BandwidthStats(
      totalBytesReceived: _totalBytesReceived,
      totalBytesSent: _totalBytesSent,
      recentBytesReceived: recentReceived,
      recentBytesSent: recentSent,
      receiveRateBps: receiveRate,
      sendRateBps: sendRate,
      trackingDuration: _trackingStartTime != null
          ? now.difference(_trackingStartTime!)
          : Duration.zero,
    );
  }

  /// Reset all statistics
  void reset() {
    _samples.clear();
    _totalBytesReceived = 0;
    _totalBytesSent = 0;
    _trackingStartTime = null;
  }
}

class _BandwidthSample {
  const _BandwidthSample({
    required this.timestamp,
    required this.bytesReceived,
    required this.bytesSent,
  });

  final DateTime timestamp;
  final int bytesReceived;
  final int bytesSent;
}

/// Bandwidth usage statistics
class BandwidthStats {
  const BandwidthStats({
    required this.totalBytesReceived,
    required this.totalBytesSent,
    required this.recentBytesReceived,
    required this.recentBytesSent,
    required this.receiveRateBps,
    required this.sendRateBps,
    required this.trackingDuration,
  });

  final int totalBytesReceived;
  final int totalBytesSent;
  final int recentBytesReceived;
  final int recentBytesSent;
  final double receiveRateBps;
  final double sendRateBps;
  final Duration trackingDuration;

  int get totalBytes => totalBytesReceived + totalBytesSent;
  int get recentBytes => recentBytesReceived + recentBytesSent;

  String get formattedTotalReceived => _formatBytes(totalBytesReceived);
  String get formattedTotalSent => _formatBytes(totalBytesSent);
  String get formattedTotal => _formatBytes(totalBytes);
  String get formattedReceiveRate =>
      '${_formatBytes(receiveRateBps.round())}/s';
  String get formattedSendRate => '${_formatBytes(sendRateBps.round())}/s';

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

// ============================================================================
// Prefetch Manager
// ============================================================================

/// Manages prefetching of likely-needed data
class PrefetchManager {
  final Map<String, DateTime> _prefetchedItems = {};
  final Set<String> _prefetchingInProgress = {};
  // Priority-sorted list (high priority at front, maintained via binary insertion)
  final List<_PrefetchTask> _queue = [];
  bool _isProcessing = false;

  /// Maximum prefetch items to keep track of
  static const int _maxTrackedItems = 50;

  /// How long to consider an item "fresh" (no need to refetch)
  static const Duration _freshDuration = Duration(minutes: 5);

  /// Maximum concurrent prefetch operations
  static const int _maxConcurrent = 2;

  /// Schedule a prefetch task
  void schedule(
    String key,
    Future<void> Function() task, {
    PrefetchPriority priority = PrefetchPriority.normal,
  }) {
    // Skip if already prefetched recently
    final lastPrefetch = _prefetchedItems[key];
    if (lastPrefetch != null &&
        DateTime.now().difference(lastPrefetch) < _freshDuration) {
      AppLogger.debug('[Prefetch] Skipping $key - still fresh');
      return;
    }

    // Skip if already in progress
    if (_prefetchingInProgress.contains(key)) {
      AppLogger.debug('[Prefetch] Skipping $key - already in progress');
      return;
    }

    // Insert with priority ordering (high priority at front)
    final newTask = _PrefetchTask(key: key, task: task, priority: priority);
    _insertSorted(newTask);
    _processQueue();
  }

  /// Insert task in sorted order (binary search for O(log n) position finding)
  void _insertSorted(_PrefetchTask task) {
    if (_queue.isEmpty) {
      _queue.add(task);
      return;
    }

    // Binary search for insertion point (high priority first)
    var low = 0;
    var high = _queue.length;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      // Higher priority index = higher priority, should come first
      if (_queue[mid].priority.index >= task.priority.index) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    _queue.insert(low, task);
  }

  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      while (_queue.isNotEmpty &&
          _prefetchingInProgress.length < _maxConcurrent) {
        // Remove highest priority task (at front of sorted list)
        final task = _queue.removeAt(0);
        _prefetchingInProgress.add(task.key);

        // Run in background, don't await
        _executePrefetch(task);
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _executePrefetch(_PrefetchTask task) async {
    try {
      AppLogger.debug('[Prefetch] Starting: ${task.key}');
      await task.task();
      _prefetchedItems[task.key] = DateTime.now();
      AppLogger.debug('[Prefetch] Completed: ${task.key}');

      // Cleanup old entries
      if (_prefetchedItems.length > _maxTrackedItems) {
        _cleanupOldEntries();
      }
    } catch (e) {
      AppLogger.warning(
        '[Prefetch] Failed: ${task.key}',
        data: {'error': e.toString()},
      );
    } finally {
      _prefetchingInProgress.remove(task.key);
      _processQueue();
    }
  }

  void _cleanupOldEntries() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(minutes: 30));
    _prefetchedItems.removeWhere((_, time) => time.isBefore(cutoff));
  }

  /// Check if an item was recently prefetched
  bool isPrefetched(String key) {
    final lastPrefetch = _prefetchedItems[key];
    if (lastPrefetch == null) return false;
    return DateTime.now().difference(lastPrefetch) < _freshDuration;
  }

  /// Cancel all pending prefetch tasks
  void cancelAll() {
    _queue.clear();
    // Note: Can't cancel in-progress tasks, but they'll complete naturally
  }

  /// Get current prefetch queue length
  int get queueLength => _queue.length;

  /// Get number of in-progress prefetches
  int get inProgressCount => _prefetchingInProgress.length;
}

enum PrefetchPriority { low, normal, high }

class _PrefetchTask {
  const _PrefetchTask({
    required this.key,
    required this.task,
    required this.priority,
  });

  final String key;
  final Future<void> Function() task;
  final PrefetchPriority priority;
}

// ============================================================================
// Delta Sync Support
// ============================================================================

/// Tracks sync state for delta synchronization
class DeltaSyncTracker {
  final Map<String, int> _lastSyncIndex = {};
  final Map<String, DateTime> _lastSyncTime = {};

  /// Get the last known sync index for a resource
  int? getLastSyncIndex(String resourceKey) => _lastSyncIndex[resourceKey];

  /// Get the last sync timestamp for a resource
  DateTime? getLastSyncTime(String resourceKey) => _lastSyncTime[resourceKey];

  /// Update sync state after a successful sync
  void updateSyncState(String resourceKey, {int? index, DateTime? timestamp}) {
    if (index != null) {
      _lastSyncIndex[resourceKey] = index;
    }
    _lastSyncTime[resourceKey] = timestamp ?? DateTime.now();
  }

  /// Check if a full sync is needed (no prior sync state)
  bool needsFullSync(String resourceKey) =>
      !_lastSyncIndex.containsKey(resourceKey);

  /// Clear sync state for a resource (forces full sync)
  void clearSyncState(String resourceKey) {
    _lastSyncIndex.remove(resourceKey);
    _lastSyncTime.remove(resourceKey);
  }

  /// Clear all sync state
  void clearAll() {
    _lastSyncIndex.clear();
    _lastSyncTime.clear();
  }

  /// Get sync state as map (for persistence)
  Map<String, dynamic> toJson() {
    return {
      'indexes': Map<String, int>.from(_lastSyncIndex),
      'timestamps': _lastSyncTime.map(
        (k, v) => MapEntry(k, v.toIso8601String()),
      ),
    };
  }

  /// Restore sync state from map
  void fromJson(Map<String, dynamic> json) {
    final indexes = json['indexes'] as Map<String, dynamic>?;
    if (indexes != null) {
      _lastSyncIndex.clear();
      indexes.forEach((k, v) {
        if (v is int) _lastSyncIndex[k] = v;
      });
    }

    final timestamps = json['timestamps'] as Map<String, dynamic>?;
    if (timestamps != null) {
      _lastSyncTime.clear();
      timestamps.forEach((k, v) {
        if (v is String) {
          final parsed = DateTime.tryParse(v);
          if (parsed != null) _lastSyncTime[k] = parsed;
        }
      });
    }
  }
}

// ============================================================================
// Network Optimizer - Main Service
// ============================================================================

/// Centralized network optimization service
class NetworkOptimizer {
  NetworkOptimizer();

  final RequestDeduplicator deduplicator = RequestDeduplicator();
  final BandwidthTracker bandwidthTracker = BandwidthTracker();
  final PrefetchManager prefetchManager = PrefetchManager();
  final DeltaSyncTracker deltaSyncTracker = DeltaSyncTracker();

  /// Recommended headers for optimized requests
  static const Map<String, String> optimizedHeaders = {
    'Accept-Encoding': 'gzip, deflate',
    'Connection': 'keep-alive',
  };

  /// Execute a request with deduplication and bandwidth tracking
  Future<T> executeOptimized<T>(
    String requestKey,
    Future<T> Function() request, {
    int? expectedResponseSize,
  }) async {
    final result = await deduplicator.dedupe(requestKey, request);

    // Track bandwidth if size provided
    if (expectedResponseSize != null) {
      bandwidthTracker.recordReceived(expectedResponseSize);
    }

    return result;
  }

  /// Schedule prefetching of related data
  void prefetch(
    String key,
    Future<void> Function() task, {
    PrefetchPriority priority = PrefetchPriority.normal,
  }) {
    prefetchManager.schedule(key, task, priority: priority);
  }

  /// Get current network statistics
  NetworkStats getStats() {
    final bandwidth = bandwidthTracker.getStats();
    return NetworkStats(
      bandwidth: bandwidth,
      pendingRequests: deduplicator.pendingCount,
      prefetchQueueLength: prefetchManager.queueLength,
      prefetchInProgress: prefetchManager.inProgressCount,
    );
  }

  /// Reset all tracking
  void reset() {
    deduplicator.clear();
    bandwidthTracker.reset();
    prefetchManager.cancelAll();
    deltaSyncTracker.clearAll();
  }
}

/// Combined network statistics
class NetworkStats {
  const NetworkStats({
    required this.bandwidth,
    required this.pendingRequests,
    required this.prefetchQueueLength,
    required this.prefetchInProgress,
  });

  final BandwidthStats bandwidth;
  final int pendingRequests;
  final int prefetchQueueLength;
  final int prefetchInProgress;
}

// ============================================================================
// Providers
// ============================================================================

@riverpod
NetworkOptimizer networkOptimizer(Ref ref) {
  final optimizer = NetworkOptimizer();

  ref.onDispose(optimizer.reset);

  return optimizer;
}

/// Stream of bandwidth statistics updated every 5 seconds
@riverpod
Stream<BandwidthStats> bandwidthStats(Ref ref) async* {
  final optimizer = ref.watch(networkOptimizerProvider);

  // Emit initial stats immediately
  yield optimizer.bandwidthTracker.getStats();

  // Then emit updates every 5 seconds
  await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
    yield optimizer.bandwidthTracker.getStats();
  }
}
