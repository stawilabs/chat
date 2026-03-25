import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/navigation_helper.dart';
import '../../profile/data/profile_providers.dart';
import '../data/detail_panel_providers.dart';
import '../data/room_service.dart';
import '../data/room_subscription_service.dart';

/// Member role constants
class MemberRole {
  static const String owner = 'owner';
  static const String admin = 'admin';
  static const String moderator = 'moderator';
  static const String member = 'member';

  /// Check if a role has admin privileges
  static bool isAdmin(String? role) {
    final r = role?.toLowerCase() ?? '';
    return r == owner || r == admin;
  }

  /// Check if a role is owner
  static bool isOwner(String? role) {
    return role?.toLowerCase() == owner;
  }

  /// Get display name for a role
  static String displayName(String? role) {
    switch (role?.toLowerCase()) {
      case owner:
        return 'Owner';
      case admin:
        return 'Admin';
      case moderator:
        return 'Moderator';
      case member:
      default:
        return 'Member';
    }
  }
}

/// Bottom sheet for member actions (view profile, promote, demote, remove)
/// Only admins can see promote/demote/remove options
class MemberActionSheet extends ConsumerWidget {
  const MemberActionSheet({
    required this.roomId,
    required this.member,
    super.key,
  });

  final String roomId;
  final RoomSubscriptionInfo member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentProfileAsync = ref.watch(currentProfileProvider);

    return currentProfileAsync.when(
      data: (currentProfile) {
        if (currentProfile == null) {
          return _buildBasicActions(context, ref);
        }

        // Check if current user is an admin
        final currentUserIsAdmin = ref.watch(
          isCurrentUserAdminProvider((roomId, currentProfile.id)),
        );

        return currentUserIsAdmin.when(
          data: (isAdmin) =>
              _buildContent(context, ref, currentProfile.id, isAdmin),
          loading: () => _buildBasicActions(context, ref),
          error: (_, _) => _buildBasicActions(context, ref),
        );
      },
      loading: () => _buildBasicActions(context, ref),
      error: (_, _) => _buildBasicActions(context, ref),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    String currentProfileId,
    bool currentUserIsAdmin,
  ) {
    final theme = Theme.of(context);
    final isSelf = member.profileId == currentProfileId;
    final memberIsAdmin = MemberRole.isAdmin(member.role);
    final memberIsOwner = MemberRole.isOwner(member.role);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with member info
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getColorForName(
                    member.name,
                  ).withValues(alpha: 0.2),
                  backgroundImage: member.avatarUrl != null
                      ? NetworkImage(member.avatarUrl!)
                      : null,
                  child: member.avatarUrl == null
                      ? Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: _getColorForName(member.name),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        MemberRole.displayName(member.role),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (memberIsAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      memberIsOwner ? 'Owner' : 'Admin',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // View Profile action
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('View Profile'),
            onTap: () {
              Navigator.pop(context);
              if (member.profileId != null) {
                context.navigateToProfile(profileId: member.profileId!);
              }
            },
          ),

          // Message action
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Send Message'),
            onTap: () async {
              Navigator.pop(context);
              if (member.profileId != null && member.contactId != null) {
                try {
                  final roomService = await ref.read(
                    roomServiceProvider.future,
                  );
                  final room = await roomService.findOrCreateDirectRoom(
                    profileId: member.profileId!,
                    contactId: member.contactId!,
                    displayName: member.name,
                  );
                  if (context.mounted) {
                    context.navigateToChat(
                      roomId: room.id,
                      roomName: member.name,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to open chat: $e')),
                    );
                  }
                }
              }
            },
          ),

          // Admin actions (only visible to admins and not for self or owner)
          if (currentUserIsAdmin && !isSelf && !memberIsOwner) ...[
            const Divider(),

            // Promote/Demote
            if (!memberIsAdmin)
              ListTile(
                leading: Icon(
                  Icons.arrow_upward,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Make Admin'),
                subtitle: const Text('Grant admin privileges'),
                onTap: () => _promoteToAdmin(context, ref),
              )
            else
              ListTile(
                leading: Icon(
                  Icons.arrow_downward,
                  color: theme.colorScheme.tertiary,
                ),
                title: const Text('Remove Admin'),
                subtitle: const Text('Revoke admin privileges'),
                onTap: () => _demoteFromAdmin(context, ref),
              ),

            // Remove from group
            ListTile(
              leading: Icon(Icons.person_remove, color: Colors.red.shade600),
              title: Text(
                'Remove from Group',
                style: TextStyle(color: Colors.red.shade600),
              ),
              subtitle: const Text('Remove this member from the group'),
              onTap: () => _confirmRemoveMember(context, ref),
            ),
          ],

          // Self actions
          if (isSelf && !memberIsOwner) ...[
            const Divider(),
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.red.shade600),
              title: Text(
                'Leave Group',
                style: TextStyle(color: Colors.red.shade600),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmLeaveGroup(context, ref);
              },
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBasicActions(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('View Profile'),
            onTap: () {
              Navigator.pop(context);
              if (member.profileId != null) {
                context.navigateToProfile(profileId: member.profileId!);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Send Message'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Direct messaging coming soon')),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _promoteToAdmin(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);

    try {
      final roomService = await ref.read(roomServiceProvider.future);
      await roomService.promoteToAdmin(
        roomId: roomId,
        subscriptionId: member.id,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.name} is now an admin')),
        );
        // Refresh the members list
        ref.invalidate(roomMembersProvider(roomId));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to promote member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _demoteFromAdmin(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);

    try {
      final roomService = await ref.read(roomServiceProvider.future);
      await roomService.demoteFromAdmin(
        roomId: roomId,
        subscriptionId: member.id,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.name} is no longer an admin')),
        );
        ref.invalidate(roomMembersProvider(roomId));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to demote member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmRemoveMember(BuildContext context, WidgetRef ref) {
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.name} from this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeMember(context, ref);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(BuildContext context, WidgetRef ref) async {
    if (member.profileId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot remove member: missing profile ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final roomService = await ref.read(roomServiceProvider.future);
      await roomService.removeMemberByAdmin(
        roomId: roomId,
        subscriptionId: member.id,
        profileId: member.profileId!,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.name} has been removed')),
        );
        ref.invalidate(roomMembersProvider(roomId));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmLeaveGroup(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final roomService = await ref.read(roomServiceProvider.future);
                await roomService.leaveRoom(roomId);
                if (context.mounted) {
                  context.navigateBack('/');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to leave group: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Color _getColorForName(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];
    final index = name.isEmpty ? 0 : name.codeUnitAt(0) % colors.length;
    return colors[index];
  }
}

/// Provider to check if current user is an admin in the room
final isCurrentUserAdminProvider =
    FutureProvider.family<bool, (String, String)>((ref, args) async {
      final (roomId, profileId) = args;
      final memberRepo = ref.watch(roomSubscriptionRepositoryProvider);
      return memberRepo.isRoomAdmin(roomId, profileId);
    });

/// Show the member action sheet
void showMemberActionSheet({
  required BuildContext context,
  required String roomId,
  required RoomSubscriptionInfo member,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => MemberActionSheet(roomId: roomId, member: member),
  );
}
