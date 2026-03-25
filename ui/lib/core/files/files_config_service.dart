import 'package:antinvestor_api_files/antinvestor_api_files.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import '../networking/api_config.dart';
import '../networking/client.dart';

/// Service to retrieve and cache the Files API configuration.
///
/// Wraps [FilesServiceClient.getConfig] to expose the max upload size
/// and any additional configuration from the server.
class FilesConfigService {
  FilesConfigService(this._getClient);

  final Future<FilesServiceClient> Function() _getClient;

  /// Base URL for HTTP uploads
  String get baseUrl => ApiConfig.filesBaseUrl;

  /// Build a direct HTTP URL for content by media ID.
  String buildContentUrl(String mediaId) => contentUrl(baseUrl, mediaId);

  /// Build a direct HTTP URL for thumbnails by media ID.
  String buildThumbnailUrl(
    String mediaId, {
    int width = 256,
    int height = 256,
    ThumbnailMethod method = ThumbnailMethod.CROP,
  }) => thumbnailUrl(
    baseUrl,
    mediaId,
    width: width,
    height: height,
    method: method,
  );

  /// Build a content URL from a base URL and media ID.
  ///
  /// Public static utility for code that doesn't have access to a
  /// [FilesConfigService] instance (e.g. sync engine, background tasks).
  static String buildContentUrlFrom(String baseUrl, String mediaId) =>
      contentUrl(baseUrl, mediaId);

  /// Cached max upload size (bytes). Null until first fetch.
  int? _cachedMaxUploadSize;

  /// Get the maximum upload size allowed by the server (in bytes).
  ///
  /// Caches the result for the session since it won't change.
  Future<int> getMaxUploadSize() async {
    if (_cachedMaxUploadSize != null) return _cachedMaxUploadSize!;

    try {
      final client = await _getClient();
      final response = await client.getConfig(GetConfigRequest());
      _cachedMaxUploadSize = response.maxUploadBytes.toInt();

      AppLogger.info(
        'Files config loaded',
        data: {'maxUploadSize': _cachedMaxUploadSize},
      );

      return _cachedMaxUploadSize!;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load files config',
        error: e,
        stackTrace: stackTrace,
      );
      // Default to 50MB if config unavailable
      return 50 * 1024 * 1024;
    }
  }

  /// Clear the cached config (e.g. on re-authentication).
  void clearCache() {
    _cachedMaxUploadSize = null;
  }
}

/// Provider for [FilesConfigService].
final filesConfigServiceProvider = Provider<FilesConfigService>((ref) {
  return FilesConfigService(() => ref.read(filesServiceClientProvider.future));
});
