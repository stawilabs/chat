import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/media_cache_manager.dart';
import '../../../core/navigation/navigation_helper.dart';
import '../../../core/theme/app_theme.dart';

class CacheSettingsScreen extends ConsumerStatefulWidget {
  const CacheSettingsScreen({super.key});

  @override
  ConsumerState<CacheSettingsScreen> createState() =>
      _CacheSettingsScreenState();
}

class _CacheSettingsScreenState extends ConsumerState<CacheSettingsScreen> {
  bool _isClearing = false;

  @override
  Widget build(BuildContext context) {
    final cacheStatsAsync = ref.watch(mediaCacheStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Cache'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigateBack('/settings/storage'),
        ),
      ),
      body: cacheStatsAsync.when(
        data: (stats) => _buildContent(context, stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading cache stats: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(mediaCacheStatsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MediaCacheStats stats) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Cache Usage Card
        _buildCacheUsageCard(context, stats),

        const SizedBox(height: 16),

        // Cache Size Setting
        _buildSettingsSection(
          context,
          title: 'Cache Settings',
          items: [
            _buildCacheSizeSelector(context, stats),
            _buildPerRoomCacheToggle(context),
          ],
        ),

        // Storage Warning (if low)
        if (stats.isStorageLow) _buildStorageWarning(context, stats),

        const SizedBox(height: 16),

        // Cache Actions
        _buildSettingsSection(
          context,
          title: 'Actions',
          items: [_buildClearCacheButton(context, stats)],
        ),

        // Per-Room Cache Stats (if enabled and available)
        if (stats.roomStats != null && stats.roomStats!.isNotEmpty)
          _buildRoomCacheSection(context, stats),
      ],
    );
  }

  Widget _buildCacheUsageCard(BuildContext context, MediaCacheStats stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.storage, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Cache Usage',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Usage Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: stats.usageRatio,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                stats.usageRatio > 0.9
                    ? Colors.red.shade300
                    : stats.usageRatio > 0.7
                    ? Colors.orange.shade300
                    : Colors.white,
              ),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),

          // Size Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${stats.usedSizeFormatted} used',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${stats.maxSizeFormatted} max',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // File Count
          Text(
            '${stats.fileCount} files cached',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheSizeSelector(BuildContext context, MediaCacheStats stats) {
    final currentSizeMB = stats.maxSizeBytes ~/ (1024 * 1024);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.data_usage, color: AppTheme.primaryGreen),
        ),
        title: Text(
          'Maximum Cache Size',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          _formatCacheSize(currentSizeMB),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: () => _showCacheSizeDialog(currentSizeMB),
      ),
    );
  }

  Widget _buildPerRoomCacheToggle(BuildContext context) {
    final cacheManager = ref.read(mediaCacheManagerProvider);
    final isEnabled = cacheManager.isPerRoomCacheEnabled;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.folder_special, color: AppTheme.primaryGreen),
        ),
        title: Text(
          'Per-Room Cache',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'Organize cache by room for selective clearing',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        value: isEnabled,
        onChanged: (value) async {
          await cacheManager.setPerRoomCacheEnabled(value);
          ref.invalidate(mediaCacheStatsProvider);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildStorageWarning(BuildContext context, MediaCacheStats stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low Device Storage',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Only ${stats.availableStorageFormatted} available. '
                  'Consider clearing cache to free up space.',
                  style: TextStyle(fontSize: 13, color: Colors.orange.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearCacheButton(BuildContext context, MediaCacheStats stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isClearing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_sweep, color: Colors.red),
        ),
        title: Text(
          'Clear All Cache',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.red,
          ),
        ),
        subtitle: Text(
          'Free up ${stats.usedSizeFormatted} by clearing all cached media',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        enabled: !_isClearing && stats.usedSizeBytes > 0,
        onTap: () => _confirmClearCache(stats),
      ),
    );
  }

  Widget _buildRoomCacheSection(BuildContext context, MediaCacheStats stats) {
    final sortedRooms = stats.roomStats!.entries.toList()
      ..sort((a, b) => b.value.sizeBytes.compareTo(a.value.sizeBytes));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Cache by Room',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
        ...sortedRooms
            .take(10)
            .map((entry) => _buildRoomCacheItem(context, entry.value)),
        if (sortedRooms.length > 10)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '+ ${sortedRooms.length - 10} more rooms',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _buildRoomCacheItem(BuildContext context, RoomCacheStats roomStats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
          child: const Icon(Icons.chat, color: AppTheme.primaryGreen, size: 20),
        ),
        title: Text(
          'Room ${roomStats.roomId.substring(0, 8)}...',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        subtitle: Text(
          '${roomStats.fileCount} files',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              roomStats.sizeFormatted,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _confirmClearRoomCache(roomStats),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  String _formatCacheSize(int sizeMB) {
    if (sizeMB >= 1024) {
      return '${(sizeMB / 1024).toStringAsFixed(1)} GB';
    }
    return '$sizeMB MB';
  }

  Future<void> _showCacheSizeDialog(int currentSizeMB) async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maximum Cache Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: cacheSizeOptionsMB.map((sizeMB) {
            final isSelected =
                sizeMB == currentSizeMB ||
                (sizeMB == 500 && currentSizeMB == 500);
            return ListTile(
              title: Text(_formatCacheSize(sizeMB)),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppTheme.primaryGreen)
                  : null,
              onTap: () => Navigator.of(context).pop(sizeMB),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null) {
      final cacheManager = ref.read(mediaCacheManagerProvider);
      await cacheManager.setMaxCacheSize(selected * 1024 * 1024);
      ref.invalidate(mediaCacheStatsProvider);
    }
  }

  Future<void> _confirmClearCache(MediaCacheStats stats) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Cache'),
        content: Text(
          'This will delete all ${stats.fileCount} cached media files '
          '(${stats.usedSizeFormatted}). Downloaded media will need to be '
          're-downloaded when viewed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _clearAllCache();
    }
  }

  Future<void> _confirmClearRoomCache(RoomCacheStats roomStats) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Room Cache'),
        content: Text(
          'This will delete ${roomStats.fileCount} cached files '
          '(${roomStats.sizeFormatted}) for this room.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final cacheManager = ref.read(mediaCacheManagerProvider);
      await cacheManager.clearRoomCache(roomStats.roomId);
      ref.invalidate(mediaCacheStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Room cache cleared')));
      }
    }
  }

  Future<void> _clearAllCache() async {
    setState(() => _isClearing = true);

    try {
      final cacheManager = ref.read(mediaCacheManagerProvider);
      await cacheManager.clearAllCache();
      ref.invalidate(mediaCacheStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to clear cache: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }
}
