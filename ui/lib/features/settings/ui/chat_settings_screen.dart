import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/navigation_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../data/settings_providers.dart';

class ChatSettingsScreen extends ConsumerStatefulWidget {
  const ChatSettingsScreen({super.key});

  @override
  ConsumerState<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends ConsumerState<ChatSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) => Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.navigateBack('/settings'),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _buildSettingsSection(
              context,
              title: 'Display',
              items: [
                _buildSettingsItem(
                  context,
                  title: 'Wallpaper',
                  subtitle: settings['wallpaper'] ?? 'Default',
                  onTap: () =>
                      _showWallpaperOptions(settings['wallpaper'] ?? 'Default'),
                ),
                _buildSettingsItem(
                  context,
                  title: 'Font size',
                  subtitle: settings['font_size'] ?? 'Medium',
                  onTap: () =>
                      _showFontSizeOptions(settings['font_size'] ?? 'Medium'),
                ),
              ],
            ),
            _buildSettingsSection(
              context,
              title: 'Chat history',
              items: [
                _buildSwitchItem(
                  context,
                  title: 'Keep chats archived',
                  subtitle:
                      'Archived chats will remain archived when new messages arrive',
                  value: settings['archive_chats'] ?? false,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .toggleArchiveChats(value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error loading settings: $error'))),
    );
  }

  void _showWallpaperOptions(String currentWallpaper) {
    final wallpapers = ['Default', 'Solid Color', 'Gradient', 'Custom Image'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Wallpaper'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final wallpaper in wallpapers)
              ListTile(
                title: Text(wallpaper),
                trailing: currentWallpaper == wallpaper
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .updateWallpaper(wallpaper);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFontSizeOptions(String currentFontSize) {
    final fontSizes = ['Small', 'Medium', 'Large', 'Extra Large'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Font Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final fontSize in fontSizes)
              ListTile(
                title: Text(fontSize),
                trailing: currentFontSize == fontSize
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).updateFontSize(fontSize);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) => Column(
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

  Widget _buildSettingsItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => Container(
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
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 20,
      ),
      onTap: onTap,
    ),
  );

  Widget _buildSwitchItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Container(
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
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primaryGreen,
      ),
    ),
  );
}
