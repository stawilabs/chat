import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_theme.dart';
import '../../contacts/data/roster_repository.dart';
import '../../contacts/services/contact_service.dart';
import '../../contacts/ui/contact_permission_view.dart';
import '../../contacts/ui/widgets/contact_avatar.dart';
import '../data/room_service.dart';
import 'group_details_screen.dart';

class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final _searchController = TextEditingController();
  final _selectedContacts = <RosterEntry>{};
  final _scrollController = ScrollController();
  String _searchQuery = '';
  bool _isCreatingRoom = false;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final permissionAsync = ref.watch(contactPermissionGrantedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New chat'),
        actions: [
          // Show "Chat" button only when exactly 1 contact selected
          if (_selectedContacts.length == 1)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: _isCreatingRoom ? null : _createDirectChat,
                icon: _isCreatingRoom
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chat, size: 18),
                label: const Text('Chat'),
              ),
            ),
        ],
      ),
      body: permissionAsync.when(
        data: (hasPermission) {
          if (!hasPermission) {
            return ContactPermissionView(
              onPermissionGranted: () async {
                ref.invalidate(contactPermissionGrantedProvider);
                final rosterRepo = await ref.read(
                  rosterRepositoryProvider.future,
                );
                await rosterRepo.syncContactsLocal();
                unawaited(rosterRepo.syncContactsToServer());
              },
            );
          }
          return _buildContactSelectionBody(theme);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error checking permission: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(contactPermissionGrantedProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      // "Create group" FAB — visible when 2+ contacts selected
      floatingActionButton: _selectedContacts.length >= 2
          ? FloatingActionButton.extended(
              onPressed: _navigateToGroupDetails,
              backgroundColor: AppTheme.brightGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.group_add),
              label: const Text('Create group'),
            )
          : null,
    );
  }

  Widget _buildContactSelectionBody(ThemeData theme) {
    final rosterAsync = ref.watch(rosterStreamProvider);

    return Column(
      children: [
        // "To:" chip bar with search
        _buildToChipBar(theme),

        const Divider(height: 1),

        // Contact list
        Expanded(
          child: rosterAsync.when(
            data: (contacts) {
              final filteredContacts = _filterContacts(contacts);

              if (contacts.isEmpty) {
                return _buildEmptyState(theme);
              }

              if (filteredContacts.isEmpty && _searchQuery.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No contacts match "$_searchQuery"',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return _buildContactList(filteredContacts, theme);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load contacts',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => ref.invalidate(rosterStreamProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// "To:" chip bar with selected contact chips and inline search
  Widget _buildToChipBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'To:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _scrollController,
              child: Row(
                children: [
                  // Selected contact chips
                  ..._selectedContacts.map(
                    (contact) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _buildContactChip(contact, theme),
                    ),
                  ),
                  // Inline search field
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      style: theme.textTheme.bodyMedium,
                      onChanged: (value) {
                        setState(() => _searchQuery = value.toLowerCase());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  /// Individual contact chip with small avatar
  Widget _buildContactChip(RosterEntry contact, ThemeData theme) {
    final name = contact.displayName ?? contact.contactDetail;
    return GestureDetector(
      onTap: () => setState(() => _selectedContacts.remove(contact)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ContactAvatar(displayName: name, radius: 10),
            const SizedBox(width: 6),
            Text(
              name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Contact list with section headers and trailing check indicators
  Widget _buildContactList(List<RosterEntry> contacts, ThemeData theme) {
    // Split into verified (on app) and unverified
    final onApp = contacts.where((c) => c.isVerified).toList();
    final other = contacts.where((c) => !c.isVerified).toList();

    return ListView(
      children: [
        if (onApp.isNotEmpty) ...[
          _buildSectionHeader('Contacts on App', theme),
          ...onApp.map((c) => _buildContactTile(c, theme)),
        ],
        if (other.isNotEmpty) ...[
          _buildSectionHeader('Other contacts', theme),
          ...other.map((c) => _buildContactTile(c, theme)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: AppTheme.primaryGreen,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildContactTile(RosterEntry contact, ThemeData theme) {
    final isSelected = _selectedContacts.contains(contact);
    final name = contact.displayName ?? contact.contactDetail;

    return ListTile(
      leading: Stack(
        children: [
          ContactAvatar(displayName: name),
          if (contact.isVerified)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: contact.displayName != null
          ? Text(
              contact.contactDetail,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            )
          : null,
      trailing: _buildSelectionIndicator(isSelected, theme),
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedContacts.remove(contact);
          } else {
            _selectedContacts.add(contact);
          }
        });
        // Scroll chip bar to end after adding
        if (!isSelected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          });
        }
      },
    );
  }

  /// Green filled circle with checkmark when selected, grey outline when not
  Widget _buildSelectionIndicator(bool isSelected, ThemeData theme) {
    if (isSelected) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primaryGreen,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 18),
      );
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.outline, width: 1.5),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contacts_outlined,
            size: 80,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            'No contacts yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sync your contacts to find friends on the app',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _syncContacts,
            icon: const Icon(Icons.sync),
            label: const Text('Sync Contacts'),
          ),
        ],
      ),
    ),
  );

  List<RosterEntry> _filterContacts(List<RosterEntry> contacts) {
    if (_searchQuery.isEmpty) {
      return contacts;
    }

    return contacts.where((contact) {
      final name = (contact.displayName ?? '').toLowerCase();
      final detail = contact.contactDetail.toLowerCase();
      return name.contains(_searchQuery) || detail.contains(_searchQuery);
    }).toList();
  }

  Future<void> _syncContacts() async {
    final rosterRepo = await ref.read(rosterRepositoryProvider.future);

    if (!mounted) return;

    await rosterRepo.syncContactsLocal();
    unawaited(rosterRepo.syncContactsToServer());
  }

  /// Get the correct contact identifier based on priority:
  /// 1. contactId (if available) - from server
  /// 2. contactDetail (phone/email) - fallback
  String _getContactIdentifier(RosterEntry contact) {
    if (contact.contactId != null && contact.contactId!.isNotEmpty) {
      return contact.contactId!;
    }
    return contact.contactDetail;
  }

  void _navigateToGroupDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            GroupDetailsScreen(selectedContacts: _selectedContacts.toList()),
      ),
    );
  }

  Future<void> _createDirectChat() async {
    if (_selectedContacts.length != 1) return;

    setState(() => _isCreatingRoom = true);

    try {
      final roomService = await ref.read(roomServiceProvider.future);
      final contact = _selectedContacts.first;
      final contactIds = [_getContactIdentifier(contact)];
      final roomName = contact.displayName ?? contact.contactDetail;

      AppLogger.info(
        '[NewChat] Creating direct chat',
        data: {'name': roomName, 'type': 'direct'},
      );

      final room = await roomService.createRoom(
        name: roomName,
        type: 'direct',
        contactIds: contactIds,
      );

      if (mounted) {
        context.go('/chat/${room.id}?name=${Uri.encodeComponent(room.name)}');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '[NewChat] Failed to create direct chat',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create chat: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingRoom = false);
      }
    }
  }
}
