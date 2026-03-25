import 'package:flutter/material.dart';

import '../core/error/app_error.dart';

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    required this.error,
    super.key,
    this.onRetry,
    this.onDismiss,
  });
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: _getBackgroundColor(theme),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(_getIcon(), color: _getIconColor(theme), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.message,
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontSize: 14,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: theme.colorScheme.onErrorContainer,
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(ThemeData theme) {
    switch (error.type) {
      case ErrorType.network:
        return Colors.orange.shade100;
      case ErrorType.authentication:
        return Colors.red.shade100;
      case ErrorType.validation:
        return Colors.yellow.shade100;
      case ErrorType.server:
      case ErrorType.unknown:
        return theme.colorScheme.errorContainer;
    }
  }

  Color _getIconColor(ThemeData theme) {
    switch (error.type) {
      case ErrorType.network:
        return Colors.orange.shade700;
      case ErrorType.authentication:
        return Colors.red.shade700;
      case ErrorType.validation:
        return Colors.yellow.shade700;
      case ErrorType.server:
      case ErrorType.unknown:
        return theme.colorScheme.error;
    }
  }

  IconData _getIcon() {
    switch (error.type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.lock_outline;
      case ErrorType.validation:
        return Icons.warning_amber;
      case ErrorType.server:
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }
}
