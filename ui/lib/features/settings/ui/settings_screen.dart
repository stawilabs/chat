import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/user_info_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfoAsync = ref.watch(userInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigateBack(),
        ),
      ),
      body: Column(
        children: [
          // Profile Header
          _buildProfileHeader(context, userInfoAsync),

          // Settings List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSettingsItem(
                  context,
                  icon: Icons.account_circle_outlined,
                  title: 'Account',
                  subtitle: 'Profile information, security',
                  onTap: () => context.navigateToAccountSettings(),
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.lock_outline,
                  title: 'Privacy',
                  subtitle: 'Block contacts, disappearing messages',
                  onTap: () => context.navigateToPrivacySettings(),
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.fingerprint,
                  title: 'Security',
                  subtitle: 'Biometric lock, app lock settings',
                  onTap: () => context.navigateToSecuritySettings(),
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.chat_outlined,
                  title: 'Chats',
                  subtitle: 'Chat history, wallpaper, font size',
                  onTap: () => context.navigateToChatSettings(),
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Message, group & call tones',
                  onTap: () => context.navigateToNotificationSettings(),
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.storage_outlined,
                  title: 'Storage',
                  subtitle: 'Network usage, storage management',
                  onTap: () => context.navigateToStorageSettings(),
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  subtitle: 'Theme, dark mode, accent color',
                  onTap: () => context.go('/settings/theme'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    AsyncValue<UserInfo?> userInfoAsync,
  ) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: const BoxDecoration(
      color: AppTheme.primaryGreen,
      image: DecorationImage(
        image: AssetImage('assets/chat_pattern.webp'),
        repeat: ImageRepeat.repeat,
        opacity: 0.1,
      ),
    ),
    child: userInfoAsync.when(
      data: (userInfo) => Column(
        children: [
          // Large Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage: userInfo?.picture != null
                ? NetworkImage(userInfo!.picture!)
                : null,
            child: userInfo?.picture == null
                ? Text(
                    userInfo?.initials ?? 'U',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            userInfo?.displayName ?? 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),

          // About text
          Text(
            'Hey there! I am using Chat.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      loading: () => Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      error: (error, stackTrace) => Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
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
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
}
