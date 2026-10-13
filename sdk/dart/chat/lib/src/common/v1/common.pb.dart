// This is a generated file - do not edit.
//
// Generated from common/v1/common.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../google/protobuf/struct.pb.dart' as $0;
import 'common.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'common.pbenum.dart';

/// PageCursor provides standard offset-based pagination/cursor stream parameters.
/// Used for list operations that return large result sets.
class PageCursor extends $pb.GeneratedMessage {
  factory PageCursor({
    $core.int? limit,
    $core.String? page,
  }) {
    final result = create();
    if (limit != null) result.limit = limit;
    if (page != null) result.page = page;
    return result;
  }

  PageCursor._();

  factory PageCursor.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PageCursor.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PageCursor',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'common.v1'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'limit', $pb.PbFieldType.O3)
    ..aOS(2, _omitFieldNames ? '' : 'page')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PageCursor clone() => PageCursor()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PageCursor copyWith(void Function(PageCursor) updates) =>
      super.copyWith((message) => updates(message as PageCursor)) as PageCursor;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PageCursor create() => PageCursor._();
  @$core.override
  PageCursor createEmptyInstance() => create();
  static $pb.PbList<PageCursor> createRepeated() => $pb.PbList<PageCursor>();
  @$core.pragma('dart2js:noInline')
  static PageCursor getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PageCursor>(create);
  static PageCursor? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get limit => $_getIZ(0);
  @$pb.TagNumber(1)
  set limit($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLimit() => $_has(0);
  @$pb.TagNumber(1)
  void clearLimit() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get page => $_getSZ(1);
  @$pb.TagNumber(2)
  set page($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPage() => $_has(1);
  @$pb.TagNumber(2)
  void clearPage() => $_clearField(2);
}

/// SearchRequest provides a standard structure for search operations across services.
/// Supports text search, ID-based queries, pagination, property filtering, and extensibility.
class SearchRequest extends $pb.GeneratedMessage {
  factory SearchRequest({
    $core.String? query,
    $core.String? idQuery,
    PageCursor? cursor,
    $core.Iterable<$core.String>? properties,
    $0.Struct? extras,
  }) {
    final result = create();
    if (query != null) result.query = query;
    if (idQuery != null) result.idQuery = idQuery;
    if (cursor != null) result.cursor = cursor;
    if (properties != null) result.properties.addAll(properties);
    if (extras != null) result.extras = extras;
    return result;
  }

  SearchRequest._();

  factory SearchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SearchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'common.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'query')
    ..aOS(2, _omitFieldNames ? '' : 'idQuery')
    ..aOM<PageCursor>(3, _omitFieldNames ? '' : 'cursor',
        subBuilder: PageCursor.create)
    ..pPS(7, _omitFieldNames ? '' : 'properties')
    ..aOM<$0.Struct>(8, _omitFieldNames ? '' : 'extras',
        subBuilder: $0.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchRequest clone() => SearchRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SearchRequest copyWith(void Function(SearchRequest) updates) =>
      super.copyWith((message) => updates(message as SearchRequest))
          as SearchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchRequest create() => SearchRequest._();
  @$core.override
  SearchRequest createEmptyInstance() => create();
  static $pb.PbList<SearchRequest> createRepeated() =>
      $pb.PbList<SearchRequest>();
  @$core.pragma('dart2js:noInline')
  static SearchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchRequest>(create);
  static SearchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get query => $_getSZ(0);
  @$pb.TagNumber(1)
  set query($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQuery() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuery() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get idQuery => $_getSZ(1);
  @$pb.TagNumber(2)
  set idQuery($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIdQuery() => $_has(1);
  @$pb.TagNumber(2)
  void clearIdQuery() => $_clearField(2);

  @$pb.TagNumber(3)
  PageCursor get cursor => $_getN(2);
  @$pb.TagNumber(3)
  set cursor(PageCursor value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCursor() => $_has(2);
  @$pb.TagNumber(3)
  void clearCursor() => $_clearField(3);
  @$pb.TagNumber(3)
  PageCursor ensureCursor() => $_ensure(2);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get properties => $_getList(3);

  @$pb.TagNumber(8)
  $0.Struct get extras => $_getN(4);
  @$pb.TagNumber(8)
  set extras($0.Struct value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasExtras() => $_has(4);
  @$pb.TagNumber(8)
  void clearExtras() => $_clearField(8);
  @$pb.TagNumber(8)
  $0.Struct ensureExtras() => $_ensure(4);
}

/// StatusRequest retrieves the current status of an entity or operation.
class StatusRequest extends $pb.GeneratedMessage {
  factory StatusRequest({
    $core.String? id,
    $0.Struct? extras,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (extras != null) result.extras = extras;
    return result;
  }

  StatusRequest._();

  factory StatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'common.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<$0.Struct>(2, _omitFieldNames ? '' : 'extras',
        subBuilder: $0.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusRequest clone() => StatusRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusRequest copyWith(void Function(StatusRequest) updates) =>
      super.copyWith((message) => updates(message as StatusRequest))
          as StatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatusRequest create() => StatusRequest._();
  @$core.override
  StatusRequest createEmptyInstance() => create();
  static $pb.PbList<StatusRequest> createRepeated() =>
      $pb.PbList<StatusRequest>();
  @$core.pragma('dart2js:noInline')
  static StatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StatusRequest>(create);
  static StatusRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Struct get extras => $_getN(1);
  @$pb.TagNumber(2)
  set extras($0.Struct value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasExtras() => $_has(1);
  @$pb.TagNumber(2)
  void clearExtras() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Struct ensureExtras() => $_ensure(1);
}

/// StatusResponse returns the current state and status of an entity or operation.
class StatusResponse extends $pb.GeneratedMessage {
  factory StatusResponse({
    $core.String? id,
    STATE? state,
    STATUS? status,
    $core.String? externalId,
    $core.String? transientId,
    $0.Struct? extras,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (state != null) result.state = state;
    if (status != null) result.status = status;
    if (externalId != null) result.externalId = externalId;
    if (transientId != null) result.transientId = transientId;
    if (extras != null) result.extras = extras;
    return result;
  }

  StatusResponse._();

  factory StatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatusResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'common.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..e<STATE>(2, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker: STATE.CREATED,
        valueOf: STATE.valueOf,
        enumValues: STATE.values)
    ..e<STATUS>(3, _omitFieldNames ? '' : 'status', $pb.PbFieldType.OE,
        defaultOrMaker: STATUS.UNKNOWN,
        valueOf: STATUS.valueOf,
        enumValues: STATUS.values)
    ..aOS(4, _omitFieldNames ? '' : 'externalId')
    ..aOS(5, _omitFieldNames ? '' : 'transientId')
    ..aOM<$0.Struct>(6, _omitFieldNames ? '' : 'extras',
        subBuilder: $0.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusResponse clone() => StatusResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusResponse copyWith(void Function(StatusResponse) updates) =>
      super.copyWith((message) => updates(message as StatusResponse))
          as StatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatusResponse create() => StatusResponse._();
  @$core.override
  StatusResponse createEmptyInstance() => create();
  static $pb.PbList<StatusResponse> createRepeated() =>
      $pb.PbList<StatusResponse>();
  @$core.pragma('dart2js:noInline')
  static StatusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StatusResponse>(create);
  static StatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  STATE get state => $_getN(1);
  @$pb.TagNumber(2)
  set state(STATE value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasState() => $_has(1);
  @$pb.TagNumber(2)
  void clearState() => $_clearField(2);

  @$pb.TagNumber(3)
  STATUS get status => $_getN(2);
  @$pb.TagNumber(3)
  set status(STATUS value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get externalId => $_getSZ(3);
  @$pb.TagNumber(4)
  set externalId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasExternalId() => $_has(3);
  @$pb.TagNumber(4)
  void clearExternalId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get transientId => $_getSZ(4);
  @$pb.TagNumber(5)
  set transientId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTransientId() => $_has(4);
  @$pb.TagNumber(5)
  void clearTransientId() => $_clearField(5);

  @$pb.TagNumber(6)
  $0.Struct get extras => $_getN(5);
  @$pb.TagNumber(6)
  set extras($0.Struct value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasExtras() => $_has(5);
  @$pb.TagNumber(6)
  void clearExtras() => $_clearField(6);
  @$pb.TagNumber(6)
  $0.Struct ensureExtras() => $_ensure(5);
}

/// StatusUpdateRequest updates the state and/or status of an entity or operation.
/// Used for state transitions and status updates by authorized services.
class StatusUpdateRequest extends $pb.GeneratedMessage {
  factory StatusUpdateRequest({
    $core.String? id,
    STATE? state,
    STATUS? status,
    $core.String? externalId,
    $0.Struct? extras,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (state != null) result.state = state;
    if (status != null) result.status = status;
    if (externalId != null) result.externalId = externalId;
    if (extras != null) result.extras = extras;
    return result;
  }

  StatusUpdateRequest._();

  factory StatusUpdateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StatusUpdateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatusUpdateRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'common.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..e<STATE>(2, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker: STATE.CREATED,
        valueOf: STATE.valueOf,
        enumValues: STATE.values)
    ..e<STATUS>(3, _omitFieldNames ? '' : 'status', $pb.PbFieldType.OE,
        defaultOrMaker: STATUS.UNKNOWN,
        valueOf: STATUS.valueOf,
        enumValues: STATUS.values)
    ..aOS(4, _omitFieldNames ? '' : 'externalId')
    ..aOM<$0.Struct>(5, _omitFieldNames ? '' : 'extras',
        subBuilder: $0.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusUpdateRequest clone() => StatusUpdateRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusUpdateRequest copyWith(void Function(StatusUpdateRequest) updates) =>
      super.copyWith((message) => updates(message as StatusUpdateRequest))
          as StatusUpdateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatusUpdateRequest create() => StatusUpdateRequest._();
  @$core.override
  StatusUpdateRequest createEmptyInstance() => create();
  static $pb.PbList<StatusUpdateRequest> createRepeated() =>
      $pb.PbList<StatusUpdateRequest>();
  @$core.pragma('dart2js:noInline')
  static StatusUpdateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StatusUpdateRequest>(create);
  static StatusUpdateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  STATE get state => $_getN(1);
  @$pb.TagNumber(2)
  set state(STATE value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasState() => $_has(1);
  @$pb.TagNumber(2)
  void clearState() => $_clearField(2);

  @$pb.TagNumber(3)
  STATUS get status => $_getN(2);
  @$pb.TagNumber(3)
  set status(STATUS value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get externalId => $_getSZ(3);
  @$pb.TagNumber(4)
  set externalId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasExternalId() => $_has(3);
  @$pb.TagNumber(4)
  void clearExternalId() => $_clearField(4);

  @$pb.TagNumber(5)
  $0.Struct get extras => $_getN(4);
  @$pb.TagNumber(5)
  set extras($0.Struct value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasExtras() => $_has(4);
  @$pb.TagNumber(5)
  void clearExtras() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.Struct ensureExtras() => $_ensure(4);
}

/// StatusUpdateResponse returns the updated status after a status update operation.
class StatusUpdateResponse extends $pb.GeneratedMessage {
  factory StatusUpdateResponse({
    StatusResponse? data,
  }) {
    final result = create();
    if (data != null) result.data = data;
    return result;
  }

  StatusUpdateResponse._();

  factory StatusUpdateResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StatusUpdateResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatusUpdateResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'common.v1'),
      createEmptyInstance: create)
    ..aOM<StatusResponse>(1, _omitFieldNames ? '' : 'data',
        subBuilder: StatusResponse.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusUpdateResponse clone() =>
      StatusUpdateResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusUpdateResponse copyWith(void Function(StatusUpdateResponse) updates) =>
      super.copyWith((message) => updates(message as StatusUpdateResponse))
          as StatusUpdateResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatusUpdateResponse create() => StatusUpdateResponse._();
  @$core.override
  StatusUpdateResponse createEmptyInstance() => create();
  static $pb.PbList<StatusUpdateResponse> createRepeated() =>
      $pb.PbList<StatusUpdateResponse>();
  @$core.pragma('dart2js:noInline')
  static StatusUpdateResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StatusUpdateResponse>(create);
  static StatusUpdateResponse? _defaultInstance;

  @$pb.TagNumber(1)
  StatusResponse get data => $_getN(0);
  @$pb.TagNumber(1)
  set data(StatusResponse value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => $_clearField(1);
  @$pb.TagNumber(1)
  StatusResponse ensureData() => $_ensure(0);
}

/// ContactLink represents a link between a contact and a profile in the system.
/// Used for associating external contacts with internal profiles across services.
/// This enables unified identity management and contact resolution.
class ContactLink extends $pb.GeneratedMessage {
  factory ContactLink({
    $core.String? profileName,
    $core.String? profileType,
    $core.String? profileId,
    $core.String? profileImageId,
    $core.String? contactId,
    $core.String? detail,
    $0.Struct? extras,
  }) {
    final result = create();
    if (profileName != null) result.profileName = profileName;
    if (profileType != null) result.profileType = profileType;
    if (profileId != null) result.profileId = profileId;
    if (profileImageId != null) result.profileImageId = profileImageId;
    if (contactId != null) result.contactId = contactId;
    if (detail != null) result.detail = detail;
    if (extras != null) result.extras = extras;
    return result;
  }

  ContactLink._();

  factory ContactLink.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ContactLink.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContactLink',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'common.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'profileName')
    ..aOS(2, _omitFieldNames ? '' : 'profileType')
    ..aOS(3, _omitFieldNames ? '' : 'profileId')
    ..aOS(4, _omitFieldNames ? '' : 'profileImageId')
    ..aOS(8, _omitFieldNames ? '' : 'contactId')
    ..aOS(9, _omitFieldNames ? '' : 'detail')
    ..aOM<$0.Struct>(10, _omitFieldNames ? '' : 'extras',
        subBuilder: $0.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContactLink clone() => ContactLink()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContactLink copyWith(void Function(ContactLink) updates) =>
      super.copyWith((message) => updates(message as ContactLink))
          as ContactLink;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ContactLink create() => ContactLink._();
  @$core.override
  ContactLink createEmptyInstance() => create();
  static $pb.PbList<ContactLink> createRepeated() => $pb.PbList<ContactLink>();
  @$core.pragma('dart2js:noInline')
  static ContactLink getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContactLink>(create);
  static ContactLink? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get profileName => $_getSZ(0);
  @$pb.TagNumber(1)
  set profileName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProfileName() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfileName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get profileType => $_getSZ(1);
  @$pb.TagNumber(2)
  set profileType($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProfileType() => $_has(1);
  @$pb.TagNumber(2)
  void clearProfileType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get profileId => $_getSZ(2);
  @$pb.TagNumber(3)
  set profileId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProfileId() => $_has(2);
  @$pb.TagNumber(3)
  void clearProfileId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get profileImageId => $_getSZ(3);
  @$pb.TagNumber(4)
  set profileImageId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasProfileImageId() => $_has(3);
  @$pb.TagNumber(4)
  void clearProfileImageId() => $_clearField(4);

  @$pb.TagNumber(8)
  $core.String get contactId => $_getSZ(4);
  @$pb.TagNumber(8)
  set contactId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(8)
  $core.bool hasContactId() => $_has(4);
  @$pb.TagNumber(8)
  void clearContactId() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get detail => $_getSZ(5);
  @$pb.TagNumber(9)
  set detail($core.String value) => $_setString(5, value);
  @$pb.TagNumber(9)
  $core.bool hasDetail() => $_has(5);
  @$pb.TagNumber(9)
  void clearDetail() => $_clearField(9);

  @$pb.TagNumber(10)
  $0.Struct get extras => $_getN(6);
  @$pb.TagNumber(10)
  set extras($0.Struct value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasExtras() => $_has(6);
  @$pb.TagNumber(10)
  void clearExtras() => $_clearField(10);
  @$pb.TagNumber(10)
  $0.Struct ensureExtras() => $_ensure(6);
}

/// Standard error codes used by API responses.
/// Use gRPC status codes; the application-level ErrorDetail below may carry more.
class ErrorDetail extends $pb.GeneratedMessage {
  factory ErrorDetail({
    $core.int? code,
    $core.String? message,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? meta,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (message != null) result.message = message;
    if (meta != null) result.meta.addEntries(meta);
    return result;
  }

  ErrorDetail._();

  factory ErrorDetail.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ErrorDetail.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ErrorDetail',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'common.v1'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'code', $pb.PbFieldType.O3)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..m<$core.String, $core.String>(3, _omitFieldNames ? '' : 'meta',
        entryClassName: 'ErrorDetail.MetaEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('common.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ErrorDetail clone() => ErrorDetail()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ErrorDetail copyWith(void Function(ErrorDetail) updates) =>
      super.copyWith((message) => updates(message as ErrorDetail))
          as ErrorDetail;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ErrorDetail create() => ErrorDetail._();
  @$core.override
  ErrorDetail createEmptyInstance() => create();
  static $pb.PbList<ErrorDetail> createRepeated() => $pb.PbList<ErrorDetail>();
  @$core.pragma('dart2js:noInline')
  static ErrorDetail getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ErrorDetail>(create);
  static ErrorDetail? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get code => $_getIZ(0);
  @$pb.TagNumber(1)
  set code($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbMap<$core.String, $core.String> get meta => $_getMap(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
