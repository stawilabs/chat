import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/invite_link_providers.dart';
import '../domain/invite_link.dart';

/// Dialog for creating a new invite link
///
/// Allows configuration of:
/// - Link name/label
/// - Expiration time
/// - Max uses
/// - Approval requirement
class CreateInviteLinkDialog extends ConsumerStatefulWidget {
  const CreateInviteLinkDialog({
    required this.roomId,
    required this.createdBy,
    super.key,
  });

  final String roomId;
  final String createdBy;

  @override
  ConsumerState<CreateInviteLinkDialog> createState() =>
      _CreateInviteLinkDialogState();
}

class _CreateInviteLinkDialogState
    extends ConsumerState<CreateInviteLinkDialog> {
  final _nameController = TextEditingController();
  final _maxUsesController = TextEditingController();

  String _expiryOption = 'never'; // never, 1h, 1d, 7d, 30d, custom
  bool _requiresApproval = false;
  bool _hasMaxUses = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  Duration? get _selectedExpiry {
    switch (_expiryOption) {
      case '1h':
        return const Duration(hours: 1);
      case '1d':
        return const Duration(days: 1);
      case '7d':
        return const Duration(days: 7);
      case '30d':
        return const Duration(days: 30);
      default:
        return null;
    }
  }

  int? get _maxUses {
    if (!_hasMaxUses) return null;
    final text = _maxUsesController.text.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  Future<void> _createLink() async {
    setState(() => _isLoading = true);

    try {
      final link = await ref
          .read(inviteLinkProvider.notifier)
          .createLink(
            roomId: widget.roomId,
            createdBy: widget.createdBy,
            expiresIn: _selectedExpiry,
            maxUses: _maxUses,
            requiresApproval: _requiresApproval,
            name: _nameController.text.trim().isNotEmpty
                ? _nameController.text.trim()
                : null,
          );

      if (mounted) {
        Navigator.pop(context, link);
        _showSuccessSnackbar(context, link);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackbar(BuildContext context, InviteLink link) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(child: Text('Invite link created!')),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: link.inviteUrl));
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              },
              child: const Text('Copy', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Create Invite Link'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Link name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Link Name (optional)',
                hintText: 'e.g., "Weekend Event"',
                prefixIcon: Icon(Icons.label_outline),
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 16),

            // Expiry options
            Text(
              'Expires After',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildExpiryChip('never', 'Never'),
                _buildExpiryChip('1h', '1 hour'),
                _buildExpiryChip('1d', '1 day'),
                _buildExpiryChip('7d', '7 days'),
                _buildExpiryChip('30d', '30 days'),
              ],
            ),
            const SizedBox(height: 16),

            // Max uses
            Row(
              children: [
                Checkbox(
                  value: _hasMaxUses,
                  onChanged: (value) {
                    setState(() => _hasMaxUses = value ?? false);
                  },
                ),
                const Text('Limit number of uses'),
              ],
            ),
            if (_hasMaxUses) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _maxUsesController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Uses',
                  hintText: 'e.g., 10',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
            const SizedBox(height: 16),

            // Approval requirement
            SwitchListTile(
              title: const Text('Require Admin Approval'),
              subtitle: const Text(
                'New members must be approved before joining',
              ),
              value: _requiresApproval,
              onChanged: (value) {
                setState(() => _requiresApproval = value);
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createLink,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Widget _buildExpiryChip(String value, String label) {
    final isSelected = _expiryOption == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _expiryOption = value);
        }
      },
      selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryGreen,
    );
  }
}
