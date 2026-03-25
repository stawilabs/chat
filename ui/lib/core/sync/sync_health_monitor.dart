import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import 'pending_job_repository.dart';
import 'sync_engine.dart';

/// Circuit breaker states for connection management
enum CircuitBreakerState {
  /// Normal operation - connections allowed
  closed,

  /// Partial failure - allowing limited connections (test probes)
  halfOpen,

  /// Full failure - connections blocked until reset
  open,
}

/// Health status for the sync system
enum SyncHealthStatus {
  /// All systems functioning normally
  healthy,

  /// Minor issues detected, monitoring
  degraded,

  /// Significant issues, requires attention
  unhealthy,

  /// Critical failure, sync disabled
  critical,
}

/// Comprehensive health metrics for the sync system
class SyncHealthMetrics {
  const SyncHealthMetrics({
    required this.status,
    required this.connectionState,
    required this.circuitBreakerState,
    required this.jobQueueHealth,
    required this.consecutiveFailures,
    required this.lastSuccessfulConnection,
    required this.lastFailure,
    required this.failureReason,
    required this.uptimeMs,
    required this.messagesProcessedCount,
    required this.messagesFailedCount,
    required this.averageLatencyMs,
  });

  /// Overall health status
  final SyncHealthStatus status;

  /// Current connection state
  final SyncConnectionState connectionState;

  /// Circuit breaker state
  final CircuitBreakerState circuitBreakerState;

  /// Job queue health
  final JobQueueHealth? jobQueueHealth;

  /// Number of consecutive connection failures
  final int consecutiveFailures;

  /// Last successful connection time
  final DateTime? lastSuccessfulConnection;

  /// Last failure time
  final DateTime? lastFailure;

  /// Reason for last failure
  final String? failureReason;

  /// Total uptime in milliseconds
  final int uptimeMs;

  /// Total messages processed successfully
  final int messagesProcessedCount;

  /// Total messages that failed processing
  final int messagesFailedCount;

  /// Average message processing latency in milliseconds
  final double averageLatencyMs;

  /// Success rate as a percentage
  double get successRate {
    final total = messagesProcessedCount + messagesFailedCount;
    return total == 0 ? 100.0 : (messagesProcessedCount / total) * 100;
  }

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'connectionState': connectionState.name,
    'circuitBreakerState': circuitBreakerState.name,
    'consecutiveFailures': consecutiveFailures,
    'lastSuccessfulConnection': lastSuccessfulConnection?.toIso8601String(),
    'lastFailure': lastFailure?.toIso8601String(),
    'failureReason': failureReason,
    'uptimeMs': uptimeMs,
    'messagesProcessedCount': messagesProcessedCount,
    'messagesFailedCount': messagesFailedCount,
    'averageLatencyMs': averageLatencyMs,
    'successRate': successRate,
    if (jobQueueHealth != null) 'jobQueueHealth': jobQueueHealth!.toJson(),
  };
}

/// Monitors and manages sync system health with circuit breaker pattern
///
/// Features:
/// - Circuit breaker to prevent hammering failed connections
/// - Health metrics tracking
/// - Automatic recovery mechanisms
/// - Alerting for critical issues
class SyncHealthMonitor {
  SyncHealthMonitor(this._jobRepo);

  final PendingJobRepository _jobRepo;

  // Circuit breaker configuration
  static const _failureThreshold = 5;
  static const _successThreshold = 3;
  static const _openDuration = Duration(minutes: 2);

  // Health thresholds
  static const _degradedLatencyMs = 500;
  static const _unhealthyLatencyMs = 2000;
  static const _criticalFailureRate = 50.0; // percentage

  // State
  CircuitBreakerState _circuitState = CircuitBreakerState.closed;
  int _consecutiveFailures = 0;
  int _consecutiveSuccesses = 0;
  DateTime? _lastSuccessfulConnection;
  DateTime? _lastFailure;
  String? _lastFailureReason;
  DateTime? _circuitOpenedAt;
  Timer? _halfOpenTimer;

  // Metrics
  int _messagesProcessedCount = 0;
  int _messagesFailedCount = 0;
  final List<int> _recentLatencies = [];
  static const _maxLatencySamples = 100;
  DateTime? _monitoringStartTime;

  // Stream for health updates
  final _healthController = StreamController<SyncHealthMetrics>.broadcast();
  Stream<SyncHealthMetrics> get healthStream => _healthController.stream;

  /// Current circuit breaker state
  CircuitBreakerState get circuitState => _circuitState;

  /// Whether connections are currently allowed
  bool get isConnectionAllowed {
    switch (_circuitState) {
      case CircuitBreakerState.closed:
        return true;
      case CircuitBreakerState.halfOpen:
        // Allow test probes in half-open state
        return true;
      case CircuitBreakerState.open:
        // Check if enough time has passed to try again
        if (_circuitOpenedAt != null) {
          final elapsed = DateTime.now().difference(_circuitOpenedAt!);
          if (elapsed >= _openDuration) {
            _transitionToHalfOpen();
            return true;
          }
        }
        return false;
    }
  }

  /// Start monitoring
  void start() {
    _monitoringStartTime = DateTime.now();
    AppLogger.info('SyncHealthMonitor: Started');
  }

  /// Stop monitoring
  void stop() {
    _halfOpenTimer?.cancel();
    _halfOpenTimer = null;
    AppLogger.info('SyncHealthMonitor: Stopped');
  }

  /// Record a successful connection
  void recordConnectionSuccess() {
    _lastSuccessfulConnection = DateTime.now();
    _consecutiveFailures = 0;
    _consecutiveSuccesses++;

    if (_circuitState == CircuitBreakerState.halfOpen) {
      if (_consecutiveSuccesses >= _successThreshold) {
        _transitionToClosed();
      }
    }

    _emitHealthUpdate();
  }

  /// Record a connection failure
  void recordConnectionFailure(String reason) {
    _lastFailure = DateTime.now();
    _lastFailureReason = reason;
    _consecutiveFailures++;
    _consecutiveSuccesses = 0;

    AppLogger.warning(
      'SyncHealthMonitor: Connection failure recorded',
      data: {
        'reason': reason,
        'consecutiveFailures': _consecutiveFailures,
        'circuitState': _circuitState.name,
      },
    );

    // Circuit breaker logic
    if (_circuitState == CircuitBreakerState.closed &&
        _consecutiveFailures >= _failureThreshold) {
      _transitionToOpen(reason);
    } else if (_circuitState == CircuitBreakerState.halfOpen) {
      // Any failure in half-open state reopens the circuit
      _transitionToOpen(reason);
    }

    _emitHealthUpdate();
  }

  /// Record a message processed successfully
  void recordMessageSuccess({int latencyMs = 0}) {
    _messagesProcessedCount++;
    _recordLatency(latencyMs);
  }

  /// Record a message processing failure
  void recordMessageFailure() {
    _messagesFailedCount++;
    _emitHealthUpdate();
  }

  /// Record processing latency
  void _recordLatency(int latencyMs) {
    _recentLatencies.add(latencyMs);
    if (_recentLatencies.length > _maxLatencySamples) {
      _recentLatencies.removeAt(0);
    }
  }

  /// Get current health metrics
  Future<SyncHealthMetrics> getHealthMetrics({
    SyncConnectionState? connectionState,
  }) async {
    final jobHealth = await _jobRepo.getQueueHealth();
    final avgLatency = _calculateAverageLatency();
    final uptimeMs = _monitoringStartTime != null
        ? DateTime.now().difference(_monitoringStartTime!).inMilliseconds
        : 0;

    final status = _determineHealthStatus(
      connectionState ?? SyncConnectionState.disconnected,
      jobHealth,
      avgLatency,
    );

    return SyncHealthMetrics(
      status: status,
      connectionState: connectionState ?? SyncConnectionState.disconnected,
      circuitBreakerState: _circuitState,
      jobQueueHealth: jobHealth,
      consecutiveFailures: _consecutiveFailures,
      lastSuccessfulConnection: _lastSuccessfulConnection,
      lastFailure: _lastFailure,
      failureReason: _lastFailureReason,
      uptimeMs: uptimeMs,
      messagesProcessedCount: _messagesProcessedCount,
      messagesFailedCount: _messagesFailedCount,
      averageLatencyMs: avgLatency,
    );
  }

  /// Manually reset the circuit breaker
  void resetCircuitBreaker() {
    AppLogger.info('SyncHealthMonitor: Circuit breaker manually reset');
    _transitionToClosed();
  }

  /// Manually trigger recovery
  Future<void> triggerRecovery() async {
    AppLogger.info('SyncHealthMonitor: Manual recovery triggered');

    // Reset circuit breaker
    _transitionToClosed();

    // Clear stuck jobs
    await _jobRepo.performStartupCleanup();

    _emitHealthUpdate();
  }

  // Private methods

  void _transitionToClosed() {
    _circuitState = CircuitBreakerState.closed;
    _consecutiveFailures = 0;
    _halfOpenTimer?.cancel();
    _halfOpenTimer = null;
    _circuitOpenedAt = null;

    AppLogger.info('SyncHealthMonitor: Circuit breaker closed');
    _emitHealthUpdate();
  }

  void _transitionToHalfOpen() {
    _circuitState = CircuitBreakerState.halfOpen;
    _consecutiveSuccesses = 0;

    AppLogger.info('SyncHealthMonitor: Circuit breaker half-open');
    _emitHealthUpdate();
  }

  void _transitionToOpen(String reason) {
    _circuitState = CircuitBreakerState.open;
    _circuitOpenedAt = DateTime.now();

    AppLogger.error(
      'SyncHealthMonitor: Circuit breaker opened',
      data: {
        'reason': reason,
        'consecutiveFailures': _consecutiveFailures,
        'openDuration': _openDuration.inSeconds,
      },
    );

    // Schedule transition to half-open
    _halfOpenTimer?.cancel();
    _halfOpenTimer = Timer(_openDuration, () {
      if (_circuitState == CircuitBreakerState.open) {
        _transitionToHalfOpen();
      }
    });

    _emitHealthUpdate();
  }

  double _calculateAverageLatency() {
    if (_recentLatencies.isEmpty) return 0;
    final sum = _recentLatencies.fold<int>(0, (sum, l) => sum + l);
    return sum / _recentLatencies.length;
  }

  SyncHealthStatus _determineHealthStatus(
    SyncConnectionState connectionState,
    JobQueueHealth jobHealth,
    double avgLatency,
  ) {
    // Critical: Circuit breaker open or too many failures
    if (_circuitState == CircuitBreakerState.open) {
      return SyncHealthStatus.critical;
    }

    // Critical: High failure rate
    final total = _messagesProcessedCount + _messagesFailedCount;
    if (total > 10) {
      final failureRate = (_messagesFailedCount / total) * 100;
      if (failureRate >= _criticalFailureRate) {
        return SyncHealthStatus.critical;
      }
    }

    // Unhealthy: Not connected or high latency
    if (connectionState == SyncConnectionState.disconnected &&
        _consecutiveFailures >= 2) {
      return SyncHealthStatus.unhealthy;
    }
    if (avgLatency > _unhealthyLatencyMs) {
      return SyncHealthStatus.unhealthy;
    }

    // Unhealthy: Job queue issues
    if (!jobHealth.isHealthy && jobHealth.stuckCount > 0) {
      return SyncHealthStatus.unhealthy;
    }

    // Degraded: Some issues but functional
    if (_circuitState == CircuitBreakerState.halfOpen) {
      return SyncHealthStatus.degraded;
    }
    if (avgLatency > _degradedLatencyMs) {
      return SyncHealthStatus.degraded;
    }
    if (!jobHealth.isHealthy) {
      return SyncHealthStatus.degraded;
    }
    if (_consecutiveFailures > 0) {
      return SyncHealthStatus.degraded;
    }

    return SyncHealthStatus.healthy;
  }

  bool _healthUpdateScheduled = false;

  void _emitHealthUpdate() {
    // Debounce: only schedule one microtask at a time to prevent unbounded
    // DB queries when multiple events fire in a burst.
    if (_healthUpdateScheduled) return;
    _healthUpdateScheduled = true;

    Future.microtask(() async {
      _healthUpdateScheduled = false;
      final metrics = await getHealthMetrics();
      if (!_healthController.isClosed) {
        _healthController.add(metrics);
      }
    });
  }

  void dispose() {
    stop();
    _healthController.close();
  }
}

/// Provider for SyncHealthMonitor
final syncHealthMonitorProvider = Provider<SyncHealthMonitor>((ref) {
  final jobRepo = ref.watch(pendingJobRepositoryProvider);
  final monitor = SyncHealthMonitor(jobRepo);

  ref.onDispose(monitor.dispose);

  return monitor;
});

/// Provider for current sync health metrics
final syncHealthMetricsProvider = FutureProvider<SyncHealthMetrics>((
  ref,
) async {
  final monitor = ref.watch(syncHealthMonitorProvider);
  final syncEngine = await ref.watch(syncEngineProvider.future);

  return monitor.getHealthMetrics(
    connectionState: syncEngine.currentConnectionState,
  );
});

/// Stream provider for real-time health updates
final syncHealthStreamProvider = StreamProvider<SyncHealthMetrics>((ref) {
  final monitor = ref.watch(syncHealthMonitorProvider);
  return monitor.healthStream;
});
