// This is a generated file - do not edit.
//
// Generated from socialtrader/v1/pools.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class PrepareLeaderOrderRequest_Kind extends $pb.ProtobufEnum {
  static const PrepareLeaderOrderRequest_Kind KIND_UNSPECIFIED =
      PrepareLeaderOrderRequest_Kind._(
          0, _omitEnumNames ? '' : 'KIND_UNSPECIFIED');
  static const PrepareLeaderOrderRequest_Kind KIND_LIMIT =
      PrepareLeaderOrderRequest_Kind._(1, _omitEnumNames ? '' : 'KIND_LIMIT');
  static const PrepareLeaderOrderRequest_Kind KIND_IOC =
      PrepareLeaderOrderRequest_Kind._(2, _omitEnumNames ? '' : 'KIND_IOC');
  static const PrepareLeaderOrderRequest_Kind KIND_CANCEL =
      PrepareLeaderOrderRequest_Kind._(3, _omitEnumNames ? '' : 'KIND_CANCEL');
  static const PrepareLeaderOrderRequest_Kind KIND_CLAIM =
      PrepareLeaderOrderRequest_Kind._(4, _omitEnumNames ? '' : 'KIND_CLAIM');
  static const PrepareLeaderOrderRequest_Kind KIND_SELL_FOR_REDEEMS =
      PrepareLeaderOrderRequest_Kind._(
          5, _omitEnumNames ? '' : 'KIND_SELL_FOR_REDEEMS');

  /// settleQueue(maxItems) is permissionless; max_levels carries maxItems.
  static const PrepareLeaderOrderRequest_Kind KIND_SETTLE_QUEUE =
      PrepareLeaderOrderRequest_Kind._(
          6, _omitEnumNames ? '' : 'KIND_SETTLE_QUEUE');

  /// cancelForRedeems(orderId) is permissionless while redeems are queued.
  static const PrepareLeaderOrderRequest_Kind KIND_CANCEL_FOR_REDEEMS =
      PrepareLeaderOrderRequest_Kind._(
          7, _omitEnumNames ? '' : 'KIND_CANCEL_FOR_REDEEMS');

  /// crystallizeFee() is permissionless.
  static const PrepareLeaderOrderRequest_Kind KIND_CRYSTALLIZE_FEE =
      PrepareLeaderOrderRequest_Kind._(
          8, _omitEnumNames ? '' : 'KIND_CRYSTALLIZE_FEE');

  static const $core.List<PrepareLeaderOrderRequest_Kind> values =
      <PrepareLeaderOrderRequest_Kind>[
    KIND_UNSPECIFIED,
    KIND_LIMIT,
    KIND_IOC,
    KIND_CANCEL,
    KIND_CLAIM,
    KIND_SELL_FOR_REDEEMS,
    KIND_SETTLE_QUEUE,
    KIND_CANCEL_FOR_REDEEMS,
    KIND_CRYSTALLIZE_FEE,
  ];

  static final $core.List<PrepareLeaderOrderRequest_Kind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static PrepareLeaderOrderRequest_Kind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PrepareLeaderOrderRequest_Kind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
