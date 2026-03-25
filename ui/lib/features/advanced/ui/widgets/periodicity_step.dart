import 'package:flutter/material.dart';

import '../../domain/group_finance_config.dart';

/// Step widget for selecting the savings period
class PeriodicityStep extends StatelessWidget {
  const PeriodicityStep({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final PeriodType? selected;
  final ValueChanged<PeriodType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Savings period',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'How often should members contribute?',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...PeriodType.values.map(
          (type) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RadioListTile<PeriodType>(
              value: type,
              groupValue: selected,
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              title: Text(type.displayName),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: selected == type
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              selected: selected == type,
            ),
          ),
        ),
      ],
    );
  }
}
