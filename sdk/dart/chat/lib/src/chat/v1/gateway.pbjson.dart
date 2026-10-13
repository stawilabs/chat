// This is a generated file - do not edit.
//
// Generated from chat/v1/gateway.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

import '../../common/v1/common.pbjson.dart' as $2;
import '../../google/protobuf/struct.pbjson.dart' as $3;
import '../../google/protobuf/timestamp.pbjson.dart' as $0;
import 'definitions.pbjson.dart' as $1;
import 'payload_type.pbjson.dart' as $4;

@$core.Deprecated('Use streamHelloDescriptor instead')
const StreamHello$json = {
  '1': 'StreamHello',
  '2': [
    {'1': 'resume_token', '3': 1, '4': 1, '5': 9, '10': 'resumeToken'},
    {
      '1': 'capabilities',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.chat.v1.StreamHello.CapabilitiesEntry',
      '10': 'capabilities'
    },
    {
      '1': 'client_time',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'clientTime'
    },
  ],
  '3': [StreamHello_CapabilitiesEntry$json],
};

@$core.Deprecated('Use streamHelloDescriptor instead')
const StreamHello_CapabilitiesEntry$json = {
  '1': 'CapabilitiesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `StreamHello`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamHelloDescriptor = $convert.base64Decode(
    'CgtTdHJlYW1IZWxsbxIhCgxyZXN1bWVfdG9rZW4YASABKAlSC3Jlc3VtZVRva2VuEkoKDGNhcG'
    'FiaWxpdGllcxgCIAMoCzImLmNoYXQudjEuU3RyZWFtSGVsbG8uQ2FwYWJpbGl0aWVzRW50cnlS'
    'DGNhcGFiaWxpdGllcxI7CgtjbGllbnRfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW'
    '1lc3RhbXBSCmNsaWVudFRpbWUaPwoRQ2FwYWJpbGl0aWVzRW50cnkSEAoDa2V5GAEgASgJUgNr'
    'ZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AQ==');

@$core.Deprecated('Use streamRequestDescriptor instead')
const StreamRequest$json = {
  '1': 'StreamRequest',
  '2': [
    {
      '1': 'hello',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.StreamHello',
      '9': 0,
      '10': 'hello'
    },
    {
      '1': 'command',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.ClientCommand',
      '9': 0,
      '10': 'command'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `StreamRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamRequestDescriptor = $convert.base64Decode(
    'Cg1TdHJlYW1SZXF1ZXN0EiwKBWhlbGxvGAEgASgLMhQuY2hhdC52MS5TdHJlYW1IZWxsb0gAUg'
    'VoZWxsbxIyCgdjb21tYW5kGAwgASgLMhYuY2hhdC52MS5DbGllbnRDb21tYW5kSABSB2NvbW1h'
    'bmRCCQoHcGF5bG9hZA==');

@$core.Deprecated('Use streamResponseDescriptor instead')
const StreamResponse$json = {
  '1': 'StreamResponse',
  '2': [
    {'1': 'id', '3': 3, '4': 1, '5': 9, '8': {}, '10': 'id'},
    {
      '1': 'timestamp',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'timestamp'
    },
    {
      '1': 'message',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.RoomEvent',
      '9': 0,
      '10': 'message'
    },
    {
      '1': 'presence_event',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.PresenceEvent',
      '9': 0,
      '10': 'presenceEvent'
    },
    {
      '1': 'receipt_event',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.ReceiptEvent',
      '9': 0,
      '10': 'receiptEvent'
    },
    {
      '1': 'read_event',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.ReadMarker',
      '9': 0,
      '10': 'readEvent'
    },
    {
      '1': 'typing_event',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.chat.v1.TypingEvent',
      '9': 0,
      '10': 'typingEvent'
    },
    {
      '1': 'error',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.common.v1.ErrorDetail',
      '9': 0,
      '10': 'error'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `StreamResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamResponseDescriptor = $convert.base64Decode(
    'Cg5TdHJlYW1SZXNwb25zZRIrCgJpZBgDIAEoCUIbukgYchYQAxgoMhBbMC05YS16Xy1dezMsND'
    'B9UgJpZBI4Cgl0aW1lc3RhbXAYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgl0'
    'aW1lc3RhbXASLgoHbWVzc2FnZRgKIAEoCzISLmNoYXQudjEuUm9vbUV2ZW50SABSB21lc3NhZ2'
    'USPwoOcHJlc2VuY2VfZXZlbnQYDCABKAsyFi5jaGF0LnYxLlByZXNlbmNlRXZlbnRIAFINcHJl'
    'c2VuY2VFdmVudBI8Cg1yZWNlaXB0X2V2ZW50GA0gASgLMhUuY2hhdC52MS5SZWNlaXB0RXZlbn'
    'RIAFIMcmVjZWlwdEV2ZW50EjQKCnJlYWRfZXZlbnQYDyABKAsyEy5jaGF0LnYxLlJlYWRNYXJr'
    'ZXJIAFIJcmVhZEV2ZW50EjkKDHR5cGluZ19ldmVudBgRIAEoCzIULmNoYXQudjEuVHlwaW5nRX'
    'ZlbnRIAFILdHlwaW5nRXZlbnQSLgoFZXJyb3IYFCABKAsyFi5jb21tb24udjEuRXJyb3JEZXRh'
    'aWxIAFIFZXJyb3JCCQoHcGF5bG9hZA==');

const $core.Map<$core.String, $core.dynamic> GatewayServiceBase$json = {
  '1': 'GatewayService',
  '2': [
    {
      '1': 'Stream',
      '2': '.chat.v1.StreamRequest',
      '3': '.chat.v1.StreamResponse',
      '4': {},
      '5': true,
      '6': true
    },
  ],
  '3': {},
};

@$core.Deprecated('Use gatewayServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    GatewayServiceBase$messageJson = {
  '.chat.v1.StreamRequest': StreamRequest$json,
  '.chat.v1.StreamHello': StreamHello$json,
  '.chat.v1.StreamHello.CapabilitiesEntry': StreamHello_CapabilitiesEntry$json,
  '.google.protobuf.Timestamp': $0.Timestamp$json,
  '.chat.v1.ClientCommand': $1.ClientCommand$json,
  '.chat.v1.ReceiptEvent': $1.ReceiptEvent$json,
  '.chat.v1.AckEvent': $1.AckEvent$json,
  '.common.v1.ErrorDetail': $2.ErrorDetail$json,
  '.common.v1.ErrorDetail.MetaEntry': $2.ErrorDetail_MetaEntry$json,
  '.chat.v1.TypingEvent': $1.TypingEvent$json,
  '.chat.v1.PresenceEvent': $1.PresenceEvent$json,
  '.common.v1.ContactLink': $2.ContactLink$json,
  '.google.protobuf.Struct': $3.Struct$json,
  '.google.protobuf.Struct.FieldsEntry': $3.Struct_FieldsEntry$json,
  '.google.protobuf.Value': $3.Value$json,
  '.google.protobuf.ListValue': $3.ListValue$json,
  '.chat.v1.ReadMarker': $1.ReadMarker$json,
  '.chat.v1.RoomEvent': $1.RoomEvent$json,
  '.chat.v1.Payload': $4.Payload$json,
  '.chat.v1.RoomChangeContent': $4.RoomChangeContent$json,
  '.chat.v1.ModerationContent': $4.ModerationContent$json,
  '.chat.v1.TextContent': $4.TextContent$json,
  '.chat.v1.TextAnnotation': $4.TextAnnotation$json,
  '.chat.v1.AttachmentContent': $4.AttachmentContent$json,
  '.chat.v1.AttachmentPreview': $4.AttachmentPreview$json,
  '.chat.v1.ReactionContent': $4.ReactionContent$json,
  '.chat.v1.EncryptedContent': $4.EncryptedContent$json,
  '.chat.v1.CallContent': $4.CallContent$json,
  '.chat.v1.MotionContent': $4.MotionContent$json,
  '.chat.v1.PassingRule': $4.PassingRule$json,
  '.chat.v1.VoteChoice': $4.VoteChoice$json,
  '.chat.v1.VoteCast': $4.VoteCast$json,
  '.chat.v1.MotionTally': $4.MotionTally$json,
  '.chat.v1.VoteTally': $4.VoteTally$json,
  '.chat.v1.FormRequestContent': $4.FormRequestContent$json,
  '.chat.v1.FormSchema': $4.FormSchema$json,
  '.chat.v1.FormStep': $4.FormStep$json,
  '.chat.v1.FormSection': $4.FormSection$json,
  '.chat.v1.FormField': $4.FormField$json,
  '.chat.v1.FormValidationRule': $4.FormValidationRule$json,
  '.chat.v1.FormConditionGroup': $4.FormConditionGroup$json,
  '.chat.v1.FormConditionClause': $4.FormConditionClause$json,
  '.chat.v1.FormOption': $4.FormOption$json,
  '.chat.v1.FormFormattingHint': $4.FormFormattingHint$json,
  '.chat.v1.FormReviewHint': $4.FormReviewHint$json,
  '.chat.v1.FormSubmissionSnapshot': $4.FormSubmissionSnapshot$json,
  '.chat.v1.FormReviewSection': $4.FormReviewSection$json,
  '.chat.v1.FormReviewItem': $4.FormReviewItem$json,
  '.chat.v1.FormPermissions': $4.FormPermissions$json,
  '.chat.v1.FormSubmissionResultContent': $4.FormSubmissionResultContent$json,
  '.chat.v1.FinanceCardContent': $4.FinanceCardContent$json,
  '.chat.v1.FinanceCardContent.DataEntry': $4.FinanceCardContent_DataEntry$json,
  '.chat.v1.StawiRoomConversionContent': $4.StawiRoomConversionContent$json,
  '.chat.v1.StawiRoomConversionContent.RuleValuesEntry':
      $4.StawiRoomConversionContent_RuleValuesEntry$json,
  '.chat.v1.StawiGenesis': $4.StawiGenesis$json,
  '.chat.v1.StawiGenesisSignatureContent': $4.StawiGenesisSignatureContent$json,
  '.chat.v1.StawiSignedCallContent': $4.StawiSignedCallContent$json,
  '.chat.v1.StawiCallOutcomeContent': $4.StawiCallOutcomeContent$json,
  '.chat.v1.StawiAgentInvitationContent': $4.StawiAgentInvitationContent$json,
  '.chat.v1.StawiAgentAcceptanceContent': $4.StawiAgentAcceptanceContent$json,
  '.chat.v1.StreamResponse': StreamResponse$json,
};

/// Descriptor for `GatewayService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List gatewayServiceDescriptor = $convert.base64Decode(
    'Cg5HYXRld2F5U2VydmljZRKDAwoGU3RyZWFtEhYuY2hhdC52MS5TdHJlYW1SZXF1ZXN0GhcuY2'
    'hhdC52MS5TdHJlYW1SZXNwb25zZSLDArpHqgIKCVJlYWwtdGltZRItRXN0YWJsaXNoIGJpLWRp'
    'cmVjdGlvbmFsIHN0cmVhbWluZyBjb25uZWN0aW9uGuUBT3BlbnMgYSBwZXJzaXN0ZW50IGJpLW'
    'RpcmVjdGlvbmFsIHN0cmVhbSBmb3IgcmVhbC10aW1lIGNoYXQgZXZlbnRzLiBDbGllbnRzIHNl'
    'bmQgU3RyZWFtUmVxdWVzdCBtZXNzYWdlcyAoYXV0aCwgYWNrcywgY29tbWFuZHMpIGFuZCByZW'
    'NlaXZlIFNlcnZlckV2ZW50IG1lc3NhZ2VzIGluIGNocm9ub2xvZ2ljYWwgb3JkZXIuIFN1cHBv'
    'cnRzIHNlc3Npb24gcmVzdW1wdGlvbiB2aWEgcmVzdW1lX3Rva2VuLioGc3RyZWFtgrUYEQoPZ2'
    'F0ZXdheV9jb25uZWN0KAEwARqlAYK1GKABCg9zZXJ2aWNlX2dhdGV3YXkSD2dhdGV3YXlfY29u'
    'bmVjdBoTCAESD2dhdGV3YXlfY29ubmVjdBoTCAISD2dhdGV3YXlfY29ubmVjdBoTCAMSD2dhdG'
    'V3YXlfY29ubmVjdBoTCAQSD2dhdGV3YXlfY29ubmVjdBoTCAUSD2dhdGV3YXlfY29ubmVjdBoT'
    'CAYSD2dhdGV3YXlfY29ubmVjdA==');
