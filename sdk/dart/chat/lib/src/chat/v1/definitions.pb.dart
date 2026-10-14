// This is a generated file - do not edit.
//
// Generated from chat/v1/definitions.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $0;

import '../../common/v1/common.pb.dart' as $2;
import 'definitions.pbenum.dart';
import 'payload_type.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'definitions.pbenum.dart';

/// Unified message (user / bot / system / signalling)
class RoomEvent extends $pb.GeneratedMessage {
  factory RoomEvent({
    $core.String? id,
    $core.String? roomId,
    $core.String? subscriptionId,
    RoomEventType? type,
    $0.Timestamp? sentAt,
    $core.bool? edited,
    $core.bool? redacted,
    $core.String? parentId,
    $1.Payload? payload,
  }) {
    final result = RoomEvent._();
    if (id != null) result.id = id;
    if (roomId != null) result.roomId = roomId;
    if (subscriptionId != null) result.subscriptionId = subscriptionId;
    if (type != null) result.type = type;
    if (sentAt != null) result.sentAt = sentAt;
    if (edited != null) result.edited = edited;
    if (redacted != null) result.redacted = redacted;
    if (parentId != null) result.parentId = parentId;
    if (payload != null) result.payload = payload;
    return result;
  }

  RoomEvent._();

  factory RoomEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RoomEvent()..mergeFromBuffer(data, registry);
  factory RoomEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RoomEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RoomEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: RoomEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'roomId')
    ..aOS(3, _omitFieldNames ? '' : 'subscriptionId')
    ..aE<RoomEventType>(4, _omitFieldNames ? '' : 'type',
        enumValues: RoomEventType.values)
    ..aOM<$0.Timestamp>(7, _omitFieldNames ? '' : 'sentAt',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOB(8, _omitFieldNames ? '' : 'edited')
    ..aOB(9, _omitFieldNames ? '' : 'redacted')
    ..aOS(10, _omitFieldNames ? '' : 'parentId')
    ..aOM<$1.Payload>(15, _omitFieldNames ? '' : 'payload',
        subBuilder: $1.Payload.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoomEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoomEvent copyWith(void Function(RoomEvent) updates) =>
      super.copyWith((message) => updates(message as RoomEvent)) as RoomEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RoomEvent() / RoomEvent.new instead')
  static RoomEvent create() => RoomEvent._();
  static $pb.GeneratedMessage $_createMessage() => RoomEvent._();
  @$core.override
  RoomEvent createEmptyInstance() => RoomEvent._();
  @$core.pragma('dart2js:noInline')
  static RoomEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RoomEvent>(RoomEvent.$_createMessage);
  static RoomEvent? _defaultInstance;

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
  $core.String get subscriptionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set subscriptionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSubscriptionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSubscriptionId() => $_clearField(3);

  @$pb.TagNumber(4)
  RoomEventType get type => $_getN(3);
  @$pb.TagNumber(4)
  set type(RoomEventType value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasType() => $_has(3);
  @$pb.TagNumber(4)
  void clearType() => $_clearField(4);

  @$pb.TagNumber(7)
  $0.Timestamp get sentAt => $_getN(4);
  @$pb.TagNumber(7)
  set sentAt($0.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasSentAt() => $_has(4);
  @$pb.TagNumber(7)
  void clearSentAt() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.Timestamp ensureSentAt() => $_ensure(4);

  @$pb.TagNumber(8)
  $core.bool get edited => $_getBF(5);
  @$pb.TagNumber(8)
  set edited($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(8)
  $core.bool hasEdited() => $_has(5);
  @$pb.TagNumber(8)
  void clearEdited() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get redacted => $_getBF(6);
  @$pb.TagNumber(9)
  set redacted($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(9)
  $core.bool hasRedacted() => $_has(6);
  @$pb.TagNumber(9)
  void clearRedacted() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get parentId => $_getSZ(7);
  @$pb.TagNumber(10)
  set parentId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(10)
  $core.bool hasParentId() => $_has(7);
  @$pb.TagNumber(10)
  void clearParentId() => $_clearField(10);

  @$pb.TagNumber(15)
  $1.Payload get payload => $_getN(8);
  @$pb.TagNumber(15)
  set payload($1.Payload value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasPayload() => $_has(8);
  @$pb.TagNumber(15)
  void clearPayload() => $_clearField(15);
  @$pb.TagNumber(15)
  $1.Payload ensurePayload() => $_ensure(8);
}

/// Acknowledgement for event(s) received; server uses it to free ephemeral delivery buffers.
/// ack_event_id: last event_id client processed (inclusive).
/// If error is set, indicates the event failed to send/process correctly.
class AckEvent extends $pb.GeneratedMessage {
  factory AckEvent({
    $core.String? roomId,
    $core.Iterable<$core.String>? eventId,
    $core.String? subscriptionId,
    $0.Timestamp? ackAt,
    $2.ErrorDetail? error,
  }) {
    final result = AckEvent._();
    if (roomId != null) result.roomId = roomId;
    if (eventId != null) result.eventId.addAll(eventId);
    if (subscriptionId != null) result.subscriptionId = subscriptionId;
    if (ackAt != null) result.ackAt = ackAt;
    if (error != null) result.error = error;
    return result;
  }

  AckEvent._();

  factory AckEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AckEvent()..mergeFromBuffer(data, registry);
  factory AckEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AckEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AckEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: AckEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..pPS(2, _omitFieldNames ? '' : 'eventId')
    ..aOS(3, _omitFieldNames ? '' : 'subscriptionId')
    ..aOM<$0.Timestamp>(4, _omitFieldNames ? '' : 'ackAt',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOM<$2.ErrorDetail>(7, _omitFieldNames ? '' : 'error',
        subBuilder: $2.ErrorDetail.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AckEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AckEvent copyWith(void Function(AckEvent) updates) =>
      super.copyWith((message) => updates(message as AckEvent)) as AckEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AckEvent() / AckEvent.new instead')
  static AckEvent create() => AckEvent._();
  static $pb.GeneratedMessage $_createMessage() => AckEvent._();
  @$core.override
  AckEvent createEmptyInstance() => AckEvent._();
  @$core.pragma('dart2js:noInline')
  static AckEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AckEvent>(AckEvent.$_createMessage);
  static AckEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get eventId => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get subscriptionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set subscriptionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSubscriptionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSubscriptionId() => $_clearField(3);

  @$pb.TagNumber(4)
  $0.Timestamp get ackAt => $_getN(3);
  @$pb.TagNumber(4)
  set ackAt($0.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAckAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearAckAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Timestamp ensureAckAt() => $_ensure(3);

  @$pb.TagNumber(7)
  $2.ErrorDetail get error => $_getN(4);
  @$pb.TagNumber(7)
  set error($2.ErrorDetail value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(7)
  void clearError() => $_clearField(7);
  @$pb.TagNumber(7)
  $2.ErrorDetail ensureError() => $_ensure(4);
}

/// ReceiptEvent is OPTIONAL and ephemeral.
/// Servers MAY ignore it.
/// Clients SHOULD prefer ReadMarker for durable state.
/// Servers MUST NOT persist ReceiptEvent.
/// Servers MAY drop ReceiptEvent without acknowledgment.
class ReceiptEvent extends $pb.GeneratedMessage {
  factory ReceiptEvent({
    $core.String? roomId,
    $core.Iterable<$core.String>? eventId,
    $core.String? subscriptionId,
  }) {
    final result = ReceiptEvent._();
    if (roomId != null) result.roomId = roomId;
    if (eventId != null) result.eventId.addAll(eventId);
    if (subscriptionId != null) result.subscriptionId = subscriptionId;
    return result;
  }

  ReceiptEvent._();

  factory ReceiptEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReceiptEvent()..mergeFromBuffer(data, registry);
  factory ReceiptEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReceiptEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReceiptEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: ReceiptEvent.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'roomId')
    ..pPS(3, _omitFieldNames ? '' : 'eventId')
    ..aOS(5, _omitFieldNames ? '' : 'subscriptionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReceiptEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReceiptEvent copyWith(void Function(ReceiptEvent) updates) =>
      super.copyWith((message) => updates(message as ReceiptEvent))
          as ReceiptEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReceiptEvent() / ReceiptEvent.new instead')
  static ReceiptEvent create() => ReceiptEvent._();
  static $pb.GeneratedMessage $_createMessage() => ReceiptEvent._();
  @$core.override
  ReceiptEvent createEmptyInstance() => ReceiptEvent._();
  @$core.pragma('dart2js:noInline')
  static ReceiptEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReceiptEvent>(
          ReceiptEvent.$_createMessage);
  static ReceiptEvent? _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(2)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(2)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(2)
  void clearRoomId() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get eventId => $_getList(1);

  @$pb.TagNumber(5)
  $core.String get subscriptionId => $_getSZ(2);
  @$pb.TagNumber(5)
  set subscriptionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(5)
  $core.bool hasSubscriptionId() => $_has(2);
  @$pb.TagNumber(5)
  void clearSubscriptionId() => $_clearField(5);
}

class ReadMarker extends $pb.GeneratedMessage {
  factory ReadMarker({
    $core.String? roomId,
    $core.String? upToEventId,
    $core.String? subscriptionId,
  }) {
    final result = ReadMarker._();
    if (roomId != null) result.roomId = roomId;
    if (upToEventId != null) result.upToEventId = upToEventId;
    if (subscriptionId != null) result.subscriptionId = subscriptionId;
    return result;
  }

  ReadMarker._();

  factory ReadMarker.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReadMarker()..mergeFromBuffer(data, registry);
  factory ReadMarker.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReadMarker()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadMarker',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: ReadMarker.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..aOS(3, _omitFieldNames ? '' : 'upToEventId')
    ..aOS(5, _omitFieldNames ? '' : 'subscriptionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadMarker clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadMarker copyWith(void Function(ReadMarker) updates) =>
      super.copyWith((message) => updates(message as ReadMarker)) as ReadMarker;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReadMarker() / ReadMarker.new instead')
  static ReadMarker create() => ReadMarker._();
  static $pb.GeneratedMessage $_createMessage() => ReadMarker._();
  @$core.override
  ReadMarker createEmptyInstance() => ReadMarker._();
  @$core.pragma('dart2js:noInline')
  static ReadMarker getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadMarker>(ReadMarker.$_createMessage);
  static ReadMarker? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);

  @$pb.TagNumber(3)
  $core.String get upToEventId => $_getSZ(1);
  @$pb.TagNumber(3)
  set upToEventId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(3)
  $core.bool hasUpToEventId() => $_has(1);
  @$pb.TagNumber(3)
  void clearUpToEventId() => $_clearField(3);

  @$pb.TagNumber(5)
  $core.String get subscriptionId => $_getSZ(2);
  @$pb.TagNumber(5)
  set subscriptionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(5)
  $core.bool hasSubscriptionId() => $_has(2);
  @$pb.TagNumber(5)
  void clearSubscriptionId() => $_clearField(5);
}

/// Presence event affecting a user (and visible to rooms the user is a member of)
class PresenceEvent extends $pb.GeneratedMessage {
  factory PresenceEvent({
    $2.ContactLink? source,
    PresenceStatus? status,
    $core.String? statusMsg,
    $0.Timestamp? lastActive,
  }) {
    final result = PresenceEvent._();
    if (source != null) result.source = source;
    if (status != null) result.status = status;
    if (statusMsg != null) result.statusMsg = statusMsg;
    if (lastActive != null) result.lastActive = lastActive;
    return result;
  }

  PresenceEvent._();

  factory PresenceEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PresenceEvent()..mergeFromBuffer(data, registry);
  factory PresenceEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PresenceEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PresenceEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: PresenceEvent.$_createMessage)
    ..aOM<$2.ContactLink>(1, _omitFieldNames ? '' : 'source',
        subBuilder: $2.ContactLink.$_createMessage)
    ..aE<PresenceStatus>(2, _omitFieldNames ? '' : 'status',
        enumValues: PresenceStatus.values)
    ..aOS(3, _omitFieldNames ? '' : 'statusMsg')
    ..aOM<$0.Timestamp>(4, _omitFieldNames ? '' : 'lastActive',
        subBuilder: $0.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PresenceEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PresenceEvent copyWith(void Function(PresenceEvent) updates) =>
      super.copyWith((message) => updates(message as PresenceEvent))
          as PresenceEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PresenceEvent() / PresenceEvent.new instead')
  static PresenceEvent create() => PresenceEvent._();
  static $pb.GeneratedMessage $_createMessage() => PresenceEvent._();
  @$core.override
  PresenceEvent createEmptyInstance() => PresenceEvent._();
  @$core.pragma('dart2js:noInline')
  static PresenceEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PresenceEvent>(
          PresenceEvent.$_createMessage);
  static PresenceEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $2.ContactLink get source => $_getN(0);
  @$pb.TagNumber(1)
  set source($2.ContactLink value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSource() => $_has(0);
  @$pb.TagNumber(1)
  void clearSource() => $_clearField(1);
  @$pb.TagNumber(1)
  $2.ContactLink ensureSource() => $_ensure(0);

  @$pb.TagNumber(2)
  PresenceStatus get status => $_getN(1);
  @$pb.TagNumber(2)
  set status(PresenceStatus value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get statusMsg => $_getSZ(2);
  @$pb.TagNumber(3)
  set statusMsg($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStatusMsg() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatusMsg() => $_clearField(3);

  @$pb.TagNumber(4)
  $0.Timestamp get lastActive => $_getN(3);
  @$pb.TagNumber(4)
  set lastActive($0.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasLastActive() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastActive() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Timestamp ensureLastActive() => $_ensure(3);
}

/// Typing indicator
class TypingEvent extends $pb.GeneratedMessage {
  factory TypingEvent({
    $core.String? subscriptionId,
    $core.String? roomId,
    $core.bool? typing,
    $0.Timestamp? since,
  }) {
    final result = TypingEvent._();
    if (subscriptionId != null) result.subscriptionId = subscriptionId;
    if (roomId != null) result.roomId = roomId;
    if (typing != null) result.typing = typing;
    if (since != null) result.since = since;
    return result;
  }

  TypingEvent._();

  factory TypingEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TypingEvent()..mergeFromBuffer(data, registry);
  factory TypingEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TypingEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TypingEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: TypingEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'subscriptionId')
    ..aOS(2, _omitFieldNames ? '' : 'roomId')
    ..aOB(3, _omitFieldNames ? '' : 'typing')
    ..aOM<$0.Timestamp>(5, _omitFieldNames ? '' : 'since',
        subBuilder: $0.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TypingEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TypingEvent copyWith(void Function(TypingEvent) updates) =>
      super.copyWith((message) => updates(message as TypingEvent))
          as TypingEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TypingEvent() / TypingEvent.new instead')
  static TypingEvent create() => TypingEvent._();
  static $pb.GeneratedMessage $_createMessage() => TypingEvent._();
  @$core.override
  TypingEvent createEmptyInstance() => TypingEvent._();
  @$core.pragma('dart2js:noInline')
  static TypingEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TypingEvent>(
          TypingEvent.$_createMessage);
  static TypingEvent? _defaultInstance;

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
  $core.bool get typing => $_getBF(2);
  @$pb.TagNumber(3)
  set typing($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTyping() => $_has(2);
  @$pb.TagNumber(3)
  void clearTyping() => $_clearField(3);

  @$pb.TagNumber(5)
  $0.Timestamp get since => $_getN(3);
  @$pb.TagNumber(5)
  set since($0.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasSince() => $_has(3);
  @$pb.TagNumber(5)
  void clearSince() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.Timestamp ensureSince() => $_ensure(3);
}

enum ClientCommand_State {
  receipt,
  ack,
  typing,
  presence,
  readMarker,
  event,
  notSet
}

/// ClientCommand represents durable state changes initiated by the client.
/// Commands are validated, persisted, and broadcast as needed.
/// ClientCommand results in at least one RoomEvent being emitted.
class ClientCommand extends $pb.GeneratedMessage {
  factory ClientCommand({
    ReceiptEvent? receipt,
    AckEvent? ack,
    TypingEvent? typing,
    PresenceEvent? presence,
    ReadMarker? readMarker,
    RoomEvent? event,
  }) {
    final result = ClientCommand._();
    if (receipt != null) result.receipt = receipt;
    if (ack != null) result.ack = ack;
    if (typing != null) result.typing = typing;
    if (presence != null) result.presence = presence;
    if (readMarker != null) result.readMarker = readMarker;
    if (event != null) result.event = event;
    return result;
  }

  ClientCommand._();

  factory ClientCommand.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClientCommand()..mergeFromBuffer(data, registry);
  factory ClientCommand.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClientCommand()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ClientCommand_State>
      _ClientCommand_StateByTag = {
    2: ClientCommand_State.receipt,
    3: ClientCommand_State.ack,
    4: ClientCommand_State.typing,
    5: ClientCommand_State.presence,
    8: ClientCommand_State.readMarker,
    10: ClientCommand_State.event,
    0: ClientCommand_State.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientCommand',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: ClientCommand.$_createMessage)
    ..oo(0, [2, 3, 4, 5, 8, 10])
    ..aOM<ReceiptEvent>(2, _omitFieldNames ? '' : 'receipt',
        subBuilder: ReceiptEvent.$_createMessage)
    ..aOM<AckEvent>(3, _omitFieldNames ? '' : 'ack',
        subBuilder: AckEvent.$_createMessage)
    ..aOM<TypingEvent>(4, _omitFieldNames ? '' : 'typing',
        subBuilder: TypingEvent.$_createMessage)
    ..aOM<PresenceEvent>(5, _omitFieldNames ? '' : 'presence',
        subBuilder: PresenceEvent.$_createMessage)
    ..aOM<ReadMarker>(8, _omitFieldNames ? '' : 'readMarker',
        subBuilder: ReadMarker.$_createMessage)
    ..aOM<RoomEvent>(10, _omitFieldNames ? '' : 'event',
        subBuilder: RoomEvent.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientCommand clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientCommand copyWith(void Function(ClientCommand) updates) =>
      super.copyWith((message) => updates(message as ClientCommand))
          as ClientCommand;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ClientCommand() / ClientCommand.new instead')
  static ClientCommand create() => ClientCommand._();
  static $pb.GeneratedMessage $_createMessage() => ClientCommand._();
  @$core.override
  ClientCommand createEmptyInstance() => ClientCommand._();
  @$core.pragma('dart2js:noInline')
  static ClientCommand getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ClientCommand>(
          ClientCommand.$_createMessage);
  static ClientCommand? _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(8)
  @$pb.TagNumber(10)
  ClientCommand_State whichState() =>
      _ClientCommand_StateByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(8)
  @$pb.TagNumber(10)
  void clearState() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(2)
  ReceiptEvent get receipt => $_getN(0);
  @$pb.TagNumber(2)
  set receipt(ReceiptEvent value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasReceipt() => $_has(0);
  @$pb.TagNumber(2)
  void clearReceipt() => $_clearField(2);
  @$pb.TagNumber(2)
  ReceiptEvent ensureReceipt() => $_ensure(0);

  @$pb.TagNumber(3)
  AckEvent get ack => $_getN(1);
  @$pb.TagNumber(3)
  set ack(AckEvent value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAck() => $_has(1);
  @$pb.TagNumber(3)
  void clearAck() => $_clearField(3);
  @$pb.TagNumber(3)
  AckEvent ensureAck() => $_ensure(1);

  @$pb.TagNumber(4)
  TypingEvent get typing => $_getN(2);
  @$pb.TagNumber(4)
  set typing(TypingEvent value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasTyping() => $_has(2);
  @$pb.TagNumber(4)
  void clearTyping() => $_clearField(4);
  @$pb.TagNumber(4)
  TypingEvent ensureTyping() => $_ensure(2);

  @$pb.TagNumber(5)
  PresenceEvent get presence => $_getN(3);
  @$pb.TagNumber(5)
  set presence(PresenceEvent value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasPresence() => $_has(3);
  @$pb.TagNumber(5)
  void clearPresence() => $_clearField(5);
  @$pb.TagNumber(5)
  PresenceEvent ensurePresence() => $_ensure(3);

  @$pb.TagNumber(8)
  ReadMarker get readMarker => $_getN(4);
  @$pb.TagNumber(8)
  set readMarker(ReadMarker value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasReadMarker() => $_has(4);
  @$pb.TagNumber(8)
  void clearReadMarker() => $_clearField(8);
  @$pb.TagNumber(8)
  ReadMarker ensureReadMarker() => $_ensure(4);

  @$pb.TagNumber(10)
  RoomEvent get event => $_getN(5);
  @$pb.TagNumber(10)
  set event(RoomEvent value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasEvent() => $_has(5);
  @$pb.TagNumber(10)
  void clearEvent() => $_clearField(10);
  @$pb.TagNumber(10)
  RoomEvent ensureEvent() => $_ensure(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
