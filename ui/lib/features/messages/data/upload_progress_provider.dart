import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/files/files_upload_service.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/upload_progress.dart';

part 'upload_progress_provider.g.dart';

/// Manages upload progress state for multiple concurrent uploads
///
/// Provides methods to start, cancel, retry, and track uploads
/// using [FilesUploadService] for proto-based streaming uploads.
///
/// Example:
/// ```dart
/// // Watch a specific upload's progress
/// final progress = ref.watch(uploadProgressProvider)['msg-123'];
///
/// // Start an upload
/// ref.read(uploadProgressProvider.notifier).startUpload(file, 'msg-123');
/// ```
@riverpod
class UploadProgressNotifier extends _$UploadProgressNotifier {
  @override
  Map<String, UploadProgress> build() {
    return {};
  }

  FilesUploadService get _uploadService => ref.read(filesUploadServiceProvider);

  /// Start a new upload
  ///
  /// Parameters:
  /// - [file]: File to upload
  /// - [localId]: Local message ID for tracking
  /// - [mimeType]: Optional MIME type
  ///
  /// Returns [FilesUploadResult] when complete
  Future<FilesUploadResult> startUpload(
    File file, {
    required String localId,
    String? mimeType,
  }) async {
    AppLogger.info(
      'Starting upload via provider',
      data: {'localId': localId, 'path': file.path},
    );

    // Initialize progress state
    final fileName = file.path.split('/').last;
    final fileSize = await file.length();

    state = {
      ...state,
      localId: UploadProgress.pending(
        localId: localId,
        fileName: fileName,
        totalBytes: fileSize,
      ),
    };

    try {
      // Start the upload with progress tracking
      final result = await _uploadService.uploadFile(
        file,
        mimeType: mimeType,
        onProgress: (progress) {
          final uploadedBytes = (progress * fileSize).toInt();
          state = {
            ...state,
            localId: UploadProgress.uploading(
              localId: localId,
              progress: progress,
              fileName: fileName,
              totalBytes: fileSize,
              uploadedBytes: uploadedBytes,
            ),
          };
        },
      );

      // Update progress to completed
      state = {
        ...state,
        localId: UploadProgress.completed(
          localId: localId,
          fileName: fileName,
          totalBytes: fileSize,
        ),
      };

      return result;
    } catch (e) {
      // Update progress to failed
      state = {
        ...state,
        localId: UploadProgress.failed(
          localId: localId,
          error: e.toString(),
          fileName: fileName,
          totalBytes: fileSize,
        ),
      };
      rethrow;
    }
  }

  /// Retry a failed upload
  ///
  /// Parameters:
  /// - [file]: File to retry uploading
  /// - [localId]: Local message ID
  /// - [mimeType]: Optional MIME type
  ///
  /// Returns [FilesUploadResult] when complete
  Future<FilesUploadResult> retryUpload(
    File file, {
    required String localId,
    String? mimeType,
  }) async {
    AppLogger.info('Retrying upload via provider', data: {'localId': localId});

    // Update state to pending
    final currentProgress = state[localId];
    if (currentProgress != null) {
      state = {
        ...state,
        localId: currentProgress.copyWith(
          state: UploadState.pending,
          error: null,
        ),
      };
    }

    return startUpload(file, localId: localId, mimeType: mimeType);
  }

  /// Cancel an active upload
  ///
  /// Marks the upload as cancelled in the progress state.
  /// Note: The underlying proto stream cannot be cancelled mid-transfer,
  /// but the state is updated so the UI reflects the cancellation.
  bool cancelUpload(String localId) {
    final progress = state[localId];
    if (progress != null && progress.isInProgress) {
      state = {
        ...state,
        localId: progress.copyWith(
          state: UploadState.cancelled,
          completedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      };
      AppLogger.info(
        'Upload cancelled via provider',
        data: {'localId': localId},
      );
      return true;
    }
    return false;
  }

  /// Clear progress for a completed upload
  void clearProgress(String localId) {
    state = Map.from(state)..remove(localId);
  }

  /// Clear all completed or failed uploads
  void clearCompleted() {
    final activeUploads = <String, UploadProgress>{};
    for (final entry in state.entries) {
      if (!entry.value.isDone) {
        activeUploads[entry.key] = entry.value;
      }
    }
    state = activeUploads;
  }

  /// Get progress for a specific upload
  UploadProgress? getProgress(String localId) => state[localId];

  /// Check if there are any active uploads
  bool get hasActiveUploads => state.values.any((p) => p.isInProgress);

  /// Get count of active uploads
  int get activeUploadCount => state.values.where((p) => p.isInProgress).length;
}

/// Provider for a specific upload's progress
///
/// Example:
/// ```dart
/// final progress = ref.watch(singleUploadProgressProvider('msg-123'));
/// if (progress != null && progress.isInProgress) {
///   // Show progress indicator
/// }
/// ```
@riverpod
UploadProgress? singleUploadProgress(Ref ref, String localId) {
  final allUploads = ref.watch(uploadProgressProvider);
  return allUploads[localId];
}

/// Provider for checking if a specific upload is active
@riverpod
bool isUploading(Ref ref, String localId) {
  final progress = ref.watch(singleUploadProgressProvider(localId));
  return progress?.isInProgress ?? false;
}

/// Provider for active upload count
@riverpod
int activeUploadCount(Ref ref) {
  final uploads = ref.watch(uploadProgressProvider);
  return uploads.values.where((p) => p.isInProgress).length;
}

/// Provider for total upload progress across all active uploads
@riverpod
double totalUploadProgress(Ref ref) {
  final uploads = ref.watch(uploadProgressProvider);
  final activeUploads = uploads.values.where((p) => p.isInProgress).toList();

  if (activeUploads.isEmpty) return 0;

  var totalBytes = 0;
  var uploadedBytesTotal = 0;

  for (final upload in activeUploads) {
    final uploadTotal = upload.totalBytes;
    if (uploadTotal != null) {
      totalBytes += uploadTotal;
    }
    uploadedBytesTotal += upload.uploadedBytes;
  }

  if (totalBytes == 0) return 0;
  return uploadedBytesTotal / totalBytes;
}
