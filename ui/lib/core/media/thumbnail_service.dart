// ignore_for_file: avoid_slow_async_io

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../logging/app_logger.dart';

/// Configuration for thumbnail generation
class ThumbnailConfig {
  const ThumbnailConfig({
    this.maxWidth = 200,
    this.maxHeight = 200,
    this.quality = 70,
    this.format = ThumbnailFormat.jpeg,
  });

  /// Maximum width of the thumbnail
  final int maxWidth;

  /// Maximum height of the thumbnail
  final int maxHeight;

  /// Quality of the thumbnail (0-100)
  final int quality;

  /// Output format for the thumbnail
  final ThumbnailFormat format;
}

/// Supported thumbnail output formats
enum ThumbnailFormat { jpeg, png, webp }

/// Result of thumbnail generation
class ThumbnailResult {
  const ThumbnailResult({
    required this.file,
    required this.width,
    required this.height,
    required this.size,
    this.blurHash,
  });

  /// The generated thumbnail file
  final File file;

  /// Width of the thumbnail in pixels
  final int width;

  /// Height of the thumbnail in pixels
  final int height;

  /// Size of the thumbnail in bytes
  final int size;

  /// Optional blur hash for instant preview
  final String? blurHash;
}

/// Provider for ThumbnailService
final thumbnailServiceProvider = Provider<ThumbnailService>((ref) {
  return ThumbnailService();
});

/// Service for generating thumbnails from images and videos
///
/// Provides client-side thumbnail generation for:
/// - Images: Resizes and compresses for quick preview
/// - Videos: Extracts first frame as thumbnail
///
/// Example:
/// ```dart
/// final service = ref.read(thumbnailServiceProvider);
/// final thumbnail = await service.generateImageThumbnail(imageFile);
/// if (thumbnail != null) {
///   print('Thumbnail: ${thumbnail.file.path}');
/// }
/// ```
class ThumbnailService {
  ThumbnailService([ThumbnailConfig? config])
    : _config = config ?? const ThumbnailConfig();

  final ThumbnailConfig _config;

  /// Generate a thumbnail from an image file
  ///
  /// Returns a [ThumbnailResult] with the generated thumbnail,
  /// or null if generation fails.
  Future<ThumbnailResult?> generateImageThumbnail(
    File imageFile, {
    ThumbnailConfig? config,
  }) async {
    final effectiveConfig = config ?? _config;

    try {
      // Get temp directory for thumbnail
      final tempDir = await getTemporaryDirectory();

      // Determine output format and extension
      final (compressFormat, extension) = switch (effectiveConfig.format) {
        ThumbnailFormat.png => (CompressFormat.png, 'png'),
        ThumbnailFormat.webp => (CompressFormat.webp, 'webp'),
        ThumbnailFormat.jpeg => (CompressFormat.jpeg, 'jpg'),
      };

      final thumbnailName =
          'thumb_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final thumbnailPath = path.join(tempDir.path, thumbnailName);

      // Generate thumbnail using flutter_image_compress
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        thumbnailPath,
        minWidth: effectiveConfig.maxWidth,
        minHeight: effectiveConfig.maxHeight,
        quality: effectiveConfig.quality,
        format: compressFormat,
      );

      if (result == null) {
        AppLogger.warning('Failed to generate image thumbnail');
        return null;
      }

      final thumbnailFile = File(result.path);
      final thumbnailStat = await thumbnailFile.stat();

      // Read actual dimensions from the generated thumbnail
      final imageBytes = await thumbnailFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();

      AppLogger.debug(
        'Image thumbnail generated',
        data: {
          'originalPath': imageFile.path,
          'thumbnailPath': result.path,
          'size': thumbnailStat.size,
          'width': frame.image.width,
          'height': frame.image.height,
        },
      );

      return ThumbnailResult(
        file: thumbnailFile,
        width: frame.image.width,
        height: frame.image.height,
        size: thumbnailStat.size,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to generate image thumbnail',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Generate a thumbnail from a video file
  ///
  /// Extracts the first frame of the video as a thumbnail.
  /// Returns a [ThumbnailResult] with the generated thumbnail,
  /// or null if generation fails.
  Future<ThumbnailResult?> generateVideoThumbnail(
    File videoFile, {
    ThumbnailConfig? config,
    int timeMs = 0,
  }) async {
    final effectiveConfig = config ?? _config;

    // Video thumbnail not supported on web
    if (kIsWeb) {
      AppLogger.debug('Video thumbnail not supported on web');
      return null;
    }

    try {
      // Get temp directory for thumbnail
      final tempDir = await getTemporaryDirectory();

      // Determine output format and extension
      final (imageFormat, extension) = switch (effectiveConfig.format) {
        ThumbnailFormat.png => (ImageFormat.PNG, 'png'),
        ThumbnailFormat.webp => (ImageFormat.WEBP, 'webp'),
        ThumbnailFormat.jpeg => (ImageFormat.JPEG, 'jpg'),
      };

      final thumbnailName =
          'vthumb_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final thumbnailPath = path.join(tempDir.path, thumbnailName);

      // Generate thumbnail using video_thumbnail
      final thumbnailFile = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: thumbnailPath,
        imageFormat: imageFormat,
        maxWidth: effectiveConfig.maxWidth,
        maxHeight: effectiveConfig.maxHeight,
        quality: effectiveConfig.quality,
        timeMs: timeMs,
      );

      if (thumbnailFile == null) {
        AppLogger.warning('Failed to generate video thumbnail');
        return null;
      }

      final file = File(thumbnailFile);
      final thumbnailStat = await file.stat();

      // Read actual dimensions from the generated thumbnail
      final imageBytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();

      AppLogger.debug(
        'Video thumbnail generated',
        data: {
          'videoPath': videoFile.path,
          'thumbnailPath': thumbnailFile,
          'size': thumbnailStat.size,
          'timeMs': timeMs,
          'width': frame.image.width,
          'height': frame.image.height,
        },
      );

      return ThumbnailResult(
        file: file,
        width: frame.image.width,
        height: frame.image.height,
        size: thumbnailStat.size,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to generate video thumbnail',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Generate a thumbnail from video data (Uint8List)
  ///
  /// Returns the thumbnail as bytes, or null if generation fails.
  Future<Uint8List?> generateVideoThumbnailData(
    String videoPath, {
    ThumbnailConfig? config,
    int timeMs = 0,
  }) async {
    final effectiveConfig = config ?? _config;

    if (kIsWeb) {
      return null;
    }

    try {
      final imageFormat = switch (effectiveConfig.format) {
        ThumbnailFormat.png => ImageFormat.PNG,
        ThumbnailFormat.webp => ImageFormat.WEBP,
        ThumbnailFormat.jpeg => ImageFormat.JPEG,
      };

      final thumbnailData = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: imageFormat,
        maxWidth: effectiveConfig.maxWidth,
        maxHeight: effectiveConfig.maxHeight,
        quality: effectiveConfig.quality,
        timeMs: timeMs,
      );

      return thumbnailData;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to generate video thumbnail data',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Clean up temporary thumbnail files older than the specified duration
  Future<void> cleanupOldThumbnails({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final now = DateTime.now();

      await for (final entity in tempDir.list()) {
        if (entity is File) {
          final name = path.basename(entity.path);
          if (name.startsWith('thumb_') || name.startsWith('vthumb_')) {
            final stat = await entity.stat();
            final age = now.difference(stat.modified);
            if (age > maxAge) {
              await entity.delete();
              AppLogger.debug(
                'Deleted old thumbnail',
                data: {'path': entity.path},
              );
            }
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to cleanup old thumbnails',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
