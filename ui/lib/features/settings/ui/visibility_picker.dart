import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Visibility options for privacy settings
enum VisibilityOption {
  everyone('everyone', 'Everyone'),
  contacts('contacts', 'My Contacts'),
  nobody('nobody', 'Nobody');

  const VisibilityOption(this.value, this.label);

  final String value;
  final String label;

  static VisibilityOption fromValue(String value) =>
      VisibilityOption.values.firstWhere(
        (e) => e.value == value,
        orElse: () => VisibilityOption.everyone,
      );
}

/// A dialog picker for selecting visibility options
class VisibilityPicker extends StatelessWidget {
  const VisibilityPicker({
    required this.title,
    required this.description,
    required this.currentValue,
    required this.onChanged,
    super.key,
  });

  final String title;
  final String description;
  final String currentValue;
  final ValueChanged<String> onChanged;

  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String description,
    required String currentValue,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => _VisibilityPickerDialog(
        title: title,
        description: description,
        currentValue: currentValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentOption = VisibilityOption.fromValue(currentValue);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          currentOption.label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.primaryGreen),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
        onTap: () async {
          final result = await show(
            context: context,
            title: title,
            description: description,
            currentValue: currentValue,
          );
          if (result != null) {
            onChanged(result);
          }
        },
      ),
    );
  }
}

class _VisibilityPickerDialog extends StatelessWidget {
  const _VisibilityPickerDialog({
    required this.title,
    required this.description,
    required this.currentValue,
  });

  final String title;
  final String description;
  final String currentValue;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...VisibilityOption.values.map(
            (option) => _VisibilityOptionTile(
              option: option,
              isSelected: option.value == currentValue,
              onTap: () => Navigator.of(context).pop(option.value),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _VisibilityOptionTile extends StatelessWidget {
  const _VisibilityOptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final VisibilityOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        _getIconForOption(option),
        color: isSelected
            ? AppTheme.primaryGreen
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        option.label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected
              ? AppTheme.primaryGreen
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppTheme.primaryGreen)
          : null,
      onTap: onTap,
    );
  }

  IconData _getIconForOption(VisibilityOption option) {
    switch (option) {
      case VisibilityOption.everyone:
        return Icons.public;
      case VisibilityOption.contacts:
        return Icons.contacts;
      case VisibilityOption.nobody:
        return Icons.lock;
    }
  }
}
