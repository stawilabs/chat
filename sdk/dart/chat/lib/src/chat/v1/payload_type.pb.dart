// This is a generated file - do not edit.
//
// Generated from chat/v1/payload_type.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../google/protobuf/struct.pb.dart' as $0;
import '../../google/protobuf/timestamp.pb.dart' as $1;
import 'payload_type.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'payload_type.pbenum.dart';

class RoomChangeContent extends $pb.GeneratedMessage {
  factory RoomChangeContent({
    RoomChangeAction? action,
    $core.String? actorSubscriptionId,
    $core.Iterable<$core.String>? targetSubscriptionIds,
    $core.String? body,
    $0.Struct? details,
  }) {
    final result = create();
    if (action != null) result.action = action;
    if (actorSubscriptionId != null)
      result.actorSubscriptionId = actorSubscriptionId;
    if (targetSubscriptionIds != null)
      result.targetSubscriptionIds.addAll(targetSubscriptionIds);
    if (body != null) result.body = body;
    if (details != null) result.details = details;
    return result;
  }

  RoomChangeContent._();

  factory RoomChangeContent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RoomChangeContent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RoomChangeContent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..e<RoomChangeAction>(
        1, _omitFieldNames ? '' : 'action', $pb.PbFieldType.OE,
        defaultOrMaker: RoomChangeAction.ROOM_CHANGE_ACTION_UNSPECIFIED,
        valueOf: RoomChangeAction.valueOf,
        enumValues: RoomChangeAction.values)
    ..aOS(2, _omitFieldNames ? '' : 'actorSubscriptionId')
    ..pPS(3, _omitFieldNames ? '' : 'targetSubscriptionIds')
    ..aOS(4, _omitFieldNames ? '' : 'body')
    ..aOM<$0.Struct>(5, _omitFieldNames ? '' : 'details',
        subBuilder: $0.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoomChangeContent clone() => RoomChangeContent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoomChangeContent copyWith(void Function(RoomChangeContent) updates) =>
      super.copyWith((message) => updates(message as RoomChangeContent))
          as RoomChangeContent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RoomChangeContent create() => RoomChangeContent._();
  @$core.override
  RoomChangeContent createEmptyInstance() => create();
  static $pb.PbList<RoomChangeContent> createRepeated() =>
      $pb.PbList<RoomChangeContent>();
  @$core.pragma('dart2js:noInline')
  static RoomChangeContent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RoomChangeContent>(create);
  static RoomChangeContent? _defaultInstance;

  @$pb.TagNumber(1)
  RoomChangeAction get action => $_getN(0);
  @$pb.TagNumber(1)
  set action(RoomChangeAction value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get actorSubscriptionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set actorSubscriptionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasActorSubscriptionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearActorSubscriptionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get targetSubscriptionIds => $_getList(2);

  /// Human-readable summary (server-generated, for display)
  @$pb.TagNumber(4)
  $core.String get body => $_getSZ(3);
  @$pb.TagNumber(4)
  set body($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBody() => $_has(3);
  @$pb.TagNumber(4)
  void clearBody() => $_clearField(4);

  /// Optional structured detail (depends on action)
  @$pb.TagNumber(5)
  $0.Struct get details => $_getN(4);
  @$pb.TagNumber(5)
  set details($0.Struct value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasDetails() => $_has(4);
  @$pb.TagNumber(5)
  void clearDetails() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.Struct ensureDetails() => $_ensure(4);
}

class ModerationContent extends $pb.GeneratedMessage {
  factory ModerationContent({
    $core.String? body,
    $core.String? actorSubscriptionId,
    $core.Iterable<$core.String>? targetSubscriptionIds,
    $core.String? language,
    $0.Struct? metadata,
  }) {
    final result = create();
    if (body != null) result.body = body;
    if (actorSubscriptionId != null)
      result.actorSubscriptionId = actorSubscriptionId;
    if (targetSubscriptionIds != null)
      result.targetSubscriptionIds.addAll(targetSubscriptionIds);
    if (language != null) result.language = language;
    if (metadata != null) result.metadata = metadata;
    return result;
  }

  ModerationContent._();

  factory ModerationContent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModerationContent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModerationContent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'body')
    ..aOS(2, _omitFieldNames ? '' : 'actorSubscriptionId')
    ..pPS(3, _omitFieldNames ? '' : 'targetSubscriptionIds')
    ..aOS(4, _omitFieldNames ? '' : 'language')
    ..aOM<$0.Struct>(8, _omitFieldNames ? '' : 'metadata',
        subBuilder: $0.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModerationContent clone() => ModerationContent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModerationContent copyWith(void Function(ModerationContent) updates) =>
      super.copyWith((message) => updates(message as ModerationContent))
          as ModerationContent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModerationContent create() => ModerationContent._();
  @$core.override
  ModerationContent createEmptyInstance() => create();
  static $pb.PbList<ModerationContent> createRepeated() =>
      $pb.PbList<ModerationContent>();
  @$core.pragma('dart2js:noInline')
  static ModerationContent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModerationContent>(create);
  static ModerationContent? _defaultInstance;

  /// Human-readable message body describing the action.
  /// Intended for display to end users.
  @$pb.TagNumber(1)
  $core.String get body => $_getSZ(0);
  @$pb.TagNumber(1)
  set body($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBody() => $_has(0);
  @$pb.TagNumber(1)
  void clearBody() => $_clearField(1);

  /// Subscription ID of the actor who initiated the action.
  @$pb.TagNumber(2)
  $core.String get actorSubscriptionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set actorSubscriptionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasActorSubscriptionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearActorSubscriptionId() => $_clearField(2);

  /// Subscription IDs of entities targeted by the action.
  /// Must not contain duplicates and must not include the actor.
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get targetSubscriptionIds => $_getList(2);

  /// Optional language tag for the body, using BCP-47 (e.g. "en", "fr-CA").
  @$pb.TagNumber(4)
  $core.String get language => $_getSZ(3);
  @$pb.TagNumber(4)
  set language($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLanguage() => $_has(3);
  @$pb.TagNumber(4)
  void clearLanguage() => $_clearField(4);

  /// Optional structured metadata associated with the action.
  /// Use only for non-indexed, auxiliary data.
  @$pb.TagNumber(8)
  $0.Struct get metadata => $_getN(4);
  @$pb.TagNumber(8)
  set metadata($0.Struct value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasMetadata() => $_has(4);
  @$pb.TagNumber(8)
  void clearMetadata() => $_clearField(8);
  @$pb.TagNumber(8)
  $0.Struct ensureMetadata() => $_ensure(4);
}

class TextContent extends $pb.GeneratedMessage {
  factory TextContent({
    $core.String? body,
    $core.String? format,
    $core.Iterable<TextAnnotation>? annotations,
    $core.String? lang,
  }) {
    final result = create();
    if (body != null) result.body = body;
    if (format != null) result.format = format;
    if (annotations != null) result.annotations.addAll(annotations);
    if (lang != null) result.lang = lang;
    return result;
  }

  TextContent._();

  factory TextContent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TextContent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TextContent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'body')
    ..aOS(2, _omitFieldNames ? '' : 'format')
    ..pc<TextAnnotation>(
        3, _omitFieldNames ? '' : 'annotations', $pb.PbFieldType.PM,
        subBuilder: TextAnnotation.create)
    ..aOS(4, _omitFieldNames ? '' : 'lang')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextContent clone() => TextContent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextContent copyWith(void Function(TextContent) updates) =>
      super.copyWith((message) => updates(message as TextContent))
          as TextContent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TextContent create() => TextContent._();
  @$core.override
  TextContent createEmptyInstance() => create();
  static $pb.PbList<TextContent> createRepeated() => $pb.PbList<TextContent>();
  @$core.pragma('dart2js:noInline')
  static TextContent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TextContent>(create);
  static TextContent? _defaultInstance;

  /// Required human-readable message body
  @$pb.TagNumber(1)
  $core.String get body => $_getSZ(0);
  @$pb.TagNumber(1)
  set body($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBody() => $_has(0);
  @$pb.TagNumber(1)
  void clearBody() => $_clearField(1);

  /// Content format identifier (NOT MIME type)
  /// Examples: "plain", "markdown", "html-lite"
  @$pb.TagNumber(2)
  $core.String get format => $_getSZ(1);
  @$pb.TagNumber(2)
  set format($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFormat() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormat() => $_clearField(2);

  /// Structured annotations for clients (mentions, links, emojis)
  @$pb.TagNumber(3)
  $pb.PbList<TextAnnotation> get annotations => $_getList(2);

  /// Optional language hint (BCP-47), e.g. "en", "fr-CA"
  @$pb.TagNumber(4)
  $core.String get lang => $_getSZ(3);
  @$pb.TagNumber(4)
  set lang($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLang() => $_has(3);
  @$pb.TagNumber(4)
  void clearLang() => $_clearField(4);
}

class TextAnnotation extends $pb.GeneratedMessage {
  factory TextAnnotation({
    TextAnnotation_Type? type,
    $core.int? offset,
    $core.int? length,
    $core.String? value,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (offset != null) result.offset = offset;
    if (length != null) result.length = length;
    if (value != null) result.value = value;
    return result;
  }

  TextAnnotation._();

  factory TextAnnotation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TextAnnotation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TextAnnotation',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..e<TextAnnotation_Type>(
        1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker: TextAnnotation_Type.TYPE_UNSPECIFIED,
        valueOf: TextAnnotation_Type.valueOf,
        enumValues: TextAnnotation_Type.values)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'offset', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'length', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextAnnotation clone() => TextAnnotation()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextAnnotation copyWith(void Function(TextAnnotation) updates) =>
      super.copyWith((message) => updates(message as TextAnnotation))
          as TextAnnotation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TextAnnotation create() => TextAnnotation._();
  @$core.override
  TextAnnotation createEmptyInstance() => create();
  static $pb.PbList<TextAnnotation> createRepeated() =>
      $pb.PbList<TextAnnotation>();
  @$core.pragma('dart2js:noInline')
  static TextAnnotation getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TextAnnotation>(create);
  static TextAnnotation? _defaultInstance;

  @$pb.TagNumber(1)
  TextAnnotation_Type get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(TextAnnotation_Type value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  /// UTF-16 offset & length for cross-platform compatibility
  @$pb.TagNumber(2)
  $core.int get offset => $_getIZ(1);
  @$pb.TagNumber(2)
  set offset($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOffset() => $_has(1);
  @$pb.TagNumber(2)
  void clearOffset() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get length => $_getIZ(2);
  @$pb.TagNumber(3)
  set length($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLength() => $_has(2);
  @$pb.TagNumber(3)
  void clearLength() => $_clearField(3);

  /// Target identifier (e.g., profile_id, room_id, URL)
  @$pb.TagNumber(4)
  $core.String get value => $_getSZ(3);
  @$pb.TagNumber(4)
  set value($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasValue() => $_has(3);
  @$pb.TagNumber(4)
  void clearValue() => $_clearField(4);
}

class AttachmentContent extends $pb.GeneratedMessage {
  factory AttachmentContent({
    $core.String? attachmentId,
    $core.String? filename,
    $core.String? mimeType,
    $fixnum.Int64? sizeBytes,
    $core.String? uri,
    $core.Iterable<AttachmentPreview>? previews,
    TextContent? caption,
    $core.bool? encrypted,
    $core.String? checksum,
  }) {
    final result = create();
    if (attachmentId != null) result.attachmentId = attachmentId;
    if (filename != null) result.filename = filename;
    if (mimeType != null) result.mimeType = mimeType;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (uri != null) result.uri = uri;
    if (previews != null) result.previews.addAll(previews);
    if (caption != null) result.caption = caption;
    if (encrypted != null) result.encrypted = encrypted;
    if (checksum != null) result.checksum = checksum;
    return result;
  }

  AttachmentContent._();

  factory AttachmentContent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AttachmentContent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AttachmentContent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'attachmentId')
    ..aOS(2, _omitFieldNames ? '' : 'filename')
    ..aOS(3, _omitFieldNames ? '' : 'mimeType')
    ..aInt64(4, _omitFieldNames ? '' : 'sizeBytes')
    ..aOS(5, _omitFieldNames ? '' : 'uri')
    ..pc<AttachmentPreview>(
        6, _omitFieldNames ? '' : 'previews', $pb.PbFieldType.PM,
        subBuilder: AttachmentPreview.create)
    ..aOM<TextContent>(7, _omitFieldNames ? '' : 'caption',
        subBuilder: TextContent.create)
    ..aOB(8, _omitFieldNames ? '' : 'encrypted')
    ..aOS(9, _omitFieldNames ? '' : 'checksum')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttachmentContent clone() => AttachmentContent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttachmentContent copyWith(void Function(AttachmentContent) updates) =>
      super.copyWith((message) => updates(message as AttachmentContent))
          as AttachmentContent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AttachmentContent create() => AttachmentContent._();
  @$core.override
  AttachmentContent createEmptyInstance() => create();
  static $pb.PbList<AttachmentContent> createRepeated() =>
      $pb.PbList<AttachmentContent>();
  @$core.pragma('dart2js:noInline')
  static AttachmentContent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AttachmentContent>(create);
  static AttachmentContent? _defaultInstance;

  /// Logical identifier of the attachment
  @$pb.TagNumber(1)
  $core.String get attachmentId => $_getSZ(0);
  @$pb.TagNumber(1)
  set attachmentId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAttachmentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAttachmentId() => $_clearField(1);

  /// Original filename (optional, user-facing)
  @$pb.TagNumber(2)
  $core.String get filename => $_getSZ(1);
  @$pb.TagNumber(2)
  set filename($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFilename() => $_has(1);
  @$pb.TagNumber(2)
  void clearFilename() => $_clearField(2);

  /// MIME type (e.g. image/png, application/pdf)
  @$pb.TagNumber(3)
  $core.String get mimeType => $_getSZ(2);
  @$pb.TagNumber(3)
  set mimeType($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMimeType() => $_has(2);
  @$pb.TagNumber(3)
  void clearMimeType() => $_clearField(3);

  /// Size in bytes (for quota enforcement & UX)
  @$pb.TagNumber(4)
  $fixnum.Int64 get sizeBytes => $_getI64(3);
  @$pb.TagNumber(4)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSizeBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearSizeBytes() => $_clearField(4);

  /// Content location (signed URL or opaque locator)
  @$pb.TagNumber(5)
  $core.String get uri => $_getSZ(4);
  @$pb.TagNumber(5)
  set uri($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUri() => $_has(4);
  @$pb.TagNumber(5)
  void clearUri() => $_clearField(5);

  /// Optional previews / thumbnails
  @$pb.TagNumber(6)
  $pb.PbList<AttachmentPreview> get previews => $_getList(5);

  /// Optional caption text
  @$pb.TagNumber(7)
  TextContent get caption => $_getN(6);
  @$pb.TagNumber(7)
  set caption(TextContent value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasCaption() => $_has(6);
  @$pb.TagNumber(7)
  void clearCaption() => $_clearField(7);
  @$pb.TagNumber(7)
  TextContent ensureCaption() => $_ensure(6);

  /// Indicates whether attachment is end-to-end encrypted
  @$pb.TagNumber(8)
  $core.bool get encrypted => $_getBF(7);
  @$pb.TagNumber(8)
  set encrypted($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasEncrypted() => $_has(7);
  @$pb.TagNumber(8)
  void clearEncrypted() => $_clearField(8);

  /// Optional content hash (e.g. sha256:base64)
  @$pb.TagNumber(9)
  $core.String get checksum => $_getSZ(8);
  @$pb.TagNumber(9)
  set checksum($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasChecksum() => $_has(8);
  @$pb.TagNumber(9)
  void clearChecksum() => $_clearField(9);
}

class AttachmentPreview extends $pb.GeneratedMessage {
  factory AttachmentPreview({
    $core.String? mimeType,
    $core.int? width,
    $core.int? height,
    $core.String? uri,
    $fixnum.Int64? sizeBytes,
  }) {
    final result = create();
    if (mimeType != null) result.mimeType = mimeType;
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (uri != null) result.uri = uri;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    return result;
  }

  AttachmentPreview._();

  factory AttachmentPreview.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AttachmentPreview.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AttachmentPreview',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'mimeType')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'width', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'height', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'uri')
    ..aInt64(5, _omitFieldNames ? '' : 'sizeBytes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttachmentPreview clone() => AttachmentPreview()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttachmentPreview copyWith(void Function(AttachmentPreview) updates) =>
      super.copyWith((message) => updates(message as AttachmentPreview))
          as AttachmentPreview;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AttachmentPreview create() => AttachmentPreview._();
  @$core.override
  AttachmentPreview createEmptyInstance() => create();
  static $pb.PbList<AttachmentPreview> createRepeated() =>
      $pb.PbList<AttachmentPreview>();
  @$core.pragma('dart2js:noInline')
  static AttachmentPreview getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AttachmentPreview>(create);
  static AttachmentPreview? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get mimeType => $_getSZ(0);
  @$pb.TagNumber(1)
  set mimeType($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMimeType() => $_has(0);
  @$pb.TagNumber(1)
  void clearMimeType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get width => $_getIZ(1);
  @$pb.TagNumber(2)
  set width($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWidth() => $_has(1);
  @$pb.TagNumber(2)
  void clearWidth() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get height => $_getIZ(2);
  @$pb.TagNumber(3)
  set height($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHeight() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeight() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get uri => $_getSZ(3);
  @$pb.TagNumber(4)
  set uri($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUri() => $_has(3);
  @$pb.TagNumber(4)
  void clearUri() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get sizeBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSizeBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearSizeBytes() => $_clearField(5);
}

class ReactionContent extends $pb.GeneratedMessage {
  factory ReactionContent({
    $core.String? targetEventId,
    $core.String? reaction,
    $core.bool? add,
  }) {
    final result = create();
    if (targetEventId != null) result.targetEventId = targetEventId;
    if (reaction != null) result.reaction = reaction;
    if (add != null) result.add = add;
    return result;
  }

  ReactionContent._();

  factory ReactionContent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReactionContent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReactionContent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'targetEventId')
    ..aOS(2, _omitFieldNames ? '' : 'reaction')
    ..aOB(3, _omitFieldNames ? '' : 'add')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReactionContent clone() => ReactionContent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReactionContent copyWith(void Function(ReactionContent) updates) =>
      super.copyWith((message) => updates(message as ReactionContent))
          as ReactionContent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReactionContent create() => ReactionContent._();
  @$core.override
  ReactionContent createEmptyInstance() => create();
  static $pb.PbList<ReactionContent> createRepeated() =>
      $pb.PbList<ReactionContent>();
  @$core.pragma('dart2js:noInline')
  static ReactionContent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReactionContent>(create);
  static ReactionContent? _defaultInstance;

  /// Target message being reacted to
  @$pb.TagNumber(1)
  $core.String get targetEventId => $_getSZ(0);
  @$pb.TagNumber(1)
  set targetEventId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTargetEventId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTargetEventId() => $_clearField(1);

  /// Reaction key (e.g. 👍, ❤️, :custom_emoji:)
  @$pb.TagNumber(2)
  $core.String get reaction => $_getSZ(1);
  @$pb.TagNumber(2)
  set reaction($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReaction() => $_has(1);
  @$pb.TagNumber(2)
  void clearReaction() => $_clearField(2);

  /// add=true → ensure reaction exists
  /// add=false → ensure reaction does not exist
  @$pb.TagNumber(3)
  $core.bool get add => $_getBF(2);
  @$pb.TagNumber(3)
  set add($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAdd() => $_has(2);
  @$pb.TagNumber(3)
  void clearAdd() => $_clearField(3);
}

class EncryptedContent extends $pb.GeneratedMessage {
  factory EncryptedContent({
    $core.String? algorithm,
    $core.List<$core.int>? ciphertext,
    $core.List<$core.int>? nonce,
    $core.String? senderKeyId,
    $core.Iterable<$core.String>? recipientKeyIds,
    $core.List<$core.int>? aad,
    $core.String? sessionId,
  }) {
    final result = create();
    if (algorithm != null) result.algorithm = algorithm;
    if (ciphertext != null) result.ciphertext = ciphertext;
    if (nonce != null) result.nonce = nonce;
    if (senderKeyId != null) result.senderKeyId = senderKeyId;
    if (recipientKeyIds != null) result.recipientKeyIds.addAll(recipientKeyIds);
    if (aad != null) result.aad = aad;
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  EncryptedContent._();

  factory EncryptedContent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EncryptedContent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EncryptedContent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'algorithm')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'ciphertext', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..aOS(4, _omitFieldNames ? '' : 'senderKeyId')
    ..pPS(5, _omitFieldNames ? '' : 'recipientKeyIds')
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'aad', $pb.PbFieldType.OY)
    ..aOS(7, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EncryptedContent clone() => EncryptedContent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EncryptedContent copyWith(void Function(EncryptedContent) updates) =>
      super.copyWith((message) => updates(message as EncryptedContent))
          as EncryptedContent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedContent create() => EncryptedContent._();
  @$core.override
  EncryptedContent createEmptyInstance() => create();
  static $pb.PbList<EncryptedContent> createRepeated() =>
      $pb.PbList<EncryptedContent>();
  @$core.pragma('dart2js:noInline')
  static EncryptedContent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EncryptedContent>(create);
  static EncryptedContent? _defaultInstance;

  /// Encryption scheme identifier
  /// Examples: "olm.v2", "megolm.v1", "x25519-aesgcm"
  @$pb.TagNumber(1)
  $core.String get algorithm => $_getSZ(0);
  @$pb.TagNumber(1)
  set algorithm($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAlgorithm() => $_has(0);
  @$pb.TagNumber(1)
  void clearAlgorithm() => $_clearField(1);

  /// Base64 or binary-safe encoded ciphertext
  @$pb.TagNumber(2)
  $core.List<$core.int> get ciphertext => $_getN(1);
  @$pb.TagNumber(2)
  set ciphertext($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCiphertext() => $_has(1);
  @$pb.TagNumber(2)
  void clearCiphertext() => $_clearField(2);

  /// Optional per-message nonce / IV
  @$pb.TagNumber(3)
  $core.List<$core.int> get nonce => $_getN(2);
  @$pb.TagNumber(3)
  set nonce($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNonce() => $_has(2);
  @$pb.TagNumber(3)
  void clearNonce() => $_clearField(3);

  /// Optional sender key identifier
  @$pb.TagNumber(4)
  $core.String get senderKeyId => $_getSZ(3);
  @$pb.TagNumber(4)
  set senderKeyId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSenderKeyId() => $_has(3);
  @$pb.TagNumber(4)
  void clearSenderKeyId() => $_clearField(4);

  /// Optional recipient key references (for fan-out)
  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get recipientKeyIds => $_getList(4);

  /// Additional authenticated data (AAD)
  @$pb.TagNumber(6)
  $core.List<$core.int> get aad => $_getN(5);
  @$pb.TagNumber(6)
  set aad($core.List<$core.int> value) => $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAad() => $_has(5);
  @$pb.TagNumber(6)
  void clearAad() => $_clearField(6);

  /// Optional key agreement context identifier
  @$pb.TagNumber(7)
  $core.String get sessionId => $_getSZ(6);
  @$pb.TagNumber(7)
  set sessionId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSessionId() => $_has(6);
  @$pb.TagNumber(7)
  void clearSessionId() => $_clearField(7);
}

class CallContent extends $pb.GeneratedMessage {
  factory CallContent({
    $core.String? callId,
    CallContent_CallType? type,
    CallContent_CallAction? action,
    $core.String? sdp,
    $core.String? iceCandidate,
    $0.Struct? metadata,
  }) {
    final result = create();
    if (callId != null) result.callId = callId;
    if (type != null) result.type = type;
    if (action != null) result.action = action;
    if (sdp != null) result.sdp = sdp;
    if (iceCandidate != null) result.iceCandidate = iceCandidate;
    if (metadata != null) result.metadata = metadata;
    return result;
  }

  CallContent._();

  factory CallContent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CallContent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CallContent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'callId')
    ..e<CallContent_CallType>(
        2, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker: CallContent_CallType.CALL_TYPE_UNSPECIFIED,
        valueOf: CallContent_CallType.valueOf,
        enumValues: CallContent_CallType.values)
    ..e<CallContent_CallAction>(
        3, _omitFieldNames ? '' : 'action', $pb.PbFieldType.OE,
        defaultOrMaker: CallContent_CallAction.CALL_ACTION_UNSPECIFIED,
        valueOf: CallContent_CallAction.valueOf,
        enumValues: CallContent_CallAction.values)
    ..aOS(4, _omitFieldNames ? '' : 'sdp')
    ..aOS(5, _omitFieldNames ? '' : 'iceCandidate')
    ..aOM<$0.Struct>(8, _omitFieldNames ? '' : 'metadata',
        subBuilder: $0.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallContent clone() => CallContent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CallContent copyWith(void Function(CallContent) updates) =>
      super.copyWith((message) => updates(message as CallContent))
          as CallContent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CallContent create() => CallContent._();
  @$core.override
  CallContent createEmptyInstance() => create();
  static $pb.PbList<CallContent> createRepeated() => $pb.PbList<CallContent>();
  @$core.pragma('dart2js:noInline')
  static CallContent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CallContent>(create);
  static CallContent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get callId => $_getSZ(0);
  @$pb.TagNumber(1)
  set callId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCallId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCallId() => $_clearField(1);

  @$pb.TagNumber(2)
  CallContent_CallType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(CallContent_CallType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  /// OFFER, ANSWER → sdp required
  /// ICE_CANDIDATE → ice_candidate required
  /// END → no payload required
  @$pb.TagNumber(3)
  CallContent_CallAction get action => $_getN(2);
  @$pb.TagNumber(3)
  set action(CallContent_CallAction value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAction() => $_has(2);
  @$pb.TagNumber(3)
  void clearAction() => $_clearField(3);

  /// WebRTC payload (SDP or ICE candidate)
  @$pb.TagNumber(4)
  $core.String get sdp => $_getSZ(3);
  @$pb.TagNumber(4)
  set sdp($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSdp() => $_has(3);
  @$pb.TagNumber(4)
  void clearSdp() => $_clearField(4);

  /// Optional ICE candidate (when action = ICE_CANDIDATE)
  @$pb.TagNumber(5)
  $core.String get iceCandidate => $_getSZ(4);
  @$pb.TagNumber(5)
  set iceCandidate($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIceCandidate() => $_has(4);
  @$pb.TagNumber(5)
  void clearIceCandidate() => $_clearField(5);

  /// Optional metadata (bitrate, codecs, device hints)
  @$pb.TagNumber(8)
  $0.Struct get metadata => $_getN(5);
  @$pb.TagNumber(8)
  set metadata($0.Struct value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasMetadata() => $_has(5);
  @$pb.TagNumber(8)
  void clearMetadata() => $_clearField(8);
  @$pb.TagNumber(8)
  $0.Struct ensureMetadata() => $_ensure(5);
}

class MotionContent extends $pb.GeneratedMessage {
  factory MotionContent({
    $core.String? id,
    $core.String? title,
    $core.String? description,
    $core.int? eligibleVotes,
    PassingRule? passingRule,
    $core.Iterable<VoteChoice>? choices,
    $fixnum.Int64? closesAt,
    $core.Iterable<$core.String>? eligibleRoles,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (title != null) result.title = title;
    if (description != null) result.description = description;
    if (eligibleVotes != null) result.eligibleVotes = eligibleVotes;
    if (passingRule != null) result.passingRule = passingRule;
    if (choices != null) result.choices.addAll(choices);
    if (closesAt != null) result.closesAt = closesAt;
    if (eligibleRoles != null) result.eligibleRoles.addAll(eligibleRoles);
    return result;
  }

  MotionContent._();

  factory MotionContent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MotionContent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MotionContent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..a<$core.int>(
        4, _omitFieldNames ? '' : 'eligibleVotes', $pb.PbFieldType.OU3)
    ..aOM<PassingRule>(7, _omitFieldNames ? '' : 'passingRule',
        subBuilder: PassingRule.create)
    ..pc<VoteChoice>(8, _omitFieldNames ? '' : 'choices', $pb.PbFieldType.PM,
        subBuilder: VoteChoice.create)
    ..aInt64(12, _omitFieldNames ? '' : 'closesAt')
    ..pPS(13, _omitFieldNames ? '' : 'eligibleRoles')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MotionContent clone() => MotionContent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MotionContent copyWith(void Function(MotionContent) updates) =>
      super.copyWith((message) => updates(message as MotionContent))
          as MotionContent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MotionContent create() => MotionContent._();
  @$core.override
  MotionContent createEmptyInstance() => create();
  static $pb.PbList<MotionContent> createRepeated() =>
      $pb.PbList<MotionContent>();
  @$core.pragma('dart2js:noInline')
  static MotionContent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MotionContent>(create);
  static MotionContent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Human-readable description
  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => $_clearField(3);

  /// Snapshot of eligible voters at creation time (optional, cached)
  @$pb.TagNumber(4)
  $core.int get eligibleVotes => $_getIZ(3);
  @$pb.TagNumber(4)
  set eligibleVotes($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEligibleVotes() => $_has(3);
  @$pb.TagNumber(4)
  void clearEligibleVotes() => $_clearField(4);

  /// Number of votes required to pass
  /// Can represent absolute count or percentage thresholds
  /// Passing rule
  @$pb.TagNumber(7)
  PassingRule get passingRule => $_getN(4);
  @$pb.TagNumber(7)
  set passingRule(PassingRule value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasPassingRule() => $_has(4);
  @$pb.TagNumber(7)
  void clearPassingRule() => $_clearField(7);
  @$pb.TagNumber(7)
  PassingRule ensurePassingRule() => $_ensure(4);

  /// Available choices (YES / NO / ABSTAIN, etc)
  @$pb.TagNumber(8)
  $pb.PbList<VoteChoice> get choices => $_getList(5);

  /// Optional deadline (unix seconds)
  @$pb.TagNumber(12)
  $fixnum.Int64 get closesAt => $_getI64(6);
  @$pb.TagNumber(12)
  set closesAt($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(12)
  $core.bool hasClosesAt() => $_has(6);
  @$pb.TagNumber(12)
  void clearClosesAt() => $_clearField(12);

  /// Roles allowed to vote; eligible_votes is derived
  @$pb.TagNumber(13)
  $pb.PbList<$core.String> get eligibleRoles => $_getList(7);
}

class VoteChoice extends $pb.GeneratedMessage {
  factory VoteChoice({
    $core.String? id,
    $core.String? name,
    $core.String? description,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    return result;
  }

  VoteChoice._();

  factory VoteChoice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory VoteChoice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VoteChoice',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VoteChoice clone() => VoteChoice()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VoteChoice copyWith(void Function(VoteChoice) updates) =>
      super.copyWith((message) => updates(message as VoteChoice)) as VoteChoice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VoteChoice create() => VoteChoice._();
  @$core.override
  VoteChoice createEmptyInstance() => create();
  static $pb.PbList<VoteChoice> createRepeated() => $pb.PbList<VoteChoice>();
  @$core.pragma('dart2js:noInline')
  static VoteChoice getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VoteChoice>(create);
  static VoteChoice? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => $_clearField(3);
}

enum PassingRule_Rule { absolute, percentage, notSet }

class PassingRule extends $pb.GeneratedMessage {
  factory PassingRule({
    $core.int? absolute,
    $core.int? percentage,
    $core.String? passingChoiceId,
  }) {
    final result = create();
    if (absolute != null) result.absolute = absolute;
    if (percentage != null) result.percentage = percentage;
    if (passingChoiceId != null) result.passingChoiceId = passingChoiceId;
    return result;
  }

  PassingRule._();

  factory PassingRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PassingRule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, PassingRule_Rule> _PassingRule_RuleByTag = {
    1: PassingRule_Rule.absolute,
    2: PassingRule_Rule.percentage,
    0: PassingRule_Rule.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PassingRule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..a<$core.int>(1, _omitFieldNames ? '' : 'absolute', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'percentage', $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'passingChoiceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PassingRule clone() => PassingRule()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PassingRule copyWith(void Function(PassingRule) updates) =>
      super.copyWith((message) => updates(message as PassingRule))
          as PassingRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PassingRule create() => PassingRule._();
  @$core.override
  PassingRule createEmptyInstance() => create();
  static $pb.PbList<PassingRule> createRepeated() => $pb.PbList<PassingRule>();
  @$core.pragma('dart2js:noInline')
  static PassingRule getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PassingRule>(create);
  static PassingRule? _defaultInstance;

  PassingRule_Rule whichRule() => _PassingRule_RuleByTag[$_whichOneof(0)]!;
  void clearRule() => $_clearField($_whichOneof(0));

  /// Absolute number of votes required
  @$pb.TagNumber(1)
  $core.int get absolute => $_getIZ(0);
  @$pb.TagNumber(1)
  set absolute($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAbsolute() => $_has(0);
  @$pb.TagNumber(1)
  void clearAbsolute() => $_clearField(1);

  /// Percentage required to pass (0–100)
  @$pb.TagNumber(2)
  $core.int get percentage => $_getIZ(1);
  @$pb.TagNumber(2)
  set percentage($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPercentage() => $_has(1);
  @$pb.TagNumber(2)
  void clearPercentage() => $_clearField(2);

  /// Which choice constitutes "passing" (usually YES)
  @$pb.TagNumber(3)
  $core.String get passingChoiceId => $_getSZ(2);
  @$pb.TagNumber(3)
  set passingChoiceId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPassingChoiceId() => $_has(2);
  @$pb.TagNumber(3)
  void clearPassingChoiceId() => $_clearField(3);
}

/// total_votes_cast = sum(choice counts excluding invalid if configured)
/// remaining_votes  = eligible_votes - total_votes_cast
/// dead_votes       = tally(choice_id == "invalid")
/// target_votes     = derived from PassingRule
/// passed           = tally(passing_choice_id) >= target_votes
class VoteCast extends $pb.GeneratedMessage {
  factory VoteCast({
    $core.String? motionId,
    $core.String? choiceId,
  }) {
    final result = create();
    if (motionId != null) result.motionId = motionId;
    if (choiceId != null) result.choiceId = choiceId;
    return result;
  }

  VoteCast._();

  factory VoteCast.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory VoteCast.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VoteCast',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'motionId')
    ..aOS(2, _omitFieldNames ? '' : 'choiceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VoteCast clone() => VoteCast()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VoteCast copyWith(void Function(VoteCast) updates) =>
      super.copyWith((message) => updates(message as VoteCast)) as VoteCast;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VoteCast create() => VoteCast._();
  @$core.override
  VoteCast createEmptyInstance() => create();
  static $pb.PbList<VoteCast> createRepeated() => $pb.PbList<VoteCast>();
  @$core.pragma('dart2js:noInline')
  static VoteCast getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VoteCast>(create);
  static VoteCast? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get motionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set motionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMotionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMotionId() => $_clearField(1);

  /// Selected choice
  @$pb.TagNumber(2)
  $core.String get choiceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set choiceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChoiceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChoiceId() => $_clearField(2);
}

class VoteTally extends $pb.GeneratedMessage {
  factory VoteTally({
    $core.String? choiceId,
    $core.int? count,
  }) {
    final result = create();
    if (choiceId != null) result.choiceId = choiceId;
    if (count != null) result.count = count;
    return result;
  }

  VoteTally._();

  factory VoteTally.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory VoteTally.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VoteTally',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'choiceId')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'count', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VoteTally clone() => VoteTally()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VoteTally copyWith(void Function(VoteTally) updates) =>
      super.copyWith((message) => updates(message as VoteTally)) as VoteTally;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VoteTally create() => VoteTally._();
  @$core.override
  VoteTally createEmptyInstance() => create();
  static $pb.PbList<VoteTally> createRepeated() => $pb.PbList<VoteTally>();
  @$core.pragma('dart2js:noInline')
  static VoteTally getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VoteTally>(create);
  static VoteTally? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get choiceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set choiceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChoiceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChoiceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get count => $_getIZ(1);
  @$pb.TagNumber(2)
  set count($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearCount() => $_clearField(2);
}

class MotionTally extends $pb.GeneratedMessage {
  factory MotionTally({
    $core.String? motionId,
    $core.int? eligibleVotes,
    $core.Iterable<VoteTally>? tallies,
    $core.int? totalVotesCast,
    $core.int? deadVotes,
    $core.int? targetVotes,
    $core.bool? passed,
    $core.bool? closed,
  }) {
    final result = create();
    if (motionId != null) result.motionId = motionId;
    if (eligibleVotes != null) result.eligibleVotes = eligibleVotes;
    if (tallies != null) result.tallies.addAll(tallies);
    if (totalVotesCast != null) result.totalVotesCast = totalVotesCast;
    if (deadVotes != null) result.deadVotes = deadVotes;
    if (targetVotes != null) result.targetVotes = targetVotes;
    if (passed != null) result.passed = passed;
    if (closed != null) result.closed = closed;
    return result;
  }

  MotionTally._();

  factory MotionTally.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MotionTally.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MotionTally',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'motionId')
    ..a<$core.int>(
        2, _omitFieldNames ? '' : 'eligibleVotes', $pb.PbFieldType.OU3)
    ..pc<VoteTally>(3, _omitFieldNames ? '' : 'tallies', $pb.PbFieldType.PM,
        subBuilder: VoteTally.create)
    ..a<$core.int>(
        4, _omitFieldNames ? '' : 'totalVotesCast', $pb.PbFieldType.OU3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'deadVotes', $pb.PbFieldType.OU3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'targetVotes', $pb.PbFieldType.OU3)
    ..aOB(8, _omitFieldNames ? '' : 'passed')
    ..aOB(9, _omitFieldNames ? '' : 'closed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MotionTally clone() => MotionTally()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MotionTally copyWith(void Function(MotionTally) updates) =>
      super.copyWith((message) => updates(message as MotionTally))
          as MotionTally;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MotionTally create() => MotionTally._();
  @$core.override
  MotionTally createEmptyInstance() => create();
  static $pb.PbList<MotionTally> createRepeated() => $pb.PbList<MotionTally>();
  @$core.pragma('dart2js:noInline')
  static MotionTally getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MotionTally>(create);
  static MotionTally? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get motionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set motionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMotionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMotionId() => $_clearField(1);

  /// Total eligible voters
  @$pb.TagNumber(2)
  $core.int get eligibleVotes => $_getIZ(1);
  @$pb.TagNumber(2)
  set eligibleVotes($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEligibleVotes() => $_has(1);
  @$pb.TagNumber(2)
  void clearEligibleVotes() => $_clearField(2);

  /// Votes per choice
  @$pb.TagNumber(3)
  $pb.PbList<VoteTally> get tallies => $_getList(2);

  /// Derived counts
  @$pb.TagNumber(4)
  $core.int get totalVotesCast => $_getIZ(3);
  @$pb.TagNumber(4)
  set totalVotesCast($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotalVotesCast() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotalVotesCast() => $_clearField(4);

  /// Dead votes (invalid, expired, disqualified)
  @$pb.TagNumber(6)
  $core.int get deadVotes => $_getIZ(4);
  @$pb.TagNumber(6)
  set deadVotes($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(6)
  $core.bool hasDeadVotes() => $_has(4);
  @$pb.TagNumber(6)
  void clearDeadVotes() => $_clearField(6);

  /// Passing evaluation
  @$pb.TagNumber(7)
  $core.int get targetVotes => $_getIZ(5);
  @$pb.TagNumber(7)
  set targetVotes($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(7)
  $core.bool hasTargetVotes() => $_has(5);
  @$pb.TagNumber(7)
  void clearTargetVotes() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get passed => $_getBF(6);
  @$pb.TagNumber(8)
  set passed($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(8)
  $core.bool hasPassed() => $_has(6);
  @$pb.TagNumber(8)
  void clearPassed() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get closed => $_getBF(7);
  @$pb.TagNumber(9)
  set closed($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(9)
  $core.bool hasClosed() => $_has(7);
  @$pb.TagNumber(9)
  void clearClosed() => $_clearField(9);
}

enum FormValidationRule_Rule {
  required,
  minLength,
  maxLength,
  minValue,
  maxValue,
  pattern,
  minItems,
  maxItems,
  notSet
}

class FormValidationRule extends $pb.GeneratedMessage {
  factory FormValidationRule({
    $core.String? code,
    $core.String? message,
    $core.bool? required,
    $core.int? minLength,
    $core.int? maxLength,
    $core.double? minValue,
    $core.double? maxValue,
    $core.String? pattern,
    $core.int? minItems,
    $core.int? maxItems,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (message != null) result.message = message;
    if (required != null) result.required = required;
    if (minLength != null) result.minLength = minLength;
    if (maxLength != null) result.maxLength = maxLength;
    if (minValue != null) result.minValue = minValue;
    if (maxValue != null) result.maxValue = maxValue;
    if (pattern != null) result.pattern = pattern;
    if (minItems != null) result.minItems = minItems;
    if (maxItems != null) result.maxItems = maxItems;
    return result;
  }

  FormValidationRule._();

  factory FormValidationRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FormValidationRule.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, FormValidationRule_Rule>
      _FormValidationRule_RuleByTag = {
    3: FormValidationRule_Rule.required,
    4: FormValidationRule_Rule.minLength,
    5: FormValidationRule_Rule.maxLength,
    6: FormValidationRule_Rule.minValue,
    7: FormValidationRule_Rule.maxValue,
    8: FormValidationRule_Rule.pattern,
    9: FormValidationRule_Rule.minItems,
    10: FormValidationRule_Rule.maxItems,
    0: FormValidationRule_Rule.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormValidationRule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..oo(0, [3, 4, 5, 6, 7, 8, 9, 10])
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOB(3, _omitFieldNames ? '' : 'required')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'minLength', $pb.PbFieldType.O3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'maxLength', $pb.PbFieldType.O3)
    ..a<$core.double>(6, _omitFieldNames ? '' : 'minValue', $pb.PbFieldType.OD)
    ..a<$core.double>(7, _omitFieldNames ? '' : 'maxValue', $pb.PbFieldType.OD)
    ..aOS(8, _omitFieldNames ? '' : 'pattern')
    ..a<$core.int>(9, _omitFieldNames ? '' : 'minItems', $pb.PbFieldType.O3)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'maxItems', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormValidationRule clone() => FormValidationRule()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormValidationRule copyWith(void Function(FormValidationRule) updates) =>
      super.copyWith((message) => updates(message as FormValidationRule))
          as FormValidationRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormValidationRule create() => FormValidationRule._();
  @$core.override
  FormValidationRule createEmptyInstance() => create();
  static $pb.PbList<FormValidationRule> createRepeated() =>
      $pb.PbList<FormValidationRule>();
  @$core.pragma('dart2js:noInline')
  static FormValidationRule getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FormValidationRule>(create);
  static FormValidationRule? _defaultInstance;

  FormValidationRule_Rule whichRule() =>
      _FormValidationRule_RuleByTag[$_whichOneof(0)]!;
  void clearRule() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
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
  $core.bool get required => $_getBF(2);
  @$pb.TagNumber(3)
  set required($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRequired() => $_has(2);
  @$pb.TagNumber(3)
  void clearRequired() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get minLength => $_getIZ(3);
  @$pb.TagNumber(4)
  set minLength($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMinLength() => $_has(3);
  @$pb.TagNumber(4)
  void clearMinLength() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get maxLength => $_getIZ(4);
  @$pb.TagNumber(5)
  set maxLength($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMaxLength() => $_has(4);
  @$pb.TagNumber(5)
  void clearMaxLength() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get minValue => $_getN(5);
  @$pb.TagNumber(6)
  set minValue($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMinValue() => $_has(5);
  @$pb.TagNumber(6)
  void clearMinValue() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get maxValue => $_getN(6);
  @$pb.TagNumber(7)
  set maxValue($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMaxValue() => $_has(6);
  @$pb.TagNumber(7)
  void clearMaxValue() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get pattern => $_getSZ(7);
  @$pb.TagNumber(8)
  set pattern($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPattern() => $_has(7);
  @$pb.TagNumber(8)
  void clearPattern() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get minItems => $_getIZ(8);
  @$pb.TagNumber(9)
  set minItems($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasMinItems() => $_has(8);
  @$pb.TagNumber(9)
  void clearMinItems() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get maxItems => $_getIZ(9);
  @$pb.TagNumber(10)
  set maxItems($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasMaxItems() => $_has(9);
  @$pb.TagNumber(10)
  void clearMaxItems() => $_clearField(10);
}

class FormConditionClause extends $pb.GeneratedMessage {
  factory FormConditionClause({
    $core.String? fieldKey,
    FormConditionOperator? operator,
    $0.Value? value,
    $core.Iterable<$0.Value>? values,
  }) {
    final result = create();
    if (fieldKey != null) result.fieldKey = fieldKey;
    if (operator != null) result.operator = operator;
    if (value != null) result.value = value;
    if (values != null) result.values.addAll(values);
    return result;
  }

  FormConditionClause._();

  factory FormConditionClause.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FormConditionClause.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormConditionClause',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'fieldKey')
    ..e<FormConditionOperator>(
        2, _omitFieldNames ? '' : 'operator', $pb.PbFieldType.OE,
        defaultOrMaker:
            FormConditionOperator.FORM_CONDITION_OPERATOR_UNSPECIFIED,
        valueOf: FormConditionOperator.valueOf,
        enumValues: FormConditionOperator.values)
    ..aOM<$0.Value>(3, _omitFieldNames ? '' : 'value',
        subBuilder: $0.Value.create)
    ..pc<$0.Value>(4, _omitFieldNames ? '' : 'values', $pb.PbFieldType.PM,
        subBuilder: $0.Value.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormConditionClause clone() => FormConditionClause()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormConditionClause copyWith(void Function(FormConditionClause) updates) =>
      super.copyWith((message) => updates(message as FormConditionClause))
          as FormConditionClause;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormConditionClause create() => FormConditionClause._();
  @$core.override
  FormConditionClause createEmptyInstance() => create();
  static $pb.PbList<FormConditionClause> createRepeated() =>
      $pb.PbList<FormConditionClause>();
  @$core.pragma('dart2js:noInline')
  static FormConditionClause getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FormConditionClause>(create);
  static FormConditionClause? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldKey => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldKey($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFieldKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldKey() => $_clearField(1);

  @$pb.TagNumber(2)
  FormConditionOperator get operator => $_getN(1);
  @$pb.TagNumber(2)
  set operator(FormConditionOperator value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOperator() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperator() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.Value get value => $_getN(2);
  @$pb.TagNumber(3)
  set value($0.Value value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearValue() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Value ensureValue() => $_ensure(2);

  @$pb.TagNumber(4)
  $pb.PbList<$0.Value> get values => $_getList(3);
}

class FormConditionGroup extends $pb.GeneratedMessage {
  factory FormConditionGroup({
    $core.Iterable<FormConditionClause>? all,
    $core.Iterable<FormConditionClause>? any,
  }) {
    final result = create();
    if (all != null) result.all.addAll(all);
    if (any != null) result.any.addAll(any);
    return result;
  }

  FormConditionGroup._();

  factory FormConditionGroup.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FormConditionGroup.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormConditionGroup',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..pc<FormConditionClause>(
        1, _omitFieldNames ? '' : 'all', $pb.PbFieldType.PM,
        subBuilder: FormConditionClause.create)
    ..pc<FormConditionClause>(
        2, _omitFieldNames ? '' : 'any', $pb.PbFieldType.PM,
        subBuilder: FormConditionClause.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormConditionGroup clone() => FormConditionGroup()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormConditionGroup copyWith(void Function(FormConditionGroup) updates) =>
      super.copyWith((message) => updates(message as FormConditionGroup))
          as FormConditionGroup;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormConditionGroup create() => FormConditionGroup._();
  @$core.override
  FormConditionGroup createEmptyInstance() => create();
  static $pb.PbList<FormConditionGroup> createRepeated() =>
      $pb.PbList<FormConditionGroup>();
  @$core.pragma('dart2js:noInline')
  static FormConditionGroup getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FormConditionGroup>(create);
  static FormConditionGroup? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<FormConditionClause> get all => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<FormConditionClause> get any => $_getList(1);
}

class FormOption extends $pb.GeneratedMessage {
  factory FormOption({
    $core.String? value,
    $core.String? label,
    $core.String? helpText,
    $core.bool? disabled,
    $0.Struct? metadata,
  }) {
    final result = create();
    if (value != null) result.value = value;
    if (label != null) result.label = label;
    if (helpText != null) result.helpText = helpText;
    if (disabled != null) result.disabled = disabled;
    if (metadata != null) result.metadata = metadata;
    return result;
  }

  FormOption._();

  factory FormOption.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FormOption.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormOption',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'value')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'helpText')
    ..aOB(4, _omitFieldNames ? '' : 'disabled')
    ..aOM<$0.Struct>(5, _omitFieldNames ? '' : 'metadata',
        subBuilder: $0.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormOption clone() => FormOption()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormOption copyWith(void Function(FormOption) updates) =>
      super.copyWith((message) => updates(message as FormOption)) as FormOption;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormOption create() => FormOption._();
  @$core.override
  FormOption createEmptyInstance() => create();
  static $pb.PbList<FormOption> createRepeated() => $pb.PbList<FormOption>();
  @$core.pragma('dart2js:noInline')
  static FormOption getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FormOption>(create);
  static FormOption? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get helpText => $_getSZ(2);
  @$pb.TagNumber(3)
  set helpText($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHelpText() => $_has(2);
  @$pb.TagNumber(3)
  void clearHelpText() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get disabled => $_getBF(3);
  @$pb.TagNumber(4)
  set disabled($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDisabled() => $_has(3);
  @$pb.TagNumber(4)
  void clearDisabled() => $_clearField(4);

  @$pb.TagNumber(5)
  $0.Struct get metadata => $_getN(4);
  @$pb.TagNumber(5)
  set metadata($0.Struct value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasMetadata() => $_has(4);
  @$pb.TagNumber(5)
  void clearMetadata() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.Struct ensureMetadata() => $_ensure(4);
}

class FormFormattingHint extends $pb.GeneratedMessage {
  factory FormFormattingHint({
    $core.String? inputMask,
    $core.String? displayFormat,
    $core.String? currencyCode,
    $core.int? decimalScale,
    $core.String? keyboard,
    $core.String? autocomplete,
  }) {
    final result = create();
    if (inputMask != null) result.inputMask = inputMask;
    if (displayFormat != null) result.displayFormat = displayFormat;
    if (currencyCode != null) result.currencyCode = currencyCode;
    if (decimalScale != null) result.decimalScale = decimalScale;
    if (keyboard != null) result.keyboard = keyboard;
    if (autocomplete != null) result.autocomplete = autocomplete;
    return result;
  }

  FormFormattingHint._();

  factory FormFormattingHint.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FormFormattingHint.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormFormattingHint',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'inputMask')
    ..aOS(2, _omitFieldNames ? '' : 'displayFormat')
    ..aOS(3, _omitFieldNames ? '' : 'currencyCode')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'decimalScale', $pb.PbFieldType.O3)
    ..aOS(5, _omitFieldNames ? '' : 'keyboard')
    ..aOS(6, _omitFieldNames ? '' : 'autocomplete')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormFormattingHint clone() => FormFormattingHint()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormFormattingHint copyWith(void Function(FormFormattingHint) updates) =>
      super.copyWith((message) => updates(message as FormFormattingHint))
          as FormFormattingHint;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormFormattingHint create() => FormFormattingHint._();
  @$core.override
  FormFormattingHint createEmptyInstance() => create();
  static $pb.PbList<FormFormattingHint> createRepeated() =>
      $pb.PbList<FormFormattingHint>();
  @$core.pragma('dart2js:noInline')
  static FormFormattingHint getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FormFormattingHint>(create);
  static FormFormattingHint? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get inputMask => $_getSZ(0);
  @$pb.TagNumber(1)
  set inputMask($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInputMask() => $_has(0);
  @$pb.TagNumber(1)
  void clearInputMask() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get displayFormat => $_getSZ(1);
  @$pb.TagNumber(2)
  set displayFormat($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDisplayFormat() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisplayFormat() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get currencyCode => $_getSZ(2);
  @$pb.TagNumber(3)
  set currencyCode($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCurrencyCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearCurrencyCode() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get decimalScale => $_getIZ(3);
  @$pb.TagNumber(4)
  set decimalScale($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDecimalScale() => $_has(3);
  @$pb.TagNumber(4)
  void clearDecimalScale() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get keyboard => $_getSZ(4);
  @$pb.TagNumber(5)
  set keyboard($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasKeyboard() => $_has(4);
  @$pb.TagNumber(5)
  void clearKeyboard() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get autocomplete => $_getSZ(5);
  @$pb.TagNumber(6)
  set autocomplete($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAutocomplete() => $_has(5);
  @$pb.TagNumber(6)
  void clearAutocomplete() => $_clearField(6);
}

class FormReviewHint extends $pb.GeneratedMessage {
  factory FormReviewHint({
    $core.bool? includeInReview,
    $core.String? label,
    $core.String? sectionLabel,
    $core.String? formatter,
    $core.int? order,
  }) {
    final result = create();
    if (includeInReview != null) result.includeInReview = includeInReview;
    if (label != null) result.label = label;
    if (sectionLabel != null) result.sectionLabel = sectionLabel;
    if (formatter != null) result.formatter = formatter;
    if (order != null) result.order = order;
    return result;
  }

  FormReviewHint._();

  factory FormReviewHint.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FormReviewHint.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormReviewHint',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'includeInReview')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'sectionLabel')
    ..aOS(4, _omitFieldNames ? '' : 'formatter')
    ..a<$core.int>(5, _omitFieldNames ? '' : 'order', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormReviewHint clone() => FormReviewHint()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormReviewHint copyWith(void Function(FormReviewHint) updates) =>
      super.copyWith((message) => updates(message as FormReviewHint))
          as FormReviewHint;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormReviewHint create() => FormReviewHint._();
  @$core.override
  FormReviewHint createEmptyInstance() => create();
  static $pb.PbList<FormReviewHint> createRepeated() =>
      $pb.PbList<FormReviewHint>();
  @$core.pragma('dart2js:noInline')
  static FormReviewHint getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FormReviewHint>(create);
  static FormReviewHint? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get includeInReview => $_getBF(0);
  @$pb.TagNumber(1)
  set includeInReview($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIncludeInReview() => $_has(0);
  @$pb.TagNumber(1)
  void clearIncludeInReview() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sectionLabel => $_getSZ(2);
  @$pb.TagNumber(3)
  set sectionLabel($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSectionLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearSectionLabel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get formatter => $_getSZ(3);
  @$pb.TagNumber(4)
  set formatter($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFormatter() => $_has(3);
  @$pb.TagNumber(4)
  void clearFormatter() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get order => $_getIZ(4);
  @$pb.TagNumber(5)
  set order($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOrder() => $_has(4);
  @$pb.TagNumber(5)
  void clearOrder() => $_clearField(5);
}

class FormField extends $pb.GeneratedMessage {
  factory FormField({
    $core.String? key,
    FormFieldType? type,
    $core.String? label,
    $core.String? helpText,
    $core.String? placeholder,
    $core.bool? required,
    $0.Value? defaultValue,
    $core.Iterable<FormValidationRule>? validationRules,
    FormConditionGroup? visibilityCondition,
    FormConditionGroup? editabilityCondition,
    $core.Iterable<FormOption>? options,
    $core.Iterable<FormField>? nestedFields,
    $core.Iterable<FormSection>? nestedSections,
    FormFormattingHint? formatting,
    $0.Struct? uiHints,
    FormReviewHint? review,
    $core.Iterable<$core.String>? visibleToRoles,
    $core.bool? repeatable,
    $core.bool? hidden,
  }) {
    final result = create();
    if (key != null) result.key = key;
    if (type != null) result.type = type;
    if (label != null) result.label = label;
    if (helpText != null) result.helpText = helpText;
    if (placeholder != null) result.placeholder = placeholder;
    if (required != null) result.required = required;
    if (defaultValue != null) result.defaultValue = defaultValue;
    if (validationRules != null) result.validationRules.addAll(validationRules);
    if (visibilityCondition != null)
      result.visibilityCondition = visibilityCondition;
    if (editabilityCondition != null)
      result.editabilityCondition = editabilityCondition;
    if (options != null) result.options.addAll(options);
    if (nestedFields != null) result.nestedFields.addAll(nestedFields);
    if (nestedSections != null) result.nestedSections.addAll(nestedSections);
    if (formatting != null) result.formatting = formatting;
    if (uiHints != null) result.uiHints = uiHints;
    if (review != null) result.review = review;
    if (visibleToRoles != null) result.visibleToRoles.addAll(visibleToRoles);
    if (repeatable != null) result.repeatable = repeatable;
    if (hidden != null) result.hidden = hidden;
    return result;
  }

  FormField._();

  factory FormField.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FormField.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormField',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..e<FormFieldType>(2, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker: FormFieldType.FORM_FIELD_TYPE_UNSPECIFIED,
        valueOf: FormFieldType.valueOf,
        enumValues: FormFieldType.values)
    ..aOS(3, _omitFieldNames ? '' : 'label')
    ..aOS(4, _omitFieldNames ? '' : 'helpText')
    ..aOS(5, _omitFieldNames ? '' : 'placeholder')
    ..aOB(6, _omitFieldNames ? '' : 'required')
    ..aOM<$0.Value>(7, _omitFieldNames ? '' : 'defaultValue',
        subBuilder: $0.Value.create)
    ..pc<FormValidationRule>(
        8, _omitFieldNames ? '' : 'validationRules', $pb.PbFieldType.PM,
        subBuilder: FormValidationRule.create)
    ..aOM<FormConditionGroup>(9, _omitFieldNames ? '' : 'visibilityCondition',
        subBuilder: FormConditionGroup.create)
    ..aOM<FormConditionGroup>(10, _omitFieldNames ? '' : 'editabilityCondition',
        subBuilder: FormConditionGroup.create)
    ..pc<FormOption>(11, _omitFieldNames ? '' : 'options', $pb.PbFieldType.PM,
        subBuilder: FormOption.create)
    ..pc<FormField>(
        12, _omitFieldNames ? '' : 'nestedFields', $pb.PbFieldType.PM,
        subBuilder: FormField.create)
    ..pc<FormSection>(
        13, _omitFieldNames ? '' : 'nestedSections', $pb.PbFieldType.PM,
        subBuilder: FormSection.create)
    ..aOM<FormFormattingHint>(14, _omitFieldNames ? '' : 'formatting',
        subBuilder: FormFormattingHint.create)
    ..aOM<$0.Struct>(15, _omitFieldNames ? '' : 'uiHints',
        subBuilder: $0.Struct.create)
    ..aOM<FormReviewHint>(16, _omitFieldNames ? '' : 'review',
        subBuilder: FormReviewHint.create)
    ..pPS(17, _omitFieldNames ? '' : 'visibleToRoles')
    ..aOB(18, _omitFieldNames ? '' : 'repeatable')
    ..aOB(19, _omitFieldNames ? '' : 'hidden')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormField clone() => FormField()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormField copyWith(void Function(FormField) updates) =>
      super.copyWith((message) => updates(message as FormField)) as FormField;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormField create() => FormField._();
  @$core.override
  FormField createEmptyInstance() => create();
  static $pb.PbList<FormField> createRepeated() => $pb.PbList<FormField>();
  @$core.pragma('dart2js:noInline')
  static FormField getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FormField>(create);
  static FormField? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  @$pb.TagNumber(2)
  FormFieldType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(FormFieldType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get label => $_getSZ(2);
  @$pb.TagNumber(3)
  set label($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLabel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get helpText => $_getSZ(3);
  @$pb.TagNumber(4)
  set helpText($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHelpText() => $_has(3);
  @$pb.TagNumber(4)
  void clearHelpText() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get placeholder => $_getSZ(4);
  @$pb.TagNumber(5)
  set placeholder($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPlaceholder() => $_has(4);
  @$pb.TagNumber(5)
  void clearPlaceholder() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get required => $_getBF(5);
  @$pb.TagNumber(6)
  set required($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRequired() => $_has(5);
  @$pb.TagNumber(6)
  void clearRequired() => $_clearField(6);

  @$pb.TagNumber(7)
  $0.Value get defaultValue => $_getN(6);
  @$pb.TagNumber(7)
  set defaultValue($0.Value value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasDefaultValue() => $_has(6);
  @$pb.TagNumber(7)
  void clearDefaultValue() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.Value ensureDefaultValue() => $_ensure(6);

  @$pb.TagNumber(8)
  $pb.PbList<FormValidationRule> get validationRules => $_getList(7);

  @$pb.TagNumber(9)
  FormConditionGroup get visibilityCondition => $_getN(8);
  @$pb.TagNumber(9)
  set visibilityCondition(FormConditionGroup value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasVisibilityCondition() => $_has(8);
  @$pb.TagNumber(9)
  void clearVisibilityCondition() => $_clearField(9);
  @$pb.TagNumber(9)
  FormConditionGroup ensureVisibilityCondition() => $_ensure(8);

  @$pb.TagNumber(10)
  FormConditionGroup get editabilityCondition => $_getN(9);
  @$pb.TagNumber(10)
  set editabilityCondition(FormConditionGroup value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasEditabilityCondition() => $_has(9);
  @$pb.TagNumber(10)
  void clearEditabilityCondition() => $_clearField(10);
  @$pb.TagNumber(10)
  FormConditionGroup ensureEditabilityCondition() => $_ensure(9);

  @$pb.TagNumber(11)
  $pb.PbList<FormOption> get options => $_getList(10);

  @$pb.TagNumber(12)
  $pb.PbList<FormField> get nestedFields => $_getList(11);

  @$pb.TagNumber(13)
  $pb.PbList<FormSection> get nestedSections => $_getList(12);

  @$pb.TagNumber(14)
  FormFormattingHint get formatting => $_getN(13);
  @$pb.TagNumber(14)
  set formatting(FormFormattingHint value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasFormatting() => $_has(13);
  @$pb.TagNumber(14)
  void clearFormatting() => $_clearField(14);
  @$pb.TagNumber(14)
  FormFormattingHint ensureFormatting() => $_ensure(13);

  @$pb.TagNumber(15)
  $0.Struct get uiHints => $_getN(14);
  @$pb.TagNumber(15)
  set uiHints($0.Struct value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasUiHints() => $_has(14);
  @$pb.TagNumber(15)
  void clearUiHints() => $_clearField(15);
  @$pb.TagNumber(15)
  $0.Struct ensureUiHints() => $_ensure(14);

  @$pb.TagNumber(16)
  FormReviewHint get review => $_getN(15);
  @$pb.TagNumber(16)
  set review(FormReviewHint value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasReview() => $_has(15);
  @$pb.TagNumber(16)
  void clearReview() => $_clearField(16);
  @$pb.TagNumber(16)
  FormReviewHint ensureReview() => $_ensure(15);

  @$pb.TagNumber(17)
  $pb.PbList<$core.String> get visibleToRoles => $_getList(16);

  @$pb.TagNumber(18)
  $core.bool get repeatable => $_getBF(17);
  @$pb.TagNumber(18)
  set repeatable($core.bool value) => $_setBool(17, value);
  @$pb.TagNumber(18)
  $core.bool hasRepeatable() => $_has(17);
  @$pb.TagNumber(18)
  void clearRepeatable() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.bool get hidden => $_getBF(18);
  @$pb.TagNumber(19)
  set hidden($core.bool value) => $_setBool(18, value);
  @$pb.TagNumber(19)
  $core.bool hasHidden() => $_has(18);
  @$pb.TagNumber(19)
  void clearHidden() => $_clearField(19);
}

class FormSection extends $pb.GeneratedMessage {
  factory FormSection({
    $core.String? id,
    $core.String? title,
    $core.String? description,
    $core.Iterable<FormField>? fields,
    $0.Struct? uiHints,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (title != null) result.title = title;
    if (description != null) result.description = description;
    if (fields != null) result.fields.addAll(fields);
    if (uiHints != null) result.uiHints = uiHints;
    return result;
  }

  FormSection._();

  factory FormSection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FormSection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormSection',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..pc<FormField>(4, _omitFieldNames ? '' : 'fields', $pb.PbFieldType.PM,
        subBuilder: FormField.create)
    ..aOM<$0.Struct>(5, _omitFieldNames ? '' : 'uiHints',
        subBuilder: $0.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormSection clone() => FormSection()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormSection copyWith(void Function(FormSection) updates) =>
      super.copyWith((message) => updates(message as FormSection))
          as FormSection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormSection create() => FormSection._();
  @$core.override
  FormSection createEmptyInstance() => create();
  static $pb.PbList<FormSection> createRepeated() => $pb.PbList<FormSection>();
  @$core.pragma('dart2js:noInline')
  static FormSection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FormSection>(create);
  static FormSection? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<FormField> get fields => $_getList(3);

  @$pb.TagNumber(5)
  $0.Struct get uiHints => $_getN(4);
  @$pb.TagNumber(5)
  set uiHints($0.Struct value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasUiHints() => $_has(4);
  @$pb.TagNumber(5)
  void clearUiHints() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.Struct ensureUiHints() => $_ensure(4);
}

class FormStep extends $pb.GeneratedMessage {
  factory FormStep({
    $core.String? id,
    $core.String? title,
    $core.String? description,
    $core.Iterable<FormSection>? sections,
    $0.Struct? uiHints,
    FormConditionGroup? visibilityCondition,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (title != null) result.title = title;
    if (description != null) result.description = description;
    if (sections != null) result.sections.addAll(sections);
    if (uiHints != null) result.uiHints = uiHints;
    if (visibilityCondition != null)
      result.visibilityCondition = visibilityCondition;
    return result;
  }

  FormStep._();

  factory FormStep.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FormStep.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormStep',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..pc<FormSection>(4, _omitFieldNames ? '' : 'sections', $pb.PbFieldType.PM,
        subBuilder: FormSection.create)
    ..aOM<$0.Struct>(5, _omitFieldNames ? '' : 'uiHints',
        subBuilder: $0.Struct.create)
    ..aOM<FormConditionGroup>(6, _omitFieldNames ? '' : 'visibilityCondition',
        subBuilder: FormConditionGroup.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormStep clone() => FormStep()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormStep copyWith(void Function(FormStep) updates) =>
      super.copyWith((message) => updates(message as FormStep)) as FormStep;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormStep create() => FormStep._();
  @$core.override
  FormStep createEmptyInstance() => create();
  static $pb.PbList<FormStep> createRepeated() => $pb.PbList<FormStep>();
  @$core.pragma('dart2js:noInline')
  static FormStep getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FormStep>(create);
  static FormStep? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<FormSection> get sections => $_getList(3);

  @$pb.TagNumber(5)
  $0.Struct get uiHints => $_getN(4);
  @$pb.TagNumber(5)
  set uiHints($0.Struct value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasUiHints() => $_has(4);
  @$pb.TagNumber(5)
  void clearUiHints() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.Struct ensureUiHints() => $_ensure(4);

  @$pb.TagNumber(6)
  FormConditionGroup get visibilityCondition => $_getN(5);
  @$pb.TagNumber(6)
  set visibilityCondition(FormConditionGroup value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasVisibilityCondition() => $_has(5);
  @$pb.TagNumber(6)
  void clearVisibilityCondition() => $_clearField(6);
  @$pb.TagNumber(6)
  FormConditionGroup ensureVisibilityCondition() => $_ensure(5);
}

class FormSchema extends $pb.GeneratedMessage {
  factory FormSchema({
    $core.String? formId,
    $core.int? formVersion,
    $core.String? title,
    $core.String? subtitle,
    $core.String? description,
    $core.Iterable<FormStep>? steps,
    $0.Struct? workflowMetadata,
    $0.Struct? uiHints,
  }) {
    final result = create();
    if (formId != null) result.formId = formId;
    if (formVersion != null) result.formVersion = formVersion;
    if (title != null) result.title = title;
    if (subtitle != null) result.subtitle = subtitle;
    if (description != null) result.description = description;
    if (steps != null) result.steps.addAll(steps);
    if (workflowMetadata != null) result.workflowMetadata = workflowMetadata;
    if (uiHints != null) result.uiHints = uiHints;
    return result;
  }

  FormSchema._();

  factory FormSchema.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FormSchema.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormSchema',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'formId')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'formVersion', $pb.PbFieldType.O3)
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOS(4, _omitFieldNames ? '' : 'subtitle')
    ..aOS(5, _omitFieldNames ? '' : 'description')
    ..pc<FormStep>(6, _omitFieldNames ? '' : 'steps', $pb.PbFieldType.PM,
        subBuilder: FormStep.create)
    ..aOM<$0.Struct>(7, _omitFieldNames ? '' : 'workflowMetadata',
        subBuilder: $0.Struct.create)
    ..aOM<$0.Struct>(8, _omitFieldNames ? '' : 'uiHints',
        subBuilder: $0.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormSchema clone() => FormSchema()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormSchema copyWith(void Function(FormSchema) updates) =>
      super.copyWith((message) => updates(message as FormSchema)) as FormSchema;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormSchema create() => FormSchema._();
  @$core.override
  FormSchema createEmptyInstance() => create();
  static $pb.PbList<FormSchema> createRepeated() => $pb.PbList<FormSchema>();
  @$core.pragma('dart2js:noInline')
  static FormSchema getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FormSchema>(create);
  static FormSchema? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get formId => $_getSZ(0);
  @$pb.TagNumber(1)
  set formId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFormId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFormId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get formVersion => $_getIZ(1);
  @$pb.TagNumber(2)
  set formVersion($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFormVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get subtitle => $_getSZ(3);
  @$pb.TagNumber(4)
  set subtitle($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSubtitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearSubtitle() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get description => $_getSZ(4);
  @$pb.TagNumber(5)
  set description($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDescription() => $_has(4);
  @$pb.TagNumber(5)
  void clearDescription() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<FormStep> get steps => $_getList(5);

  @$pb.TagNumber(7)
  $0.Struct get workflowMetadata => $_getN(6);
  @$pb.TagNumber(7)
  set workflowMetadata($0.Struct value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasWorkflowMetadata() => $_has(6);
  @$pb.TagNumber(7)
  void clearWorkflowMetadata() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.Struct ensureWorkflowMetadata() => $_ensure(6);

  @$pb.TagNumber(8)
  $0.Struct get uiHints => $_getN(7);
  @$pb.TagNumber(8)
  set uiHints($0.Struct value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasUiHints() => $_has(7);
  @$pb.TagNumber(8)
  void clearUiHints() => $_clearField(8);
  @$pb.TagNumber(8)
  $0.Struct ensureUiHints() => $_ensure(7);
}

class FormPermissions extends $pb.GeneratedMessage {
  factory FormPermissions({
    $core.bool? canEdit,
    $core.bool? canSubmit,
    $core.bool? canSaveDraft,
    $core.bool? canGoBack,
    $core.String? assigneeSubscriptionId,
  }) {
    final result = create();
    if (canEdit != null) result.canEdit = canEdit;
    if (canSubmit != null) result.canSubmit = canSubmit;
    if (canSaveDraft != null) result.canSaveDraft = canSaveDraft;
    if (canGoBack != null) result.canGoBack = canGoBack;
    if (assigneeSubscriptionId != null)
      result.assigneeSubscriptionId = assigneeSubscriptionId;
    return result;
  }

  FormPermissions._();

  factory FormPermissions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FormPermissions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormPermissions',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'canEdit')
    ..aOB(2, _omitFieldNames ? '' : 'canSubmit')
    ..aOB(3, _omitFieldNames ? '' : 'canSaveDraft')
    ..aOB(4, _omitFieldNames ? '' : 'canGoBack')
    ..aOS(5, _omitFieldNames ? '' : 'assigneeSubscriptionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormPermissions clone() => FormPermissions()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormPermissions copyWith(void Function(FormPermissions) updates) =>
      super.copyWith((message) => updates(message as FormPermissions))
          as FormPermissions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormPermissions create() => FormPermissions._();
  @$core.override
  FormPermissions createEmptyInstance() => create();
  static $pb.PbList<FormPermissions> createRepeated() =>
      $pb.PbList<FormPermissions>();
  @$core.pragma('dart2js:noInline')
  static FormPermissions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FormPermissions>(create);
  static FormPermissions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get canEdit => $_getBF(0);
  @$pb.TagNumber(1)
  set canEdit($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCanEdit() => $_has(0);
  @$pb.TagNumber(1)
  void clearCanEdit() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get canSubmit => $_getBF(1);
  @$pb.TagNumber(2)
  set canSubmit($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCanSubmit() => $_has(1);
  @$pb.TagNumber(2)
  void clearCanSubmit() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get canSaveDraft => $_getBF(2);
  @$pb.TagNumber(3)
  set canSaveDraft($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCanSaveDraft() => $_has(2);
  @$pb.TagNumber(3)
  void clearCanSaveDraft() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get canGoBack => $_getBF(3);
  @$pb.TagNumber(4)
  set canGoBack($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCanGoBack() => $_has(3);
  @$pb.TagNumber(4)
  void clearCanGoBack() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get assigneeSubscriptionId => $_getSZ(4);
  @$pb.TagNumber(5)
  set assigneeSubscriptionId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAssigneeSubscriptionId() => $_has(4);
  @$pb.TagNumber(5)
  void clearAssigneeSubscriptionId() => $_clearField(5);
}

class FormReviewItem extends $pb.GeneratedMessage {
  factory FormReviewItem({
    $core.String? fieldKey,
    $core.String? label,
    $core.String? displayValue,
    $core.bool? emphasized,
  }) {
    final result = create();
    if (fieldKey != null) result.fieldKey = fieldKey;
    if (label != null) result.label = label;
    if (displayValue != null) result.displayValue = displayValue;
    if (emphasized != null) result.emphasized = emphasized;
    return result;
  }

  FormReviewItem._();

  factory FormReviewItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FormReviewItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormReviewItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'fieldKey')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'displayValue')
    ..aOB(4, _omitFieldNames ? '' : 'emphasized')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormReviewItem clone() => FormReviewItem()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormReviewItem copyWith(void Function(FormReviewItem) updates) =>
      super.copyWith((message) => updates(message as FormReviewItem))
          as FormReviewItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormReviewItem create() => FormReviewItem._();
  @$core.override
  FormReviewItem createEmptyInstance() => create();
  static $pb.PbList<FormReviewItem> createRepeated() =>
      $pb.PbList<FormReviewItem>();
  @$core.pragma('dart2js:noInline')
  static FormReviewItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FormReviewItem>(create);
  static FormReviewItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldKey => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldKey($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFieldKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldKey() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get displayValue => $_getSZ(2);
  @$pb.TagNumber(3)
  set displayValue($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDisplayValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisplayValue() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get emphasized => $_getBF(3);
  @$pb.TagNumber(4)
  set emphasized($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEmphasized() => $_has(3);
  @$pb.TagNumber(4)
  void clearEmphasized() => $_clearField(4);
}

class FormReviewSection extends $pb.GeneratedMessage {
  factory FormReviewSection({
    $core.String? stepId,
    $core.String? stepTitle,
    $core.String? sectionId,
    $core.String? sectionTitle,
    $core.Iterable<FormReviewItem>? items,
  }) {
    final result = create();
    if (stepId != null) result.stepId = stepId;
    if (stepTitle != null) result.stepTitle = stepTitle;
    if (sectionId != null) result.sectionId = sectionId;
    if (sectionTitle != null) result.sectionTitle = sectionTitle;
    if (items != null) result.items.addAll(items);
    return result;
  }

  FormReviewSection._();

  factory FormReviewSection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FormReviewSection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormReviewSection',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'stepId')
    ..aOS(2, _omitFieldNames ? '' : 'stepTitle')
    ..aOS(3, _omitFieldNames ? '' : 'sectionId')
    ..aOS(4, _omitFieldNames ? '' : 'sectionTitle')
    ..pc<FormReviewItem>(5, _omitFieldNames ? '' : 'items', $pb.PbFieldType.PM,
        subBuilder: FormReviewItem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormReviewSection clone() => FormReviewSection()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormReviewSection copyWith(void Function(FormReviewSection) updates) =>
      super.copyWith((message) => updates(message as FormReviewSection))
          as FormReviewSection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormReviewSection create() => FormReviewSection._();
  @$core.override
  FormReviewSection createEmptyInstance() => create();
  static $pb.PbList<FormReviewSection> createRepeated() =>
      $pb.PbList<FormReviewSection>();
  @$core.pragma('dart2js:noInline')
  static FormReviewSection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FormReviewSection>(create);
  static FormReviewSection? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get stepId => $_getSZ(0);
  @$pb.TagNumber(1)
  set stepId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStepId() => $_has(0);
  @$pb.TagNumber(1)
  void clearStepId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get stepTitle => $_getSZ(1);
  @$pb.TagNumber(2)
  set stepTitle($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStepTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearStepTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sectionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sectionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSectionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSectionId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get sectionTitle => $_getSZ(3);
  @$pb.TagNumber(4)
  set sectionTitle($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSectionTitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearSectionTitle() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<FormReviewItem> get items => $_getList(4);
}

class FormSubmissionSnapshot extends $pb.GeneratedMessage {
  factory FormSubmissionSnapshot({
    $core.String? formInstanceId,
    $core.String? schemaId,
    $core.int? schemaVersion,
    $1.Timestamp? submittedAt,
    $core.String? submittedBySubscriptionId,
    $0.Struct? answers,
    $core.Iterable<FormReviewSection>? formattedSections,
    $core.String? submissionReference,
    FormMessageState? status,
    $core.String? backendMessage,
    $core.String? workflowMessage,
    $0.Struct? metadata,
  }) {
    final result = create();
    if (formInstanceId != null) result.formInstanceId = formInstanceId;
    if (schemaId != null) result.schemaId = schemaId;
    if (schemaVersion != null) result.schemaVersion = schemaVersion;
    if (submittedAt != null) result.submittedAt = submittedAt;
    if (submittedBySubscriptionId != null)
      result.submittedBySubscriptionId = submittedBySubscriptionId;
    if (answers != null) result.answers = answers;
    if (formattedSections != null)
      result.formattedSections.addAll(formattedSections);
    if (submissionReference != null)
      result.submissionReference = submissionReference;
    if (status != null) result.status = status;
    if (backendMessage != null) result.backendMessage = backendMessage;
    if (workflowMessage != null) result.workflowMessage = workflowMessage;
    if (metadata != null) result.metadata = metadata;
    return result;
  }

  FormSubmissionSnapshot._();

  factory FormSubmissionSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FormSubmissionSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormSubmissionSnapshot',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'formInstanceId')
    ..aOS(2, _omitFieldNames ? '' : 'schemaId')
    ..a<$core.int>(
        3, _omitFieldNames ? '' : 'schemaVersion', $pb.PbFieldType.O3)
    ..aOM<$1.Timestamp>(4, _omitFieldNames ? '' : 'submittedAt',
        subBuilder: $1.Timestamp.create)
    ..aOS(5, _omitFieldNames ? '' : 'submittedBySubscriptionId')
    ..aOM<$0.Struct>(6, _omitFieldNames ? '' : 'answers',
        subBuilder: $0.Struct.create)
    ..pc<FormReviewSection>(
        7, _omitFieldNames ? '' : 'formattedSections', $pb.PbFieldType.PM,
        subBuilder: FormReviewSection.create)
    ..aOS(8, _omitFieldNames ? '' : 'submissionReference')
    ..e<FormMessageState>(
        9, _omitFieldNames ? '' : 'status', $pb.PbFieldType.OE,
        defaultOrMaker: FormMessageState.FORM_MESSAGE_STATE_UNSPECIFIED,
        valueOf: FormMessageState.valueOf,
        enumValues: FormMessageState.values)
    ..aOS(10, _omitFieldNames ? '' : 'backendMessage')
    ..aOS(11, _omitFieldNames ? '' : 'workflowMessage')
    ..aOM<$0.Struct>(12, _omitFieldNames ? '' : 'metadata',
        subBuilder: $0.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormSubmissionSnapshot clone() =>
      FormSubmissionSnapshot()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormSubmissionSnapshot copyWith(
          void Function(FormSubmissionSnapshot) updates) =>
      super.copyWith((message) => updates(message as FormSubmissionSnapshot))
          as FormSubmissionSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormSubmissionSnapshot create() => FormSubmissionSnapshot._();
  @$core.override
  FormSubmissionSnapshot createEmptyInstance() => create();
  static $pb.PbList<FormSubmissionSnapshot> createRepeated() =>
      $pb.PbList<FormSubmissionSnapshot>();
  @$core.pragma('dart2js:noInline')
  static FormSubmissionSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FormSubmissionSnapshot>(create);
  static FormSubmissionSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get formInstanceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set formInstanceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFormInstanceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFormInstanceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get schemaId => $_getSZ(1);
  @$pb.TagNumber(2)
  set schemaId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSchemaId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSchemaId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get schemaVersion => $_getIZ(2);
  @$pb.TagNumber(3)
  set schemaVersion($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSchemaVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearSchemaVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $1.Timestamp get submittedAt => $_getN(3);
  @$pb.TagNumber(4)
  set submittedAt($1.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSubmittedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearSubmittedAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.Timestamp ensureSubmittedAt() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.String get submittedBySubscriptionId => $_getSZ(4);
  @$pb.TagNumber(5)
  set submittedBySubscriptionId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSubmittedBySubscriptionId() => $_has(4);
  @$pb.TagNumber(5)
  void clearSubmittedBySubscriptionId() => $_clearField(5);

  @$pb.TagNumber(6)
  $0.Struct get answers => $_getN(5);
  @$pb.TagNumber(6)
  set answers($0.Struct value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasAnswers() => $_has(5);
  @$pb.TagNumber(6)
  void clearAnswers() => $_clearField(6);
  @$pb.TagNumber(6)
  $0.Struct ensureAnswers() => $_ensure(5);

  @$pb.TagNumber(7)
  $pb.PbList<FormReviewSection> get formattedSections => $_getList(6);

  @$pb.TagNumber(8)
  $core.String get submissionReference => $_getSZ(7);
  @$pb.TagNumber(8)
  set submissionReference($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSubmissionReference() => $_has(7);
  @$pb.TagNumber(8)
  void clearSubmissionReference() => $_clearField(8);

  @$pb.TagNumber(9)
  FormMessageState get status => $_getN(8);
  @$pb.TagNumber(9)
  set status(FormMessageState value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasStatus() => $_has(8);
  @$pb.TagNumber(9)
  void clearStatus() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get backendMessage => $_getSZ(9);
  @$pb.TagNumber(10)
  set backendMessage($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasBackendMessage() => $_has(9);
  @$pb.TagNumber(10)
  void clearBackendMessage() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get workflowMessage => $_getSZ(10);
  @$pb.TagNumber(11)
  set workflowMessage($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasWorkflowMessage() => $_has(10);
  @$pb.TagNumber(11)
  void clearWorkflowMessage() => $_clearField(11);

  @$pb.TagNumber(12)
  $0.Struct get metadata => $_getN(11);
  @$pb.TagNumber(12)
  set metadata($0.Struct value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasMetadata() => $_has(11);
  @$pb.TagNumber(12)
  void clearMetadata() => $_clearField(12);
  @$pb.TagNumber(12)
  $0.Struct ensureMetadata() => $_ensure(11);
}

class FormRequestContent extends $pb.GeneratedMessage {
  factory FormRequestContent({
    $core.String? formInstanceId,
    $core.String? schemaId,
    $core.int? schemaVersion,
    $core.String? title,
    $core.String? description,
    FormMessageState? state,
    $core.bool? reviewRequired,
    FormSchema? schema,
    $0.Struct? initialValues,
    $0.Struct? serverDraftValues,
    FormSubmissionSnapshot? finalSubmissionSnapshot,
    FormPermissions? permissions,
    $1.Timestamp? expiresAt,
    $0.Struct? workflowContext,
    $core.String? currentWorkflowState,
  }) {
    final result = create();
    if (formInstanceId != null) result.formInstanceId = formInstanceId;
    if (schemaId != null) result.schemaId = schemaId;
    if (schemaVersion != null) result.schemaVersion = schemaVersion;
    if (title != null) result.title = title;
    if (description != null) result.description = description;
    if (state != null) result.state = state;
    if (reviewRequired != null) result.reviewRequired = reviewRequired;
    if (schema != null) result.schema = schema;
    if (initialValues != null) result.initialValues = initialValues;
    if (serverDraftValues != null) result.serverDraftValues = serverDraftValues;
    if (finalSubmissionSnapshot != null)
      result.finalSubmissionSnapshot = finalSubmissionSnapshot;
    if (permissions != null) result.permissions = permissions;
    if (expiresAt != null) result.expiresAt = expiresAt;
    if (workflowContext != null) result.workflowContext = workflowContext;
    if (currentWorkflowState != null)
      result.currentWorkflowState = currentWorkflowState;
    return result;
  }

  FormRequestContent._();

  factory FormRequestContent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FormRequestContent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormRequestContent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'formInstanceId')
    ..aOS(2, _omitFieldNames ? '' : 'schemaId')
    ..a<$core.int>(
        3, _omitFieldNames ? '' : 'schemaVersion', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'title')
    ..aOS(5, _omitFieldNames ? '' : 'description')
    ..e<FormMessageState>(6, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker: FormMessageState.FORM_MESSAGE_STATE_UNSPECIFIED,
        valueOf: FormMessageState.valueOf,
        enumValues: FormMessageState.values)
    ..aOB(7, _omitFieldNames ? '' : 'reviewRequired')
    ..aOM<FormSchema>(8, _omitFieldNames ? '' : 'schema',
        subBuilder: FormSchema.create)
    ..aOM<$0.Struct>(9, _omitFieldNames ? '' : 'initialValues',
        subBuilder: $0.Struct.create)
    ..aOM<$0.Struct>(10, _omitFieldNames ? '' : 'serverDraftValues',
        subBuilder: $0.Struct.create)
    ..aOM<FormSubmissionSnapshot>(
        11, _omitFieldNames ? '' : 'finalSubmissionSnapshot',
        subBuilder: FormSubmissionSnapshot.create)
    ..aOM<FormPermissions>(12, _omitFieldNames ? '' : 'permissions',
        subBuilder: FormPermissions.create)
    ..aOM<$1.Timestamp>(13, _omitFieldNames ? '' : 'expiresAt',
        subBuilder: $1.Timestamp.create)
    ..aOM<$0.Struct>(14, _omitFieldNames ? '' : 'workflowContext',
        subBuilder: $0.Struct.create)
    ..aOS(15, _omitFieldNames ? '' : 'currentWorkflowState')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormRequestContent clone() => FormRequestContent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormRequestContent copyWith(void Function(FormRequestContent) updates) =>
      super.copyWith((message) => updates(message as FormRequestContent))
          as FormRequestContent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormRequestContent create() => FormRequestContent._();
  @$core.override
  FormRequestContent createEmptyInstance() => create();
  static $pb.PbList<FormRequestContent> createRepeated() =>
      $pb.PbList<FormRequestContent>();
  @$core.pragma('dart2js:noInline')
  static FormRequestContent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FormRequestContent>(create);
  static FormRequestContent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get formInstanceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set formInstanceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFormInstanceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFormInstanceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get schemaId => $_getSZ(1);
  @$pb.TagNumber(2)
  set schemaId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSchemaId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSchemaId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get schemaVersion => $_getIZ(2);
  @$pb.TagNumber(3)
  set schemaVersion($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSchemaVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearSchemaVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get title => $_getSZ(3);
  @$pb.TagNumber(4)
  set title($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearTitle() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get description => $_getSZ(4);
  @$pb.TagNumber(5)
  set description($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDescription() => $_has(4);
  @$pb.TagNumber(5)
  void clearDescription() => $_clearField(5);

  @$pb.TagNumber(6)
  FormMessageState get state => $_getN(5);
  @$pb.TagNumber(6)
  set state(FormMessageState value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasState() => $_has(5);
  @$pb.TagNumber(6)
  void clearState() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get reviewRequired => $_getBF(6);
  @$pb.TagNumber(7)
  set reviewRequired($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasReviewRequired() => $_has(6);
  @$pb.TagNumber(7)
  void clearReviewRequired() => $_clearField(7);

  @$pb.TagNumber(8)
  FormSchema get schema => $_getN(7);
  @$pb.TagNumber(8)
  set schema(FormSchema value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasSchema() => $_has(7);
  @$pb.TagNumber(8)
  void clearSchema() => $_clearField(8);
  @$pb.TagNumber(8)
  FormSchema ensureSchema() => $_ensure(7);

  @$pb.TagNumber(9)
  $0.Struct get initialValues => $_getN(8);
  @$pb.TagNumber(9)
  set initialValues($0.Struct value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasInitialValues() => $_has(8);
  @$pb.TagNumber(9)
  void clearInitialValues() => $_clearField(9);
  @$pb.TagNumber(9)
  $0.Struct ensureInitialValues() => $_ensure(8);

  @$pb.TagNumber(10)
  $0.Struct get serverDraftValues => $_getN(9);
  @$pb.TagNumber(10)
  set serverDraftValues($0.Struct value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasServerDraftValues() => $_has(9);
  @$pb.TagNumber(10)
  void clearServerDraftValues() => $_clearField(10);
  @$pb.TagNumber(10)
  $0.Struct ensureServerDraftValues() => $_ensure(9);

  @$pb.TagNumber(11)
  FormSubmissionSnapshot get finalSubmissionSnapshot => $_getN(10);
  @$pb.TagNumber(11)
  set finalSubmissionSnapshot(FormSubmissionSnapshot value) =>
      $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasFinalSubmissionSnapshot() => $_has(10);
  @$pb.TagNumber(11)
  void clearFinalSubmissionSnapshot() => $_clearField(11);
  @$pb.TagNumber(11)
  FormSubmissionSnapshot ensureFinalSubmissionSnapshot() => $_ensure(10);

  @$pb.TagNumber(12)
  FormPermissions get permissions => $_getN(11);
  @$pb.TagNumber(12)
  set permissions(FormPermissions value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasPermissions() => $_has(11);
  @$pb.TagNumber(12)
  void clearPermissions() => $_clearField(12);
  @$pb.TagNumber(12)
  FormPermissions ensurePermissions() => $_ensure(11);

  @$pb.TagNumber(13)
  $1.Timestamp get expiresAt => $_getN(12);
  @$pb.TagNumber(13)
  set expiresAt($1.Timestamp value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasExpiresAt() => $_has(12);
  @$pb.TagNumber(13)
  void clearExpiresAt() => $_clearField(13);
  @$pb.TagNumber(13)
  $1.Timestamp ensureExpiresAt() => $_ensure(12);

  @$pb.TagNumber(14)
  $0.Struct get workflowContext => $_getN(13);
  @$pb.TagNumber(14)
  set workflowContext($0.Struct value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasWorkflowContext() => $_has(13);
  @$pb.TagNumber(14)
  void clearWorkflowContext() => $_clearField(14);
  @$pb.TagNumber(14)
  $0.Struct ensureWorkflowContext() => $_ensure(13);

  @$pb.TagNumber(15)
  $core.String get currentWorkflowState => $_getSZ(14);
  @$pb.TagNumber(15)
  set currentWorkflowState($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasCurrentWorkflowState() => $_has(14);
  @$pb.TagNumber(15)
  void clearCurrentWorkflowState() => $_clearField(15);
}

class FormSubmissionResultContent extends $pb.GeneratedMessage {
  factory FormSubmissionResultContent({
    $core.String? formInstanceId,
    $core.String? schemaId,
    $core.int? schemaVersion,
    $core.String? sourceEventId,
    FormMessageState? state,
    $core.bool? reviewConfirmed,
    FormSubmissionSnapshot? submissionSnapshot,
    $0.Struct? metadata,
  }) {
    final result = create();
    if (formInstanceId != null) result.formInstanceId = formInstanceId;
    if (schemaId != null) result.schemaId = schemaId;
    if (schemaVersion != null) result.schemaVersion = schemaVersion;
    if (sourceEventId != null) result.sourceEventId = sourceEventId;
    if (state != null) result.state = state;
    if (reviewConfirmed != null) result.reviewConfirmed = reviewConfirmed;
    if (submissionSnapshot != null)
      result.submissionSnapshot = submissionSnapshot;
    if (metadata != null) result.metadata = metadata;
    return result;
  }

  FormSubmissionResultContent._();

  factory FormSubmissionResultContent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FormSubmissionResultContent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormSubmissionResultContent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'formInstanceId')
    ..aOS(2, _omitFieldNames ? '' : 'schemaId')
    ..a<$core.int>(
        3, _omitFieldNames ? '' : 'schemaVersion', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'sourceEventId')
    ..e<FormMessageState>(5, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker: FormMessageState.FORM_MESSAGE_STATE_UNSPECIFIED,
        valueOf: FormMessageState.valueOf,
        enumValues: FormMessageState.values)
    ..aOB(6, _omitFieldNames ? '' : 'reviewConfirmed')
    ..aOM<FormSubmissionSnapshot>(
        7, _omitFieldNames ? '' : 'submissionSnapshot',
        subBuilder: FormSubmissionSnapshot.create)
    ..aOM<$0.Struct>(8, _omitFieldNames ? '' : 'metadata',
        subBuilder: $0.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormSubmissionResultContent clone() =>
      FormSubmissionResultContent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormSubmissionResultContent copyWith(
          void Function(FormSubmissionResultContent) updates) =>
      super.copyWith(
              (message) => updates(message as FormSubmissionResultContent))
          as FormSubmissionResultContent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormSubmissionResultContent create() =>
      FormSubmissionResultContent._();
  @$core.override
  FormSubmissionResultContent createEmptyInstance() => create();
  static $pb.PbList<FormSubmissionResultContent> createRepeated() =>
      $pb.PbList<FormSubmissionResultContent>();
  @$core.pragma('dart2js:noInline')
  static FormSubmissionResultContent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FormSubmissionResultContent>(create);
  static FormSubmissionResultContent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get formInstanceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set formInstanceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFormInstanceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFormInstanceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get schemaId => $_getSZ(1);
  @$pb.TagNumber(2)
  set schemaId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSchemaId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSchemaId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get schemaVersion => $_getIZ(2);
  @$pb.TagNumber(3)
  set schemaVersion($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSchemaVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearSchemaVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get sourceEventId => $_getSZ(3);
  @$pb.TagNumber(4)
  set sourceEventId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSourceEventId() => $_has(3);
  @$pb.TagNumber(4)
  void clearSourceEventId() => $_clearField(4);

  @$pb.TagNumber(5)
  FormMessageState get state => $_getN(4);
  @$pb.TagNumber(5)
  set state(FormMessageState value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasState() => $_has(4);
  @$pb.TagNumber(5)
  void clearState() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get reviewConfirmed => $_getBF(5);
  @$pb.TagNumber(6)
  set reviewConfirmed($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasReviewConfirmed() => $_has(5);
  @$pb.TagNumber(6)
  void clearReviewConfirmed() => $_clearField(6);

  @$pb.TagNumber(7)
  FormSubmissionSnapshot get submissionSnapshot => $_getN(6);
  @$pb.TagNumber(7)
  set submissionSnapshot(FormSubmissionSnapshot value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasSubmissionSnapshot() => $_has(6);
  @$pb.TagNumber(7)
  void clearSubmissionSnapshot() => $_clearField(7);
  @$pb.TagNumber(7)
  FormSubmissionSnapshot ensureSubmissionSnapshot() => $_ensure(6);

  @$pb.TagNumber(8)
  $0.Struct get metadata => $_getN(7);
  @$pb.TagNumber(8)
  set metadata($0.Struct value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasMetadata() => $_has(7);
  @$pb.TagNumber(8)
  void clearMetadata() => $_clearField(8);
  @$pb.TagNumber(8)
  $0.Struct ensureMetadata() => $_ensure(7);
}

/// FinanceCardContent is a finance fact rendered into a room. It is display
/// only: chat never carries authorization, so a card carries no token,
/// signature, capability or approval. Any action a card offers is completed by
/// the client as a device-signed command to the finance service, never by
/// replying in chat.
class FinanceCardContent extends $pb.GeneratedMessage {
  factory FinanceCardContent({
    $core.String? cardId,
    $core.String? groupId,
    $core.String? kind,
    $core.String? title,
    $core.String? body,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? data,
  }) {
    final result = create();
    if (cardId != null) result.cardId = cardId;
    if (groupId != null) result.groupId = groupId;
    if (kind != null) result.kind = kind;
    if (title != null) result.title = title;
    if (body != null) result.body = body;
    if (data != null) result.data.addEntries(data);
    return result;
  }

  FinanceCardContent._();

  factory FinanceCardContent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FinanceCardContent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FinanceCardContent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'cardId')
    ..aOS(2, _omitFieldNames ? '' : 'groupId')
    ..aOS(3, _omitFieldNames ? '' : 'kind')
    ..aOS(4, _omitFieldNames ? '' : 'title')
    ..aOS(5, _omitFieldNames ? '' : 'body')
    ..m<$core.String, $core.String>(6, _omitFieldNames ? '' : 'data',
        entryClassName: 'FinanceCardContent.DataEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('chat.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FinanceCardContent clone() => FinanceCardContent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FinanceCardContent copyWith(void Function(FinanceCardContent) updates) =>
      super.copyWith((message) => updates(message as FinanceCardContent))
          as FinanceCardContent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FinanceCardContent create() => FinanceCardContent._();
  @$core.override
  FinanceCardContent createEmptyInstance() => create();
  static $pb.PbList<FinanceCardContent> createRepeated() =>
      $pb.PbList<FinanceCardContent>();
  @$core.pragma('dart2js:noInline')
  static FinanceCardContent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FinanceCardContent>(create);
  static FinanceCardContent? _defaultInstance;

  /// Identifier of the finance fact this card renders. Stable across
  /// re-renders so a client can de-duplicate.
  @$pb.TagNumber(1)
  $core.String get cardId => $_getSZ(0);
  @$pb.TagNumber(1)
  set cardId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCardId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCardId() => $_clearField(1);

  /// Finance group the card belongs to; matches the room's
  /// `stawi.group_id` metadata.
  @$pb.TagNumber(2)
  $core.String get groupId => $_getSZ(1);
  @$pb.TagNumber(2)
  set groupId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGroupId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroupId() => $_clearField(2);

  /// Card kind, e.g. "PROPOSAL", "MOTION_TALLY", "CONTRIBUTION".
  @$pb.TagNumber(3)
  $core.String get kind => $_getSZ(2);
  @$pb.TagNumber(3)
  set kind($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  /// Human-readable heading.
  @$pb.TagNumber(4)
  $core.String get title => $_getSZ(3);
  @$pb.TagNumber(4)
  set title($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearTitle() => $_clearField(4);

  /// Human-readable body.
  @$pb.TagNumber(5)
  $core.String get body => $_getSZ(4);
  @$pb.TagNumber(5)
  set body($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBody() => $_has(4);
  @$pb.TagNumber(5)
  void clearBody() => $_clearField(5);

  /// Display-only values for the renderer (identifiers, amounts, labels).
  @$pb.TagNumber(6)
  $pb.PbMap<$core.String, $core.String> get data => $_getMap(5);
}

/// StawiRoomConversionContent asks for this room to become a Stawi room: the
/// chain creates custody for the room under the room's own id once the
/// founders have signed the genesis. Chat relays the request to settlement,
/// which compiles the constitution and prepares the genesis; chat then fills
/// in `genesis` on the stored event, so the event itself is the genesis card.
class StawiRoomConversionContent extends $pb.GeneratedMessage {
  factory StawiRoomConversionContent({
    $core.String? templateId,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? ruleValues,
    $core.Iterable<$core.String>? founderSubscriptionIds,
    StawiJoinPolicy? joinPolicy,
    StawiGenesis? genesis,
    $core.String? agentProfileId,
  }) {
    final result = create();
    if (templateId != null) result.templateId = templateId;
    if (ruleValues != null) result.ruleValues.addEntries(ruleValues);
    if (founderSubscriptionIds != null)
      result.founderSubscriptionIds.addAll(founderSubscriptionIds);
    if (joinPolicy != null) result.joinPolicy = joinPolicy;
    if (genesis != null) result.genesis = genesis;
    if (agentProfileId != null) result.agentProfileId = agentProfileId;
    return result;
  }

  StawiRoomConversionContent._();

  factory StawiRoomConversionContent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StawiRoomConversionContent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StawiRoomConversionContent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'templateId')
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'ruleValues',
        entryClassName: 'StawiRoomConversionContent.RuleValuesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('chat.v1'))
    ..pPS(3, _omitFieldNames ? '' : 'founderSubscriptionIds')
    ..e<StawiJoinPolicy>(
        4, _omitFieldNames ? '' : 'joinPolicy', $pb.PbFieldType.OE,
        defaultOrMaker: StawiJoinPolicy.STAWI_JOIN_POLICY_UNSPECIFIED,
        valueOf: StawiJoinPolicy.valueOf,
        enumValues: StawiJoinPolicy.values)
    ..aOM<StawiGenesis>(5, _omitFieldNames ? '' : 'genesis',
        subBuilder: StawiGenesis.create)
    ..aOS(6, _omitFieldNames ? '' : 'agentProfileId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StawiRoomConversionContent clone() =>
      StawiRoomConversionContent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StawiRoomConversionContent copyWith(
          void Function(StawiRoomConversionContent) updates) =>
      super.copyWith(
              (message) => updates(message as StawiRoomConversionContent))
          as StawiRoomConversionContent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StawiRoomConversionContent create() => StawiRoomConversionContent._();
  @$core.override
  StawiRoomConversionContent createEmptyInstance() => create();
  static $pb.PbList<StawiRoomConversionContent> createRepeated() =>
      $pb.PbList<StawiRoomConversionContent>();
  @$core.pragma('dart2js:noInline')
  static StawiRoomConversionContent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StawiRoomConversionContent>(create);
  static StawiRoomConversionContent? _defaultInstance;

  /// Constitution template the rules are applied to.
  @$pb.TagNumber(1)
  $core.String get templateId => $_getSZ(0);
  @$pb.TagNumber(1)
  set templateId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTemplateId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTemplateId() => $_clearField(1);

  /// Rule values for the template, keyed by rule name. Values are strings
  /// (decimal numbers, durations, enum names); settlement parses and checks
  /// them against the template when it compiles the constitution.
  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $core.String> get ruleValues => $_getMap(1);

  /// Subscriptions of this room whose holders found the Stawi room. Each must
  /// be an active subscription of the room.
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get founderSubscriptionIds => $_getList(2);

  @$pb.TagNumber(4)
  StawiJoinPolicy get joinPolicy => $_getN(3);
  @$pb.TagNumber(4)
  set joinPolicy(StawiJoinPolicy value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasJoinPolicy() => $_has(3);
  @$pb.TagNumber(4)
  void clearJoinPolicy() => $_clearField(4);

  /// Output only: the genesis settlement prepared. Set by the server on the
  /// stored event; a client that sets it is refused.
  @$pb.TagNumber(5)
  StawiGenesis get genesis => $_getN(4);
  @$pb.TagNumber(5)
  set genesis(StawiGenesis value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasGenesis() => $_has(4);
  @$pb.TagNumber(5)
  void clearGenesis() => $_clearField(5);
  @$pb.TagNumber(5)
  StawiGenesis ensureGenesis() => $_ensure(4);

  /// Optional: the profile of the room's Stawi agent (protocol fee spec), paid
  /// a share of the Stawi fee for the life of the room; empty for none. Chat
  /// accepts an active member of this room, or a DM partner of the converting
  /// member who has taken part in that DM. Settlement resolves the profile to
  /// its account; the founders sign it in the genesis.
  @$pb.TagNumber(6)
  $core.String get agentProfileId => $_getSZ(5);
  @$pb.TagNumber(6)
  set agentProfileId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAgentProfileId() => $_has(5);
  @$pb.TagNumber(6)
  void clearAgentProfileId() => $_clearField(6);
}

/// StawiGenesis is a prepared room genesis awaiting founder signatures.
class StawiGenesis extends $pb.GeneratedMessage {
  factory StawiGenesis({
    $core.String? genesisId,
    $core.List<$core.int>? genesisHash,
    $core.List<$core.int>? constitutionHash,
    $1.Timestamp? expiresAt,
    $core.Iterable<$core.String>? founderProfileIds,
  }) {
    final result = create();
    if (genesisId != null) result.genesisId = genesisId;
    if (genesisHash != null) result.genesisHash = genesisHash;
    if (constitutionHash != null) result.constitutionHash = constitutionHash;
    if (expiresAt != null) result.expiresAt = expiresAt;
    if (founderProfileIds != null)
      result.founderProfileIds.addAll(founderProfileIds);
    return result;
  }

  StawiGenesis._();

  factory StawiGenesis.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StawiGenesis.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StawiGenesis',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'genesisId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'genesisHash', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'constitutionHash', $pb.PbFieldType.OY)
    ..aOM<$1.Timestamp>(4, _omitFieldNames ? '' : 'expiresAt',
        subBuilder: $1.Timestamp.create)
    ..pPS(5, _omitFieldNames ? '' : 'founderProfileIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StawiGenesis clone() => StawiGenesis()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StawiGenesis copyWith(void Function(StawiGenesis) updates) =>
      super.copyWith((message) => updates(message as StawiGenesis))
          as StawiGenesis;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StawiGenesis create() => StawiGenesis._();
  @$core.override
  StawiGenesis createEmptyInstance() => create();
  static $pb.PbList<StawiGenesis> createRepeated() =>
      $pb.PbList<StawiGenesis>();
  @$core.pragma('dart2js:noInline')
  static StawiGenesis getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StawiGenesis>(create);
  static StawiGenesis? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get genesisId => $_getSZ(0);
  @$pb.TagNumber(1)
  set genesisId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGenesisId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGenesisId() => $_clearField(1);

  /// The digest each founder's device signs (account-wrapped by the app).
  @$pb.TagNumber(2)
  $core.List<$core.int> get genesisHash => $_getN(1);
  @$pb.TagNumber(2)
  set genesisHash($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGenesisHash() => $_has(1);
  @$pb.TagNumber(2)
  void clearGenesisHash() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get constitutionHash => $_getN(2);
  @$pb.TagNumber(3)
  set constitutionHash($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasConstitutionHash() => $_has(2);
  @$pb.TagNumber(3)
  void clearConstitutionHash() => $_clearField(3);

  @$pb.TagNumber(4)
  $1.Timestamp get expiresAt => $_getN(3);
  @$pb.TagNumber(4)
  set expiresAt($1.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasExpiresAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearExpiresAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.Timestamp ensureExpiresAt() => $_ensure(3);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get founderProfileIds => $_getList(4);
}

/// StawiGenesisSignatureContent is a founder's signature over a prepared
/// genesis. Chat checks the sender is one of the genesis founders and hands
/// the signature to settlement; at founding quorum settlement creates the
/// room on chain.
class StawiGenesisSignatureContent extends $pb.GeneratedMessage {
  factory StawiGenesisSignatureContent({
    $core.String? genesisId,
    $core.List<$core.int>? signature,
    $core.String? signerKeyId,
    $core.String? algorithm,
    $core.List<$core.int>? webauthnAuthenticatorData,
    $core.List<$core.int>? webauthnClientDataJson,
  }) {
    final result = create();
    if (genesisId != null) result.genesisId = genesisId;
    if (signature != null) result.signature = signature;
    if (signerKeyId != null) result.signerKeyId = signerKeyId;
    if (algorithm != null) result.algorithm = algorithm;
    if (webauthnAuthenticatorData != null)
      result.webauthnAuthenticatorData = webauthnAuthenticatorData;
    if (webauthnClientDataJson != null)
      result.webauthnClientDataJson = webauthnClientDataJson;
    return result;
  }

  StawiGenesisSignatureContent._();

  factory StawiGenesisSignatureContent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StawiGenesisSignatureContent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StawiGenesisSignatureContent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'genesisId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'signature', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'signerKeyId')
    ..aOS(4, _omitFieldNames ? '' : 'algorithm')
    ..a<$core.List<$core.int>>(5,
        _omitFieldNames ? '' : 'webauthnAuthenticatorData', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'webauthnClientDataJson', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StawiGenesisSignatureContent clone() =>
      StawiGenesisSignatureContent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StawiGenesisSignatureContent copyWith(
          void Function(StawiGenesisSignatureContent) updates) =>
      super.copyWith(
              (message) => updates(message as StawiGenesisSignatureContent))
          as StawiGenesisSignatureContent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StawiGenesisSignatureContent create() =>
      StawiGenesisSignatureContent._();
  @$core.override
  StawiGenesisSignatureContent createEmptyInstance() => create();
  static $pb.PbList<StawiGenesisSignatureContent> createRepeated() =>
      $pb.PbList<StawiGenesisSignatureContent>();
  @$core.pragma('dart2js:noInline')
  static StawiGenesisSignatureContent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StawiGenesisSignatureContent>(create);
  static StawiGenesisSignatureContent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get genesisId => $_getSZ(0);
  @$pb.TagNumber(1)
  set genesisId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGenesisId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGenesisId() => $_clearField(1);

  /// The device signature over the founder's signing digest: secp256k1
  /// (65 bytes) or P-256 (x ‖ y ‖ r ‖ s) for WebAuthn.
  @$pb.TagNumber(2)
  $core.List<$core.int> get signature => $_getN(1);
  @$pb.TagNumber(2)
  set signature($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSignature() => $_has(1);
  @$pb.TagNumber(2)
  void clearSignature() => $_clearField(2);

  /// The device key that produced the signature.
  @$pb.TagNumber(3)
  $core.String get signerKeyId => $_getSZ(2);
  @$pb.TagNumber(3)
  set signerKeyId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSignerKeyId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSignerKeyId() => $_clearField(3);

  /// "secp256k1" or "p256-webauthn".
  @$pb.TagNumber(4)
  $core.String get algorithm => $_getSZ(3);
  @$pb.TagNumber(4)
  set algorithm($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAlgorithm() => $_has(3);
  @$pb.TagNumber(4)
  void clearAlgorithm() => $_clearField(4);

  /// WebAuthn assertion material; empty for secp256k1.
  @$pb.TagNumber(5)
  $core.List<$core.int> get webauthnAuthenticatorData => $_getN(4);
  @$pb.TagNumber(5)
  set webauthnAuthenticatorData($core.List<$core.int> value) =>
      $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasWebauthnAuthenticatorData() => $_has(4);
  @$pb.TagNumber(5)
  void clearWebauthnAuthenticatorData() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.int> get webauthnClientDataJson => $_getN(5);
  @$pb.TagNumber(6)
  set webauthnClientDataJson($core.List<$core.int> value) =>
      $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasWebauthnClientDataJson() => $_has(5);
  @$pb.TagNumber(6)
  void clearWebauthnClientDataJson() => $_clearField(6);
}

/// StawiSignedCallContent carries a room governance call (invite, accept,
/// join, admit, leave, suspend, roles, propose, vote, delegate, freeze) that
/// the app prepared through settlement and signed with the device key. Chat
/// checks the sender's subscription is the call's signer and relays it; the
/// room changes only when the chain reports the call.
class StawiSignedCallContent extends $pb.GeneratedMessage {
  factory StawiSignedCallContent({
    $core.String? callId,
    $core.String? kind,
    $core.List<$core.int>? signature,
    $core.String? signerKeyId,
    $core.String? summary,
    $core.String? algorithm,
    $core.List<$core.int>? webauthnAuthenticatorData,
    $core.List<$core.int>? webauthnClientDataJson,
  }) {
    final result = create();
    if (callId != null) result.callId = callId;
    if (kind != null) result.kind = kind;
    if (signature != null) result.signature = signature;
    if (signerKeyId != null) result.signerKeyId = signerKeyId;
    if (summary != null) result.summary = summary;
    if (algorithm != null) result.algorithm = algorithm;
    if (webauthnAuthenticatorData != null)
      result.webauthnAuthenticatorData = webauthnAuthenticatorData;
    if (webauthnClientDataJson != null)
      result.webauthnClientDataJson = webauthnClientDataJson;
    return result;
  }

  StawiSignedCallContent._();

  factory StawiSignedCallContent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StawiSignedCallContent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StawiSignedCallContent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'callId')
    ..aOS(2, _omitFieldNames ? '' : 'kind')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'signature', $pb.PbFieldType.OY)
    ..aOS(4, _omitFieldNames ? '' : 'signerKeyId')
    ..aOS(5, _omitFieldNames ? '' : 'summary')
    ..aOS(6, _omitFieldNames ? '' : 'algorithm')
    ..a<$core.List<$core.int>>(7,
        _omitFieldNames ? '' : 'webauthnAuthenticatorData', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        8, _omitFieldNames ? '' : 'webauthnClientDataJson', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StawiSignedCallContent clone() =>
      StawiSignedCallContent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StawiSignedCallContent copyWith(
          void Function(StawiSignedCallContent) updates) =>
      super.copyWith((message) => updates(message as StawiSignedCallContent))
          as StawiSignedCallContent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StawiSignedCallContent create() => StawiSignedCallContent._();
  @$core.override
  StawiSignedCallContent createEmptyInstance() => create();
  static $pb.PbList<StawiSignedCallContent> createRepeated() =>
      $pb.PbList<StawiSignedCallContent>();
  @$core.pragma('dart2js:noInline')
  static StawiSignedCallContent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StawiSignedCallContent>(create);
  static StawiSignedCallContent? _defaultInstance;

  /// The call id settlement returned when the call was prepared.
  @$pb.TagNumber(1)
  $core.String get callId => $_getSZ(0);
  @$pb.TagNumber(1)
  set callId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCallId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCallId() => $_clearField(1);

  /// The call kind, as settlement names it (e.g. "INVITE", "CAST_VOTE").
  @$pb.TagNumber(2)
  $core.String get kind => $_getSZ(1);
  @$pb.TagNumber(2)
  set kind($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  /// The device signature over the call's digest: secp256k1 (65 bytes) or
  /// P-256 (x ‖ y ‖ r ‖ s) for WebAuthn.
  @$pb.TagNumber(3)
  $core.List<$core.int> get signature => $_getN(2);
  @$pb.TagNumber(3)
  set signature($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSignature() => $_has(2);
  @$pb.TagNumber(3)
  void clearSignature() => $_clearField(3);

  /// The device key that produced the signature.
  @$pb.TagNumber(4)
  $core.String get signerKeyId => $_getSZ(3);
  @$pb.TagNumber(4)
  set signerKeyId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSignerKeyId() => $_has(3);
  @$pb.TagNumber(4)
  void clearSignerKeyId() => $_clearField(4);

  /// Human-readable description of the act, for display.
  @$pb.TagNumber(5)
  $core.String get summary => $_getSZ(4);
  @$pb.TagNumber(5)
  set summary($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSummary() => $_has(4);
  @$pb.TagNumber(5)
  void clearSummary() => $_clearField(5);

  /// "secp256k1" or "p256-webauthn".
  @$pb.TagNumber(6)
  $core.String get algorithm => $_getSZ(5);
  @$pb.TagNumber(6)
  set algorithm($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAlgorithm() => $_has(5);
  @$pb.TagNumber(6)
  void clearAlgorithm() => $_clearField(6);

  /// WebAuthn assertion material; empty for secp256k1.
  @$pb.TagNumber(7)
  $core.List<$core.int> get webauthnAuthenticatorData => $_getN(6);
  @$pb.TagNumber(7)
  set webauthnAuthenticatorData($core.List<$core.int> value) =>
      $_setBytes(6, value);
  @$pb.TagNumber(7)
  $core.bool hasWebauthnAuthenticatorData() => $_has(6);
  @$pb.TagNumber(7)
  void clearWebauthnAuthenticatorData() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.List<$core.int> get webauthnClientDataJson => $_getN(7);
  @$pb.TagNumber(8)
  set webauthnClientDataJson($core.List<$core.int> value) =>
      $_setBytes(7, value);
  @$pb.TagNumber(8)
  $core.bool hasWebauthnClientDataJson() => $_has(7);
  @$pb.TagNumber(8)
  void clearWebauthnClientDataJson() => $_clearField(8);
}

/// StawiCallOutcomeContent is server-generated: what became of a conversion,
/// a genesis signature or a signed call. Clients cannot send it.
class StawiCallOutcomeContent extends $pb.GeneratedMessage {
  factory StawiCallOutcomeContent({
    $core.String? callId,
    $core.String? genesisId,
    StawiCallOutcomeState? state,
    $core.String? reason,
    $core.String? sourceEventId,
    $core.String? kind,
    $fixnum.Int64? chainId,
    $core.List<$core.int>? txHash,
    $fixnum.Int64? blockNumber,
    $fixnum.Int64? logIndex,
  }) {
    final result = create();
    if (callId != null) result.callId = callId;
    if (genesisId != null) result.genesisId = genesisId;
    if (state != null) result.state = state;
    if (reason != null) result.reason = reason;
    if (sourceEventId != null) result.sourceEventId = sourceEventId;
    if (kind != null) result.kind = kind;
    if (chainId != null) result.chainId = chainId;
    if (txHash != null) result.txHash = txHash;
    if (blockNumber != null) result.blockNumber = blockNumber;
    if (logIndex != null) result.logIndex = logIndex;
    return result;
  }

  StawiCallOutcomeContent._();

  factory StawiCallOutcomeContent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StawiCallOutcomeContent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StawiCallOutcomeContent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'callId')
    ..aOS(2, _omitFieldNames ? '' : 'genesisId')
    ..e<StawiCallOutcomeState>(
        3, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker:
            StawiCallOutcomeState.STAWI_CALL_OUTCOME_STATE_UNSPECIFIED,
        valueOf: StawiCallOutcomeState.valueOf,
        enumValues: StawiCallOutcomeState.values)
    ..aOS(4, _omitFieldNames ? '' : 'reason')
    ..aOS(5, _omitFieldNames ? '' : 'sourceEventId')
    ..aOS(6, _omitFieldNames ? '' : 'kind')
    ..a<$fixnum.Int64>(7, _omitFieldNames ? '' : 'chainId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(
        8, _omitFieldNames ? '' : 'txHash', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        9, _omitFieldNames ? '' : 'blockNumber', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        10, _omitFieldNames ? '' : 'logIndex', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StawiCallOutcomeContent clone() =>
      StawiCallOutcomeContent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StawiCallOutcomeContent copyWith(
          void Function(StawiCallOutcomeContent) updates) =>
      super.copyWith((message) => updates(message as StawiCallOutcomeContent))
          as StawiCallOutcomeContent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StawiCallOutcomeContent create() => StawiCallOutcomeContent._();
  @$core.override
  StawiCallOutcomeContent createEmptyInstance() => create();
  static $pb.PbList<StawiCallOutcomeContent> createRepeated() =>
      $pb.PbList<StawiCallOutcomeContent>();
  @$core.pragma('dart2js:noInline')
  static StawiCallOutcomeContent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StawiCallOutcomeContent>(create);
  static StawiCallOutcomeContent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get callId => $_getSZ(0);
  @$pb.TagNumber(1)
  set callId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCallId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCallId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get genesisId => $_getSZ(1);
  @$pb.TagNumber(2)
  set genesisId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGenesisId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGenesisId() => $_clearField(2);

  @$pb.TagNumber(3)
  StawiCallOutcomeState get state => $_getN(2);
  @$pb.TagNumber(3)
  set state(StawiCallOutcomeState value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasState() => $_has(2);
  @$pb.TagNumber(3)
  void clearState() => $_clearField(3);

  /// Why a FAILED outcome failed.
  @$pb.TagNumber(4)
  $core.String get reason => $_getSZ(3);
  @$pb.TagNumber(4)
  set reason($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReason() => $_has(3);
  @$pb.TagNumber(4)
  void clearReason() => $_clearField(4);

  /// The chat event that carried the act, when the act came through chat.
  @$pb.TagNumber(5)
  $core.String get sourceEventId => $_getSZ(4);
  @$pb.TagNumber(5)
  set sourceEventId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSourceEventId() => $_has(4);
  @$pb.TagNumber(5)
  void clearSourceEventId() => $_clearField(5);

  /// The call kind, or the chain event an OBSERVED outcome reports.
  @$pb.TagNumber(6)
  $core.String get kind => $_getSZ(5);
  @$pb.TagNumber(6)
  set kind($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasKind() => $_has(5);
  @$pb.TagNumber(6)
  void clearKind() => $_clearField(6);

  /// Where an OBSERVED outcome was seen on chain.
  @$pb.TagNumber(7)
  $fixnum.Int64 get chainId => $_getI64(6);
  @$pb.TagNumber(7)
  set chainId($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasChainId() => $_has(6);
  @$pb.TagNumber(7)
  void clearChainId() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.List<$core.int> get txHash => $_getN(7);
  @$pb.TagNumber(8)
  set txHash($core.List<$core.int> value) => $_setBytes(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTxHash() => $_has(7);
  @$pb.TagNumber(8)
  void clearTxHash() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get blockNumber => $_getI64(8);
  @$pb.TagNumber(9)
  set blockNumber($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasBlockNumber() => $_has(8);
  @$pb.TagNumber(9)
  void clearBlockNumber() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get logIndex => $_getI64(9);
  @$pb.TagNumber(10)
  set logIndex($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasLogIndex() => $_has(9);
  @$pb.TagNumber(10)
  void clearLogIndex() => $_clearField(10);
}

enum Payload_Data {
  default_7,
  roomChange,
  moderation,
  text,
  attachment,
  reaction,
  encrypted,
  call,
  motion,
  vote,
  motionTally,
  voteTally,
  formRequest,
  formSubmissionResult,
  financeCard,
  stawiRoomConversion,
  stawiGenesisSignature,
  stawiSignedCall,
  stawiCallOutcome,
  notSet
}

class Payload extends $pb.GeneratedMessage {
  factory Payload({
    PayloadType? type,
    $0.Struct? default_7,
    RoomChangeContent? roomChange,
    ModerationContent? moderation,
    TextContent? text,
    AttachmentContent? attachment,
    ReactionContent? reaction,
    EncryptedContent? encrypted,
    CallContent? call,
    MotionContent? motion,
    VoteCast? vote,
    MotionTally? motionTally,
    VoteTally? voteTally,
    FormRequestContent? formRequest,
    FormSubmissionResultContent? formSubmissionResult,
    FinanceCardContent? financeCard,
    StawiRoomConversionContent? stawiRoomConversion,
    StawiGenesisSignatureContent? stawiGenesisSignature,
    StawiSignedCallContent? stawiSignedCall,
    StawiCallOutcomeContent? stawiCallOutcome,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (default_7 != null) result.default_7 = default_7;
    if (roomChange != null) result.roomChange = roomChange;
    if (moderation != null) result.moderation = moderation;
    if (text != null) result.text = text;
    if (attachment != null) result.attachment = attachment;
    if (reaction != null) result.reaction = reaction;
    if (encrypted != null) result.encrypted = encrypted;
    if (call != null) result.call = call;
    if (motion != null) result.motion = motion;
    if (vote != null) result.vote = vote;
    if (motionTally != null) result.motionTally = motionTally;
    if (voteTally != null) result.voteTally = voteTally;
    if (formRequest != null) result.formRequest = formRequest;
    if (formSubmissionResult != null)
      result.formSubmissionResult = formSubmissionResult;
    if (financeCard != null) result.financeCard = financeCard;
    if (stawiRoomConversion != null)
      result.stawiRoomConversion = stawiRoomConversion;
    if (stawiGenesisSignature != null)
      result.stawiGenesisSignature = stawiGenesisSignature;
    if (stawiSignedCall != null) result.stawiSignedCall = stawiSignedCall;
    if (stawiCallOutcome != null) result.stawiCallOutcome = stawiCallOutcome;
    return result;
  }

  Payload._();

  factory Payload.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Payload.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Payload_Data> _Payload_DataByTag = {
    7: Payload_Data.default_7,
    8: Payload_Data.roomChange,
    10: Payload_Data.moderation,
    15: Payload_Data.text,
    16: Payload_Data.attachment,
    17: Payload_Data.reaction,
    18: Payload_Data.encrypted,
    19: Payload_Data.call,
    25: Payload_Data.motion,
    26: Payload_Data.vote,
    28: Payload_Data.motionTally,
    29: Payload_Data.voteTally,
    30: Payload_Data.formRequest,
    31: Payload_Data.formSubmissionResult,
    40: Payload_Data.financeCard,
    41: Payload_Data.stawiRoomConversion,
    42: Payload_Data.stawiGenesisSignature,
    43: Payload_Data.stawiSignedCall,
    44: Payload_Data.stawiCallOutcome,
    0: Payload_Data.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Payload',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'),
      createEmptyInstance: create)
    ..oo(0, [
      7,
      8,
      10,
      15,
      16,
      17,
      18,
      19,
      25,
      26,
      28,
      29,
      30,
      31,
      40,
      41,
      42,
      43,
      44
    ])
    ..e<PayloadType>(1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker: PayloadType.PAYLOAD_TYPE_UNSPECIFIED,
        valueOf: PayloadType.valueOf,
        enumValues: PayloadType.values)
    ..aOM<$0.Struct>(7, _omitFieldNames ? '' : 'default',
        subBuilder: $0.Struct.create)
    ..aOM<RoomChangeContent>(8, _omitFieldNames ? '' : 'roomChange',
        subBuilder: RoomChangeContent.create)
    ..aOM<ModerationContent>(10, _omitFieldNames ? '' : 'moderation',
        subBuilder: ModerationContent.create)
    ..aOM<TextContent>(15, _omitFieldNames ? '' : 'text',
        subBuilder: TextContent.create)
    ..aOM<AttachmentContent>(16, _omitFieldNames ? '' : 'attachment',
        subBuilder: AttachmentContent.create)
    ..aOM<ReactionContent>(17, _omitFieldNames ? '' : 'reaction',
        subBuilder: ReactionContent.create)
    ..aOM<EncryptedContent>(18, _omitFieldNames ? '' : 'encrypted',
        subBuilder: EncryptedContent.create)
    ..aOM<CallContent>(19, _omitFieldNames ? '' : 'call',
        subBuilder: CallContent.create)
    ..aOM<MotionContent>(25, _omitFieldNames ? '' : 'motion',
        subBuilder: MotionContent.create)
    ..aOM<VoteCast>(26, _omitFieldNames ? '' : 'vote',
        subBuilder: VoteCast.create)
    ..aOM<MotionTally>(28, _omitFieldNames ? '' : 'motionTally',
        subBuilder: MotionTally.create)
    ..aOM<VoteTally>(29, _omitFieldNames ? '' : 'voteTally',
        subBuilder: VoteTally.create)
    ..aOM<FormRequestContent>(30, _omitFieldNames ? '' : 'formRequest',
        subBuilder: FormRequestContent.create)
    ..aOM<FormSubmissionResultContent>(
        31, _omitFieldNames ? '' : 'formSubmissionResult',
        subBuilder: FormSubmissionResultContent.create)
    ..aOM<FinanceCardContent>(40, _omitFieldNames ? '' : 'financeCard',
        subBuilder: FinanceCardContent.create)
    ..aOM<StawiRoomConversionContent>(
        41, _omitFieldNames ? '' : 'stawiRoomConversion',
        subBuilder: StawiRoomConversionContent.create)
    ..aOM<StawiGenesisSignatureContent>(
        42, _omitFieldNames ? '' : 'stawiGenesisSignature',
        subBuilder: StawiGenesisSignatureContent.create)
    ..aOM<StawiSignedCallContent>(43, _omitFieldNames ? '' : 'stawiSignedCall',
        subBuilder: StawiSignedCallContent.create)
    ..aOM<StawiCallOutcomeContent>(
        44, _omitFieldNames ? '' : 'stawiCallOutcome',
        subBuilder: StawiCallOutcomeContent.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Payload clone() => Payload()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Payload copyWith(void Function(Payload) updates) =>
      super.copyWith((message) => updates(message as Payload)) as Payload;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Payload create() => Payload._();
  @$core.override
  Payload createEmptyInstance() => create();
  static $pb.PbList<Payload> createRepeated() => $pb.PbList<Payload>();
  @$core.pragma('dart2js:noInline')
  static Payload getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Payload>(create);
  static Payload? _defaultInstance;

  Payload_Data whichData() => _Payload_DataByTag[$_whichOneof(0)]!;
  void clearData() => $_clearField($_whichOneof(0));

  /// The `type` MUST correspond to the populated payload.
  /// Servers MUST reject mismatches.
  @$pb.TagNumber(1)
  PayloadType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(PayloadType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  /// type = PAYLOAD_TYPE_UNSPECIFIED
  @$pb.TagNumber(7)
  $0.Struct get default_7 => $_getN(1);
  @$pb.TagNumber(7)
  set default_7($0.Struct value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasDefault_7() => $_has(1);
  @$pb.TagNumber(7)
  void clearDefault_7() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.Struct ensureDefault_7() => $_ensure(1);

  /// type = PAYLOAD_TYPE_ROOM_CHANGE
  @$pb.TagNumber(8)
  RoomChangeContent get roomChange => $_getN(2);
  @$pb.TagNumber(8)
  set roomChange(RoomChangeContent value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasRoomChange() => $_has(2);
  @$pb.TagNumber(8)
  void clearRoomChange() => $_clearField(8);
  @$pb.TagNumber(8)
  RoomChangeContent ensureRoomChange() => $_ensure(2);

  /// type = PAYLOAD_TYPE_MODERATION
  @$pb.TagNumber(10)
  ModerationContent get moderation => $_getN(3);
  @$pb.TagNumber(10)
  set moderation(ModerationContent value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasModeration() => $_has(3);
  @$pb.TagNumber(10)
  void clearModeration() => $_clearField(10);
  @$pb.TagNumber(10)
  ModerationContent ensureModeration() => $_ensure(3);

  /// type = PAYLOAD_TYPE_TEXT
  @$pb.TagNumber(15)
  TextContent get text => $_getN(4);
  @$pb.TagNumber(15)
  set text(TextContent value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasText() => $_has(4);
  @$pb.TagNumber(15)
  void clearText() => $_clearField(15);
  @$pb.TagNumber(15)
  TextContent ensureText() => $_ensure(4);

  /// type = PAYLOAD_TYPE_ATTACHMENT
  @$pb.TagNumber(16)
  AttachmentContent get attachment => $_getN(5);
  @$pb.TagNumber(16)
  set attachment(AttachmentContent value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasAttachment() => $_has(5);
  @$pb.TagNumber(16)
  void clearAttachment() => $_clearField(16);
  @$pb.TagNumber(16)
  AttachmentContent ensureAttachment() => $_ensure(5);

  /// type = PAYLOAD_TYPE_REACTION
  @$pb.TagNumber(17)
  ReactionContent get reaction => $_getN(6);
  @$pb.TagNumber(17)
  set reaction(ReactionContent value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasReaction() => $_has(6);
  @$pb.TagNumber(17)
  void clearReaction() => $_clearField(17);
  @$pb.TagNumber(17)
  ReactionContent ensureReaction() => $_ensure(6);

  /// type = PAYLOAD_TYPE_ENCRYPTED
  @$pb.TagNumber(18)
  EncryptedContent get encrypted => $_getN(7);
  @$pb.TagNumber(18)
  set encrypted(EncryptedContent value) => $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasEncrypted() => $_has(7);
  @$pb.TagNumber(18)
  void clearEncrypted() => $_clearField(18);
  @$pb.TagNumber(18)
  EncryptedContent ensureEncrypted() => $_ensure(7);

  /// type = PAYLOAD_TYPE_CALL
  @$pb.TagNumber(19)
  CallContent get call => $_getN(8);
  @$pb.TagNumber(19)
  set call(CallContent value) => $_setField(19, value);
  @$pb.TagNumber(19)
  $core.bool hasCall() => $_has(8);
  @$pb.TagNumber(19)
  void clearCall() => $_clearField(19);
  @$pb.TagNumber(19)
  CallContent ensureCall() => $_ensure(8);

  /// type = PAYLOAD_TYPE_MOTION
  @$pb.TagNumber(25)
  MotionContent get motion => $_getN(9);
  @$pb.TagNumber(25)
  set motion(MotionContent value) => $_setField(25, value);
  @$pb.TagNumber(25)
  $core.bool hasMotion() => $_has(9);
  @$pb.TagNumber(25)
  void clearMotion() => $_clearField(25);
  @$pb.TagNumber(25)
  MotionContent ensureMotion() => $_ensure(9);

  /// type = PAYLOAD_TYPE_VOTE
  @$pb.TagNumber(26)
  VoteCast get vote => $_getN(10);
  @$pb.TagNumber(26)
  set vote(VoteCast value) => $_setField(26, value);
  @$pb.TagNumber(26)
  $core.bool hasVote() => $_has(10);
  @$pb.TagNumber(26)
  void clearVote() => $_clearField(26);
  @$pb.TagNumber(26)
  VoteCast ensureVote() => $_ensure(10);

  /// type = PAYLOAD_TYPE_MOTION_TALLY
  @$pb.TagNumber(28)
  MotionTally get motionTally => $_getN(11);
  @$pb.TagNumber(28)
  set motionTally(MotionTally value) => $_setField(28, value);
  @$pb.TagNumber(28)
  $core.bool hasMotionTally() => $_has(11);
  @$pb.TagNumber(28)
  void clearMotionTally() => $_clearField(28);
  @$pb.TagNumber(28)
  MotionTally ensureMotionTally() => $_ensure(11);

  /// type = PAYLOAD_TYPE_VOTE_TALLY
  @$pb.TagNumber(29)
  VoteTally get voteTally => $_getN(12);
  @$pb.TagNumber(29)
  set voteTally(VoteTally value) => $_setField(29, value);
  @$pb.TagNumber(29)
  $core.bool hasVoteTally() => $_has(12);
  @$pb.TagNumber(29)
  void clearVoteTally() => $_clearField(29);
  @$pb.TagNumber(29)
  VoteTally ensureVoteTally() => $_ensure(12);

  /// type = PAYLOAD_TYPE_FORM_REQUEST
  @$pb.TagNumber(30)
  FormRequestContent get formRequest => $_getN(13);
  @$pb.TagNumber(30)
  set formRequest(FormRequestContent value) => $_setField(30, value);
  @$pb.TagNumber(30)
  $core.bool hasFormRequest() => $_has(13);
  @$pb.TagNumber(30)
  void clearFormRequest() => $_clearField(30);
  @$pb.TagNumber(30)
  FormRequestContent ensureFormRequest() => $_ensure(13);

  /// type = PAYLOAD_TYPE_FORM_SUBMISSION_RESULT
  @$pb.TagNumber(31)
  FormSubmissionResultContent get formSubmissionResult => $_getN(14);
  @$pb.TagNumber(31)
  set formSubmissionResult(FormSubmissionResultContent value) =>
      $_setField(31, value);
  @$pb.TagNumber(31)
  $core.bool hasFormSubmissionResult() => $_has(14);
  @$pb.TagNumber(31)
  void clearFormSubmissionResult() => $_clearField(31);
  @$pb.TagNumber(31)
  FormSubmissionResultContent ensureFormSubmissionResult() => $_ensure(14);

  /// type = PAYLOAD_TYPE_FINANCE_CARD
  @$pb.TagNumber(40)
  FinanceCardContent get financeCard => $_getN(15);
  @$pb.TagNumber(40)
  set financeCard(FinanceCardContent value) => $_setField(40, value);
  @$pb.TagNumber(40)
  $core.bool hasFinanceCard() => $_has(15);
  @$pb.TagNumber(40)
  void clearFinanceCard() => $_clearField(40);
  @$pb.TagNumber(40)
  FinanceCardContent ensureFinanceCard() => $_ensure(15);

  /// type = PAYLOAD_TYPE_STAWI_ROOM_CONVERSION
  @$pb.TagNumber(41)
  StawiRoomConversionContent get stawiRoomConversion => $_getN(16);
  @$pb.TagNumber(41)
  set stawiRoomConversion(StawiRoomConversionContent value) =>
      $_setField(41, value);
  @$pb.TagNumber(41)
  $core.bool hasStawiRoomConversion() => $_has(16);
  @$pb.TagNumber(41)
  void clearStawiRoomConversion() => $_clearField(41);
  @$pb.TagNumber(41)
  StawiRoomConversionContent ensureStawiRoomConversion() => $_ensure(16);

  /// type = PAYLOAD_TYPE_STAWI_GENESIS_SIGNATURE
  @$pb.TagNumber(42)
  StawiGenesisSignatureContent get stawiGenesisSignature => $_getN(17);
  @$pb.TagNumber(42)
  set stawiGenesisSignature(StawiGenesisSignatureContent value) =>
      $_setField(42, value);
  @$pb.TagNumber(42)
  $core.bool hasStawiGenesisSignature() => $_has(17);
  @$pb.TagNumber(42)
  void clearStawiGenesisSignature() => $_clearField(42);
  @$pb.TagNumber(42)
  StawiGenesisSignatureContent ensureStawiGenesisSignature() => $_ensure(17);

  /// type = PAYLOAD_TYPE_STAWI_SIGNED_CALL
  @$pb.TagNumber(43)
  StawiSignedCallContent get stawiSignedCall => $_getN(18);
  @$pb.TagNumber(43)
  set stawiSignedCall(StawiSignedCallContent value) => $_setField(43, value);
  @$pb.TagNumber(43)
  $core.bool hasStawiSignedCall() => $_has(18);
  @$pb.TagNumber(43)
  void clearStawiSignedCall() => $_clearField(43);
  @$pb.TagNumber(43)
  StawiSignedCallContent ensureStawiSignedCall() => $_ensure(18);

  /// type = PAYLOAD_TYPE_STAWI_CALL_OUTCOME
  @$pb.TagNumber(44)
  StawiCallOutcomeContent get stawiCallOutcome => $_getN(19);
  @$pb.TagNumber(44)
  set stawiCallOutcome(StawiCallOutcomeContent value) => $_setField(44, value);
  @$pb.TagNumber(44)
  $core.bool hasStawiCallOutcome() => $_has(19);
  @$pb.TagNumber(44)
  void clearStawiCallOutcome() => $_clearField(44);
  @$pb.TagNumber(44)
  StawiCallOutcomeContent ensureStawiCallOutcome() => $_ensure(19);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
