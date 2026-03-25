import 'package:freezed_annotation/freezed_annotation.dart';

part 'download_progress.freezed.dart';
part 'download_progress.g.dart';

/// State of a download operation
enum DownloadState {
  /// Download has not started yet
  pending,

  /// Download is actively in progress
  downloading,

  /// Download completed successfully
  completed,

  /// Download failed (can be retried)
  failed,

  /// Download was cancelled by the user
  cancelled,

  /// Download is paused (for resumable downloads)
  paused,
}

/// Represents the progress of a file download operation
///
/// Tracks the download state, progress percentage, and any errors
/// that occurred during download. Used to update UI with real-time
/// download feedback.
///
/// Example:
/// ```dart
/// final progress = DownloadProgress(
///   downloadId: 'dl-123',
///   progress: 0.45,
///   state: DownloadState.downloading,
///   fileName: 'photo.jpg',
///   fileUrl: 'https://example.com/photo.jpg',
///   totalBytes: 1024000,
///   downloadedBytes: 460800,
/// );
///
/// // Display progress
/// print('${(progress.progress * 100).toStringAsFixed(0)}%');
/// ```
@freezed
abstract class DownloadProgress with _$DownloadProgress {
  const factory DownloadProgress({
    /// Unique download ID for tracking
    required String downloadId,

    /// Progress percentage from 0.0 to 1.0
    @Default(0.0) double progress,

    /// Current state of the download
    @Default(DownloadState.pending) DownloadState state,

    /// Error message if download failed
    String? error,

    /// File name being downloaded
    String? fileName,

    /// Remote file URL being downloaded
    String? fileUrl,

    /// Local file path where download is saved
    String? localPath,

    /// Total size of the file in bytes
    int? totalBytes,

    /// Number of bytes downloaded so far
    @Default(0) int downloadedBytes,

    /// Current chunk index for chunked downloads
    @Default(0) int currentChunk,

    /// Total number of chunks for chunked downloads
    @Default(1) int totalChunks,

    /// ETag for HTTP caching and resume validation
    String? etag,

    /// Timestamp when download started
    int? startedAt,

    /// Timestamp when download completed or failed
    int? completedAt,

    /// Number of retry attempts
    @Default(0) int retryCount,

    /// Whether this is a chunked download
    @Default(false) bool isChunked,

    /// Room ID this download is associated with
    String? roomId,

    /// MIME type of the file
    String? mimeType,
  }) = _DownloadProgress;

  factory DownloadProgress.fromJson(Map<String, dynamic> json) =>
      _$DownloadProgressFromJson(json);

  const DownloadProgress._();

  /// Create a new pending download progress
  factory DownloadProgress.pending({
    required String downloadId,
    String? fileName,
    String? fileUrl,
    String? localPath,
    int? totalBytes,
    String? roomId,
    String? mimeType,
  }) => DownloadProgress(
    downloadId: downloadId,
    fileName: fileName,
    fileUrl: fileUrl,
    localPath: localPath,
    totalBytes: totalBytes,
    roomId: roomId,
    mimeType: mimeType,
    startedAt: DateTime.now().millisecondsSinceEpoch,
  );

  /// Create a downloading progress state
  factory DownloadProgress.downloading({
    required String downloadId,
    required double progress,
    String? fileName,
    String? fileUrl,
    String? localPath,
    int? totalBytes,
    int downloadedBytes = 0,
    int currentChunk = 0,
    int totalChunks = 1,
    String? etag,
    bool isChunked = false,
    String? roomId,
    String? mimeType,
  }) => DownloadProgress(
    downloadId: downloadId,
    progress: progress,
    state: DownloadState.downloading,
    fileName: fileName,
    fileUrl: fileUrl,
    localPath: localPath,
    totalBytes: totalBytes,
    downloadedBytes: downloadedBytes,
    currentChunk: currentChunk,
    totalChunks: totalChunks,
    etag: etag,
    isChunked: isChunked,
    roomId: roomId,
    mimeType: mimeType,
    startedAt: DateTime.now().millisecondsSinceEpoch,
  );

  /// Create a completed download progress
  factory DownloadProgress.completed({
    required String downloadId,
    String? fileName,
    String? fileUrl,
    String? localPath,
    int? totalBytes,
    String? roomId,
    String? mimeType,
  }) => DownloadProgress(
    downloadId: downloadId,
    progress: 1,
    state: DownloadState.completed,
    fileName: fileName,
    fileUrl: fileUrl,
    localPath: localPath,
    totalBytes: totalBytes,
    downloadedBytes: totalBytes ?? 0,
    roomId: roomId,
    mimeType: mimeType,
    completedAt: DateTime.now().millisecondsSinceEpoch,
  );

  /// Create a failed download progress
  factory DownloadProgress.failed({
    required String downloadId,
    required String error,
    String? fileName,
    String? fileUrl,
    String? localPath,
    int? totalBytes,
    int downloadedBytes = 0,
    int retryCount = 0,
    String? roomId,
    String? mimeType,
  }) => DownloadProgress(
    downloadId: downloadId,
    state: DownloadState.failed,
    error: error,
    fileName: fileName,
    fileUrl: fileUrl,
    localPath: localPath,
    totalBytes: totalBytes,
    downloadedBytes: downloadedBytes,
    retryCount: retryCount,
    roomId: roomId,
    mimeType: mimeType,
    completedAt: DateTime.now().millisecondsSinceEpoch,
  );

  /// Returns true if the download is currently in progress
  bool get isInProgress => state == DownloadState.downloading;

  /// Returns true if the download can be retried
  bool get canRetry =>
      state == DownloadState.failed || state == DownloadState.cancelled;

  /// Returns true if the download can be cancelled
  bool get canCancel =>
      state == DownloadState.pending || state == DownloadState.downloading;

  /// Returns true if the download is done (completed, failed, or cancelled)
  bool get isDone =>
      state == DownloadState.completed ||
      state == DownloadState.failed ||
      state == DownloadState.cancelled;

  /// Returns the progress percentage as an integer (0-100)
  int get progressPercent => (progress * 100).round();

  /// Returns the download speed in bytes per second (if tracking timestamps)
  double? get downloadSpeed {
    if (startedAt == null || downloadedBytes == 0) return null;
    final elapsedMs = DateTime.now().millisecondsSinceEpoch - startedAt!;
    if (elapsedMs <= 0) return null;
    return downloadedBytes / (elapsedMs / 1000);
  }

  /// Returns estimated time remaining in seconds
  int? get estimatedTimeRemaining {
    final speed = downloadSpeed;
    if (speed == null || speed <= 0 || totalBytes == null) return null;
    final remaining = totalBytes! - downloadedBytes;
    return (remaining / speed).round();
  }

  /// Returns a human-readable progress string
  String get progressText {
    switch (state) {
      case DownloadState.pending:
        return 'Waiting...';
      case DownloadState.downloading:
        if (isChunked) {
          return 'Downloading chunk $currentChunk of $totalChunks ($progressPercent%)';
        }
        return 'Downloading... $progressPercent%';
      case DownloadState.completed:
        return 'Download complete';
      case DownloadState.failed:
        return 'Download failed${error != null ? ": $error" : ""}';
      case DownloadState.cancelled:
        return 'Download cancelled';
      case DownloadState.paused:
        return 'Download paused ($progressPercent%)';
    }
  }

  /// Returns a formatted file size string
  String get formattedFileSize {
    if (totalBytes == null) return 'Unknown size';
    return _formatBytes(totalBytes!);
  }

  /// Returns a formatted downloaded size string
  String get formattedDownloadedSize => _formatBytes(downloadedBytes);

  /// Returns a formatted progress string (e.g., "5.2 MB / 10.4 MB")
  String get formattedProgress {
    if (totalBytes == null) return formattedDownloadedSize;
    return '${_formatBytes(downloadedBytes)} / ${_formatBytes(totalBytes!)}';
  }

  /// Format bytes to human-readable string
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
