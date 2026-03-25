import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/media_compression_service.dart';
import '../../../core/navigation/navigation_helper.dart';
import '../../../core/settings/settings_service.dart';
import '../../../core/theme/app_theme.dart';

/// Settings screen for media compression options
class MediaCompressionSettingsScreen extends ConsumerStatefulWidget {
  const MediaCompressionSettingsScreen({super.key});

  @override
  ConsumerState<MediaCompressionSettingsScreen> createState() =>
      _MediaCompressionSettingsScreenState();
}

class _MediaCompressionSettingsScreenState
    extends ConsumerState<MediaCompressionSettingsScreen> {
  late bool _compressionEnabled;
  late int _imageQuality;
  late CompressionQualityPreset _videoQuality;
  late bool _showSizeEstimate;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final settingsService = ref.read(settingsServiceProvider);

    _compressionEnabled = settingsService.getBool(
      CompressionSettingsKeys.compressionEnabled,
      defaultValue: CompressionDefaults.compressionEnabled,
    );
    _imageQuality = settingsService.getInt(
      CompressionSettingsKeys.imageQuality,
      defaultValue: CompressionDefaults.imageQuality,
    );
    final videoQualityStr = settingsService.getString(
      CompressionSettingsKeys.videoQuality,
      defaultValue: CompressionQualityPreset.medium.name,
    );
    _videoQuality = CompressionQualityPreset.fromString(videoQualityStr);
    _showSizeEstimate = settingsService.getBool(
      CompressionSettingsKeys.showSizeEstimate,
      defaultValue: CompressionDefaults.showSizeEstimate,
    );
  }

  Future<void> _saveCompressionEnabled(bool value) async {
    setState(() => _compressionEnabled = value);
    await ref
        .read(settingsServiceProvider)
        .setBool(CompressionSettingsKeys.compressionEnabled, value);
  }

  Future<void> _saveImageQuality(int value) async {
    setState(() => _imageQuality = value);
    await ref
        .read(settingsServiceProvider)
        .setInt(CompressionSettingsKeys.imageQuality, value);
  }

  Future<void> _saveVideoQuality(CompressionQualityPreset value) async {
    setState(() => _videoQuality = value);
    await ref
        .read(settingsServiceProvider)
        .setString(CompressionSettingsKeys.videoQuality, value.name);
  }

  Future<void> _saveShowSizeEstimate(bool value) async {
    setState(() => _showSizeEstimate = value);
    await ref
        .read(settingsServiceProvider)
        .setBool(CompressionSettingsKeys.showSizeEstimate, value);
  }

  Future<void> _clearCompressionCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Compression Cache'),
        content: const Text(
          'This will delete all temporary files created during compression. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(mediaCompressionServiceProvider).clearCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compression cache cleared')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Compression'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigateBack('/settings/storage'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Enable/Disable compression
          _buildSettingsSection(
            context,
            title: 'General',
            items: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                title: Text(
                  'Enable compression',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Compress images and videos before sending',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: _compressionEnabled,
                onChanged: _saveCompressionEnabled,
                activeThumbColor: AppTheme.primaryGreen,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                title: Text(
                  'Show size estimate',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Display estimated file size before sending',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: _showSizeEstimate,
                onChanged: _compressionEnabled ? _saveShowSizeEstimate : null,
                activeThumbColor: AppTheme.primaryGreen,
              ),
            ],
          ),

          // Image compression settings
          _buildSettingsSection(
            context,
            title: 'Image Compression',
            items: [_buildImageQualityItem(context)],
          ),

          // Video compression settings
          _buildSettingsSection(
            context,
            title: 'Video Compression',
            items: [_buildVideoQualityItem(context)],
          ),

          // Info section
          _buildSettingsSection(
            context,
            title: 'Information',
            items: [_buildInfoCard(context)],
          ),

          // Cache management
          _buildSettingsSection(
            context,
            title: 'Cache',
            items: [_buildClearCacheItem(context)],
          ),
        ],
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

  Widget _buildImageQualityItem(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'JPEG Quality',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _compressionEnabled
                        ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$_imageQuality%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _compressionEnabled
                          ? AppTheme.primaryGreen
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Lower quality = smaller file size',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: _compressionEnabled
                    ? AppTheme.primaryGreen
                    : theme.colorScheme.onSurfaceVariant,
                thumbColor: _compressionEnabled
                    ? AppTheme.primaryGreen
                    : theme.colorScheme.onSurfaceVariant,
                inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Slider(
                value: _imageQuality.toDouble(),
                min: 10,
                max: 100,
                divisions: 18,
                label: '$_imageQuality%',
                onChanged: _compressionEnabled
                    ? (value) => setState(() => _imageQuality = value.round())
                    : null,
                onChangeEnd: _compressionEnabled
                    ? (value) => _saveImageQuality(value.round())
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Smaller file',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    'Better quality',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoQualityItem(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Video Resolution',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select default video compression quality',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CompressionQualityPreset.values.map((preset) {
                final isSelected = _videoQuality == preset;
                final isEnabled = _compressionEnabled;
                return ChoiceChip(
                  label: Text(preset.displayName),
                  selected: isSelected,
                  onSelected: isEnabled
                      ? (selected) {
                          if (selected) {
                            _saveVideoQuality(preset);
                          }
                        }
                      : null,
                  selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected && isEnabled
                        ? AppTheme.primaryGreen
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected && isEnabled
                        ? AppTheme.primaryGreen
                        : theme.colorScheme.outline,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  'About compression',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Images are compressed to a maximum of 1920x1080 pixels. '
              'Videos are re-encoded to the selected resolution. '
              'Compression reduces file size and upload time, but may slightly reduce quality.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can always choose to send the original file when sending media.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearCacheItem(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
        title: Text(
          'Clear compression cache',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Delete temporary files from video compression',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: _clearCompressionCache,
      ),
    );
  }
}
