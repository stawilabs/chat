import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'media_compression_service.dart';

/// Widget for displaying compression options before sending media
///
/// Shows:
/// - Current file size
/// - Estimated compressed size
/// - Quality slider for images
/// - Quality preset selector for videos
/// - Option to keep original quality
class CompressionOptionsWidget extends ConsumerStatefulWidget {
  const CompressionOptionsWidget({
    required this.file,
    required this.isVideo,
    required this.onConfirm,
    this.onCancel,
    super.key,
  });

  /// The file to be compressed
  final File file;

  /// Whether this is a video file
  final bool isVideo;

  /// Callback when user confirms with compression settings
  final void Function({
    required bool keepOriginal,
    int? imageQuality,
    CompressionQualityPreset? videoQuality,
  })
  onConfirm;

  /// Callback when user cancels
  final VoidCallback? onCancel;

  @override
  ConsumerState<CompressionOptionsWidget> createState() =>
      _CompressionOptionsWidgetState();
}

class _CompressionOptionsWidgetState
    extends ConsumerState<CompressionOptionsWidget> {
  bool _keepOriginal = false;
  int _imageQuality = CompressionDefaults.imageQuality;
  CompressionQualityPreset _videoQuality = CompressionQualityPreset.medium;

  int _originalSize = 0;
  int _estimatedSize = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFileSizes();
  }

  Future<void> _loadFileSizes() async {
    setState(() => _isLoading = true);

    final compressionService = ref.read(mediaCompressionServiceProvider);

    // Get initial settings from service
    _imageQuality = compressionService.imageQuality;
    _videoQuality = compressionService.videoQualityPreset;

    // Get original size
    _originalSize = await widget.file.length();

    // Estimate compressed size
    await _updateEstimate();

    setState(() => _isLoading = false);
  }

  Future<void> _updateEstimate() async {
    final compressionService = ref.read(mediaCompressionServiceProvider);

    if (_keepOriginal) {
      _estimatedSize = _originalSize;
    } else if (widget.isVideo) {
      _estimatedSize = await compressionService.estimateVideoSize(
        widget.file,
        qualityPreset: _videoQuality,
      );
    } else {
      _estimatedSize = await compressionService.estimateImageSize(
        widget.file,
        quality: _imageQuality,
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Text(
            widget.isVideo ? 'Video Compression' : 'Image Compression',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // File sizes
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            _buildSizeInfo(context),
            const SizedBox(height: 24),

            // Keep original toggle
            _buildOriginalToggle(context),
            const SizedBox(height: 16),

            // Quality controls (hidden when keeping original)
            if (!_keepOriginal) ...[
              if (widget.isVideo)
                _buildVideoQualitySelector(context)
              else
                _buildImageQualitySlider(context),
              const SizedBox(height: 24),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onCancel?.call();
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Send'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSizeInfo(BuildContext context) {
    final theme = Theme.of(context);
    final savings = _originalSize - _estimatedSize;
    final savingsPercent = _originalSize > 0
        ? (savings / _originalSize * 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Original size:', style: theme.textTheme.bodyMedium),
              Text(
                formatBytes(_originalSize),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estimated size:', style: theme.textTheme.bodyMedium),
              Text(
                formatBytes(_estimatedSize),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _keepOriginal ? null : AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          if (!_keepOriginal && savings > 0) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.compress,
                  size: 16,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  'Save ~${formatBytes(savings)} (${savingsPercent.toStringAsFixed(0)}%)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOriginalToggle(BuildContext context) {
    final theme = Theme.of(context);

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('Send original quality', style: theme.textTheme.bodyLarge),
      subtitle: Text(
        'Skip compression and send the original file',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      value: _keepOriginal,
      onChanged: (value) {
        setState(() => _keepOriginal = value);
        _updateEstimate();
      },
      activeThumbColor: AppTheme.primaryGreen,
    );
  }

  Widget _buildImageQualitySlider(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Image quality', style: theme.textTheme.bodyLarge),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$_imageQuality%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppTheme.primaryGreen,
            thumbColor: AppTheme.primaryGreen,
            inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
          ),
          child: Slider(
            value: _imageQuality.toDouble(),
            min: 10,
            max: 100,
            divisions: 18,
            label: '$_imageQuality%',
            onChanged: (value) {
              setState(() => _imageQuality = value.round());
            },
            onChangeEnd: (value) {
              _updateEstimate();
            },
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
    );
  }

  Widget _buildVideoQualitySelector(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Video quality', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CompressionQualityPreset.values.map((preset) {
            final isSelected = _videoQuality == preset;
            return ChoiceChip(
              label: Text(preset.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _videoQuality = preset);
                  _updateEstimate();
                }
              },
              selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? AppTheme.primaryGreen
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.primaryGreen
                    : theme.colorScheme.outline,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _onConfirm() {
    widget.onConfirm(
      keepOriginal: _keepOriginal,
      imageQuality: widget.isVideo ? null : _imageQuality,
      videoQuality: widget.isVideo ? _videoQuality : null,
    );
    Navigator.of(context).pop();
  }
}

/// Widget showing compression progress
class CompressionProgressIndicator extends StatelessWidget {
  const CompressionProgressIndicator({
    required this.progress,
    this.stage,
    this.estimatedSize,
    super.key,
  });

  /// Progress value from 0.0 to 1.0
  final double progress;

  /// Current stage description
  final String? stage;

  /// Estimated final size in bytes
  final int? estimatedSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.compress, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stage ?? 'Compressing...',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryGreen,
              ),
              minHeight: 6,
            ),
          ),
          if (estimatedSize != null) ...[
            const SizedBox(height: 8),
            Text(
              'Estimated size: ${formatBytes(estimatedSize!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Show compression options bottom sheet
Future<void> showCompressionOptionsSheet({
  required BuildContext context,
  required File file,
  required bool isVideo,
  required void Function({
    required bool keepOriginal,
    int? imageQuality,
    CompressionQualityPreset? videoQuality,
  })
  onConfirm,
  VoidCallback? onCancel,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CompressionOptionsWidget(
      file: file,
      isVideo: isVideo,
      onConfirm: onConfirm,
      onCancel: onCancel,
    ),
  );
}
