import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../logging/app_logger.dart';
import '../networking/certificate_pinning.dart';
import '../networking/client.dart';
import 'files_config_service.dart';

/// Resolves media content from message content maps to downloadable bytes.
///
/// Resolution priority:
/// 1. `url` as HTTPS → HTTP GET
/// 2. `attachmentId` / `mediaId` → build direct HTTP URL
/// 3. `localPath` → read from local file (pending upload)
class ContentResolver {
  ContentResolver(
    this._filesConfigService,
    this._getAccessToken,
    this._httpClient,
  );

  final FilesConfigService _filesConfigService;
  final Future<String?> Function() _getAccessToken;
  final http.Client _httpClient;

  /// Resolve an image URL from message content, returning bytes.
  ///
  /// For MXC URIs, fetches a server-generated thumbnail at the specified
  /// dimensions for better performance. For HTTPS URLs, downloads the full
  /// image.
  Future<Uint8List?> resolveImageUrl(
    Map<String, dynamic> content, {
    int? width,
    int? height,
  }) async {
    final url = _resolveHttpUrl(content);
    if (url != null) {
      return _downloadLegacyUrl(url);
    }

    // Local file (pending upload)
    final localPath = content['localPath'] as String?;
    if (localPath != null) {
      return _readLocalFile(localPath);
    }

    return null;
  }

  /// Resolve a file download from message content, saving to [destPath].
  Future<File?> resolveFileDownload(
    Map<String, dynamic> content,
    String destPath,
  ) async {
    final url = _resolveHttpUrl(content);
    if (url != null) {
      final bytes = await _downloadLegacyUrl(url);
      if (bytes != null) {
        final file = File(destPath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
        return file;
      }
    }

    // Local file
    final localPath = content['localPath'] as String?;
    if (localPath != null) {
      final source = File(localPath);
      if (source.existsSync()) {
        return source.copy(destPath);
      }
    }

    return null;
  }

  /// Resolve a video thumbnail from message content.
  Future<Uint8List?> resolveVideoThumbnail(
    Map<String, dynamic> content, {
    int width = 256,
    int height = 256,
  }) async {
    final thumbnailUrl = content['thumbnailUrl'] as String?;
    if (thumbnailUrl != null && thumbnailUrl.startsWith('http')) {
      return _downloadLegacyUrl(thumbnailUrl);
    }

    final mediaId =
        (content['attachmentId'] as String?) ?? (content['mediaId'] as String?);
    if (mediaId != null && mediaId.isNotEmpty) {
      final url = _filesConfigService.buildThumbnailUrl(
        mediaId,
        width: width,
        height: height,
      );
      return _downloadLegacyUrl(url);
    }

    // Local thumbnail
    final localThumbnailPath = content['localThumbnailPath'] as String?;
    if (localThumbnailPath != null) {
      return _readLocalFile(localThumbnailPath);
    }

    return null;
  }

  /// Resolve the display URL for a media item.
  ///
  /// Returns a URL string suitable for widgets that need a URL rather than
  /// bytes (e.g. `CachedNetworkImage`). For MXC URIs, returns null since
  /// those require the download service. For legacy URLs, returns the URL
  /// directly.
  String? resolveLegacyUrl(Map<String, dynamic> content) {
    return _resolveHttpUrl(content);
  }

  String? _resolveHttpUrl(Map<String, dynamic> content) {
    final url = content['url'] as String?;
    if (url != null && url.startsWith('http')) return url;

    final mediaId =
        (content['attachmentId'] as String?) ?? (content['mediaId'] as String?);
    if (mediaId != null && mediaId.isNotEmpty) {
      return _filesConfigService.buildContentUrl(mediaId);
    }

    return null;
  }

  /// Download from a legacy HTTPS URL.
  Future<Uint8List?> _downloadLegacyUrl(String url) async {
    try {
      final token = await _getAccessToken();
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Legacy URL download failed',
        error: e,
        stackTrace: stackTrace,
        data: {'url': url},
      );
      return null;
    }
  }

  /// Read bytes from a local file path.
  Future<Uint8List?> _readLocalFile(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) {
        return file.readAsBytes();
      }
      return null;
    } catch (e) {
      AppLogger.debug('Failed to read local file: $path');
      return null;
    }
  }
}

/// Provider for [ContentResolver].
final contentResolverProvider = Provider<ContentResolver>((ref) {
  final configService = ref.watch(filesConfigServiceProvider);
  final tokenManager = ref.watch(tokenManagerProvider);
  final certificatePinning = ref.watch(certificatePinningProvider);
  final httpClient = kIsWeb
      ? http.Client()
      : IOClient(certificatePinning.createPinnedHttpClient());
  ref.onDispose(httpClient.close);
  return ContentResolver(
    configService,
    () async => tokenManager.accessToken,
    httpClient,
  );
});
