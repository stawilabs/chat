import 'package:flutter/material.dart';

/// Curated list of currencies
const _currencies = [
  ('KES', 'Kenyan Shilling'),
  ('TZS', 'Tanzanian Shilling'),
  ('UGX', 'Ugandan Shilling'),
  ('USD', 'US Dollar'),
  ('EUR', 'Euro'),
  ('GBP', 'British Pound'),
];

/// Step widget for selecting the group currency
class CurrencyStep extends StatelessWidget {
  const CurrencyStep({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final String? selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select currency',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the currency for group transactions',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: selected,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.monetization_on_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            labelText: 'Currency',
          ),
          items: _currencies
              .map(
                (c) => DropdownMenuItem(
                  value: c.$1,
                  child: Text('${c.$1} — ${c.$2}'),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}
