import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/data/current_user_provider.dart';
import '../data/invite_link_providers.dart';
import '../domain/invite_link.dart';
import 'create_invite_link_dialog.dart';
import 'invite_link_detail_sheet.dart';
import 'invite_link_qr_dialog.dart';

/// Screen for managing invite links for a room
///
/// Displays all invite links for a room with options to:
/// - Create new links
/// - View link details and QR codes
/// - Copy/share links
/// - Revoke links
/// - See who joined via each link
class InviteLinksScreen extends ConsumerWidget {
  const InviteLinksScreen({
    required this.roomId,
    required this.roomName,
    super.key,
  });

  final String roomId;
  final String roomName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(roomInviteLinksProvider(roomId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Links'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: linksAsync.when(
        data: (links) => _buildLinksList(context, ref, links),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading invite links: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(roomInviteLinksProvider(roomId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add_link),
        label: const Text('Create Link'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildLinksList(
    BuildContext context,
    WidgetRef ref,
    List<InviteLink> links,
  ) {
    if (links.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.link_off,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No invite links yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a link to invite people to this group',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    // Group links by status
    final activeLinks = links.where((l) => l.isValid).toList();
    final inactiveLinks = links.where((l) => !l.isValid).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        if (activeLinks.isNotEmpty) ...[
          _buildSectionHeader(context, 'Active Links'),
          ...activeLinks.map((link) => _buildLinkTile(context, ref, link)),
        ],
        if (inactiveLinks.isNotEmpty) ...[
          _buildSectionHeader(context, 'Inactive Links'),
          ...inactiveLinks.map((link) => _buildLinkTile(context, ref, link)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLinkTile(BuildContext context, WidgetRef ref, InviteLink link) {
    final theme = Theme.of(context);
    final isActive = link.isValid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _showLinkDetails(context, ref, link),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                          : theme.colorScheme.outline.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isActive ? Icons.link : Icons.link_off,
                      color: isActive
                          ? AppTheme.primaryGreen
                          : theme.colorScheme.outline,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          link.name ?? 'Invite Link',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'chat.app/join/${link.code}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(context, link),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    context,
                    Icons.people_outline,
                    '${link.useCount} joined',
                  ),
                  if (link.maxUses != null) ...[
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      context,
                      Icons.numbers,
                      '${link.remainingUses} left',
                    ),
                  ],
                  if (link.expiresAt != null) ...[
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      context,
                      Icons.schedule,
                      _formatExpiry(link.expiresAt!),
                    ),
                  ],
                  if (link.requiresApproval) ...[
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      context,
                      Icons.verified_user_outlined,
                      'Approval',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isActive) ...[
                    IconButton(
                      icon: const Icon(Icons.qr_code),
                      onPressed: () => _showQrDialog(context, link),
                      tooltip: 'Show QR Code',
                      iconSize: 20,
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyLink(context, link),
                      tooltip: 'Copy Link',
                      iconSize: 20,
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => _shareLink(link),
                      tooltip: 'Share Link',
                      iconSize: 20,
                    ),
                  ],
                  IconButton(
                    icon: Icon(
                      isActive ? Icons.block : Icons.delete_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => isActive
                        ? _confirmRevoke(context, ref, link)
                        : _confirmDelete(context, ref, link),
                    tooltip: isActive ? 'Revoke Link' : 'Delete Link',
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, InviteLink link) {
    final Color color;
    final text = link.statusText;

    switch (text) {
      case 'Active':
        color = Colors.green;
      case 'Revoked':
        color = Colors.red;
      case 'Expired':
        color = Colors.orange;
      case 'Max uses reached':
        color = Colors.orange;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.outline),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  String _formatExpiry(int expiresAt) {
    final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt);
    final now = DateTime.now();

    if (expiry.isBefore(now)) {
      return 'Expired';
    }

    final diff = expiry.difference(now);
    if (diff.inDays > 0) {
      return '${diff.inDays}d left';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h left';
    } else {
      return '${diff.inMinutes}m left';
    }
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final profileId = await ref.read(currentProfileIdProvider.future);
    if (profileId == null || !context.mounted) return;

    showDialog(
      context: context,
      builder: (context) =>
          CreateInviteLinkDialog(roomId: roomId, createdBy: profileId),
    );
  }

  void _showLinkDetails(BuildContext context, WidgetRef ref, InviteLink link) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => InviteLinkDetailSheet(link: link, roomId: roomId),
    );
  }

  void _showQrDialog(BuildContext context, InviteLink link) {
    showDialog(
      context: context,
      builder: (context) => InviteLinkQrDialog(link: link),
    );
  }

  void _copyLink(BuildContext context, InviteLink link) {
    Clipboard.setData(ClipboardData(text: link.inviteUrl));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
  }

  void _shareLink(InviteLink link) {
    SharePlus.instance.share(
      ShareParams(
        text: 'Join our group on Chat!\n${link.inviteUrl}',
        subject: 'Invite to join $roomName',
      ),
    );
  }

  void _confirmRevoke(BuildContext context, WidgetRef ref, InviteLink link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Invite Link?'),
        content: const Text(
          'This link will no longer work for new members. '
          'Members who already joined will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(inviteLinkProvider.notifier).revokeLink(link.id, roomId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, InviteLink link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invite Link?'),
        content: const Text(
          'This will permanently delete the invite link and its history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(inviteLinkProvider.notifier).deleteLink(link.id, roomId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
