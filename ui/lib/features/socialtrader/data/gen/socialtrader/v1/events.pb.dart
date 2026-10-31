// This is a generated file - do not edit.
//
// Generated from socialtrader/v1/events.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// PoolIndexed is the in-process event the indexer emits for every pool event
/// it writes (pool.event.indexed); the card poster consumes it.
class PoolIndexed extends $pb.GeneratedMessage {
  factory PoolIndexed({
    $core.String? pool,
    $core.String? kind,
    $core.String? eventKey,
    $fixnum.Int64? block,
  }) {
    final result = PoolIndexed._();
    if (pool != null) result.pool = pool;
    if (kind != null) result.kind = kind;
    if (eventKey != null) result.eventKey = eventKey;
    if (block != null) result.block = block;
    return result;
  }

  PoolIndexed._();

  factory PoolIndexed.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PoolIndexed()..mergeFromBuffer(data, registry);
  factory PoolIndexed.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PoolIndexed()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PoolIndexed',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: PoolIndexed.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'pool')
    ..aOS(2, _omitFieldNames ? '' : 'kind')
    ..aOS(3, _omitFieldNames ? '' : 'eventKey')
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'block', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PoolIndexed clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PoolIndexed copyWith(void Function(PoolIndexed) updates) =>
      super.copyWith((message) => updates(message as PoolIndexed))
          as PoolIndexed;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PoolIndexed() / PoolIndexed.new instead')
  static PoolIndexed create() => PoolIndexed._();
  static $pb.GeneratedMessage $_createMessage() => PoolIndexed._();
  @$core.override
  PoolIndexed createEmptyInstance() => PoolIndexed._();
  @$core.pragma('dart2js:noInline')
  static PoolIndexed getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PoolIndexed>(
          PoolIndexed.$_createMessage);
  static PoolIndexed? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get pool => $_getSZ(0);
  @$pb.TagNumber(1)
  set pool($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPool() => $_has(0);
  @$pb.TagNumber(1)
  void clearPool() => $_clearField(1);

  /// deposited|redeemed|redeem_queued|redeem_cancelled|leader_order|fee_paid|paused|leader_replaced|created
  @$pb.TagNumber(2)
  $core.String get kind => $_getSZ(1);
  @$pb.TagNumber(2)
  set kind($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  /// chain_id:tx_hash:log_index
  @$pb.TagNumber(3)
  $core.String get eventKey => $_getSZ(2);
  @$pb.TagNumber(3)
  set eventKey($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEventKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearEventKey() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get block => $_getI64(3);
  @$pb.TagNumber(4)
  set block($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBlock() => $_has(3);
  @$pb.TagNumber(4)
  void clearBlock() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
