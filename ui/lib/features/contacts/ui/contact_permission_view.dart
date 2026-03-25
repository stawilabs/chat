import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';

/// An inline view explaining why contact access is needed and providing
/// a single button to request permission.
///
/// This replaces the empty state and permission dialog with a single,
/// streamlined experience where users see the explanation and can grant
/// permission with one tap.
class ContactPermissionView extends StatefulWidget {
  const ContactPermissionView({
    required this.onPermissionGranted,
    this.onPermissionDeclined,
    super.key,
  });

  /// Called when the user grants contact permission
  final VoidCallback onPermissionGranted;

  /// Called when the user declines or the permission is denied
  final VoidCallback? onPermissionDeclined;

  @override
  State<ContactPermissionView> createState() => _ContactPermissionViewState();
}

class _ContactPermissionViewState extends State<ContactPermissionView> {
  bool _isRequesting = false;
  bool _isPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.contacts.status;
    if (mounted) {
      setState(() {
        _isPermanentlyDenied = status.isPermanentlyDenied;
      });
    }
  }

  Future<void> _requestPermission() async {
    if (_isRequesting) return;

    setState(() => _isRequesting = true);

    try {
      if (_isPermanentlyDenied) {
        // Open settings since permission was permanently denied
        await openAppSettings();

        // Check permission status after returning from settings
        if (!mounted) return;
        final newStatus = await Permission.contacts.status;

        if (newStatus.isGranted) {
          widget.onPermissionGranted();
        } else {
          setState(() {
            _isPermanentlyDenied = newStatus.isPermanentlyDenied;
          });
          widget.onPermissionDeclined?.call();
        }
      } else {
        // Request permission directly
        final status = await Permission.contacts.request();

        if (!mounted) return;

        if (status.isGranted) {
          widget.onPermissionGranted();
        } else if (status.isPermanentlyDenied) {
          setState(() => _isPermanentlyDenied = true);
          widget.onPermissionDeclined?.call();
        } else {
          widget.onPermissionDeclined?.call();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon in circular container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.contacts_rounded,
                size: 44,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Allow Access to Contacts',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Explanation text
            Text(
              'Access to your contacts lets you quickly find people you know and invite them to your groups.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Benefits container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _BenefitRow(
                    icon: Icons.search_rounded,
                    text: 'Easily search contacts',
                    theme: theme,
                  ),
                  const SizedBox(height: 14),
                  _BenefitRow(
                    icon: Icons.group_add_rounded,
                    text: 'Add members to groups',
                    theme: theme,
                  ),
                  const SizedBox(height: 14),
                  _BenefitRow(
                    icon: Icons.auto_awesome_rounded,
                    text: 'Enhance contacts with app profiles',
                    theme: theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Privacy reassurance
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 6),
                Text(
                  'Your contacts stay private on your device',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),

            // Warning for permanently denied
            if (_isPermanentlyDenied) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Permission was previously denied. Tap below to open Settings and enable contact access.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Action button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isRequesting ? null : _requestPermission,
                icon: _isRequesting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : Icon(
                        _isPermanentlyDenied
                            ? Icons.settings_rounded
                            : Icons.sync_rounded,
                      ),
                label: Text(
                  _isPermanentlyDenied ? 'Open Settings' : 'Continue',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row displaying a benefit with an icon
class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.text,
    required this.theme,
  });

  final IconData icon;
  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
