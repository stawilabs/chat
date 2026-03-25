import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/navigation/navigation_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../contacts/services/block_service.dart';

/// Screen displaying the list of blocked users with options to unblock
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedUsersAsync = ref.watch(blockedUsersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Contacts'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigateBack('/settings/privacy'),
        ),
      ),
      body: blockedUsersAsync.when(
        data: (blockedUsers) {
          if (blockedUsers.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildBlockedUsersList(context, ref, blockedUsers);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading blocked contacts',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Colors.green.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No blocked contacts',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'You have not blocked anyone yet. Blocked contacts will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    ),
  );

  Widget _buildBlockedUsersList(
    BuildContext context,
    WidgetRef ref,
    List<RosterData> blockedUsers,
  ) => ListView.builder(
    padding: const EdgeInsets.symmetric(vertical: 8),
    itemCount: blockedUsers.length,
    itemBuilder: (context, index) {
      final user = blockedUsers[index];
      return _buildBlockedUserTile(context, ref, user);
    },
  );

  Widget _buildBlockedUserTile(
    BuildContext context,
    WidgetRef ref,
    RosterData user,
  ) {
    final displayName = user.displayName ?? user.contactDetail;
    final initials = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : '?';

    return Container(
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade100,
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          displayName,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.contactDetail.isNotEmpty &&
                user.contactDetail != displayName)
              Text(
                user.contactDetail,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.block, size: 12, color: Colors.red.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Blocked',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: TextButton(
          onPressed: () => _confirmUnblock(context, ref, user),
          style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
          child: const Text('Unblock'),
        ),
        onTap: () {
          if (user.profileId != null) {
            context.navigateToProfile(profileId: user.profileId!);
          }
        },
      ),
    );
  }

  void _confirmUnblock(BuildContext context, WidgetRef ref, RosterData user) {
    final displayName = user.displayName ?? user.contactDetail;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unblock Contact'),
        content: Text(
          'Are you sure you want to unblock $displayName? They will be able to message you again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _unblockUser(context, ref, user);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  Future<void> _unblockUser(
    BuildContext context,
    WidgetRef ref,
    RosterData user,
  ) async {
    try {
      final blockService = await ref.read(blockServiceProvider.future);
      await blockService.unblockUserByRosterId(user.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${user.displayName ?? user.contactDetail} has been unblocked',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unblock contact: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
