// ignore_for_file: sort_constructors_first, avoid_annotating_with_dynamic

class FormMessageState {
  const FormMessageState._(this.value);

  final String value;

  static const unspecified = FormMessageState._(
    'FORM_MESSAGE_STATE_UNSPECIFIED',
  );
  static const open = FormMessageState._('FORM_MESSAGE_STATE_OPEN');
  static const inReview = FormMessageState._('FORM_MESSAGE_STATE_IN_REVIEW');
  static const submitting = FormMessageState._('FORM_MESSAGE_STATE_SUBMITTING');
  static const submitted = FormMessageState._('FORM_MESSAGE_STATE_SUBMITTED');
  static const failedSubmission = FormMessageState._(
    'FORM_MESSAGE_STATE_FAILED_SUBMISSION',
  );
  static const expired = FormMessageState._('FORM_MESSAGE_STATE_EXPIRED');
  static const cancelled = FormMessageState._('FORM_MESSAGE_STATE_CANCELLED');

  static const values = [
    unspecified,
    open,
    inReview,
    submitting,
    submitted,
    failedSubmission,
    expired,
    cancelled,
  ];

  static FormMessageState fromJsonValue(String? raw) {
    return values.firstWhere(
      (value) => value.value == raw,
      orElse: () => unspecified,
    );
  }

  bool get isTerminal =>
      this == submitted || this == expired || this == cancelled;

  @override
  String toString() => value;
}

class FormFieldType {
  const FormFieldType._(this.value);

  final String value;

  static const unspecified = FormFieldType._('FORM_FIELD_TYPE_UNSPECIFIED');
  static const text = FormFieldType._('FORM_FIELD_TYPE_TEXT');
  static const multiline = FormFieldType._('FORM_FIELD_TYPE_MULTILINE');
  static const number = FormFieldType._('FORM_FIELD_TYPE_NUMBER');
  static const decimal = FormFieldType._('FORM_FIELD_TYPE_DECIMAL');
  static const currency = FormFieldType._('FORM_FIELD_TYPE_CURRENCY');
  static const phone = FormFieldType._('FORM_FIELD_TYPE_PHONE');
  static const email = FormFieldType._('FORM_FIELD_TYPE_EMAIL');
  static const date = FormFieldType._('FORM_FIELD_TYPE_DATE');
  static const datetime = FormFieldType._('FORM_FIELD_TYPE_DATETIME');
  static const select = FormFieldType._('FORM_FIELD_TYPE_SELECT');
  static const radio = FormFieldType._('FORM_FIELD_TYPE_RADIO');
  static const checkboxGroup = FormFieldType._(
    'FORM_FIELD_TYPE_CHECKBOX_GROUP',
  );
  static const boolean = FormFieldType._('FORM_FIELD_TYPE_BOOLEAN');
  static const file = FormFieldType._('FORM_FIELD_TYPE_FILE');
  static const address = FormFieldType._('FORM_FIELD_TYPE_ADDRESS');
  static const repeatableGroup = FormFieldType._(
    'FORM_FIELD_TYPE_REPEATABLE_GROUP',
  );
  static const group = FormFieldType._('FORM_FIELD_TYPE_GROUP');
  static const section = FormFieldType._('FORM_FIELD_TYPE_SECTION');
  static const hidden = FormFieldType._('FORM_FIELD_TYPE_HIDDEN');
  static const computed = FormFieldType._('FORM_FIELD_TYPE_COMPUTED');

  static const values = [
    unspecified,
    text,
    multiline,
    number,
    decimal,
    currency,
    phone,
    email,
    date,
    datetime,
    select,
    radio,
    checkboxGroup,
    boolean,
    file,
    address,
    repeatableGroup,
    group,
    section,
    hidden,
    computed,
  ];

  static FormFieldType fromJsonValue(String? raw) {
    return values.firstWhere(
      (value) => value.value == raw,
      orElse: () => unspecified,
    );
  }

  bool get isTextLike =>
      this == text ||
      this == multiline ||
      this == email ||
      this == phone ||
      this == date ||
      this == datetime;
}

class FormConditionOperator {
  const FormConditionOperator._(this.value);

  final String value;

  static const unspecified = FormConditionOperator._(
    'FORM_CONDITION_OPERATOR_UNSPECIFIED',
  );
  static const equals = FormConditionOperator._(
    'FORM_CONDITION_OPERATOR_EQUALS',
  );
  static const notEquals = FormConditionOperator._(
    'FORM_CONDITION_OPERATOR_NOT_EQUALS',
  );
  static const greaterThan = FormConditionOperator._(
    'FORM_CONDITION_OPERATOR_GREATER_THAN',
  );
  static const greaterThanOrEqual = FormConditionOperator._(
    'FORM_CONDITION_OPERATOR_GREATER_THAN_OR_EQUAL',
  );
  static const lessThan = FormConditionOperator._(
    'FORM_CONDITION_OPERATOR_LESS_THAN',
  );
  static const lessThanOrEqual = FormConditionOperator._(
    'FORM_CONDITION_OPERATOR_LESS_THAN_OR_EQUAL',
  );
  static const within = FormConditionOperator._('FORM_CONDITION_OPERATOR_IN');
  static const notWithin = FormConditionOperator._(
    'FORM_CONDITION_OPERATOR_NOT_IN',
  );
  static const contains = FormConditionOperator._(
    'FORM_CONDITION_OPERATOR_CONTAINS',
  );
  static const notContains = FormConditionOperator._(
    'FORM_CONDITION_OPERATOR_NOT_CONTAINS',
  );
  static const isTrue = FormConditionOperator._(
    'FORM_CONDITION_OPERATOR_IS_TRUE',
  );
  static const isFalse = FormConditionOperator._(
    'FORM_CONDITION_OPERATOR_IS_FALSE',
  );
  static const exists = FormConditionOperator._(
    'FORM_CONDITION_OPERATOR_EXISTS',
  );
  static const notExists = FormConditionOperator._(
    'FORM_CONDITION_OPERATOR_NOT_EXISTS',
  );

  static const values = [
    unspecified,
    equals,
    notEquals,
    greaterThan,
    greaterThanOrEqual,
    lessThan,
    lessThanOrEqual,
    within,
    notWithin,
    contains,
    notContains,
    isTrue,
    isFalse,
    exists,
    notExists,
  ];

  static FormConditionOperator fromJsonValue(String? raw) {
    return values.firstWhere(
      (value) => value.value == raw,
      orElse: () => unspecified,
    );
  }
}

class FormPermissions {
  const FormPermissions({
    required this.canEdit,
    required this.canSubmit,
    required this.canSaveDraft,
    required this.canGoBack,
    required this.assigneeSubscriptionId,
  });

  final bool canEdit;
  final bool canSubmit;
  final bool canSaveDraft;
  final bool canGoBack;
  final String assigneeSubscriptionId;

  bool get hasAssignee => assigneeSubscriptionId.isNotEmpty;

  bool canEditForSubscription(String? subscriptionId) {
    if (!canEdit) {
      return false;
    }
    if (!hasAssignee) {
      return true;
    }
    return subscriptionId != null && subscriptionId == assigneeSubscriptionId;
  }

  bool canSubmitForSubscription(String? subscriptionId) {
    if (!canSubmit) {
      return false;
    }
    if (!hasAssignee) {
      return true;
    }
    return subscriptionId != null && subscriptionId == assigneeSubscriptionId;
  }

  factory FormPermissions.fromJson(Map<String, dynamic>? json) {
    return FormPermissions(
      canEdit: json?['canEdit'] == true,
      canSubmit: json?['canSubmit'] == true,
      canSaveDraft: json?['canSaveDraft'] != false,
      canGoBack: json?['canGoBack'] != false,
      assigneeSubscriptionId: json?['assigneeSubscriptionId'] as String? ?? '',
    );
  }
}

class FormOption {
  const FormOption({
    required this.value,
    required this.label,
    required this.helpText,
    required this.disabled,
  });

  final String value;
  final String label;
  final String helpText;
  final bool disabled;

  factory FormOption.fromJson(Map<String, dynamic> json) {
    return FormOption(
      value: json['value'] as String? ?? '',
      label: json['label'] as String? ?? '',
      helpText: json['helpText'] as String? ?? '',
      disabled: json['disabled'] == true,
    );
  }
}

class FormValidationRule {
  const FormValidationRule({
    required this.code,
    required this.message,
    this.requiredValue,
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.pattern,
    this.minItems,
    this.maxItems,
  });

  final String code;
  final String message;
  final bool? requiredValue;
  final int? minLength;
  final int? maxLength;
  final num? minValue;
  final num? maxValue;
  final String? pattern;
  final int? minItems;
  final int? maxItems;

  factory FormValidationRule.fromJson(Map<String, dynamic> json) {
    return FormValidationRule(
      code: json['code'] as String? ?? '',
      message: json['message'] as String? ?? '',
      requiredValue: json['required'] as bool?,
      minLength: (json['minLength'] as num?)?.toInt(),
      maxLength: (json['maxLength'] as num?)?.toInt(),
      minValue: json['minValue'] as num?,
      maxValue: json['maxValue'] as num?,
      pattern: json['pattern'] as String?,
      minItems: (json['minItems'] as num?)?.toInt(),
      maxItems: (json['maxItems'] as num?)?.toInt(),
    );
  }
}

class FormConditionClause {
  const FormConditionClause({
    required this.fieldKey,
    required this.operator,
    required this.value,
    required this.values,
  });

  final String fieldKey;
  final FormConditionOperator operator;
  final dynamic value;
  final List<dynamic> values;

  factory FormConditionClause.fromJson(Map<String, dynamic> json) {
    final list = json['values'] as List<dynamic>? ?? const [];
    return FormConditionClause(
      fieldKey: json['fieldKey'] as String? ?? '',
      operator: FormConditionOperator.fromJsonValue(
        json['operator'] as String?,
      ),
      value: json['value'],
      values: List<dynamic>.from(list),
    );
  }
}

class FormConditionGroup {
  const FormConditionGroup({required this.all, required this.any});

  final List<FormConditionClause> all;
  final List<FormConditionClause> any;

  factory FormConditionGroup.fromJson(Map<String, dynamic>? json) {
    final all = json?['all'] as List<dynamic>? ?? const [];
    final any = json?['any'] as List<dynamic>? ?? const [];
    return FormConditionGroup(
      all: all
          .map(
            (item) =>
                FormConditionClause.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      any: any
          .map(
            (item) =>
                FormConditionClause.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class FormReviewHint {
  const FormReviewHint({
    required this.includeInReview,
    required this.label,
    required this.sectionLabel,
    required this.formatter,
    required this.order,
  });

  final bool includeInReview;
  final String label;
  final String sectionLabel;
  final String formatter;
  final int order;

  factory FormReviewHint.fromJson(Map<String, dynamic>? json) {
    return FormReviewHint(
      includeInReview: json?['includeInReview'] != false,
      label: json?['label'] as String? ?? '',
      sectionLabel: json?['sectionLabel'] as String? ?? '',
      formatter: json?['formatter'] as String? ?? '',
      order: (json?['order'] as num?)?.toInt() ?? 0,
    );
  }
}

class FormFormattingHint {
  const FormFormattingHint({
    required this.inputMask,
    required this.displayFormat,
    required this.currencyCode,
    required this.decimalScale,
    required this.keyboard,
    required this.autocomplete,
  });

  final String inputMask;
  final String displayFormat;
  final String currencyCode;
  final int? decimalScale;
  final String keyboard;
  final String autocomplete;

  factory FormFormattingHint.fromJson(Map<String, dynamic>? json) {
    return FormFormattingHint(
      inputMask: json?['inputMask'] as String? ?? '',
      displayFormat: json?['displayFormat'] as String? ?? '',
      currencyCode: json?['currencyCode'] as String? ?? '',
      decimalScale: (json?['decimalScale'] as num?)?.toInt(),
      keyboard: json?['keyboard'] as String? ?? '',
      autocomplete: json?['autocomplete'] as String? ?? '',
    );
  }
}

class FormField {
  const FormField({
    required this.key,
    required this.type,
    required this.label,
    required this.helpText,
    required this.placeholder,
    required this.requiredValue,
    required this.defaultValue,
    required this.validationRules,
    required this.visibilityCondition,
    required this.editabilityCondition,
    required this.options,
    required this.nestedFields,
    required this.nestedSections,
    required this.review,
    required this.formatting,
    required this.repeatable,
    required this.hidden,
  });

  final String key;
  final FormFieldType type;
  final String label;
  final String helpText;
  final String placeholder;
  final bool requiredValue;
  final dynamic defaultValue;
  final List<FormValidationRule> validationRules;
  final FormConditionGroup visibilityCondition;
  final FormConditionGroup editabilityCondition;
  final List<FormOption> options;
  final List<FormField> nestedFields;
  final List<FormSection> nestedSections;
  final FormReviewHint review;
  final FormFormattingHint formatting;
  final bool repeatable;
  final bool hidden;

  factory FormField.fromJson(Map<String, dynamic> json) {
    final nestedFields = json['nestedFields'] as List<dynamic>? ?? const [];
    final nestedSections = json['nestedSections'] as List<dynamic>? ?? const [];
    final options = json['options'] as List<dynamic>? ?? const [];
    final validationRules =
        json['validationRules'] as List<dynamic>? ?? const [];
    return FormField(
      key: json['key'] as String? ?? '',
      type: FormFieldType.fromJsonValue(json['type'] as String?),
      label: json['label'] as String? ?? '',
      helpText: json['helpText'] as String? ?? '',
      placeholder: json['placeholder'] as String? ?? '',
      requiredValue: json['required'] == true,
      defaultValue: json['defaultValue'],
      validationRules: validationRules
          .map(
            (item) => FormValidationRule.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      visibilityCondition: FormConditionGroup.fromJson(
        json['visibilityCondition'] as Map<String, dynamic>?,
      ),
      editabilityCondition: FormConditionGroup.fromJson(
        json['editabilityCondition'] as Map<String, dynamic>?,
      ),
      options: options
          .map((item) => FormOption.fromJson(item as Map<String, dynamic>))
          .toList(),
      nestedFields: nestedFields
          .map((item) => FormField.fromJson(item as Map<String, dynamic>))
          .toList(),
      nestedSections: nestedSections
          .map((item) => FormSection.fromJson(item as Map<String, dynamic>))
          .toList(),
      review: FormReviewHint.fromJson(json['review'] as Map<String, dynamic>?),
      formatting: FormFormattingHint.fromJson(
        json['formatting'] as Map<String, dynamic>?,
      ),
      repeatable: json['repeatable'] == true,
      hidden: json['hidden'] == true,
    );
  }
}

class FormSection {
  const FormSection({
    required this.id,
    required this.title,
    required this.description,
    required this.fields,
  });

  final String id;
  final String title;
  final String description;
  final List<FormField> fields;

  factory FormSection.fromJson(Map<String, dynamic> json) {
    final fields = json['fields'] as List<dynamic>? ?? const [];
    return FormSection(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      fields: fields
          .map((item) => FormField.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FormStep {
  const FormStep({
    required this.id,
    required this.title,
    required this.description,
    required this.sections,
    required this.visibilityCondition,
  });

  final String id;
  final String title;
  final String description;
  final List<FormSection> sections;
  final FormConditionGroup visibilityCondition;

  factory FormStep.fromJson(Map<String, dynamic> json) {
    final sections = json['sections'] as List<dynamic>? ?? const [];
    return FormStep(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      sections: sections
          .map((item) => FormSection.fromJson(item as Map<String, dynamic>))
          .toList(),
      visibilityCondition: FormConditionGroup.fromJson(
        json['visibilityCondition'] as Map<String, dynamic>?,
      ),
    );
  }
}

class FormSchema {
  const FormSchema({
    required this.formId,
    required this.formVersion,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.steps,
  });

  final String formId;
  final int formVersion;
  final String title;
  final String subtitle;
  final String description;
  final List<FormStep> steps;

  factory FormSchema.fromJson(Map<String, dynamic> json) {
    final steps = json['steps'] as List<dynamic>? ?? const [];
    return FormSchema(
      formId: json['formId'] as String? ?? '',
      formVersion: (json['formVersion'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
      steps: steps
          .map((item) => FormStep.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FormReviewItem {
  const FormReviewItem({
    required this.fieldKey,
    required this.label,
    required this.displayValue,
    required this.emphasized,
  });

  final String fieldKey;
  final String label;
  final String displayValue;
  final bool emphasized;

  factory FormReviewItem.fromJson(Map<String, dynamic> json) {
    return FormReviewItem(
      fieldKey: json['fieldKey'] as String? ?? '',
      label: json['label'] as String? ?? '',
      displayValue: json['displayValue'] as String? ?? '',
      emphasized: json['emphasized'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'fieldKey': fieldKey,
    'label': label,
    'displayValue': displayValue,
    'emphasized': emphasized,
  };
}

class FormReviewSectionModel {
  const FormReviewSectionModel({
    required this.stepId,
    required this.stepTitle,
    required this.sectionId,
    required this.sectionTitle,
    required this.items,
  });

  final String stepId;
  final String stepTitle;
  final String sectionId;
  final String sectionTitle;
  final List<FormReviewItem> items;

  factory FormReviewSectionModel.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? const [];
    return FormReviewSectionModel(
      stepId: json['stepId'] as String? ?? '',
      stepTitle: json['stepTitle'] as String? ?? '',
      sectionId: json['sectionId'] as String? ?? '',
      sectionTitle: json['sectionTitle'] as String? ?? '',
      items: items
          .map((item) => FormReviewItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'stepId': stepId,
    'stepTitle': stepTitle,
    'sectionId': sectionId,
    'sectionTitle': sectionTitle,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

class FormSubmissionSnapshotModel {
  const FormSubmissionSnapshotModel({
    required this.formInstanceId,
    required this.schemaId,
    required this.schemaVersion,
    required this.answers,
    required this.formattedSections,
    required this.submittedBySubscriptionId,
    required this.status,
    this.submissionReference,
    this.backendMessage,
    this.workflowMessage,
    this.submittedAt,
  });

  final String formInstanceId;
  final String schemaId;
  final int schemaVersion;
  final Map<String, dynamic> answers;
  final List<FormReviewSectionModel> formattedSections;
  final String submittedBySubscriptionId;
  final FormMessageState status;
  final String? submissionReference;
  final String? backendMessage;
  final String? workflowMessage;
  final DateTime? submittedAt;

  factory FormSubmissionSnapshotModel.fromJson(Map<String, dynamic> json) {
    final sections = json['formattedSections'] as List<dynamic>? ?? const [];
    return FormSubmissionSnapshotModel(
      formInstanceId: json['formInstanceId'] as String? ?? '',
      schemaId: json['schemaId'] as String? ?? '',
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 0,
      answers: Map<String, dynamic>.from(
        json['answers'] as Map? ?? const <String, dynamic>{},
      ),
      formattedSections: sections
          .map(
            (item) =>
                FormReviewSectionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      submittedBySubscriptionId:
          json['submittedBySubscriptionId'] as String? ?? '',
      status: FormMessageState.fromJsonValue(json['status'] as String?),
      submissionReference: json['submissionReference'] as String?,
      backendMessage: json['backendMessage'] as String?,
      workflowMessage: json['workflowMessage'] as String?,
      submittedAt: _parseDateTime(json['submittedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'formInstanceId': formInstanceId,
    'schemaId': schemaId,
    'schemaVersion': schemaVersion,
    'answers': answers,
    'formattedSections': formattedSections
        .map((section) => section.toJson())
        .toList(),
    'submittedBySubscriptionId': submittedBySubscriptionId,
    'status': status.value,
    if (submissionReference != null) 'submissionReference': submissionReference,
    if (backendMessage != null) 'backendMessage': backendMessage,
    if (workflowMessage != null) 'workflowMessage': workflowMessage,
    if (submittedAt != null) 'submittedAt': submittedAt!.toIso8601String(),
  };
}

class FormRequestMessageModel {
  const FormRequestMessageModel({
    required this.formInstanceId,
    required this.schemaId,
    required this.schemaVersion,
    required this.title,
    required this.description,
    required this.state,
    required this.reviewRequired,
    required this.schema,
    required this.initialValues,
    required this.serverDraftValues,
    required this.finalSubmissionSnapshot,
    required this.permissions,
    required this.currentWorkflowState,
    this.expiresAt,
  });

  final String formInstanceId;
  final String schemaId;
  final int schemaVersion;
  final String title;
  final String description;
  final FormMessageState state;
  final bool reviewRequired;
  final FormSchema schema;
  final Map<String, dynamic> initialValues;
  final Map<String, dynamic> serverDraftValues;
  final FormSubmissionSnapshotModel? finalSubmissionSnapshot;
  final FormPermissions permissions;
  final String currentWorkflowState;
  final DateTime? expiresAt;

  factory FormRequestMessageModel.fromContent(Map<String, dynamic> json) {
    return FormRequestMessageModel(
      formInstanceId: json['formInstanceId'] as String? ?? '',
      schemaId: json['schemaId'] as String? ?? '',
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      state: FormMessageState.fromJsonValue(json['state'] as String?),
      reviewRequired: json['reviewRequired'] != false,
      schema: FormSchema.fromJson(
        Map<String, dynamic>.from(
          json['schema'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      initialValues: Map<String, dynamic>.from(
        json['initialValues'] as Map? ?? const <String, dynamic>{},
      ),
      serverDraftValues: Map<String, dynamic>.from(
        json['serverDraftValues'] as Map? ?? const <String, dynamic>{},
      ),
      finalSubmissionSnapshot: json['finalSubmissionSnapshot'] == null
          ? null
          : FormSubmissionSnapshotModel.fromJson(
              Map<String, dynamic>.from(json['finalSubmissionSnapshot'] as Map),
            ),
      permissions: FormPermissions.fromJson(
        json['permissions'] as Map<String, dynamic>?,
      ),
      currentWorkflowState: json['currentWorkflowState'] as String? ?? '',
      expiresAt: _parseDateTime(json['expiresAt']),
    );
  }
}

class FormSubmissionResultMessageModel {
  const FormSubmissionResultMessageModel({
    required this.formInstanceId,
    required this.schemaId,
    required this.schemaVersion,
    required this.sourceEventId,
    required this.state,
    required this.reviewConfirmed,
    required this.submissionSnapshot,
  });

  final String formInstanceId;
  final String schemaId;
  final int schemaVersion;
  final String sourceEventId;
  final FormMessageState state;
  final bool reviewConfirmed;
  final FormSubmissionSnapshotModel submissionSnapshot;

  factory FormSubmissionResultMessageModel.fromContent(
    Map<String, dynamic> json,
  ) {
    return FormSubmissionResultMessageModel(
      formInstanceId: json['formInstanceId'] as String? ?? '',
      schemaId: json['schemaId'] as String? ?? '',
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 0,
      sourceEventId: json['sourceEventId'] as String? ?? '',
      state: FormMessageState.fromJsonValue(json['state'] as String?),
      reviewConfirmed: json['reviewConfirmed'] == true,
      submissionSnapshot: FormSubmissionSnapshotModel.fromJson(
        Map<String, dynamic>.from(
          json['submissionSnapshot'] as Map? ?? const <String, dynamic>{},
        ),
      ),
    );
  }

  Map<String, dynamic> toContent() => {
    'formInstanceId': formInstanceId,
    'schemaId': schemaId,
    'schemaVersion': schemaVersion,
    'sourceEventId': sourceEventId,
    'state': state.value,
    'reviewConfirmed': reviewConfirmed,
    'submissionSnapshot': submissionSnapshot.toJson(),
  };
}

DateTime? _parseDateTime(dynamic raw) {
  if (raw is! String || raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw);
}
