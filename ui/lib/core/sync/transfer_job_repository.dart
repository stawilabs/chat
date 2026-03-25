import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../logging/app_logger.dart';

/// Transfer type constants
class TransferType {
  static const String upload = 'upload';
  static const String download = 'download';
}

/// Transfer status constants
class TransferStatus {
  static const String pending = 'pending';
  static const String active = 'active';
  static const String paused = 'paused';
  static const String completed = 'completed';
  static const String failed = 'failed';
}

/// Priority levels for transfers
/// Lower values = higher priority
class TransferPriority {
  static const int critical = 0;
  static const int high = 1;
  static const int normal = 2;
  static const int low = 3;
}

/// Maximum retry attempts before marking as failed
const int maxTransferRetries = 5;

/// Base delay for exponential backoff (milliseconds)
const int baseRetryDelayMs = 1000;

/// Maximum delay between retries (5 minutes)
const int maxRetryDelayMs = 5 * 60 * 1000;

/// Repository for managing transfer jobs (uploads and downloads)
///
/// Provides CRUD operations, priority queue management, and retry logic
/// for file transfers. Supports both uploads and downloads in a unified queue.
///
/// Example:
/// ```dart
/// final repo = ref.read(transferJobRepositoryProvider);
///
/// // Create an upload job
/// await repo.createUploadJob(
///   referenceId: 'msg-123',
///   roomId: 'room-456',
///   localPath: '/path/to/file.jpg',
///   fileName: 'photo.jpg',
///   totalSize: 1024000,
/// );
///
/// // Get pending jobs
/// final jobs = await repo.getPendingJobs();
/// ```
class TransferJobRepository {
  TransferJobRepository(this._db);

  final AppDatabase _db;

  // ============================================================================
  // Create Operations
  // ============================================================================

  /// Create a new upload job
  ///
  /// Uploads are given priority 1 (high) by default.
  Future<int> createUploadJob({
    required String referenceId,
    required String roomId,
    required String localPath,
    required String fileName,
    required int totalSize,
    String? fileUrl,
    String? mimeType,
    int priority = TransferPriority.high,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final job = TransferJobsCompanion.insert(
      transferType: TransferType.upload,
      referenceId: referenceId,
      roomId: roomId,
      fileUrl: fileUrl ?? '',
      localPath: localPath,
      fileName: fileName,
      totalSize: totalSize,
      mimeType: Value(mimeType),
      priority: Value(priority),
      status: const Value(TransferStatus.pending),
      createdAt: now,
    );

    final id = await _db.into(_db.transferJobs).insert(job);

    AppLogger.info(
      'Upload job created',
      data: {
        'id': id,
        'referenceId': referenceId,
        'fileName': fileName,
        'totalSize': totalSize,
      },
    );

    return id;
  }

  /// Create a new download job
  ///
  /// Downloads are given priority 2 (normal) by default.
  Future<int> createDownloadJob({
    required String referenceId,
    required String roomId,
    required String fileUrl,
    required String localPath,
    required String fileName,
    required int totalSize,
    String? mimeType,
    int priority = TransferPriority.normal,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final job = TransferJobsCompanion.insert(
      transferType: TransferType.download,
      referenceId: referenceId,
      roomId: roomId,
      fileUrl: fileUrl,
      localPath: localPath,
      fileName: fileName,
      totalSize: totalSize,
      mimeType: Value(mimeType),
      priority: Value(priority),
      status: const Value(TransferStatus.pending),
      createdAt: now,
    );

    final id = await _db.into(_db.transferJobs).insert(job);

    AppLogger.info(
      'Download job created',
      data: {
        'id': id,
        'referenceId': referenceId,
        'fileUrl': fileUrl,
        'fileName': fileName,
      },
    );

    return id;
  }

  // ============================================================================
  // Read Operations
  // ============================================================================

  /// Get a transfer job by ID
  Future<TransferJob?> getJob(int id) async {
    final query = _db.select(_db.transferJobs)..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }

  /// Get a transfer job by reference ID
  Future<TransferJob?> getJobByReferenceId(String referenceId) async {
    final query = _db.select(_db.transferJobs)
      ..where((t) => t.referenceId.equals(referenceId));
    return query.getSingleOrNull();
  }

  /// Get all pending jobs ordered by priority
  ///
  /// Returns jobs that are ready to be processed (pending status,
  /// either no retry time set or retry time has passed).
  /// Uploads are prioritized over downloads.
  Future<List<TransferJob>> getPendingJobs({int limit = 10}) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final query = _db.select(_db.transferJobs)
      ..where(
        (t) =>
            t.status.equals(TransferStatus.pending) &
            (t.nextRetryAt.isNull() | t.nextRetryAt.isSmallerOrEqualValue(now)),
      )
      ..orderBy([
        (t) => OrderingTerm.asc(t.priority),
        (t) => OrderingTerm.asc(t.createdAt),
      ])
      ..limit(limit);

    return query.get();
  }

  /// Watch pending jobs as a stream
  ///
  /// Emits whenever the pending jobs list changes.
  /// Uses SQLite's strftime to compute current time at query evaluation,
  /// ensuring jobs become visible when their retry time passes.
  Stream<List<TransferJob>> watchPendingJobs({int limit = 10}) {
    // Use SQLite expression to get current timestamp at query time
    // strftime('%s', 'now') returns Unix timestamp in seconds, multiply by 1000 for ms
    const currentTimeMs = CustomExpression<int>(
      "(strftime('%s', 'now') * 1000)",
    );

    final query = _db.select(_db.transferJobs)
      ..where(
        (t) =>
            t.status.equals(TransferStatus.pending) &
            (t.nextRetryAt.isNull() |
                t.nextRetryAt.isSmallerOrEqual(currentTimeMs)),
      )
      ..orderBy([
        (t) => OrderingTerm.asc(t.priority),
        (t) => OrderingTerm.asc(t.createdAt),
      ])
      ..limit(limit);

    return query.watch();
  }

  /// Get all active (currently processing) jobs
  Future<List<TransferJob>> getActiveJobs() async {
    final query = _db.select(_db.transferJobs)
      ..where((t) => t.status.equals(TransferStatus.active));
    return query.get();
  }

  /// Get all jobs for a specific room
  Future<List<TransferJob>> getJobsByRoom(String roomId) async {
    final query = _db.select(_db.transferJobs)
      ..where((t) => t.roomId.equals(roomId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.get();
  }

  /// Watch all jobs for a specific room
  Stream<List<TransferJob>> watchJobsByRoom(String roomId) {
    final query = _db.select(_db.transferJobs)
      ..where((t) => t.roomId.equals(roomId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch();
  }

  /// Get pending upload count
  Future<int> getPendingUploadCount() async {
    final query = _db.selectOnly(_db.transferJobs)
      ..addColumns([_db.transferJobs.id.count()])
      ..where(
        _db.transferJobs.transferType.equals(TransferType.upload) &
            (_db.transferJobs.status.equals(TransferStatus.pending) |
                _db.transferJobs.status.equals(TransferStatus.active)),
      );
    final result = await query.getSingle();
    return result.read(_db.transferJobs.id.count()) ?? 0;
  }

  /// Get pending download count
  Future<int> getPendingDownloadCount() async {
    final query = _db.selectOnly(_db.transferJobs)
      ..addColumns([_db.transferJobs.id.count()])
      ..where(
        _db.transferJobs.transferType.equals(TransferType.download) &
            (_db.transferJobs.status.equals(TransferStatus.pending) |
                _db.transferJobs.status.equals(TransferStatus.active)),
      );
    final result = await query.getSingle();
    return result.read(_db.transferJobs.id.count()) ?? 0;
  }

  // ============================================================================
  // Update Operations
  // ============================================================================

  /// Update transfer progress
  Future<void> updateProgress({
    required int id,
    required int transferredSize,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.transferJobs)..where((t) => t.id.equals(id))).write(
      TransferJobsCompanion(
        transferredSize: Value(transferredSize),
        updatedAt: Value(now),
      ),
    );
  }

  /// Mark job as active (currently processing)
  Future<void> markActive(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.transferJobs)..where((t) => t.id.equals(id))).write(
      TransferJobsCompanion(
        status: const Value(TransferStatus.active),
        updatedAt: Value(now),
      ),
    );

    AppLogger.debug('Transfer job marked active', data: {'id': id});
  }

  /// Mark job as paused
  Future<void> markPaused(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.transferJobs)..where((t) => t.id.equals(id))).write(
      TransferJobsCompanion(
        status: const Value(TransferStatus.paused),
        updatedAt: Value(now),
      ),
    );

    AppLogger.debug('Transfer job paused', data: {'id': id});
  }

  /// Mark job as completed
  Future<void> markCompleted(int id, {String? fileUrl}) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.transferJobs)..where((t) => t.id.equals(id))).write(
      TransferJobsCompanion(
        status: const Value(TransferStatus.completed),
        fileUrl: fileUrl != null ? Value(fileUrl) : const Value.absent(),
        updatedAt: Value(now),
      ),
    );

    AppLogger.info('Transfer job completed', data: {'id': id});
  }

  /// Mark job as failed with retry logic
  ///
  /// If retry count hasn't exceeded max, schedules a retry with exponential backoff.
  /// Otherwise marks the job as permanently failed.
  Future<void> markFailed(int id, String error) async {
    final job = await getJob(id);
    if (job == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final newRetryCount = job.retryCount + 1;

    if (newRetryCount >= maxTransferRetries) {
      // Permanently failed
      await (_db.update(_db.transferJobs)..where((t) => t.id.equals(id))).write(
        TransferJobsCompanion(
          status: const Value(TransferStatus.failed),
          retryCount: Value(newRetryCount),
          lastError: Value(error),
          updatedAt: Value(now),
        ),
      );

      AppLogger.warning(
        'Transfer job permanently failed',
        data: {'id': id, 'retryCount': newRetryCount, 'error': error},
      );
    } else {
      // Schedule retry with exponential backoff
      final delay = _calculateRetryDelay(newRetryCount);
      final nextRetryAt = now + delay;

      await (_db.update(_db.transferJobs)..where((t) => t.id.equals(id))).write(
        TransferJobsCompanion(
          status: const Value(TransferStatus.pending),
          retryCount: Value(newRetryCount),
          lastError: Value(error),
          nextRetryAt: Value(nextRetryAt),
          updatedAt: Value(now),
        ),
      );

      AppLogger.info(
        'Transfer job scheduled for retry',
        data: {
          'id': id,
          'retryCount': newRetryCount,
          'nextRetryIn': '${delay / 1000}s',
        },
      );
    }
  }

  /// Update file URL after successful upload
  Future<void> updateFileUrl(int id, String fileUrl) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.transferJobs)..where((t) => t.id.equals(id))).write(
      TransferJobsCompanion(fileUrl: Value(fileUrl), updatedAt: Value(now)),
    );
  }

  /// Reset job to pending status (for manual retry)
  Future<void> resetToPending(int id) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.transferJobs)..where((t) => t.id.equals(id))).write(
      TransferJobsCompanion(
        status: const Value(TransferStatus.pending),
        nextRetryAt: const Value(null),
        updatedAt: Value(now),
      ),
    );

    AppLogger.debug('Transfer job reset to pending', data: {'id': id});
  }

  /// Update job priority
  Future<void> updatePriority(int id, int priority) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.transferJobs)..where((t) => t.id.equals(id))).write(
      TransferJobsCompanion(priority: Value(priority), updatedAt: Value(now)),
    );
  }

  // ============================================================================
  // Delete Operations
  // ============================================================================

  /// Delete a transfer job by ID
  Future<void> deleteJob(int id) async {
    await (_db.delete(_db.transferJobs)..where((t) => t.id.equals(id))).go();
    AppLogger.debug('Transfer job deleted', data: {'id': id});
  }

  /// Delete a transfer job by reference ID
  Future<void> deleteJobByReferenceId(String referenceId) async {
    await (_db.delete(
      _db.transferJobs,
    )..where((t) => t.referenceId.equals(referenceId))).go();
    AppLogger.debug(
      'Transfer job deleted by reference',
      data: {'referenceId': referenceId},
    );
  }

  /// Delete all completed jobs
  Future<int> deleteCompletedJobs() async {
    final count = await (_db.delete(
      _db.transferJobs,
    )..where((t) => t.status.equals(TransferStatus.completed))).go();
    AppLogger.info('Deleted completed transfer jobs', data: {'count': count});
    return count;
  }

  /// Delete all failed jobs
  Future<int> deleteFailedJobs() async {
    final count = await (_db.delete(
      _db.transferJobs,
    )..where((t) => t.status.equals(TransferStatus.failed))).go();
    AppLogger.info('Deleted failed transfer jobs', data: {'count': count});
    return count;
  }

  /// Delete all jobs for a room
  Future<int> deleteJobsByRoom(String roomId) async {
    final count = await (_db.delete(
      _db.transferJobs,
    )..where((t) => t.roomId.equals(roomId))).go();
    AppLogger.info(
      'Deleted transfer jobs for room',
      data: {'roomId': roomId, 'count': count},
    );
    return count;
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Calculate retry delay using exponential backoff with jitter
  int _calculateRetryDelay(int retryCount) {
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, ...
    final exponentialDelay = baseRetryDelayMs * pow(2, retryCount - 1);

    // Cap at max delay
    final cappedDelay = min(exponentialDelay, maxRetryDelayMs).toInt();

    // Add jitter (0-25% of delay)
    final jitter = Random().nextDouble() * 0.25 * cappedDelay;

    return cappedDelay + jitter.toInt();
  }

  /// Check if there are any pending transfers
  Future<bool> hasPendingTransfers() async {
    final count =
        await getPendingUploadCount() + await getPendingDownloadCount();
    return count > 0;
  }

  /// Get total bytes to transfer across all pending jobs
  Future<int> getTotalPendingBytes() async {
    final query = _db.selectOnly(_db.transferJobs)
      ..addColumns([_db.transferJobs.totalSize.sum()])
      ..where(
        _db.transferJobs.status.equals(TransferStatus.pending) |
            _db.transferJobs.status.equals(TransferStatus.active),
      );
    final result = await query.getSingle();
    return result.read(_db.transferJobs.totalSize.sum())?.toInt() ?? 0;
  }

  /// Get total bytes transferred across all pending jobs
  Future<int> getTotalTransferredBytes() async {
    final query = _db.selectOnly(_db.transferJobs)
      ..addColumns([_db.transferJobs.transferredSize.sum()])
      ..where(
        _db.transferJobs.status.equals(TransferStatus.pending) |
            _db.transferJobs.status.equals(TransferStatus.active),
      );
    final result = await query.getSingle();
    return result.read(_db.transferJobs.transferredSize.sum())?.toInt() ?? 0;
  }
}

/// Provider for TransferJobRepository
final transferJobRepositoryProvider = Provider<TransferJobRepository>((ref) {
  return TransferJobRepository(AppDatabase.instance);
});
