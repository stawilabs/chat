import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/navigation_helper.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/settings/settings_service.dart';
import '../../../core/theme/app_theme.dart';

/// Security settings screen for configuring biometric lock and related options
class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  bool _biometricEnabled = false;
  int _lockTimeoutMinutes = 1;
  bool _showNotificationsLocked = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsService = ref.read(settingsServiceProvider);

    setState(() {
      _biometricEnabled = settingsService.biometricEnabled;
      _lockTimeoutMinutes = settingsService.lockTimeoutMinutes;
      _showNotificationsLocked = settingsService.showNotificationsLocked;
      _isLoading = false;
    });
  }

  Future<void> _toggleBiometric(bool enabled) async {
    // If enabling, verify biometric is available first
    if (enabled) {
      final biometricService = ref.read(biometricServiceProvider);
      final isAvailable = await biometricService.isBiometricAvailable();

      if (!isAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Biometric authentication is not available on this device',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Test authentication before enabling
      final result = await biometricService.authenticate(
        localizedReason: 'Authenticate to enable biometric lock',
      );

      if (result != BiometricAuthResult.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication required to enable biometric lock'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    final settingsService = ref.read(settingsServiceProvider);
    await settingsService.setBiometricEnabled(enabled);

    setState(() {
      _biometricEnabled = enabled;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled ? 'Biometric lock enabled' : 'Biometric lock disabled',
        ),
        backgroundColor: enabled ? AppTheme.brightGreen : null,
      ),
    );
  }

  Future<void> _setLockTimeout(int minutes) async {
    final settingsService = ref.read(settingsServiceProvider);
    await settingsService.setLockTimeoutMinutes(minutes);

    setState(() {
      _lockTimeoutMinutes = minutes;
    });
  }

  Future<void> _toggleShowNotifications(bool show) async {
    final settingsService = ref.read(settingsServiceProvider);
    await settingsService.setShowNotificationsLocked(show);

    setState(() {
      _showNotificationsLocked = show;
    });
  }

  void _showTimeoutPicker() {
    final timeouts = [
      (0, 'Immediately'),
      (1, '1 minute'),
      (5, '5 minutes'),
      (15, '15 minutes'),
      (30, '30 minutes'),
      (60, '1 hour'),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Lock after inactivity',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            ...timeouts.map(
              (timeout) => ListTile(
                title: Text(timeout.$2),
                trailing: _lockTimeoutMinutes == timeout.$1
                    ? const Icon(Icons.check, color: AppTheme.primaryGreen)
                    : null,
                onTap: () {
                  _setLockTimeout(timeout.$1);
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _getTimeoutDescription(int minutes) {
    if (minutes == 0) return 'Immediately';
    if (minutes == 1) return '1 minute';
    if (minutes < 60) return '$minutes minutes';
    if (minutes == 60) return '1 hour';
    return '${minutes ~/ 60} hours';
  }

  @override
  Widget build(BuildContext context) {
    final isBiometricAvailableAsync = ref.watch(isBiometricAvailableProvider);
    final biometricDescriptionAsync = ref.watch(biometricDescriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigateBack('/settings'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Biometric Lock Section
                _buildSettingsSection(
                  context,
                  title: 'Biometric Lock',
                  items: [
                    _buildBiometricToggle(
                      context,
                      isBiometricAvailableAsync,
                      biometricDescriptionAsync,
                    ),
                  ],
                ),

                // Lock Timeout Section (only visible when biometric is enabled)
                if (_biometricEnabled) ...[
                  _buildSettingsSection(
                    context,
                    title: 'Lock Timeout',
                    items: [
                      _buildSettingsItem(
                        context,
                        title: 'Lock after inactivity',
                        subtitle: _getTimeoutDescription(_lockTimeoutMinutes),
                        onTap: _showTimeoutPicker,
                      ),
                    ],
                  ),

                  // Notifications Section
                  _buildSettingsSection(
                    context,
                    title: 'When Locked',
                    items: [
                      _buildSwitchItem(
                        context,
                        title: 'Show notifications',
                        subtitle:
                            'Display notification content when app is locked',
                        value: _showNotificationsLocked,
                        onChanged: _toggleShowNotifications,
                      ),
                    ],
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
                            Icons.info_outline,
                            color: AppTheme.primaryGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'About Biometric Lock',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryGreen,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'When enabled, you will need to authenticate using '
                                  'fingerprint, face recognition, or device PIN/password '
                                  'to access the app after the configured timeout.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
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
              ],
            ),
    );
  }

  Widget _buildBiometricToggle(
    BuildContext context,
    AsyncValue<bool> isBiometricAvailableAsync,
    AsyncValue<String> biometricDescriptionAsync,
  ) {
    return isBiometricAvailableAsync.when(
      data: (isAvailable) {
        final subtitle = biometricDescriptionAsync.when(
          data: (description) => isAvailable
              ? 'Use $description to unlock'
              : 'Not available on this device',
          loading: () => 'Checking...',
          error: (_, _) => 'Error checking availability',
        );

        return _buildSwitchItem(
          context,
          title: 'Enable biometric lock',
          subtitle: subtitle,
          value: _biometricEnabled,
          enabled: isAvailable,
          onChanged: isAvailable ? _toggleBiometric : null,
        );
      },
      loading: () => _buildSwitchItem(
        context,
        title: 'Enable biometric lock',
        subtitle: 'Checking availability...',
        value: false,
        enabled: false,
        onChanged: null,
      ),
      error: (_, _) => _buildSwitchItem(
        context,
        title: 'Enable biometric lock',
        subtitle: 'Error checking availability',
        value: false,
        enabled: false,
        onChanged: null,
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
    required ValueChanged<bool>? onChanged,
    bool enabled = true,
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
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: enabled ? null : Theme.of(context).disabledColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: enabled
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : Theme.of(context).disabledColor,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeTrackColor: AppTheme.primaryGreen.withValues(alpha: 0.5),
        activeThumbColor: AppTheme.primaryGreen,
      ),
    ),
  );
}
