// ignore_for_file: avoid_annotating_with_dynamic, deprecated_member_use

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart' hide FormField;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../messages/domain/room_event.dart' as domain;
import '../data/form_message_controller.dart';
import '../domain/form_logic.dart';
import '../domain/form_message_models.dart';

class FormMessageCard extends ConsumerWidget {
  const FormMessageCard({
    required this.message,
    required this.isMe,
    super.key,
  });

  final domain.RoomEvent message;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = FormRequestMessageModel.fromContent(message.content);
    final state = ref.watch(formMessageControllerProvider(message));
    final submissionOwnerId = form.permissions.hasAssignee
        ? form.permissions.assigneeSubscriptionId
        : state.currentSubscriptionId;
    final submissionAsync = ref.watch(
      latestFormSubmissionEventProvider(
        (eventId: message.id, senderId: submissionOwnerId),
      ),
    );

    final directSnapshot = form.finalSubmissionSnapshot;
    final linkedSubmission = submissionAsync.asData?.value;
    final linkedSnapshot = linkedSubmission == null
        ? null
        : FormSubmissionResultMessageModel.fromContent(linkedSubmission.content)
              .submissionSnapshot;

    final directSnapshotMatchesCurrentUser =
        directSnapshot != null &&
        (!form.permissions.hasAssignee ||
            directSnapshot.submittedBySubscriptionId == submissionOwnerId);
    final snapshot = directSnapshotMatchesCurrentUser
        ? directSnapshot
        : linkedSnapshot;
    final shouldRenderSubmitted = form.permissions.hasAssignee
        ? snapshot != null || form.state == FormMessageState.submitted
        : snapshot != null;
    if (shouldRenderSubmitted) {
      return _SubmittedFormView(
        form: form,
        snapshot: snapshot,
        isMe: isMe,
      );
    }

    return _EditableFormView(message: message, form: form);
  }
}

class _EditableFormView extends ConsumerWidget {
  const _EditableFormView({required this.message, required this.form});

  final domain.RoomEvent message;
  final FormRequestMessageModel form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(formMessageControllerProvider(message));
    final controller = ref.read(formMessageControllerProvider(message).notifier);

    if (!state.hydrated) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!state.hasVisibleSteps) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('This form has no active steps for the current answers.'),
        ),
      );
    }

    if (!state.canEditForm) {
      return _FormLockedView(form: state.form);
    }

    final reviewSections = FormLogic.buildReviewSections(
      state.form.schema,
      state.answers,
    );
    final visibleStep = state.form.schema.steps[state.currentStep];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              form.title.isEmpty ? form.schema.title : form.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (form.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                form.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            _FormHeader(
              state: state,
              stepCount: state.visibleStepIndexes.length,
            ),
            const SizedBox(height: 12),
            if (!state.isReviewing)
              _StepView(
                step: visibleStep,
                answers: state.answers,
                validationMessages: state.validationMessages,
                permissions: state.form.permissions,
                onChanged: controller.updateAnswer,
              )
            else
              _ReviewView(
                sections: reviewSections,
                submissionError: state.submissionError,
                reviewConfirmed: state.reviewConfirmed,
                isSubmitting: state.isSubmitting,
                onEditStep: controller.jumpToStepById,
                onConfirmChanged: controller.setReviewConfirmed,
                onSubmit: controller.submit,
              ),
            if (!state.isReviewing) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (state.form.permissions.canGoBack &&
                      state.currentVisibleStepPosition > 0)
                    OutlinedButton(
                      onPressed: controller.previousStep,
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: controller.nextStep,
                    child: Text(state.isLastStep ? 'Review' : 'Next'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FormLockedView extends StatelessWidget {
  const _FormLockedView({required this.form});

  final FormRequestMessageModel form;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    form.title.isEmpty ? form.schema.title : form.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StateChip(
                  label: 'Assigned',
                  color: Colors.blueGrey.shade700,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'This form can only be completed by the assigned member.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (form.permissions.assigneeSubscriptionId.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Assigned subscription: ${form.permissions.assigneeSubscriptionId}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({required this.state, required this.stepCount});

  final FormMessageUiState state;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    final label = state.isReviewing
        ? 'Review and verify'
        : 'Step ${state.currentVisibleStepPosition + 1} of $stepCount';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: state.isReviewing
                    ? 1
                    : (state.currentStep + 1) / stepCount,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _StateChip(
          label: state.isReviewing ? 'Review' : 'Open',
          color: state.isReviewing
              ? Colors.orange.shade700
              : Colors.blue.shade700,
        ),
      ],
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({
    required this.step,
    required this.answers,
    required this.validationMessages,
    required this.permissions,
    required this.onChanged,
  });

  final FormStep step;
  final Map<String, dynamic> answers;
  final Map<String, String> validationMessages;
  final FormPermissions permissions;
  final void Function(String key, dynamic value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (step.title.isNotEmpty)
          Text(step.title, style: Theme.of(context).textTheme.titleSmall),
        if (step.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            step.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 12),
        for (final section in step.sections) ...[
          if (section.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                section.title,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          if (section.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                section.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          for (final field in section.fields)
            if (FormLogic.isFieldVisible(field, answers))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FieldRenderer(
                  field: field,
                  answers: answers,
                  value: answers[field.key],
                  errorText: validationMessages[field.key],
                  canEdit: FormLogic.isFieldEditable(field, answers, permissions),
                  onChanged: (value) => onChanged(field.key, value),
                ),
              ),
        ],
      ],
    );
  }
}

class _FieldRenderer extends StatelessWidget {
  const _FieldRenderer({
    required this.field,
    required this.answers,
    required this.value,
    required this.errorText,
    required this.canEdit,
    required this.onChanged,
  });

  final FormField field;
  final Map<String, dynamic> answers;
  final dynamic value;
  final String? errorText;
  final bool canEdit;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = field.requiredValue ? '${field.label} *' : field.label;
    final decoration = InputDecoration(
      labelText: label.isEmpty ? field.key : label,
      hintText: field.placeholder.isEmpty ? null : field.placeholder,
      helperText: field.helpText.isEmpty ? null : field.helpText,
      errorText: errorText,
      border: const OutlineInputBorder(),
    );

    if (field.type == FormFieldType.boolean) {
      return SwitchListTile.adaptive(
        value: value == true,
        onChanged: canEdit ? onChanged : null,
        title: Text(label.isEmpty ? field.key : label),
        subtitle: field.helpText.isEmpty ? null : Text(field.helpText),
      );
    }

    if (field.type == FormFieldType.select) {
      return DropdownButtonFormField<String>(
        value: value as String?,
        items: [
          for (final option in field.options)
            DropdownMenuItem<String>(
              value: option.value,
              child: Text(option.label.isEmpty ? option.value : option.label),
            ),
        ],
        onChanged: canEdit ? onChanged : null,
        decoration: decoration,
      );
    }

    if (field.type == FormFieldType.radio) {
      return InputDecorator(
        decoration: decoration,
        child: Column(
          children: [
            for (final option in field.options)
              RadioListTile<String>(
                value: option.value,
                groupValue: value as String?,
                onChanged: canEdit ? onChanged : null,
                title: Text(
                  option.label.isEmpty ? option.value : option.label,
                ),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      );
    }

    if (field.type == FormFieldType.checkboxGroup) {
      final selected = (value as List<dynamic>? ?? const []).cast<String>();
      return InputDecorator(
        decoration: decoration,
        child: Column(
          children: [
            for (final option in field.options)
              CheckboxListTile(
                value: selected.contains(option.value),
                onChanged: !canEdit
                    ? null
                    : (checked) {
                        final next = [...selected];
                        if ((checked ?? false) && !next.contains(option.value)) {
                          next.add(option.value);
                        } else {
                          next.remove(option.value);
                        }
                        onChanged(next);
                      },
                title: Text(
                  option.label.isEmpty ? option.value : option.label,
                ),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      );
    }

    if (field.type == FormFieldType.date || field.type == FormFieldType.datetime) {
      final text = value as String?;
      return InkWell(
        onTap: !canEdit
            ? null
            : () async {
                final now = DateTime.now();
                final initialDate = text == null
                    ? now
                    : DateTime.tryParse(text) ?? now;
                final pickedDate = await showDatePicker(
                  context: context,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                  initialDate: initialDate,
                );
                if (pickedDate == null) {
                  return;
                }
                if (!context.mounted) {
                  return;
                }
                if (field.type == FormFieldType.date) {
                  onChanged(pickedDate.toIso8601String().split('T').first);
                  return;
                }
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(initialDate),
                );
                if (pickedTime == null) {
                  return;
                }
                final combined = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
                onChanged(combined.toUtc().toIso8601String());
              },
        child: IgnorePointer(
          child: TextFormField(
            key: ValueKey('${field.key}-${text ?? ''}'),
            initialValue: text ?? '',
            decoration: decoration.copyWith(
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
          ),
        ),
      );
    }

    if (field.type == FormFieldType.file) {
      final fileValue = value as Map<String, dynamic>?;
      return InputDecorator(
        decoration: decoration,
        child: Row(
          children: [
            Expanded(
              child: Text(
                fileValue == null
                    ? 'No file selected'
                    : (fileValue['name'] as String? ?? 'Selected file'),
              ),
            ),
            TextButton(
              onPressed: !canEdit
                  ? null
                  : () async {
                      final file = await openFile();
                      if (file == null) {
                        return;
                      }
                      final size = await file.length();
                      onChanged({
                        'name': file.name,
                        'path': file.path,
                        'mimeType': '',
                        'size': size,
                      });
                    },
              child: const Text('Choose File'),
            ),
          ],
        ),
      );
    }

    if (field.type == FormFieldType.group ||
        field.type == FormFieldType.section ||
        field.type == FormFieldType.address) {
      final nestedAnswers = Map<String, dynamic>.from(
        value as Map? ?? const <String, dynamic>{},
      );
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.isEmpty ? field.key : label),
            if (field.helpText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                field.helpText,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            for (final nestedField in field.nestedFields)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FieldRenderer(
                  field: nestedField,
                  answers: answers,
                  value: nestedAnswers[nestedField.key],
                  errorText: errorText,
                  canEdit: canEdit,
                  onChanged: (nextValue) {
                    final next = Map<String, dynamic>.from(nestedAnswers);
                    next[nestedField.key] = nextValue;
                    onChanged(next);
                  },
                ),
              ),
            for (final nestedSection in field.nestedSections)
              for (final nestedField in nestedSection.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FieldRenderer(
                    field: nestedField,
                    answers: answers,
                    value: nestedAnswers[nestedField.key],
                    errorText: errorText,
                    canEdit: canEdit,
                    onChanged: (nextValue) {
                      final next = Map<String, dynamic>.from(nestedAnswers);
                      next[nestedField.key] = nextValue;
                      onChanged(next);
                    },
                  ),
                ),
          ],
        ),
      );
    }

    if (field.type == FormFieldType.repeatableGroup) {
      final rows = (value as List<dynamic>? ?? const []).cast<Map>();
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.isEmpty ? field.key : label),
            const SizedBox(height: 8),
            for (var index = 0; index < rows.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RepeatableGroupRow(
                  index: index,
                  field: field,
                  answers: answers,
                  row: Map<String, dynamic>.from(rows[index]),
                  onChanged: (nextRow) {
                    final next = rows.map(Map<String, dynamic>.from).toList();
                    next[index] = nextRow;
                    onChanged(next);
                  },
                  onRemove: () {
                    final next = rows.map(Map<String, dynamic>.from).toList();
                    next.removeAt(index);
                    onChanged(next);
                  },
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: !canEdit
                    ? null
                    : () {
                        final next = rows.map(Map<String, dynamic>.from).toList();
                        next.add(<String, dynamic>{});
                        onChanged(next);
                      },
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ),
          ],
        ),
      );
    }

    return TextFormField(
      key: ValueKey('${field.key}-${value ?? ''}'),
      initialValue: value?.toString() ?? '',
      enabled: canEdit,
      minLines: field.type == FormFieldType.multiline ? 4 : 1,
      maxLines: field.type == FormFieldType.multiline ? 6 : 1,
      keyboardType: _keyboardTypeForField(field),
      decoration: decoration,
      onChanged: onChanged,
    );
  }
}

class _RepeatableGroupRow extends StatelessWidget {
  const _RepeatableGroupRow({
    required this.index,
    required this.field,
    required this.answers,
    required this.row,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final FormField field;
  final Map<String, dynamic> answers;
  final Map<String, dynamic> row;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Item ${index + 1}'),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          for (final nestedField in field.nestedFields)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FieldRenderer(
                field: nestedField,
                answers: answers,
                value: row[nestedField.key],
                errorText: null,
                canEdit: true,
                onChanged: (value) {
                  final next = Map<String, dynamic>.from(row);
                  next[nestedField.key] = value;
                  onChanged(next);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewView extends StatelessWidget {
  const _ReviewView({
    required this.sections,
    required this.reviewConfirmed,
    required this.isSubmitting,
    required this.onEditStep,
    required this.onConfirmChanged,
    required this.onSubmit,
    this.submissionError,
  });

  final List<FormReviewSectionModel> sections;
  final bool reviewConfirmed;
  final bool isSubmitting;
  final void Function(String stepId) onEditStep;
  final ValueChanged<bool> onConfirmChanged;
  final VoidCallback onSubmit;
  final String? submissionError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < sections.length; index++) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sections[index].sectionTitle.isEmpty
                            ? sections[index].stepTitle
                            : sections[index].sectionTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () => onEditStep(sections[index].stepId),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
                for (final item in sections[index].items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.displayValue,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: reviewConfirmed,
          onChanged: (value) => onConfirmChanged(value ?? false),
          title: const Text('I confirm the details above are correct.'),
        ),
        if (submissionError != null) ...[
          const SizedBox(height: 8),
          Text(
            submissionError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: isSubmitting ? null : onSubmit,
            icon: isSubmitting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_outlined),
            label: const Text('Submit'),
          ),
        ),
      ],
    );
  }
}

class _SubmittedFormView extends StatelessWidget {
  const _SubmittedFormView({
    required this.form,
    required this.snapshot,
    required this.isMe,
  });

  final FormRequestMessageModel form;
  final FormSubmissionSnapshotModel? snapshot;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final effectiveSnapshot = snapshot ??
        FormSubmissionSnapshotModel(
          formInstanceId: form.formInstanceId,
          schemaId: form.schemaId,
          schemaVersion: form.schemaVersion,
          answers: const {},
          formattedSections: const [],
          submittedBySubscriptionId: '',
          status: FormMessageState.submitted,
        );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    form.title.isEmpty ? form.schema.title : form.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StateChip(
                  label: 'Submitted',
                  color: Colors.green.shade700,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (effectiveSnapshot.submittedAt != null)
              Text(
                'Submitted ${effectiveSnapshot.submittedAt!.toLocal()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (effectiveSnapshot.submittedBySubscriptionId.isNotEmpty)
              Text(
                'Submitted by ${effectiveSnapshot.submittedBySubscriptionId}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if ((effectiveSnapshot.submissionReference ?? '').isNotEmpty)
              Text(
                'Reference: ${effectiveSnapshot.submissionReference}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if ((effectiveSnapshot.workflowMessage ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(effectiveSnapshot.workflowMessage!),
            ],
            if ((effectiveSnapshot.backendMessage ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(effectiveSnapshot.backendMessage!),
            ],
            const SizedBox(height: 12),
            for (final section in effectiveSnapshot.formattedSections) ...[
              Text(
                section.sectionTitle.isEmpty
                    ? section.stepTitle
                    : section.sectionTitle,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              for (final item in section.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(item.label)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.displayValue,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

TextInputType? _keyboardTypeForField(FormField field) {
  if (field.type == FormFieldType.number) {
    return TextInputType.number;
  }
  if (field.type == FormFieldType.decimal ||
      field.type == FormFieldType.currency) {
    return const TextInputType.numberWithOptions(decimal: true);
  }
  if (field.type == FormFieldType.email) {
    return TextInputType.emailAddress;
  }
  if (field.type == FormFieldType.phone) {
    return TextInputType.phone;
  }
  return null;
}
