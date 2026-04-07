//
//  Generated code. Do not modify.
//  source: chat/v1/payload_type.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Allowed message types. Extendable via new enum values; clients must ignore unknown values.
class PayloadType extends $pb.ProtobufEnum {
  static const PayloadType PAYLOAD_TYPE_UNSPECIFIED = PayloadType._(0, _omitEnumNames ? '' : 'PAYLOAD_TYPE_UNSPECIFIED');
  static const PayloadType PAYLOAD_TYPE_ROOM_CHANGE = PayloadType._(1, _omitEnumNames ? '' : 'PAYLOAD_TYPE_ROOM_CHANGE');
  static const PayloadType PAYLOAD_TYPE_TEXT = PayloadType._(2, _omitEnumNames ? '' : 'PAYLOAD_TYPE_TEXT');
  static const PayloadType PAYLOAD_TYPE_ATTACHMENT = PayloadType._(3, _omitEnumNames ? '' : 'PAYLOAD_TYPE_ATTACHMENT');
  static const PayloadType PAYLOAD_TYPE_REACTION = PayloadType._(7, _omitEnumNames ? '' : 'PAYLOAD_TYPE_REACTION');
  static const PayloadType PAYLOAD_TYPE_ENCRYPTED = PayloadType._(6, _omitEnumNames ? '' : 'PAYLOAD_TYPE_ENCRYPTED');
  static const PayloadType PAYLOAD_TYPE_CALL = PayloadType._(20, _omitEnumNames ? '' : 'PAYLOAD_TYPE_CALL');
  static const PayloadType PAYLOAD_TYPE_MODERATION = PayloadType._(21, _omitEnumNames ? '' : 'PAYLOAD_TYPE_MODERATION');
  static const PayloadType PAYLOAD_TYPE_MOTION = PayloadType._(22, _omitEnumNames ? '' : 'PAYLOAD_TYPE_MOTION');
  static const PayloadType PAYLOAD_TYPE_VOTE = PayloadType._(23, _omitEnumNames ? '' : 'PAYLOAD_TYPE_VOTE');
  static const PayloadType PAYLOAD_TYPE_MOTION_TALLY = PayloadType._(24, _omitEnumNames ? '' : 'PAYLOAD_TYPE_MOTION_TALLY');
  static const PayloadType PAYLOAD_TYPE_VOTE_TALLY = PayloadType._(25, _omitEnumNames ? '' : 'PAYLOAD_TYPE_VOTE_TALLY');
  static const PayloadType PAYLOAD_TYPE_FORM_REQUEST = PayloadType._(30, _omitEnumNames ? '' : 'PAYLOAD_TYPE_FORM_REQUEST');
  static const PayloadType PAYLOAD_TYPE_FORM_SUBMISSION_RESULT = PayloadType._(31, _omitEnumNames ? '' : 'PAYLOAD_TYPE_FORM_SUBMISSION_RESULT');

  static const $core.List<PayloadType> values = <PayloadType> [
    PAYLOAD_TYPE_UNSPECIFIED,
    PAYLOAD_TYPE_ROOM_CHANGE,
    PAYLOAD_TYPE_TEXT,
    PAYLOAD_TYPE_ATTACHMENT,
    PAYLOAD_TYPE_REACTION,
    PAYLOAD_TYPE_ENCRYPTED,
    PAYLOAD_TYPE_CALL,
    PAYLOAD_TYPE_MODERATION,
    PAYLOAD_TYPE_MOTION,
    PAYLOAD_TYPE_VOTE,
    PAYLOAD_TYPE_MOTION_TALLY,
    PAYLOAD_TYPE_VOTE_TALLY,
    PAYLOAD_TYPE_FORM_REQUEST,
    PAYLOAD_TYPE_FORM_SUBMISSION_RESULT,
  ];

  static final $core.Map<$core.int, PayloadType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static PayloadType? valueOf($core.int value) => _byValue[value];

  const PayloadType._($core.int v, $core.String n) : super(v, n);
}

class RoomChangeAction extends $pb.ProtobufEnum {
  static const RoomChangeAction ROOM_CHANGE_ACTION_UNSPECIFIED = RoomChangeAction._(0, _omitEnumNames ? '' : 'ROOM_CHANGE_ACTION_UNSPECIFIED');
  static const RoomChangeAction ROOM_CHANGE_ACTION_CREATED = RoomChangeAction._(1, _omitEnumNames ? '' : 'ROOM_CHANGE_ACTION_CREATED');
  static const RoomChangeAction ROOM_CHANGE_ACTION_UPDATED = RoomChangeAction._(2, _omitEnumNames ? '' : 'ROOM_CHANGE_ACTION_UPDATED');
  static const RoomChangeAction ROOM_CHANGE_ACTION_DELETED = RoomChangeAction._(3, _omitEnumNames ? '' : 'ROOM_CHANGE_ACTION_DELETED');
  static const RoomChangeAction ROOM_CHANGE_ACTION_MEMBER_ADDED = RoomChangeAction._(4, _omitEnumNames ? '' : 'ROOM_CHANGE_ACTION_MEMBER_ADDED');
  static const RoomChangeAction ROOM_CHANGE_ACTION_MEMBER_REMOVED = RoomChangeAction._(5, _omitEnumNames ? '' : 'ROOM_CHANGE_ACTION_MEMBER_REMOVED');
  static const RoomChangeAction ROOM_CHANGE_ACTION_ROLE_CHANGED = RoomChangeAction._(6, _omitEnumNames ? '' : 'ROOM_CHANGE_ACTION_ROLE_CHANGED');

  static const $core.List<RoomChangeAction> values = <RoomChangeAction> [
    ROOM_CHANGE_ACTION_UNSPECIFIED,
    ROOM_CHANGE_ACTION_CREATED,
    ROOM_CHANGE_ACTION_UPDATED,
    ROOM_CHANGE_ACTION_DELETED,
    ROOM_CHANGE_ACTION_MEMBER_ADDED,
    ROOM_CHANGE_ACTION_MEMBER_REMOVED,
    ROOM_CHANGE_ACTION_ROLE_CHANGED,
  ];

  static final $core.Map<$core.int, RoomChangeAction> _byValue = $pb.ProtobufEnum.initByValue(values);
  static RoomChangeAction? valueOf($core.int value) => _byValue[value];

  const RoomChangeAction._($core.int v, $core.String n) : super(v, n);
}

class FormMessageState extends $pb.ProtobufEnum {
  static const FormMessageState FORM_MESSAGE_STATE_UNSPECIFIED = FormMessageState._(0, _omitEnumNames ? '' : 'FORM_MESSAGE_STATE_UNSPECIFIED');
  static const FormMessageState FORM_MESSAGE_STATE_OPEN = FormMessageState._(1, _omitEnumNames ? '' : 'FORM_MESSAGE_STATE_OPEN');
  static const FormMessageState FORM_MESSAGE_STATE_IN_REVIEW = FormMessageState._(2, _omitEnumNames ? '' : 'FORM_MESSAGE_STATE_IN_REVIEW');
  static const FormMessageState FORM_MESSAGE_STATE_SUBMITTING = FormMessageState._(3, _omitEnumNames ? '' : 'FORM_MESSAGE_STATE_SUBMITTING');
  static const FormMessageState FORM_MESSAGE_STATE_SUBMITTED = FormMessageState._(4, _omitEnumNames ? '' : 'FORM_MESSAGE_STATE_SUBMITTED');
  static const FormMessageState FORM_MESSAGE_STATE_FAILED_SUBMISSION = FormMessageState._(5, _omitEnumNames ? '' : 'FORM_MESSAGE_STATE_FAILED_SUBMISSION');
  static const FormMessageState FORM_MESSAGE_STATE_EXPIRED = FormMessageState._(6, _omitEnumNames ? '' : 'FORM_MESSAGE_STATE_EXPIRED');
  static const FormMessageState FORM_MESSAGE_STATE_CANCELLED = FormMessageState._(7, _omitEnumNames ? '' : 'FORM_MESSAGE_STATE_CANCELLED');

  static const $core.List<FormMessageState> values = <FormMessageState> [
    FORM_MESSAGE_STATE_UNSPECIFIED,
    FORM_MESSAGE_STATE_OPEN,
    FORM_MESSAGE_STATE_IN_REVIEW,
    FORM_MESSAGE_STATE_SUBMITTING,
    FORM_MESSAGE_STATE_SUBMITTED,
    FORM_MESSAGE_STATE_FAILED_SUBMISSION,
    FORM_MESSAGE_STATE_EXPIRED,
    FORM_MESSAGE_STATE_CANCELLED,
  ];

  static final $core.Map<$core.int, FormMessageState> _byValue = $pb.ProtobufEnum.initByValue(values);
  static FormMessageState? valueOf($core.int value) => _byValue[value];

  const FormMessageState._($core.int v, $core.String n) : super(v, n);
}

class FormFieldType extends $pb.ProtobufEnum {
  static const FormFieldType FORM_FIELD_TYPE_UNSPECIFIED = FormFieldType._(0, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_UNSPECIFIED');
  static const FormFieldType FORM_FIELD_TYPE_TEXT = FormFieldType._(1, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_TEXT');
  static const FormFieldType FORM_FIELD_TYPE_MULTILINE = FormFieldType._(2, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_MULTILINE');
  static const FormFieldType FORM_FIELD_TYPE_NUMBER = FormFieldType._(3, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_NUMBER');
  static const FormFieldType FORM_FIELD_TYPE_DECIMAL = FormFieldType._(4, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_DECIMAL');
  static const FormFieldType FORM_FIELD_TYPE_CURRENCY = FormFieldType._(5, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_CURRENCY');
  static const FormFieldType FORM_FIELD_TYPE_PHONE = FormFieldType._(6, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_PHONE');
  static const FormFieldType FORM_FIELD_TYPE_EMAIL = FormFieldType._(7, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_EMAIL');
  static const FormFieldType FORM_FIELD_TYPE_DATE = FormFieldType._(8, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_DATE');
  static const FormFieldType FORM_FIELD_TYPE_DATETIME = FormFieldType._(9, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_DATETIME');
  static const FormFieldType FORM_FIELD_TYPE_SELECT = FormFieldType._(10, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_SELECT');
  static const FormFieldType FORM_FIELD_TYPE_RADIO = FormFieldType._(11, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_RADIO');
  static const FormFieldType FORM_FIELD_TYPE_CHECKBOX_GROUP = FormFieldType._(12, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_CHECKBOX_GROUP');
  static const FormFieldType FORM_FIELD_TYPE_BOOLEAN = FormFieldType._(13, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_BOOLEAN');
  static const FormFieldType FORM_FIELD_TYPE_FILE = FormFieldType._(14, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_FILE');
  static const FormFieldType FORM_FIELD_TYPE_ADDRESS = FormFieldType._(15, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_ADDRESS');
  static const FormFieldType FORM_FIELD_TYPE_REPEATABLE_GROUP = FormFieldType._(16, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_REPEATABLE_GROUP');
  static const FormFieldType FORM_FIELD_TYPE_GROUP = FormFieldType._(17, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_GROUP');
  static const FormFieldType FORM_FIELD_TYPE_SECTION = FormFieldType._(18, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_SECTION');
  static const FormFieldType FORM_FIELD_TYPE_HIDDEN = FormFieldType._(19, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_HIDDEN');
  static const FormFieldType FORM_FIELD_TYPE_COMPUTED = FormFieldType._(20, _omitEnumNames ? '' : 'FORM_FIELD_TYPE_COMPUTED');

  static const $core.List<FormFieldType> values = <FormFieldType> [
    FORM_FIELD_TYPE_UNSPECIFIED,
    FORM_FIELD_TYPE_TEXT,
    FORM_FIELD_TYPE_MULTILINE,
    FORM_FIELD_TYPE_NUMBER,
    FORM_FIELD_TYPE_DECIMAL,
    FORM_FIELD_TYPE_CURRENCY,
    FORM_FIELD_TYPE_PHONE,
    FORM_FIELD_TYPE_EMAIL,
    FORM_FIELD_TYPE_DATE,
    FORM_FIELD_TYPE_DATETIME,
    FORM_FIELD_TYPE_SELECT,
    FORM_FIELD_TYPE_RADIO,
    FORM_FIELD_TYPE_CHECKBOX_GROUP,
    FORM_FIELD_TYPE_BOOLEAN,
    FORM_FIELD_TYPE_FILE,
    FORM_FIELD_TYPE_ADDRESS,
    FORM_FIELD_TYPE_REPEATABLE_GROUP,
    FORM_FIELD_TYPE_GROUP,
    FORM_FIELD_TYPE_SECTION,
    FORM_FIELD_TYPE_HIDDEN,
    FORM_FIELD_TYPE_COMPUTED,
  ];

  static final $core.Map<$core.int, FormFieldType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static FormFieldType? valueOf($core.int value) => _byValue[value];

  const FormFieldType._($core.int v, $core.String n) : super(v, n);
}

class FormConditionOperator extends $pb.ProtobufEnum {
  static const FormConditionOperator FORM_CONDITION_OPERATOR_UNSPECIFIED = FormConditionOperator._(0, _omitEnumNames ? '' : 'FORM_CONDITION_OPERATOR_UNSPECIFIED');
  static const FormConditionOperator FORM_CONDITION_OPERATOR_EQUALS = FormConditionOperator._(1, _omitEnumNames ? '' : 'FORM_CONDITION_OPERATOR_EQUALS');
  static const FormConditionOperator FORM_CONDITION_OPERATOR_NOT_EQUALS = FormConditionOperator._(2, _omitEnumNames ? '' : 'FORM_CONDITION_OPERATOR_NOT_EQUALS');
  static const FormConditionOperator FORM_CONDITION_OPERATOR_GREATER_THAN = FormConditionOperator._(3, _omitEnumNames ? '' : 'FORM_CONDITION_OPERATOR_GREATER_THAN');
  static const FormConditionOperator FORM_CONDITION_OPERATOR_GREATER_THAN_OR_EQUAL = FormConditionOperator._(4, _omitEnumNames ? '' : 'FORM_CONDITION_OPERATOR_GREATER_THAN_OR_EQUAL');
  static const FormConditionOperator FORM_CONDITION_OPERATOR_LESS_THAN = FormConditionOperator._(5, _omitEnumNames ? '' : 'FORM_CONDITION_OPERATOR_LESS_THAN');
  static const FormConditionOperator FORM_CONDITION_OPERATOR_LESS_THAN_OR_EQUAL = FormConditionOperator._(6, _omitEnumNames ? '' : 'FORM_CONDITION_OPERATOR_LESS_THAN_OR_EQUAL');
  static const FormConditionOperator FORM_CONDITION_OPERATOR_IN = FormConditionOperator._(7, _omitEnumNames ? '' : 'FORM_CONDITION_OPERATOR_IN');
  static const FormConditionOperator FORM_CONDITION_OPERATOR_NOT_IN = FormConditionOperator._(8, _omitEnumNames ? '' : 'FORM_CONDITION_OPERATOR_NOT_IN');
  static const FormConditionOperator FORM_CONDITION_OPERATOR_CONTAINS = FormConditionOperator._(9, _omitEnumNames ? '' : 'FORM_CONDITION_OPERATOR_CONTAINS');
  static const FormConditionOperator FORM_CONDITION_OPERATOR_NOT_CONTAINS = FormConditionOperator._(10, _omitEnumNames ? '' : 'FORM_CONDITION_OPERATOR_NOT_CONTAINS');
  static const FormConditionOperator FORM_CONDITION_OPERATOR_IS_TRUE = FormConditionOperator._(11, _omitEnumNames ? '' : 'FORM_CONDITION_OPERATOR_IS_TRUE');
  static const FormConditionOperator FORM_CONDITION_OPERATOR_IS_FALSE = FormConditionOperator._(12, _omitEnumNames ? '' : 'FORM_CONDITION_OPERATOR_IS_FALSE');
  static const FormConditionOperator FORM_CONDITION_OPERATOR_EXISTS = FormConditionOperator._(13, _omitEnumNames ? '' : 'FORM_CONDITION_OPERATOR_EXISTS');
  static const FormConditionOperator FORM_CONDITION_OPERATOR_NOT_EXISTS = FormConditionOperator._(14, _omitEnumNames ? '' : 'FORM_CONDITION_OPERATOR_NOT_EXISTS');

  static const $core.List<FormConditionOperator> values = <FormConditionOperator> [
    FORM_CONDITION_OPERATOR_UNSPECIFIED,
    FORM_CONDITION_OPERATOR_EQUALS,
    FORM_CONDITION_OPERATOR_NOT_EQUALS,
    FORM_CONDITION_OPERATOR_GREATER_THAN,
    FORM_CONDITION_OPERATOR_GREATER_THAN_OR_EQUAL,
    FORM_CONDITION_OPERATOR_LESS_THAN,
    FORM_CONDITION_OPERATOR_LESS_THAN_OR_EQUAL,
    FORM_CONDITION_OPERATOR_IN,
    FORM_CONDITION_OPERATOR_NOT_IN,
    FORM_CONDITION_OPERATOR_CONTAINS,
    FORM_CONDITION_OPERATOR_NOT_CONTAINS,
    FORM_CONDITION_OPERATOR_IS_TRUE,
    FORM_CONDITION_OPERATOR_IS_FALSE,
    FORM_CONDITION_OPERATOR_EXISTS,
    FORM_CONDITION_OPERATOR_NOT_EXISTS,
  ];

  static final $core.Map<$core.int, FormConditionOperator> _byValue = $pb.ProtobufEnum.initByValue(values);
  static FormConditionOperator? valueOf($core.int value) => _byValue[value];

  const FormConditionOperator._($core.int v, $core.String n) : super(v, n);
}

class TextAnnotation_Type extends $pb.ProtobufEnum {
  static const TextAnnotation_Type TYPE_UNSPECIFIED = TextAnnotation_Type._(0, _omitEnumNames ? '' : 'TYPE_UNSPECIFIED');
  static const TextAnnotation_Type TYPE_MENTION_USER = TextAnnotation_Type._(1, _omitEnumNames ? '' : 'TYPE_MENTION_USER');
  static const TextAnnotation_Type TYPE_MENTION_ROOM = TextAnnotation_Type._(2, _omitEnumNames ? '' : 'TYPE_MENTION_ROOM');
  static const TextAnnotation_Type TYPE_LINK = TextAnnotation_Type._(3, _omitEnumNames ? '' : 'TYPE_LINK');
  static const TextAnnotation_Type TYPE_EMOJI = TextAnnotation_Type._(4, _omitEnumNames ? '' : 'TYPE_EMOJI');
  static const TextAnnotation_Type TYPE_HASHTAG = TextAnnotation_Type._(5, _omitEnumNames ? '' : 'TYPE_HASHTAG');

  static const $core.List<TextAnnotation_Type> values = <TextAnnotation_Type> [
    TYPE_UNSPECIFIED,
    TYPE_MENTION_USER,
    TYPE_MENTION_ROOM,
    TYPE_LINK,
    TYPE_EMOJI,
    TYPE_HASHTAG,
  ];

  static final $core.Map<$core.int, TextAnnotation_Type> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TextAnnotation_Type? valueOf($core.int value) => _byValue[value];

  const TextAnnotation_Type._($core.int v, $core.String n) : super(v, n);
}

class CallContent_CallType extends $pb.ProtobufEnum {
  static const CallContent_CallType CALL_TYPE_UNSPECIFIED = CallContent_CallType._(0, _omitEnumNames ? '' : 'CALL_TYPE_UNSPECIFIED');
  static const CallContent_CallType CALL_TYPE_AUDIO = CallContent_CallType._(1, _omitEnumNames ? '' : 'CALL_TYPE_AUDIO');
  static const CallContent_CallType CALL_TYPE_VIDEO = CallContent_CallType._(2, _omitEnumNames ? '' : 'CALL_TYPE_VIDEO');
  static const CallContent_CallType CALL_TYPE_SCREEN_SHARE = CallContent_CallType._(3, _omitEnumNames ? '' : 'CALL_TYPE_SCREEN_SHARE');

  static const $core.List<CallContent_CallType> values = <CallContent_CallType> [
    CALL_TYPE_UNSPECIFIED,
    CALL_TYPE_AUDIO,
    CALL_TYPE_VIDEO,
    CALL_TYPE_SCREEN_SHARE,
  ];

  static final $core.Map<$core.int, CallContent_CallType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static CallContent_CallType? valueOf($core.int value) => _byValue[value];

  const CallContent_CallType._($core.int v, $core.String n) : super(v, n);
}

class CallContent_CallAction extends $pb.ProtobufEnum {
  static const CallContent_CallAction CALL_ACTION_UNSPECIFIED = CallContent_CallAction._(0, _omitEnumNames ? '' : 'CALL_ACTION_UNSPECIFIED');
  static const CallContent_CallAction CALL_ACTION_OFFER = CallContent_CallAction._(1, _omitEnumNames ? '' : 'CALL_ACTION_OFFER');
  static const CallContent_CallAction CALL_ACTION_ANSWER = CallContent_CallAction._(2, _omitEnumNames ? '' : 'CALL_ACTION_ANSWER');
  static const CallContent_CallAction CALL_ACTION_ICE_CANDIDATE = CallContent_CallAction._(3, _omitEnumNames ? '' : 'CALL_ACTION_ICE_CANDIDATE');
  static const CallContent_CallAction CALL_ACTION_END = CallContent_CallAction._(4, _omitEnumNames ? '' : 'CALL_ACTION_END');

  static const $core.List<CallContent_CallAction> values = <CallContent_CallAction> [
    CALL_ACTION_UNSPECIFIED,
    CALL_ACTION_OFFER,
    CALL_ACTION_ANSWER,
    CALL_ACTION_ICE_CANDIDATE,
    CALL_ACTION_END,
  ];

  static final $core.Map<$core.int, CallContent_CallAction> _byValue = $pb.ProtobufEnum.initByValue(values);
  static CallContent_CallAction? valueOf($core.int value) => _byValue[value];

  const CallContent_CallAction._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
