// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/db/database.dart';
import '../../../core/navigation/navigation_helper.dart';
import '../../calls/services/call_manager.dart';
import '../../calls/ui/call_screen.dart';
import '../../contacts/services/block_service.dart';
import '../../contacts/services/report_service.dart';
import '../../rooms/data/room_providers.dart';
import '../../rooms/data/room_service.dart';
import '../data/profile_providers.dart';

/// Profile details screen showing user information
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({required this.profileId, super.key});
  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByIdProvider(profileId));
    final isBlockedAsync = ref.watch(isUserBlockedProviderProvider(profileId));

    return Scaffold(
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return _buildNotFoundScreen(context);
          }
          return _buildProfileContent(
            context,
            ref,
            profile,
            isBlockedAsync.value ?? false,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading profile: $e')),
      ),
    );
  }

  Widget _buildNotFoundScreen(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Profile'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // Navigate back using navigation helper
          context.navigateBack();
        },
      ),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Profile not found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.navigateBack();
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    ),
  );

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
    bool isBlocked,
  ) {
    final theme = Theme.of(context);
    final sharedRoomsAsync = ref.watch(sharedRoomsProvider(profileId));

    return CustomScrollView(
      slivers: [
        // Profile header with large avatar
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Navigate back using navigation helper
              context.navigateBack();
            },
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Avatar
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage: profile.avatarUrl != null
                          ? NetworkImage(profile.avatarUrl!)
                          : null,
                      child: profile.avatarUrl == null
                          ? Text(
                              (profile.name ?? '?')[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Name
                    Text(
                      profile.name ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Status or blocked indicator
                    if (isBlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.block, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Blocked',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        'Member',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showOptionsMenu(context, ref, isBlocked),
            ),
          ],
        ),

        // Action buttons (hidden if blocked)
        if (!isBlocked)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    context,
                    icon: Icons.chat,
                    label: 'Message',
                    onTap: () => _startChat(context, ref, profile),
                  ),
                  _buildActionButton(
                    context,
                    icon: Icons.call,
                    label: 'Call',
                    onTap: () => _startCall(context, profile, ref: ref),
                  ),
                  _buildActionButton(
                    context,
                    icon: Icons.videocam,
                    label: 'Video',
                    onTap: () => _startVideoCall(context, profile, ref: ref),
                  ),
                ],
              ),
            ),
          ),

        // Blocked user actions
        if (isBlocked)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.block, size: 48, color: Colors.red.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'You have blocked this user',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'They cannot message you or see when you are online.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => _confirmUnblock(context, ref),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Unblock'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Profile info section
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context, 'About'),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Bio'),
                subtitle: Text(
                  _getMetadataValue(profile, 'bio') ?? 'No bio available',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const Divider(),
            ],
          ),
        ),

        // Shared groups section
        SliverToBoxAdapter(
          child: _buildSectionHeader(context, 'Shared Groups'),
        ),
        sharedRoomsAsync.when(
          data: (rooms) {
            if (rooms.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No shared groups',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final room = rooms[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.2,
                    ),
                    child: Text(
                      room.name.isNotEmpty ? room.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(room.name),
                  subtitle: const Text('Group'),
                  onTap: () => context.navigateToChat(
                    roomId: room.id,
                    roomName: room.name,
                  ),
                );
              }, childCount: rooms.length),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading shared groups: $e'),
            ),
          ),
        ),

        // Shared media section
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSectionHeader(context, 'Shared Media'),
              SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'No shared media',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, WidgetRef ref, bool isBlocked) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Contact'),
              onTap: () {
                Navigator.pop(context);
                SharePlus.instance.share(
                  ShareParams(
                    text:
                        'Check out this contact on Stawi: https://stawi.org/profile/$profileId',
                  ),
                );
              },
            ),
            if (isBlocked)
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Unblock'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmUnblock(context, ref);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Block'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmBlock(context, ref);
                },
              ),
            ListTile(
              leading: Icon(Icons.report, color: Colors.red.shade600),
              title: Text(
                'Report',
                style: TextStyle(color: Colors.red.shade600),
              ),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBlock(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Block User'),
        content: const Text(
          'Are you sure you want to block this user? They will not be able to message you and you will not see their messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _blockUser(context, ref);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _confirmUnblock(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unblock User'),
        content: const Text(
          'Are you sure you want to unblock this user? They will be able to message you again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _unblockUser(context, ref);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  Future<void> _blockUser(BuildContext context, WidgetRef ref) async {
    try {
      final blockService = await ref.read(blockServiceProvider.future);
      await blockService.blockUser(profileId);

      // Invalidate the blocked state
      ref.invalidate(isUserBlockedProviderProvider(profileId));
      ref.invalidate(blockedUsersProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User blocked'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to block user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unblockUser(BuildContext context, WidgetRef ref) async {
    try {
      final blockService = await ref.read(blockServiceProvider.future);
      await blockService.unblockUser(profileId);

      // Invalidate the blocked state
      ref.invalidate(isUserBlockedProviderProvider(profileId));
      ref.invalidate(blockedUsersProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User unblocked'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unblock user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReportDialog(BuildContext context, WidgetRef ref) {
    ReportReason? selectedReason;
    var alsoBlock = false;
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Report User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Why are you reporting this user?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                ...ReportReason.values.map(
                  (reason) => RadioListTile<ReportReason>(
                    title: Text(reason.displayName),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) =>
                        setState(() => selectedReason = value),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Additional details (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Provide more context about this report...',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: alsoBlock,
                      onChanged: (value) =>
                          setState(() => alsoBlock = value ?? false),
                    ),
                    Expanded(
                      child: Text(
                        'Also block this user',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      Navigator.pop(dialogContext);
                      await _submitReport(
                        context,
                        ref,
                        selectedReason!,
                        detailsController.text.isEmpty
                            ? null
                            : detailsController.text,
                      );
                      if (alsoBlock) {
                        final blockService = await ref.read(
                          blockServiceProvider.future,
                        );
                        await blockService.blockUser(profileId);
                      }
                    },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport(
    BuildContext context,
    WidgetRef ref,
    ReportReason reason,
    String? details,
  ) async {
    try {
      final reportService = await ref.read(reportServiceProvider.future);
      await reportService.submitReport(
        reportedUserId: profileId,
        reason: reason,
        details: details,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Report submitted. Thank you for helping keep our community safe.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startChat(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
  ) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Creating direct message...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Create or find direct message room with this user
      final roomListNotifier = ref.read(roomListProvider.notifier);
      final room = await roomListNotifier.createRoom(
        name: profile.name ?? 'Direct Message',
        type: 'direct',
        isPrivate: true,
        contactIds: [profile.id],
        metadata: {'directMessage': true, 'participantId': profile.id},
      );

      // Navigate to the newly created chat
      if (context.mounted) {
        context.navigateToChat(roomId: room.id, roomName: room.name);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startCall(
    BuildContext context,
    Profile profile, {
    required WidgetRef ref,
  }) async {
    try {
      final service = await ref.read(roomServiceProvider.future);
      final room = await service.findOrCreateDirectRoom(
        profileId: profile.id,
        contactId: profile.id,
        displayName: profile.name,
      );
      final callManager = await ref.read(callManagerProvider.future);
      await callManager.startCall(room.id);
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                CallScreen(roomId: room.id, roomName: profile.name ?? 'Call'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start call: $e')));
      }
    }
  }

  Future<void> _startVideoCall(
    BuildContext context,
    Profile profile, {
    required WidgetRef ref,
  }) async {
    try {
      final service = await ref.read(roomServiceProvider.future);
      final room = await service.findOrCreateDirectRoom(
        profileId: profile.id,
        contactId: profile.id,
        displayName: profile.name,
      );
      final callManager = await ref.read(callManagerProvider.future);
      await callManager.startCall(room.id);
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                CallScreen(roomId: room.id, roomName: profile.name ?? 'Call'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start video call: $e')),
        );
      }
    }
  }

  String? _getMetadataValue(Profile profile, String key) {
    if (profile.metadata == null) return null;
    try {
      // Assuming metadata is stored as JSON
      return null; // Would need to parse JSON
    } catch (e) {
      return null;
    }
  }
}
