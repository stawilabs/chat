import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/data/auth_state_provider.dart';
import '../features/auth/data/user_info_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfoAsync = ref.watch(userInfoProvider);
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          // Header with user profile
          _buildHeader(context, theme, userInfoAsync),

          const Divider(height: 1),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/settings');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  onTap: () {
                    Navigator.pop(context);
                    // Note: Help navigation will be implemented
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          ),

          // Bottom section with logout
          const Divider(height: 1),
          _buildBottomSection(context, ref, theme, userInfoAsync),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    AsyncValue<UserInfo?> userInfoAsync,
  ) => Container(
    width: double.infinity,
    padding: EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 24,
      bottom: 24,
      left: 20,
      right: 20,
    ),
    decoration: BoxDecoration(color: theme.colorScheme.primaryContainer),
    child: userInfoAsync.when(
      data: (userInfo) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile avatar
          CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.primary,
            backgroundImage: userInfo?.picture != null
                ? NetworkImage(userInfo!.picture!)
                : null,
            child: userInfo?.picture == null
                ? Text(
                    userInfo?.initials ?? 'U',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // User name
          Text(
            userInfo?.displayName ?? 'User',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),

          // User email/phone
          if (userInfo?.email != null || userInfo?.phone != null) ...[
            const SizedBox(height: 4),
            Text(
              userInfo?.email ?? userInfo?.phone ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ],
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(
              Icons.person,
              size: 36,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'User',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildBottomSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AsyncValue<UserInfo?> userInfoAsync,
  ) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          // Logged in info
          userInfoAsync.whenData((userInfo) {
                if (userInfo?.id != null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Logged in as ${userInfo?.displayName ?? "User"}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }).value ??
              const SizedBox.shrink(),

          // Logout button
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              'Logout',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () => _handleLogout(context, ref),
          ),
        ],
      ),
    ),
  );

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      Navigator.of(context).pop(); // Close drawer
      await ref.read(authStateProvider.notifier).logout();
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Chat',
      applicationVersion: '1.0.0',
      applicationIcon: const FlutterLogo(size: 48),
      children: [const Text('A secure messaging application.')],
    );
  }
}
