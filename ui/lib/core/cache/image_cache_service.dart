import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../logging/app_logger.dart';
import 'lru_cache.dart';

/// Memory limit for image cache in bytes (50MB)
const int _defaultMemoryLimitBytes = 50 * 1024 * 1024;

/// Default max age for cached files (30 days)
const Duration _defaultMaxAge = Duration(days: 30);

/// Maximum number of cached files on disk
const int _defaultMaxNrOfCacheObjects = 500;

/// Provider for ImageCacheService
final imageCacheServiceProvider = Provider<ImageCacheService>((ref) {
  return ImageCacheService();
});

/// Provider for profile image cache manager
final profileCacheManagerProvider = Provider<CacheManager>((ref) {
  return ImageCacheService.profileCacheManager;
});

/// Provider for media thumbnail cache manager
final mediaCacheManagerProvider = Provider<CacheManager>((ref) {
  return ImageCacheService.mediaCacheManager;
});

/// Service for managing image caching across the application.
///
/// Provides:
/// - LRU memory cache with 50MB limit
/// - Disk cache for offline access
/// - Separate caches for profile images and media thumbnails
/// - Cache invalidation support
/// - Preloading capabilities
class ImageCacheService {
  ImageCacheService({int memoryLimitBytes = _defaultMemoryLimitBytes})
    : _memoryCache = SizedLRUCache<String, Uint8List>(
        maxSizeBytes: memoryLimitBytes,
        sizeCalculator: (bytes) => bytes.length,
        onEvict: (key, value) {
          AppLogger.debug(
            'Image evicted from memory cache',
            data: {
              'url': key.length > 50 ? '${key.substring(0, 50)}...' : key,
              'size': value.length,
            },
          );
        },
      );

  /// Memory cache for decoded image data
  final SizedLRUCache<String, Uint8List> _memoryCache;

  /// Tracks URLs being preloaded to avoid duplicates
  final Set<String> _preloadingUrls = {};

  /// Tracks which URLs are profile images (for selective cache clearing)
  final Set<String> _profileImageUrls = {};

  /// Tracks which URLs are media thumbnails (for selective cache clearing)
  final Set<String> _mediaImageUrls = {};

  /// Cache manager for profile images (avatars)
  static final CacheManager profileCacheManager = CacheManager(
    Config(
      'profile_image_cache',
      stalePeriod: _defaultMaxAge,
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: 'profile_image_cache'),
      fileService: HttpFileService(),
    ),
  );

  /// Cache manager for media thumbnails (message images, videos)
  static final CacheManager mediaCacheManager = CacheManager(
    Config(
      'media_thumbnail_cache',
      stalePeriod: _defaultMaxAge,
      maxNrOfCacheObjects: _defaultMaxNrOfCacheObjects,
      repo: JsonCacheInfoRepository(databaseName: 'media_thumbnail_cache'),
      fileService: HttpFileService(),
    ),
  );

  /// Gets image bytes from memory cache.
  Uint8List? getFromMemory(String url) {
    return _memoryCache.get(url);
  }

  /// Stores image bytes in memory cache.
  void putInMemory(String url, Uint8List bytes) {
    _memoryCache.put(url, bytes);
  }

  /// Gets a file from the profile cache.
  Future<FileInfo?> getProfileImage(String url) async {
    try {
      return await profileCacheManager.getFileFromCache(url);
    } catch (e) {
      AppLogger.warning(
        'Failed to get profile image from cache',
        data: {'error': e.toString()},
      );
      return null;
    }
  }

  /// Gets a file from the media cache.
  Future<FileInfo?> getMediaThumbnail(String url) async {
    try {
      return await mediaCacheManager.getFileFromCache(url);
    } catch (e) {
      AppLogger.warning(
        'Failed to get media thumbnail from cache',
        data: {'error': e.toString()},
      );
      return null;
    }
  }

  /// Downloads and caches a profile image.
  Future<FileInfo> downloadProfileImage(String url) async {
    return profileCacheManager.downloadFile(url);
  }

  /// Downloads and caches a media thumbnail.
  Future<FileInfo> downloadMediaThumbnail(String url) async {
    return mediaCacheManager.downloadFile(url);
  }

  /// Invalidates a specific profile image from cache.
  Future<void> invalidateProfileImage(String url) async {
    _memoryCache.remove(url);
    _profileImageUrls.remove(url);
    await profileCacheManager.removeFile(url);
    AppLogger.debug('Profile image invalidated', data: {'url': url});
  }

  /// Invalidates a specific media thumbnail from cache.
  Future<void> invalidateMediaThumbnail(String url) async {
    _memoryCache.remove(url);
    _mediaImageUrls.remove(url);
    await mediaCacheManager.removeFile(url);
    AppLogger.debug('Media thumbnail invalidated', data: {'url': url});
  }

  /// Invalidates all profile images.
  Future<void> clearProfileCache() async {
    await profileCacheManager.emptyCache();
    // Clear tracked profile URLs from memory cache
    for (final url in _profileImageUrls) {
      _memoryCache.remove(url);
    }
    _profileImageUrls.clear();
    AppLogger.info('Profile image cache cleared');
  }

  /// Invalidates all media thumbnails.
  Future<void> clearMediaCache() async {
    await mediaCacheManager.emptyCache();
    // Clear tracked media URLs from memory cache
    for (final url in _mediaImageUrls) {
      _memoryCache.remove(url);
    }
    _mediaImageUrls.clear();
    AppLogger.info('Media thumbnail cache cleared');
  }

  /// Clears all image caches.
  Future<void> clearAll() async {
    _memoryCache.clear();
    _profileImageUrls.clear();
    _mediaImageUrls.clear();
    await Future.wait([
      profileCacheManager.emptyCache(),
      mediaCacheManager.emptyCache(),
    ]);
    AppLogger.info('All image caches cleared');
  }

  /// Preloads a list of profile image URLs.
  ///
  /// Useful for preloading visible contact avatars.
  Future<void> preloadProfileImages(List<String> urls) async {
    final urlsToLoad = urls
        .where((url) => !_preloadingUrls.contains(url))
        .toList();

    for (final url in urlsToLoad) {
      _preloadingUrls.add(url);
      _profileImageUrls.add(url); // Track for selective cache clearing
    }

    try {
      await Future.wait(
        urlsToLoad.map((url) => _preloadSingle(url, profileCacheManager)),
      );
    } finally {
      for (final url in urlsToLoad) {
        _preloadingUrls.remove(url);
      }
    }
  }

  /// Preloads a list of media thumbnail URLs.
  ///
  /// Useful for preloading visible message thumbnails.
  Future<void> preloadMediaThumbnails(List<String> urls) async {
    final urlsToLoad = urls
        .where((url) => !_preloadingUrls.contains(url))
        .toList();

    for (final url in urlsToLoad) {
      _preloadingUrls.add(url);
      _mediaImageUrls.add(url); // Track for selective cache clearing
    }

    try {
      await Future.wait(
        urlsToLoad.map((url) => _preloadSingle(url, mediaCacheManager)),
      );
    } finally {
      for (final url in urlsToLoad) {
        _preloadingUrls.remove(url);
      }
    }
  }

  Future<void> _preloadSingle(String url, CacheManager manager) async {
    try {
      // Check if already cached
      final cached = await manager.getFileFromCache(url);
      if (cached != null && cached.validTill.isAfter(DateTime.now())) {
        return; // Already cached and valid
      }

      // Download and cache
      await manager.downloadFile(url);
      AppLogger.debug('Image preloaded', data: {'url': url});
    } catch (e) {
      // Silent failure for preloading
      AppLogger.debug(
        'Failed to preload image',
        data: {'url': url, 'error': e.toString()},
      );
    }
  }

  /// Gets cache statistics.
  Map<String, dynamic> getStats() {
    return {
      'memoryUsedBytes': _memoryCache.currentSizeBytes,
      'memoryMaxBytes': _memoryCache.maxSize,
      'memoryUsagePercent':
          '${(_memoryCache.usageRatio * 100).toStringAsFixed(1)}%',
      'memoryCacheCount': _memoryCache.length,
    };
  }

  /// Gets the total disk cache size.
  Future<int> getDiskCacheSize() async {
    try {
      final cacheDir = await getApplicationCacheDirectory();

      Future<int> calculateDirSize(String dirName) async {
        final dir = Directory('${cacheDir.path}/$dirName');
        var dirSize = 0;
        // ignore: avoid_slow_async_io - async version is correct here
        if (await dir.exists()) {
          await for (final entity in dir.list(recursive: true)) {
            if (entity is File) {
              dirSize += await entity.length();
            }
          }
        }
        return dirSize;
      }

      final sizes = await Future.wait([
        calculateDirSize('profile_image_cache'),
        calculateDirSize('media_thumbnail_cache'),
      ]);

      return sizes.reduce((a, b) => a + b);
    } catch (e) {
      AppLogger.warning(
        'Failed to calculate disk cache size',
        data: {'error': e.toString()},
      );
      return 0;
    }
  }
}

/// Precaches an image from URL into Flutter's image cache.
///
/// This is useful for preloading images that will be displayed soon.
Future<void> precacheNetworkImage(
  BuildContext context,
  String url, {
  CacheManager? cacheManager,
}) async {
  try {
    final manager = cacheManager ?? ImageCacheService.mediaCacheManager;
    final file = await manager.getSingleFile(url);
    if (context.mounted) {
      await precacheImage(FileImage(file), context);
    }
  } catch (e) {
    AppLogger.debug(
      'Failed to precache image',
      data: {'url': url, 'error': e.toString()},
    );
  }
}

/// Helper class for managing image preloading with scroll controllers.
///
/// Use this instead of an extension to ensure proper listener cleanup:
/// ```dart
/// late final ImagePreloadHelper _preloadHelper;
///
/// @override
/// void initState() {
///   super.initState();
///   _preloadHelper = ImagePreloadHelper(
///     controller: _scrollController,
///     cacheService: imageCacheService,
///     getUrls: (start, end) => messages.sublist(start, end).map((m) => m.imageUrl).toList(),
///   );
/// }
///
/// @override
/// void dispose() {
///   _preloadHelper.dispose();
///   _scrollController.dispose();
///   super.dispose();
/// }
/// ```
class ImagePreloadHelper {
  ImagePreloadHelper({
    required this.controller,
    required this.cacheService,
    required this.getUrls,
    this.itemHeight = 80.0,
    this.preloadCount = 5,
    this.isProfileImages = false,
  }) {
    _listener = _onScroll;
    controller.addListener(_listener);
  }
  final ScrollController controller;
  final ImageCacheService cacheService;
  final List<String?> Function(int startIndex, int endIndex) getUrls;
  final double itemHeight;
  final int preloadCount;
  final bool isProfileImages;

  late final VoidCallback _listener;

  void _onScroll() {
    if (!controller.hasClients) return;

    final scrollPosition = controller.position;
    final viewportHeight = scrollPosition.viewportDimension;
    final scrollOffset = scrollPosition.pixels;

    // Calculate visible range and preload range
    final lastVisible = ((scrollOffset + viewportHeight) / itemHeight).ceil();

    // Preload items ahead of current view
    final preloadStart = lastVisible;
    final preloadEnd = lastVisible + preloadCount;

    final urls = getUrls(
      preloadStart,
      preloadEnd,
    ).where((url) => url != null).cast<String>().toList();

    if (urls.isNotEmpty) {
      if (isProfileImages) {
        cacheService.preloadProfileImages(urls);
      } else {
        cacheService.preloadMediaThumbnails(urls);
      }
    }
  }

  /// Removes the scroll listener. Call this in dispose().
  void dispose() {
    controller.removeListener(_listener);
  }
}
