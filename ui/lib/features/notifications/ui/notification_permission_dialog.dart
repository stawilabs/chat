import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';

/// Result of the notification permission dialog
enum NotificationPermissionResult {
  /// User tapped "Not Now" - declined to grant permission
  declined,

  /// User granted permission (or it was already granted)
  granted,

  /// User needs to go to settings (permission permanently denied)
  openSettings,
}

/// A dialog explaining why notification access is needed for the chat app.
///
/// Shows:
/// - Notification bell icon in a circular container
/// - Clear title: "Enable Notifications"
/// - Explanation text about why notifications matter for messaging
/// - Three benefits with icons
/// - Privacy reassurance note
/// - Warning for permanently denied state
/// - "Not Now" and "Continue"/"Open Settings" buttons
class NotificationPermissionDialog extends StatelessWidget {
  const NotificationPermissionDialog({
    required this.isPermanentlyDenied,
    super.key,
  });

  /// Whether the permission was permanently denied by the user
  final bool isPermanentlyDenied;

  /// Show the notification permission dialog
  ///
  /// Returns [NotificationPermissionResult] indicating the user's choice.
  /// Only shows the dialog if permission is not already granted.
  static Future<NotificationPermissionResult> show(BuildContext context) async {
    // Check current permission status
    final status = await Permission.notification.status;

    // Already granted - no need to show dialog
    if (status.isGranted) {
      return NotificationPermissionResult.granted;
    }

    // Check if permanently denied
    final isPermanentlyDenied = status.isPermanentlyDenied;

    if (!context.mounted) return NotificationPermissionResult.declined;

    final result = await showDialog<NotificationPermissionResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NotificationPermissionDialog(
        isPermanentlyDenied: isPermanentlyDenied,
      ),
    );

    return result ?? NotificationPermissionResult.declined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Notification bell icon in circular container
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_rounded,
                size: 40,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Enable Notifications',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Explanation text
            Text(
              'To make sure you never miss important messages, we need your permission to send notifications.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Benefits container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _BenefitRow(
                    icon: Icons.message_rounded,
                    text: 'Know when new messages arrive',
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _BenefitRow(
                    icon: Icons.call_rounded,
                    text: 'Get alerted for incoming calls',
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _BenefitRow(
                    icon: Icons.groups_rounded,
                    text: 'Stay updated on group activities',
                    theme: theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Privacy reassurance
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 6),
                Text(
                  'You can customize notifications anytime',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),

            // Warning for permanently denied
            if (isPermanentlyDenied) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Permission was previously denied. Please enable it in Settings.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Not Now button
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(NotificationPermissionResult.declined);
          },
          child: Text(
            'Not Now',
            style: TextStyle(color: theme.colorScheme.outline),
          ),
        ),

        // Continue / Open Settings button
        FilledButton(
          onPressed: () async {
            if (isPermanentlyDenied) {
              // Open settings and return result
              Navigator.of(
                context,
              ).pop(NotificationPermissionResult.openSettings);
            } else {
              // Request permission
              final status = await Permission.notification.request();
              if (!context.mounted) return;

              if (status.isGranted) {
                Navigator.of(context).pop(NotificationPermissionResult.granted);
              } else if (status.isPermanentlyDenied) {
                Navigator.of(
                  context,
                ).pop(NotificationPermissionResult.openSettings);
              } else {
                // User denied - close dialog
                Navigator.of(
                  context,
                ).pop(NotificationPermissionResult.declined);
              }
            }
          },
          child: Text(isPermanentlyDenied ? 'Open Settings' : 'Continue'),
        ),
      ],
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
