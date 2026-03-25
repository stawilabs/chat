import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_handler.dart';
import '../services/motion_service.dart';

/// Dialog for creating a new motion
/// Includes input validation and admin permission checking
class CreateMotionDialog extends ConsumerStatefulWidget {
  const CreateMotionDialog({required this.roomId, super.key});
  final String roomId;

  @override
  ConsumerState<CreateMotionDialog> createState() => _CreateMotionDialogState();
}

class _CreateMotionDialogState extends ConsumerState<CreateMotionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= 10) {
      ErrorHandler.showInfo(context, 'Maximum 10 options allowed');
      return;
    }
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) {
      ErrorHandler.showInfo(context, 'Minimum 2 options required');
      return;
    }
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  Future<void> _selectDeadline() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_deadline),
      );

      if (pickedTime != null) {
        setState(() {
          _deadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _createMotion() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate options
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ErrorHandler.showInfo(context, 'Please provide at least 2 options');
      return;
    }

    setState(() => _isCreating = true);

    try {
      final motionService = await ref.read(motionServiceProvider.future);
      await motionService.createMotion(
        roomId: widget.roomId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        options: options,
        deadline: _deadline,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ErrorHandler.showSuccess(context, 'Motion created successfully');
      }
    } catch (e, stack) {
      if (mounted) {
        ErrorHandler.handleError(context, e, stack, onRetry: _createMotion);
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Create Motion'),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Motion Title *',
                hintText: 'e.g., Approve new member',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                if (value.trim().length < 5) {
                  return 'Title must be at least 5 characters';
                }
                if (value.trim().length > 100) {
                  return 'Title must be less than 100 characters';
                }
                return null;
              },
              maxLength: 100,
              enabled: !_isCreating,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Provide more details...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
              enabled: !_isCreating,
            ),
            const SizedBox(height: 16),

            // Options
            const Text(
              'Options *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._optionControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Option ${index + 1}',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Option cannot be empty';
                          }
                          return null;
                        },
                        enabled: !_isCreating,
                      ),
                    ),
                    if (_optionControllers.length > 2)
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        onPressed: _isCreating
                            ? null
                            : () => _removeOption(index),
                      ),
                  ],
                ),
              );
            }),
            if (_optionControllers.length < 10)
              TextButton.icon(
                onPressed: _isCreating ? null : _addOption,
                icon: const Icon(Icons.add),
                label: const Text('Add Option'),
              ),
            const SizedBox(height: 16),

            // Deadline
            const Text(
              'Deadline *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(_formatDeadline(_deadline)),
              trailing: const Icon(Icons.edit),
              onTap: _isCreating ? null : _selectDeadline,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: _isCreating ? null : _createMotion,
        child: _isCreating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Create'),
      ),
    ],
  );

  String _formatDeadline(DateTime date) =>
      '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}
