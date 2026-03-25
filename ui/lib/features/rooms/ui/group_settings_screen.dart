import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_theme.dart';
import '../data/room_providers.dart';
import 'group_avatar_picker.dart';

/// Group settings screen for editing group name, description, avatar, and permissions
///
/// Requirements:
/// - Group name editing (max 100 chars)
/// - Group description editing (max 500 chars)
/// - Group avatar upload
/// - Settings for who can edit info, send messages, add members
/// - Changes logged as system messages
class GroupSettingsScreen extends ConsumerStatefulWidget {
  const GroupSettingsScreen({
    required this.roomId,
    required this.roomName,
    super.key,
  });

  final String roomId;
  final String roomName;

  @override
  ConsumerState<GroupSettingsScreen> createState() =>
      _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  String? _avatarUrl;
  bool _isLoading = false;
  bool _hasChanges = false;

  // Permission settings
  String _editInfoPermission = 'admins'; // 'admins', 'all_members'
  String _sendMessagesPermission = 'all_members'; // 'admins', 'all_members'
  String _addMembersPermission = 'admins'; // 'admins', 'all_members'

  // Character limits
  static const int _maxNameLength = 100;
  static const int _maxDescriptionLength = 500;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.roomName);
    _descriptionController = TextEditingController();
    _loadRoomData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadRoomData() async {
    try {
      final room = await ref.read(roomByIdProvider(widget.roomId).future);
      if (room != null && mounted) {
        setState(() {
          _nameController.text = room.name;
          final metadata = room.metadata ?? {};
          _descriptionController.text =
              metadata['description'] as String? ?? '';
          _avatarUrl = metadata['avatarUrl'] as String?;
          _editInfoPermission =
              metadata['editInfoPermission'] as String? ?? 'admins';
          _sendMessagesPermission =
              metadata['sendMessagesPermission'] as String? ?? 'all_members';
          _addMembersPermission =
              metadata['addMembersPermission'] as String? ?? 'admins';
        });
      }
    } catch (e, stackTrace) {
      // Log error but don't crash - fields will have default values
      AppLogger.error(
        'Failed to load room data',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name cannot be empty')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final roomListNotifier = ref.read(roomListProvider.notifier);

      // Build metadata with all settings
      final metadata = <String, dynamic>{
        'description': _descriptionController.text.trim(),
        'editInfoPermission': _editInfoPermission,
        'sendMessagesPermission': _sendMessagesPermission,
        'addMembersPermission': _addMembersPermission,
        if (_avatarUrl != null) 'avatarUrl': _avatarUrl,
      };

      await roomListNotifier.updateRoom(
        roomId: widget.roomId,
        name: name,
        description: _descriptionController.text.trim(),
        metadata: metadata,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Group settings saved')));
        setState(() {
          _hasChanges = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _onAvatarChanged(String? newUrl) {
    setState(() {
      _avatarUrl = newUrl;
      _hasChanges = true;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to leave without saving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          // Use Navigator.pop directly to avoid retriggering onPopInvokedWithResult
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Group Settings'),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Let PopScope handle the confirmation dialog if there are changes
              Navigator.of(context).maybePop();
            },
          ),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar section
              Center(
                child: GroupAvatarPicker(
                  roomId: widget.roomId,
                  currentAvatarUrl: _avatarUrl,
                  groupName: _nameController.text,
                  onAvatarChanged: _onAvatarChanged,
                ),
              ),
              const SizedBox(height: 24),

              // Group name section
              _buildSectionHeader(context, 'Group Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                maxLength: _maxNameLength,
                decoration: InputDecoration(
                  hintText: 'Enter group name',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterText: '${_nameController.text.length}/$_maxNameLength',
                ),
                onChanged: (_) => _onFieldChanged(),
              ),
              const SizedBox(height: 24),

              // Group description section
              _buildSectionHeader(context, 'Group Description'),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLength: _maxDescriptionLength,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter group description (optional)',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterText:
                      '${_descriptionController.text.length}/$_maxDescriptionLength',
                ),
                onChanged: (_) => _onFieldChanged(),
              ),
              const SizedBox(height: 32),

              // Permissions section
              _buildSectionHeader(context, 'Group Permissions'),
              const SizedBox(height: 16),

              _buildPermissionDropdown(
                context,
                title: 'Who can edit group info',
                subtitle: 'Change name, description, and avatar',
                value: _editInfoPermission,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _editInfoPermission = value;
                      _hasChanges = true;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              _buildPermissionDropdown(
                context,
                title: 'Who can send messages',
                subtitle: 'Post messages to the group',
                value: _sendMessagesPermission,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sendMessagesPermission = value;
                      _hasChanges = true;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              _buildPermissionDropdown(
                context,
                title: 'Who can add members',
                subtitle: 'Invite new people to the group',
                value: _addMembersPermission,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _addMembersPermission = value;
                      _hasChanges = true;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) => Text(
    title,
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
      letterSpacing: 0.5,
    ),
  );

  Widget _buildPermissionDropdown(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String value,
    required void Function(String?) onChanged,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButton<String>(
                value: value,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'admins', child: Text('Only admins')),
                  DropdownMenuItem(
                    value: 'all_members',
                    child: Text('All members'),
                  ),
                ],
                onChanged: onChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
