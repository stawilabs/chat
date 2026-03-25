import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/invite_link.dart';

/// Dialog showing QR code for an invite link
class InviteLinkQrDialog extends StatelessWidget {
  const InviteLinkQrDialog({required this.link, super.key});

  final InviteLink link;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(link.name ?? 'Invite Link'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(Icons.qr_code_2, size: 160, color: Colors.grey[800]),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            link.inviteUrl,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Scan to join',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: link.inviteUrl));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link copied to clipboard')),
            );
          },
          child: const Text('Copy Link'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
