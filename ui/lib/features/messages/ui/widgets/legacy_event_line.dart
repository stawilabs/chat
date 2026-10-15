import 'package:flutter/material.dart';

/// Stand-in for the retired off-chain event types (motion, transaction,
/// group config). Stored rows still decode; they render as this grey line.
class LegacyEventLine extends StatelessWidget {
  const LegacyEventLine({super.key = const Key('legacy-event')});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Center(
        child: Text(
          'This message type is no longer supported',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
