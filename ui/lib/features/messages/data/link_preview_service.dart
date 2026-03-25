import 'dart:async';
import 'dart:convert';

import 'package:antinvestor_api_files/antinvestor_api_files.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;

import '../../../core/files/files_config_service.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/networking/api_config.dart';
import '../../../core/networking/client.dart';
import '../domain/link_preview.dart';

/// Service for fetching OpenGraph link previews
///
/// Fetches metadata from URLs to display rich previews in messages.
/// Uses the proto [FilesServiceClient.getUrlPreview] API as the primary
/// source, with fallback to direct HTTP OG tag parsing.
/// Supports caching, timeout handling, and graceful degradation.
class LinkPreviewService {
  LinkPreviewService(this._getAccessToken, this._getFilesClient);

  final Future<String?> Function() _getAccessToken;
  final Future<FilesServiceClient> Function() _getFilesClient;

  /// In-memory cache for link previews (FIFO eviction with TTL)
  final Map<String, _CachedPreview> _cache = {};
  static const int _maxCacheSize = 100;
  static const Duration _cacheTtl = Duration(hours: 1);
  static const Duration _fetchTimeout = Duration(seconds: 5);

  /// Fetch link preview for a URL
  ///
  /// Returns cached result if available, otherwise fetches from server.
  /// Returns null if fetch fails or URL is invalid.
  Future<LinkPreview?> fetchPreview(String url) async {
    // Validate URL
    if (!_isValidUrl(url)) {
      return null;
    }

    // Check cache first
    final cached = _getCached(url);
    if (cached != null) {
      return cached;
    }

    try {
      final preview = await _fetchFromServer(url).timeout(_fetchTimeout);
      if (preview != null) {
        _addToCache(url, preview);
      }
      return preview;
    } on TimeoutException {
      AppLogger.warning('Link preview fetch timed out', data: {'url': url});
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to fetch link preview',
        error: e,
        stackTrace: stackTrace,
        data: {'url': url},
      );
      return null;
    }
  }

  /// Extract URLs from text message
  static List<String> extractUrls(String text) {
    final urlPattern = RegExp(
      r'https?://[^\s<>\[\]{}|\\^`"]+',
      caseSensitive: false,
    );

    return urlPattern
        .allMatches(text)
        .map((m) => m.group(0)!)
        .where(_isValidUrl)
        .toList();
  }

  /// Check if URL is valid and should have preview fetched
  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return false;
      }
      // Skip certain file types that don't have OpenGraph
      final path = uri.path.toLowerCase();
      if (path.endsWith('.pdf') ||
          path.endsWith('.zip') ||
          path.endsWith('.tar') ||
          path.endsWith('.gz') ||
          path.endsWith('.exe') ||
          path.endsWith('.dmg')) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<LinkPreview?> _fetchFromServer(String url) async {
    // Try proto API first
    try {
      final client = await _getFilesClient();
      final response = await client.getUrlPreview(
        GetUrlPreviewRequest(url: url),
      );

      final preview = _parseProtoResponse(url, response);
      if (preview != null) return preview;
    } catch (e) {
      AppLogger.debug(
        'Proto URL preview failed, trying fallback',
        data: {'url': url, 'error': '$e'},
      );
    }

    // Fallback: legacy HTTP endpoint
    try {
      final token = await _getAccessToken();
      final uri = Uri.parse(
        '${ApiConfig.filesBaseUrl}/v1/preview',
      ).replace(queryParameters: {'url': url});

      final response = await http.get(
        uri,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return LinkPreview.fromJson(json);
      }
    } catch (e) {
      AppLogger.debug('Legacy URL preview failed', data: {'url': url});
    }

    // Final fallback: direct OG tag parsing
    return _fetchDirectly(url);
  }

  /// Parse proto [GetUrlPreviewResponse] into a [LinkPreview].
  LinkPreview? _parseProtoResponse(String url, GetUrlPreviewResponse response) {
    final ogData = response.hasOgData() ? response.ogData : null;
    if (ogData == null) return null;

    // Extract OG fields from the protobuf Struct
    final fields = ogData.fields;

    String? getString(String key) {
      final value = fields[key];
      if (value == null) return null;
      if (value.hasStringValue()) return value.stringValue;
      return null;
    }

    final title = getString('og:title') ?? getString('title');
    if (title == null || title.isEmpty) return null;

    String? imageUrl;
    if (response.hasOgImageMediaId() && response.ogImageMediaId.isNotEmpty) {
      imageUrl = FilesConfigService.buildContentUrlFrom(
        ApiConfig.filesBaseUrl,
        response.ogImageMediaId,
      );
    }
    imageUrl ??= getString('og:image');

    final baseUri = Uri.parse(url);

    return LinkPreview(
      url: url,
      title: title,
      description: getString('og:description') ?? getString('description'),
      imageUrl: imageUrl,
      siteName: getString('og:site_name') ?? baseUri.host,
      favicon: getString('favicon'),
    );
  }

  /// Fallback method to fetch OpenGraph tags directly from the URL
  Future<LinkPreview?> _fetchDirectly(String url) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (compatible; LinkPreviewBot/1.0; +https://antinvestor.com)',
            },
          )
          .timeout(_fetchTimeout);

      if (response.statusCode != 200) {
        return null;
      }

      final html = response.body;
      return _parseOpenGraphTags(url, html);
    } catch (e) {
      AppLogger.debug('Direct fetch failed for $url: $e');
      return null;
    }
  }

  /// HTML entity decoder instance
  static final _htmlUnescape = HtmlUnescape();

  /// Parse OpenGraph tags from HTML using proper HTML parsing
  ///
  /// This uses the html package for robust parsing that handles
  /// attribute order variations and HTML quirks.
  LinkPreview? _parseOpenGraphTags(String url, String htmlContent) {
    final document = html_parser.parse(htmlContent);

    // Helper to get meta content by property attribute
    String? getMetaProperty(String property) {
      return document
          .querySelector('meta[property="$property"]')
          ?.attributes['content']
          ?.trim();
    }

    // Helper to get meta content by name attribute
    String? getMetaName(String name) {
      return document
          .querySelector('meta[name="$name"]')
          ?.attributes['content']
          ?.trim();
    }

    // Helper to get link href by rel attribute
    String? getLinkHref(String rel) {
      // Try exact match first, then contains match for "shortcut icon" etc.
      return document.querySelector('link[rel="$rel"]')?.attributes['href'] ??
          document.querySelector('link[rel*="$rel"]')?.attributes['href'];
    }

    // Parse og:title, fallback to <title> tag
    var title = getMetaProperty('og:title');
    if (title == null || title.isEmpty) {
      title = document.querySelector('title')?.text.trim();
    }

    // Parse og:description, fallback to meta description
    var description = getMetaProperty('og:description');
    if (description == null || description.isEmpty) {
      description = getMetaName('description');
    }

    // Parse og:image
    var imageUrl = getMetaProperty('og:image');

    // Parse og:site_name
    final siteName = getMetaProperty('og:site_name');

    // Parse favicon
    var favicon = getLinkHref('icon');

    // Resolve relative URLs
    final baseUri = Uri.parse(url);
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      imageUrl = baseUri.resolve(imageUrl).toString();
    }
    if (favicon != null && !favicon.startsWith('http')) {
      favicon = baseUri.resolve(favicon).toString();
    }

    // Need at least a title to return a preview
    if (title == null || title.isEmpty) {
      return null;
    }

    return LinkPreview(
      url: url,
      title: _htmlUnescape.convert(title),
      description: description != null
          ? _htmlUnescape.convert(description)
          : null,
      imageUrl: imageUrl,
      siteName: siteName ?? baseUri.host,
      favicon: favicon,
    );
  }

  LinkPreview? _getCached(String url) {
    final cached = _cache[url];
    if (cached == null) return null;

    // Check if expired
    if (DateTime.now().difference(cached.timestamp) > _cacheTtl) {
      _cache.remove(url);
      return null;
    }

    return cached.preview;
  }

  void _addToCache(String url, LinkPreview preview) {
    // Evict oldest entries if cache is full
    if (_cache.length >= _maxCacheSize) {
      final oldest = _cache.entries.reduce(
        (a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b,
      );
      _cache.remove(oldest.key);
    }

    _cache[url] = _CachedPreview(preview: preview, timestamp: DateTime.now());
  }

  /// Clear cache (useful for testing or memory pressure)
  void clearCache() {
    _cache.clear();
  }
}

class _CachedPreview {
  _CachedPreview({required this.preview, required this.timestamp});
  final LinkPreview preview;
  final DateTime timestamp;
}

// Provider
final linkPreviewServiceProvider = Provider<LinkPreviewService>((ref) {
  final tokenManager = ref.watch(tokenManagerProvider);
  return LinkPreviewService(
    () async => tokenManager.accessToken,
    () => ref.read(filesServiceClientProvider.future),
  );
});

/// Provider to fetch link preview for a specific URL
final linkPreviewProvider = FutureProvider.family<LinkPreview?, String>((
  ref,
  url,
) async {
  final service = ref.watch(linkPreviewServiceProvider);
  return service.fetchPreview(url);
});

/// Provider to extract and fetch previews for all URLs in a message
final messageLinksPreviewProvider =
    FutureProvider.family<List<LinkPreview>, String>((ref, text) async {
      final service = ref.watch(linkPreviewServiceProvider);
      final urls = LinkPreviewService.extractUrls(text);

      if (urls.isEmpty) {
        return [];
      }

      // Only fetch preview for the first URL to avoid overwhelming the UI
      final preview = await service.fetchPreview(urls.first);
      return preview != null ? [preview] : [];
    });
