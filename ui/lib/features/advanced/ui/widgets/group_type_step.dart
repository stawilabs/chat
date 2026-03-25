import 'package:flutter/material.dart';

import '../../domain/group_finance_config.dart';

/// Step widget for selecting the financial group type
class GroupTypeStep extends StatelessWidget {
  const GroupTypeStep({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final GroupType? selected;
  final ValueChanged<GroupType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select group type',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose how your financial group will operate',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...GroupType.values.map(
          (type) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RadioListTile<GroupType>(
              value: type,
              groupValue: selected,
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              title: Text(type.displayName),
              subtitle: Text(
                type.description,
                style: theme.textTheme.bodySmall,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: selected == type
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              selected: selected == type,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
