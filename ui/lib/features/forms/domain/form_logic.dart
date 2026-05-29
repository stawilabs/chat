// ignore_for_file: avoid_annotating_with_dynamic

import 'dart:math' as math;

import 'form_message_models.dart';

class FormValidationIssue {
  const FormValidationIssue({
    required this.fieldKey,
    required this.message,
    this.stepIndex,
  });

  final String fieldKey;
  final String message;
  final int? stepIndex;
}

class FormLogic {
  const FormLogic._();

  static bool isFieldVisible(FormField field, Map<String, dynamic> answers) {
    if (field.hidden) {
      return false;
    }
    return _matchesGroup(field.visibilityCondition, answers);
  }

  static bool isFieldEditable(
    FormField field,
    Map<String, dynamic> answers,
    FormPermissions permissions,
  ) {
    if (!permissions.canEdit) {
      return false;
    }
    return _matchesGroup(field.editabilityCondition, answers);
  }

  static List<FormField> fieldsForStep(
    FormStep step,
    Map<String, dynamic> answers,
  ) {
    return [
      for (final section in step.sections)
        for (final field in section.fields)
          if (isFieldVisible(field, answers)) field,
    ];
  }

  static bool isStepVisible(FormStep step, Map<String, dynamic> answers) {
    return _matchesGroup(step.visibilityCondition, answers);
  }

  static List<int> visibleStepIndexes(
    FormSchema schema,
    Map<String, dynamic> answers,
  ) {
    return [
      for (var index = 0; index < schema.steps.length; index++)
        if (isStepVisible(schema.steps[index], answers)) index,
    ];
  }

  static int normalizeStepIndex(
    FormSchema schema,
    Map<String, dynamic> answers, {
    required int preferredIndex,
  }) {
    final visible = visibleStepIndexes(schema, answers);
    if (visible.isEmpty) {
      return 0;
    }
    if (visible.contains(preferredIndex)) {
      return preferredIndex;
    }
    for (final index in visible) {
      if (index > preferredIndex) {
        return index;
      }
    }
    return visible.last;
  }

  static int? nextVisibleStepIndex(
    FormSchema schema,
    Map<String, dynamic> answers,
    int currentStepIndex,
  ) {
    final visible = visibleStepIndexes(schema, answers);
    for (final index in visible) {
      if (index > currentStepIndex) {
        return index;
      }
    }
    return null;
  }

  static int? previousVisibleStepIndex(
    FormSchema schema,
    Map<String, dynamic> answers,
    int currentStepIndex,
  ) {
    final visible = visibleStepIndexes(schema, answers);
    for (var index = visible.length - 1; index >= 0; index--) {
      if (visible[index] < currentStepIndex) {
        return visible[index];
      }
    }
    return null;
  }

  static int? stepIndexById(FormSchema schema, String stepId) {
    for (var index = 0; index < schema.steps.length; index++) {
      if (schema.steps[index].id == stepId) {
        return index;
      }
    }
    return null;
  }

  static List<FormValidationIssue> validateStep(
    FormSchema schema,
    int stepIndex,
    Map<String, dynamic> answers,
  ) {
    if (stepIndex < 0 || stepIndex >= schema.steps.length) {
      return const [];
    }
    final issues = <FormValidationIssue>[];
    final step = schema.steps[stepIndex];
    if (!isStepVisible(step, answers)) {
      return const [];
    }
    for (final section in step.sections) {
      for (final field in section.fields) {
        issues.addAll(
          _validateField(
            field,
            answers,
            rootAnswers: answers,
            stepIndex: stepIndex,
          ),
        );
      }
    }
    return issues;
  }

  static List<FormValidationIssue> validateAll(
    FormSchema schema,
    Map<String, dynamic> answers,
  ) {
    final issues = <FormValidationIssue>[];
    for (final index in visibleStepIndexes(schema, answers)) {
      issues.addAll(validateStep(schema, index, answers));
    }
    return issues;
  }

  static List<FormReviewSectionModel> buildReviewSections(
    FormSchema schema,
    Map<String, dynamic> answers,
  ) {
    final sections = <FormReviewSectionModel>[];
    for (final step in schema.steps) {
      if (!isStepVisible(step, answers)) {
        continue;
      }
      for (final section in step.sections) {
        final items = <FormReviewItem>[];
        for (final field in section.fields) {
          items.addAll(_reviewItemsForField(field, answers, answers));
        }
        if (items.isNotEmpty) {
          sections.add(
            FormReviewSectionModel(
              stepId: step.id,
              stepTitle: step.title,
              sectionId: section.id,
              sectionTitle: section.title,
              items: items,
            ),
          );
        }
      }
    }
    return sections;
  }

  static List<FormValidationIssue> _validateField(
    FormField field,
    Map<String, dynamic> scopeAnswers, {
    required Map<String, dynamic> rootAnswers,
    required int stepIndex,
  }) {
    if (!isFieldVisible(field, rootAnswers)) {
      return const [];
    }

    final value = scopeAnswers[field.key];
    final issues = <FormValidationIssue>[];
    final isRequired =
        field.requiredValue ||
        field.validationRules.any((rule) => rule.requiredValue ?? false);
    if (_isEmptyValue(value)) {
      if (isRequired) {
        issues.add(
          FormValidationIssue(
            fieldKey: field.key,
            message:
                '${field.label.isEmpty ? field.key : field.label} is required',
            stepIndex: stepIndex,
          ),
        );
      }
      return issues;
    }

    if (field.type == FormFieldType.group ||
        field.type == FormFieldType.section) {
      final groupAnswers = Map<String, dynamic>.from(value as Map);
      for (final nestedField in field.nestedFields) {
        issues.addAll(
          _validateField(
            nestedField,
            groupAnswers,
            rootAnswers: rootAnswers,
            stepIndex: stepIndex,
          ),
        );
      }
      for (final nestedSection in field.nestedSections) {
        for (final nestedField in nestedSection.fields) {
          issues.addAll(
            _validateField(
              nestedField,
              groupAnswers,
              rootAnswers: rootAnswers,
              stepIndex: stepIndex,
            ),
          );
        }
      }
      return issues;
    }

    if (field.type == FormFieldType.repeatableGroup) {
      final rows = value as List<dynamic>;
      for (final row in rows) {
        final map = Map<String, dynamic>.from(row as Map);
        for (final nestedField in field.nestedFields) {
          issues.addAll(
            _validateField(
              nestedField,
              map,
              rootAnswers: rootAnswers,
              stepIndex: stepIndex,
            ),
          );
        }
      }
      return issues;
    }

    for (final rule in field.validationRules) {
      final message = rule.message.isEmpty ? 'is invalid' : rule.message;
      if (rule.minLength != null &&
          value is String &&
          value.trim().length < rule.minLength!) {
        issues.add(
          FormValidationIssue(
            fieldKey: field.key,
            message: message,
            stepIndex: stepIndex,
          ),
        );
      }
      if (rule.maxLength != null &&
          value is String &&
          value.length > rule.maxLength!) {
        issues.add(
          FormValidationIssue(
            fieldKey: field.key,
            message: message,
            stepIndex: stepIndex,
          ),
        );
      }
      if (rule.minItems != null &&
          value is List &&
          value.length < rule.minItems!) {
        issues.add(
          FormValidationIssue(
            fieldKey: field.key,
            message: message,
            stepIndex: stepIndex,
          ),
        );
      }
      if (rule.maxItems != null &&
          value is List &&
          value.length > rule.maxItems!) {
        issues.add(
          FormValidationIssue(
            fieldKey: field.key,
            message: message,
            stepIndex: stepIndex,
          ),
        );
      }
      if (rule.minValue != null) {
        final number = _toNum(value);
        if (number != null && number < rule.minValue!) {
          issues.add(
            FormValidationIssue(
              fieldKey: field.key,
              message: message,
              stepIndex: stepIndex,
            ),
          );
        }
      }
      if (rule.maxValue != null) {
        final number = _toNum(value);
        if (number != null && number > rule.maxValue!) {
          issues.add(
            FormValidationIssue(
              fieldKey: field.key,
              message: message,
              stepIndex: stepIndex,
            ),
          );
        }
      }
      if (rule.pattern != null && value is String) {
        final regex = RegExp(rule.pattern!);
        if (!regex.hasMatch(value)) {
          issues.add(
            FormValidationIssue(
              fieldKey: field.key,
              message: message,
              stepIndex: stepIndex,
            ),
          );
        }
      }
    }

    if ((field.type == FormFieldType.select ||
            field.type == FormFieldType.radio) &&
        value is String &&
        !_isAllowedOption(field, value)) {
      issues.add(
        FormValidationIssue(
          fieldKey: field.key,
          message:
              '${field.label.isEmpty ? field.key : field.label} has an invalid option',
          stepIndex: stepIndex,
        ),
      );
    }

    if (field.type == FormFieldType.checkboxGroup && value is List) {
      final invalid = value.any(
        (item) => item is! String || !_isAllowedOption(field, item),
      );
      if (invalid) {
        issues.add(
          FormValidationIssue(
            fieldKey: field.key,
            message:
                '${field.label.isEmpty ? field.key : field.label} has an invalid option',
            stepIndex: stepIndex,
          ),
        );
      }
    }

    return issues;
  }

  static List<FormReviewItem> _reviewItemsForField(
    FormField field,
    Map<String, dynamic> scopeAnswers,
    Map<String, dynamic> rootAnswers,
  ) {
    if (!isFieldVisible(field, rootAnswers) || !field.review.includeInReview) {
      return const [];
    }

    final value = scopeAnswers[field.key];
    if (_isEmptyValue(value)) {
      return const [];
    }

    if (field.type == FormFieldType.group ||
        field.type == FormFieldType.section) {
      final nestedAnswers = Map<String, dynamic>.from(value as Map);
      return [
        for (final nestedField in field.nestedFields)
          ..._reviewItemsForField(nestedField, nestedAnswers, rootAnswers),
        for (final nestedSection in field.nestedSections)
          for (final nestedField in nestedSection.fields)
            ..._reviewItemsForField(nestedField, nestedAnswers, rootAnswers),
      ];
    }

    if (field.type == FormFieldType.repeatableGroup) {
      final rows = value as List<dynamic>;
      return [
        FormReviewItem(
          fieldKey: field.key,
          label: field.review.label.isEmpty ? field.label : field.review.label,
          displayValue: '${rows.length} entries',
          emphasized: false,
        ),
      ];
    }

    return [
      FormReviewItem(
        fieldKey: field.key,
        label: field.review.label.isEmpty ? field.label : field.review.label,
        displayValue: _formatValue(field, value),
        emphasized: false,
      ),
    ];
  }

  static String _formatValue(FormField field, dynamic value) {
    if (value == null) {
      return '';
    }
    if (field.type == FormFieldType.boolean && value is bool) {
      return value ? 'Yes' : 'No';
    }
    if ((field.type == FormFieldType.select ||
            field.type == FormFieldType.radio) &&
        value is String) {
      final matches = field.options.where((item) => item.value == value);
      return matches.isEmpty ? value : matches.first.label;
    }
    if (field.type == FormFieldType.checkboxGroup && value is List) {
      final labels = value.whereType<String>().map((entry) {
        final matches = field.options.where((item) => item.value == entry);
        return matches.isEmpty ? entry : matches.first.label;
      }).toList();
      return labels.join(', ');
    }
    if ((field.type == FormFieldType.currency ||
            field.type == FormFieldType.decimal ||
            field.type == FormFieldType.number) &&
        value is num) {
      final scale =
          field.formatting.decimalScale ??
          (field.type == FormFieldType.number ? 0 : 2);
      return value.toStringAsFixed(math.max(0, scale));
    }
    if (value is List) {
      return value.join(', ');
    }
    return value.toString();
  }

  static bool _matchesGroup(
    FormConditionGroup group,
    Map<String, dynamic> answers,
  ) {
    if (group.all.isNotEmpty &&
        group.all.any((clause) => !_matchesClause(clause, answers))) {
      return false;
    }
    if (group.any.isNotEmpty &&
        !group.any.any((clause) => _matchesClause(clause, answers))) {
      return false;
    }
    return true;
  }

  static bool _matchesClause(
    FormConditionClause clause,
    Map<String, dynamic> answers,
  ) {
    final value = answers[clause.fieldKey];
    switch (clause.operator) {
      case FormConditionOperator.exists:
        return !_isEmptyValue(value);
      case FormConditionOperator.notExists:
        return _isEmptyValue(value);
      case FormConditionOperator.isTrue:
        return value == true;
      case FormConditionOperator.isFalse:
        return value == false;
      case FormConditionOperator.equals:
        return value == clause.value;
      case FormConditionOperator.notEquals:
        return value != clause.value;
      case FormConditionOperator.greaterThan:
        final left = _toNum(value);
        final right = _toNum(clause.value);
        return left != null && right != null && left > right;
      case FormConditionOperator.greaterThanOrEqual:
        final left = _toNum(value);
        final right = _toNum(clause.value);
        return left != null && right != null && left >= right;
      case FormConditionOperator.lessThan:
        final left = _toNum(value);
        final right = _toNum(clause.value);
        return left != null && right != null && left < right;
      case FormConditionOperator.lessThanOrEqual:
        final left = _toNum(value);
        final right = _toNum(clause.value);
        return left != null && right != null && left <= right;
      case FormConditionOperator.contains:
        if (value is List) {
          return value.contains(clause.value);
        }
        if (value is String && clause.value is String) {
          return value.contains(clause.value as String);
        }
        return false;
      case FormConditionOperator.notContains:
        if (value is List) {
          return !value.contains(clause.value);
        }
        if (value is String && clause.value is String) {
          return !value.contains(clause.value as String);
        }
        return true;
      case FormConditionOperator.within:
        return clause.values.contains(value);
      case FormConditionOperator.notWithin:
        return !clause.values.contains(value);
      case FormConditionOperator.unspecified:
        return true;
    }
    return true;
  }

  static bool _isEmptyValue(dynamic value) {
    if (value == null) {
      return true;
    }
    if (value is String) {
      return value.trim().isEmpty;
    }
    if (value is List || value is Map) {
      return (value as dynamic).isEmpty;
    }
    return false;
  }

  static num? _toNum(dynamic value) {
    if (value is num) {
      return value;
    }
    return null;
  }

  static bool _isAllowedOption(FormField field, String value) {
    return field.options.any((option) => option.value == value);
  }
}
