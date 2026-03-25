import 'package:flutter/material.dart';

/// Bottom sheet for editing a message
///
/// Shows the current message text in an editable field and provides
/// Save and Cancel buttons.
class EditMessageSheet extends StatefulWidget {
  const EditMessageSheet({
    required this.messageId,
    required this.currentText,
    required this.onSave,
    super.key,
  });
  final String messageId;
  final String currentText;
  final Future<bool> Function(String messageId, String newText) onSave;

  @override
  State<EditMessageSheet> createState() => _EditMessageSheetState();
}

class _EditMessageSheetState extends State<EditMessageSheet> {
  late TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasChanges => _controller.text.trim() != widget.currentText.trim();

  bool get _canSave =>
      _hasChanges && _controller.text.trim().isNotEmpty && !_isSaving;

  Future<void> _save() async {
    if (!_canSave) return;

    setState(() => _isSaving = true);

    final success = await widget.onSave(
      widget.messageId,
      _controller.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to edit message. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.edit, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Edit Message',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Text field
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: null,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Enter message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _canSave ? _save : null,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the edit message sheet
///
/// Returns true if the message was edited successfully, false otherwise.
Future<bool> showEditMessageSheet({
  required BuildContext context,
  required String messageId,
  required String currentText,
  required Future<bool> Function(String messageId, String newText) onSave,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => EditMessageSheet(
      messageId: messageId,
      currentText: currentText,
      onSave: onSave,
    ),
  );

  return result ?? false;
}
