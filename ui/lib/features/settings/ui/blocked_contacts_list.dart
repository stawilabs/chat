import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/navigation_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../contacts/data/roster_repository.dart';

/// Screen to display and manage blocked contacts
class BlockedContactsListScreen extends ConsumerWidget {
  const BlockedContactsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedContactsAsync = ref.watch(blockedRosterEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Contacts'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigateBack('/settings/privacy'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Block a contact',
            onPressed: () => _showAddBlockedContactDialog(context, ref),
          ),
        ],
      ),
      body: blockedContactsAsync.when(
        data: (blockedContacts) {
          if (blockedContacts.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildBlockedContactsList(context, ref, blockedContacts);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          ),
        ),
        error: (error, stackTrace) => _buildErrorState(context, ref, error),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No blocked contacts',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Contacts you block will appear here. '
              'Blocked contacts cannot send you messages or see your updates.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedContactsList(
    BuildContext context,
    WidgetRef ref,
    List<RosterEntry> blockedContacts,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: blockedContacts.length,
      itemBuilder: (context, index) {
        final contact = blockedContacts[index];
        return _BlockedContactTile(
          contact: contact,
          onUnblock: () => _unblockContact(context, ref, contact),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load blocked contacts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(blockedRosterEntriesProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddBlockedContactDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final rosterAsync = ref.read(rosterEntriesProvider);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _ContactSelectionSheet(
            scrollController: scrollController,
            rosterAsync: rosterAsync,
            onContactSelected: (contact) async {
              Navigator.of(context).pop();
              await _blockContact(context, ref, contact);
            },
          );
        },
      ),
    );
  }

  Future<void> _blockContact(
    BuildContext context,
    WidgetRef ref,
    RosterEntry contact,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Contact'),
        content: Text(
          'Are you sure you want to block ${contact.displayName ?? contact.contactDetail}? '
          'They will not be able to send you messages or see your updates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      try {
        final repo = await ref.read(rosterRepositoryProvider.future);
        await repo.blockRosterEntry(contact.id);
        ref.invalidate(blockedRosterEntriesProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${contact.displayName ?? contact.contactDetail} has been blocked',
              ),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  await repo.unblockRosterEntry(contact.id);
                  ref.invalidate(blockedRosterEntriesProvider);
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to block contact: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _unblockContact(
    BuildContext context,
    WidgetRef ref,
    RosterEntry contact,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock Contact'),
        content: Text(
          'Are you sure you want to unblock ${contact.displayName ?? contact.contactDetail}? '
          'They will be able to send you messages again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      try {
        final repo = await ref.read(rosterRepositoryProvider.future);
        await repo.unblockRosterEntry(contact.id);
        ref.invalidate(blockedRosterEntriesProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${contact.displayName ?? contact.contactDetail} has been unblocked',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to unblock contact: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}

class _BlockedContactTile extends StatelessWidget {
  const _BlockedContactTile({required this.contact, required this.onUnblock});

  final RosterEntry contact;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
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
          backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
          child: Text(
            _getInitials(contact.displayName ?? contact.contactDetail),
            style: const TextStyle(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          contact.displayName ?? contact.contactDetail,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: contact.displayName != null
            ? Text(
                contact.contactDetail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: TextButton(
          onPressed: onUnblock,
          child: const Text('Unblock'),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _ContactSelectionSheet extends ConsumerWidget {
  const _ContactSelectionSheet({
    required this.scrollController,
    required this.rosterAsync,
    required this.onContactSelected,
  });

  final ScrollController scrollController;
  final AsyncValue<List<RosterEntry>> rosterAsync;
  final ValueChanged<RosterEntry> onContactSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Select a contact to block',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const Divider(),
        Expanded(
          child: rosterAsync.when(
            data: (contacts) {
              // Filter out already blocked contacts
              final unblockedContacts = contacts
                  .where((c) => !c.isBlocked)
                  .toList();

              if (unblockedContacts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No contacts available to block',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: scrollController,
                itemCount: unblockedContacts.length,
                itemBuilder: (context, index) {
                  final contact = unblockedContacts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        _getInitials(
                          contact.displayName ?? contact.contactDetail,
                        ),
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(contact.displayName ?? contact.contactDetail),
                    subtitle: contact.displayName != null
                        ? Text(contact.contactDetail)
                        : null,
                    onTap: () => onContactSelected(contact),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryGreen,
                ),
              ),
            ),
            error: (error, _) =>
                Center(child: Text('Error loading contacts: $error')),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
