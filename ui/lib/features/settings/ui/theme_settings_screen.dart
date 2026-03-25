// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/navigation/navigation_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_service.dart';

class ThemeSettingsScreen extends ConsumerStatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  ConsumerState<ThemeSettingsScreen> createState() =>
      _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends ConsumerState<ThemeSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final accentColor = ref.watch(accentColorProvider);
    final wallpaper = ref.watch(chatWallpaperProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigateBack('/settings'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSection(
            context,
            title: 'Appearance',
            children: [
              _buildThemeModeSelector(context, themeMode),
              const SizedBox(height: 16),
              _buildAccentColorSelector(context, accentColor),
            ],
          ),
          _buildSection(
            context,
            title: 'Text',
            children: [
              _buildFontSizeSelector(context, fontSize),
              const SizedBox(height: 8),
              _buildFontSizePreview(context, fontSize),
            ],
          ),
          _buildSection(
            context,
            title: 'Chat Wallpaper',
            children: [_buildWallpaperSelector(context, wallpaper)],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildThemeModeSelector(BuildContext context, AppThemeMode current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme Mode',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: AppThemeMode.values.map((mode) {
            final isSelected = mode == current;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _ThemeModeCard(
                  mode: mode,
                  isSelected: isSelected,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).setThemeMode(mode);
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAccentColorSelector(BuildContext context, Color current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Accent Color',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (current != AppTheme.primaryGreen)
              TextButton(
                onPressed: () {
                  ref.read(accentColorProvider.notifier).resetToDefault();
                },
                child: const Text('Reset'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AccentColors.presets.map((color) {
            final isSelected = color.toARGB32() == current.toARGB32();
            return GestureDetector(
              onTap: () {
                ref.read(accentColorProvider.notifier).setAccentColor(color);
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFontSizeSelector(BuildContext context, AppFontSize current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Font Size',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<AppFontSize>(
          segments: AppFontSize.values.map((size) {
            return ButtonSegment<AppFontSize>(
              value: size,
              label: Text(size.displayName),
            );
          }).toList(),
          selected: {current},
          onSelectionChanged: (selection) {
            ref.read(fontSizeProvider.notifier).setFontSize(selection.first);
          },
        ),
      ],
    );
  }

  Widget _buildFontSizePreview(BuildContext context, AppFontSize fontSize) {
    final scale = _getScale(fontSize);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: TextStyle(
              fontSize: 12 * scale,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is how your messages will look',
            style: TextStyle(
              fontSize: 16 * scale,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Smaller text like timestamps',
            style: TextStyle(
              fontSize: 12 * scale,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  double _getScale(AppFontSize fontSize) {
    switch (fontSize) {
      case AppFontSize.small:
        return 0.85;
      case AppFontSize.medium:
        return 1;
      case AppFontSize.large:
        return 1.15;
      case AppFontSize.extraLarge:
        return 1.3;
    }
  }

  Widget _buildWallpaperSelector(BuildContext context, String? current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WallpaperPreview(
          wallpaperPath: current,
          onTap: () => _showWallpaperOptions(context, current),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickWallpaperFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: current != null
                    ? () {
                        ref
                            .read(chatWallpaperProvider.notifier)
                            .clearWallpaper();
                      }
                    : null,
                icon: const Icon(Icons.clear),
                label: const Text('Remove'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showWallpaperOptions(BuildContext context, String? current) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickWallpaperFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _takeWallpaperPhoto();
              },
            ),
            if (current != null)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remove wallpaper'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(chatWallpaperProvider.notifier).clearWallpaper();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickWallpaperFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      await _saveWallpaper(image.path);
    }
  }

  Future<void> _takeWallpaperPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      await _saveWallpaper(image.path);
    }
  }

  Future<void> _saveWallpaper(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final wallpaperDir = Directory('${appDir.path}/wallpapers');
      if (!await wallpaperDir.exists()) {
        await wallpaperDir.create(recursive: true);
      }

      // Preserve original file extension to avoid format issues
      final fileExtension = sourcePath.split('.').last;
      final fileName =
          'wallpaper_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final destPath = '${wallpaperDir.path}/$fileName';

      await File(sourcePath).copy(destPath);

      if (mounted) {
        ref.read(chatWallpaperProvider.notifier).setWallpaper(destPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to set wallpaper: $e')));
      }
    }
  }
}

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });
  final AppThemeMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              mode.icon,
              size: 32,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              mode.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _WallpaperPreview extends StatelessWidget {
  const _WallpaperPreview({required this.onTap, this.wallpaperPath});
  final String? wallpaperPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: wallpaperPath != null
            ? Image.file(
                File(wallpaperPath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildDefaultPreview(context),
              )
            : _buildDefaultPreview(context),
      ),
    );
  }

  Widget _buildDefaultPreview(BuildContext context) {
    return Container(
      color: AppTheme.getChatBackground(context),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wallpaper,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to change wallpaper',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
