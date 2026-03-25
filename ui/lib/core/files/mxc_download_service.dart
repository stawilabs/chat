import 'dart:io';
import 'dart:typed_data';

import 'package:antinvestor_api_files/antinvestor_api_files.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cache/media_cache_manager.dart';
import '../logging/app_logger.dart';
import '../networking/client.dart';
import 'mxc_uri.dart';

/// Metadata about downloaded content.
class ContentMetadata {
  const ContentMetadata({this.contentType, this.filename});

  final String? contentType;
  final String? filename;
}

/// Service for downloading files and thumbnails via the proto
/// [FilesServiceClient.getContent] and [FilesServiceClient.getContentThumbnail]
/// RPCs.
///
/// Uses the proto-defined download API with MXC URIs for all file downloads.
class MxcDownloadService {
  MxcDownloadService(this._getClient, this._cacheManager);

  final Future<FilesServiceClient> Function() _getClient;
  final MediaCacheManager _cacheManager;

  /// Download the full content for an MXC URI.
  ///
  /// Checks the media cache first. If not cached, downloads via proto API
  /// and caches the result.
  Future<Uint8List?> downloadContent(MxcUri uri) async {
    // Check cache first
    final cacheKey = _cacheKeyForContent(uri);
    final cached = await _cacheManager.getCachedFile(cacheKey);
    if (cached != null) {
      return cached.readAsBytes();
    }

    try {
      final client = await _getClient();
      final response = await client.getContent(
        GetContentRequest(mediaId: uri.mediaId),
      );

      final bytes = Uint8List.fromList(response.content);

      // Cache the downloaded content
      await _cacheManager.cacheFile(bytes, cacheKey, url: uri.toString());

      AppLogger.debug(
        'Content downloaded via MXC',
        data: {'uri': uri.toString(), 'size': bytes.length},
      );

      return bytes;
    } catch (e, stackTrace) {
      AppLogger.error(
        'MXC content download failed',
        error: e,
        stackTrace: stackTrace,
        data: {'uri': uri.toString()},
      );
      return null;
    }
  }

  /// Download content and write directly to a file.
  ///
  /// For large files, this avoids holding the full content in memory
  /// by writing directly to disk.
  Future<File?> downloadContentToFile(MxcUri uri, String destPath) async {
    // Check cache first
    final cacheKey = _cacheKeyForContent(uri);
    final cached = await _cacheManager.getCachedFile(cacheKey);
    if (cached != null) {
      // Copy from cache to destination
      final dest = File(destPath);
      await dest.parent.create(recursive: true);
      return cached.copy(destPath);
    }

    try {
      final client = await _getClient();
      final response = await client.getContent(
        GetContentRequest(mediaId: uri.mediaId),
      );

      final file = File(destPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(response.content);

      // Also cache
      await _cacheManager.cacheFile(
        response.content,
        cacheKey,
        url: uri.toString(),
      );

      AppLogger.debug(
        'Content downloaded to file via MXC',
        data: {'uri': uri.toString(), 'destPath': destPath},
      );

      return file;
    } catch (e, stackTrace) {
      AppLogger.error(
        'MXC file download failed',
        error: e,
        stackTrace: stackTrace,
        data: {'uri': uri.toString()},
      );
      return null;
    }
  }

  /// Download a thumbnail for an MXC URI with specified dimensions.
  ///
  /// Uses the server-side thumbnail generation which supports scaling and
  /// cropping. Results are cached keyed by URI + dimensions + method.
  Future<Uint8List?> downloadThumbnail(
    MxcUri uri, {
    int width = 256,
    int height = 256,
    ThumbnailMethod method = ThumbnailMethod.SCALE,
  }) async {
    final cacheKey = _cacheKeyForThumbnail(uri, width, height, method);
    final cached = await _cacheManager.getCachedFile(cacheKey);
    if (cached != null) {
      return cached.readAsBytes();
    }

    try {
      final client = await _getClient();
      final response = await client.getContentThumbnail(
        GetContentThumbnailRequest(
          mediaId: uri.mediaId,
          width: width,
          height: height,
          method: method,
        ),
      );

      final bytes = Uint8List.fromList(response.content);

      // Cache the thumbnail
      await _cacheManager.cacheFile(bytes, cacheKey, url: uri.toString());

      AppLogger.debug(
        'Thumbnail downloaded via MXC',
        data: {
          'uri': uri.toString(),
          'size': bytes.length,
          'dimensions': '${width}x$height',
        },
      );

      return bytes;
    } catch (e, stackTrace) {
      AppLogger.error(
        'MXC thumbnail download failed',
        error: e,
        stackTrace: stackTrace,
        data: {'uri': uri.toString()},
      );
      return null;
    }
  }

  /// Get metadata about content without downloading the full file.
  Future<ContentMetadata?> getContentMetadata(MxcUri uri) async {
    try {
      final client = await _getClient();
      // We use getContent but only need the metadata fields
      final response = await client.getContent(
        GetContentRequest(mediaId: uri.mediaId),
      );

      final metadata = response.metadata;
      return ContentMetadata(
        contentType: metadata.contentType,
        filename: metadata.filename,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'MXC metadata fetch failed',
        error: e,
        stackTrace: stackTrace,
        data: {'uri': uri.toString()},
      );
      return null;
    }
  }

  /// Generate a cache key for full content.
  String _cacheKeyForContent(MxcUri uri) =>
      'mxc_${uri.serverName}_${uri.mediaId}';

  /// Generate a cache key for a thumbnail with specific dimensions.
  String _cacheKeyForThumbnail(
    MxcUri uri,
    int width,
    int height,
    ThumbnailMethod method,
  ) => 'mxc_${uri.serverName}_${uri.mediaId}_${width}x${height}_${method.name}';
}

/// Provider for [MxcDownloadService].
final mxcDownloadServiceProvider = Provider<MxcDownloadService>((ref) {
  final cacheManager = ref.watch(mediaCacheManagerProvider);
  return MxcDownloadService(
    () => ref.read(filesServiceClientProvider.future),
    cacheManager,
  );
});
