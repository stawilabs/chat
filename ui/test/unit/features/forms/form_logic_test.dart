import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/forms/domain/form_logic.dart';
import 'package:stawi/features/forms/domain/form_message_models.dart';

void main() {
  group('FormPermissions', () {
    test('only assigned subscription can edit and submit', () {
      const permissions = FormPermissions(
        canEdit: true,
        canSubmit: true,
        canSaveDraft: true,
        canGoBack: true,
        assigneeSubscriptionId: 'sub-assigned',
      );

      expect(permissions.canEditForSubscription('sub-assigned'), isTrue);
      expect(permissions.canSubmitForSubscription('sub-assigned'), isTrue);
      expect(permissions.canEditForSubscription('sub-other'), isFalse);
      expect(permissions.canSubmitForSubscription(null), isFalse);
    });
  });

  group('FormLogic branching', () {
    final schema = FormSchema.fromJson({
      'formId': 'loan_application',
      'formVersion': 1,
      'title': 'Loan application',
      'steps': [
        {
          'id': 'product',
          'title': 'Product',
          'sections': [
            {
              'id': 'product_section',
              'fields': [
                {
                  'key': 'product_type',
                  'type': 'FORM_FIELD_TYPE_SELECT',
                  'label': 'Product type',
                  'required': true,
                  'options': [
                    {'value': 'loan', 'label': 'Loan'},
                    {'value': 'savings', 'label': 'Savings'},
                  ],
                  'review': {'includeInReview': true},
                },
              ],
            },
          ],
        },
        {
          'id': 'loan_details',
          'title': 'Loan details',
          'visibilityCondition': {
            'all': [
              {
                'fieldKey': 'product_type',
                'operator': 'FORM_CONDITION_OPERATOR_EQUALS',
                'value': 'loan',
              },
            ],
          },
          'sections': [
            {
              'id': 'loan_section',
              'fields': [
                {
                  'key': 'loan_amount',
                  'type': 'FORM_FIELD_TYPE_NUMBER',
                  'label': 'Loan amount',
                  'required': true,
                  'review': {'includeInReview': true},
                },
              ],
            },
          ],
        },
        {
          'id': 'savings_details',
          'title': 'Savings details',
          'visibilityCondition': {
            'all': [
              {
                'fieldKey': 'product_type',
                'operator': 'FORM_CONDITION_OPERATOR_EQUALS',
                'value': 'savings',
              },
            ],
          },
          'sections': [
            {
              'id': 'savings_section',
              'fields': [
                {
                  'key': 'target_amount',
                  'type': 'FORM_FIELD_TYPE_NUMBER',
                  'label': 'Target amount',
                  'required': true,
                  'review': {'includeInReview': true},
                },
              ],
            },
          ],
        },
      ],
    });

    test('visible steps change with selected option', () {
      expect(
        FormLogic.visibleStepIndexes(schema, {'product_type': 'loan'}),
        equals([0, 1]),
      );
      expect(
        FormLogic.visibleStepIndexes(schema, {'product_type': 'savings'}),
        equals([0, 2]),
      );
    });

    test('validation ignores hidden branch steps', () {
      final issues = FormLogic.validateAll(schema, {
        'product_type': 'loan',
        'loan_amount': 2000,
      });

      expect(issues, isEmpty);
    });

    test('review sections only include active branch', () {
      final sections = FormLogic.buildReviewSections(schema, {
        'product_type': 'savings',
        'target_amount': 50000,
      });

      expect(
        sections.map((section) => section.stepId),
        equals(['product', 'savings_details']),
      );
      expect(
        sections.any((section) => section.stepId == 'loan_details'),
        isFalse,
      );
    });
  });
}
