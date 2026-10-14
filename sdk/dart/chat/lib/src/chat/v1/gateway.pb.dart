// This is a generated file - do not edit.
//
// Generated from chat/v1/gateway.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $0;

import '../../common/v1/common.pb.dart' as $2;
import 'definitions.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// StreamHello message sent by client to server to initiate a connection.
/// resume_token: server-supplied resume_token from previous session.
/// capabilities: list of capabilities supported by the client.
/// StreamHello MUST be the first message sent by the client.
/// Servers MUST reject any other message types before StreamHello.
class StreamHello extends $pb.GeneratedMessage {
  factory StreamHello({
    $core.String? resumeToken,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? capabilities,
    $0.Timestamp? clientTime,
  }) {
    final result = StreamHello._();
    if (resumeToken != null) result.resumeToken = resumeToken;
    if (capabilities != null) result.capabilities.addEntries(capabilities);
    if (clientTime != null) result.clientTime = clientTime;
    return result;
  }

  StreamHello._();

  factory StreamHello.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StreamHello()..mergeFromBuffer(data, registry);
  factory StreamHello.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StreamHello()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamHello',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: StreamHello.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'resumeToken')
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'capabilities',
        entryClassName: 'StreamHello.CapabilitiesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('chat.v1'))
    ..aOM<$0.Timestamp>(3, _omitFieldNames ? '' : 'clientTime',
        subBuilder: $0.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamHello clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamHello copyWith(void Function(StreamHello) updates) =>
      super.copyWith((message) => updates(message as StreamHello))
          as StreamHello;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StreamHello() / StreamHello.new instead')
  static StreamHello create() => StreamHello._();
  static $pb.GeneratedMessage $_createMessage() => StreamHello._();
  @$core.override
  StreamHello createEmptyInstance() => StreamHello._();
  @$core.pragma('dart2js:noInline')
  static StreamHello getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StreamHello>(
          StreamHello.$_createMessage);
  static StreamHello? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get resumeToken => $_getSZ(0);
  @$pb.TagNumber(1)
  set resumeToken($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasResumeToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearResumeToken() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $core.String> get capabilities => $_getMap(1);

  @$pb.TagNumber(3)
  $0.Timestamp get clientTime => $_getN(2);
  @$pb.TagNumber(3)
  set clientTime($0.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasClientTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearClientTime() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Timestamp ensureClientTime() => $_ensure(2);
}

enum StreamRequest_Payload { hello, command, notSet }

/// Client message over Connect stream. After initial connect frame, client sends acks/commands.
class StreamRequest extends $pb.GeneratedMessage {
  factory StreamRequest({
    StreamHello? hello,
    $1.ClientCommand? command,
  }) {
    final result = StreamRequest._();
    if (hello != null) result.hello = hello;
    if (command != null) result.command = command;
    return result;
  }

  StreamRequest._();

  factory StreamRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StreamRequest()..mergeFromBuffer(data, registry);
  factory StreamRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StreamRequest()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, StreamRequest_Payload>
      _StreamRequest_PayloadByTag = {
    1: StreamRequest_Payload.hello,
    12: StreamRequest_Payload.command,
    0: StreamRequest_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: StreamRequest.$_createMessage)
    ..oo(0, [1, 12])
    ..aOM<StreamHello>(1, _omitFieldNames ? '' : 'hello',
        subBuilder: StreamHello.$_createMessage)
    ..aOM<$1.ClientCommand>(12, _omitFieldNames ? '' : 'command',
        subBuilder: $1.ClientCommand.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamRequest copyWith(void Function(StreamRequest) updates) =>
      super.copyWith((message) => updates(message as StreamRequest))
          as StreamRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StreamRequest() / StreamRequest.new instead')
  static StreamRequest create() => StreamRequest._();
  static $pb.GeneratedMessage $_createMessage() => StreamRequest._();
  @$core.override
  StreamRequest createEmptyInstance() => StreamRequest._();
  @$core.pragma('dart2js:noInline')
  static StreamRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StreamRequest>(
          StreamRequest.$_createMessage);
  static StreamRequest? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(12)
  StreamRequest_Payload whichPayload() =>
      _StreamRequest_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(12)
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  StreamHello get hello => $_getN(0);
  @$pb.TagNumber(1)
  set hello(StreamHello value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHello() => $_has(0);
  @$pb.TagNumber(1)
  void clearHello() => $_clearField(1);
  @$pb.TagNumber(1)
  StreamHello ensureHello() => $_ensure(0);

  @$pb.TagNumber(12)
  $1.ClientCommand get command => $_getN(1);
  @$pb.TagNumber(12)
  set command($1.ClientCommand value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasCommand() => $_has(1);
  @$pb.TagNumber(12)
  void clearCommand() => $_clearField(12);
  @$pb.TagNumber(12)
  $1.ClientCommand ensureCommand() => $_ensure(1);
}

enum StreamResponse_Payload {
  message,
  presenceEvent,
  receiptEvent,
  readEvent,
  typingEvent,
  error,
  notSet
}

/// Server -> Client event payload. All events in a room are delivered over Connect stream.
/// event_id: globally unique id (opaque string) assigned by server, strictly monotonically increasing per room.
/// sequence: strictly increasing 64-bit integer per-room sequence number (useful for resume & ordering).
class StreamResponse extends $pb.GeneratedMessage {
  factory StreamResponse({
    $core.String? id,
    $0.Timestamp? timestamp,
    $1.RoomEvent? message,
    $1.PresenceEvent? presenceEvent,
    $1.ReceiptEvent? receiptEvent,
    $1.ReadMarker? readEvent,
    $1.TypingEvent? typingEvent,
    $2.ErrorDetail? error,
  }) {
    final result = StreamResponse._();
    if (id != null) result.id = id;
    if (timestamp != null) result.timestamp = timestamp;
    if (message != null) result.message = message;
    if (presenceEvent != null) result.presenceEvent = presenceEvent;
    if (receiptEvent != null) result.receiptEvent = receiptEvent;
    if (readEvent != null) result.readEvent = readEvent;
    if (typingEvent != null) result.typingEvent = typingEvent;
    if (error != null) result.error = error;
    return result;
  }

  StreamResponse._();

  factory StreamResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StreamResponse()..mergeFromBuffer(data, registry);
  factory StreamResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StreamResponse()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, StreamResponse_Payload>
      _StreamResponse_PayloadByTag = {
    10: StreamResponse_Payload.message,
    12: StreamResponse_Payload.presenceEvent,
    13: StreamResponse_Payload.receiptEvent,
    15: StreamResponse_Payload.readEvent,
    17: StreamResponse_Payload.typingEvent,
    20: StreamResponse_Payload.error,
    0: StreamResponse_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: StreamResponse.$_createMessage)
    ..oo(0, [10, 12, 13, 15, 17, 20])
    ..aOS(3, _omitFieldNames ? '' : 'id')
    ..aOM<$0.Timestamp>(5, _omitFieldNames ? '' : 'timestamp',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOM<$1.RoomEvent>(10, _omitFieldNames ? '' : 'message',
        subBuilder: $1.RoomEvent.$_createMessage)
    ..aOM<$1.PresenceEvent>(12, _omitFieldNames ? '' : 'presenceEvent',
        subBuilder: $1.PresenceEvent.$_createMessage)
    ..aOM<$1.ReceiptEvent>(13, _omitFieldNames ? '' : 'receiptEvent',
        subBuilder: $1.ReceiptEvent.$_createMessage)
    ..aOM<$1.ReadMarker>(15, _omitFieldNames ? '' : 'readEvent',
        subBuilder: $1.ReadMarker.$_createMessage)
    ..aOM<$1.TypingEvent>(17, _omitFieldNames ? '' : 'typingEvent',
        subBuilder: $1.TypingEvent.$_createMessage)
    ..aOM<$2.ErrorDetail>(20, _omitFieldNames ? '' : 'error',
        subBuilder: $2.ErrorDetail.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamResponse copyWith(void Function(StreamResponse) updates) =>
      super.copyWith((message) => updates(message as StreamResponse))
          as StreamResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StreamResponse() / StreamResponse.new instead')
  static StreamResponse create() => StreamResponse._();
  static $pb.GeneratedMessage $_createMessage() => StreamResponse._();
  @$core.override
  StreamResponse createEmptyInstance() => StreamResponse._();
  @$core.pragma('dart2js:noInline')
  static StreamResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StreamResponse>(
          StreamResponse.$_createMessage);
  static StreamResponse? _defaultInstance;

  @$pb.TagNumber(10)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(15)
  @$pb.TagNumber(17)
  @$pb.TagNumber(20)
  StreamResponse_Payload whichPayload() =>
      _StreamResponse_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(10)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(15)
  @$pb.TagNumber(17)
  @$pb.TagNumber(20)
  void clearPayload() => $_clearField($_whichOneof(0));

  /// NOTE:
  /// Stream IDs are XIDs and MUST be lexicographically sortable by creation time.
  /// Clients MUST NOT assume any other ordering mechanism.
  @$pb.TagNumber(3)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(3)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(3)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(3)
  void clearId() => $_clearField(3);

  @$pb.TagNumber(5)
  $0.Timestamp get timestamp => $_getN(1);
  @$pb.TagNumber(5)
  set timestamp($0.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasTimestamp() => $_has(1);
  @$pb.TagNumber(5)
  void clearTimestamp() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.Timestamp ensureTimestamp() => $_ensure(1);

  @$pb.TagNumber(10)
  $1.RoomEvent get message => $_getN(2);
  @$pb.TagNumber(10)
  set message($1.RoomEvent value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(10)
  void clearMessage() => $_clearField(10);
  @$pb.TagNumber(10)
  $1.RoomEvent ensureMessage() => $_ensure(2);

  @$pb.TagNumber(12)
  $1.PresenceEvent get presenceEvent => $_getN(3);
  @$pb.TagNumber(12)
  set presenceEvent($1.PresenceEvent value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasPresenceEvent() => $_has(3);
  @$pb.TagNumber(12)
  void clearPresenceEvent() => $_clearField(12);
  @$pb.TagNumber(12)
  $1.PresenceEvent ensurePresenceEvent() => $_ensure(3);

  @$pb.TagNumber(13)
  $1.ReceiptEvent get receiptEvent => $_getN(4);
  @$pb.TagNumber(13)
  set receiptEvent($1.ReceiptEvent value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasReceiptEvent() => $_has(4);
  @$pb.TagNumber(13)
  void clearReceiptEvent() => $_clearField(13);
  @$pb.TagNumber(13)
  $1.ReceiptEvent ensureReceiptEvent() => $_ensure(4);

  @$pb.TagNumber(15)
  $1.ReadMarker get readEvent => $_getN(5);
  @$pb.TagNumber(15)
  set readEvent($1.ReadMarker value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasReadEvent() => $_has(5);
  @$pb.TagNumber(15)
  void clearReadEvent() => $_clearField(15);
  @$pb.TagNumber(15)
  $1.ReadMarker ensureReadEvent() => $_ensure(5);

  @$pb.TagNumber(17)
  $1.TypingEvent get typingEvent => $_getN(6);
  @$pb.TagNumber(17)
  set typingEvent($1.TypingEvent value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasTypingEvent() => $_has(6);
  @$pb.TagNumber(17)
  void clearTypingEvent() => $_clearField(17);
  @$pb.TagNumber(17)
  $1.TypingEvent ensureTypingEvent() => $_ensure(6);

  /// error:
  /// - If present, represents a server-side error related to the stream or event.
  /// - MAY be recoverable (client should continue stream) or fatal.
  /// - Fatal errors MUST be followed by stream termination.
  @$pb.TagNumber(20)
  $2.ErrorDetail get error => $_getN(7);
  @$pb.TagNumber(20)
  set error($2.ErrorDetail value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasError() => $_has(7);
  @$pb.TagNumber(20)
  void clearError() => $_clearField(20);
  @$pb.TagNumber(20)
  $2.ErrorDetail ensureError() => $_ensure(7);
}

class GatewayServiceApi {
  final $pb.RpcClient _client;

  GatewayServiceApi(this._client);

  /// Bi-directional, long-lived connection. Client sends StreamRequest (initial auth + acks/commands).
  /// Server streams StreamResponse objects in chronological order for rooms the client is subscribed to.
  /// Stream resume: client may provide last_received_event_id or resume_token to continue after reconnect.
  $async.Future<StreamResponse> stream(
          $pb.ClientContext? ctx, StreamRequest request) =>
      _client.invoke<StreamResponse>(
          ctx, 'GatewayService', 'Stream', request, StreamResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
