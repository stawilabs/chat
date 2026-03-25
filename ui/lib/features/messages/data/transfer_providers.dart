import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/files/content_resolver.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/sync/transfer_job_repository.dart';
import '../../notifications/transfer_notification_service.dart';
import '../domain/download_progress.dart';
import '../domain/upload_progress.dart';
import 'upload_progress_provider.dart';

part 'transfer_providers.g.dart';

// ============================================================================
// Download Progress Provider
// ============================================================================

/// Manages download progress state for multiple concurrent downloads
///
/// Uses [ContentResolver] for downloading files via MXC or legacy URLs.
///
/// Example:
/// ```dart
/// // Watch a specific download's progress
/// final progress = ref.watch(downloadProgressProvider)['dl-123'];
///
/// // Start a download
/// ref.read(downloadProgressProvider.notifier).startDownload(
///   fileUrl: 'https://files.example.com/v1/content/media_id',
///   downloadId: 'dl-123',
/// );
/// ```
@riverpod
class DownloadProgressNotifier extends _$DownloadProgressNotifier {
  @override
  Map<String, DownloadProgress> build() {
    return {};
  }

  ContentResolver get _resolver => ref.read(contentResolverProvider);

  /// Start a new download
  ///
  /// Parameters:
  /// - [fileUrl]: URL of the file to download (MXC URI or HTTPS URL)
  /// - [downloadId]: Unique download ID for tracking
  /// - [fileName]: Optional custom file name
  /// - [destinationPath]: Destination path to save the file
  /// - [roomId]: Optional room ID for context
  ///
  /// Returns [File] on success, null on failure
  Future<File?> startDownload({
    required String fileUrl,
    required String downloadId,
    required String destinationPath,
    String? fileName,
    String? roomId,
  }) async {
    AppLogger.info(
      'Starting download via provider',
      data: {'downloadId': downloadId, 'fileUrl': fileUrl},
    );

    // Extract file name from URL if not provided
    final extractedFileName =
        fileName ?? fileUrl.split('/').last.split('?').first;

    // Initialize progress state
    state = {
      ...state,
      downloadId: DownloadProgress.pending(
        downloadId: downloadId,
        fileName: extractedFileName,
        fileUrl: fileUrl,
        localPath: destinationPath,
        roomId: roomId,
      ),
    };

    try {
      // Update to downloading state
      state = {
        ...state,
        downloadId: DownloadProgress.downloading(
          downloadId: downloadId,
          progress: 0,
          fileName: extractedFileName,
          fileUrl: fileUrl,
          localPath: destinationPath,
          roomId: roomId,
        ),
      };

      // Use ContentResolver for the download
      final content = <String, dynamic>{'url': fileUrl};
      final file = await _resolver.resolveFileDownload(
        content,
        destinationPath,
      );

      if (file != null) {
        final fileSize = await file.length();
        state = {
          ...state,
          downloadId: DownloadProgress.completed(
            downloadId: downloadId,
            fileName: extractedFileName,
            fileUrl: fileUrl,
            localPath: destinationPath,
            totalBytes: fileSize,
            roomId: roomId,
          ),
        };

        AppLogger.info(
          'Download completed',
          data: {'downloadId': downloadId, 'fileName': extractedFileName},
        );
        return file;
      } else {
        state = {
          ...state,
          downloadId: DownloadProgress.failed(
            downloadId: downloadId,
            error: 'Download returned null',
            fileName: extractedFileName,
            fileUrl: fileUrl,
            localPath: destinationPath,
          ),
        };
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Download failed',
        error: e,
        stackTrace: stackTrace,
        data: {'downloadId': downloadId},
      );

      state = {
        ...state,
        downloadId: DownloadProgress.failed(
          downloadId: downloadId,
          error: e.toString(),
          fileName: extractedFileName,
          fileUrl: fileUrl,
          localPath: destinationPath,
        ),
      };
      return null;
    }
  }

  /// Cancel an active download
  bool cancelDownload(String downloadId) {
    final progress = state[downloadId];
    if (progress != null && progress.isInProgress) {
      state = {
        ...state,
        downloadId: progress.copyWith(
          state: DownloadState.cancelled,
          completedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      };
      AppLogger.info(
        'Download cancelled via provider',
        data: {'downloadId': downloadId},
      );
      return true;
    }
    return false;
  }

  /// Retry a failed download
  Future<File?> retryDownload({
    required String fileUrl,
    required String downloadId,
    required String destinationPath,
    String? fileName,
    String? roomId,
  }) async {
    AppLogger.info(
      'Retrying download via provider',
      data: {'downloadId': downloadId},
    );

    // Update state to pending
    final currentProgress = state[downloadId];
    if (currentProgress != null) {
      state = {
        ...state,
        downloadId: currentProgress.copyWith(
          state: DownloadState.pending,
          error: null,
        ),
      };
    }

    return startDownload(
      fileUrl: fileUrl,
      downloadId: downloadId,
      destinationPath: destinationPath,
      fileName: fileName,
      roomId: roomId,
    );
  }

  /// Clear progress for a completed download
  void clearProgress(String downloadId) {
    state = Map.from(state)..remove(downloadId);
  }

  /// Clear all completed or failed downloads
  void clearCompleted() {
    final activeDownloads = <String, DownloadProgress>{};
    for (final entry in state.entries) {
      if (!entry.value.isDone) {
        activeDownloads[entry.key] = entry.value;
      }
    }
    state = activeDownloads;
  }

  /// Get progress for a specific download
  DownloadProgress? getProgress(String downloadId) => state[downloadId];

  /// Check if there are any active downloads
  bool get hasActiveDownloads => state.values.any((p) => p.isInProgress);

  /// Get count of active downloads
  int get activeDownloadCount =>
      state.values.where((p) => p.isInProgress).length;
}

// ============================================================================
// Single Download Progress Provider
// ============================================================================

/// Provider for a specific download's progress
@riverpod
DownloadProgress? singleDownloadProgress(Ref ref, String downloadId) {
  final allDownloads = ref.watch(downloadProgressProvider);
  return allDownloads[downloadId];
}

/// Provider for checking if a specific download is active
@riverpod
bool isDownloading(Ref ref, String downloadId) {
  final progress = ref.watch(singleDownloadProgressProvider(downloadId));
  return progress?.isInProgress ?? false;
}

/// Provider for active download count
@riverpod
int activeDownloadCount(Ref ref) {
  final downloads = ref.watch(downloadProgressProvider);
  return downloads.values.where((p) => p.isInProgress).length;
}

/// Provider for total download progress across all active downloads
@riverpod
double totalDownloadProgress(Ref ref) {
  final downloads = ref.watch(downloadProgressProvider);
  final activeDownloads = downloads.values
      .where((p) => p.isInProgress)
      .toList();

  if (activeDownloads.isEmpty) return 0;

  var totalBytes = 0;
  var downloadedBytesTotal = 0;

  for (final download in activeDownloads) {
    final downloadTotal = download.totalBytes;
    if (downloadTotal != null) {
      totalBytes += downloadTotal;
    }
    downloadedBytesTotal += download.downloadedBytes;
  }

  if (totalBytes == 0) return 0;
  return downloadedBytesTotal / totalBytes;
}

// ============================================================================
// Transfer Queue Service
// ============================================================================

/// Service for managing the unified transfer queue for uploads and downloads
///
/// Coordinates transfer jobs, prioritizes uploads over downloads,
/// and handles notifications for transfer progress.
class TransferQueueService {
  TransferQueueService(this._repository);

  final TransferJobRepository _repository;

  /// Queue an upload job
  Future<int> queueUpload({
    required File file,
    required String localId,
    required String roomId,
    String? mimeType,
    int priority = TransferPriority.high,
  }) async {
    final fileName = file.path.split('/').last;
    final totalSize = await file.length();

    final jobId = await _repository.createUploadJob(
      referenceId: localId,
      roomId: roomId,
      localPath: file.path,
      fileName: fileName,
      totalSize: totalSize,
      mimeType: mimeType,
      priority: priority,
    );

    AppLogger.info(
      'Upload queued',
      data: {'jobId': jobId, 'localId': localId, 'fileName': fileName},
    );

    return jobId;
  }

  /// Queue a download job
  Future<int> queueDownload({
    required String fileUrl,
    required String downloadId,
    required String roomId,
    required String localPath,
    required String fileName,
    required int totalSize,
    String? mimeType,
    int priority = TransferPriority.normal,
  }) async {
    final jobId = await _repository.createDownloadJob(
      referenceId: downloadId,
      roomId: roomId,
      fileUrl: fileUrl,
      localPath: localPath,
      fileName: fileName,
      totalSize: totalSize,
      mimeType: mimeType,
      priority: priority,
    );

    AppLogger.info(
      'Download queued',
      data: {'jobId': jobId, 'downloadId': downloadId, 'fileName': fileName},
    );

    return jobId;
  }

  /// Cancel a queued job
  Future<void> cancelJob(int jobId) async {
    await _repository.deleteJob(jobId);
    AppLogger.info('Transfer job cancelled', data: {'jobId': jobId});
  }

  /// Cancel a job by reference ID
  Future<void> cancelJobByReferenceId(String referenceId) async {
    await _repository.deleteJobByReferenceId(referenceId);
  }

  /// Pause a job
  Future<void> pauseJob(int jobId) async {
    await _repository.markPaused(jobId);
  }

  /// Resume a job
  Future<void> resumeJob(int jobId) async {
    await _repository.resetToPending(jobId);
  }

  /// Retry a failed job
  Future<void> retryJob(int jobId) async {
    await _repository.resetToPending(jobId);
  }

  /// Update job priority
  Future<void> updatePriority(int jobId, int priority) async {
    await _repository.updatePriority(jobId, priority);
  }

  /// Clear completed jobs
  Future<int> clearCompleted() async {
    return _repository.deleteCompletedJobs();
  }

  /// Clear failed jobs
  Future<int> clearFailed() async {
    return _repository.deleteFailedJobs();
  }
}

/// Provider for TransferQueueService
@riverpod
TransferQueueService transferQueueService(Ref ref) {
  final repository = ref.watch(transferJobRepositoryProvider);
  return TransferQueueService(repository);
}

// ============================================================================
// Transfer Statistics Providers
// ============================================================================

/// Provider for pending upload count
@riverpod
Future<int> pendingUploadCount(Ref ref) async {
  final repository = ref.watch(transferJobRepositoryProvider);
  return repository.getPendingUploadCount();
}

/// Provider for pending download count
@riverpod
Future<int> pendingDownloadCount(Ref ref) async {
  final repository = ref.watch(transferJobRepositoryProvider);
  return repository.getPendingDownloadCount();
}

/// Provider for total pending bytes
@riverpod
Future<int> totalPendingBytes(Ref ref) async {
  final repository = ref.watch(transferJobRepositoryProvider);
  return repository.getTotalPendingBytes();
}

/// Provider for total transferred bytes
@riverpod
Future<int> totalTransferredBytes(Ref ref) async {
  final repository = ref.watch(transferJobRepositoryProvider);
  return repository.getTotalTransferredBytes();
}

/// Provider for checking if there are any active transfers
@riverpod
bool hasActiveTransfers(Ref ref) {
  final uploadProgress = ref.watch(uploadProgressProvider);
  final downloadProgress = ref.watch(downloadProgressProvider);

  final hasActiveUploads = uploadProgress.values.any((p) => p.isInProgress);
  final hasActiveDownloads = downloadProgress.values.any((p) => p.isInProgress);

  return hasActiveUploads || hasActiveDownloads;
}

/// Provider for overall transfer progress (uploads + downloads)
@riverpod
double overallTransferProgress(Ref ref) {
  final uploadProgress = ref.watch(totalUploadProgressProvider);
  final downloadProgress = ref.watch(totalDownloadProgressProvider);

  final uploadCount = ref.watch(activeUploadCountProvider);
  final downloadCount = ref.watch(activeDownloadCountProvider);

  final totalCount = uploadCount + downloadCount;
  if (totalCount == 0) return 0;

  return (uploadProgress * uploadCount + downloadProgress * downloadCount) /
      totalCount;
}

// ============================================================================
// Transfer Notification Integration
// ============================================================================

/// Provider that automatically shows/updates transfer notifications
///
/// This provider watches upload and download progress state notifiers
/// and shows appropriate notifications.
@riverpod
class TransferNotifications extends _$TransferNotifications {
  Map<String, UploadProgress> _prevUploads = {};
  Map<String, DownloadProgress> _prevDownloads = {};

  @override
  bool build() {
    final notificationService = ref.watch(transferNotificationServiceProvider);

    // Initialize notification service if not already
    if (!notificationService.isInitialized) {
      notificationService.initialize(onAction: _handleNotificationAction);
    }

    // Watch upload and download progress for changes
    final uploads = ref.watch(uploadProgressProvider);
    final downloads = ref.watch(downloadProgressProvider);

    // Process upload state changes
    for (final entry in uploads.entries) {
      final prev = _prevUploads[entry.key];
      if (prev?.state != entry.value.state ||
          prev?.progress != entry.value.progress) {
        _handleUploadProgress(entry.value, notificationService);
      }
    }

    // Process download state changes
    for (final entry in downloads.entries) {
      final prev = _prevDownloads[entry.key];
      if (prev?.state != entry.value.state ||
          prev?.progress != entry.value.progress) {
        _handleDownloadProgress(entry.value, notificationService);
      }
    }

    _prevUploads = Map.of(uploads);
    _prevDownloads = Map.of(downloads);

    return true;
  }

  void _handleUploadProgress(
    UploadProgress progress,
    TransferNotificationService service,
  ) {
    switch (progress.state) {
      case UploadState.uploading:
        service.showUploadProgress(
          uploadId: progress.localId,
          fileName: progress.fileName ?? 'File',
          progress: progress.progress,
          uploadedBytes: progress.uploadedBytes,
          totalBytes: progress.totalBytes ?? 0,
        );
      case UploadState.completed:
        service.showUploadComplete(
          uploadId: progress.localId,
          fileName: progress.fileName ?? 'File',
          totalBytes: progress.totalBytes,
        );
      case UploadState.failed:
        service.showUploadFailed(
          uploadId: progress.localId,
          fileName: progress.fileName ?? 'File',
          error: progress.error,
        );
      case UploadState.cancelled:
        service.cancelUploadNotification(progress.localId);
      case UploadState.pending:
      case UploadState.paused:
        // No notification update needed
        break;
    }
  }

  void _handleDownloadProgress(
    DownloadProgress progress,
    TransferNotificationService service,
  ) {
    switch (progress.state) {
      case DownloadState.downloading:
        service.showDownloadProgress(
          downloadId: progress.downloadId,
          fileName: progress.fileName ?? 'File',
          progress: progress.progress,
          downloadedBytes: progress.downloadedBytes,
          totalBytes: progress.totalBytes ?? 0,
        );
      case DownloadState.completed:
        service.showDownloadComplete(
          downloadId: progress.downloadId,
          fileName: progress.fileName ?? 'File',
          localPath: progress.localPath,
          totalBytes: progress.totalBytes,
        );
      case DownloadState.failed:
        service.showDownloadFailed(
          downloadId: progress.downloadId,
          fileName: progress.fileName ?? 'File',
          error: progress.error,
        );
      case DownloadState.cancelled:
        service.cancelDownloadNotification(progress.downloadId);
      case DownloadState.pending:
      case DownloadState.paused:
        // No notification update needed
        break;
    }
  }

  void _handleNotificationAction(String actionId, String transferId) {
    AppLogger.info(
      'Transfer notification action',
      data: {'actionId': actionId, 'transferId': transferId},
    );

    switch (actionId) {
      case TransferNotificationActions.cancelUpload:
        ref.read(uploadProgressProvider.notifier).cancelUpload(transferId);
      case TransferNotificationActions.cancelDownload:
        ref.read(downloadProgressProvider.notifier).cancelDownload(transferId);
      case TransferNotificationActions.openFile:
        AppLogger.info('Open file requested', data: {'path': transferId});
    }
  }
}

/// Provider to activate transfer notifications
@riverpod
bool transferNotificationsActive(Ref ref) {
  ref.watch(transferNotificationsProvider);
  return true;
}
