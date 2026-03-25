import 'package:flutter/material.dart';

import '../../messages/domain/room_event.dart';
import '../domain/group_finance_config.dart';

/// System-style banner bubble for group finance configuration events
class GroupConfigBubble extends StatelessWidget {
  const GroupConfigBubble({required this.event, super.key});

  final RoomEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String header;
    String detail;

    try {
      final config = GroupFinanceConfig.fromJson(event.content);
      header = 'Finance settings updated';
      detail = config.summary;
    } catch (_) {
      header = 'Finance settings updated';
      detail = 'Configuration changed';
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.green.withValues(alpha: 0.15)
              : Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 16,
              color: isDark ? Colors.green.shade300 : Colors.green.shade700,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    header,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.green.shade300
                          : Colors.green.shade700,
                    ),
                  ),
                  Text(
                    detail,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
