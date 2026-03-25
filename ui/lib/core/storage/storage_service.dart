// ignore_for_file: avoid_slow_async_io

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../cache/image_cache_service.dart';
import '../db/database.dart';
import '../logging/app_logger.dart';
import '../settings/settings_service.dart';

part 'storage_service.g.dart';

/// Storage category breakdown
class StorageBreakdownItem {
  const StorageBreakdownItem({
    required this.category,
    required this.sizeBytes,
    required this.itemCount,
    this.icon,
  });

  final String category;
  final int sizeBytes;
  final int itemCount;
  final String? icon;

  String get formattedSize => StorageService.formatBytes(sizeBytes);
}

/// Per-chat storage usage
class ChatStorageUsage {
  const ChatStorageUsage({
    required this.roomId,
    required this.roomName,
    required this.totalSizeBytes,
    required this.mediaCount,
    required this.messageCount,
  });

  final String roomId;
  final String roomName;
  final int totalSizeBytes;
  final int mediaCount;
  final int messageCount;

  String get formattedSize => StorageService.formatBytes(totalSizeBytes);
}

/// Overall storage information
class StorageInfo {
  const StorageInfo({
    required this.totalUsedBytes,
    required this.availableBytes,
    required this.breakdown,
    required this.chatUsage,
  });

  final int totalUsedBytes;
  final int availableBytes;
  final List<StorageBreakdownItem> breakdown;
  final List<ChatStorageUsage> chatUsage;

  String get formattedTotalUsed => StorageService.formatBytes(totalUsedBytes);
  String get formattedAvailable => StorageService.formatBytes(availableBytes);

  double get usagePercent {
    final total = totalUsedBytes + availableBytes;
    if (total == 0) return 0;
    return totalUsedBytes / total;
  }
}

/// Auto-delete configuration
class AutoDeleteSettings {
  const AutoDeleteSettings({
    this.enabled = false,
    this.deleteAfterDays = 30,
    this.deleteMediaOnly = true,
  });

  factory AutoDeleteSettings.fromJson(Map<String, dynamic> json) =>
      AutoDeleteSettings(
        enabled: json['enabled'] as bool? ?? false,
        deleteAfterDays: json['deleteAfterDays'] as int? ?? 30,
        deleteMediaOnly: json['deleteMediaOnly'] as bool? ?? true,
      );

  final bool enabled;
  final int deleteAfterDays;
  final bool deleteMediaOnly;

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'deleteAfterDays': deleteAfterDays,
    'deleteMediaOnly': deleteMediaOnly,
  };
}

/// Settings keys for storage management
class StorageSettingsKeys {
  static const autoDeleteSettings = 'auto_delete_settings';
  static const storageWarningThresholdMb = 'storage_warning_threshold_mb';
  static const lastStorageCheck = 'last_storage_check';
}

/// Storage defaults
class StorageDefaults {
  static const storageWarningThresholdMb = 100; // Warn when < 100MB available
}

/// Provider for StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  final db = AppDatabase.instance;
  final imageCacheService = ref.watch(imageCacheServiceProvider);
  final settingsService = ref.watch(settingsServiceProvider);
  return StorageService(db, imageCacheService, settingsService);
});

/// Provider for storage info (async)
@riverpod
Future<StorageInfo> storageInfo(Ref ref) async {
  final service = ref.watch(storageServiceProvider);
  return service.getStorageInfo();
}

/// Provider for auto-delete settings
@riverpod
class AutoDeleteSettingsNotifier extends _$AutoDeleteSettingsNotifier {
  @override
  AutoDeleteSettings build() {
    final settingsService = ref.watch(settingsServiceProvider);
    final json = settingsService.getJson(
      StorageSettingsKeys.autoDeleteSettings,
    );
    if (json != null) {
      return AutoDeleteSettings.fromJson(json);
    }
    return const AutoDeleteSettings();
  }

  Future<void> updateSettings(AutoDeleteSettings settings) async {
    final settingsService = ref.read(settingsServiceProvider);
    await settingsService.setJson(
      StorageSettingsKeys.autoDeleteSettings,
      settings.toJson(),
    );
    state = settings;
  }

  Future<void> setEnabled(bool enabled) async {
    await updateSettings(
      AutoDeleteSettings(
        enabled: enabled,
        deleteAfterDays: state.deleteAfterDays,
        deleteMediaOnly: state.deleteMediaOnly,
      ),
    );
  }

  Future<void> setDeleteAfterDays(int days) async {
    await updateSettings(
      AutoDeleteSettings(
        enabled: state.enabled,
        deleteAfterDays: days,
        deleteMediaOnly: state.deleteMediaOnly,
      ),
    );
  }

  Future<void> setDeleteMediaOnly(bool mediaOnly) async {
    await updateSettings(
      AutoDeleteSettings(
        enabled: state.enabled,
        deleteAfterDays: state.deleteAfterDays,
        deleteMediaOnly: mediaOnly,
      ),
    );
  }
}

/// Service for managing storage calculations and cleanup
class StorageService {
  StorageService(
    this._database,
    this._imageCacheService,
    this._settingsService,
  );

  final AppDatabase _database;
  final ImageCacheService _imageCacheService;
  final SettingsService _settingsService;

  /// Format bytes to human-readable string
  static String formatBytes(int bytes) {
    if (bytes < 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get comprehensive storage information
  Future<StorageInfo> getStorageInfo() async {
    try {
      final breakdown = await _getStorageBreakdown();
      final chatUsage = await _getChatStorageUsage();
      final availableBytes = await _getAvailableStorage();

      final totalUsed = breakdown.fold<int>(
        0,
        (sum, item) => sum + item.sizeBytes,
      );

      return StorageInfo(
        totalUsedBytes: totalUsed,
        availableBytes: availableBytes,
        breakdown: breakdown,
        chatUsage: chatUsage,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to get storage info',
        error: e,
        stackTrace: stackTrace,
      );
      return const StorageInfo(
        totalUsedBytes: 0,
        availableBytes: 0,
        breakdown: [],
        chatUsage: [],
      );
    }
  }

  /// Get storage breakdown by category
  Future<List<StorageBreakdownItem>> _getStorageBreakdown() async {
    final items = <StorageBreakdownItem>[];

    // Database size
    final dbSize = await _getDatabaseSize();
    final messageCount = await _getMessageCount();
    items.add(
      StorageBreakdownItem(
        category: 'Database',
        sizeBytes: dbSize,
        itemCount: messageCount,
        icon: 'database',
      ),
    );

    // Image cache
    final imageCacheSize = await _imageCacheService.getDiskCacheSize();
    items.add(
      StorageBreakdownItem(
        category: 'Image Cache',
        sizeBytes: imageCacheSize,
        itemCount: 0, // Count not easily available
        icon: 'image',
      ),
    );

    // Media files (downloaded)
    final mediaInfo = await _getMediaFilesInfo();
    items.add(
      StorageBreakdownItem(
        category: 'Media Files',
        sizeBytes: mediaInfo['size'] ?? 0,
        itemCount: mediaInfo['count'] ?? 0,
        icon: 'video_file',
      ),
    );

    // Temporary files
    final tempInfo = await _getTempFilesInfo();
    items.add(
      StorageBreakdownItem(
        category: 'Temporary Files',
        sizeBytes: tempInfo['size'] ?? 0,
        itemCount: tempInfo['count'] ?? 0,
        icon: 'folder_delete',
      ),
    );

    return items;
  }

  /// Get per-chat storage usage
  Future<List<ChatStorageUsage>> _getChatStorageUsage() async {
    try {
      // Get all rooms with message counts and estimate sizes
      final rooms = await _database.select(_database.rooms).get();
      final chatUsageList = <ChatStorageUsage>[];

      for (final room in rooms) {
        final messages = await (_database.select(
          _database.roomEvents,
        )..where((e) => e.roomId.equals(room.id))).get();

        // Calculate total content size
        var totalSize = 0;
        var mediaCount = 0;

        for (final msg in messages) {
          // Estimate message size from content
          final contentSize = msg.content?.length ?? 0;
          totalSize += contentSize;

          // Count media messages (types 1-4 are image, video, audio, file)
          if (msg.type >= 1 && msg.type <= 4) {
            mediaCount++;
            // Add estimated file size from content metadata
            if (msg.content != null) {
              try {
                final content =
                    jsonDecode(msg.content!) as Map<String, dynamic>;
                totalSize += (content['fileSize'] as int?) ?? 0;
              } catch (_) {
                // Ignore JSON parse errors
              }
            }
          }
        }

        chatUsageList.add(
          ChatStorageUsage(
            roomId: room.id,
            roomName: room.name ?? 'Unknown Chat',
            totalSizeBytes: totalSize,
            mediaCount: mediaCount,
            messageCount: messages.length,
          ),
        );
      }

      // Sort by size descending
      chatUsageList.sort(
        (a, b) => b.totalSizeBytes.compareTo(a.totalSizeBytes),
      );

      return chatUsageList;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to get chat storage usage',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Get database file size
  Future<int> _getDatabaseSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbFile = File('${appDir.path}/chat_v1.db');
      if (await dbFile.exists()) {
        return await dbFile.length();
      }
    } catch (e) {
      AppLogger.warning('Failed to get database size', data: {'error': '$e'});
    }
    return 0;
  }

  /// Get total message count
  Future<int> _getMessageCount() async {
    try {
      final result = await _database.select(_database.roomEvents).get();
      return result.length;
    } catch (_) {
      return 0;
    }
  }

  /// Get media files info (size and count)
  Future<Map<String, int>> _getMediaFilesInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${appDir.path}/media');

      if (!await mediaDir.exists()) {
        return {'size': 0, 'count': 0};
      }

      var totalSize = 0;
      var count = 0;

      await for (final entity in mediaDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
          count++;
        }
      }

      return {'size': totalSize, 'count': count};
    } catch (e) {
      AppLogger.warning(
        'Failed to get media files info',
        data: {'error': '$e'},
      );
      return {'size': 0, 'count': 0};
    }
  }

  /// Get temporary files info
  Future<Map<String, int>> _getTempFilesInfo() async {
    try {
      final tempDir = await getTemporaryDirectory();
      var totalSize = 0;
      var count = 0;

      await for (final entity in tempDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
          count++;
        }
      }

      return {'size': totalSize, 'count': count};
    } catch (e) {
      AppLogger.warning('Failed to get temp files info', data: {'error': '$e'});
      return {'size': 0, 'count': 0};
    }
  }

  /// Get available storage on device
  Future<int> _getAvailableStorage() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final stat = await appDir.stat();
      // Note: FileStat doesn't provide free space, use platform-specific approach
      // For now, return a placeholder or use disk_space package if needed
      // This is a simplified implementation
      return stat.size > 0 ? 1024 * 1024 * 1024 : 0; // 1GB placeholder
    } catch (_) {
      return 0;
    }
  }

  /// Clear all caches (image cache + temp files)
  Future<void> clearCache() async {
    try {
      // Clear image cache
      await _imageCacheService.clearAll();

      // Clear temp directory
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list()) {
          try {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
            }
          } catch (_) {
            // Ignore individual file deletion errors
          }
        }
      }

      AppLogger.info('Cache cleared successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to clear cache',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete old media files (older than specified days)
  Future<int> deleteOldMedia({int olderThanDays = 30}) async {
    var deletedCount = 0;
    final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
    final cutoffTimestamp = cutoffDate.millisecondsSinceEpoch;

    try {
      // Delete old media messages from database
      // Media types are: 1=image, 2=video, 3=audio, 4=file
      final oldMediaMessages =
          await (_database.select(_database.roomEvents)..where(
                (e) =>
                    e.type.isIn([1, 2, 3, 4]) &
                    e.createdAt.isSmallerThan(Variable(cutoffTimestamp)),
              ))
              .get();

      for (final msg in oldMediaMessages) {
        // Try to delete the local file if it exists
        if (msg.content != null) {
          try {
            final content = jsonDecode(msg.content!) as Map<String, dynamic>;
            final localPath = content['localPath'] as String?;
            if (localPath != null) {
              final file = File(localPath);
              if (await file.exists()) {
                await file.delete();
                deletedCount++;
              }
            }
          } catch (_) {
            // Ignore JSON parse or file deletion errors
          }
        }

        // Mark message as having no local file
        await (_database.update(
          _database.roomEvents,
        )..where((e) => e.id.equals(msg.id))).write(
          RoomEventsCompanion(
            content: Value(_updateContentRemoveLocalPath(msg.content)),
          ),
        );
      }

      // Also delete old files from media directory
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${appDir.path}/media');

      if (await mediaDir.exists()) {
        await for (final entity in mediaDir.list(recursive: true)) {
          if (entity is File) {
            final stat = await entity.stat();
            if (stat.modified.isBefore(cutoffDate)) {
              await entity.delete();
              deletedCount++;
            }
          }
        }
      }

      AppLogger.info(
        'Deleted old media',
        data: {'count': deletedCount, 'olderThanDays': olderThanDays},
      );

      return deletedCount;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to delete old media',
        error: e,
        stackTrace: stackTrace,
      );
      return deletedCount;
    }
  }

  /// Remove localPath from content JSON
  String? _updateContentRemoveLocalPath(String? content) {
    if (content == null) return null;
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      map.remove('localPath');
      return jsonEncode(map);
    } catch (_) {
      return content;
    }
  }

  /// Run auto-delete if enabled
  Future<void> runAutoDelete() async {
    final json = _settingsService.getJson(
      StorageSettingsKeys.autoDeleteSettings,
    );
    if (json == null) return;

    final settings = AutoDeleteSettings.fromJson(json);
    if (!settings.enabled) return;

    AppLogger.info(
      'Running auto-delete',
      data: {
        'deleteAfterDays': settings.deleteAfterDays,
        'mediaOnly': settings.deleteMediaOnly,
      },
    );

    await deleteOldMedia(olderThanDays: settings.deleteAfterDays);
  }

  /// Check if storage is low and should show warning
  Future<bool> shouldShowStorageWarning() async {
    try {
      final thresholdMb = _settingsService.getInt(
        StorageSettingsKeys.storageWarningThresholdMb,
        defaultValue: StorageDefaults.storageWarningThresholdMb,
      );

      final storageInfo = await getStorageInfo();
      final availableMb = storageInfo.availableBytes / (1024 * 1024);

      return availableMb < thresholdMb;
    } catch (_) {
      return false;
    }
  }

  /// Export chat data for a specific room
  Future<String> exportChatData(String roomId) async {
    try {
      // Get room info
      final room = await (_database.select(
        _database.rooms,
      )..where((r) => r.id.equals(roomId))).getSingleOrNull();

      if (room == null) {
        throw Exception('Room not found');
      }

      // Get all messages
      final messages =
          await (_database.select(_database.roomEvents)
                ..where((e) => e.roomId.equals(roomId))
                ..orderBy([(e) => OrderingTerm.asc(e.createdAt)]))
              .get();

      // Get room members
      final members = await (_database.select(
        _database.roomSubscriptions,
      )..where((m) => m.roomId.equals(roomId))).get();

      // Build export data
      final exportData = {
        'exportedAt': DateTime.now().toIso8601String(),
        'room': {'id': room.id, 'name': room.name, 'type': room.type},
        'members': members
            .map(
              (m) => {
                'id': m.id,
                'profileId': m.profileId,
                'role': m.role,
                'joinedAt': m.joinedAt,
              },
            )
            .toList(),
        'messages': messages
            .map(
              (m) => {
                'id': m.id,
                'senderId': m.senderId,
                'type': m.type,
                'content': m.content != null ? jsonDecode(m.content!) : null,
                'createdAt': m.createdAt,
                'serverTs': m.serverTs,
              },
            )
            .toList(),
        'totalMessages': messages.length,
      };

      return const JsonEncoder.withIndent('  ').convert(exportData);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to export chat data',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Export all chats data
  Future<String> exportAllChatsData() async {
    try {
      final rooms = await _database.select(_database.rooms).get();
      final allChats = <Map<String, dynamic>>[];

      for (final room in rooms) {
        final messages =
            await (_database.select(_database.roomEvents)
                  ..where((e) => e.roomId.equals(room.id))
                  ..orderBy([(e) => OrderingTerm.asc(e.createdAt)]))
                .get();

        allChats.add({
          'room': {'id': room.id, 'name': room.name, 'type': room.type},
          'messages': messages
              .map(
                (m) => {
                  'id': m.id,
                  'senderId': m.senderId,
                  'type': m.type,
                  'content': m.content != null ? jsonDecode(m.content!) : null,
                  'createdAt': m.createdAt,
                },
              )
              .toList(),
          'totalMessages': messages.length,
        });
      }

      final exportData = {
        'exportedAt': DateTime.now().toIso8601String(),
        'totalChats': allChats.length,
        'chats': allChats,
      };

      return const JsonEncoder.withIndent('  ').convert(exportData);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to export all chats data',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete all data for a specific chat
  Future<void> deleteChatData(String roomId) async {
    try {
      // Delete messages
      await (_database.delete(
        _database.roomEvents,
      )..where((e) => e.roomId.equals(roomId))).go();

      // Delete room members
      await (_database.delete(
        _database.roomSubscriptions,
      )..where((m) => m.roomId.equals(roomId))).go();

      // Delete room
      await (_database.delete(
        _database.rooms,
      )..where((r) => r.id.equals(roomId))).go();

      AppLogger.info('Chat data deleted', data: {'roomId': roomId});
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to delete chat data',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
