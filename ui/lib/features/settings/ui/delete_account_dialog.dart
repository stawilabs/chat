import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../data/account_service.dart';

/// Steps in the delete account dialog flow
enum _DeleteAccountStep { warning, reason, confirm }

/// Dialog for confirming account deletion with warnings
class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  /// Shows the delete account dialog
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DeleteAccountDialog(),
    );
  }

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _confirmChecked = false;
  bool _isDeleting = false;
  _DeleteAccountStep _step = _DeleteAccountStep.warning;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red.shade700,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Delete Account'),
        ],
      ),
      content: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildStepContent(theme),
      ),
      actions: _buildActions(context),
    );
  }

  Widget _buildStepContent(ThemeData theme) {
    return switch (_step) {
      _DeleteAccountStep.warning => _buildWarningStep(theme),
      _DeleteAccountStep.reason => _buildReasonStep(theme),
      _DeleteAccountStep.confirm => _buildConfirmStep(theme),
    };
  }

  Widget _buildWarningStep(ThemeData theme) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This action is permanent and cannot be undone.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Deleting your account will:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildWarningItem(theme, 'Delete all your messages permanently'),
          _buildWarningItem(theme, 'Remove you from all groups and chats'),
          _buildWarningItem(theme, 'Delete your profile and contacts'),
          _buildWarningItem(theme, 'Revoke access on all devices'),
          _buildWarningItem(theme, 'Delete all transaction and motion history'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Consider downloading your data before proceeding.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.remove_circle, size: 16, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildReasonStep(ThemeData theme) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We\'re sorry to see you go!',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Would you mind telling us why you\'re leaving? '
            'Your feedback helps us improve.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Optional: Tell us why...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmStep(ThemeData theme) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This is your final warning. '
                    'Your account and all data will be permanently deleted.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _confirmChecked,
            onChanged: _isDeleting
                ? null
                : (value) => setState(() => _confirmChecked = value ?? false),
            title: Text(
              'I understand that this action is permanent and '
              'all my data will be deleted',
              style: theme.textTheme.bodyMedium,
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    if (_isDeleting) {
      return [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Deleting account...'),
            ],
          ),
        ),
      ];
    }

    return switch (_step) {
      _DeleteAccountStep.warning => [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => setState(() => _step = _DeleteAccountStep.reason),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
          ),
          child: const Text('Continue'),
        ),
      ],
      _DeleteAccountStep.reason => [
        TextButton(
          onPressed: () => setState(() => _step = _DeleteAccountStep.warning),
          child: const Text('Back'),
        ),
        ElevatedButton(
          onPressed: () => setState(() => _step = _DeleteAccountStep.confirm),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
          ),
          child: const Text('Continue'),
        ),
      ],
      _DeleteAccountStep.confirm => [
        TextButton(
          onPressed: () => setState(() => _step = _DeleteAccountStep.reason),
          child: const Text('Back'),
        ),
        ElevatedButton(
          onPressed: _confirmChecked ? _deleteAccount : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete My Account'),
        ),
      ],
    };
  }

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);

    try {
      final service = ref.read(accountServiceProvider);
      final reason = _reasonController.text.trim();
      final success = await service.deleteAccount(
        reason: reason.isNotEmpty ? reason : null,
      );

      if (!mounted) return;

      if (success) {
        // Log out the user
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.logout();

        if (!mounted) return;

        Navigator.of(context).pop(true);

        // Navigate to login
        context.go('/login');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been scheduled for deletion'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      } else {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete account. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
