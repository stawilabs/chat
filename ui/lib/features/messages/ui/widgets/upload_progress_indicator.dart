import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/upload_progress_provider.dart';
import '../../domain/upload_progress.dart';

/// Widget that displays upload progress for a media message
///
/// Shows a circular progress indicator with percentage, and provides
/// cancel/retry actions based on the upload state.
///
/// Example:
/// ```dart
/// UploadProgressIndicator(
///   localId: message.localId!,
///   onCancel: () => cancelUpload(message.localId!),
///   onRetry: () => retryUpload(message.localId!),
/// )
/// ```
class UploadProgressIndicator extends ConsumerWidget {
  const UploadProgressIndicator({
    required this.localId,
    super.key,
    this.size = 48.0,
    this.strokeWidth = 3.0,
    this.onCancel,
    this.onRetry,
    this.showPercentage = true,
    this.showCancelButton = true,
    this.backgroundColor,
  });

  /// Local message ID to track
  final String localId;

  /// Size of the progress indicator
  final double size;

  /// Width of the progress circle stroke
  final double strokeWidth;

  /// Callback when cancel is tapped
  final VoidCallback? onCancel;

  /// Callback when retry is tapped
  final VoidCallback? onRetry;

  /// Whether to show percentage text
  final bool showPercentage;

  /// Whether to show cancel button during upload
  final bool showCancelButton;

  /// Background color overlay
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(singleUploadProgressProvider(localId));

    if (progress == null) {
      return const SizedBox.shrink();
    }

    return _buildProgressContent(context, progress);
  }

  Widget _buildProgressContent(BuildContext context, UploadProgress progress) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress circle
          if (progress.isInProgress || progress.state == UploadState.pending)
            SizedBox(
              width: size - 8,
              height: size - 8,
              child: CircularProgressIndicator(
                value: progress.state == UploadState.pending
                    ? null
                    : progress.progress,
                strokeWidth: strokeWidth,
                color: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
              ),
            ),

          // Center content based on state
          _buildCenterContent(context, progress, theme),
        ],
      ),
    );
  }

  Widget _buildCenterContent(
    BuildContext context,
    UploadProgress progress,
    ThemeData theme,
  ) {
    switch (progress.state) {
      case UploadState.pending:
        return const Icon(Icons.hourglass_empty, color: Colors.white, size: 20);

      case UploadState.uploading:
        if (showCancelButton && onCancel != null) {
          return GestureDetector(
            onTap: onCancel,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.close, color: Colors.white, size: 16),
                if (showPercentage)
                  Text(
                    '${progress.progressPercent}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          );
        } else if (showPercentage) {
          return Text(
            '${progress.progressPercent}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          );
        }
        return const SizedBox.shrink();

      case UploadState.failed:
        return GestureDetector(
          onTap: onRetry,
          child: const Icon(Icons.refresh, color: Colors.white, size: 24),
        );

      case UploadState.cancelled:
        return GestureDetector(
          onTap: onRetry,
          child: const Icon(Icons.replay, color: Colors.white, size: 24),
        );

      case UploadState.paused:
        return GestureDetector(
          onTap: onRetry,
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
        );

      case UploadState.completed:
        return const Icon(Icons.check, color: Colors.white, size: 24);
    }
  }
}

/// Compact upload progress bar for inline display
///
/// Shows a horizontal progress bar with optional text
class UploadProgressBar extends ConsumerWidget {
  const UploadProgressBar({
    required this.localId,
    super.key,
    this.height = 4.0,
    this.showText = true,
    this.onCancel,
    this.onRetry,
  });

  final String localId;
  final double height;
  final bool showText;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(singleUploadProgressProvider(localId));

    if (progress == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: progress.state == UploadState.pending
                ? null
                : progress.progress,
            minHeight: height,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(progress.state, theme),
            ),
          ),
        ),

        // Text and actions
        if (showText) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  progress.progressText,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (progress.canCancel && onCancel != null)
                GestureDetector(
                  onTap: onCancel,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              if (progress.canRetry && onRetry != null)
                GestureDetector(
                  onTap: onRetry,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.refresh,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Color _getProgressColor(UploadState state, ThemeData theme) {
    switch (state) {
      case UploadState.pending:
      case UploadState.uploading:
        return theme.colorScheme.primary;
      case UploadState.completed:
        return Colors.green;
      case UploadState.failed:
        return theme.colorScheme.error;
      case UploadState.cancelled:
      case UploadState.paused:
        return theme.colorScheme.outline;
    }
  }
}

/// Full upload progress card with all details
///
/// Shows complete upload information including speed, ETA, and file details
class UploadProgressCard extends ConsumerWidget {
  const UploadProgressCard({
    required this.localId,
    super.key,
    this.onCancel,
    this.onRetry,
    this.onDismiss,
  });

  final String localId;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(singleUploadProgressProvider(localId));

    if (progress == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with file name and dismiss
            Row(
              children: [
                Icon(
                  _getFileIcon(progress.fileName),
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    progress.fileName ?? 'Uploading...',
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (progress.isDone && onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            UploadProgressBar(localId: localId, showText: false, height: 6),

            const SizedBox(height: 8),

            // Stats row
            Row(
              children: [
                // Progress text
                Text(
                  progress.progressText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),

                // Size info
                if (progress.totalBytes != null)
                  Text(
                    '${_formatBytes(progress.uploadedBytes)} / ${_formatBytes(progress.totalBytes!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),

            // Speed and ETA (if uploading)
            if (progress.isInProgress) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (progress.uploadSpeed != null)
                    Text(
                      '${_formatBytes(progress.uploadSpeed!.round())}/s',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const Spacer(),
                  if (progress.estimatedTimeRemaining != null)
                    Text(
                      '${_formatDuration(progress.estimatedTimeRemaining!)} remaining',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],

            // Action buttons
            if (progress.canCancel || progress.canRetry) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (progress.canCancel && onCancel != null)
                    TextButton(
                      onPressed: onCancel,
                      child: const Text('Cancel'),
                    ),
                  if (progress.canRetry && onRetry != null)
                    FilledButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String? fileName) {
    if (fileName == null) return Icons.file_upload;

    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return Icons.videocam;
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'ogg':
        return Icons.audiotrack;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) {
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      return '${mins}m ${secs}s';
    }
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    return '${hours}h ${mins}m';
  }
}
