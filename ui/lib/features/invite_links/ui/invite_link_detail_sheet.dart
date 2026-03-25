import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../data/invite_link_providers.dart';
import '../domain/invite_link.dart';

/// Bottom sheet showing invite link details and actions
class InviteLinkDetailSheet extends ConsumerWidget {
  const InviteLinkDetailSheet({
    required this.link,
    required this.roomId,
    super.key,
  });

  final InviteLink link;
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                link.name ?? 'Invite Link',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    link.inviteUrl,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: link.inviteUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            'Uses',
            '${link.useCount}/${link.maxUses ?? '∞'}',
          ),
          if (link.expiresAt != null)
            _buildInfoRow(context, 'Expires', _formatExpiry(link.expiresAt!)),
          _buildInfoRow(
            context,
            'Requires Approval',
            link.requiresApproval ? 'Yes' : 'No',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(text: link.inviteUrl),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.link_off),
                  label: const Text('Revoke'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    await ref
                        .read(inviteLinkProvider.notifier)
                        .revokeLink(link.id, roomId);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  String _formatExpiry(int expiresAt) {
    final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt);
    final now = DateTime.now();
    final diff = expiry.difference(now);

    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return '${diff.inDays} days';
    if (diff.inHours > 0) return '${diff.inHours} hours';
    return '${diff.inMinutes} minutes';
  }
}
