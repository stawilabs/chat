import 'package:flutter/material.dart';

/// Step widget for picking a date (reusable for savings start and termination)
class CalendarStep extends StatelessWidget {
  const CalendarStep({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    super.key,
  });

  final String label;
  final String subtitle;
  final DateTime? selected;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(
            selected != null
                ? '${selected!.day}/${selected!.month}/${selected!.year}'
                : 'Select a date',
          ),
          trailing: const Icon(Icons.chevron_right),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: selected ?? now,
              firstDate: firstDate ?? now,
              lastDate: lastDate ?? now.add(const Duration(days: 365 * 5)),
            );
            if (picked != null) onChanged(picked);
          },
        ),
      ],
    );
  }
}
