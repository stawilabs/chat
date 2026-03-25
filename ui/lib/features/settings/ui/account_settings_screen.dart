import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/navigation/navigation_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/user_info_provider.dart';
import '../data/account_service.dart';
import 'delete_account_dialog.dart';

/// Account settings screen for managing profile, security, and account actions
class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  bool _isLoggingOut = false;
  bool _isRequestingData = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userInfoAsync = ref.watch(userInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
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
          // User Info Header
          userInfoAsync.when(
            data: (userInfo) => _buildUserInfoHeader(context, theme, userInfo),
            loading: () => _buildUserInfoHeaderLoading(theme),
            error: (error, stack) => const SizedBox.shrink(),
          ),

          // Profile Section
          _buildSettingsSection(
            context,
            title: 'Profile',
            items: [
              _buildSettingsItem(
                context,
                icon: Icons.person_outline,
                title: 'Edit profile',
                subtitle: 'Change name, photo, about',
                onTap: () => context.navigateToProfileEdit(),
              ),
            ],
          ),

          // Contact Information Section
          _buildSettingsSection(
            context,
            title: 'Contact Information',
            items: [
              _buildSettingsItem(
                context,
                icon: Icons.phone_outlined,
                title: 'Phone number',
                subtitle: userInfoAsync.maybeWhen(
                  data: (info) => info?.phone ?? 'Add phone number',
                  orElse: () => 'Add phone number',
                ),
                onTap: () => _showChangePhoneDialog(context),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.email_outlined,
                title: 'Email address',
                subtitle: userInfoAsync.maybeWhen(
                  data: (info) => info?.email ?? 'Add email address',
                  orElse: () => 'Add email address',
                ),
                onTap: () => _showChangeEmailDialog(context),
              ),
            ],
          ),

          // Security Section
          _buildSettingsSection(
            context,
            title: 'Security',
            items: [
              _buildSettingsItem(
                context,
                icon: Icons.security_outlined,
                title: 'Two-step verification',
                subtitle: 'Add an extra layer of security',
                onTap: () => context.push('/settings/security/2fa'),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.password_outlined,
                title: 'Change password',
                subtitle: 'Update your account password',
                onTap: () => _showChangePasswordDialog(context),
              ),
            ],
          ),

          // Devices Section
          _buildSettingsSection(
            context,
            title: 'Devices',
            items: [
              _buildSettingsItem(
                context,
                icon: Icons.devices_outlined,
                title: 'Linked devices',
                subtitle: 'Manage devices logged into your account',
                onTap: () => context.push('/settings/account/devices'),
              ),
            ],
          ),

          // Data & Privacy Section
          _buildSettingsSection(
            context,
            title: 'Data & Privacy',
            items: [
              _buildSettingsItem(
                context,
                icon: Icons.download_outlined,
                title: 'Request account data',
                subtitle: 'Download a copy of your data',
                trailing: _isRequestingData
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _isRequestingData
                    ? null
                    : () => _requestAccountData(context),
              ),
            ],
          ),

          // Account Actions Section
          _buildSettingsSection(
            context,
            title: 'Account Actions',
            items: [
              _buildSettingsItem(
                context,
                icon: Icons.logout,
                title: 'Log out',
                subtitle: 'Sign out of your account',
                iconColor: Colors.orange,
                trailing: _isLoggingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _isLoggingOut ? null : () => _showLogoutDialog(context),
              ),
              _buildSettingsItem(
                context,
                icon: Icons.delete_forever,
                title: 'Delete account',
                subtitle: 'Permanently delete your account and data',
                iconColor: Colors.red,
                textColor: Colors.red,
                onTap: () => _showDeleteAccountDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUserInfoHeader(
    BuildContext context,
    ThemeData theme,
    UserInfo? userInfo,
  ) {
    final name = userInfo?.name ?? 'User';
    final email = userInfo?.email;
    final phone = userInfo?.phone;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (email != null || phone != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    email ?? phone ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoHeaderLoading(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                height: 16,
                child: LinearProgressIndicator(),
              ),
              SizedBox(height: 8),
              SizedBox(
                width: 150,
                height: 12,
                child: LinearProgressIndicator(),
              ),
            ],
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
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
    Widget? trailing,
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primaryGreen).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? AppTheme.primaryGreen, size: 24),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color:
              textColor?.withValues(alpha: 0.7) ??
              Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
      onTap: onTap,
    ),
  );

  Future<void> _showChangePhoneDialog(BuildContext context) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Phone Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your new phone number. A verification code will be sent.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '+1 234 567 8900',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send Code'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      final phone = controller.text.trim();
      if (phone.isNotEmpty) {
        final service = ref.read(accountServiceProvider);
        final success = await service.updatePhoneNumber(phone);

        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Verification code sent to $phone'
                    : 'Failed to update phone number',
              ),
              backgroundColor: success ? AppTheme.primaryGreen : Colors.red,
            ),
          );
        }
      }
    }

    controller.dispose();
  }

  Future<void> _showChangeEmailDialog(BuildContext context) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Email Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your new email address. A verification link will be sent.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email address',
                hintText: 'example@email.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      final email = controller.text.trim();
      if (email.isNotEmpty) {
        final service = ref.read(accountServiceProvider);
        final success = await service.updateEmail(email);

        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Verification link sent to $email'
                    : 'Failed to update email address',
              ),
              backgroundColor: success ? AppTheme.primaryGreen : Colors.red,
            ),
          );
        }
      }
    }

    controller.dispose();
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final uri = Uri.parse('https://stawi.org/account/password');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open password change page'),
                    ),
                  );
                }
              }
            },
            child: const Text('Update Password'),
          ),
        ],
      ),
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
  }

  Future<void> _requestAccountData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isRequestingData = true);

    try {
      final service = ref.read(accountServiceProvider);
      final result = await service.requestAccountData();

      if (!mounted) return;

      if (result != null) {
        showDialog<void>(
          context: this.context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Data Request Submitted'),
            content: const Text(
              'Your data export request has been submitted. '
              'You will receive a notification when your data is ready for download.\n\n'
              'This may take up to 24 hours depending on the amount of data.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to request account data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingData = false);
      }
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.logout();

      if (!mounted) return;

      context.go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    await DeleteAccountDialog.show(context);
  }
}
