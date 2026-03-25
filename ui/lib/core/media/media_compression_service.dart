import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

import '../logging/app_logger.dart';
import '../settings/settings_service.dart';

/// Settings keys for media compression
class CompressionSettingsKeys {
  static const imageQuality = 'compression_image_quality';
  static const videoQuality = 'compression_video_quality';
  static const compressionEnabled = 'compression_enabled';
  static const showSizeEstimate = 'compression_show_size_estimate';
}

/// Default values for compression settings
class CompressionDefaults {
  static const imageQuality = 80;
  static const videoQuality = VideoQuality.Res960x540Quality;
  static const compressionEnabled = true;
  static const showSizeEstimate = true;
  static const maxImageWidth = 1920;
  static const maxImageHeight = 1080;
}

/// Compression quality preset for videos
enum CompressionQualityPreset {
  low(VideoQuality.Res640x480Quality, 'Low (480p)'),
  medium(VideoQuality.Res960x540Quality, 'Medium (540p)'),
  high(VideoQuality.Res1280x720Quality, 'High (720p)'),
  original(VideoQuality.Res1920x1080Quality, 'Original (1080p)');

  const CompressionQualityPreset(this.videoQuality, this.displayName);
  final VideoQuality videoQuality;
  final String displayName;

  static CompressionQualityPreset fromString(String value) {
    return CompressionQualityPreset.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CompressionQualityPreset.medium,
    );
  }
}

/// Result of a compression operation
class CompressionResult {
  const CompressionResult({
    required this.file,
    required this.originalSize,
    required this.compressedSize,
    required this.wasCompressed,
    this.width,
    this.height,
    this.duration,
  });

  /// The resulting file (compressed or original if compression was skipped)
  final File file;

  /// Original file size in bytes
  final int originalSize;

  /// Compressed file size in bytes (same as original if not compressed)
  final int compressedSize;

  /// Whether compression was actually performed
  final bool wasCompressed;

  /// Width of image/video after compression (if applicable)
  final int? width;

  /// Height of image/video after compression (if applicable)
  final int? height;

  /// Duration of video in milliseconds (if applicable)
  final int? duration;

  /// Size savings as a percentage
  double get savingsPercent {
    if (originalSize == 0) return 0;
    return ((originalSize - compressedSize) / originalSize) * 100;
  }

  /// Human-readable size difference
  String get sizeReduction {
    final diff = originalSize - compressedSize;
    return formatBytes(diff);
  }
}

/// Progress information during compression
class CompressionProgress {
  const CompressionProgress({
    required this.progress,
    required this.stage,
    this.estimatedSize,
  });

  /// Progress from 0.0 to 1.0
  final double progress;

  /// Current stage description
  final String stage;

  /// Estimated final size in bytes (if available)
  final int? estimatedSize;
}

/// Service for compressing images and videos before upload
///
/// Features:
/// - Image compression to max 1920x1080 with configurable JPEG quality
/// - Video compression to 720p (configurable)
/// - Progress callbacks during compression
/// - Size estimation before compression
/// - Original quality bypass option
class MediaCompressionService {
  MediaCompressionService(this._settingsService);

  final SettingsService _settingsService;

  /// Subscription for video compression progress
  Subscription? _progressSubscription;

  /// Get current image quality setting
  int get imageQuality => _settingsService.getInt(
    CompressionSettingsKeys.imageQuality,
    defaultValue: CompressionDefaults.imageQuality,
  );

  /// Get current video quality preset
  CompressionQualityPreset get videoQualityPreset {
    final value = _settingsService.getString(
      CompressionSettingsKeys.videoQuality,
      defaultValue: CompressionQualityPreset.medium.name,
    );
    return CompressionQualityPreset.fromString(value);
  }

  /// Check if compression is enabled
  bool get isCompressionEnabled => _settingsService.getBool(
    CompressionSettingsKeys.compressionEnabled,
    defaultValue: CompressionDefaults.compressionEnabled,
  );

  /// Compress an image file
  ///
  /// Parameters:
  /// - [file]: The image file to compress
  /// - [quality]: JPEG quality (0-100), defaults to settings value
  /// - [maxWidth]: Maximum width, defaults to 1920
  /// - [maxHeight]: Maximum height, defaults to 1080
  /// - [keepOriginal]: If true, returns original file without compression
  /// - [onProgress]: Progress callback
  ///
  /// Returns a [CompressionResult] with the compressed file and metadata
  Future<CompressionResult> compressImage(
    File file, {
    int? quality,
    int maxWidth = CompressionDefaults.maxImageWidth,
    int maxHeight = CompressionDefaults.maxImageHeight,
    bool keepOriginal = false,
    void Function(CompressionProgress progress)? onProgress,
  }) async {
    final originalSize = await file.length();
    final effectiveQuality = quality ?? imageQuality;

    // Check if compression should be skipped
    if (keepOriginal || !isCompressionEnabled) {
      AppLogger.debug(
        'Image compression skipped',
        data: {
          'keepOriginal': keepOriginal,
          'compressionEnabled': isCompressionEnabled,
        },
      );
      return CompressionResult(
        file: file,
        originalSize: originalSize,
        compressedSize: originalSize,
        wasCompressed: false,
      );
    }

    onProgress?.call(
      const CompressionProgress(progress: 0.1, stage: 'Preparing image...'),
    );

    try {
      // Get output path in temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(file.path);
      final targetPath = '${tempDir.path}/${fileName}_compressed.jpg';

      AppLogger.debug(
        'Starting image compression',
        data: {
          'originalSize': originalSize,
          'quality': effectiveQuality,
          'maxWidth': maxWidth,
          'maxHeight': maxHeight,
        },
      );

      onProgress?.call(
        const CompressionProgress(progress: 0.3, stage: 'Compressing image...'),
      );

      // Compress the image
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: effectiveQuality,
        minWidth: maxWidth,
        minHeight: maxHeight,
      );

      onProgress?.call(
        const CompressionProgress(progress: 0.9, stage: 'Finalizing...'),
      );

      if (result == null) {
        AppLogger.warning('Image compression returned null, using original');
        return CompressionResult(
          file: file,
          originalSize: originalSize,
          compressedSize: originalSize,
          wasCompressed: false,
        );
      }

      final compressedFile = File(result.path);
      final compressedSize = await compressedFile.length();

      // If compressed file is larger, use original
      if (compressedSize >= originalSize) {
        AppLogger.info(
          'Compressed image larger than original, using original',
          data: {
            'originalSize': originalSize,
            'compressedSize': compressedSize,
          },
        );
        // Clean up temp file
        await compressedFile.delete();
        return CompressionResult(
          file: file,
          originalSize: originalSize,
          compressedSize: originalSize,
          wasCompressed: false,
        );
      }

      onProgress?.call(
        CompressionProgress(
          progress: 1,
          stage: 'Complete',
          estimatedSize: compressedSize,
        ),
      );

      AppLogger.info(
        'Image compressed successfully',
        data: {
          'originalSize': originalSize,
          'compressedSize': compressedSize,
          'savingsPercent':
              ((originalSize - compressedSize) / originalSize * 100)
                  .toStringAsFixed(1),
        },
      );

      return CompressionResult(
        file: compressedFile,
        originalSize: originalSize,
        compressedSize: compressedSize,
        wasCompressed: true,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Image compression failed',
        error: e,
        stackTrace: stackTrace,
      );
      // Return original file on error
      return CompressionResult(
        file: file,
        originalSize: originalSize,
        compressedSize: originalSize,
        wasCompressed: false,
      );
    }
  }

  /// Compress a video file
  ///
  /// Parameters:
  /// - [file]: The video file to compress
  /// - [qualityPreset]: Quality preset, defaults to settings value
  /// - [keepOriginal]: If true, returns original file without compression
  /// - [onProgress]: Progress callback
  ///
  /// Returns a [CompressionResult] with the compressed file and metadata
  Future<CompressionResult> compressVideo(
    File file, {
    CompressionQualityPreset? qualityPreset,
    bool keepOriginal = false,
    void Function(CompressionProgress progress)? onProgress,
  }) async {
    final originalSize = await file.length();
    final effectiveQuality = qualityPreset ?? videoQualityPreset;

    // Check if compression should be skipped
    if (keepOriginal ||
        !isCompressionEnabled ||
        effectiveQuality == CompressionQualityPreset.original) {
      AppLogger.debug(
        'Video compression skipped',
        data: {
          'keepOriginal': keepOriginal,
          'compressionEnabled': isCompressionEnabled,
          'quality': effectiveQuality.name,
        },
      );
      return CompressionResult(
        file: file,
        originalSize: originalSize,
        compressedSize: originalSize,
        wasCompressed: false,
      );
    }

    try {
      AppLogger.debug(
        'Starting video compression',
        data: {'originalSize': originalSize, 'quality': effectiveQuality.name},
      );

      // Set up progress listener
      _progressSubscription?.unsubscribe();
      _progressSubscription = VideoCompress.compressProgress$.subscribe((
        progress,
      ) {
        onProgress?.call(
          CompressionProgress(
            progress: progress / 100,
            stage: 'Compressing video... ${progress.toStringAsFixed(0)}%',
          ),
        );
      });

      onProgress?.call(
        const CompressionProgress(
          progress: 0,
          stage: 'Starting video compression...',
        ),
      );

      // Compress the video
      final info = await VideoCompress.compressVideo(
        file.path,
        quality: effectiveQuality.videoQuality,
        includeAudio: true,
      );

      _progressSubscription?.unsubscribe();
      _progressSubscription = null;

      if (info == null || info.file == null) {
        AppLogger.warning('Video compression returned null, using original');
        return CompressionResult(
          file: file,
          originalSize: originalSize,
          compressedSize: originalSize,
          wasCompressed: false,
        );
      }

      final compressedFile = info.file!;
      final compressedSize = await compressedFile.length();

      // If compressed file is larger, use original
      if (compressedSize >= originalSize) {
        AppLogger.info(
          'Compressed video larger than original, using original',
          data: {
            'originalSize': originalSize,
            'compressedSize': compressedSize,
          },
        );
        // Clean up temp file
        await compressedFile.delete();
        return CompressionResult(
          file: file,
          originalSize: originalSize,
          compressedSize: originalSize,
          wasCompressed: false,
        );
      }

      onProgress?.call(
        CompressionProgress(
          progress: 1,
          stage: 'Complete',
          estimatedSize: compressedSize,
        ),
      );

      AppLogger.info(
        'Video compressed successfully',
        data: {
          'originalSize': originalSize,
          'compressedSize': compressedSize,
          'savingsPercent':
              ((originalSize - compressedSize) / originalSize * 100)
                  .toStringAsFixed(1),
          'width': info.width,
          'height': info.height,
          'duration': info.duration,
        },
      );

      return CompressionResult(
        file: compressedFile,
        originalSize: originalSize,
        compressedSize: compressedSize,
        wasCompressed: true,
        width: info.width?.toInt(),
        height: info.height?.toInt(),
        duration: (info.duration ?? 0).toInt(),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Video compression failed',
        error: e,
        stackTrace: stackTrace,
      );
      _progressSubscription?.unsubscribe();
      _progressSubscription = null;
      // Return original file on error
      return CompressionResult(
        file: file,
        originalSize: originalSize,
        compressedSize: originalSize,
        wasCompressed: false,
      );
    }
  }

  /// Estimate the compressed size of an image
  ///
  /// This provides a rough estimate based on typical compression ratios.
  /// Actual compression results may vary.
  Future<int> estimateImageSize(File file, {int? quality}) async {
    final originalSize = await file.length();
    final effectiveQuality = quality ?? imageQuality;

    if (!isCompressionEnabled) {
      return originalSize;
    }

    // Rough estimation based on quality setting
    // At 80% quality, typical JPEG compression is around 70-80% of original
    // Lower quality = more compression
    final compressionRatio = 0.5 + (effectiveQuality / 200);
    return (originalSize * compressionRatio).round();
  }

  /// Estimate the compressed size of a video
  ///
  /// This provides a rough estimate based on typical compression ratios.
  /// Actual compression results may vary significantly.
  Future<int> estimateVideoSize(
    File file, {
    CompressionQualityPreset? qualityPreset,
  }) async {
    final originalSize = await file.length();
    final effectiveQuality = qualityPreset ?? videoQualityPreset;

    if (!isCompressionEnabled ||
        effectiveQuality == CompressionQualityPreset.original) {
      return originalSize;
    }

    // Rough estimation based on quality preset
    // These are approximate ratios for typical video content
    final compressionRatio = switch (effectiveQuality) {
      CompressionQualityPreset.low => 0.2,
      CompressionQualityPreset.medium => 0.4,
      CompressionQualityPreset.high => 0.6,
      CompressionQualityPreset.original => 1.0,
    };

    return (originalSize * compressionRatio).round();
  }

  /// Cancel any ongoing video compression
  Future<void> cancelVideoCompression() async {
    await VideoCompress.cancelCompression();
    _progressSubscription?.unsubscribe();
    _progressSubscription = null;
    AppLogger.debug('Video compression cancelled');
  }

  /// Delete all temporary cache files from video compression
  Future<void> clearCache() async {
    await VideoCompress.deleteAllCache();
    AppLogger.debug('Video compression cache cleared');
  }

  /// Dispose resources
  void dispose() {
    _progressSubscription?.unsubscribe();
    _progressSubscription = null;
  }
}

/// Format bytes to human-readable string
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

// Provider for MediaCompressionService
final mediaCompressionServiceProvider = Provider<MediaCompressionService>((
  ref,
) {
  final settingsService = ref.watch(settingsServiceProvider);
  final service = MediaCompressionService(settingsService);

  ref.onDispose(service.dispose);

  return service;
});
