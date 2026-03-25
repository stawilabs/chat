import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../features/contacts/data/roster_repository.dart';
import '../../features/rooms/data/room_subscription_service.dart';

/// Sender name label with per-user color from rotating palette.
///
/// Only shown for received messages in group chats when not grouped.
class MessageSenderName extends ConsumerWidget {
  const MessageSenderName({required this.senderId, super.key});

  final String senderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = _getSenderName(ref);
    final color = AppTheme.getSenderNameColor(senderId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _getSenderName(WidgetRef ref) {
    final profileIdAsync = ref.watch(
      profileIdFromSubscriptionProvider(senderId),
    );
    final profilesAsync = ref.watch(profilesWithContactsStreamProvider);

    final profileId = profileIdAsync.when(
      data: (id) => id,
      loading: () => null,
      error: (_, _) => null,
    );

    return profilesAsync.when(
      data: (profiles) {
        if (profileId != null) {
          final senderProfile = profiles
              .where((p) => p.profile.id == profileId)
              .firstOrNull;
          if (senderProfile != null) {
            return senderProfile.displayName;
          }
        }
        return senderId;
      },
      loading: () => senderId,
      error: (_, _) => senderId,
    );
  }
}
