// This is a generated file - do not edit.
//
// Generated from socialtrader/v1/events.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use poolIndexedDescriptor instead')
const PoolIndexed$json = {
  '1': 'PoolIndexed',
  '2': [
    {'1': 'pool', '3': 1, '4': 1, '5': 9, '10': 'pool'},
    {'1': 'kind', '3': 2, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'event_key', '3': 3, '4': 1, '5': 9, '10': 'eventKey'},
    {'1': 'block', '3': 4, '4': 1, '5': 4, '10': 'block'},
  ],
};

/// Descriptor for `PoolIndexed`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List poolIndexedDescriptor = $convert.base64Decode(
    'CgtQb29sSW5kZXhlZBISCgRwb29sGAEgASgJUgRwb29sEhIKBGtpbmQYAiABKAlSBGtpbmQSGw'
    'oJZXZlbnRfa2V5GAMgASgJUghldmVudEtleRIUCgVibG9jaxgEIAEoBFIFYmxvY2s=');
