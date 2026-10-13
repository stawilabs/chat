// This is a generated file - do not edit.
//
// Generated from chat/v1/chat.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../common/v1/common.pb.dart' as $1;
import '../../google/protobuf/struct.pb.dart' as $2;
import '../../google/protobuf/timestamp.pb.dart' as $3;
import 'chat.pbenum.dart';
import 'definitions.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'chat.pbenum.dart';

class SendEventRequest extends $pb.GeneratedMessage {
  factory SendEventRequest({
    $core.Iterable<$0.RoomEvent>? event,
  }) {
    final result = create();
    if (event != null) result.event.addAll(event);
    return result;
  }

  SendEventRequest._();

  factory SendEventRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SendEventRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendEventRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..pc<$0.RoomEvent>(4, _omitFieldNames ? '' : 'event', $pb.PbFieldType.PM,
        subBuilder: $0.RoomEvent.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendEventRequest clone() => SendEventRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendEventRequest copyWith(void Function(SendEventRequest) updates) =>
      super.copyWith((message) => updates(message as SendEventRequest))
          as SendEventRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SendEventRequest create() => SendEventRequest._();
  @$core.override
  SendEventRequest createEmptyInstance() => create();
  static $pb.PbList<SendEventRequest> createRepeated() =>
      $pb.PbList<SendEventRequest>();
  @$core.pragma('dart2js:noInline')
  static SendEventRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendEventRequest>(create);
  static SendEventRequest? _defaultInstance;

  @$pb.TagNumber(4)
  $pb.PbList<$0.RoomEvent> get event => $_getList(0);
}

class SendEventResponse extends $pb.GeneratedMessage {
  factory SendEventResponse({
    $core.Iterable<$0.AckEvent>? ack,
  }) {
    final result = create();
    if (ack != null) result.ack.addAll(ack);
    return result;
  }

  SendEventResponse._();

  factory SendEventResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SendEventResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendEventResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..pc<$0.AckEvent>(1, _omitFieldNames ? '' : 'ack', $pb.PbFieldType.PM,
        subBuilder: $0.AckEvent.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendEventResponse clone() => SendEventResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendEventResponse copyWith(void Function(SendEventResponse) updates) =>
      super.copyWith((message) => updates(message as SendEventResponse))
          as SendEventResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SendEventResponse create() => SendEventResponse._();
  @$core.override
  SendEventResponse createEmptyInstance() => create();
  static $pb.PbList<SendEventResponse> createRepeated() =>
      $pb.PbList<SendEventResponse>();
  @$core.pragma('dart2js:noInline')
  static SendEventResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendEventResponse>(create);
  static SendEventResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.AckEvent> get ack => $_getList(0);
}

class GetEventRequest extends $pb.GeneratedMessage {
  factory GetEventRequest({
    $core.String? roomId,
    $core.String? eventId,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (eventId != null) result.eventId = eventId;
    return result;
  }

  GetEventRequest._();

  factory GetEventRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetEventRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetEventRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..aOS(2, _omitFieldNames ? '' : 'eventId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEventRequest clone() => GetEventRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEventRequest copyWith(void Function(GetEventRequest) updates) =>
      super.copyWith((message) => updates(message as GetEventRequest))
          as GetEventRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetEventRequest create() => GetEventRequest._();
  @$core.override
  GetEventRequest createEmptyInstance() => create();
  static $pb.PbList<GetEventRequest> createRepeated() =>
      $pb.PbList<GetEventRequest>();
  @$core.pragma('dart2js:noInline')
  static GetEventRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetEventRequest>(create);
  static GetEventRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get eventId => $_getSZ(1);
  @$pb.TagNumber(2)
  set eventId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEventId() => $_has(1);
  @$pb.TagNumber(2)
  void clearEventId() => $_clearField(2);
}

class GetEventResponse extends $pb.GeneratedMessage {
  factory GetEventResponse({
    $0.RoomEvent? event,
    $1.ErrorDetail? error,
  }) {
    final result = create();
    if (event != null) result.event = event;
    if (error != null) result.error = error;
    return result;
  }

  GetEventResponse._();

  factory GetEventResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetEventResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetEventResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOM<$0.RoomEvent>(1, _omitFieldNames ? '' : 'event',
        subBuilder: $0.RoomEvent.create)
    ..aOM<$1.ErrorDetail>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.ErrorDetail.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEventResponse clone() => GetEventResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEventResponse copyWith(void Function(GetEventResponse) updates) =>
      super.copyWith((message) => updates(message as GetEventResponse))
          as GetEventResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetEventResponse create() => GetEventResponse._();
  @$core.override
  GetEventResponse createEmptyInstance() => create();
  static $pb.PbList<GetEventResponse> createRepeated() =>
      $pb.PbList<GetEventResponse>();
  @$core.pragma('dart2js:noInline')
  static GetEventResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetEventResponse>(create);
  static GetEventResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $0.RoomEvent get event => $_getN(0);
  @$pb.TagNumber(1)
  set event($0.RoomEvent value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasEvent() => $_has(0);
  @$pb.TagNumber(1)
  void clearEvent() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.RoomEvent ensureEvent() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ErrorDetail get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($1.ErrorDetail value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ErrorDetail ensureError() => $_ensure(1);
}

/// History request: paging via opaque cursor. 'limit' is capped by server (e.g. 100).
/// Ordering is determined by XID lexicographic order.
/// Cursor encapsulates last seen event ID.
class GetHistoryRequest extends $pb.GeneratedMessage {
  factory GetHistoryRequest({
    $core.String? roomId,
    $1.PageCursor? cursor,
    $core.bool? forward,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (cursor != null) result.cursor = cursor;
    if (forward != null) result.forward = forward;
    return result;
  }

  GetHistoryRequest._();

  factory GetHistoryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetHistoryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetHistoryRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(2, _omitFieldNames ? '' : 'roomId')
    ..aOM<$1.PageCursor>(3, _omitFieldNames ? '' : 'cursor',
        subBuilder: $1.PageCursor.create)
    ..aOB(5, _omitFieldNames ? '' : 'forward')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHistoryRequest clone() => GetHistoryRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHistoryRequest copyWith(void Function(GetHistoryRequest) updates) =>
      super.copyWith((message) => updates(message as GetHistoryRequest))
          as GetHistoryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetHistoryRequest create() => GetHistoryRequest._();
  @$core.override
  GetHistoryRequest createEmptyInstance() => create();
  static $pb.PbList<GetHistoryRequest> createRepeated() =>
      $pb.PbList<GetHistoryRequest>();
  @$core.pragma('dart2js:noInline')
  static GetHistoryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetHistoryRequest>(create);
  static GetHistoryRequest? _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(2)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(2)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(2)
  void clearRoomId() => $_clearField(2);

  @$pb.TagNumber(3)
  $1.PageCursor get cursor => $_getN(1);
  @$pb.TagNumber(3)
  set cursor($1.PageCursor value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCursor() => $_has(1);
  @$pb.TagNumber(3)
  void clearCursor() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.PageCursor ensureCursor() => $_ensure(1);

  /// direction: FORWARD means older -> newer; BACKWARD newer -> older (default BACKWARD).
  @$pb.TagNumber(5)
  $core.bool get forward => $_getBF(2);
  @$pb.TagNumber(5)
  set forward($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(5)
  $core.bool hasForward() => $_has(2);
  @$pb.TagNumber(5)
  void clearForward() => $_clearField(5);
}

class GetHistoryResponse extends $pb.GeneratedMessage {
  factory GetHistoryResponse({
    $core.Iterable<$0.RoomEvent>? events,
    $core.String? nextCursor,
    $core.String? prevCursor,
  }) {
    final result = create();
    if (events != null) result.events.addAll(events);
    if (nextCursor != null) result.nextCursor = nextCursor;
    if (prevCursor != null) result.prevCursor = prevCursor;
    return result;
  }

  GetHistoryResponse._();

  factory GetHistoryResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetHistoryResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetHistoryResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..pc<$0.RoomEvent>(1, _omitFieldNames ? '' : 'events', $pb.PbFieldType.PM,
        subBuilder: $0.RoomEvent.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextCursor')
    ..aOS(3, _omitFieldNames ? '' : 'prevCursor')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHistoryResponse clone() => GetHistoryResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHistoryResponse copyWith(void Function(GetHistoryResponse) updates) =>
      super.copyWith((message) => updates(message as GetHistoryResponse))
          as GetHistoryResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetHistoryResponse create() => GetHistoryResponse._();
  @$core.override
  GetHistoryResponse createEmptyInstance() => create();
  static $pb.PbList<GetHistoryResponse> createRepeated() =>
      $pb.PbList<GetHistoryResponse>();
  @$core.pragma('dart2js:noInline')
  static GetHistoryResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetHistoryResponse>(create);
  static GetHistoryResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.RoomEvent> get events => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get nextCursor => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextCursor($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextCursor() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextCursor() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get prevCursor => $_getSZ(2);
  @$pb.TagNumber(3)
  set prevCursor($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPrevCursor() => $_has(2);
  @$pb.TagNumber(3)
  void clearPrevCursor() => $_clearField(3);
}

class GetRoomRequest extends $pb.GeneratedMessage {
  factory GetRoomRequest({
    $core.String? roomId,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    return result;
  }

  GetRoomRequest._();

  factory GetRoomRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetRoomRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetRoomRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRoomRequest clone() => GetRoomRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRoomRequest copyWith(void Function(GetRoomRequest) updates) =>
      super.copyWith((message) => updates(message as GetRoomRequest))
          as GetRoomRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetRoomRequest create() => GetRoomRequest._();
  @$core.override
  GetRoomRequest createEmptyInstance() => create();
  static $pb.PbList<GetRoomRequest> createRepeated() =>
      $pb.PbList<GetRoomRequest>();
  @$core.pragma('dart2js:noInline')
  static GetRoomRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetRoomRequest>(create);
  static GetRoomRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);
}

class GetDirectPartnerAccountRequest extends $pb.GeneratedMessage {
  factory GetDirectPartnerAccountRequest({
    $core.String? roomId,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    return result;
  }

  GetDirectPartnerAccountRequest._();

  factory GetDirectPartnerAccountRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetDirectPartnerAccountRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetDirectPartnerAccountRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDirectPartnerAccountRequest clone() =>
      GetDirectPartnerAccountRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDirectPartnerAccountRequest copyWith(
          void Function(GetDirectPartnerAccountRequest) updates) =>
      super.copyWith(
              (message) => updates(message as GetDirectPartnerAccountRequest))
          as GetDirectPartnerAccountRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetDirectPartnerAccountRequest create() =>
      GetDirectPartnerAccountRequest._();
  @$core.override
  GetDirectPartnerAccountRequest createEmptyInstance() => create();
  static $pb.PbList<GetDirectPartnerAccountRequest> createRepeated() =>
      $pb.PbList<GetDirectPartnerAccountRequest>();
  @$core.pragma('dart2js:noInline')
  static GetDirectPartnerAccountRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetDirectPartnerAccountRequest>(create);
  static GetDirectPartnerAccountRequest? _defaultInstance;

  /// The DIRECT room the caller shares with the partner.
  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);
}

class GetDirectPartnerAccountResponse extends $pb.GeneratedMessage {
  factory GetDirectPartnerAccountResponse({
    $core.String? profileId,
    $core.List<$core.int>? account,
    $core.bool? deployed,
  }) {
    final result = create();
    if (profileId != null) result.profileId = profileId;
    if (account != null) result.account = account;
    if (deployed != null) result.deployed = deployed;
    return result;
  }

  GetDirectPartnerAccountResponse._();

  factory GetDirectPartnerAccountResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetDirectPartnerAccountResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetDirectPartnerAccountResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'profileId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'account', $pb.PbFieldType.OY)
    ..aOB(3, _omitFieldNames ? '' : 'deployed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDirectPartnerAccountResponse clone() =>
      GetDirectPartnerAccountResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDirectPartnerAccountResponse copyWith(
          void Function(GetDirectPartnerAccountResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetDirectPartnerAccountResponse))
          as GetDirectPartnerAccountResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetDirectPartnerAccountResponse create() =>
      GetDirectPartnerAccountResponse._();
  @$core.override
  GetDirectPartnerAccountResponse createEmptyInstance() => create();
  static $pb.PbList<GetDirectPartnerAccountResponse> createRepeated() =>
      $pb.PbList<GetDirectPartnerAccountResponse>();
  @$core.pragma('dart2js:noInline')
  static GetDirectPartnerAccountResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetDirectPartnerAccountResponse>(
          create);
  static GetDirectPartnerAccountResponse? _defaultInstance;

  /// The other person in the DM.
  @$pb.TagNumber(1)
  $core.String get profileId => $_getSZ(0);
  @$pb.TagNumber(1)
  set profileId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProfileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfileId() => $_clearField(1);

  /// The partner's primary Stawi account; empty when they have none.
  @$pb.TagNumber(2)
  $core.List<$core.int> get account => $_getN(1);
  @$pb.TagNumber(2)
  set account($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAccount() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccount() => $_clearField(2);

  /// Whether the account is deployed on chain.
  @$pb.TagNumber(3)
  $core.bool get deployed => $_getBF(2);
  @$pb.TagNumber(3)
  set deployed($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDeployed() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeployed() => $_clearField(3);
}

class GetRoomResponse extends $pb.GeneratedMessage {
  factory GetRoomResponse({
    Room? room,
    $1.ErrorDetail? error,
  }) {
    final result = create();
    if (room != null) result.room = room;
    if (error != null) result.error = error;
    return result;
  }

  GetRoomResponse._();

  factory GetRoomResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetRoomResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetRoomResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOM<Room>(1, _omitFieldNames ? '' : 'room', subBuilder: Room.create)
    ..aOM<$1.ErrorDetail>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.ErrorDetail.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRoomResponse clone() => GetRoomResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRoomResponse copyWith(void Function(GetRoomResponse) updates) =>
      super.copyWith((message) => updates(message as GetRoomResponse))
          as GetRoomResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetRoomResponse create() => GetRoomResponse._();
  @$core.override
  GetRoomResponse createEmptyInstance() => create();
  static $pb.PbList<GetRoomResponse> createRepeated() =>
      $pb.PbList<GetRoomResponse>();
  @$core.pragma('dart2js:noInline')
  static GetRoomResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetRoomResponse>(create);
  static GetRoomResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Room get room => $_getN(0);
  @$pb.TagNumber(1)
  set room(Room value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRoom() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoom() => $_clearField(1);
  @$pb.TagNumber(1)
  Room ensureRoom() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ErrorDetail get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($1.ErrorDetail value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ErrorDetail ensureError() => $_ensure(1);
}

class Room extends $pb.GeneratedMessage {
  factory Room({
    $core.String? id,
    $core.String? name,
    $core.String? description,
    $core.bool? isPrivate,
    $2.Struct? metadata,
    $3.Timestamp? createdAt,
    $3.Timestamp? updatedAt,
    $core.String? creatorId,
    $core.bool? requiresApproval,
    RoomType? type,
    StawiRoomBinding? stawi,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (isPrivate != null) result.isPrivate = isPrivate;
    if (metadata != null) result.metadata = metadata;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (creatorId != null) result.creatorId = creatorId;
    if (requiresApproval != null) result.requiresApproval = requiresApproval;
    if (type != null) result.type = type;
    if (stawi != null) result.stawi = stawi;
    return result;
  }

  Room._();

  factory Room.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Room.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Room',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'description')
    ..aOB(5, _omitFieldNames ? '' : 'isPrivate')
    ..aOM<$2.Struct>(6, _omitFieldNames ? '' : 'metadata',
        subBuilder: $2.Struct.create)
    ..aOM<$3.Timestamp>(7, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $3.Timestamp.create)
    ..aOM<$3.Timestamp>(8, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $3.Timestamp.create)
    ..aOS(9, _omitFieldNames ? '' : 'creatorId')
    ..aOB(10, _omitFieldNames ? '' : 'requiresApproval')
    ..e<RoomType>(11, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker: RoomType.ROOM_TYPE_UNSPECIFIED,
        valueOf: RoomType.valueOf,
        enumValues: RoomType.values)
    ..aOM<StawiRoomBinding>(12, _omitFieldNames ? '' : 'stawi',
        subBuilder: StawiRoomBinding.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Room clone() => Room()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Room copyWith(void Function(Room) updates) =>
      super.copyWith((message) => updates(message as Room)) as Room;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Room create() => Room._();
  @$core.override
  Room createEmptyInstance() => create();
  static $pb.PbList<Room> createRepeated() => $pb.PbList<Room>();
  @$core.pragma('dart2js:noInline')
  static Room getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Room>(create);
  static Room? _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(2)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(2)
  void clearId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(4)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(4)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(4)
  void clearDescription() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isPrivate => $_getBF(3);
  @$pb.TagNumber(5)
  set isPrivate($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(5)
  $core.bool hasIsPrivate() => $_has(3);
  @$pb.TagNumber(5)
  void clearIsPrivate() => $_clearField(5);

  @$pb.TagNumber(6)
  $2.Struct get metadata => $_getN(4);
  @$pb.TagNumber(6)
  set metadata($2.Struct value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasMetadata() => $_has(4);
  @$pb.TagNumber(6)
  void clearMetadata() => $_clearField(6);
  @$pb.TagNumber(6)
  $2.Struct ensureMetadata() => $_ensure(4);

  @$pb.TagNumber(7)
  $3.Timestamp get createdAt => $_getN(5);
  @$pb.TagNumber(7)
  set createdAt($3.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasCreatedAt() => $_has(5);
  @$pb.TagNumber(7)
  void clearCreatedAt() => $_clearField(7);
  @$pb.TagNumber(7)
  $3.Timestamp ensureCreatedAt() => $_ensure(5);

  @$pb.TagNumber(8)
  $3.Timestamp get updatedAt => $_getN(6);
  @$pb.TagNumber(8)
  set updatedAt($3.Timestamp value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasUpdatedAt() => $_has(6);
  @$pb.TagNumber(8)
  void clearUpdatedAt() => $_clearField(8);
  @$pb.TagNumber(8)
  $3.Timestamp ensureUpdatedAt() => $_ensure(6);

  @$pb.TagNumber(9)
  $core.String get creatorId => $_getSZ(7);
  @$pb.TagNumber(9)
  set creatorId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(9)
  $core.bool hasCreatorId() => $_has(7);
  @$pb.TagNumber(9)
  void clearCreatorId() => $_clearField(9);

  /// If true, changes to this room require approval from owners before execution
  @$pb.TagNumber(10)
  $core.bool get requiresApproval => $_getBF(8);
  @$pb.TagNumber(10)
  set requiresApproval($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(10)
  $core.bool hasRequiresApproval() => $_has(8);
  @$pb.TagNumber(10)
  void clearRequiresApproval() => $_clearField(10);

  @$pb.TagNumber(11)
  RoomType get type => $_getN(9);
  @$pb.TagNumber(11)
  set type(RoomType value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasType() => $_has(9);
  @$pb.TagNumber(11)
  void clearType() => $_clearField(11);

  /// The room's Stawi binding: set once the room has been converted to a
  /// Stawi room (a genesis was prepared), unset for a plain chat room. Every
  /// member sees it, including one who joined after the conversion.
  @$pb.TagNumber(12)
  StawiRoomBinding get stawi => $_getN(10);
  @$pb.TagNumber(12)
  set stawi(StawiRoomBinding value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasStawi() => $_has(10);
  @$pb.TagNumber(12)
  void clearStawi() => $_clearField(12);
  @$pb.TagNumber(12)
  StawiRoomBinding ensureStawi() => $_ensure(10);
}

/// StawiRoomBinding binds a chat room to its on-chain custody. The chain room
/// id is the chat room id: one identifier names the room in chat, in finance
/// and on chain.
class StawiRoomBinding extends $pb.GeneratedMessage {
  factory StawiRoomBinding({
    StawiRoomState? state,
    $core.String? genesisId,
    $core.String? genesisEventId,
    $3.Timestamp? genesisExpiresAt,
    $fixnum.Int64? chainId,
    $core.String? custodyAddress,
    $core.String? governanceAddress,
    $fixnum.Int64? policyEpoch,
    $3.Timestamp? boundAt,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (genesisId != null) result.genesisId = genesisId;
    if (genesisEventId != null) result.genesisEventId = genesisEventId;
    if (genesisExpiresAt != null) result.genesisExpiresAt = genesisExpiresAt;
    if (chainId != null) result.chainId = chainId;
    if (custodyAddress != null) result.custodyAddress = custodyAddress;
    if (governanceAddress != null) result.governanceAddress = governanceAddress;
    if (policyEpoch != null) result.policyEpoch = policyEpoch;
    if (boundAt != null) result.boundAt = boundAt;
    return result;
  }

  StawiRoomBinding._();

  factory StawiRoomBinding.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StawiRoomBinding.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StawiRoomBinding',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..e<StawiRoomState>(1, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker: StawiRoomState.STAWI_ROOM_STATE_UNSPECIFIED,
        valueOf: StawiRoomState.valueOf,
        enumValues: StawiRoomState.values)
    ..aOS(2, _omitFieldNames ? '' : 'genesisId')
    ..aOS(3, _omitFieldNames ? '' : 'genesisEventId')
    ..aOM<$3.Timestamp>(4, _omitFieldNames ? '' : 'genesisExpiresAt',
        subBuilder: $3.Timestamp.create)
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'chainId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(6, _omitFieldNames ? '' : 'custodyAddress')
    ..aOS(7, _omitFieldNames ? '' : 'governanceAddress')
    ..a<$fixnum.Int64>(
        8, _omitFieldNames ? '' : 'policyEpoch', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$3.Timestamp>(9, _omitFieldNames ? '' : 'boundAt',
        subBuilder: $3.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StawiRoomBinding clone() => StawiRoomBinding()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StawiRoomBinding copyWith(void Function(StawiRoomBinding) updates) =>
      super.copyWith((message) => updates(message as StawiRoomBinding))
          as StawiRoomBinding;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StawiRoomBinding create() => StawiRoomBinding._();
  @$core.override
  StawiRoomBinding createEmptyInstance() => create();
  static $pb.PbList<StawiRoomBinding> createRepeated() =>
      $pb.PbList<StawiRoomBinding>();
  @$core.pragma('dart2js:noInline')
  static StawiRoomBinding getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StawiRoomBinding>(create);
  static StawiRoomBinding? _defaultInstance;

  @$pb.TagNumber(1)
  StawiRoomState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(StawiRoomState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);

  /// The latest genesis prepared for the room.
  @$pb.TagNumber(2)
  $core.String get genesisId => $_getSZ(1);
  @$pb.TagNumber(2)
  set genesisId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGenesisId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGenesisId() => $_clearField(2);

  /// The room event (stawi room conversion) that carries the genesis card.
  @$pb.TagNumber(3)
  $core.String get genesisEventId => $_getSZ(2);
  @$pb.TagNumber(3)
  set genesisEventId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGenesisEventId() => $_has(2);
  @$pb.TagNumber(3)
  void clearGenesisEventId() => $_clearField(3);

  /// When the pending genesis expires; unset once bound.
  @$pb.TagNumber(4)
  $3.Timestamp get genesisExpiresAt => $_getN(3);
  @$pb.TagNumber(4)
  set genesisExpiresAt($3.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasGenesisExpiresAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearGenesisExpiresAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $3.Timestamp ensureGenesisExpiresAt() => $_ensure(3);

  /// The following are set once the room is bound.
  @$pb.TagNumber(5)
  $fixnum.Int64 get chainId => $_getI64(4);
  @$pb.TagNumber(5)
  set chainId($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasChainId() => $_has(4);
  @$pb.TagNumber(5)
  void clearChainId() => $_clearField(5);

  /// The room's RoomCustody contract address (0x-prefixed, lower case).
  @$pb.TagNumber(6)
  $core.String get custodyAddress => $_getSZ(5);
  @$pb.TagNumber(6)
  set custodyAddress($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCustodyAddress() => $_has(5);
  @$pb.TagNumber(6)
  void clearCustodyAddress() => $_clearField(6);

  /// The room's GovernanceModule address (0x-prefixed, lower case).
  @$pb.TagNumber(7)
  $core.String get governanceAddress => $_getSZ(6);
  @$pb.TagNumber(7)
  set governanceAddress($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasGovernanceAddress() => $_has(6);
  @$pb.TagNumber(7)
  void clearGovernanceAddress() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get policyEpoch => $_getI64(7);
  @$pb.TagNumber(8)
  set policyEpoch($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPolicyEpoch() => $_has(7);
  @$pb.TagNumber(8)
  void clearPolicyEpoch() => $_clearField(8);

  @$pb.TagNumber(9)
  $3.Timestamp get boundAt => $_getN(8);
  @$pb.TagNumber(9)
  set boundAt($3.Timestamp value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasBoundAt() => $_has(8);
  @$pb.TagNumber(9)
  void clearBoundAt() => $_clearField(9);
  @$pb.TagNumber(9)
  $3.Timestamp ensureBoundAt() => $_ensure(8);
}

class CreateRoomRequest extends $pb.GeneratedMessage {
  factory CreateRoomRequest({
    $core.String? id,
    $core.String? name,
    $core.String? description,
    $core.bool? isPrivate,
    $core.Iterable<$1.ContactLink>? members,
    $2.Struct? metadata,
    $core.bool? requiresApproval,
    RoomType? type,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (isPrivate != null) result.isPrivate = isPrivate;
    if (members != null) result.members.addAll(members);
    if (metadata != null) result.metadata = metadata;
    if (requiresApproval != null) result.requiresApproval = requiresApproval;
    if (type != null) result.type = type;
    return result;
  }

  CreateRoomRequest._();

  factory CreateRoomRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateRoomRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateRoomRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(3, _omitFieldNames ? '' : 'id')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aOS(5, _omitFieldNames ? '' : 'description')
    ..aOB(6, _omitFieldNames ? '' : 'isPrivate')
    ..pc<$1.ContactLink>(
        7, _omitFieldNames ? '' : 'members', $pb.PbFieldType.PM,
        subBuilder: $1.ContactLink.create)
    ..aOM<$2.Struct>(8, _omitFieldNames ? '' : 'metadata',
        subBuilder: $2.Struct.create)
    ..aOB(9, _omitFieldNames ? '' : 'requiresApproval')
    ..e<RoomType>(10, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker: RoomType.ROOM_TYPE_UNSPECIFIED,
        valueOf: RoomType.valueOf,
        enumValues: RoomType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateRoomRequest clone() => CreateRoomRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateRoomRequest copyWith(void Function(CreateRoomRequest) updates) =>
      super.copyWith((message) => updates(message as CreateRoomRequest))
          as CreateRoomRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateRoomRequest create() => CreateRoomRequest._();
  @$core.override
  CreateRoomRequest createEmptyInstance() => create();
  static $pb.PbList<CreateRoomRequest> createRepeated() =>
      $pb.PbList<CreateRoomRequest>();
  @$core.pragma('dart2js:noInline')
  static CreateRoomRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateRoomRequest>(create);
  static CreateRoomRequest? _defaultInstance;

  /// Optional caller-supplied room identifier.
  ///
  /// A room is the entity: its id in chat, in the finance service and on chain
  /// is one value. When a room is created in finance first, the caller hands
  /// chat that id here; when it is omitted chat mints one as before. Creating
  /// the same id twice returns the room that already exists, so a caller may
  /// safely retry.
  ///
  /// The identifier format is the platform's own (an xid, as util.IDString
  /// mints): 20 characters over [0-9a-v]. Anything else is refused.
  @$pb.TagNumber(3)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(3)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(3)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(3)
  void clearId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(4)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(4)
  void clearName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(5)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(5)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(5)
  void clearDescription() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get isPrivate => $_getBF(3);
  @$pb.TagNumber(6)
  set isPrivate($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(6)
  $core.bool hasIsPrivate() => $_has(3);
  @$pb.TagNumber(6)
  void clearIsPrivate() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<$1.ContactLink> get members => $_getList(4);

  @$pb.TagNumber(8)
  $2.Struct get metadata => $_getN(5);
  @$pb.TagNumber(8)
  set metadata($2.Struct value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasMetadata() => $_has(5);
  @$pb.TagNumber(8)
  void clearMetadata() => $_clearField(8);
  @$pb.TagNumber(8)
  $2.Struct ensureMetadata() => $_ensure(5);

  /// If true, changes to this room require approval from owners before execution
  @$pb.TagNumber(9)
  $core.bool get requiresApproval => $_getBF(6);
  @$pb.TagNumber(9)
  set requiresApproval($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(9)
  $core.bool hasRequiresApproval() => $_has(6);
  @$pb.TagNumber(9)
  void clearRequiresApproval() => $_clearField(9);

  @$pb.TagNumber(10)
  RoomType get type => $_getN(7);
  @$pb.TagNumber(10)
  set type(RoomType value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasType() => $_has(7);
  @$pb.TagNumber(10)
  void clearType() => $_clearField(10);
}

class CreateRoomResponse extends $pb.GeneratedMessage {
  factory CreateRoomResponse({
    Room? room,
    $1.ErrorDetail? error,
  }) {
    final result = create();
    if (room != null) result.room = room;
    if (error != null) result.error = error;
    return result;
  }

  CreateRoomResponse._();

  factory CreateRoomResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateRoomResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateRoomResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOM<Room>(1, _omitFieldNames ? '' : 'room', subBuilder: Room.create)
    ..aOM<$1.ErrorDetail>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.ErrorDetail.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateRoomResponse clone() => CreateRoomResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateRoomResponse copyWith(void Function(CreateRoomResponse) updates) =>
      super.copyWith((message) => updates(message as CreateRoomResponse))
          as CreateRoomResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateRoomResponse create() => CreateRoomResponse._();
  @$core.override
  CreateRoomResponse createEmptyInstance() => create();
  static $pb.PbList<CreateRoomResponse> createRepeated() =>
      $pb.PbList<CreateRoomResponse>();
  @$core.pragma('dart2js:noInline')
  static CreateRoomResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateRoomResponse>(create);
  static CreateRoomResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Room get room => $_getN(0);
  @$pb.TagNumber(1)
  set room(Room value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRoom() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoom() => $_clearField(1);
  @$pb.TagNumber(1)
  Room ensureRoom() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ErrorDetail get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($1.ErrorDetail value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ErrorDetail ensureError() => $_ensure(1);
}

class SearchRoomsRequest extends $pb.GeneratedMessage {
  factory SearchRoomsRequest({
    $core.String? query,
    $core.Iterable<$core.String>? properties,
    $2.Struct? extras,
    $1.PageCursor? cursor,
  }) {
    final result = create();
    if (query != null) result.query = query;
    if (properties != null) result.properties.addAll(properties);
    if (extras != null) result.extras = extras;
    if (cursor != null) result.cursor = cursor;
    return result;
  }

  SearchRoomsRequest._();

  factory SearchRoomsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchRoomsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchRoomsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'query')
    ..pPS(6, _omitFieldNames ? '' : 'properties')
    ..aOM<$2.Struct>(7, _omitFieldNames ? '' : 'extras',
        subBuilder: $2.Struct.create)
    ..aOM<$1.PageCursor>(10, _omitFieldNames ? '' : 'cursor',
        subBuilder: $1.PageCursor.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchRoomsRequest clone() => SearchRoomsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchRoomsRequest copyWith(void Function(SearchRoomsRequest) updates) =>
      super.copyWith((message) => updates(message as SearchRoomsRequest))
          as SearchRoomsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchRoomsRequest create() => SearchRoomsRequest._();
  @$core.override
  SearchRoomsRequest createEmptyInstance() => create();
  static $pb.PbList<SearchRoomsRequest> createRepeated() =>
      $pb.PbList<SearchRoomsRequest>();
  @$core.pragma('dart2js:noInline')
  static SearchRoomsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchRoomsRequest>(create);
  static SearchRoomsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get query => $_getSZ(0);
  @$pb.TagNumber(1)
  set query($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQuery() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuery() => $_clearField(1);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get properties => $_getList(1);

  @$pb.TagNumber(7)
  $2.Struct get extras => $_getN(2);
  @$pb.TagNumber(7)
  set extras($2.Struct value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasExtras() => $_has(2);
  @$pb.TagNumber(7)
  void clearExtras() => $_clearField(7);
  @$pb.TagNumber(7)
  $2.Struct ensureExtras() => $_ensure(2);

  @$pb.TagNumber(10)
  $1.PageCursor get cursor => $_getN(3);
  @$pb.TagNumber(10)
  set cursor($1.PageCursor value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasCursor() => $_has(3);
  @$pb.TagNumber(10)
  void clearCursor() => $_clearField(10);
  @$pb.TagNumber(10)
  $1.PageCursor ensureCursor() => $_ensure(3);
}

class SearchRoomsResponse extends $pb.GeneratedMessage {
  factory SearchRoomsResponse({
    $core.Iterable<Room>? data,
    $core.String? nextCursor,
    $core.String? prevCursor,
  }) {
    final result = create();
    if (data != null) result.data.addAll(data);
    if (nextCursor != null) result.nextCursor = nextCursor;
    if (prevCursor != null) result.prevCursor = prevCursor;
    return result;
  }

  SearchRoomsResponse._();

  factory SearchRoomsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchRoomsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchRoomsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..pc<Room>(1, _omitFieldNames ? '' : 'data', $pb.PbFieldType.PM,
        subBuilder: Room.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextCursor')
    ..aOS(3, _omitFieldNames ? '' : 'prevCursor')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchRoomsResponse clone() => SearchRoomsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchRoomsResponse copyWith(void Function(SearchRoomsResponse) updates) =>
      super.copyWith((message) => updates(message as SearchRoomsResponse))
          as SearchRoomsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchRoomsResponse create() => SearchRoomsResponse._();
  @$core.override
  SearchRoomsResponse createEmptyInstance() => create();
  static $pb.PbList<SearchRoomsResponse> createRepeated() =>
      $pb.PbList<SearchRoomsResponse>();
  @$core.pragma('dart2js:noInline')
  static SearchRoomsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchRoomsResponse>(create);
  static SearchRoomsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Room> get data => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get nextCursor => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextCursor($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextCursor() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextCursor() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get prevCursor => $_getSZ(2);
  @$pb.TagNumber(3)
  set prevCursor($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPrevCursor() => $_has(2);
  @$pb.TagNumber(3)
  void clearPrevCursor() => $_clearField(3);
}

class UpdateRoomRequest extends $pb.GeneratedMessage {
  factory UpdateRoomRequest({
    $core.String? roomId,
    $core.String? name,
    $core.String? description,
    $2.Struct? metadata,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (metadata != null) result.metadata = metadata;
    return result;
  }

  UpdateRoomRequest._();

  factory UpdateRoomRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateRoomRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateRoomRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(2, _omitFieldNames ? '' : 'roomId')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'description')
    ..aOM<$2.Struct>(5, _omitFieldNames ? '' : 'metadata',
        subBuilder: $2.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateRoomRequest clone() => UpdateRoomRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateRoomRequest copyWith(void Function(UpdateRoomRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateRoomRequest))
          as UpdateRoomRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateRoomRequest create() => UpdateRoomRequest._();
  @$core.override
  UpdateRoomRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateRoomRequest> createRepeated() =>
      $pb.PbList<UpdateRoomRequest>();
  @$core.pragma('dart2js:noInline')
  static UpdateRoomRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateRoomRequest>(create);
  static UpdateRoomRequest? _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(2)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(2)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(2)
  void clearRoomId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(4)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(4)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(4)
  void clearDescription() => $_clearField(4);

  @$pb.TagNumber(5)
  $2.Struct get metadata => $_getN(3);
  @$pb.TagNumber(5)
  set metadata($2.Struct value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasMetadata() => $_has(3);
  @$pb.TagNumber(5)
  void clearMetadata() => $_clearField(5);
  @$pb.TagNumber(5)
  $2.Struct ensureMetadata() => $_ensure(3);
}

class UpdateRoomResponse extends $pb.GeneratedMessage {
  factory UpdateRoomResponse({
    Room? room,
    $1.ErrorDetail? error,
  }) {
    final result = create();
    if (room != null) result.room = room;
    if (error != null) result.error = error;
    return result;
  }

  UpdateRoomResponse._();

  factory UpdateRoomResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateRoomResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateRoomResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOM<Room>(1, _omitFieldNames ? '' : 'room', subBuilder: Room.create)
    ..aOM<$1.ErrorDetail>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.ErrorDetail.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateRoomResponse clone() => UpdateRoomResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateRoomResponse copyWith(void Function(UpdateRoomResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateRoomResponse))
          as UpdateRoomResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateRoomResponse create() => UpdateRoomResponse._();
  @$core.override
  UpdateRoomResponse createEmptyInstance() => create();
  static $pb.PbList<UpdateRoomResponse> createRepeated() =>
      $pb.PbList<UpdateRoomResponse>();
  @$core.pragma('dart2js:noInline')
  static UpdateRoomResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateRoomResponse>(create);
  static UpdateRoomResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Room get room => $_getN(0);
  @$pb.TagNumber(1)
  set room(Room value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRoom() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoom() => $_clearField(1);
  @$pb.TagNumber(1)
  Room ensureRoom() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ErrorDetail get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($1.ErrorDetail value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ErrorDetail ensureError() => $_ensure(1);
}

class DeleteRoomRequest extends $pb.GeneratedMessage {
  factory DeleteRoomRequest({
    $core.String? roomId,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    return result;
  }

  DeleteRoomRequest._();

  factory DeleteRoomRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteRoomRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteRoomRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(2, _omitFieldNames ? '' : 'roomId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteRoomRequest clone() => DeleteRoomRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteRoomRequest copyWith(void Function(DeleteRoomRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteRoomRequest))
          as DeleteRoomRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteRoomRequest create() => DeleteRoomRequest._();
  @$core.override
  DeleteRoomRequest createEmptyInstance() => create();
  static $pb.PbList<DeleteRoomRequest> createRepeated() =>
      $pb.PbList<DeleteRoomRequest>();
  @$core.pragma('dart2js:noInline')
  static DeleteRoomRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteRoomRequest>(create);
  static DeleteRoomRequest? _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(2)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(2)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(2)
  void clearRoomId() => $_clearField(2);
}

class DeleteRoomResponse extends $pb.GeneratedMessage {
  factory DeleteRoomResponse({
    $core.String? roomId,
    $1.ErrorDetail? error,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (error != null) result.error = error;
    return result;
  }

  DeleteRoomResponse._();

  factory DeleteRoomResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteRoomResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteRoomResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..aOM<$1.ErrorDetail>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.ErrorDetail.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteRoomResponse clone() => DeleteRoomResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteRoomResponse copyWith(void Function(DeleteRoomResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteRoomResponse))
          as DeleteRoomResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteRoomResponse create() => DeleteRoomResponse._();
  @$core.override
  DeleteRoomResponse createEmptyInstance() => create();
  static $pb.PbList<DeleteRoomResponse> createRepeated() =>
      $pb.PbList<DeleteRoomResponse>();
  @$core.pragma('dart2js:noInline')
  static DeleteRoomResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteRoomResponse>(create);
  static DeleteRoomResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);

  @$pb.TagNumber(2)
  $1.ErrorDetail get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($1.ErrorDetail value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ErrorDetail ensureError() => $_ensure(1);
}

class RoomSubscription extends $pb.GeneratedMessage {
  factory RoomSubscription({
    $core.String? id,
    $core.String? roomId,
    $1.ContactLink? member,
    $core.Iterable<$core.String>? roles,
    $3.Timestamp? joinedAt,
    $3.Timestamp? lastActive,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (roomId != null) result.roomId = roomId;
    if (member != null) result.member = member;
    if (roles != null) result.roles.addAll(roles);
    if (joinedAt != null) result.joinedAt = joinedAt;
    if (lastActive != null) result.lastActive = lastActive;
    return result;
  }

  RoomSubscription._();

  factory RoomSubscription.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RoomSubscription.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RoomSubscription',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'roomId')
    ..aOM<$1.ContactLink>(3, _omitFieldNames ? '' : 'member',
        subBuilder: $1.ContactLink.create)
    ..pPS(4, _omitFieldNames ? '' : 'roles')
    ..aOM<$3.Timestamp>(5, _omitFieldNames ? '' : 'joinedAt',
        subBuilder: $3.Timestamp.create)
    ..aOM<$3.Timestamp>(6, _omitFieldNames ? '' : 'lastActive',
        subBuilder: $3.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoomSubscription clone() => RoomSubscription()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoomSubscription copyWith(void Function(RoomSubscription) updates) =>
      super.copyWith((message) => updates(message as RoomSubscription))
          as RoomSubscription;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RoomSubscription create() => RoomSubscription._();
  @$core.override
  RoomSubscription createEmptyInstance() => create();
  static $pb.PbList<RoomSubscription> createRepeated() =>
      $pb.PbList<RoomSubscription>();
  @$core.pragma('dart2js:noInline')
  static RoomSubscription getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RoomSubscription>(create);
  static RoomSubscription? _defaultInstance;

  /// NOTE:
  /// Event IDs are XIDs and MUST be lexicographically sortable by creation time.
  /// Clients MUST NOT assume any other ordering mechanism.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get roomId => $_getSZ(1);
  @$pb.TagNumber(2)
  set roomId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRoomId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRoomId() => $_clearField(2);

  @$pb.TagNumber(3)
  $1.ContactLink get member => $_getN(2);
  @$pb.TagNumber(3)
  set member($1.ContactLink value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasMember() => $_has(2);
  @$pb.TagNumber(3)
  void clearMember() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.ContactLink ensureMember() => $_ensure(2);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get roles => $_getList(3);

  @$pb.TagNumber(5)
  $3.Timestamp get joinedAt => $_getN(4);
  @$pb.TagNumber(5)
  set joinedAt($3.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasJoinedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearJoinedAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $3.Timestamp ensureJoinedAt() => $_ensure(4);

  @$pb.TagNumber(6)
  $3.Timestamp get lastActive => $_getN(5);
  @$pb.TagNumber(6)
  set lastActive($3.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasLastActive() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastActive() => $_clearField(6);
  @$pb.TagNumber(6)
  $3.Timestamp ensureLastActive() => $_ensure(5);
}

class AddRoomSubscriptionsRequest extends $pb.GeneratedMessage {
  factory AddRoomSubscriptionsRequest({
    $core.String? roomId,
    $core.Iterable<RoomSubscription>? members,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (members != null) result.members.addAll(members);
    return result;
  }

  AddRoomSubscriptionsRequest._();

  factory AddRoomSubscriptionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddRoomSubscriptionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddRoomSubscriptionsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(2, _omitFieldNames ? '' : 'roomId')
    ..pc<RoomSubscription>(
        3, _omitFieldNames ? '' : 'members', $pb.PbFieldType.PM,
        subBuilder: RoomSubscription.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddRoomSubscriptionsRequest clone() =>
      AddRoomSubscriptionsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddRoomSubscriptionsRequest copyWith(
          void Function(AddRoomSubscriptionsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as AddRoomSubscriptionsRequest))
          as AddRoomSubscriptionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddRoomSubscriptionsRequest create() =>
      AddRoomSubscriptionsRequest._();
  @$core.override
  AddRoomSubscriptionsRequest createEmptyInstance() => create();
  static $pb.PbList<AddRoomSubscriptionsRequest> createRepeated() =>
      $pb.PbList<AddRoomSubscriptionsRequest>();
  @$core.pragma('dart2js:noInline')
  static AddRoomSubscriptionsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddRoomSubscriptionsRequest>(create);
  static AddRoomSubscriptionsRequest? _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(2)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(2)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(2)
  void clearRoomId() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<RoomSubscription> get members => $_getList(1);
}

class AddRoomSubscriptionsResponse extends $pb.GeneratedMessage {
  factory AddRoomSubscriptionsResponse({
    $core.String? roomId,
    $1.ErrorDetail? error,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (error != null) result.error = error;
    return result;
  }

  AddRoomSubscriptionsResponse._();

  factory AddRoomSubscriptionsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddRoomSubscriptionsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddRoomSubscriptionsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..aOM<$1.ErrorDetail>(3, _omitFieldNames ? '' : 'error',
        subBuilder: $1.ErrorDetail.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddRoomSubscriptionsResponse clone() =>
      AddRoomSubscriptionsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddRoomSubscriptionsResponse copyWith(
          void Function(AddRoomSubscriptionsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as AddRoomSubscriptionsResponse))
          as AddRoomSubscriptionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddRoomSubscriptionsResponse create() =>
      AddRoomSubscriptionsResponse._();
  @$core.override
  AddRoomSubscriptionsResponse createEmptyInstance() => create();
  static $pb.PbList<AddRoomSubscriptionsResponse> createRepeated() =>
      $pb.PbList<AddRoomSubscriptionsResponse>();
  @$core.pragma('dart2js:noInline')
  static AddRoomSubscriptionsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddRoomSubscriptionsResponse>(create);
  static AddRoomSubscriptionsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);

  @$pb.TagNumber(3)
  $1.ErrorDetail get error => $_getN(1);
  @$pb.TagNumber(3)
  set error($1.ErrorDetail value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.ErrorDetail ensureError() => $_ensure(1);
}

class RemoveRoomSubscriptionsRequest extends $pb.GeneratedMessage {
  factory RemoveRoomSubscriptionsRequest({
    $core.String? roomId,
    $core.Iterable<$core.String>? subscriptionId,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (subscriptionId != null) result.subscriptionId.addAll(subscriptionId);
    return result;
  }

  RemoveRoomSubscriptionsRequest._();

  factory RemoveRoomSubscriptionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RemoveRoomSubscriptionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveRoomSubscriptionsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(2, _omitFieldNames ? '' : 'roomId')
    ..pPS(3, _omitFieldNames ? '' : 'subscriptionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveRoomSubscriptionsRequest clone() =>
      RemoveRoomSubscriptionsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveRoomSubscriptionsRequest copyWith(
          void Function(RemoveRoomSubscriptionsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as RemoveRoomSubscriptionsRequest))
          as RemoveRoomSubscriptionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RemoveRoomSubscriptionsRequest create() =>
      RemoveRoomSubscriptionsRequest._();
  @$core.override
  RemoveRoomSubscriptionsRequest createEmptyInstance() => create();
  static $pb.PbList<RemoveRoomSubscriptionsRequest> createRepeated() =>
      $pb.PbList<RemoveRoomSubscriptionsRequest>();
  @$core.pragma('dart2js:noInline')
  static RemoveRoomSubscriptionsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveRoomSubscriptionsRequest>(create);
  static RemoveRoomSubscriptionsRequest? _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(2)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(2)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(2)
  void clearRoomId() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get subscriptionId => $_getList(1);
}

class RemoveRoomSubscriptionsResponse extends $pb.GeneratedMessage {
  factory RemoveRoomSubscriptionsResponse({
    $core.String? roomId,
    $1.ErrorDetail? error,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (error != null) result.error = error;
    return result;
  }

  RemoveRoomSubscriptionsResponse._();

  factory RemoveRoomSubscriptionsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RemoveRoomSubscriptionsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveRoomSubscriptionsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..aOM<$1.ErrorDetail>(3, _omitFieldNames ? '' : 'error',
        subBuilder: $1.ErrorDetail.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveRoomSubscriptionsResponse clone() =>
      RemoveRoomSubscriptionsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveRoomSubscriptionsResponse copyWith(
          void Function(RemoveRoomSubscriptionsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as RemoveRoomSubscriptionsResponse))
          as RemoveRoomSubscriptionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RemoveRoomSubscriptionsResponse create() =>
      RemoveRoomSubscriptionsResponse._();
  @$core.override
  RemoveRoomSubscriptionsResponse createEmptyInstance() => create();
  static $pb.PbList<RemoveRoomSubscriptionsResponse> createRepeated() =>
      $pb.PbList<RemoveRoomSubscriptionsResponse>();
  @$core.pragma('dart2js:noInline')
  static RemoveRoomSubscriptionsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveRoomSubscriptionsResponse>(
          create);
  static RemoveRoomSubscriptionsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);

  @$pb.TagNumber(3)
  $1.ErrorDetail get error => $_getN(1);
  @$pb.TagNumber(3)
  set error($1.ErrorDetail value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.ErrorDetail ensureError() => $_ensure(1);
}

class UpdateSubscriptionRoleRequest extends $pb.GeneratedMessage {
  factory UpdateSubscriptionRoleRequest({
    $core.String? roomId,
    $core.String? subscriptionId,
    $core.Iterable<$core.String>? roles,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (subscriptionId != null) result.subscriptionId = subscriptionId;
    if (roles != null) result.roles.addAll(roles);
    return result;
  }

  UpdateSubscriptionRoleRequest._();

  factory UpdateSubscriptionRoleRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateSubscriptionRoleRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateSubscriptionRoleRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(2, _omitFieldNames ? '' : 'roomId')
    ..aOS(3, _omitFieldNames ? '' : 'subscriptionId')
    ..pPS(4, _omitFieldNames ? '' : 'roles')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSubscriptionRoleRequest clone() =>
      UpdateSubscriptionRoleRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSubscriptionRoleRequest copyWith(
          void Function(UpdateSubscriptionRoleRequest) updates) =>
      super.copyWith(
              (message) => updates(message as UpdateSubscriptionRoleRequest))
          as UpdateSubscriptionRoleRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateSubscriptionRoleRequest create() =>
      UpdateSubscriptionRoleRequest._();
  @$core.override
  UpdateSubscriptionRoleRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateSubscriptionRoleRequest> createRepeated() =>
      $pb.PbList<UpdateSubscriptionRoleRequest>();
  @$core.pragma('dart2js:noInline')
  static UpdateSubscriptionRoleRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateSubscriptionRoleRequest>(create);
  static UpdateSubscriptionRoleRequest? _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(2)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(2)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(2)
  void clearRoomId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get subscriptionId => $_getSZ(1);
  @$pb.TagNumber(3)
  set subscriptionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(3)
  $core.bool hasSubscriptionId() => $_has(1);
  @$pb.TagNumber(3)
  void clearSubscriptionId() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get roles => $_getList(2);
}

class UpdateSubscriptionRoleResponse extends $pb.GeneratedMessage {
  factory UpdateSubscriptionRoleResponse({
    $core.String? roomId,
    $1.ErrorDetail? error,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (error != null) result.error = error;
    return result;
  }

  UpdateSubscriptionRoleResponse._();

  factory UpdateSubscriptionRoleResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateSubscriptionRoleResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateSubscriptionRoleResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..aOM<$1.ErrorDetail>(3, _omitFieldNames ? '' : 'error',
        subBuilder: $1.ErrorDetail.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSubscriptionRoleResponse clone() =>
      UpdateSubscriptionRoleResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSubscriptionRoleResponse copyWith(
          void Function(UpdateSubscriptionRoleResponse) updates) =>
      super.copyWith(
              (message) => updates(message as UpdateSubscriptionRoleResponse))
          as UpdateSubscriptionRoleResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateSubscriptionRoleResponse create() =>
      UpdateSubscriptionRoleResponse._();
  @$core.override
  UpdateSubscriptionRoleResponse createEmptyInstance() => create();
  static $pb.PbList<UpdateSubscriptionRoleResponse> createRepeated() =>
      $pb.PbList<UpdateSubscriptionRoleResponse>();
  @$core.pragma('dart2js:noInline')
  static UpdateSubscriptionRoleResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateSubscriptionRoleResponse>(create);
  static UpdateSubscriptionRoleResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);

  @$pb.TagNumber(3)
  $1.ErrorDetail get error => $_getN(1);
  @$pb.TagNumber(3)
  set error($1.ErrorDetail value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.ErrorDetail ensureError() => $_ensure(1);
}

class SearchRoomSubscriptionsRequest extends $pb.GeneratedMessage {
  factory SearchRoomSubscriptionsRequest({
    $core.String? roomId,
    $1.PageCursor? cursor,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (cursor != null) result.cursor = cursor;
    return result;
  }

  SearchRoomSubscriptionsRequest._();

  factory SearchRoomSubscriptionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchRoomSubscriptionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchRoomSubscriptionsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(2, _omitFieldNames ? '' : 'roomId')
    ..aOM<$1.PageCursor>(4, _omitFieldNames ? '' : 'cursor',
        subBuilder: $1.PageCursor.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchRoomSubscriptionsRequest clone() =>
      SearchRoomSubscriptionsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchRoomSubscriptionsRequest copyWith(
          void Function(SearchRoomSubscriptionsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SearchRoomSubscriptionsRequest))
          as SearchRoomSubscriptionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchRoomSubscriptionsRequest create() =>
      SearchRoomSubscriptionsRequest._();
  @$core.override
  SearchRoomSubscriptionsRequest createEmptyInstance() => create();
  static $pb.PbList<SearchRoomSubscriptionsRequest> createRepeated() =>
      $pb.PbList<SearchRoomSubscriptionsRequest>();
  @$core.pragma('dart2js:noInline')
  static SearchRoomSubscriptionsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchRoomSubscriptionsRequest>(create);
  static SearchRoomSubscriptionsRequest? _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(2)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(2)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(2)
  void clearRoomId() => $_clearField(2);

  @$pb.TagNumber(4)
  $1.PageCursor get cursor => $_getN(1);
  @$pb.TagNumber(4)
  set cursor($1.PageCursor value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCursor() => $_has(1);
  @$pb.TagNumber(4)
  void clearCursor() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.PageCursor ensureCursor() => $_ensure(1);
}

class SearchRoomSubscriptionsResponse extends $pb.GeneratedMessage {
  factory SearchRoomSubscriptionsResponse({
    $core.String? roomId,
    $core.Iterable<RoomSubscription>? members,
    $core.String? nextCursor,
    $core.String? prevCursor,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (members != null) result.members.addAll(members);
    if (nextCursor != null) result.nextCursor = nextCursor;
    if (prevCursor != null) result.prevCursor = prevCursor;
    return result;
  }

  SearchRoomSubscriptionsResponse._();

  factory SearchRoomSubscriptionsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchRoomSubscriptionsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchRoomSubscriptionsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..pc<RoomSubscription>(
        2, _omitFieldNames ? '' : 'members', $pb.PbFieldType.PM,
        subBuilder: RoomSubscription.create)
    ..aOS(4, _omitFieldNames ? '' : 'nextCursor')
    ..aOS(5, _omitFieldNames ? '' : 'prevCursor')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchRoomSubscriptionsResponse clone() =>
      SearchRoomSubscriptionsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchRoomSubscriptionsResponse copyWith(
          void Function(SearchRoomSubscriptionsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as SearchRoomSubscriptionsResponse))
          as SearchRoomSubscriptionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchRoomSubscriptionsResponse create() =>
      SearchRoomSubscriptionsResponse._();
  @$core.override
  SearchRoomSubscriptionsResponse createEmptyInstance() => create();
  static $pb.PbList<SearchRoomSubscriptionsResponse> createRepeated() =>
      $pb.PbList<SearchRoomSubscriptionsResponse>();
  @$core.pragma('dart2js:noInline')
  static SearchRoomSubscriptionsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchRoomSubscriptionsResponse>(
          create);
  static SearchRoomSubscriptionsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<RoomSubscription> get members => $_getList(1);

  @$pb.TagNumber(4)
  $core.String get nextCursor => $_getSZ(2);
  @$pb.TagNumber(4)
  set nextCursor($core.String value) => $_setString(2, value);
  @$pb.TagNumber(4)
  $core.bool hasNextCursor() => $_has(2);
  @$pb.TagNumber(4)
  void clearNextCursor() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get prevCursor => $_getSZ(3);
  @$pb.TagNumber(5)
  set prevCursor($core.String value) => $_setString(3, value);
  @$pb.TagNumber(5)
  $core.bool hasPrevCursor() => $_has(3);
  @$pb.TagNumber(5)
  void clearPrevCursor() => $_clearField(5);
}

/// SubscriptionSettings holds per-room preferences for a member.
class SubscriptionSettings extends $pb.GeneratedMessage {
  factory SubscriptionSettings({
    $core.String? subscriptionId,
    $core.String? roomId,
    NotificationLevel? notificationLevel,
    $core.bool? muted,
    $core.bool? archived,
    $core.bool? pinned,
  }) {
    final result = create();
    if (subscriptionId != null) result.subscriptionId = subscriptionId;
    if (roomId != null) result.roomId = roomId;
    if (notificationLevel != null) result.notificationLevel = notificationLevel;
    if (muted != null) result.muted = muted;
    if (archived != null) result.archived = archived;
    if (pinned != null) result.pinned = pinned;
    return result;
  }

  SubscriptionSettings._();

  factory SubscriptionSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubscriptionSettings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscriptionSettings',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'subscriptionId')
    ..aOS(2, _omitFieldNames ? '' : 'roomId')
    ..e<NotificationLevel>(
        3, _omitFieldNames ? '' : 'notificationLevel', $pb.PbFieldType.OE,
        defaultOrMaker: NotificationLevel.NOTIFICATION_LEVEL_UNSPECIFIED,
        valueOf: NotificationLevel.valueOf,
        enumValues: NotificationLevel.values)
    ..aOB(4, _omitFieldNames ? '' : 'muted')
    ..aOB(5, _omitFieldNames ? '' : 'archived')
    ..aOB(6, _omitFieldNames ? '' : 'pinned')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionSettings clone() =>
      SubscriptionSettings()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionSettings copyWith(void Function(SubscriptionSettings) updates) =>
      super.copyWith((message) => updates(message as SubscriptionSettings))
          as SubscriptionSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscriptionSettings create() => SubscriptionSettings._();
  @$core.override
  SubscriptionSettings createEmptyInstance() => create();
  static $pb.PbList<SubscriptionSettings> createRepeated() =>
      $pb.PbList<SubscriptionSettings>();
  @$core.pragma('dart2js:noInline')
  static SubscriptionSettings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscriptionSettings>(create);
  static SubscriptionSettings? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get subscriptionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set subscriptionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSubscriptionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubscriptionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get roomId => $_getSZ(1);
  @$pb.TagNumber(2)
  set roomId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRoomId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRoomId() => $_clearField(2);

  @$pb.TagNumber(3)
  NotificationLevel get notificationLevel => $_getN(2);
  @$pb.TagNumber(3)
  set notificationLevel(NotificationLevel value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasNotificationLevel() => $_has(2);
  @$pb.TagNumber(3)
  void clearNotificationLevel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get muted => $_getBF(3);
  @$pb.TagNumber(4)
  set muted($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMuted() => $_has(3);
  @$pb.TagNumber(4)
  void clearMuted() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get archived => $_getBF(4);
  @$pb.TagNumber(5)
  set archived($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasArchived() => $_has(4);
  @$pb.TagNumber(5)
  void clearArchived() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get pinned => $_getBF(5);
  @$pb.TagNumber(6)
  set pinned($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPinned() => $_has(5);
  @$pb.TagNumber(6)
  void clearPinned() => $_clearField(6);
}

class GetSubscriptionSettingsRequest extends $pb.GeneratedMessage {
  factory GetSubscriptionSettingsRequest({
    $core.String? roomId,
    $core.String? subscriptionId,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (subscriptionId != null) result.subscriptionId = subscriptionId;
    return result;
  }

  GetSubscriptionSettingsRequest._();

  factory GetSubscriptionSettingsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSubscriptionSettingsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSubscriptionSettingsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..aOS(2, _omitFieldNames ? '' : 'subscriptionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSubscriptionSettingsRequest clone() =>
      GetSubscriptionSettingsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSubscriptionSettingsRequest copyWith(
          void Function(GetSubscriptionSettingsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as GetSubscriptionSettingsRequest))
          as GetSubscriptionSettingsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSubscriptionSettingsRequest create() =>
      GetSubscriptionSettingsRequest._();
  @$core.override
  GetSubscriptionSettingsRequest createEmptyInstance() => create();
  static $pb.PbList<GetSubscriptionSettingsRequest> createRepeated() =>
      $pb.PbList<GetSubscriptionSettingsRequest>();
  @$core.pragma('dart2js:noInline')
  static GetSubscriptionSettingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSubscriptionSettingsRequest>(create);
  static GetSubscriptionSettingsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get subscriptionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set subscriptionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSubscriptionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubscriptionId() => $_clearField(2);
}

class GetSubscriptionSettingsResponse extends $pb.GeneratedMessage {
  factory GetSubscriptionSettingsResponse({
    SubscriptionSettings? settings,
    $1.ErrorDetail? error,
  }) {
    final result = create();
    if (settings != null) result.settings = settings;
    if (error != null) result.error = error;
    return result;
  }

  GetSubscriptionSettingsResponse._();

  factory GetSubscriptionSettingsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSubscriptionSettingsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSubscriptionSettingsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOM<SubscriptionSettings>(1, _omitFieldNames ? '' : 'settings',
        subBuilder: SubscriptionSettings.create)
    ..aOM<$1.ErrorDetail>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.ErrorDetail.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSubscriptionSettingsResponse clone() =>
      GetSubscriptionSettingsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSubscriptionSettingsResponse copyWith(
          void Function(GetSubscriptionSettingsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetSubscriptionSettingsResponse))
          as GetSubscriptionSettingsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSubscriptionSettingsResponse create() =>
      GetSubscriptionSettingsResponse._();
  @$core.override
  GetSubscriptionSettingsResponse createEmptyInstance() => create();
  static $pb.PbList<GetSubscriptionSettingsResponse> createRepeated() =>
      $pb.PbList<GetSubscriptionSettingsResponse>();
  @$core.pragma('dart2js:noInline')
  static GetSubscriptionSettingsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSubscriptionSettingsResponse>(
          create);
  static GetSubscriptionSettingsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SubscriptionSettings get settings => $_getN(0);
  @$pb.TagNumber(1)
  set settings(SubscriptionSettings value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSettings() => $_has(0);
  @$pb.TagNumber(1)
  void clearSettings() => $_clearField(1);
  @$pb.TagNumber(1)
  SubscriptionSettings ensureSettings() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ErrorDetail get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($1.ErrorDetail value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ErrorDetail ensureError() => $_ensure(1);
}

class UpdateSubscriptionSettingsRequest extends $pb.GeneratedMessage {
  factory UpdateSubscriptionSettingsRequest({
    $core.String? roomId,
    $core.String? subscriptionId,
    NotificationLevel? notificationLevel,
    $core.bool? muted,
    $core.bool? archived,
    $core.bool? pinned,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (subscriptionId != null) result.subscriptionId = subscriptionId;
    if (notificationLevel != null) result.notificationLevel = notificationLevel;
    if (muted != null) result.muted = muted;
    if (archived != null) result.archived = archived;
    if (pinned != null) result.pinned = pinned;
    return result;
  }

  UpdateSubscriptionSettingsRequest._();

  factory UpdateSubscriptionSettingsRequest.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateSubscriptionSettingsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateSubscriptionSettingsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..aOS(2, _omitFieldNames ? '' : 'subscriptionId')
    ..e<NotificationLevel>(
        3, _omitFieldNames ? '' : 'notificationLevel', $pb.PbFieldType.OE,
        defaultOrMaker: NotificationLevel.NOTIFICATION_LEVEL_UNSPECIFIED,
        valueOf: NotificationLevel.valueOf,
        enumValues: NotificationLevel.values)
    ..aOB(4, _omitFieldNames ? '' : 'muted')
    ..aOB(5, _omitFieldNames ? '' : 'archived')
    ..aOB(6, _omitFieldNames ? '' : 'pinned')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSubscriptionSettingsRequest clone() =>
      UpdateSubscriptionSettingsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSubscriptionSettingsRequest copyWith(
          void Function(UpdateSubscriptionSettingsRequest) updates) =>
      super.copyWith((message) =>
              updates(message as UpdateSubscriptionSettingsRequest))
          as UpdateSubscriptionSettingsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateSubscriptionSettingsRequest create() =>
      UpdateSubscriptionSettingsRequest._();
  @$core.override
  UpdateSubscriptionSettingsRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateSubscriptionSettingsRequest> createRepeated() =>
      $pb.PbList<UpdateSubscriptionSettingsRequest>();
  @$core.pragma('dart2js:noInline')
  static UpdateSubscriptionSettingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateSubscriptionSettingsRequest>(
          create);
  static UpdateSubscriptionSettingsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get subscriptionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set subscriptionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSubscriptionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubscriptionId() => $_clearField(2);

  @$pb.TagNumber(3)
  NotificationLevel get notificationLevel => $_getN(2);
  @$pb.TagNumber(3)
  set notificationLevel(NotificationLevel value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasNotificationLevel() => $_has(2);
  @$pb.TagNumber(3)
  void clearNotificationLevel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get muted => $_getBF(3);
  @$pb.TagNumber(4)
  set muted($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMuted() => $_has(3);
  @$pb.TagNumber(4)
  void clearMuted() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get archived => $_getBF(4);
  @$pb.TagNumber(5)
  set archived($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasArchived() => $_has(4);
  @$pb.TagNumber(5)
  void clearArchived() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get pinned => $_getBF(5);
  @$pb.TagNumber(6)
  set pinned($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPinned() => $_has(5);
  @$pb.TagNumber(6)
  void clearPinned() => $_clearField(6);
}

class UpdateSubscriptionSettingsResponse extends $pb.GeneratedMessage {
  factory UpdateSubscriptionSettingsResponse({
    SubscriptionSettings? settings,
    $1.ErrorDetail? error,
  }) {
    final result = create();
    if (settings != null) result.settings = settings;
    if (error != null) result.error = error;
    return result;
  }

  UpdateSubscriptionSettingsResponse._();

  factory UpdateSubscriptionSettingsResponse.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateSubscriptionSettingsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateSubscriptionSettingsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOM<SubscriptionSettings>(1, _omitFieldNames ? '' : 'settings',
        subBuilder: SubscriptionSettings.create)
    ..aOM<$1.ErrorDetail>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.ErrorDetail.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSubscriptionSettingsResponse clone() =>
      UpdateSubscriptionSettingsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSubscriptionSettingsResponse copyWith(
          void Function(UpdateSubscriptionSettingsResponse) updates) =>
      super.copyWith((message) =>
              updates(message as UpdateSubscriptionSettingsResponse))
          as UpdateSubscriptionSettingsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateSubscriptionSettingsResponse create() =>
      UpdateSubscriptionSettingsResponse._();
  @$core.override
  UpdateSubscriptionSettingsResponse createEmptyInstance() => create();
  static $pb.PbList<UpdateSubscriptionSettingsResponse> createRepeated() =>
      $pb.PbList<UpdateSubscriptionSettingsResponse>();
  @$core.pragma('dart2js:noInline')
  static UpdateSubscriptionSettingsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateSubscriptionSettingsResponse>(
          create);
  static UpdateSubscriptionSettingsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SubscriptionSettings get settings => $_getN(0);
  @$pb.TagNumber(1)
  set settings(SubscriptionSettings value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSettings() => $_has(0);
  @$pb.TagNumber(1)
  void clearSettings() => $_clearField(1);
  @$pb.TagNumber(1)
  SubscriptionSettings ensureSettings() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ErrorDetail get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($1.ErrorDetail value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ErrorDetail ensureError() => $_ensure(1);
}

class LiveRequest extends $pb.GeneratedMessage {
  factory LiveRequest({
    $1.ContactLink? source,
    $core.Iterable<$0.ClientCommand>? clientStates,
  }) {
    final result = create();
    if (source != null) result.source = source;
    if (clientStates != null) result.clientStates.addAll(clientStates);
    return result;
  }

  LiveRequest._();

  factory LiveRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOM<$1.ContactLink>(2, _omitFieldNames ? '' : 'source',
        subBuilder: $1.ContactLink.create)
    ..pc<$0.ClientCommand>(
        3, _omitFieldNames ? '' : 'clientStates', $pb.PbFieldType.PM,
        subBuilder: $0.ClientCommand.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveRequest clone() => LiveRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveRequest copyWith(void Function(LiveRequest) updates) =>
      super.copyWith((message) => updates(message as LiveRequest))
          as LiveRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveRequest create() => LiveRequest._();
  @$core.override
  LiveRequest createEmptyInstance() => create();
  static $pb.PbList<LiveRequest> createRepeated() => $pb.PbList<LiveRequest>();
  @$core.pragma('dart2js:noInline')
  static LiveRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveRequest>(create);
  static LiveRequest? _defaultInstance;

  @$pb.TagNumber(2)
  $1.ContactLink get source => $_getN(0);
  @$pb.TagNumber(2)
  set source($1.ContactLink value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSource() => $_has(0);
  @$pb.TagNumber(2)
  void clearSource() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ContactLink ensureSource() => $_ensure(0);

  @$pb.TagNumber(3)
  $pb.PbList<$0.ClientCommand> get clientStates => $_getList(1);
}

class LiveResponse extends $pb.GeneratedMessage {
  factory LiveResponse({
    $1.ErrorDetail? error,
  }) {
    final result = create();
    if (error != null) result.error = error;
    return result;
  }

  LiveResponse._();

  factory LiveResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOM<$1.ErrorDetail>(1, _omitFieldNames ? '' : 'error',
        subBuilder: $1.ErrorDetail.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveResponse clone() => LiveResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveResponse copyWith(void Function(LiveResponse) updates) =>
      super.copyWith((message) => updates(message as LiveResponse))
          as LiveResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveResponse create() => LiveResponse._();
  @$core.override
  LiveResponse createEmptyInstance() => create();
  static $pb.PbList<LiveResponse> createRepeated() =>
      $pb.PbList<LiveResponse>();
  @$core.pragma('dart2js:noInline')
  static LiveResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveResponse>(create);
  static LiveResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $1.ErrorDetail get error => $_getN(0);
  @$pb.TagNumber(1)
  set error($1.ErrorDetail value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.ErrorDetail ensureError() => $_ensure(0);
}

/// Proposal represents a pending change that requires approval before execution.
class Proposal extends $pb.GeneratedMessage {
  factory Proposal({
    $core.String? id,
    $core.String? roomId,
    ProposalType? type,
    ProposalState? state,
    $core.String? requestedBy,
    $2.Struct? payload,
    $3.Timestamp? createdAt,
    $3.Timestamp? expiresAt,
    $core.String? resolvedBy,
    $3.Timestamp? resolvedAt,
    $core.String? reason,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (roomId != null) result.roomId = roomId;
    if (type != null) result.type = type;
    if (state != null) result.state = state;
    if (requestedBy != null) result.requestedBy = requestedBy;
    if (payload != null) result.payload = payload;
    if (createdAt != null) result.createdAt = createdAt;
    if (expiresAt != null) result.expiresAt = expiresAt;
    if (resolvedBy != null) result.resolvedBy = resolvedBy;
    if (resolvedAt != null) result.resolvedAt = resolvedAt;
    if (reason != null) result.reason = reason;
    return result;
  }

  Proposal._();

  factory Proposal.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Proposal.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Proposal',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'roomId')
    ..e<ProposalType>(3, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker: ProposalType.PROPOSAL_TYPE_UNSPECIFIED,
        valueOf: ProposalType.valueOf,
        enumValues: ProposalType.values)
    ..e<ProposalState>(4, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker: ProposalState.PROPOSAL_STATE_UNSPECIFIED,
        valueOf: ProposalState.valueOf,
        enumValues: ProposalState.values)
    ..aOS(5, _omitFieldNames ? '' : 'requestedBy')
    ..aOM<$2.Struct>(6, _omitFieldNames ? '' : 'payload',
        subBuilder: $2.Struct.create)
    ..aOM<$3.Timestamp>(7, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $3.Timestamp.create)
    ..aOM<$3.Timestamp>(8, _omitFieldNames ? '' : 'expiresAt',
        subBuilder: $3.Timestamp.create)
    ..aOS(9, _omitFieldNames ? '' : 'resolvedBy')
    ..aOM<$3.Timestamp>(10, _omitFieldNames ? '' : 'resolvedAt',
        subBuilder: $3.Timestamp.create)
    ..aOS(11, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Proposal clone() => Proposal()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Proposal copyWith(void Function(Proposal) updates) =>
      super.copyWith((message) => updates(message as Proposal)) as Proposal;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Proposal create() => Proposal._();
  @$core.override
  Proposal createEmptyInstance() => create();
  static $pb.PbList<Proposal> createRepeated() => $pb.PbList<Proposal>();
  @$core.pragma('dart2js:noInline')
  static Proposal getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Proposal>(create);
  static Proposal? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get roomId => $_getSZ(1);
  @$pb.TagNumber(2)
  set roomId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRoomId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRoomId() => $_clearField(2);

  @$pb.TagNumber(3)
  ProposalType get type => $_getN(2);
  @$pb.TagNumber(3)
  set type(ProposalType value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  @$pb.TagNumber(4)
  ProposalState get state => $_getN(3);
  @$pb.TagNumber(4)
  set state(ProposalState value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasState() => $_has(3);
  @$pb.TagNumber(4)
  void clearState() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get requestedBy => $_getSZ(4);
  @$pb.TagNumber(5)
  set requestedBy($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRequestedBy() => $_has(4);
  @$pb.TagNumber(5)
  void clearRequestedBy() => $_clearField(5);

  @$pb.TagNumber(6)
  $2.Struct get payload => $_getN(5);
  @$pb.TagNumber(6)
  set payload($2.Struct value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasPayload() => $_has(5);
  @$pb.TagNumber(6)
  void clearPayload() => $_clearField(6);
  @$pb.TagNumber(6)
  $2.Struct ensurePayload() => $_ensure(5);

  @$pb.TagNumber(7)
  $3.Timestamp get createdAt => $_getN(6);
  @$pb.TagNumber(7)
  set createdAt($3.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasCreatedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearCreatedAt() => $_clearField(7);
  @$pb.TagNumber(7)
  $3.Timestamp ensureCreatedAt() => $_ensure(6);

  @$pb.TagNumber(8)
  $3.Timestamp get expiresAt => $_getN(7);
  @$pb.TagNumber(8)
  set expiresAt($3.Timestamp value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasExpiresAt() => $_has(7);
  @$pb.TagNumber(8)
  void clearExpiresAt() => $_clearField(8);
  @$pb.TagNumber(8)
  $3.Timestamp ensureExpiresAt() => $_ensure(7);

  @$pb.TagNumber(9)
  $core.String get resolvedBy => $_getSZ(8);
  @$pb.TagNumber(9)
  set resolvedBy($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasResolvedBy() => $_has(8);
  @$pb.TagNumber(9)
  void clearResolvedBy() => $_clearField(9);

  @$pb.TagNumber(10)
  $3.Timestamp get resolvedAt => $_getN(9);
  @$pb.TagNumber(10)
  set resolvedAt($3.Timestamp value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasResolvedAt() => $_has(9);
  @$pb.TagNumber(10)
  void clearResolvedAt() => $_clearField(10);
  @$pb.TagNumber(10)
  $3.Timestamp ensureResolvedAt() => $_ensure(9);

  @$pb.TagNumber(11)
  $core.String get reason => $_getSZ(10);
  @$pb.TagNumber(11)
  set reason($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasReason() => $_has(10);
  @$pb.TagNumber(11)
  void clearReason() => $_clearField(11);
}

class ListProposalsRequest extends $pb.GeneratedMessage {
  factory ListProposalsRequest({
    $core.String? roomId,
    ProposalState? state,
    $1.PageCursor? cursor,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (state != null) result.state = state;
    if (cursor != null) result.cursor = cursor;
    return result;
  }

  ListProposalsRequest._();

  factory ListProposalsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListProposalsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListProposalsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..e<ProposalState>(2, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker: ProposalState.PROPOSAL_STATE_UNSPECIFIED,
        valueOf: ProposalState.valueOf,
        enumValues: ProposalState.values)
    ..aOM<$1.PageCursor>(3, _omitFieldNames ? '' : 'cursor',
        subBuilder: $1.PageCursor.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListProposalsRequest clone() =>
      ListProposalsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListProposalsRequest copyWith(void Function(ListProposalsRequest) updates) =>
      super.copyWith((message) => updates(message as ListProposalsRequest))
          as ListProposalsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListProposalsRequest create() => ListProposalsRequest._();
  @$core.override
  ListProposalsRequest createEmptyInstance() => create();
  static $pb.PbList<ListProposalsRequest> createRepeated() =>
      $pb.PbList<ListProposalsRequest>();
  @$core.pragma('dart2js:noInline')
  static ListProposalsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListProposalsRequest>(create);
  static ListProposalsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);

  /// Optional: filter by state (default: only PENDING)
  @$pb.TagNumber(2)
  ProposalState get state => $_getN(1);
  @$pb.TagNumber(2)
  set state(ProposalState value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasState() => $_has(1);
  @$pb.TagNumber(2)
  void clearState() => $_clearField(2);

  @$pb.TagNumber(3)
  $1.PageCursor get cursor => $_getN(2);
  @$pb.TagNumber(3)
  set cursor($1.PageCursor value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCursor() => $_has(2);
  @$pb.TagNumber(3)
  void clearCursor() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.PageCursor ensureCursor() => $_ensure(2);
}

class ListProposalsResponse extends $pb.GeneratedMessage {
  factory ListProposalsResponse({
    $core.Iterable<Proposal>? proposals,
    $core.String? nextCursor,
    $core.String? prevCursor,
  }) {
    final result = create();
    if (proposals != null) result.proposals.addAll(proposals);
    if (nextCursor != null) result.nextCursor = nextCursor;
    if (prevCursor != null) result.prevCursor = prevCursor;
    return result;
  }

  ListProposalsResponse._();

  factory ListProposalsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListProposalsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListProposalsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..pc<Proposal>(1, _omitFieldNames ? '' : 'proposals', $pb.PbFieldType.PM,
        subBuilder: Proposal.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextCursor')
    ..aOS(3, _omitFieldNames ? '' : 'prevCursor')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListProposalsResponse clone() =>
      ListProposalsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListProposalsResponse copyWith(
          void Function(ListProposalsResponse) updates) =>
      super.copyWith((message) => updates(message as ListProposalsResponse))
          as ListProposalsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListProposalsResponse create() => ListProposalsResponse._();
  @$core.override
  ListProposalsResponse createEmptyInstance() => create();
  static $pb.PbList<ListProposalsResponse> createRepeated() =>
      $pb.PbList<ListProposalsResponse>();
  @$core.pragma('dart2js:noInline')
  static ListProposalsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListProposalsResponse>(create);
  static ListProposalsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Proposal> get proposals => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get nextCursor => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextCursor($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextCursor() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextCursor() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get prevCursor => $_getSZ(2);
  @$pb.TagNumber(3)
  set prevCursor($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPrevCursor() => $_has(2);
  @$pb.TagNumber(3)
  void clearPrevCursor() => $_clearField(3);
}

class SubmitProposalRequest extends $pb.GeneratedMessage {
  factory SubmitProposalRequest({
    $core.String? roomId,
    $core.String? proposalId,
    ProposalAction? action,
    $core.String? reason,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (proposalId != null) result.proposalId = proposalId;
    if (action != null) result.action = action;
    if (reason != null) result.reason = reason;
    return result;
  }

  SubmitProposalRequest._();

  factory SubmitProposalRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubmitProposalRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubmitProposalRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..aOS(2, _omitFieldNames ? '' : 'proposalId')
    ..e<ProposalAction>(3, _omitFieldNames ? '' : 'action', $pb.PbFieldType.OE,
        defaultOrMaker: ProposalAction.PROPOSAL_ACTION_UNSPECIFIED,
        valueOf: ProposalAction.valueOf,
        enumValues: ProposalAction.values)
    ..aOS(4, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubmitProposalRequest clone() =>
      SubmitProposalRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubmitProposalRequest copyWith(
          void Function(SubmitProposalRequest) updates) =>
      super.copyWith((message) => updates(message as SubmitProposalRequest))
          as SubmitProposalRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubmitProposalRequest create() => SubmitProposalRequest._();
  @$core.override
  SubmitProposalRequest createEmptyInstance() => create();
  static $pb.PbList<SubmitProposalRequest> createRepeated() =>
      $pb.PbList<SubmitProposalRequest>();
  @$core.pragma('dart2js:noInline')
  static SubmitProposalRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubmitProposalRequest>(create);
  static SubmitProposalRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get proposalId => $_getSZ(1);
  @$pb.TagNumber(2)
  set proposalId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProposalId() => $_has(1);
  @$pb.TagNumber(2)
  void clearProposalId() => $_clearField(2);

  @$pb.TagNumber(3)
  ProposalAction get action => $_getN(2);
  @$pb.TagNumber(3)
  set action(ProposalAction value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAction() => $_has(2);
  @$pb.TagNumber(3)
  void clearAction() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get reason => $_getSZ(3);
  @$pb.TagNumber(4)
  set reason($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReason() => $_has(3);
  @$pb.TagNumber(4)
  void clearReason() => $_clearField(4);
}

class SubmitProposalResponse extends $pb.GeneratedMessage {
  factory SubmitProposalResponse({
    Proposal? proposal,
    $1.ErrorDetail? error,
  }) {
    final result = create();
    if (proposal != null) result.proposal = proposal;
    if (error != null) result.error = error;
    return result;
  }

  SubmitProposalResponse._();

  factory SubmitProposalResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubmitProposalResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubmitProposalResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOM<Proposal>(1, _omitFieldNames ? '' : 'proposal',
        subBuilder: Proposal.create)
    ..aOM<$1.ErrorDetail>(2, _omitFieldNames ? '' : 'error',
        subBuilder: $1.ErrorDetail.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubmitProposalResponse clone() =>
      SubmitProposalResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubmitProposalResponse copyWith(
          void Function(SubmitProposalResponse) updates) =>
      super.copyWith((message) => updates(message as SubmitProposalResponse))
          as SubmitProposalResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubmitProposalResponse create() => SubmitProposalResponse._();
  @$core.override
  SubmitProposalResponse createEmptyInstance() => create();
  static $pb.PbList<SubmitProposalResponse> createRepeated() =>
      $pb.PbList<SubmitProposalResponse>();
  @$core.pragma('dart2js:noInline')
  static SubmitProposalResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubmitProposalResponse>(create);
  static SubmitProposalResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Proposal get proposal => $_getN(0);
  @$pb.TagNumber(1)
  set proposal(Proposal value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProposal() => $_has(0);
  @$pb.TagNumber(1)
  void clearProposal() => $_clearField(1);
  @$pb.TagNumber(1)
  Proposal ensureProposal() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ErrorDetail get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($1.ErrorDetail value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ErrorDetail ensureError() => $_ensure(1);
}

class ResolveReplayCursorRequest extends $pb.GeneratedMessage {
  factory ResolveReplayCursorRequest({
    $core.String? profileId,
    $core.String? deviceId,
    $core.String? token,
  }) {
    final result = create();
    if (profileId != null) result.profileId = profileId;
    if (deviceId != null) result.deviceId = deviceId;
    if (token != null) result.token = token;
    return result;
  }

  ResolveReplayCursorRequest._();

  factory ResolveReplayCursorRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResolveReplayCursorRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResolveReplayCursorRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'profileId')
    ..aOS(2, _omitFieldNames ? '' : 'deviceId')
    ..aOS(3, _omitFieldNames ? '' : 'token')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResolveReplayCursorRequest clone() =>
      ResolveReplayCursorRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResolveReplayCursorRequest copyWith(
          void Function(ResolveReplayCursorRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ResolveReplayCursorRequest))
          as ResolveReplayCursorRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResolveReplayCursorRequest create() => ResolveReplayCursorRequest._();
  @$core.override
  ResolveReplayCursorRequest createEmptyInstance() => create();
  static $pb.PbList<ResolveReplayCursorRequest> createRepeated() =>
      $pb.PbList<ResolveReplayCursorRequest>();
  @$core.pragma('dart2js:noInline')
  static ResolveReplayCursorRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResolveReplayCursorRequest>(create);
  static ResolveReplayCursorRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get profileId => $_getSZ(0);
  @$pb.TagNumber(1)
  set profileId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProfileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfileId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get deviceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceId() => $_clearField(2);

  /// The resume token or event ID presented by the reconnecting client.
  @$pb.TagNumber(3)
  $core.String get token => $_getSZ(2);
  @$pb.TagNumber(3)
  set token($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearToken() => $_clearField(3);
}

class ResolveReplayCursorResponse extends $pb.GeneratedMessage {
  factory ResolveReplayCursorResponse({
    $core.String? cursor,
    $core.bool? found,
  }) {
    final result = create();
    if (cursor != null) result.cursor = cursor;
    if (found != null) result.found = found;
    return result;
  }

  ResolveReplayCursorResponse._();

  factory ResolveReplayCursorResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResolveReplayCursorResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResolveReplayCursorResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'cursor')
    ..aOB(2, _omitFieldNames ? '' : 'found')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResolveReplayCursorResponse clone() =>
      ResolveReplayCursorResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResolveReplayCursorResponse copyWith(
          void Function(ResolveReplayCursorResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ResolveReplayCursorResponse))
          as ResolveReplayCursorResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResolveReplayCursorResponse create() =>
      ResolveReplayCursorResponse._();
  @$core.override
  ResolveReplayCursorResponse createEmptyInstance() => create();
  static $pb.PbList<ResolveReplayCursorResponse> createRepeated() =>
      $pb.PbList<ResolveReplayCursorResponse>();
  @$core.pragma('dart2js:noInline')
  static ResolveReplayCursorResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResolveReplayCursorResponse>(create);
  static ResolveReplayCursorResponse? _defaultInstance;

  /// The resolved cursor ID, empty if the token could not be resolved.
  @$pb.TagNumber(1)
  $core.String get cursor => $_getSZ(0);
  @$pb.TagNumber(1)
  set cursor($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCursor() => $_has(0);
  @$pb.TagNumber(1)
  void clearCursor() => $_clearField(1);

  /// True if the token was successfully resolved to a cursor.
  @$pb.TagNumber(2)
  $core.bool get found => $_getBF(1);
  @$pb.TagNumber(2)
  set found($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFound() => $_has(1);
  @$pb.TagNumber(2)
  void clearFound() => $_clearField(2);
}

class GetLatestReplayCursorRequest extends $pb.GeneratedMessage {
  factory GetLatestReplayCursorRequest({
    $core.String? profileId,
    $core.String? deviceId,
  }) {
    final result = create();
    if (profileId != null) result.profileId = profileId;
    if (deviceId != null) result.deviceId = deviceId;
    return result;
  }

  GetLatestReplayCursorRequest._();

  factory GetLatestReplayCursorRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetLatestReplayCursorRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetLatestReplayCursorRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'profileId')
    ..aOS(2, _omitFieldNames ? '' : 'deviceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLatestReplayCursorRequest clone() =>
      GetLatestReplayCursorRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLatestReplayCursorRequest copyWith(
          void Function(GetLatestReplayCursorRequest) updates) =>
      super.copyWith(
              (message) => updates(message as GetLatestReplayCursorRequest))
          as GetLatestReplayCursorRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetLatestReplayCursorRequest create() =>
      GetLatestReplayCursorRequest._();
  @$core.override
  GetLatestReplayCursorRequest createEmptyInstance() => create();
  static $pb.PbList<GetLatestReplayCursorRequest> createRepeated() =>
      $pb.PbList<GetLatestReplayCursorRequest>();
  @$core.pragma('dart2js:noInline')
  static GetLatestReplayCursorRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetLatestReplayCursorRequest>(create);
  static GetLatestReplayCursorRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get profileId => $_getSZ(0);
  @$pb.TagNumber(1)
  set profileId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProfileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfileId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get deviceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceId() => $_clearField(2);
}

class GetLatestReplayCursorResponse extends $pb.GeneratedMessage {
  factory GetLatestReplayCursorResponse({
    $core.String? cursor,
  }) {
    final result = create();
    if (cursor != null) result.cursor = cursor;
    return result;
  }

  GetLatestReplayCursorResponse._();

  factory GetLatestReplayCursorResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetLatestReplayCursorResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetLatestReplayCursorResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'cursor')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLatestReplayCursorResponse clone() =>
      GetLatestReplayCursorResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLatestReplayCursorResponse copyWith(
          void Function(GetLatestReplayCursorResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetLatestReplayCursorResponse))
          as GetLatestReplayCursorResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetLatestReplayCursorResponse create() =>
      GetLatestReplayCursorResponse._();
  @$core.override
  GetLatestReplayCursorResponse createEmptyInstance() => create();
  static $pb.PbList<GetLatestReplayCursorResponse> createRepeated() =>
      $pb.PbList<GetLatestReplayCursorResponse>();
  @$core.pragma('dart2js:noInline')
  static GetLatestReplayCursorResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetLatestReplayCursorResponse>(create);
  static GetLatestReplayCursorResponse? _defaultInstance;

  /// The latest cursor ID for the device, empty if no replay entries exist.
  @$pb.TagNumber(1)
  $core.String get cursor => $_getSZ(0);
  @$pb.TagNumber(1)
  set cursor($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCursor() => $_has(0);
  @$pb.TagNumber(1)
  void clearCursor() => $_clearField(1);
}

class ListReplayEventsRequest extends $pb.GeneratedMessage {
  factory ListReplayEventsRequest({
    $core.String? profileId,
    $core.String? deviceId,
    $core.String? afterCursor,
    $core.String? upperBoundCursor,
    $core.int? limit,
  }) {
    final result = create();
    if (profileId != null) result.profileId = profileId;
    if (deviceId != null) result.deviceId = deviceId;
    if (afterCursor != null) result.afterCursor = afterCursor;
    if (upperBoundCursor != null) result.upperBoundCursor = upperBoundCursor;
    if (limit != null) result.limit = limit;
    return result;
  }

  ListReplayEventsRequest._();

  factory ListReplayEventsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListReplayEventsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListReplayEventsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'profileId')
    ..aOS(2, _omitFieldNames ? '' : 'deviceId')
    ..aOS(3, _omitFieldNames ? '' : 'afterCursor')
    ..aOS(4, _omitFieldNames ? '' : 'upperBoundCursor')
    ..a<$core.int>(5, _omitFieldNames ? '' : 'limit', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReplayEventsRequest clone() =>
      ListReplayEventsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReplayEventsRequest copyWith(
          void Function(ListReplayEventsRequest) updates) =>
      super.copyWith((message) => updates(message as ListReplayEventsRequest))
          as ListReplayEventsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListReplayEventsRequest create() => ListReplayEventsRequest._();
  @$core.override
  ListReplayEventsRequest createEmptyInstance() => create();
  static $pb.PbList<ListReplayEventsRequest> createRepeated() =>
      $pb.PbList<ListReplayEventsRequest>();
  @$core.pragma('dart2js:noInline')
  static ListReplayEventsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListReplayEventsRequest>(create);
  static ListReplayEventsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get profileId => $_getSZ(0);
  @$pb.TagNumber(1)
  set profileId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProfileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfileId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get deviceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceId() => $_clearField(2);

  /// Fetch events with cursor > after_cursor.
  @$pb.TagNumber(3)
  $core.String get afterCursor => $_getSZ(2);
  @$pb.TagNumber(3)
  set afterCursor($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAfterCursor() => $_has(2);
  @$pb.TagNumber(3)
  void clearAfterCursor() => $_clearField(3);

  /// Fetch events with cursor <= upper_bound_cursor.
  @$pb.TagNumber(4)
  $core.String get upperBoundCursor => $_getSZ(3);
  @$pb.TagNumber(4)
  set upperBoundCursor($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUpperBoundCursor() => $_has(3);
  @$pb.TagNumber(4)
  void clearUpperBoundCursor() => $_clearField(4);

  /// Maximum number of events to return per page.
  @$pb.TagNumber(5)
  $core.int get limit => $_getIZ(4);
  @$pb.TagNumber(5)
  set limit($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLimit() => $_has(4);
  @$pb.TagNumber(5)
  void clearLimit() => $_clearField(5);
}

/// A single replay entry containing a cursor ID and its serialized StreamResponse payload.
class ReplayEntry extends $pb.GeneratedMessage {
  factory ReplayEntry({
    $core.String? cursor,
    $core.List<$core.int>? responseData,
  }) {
    final result = create();
    if (cursor != null) result.cursor = cursor;
    if (responseData != null) result.responseData = responseData;
    return result;
  }

  ReplayEntry._();

  factory ReplayEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReplayEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReplayEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'cursor')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'responseData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReplayEntry clone() => ReplayEntry()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReplayEntry copyWith(void Function(ReplayEntry) updates) =>
      super.copyWith((message) => updates(message as ReplayEntry))
          as ReplayEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReplayEntry create() => ReplayEntry._();
  @$core.override
  ReplayEntry createEmptyInstance() => create();
  static $pb.PbList<ReplayEntry> createRepeated() => $pb.PbList<ReplayEntry>();
  @$core.pragma('dart2js:noInline')
  static ReplayEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReplayEntry>(create);
  static ReplayEntry? _defaultInstance;

  /// The replay cursor ID (DeviceReplayEvent.ID).
  @$pb.TagNumber(1)
  $core.String get cursor => $_getSZ(0);
  @$pb.TagNumber(1)
  set cursor($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCursor() => $_has(0);
  @$pb.TagNumber(1)
  void clearCursor() => $_clearField(1);

  /// The serialized StreamResponse protobuf bytes.
  @$pb.TagNumber(2)
  $core.List<$core.int> get responseData => $_getN(1);
  @$pb.TagNumber(2)
  set responseData($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasResponseData() => $_has(1);
  @$pb.TagNumber(2)
  void clearResponseData() => $_clearField(2);
}

class ListReplayEventsResponse extends $pb.GeneratedMessage {
  factory ListReplayEventsResponse({
    $core.Iterable<ReplayEntry>? entries,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    return result;
  }

  ListReplayEventsResponse._();

  factory ListReplayEventsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListReplayEventsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListReplayEventsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..pc<ReplayEntry>(1, _omitFieldNames ? '' : 'entries', $pb.PbFieldType.PM,
        subBuilder: ReplayEntry.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReplayEventsResponse clone() =>
      ListReplayEventsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReplayEventsResponse copyWith(
          void Function(ListReplayEventsResponse) updates) =>
      super.copyWith((message) => updates(message as ListReplayEventsResponse))
          as ListReplayEventsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListReplayEventsResponse create() => ListReplayEventsResponse._();
  @$core.override
  ListReplayEventsResponse createEmptyInstance() => create();
  static $pb.PbList<ListReplayEventsResponse> createRepeated() =>
      $pb.PbList<ListReplayEventsResponse>();
  @$core.pragma('dart2js:noInline')
  static ListReplayEventsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListReplayEventsResponse>(create);
  static ListReplayEventsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ReplayEntry> get entries => $_getList(0);
}

class ChatServiceApi {
  final $pb.RpcClient _client;

  ChatServiceApi(this._client);

  /// Send an event (unified message model). Idempotent if idempotency_key is provided.
  $async.Future<SendEventResponse> sendEvent(
          $pb.ClientContext? ctx, SendEventRequest request) =>
      _client.invoke<SendEventResponse>(
          ctx, 'ChatService', 'SendEvent', request, SendEventResponse());

  /// Fetch a single event by ID. Used for deep-linking, thread rendering, and verification.
  $async.Future<GetEventResponse> getEvent(
          $pb.ClientContext? ctx, GetEventRequest request) =>
      _client.invoke<GetEventResponse>(
          ctx, 'ChatService', 'GetEvent', request, GetEventResponse());

  /// Fetch history for a room. Cursor-based paging (cursor = opaque server token).
  $async.Future<GetHistoryResponse> getHistory(
          $pb.ClientContext? ctx, GetHistoryRequest request) =>
      _client.invoke<GetHistoryResponse>(
          ctx, 'ChatService', 'GetHistory', request, GetHistoryResponse());

  /// Fetch a single room by ID.
  $async.Future<GetRoomResponse> getRoom(
          $pb.ClientContext? ctx, GetRoomRequest request) =>
      _client.invoke<GetRoomResponse>(
          ctx, 'ChatService', 'GetRoom', request, GetRoomResponse());
  $async.Future<CreateRoomResponse> createRoom(
          $pb.ClientContext? ctx, CreateRoomRequest request) =>
      _client.invoke<CreateRoomResponse>(
          ctx, 'ChatService', 'CreateRoom', request, CreateRoomResponse());
  $async.Future<SearchRoomsResponse> searchRooms(
          $pb.ClientContext? ctx, SearchRoomsRequest request) =>
      _client.invoke<SearchRoomsResponse>(
          ctx, 'ChatService', 'SearchRooms', request, SearchRoomsResponse());
  $async.Future<UpdateRoomResponse> updateRoom(
          $pb.ClientContext? ctx, UpdateRoomRequest request) =>
      _client.invoke<UpdateRoomResponse>(
          ctx, 'ChatService', 'UpdateRoom', request, UpdateRoomResponse());
  $async.Future<DeleteRoomResponse> deleteRoom(
          $pb.ClientContext? ctx, DeleteRoomRequest request) =>
      _client.invoke<DeleteRoomResponse>(
          ctx, 'ChatService', 'DeleteRoom', request, DeleteRoomResponse());

  /// Subscriptionship & roles
  $async.Future<AddRoomSubscriptionsResponse> addRoomSubscriptions(
          $pb.ClientContext? ctx, AddRoomSubscriptionsRequest request) =>
      _client.invoke<AddRoomSubscriptionsResponse>(ctx, 'ChatService',
          'AddRoomSubscriptions', request, AddRoomSubscriptionsResponse());
  $async.Future<RemoveRoomSubscriptionsResponse> removeRoomSubscriptions(
          $pb.ClientContext? ctx, RemoveRoomSubscriptionsRequest request) =>
      _client.invoke<RemoveRoomSubscriptionsResponse>(
          ctx,
          'ChatService',
          'RemoveRoomSubscriptions',
          request,
          RemoveRoomSubscriptionsResponse());
  $async.Future<UpdateSubscriptionRoleResponse> updateSubscriptionRole(
          $pb.ClientContext? ctx, UpdateSubscriptionRoleRequest request) =>
      _client.invoke<UpdateSubscriptionRoleResponse>(ctx, 'ChatService',
          'UpdateSubscriptionRole', request, UpdateSubscriptionRoleResponse());

  /// The Stawi account of the other person in the caller's DM. The caller
  /// must be a person and an active member of the DIRECT room, the room must
  /// hold exactly two active members, and the partner must have taken part
  /// (started the DM or written in it); anything else is refused without
  /// saying anything about the room. An empty account means the partner has
  /// no Stawi account yet.
  $async.Future<GetDirectPartnerAccountResponse> getDirectPartnerAccount(
          $pb.ClientContext? ctx, GetDirectPartnerAccountRequest request) =>
      _client.invoke<GetDirectPartnerAccountResponse>(
          ctx,
          'ChatService',
          'GetDirectPartnerAccount',
          request,
          GetDirectPartnerAccountResponse());
  $async.Future<SearchRoomSubscriptionsResponse> searchRoomSubscriptions(
          $pb.ClientContext? ctx, SearchRoomSubscriptionsRequest request) =>
      _client.invoke<SearchRoomSubscriptionsResponse>(
          ctx,
          'ChatService',
          'SearchRoomSubscriptions',
          request,
          SearchRoomSubscriptionsResponse());

  /// Get per-room subscription settings for a member (notification preferences, mute, archive)
  $async.Future<GetSubscriptionSettingsResponse> getSubscriptionSettings(
          $pb.ClientContext? ctx, GetSubscriptionSettingsRequest request) =>
      _client.invoke<GetSubscriptionSettingsResponse>(
          ctx,
          'ChatService',
          'GetSubscriptionSettings',
          request,
          GetSubscriptionSettingsResponse());

  /// Update per-room subscription settings for a member
  $async.Future<UpdateSubscriptionSettingsResponse> updateSubscriptionSettings(
          $pb.ClientContext? ctx, UpdateSubscriptionSettingsRequest request) =>
      _client.invoke<UpdateSubscriptionSettingsResponse>(
          ctx,
          'ChatService',
          'UpdateSubscriptionSettings',
          request,
          UpdateSubscriptionSettingsResponse());

  /// Update different states that the client can be in for room subscriptions awareness
  $async.Future<LiveResponse> live(
          $pb.ClientContext? ctx, LiveRequest request) =>
      _client.invoke<LiveResponse>(
          ctx, 'ChatService', 'Live', request, LiveResponse());

  /// List pending proposals for a room
  $async.Future<ListProposalsResponse> listProposals(
          $pb.ClientContext? ctx, ListProposalsRequest request) =>
      _client.invoke<ListProposalsResponse>(ctx, 'ChatService', 'ListProposals',
          request, ListProposalsResponse());

  /// Submit a decision on a pending proposal (approve or reject)
  $async.Future<SubmitProposalResponse> submitProposal(
          $pb.ClientContext? ctx, SubmitProposalRequest request) =>
      _client.invoke<SubmitProposalResponse>(ctx, 'ChatService',
          'SubmitProposal', request, SubmitProposalResponse());

  /// Resolve a resume token or event ID to a replay cursor for a device.
  $async.Future<ResolveReplayCursorResponse> resolveReplayCursor(
          $pb.ClientContext? ctx, ResolveReplayCursorRequest request) =>
      _client.invoke<ResolveReplayCursorResponse>(ctx, 'ChatService',
          'ResolveReplayCursor', request, ResolveReplayCursorResponse());

  /// Get the latest replay cursor for a device (used as upper bound during replay).
  $async.Future<GetLatestReplayCursorResponse> getLatestReplayCursor(
          $pb.ClientContext? ctx, GetLatestReplayCursorRequest request) =>
      _client.invoke<GetLatestReplayCursorResponse>(ctx, 'ChatService',
          'GetLatestReplayCursor', request, GetLatestReplayCursorResponse());

  /// List replay events after a cursor for a device (paginated catch-up).
  $async.Future<ListReplayEventsResponse> listReplayEvents(
          $pb.ClientContext? ctx, ListReplayEventsRequest request) =>
      _client.invoke<ListReplayEventsResponse>(ctx, 'ChatService',
          'ListReplayEvents', request, ListReplayEventsResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
