// This is a generated file - do not edit.
//
// Generated from events/v1/events.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Indicates priority of delivery to prioritize critical events (e.g., CALL_OFFER).
class Broadcast_Priority extends $pb.ProtobufEnum {
  static const Broadcast_Priority PRIORITY_UNSPECIFIED =
      Broadcast_Priority._(0, _omitEnumNames ? '' : 'PRIORITY_UNSPECIFIED');
  static const Broadcast_Priority PRIORITY_NORMAL =
      Broadcast_Priority._(1, _omitEnumNames ? '' : 'PRIORITY_NORMAL');
  static const Broadcast_Priority PRIORITY_HIGH =
      Broadcast_Priority._(2, _omitEnumNames ? '' : 'PRIORITY_HIGH');

  static const $core.List<Broadcast_Priority> values = <Broadcast_Priority>[
    PRIORITY_UNSPECIFIED,
    PRIORITY_NORMAL,
    PRIORITY_HIGH,
  ];

  static final $core.List<Broadcast_Priority?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Broadcast_Priority? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Broadcast_Priority._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
