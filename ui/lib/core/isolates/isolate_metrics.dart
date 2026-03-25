import 'dart:collection';

import '../logging/app_logger.dart';

/// Metrics data for a single task execution
class TaskExecutionMetric {
  TaskExecutionMetric({
    required this.isolateName,
    required this.taskType,
    required this.duration,
    required this.timestamp,
  });
  final String isolateName;
  final String taskType;
  final Duration duration;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'isolateName': isolateName,
    'taskType': taskType,
    'durationMs': duration.inMilliseconds,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Aggregated metrics for a specific isolate/task combination
class TaskMetricsSummary {
  TaskMetricsSummary({
    required this.isolateName,
    required this.taskType,
    required this.totalExecutions,
    required this.totalDuration,
    required this.averageDuration,
    required this.minDuration,
    required this.maxDuration,
    required this.p50Duration,
    required this.p90Duration,
    required this.p99Duration,
  });
  final String isolateName;
  final String taskType;
  final int totalExecutions;
  final Duration totalDuration;
  final Duration averageDuration;
  final Duration minDuration;
  final Duration maxDuration;
  final Duration p50Duration;
  final Duration p90Duration;
  final Duration p99Duration;

  Map<String, dynamic> toJson() => {
    'isolateName': isolateName,
    'taskType': taskType,
    'totalExecutions': totalExecutions,
    'totalDurationMs': totalDuration.inMilliseconds,
    'averageDurationMs': averageDuration.inMilliseconds,
    'minDurationMs': minDuration.inMilliseconds,
    'maxDurationMs': maxDuration.inMilliseconds,
    'p50DurationMs': p50Duration.inMilliseconds,
    'p90DurationMs': p90Duration.inMilliseconds,
    'p99DurationMs': p99Duration.inMilliseconds,
  };
}

/// Tracks performance metrics for isolate operations
///
/// Provides detailed timing information for task execution,
/// queue depth monitoring, and aggregated statistics.
///
/// Example:
/// ```dart
/// final metrics = IsolateMetrics();
///
/// // Record a task execution
/// metrics.recordTaskExecution(
///   'message_processor',
///   'processMessages',
///   Duration(milliseconds: 50),
/// );
///
/// // Get summary
/// final summary = metrics.getSummary('message_processor', 'processMessages');
/// print('Average: ${summary.averageDuration.inMilliseconds}ms');
/// ```
class IsolateMetrics {
  /// Maximum number of metrics to retain per isolate/task
  static const int _maxMetricsPerTask = 1000;

  /// Metrics storage: isolateName -> taskType -> list of metrics
  final Map<String, Map<String, Queue<TaskExecutionMetric>>> _metrics = {};

  /// Current queue depth per isolate
  final Map<String, int> _queueDepths = {};

  /// Total task count per isolate
  final Map<String, int> _taskCounts = {};

  /// Error count per isolate
  final Map<String, int> _errorCounts = {};

  /// Record a task execution
  void recordTaskExecution(
    String isolateName,
    String taskType,
    Duration duration,
  ) {
    // Initialize storage if needed
    _metrics.putIfAbsent(isolateName, () => {});
    _metrics[isolateName]!.putIfAbsent(taskType, Queue.new);

    final queue = _metrics[isolateName]![taskType]!;

    // Add new metric
    queue.add(
      TaskExecutionMetric(
        isolateName: isolateName,
        taskType: taskType,
        duration: duration,
        timestamp: DateTime.now(),
      ),
    );

    // Trim if exceeding max
    while (queue.length > _maxMetricsPerTask) {
      queue.removeFirst();
    }

    // Update task count
    _taskCounts[isolateName] = (_taskCounts[isolateName] ?? 0) + 1;

    // Log slow tasks
    if (duration.inMilliseconds > 100) {
      AppLogger.debug(
        'Slow isolate task detected',
        data: {
          'isolateName': isolateName,
          'taskType': taskType,
          'durationMs': duration.inMilliseconds,
        },
      );
    }
  }

  /// Record a task error
  void recordTaskError(String isolateName, String taskType, Object error) {
    _errorCounts[isolateName] = (_errorCounts[isolateName] ?? 0) + 1;

    AppLogger.debug(
      'Isolate task error recorded',
      data: {
        'isolateName': isolateName,
        'taskType': taskType,
        'error': error.toString(),
      },
    );
  }

  /// Increment queue depth for an isolate
  void incrementQueueDepth(String isolateName) {
    _queueDepths[isolateName] = (_queueDepths[isolateName] ?? 0) + 1;
  }

  /// Decrement queue depth for an isolate
  void decrementQueueDepth(String isolateName) {
    final current = _queueDepths[isolateName] ?? 0;
    _queueDepths[isolateName] = current > 0 ? current - 1 : 0;
  }

  /// Get current queue depth for an isolate
  int getQueueDepth(String isolateName) => _queueDepths[isolateName] ?? 0;

  /// Get total task count for an isolate
  int getTaskCount(String isolateName) => _taskCounts[isolateName] ?? 0;

  /// Get error count for an isolate
  int getErrorCount(String isolateName) => _errorCounts[isolateName] ?? 0;

  /// Get recent metrics for a specific isolate/task combination
  List<TaskExecutionMetric> getRecentMetrics(
    String isolateName,
    String taskType, {
    int limit = 100,
  }) {
    final queue = _metrics[isolateName]?[taskType];
    if (queue == null) return [];

    return queue.toList().reversed.take(limit).toList();
  }

  /// Get aggregated summary for a specific isolate/task combination
  TaskMetricsSummary? getSummary(String isolateName, String taskType) {
    final queue = _metrics[isolateName]?[taskType];
    if (queue == null || queue.isEmpty) return null;

    final durations = queue.map((m) => m.duration).toList()
      ..sort((a, b) => a.compareTo(b));

    final totalMs = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
    final count = durations.length;

    return TaskMetricsSummary(
      isolateName: isolateName,
      taskType: taskType,
      totalExecutions: count,
      totalDuration: Duration(milliseconds: totalMs),
      averageDuration: Duration(milliseconds: totalMs ~/ count),
      minDuration: durations.first,
      maxDuration: durations.last,
      p50Duration: _percentile(durations, 50),
      p90Duration: _percentile(durations, 90),
      p99Duration: _percentile(durations, 99),
    );
  }

  /// Get all summaries for an isolate
  List<TaskMetricsSummary> getAllSummaries(String isolateName) {
    final taskTypes = _metrics[isolateName]?.keys ?? [];
    return taskTypes
        .map((taskType) => getSummary(isolateName, taskType))
        .whereType<TaskMetricsSummary>()
        .toList();
  }

  /// Get global summary across all isolates
  Map<String, dynamic> getGlobalSummary() {
    final result = <String, dynamic>{};

    for (final isolateName in _metrics.keys) {
      result[isolateName] = {
        'queueDepth': getQueueDepth(isolateName),
        'totalTasks': getTaskCount(isolateName),
        'errorCount': getErrorCount(isolateName),
        'tasks': getAllSummaries(isolateName).map((s) => s.toJson()).toList(),
      };
    }

    return result;
  }

  /// Clear all metrics
  void clear() {
    _metrics.clear();
    _queueDepths.clear();
    _taskCounts.clear();
    _errorCounts.clear();
  }

  /// Clear metrics for a specific isolate
  void clearIsolate(String isolateName) {
    _metrics.remove(isolateName);
    _queueDepths.remove(isolateName);
    _taskCounts.remove(isolateName);
    _errorCounts.remove(isolateName);
  }

  /// Log current metrics summary
  void logSummary() {
    final summary = getGlobalSummary();
    AppLogger.info('Isolate metrics summary', data: summary);
  }

  /// Calculate percentile from sorted list
  Duration _percentile(List<Duration> sortedDurations, int percentile) {
    if (sortedDurations.isEmpty) return Duration.zero;
    final index = ((percentile / 100) * (sortedDurations.length - 1)).round();
    return sortedDurations[index];
  }
}
