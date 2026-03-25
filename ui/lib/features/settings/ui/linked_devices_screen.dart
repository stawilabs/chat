import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/navigation_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../data/account_service.dart';

/// Screen showing all linked devices and active sessions
class LinkedDevicesScreen extends ConsumerStatefulWidget {
  const LinkedDevicesScreen({super.key});

  @override
  ConsumerState<LinkedDevicesScreen> createState() =>
      _LinkedDevicesScreenState();
}

class _LinkedDevicesScreenState extends ConsumerState<LinkedDevicesScreen> {
  bool _isRemoving = false;

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(linkedDevicesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Linked Devices'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigateBack('/settings/account'),
        ),
      ),
      body: devicesAsync.when(
        data: (devices) => _buildDevicesList(context, theme, devices),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('Failed to load devices', style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(linkedDevicesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDevicesList(
    BuildContext context,
    ThemeData theme,
    List<LinkedDevice> devices,
  ) {
    if (devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No devices found',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final currentDevice = devices.where((d) => d.isCurrent).toList();
    final otherDevices = devices.where((d) => !d.isCurrent).toList();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(linkedDevicesProvider),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Current Device Section
          if (currentDevice.isNotEmpty) ...[
            _buildSectionHeader(context, 'This Device'),
            ...currentDevice.map(
              (device) => _buildDeviceTile(
                context,
                theme,
                device,
                showRemoveButton: false,
              ),
            ),
          ],

          // Other Devices Section
          if (otherDevices.isNotEmpty) ...[
            _buildSectionHeader(context, 'Other Devices'),
            ...otherDevices.map(
              (device) => _buildDeviceTile(
                context,
                theme,
                device,
                showRemoveButton: true,
              ),
            ),
          ],

          // Info Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.security,
                      color: AppTheme.primaryGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Device Security',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Remove devices you no longer use or don\'t recognize '
                            'to keep your account secure. Removed devices will need '
                            'to log in again.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Log out all devices button
          if (otherDevices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton.icon(
                onPressed: _isRemoving
                    ? null
                    : () => _showLogoutAllDialog(context),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Log out all other devices'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildDeviceTile(
    BuildContext context,
    ThemeData theme,
    LinkedDevice device, {
    required bool showRemoveButton,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: device.isCurrent
            ? Border.all(color: AppTheme.primaryGreen, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: device.isCurrent
              ? AppTheme.primaryGreen
              : theme.colorScheme.primaryContainer,
          child: Icon(
            _getDeviceIcon(device.platformIcon),
            color: device.isCurrent
                ? Colors.white
                : theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                device.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (device.isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Current',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              device.platform,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (device.location != null)
              Text(
                device.location!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            Text(
              device.formattedLastActive,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: showRemoveButton
            ? IconButton(
                icon: _isRemoving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout, color: Colors.red),
                onPressed: _isRemoving
                    ? null
                    : () => _showRemoveDeviceDialog(context, device),
              )
            : null,
        isThreeLine: true,
      ),
    );
  }

  IconData _getDeviceIcon(String iconName) {
    switch (iconName) {
      case 'phone_iphone':
        return Icons.phone_iphone;
      case 'phone_android':
        return Icons.phone_android;
      case 'web':
        return Icons.web;
      case 'laptop_mac':
        return Icons.laptop_mac;
      case 'laptop_windows':
        return Icons.laptop_windows;
      case 'computer':
        return Icons.computer;
      default:
        return Icons.devices;
    }
  }

  Future<void> _showRemoveDeviceDialog(
    BuildContext context,
    LinkedDevice device,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Device'),
        content: Text(
          'Are you sure you want to log out "${device.name}"?\n\n'
          'This device will need to log in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      await _removeDevice(device);
    }
  }

  Future<void> _showLogoutAllDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out All Devices'),
        content: const Text(
          'Are you sure you want to log out all other devices?\n\n'
          'This will end all sessions except the current one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log Out All'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      await _logoutAllDevices();
    }
  }

  Future<void> _removeDevice(LinkedDevice device) async {
    setState(() => _isRemoving = true);

    try {
      final service = ref.read(accountServiceProvider);
      await service.removeDevice(device.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed ${device.name}'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      ref.invalidate(linkedDevicesProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to remove device'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRemoving = false);
      }
    }
  }

  Future<void> _logoutAllDevices() async {
    setState(() => _isRemoving = true);

    try {
      final devicesAsync = ref.read(linkedDevicesProvider);
      final devices = devicesAsync.when(
        data: (d) => d,
        loading: () => <LinkedDevice>[],
        error: (error, stack) => <LinkedDevice>[],
      );
      final otherDevices = devices.where((d) => !d.isCurrent).toList();
      final service = ref.read(accountServiceProvider);

      var successCount = 0;
      for (final device in otherDevices) {
        try {
          await service.removeDevice(device.id);
          successCount++;
        } catch (_) {
          // Continue with other devices even if one fails
        }
      }

      if (!mounted) return;

      if (successCount == otherDevices.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out all other devices'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logged out $successCount of ${otherDevices.length} devices',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }

      ref.invalidate(linkedDevicesProvider);
    } finally {
      if (mounted) {
        setState(() => _isRemoving = false);
      }
    }
  }
}
