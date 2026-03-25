import 'package:freezed_annotation/freezed_annotation.dart';

part 'upload_progress.freezed.dart';
part 'upload_progress.g.dart';

/// State of an upload operation
enum UploadState {
  /// Upload has not started yet
  pending,

  /// Upload is actively in progress
  uploading,

  /// Upload completed successfully
  completed,

  /// Upload failed (can be retried)
  failed,

  /// Upload was cancelled by the user
  cancelled,

  /// Upload is paused (for resumable uploads)
  paused,
}

/// Represents the progress of a file upload operation
///
/// Tracks the upload state, progress percentage, and any errors
/// that occurred during upload. Used to update UI with real-time
/// upload feedback.
///
/// Example:
/// ```dart
/// final progress = UploadProgress(
///   localId: 'msg-123',
///   progress: 0.45,
///   state: UploadState.uploading,
///   fileName: 'photo.jpg',
///   totalBytes: 1024000,
///   uploadedBytes: 460800,
/// );
///
/// // Display progress
/// print('${(progress.progress * 100).toStringAsFixed(0)}%');
/// ```
@freezed
abstract class UploadProgress with _$UploadProgress {
  const factory UploadProgress({
    /// Local message ID for tracking
    required String localId,

    /// Progress percentage from 0.0 to 1.0
    @Default(0.0) double progress,

    /// Current state of the upload
    @Default(UploadState.pending) UploadState state,

    /// Error message if upload failed
    String? error,

    /// Original file name being uploaded
    String? fileName,

    /// Total size of the file in bytes
    int? totalBytes,

    /// Number of bytes uploaded so far
    @Default(0) int uploadedBytes,

    /// Current chunk index for chunked uploads
    @Default(0) int currentChunk,

    /// Total number of chunks for chunked uploads
    @Default(1) int totalChunks,

    /// Upload ID from server (for resumable uploads)
    String? uploadId,

    /// Timestamp when upload started
    int? startedAt,

    /// Timestamp when upload completed or failed
    int? completedAt,

    /// Number of retry attempts
    @Default(0) int retryCount,

    /// Whether this is a chunked upload
    @Default(false) bool isChunked,
  }) = _UploadProgress;

  factory UploadProgress.fromJson(Map<String, dynamic> json) =>
      _$UploadProgressFromJson(json);

  const UploadProgress._();

  /// Create a new pending upload progress
  factory UploadProgress.pending({
    required String localId,
    String? fileName,
    int? totalBytes,
  }) => UploadProgress(
    localId: localId,
    fileName: fileName,
    totalBytes: totalBytes,
    startedAt: DateTime.now().millisecondsSinceEpoch,
  );

  /// Create an uploading progress state
  factory UploadProgress.uploading({
    required String localId,
    required double progress,
    String? fileName,
    int? totalBytes,
    int uploadedBytes = 0,
    int currentChunk = 0,
    int totalChunks = 1,
    String? uploadId,
    bool isChunked = false,
  }) => UploadProgress(
    localId: localId,
    progress: progress,
    state: UploadState.uploading,
    fileName: fileName,
    totalBytes: totalBytes,
    uploadedBytes: uploadedBytes,
    currentChunk: currentChunk,
    totalChunks: totalChunks,
    uploadId: uploadId,
    isChunked: isChunked,
    startedAt: DateTime.now().millisecondsSinceEpoch,
  );

  /// Create a completed upload progress
  factory UploadProgress.completed({
    required String localId,
    String? fileName,
    int? totalBytes,
  }) => UploadProgress(
    localId: localId,
    progress: 1,
    state: UploadState.completed,
    fileName: fileName,
    totalBytes: totalBytes,
    uploadedBytes: totalBytes ?? 0,
    completedAt: DateTime.now().millisecondsSinceEpoch,
  );

  /// Create a failed upload progress
  factory UploadProgress.failed({
    required String localId,
    required String error,
    String? fileName,
    int? totalBytes,
    int uploadedBytes = 0,
    int retryCount = 0,
  }) => UploadProgress(
    localId: localId,
    state: UploadState.failed,
    error: error,
    fileName: fileName,
    totalBytes: totalBytes,
    uploadedBytes: uploadedBytes,
    retryCount: retryCount,
    completedAt: DateTime.now().millisecondsSinceEpoch,
  );

  /// Returns true if the upload is currently in progress
  bool get isInProgress => state == UploadState.uploading;

  /// Returns true if the upload can be retried
  bool get canRetry =>
      state == UploadState.failed || state == UploadState.cancelled;

  /// Returns true if the upload can be cancelled
  bool get canCancel =>
      state == UploadState.pending || state == UploadState.uploading;

  /// Returns true if the upload is done (completed, failed, or cancelled)
  bool get isDone =>
      state == UploadState.completed ||
      state == UploadState.failed ||
      state == UploadState.cancelled;

  /// Returns the progress percentage as an integer (0-100)
  int get progressPercent => (progress * 100).round();

  /// Returns the upload speed in bytes per second (if tracking timestamps)
  double? get uploadSpeed {
    if (startedAt == null || uploadedBytes == 0) return null;
    final elapsedMs = DateTime.now().millisecondsSinceEpoch - startedAt!;
    if (elapsedMs <= 0) return null;
    return uploadedBytes / (elapsedMs / 1000);
  }

  /// Returns estimated time remaining in seconds
  int? get estimatedTimeRemaining {
    final speed = uploadSpeed;
    if (speed == null || speed <= 0 || totalBytes == null) return null;
    final remaining = totalBytes! - uploadedBytes;
    return (remaining / speed).round();
  }

  /// Returns a human-readable progress string
  String get progressText {
    switch (state) {
      case UploadState.pending:
        return 'Waiting...';
      case UploadState.uploading:
        if (isChunked) {
          return 'Uploading chunk $currentChunk of $totalChunks ($progressPercent%)';
        }
        return 'Uploading... $progressPercent%';
      case UploadState.completed:
        return 'Upload complete';
      case UploadState.failed:
        return 'Upload failed${error != null ? ": $error" : ""}';
      case UploadState.cancelled:
        return 'Upload cancelled';
      case UploadState.paused:
        return 'Upload paused ($progressPercent%)';
    }
  }
}
