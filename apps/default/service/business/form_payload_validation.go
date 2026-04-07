package business

import (
	"context"
	"errors"
	"fmt"
	"math"
	"regexp"
	"strings"

	chatv1 "buf.build/gen/go/antinvestor/chat/protocolbuffers/go/chat/v1"
	"connectrpc.com/connect"
	"google.golang.org/protobuf/types/known/structpb"
	"google.golang.org/protobuf/types/known/timestamppb"
)

const floatComparisonTolerance = 1e-9

func (mb *messageBusiness) prepareFormPayload(
	ctx context.Context,
	reqEvt *chatv1.RoomEvent,
	roomID string,
	subscriptionID string,
) error {
	if reqEvt.GetPayload() == nil {
		return nil
	}

	//nolint:exhaustive // Only form payloads need special preprocessing.
	switch reqEvt.GetPayload().GetType() {
	case chatv1.PayloadType_PAYLOAD_TYPE_FORM_REQUEST:
		return mb.validateFormRequestPayload(reqEvt)
	case chatv1.PayloadType_PAYLOAD_TYPE_FORM_SUBMISSION_RESULT:
		return mb.validateAndNormalizeFormSubmissionPayload(
			ctx,
			reqEvt,
			roomID,
			subscriptionID,
		)
	default:
		return nil
	}
}

func (mb *messageBusiness) validateFormRequestPayload(
	reqEvt *chatv1.RoomEvent,
) error {
	if reqEvt.GetType() != chatv1.RoomEventType_ROOM_EVENT_TYPE_FORM_REQUEST {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("form request event type must be ROOM_EVENT_TYPE_FORM_REQUEST"),
		)
	}

	content := reqEvt.GetPayload().GetFormRequest()
	if content == nil {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("form request payload is required"),
		)
	}

	if content.GetFormInstanceId() == "" {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("form_instance_id is required"),
		)
	}
	if content.GetSchemaId() == "" {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("schema_id is required"),
		)
	}
	if content.GetSchemaVersion() <= 0 {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("schema_version must be positive"),
		)
	}

	content.ReviewRequired = true
	if content.GetState() == chatv1.FormMessageState_FORM_MESSAGE_STATE_UNSPECIFIED {
		content.State = chatv1.FormMessageState_FORM_MESSAGE_STATE_OPEN
	}

	schema := content.GetSchema()
	if schema == nil || len(schema.GetSteps()) == 0 {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("form request schema must include at least one step"),
		)
	}
	if schema.GetFormId() == "" {
		schema.FormId = content.GetSchemaId()
	}
	if schema.GetFormVersion() <= 0 {
		schema.FormVersion = content.GetSchemaVersion()
	}

	return validateFormSchema(schema)
}

//nolint:gocognit,funlen // Submission normalization intentionally centralizes the full guard chain.
func (mb *messageBusiness) validateAndNormalizeFormSubmissionPayload(
	ctx context.Context,
	reqEvt *chatv1.RoomEvent,
	roomID string,
	subscriptionID string,
) error {
	if reqEvt.GetType() != chatv1.RoomEventType_ROOM_EVENT_TYPE_FORM_SUBMISSION_RESULT {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New(
				"form submission result event type must be ROOM_EVENT_TYPE_FORM_SUBMISSION_RESULT",
			),
		)
	}
	if reqEvt.GetParentId() == "" {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("form submission result requires parent_id"),
		)
	}

	content := reqEvt.GetPayload().GetFormSubmissionResult()
	if content == nil {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("form submission result payload is required"),
		)
	}
	if !content.GetReviewConfirmed() {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("review_confirmed must be true before submission"),
		)
	}

	parentEvent, err := mb.eventRepo.GetByEventID(ctx, roomID, reqEvt.GetParentId())
	if err != nil {
		return connect.NewError(
			connect.CodeInvalidArgument,
			fmt.Errorf("parent form request not found: %w", err),
		)
	}

	parentPayload, err := mb.payloadConverter.ToProto(parentEvent.Content)
	if err != nil {
		return connect.NewError(
			connect.CodeInternal,
			fmt.Errorf("failed to load parent form request: %w", err),
		)
	}
	parentForm := parentPayload.GetFormRequest()
	if parentPayload.GetType() != chatv1.PayloadType_PAYLOAD_TYPE_FORM_REQUEST ||
		parentForm == nil {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("parent event is not a form request"),
		)
	}

	if parentForm.GetState() == chatv1.FormMessageState_FORM_MESSAGE_STATE_EXPIRED ||
		parentForm.GetState() == chatv1.FormMessageState_FORM_MESSAGE_STATE_CANCELLED {
		return connect.NewError(
			connect.CodeFailedPrecondition,
			errors.New("form is no longer active"),
		)
	}
	if assigneeID := parentForm.GetPermissions().GetAssigneeSubscriptionId(); assigneeID != "" &&
		assigneeID != subscriptionID {
		return connect.NewError(
			connect.CodePermissionDenied,
			errors.New("only the assigned subscription may submit this form"),
		)
	}
	existingSubmission, err := mb.hasExistingFormSubmissionForSender(
		ctx,
		roomID,
		reqEvt.GetParentId(),
		subscriptionID,
	)
	if err != nil {
		return connect.NewError(
			connect.CodeInternal,
			fmt.Errorf("failed checking existing form submissions: %w", err),
		)
	}
	if existingSubmission {
		return connect.NewError(
			connect.CodeAlreadyExists,
			errors.New("this subscription has already submitted this form"),
		)
	}

	if content.GetSourceEventId() == "" {
		content.SourceEventId = reqEvt.GetParentId()
	}
	if content.GetFormInstanceId() == "" {
		content.FormInstanceId = parentForm.GetFormInstanceId()
	}
	if content.GetSchemaId() == "" {
		content.SchemaId = parentForm.GetSchemaId()
	}
	if content.GetSchemaVersion() <= 0 {
		content.SchemaVersion = parentForm.GetSchemaVersion()
	}
	if content.GetState() == chatv1.FormMessageState_FORM_MESSAGE_STATE_UNSPECIFIED {
		content.State = chatv1.FormMessageState_FORM_MESSAGE_STATE_SUBMITTED
	}

	if content.GetFormInstanceId() != parentForm.GetFormInstanceId() ||
		content.GetSchemaId() != parentForm.GetSchemaId() ||
		content.GetSchemaVersion() != parentForm.GetSchemaVersion() {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("form submission does not match parent form schema"),
		)
	}

	snapshot := content.GetSubmissionSnapshot()
	if snapshot == nil {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("submission_snapshot is required"),
		)
	}
	if snapshot.GetAnswers() == nil {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("submission answers are required"),
		)
	}

	snapshot.FormInstanceId = parentForm.GetFormInstanceId()
	snapshot.SchemaId = parentForm.GetSchemaId()
	snapshot.SchemaVersion = parentForm.GetSchemaVersion()
	snapshot.SubmittedBySubscriptionId = subscriptionID
	snapshot.Status = chatv1.FormMessageState_FORM_MESSAGE_STATE_SUBMITTED
	if snapshot.GetSubmittedAt() == nil {
		snapshot.SubmittedAt = timestamppb.Now()
	}

	if validateErr := validateFormAnswers(
		parentForm.GetSchema(),
		snapshot.GetAnswers().AsMap(),
	); validateErr != nil {
		return validateErr
	}

	return nil
}

func (mb *messageBusiness) hasExistingFormSubmissionForSender(
	ctx context.Context,
	roomID string,
	parentID string,
	subscriptionID string,
) (bool, error) {
	const pageSize = 200

	beforeEventID := ""
	for {
		events, err := mb.eventRepo.GetHistory(
			ctx,
			roomID,
			beforeEventID,
			"",
			pageSize,
		)
		if err != nil {
			return false, err
		}
		if len(events) == 0 {
			return false, nil
		}

		for _, event := range events {
			if event.ParentID == parentID &&
				event.SenderID == subscriptionID &&
				event.EventType ==
					int32(chatv1.RoomEventType_ROOM_EVENT_TYPE_FORM_SUBMISSION_RESULT) {
				return true, nil
			}
		}

		if len(events) < pageSize {
			return false, nil
		}
		beforeEventID = events[len(events)-1].GetID()
	}
}

func validateFormSchema(schema *chatv1.FormSchema) error {
	if schema == nil {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("form schema is required"),
		)
	}
	if schema.GetFormId() == "" {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("form schema id is required"),
		)
	}
	if schema.GetFormVersion() <= 0 {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("form schema version must be positive"),
		)
	}
	if len(schema.GetSteps()) == 0 {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("form schema must define at least one step"),
		)
	}

	seenKeys := map[string]struct{}{}
	for _, step := range schema.GetSteps() {
		if step.GetId() == "" {
			return connect.NewError(
				connect.CodeInvalidArgument,
				errors.New("each form step requires an id"),
			)
		}
		for _, section := range step.GetSections() {
			if err := validateFormSection(section, seenKeys); err != nil {
				return err
			}
		}
	}

	return nil
}

func validateFormSection(
	section *chatv1.FormSection,
	seenKeys map[string]struct{},
) error {
	if section == nil {
		return nil
	}
	if section.GetId() == "" {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("each form section requires an id"),
		)
	}
	for _, field := range section.GetFields() {
		if err := validateFormField(field, seenKeys); err != nil {
			return err
		}
	}
	return nil
}

func validateFormField(
	field *chatv1.FormField,
	seenKeys map[string]struct{},
) error {
	if field == nil {
		return nil
	}
	if field.GetKey() == "" {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("form field key is required"),
		)
	}
	if _, exists := seenKeys[field.GetKey()]; exists {
		return connect.NewError(
			connect.CodeInvalidArgument,
			fmt.Errorf("duplicate form field key %q", field.GetKey()),
		)
	}
	seenKeys[field.GetKey()] = struct{}{}

	for _, nestedField := range field.GetNestedFields() {
		if err := validateFormField(nestedField, seenKeys); err != nil {
			return err
		}
	}
	for _, nestedSection := range field.GetNestedSections() {
		if err := validateFormSection(nestedSection, seenKeys); err != nil {
			return err
		}
	}

	return nil
}

func validateFormAnswers(
	schema *chatv1.FormSchema,
	answers map[string]any,
) error {
	if schema == nil {
		return connect.NewError(
			connect.CodeInvalidArgument,
			errors.New("submission schema is required"),
		)
	}

	for _, step := range schema.GetSteps() {
		if !matchesCondition(step.GetVisibilityCondition(), answers) {
			continue
		}
		for _, section := range step.GetSections() {
			for _, field := range section.GetFields() {
				if err := validateAnswerForField(field, answers, answers); err != nil {
					return err
				}
			}
		}
	}

	return nil
}

//nolint:gocognit // The validator dispatches on schema field kinds in one place.
func validateAnswerForField(
	field *chatv1.FormField,
	currentScope map[string]any,
	rootAnswers map[string]any,
) error {
	if field == nil {
		return nil
	}
	if field.GetHidden() || !matchesCondition(field.GetVisibilityCondition(), rootAnswers) {
		return nil
	}

	value, hasValue := currentScope[field.GetKey()]
	isRequired := field.GetRequired() || hasRequiredRule(field.GetValidationRules())
	if !hasValue || isEmptyValue(value) {
		if isRequired {
			return connect.NewError(
				connect.CodeInvalidArgument,
				fmt.Errorf("missing required form field %q", field.GetKey()),
			)
		}
		return nil
	}

	//nolint:exhaustive // Container fields have bespoke traversal; everything else falls through to scalar validation.
	switch field.GetType() {
	case chatv1.FormFieldType_FORM_FIELD_TYPE_GROUP,
		chatv1.FormFieldType_FORM_FIELD_TYPE_SECTION:
		childMap, ok := value.(map[string]any)
		if !ok {
			return connect.NewError(
				connect.CodeInvalidArgument,
				fmt.Errorf("field %q must be an object", field.GetKey()),
			)
		}
		for _, nestedField := range field.GetNestedFields() {
			if err := validateAnswerForField(nestedField, childMap, rootAnswers); err != nil {
				return err
			}
		}
		for _, nestedSection := range field.GetNestedSections() {
			for _, nestedField := range nestedSection.GetFields() {
				if err := validateAnswerForField(nestedField, childMap, rootAnswers); err != nil {
					return err
				}
			}
		}
		return nil
	case chatv1.FormFieldType_FORM_FIELD_TYPE_REPEATABLE_GROUP:
		items, ok := value.([]any)
		if !ok {
			return connect.NewError(
				connect.CodeInvalidArgument,
				fmt.Errorf("field %q must be a list", field.GetKey()),
			)
		}
		for _, item := range items {
			itemMap, itemOK := item.(map[string]any)
			if !itemOK {
				return connect.NewError(
					connect.CodeInvalidArgument,
					fmt.Errorf("repeatable group %q items must be objects", field.GetKey()),
				)
			}
			for _, nestedField := range field.GetNestedFields() {
				if err := validateAnswerForField(nestedField, itemMap, rootAnswers); err != nil {
					return err
				}
			}
			for _, nestedSection := range field.GetNestedSections() {
				for _, nestedField := range nestedSection.GetFields() {
					if err := validateAnswerForField(nestedField, itemMap, rootAnswers); err != nil {
						return err
					}
				}
			}
		}
	default:
		if err := validateScalarField(field, value); err != nil {
			return err
		}
	}

	return nil
}

//nolint:gocognit,exhaustive // Scalar field validation intentionally handles only concrete leaf inputs.
func validateScalarField(field *chatv1.FormField, value any) error {
	switch field.GetType() {
	case chatv1.FormFieldType_FORM_FIELD_TYPE_NUMBER:
		if _, ok := toFloat(value); !ok {
			return invalidFieldError(field.GetKey(), "must be numeric")
		}
	case chatv1.FormFieldType_FORM_FIELD_TYPE_DECIMAL,
		chatv1.FormFieldType_FORM_FIELD_TYPE_CURRENCY:
		if _, ok := toFloat(value); !ok {
			return invalidFieldError(field.GetKey(), "must be a decimal number")
		}
	case chatv1.FormFieldType_FORM_FIELD_TYPE_BOOLEAN:
		if _, ok := value.(bool); !ok {
			return invalidFieldError(field.GetKey(), "must be true or false")
		}
	case chatv1.FormFieldType_FORM_FIELD_TYPE_SELECT,
		chatv1.FormFieldType_FORM_FIELD_TYPE_RADIO:
		selected, ok := value.(string)
		if !ok {
			return invalidFieldError(field.GetKey(), "must be a string option value")
		}
		if !isAllowedOption(selected, field.GetOptions()) {
			return invalidFieldError(field.GetKey(), "must match one of the declared options")
		}
	case chatv1.FormFieldType_FORM_FIELD_TYPE_CHECKBOX_GROUP:
		values, ok := value.([]any)
		if !ok {
			return invalidFieldError(field.GetKey(), "must be a list of option values")
		}
		for _, item := range values {
			selectedValue, itemOK := item.(string)
			if !itemOK || !isAllowedOption(selectedValue, field.GetOptions()) {
				return invalidFieldError(field.GetKey(), "contains an invalid option")
			}
		}
	case chatv1.FormFieldType_FORM_FIELD_TYPE_EMAIL,
		chatv1.FormFieldType_FORM_FIELD_TYPE_PHONE,
		chatv1.FormFieldType_FORM_FIELD_TYPE_TEXT,
		chatv1.FormFieldType_FORM_FIELD_TYPE_MULTILINE,
		chatv1.FormFieldType_FORM_FIELD_TYPE_DATE,
		chatv1.FormFieldType_FORM_FIELD_TYPE_DATETIME:
		if _, ok := value.(string); !ok {
			return invalidFieldError(field.GetKey(), "must be a string")
		}
	}

	for _, rule := range field.GetValidationRules() {
		if err := validateRule(field.GetKey(), rule, value); err != nil {
			return err
		}
	}

	return nil
}

//nolint:gocognit // Validation rules are intentionally dispatched in one switch.
func validateRule(
	fieldKey string,
	rule *chatv1.FormValidationRule,
	value any,
) error {
	if rule == nil {
		return nil
	}
	message := rule.GetMessage()
	if message == "" {
		message = "failed validation"
	}

	switch typedRule := rule.GetRule().(type) {
	case *chatv1.FormValidationRule_MinLength:
		if str, ok := value.(string); ok && len(strings.TrimSpace(str)) < int(typedRule.MinLength) {
			return invalidFieldError(fieldKey, message)
		}
	case *chatv1.FormValidationRule_MaxLength:
		if str, ok := value.(string); ok && len(str) > int(typedRule.MaxLength) {
			return invalidFieldError(fieldKey, message)
		}
	case *chatv1.FormValidationRule_MinValue:
		if num, ok := toFloat(value); ok && num < typedRule.MinValue {
			return invalidFieldError(fieldKey, message)
		}
	case *chatv1.FormValidationRule_MaxValue:
		if num, ok := toFloat(value); ok && num > typedRule.MaxValue {
			return invalidFieldError(fieldKey, message)
		}
	case *chatv1.FormValidationRule_Pattern:
		if str, ok := value.(string); ok {
			matched, err := regexp.MatchString(typedRule.Pattern, str)
			if err != nil || !matched {
				return invalidFieldError(fieldKey, message)
			}
		}
	case *chatv1.FormValidationRule_MinItems:
		if list, ok := value.([]any); ok && len(list) < int(typedRule.MinItems) {
			return invalidFieldError(fieldKey, message)
		}
	case *chatv1.FormValidationRule_MaxItems:
		if list, ok := value.([]any); ok && len(list) > int(typedRule.MaxItems) {
			return invalidFieldError(fieldKey, message)
		}
	}

	return nil
}

func matchesCondition(
	group *chatv1.FormConditionGroup,
	answers map[string]any,
) bool {
	if group == nil {
		return true
	}
	if len(group.GetAll()) > 0 {
		for _, clause := range group.GetAll() {
			if !matchesClause(clause, answers) {
				return false
			}
		}
	}
	if len(group.GetAny()) > 0 {
		matchedAny := false
		for _, clause := range group.GetAny() {
			if matchesClause(clause, answers) {
				matchedAny = true
				break
			}
		}
		if !matchedAny {
			return false
		}
	}
	return true
}

func matchesClause(
	clause *chatv1.FormConditionClause,
	answers map[string]any,
) bool {
	if clause == nil {
		return true
	}
	value, exists := answers[clause.GetFieldKey()]

	//nolint:exhaustive // Presence and boolean operators short-circuit before value comparison.
	switch clause.GetOperator() {
	case chatv1.FormConditionOperator_FORM_CONDITION_OPERATOR_EXISTS:
		return exists && !isEmptyValue(value)
	case chatv1.FormConditionOperator_FORM_CONDITION_OPERATOR_NOT_EXISTS:
		return !exists || isEmptyValue(value)
	case chatv1.FormConditionOperator_FORM_CONDITION_OPERATOR_IS_TRUE:
		boolValue, ok := value.(bool)
		return ok && boolValue
	case chatv1.FormConditionOperator_FORM_CONDITION_OPERATOR_IS_FALSE:
		boolValue, ok := value.(bool)
		return ok && !boolValue
	}

	expected := any(nil)
	if clause.GetValue() != nil {
		expected = clause.GetValue().AsInterface()
	}

	//nolint:exhaustive // Comparison operators are the only ones that depend on expected values.
	switch clause.GetOperator() {
	case chatv1.FormConditionOperator_FORM_CONDITION_OPERATOR_EQUALS:
		return compareValues(value, expected) == 0
	case chatv1.FormConditionOperator_FORM_CONDITION_OPERATOR_NOT_EQUALS:
		return compareValues(value, expected) != 0
	case chatv1.FormConditionOperator_FORM_CONDITION_OPERATOR_GREATER_THAN:
		return compareValues(value, expected) > 0
	case chatv1.FormConditionOperator_FORM_CONDITION_OPERATOR_GREATER_THAN_OR_EQUAL:
		return compareValues(value, expected) >= 0
	case chatv1.FormConditionOperator_FORM_CONDITION_OPERATOR_LESS_THAN:
		return compareValues(value, expected) < 0
	case chatv1.FormConditionOperator_FORM_CONDITION_OPERATOR_LESS_THAN_OR_EQUAL:
		return compareValues(value, expected) <= 0
	case chatv1.FormConditionOperator_FORM_CONDITION_OPERATOR_CONTAINS:
		return containsValue(value, expected)
	case chatv1.FormConditionOperator_FORM_CONDITION_OPERATOR_NOT_CONTAINS:
		return !containsValue(value, expected)
	case chatv1.FormConditionOperator_FORM_CONDITION_OPERATOR_IN:
		return listContains(clause.GetValues(), value)
	case chatv1.FormConditionOperator_FORM_CONDITION_OPERATOR_NOT_IN:
		return !listContains(clause.GetValues(), value)
	default:
		return true
	}
}

func hasRequiredRule(rules []*chatv1.FormValidationRule) bool {
	for _, rule := range rules {
		if requiredRule, ok := rule.GetRule().(*chatv1.FormValidationRule_Required); ok &&
			requiredRule.Required {
			return true
		}
	}
	return false
}

func isAllowedOption(value string, options []*chatv1.FormOption) bool {
	for _, option := range options {
		if option.GetValue() == value {
			return true
		}
	}
	return false
}

func isEmptyValue(value any) bool {
	switch typed := value.(type) {
	case nil:
		return true
	case string:
		return strings.TrimSpace(typed) == ""
	case []any:
		return len(typed) == 0
	case map[string]any:
		return len(typed) == 0
	default:
		return false
	}
}

func toFloat(value any) (float64, bool) {
	switch typed := value.(type) {
	case float64:
		return typed, true
	case float32:
		return float64(typed), true
	case int:
		return float64(typed), true
	case int32:
		return float64(typed), true
	case int64:
		return float64(typed), true
	default:
		return 0, false
	}
}

func containsValue(value any, expected any) bool {
	switch typed := value.(type) {
	case []any:
		for _, item := range typed {
			if compareValues(item, expected) == 0 {
				return true
			}
		}
		return false
	case string:
		expectedString, ok := expected.(string)
		return ok && strings.Contains(typed, expectedString)
	default:
		return false
	}
}

func listContains(list []*structpb.Value, target any) bool {
	for _, value := range list {
		if compareValues(value.AsInterface(), target) == 0 {
			return true
		}
	}
	return false
}

func compareValues(left any, right any) int {
	if leftFloat, ok := toFloat(left); ok {
		if rightFloat, rightOK := toFloat(right); rightOK {
			switch {
			case math.Abs(leftFloat-rightFloat) < floatComparisonTolerance:
				return 0
			case leftFloat < rightFloat:
				return -1
			default:
				return 1
			}
		}
	}

	leftString := fmt.Sprint(left)
	rightString := fmt.Sprint(right)
	switch {
	case leftString == rightString:
		return 0
	case leftString < rightString:
		return -1
	default:
		return 1
	}
}

func invalidFieldError(fieldKey string, message string) error {
	return connect.NewError(
		connect.CodeInvalidArgument,
		fmt.Errorf("field %q %s", fieldKey, message),
	)
}
