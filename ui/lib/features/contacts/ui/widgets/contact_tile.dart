import 'package:flutter/material.dart';

import '../../data/roster_repository.dart';
import 'contact_avatar.dart';

/// A reusable tile widget for displaying a contact/profile
class ContactTile extends StatelessWidget {
  const ContactTile({
    required this.profileWithContacts,
    required this.onTap,
    this.showOnAppBadge = true,
    this.trailing,
    super.key,
  });

  final ProfileWithContacts profileWithContacts;
  final VoidCallback onTap;
  final bool showOnAppBadge;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = profileWithContacts.displayName;
    final avatarUrl = profileWithContacts.avatarUrl;
    final hasVerified = profileWithContacts.hasVerifiedContact;
    final contactSummary = profileWithContacts.contactSummary;

    return ListTile(
      leading: ContactAvatar(displayName: displayName, avatarUrl: avatarUrl),
      title: Row(
        children: [
          Expanded(
            child: Text(
              displayName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasVerified)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                Icons.verified,
                color: theme.colorScheme.primary,
                size: 18,
              ),
            ),
          if (showOnAppBadge && profileWithContacts.profile.id.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: _OnAppBadge(),
            ),
        ],
      ),
      subtitle: Text(
        contactSummary,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.chat_bubble_outline,
            color: theme.colorScheme.primary,
            size: 20,
          ),
      onTap: onTap,
    );
  }
}

class _OnAppBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 10, color: Colors.green.shade700),
          const SizedBox(width: 2),
          Text(
            'On App',
            style: TextStyle(
              fontSize: 9,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
