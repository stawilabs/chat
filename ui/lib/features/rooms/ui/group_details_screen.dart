import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xid/xid.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_theme.dart';
import '../../contacts/data/roster_repository.dart';
import '../../contacts/ui/widgets/contact_avatar.dart';
import '../data/room_service.dart';
import 'group_avatar_picker.dart';

/// Step 2 of group creation: enter group name, description, and avatar
class GroupDetailsScreen extends ConsumerStatefulWidget {
  const GroupDetailsScreen({required this.selectedContacts, super.key});

  final List<RosterEntry> selectedContacts;

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nameFocusNode = FocusNode();
  late final String _tempRoomId;
  String? _avatarUrl;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _tempRoomId = Xid().toString();
    // Auto-focus the name field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupName = _nameController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New group'),
        actions: [
          IconButton(
            onPressed: _isCreating || groupName.isEmpty ? null : _createGroup,
            icon: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.check,
                    color: groupName.isEmpty
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                        : AppTheme.brightGreen,
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group avatar picker
            Center(
              child: GroupAvatarPicker(
                roomId: _tempRoomId,
                groupName: _nameController.text,
                currentAvatarUrl: _avatarUrl,
                onAvatarChanged: (url) {
                  setState(() => _avatarUrl = url);
                },
                size: 100,
              ),
            ),
            const SizedBox(height: 24),

            // Group name input
            TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              decoration: InputDecoration(
                labelText: 'Group name',
                hintText: 'Enter group name',
                prefixIcon: const Icon(Icons.group),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Group description input
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Group description (optional)',
                hintText: 'What is this group about?',
                prefixIcon: const Icon(Icons.info_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 24),

            const Divider(),
            const SizedBox(height: 16),

            // Members section header
            Text(
              'Members \u00b7 ${widget.selectedContacts.length}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Members list
            ...widget.selectedContacts.map(
              (contact) => _buildMemberTile(contact, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(RosterEntry contact, ThemeData theme) {
    final name = contact.displayName ?? contact.contactDetail;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: ContactAvatar(displayName: name, radius: 20),
        title: Text(name),
        subtitle: contact.displayName != null
            ? Text(
                contact.contactDetail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              )
            : null,
        contentPadding: EdgeInsets.zero,
      ),
    );
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

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);

    try {
      final roomService = await ref.read(roomServiceProvider.future);
      final contactIds = widget.selectedContacts
          .map(_getContactIdentifier)
          .toList();
      final description = _descriptionController.text.trim();

      AppLogger.info(
        '[GroupDetails] Creating group',
        data: {
          'name': name,
          'memberCount': contactIds.length,
          'hasDescription': description.isNotEmpty,
          'hasAvatar': _avatarUrl != null,
        },
      );

      final metadata = <String, dynamic>{};
      if (_avatarUrl != null) metadata['avatarUrl'] = _avatarUrl;

      final room = await roomService.createRoom(
        name: name,
        type: 'group',
        description: description.isNotEmpty ? description : null,
        contactIds: contactIds,
        metadata: metadata.isNotEmpty ? metadata : null,
      );

      if (mounted) {
        // Pop both screens (GroupDetailsScreen + NewChatScreen) and go to chat
        context.go('/chat/${room.id}?name=${Uri.encodeComponent(room.name)}');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '[GroupDetails] Failed to create group',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}
