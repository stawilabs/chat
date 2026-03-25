import 'package:flutter/material.dart';

import '../../domain/group_finance_config.dart';

/// Read-only summary of all configured finance fields
class FinanceSummaryStep extends StatelessWidget {
  const FinanceSummaryStep({required this.config, super.key});

  final GroupFinanceConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errors = config.validate();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review configuration',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Confirm the financial settings for your group',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _row(
                  Icons.category,
                  'Group Type',
                  config.groupType.displayName,
                ),
                const Divider(height: 24),
                _row(Icons.monetization_on, 'Currency', config.groupCurrency),
                if (config.periodType != null) ...[
                  const Divider(height: 24),
                  _row(
                    Icons.schedule,
                    'Period',
                    config.periodType!.displayName,
                  ),
                ],
                if (config.periodicSaving != null) ...[
                  const Divider(height: 24),
                  _row(
                    Icons.savings,
                    'Saving Amount',
                    '${config.groupCurrency} ${config.periodicSaving!.toStringAsFixed(2)}',
                  ),
                ],
                if (config.groupSavingsDay != null) ...[
                  const Divider(height: 24),
                  _row(
                    Icons.calendar_today,
                    'Start Date',
                    _formatDate(config.groupSavingsDay!),
                  ),
                ],
                if (config.terminationDate != null) ...[
                  const Divider(height: 24),
                  _row(
                    Icons.event_busy,
                    'Termination Date',
                    _formatDate(config.terminationDate!),
                  ),
                ],
                if (config.registrationFee != null) ...[
                  const Divider(height: 24),
                  _row(
                    Icons.receipt,
                    'Registration Fee',
                    '${config.groupCurrency} ${config.registrationFee!.toStringAsFixed(2)}',
                  ),
                ],
                if (config.membersRequired != null) ...[
                  const Divider(height: 24),
                  _row(
                    Icons.people,
                    'Members Required',
                    config.membersRequired.toString(),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (errors.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...errors.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 20, color: Colors.grey),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    ],
  );

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
