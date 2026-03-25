import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../db/database.dart';
import '../logging/app_logger.dart';
import 'pending_job.dart' as domain;

/// Health metrics for monitoring pending job queue
class JobQueueHealth {
  const JobQueueHealth({
    required this.pendingCount,
    required this.failedCount,
    required this.stuckCount,
    required this.oldestPendingAgeMs,
    required this.pendingByType,
    required this.failedByType,
    required this.averageRetryCount,
    required this.isHealthy,
    required this.healthIssues,
  });

  /// Total number of pending jobs
  final int pendingCount;

  /// Total number of failed jobs
  final int failedCount;

  /// Jobs stuck for more than the threshold duration
  final int stuckCount;

  /// Age of the oldest pending job in milliseconds
  final int oldestPendingAgeMs;

  /// Pending job count by type
  final Map<String, int> pendingByType;

  /// Failed job count by type
  final Map<String, int> failedByType;

  /// Average retry count across all pending jobs
  final double averageRetryCount;

  /// Whether the queue is in a healthy state
  final bool isHealthy;

  /// List of detected health issues
  final List<String> healthIssues;

  Map<String, dynamic> toJson() => {
    'pendingCount': pendingCount,
    'failedCount': failedCount,
    'stuckCount': stuckCount,
    'oldestPendingAgeMs': oldestPendingAgeMs,
    'pendingByType': pendingByType,
    'failedByType': failedByType,
    'averageRetryCount': averageRetryCount,
    'isHealthy': isHealthy,
    'healthIssues': healthIssues,
  };
}

/// Result of a cleanup operation
class JobCleanupResult {
  const JobCleanupResult({
    required this.deletedFailedJobs,
    required this.resetStuckJobs,
    required this.deletedOrphanedJobs,
  });

  final int deletedFailedJobs;
  final int resetStuckJobs;
  final int deletedOrphanedJobs;

  int get totalActionsPerformed =>
      deletedFailedJobs + resetStuckJobs + deletedOrphanedJobs;
}

/// Job priority levels for processing order
enum JobPriority {
  /// Highest priority - user messages that need immediate delivery
  critical(0),

  /// High priority - other user-initiated actions
  high(1),

  /// Normal priority - background operations
  normal(2),

  /// Low priority - maintenance tasks
  low(3);

  const JobPriority(this.value);
  final int value;
}

class PendingJobRepository {
  PendingJobRepository(this._database);
  final AppDatabase _database;

  // Retry backoff configuration
  static const _initialRetryDelayMs = 1000; // 1 second
  static const _maxRetryDelayMs = 300000; // 5 minutes
  static const maxRetries = 5;

  // Health thresholds
  static const _stuckJobThresholdMs = 30 * 60 * 1000; // 30 minutes
  static const _maxHealthyPendingCount = 100;
  static const _maxHealthyFailedCount = 50;
  static const _maxHealthyAverageRetries = 2.0;

  /// Priority mapping for job types
  static JobPriority _getJobPriority(domain.JobType type) {
    switch (type) {
      // Critical - user-facing messages
      case domain.JobType.sendMessage:
      case domain.JobType.sendMediaMessage:
        return JobPriority.critical;

      // High - user-initiated actions
      case domain.JobType.editMessage:
      case domain.JobType.deleteMessage:
      case domain.JobType.forwardMessage:
      case domain.JobType.vote:
        return JobPriority.high;

      // Critical - room creation blocks user from messaging
      case domain.JobType.createRoom:
        return JobPriority.critical;

      // Normal - room operations
      case domain.JobType.updateRoom:
      case domain.JobType.updateRoomAvatar:
      case domain.JobType.updateRoomPermissions:
      case domain.JobType.addRoomMembers:
      case domain.JobType.removeRoomMembers:
      case domain.JobType.changeMemberRole:
      case domain.JobType.leaveRoom:
      case domain.JobType.createInviteLink:
      case domain.JobType.revokeInviteLink:
      case domain.JobType.useInviteLink:
      case domain.JobType.approveJoinRequest:
      case domain.JobType.rejectJoinRequest:
        return JobPriority.normal;

      // Low - background tasks
      case domain.JobType.deleteRoom:
      case domain.JobType.uploadFile:
      case domain.JobType.syncContacts:
      case domain.JobType.custom:
        return JobPriority.low;
    }
  }

  /// Add a job with automatic priority assignment
  Future<int> addJob(domain.JobType type, Map<String, dynamic> payload) async {
    final priority = _getJobPriority(type);
    final now = DateTime.now().millisecondsSinceEpoch;

    final id = await _database
        .into(_database.pendingJobs)
        .insert(
          PendingJobsCompanion.insert(
            type: type.name,
            payload: Value(jsonEncode(payload)),
            createdAt: Value(now),
            priority: Value(priority.value),
          ),
        );

    AppLogger.debug(
      'Job added to queue',
      data: {'jobId': id, 'type': type.name, 'priority': priority.name},
    );

    return id;
  }

  /// Get pending jobs in priority order
  ///
  /// Jobs are returned in order of:
  /// 1. Priority (critical first)
  /// 2. Creation time (oldest first within same priority)
  ///
  /// Only returns jobs that are ready for processing (nextRetryAt has passed)
  Future<List<domain.PendingJob>> getPendingJobs() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final query = _database.select(_database.pendingJobs)
      ..where(
        (t) =>
            t.status.equals('pending') &
            // Only get jobs ready for processing (nextRetryAt is null or in the past)
            (t.nextRetryAt.isNull() | t.nextRetryAt.isSmallerOrEqualValue(now)),
      )
      ..orderBy([
        // Priority order (lower value = higher priority)
        (t) => OrderingTerm.asc(t.priority),
        // Within same priority, oldest first
        (t) => OrderingTerm.asc(t.createdAt),
      ]);

    final results = await query.get();

    return results.map(_rowToJob).toList();
  }

  /// Watch for pending jobs reactively in priority order
  ///
  /// Emits whenever jobs are added, modified, or deleted
  /// Only returns jobs that are ready for processing (nextRetryAt has passed)
  Stream<List<domain.PendingJob>> watchPendingJobs() {
    // Use a custom expression for current time so the SQL filter is evaluated
    // at query time, not at stream setup time.
    const currentTimeMs = CustomExpression<int>(
      "(strftime('%s', 'now') * 1000)",
    );

    final query = _database.select(_database.pendingJobs)
      ..where(
        (t) =>
            t.status.equals('pending') &
            (t.nextRetryAt.isNull() |
                t.nextRetryAt.isSmallerOrEqual(currentTimeMs)),
      )
      ..orderBy([
        (t) => OrderingTerm.asc(t.priority),
        (t) => OrderingTerm.asc(t.createdAt),
      ]);

    return query.watch().map((results) => results.map(_rowToJob).toList());
  }

  /// Check if there are any pending jobs ready for processing
  Future<bool> hasPendingJobs() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final query = _database.selectOnly(_database.pendingJobs)
      ..where(
        _database.pendingJobs.status.equals('pending') &
            (_database.pendingJobs.nextRetryAt.isNull() |
                _database.pendingJobs.nextRetryAt.isSmallerOrEqualValue(now)),
      )
      ..addColumns([_database.pendingJobs.id])
      ..limit(1);
    final result = await query.get();
    return result.isNotEmpty;
  }

  /// Get count of pending jobs by status
  Future<int> getPendingJobCount() async {
    final query = _database.selectOnly(_database.pendingJobs)
      ..where(_database.pendingJobs.status.equals('pending'))
      ..addColumns([_database.pendingJobs.id.count()]);
    final result = await query.getSingle();
    return result.read(_database.pendingJobs.id.count()) ?? 0;
  }

  Future<void> deleteJob(int id) async {
    await (_database.delete(
      _database.pendingJobs,
    )..where((t) => t.id.equals(id))).go();

    AppLogger.debug('Job deleted from queue', data: {'jobId': id});
  }

  /// Defer a job without incrementing retry count.
  ///
  /// Use this for transient prerequisites (e.g. missing subscription ID)
  /// to avoid exhausting retries.
  Future<void> deferJob(
    int id, {
    Duration delay = const Duration(seconds: 5),
    String? reason,
  }) async {
    final nextRetryAt =
        DateTime.now().millisecondsSinceEpoch + delay.inMilliseconds;
    final errorData = reason != null
        ? jsonEncode({'message': reason, 'retryAt': nextRetryAt})
        : null;

    await (_database.update(
      _database.pendingJobs,
    )..where((t) => t.id.equals(id))).write(
      PendingJobsCompanion(
        nextRetryAt: Value(nextRetryAt),
        lastError: Value(errorData),
      ),
    );
  }

  /// Mark a job as permanently failed with an error message
  ///
  /// Use this when a job cannot be retried (e.g., invalid data, permission denied)
  Future<void> markJobFailed(
    int id, {
    String? errorMessage,
    String? errorCode,
  }) async {
    final errorData = <String, dynamic>{};
    if (errorMessage != null) errorData['message'] = errorMessage;
    if (errorCode != null) errorData['code'] = errorCode;
    errorData['failedAt'] = DateTime.now().millisecondsSinceEpoch;

    await (_database.update(
      _database.pendingJobs,
    )..where((t) => t.id.equals(id))).write(
      PendingJobsCompanion(
        status: const Value('failed'),
        lastError: Value(errorData.isNotEmpty ? jsonEncode(errorData) : null),
      ),
    );

    AppLogger.warning(
      'Job marked as permanently failed',
      data: {'jobId': id, 'errorCode': errorCode, 'errorMessage': errorMessage},
    );
  }

  /// Increment retry count and set next retry time with exponential backoff
  ///
  /// Returns true if job can still be retried, false if max retries reached
  Future<bool> incrementRetry(int id, {String? errorMessage}) async {
    // Get current retry count
    final job = await (_database.select(
      _database.pendingJobs,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (job == null) return false;

    final newRetryCount = job.retryCount + 1;

    if (newRetryCount >= maxRetries) {
      // Mark as failed instead of deleting - preserves history
      await markJobFailed(
        id,
        errorMessage: errorMessage ?? 'Max retries exceeded',
        errorCode: 'MAX_RETRIES',
      );
      return false;
    }

    // Calculate next retry time with exponential backoff + jitter
    final baseDelay = _initialRetryDelayMs * (1 << newRetryCount);
    final cappedDelay = min(baseDelay, _maxRetryDelayMs);
    final jitter = Random().nextInt(cappedDelay ~/ 4); // 0-25% jitter
    final nextRetryAt =
        DateTime.now().millisecondsSinceEpoch + cappedDelay + jitter;

    final errorData = errorMessage != null
        ? jsonEncode({
            'message': errorMessage,
            'retryAt': nextRetryAt,
            'retryCount': newRetryCount,
          })
        : null;

    await (_database.update(
      _database.pendingJobs,
    )..where((t) => t.id.equals(id))).write(
      PendingJobsCompanion(
        retryCount: Value(newRetryCount),
        nextRetryAt: Value(nextRetryAt),
        lastError: Value(errorData),
      ),
    );

    AppLogger.debug(
      'Job retry scheduled',
      data: {
        'jobId': id,
        'retryCount': newRetryCount,
        'nextRetryMs': cappedDelay + jitter,
      },
    );

    return true;
  }

  /// Get count of failed jobs for monitoring
  Future<int> getFailedJobCount() async {
    final query = _database.selectOnly(_database.pendingJobs)
      ..where(_database.pendingJobs.status.equals('failed'))
      ..addColumns([_database.pendingJobs.id.count()]);
    final result = await query.getSingle();
    return result.read(_database.pendingJobs.id.count()) ?? 0;
  }

  /// Watch for failed jobs count (reactive)
  /// Useful for showing notification badges
  Stream<int> watchFailedJobCount() {
    final query = _database.selectOnly(_database.pendingJobs)
      ..where(_database.pendingJobs.status.equals('failed'))
      ..addColumns([_database.pendingJobs.id.count()]);

    return query.watchSingle().map(
      (row) => row.read(_database.pendingJobs.id.count()) ?? 0,
    );
  }

  /// Get comprehensive health metrics for the job queue
  Future<JobQueueHealth> getQueueHealth() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final stuckThreshold = now - _stuckJobThresholdMs;

    // Get all jobs
    final allJobs = await _database.select(_database.pendingJobs).get();

    final pendingJobs = allJobs.where((j) => j.status == 'pending').toList();
    final failedJobs = allJobs.where((j) => j.status == 'failed').toList();

    // Calculate stuck jobs (pending for too long)
    final stuckJobs = pendingJobs
        .where((j) => (j.createdAt ?? now) < stuckThreshold)
        .length;

    // Calculate oldest pending job age
    final oldestPendingAge = pendingJobs.isEmpty
        ? 0
        : now - (pendingJobs.map((j) => j.createdAt ?? now).reduce(min));

    // Count by type
    final pendingByType = <String, int>{};
    for (final job in pendingJobs) {
      pendingByType[job.type] = (pendingByType[job.type] ?? 0) + 1;
    }

    final failedByType = <String, int>{};
    for (final job in failedJobs) {
      failedByType[job.type] = (failedByType[job.type] ?? 0) + 1;
    }

    // Calculate average retry count
    final totalRetries = pendingJobs.fold<int>(
      0,
      (sum, j) => sum + j.retryCount,
    );
    final avgRetries = pendingJobs.isEmpty
        ? 0.0
        : totalRetries / pendingJobs.length;

    // Determine health issues
    final issues = <String>[];
    if (pendingJobs.length > _maxHealthyPendingCount) {
      issues.add('High pending job count: ${pendingJobs.length}');
    }
    if (failedJobs.length > _maxHealthyFailedCount) {
      issues.add('High failed job count: ${failedJobs.length}');
    }
    if (stuckJobs > 0) {
      issues.add('Stuck jobs detected: $stuckJobs');
    }
    if (avgRetries > _maxHealthyAverageRetries) {
      issues.add('High average retry count: ${avgRetries.toStringAsFixed(1)}');
    }

    return JobQueueHealth(
      pendingCount: pendingJobs.length,
      failedCount: failedJobs.length,
      stuckCount: stuckJobs,
      oldestPendingAgeMs: oldestPendingAge,
      pendingByType: pendingByType,
      failedByType: failedByType,
      averageRetryCount: avgRetries,
      isHealthy: issues.isEmpty,
      healthIssues: issues,
    );
  }

  /// Perform startup cleanup operations
  ///
  /// This should be called when the app starts to ensure the queue is in a
  /// healthy state:
  /// - Clear old failed jobs (older than maxFailedAge)
  /// - Reset stuck jobs that may have been interrupted
  /// - Remove orphaned jobs that reference deleted rooms/messages
  Future<JobCleanupResult> performStartupCleanup({
    Duration maxFailedAge = const Duration(days: 7),
    bool resetStuckJobs = true,
  }) async {
    AppLogger.info('Starting job queue cleanup');
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Clear old failed jobs
    final failedCutoff = now - maxFailedAge.inMilliseconds;
    final deletedFailed =
        await (_database.delete(_database.pendingJobs)..where(
              (t) =>
                  t.status.equals('failed') &
                  t.createdAt.isSmallerOrEqualValue(failedCutoff),
            ))
            .go();

    // 2. Reset stuck jobs (jobs pending for too long)
    var resetCount = 0;
    if (resetStuckJobs) {
      final stuckThreshold = now - _stuckJobThresholdMs;
      final stuckJobs =
          await (_database.select(_database.pendingJobs)..where(
                (t) =>
                    t.status.equals('pending') &
                    t.createdAt.isSmallerOrEqualValue(stuckThreshold),
              ))
              .get();

      for (final job in stuckJobs) {
        // Reset the job's retry state so it can be processed again
        await (_database.update(
          _database.pendingJobs,
        )..where((t) => t.id.equals(job.id))).write(
          PendingJobsCompanion(
            retryCount: const Value(0),
            nextRetryAt: const Value(null),
            lastError: Value(
              jsonEncode({
                'message': 'Job reset during startup cleanup',
                'resetAt': now,
                'wasStuckSince': job.createdAt,
              }),
            ),
          ),
        );
        resetCount++;
      }
    }

    // 3. Count orphaned jobs (we don't delete them automatically as they
    // may be valid jobs that just failed to send)
    const orphanedCount =
        0; // Placeholder - implement orphan detection if needed

    final result = JobCleanupResult(
      deletedFailedJobs: deletedFailed,
      resetStuckJobs: resetCount,
      deletedOrphanedJobs: orphanedCount,
    );

    AppLogger.info(
      'Job queue cleanup completed',
      data: {
        'deletedFailedJobs': deletedFailed,
        'resetStuckJobs': resetCount,
        'deletedOrphanedJobs': orphanedCount,
      },
    );

    return result;
  }

  /// Clear old failed jobs (older than specified duration)
  Future<int> clearOldFailedJobs({
    Duration maxAge = const Duration(days: 7),
  }) async {
    final cutoff = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    final deleted =
        await (_database.delete(_database.pendingJobs)..where(
              (t) =>
                  t.status.equals('failed') &
                  t.createdAt.isSmallerOrEqualValue(cutoff),
            ))
            .go();

    if (deleted > 0) {
      AppLogger.info('Cleared old failed jobs', data: {'count': deleted});
    }

    return deleted;
  }

  /// Get all failed jobs for debugging/monitoring
  Future<List<domain.PendingJob>> getFailedJobs({int limit = 50}) async {
    final query = _database.select(_database.pendingJobs)
      ..where((t) => t.status.equals('failed'))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);

    final results = await query.get();
    return results.map(_rowToJob).toList();
  }

  /// Get details of recent failed jobs for user notification
  Future<List<domain.PendingJob>> getRecentFailedJobs({int limit = 10}) async {
    final query = _database.select(_database.pendingJobs)
      ..where((t) => t.status.equals('failed'))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);

    final results = await query.get();
    return results.map(_rowToJob).toList();
  }

  /// Retry a specific failed job
  ///
  /// Resets the job to pending status with reset retry count
  Future<bool> retryFailedJob(int id) async {
    final job = await (_database.select(
      _database.pendingJobs,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (job == null || job.status != 'failed') return false;

    await (_database.update(
      _database.pendingJobs,
    )..where((t) => t.id.equals(id))).write(
      PendingJobsCompanion(
        status: const Value('pending'),
        retryCount: const Value(0),
        nextRetryAt: const Value(null),
        lastError: Value(
          jsonEncode({
            'message': 'Manually retried',
            'retriedAt': DateTime.now().millisecondsSinceEpoch,
          }),
        ),
      ),
    );

    AppLogger.info('Failed job manually retried', data: {'jobId': id});
    return true;
  }

  /// Delete a specific failed job (give up on it)
  Future<void> deleteFailedJob(int id) async {
    await (_database.delete(
      _database.pendingJobs,
    )..where((t) => t.id.equals(id))).go();
  }

  /// Safely decode job payload with error handling for data corruption
  Map<String, dynamic> _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      AppLogger.warning(
        'Invalid job payload format: not a map',
        data: {'payload': payload},
      );
      return {};
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to decode job payload',
        error: e,
        stackTrace: stackTrace,
        data: {'payload': payload},
      );
      return {};
    }
  }

  /// Convert database row to domain model
  domain.PendingJob _rowToJob(PendingJob row) => domain.PendingJob(
    id: row.id,
    type: domain.JobType.values.firstWhere(
      (e) => e.name == row.type,
      orElse: () => domain.JobType.custom,
    ),
    payload: _decodePayload(row.payload),
    createdAt: row.createdAt ?? 0,
    retryCount: row.retryCount,
    status: row.status,
    nextRetryAt: row.nextRetryAt,
  );
}
