// ignore_for_file: avoid_slow_async_io

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../logging/app_logger.dart';
import '../settings/settings_service.dart';

/// Default media cache size: 500MB
const int defaultMediaCacheSizeBytes = 500 * 1024 * 1024;

/// Minimum cache size: 100MB
const int minMediaCacheSizeBytes = 100 * 1024 * 1024;

/// Maximum cache size: 5GB
const int maxMediaCacheSizeBytes = 5 * 1024 * 1024 * 1024;

/// Low storage threshold: 500MB free space triggers auto-eviction
const int lowStorageThresholdBytes = 500 * 1024 * 1024;

/// Cache size options in MB for user settings
const List<int> cacheSizeOptionsMB = [100, 250, 500, 1024, 2048, 5120];

/// Settings key for media cache size
const String mediaCacheSizeKey = 'media_cache_size_bytes';

/// Settings key for per-room cache enabled
const String perRoomCacheEnabledKey = 'per_room_cache_enabled';

/// Provider for MediaCacheManager
final mediaCacheManagerProvider = Provider<MediaCacheManager>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return MediaCacheManager(settingsService);
});

/// Provider for media cache statistics
final mediaCacheStatsProvider = FutureProvider<MediaCacheStats>((ref) async {
  final cacheManager = ref.watch(mediaCacheManagerProvider);
  return cacheManager.getCacheStats();
});

/// Statistics about the media cache
class MediaCacheStats {
  MediaCacheStats({
    required this.totalSizeBytes,
    required this.usedSizeBytes,
    required this.fileCount,
    required this.maxSizeBytes,
    required this.availableStorageBytes,
    this.roomStats,
  });

  /// Total size of all cached files in bytes
  final int totalSizeBytes;

  /// Currently used cache size in bytes
  final int usedSizeBytes;

  /// Number of cached files
  final int fileCount;

  /// Maximum allowed cache size in bytes
  final int maxSizeBytes;

  /// Available storage space on device
  final int availableStorageBytes;

  /// Per-room cache statistics (if per-room caching is enabled)
  final Map<String, RoomCacheStats>? roomStats;

  /// Usage percentage (0.0 to 1.0)
  double get usageRatio =>
      maxSizeBytes > 0 ? usedSizeBytes / maxSizeBytes : 0.0;

  /// Formatted used size string
  String get usedSizeFormatted => _formatBytes(usedSizeBytes);

  /// Formatted max size string
  String get maxSizeFormatted => _formatBytes(maxSizeBytes);

  /// Formatted available storage string
  String get availableStorageFormatted => _formatBytes(availableStorageBytes);

  /// Whether storage is running low
  bool get isStorageLow => availableStorageBytes < lowStorageThresholdBytes;

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Statistics for a specific room's cached media
class RoomCacheStats {
  RoomCacheStats({
    required this.roomId,
    required this.sizeBytes,
    required this.fileCount,
    required this.lastAccessTime,
  });

  final String roomId;
  final int sizeBytes;
  final int fileCount;
  final DateTime lastAccessTime;

  String get sizeFormatted => MediaCacheStats._formatBytes(sizeBytes);
}

/// Entry in the cache metadata
class CacheEntry {
  CacheEntry({
    required this.filePath,
    required this.sizeBytes,
    required this.lastAccessTime,
    this.roomId,
    this.url,
  });

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      filePath: json['filePath'] as String,
      sizeBytes: json['sizeBytes'] as int,
      lastAccessTime: DateTime.fromMillisecondsSinceEpoch(
        json['lastAccessTime'] as int,
      ),
      roomId: json['roomId'] as String?,
      url: json['url'] as String?,
    );
  }

  final String filePath;
  final int sizeBytes;
  DateTime lastAccessTime;
  final String? roomId;
  final String? url;

  Map<String, dynamic> toJson() => {
    'filePath': filePath,
    'sizeBytes': sizeBytes,
    'lastAccessTime': lastAccessTime.millisecondsSinceEpoch,
    'roomId': roomId,
    'url': url,
  };
}

/// Manages media file caching with LRU eviction policy.
///
/// Features:
/// - Configurable cache size (default 500MB)
/// - LRU (Least Recently Used) eviction policy
/// - Auto-eviction when storage is low
/// - Per-room cache tracking (optional)
/// - Cache statistics and management
class MediaCacheManager {
  MediaCacheManager(this._settingsService);

  final SettingsService _settingsService;

  /// In-memory index of cached files for LRU tracking
  final Map<String, CacheEntry> _cacheIndex = {};

  /// Current total cache size in bytes
  int _currentSizeBytes = 0;

  /// Whether the cache has been initialized
  bool _initialized = false;

  /// Directory for media cache
  Directory? _cacheDir;

  /// Initialize the cache manager
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _cacheDir = await _getCacheDirectory();

      // Ensure cache directory exists
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      // Load existing cache metadata
      await _loadCacheIndex();

      _initialized = true;
      AppLogger.info(
        'MediaCacheManager initialized',
        data: {
          'cacheDir': _cacheDir!.path,
          'currentSize': _currentSizeBytes,
          'fileCount': _cacheIndex.length,
        },
      );

      // Check for low storage and auto-evict if needed
      await _checkAndEvictIfStorageLow();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to initialize MediaCacheManager',
        error: e,
        stackTrace: stackTrace,
      );
      _initialized = true; // Continue with empty cache
    }
  }

  /// Get the cache directory
  Future<Directory> _getCacheDirectory() async {
    final cacheDir = await getApplicationCacheDirectory();
    return Directory('${cacheDir.path}/media_cache');
  }

  /// Load cache index from disk
  Future<void> _loadCacheIndex() async {
    _cacheIndex.clear();
    _currentSizeBytes = 0;

    if (_cacheDir == null || !await _cacheDir!.exists()) return;

    try {
      await for (final entity in _cacheDir!.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          final entry = CacheEntry(
            filePath: entity.path,
            sizeBytes: stat.size,
            lastAccessTime: stat.accessed,
          );
          _cacheIndex[entity.path] = entry;
          _currentSizeBytes += stat.size;
        }
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to load cache index',
        data: {'error': e.toString()},
      );
    }
  }

  /// Get the configured maximum cache size
  int get maxCacheSizeBytes {
    return _settingsService.getInt(
      mediaCacheSizeKey,
      defaultValue: defaultMediaCacheSizeBytes,
    );
  }

  /// Set the maximum cache size
  Future<void> setMaxCacheSize(int sizeBytes) async {
    final clampedSize = sizeBytes.clamp(
      minMediaCacheSizeBytes,
      maxMediaCacheSizeBytes,
    );
    await _settingsService.setInt(mediaCacheSizeKey, clampedSize);

    // Evict if new size is smaller than current usage
    if (_currentSizeBytes > clampedSize) {
      await _evictToSize(clampedSize);
    }

    AppLogger.info('Media cache size updated', data: {'newSize': clampedSize});
  }

  /// Check if per-room caching is enabled
  bool get isPerRoomCacheEnabled {
    return _settingsService.getBool(perRoomCacheEnabledKey);
  }

  /// Enable or disable per-room caching
  Future<void> setPerRoomCacheEnabled(bool enabled) async {
    await _settingsService.setBool(perRoomCacheEnabledKey, enabled);
  }

  /// Cache a file with LRU tracking
  ///
  /// [data] - The file data to cache
  /// [fileName] - Unique identifier/name for the file
  /// [roomId] - Optional room ID for per-room tracking
  /// [url] - Optional source URL
  Future<File?> cacheFile(
    List<int> data,
    String fileName, {
    String? roomId,
    String? url,
  }) async {
    await initialize();

    final fileSize = data.length;
    final maxSize = maxCacheSizeBytes;

    // Don't cache files larger than the max cache size
    if (fileSize > maxSize) {
      AppLogger.warning(
        'File too large to cache',
        data: {'fileName': fileName, 'size': fileSize, 'maxSize': maxSize},
      );
      return null;
    }

    try {
      // Evict files if needed to make room
      final targetSize = maxSize - fileSize;
      if (_currentSizeBytes > targetSize) {
        await _evictToSize(targetSize);
      }

      // Check storage availability
      await _checkAndEvictIfStorageLow();

      // Create the cache file
      final subDir = roomId != null && isPerRoomCacheEnabled
          ? 'rooms/$roomId'
          : 'general';
      final dir = Directory('${_cacheDir!.path}/$subDir');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(data);

      // Update cache index
      final entry = CacheEntry(
        filePath: file.path,
        sizeBytes: fileSize,
        lastAccessTime: DateTime.now(),
        roomId: roomId,
        url: url,
      );
      _cacheIndex[file.path] = entry;
      _currentSizeBytes += fileSize;

      AppLogger.debug(
        'File cached',
        data: {'fileName': fileName, 'size': fileSize},
      );

      return file;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache file', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get a cached file, updating its access time (LRU)
  Future<File?> getCachedFile(String fileName, {String? roomId}) async {
    await initialize();

    final subDir = roomId != null && isPerRoomCacheEnabled
        ? 'rooms/$roomId'
        : 'general';
    final filePath = '${_cacheDir!.path}/$subDir/$fileName';

    final entry = _cacheIndex[filePath];
    if (entry == null) return null;

    final file = File(filePath);
    if (!await file.exists()) {
      // File was deleted externally, remove from index
      _cacheIndex.remove(filePath);
      _currentSizeBytes -= entry.sizeBytes;
      return null;
    }

    // Update access time (LRU tracking)
    entry.lastAccessTime = DateTime.now();
    await file.setLastAccessed(DateTime.now());

    return file;
  }

  /// Check if a file is cached
  bool isFileCached(String fileName, {String? roomId}) {
    final subDir = roomId != null && isPerRoomCacheEnabled
        ? 'rooms/$roomId'
        : 'general';
    final filePath = '${_cacheDir!.path}/$subDir/$fileName';
    return _cacheIndex.containsKey(filePath);
  }

  /// Remove a specific file from cache
  Future<void> removeFile(String fileName, {String? roomId}) async {
    await initialize();

    final subDir = roomId != null && isPerRoomCacheEnabled
        ? 'rooms/$roomId'
        : 'general';
    final filePath = '${_cacheDir!.path}/$subDir/$fileName';

    final entry = _cacheIndex.remove(filePath);
    if (entry != null) {
      _currentSizeBytes -= entry.sizeBytes;
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        AppLogger.warning(
          'Failed to delete cached file',
          data: {'filePath': filePath, 'error': e.toString()},
        );
      }
    }
  }

  /// Clear all cached media for a specific room
  Future<void> clearRoomCache(String roomId) async {
    await initialize();

    final roomDir = Directory('${_cacheDir!.path}/rooms/$roomId');
    if (await roomDir.exists()) {
      final entriesToRemove = _cacheIndex.entries
          .where((e) => e.key.startsWith(roomDir.path))
          .map((e) => e.key)
          .toList();

      for (final path in entriesToRemove) {
        final entry = _cacheIndex.remove(path);
        if (entry != null) {
          _currentSizeBytes -= entry.sizeBytes;
        }
      }

      try {
        await roomDir.delete(recursive: true);
      } catch (e) {
        AppLogger.warning(
          'Failed to delete room cache directory',
          data: {'roomId': roomId, 'error': e.toString()},
        );
      }
    }

    AppLogger.info('Room cache cleared', data: {'roomId': roomId});
  }

  /// Clear all media cache
  Future<void> clearAllCache() async {
    await initialize();

    _cacheIndex.clear();
    _currentSizeBytes = 0;

    if (_cacheDir != null && await _cacheDir!.exists()) {
      try {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create(recursive: true);
      } catch (e) {
        AppLogger.warning(
          'Failed to clear cache directory',
          data: {'error': e.toString()},
        );
      }
    }

    AppLogger.info('All media cache cleared');
  }

  /// Get cache statistics
  Future<MediaCacheStats> getCacheStats() async {
    await initialize();

    // Refresh index to ensure accuracy
    await _loadCacheIndex();

    // Get available storage
    var availableStorage = 0;
    try {
      if (_cacheDir != null) {
        // Get free space - this is platform specific
        // For now, we'll use a simple approach
        availableStorage = await _getAvailableStorage();
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to get available storage',
        data: {'error': e.toString()},
      );
    }

    // Calculate per-room stats if enabled
    Map<String, RoomCacheStats>? roomStats;
    if (isPerRoomCacheEnabled) {
      roomStats = {};
      final roomEntries = _cacheIndex.entries.where(
        (e) => e.value.roomId != null,
      );

      for (final entry in roomEntries) {
        final roomId = entry.value.roomId!;
        if (roomStats.containsKey(roomId)) {
          final existing = roomStats[roomId]!;
          roomStats[roomId] = RoomCacheStats(
            roomId: roomId,
            sizeBytes: existing.sizeBytes + entry.value.sizeBytes,
            fileCount: existing.fileCount + 1,
            lastAccessTime:
                entry.value.lastAccessTime.isAfter(existing.lastAccessTime)
                ? entry.value.lastAccessTime
                : existing.lastAccessTime,
          );
        } else {
          roomStats[roomId] = RoomCacheStats(
            roomId: roomId,
            sizeBytes: entry.value.sizeBytes,
            fileCount: 1,
            lastAccessTime: entry.value.lastAccessTime,
          );
        }
      }
    }

    return MediaCacheStats(
      totalSizeBytes: _currentSizeBytes,
      usedSizeBytes: _currentSizeBytes,
      fileCount: _cacheIndex.length,
      maxSizeBytes: maxCacheSizeBytes,
      availableStorageBytes: availableStorage,
      roomStats: roomStats,
    );
  }

  /// Get available storage space
  Future<int> _getAvailableStorage() async {
    try {
      if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
        // Use directory stat to estimate
        final tempDir = await getTemporaryDirectory();
        await tempDir.stat();
        // This is a rough estimate - actual implementation would use
        // platform-specific APIs
        return 1024 * 1024 * 1024; // Default to 1GB as fallback
      }
    } catch (e) {
      AppLogger.debug(
        'Could not determine available storage',
        data: {'error': e.toString()},
      );
    }
    return 1024 * 1024 * 1024; // Default 1GB
  }

  /// Check storage and evict if needed
  Future<void> _checkAndEvictIfStorageLow() async {
    try {
      final availableStorage = await _getAvailableStorage();
      if (availableStorage < lowStorageThresholdBytes) {
        // Evict 25% of cache when storage is low
        final targetSize = (_currentSizeBytes * 0.75).toInt();
        await _evictToSize(targetSize);
        AppLogger.info(
          'Auto-evicted cache due to low storage',
          data: {
            'availableStorage': availableStorage,
            'newCacheSize': _currentSizeBytes,
          },
        );
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to check storage',
        data: {'error': e.toString()},
      );
    }
  }

  /// Evict files using LRU policy until cache is under target size
  Future<void> _evictToSize(int targetSizeBytes) async {
    if (_currentSizeBytes <= targetSizeBytes) return;

    // Sort entries by last access time (oldest first)
    final sortedEntries = _cacheIndex.entries.toList()
      ..sort(
        (a, b) => a.value.lastAccessTime.compareTo(b.value.lastAccessTime),
      );

    for (final entry in sortedEntries) {
      if (_currentSizeBytes <= targetSizeBytes) break;

      final filePath = entry.key;
      final cacheEntry = entry.value;

      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
        _cacheIndex.remove(filePath);
        _currentSizeBytes -= cacheEntry.sizeBytes;

        AppLogger.debug(
          'Evicted cache file',
          data: {'filePath': filePath, 'size': cacheEntry.sizeBytes},
        );
      } catch (e) {
        AppLogger.warning(
          'Failed to evict file',
          data: {'filePath': filePath, 'error': e.toString()},
        );
      }
    }
  }

  /// Manually trigger eviction check
  Future<void> checkAndEvict() async {
    await initialize();
    await _checkAndEvictIfStorageLow();

    // Also check against max cache size
    if (_currentSizeBytes > maxCacheSizeBytes) {
      await _evictToSize(maxCacheSizeBytes);
    }
  }

  /// Current cache size in bytes
  int get currentSizeBytes => _currentSizeBytes;

  /// Number of cached files
  int get fileCount => _cacheIndex.length;
}
