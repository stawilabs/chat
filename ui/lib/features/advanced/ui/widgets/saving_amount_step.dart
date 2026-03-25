import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Step widget for entering the periodic saving amount
class SavingAmountStep extends StatelessWidget {
  const SavingAmountStep({
    required this.currency,
    required this.controller,
    super.key,
  });

  final String currency;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saving amount',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'How much should each member contribute per period?',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          decoration: InputDecoration(
            prefixText: '$currency ',
            labelText: 'Amount per period',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Amount is required';
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) return 'Enter a valid amount';
            return null;
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }
}
