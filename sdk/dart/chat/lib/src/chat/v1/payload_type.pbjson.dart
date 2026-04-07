//
//  Generated code. Do not modify.
//  source: chat/v1/payload_type.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use payloadTypeDescriptor instead')
const PayloadType$json = {
  '1': 'PayloadType',
  '2': [
    {'1': 'PAYLOAD_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'PAYLOAD_TYPE_ROOM_CHANGE', '2': 1},
    {'1': 'PAYLOAD_TYPE_TEXT', '2': 2},
    {'1': 'PAYLOAD_TYPE_ATTACHMENT', '2': 3},
    {'1': 'PAYLOAD_TYPE_REACTION', '2': 7},
    {'1': 'PAYLOAD_TYPE_ENCRYPTED', '2': 6},
    {'1': 'PAYLOAD_TYPE_CALL', '2': 20},
    {'1': 'PAYLOAD_TYPE_MODERATION', '2': 21},
    {'1': 'PAYLOAD_TYPE_MOTION', '2': 22},
    {'1': 'PAYLOAD_TYPE_VOTE', '2': 23},
    {'1': 'PAYLOAD_TYPE_MOTION_TALLY', '2': 24},
    {'1': 'PAYLOAD_TYPE_VOTE_TALLY', '2': 25},
    {'1': 'PAYLOAD_TYPE_FORM_REQUEST', '2': 30},
    {'1': 'PAYLOAD_TYPE_FORM_SUBMISSION_RESULT', '2': 31},
  ],
};

/// Descriptor for `PayloadType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List payloadTypeDescriptor = $convert.base64Decode(
    'CgtQYXlsb2FkVHlwZRIcChhQQVlMT0FEX1RZUEVfVU5TUEVDSUZJRUQQABIcChhQQVlMT0FEX1'
    'RZUEVfUk9PTV9DSEFOR0UQARIVChFQQVlMT0FEX1RZUEVfVEVYVBACEhsKF1BBWUxPQURfVFlQ'
    'RV9BVFRBQ0hNRU5UEAMSGQoVUEFZTE9BRF9UWVBFX1JFQUNUSU9OEAcSGgoWUEFZTE9BRF9UWV'
    'BFX0VOQ1JZUFRFRBAGEhUKEVBBWUxPQURfVFlQRV9DQUxMEBQSGwoXUEFZTE9BRF9UWVBFX01P'
    'REVSQVRJT04QFRIXChNQQVlMT0FEX1RZUEVfTU9USU9OEBYSFQoRUEFZTE9BRF9UWVBFX1ZPVE'
    'UQFxIdChlQQVlMT0FEX1RZUEVfTU9USU9OX1RBTExZEBgSGwoXUEFZTE9BRF9UWVBFX1ZPVEVf'
    'VEFMTFkQGRIdChlQQVlMT0FEX1RZUEVfRk9STV9SRVFVRVNUEB4SJwojUEFZTE9BRF9UWVBFX0'
    'ZPUk1fU1VCTUlTU0lPTl9SRVNVTFQQHw==');

@$core.Deprecated('Use roomChangeActionDescriptor instead')
const RoomChangeAction$json = {
  '1': 'RoomChangeAction',
  '2': [
    {'1': 'ROOM_CHANGE_ACTION_UNSPECIFIED', '2': 0},
    {'1': 'ROOM_CHANGE_ACTION_CREATED', '2': 1},
    {'1': 'ROOM_CHANGE_ACTION_UPDATED', '2': 2},
    {'1': 'ROOM_CHANGE_ACTION_DELETED', '2': 3},
    {'1': 'ROOM_CHANGE_ACTION_MEMBER_ADDED', '2': 4},
    {'1': 'ROOM_CHANGE_ACTION_MEMBER_REMOVED', '2': 5},
    {'1': 'ROOM_CHANGE_ACTION_ROLE_CHANGED', '2': 6},
  ],
};

/// Descriptor for `RoomChangeAction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List roomChangeActionDescriptor = $convert.base64Decode(
    'ChBSb29tQ2hhbmdlQWN0aW9uEiIKHlJPT01fQ0hBTkdFX0FDVElPTl9VTlNQRUNJRklFRBAAEh'
    '4KGlJPT01fQ0hBTkdFX0FDVElPTl9DUkVBVEVEEAESHgoaUk9PTV9DSEFOR0VfQUNUSU9OX1VQ'
    'REFURUQQAhIeChpST09NX0NIQU5HRV9BQ1RJT05fREVMRVRFRBADEiMKH1JPT01fQ0hBTkdFX0'
    'FDVElPTl9NRU1CRVJfQURERUQQBBIlCiFST09NX0NIQU5HRV9BQ1RJT05fTUVNQkVSX1JFTU9W'
    'RUQQBRIjCh9ST09NX0NIQU5HRV9BQ1RJT05fUk9MRV9DSEFOR0VEEAY=');

@$core.Deprecated('Use formMessageStateDescriptor instead')
const FormMessageState$json = {
  '1': 'FormMessageState',
  '2': [
    {'1': 'FORM_MESSAGE_STATE_UNSPECIFIED', '2': 0},
    {'1': 'FORM_MESSAGE_STATE_OPEN', '2': 1},
    {'1': 'FORM_MESSAGE_STATE_IN_REVIEW', '2': 2},
    {'1': 'FORM_MESSAGE_STATE_SUBMITTING', '2': 3},
    {'1': 'FORM_MESSAGE_STATE_SUBMITTED', '2': 4},
    {'1': 'FORM_MESSAGE_STATE_FAILED_SUBMISSION', '2': 5},
    {'1': 'FORM_MESSAGE_STATE_EXPIRED', '2': 6},
    {'1': 'FORM_MESSAGE_STATE_CANCELLED', '2': 7},
  ],
};

/// Descriptor for `FormMessageState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List formMessageStateDescriptor = $convert.base64Decode(
    'ChBGb3JtTWVzc2FnZVN0YXRlEiIKHkZPUk1fTUVTU0FHRV9TVEFURV9VTlNQRUNJRklFRBAAEh'
    'sKF0ZPUk1fTUVTU0FHRV9TVEFURV9PUEVOEAESIAocRk9STV9NRVNTQUdFX1NUQVRFX0lOX1JF'
    'VklFVxACEiEKHUZPUk1fTUVTU0FHRV9TVEFURV9TVUJNSVRUSU5HEAMSIAocRk9STV9NRVNTQU'
    'dFX1NUQVRFX1NVQk1JVFRFRBAEEigKJEZPUk1fTUVTU0FHRV9TVEFURV9GQUlMRURfU1VCTUlT'
    'U0lPThAFEh4KGkZPUk1fTUVTU0FHRV9TVEFURV9FWFBJUkVEEAYSIAocRk9STV9NRVNTQUdFX1'
    'NUQVRFX0NBTkNFTExFRBAH');

@$core.Deprecated('Use formFieldTypeDescriptor instead')
const FormFieldType$json = {
  '1': 'FormFieldType',
  '2': [
    {'1': 'FORM_FIELD_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'FORM_FIELD_TYPE_TEXT', '2': 1},
    {'1': 'FORM_FIELD_TYPE_MULTILINE', '2': 2},
    {'1': 'FORM_FIELD_TYPE_NUMBER', '2': 3},
    {'1': 'FORM_FIELD_TYPE_DECIMAL', '2': 4},
    {'1': 'FORM_FIELD_TYPE_CURRENCY', '2': 5},
    {'1': 'FORM_FIELD_TYPE_PHONE', '2': 6},
    {'1': 'FORM_FIELD_TYPE_EMAIL', '2': 7},
    {'1': 'FORM_FIELD_TYPE_DATE', '2': 8},
    {'1': 'FORM_FIELD_TYPE_DATETIME', '2': 9},
    {'1': 'FORM_FIELD_TYPE_SELECT', '2': 10},
    {'1': 'FORM_FIELD_TYPE_RADIO', '2': 11},
    {'1': 'FORM_FIELD_TYPE_CHECKBOX_GROUP', '2': 12},
    {'1': 'FORM_FIELD_TYPE_BOOLEAN', '2': 13},
    {'1': 'FORM_FIELD_TYPE_FILE', '2': 14},
    {'1': 'FORM_FIELD_TYPE_ADDRESS', '2': 15},
    {'1': 'FORM_FIELD_TYPE_REPEATABLE_GROUP', '2': 16},
    {'1': 'FORM_FIELD_TYPE_GROUP', '2': 17},
    {'1': 'FORM_FIELD_TYPE_SECTION', '2': 18},
    {'1': 'FORM_FIELD_TYPE_HIDDEN', '2': 19},
    {'1': 'FORM_FIELD_TYPE_COMPUTED', '2': 20},
  ],
};

/// Descriptor for `FormFieldType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List formFieldTypeDescriptor = $convert.base64Decode(
    'Cg1Gb3JtRmllbGRUeXBlEh8KG0ZPUk1fRklFTERfVFlQRV9VTlNQRUNJRklFRBAAEhgKFEZPUk'
    '1fRklFTERfVFlQRV9URVhUEAESHQoZRk9STV9GSUVMRF9UWVBFX01VTFRJTElORRACEhoKFkZP'
    'Uk1fRklFTERfVFlQRV9OVU1CRVIQAxIbChdGT1JNX0ZJRUxEX1RZUEVfREVDSU1BTBAEEhwKGE'
    'ZPUk1fRklFTERfVFlQRV9DVVJSRU5DWRAFEhkKFUZPUk1fRklFTERfVFlQRV9QSE9ORRAGEhkK'
    'FUZPUk1fRklFTERfVFlQRV9FTUFJTBAHEhgKFEZPUk1fRklFTERfVFlQRV9EQVRFEAgSHAoYRk'
    '9STV9GSUVMRF9UWVBFX0RBVEVUSU1FEAkSGgoWRk9STV9GSUVMRF9UWVBFX1NFTEVDVBAKEhkK'
    'FUZPUk1fRklFTERfVFlQRV9SQURJTxALEiIKHkZPUk1fRklFTERfVFlQRV9DSEVDS0JPWF9HUk'
    '9VUBAMEhsKF0ZPUk1fRklFTERfVFlQRV9CT09MRUFOEA0SGAoURk9STV9GSUVMRF9UWVBFX0ZJ'
    'TEUQDhIbChdGT1JNX0ZJRUxEX1RZUEVfQUREUkVTUxAPEiQKIEZPUk1fRklFTERfVFlQRV9SRV'
    'BFQVRBQkxFX0dST1VQEBASGQoVRk9STV9GSUVMRF9UWVBFX0dST1VQEBESGwoXRk9STV9GSUVM'
    'RF9UWVBFX1NFQ1RJT04QEhIaChZGT1JNX0ZJRUxEX1RZUEVfSElEREVOEBMSHAoYRk9STV9GSU'
    'VMRF9UWVBFX0NPTVBVVEVEEBQ=');

@$core.Deprecated('Use formConditionOperatorDescriptor instead')
const FormConditionOperator$json = {
  '1': 'FormConditionOperator',
  '2': [
    {'1': 'FORM_CONDITION_OPERATOR_UNSPECIFIED', '2': 0},
    {'1': 'FORM_CONDITION_OPERATOR_EQUALS', '2': 1},
    {'1': 'FORM_CONDITION_OPERATOR_NOT_EQUALS', '2': 2},
    {'1': 'FORM_CONDITION_OPERATOR_GREATER_THAN', '2': 3},
    {'1': 'FORM_CONDITION_OPERATOR_GREATER_THAN_OR_EQUAL', '2': 4},
    {'1': 'FORM_CONDITION_OPERATOR_LESS_THAN', '2': 5},
    {'1': 'FORM_CONDITION_OPERATOR_LESS_THAN_OR_EQUAL', '2': 6},
    {'1': 'FORM_CONDITION_OPERATOR_IN', '2': 7},
    {'1': 'FORM_CONDITION_OPERATOR_NOT_IN', '2': 8},
    {'1': 'FORM_CONDITION_OPERATOR_CONTAINS', '2': 9},
    {'1': 'FORM_CONDITION_OPERATOR_NOT_CONTAINS', '2': 10},
    {'1': 'FORM_CONDITION_OPERATOR_IS_TRUE', '2': 11},
    {'1': 'FORM_CONDITION_OPERATOR_IS_FALSE', '2': 12},
    {'1': 'FORM_CONDITION_OPERATOR_EXISTS', '2': 13},
    {'1': 'FORM_CONDITION_OPERATOR_NOT_EXISTS', '2': 14},
  ],
};

/// Descriptor for `FormConditionOperator`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List formConditionOperatorDescriptor = $convert.base64Decode(
    'ChVGb3JtQ29uZGl0aW9uT3BlcmF0b3ISJwojRk9STV9DT05ESVRJT05fT1BFUkFUT1JfVU5TUE'
    'VDSUZJRUQQABIiCh5GT1JNX0NPTkRJVElPTl9PUEVSQVRPUl9FUVVBTFMQARImCiJGT1JNX0NP'
    'TkRJVElPTl9PUEVSQVRPUl9OT1RfRVFVQUxTEAISKAokRk9STV9DT05ESVRJT05fT1BFUkFUT1'
    'JfR1JFQVRFUl9USEFOEAMSMQotRk9STV9DT05ESVRJT05fT1BFUkFUT1JfR1JFQVRFUl9USEFO'
    'X09SX0VRVUFMEAQSJQohRk9STV9DT05ESVRJT05fT1BFUkFUT1JfTEVTU19USEFOEAUSLgoqRk'
    '9STV9DT05ESVRJT05fT1BFUkFUT1JfTEVTU19USEFOX09SX0VRVUFMEAYSHgoaRk9STV9DT05E'
    'SVRJT05fT1BFUkFUT1JfSU4QBxIiCh5GT1JNX0NPTkRJVElPTl9PUEVSQVRPUl9OT1RfSU4QCB'
    'IkCiBGT1JNX0NPTkRJVElPTl9PUEVSQVRPUl9DT05UQUlOUxAJEigKJEZPUk1fQ09ORElUSU9O'
    'X09QRVJBVE9SX05PVF9DT05UQUlOUxAKEiMKH0ZPUk1fQ09ORElUSU9OX09QRVJBVE9SX0lTX1'
    'RSVUUQCxIkCiBGT1JNX0NPTkRJVElPTl9PUEVSQVRPUl9JU19GQUxTRRAMEiIKHkZPUk1fQ09O'
    'RElUSU9OX09QRVJBVE9SX0VYSVNUUxANEiYKIkZPUk1fQ09ORElUSU9OX09QRVJBVE9SX05PVF'
    '9FWElTVFMQDg==');

@$core.Deprecated('Use roomChangeContentDescriptor instead')
const RoomChangeContent$json = {
  '1': 'RoomChangeContent',
  '2': [
    {'1': 'action', '3': 1, '4': 1, '5': 14, '6': '.chat.v1.RoomChangeAction', '10': 'action'},
    {'1': 'actor_subscription_id', '3': 2, '4': 1, '5': 9, '10': 'actorSubscriptionId'},
    {'1': 'target_subscription_ids', '3': 3, '4': 3, '5': 9, '10': 'targetSubscriptionIds'},
    {'1': 'body', '3': 4, '4': 1, '5': 9, '10': 'body'},
    {'1': 'details', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'details'},
  ],
};

/// Descriptor for `RoomChangeContent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roomChangeContentDescriptor = $convert.base64Decode(
    'ChFSb29tQ2hhbmdlQ29udGVudBIxCgZhY3Rpb24YASABKA4yGS5jaGF0LnYxLlJvb21DaGFuZ2'
    'VBY3Rpb25SBmFjdGlvbhIyChVhY3Rvcl9zdWJzY3JpcHRpb25faWQYAiABKAlSE2FjdG9yU3Vi'
    'c2NyaXB0aW9uSWQSNgoXdGFyZ2V0X3N1YnNjcmlwdGlvbl9pZHMYAyADKAlSFXRhcmdldFN1Yn'
    'NjcmlwdGlvbklkcxISCgRib2R5GAQgASgJUgRib2R5EjEKB2RldGFpbHMYBSABKAsyFy5nb29n'
    'bGUucHJvdG9idWYuU3RydWN0UgdkZXRhaWxz');

@$core.Deprecated('Use moderationContentDescriptor instead')
const ModerationContent$json = {
  '1': 'ModerationContent',
  '2': [
    {'1': 'body', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'body'},
    {'1': 'actor_subscription_id', '3': 2, '4': 1, '5': 9, '8': {}, '10': 'actorSubscriptionId'},
    {'1': 'target_subscription_ids', '3': 3, '4': 3, '5': 9, '8': {}, '10': 'targetSubscriptionIds'},
    {'1': 'metadata', '3': 8, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'metadata'},
    {'1': 'language', '3': 4, '4': 1, '5': 9, '8': {}, '9': 0, '10': 'language', '17': true},
  ],
  '8': [
    {'1': '_language'},
  ],
};

/// Descriptor for `ModerationContent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moderationContentDescriptor = $convert.base64Decode(
    'ChFNb2RlcmF0aW9uQ29udGVudBIeCgRib2R5GAEgASgJQgq6SAdyBRABGJBOUgRib2R5Ej0KFW'
    'FjdG9yX3N1YnNjcmlwdGlvbl9pZBgCIAEoCUIJukgGcgQQARggUhNhY3RvclN1YnNjcmlwdGlv'
    'bklkEloKF3RhcmdldF9zdWJzY3JpcHRpb25faWRzGAMgAygJQiK6SB+SARwYASIYchYQAxgoMh'
    'BbMC05YS16Xy1dezMsNDB9UhV0YXJnZXRTdWJzY3JpcHRpb25JZHMSMwoIbWV0YWRhdGEYCCAB'
    'KAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0UghtZXRhZGF0YRJLCghsYW5ndWFnZRgEIAEoCU'
    'IqukgnciUyI15bYS16QS1aXXsyLDN9KC1bYS16QS1aMC05XXsyLDh9KSokSABSCGxhbmd1YWdl'
    'iAEBQgsKCV9sYW5ndWFnZQ==');

@$core.Deprecated('Use textContentDescriptor instead')
const TextContent$json = {
  '1': 'TextContent',
  '2': [
    {'1': 'body', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'body'},
    {'1': 'format', '3': 2, '4': 1, '5': 9, '8': {}, '10': 'format'},
    {'1': 'annotations', '3': 3, '4': 3, '5': 11, '6': '.chat.v1.TextAnnotation', '10': 'annotations'},
    {'1': 'lang', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'lang', '17': true},
  ],
  '8': [
    {'1': '_lang'},
  ],
};

/// Descriptor for `TextContent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textContentDescriptor = $convert.base64Decode(
    'CgtUZXh0Q29udGVudBIeCgRib2R5GAEgASgJQgq6SAdyBRABGJBOUgRib2R5EiEKBmZvcm1hdB'
    'gCIAEoCUIJukgGcgQQARggUgZmb3JtYXQSOQoLYW5ub3RhdGlvbnMYAyADKAsyFy5jaGF0LnYx'
    'LlRleHRBbm5vdGF0aW9uUgthbm5vdGF0aW9ucxIXCgRsYW5nGAQgASgJSABSBGxhbmeIAQFCBw'
    'oFX2xhbmc=');

@$core.Deprecated('Use textAnnotationDescriptor instead')
const TextAnnotation$json = {
  '1': 'TextAnnotation',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 14, '6': '.chat.v1.TextAnnotation.Type', '10': 'type'},
    {'1': 'offset', '3': 2, '4': 1, '5': 5, '10': 'offset'},
    {'1': 'length', '3': 3, '4': 1, '5': 5, '10': 'length'},
    {'1': 'value', '3': 4, '4': 1, '5': 9, '10': 'value'},
  ],
  '4': [TextAnnotation_Type$json],
};

@$core.Deprecated('Use textAnnotationDescriptor instead')
const TextAnnotation_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'TYPE_UNSPECIFIED', '2': 0},
    {'1': 'TYPE_MENTION_USER', '2': 1},
    {'1': 'TYPE_MENTION_ROOM', '2': 2},
    {'1': 'TYPE_LINK', '2': 3},
    {'1': 'TYPE_EMOJI', '2': 4},
    {'1': 'TYPE_HASHTAG', '2': 5},
  ],
};

/// Descriptor for `TextAnnotation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textAnnotationDescriptor = $convert.base64Decode(
    'Cg5UZXh0QW5ub3RhdGlvbhIwCgR0eXBlGAEgASgOMhwuY2hhdC52MS5UZXh0QW5ub3RhdGlvbi'
    '5UeXBlUgR0eXBlEhYKBm9mZnNldBgCIAEoBVIGb2Zmc2V0EhYKBmxlbmd0aBgDIAEoBVIGbGVu'
    'Z3RoEhQKBXZhbHVlGAQgASgJUgV2YWx1ZSJ7CgRUeXBlEhQKEFRZUEVfVU5TUEVDSUZJRUQQAB'
    'IVChFUWVBFX01FTlRJT05fVVNFUhABEhUKEVRZUEVfTUVOVElPTl9ST09NEAISDQoJVFlQRV9M'
    'SU5LEAMSDgoKVFlQRV9FTU9KSRAEEhAKDFRZUEVfSEFTSFRBRxAF');

@$core.Deprecated('Use attachmentContentDescriptor instead')
const AttachmentContent$json = {
  '1': 'AttachmentContent',
  '2': [
    {'1': 'attachment_id', '3': 1, '4': 1, '5': 9, '10': 'attachmentId'},
    {'1': 'filename', '3': 2, '4': 1, '5': 9, '10': 'filename'},
    {'1': 'mime_type', '3': 3, '4': 1, '5': 9, '10': 'mimeType'},
    {'1': 'size_bytes', '3': 4, '4': 1, '5': 3, '10': 'sizeBytes'},
    {'1': 'uri', '3': 5, '4': 1, '5': 9, '10': 'uri'},
    {'1': 'previews', '3': 6, '4': 3, '5': 11, '6': '.chat.v1.AttachmentPreview', '10': 'previews'},
    {'1': 'caption', '3': 7, '4': 1, '5': 11, '6': '.chat.v1.TextContent', '9': 0, '10': 'caption', '17': true},
    {'1': 'encrypted', '3': 8, '4': 1, '5': 8, '10': 'encrypted'},
    {'1': 'checksum', '3': 9, '4': 1, '5': 9, '9': 1, '10': 'checksum', '17': true},
  ],
  '8': [
    {'1': '_caption'},
    {'1': '_checksum'},
  ],
};

/// Descriptor for `AttachmentContent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List attachmentContentDescriptor = $convert.base64Decode(
    'ChFBdHRhY2htZW50Q29udGVudBIjCg1hdHRhY2htZW50X2lkGAEgASgJUgxhdHRhY2htZW50SW'
    'QSGgoIZmlsZW5hbWUYAiABKAlSCGZpbGVuYW1lEhsKCW1pbWVfdHlwZRgDIAEoCVIIbWltZVR5'
    'cGUSHQoKc2l6ZV9ieXRlcxgEIAEoA1IJc2l6ZUJ5dGVzEhAKA3VyaRgFIAEoCVIDdXJpEjYKCH'
    'ByZXZpZXdzGAYgAygLMhouY2hhdC52MS5BdHRhY2htZW50UHJldmlld1IIcHJldmlld3MSMwoH'
    'Y2FwdGlvbhgHIAEoCzIULmNoYXQudjEuVGV4dENvbnRlbnRIAFIHY2FwdGlvbogBARIcCgllbm'
    'NyeXB0ZWQYCCABKAhSCWVuY3J5cHRlZBIfCghjaGVja3N1bRgJIAEoCUgBUghjaGVja3N1bYgB'
    'AUIKCghfY2FwdGlvbkILCglfY2hlY2tzdW0=');

@$core.Deprecated('Use attachmentPreviewDescriptor instead')
const AttachmentPreview$json = {
  '1': 'AttachmentPreview',
  '2': [
    {'1': 'mime_type', '3': 1, '4': 1, '5': 9, '10': 'mimeType'},
    {'1': 'width', '3': 2, '4': 1, '5': 5, '10': 'width'},
    {'1': 'height', '3': 3, '4': 1, '5': 5, '10': 'height'},
    {'1': 'uri', '3': 4, '4': 1, '5': 9, '10': 'uri'},
    {'1': 'size_bytes', '3': 5, '4': 1, '5': 3, '10': 'sizeBytes'},
  ],
};

/// Descriptor for `AttachmentPreview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List attachmentPreviewDescriptor = $convert.base64Decode(
    'ChFBdHRhY2htZW50UHJldmlldxIbCgltaW1lX3R5cGUYASABKAlSCG1pbWVUeXBlEhQKBXdpZH'
    'RoGAIgASgFUgV3aWR0aBIWCgZoZWlnaHQYAyABKAVSBmhlaWdodBIQCgN1cmkYBCABKAlSA3Vy'
    'aRIdCgpzaXplX2J5dGVzGAUgASgDUglzaXplQnl0ZXM=');

@$core.Deprecated('Use reactionContentDescriptor instead')
const ReactionContent$json = {
  '1': 'ReactionContent',
  '2': [
    {'1': 'target_event_id', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'targetEventId'},
    {'1': 'reaction', '3': 2, '4': 1, '5': 9, '8': {}, '10': 'reaction'},
    {'1': 'add', '3': 3, '4': 1, '5': 8, '10': 'add'},
  ],
};

/// Descriptor for `ReactionContent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reactionContentDescriptor = $convert.base64Decode(
    'Cg9SZWFjdGlvbkNvbnRlbnQSLwoPdGFyZ2V0X2V2ZW50X2lkGAEgASgJQge6SARyAhADUg10YX'
    'JnZXRFdmVudElkEiUKCHJlYWN0aW9uGAIgASgJQgm6SAZyBBABGEBSCHJlYWN0aW9uEhAKA2Fk'
    'ZBgDIAEoCFIDYWRk');

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent$json = {
  '1': 'EncryptedContent',
  '2': [
    {'1': 'algorithm', '3': 1, '4': 1, '5': 9, '10': 'algorithm'},
    {'1': 'ciphertext', '3': 2, '4': 1, '5': 12, '10': 'ciphertext'},
    {'1': 'nonce', '3': 3, '4': 1, '5': 12, '9': 0, '10': 'nonce', '17': true},
    {'1': 'sender_key_id', '3': 4, '4': 1, '5': 9, '9': 1, '10': 'senderKeyId', '17': true},
    {'1': 'recipient_key_ids', '3': 5, '4': 3, '5': 9, '10': 'recipientKeyIds'},
    {'1': 'aad', '3': 6, '4': 1, '5': 12, '9': 2, '10': 'aad', '17': true},
    {'1': 'session_id', '3': 7, '4': 1, '5': 9, '9': 3, '10': 'sessionId', '17': true},
  ],
  '8': [
    {'1': '_nonce'},
    {'1': '_sender_key_id'},
    {'1': '_aad'},
    {'1': '_session_id'},
  ],
};

/// Descriptor for `EncryptedContent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List encryptedContentDescriptor = $convert.base64Decode(
    'ChBFbmNyeXB0ZWRDb250ZW50EhwKCWFsZ29yaXRobRgBIAEoCVIJYWxnb3JpdGhtEh4KCmNpcG'
    'hlcnRleHQYAiABKAxSCmNpcGhlcnRleHQSGQoFbm9uY2UYAyABKAxIAFIFbm9uY2WIAQESJwoN'
    'c2VuZGVyX2tleV9pZBgEIAEoCUgBUgtzZW5kZXJLZXlJZIgBARIqChFyZWNpcGllbnRfa2V5X2'
    'lkcxgFIAMoCVIPcmVjaXBpZW50S2V5SWRzEhUKA2FhZBgGIAEoDEgCUgNhYWSIAQESIgoKc2Vz'
    'c2lvbl9pZBgHIAEoCUgDUglzZXNzaW9uSWSIAQFCCAoGX25vbmNlQhAKDl9zZW5kZXJfa2V5X2'
    'lkQgYKBF9hYWRCDQoLX3Nlc3Npb25faWQ=');

@$core.Deprecated('Use callContentDescriptor instead')
const CallContent$json = {
  '1': 'CallContent',
  '2': [
    {'1': 'call_id', '3': 1, '4': 1, '5': 9, '10': 'callId'},
    {'1': 'type', '3': 2, '4': 1, '5': 14, '6': '.chat.v1.CallContent.CallType', '10': 'type'},
    {'1': 'action', '3': 3, '4': 1, '5': 14, '6': '.chat.v1.CallContent.CallAction', '10': 'action'},
    {'1': 'sdp', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'sdp', '17': true},
    {'1': 'ice_candidate', '3': 5, '4': 1, '5': 9, '9': 1, '10': 'iceCandidate', '17': true},
    {'1': 'metadata', '3': 8, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'metadata'},
  ],
  '4': [CallContent_CallType$json, CallContent_CallAction$json],
  '8': [
    {'1': '_sdp'},
    {'1': '_ice_candidate'},
  ],
};

@$core.Deprecated('Use callContentDescriptor instead')
const CallContent_CallType$json = {
  '1': 'CallType',
  '2': [
    {'1': 'CALL_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'CALL_TYPE_AUDIO', '2': 1},
    {'1': 'CALL_TYPE_VIDEO', '2': 2},
    {'1': 'CALL_TYPE_SCREEN_SHARE', '2': 3},
  ],
};

@$core.Deprecated('Use callContentDescriptor instead')
const CallContent_CallAction$json = {
  '1': 'CallAction',
  '2': [
    {'1': 'CALL_ACTION_UNSPECIFIED', '2': 0},
    {'1': 'CALL_ACTION_OFFER', '2': 1},
    {'1': 'CALL_ACTION_ANSWER', '2': 2},
    {'1': 'CALL_ACTION_ICE_CANDIDATE', '2': 3},
    {'1': 'CALL_ACTION_END', '2': 4},
  ],
};

/// Descriptor for `CallContent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List callContentDescriptor = $convert.base64Decode(
    'CgtDYWxsQ29udGVudBIXCgdjYWxsX2lkGAEgASgJUgZjYWxsSWQSMQoEdHlwZRgCIAEoDjIdLm'
    'NoYXQudjEuQ2FsbENvbnRlbnQuQ2FsbFR5cGVSBHR5cGUSNwoGYWN0aW9uGAMgASgOMh8uY2hh'
    'dC52MS5DYWxsQ29udGVudC5DYWxsQWN0aW9uUgZhY3Rpb24SFQoDc2RwGAQgASgJSABSA3NkcI'
    'gBARIoCg1pY2VfY2FuZGlkYXRlGAUgASgJSAFSDGljZUNhbmRpZGF0ZYgBARIzCghtZXRhZGF0'
    'YRgIIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RSCG1ldGFkYXRhImsKCENhbGxUeXBlEh'
    'kKFUNBTExfVFlQRV9VTlNQRUNJRklFRBAAEhMKD0NBTExfVFlQRV9BVURJTxABEhMKD0NBTExf'
    'VFlQRV9WSURFTxACEhoKFkNBTExfVFlQRV9TQ1JFRU5fU0hBUkUQAyKMAQoKQ2FsbEFjdGlvbh'
    'IbChdDQUxMX0FDVElPTl9VTlNQRUNJRklFRBAAEhUKEUNBTExfQUNUSU9OX09GRkVSEAESFgoS'
    'Q0FMTF9BQ1RJT05fQU5TV0VSEAISHQoZQ0FMTF9BQ1RJT05fSUNFX0NBTkRJREFURRADEhMKD0'
    'NBTExfQUNUSU9OX0VORBAEQgYKBF9zZHBCEAoOX2ljZV9jYW5kaWRhdGU=');

@$core.Deprecated('Use motionContentDescriptor instead')
const MotionContent$json = {
  '1': 'MotionContent',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'description', '3': 3, '4': 1, '5': 9, '10': 'description'},
    {'1': 'eligible_roles', '3': 13, '4': 3, '5': 9, '10': 'eligibleRoles'},
    {'1': 'eligible_votes', '3': 4, '4': 1, '5': 13, '9': 0, '10': 'eligibleVotes', '17': true},
    {'1': 'passing_rule', '3': 7, '4': 1, '5': 11, '6': '.chat.v1.PassingRule', '10': 'passingRule'},
    {'1': 'choices', '3': 8, '4': 3, '5': 11, '6': '.chat.v1.VoteChoice', '10': 'choices'},
    {'1': 'closes_at', '3': 12, '4': 1, '5': 3, '9': 1, '10': 'closesAt', '17': true},
  ],
  '8': [
    {'1': '_eligible_votes'},
    {'1': '_closes_at'},
  ],
};

/// Descriptor for `MotionContent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List motionContentDescriptor = $convert.base64Decode(
    'Cg1Nb3Rpb25Db250ZW50Eg4KAmlkGAEgASgJUgJpZBIUCgV0aXRsZRgCIAEoCVIFdGl0bGUSIA'
    'oLZGVzY3JpcHRpb24YAyABKAlSC2Rlc2NyaXB0aW9uEiUKDmVsaWdpYmxlX3JvbGVzGA0gAygJ'
    'Ug1lbGlnaWJsZVJvbGVzEioKDmVsaWdpYmxlX3ZvdGVzGAQgASgNSABSDWVsaWdpYmxlVm90ZX'
    'OIAQESNwoMcGFzc2luZ19ydWxlGAcgASgLMhQuY2hhdC52MS5QYXNzaW5nUnVsZVILcGFzc2lu'
    'Z1J1bGUSLQoHY2hvaWNlcxgIIAMoCzITLmNoYXQudjEuVm90ZUNob2ljZVIHY2hvaWNlcxIgCg'
    'ljbG9zZXNfYXQYDCABKANIAVIIY2xvc2VzQXSIAQFCEQoPX2VsaWdpYmxlX3ZvdGVzQgwKCl9j'
    'bG9zZXNfYXQ=');

@$core.Deprecated('Use voteChoiceDescriptor instead')
const VoteChoice$json = {
  '1': 'VoteChoice',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'description', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'description', '17': true},
  ],
  '8': [
    {'1': '_description'},
  ],
};

/// Descriptor for `VoteChoice`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List voteChoiceDescriptor = $convert.base64Decode(
    'CgpWb3RlQ2hvaWNlEg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEiUKC2Rlc2'
    'NyaXB0aW9uGAMgASgJSABSC2Rlc2NyaXB0aW9uiAEBQg4KDF9kZXNjcmlwdGlvbg==');

@$core.Deprecated('Use passingRuleDescriptor instead')
const PassingRule$json = {
  '1': 'PassingRule',
  '2': [
    {'1': 'absolute', '3': 1, '4': 1, '5': 13, '9': 0, '10': 'absolute'},
    {'1': 'percentage', '3': 2, '4': 1, '5': 13, '9': 0, '10': 'percentage'},
    {'1': 'passing_choice_id', '3': 3, '4': 1, '5': 9, '10': 'passingChoiceId'},
  ],
  '8': [
    {'1': 'rule'},
  ],
};

/// Descriptor for `PassingRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List passingRuleDescriptor = $convert.base64Decode(
    'CgtQYXNzaW5nUnVsZRIcCghhYnNvbHV0ZRgBIAEoDUgAUghhYnNvbHV0ZRIgCgpwZXJjZW50YW'
    'dlGAIgASgNSABSCnBlcmNlbnRhZ2USKgoRcGFzc2luZ19jaG9pY2VfaWQYAyABKAlSD3Bhc3Np'
    'bmdDaG9pY2VJZEIGCgRydWxl');

@$core.Deprecated('Use voteCastDescriptor instead')
const VoteCast$json = {
  '1': 'VoteCast',
  '2': [
    {'1': 'motion_id', '3': 1, '4': 1, '5': 9, '10': 'motionId'},
    {'1': 'choice_id', '3': 2, '4': 1, '5': 9, '10': 'choiceId'},
  ],
};

/// Descriptor for `VoteCast`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List voteCastDescriptor = $convert.base64Decode(
    'CghWb3RlQ2FzdBIbCgltb3Rpb25faWQYASABKAlSCG1vdGlvbklkEhsKCWNob2ljZV9pZBgCIA'
    'EoCVIIY2hvaWNlSWQ=');

@$core.Deprecated('Use voteTallyDescriptor instead')
const VoteTally$json = {
  '1': 'VoteTally',
  '2': [
    {'1': 'choice_id', '3': 1, '4': 1, '5': 9, '10': 'choiceId'},
    {'1': 'count', '3': 2, '4': 1, '5': 13, '10': 'count'},
  ],
};

/// Descriptor for `VoteTally`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List voteTallyDescriptor = $convert.base64Decode(
    'CglWb3RlVGFsbHkSGwoJY2hvaWNlX2lkGAEgASgJUghjaG9pY2VJZBIUCgVjb3VudBgCIAEoDV'
    'IFY291bnQ=');

@$core.Deprecated('Use motionTallyDescriptor instead')
const MotionTally$json = {
  '1': 'MotionTally',
  '2': [
    {'1': 'motion_id', '3': 1, '4': 1, '5': 9, '10': 'motionId'},
    {'1': 'eligible_votes', '3': 2, '4': 1, '5': 13, '10': 'eligibleVotes'},
    {'1': 'tallies', '3': 3, '4': 3, '5': 11, '6': '.chat.v1.VoteTally', '10': 'tallies'},
    {'1': 'total_votes_cast', '3': 4, '4': 1, '5': 13, '10': 'totalVotesCast'},
    {'1': 'dead_votes', '3': 6, '4': 1, '5': 13, '10': 'deadVotes'},
    {'1': 'target_votes', '3': 7, '4': 1, '5': 13, '10': 'targetVotes'},
    {'1': 'passed', '3': 8, '4': 1, '5': 8, '10': 'passed'},
    {'1': 'closed', '3': 9, '4': 1, '5': 8, '10': 'closed'},
  ],
};

/// Descriptor for `MotionTally`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List motionTallyDescriptor = $convert.base64Decode(
    'CgtNb3Rpb25UYWxseRIbCgltb3Rpb25faWQYASABKAlSCG1vdGlvbklkEiUKDmVsaWdpYmxlX3'
    'ZvdGVzGAIgASgNUg1lbGlnaWJsZVZvdGVzEiwKB3RhbGxpZXMYAyADKAsyEi5jaGF0LnYxLlZv'
    'dGVUYWxseVIHdGFsbGllcxIoChB0b3RhbF92b3Rlc19jYXN0GAQgASgNUg50b3RhbFZvdGVzQ2'
    'FzdBIdCgpkZWFkX3ZvdGVzGAYgASgNUglkZWFkVm90ZXMSIQoMdGFyZ2V0X3ZvdGVzGAcgASgN'
    'Ugt0YXJnZXRWb3RlcxIWCgZwYXNzZWQYCCABKAhSBnBhc3NlZBIWCgZjbG9zZWQYCSABKAhSBm'
    'Nsb3NlZA==');

@$core.Deprecated('Use formValidationRuleDescriptor instead')
const FormValidationRule$json = {
  '1': 'FormValidationRule',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 9, '10': 'code'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'required', '3': 3, '4': 1, '5': 8, '9': 0, '10': 'required'},
    {'1': 'min_length', '3': 4, '4': 1, '5': 5, '9': 0, '10': 'minLength'},
    {'1': 'max_length', '3': 5, '4': 1, '5': 5, '9': 0, '10': 'maxLength'},
    {'1': 'min_value', '3': 6, '4': 1, '5': 1, '9': 0, '10': 'minValue'},
    {'1': 'max_value', '3': 7, '4': 1, '5': 1, '9': 0, '10': 'maxValue'},
    {'1': 'pattern', '3': 8, '4': 1, '5': 9, '9': 0, '10': 'pattern'},
    {'1': 'min_items', '3': 9, '4': 1, '5': 5, '9': 0, '10': 'minItems'},
    {'1': 'max_items', '3': 10, '4': 1, '5': 5, '9': 0, '10': 'maxItems'},
  ],
  '8': [
    {'1': 'rule'},
  ],
};

/// Descriptor for `FormValidationRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formValidationRuleDescriptor = $convert.base64Decode(
    'ChJGb3JtVmFsaWRhdGlvblJ1bGUSEgoEY29kZRgBIAEoCVIEY29kZRIYCgdtZXNzYWdlGAIgAS'
    'gJUgdtZXNzYWdlEhwKCHJlcXVpcmVkGAMgASgISABSCHJlcXVpcmVkEh8KCm1pbl9sZW5ndGgY'
    'BCABKAVIAFIJbWluTGVuZ3RoEh8KCm1heF9sZW5ndGgYBSABKAVIAFIJbWF4TGVuZ3RoEh0KCW'
    '1pbl92YWx1ZRgGIAEoAUgAUghtaW5WYWx1ZRIdCgltYXhfdmFsdWUYByABKAFIAFIIbWF4VmFs'
    'dWUSGgoHcGF0dGVybhgIIAEoCUgAUgdwYXR0ZXJuEh0KCW1pbl9pdGVtcxgJIAEoBUgAUghtaW'
    '5JdGVtcxIdCgltYXhfaXRlbXMYCiABKAVIAFIIbWF4SXRlbXNCBgoEcnVsZQ==');

@$core.Deprecated('Use formConditionClauseDescriptor instead')
const FormConditionClause$json = {
  '1': 'FormConditionClause',
  '2': [
    {'1': 'field_key', '3': 1, '4': 1, '5': 9, '10': 'fieldKey'},
    {'1': 'operator', '3': 2, '4': 1, '5': 14, '6': '.chat.v1.FormConditionOperator', '10': 'operator'},
    {'1': 'value', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.Value', '10': 'value'},
    {'1': 'values', '3': 4, '4': 3, '5': 11, '6': '.google.protobuf.Value', '10': 'values'},
  ],
};

/// Descriptor for `FormConditionClause`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formConditionClauseDescriptor = $convert.base64Decode(
    'ChNGb3JtQ29uZGl0aW9uQ2xhdXNlEhsKCWZpZWxkX2tleRgBIAEoCVIIZmllbGRLZXkSOgoIb3'
    'BlcmF0b3IYAiABKA4yHi5jaGF0LnYxLkZvcm1Db25kaXRpb25PcGVyYXRvclIIb3BlcmF0b3IS'
    'LAoFdmFsdWUYAyABKAsyFi5nb29nbGUucHJvdG9idWYuVmFsdWVSBXZhbHVlEi4KBnZhbHVlcx'
    'gEIAMoCzIWLmdvb2dsZS5wcm90b2J1Zi5WYWx1ZVIGdmFsdWVz');

@$core.Deprecated('Use formConditionGroupDescriptor instead')
const FormConditionGroup$json = {
  '1': 'FormConditionGroup',
  '2': [
    {'1': 'all', '3': 1, '4': 3, '5': 11, '6': '.chat.v1.FormConditionClause', '10': 'all'},
    {'1': 'any', '3': 2, '4': 3, '5': 11, '6': '.chat.v1.FormConditionClause', '10': 'any'},
  ],
};

/// Descriptor for `FormConditionGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formConditionGroupDescriptor = $convert.base64Decode(
    'ChJGb3JtQ29uZGl0aW9uR3JvdXASLgoDYWxsGAEgAygLMhwuY2hhdC52MS5Gb3JtQ29uZGl0aW'
    '9uQ2xhdXNlUgNhbGwSLgoDYW55GAIgAygLMhwuY2hhdC52MS5Gb3JtQ29uZGl0aW9uQ2xhdXNl'
    'UgNhbnk=');

@$core.Deprecated('Use formOptionDescriptor instead')
const FormOption$json = {
  '1': 'FormOption',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'help_text', '3': 3, '4': 1, '5': 9, '10': 'helpText'},
    {'1': 'disabled', '3': 4, '4': 1, '5': 8, '10': 'disabled'},
    {'1': 'metadata', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'metadata'},
  ],
};

/// Descriptor for `FormOption`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formOptionDescriptor = $convert.base64Decode(
    'CgpGb3JtT3B0aW9uEhQKBXZhbHVlGAEgASgJUgV2YWx1ZRIUCgVsYWJlbBgCIAEoCVIFbGFiZW'
    'wSGwoJaGVscF90ZXh0GAMgASgJUghoZWxwVGV4dBIaCghkaXNhYmxlZBgEIAEoCFIIZGlzYWJs'
    'ZWQSMwoIbWV0YWRhdGEYBSABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0UghtZXRhZGF0YQ'
    '==');

@$core.Deprecated('Use formFormattingHintDescriptor instead')
const FormFormattingHint$json = {
  '1': 'FormFormattingHint',
  '2': [
    {'1': 'input_mask', '3': 1, '4': 1, '5': 9, '10': 'inputMask'},
    {'1': 'display_format', '3': 2, '4': 1, '5': 9, '10': 'displayFormat'},
    {'1': 'currency_code', '3': 3, '4': 1, '5': 9, '10': 'currencyCode'},
    {'1': 'decimal_scale', '3': 4, '4': 1, '5': 5, '10': 'decimalScale'},
    {'1': 'keyboard', '3': 5, '4': 1, '5': 9, '10': 'keyboard'},
    {'1': 'autocomplete', '3': 6, '4': 1, '5': 9, '10': 'autocomplete'},
  ],
};

/// Descriptor for `FormFormattingHint`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formFormattingHintDescriptor = $convert.base64Decode(
    'ChJGb3JtRm9ybWF0dGluZ0hpbnQSHQoKaW5wdXRfbWFzaxgBIAEoCVIJaW5wdXRNYXNrEiUKDm'
    'Rpc3BsYXlfZm9ybWF0GAIgASgJUg1kaXNwbGF5Rm9ybWF0EiMKDWN1cnJlbmN5X2NvZGUYAyAB'
    'KAlSDGN1cnJlbmN5Q29kZRIjCg1kZWNpbWFsX3NjYWxlGAQgASgFUgxkZWNpbWFsU2NhbGUSGg'
    'oIa2V5Ym9hcmQYBSABKAlSCGtleWJvYXJkEiIKDGF1dG9jb21wbGV0ZRgGIAEoCVIMYXV0b2Nv'
    'bXBsZXRl');

@$core.Deprecated('Use formReviewHintDescriptor instead')
const FormReviewHint$json = {
  '1': 'FormReviewHint',
  '2': [
    {'1': 'include_in_review', '3': 1, '4': 1, '5': 8, '10': 'includeInReview'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'section_label', '3': 3, '4': 1, '5': 9, '10': 'sectionLabel'},
    {'1': 'formatter', '3': 4, '4': 1, '5': 9, '10': 'formatter'},
    {'1': 'order', '3': 5, '4': 1, '5': 5, '10': 'order'},
  ],
};

/// Descriptor for `FormReviewHint`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formReviewHintDescriptor = $convert.base64Decode(
    'Cg5Gb3JtUmV2aWV3SGludBIqChFpbmNsdWRlX2luX3JldmlldxgBIAEoCFIPaW5jbHVkZUluUm'
    'V2aWV3EhQKBWxhYmVsGAIgASgJUgVsYWJlbBIjCg1zZWN0aW9uX2xhYmVsGAMgASgJUgxzZWN0'
    'aW9uTGFiZWwSHAoJZm9ybWF0dGVyGAQgASgJUglmb3JtYXR0ZXISFAoFb3JkZXIYBSABKAVSBW'
    '9yZGVy');

@$core.Deprecated('Use formFieldDescriptor instead')
const FormField$json = {
  '1': 'FormField',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'type', '3': 2, '4': 1, '5': 14, '6': '.chat.v1.FormFieldType', '10': 'type'},
    {'1': 'label', '3': 3, '4': 1, '5': 9, '10': 'label'},
    {'1': 'help_text', '3': 4, '4': 1, '5': 9, '10': 'helpText'},
    {'1': 'placeholder', '3': 5, '4': 1, '5': 9, '10': 'placeholder'},
    {'1': 'required', '3': 6, '4': 1, '5': 8, '10': 'required'},
    {'1': 'default_value', '3': 7, '4': 1, '5': 11, '6': '.google.protobuf.Value', '10': 'defaultValue'},
    {'1': 'validation_rules', '3': 8, '4': 3, '5': 11, '6': '.chat.v1.FormValidationRule', '10': 'validationRules'},
    {'1': 'visibility_condition', '3': 9, '4': 1, '5': 11, '6': '.chat.v1.FormConditionGroup', '10': 'visibilityCondition'},
    {'1': 'editability_condition', '3': 10, '4': 1, '5': 11, '6': '.chat.v1.FormConditionGroup', '10': 'editabilityCondition'},
    {'1': 'options', '3': 11, '4': 3, '5': 11, '6': '.chat.v1.FormOption', '10': 'options'},
    {'1': 'nested_fields', '3': 12, '4': 3, '5': 11, '6': '.chat.v1.FormField', '10': 'nestedFields'},
    {'1': 'nested_sections', '3': 13, '4': 3, '5': 11, '6': '.chat.v1.FormSection', '10': 'nestedSections'},
    {'1': 'formatting', '3': 14, '4': 1, '5': 11, '6': '.chat.v1.FormFormattingHint', '10': 'formatting'},
    {'1': 'ui_hints', '3': 15, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'uiHints'},
    {'1': 'review', '3': 16, '4': 1, '5': 11, '6': '.chat.v1.FormReviewHint', '10': 'review'},
    {'1': 'visible_to_roles', '3': 17, '4': 3, '5': 9, '10': 'visibleToRoles'},
    {'1': 'repeatable', '3': 18, '4': 1, '5': 8, '10': 'repeatable'},
    {'1': 'hidden', '3': 19, '4': 1, '5': 8, '10': 'hidden'},
  ],
};

/// Descriptor for `FormField`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formFieldDescriptor = $convert.base64Decode(
    'CglGb3JtRmllbGQSEAoDa2V5GAEgASgJUgNrZXkSKgoEdHlwZRgCIAEoDjIWLmNoYXQudjEuRm'
    '9ybUZpZWxkVHlwZVIEdHlwZRIUCgVsYWJlbBgDIAEoCVIFbGFiZWwSGwoJaGVscF90ZXh0GAQg'
    'ASgJUghoZWxwVGV4dBIgCgtwbGFjZWhvbGRlchgFIAEoCVILcGxhY2Vob2xkZXISGgoIcmVxdW'
    'lyZWQYBiABKAhSCHJlcXVpcmVkEjsKDWRlZmF1bHRfdmFsdWUYByABKAsyFi5nb29nbGUucHJv'
    'dG9idWYuVmFsdWVSDGRlZmF1bHRWYWx1ZRJGChB2YWxpZGF0aW9uX3J1bGVzGAggAygLMhsuY2'
    'hhdC52MS5Gb3JtVmFsaWRhdGlvblJ1bGVSD3ZhbGlkYXRpb25SdWxlcxJOChR2aXNpYmlsaXR5'
    'X2NvbmRpdGlvbhgJIAEoCzIbLmNoYXQudjEuRm9ybUNvbmRpdGlvbkdyb3VwUhN2aXNpYmlsaX'
    'R5Q29uZGl0aW9uElAKFWVkaXRhYmlsaXR5X2NvbmRpdGlvbhgKIAEoCzIbLmNoYXQudjEuRm9y'
    'bUNvbmRpdGlvbkdyb3VwUhRlZGl0YWJpbGl0eUNvbmRpdGlvbhItCgdvcHRpb25zGAsgAygLMh'
    'MuY2hhdC52MS5Gb3JtT3B0aW9uUgdvcHRpb25zEjcKDW5lc3RlZF9maWVsZHMYDCADKAsyEi5j'
    'aGF0LnYxLkZvcm1GaWVsZFIMbmVzdGVkRmllbGRzEj0KD25lc3RlZF9zZWN0aW9ucxgNIAMoCz'
    'IULmNoYXQudjEuRm9ybVNlY3Rpb25SDm5lc3RlZFNlY3Rpb25zEjsKCmZvcm1hdHRpbmcYDiAB'
    'KAsyGy5jaGF0LnYxLkZvcm1Gb3JtYXR0aW5nSGludFIKZm9ybWF0dGluZxIyCgh1aV9oaW50cx'
    'gPIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RSB3VpSGludHMSLwoGcmV2aWV3GBAgASgL'
    'MhcuY2hhdC52MS5Gb3JtUmV2aWV3SGludFIGcmV2aWV3EigKEHZpc2libGVfdG9fcm9sZXMYES'
    'ADKAlSDnZpc2libGVUb1JvbGVzEh4KCnJlcGVhdGFibGUYEiABKAhSCnJlcGVhdGFibGUSFgoG'
    'aGlkZGVuGBMgASgIUgZoaWRkZW4=');

@$core.Deprecated('Use formSectionDescriptor instead')
const FormSection$json = {
  '1': 'FormSection',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'description', '3': 3, '4': 1, '5': 9, '10': 'description'},
    {'1': 'fields', '3': 4, '4': 3, '5': 11, '6': '.chat.v1.FormField', '10': 'fields'},
    {'1': 'ui_hints', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'uiHints'},
  ],
};

/// Descriptor for `FormSection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formSectionDescriptor = $convert.base64Decode(
    'CgtGb3JtU2VjdGlvbhIOCgJpZBgBIAEoCVICaWQSFAoFdGl0bGUYAiABKAlSBXRpdGxlEiAKC2'
    'Rlc2NyaXB0aW9uGAMgASgJUgtkZXNjcmlwdGlvbhIqCgZmaWVsZHMYBCADKAsyEi5jaGF0LnYx'
    'LkZvcm1GaWVsZFIGZmllbGRzEjIKCHVpX2hpbnRzGAUgASgLMhcuZ29vZ2xlLnByb3RvYnVmLl'
    'N0cnVjdFIHdWlIaW50cw==');

@$core.Deprecated('Use formStepDescriptor instead')
const FormStep$json = {
  '1': 'FormStep',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'description', '3': 3, '4': 1, '5': 9, '10': 'description'},
    {'1': 'sections', '3': 4, '4': 3, '5': 11, '6': '.chat.v1.FormSection', '10': 'sections'},
    {'1': 'ui_hints', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'uiHints'},
    {'1': 'visibility_condition', '3': 6, '4': 1, '5': 11, '6': '.chat.v1.FormConditionGroup', '10': 'visibilityCondition'},
  ],
};

/// Descriptor for `FormStep`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formStepDescriptor = $convert.base64Decode(
    'CghGb3JtU3RlcBIOCgJpZBgBIAEoCVICaWQSFAoFdGl0bGUYAiABKAlSBXRpdGxlEiAKC2Rlc2'
    'NyaXB0aW9uGAMgASgJUgtkZXNjcmlwdGlvbhIwCghzZWN0aW9ucxgEIAMoCzIULmNoYXQudjEu'
    'Rm9ybVNlY3Rpb25SCHNlY3Rpb25zEjIKCHVpX2hpbnRzGAUgASgLMhcuZ29vZ2xlLnByb3RvYn'
    'VmLlN0cnVjdFIHdWlIaW50cxJOChR2aXNpYmlsaXR5X2NvbmRpdGlvbhgGIAEoCzIbLmNoYXQu'
    'djEuRm9ybUNvbmRpdGlvbkdyb3VwUhN2aXNpYmlsaXR5Q29uZGl0aW9u');

@$core.Deprecated('Use formSchemaDescriptor instead')
const FormSchema$json = {
  '1': 'FormSchema',
  '2': [
    {'1': 'form_id', '3': 1, '4': 1, '5': 9, '10': 'formId'},
    {'1': 'form_version', '3': 2, '4': 1, '5': 5, '10': 'formVersion'},
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'subtitle', '3': 4, '4': 1, '5': 9, '10': 'subtitle'},
    {'1': 'description', '3': 5, '4': 1, '5': 9, '10': 'description'},
    {'1': 'steps', '3': 6, '4': 3, '5': 11, '6': '.chat.v1.FormStep', '10': 'steps'},
    {'1': 'workflow_metadata', '3': 7, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'workflowMetadata'},
    {'1': 'ui_hints', '3': 8, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'uiHints'},
  ],
};

/// Descriptor for `FormSchema`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formSchemaDescriptor = $convert.base64Decode(
    'CgpGb3JtU2NoZW1hEhcKB2Zvcm1faWQYASABKAlSBmZvcm1JZBIhCgxmb3JtX3ZlcnNpb24YAi'
    'ABKAVSC2Zvcm1WZXJzaW9uEhQKBXRpdGxlGAMgASgJUgV0aXRsZRIaCghzdWJ0aXRsZRgEIAEo'
    'CVIIc3VidGl0bGUSIAoLZGVzY3JpcHRpb24YBSABKAlSC2Rlc2NyaXB0aW9uEicKBXN0ZXBzGA'
    'YgAygLMhEuY2hhdC52MS5Gb3JtU3RlcFIFc3RlcHMSRAoRd29ya2Zsb3dfbWV0YWRhdGEYByAB'
    'KAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0UhB3b3JrZmxvd01ldGFkYXRhEjIKCHVpX2hpbn'
    'RzGAggASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIHdWlIaW50cw==');

@$core.Deprecated('Use formPermissionsDescriptor instead')
const FormPermissions$json = {
  '1': 'FormPermissions',
  '2': [
    {'1': 'can_edit', '3': 1, '4': 1, '5': 8, '10': 'canEdit'},
    {'1': 'can_submit', '3': 2, '4': 1, '5': 8, '10': 'canSubmit'},
    {'1': 'can_save_draft', '3': 3, '4': 1, '5': 8, '10': 'canSaveDraft'},
    {'1': 'can_go_back', '3': 4, '4': 1, '5': 8, '10': 'canGoBack'},
    {'1': 'assignee_subscription_id', '3': 5, '4': 1, '5': 9, '10': 'assigneeSubscriptionId'},
  ],
};

/// Descriptor for `FormPermissions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formPermissionsDescriptor = $convert.base64Decode(
    'Cg9Gb3JtUGVybWlzc2lvbnMSGQoIY2FuX2VkaXQYASABKAhSB2NhbkVkaXQSHQoKY2FuX3N1Ym'
    '1pdBgCIAEoCFIJY2FuU3VibWl0EiQKDmNhbl9zYXZlX2RyYWZ0GAMgASgIUgxjYW5TYXZlRHJh'
    'ZnQSHgoLY2FuX2dvX2JhY2sYBCABKAhSCWNhbkdvQmFjaxI4Chhhc3NpZ25lZV9zdWJzY3JpcH'
    'Rpb25faWQYBSABKAlSFmFzc2lnbmVlU3Vic2NyaXB0aW9uSWQ=');

@$core.Deprecated('Use formReviewItemDescriptor instead')
const FormReviewItem$json = {
  '1': 'FormReviewItem',
  '2': [
    {'1': 'field_key', '3': 1, '4': 1, '5': 9, '10': 'fieldKey'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'display_value', '3': 3, '4': 1, '5': 9, '10': 'displayValue'},
    {'1': 'emphasized', '3': 4, '4': 1, '5': 8, '10': 'emphasized'},
  ],
};

/// Descriptor for `FormReviewItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formReviewItemDescriptor = $convert.base64Decode(
    'Cg5Gb3JtUmV2aWV3SXRlbRIbCglmaWVsZF9rZXkYASABKAlSCGZpZWxkS2V5EhQKBWxhYmVsGA'
    'IgASgJUgVsYWJlbBIjCg1kaXNwbGF5X3ZhbHVlGAMgASgJUgxkaXNwbGF5VmFsdWUSHgoKZW1w'
    'aGFzaXplZBgEIAEoCFIKZW1waGFzaXplZA==');

@$core.Deprecated('Use formReviewSectionDescriptor instead')
const FormReviewSection$json = {
  '1': 'FormReviewSection',
  '2': [
    {'1': 'step_id', '3': 1, '4': 1, '5': 9, '10': 'stepId'},
    {'1': 'step_title', '3': 2, '4': 1, '5': 9, '10': 'stepTitle'},
    {'1': 'section_id', '3': 3, '4': 1, '5': 9, '10': 'sectionId'},
    {'1': 'section_title', '3': 4, '4': 1, '5': 9, '10': 'sectionTitle'},
    {'1': 'items', '3': 5, '4': 3, '5': 11, '6': '.chat.v1.FormReviewItem', '10': 'items'},
  ],
};

/// Descriptor for `FormReviewSection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formReviewSectionDescriptor = $convert.base64Decode(
    'ChFGb3JtUmV2aWV3U2VjdGlvbhIXCgdzdGVwX2lkGAEgASgJUgZzdGVwSWQSHQoKc3RlcF90aX'
    'RsZRgCIAEoCVIJc3RlcFRpdGxlEh0KCnNlY3Rpb25faWQYAyABKAlSCXNlY3Rpb25JZBIjCg1z'
    'ZWN0aW9uX3RpdGxlGAQgASgJUgxzZWN0aW9uVGl0bGUSLQoFaXRlbXMYBSADKAsyFy5jaGF0Ln'
    'YxLkZvcm1SZXZpZXdJdGVtUgVpdGVtcw==');

@$core.Deprecated('Use formSubmissionSnapshotDescriptor instead')
const FormSubmissionSnapshot$json = {
  '1': 'FormSubmissionSnapshot',
  '2': [
    {'1': 'form_instance_id', '3': 1, '4': 1, '5': 9, '10': 'formInstanceId'},
    {'1': 'schema_id', '3': 2, '4': 1, '5': 9, '10': 'schemaId'},
    {'1': 'schema_version', '3': 3, '4': 1, '5': 5, '10': 'schemaVersion'},
    {'1': 'submitted_at', '3': 4, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'submittedAt'},
    {'1': 'submitted_by_subscription_id', '3': 5, '4': 1, '5': 9, '10': 'submittedBySubscriptionId'},
    {'1': 'answers', '3': 6, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'answers'},
    {'1': 'formatted_sections', '3': 7, '4': 3, '5': 11, '6': '.chat.v1.FormReviewSection', '10': 'formattedSections'},
    {'1': 'submission_reference', '3': 8, '4': 1, '5': 9, '10': 'submissionReference'},
    {'1': 'status', '3': 9, '4': 1, '5': 14, '6': '.chat.v1.FormMessageState', '10': 'status'},
    {'1': 'backend_message', '3': 10, '4': 1, '5': 9, '10': 'backendMessage'},
    {'1': 'workflow_message', '3': 11, '4': 1, '5': 9, '10': 'workflowMessage'},
    {'1': 'metadata', '3': 12, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'metadata'},
  ],
};

/// Descriptor for `FormSubmissionSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formSubmissionSnapshotDescriptor = $convert.base64Decode(
    'ChZGb3JtU3VibWlzc2lvblNuYXBzaG90EigKEGZvcm1faW5zdGFuY2VfaWQYASABKAlSDmZvcm'
    '1JbnN0YW5jZUlkEhsKCXNjaGVtYV9pZBgCIAEoCVIIc2NoZW1hSWQSJQoOc2NoZW1hX3ZlcnNp'
    'b24YAyABKAVSDXNjaGVtYVZlcnNpb24SPQoMc3VibWl0dGVkX2F0GAQgASgLMhouZ29vZ2xlLn'
    'Byb3RvYnVmLlRpbWVzdGFtcFILc3VibWl0dGVkQXQSPwocc3VibWl0dGVkX2J5X3N1YnNjcmlw'
    'dGlvbl9pZBgFIAEoCVIZc3VibWl0dGVkQnlTdWJzY3JpcHRpb25JZBIxCgdhbnN3ZXJzGAYgAS'
    'gLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIHYW5zd2VycxJJChJmb3JtYXR0ZWRfc2VjdGlv'
    'bnMYByADKAsyGi5jaGF0LnYxLkZvcm1SZXZpZXdTZWN0aW9uUhFmb3JtYXR0ZWRTZWN0aW9ucx'
    'IxChRzdWJtaXNzaW9uX3JlZmVyZW5jZRgIIAEoCVITc3VibWlzc2lvblJlZmVyZW5jZRIxCgZz'
    'dGF0dXMYCSABKA4yGS5jaGF0LnYxLkZvcm1NZXNzYWdlU3RhdGVSBnN0YXR1cxInCg9iYWNrZW'
    '5kX21lc3NhZ2UYCiABKAlSDmJhY2tlbmRNZXNzYWdlEikKEHdvcmtmbG93X21lc3NhZ2UYCyAB'
    'KAlSD3dvcmtmbG93TWVzc2FnZRIzCghtZXRhZGF0YRgMIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi'
    '5TdHJ1Y3RSCG1ldGFkYXRh');

@$core.Deprecated('Use formRequestContentDescriptor instead')
const FormRequestContent$json = {
  '1': 'FormRequestContent',
  '2': [
    {'1': 'form_instance_id', '3': 1, '4': 1, '5': 9, '10': 'formInstanceId'},
    {'1': 'schema_id', '3': 2, '4': 1, '5': 9, '10': 'schemaId'},
    {'1': 'schema_version', '3': 3, '4': 1, '5': 5, '10': 'schemaVersion'},
    {'1': 'title', '3': 4, '4': 1, '5': 9, '10': 'title'},
    {'1': 'description', '3': 5, '4': 1, '5': 9, '10': 'description'},
    {'1': 'state', '3': 6, '4': 1, '5': 14, '6': '.chat.v1.FormMessageState', '10': 'state'},
    {'1': 'review_required', '3': 7, '4': 1, '5': 8, '10': 'reviewRequired'},
    {'1': 'schema', '3': 8, '4': 1, '5': 11, '6': '.chat.v1.FormSchema', '10': 'schema'},
    {'1': 'initial_values', '3': 9, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'initialValues'},
    {'1': 'server_draft_values', '3': 10, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'serverDraftValues'},
    {'1': 'final_submission_snapshot', '3': 11, '4': 1, '5': 11, '6': '.chat.v1.FormSubmissionSnapshot', '10': 'finalSubmissionSnapshot'},
    {'1': 'permissions', '3': 12, '4': 1, '5': 11, '6': '.chat.v1.FormPermissions', '10': 'permissions'},
    {'1': 'expires_at', '3': 13, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'expiresAt'},
    {'1': 'workflow_context', '3': 14, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'workflowContext'},
    {'1': 'current_workflow_state', '3': 15, '4': 1, '5': 9, '10': 'currentWorkflowState'},
  ],
};

/// Descriptor for `FormRequestContent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formRequestContentDescriptor = $convert.base64Decode(
    'ChJGb3JtUmVxdWVzdENvbnRlbnQSKAoQZm9ybV9pbnN0YW5jZV9pZBgBIAEoCVIOZm9ybUluc3'
    'RhbmNlSWQSGwoJc2NoZW1hX2lkGAIgASgJUghzY2hlbWFJZBIlCg5zY2hlbWFfdmVyc2lvbhgD'
    'IAEoBVINc2NoZW1hVmVyc2lvbhIUCgV0aXRsZRgEIAEoCVIFdGl0bGUSIAoLZGVzY3JpcHRpb2'
    '4YBSABKAlSC2Rlc2NyaXB0aW9uEi8KBXN0YXRlGAYgASgOMhkuY2hhdC52MS5Gb3JtTWVzc2Fn'
    'ZVN0YXRlUgVzdGF0ZRInCg9yZXZpZXdfcmVxdWlyZWQYByABKAhSDnJldmlld1JlcXVpcmVkEi'
    'sKBnNjaGVtYRgIIAEoCzITLmNoYXQudjEuRm9ybVNjaGVtYVIGc2NoZW1hEj4KDmluaXRpYWxf'
    'dmFsdWVzGAkgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFINaW5pdGlhbFZhbHVlcxJHCh'
    'NzZXJ2ZXJfZHJhZnRfdmFsdWVzGAogASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIRc2Vy'
    'dmVyRHJhZnRWYWx1ZXMSWwoZZmluYWxfc3VibWlzc2lvbl9zbmFwc2hvdBgLIAEoCzIfLmNoYX'
    'QudjEuRm9ybVN1Ym1pc3Npb25TbmFwc2hvdFIXZmluYWxTdWJtaXNzaW9uU25hcHNob3QSOgoL'
    'cGVybWlzc2lvbnMYDCABKAsyGC5jaGF0LnYxLkZvcm1QZXJtaXNzaW9uc1ILcGVybWlzc2lvbn'
    'MSOQoKZXhwaXJlc19hdBgNIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCWV4cGly'
    'ZXNBdBJCChB3b3JrZmxvd19jb250ZXh0GA4gASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdF'
    'IPd29ya2Zsb3dDb250ZXh0EjQKFmN1cnJlbnRfd29ya2Zsb3dfc3RhdGUYDyABKAlSFGN1cnJl'
    'bnRXb3JrZmxvd1N0YXRl');

@$core.Deprecated('Use formSubmissionResultContentDescriptor instead')
const FormSubmissionResultContent$json = {
  '1': 'FormSubmissionResultContent',
  '2': [
    {'1': 'form_instance_id', '3': 1, '4': 1, '5': 9, '10': 'formInstanceId'},
    {'1': 'schema_id', '3': 2, '4': 1, '5': 9, '10': 'schemaId'},
    {'1': 'schema_version', '3': 3, '4': 1, '5': 5, '10': 'schemaVersion'},
    {'1': 'source_event_id', '3': 4, '4': 1, '5': 9, '10': 'sourceEventId'},
    {'1': 'state', '3': 5, '4': 1, '5': 14, '6': '.chat.v1.FormMessageState', '10': 'state'},
    {'1': 'review_confirmed', '3': 6, '4': 1, '5': 8, '10': 'reviewConfirmed'},
    {'1': 'submission_snapshot', '3': 7, '4': 1, '5': 11, '6': '.chat.v1.FormSubmissionSnapshot', '10': 'submissionSnapshot'},
    {'1': 'metadata', '3': 8, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'metadata'},
  ],
};

/// Descriptor for `FormSubmissionResultContent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formSubmissionResultContentDescriptor = $convert.base64Decode(
    'ChtGb3JtU3VibWlzc2lvblJlc3VsdENvbnRlbnQSKAoQZm9ybV9pbnN0YW5jZV9pZBgBIAEoCV'
    'IOZm9ybUluc3RhbmNlSWQSGwoJc2NoZW1hX2lkGAIgASgJUghzY2hlbWFJZBIlCg5zY2hlbWFf'
    'dmVyc2lvbhgDIAEoBVINc2NoZW1hVmVyc2lvbhImCg9zb3VyY2VfZXZlbnRfaWQYBCABKAlSDX'
    'NvdXJjZUV2ZW50SWQSLwoFc3RhdGUYBSABKA4yGS5jaGF0LnYxLkZvcm1NZXNzYWdlU3RhdGVS'
    'BXN0YXRlEikKEHJldmlld19jb25maXJtZWQYBiABKAhSD3Jldmlld0NvbmZpcm1lZBJQChNzdW'
    'JtaXNzaW9uX3NuYXBzaG90GAcgASgLMh8uY2hhdC52MS5Gb3JtU3VibWlzc2lvblNuYXBzaG90'
    'UhJzdWJtaXNzaW9uU25hcHNob3QSMwoIbWV0YWRhdGEYCCABKAsyFy5nb29nbGUucHJvdG9idW'
    'YuU3RydWN0UghtZXRhZGF0YQ==');

@$core.Deprecated('Use payloadDescriptor instead')
const Payload$json = {
  '1': 'Payload',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 14, '6': '.chat.v1.PayloadType', '10': 'type'},
    {'1': 'default', '3': 7, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '9': 0, '10': 'default'},
    {'1': 'room_change', '3': 8, '4': 1, '5': 11, '6': '.chat.v1.RoomChangeContent', '9': 0, '10': 'roomChange'},
    {'1': 'moderation', '3': 10, '4': 1, '5': 11, '6': '.chat.v1.ModerationContent', '9': 0, '10': 'moderation'},
    {'1': 'text', '3': 15, '4': 1, '5': 11, '6': '.chat.v1.TextContent', '9': 0, '10': 'text'},
    {'1': 'attachment', '3': 16, '4': 1, '5': 11, '6': '.chat.v1.AttachmentContent', '9': 0, '10': 'attachment'},
    {'1': 'reaction', '3': 17, '4': 1, '5': 11, '6': '.chat.v1.ReactionContent', '9': 0, '10': 'reaction'},
    {'1': 'encrypted', '3': 18, '4': 1, '5': 11, '6': '.chat.v1.EncryptedContent', '9': 0, '10': 'encrypted'},
    {'1': 'call', '3': 19, '4': 1, '5': 11, '6': '.chat.v1.CallContent', '9': 0, '10': 'call'},
    {'1': 'motion', '3': 25, '4': 1, '5': 11, '6': '.chat.v1.MotionContent', '9': 0, '10': 'motion'},
    {'1': 'motion_tally', '3': 28, '4': 1, '5': 11, '6': '.chat.v1.MotionTally', '9': 0, '10': 'motionTally'},
    {'1': 'vote', '3': 26, '4': 1, '5': 11, '6': '.chat.v1.VoteCast', '9': 0, '10': 'vote'},
    {'1': 'vote_tally', '3': 29, '4': 1, '5': 11, '6': '.chat.v1.VoteTally', '9': 0, '10': 'voteTally'},
    {'1': 'form_request', '3': 30, '4': 1, '5': 11, '6': '.chat.v1.FormRequestContent', '9': 0, '10': 'formRequest'},
    {'1': 'form_submission_result', '3': 31, '4': 1, '5': 11, '6': '.chat.v1.FormSubmissionResultContent', '9': 0, '10': 'formSubmissionResult'},
  ],
  '8': [
    {'1': 'data'},
  ],
};

/// Descriptor for `Payload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List payloadDescriptor = $convert.base64Decode(
    'CgdQYXlsb2FkEigKBHR5cGUYASABKA4yFC5jaGF0LnYxLlBheWxvYWRUeXBlUgR0eXBlEjMKB2'
    'RlZmF1bHQYByABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0SABSB2RlZmF1bHQSPQoLcm9v'
    'bV9jaGFuZ2UYCCABKAsyGi5jaGF0LnYxLlJvb21DaGFuZ2VDb250ZW50SABSCnJvb21DaGFuZ2'
    'USPAoKbW9kZXJhdGlvbhgKIAEoCzIaLmNoYXQudjEuTW9kZXJhdGlvbkNvbnRlbnRIAFIKbW9k'
    'ZXJhdGlvbhIqCgR0ZXh0GA8gASgLMhQuY2hhdC52MS5UZXh0Q29udGVudEgAUgR0ZXh0EjwKCm'
    'F0dGFjaG1lbnQYECABKAsyGi5jaGF0LnYxLkF0dGFjaG1lbnRDb250ZW50SABSCmF0dGFjaG1l'
    'bnQSNgoIcmVhY3Rpb24YESABKAsyGC5jaGF0LnYxLlJlYWN0aW9uQ29udGVudEgAUghyZWFjdG'
    'lvbhI5CgllbmNyeXB0ZWQYEiABKAsyGS5jaGF0LnYxLkVuY3J5cHRlZENvbnRlbnRIAFIJZW5j'
    'cnlwdGVkEioKBGNhbGwYEyABKAsyFC5jaGF0LnYxLkNhbGxDb250ZW50SABSBGNhbGwSMAoGbW'
    '90aW9uGBkgASgLMhYuY2hhdC52MS5Nb3Rpb25Db250ZW50SABSBm1vdGlvbhI5Cgxtb3Rpb25f'
    'dGFsbHkYHCABKAsyFC5jaGF0LnYxLk1vdGlvblRhbGx5SABSC21vdGlvblRhbGx5EicKBHZvdG'
    'UYGiABKAsyES5jaGF0LnYxLlZvdGVDYXN0SABSBHZvdGUSMwoKdm90ZV90YWxseRgdIAEoCzIS'
    'LmNoYXQudjEuVm90ZVRhbGx5SABSCXZvdGVUYWxseRJACgxmb3JtX3JlcXVlc3QYHiABKAsyGy'
    '5jaGF0LnYxLkZvcm1SZXF1ZXN0Q29udGVudEgAUgtmb3JtUmVxdWVzdBJcChZmb3JtX3N1Ym1p'
    'c3Npb25fcmVzdWx0GB8gASgLMiQuY2hhdC52MS5Gb3JtU3VibWlzc2lvblJlc3VsdENvbnRlbn'
    'RIAFIUZm9ybVN1Ym1pc3Npb25SZXN1bHRCBgoEZGF0YQ==');

