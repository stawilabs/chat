import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/navigation_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../data/settings_providers.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) => Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
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
              title: 'Message notifications',
              items: [
                _buildSwitchItem(
                  context,
                  title: 'Show notifications',
                  subtitle: 'Show message notifications',
                  value: settings['message_notifications'] ?? true,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .toggleMessageNotifications(value);
                  },
                ),
                _buildSwitchItem(
                  context,
                  title: 'Show preview',
                  subtitle: 'Show message content in notifications',
                  value: settings['notification_preview'] ?? true,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .toggleNotificationPreview(value);
                  },
                ),
              ],
            ),
            _buildSettingsSection(
              context,
              title: 'Group notifications',
              items: [
                _buildSwitchItem(
                  context,
                  title: 'Group notifications',
                  subtitle: 'Show notifications for group messages',
                  value: settings['group_notifications'] ?? true,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .toggleGroupNotifications(value);
                  },
                ),
              ],
            ),
            _buildSettingsSection(
              context,
              title: 'Call notifications',
              items: [
                _buildSwitchItem(
                  context,
                  title: 'Ringtone',
                  subtitle: 'Play ringtone for incoming calls',
                  value: settings['call_ringtone'] ?? true,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .toggleCallRingtone(value);
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
