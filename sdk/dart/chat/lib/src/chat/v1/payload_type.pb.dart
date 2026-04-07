//
//  Generated code. Do not modify.
//  source: chat/v1/payload_type.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../google/protobuf/struct.pb.dart' as $4;
import '../../google/protobuf/timestamp.pb.dart' as $2;
import 'payload_type.pbenum.dart';

export 'payload_type.pbenum.dart';

class RoomChangeContent extends $pb.GeneratedMessage {
  factory RoomChangeContent({
    RoomChangeAction? action,
    $core.String? actorSubscriptionId,
    $core.Iterable<$core.String>? targetSubscriptionIds,
    $core.String? body,
    $4.Struct? details,
  }) {
    final $result = create();
    if (action != null) {
      $result.action = action;
    }
    if (actorSubscriptionId != null) {
      $result.actorSubscriptionId = actorSubscriptionId;
    }
    if (targetSubscriptionIds != null) {
      $result.targetSubscriptionIds.addAll(targetSubscriptionIds);
    }
    if (body != null) {
      $result.body = body;
    }
    if (details != null) {
      $result.details = details;
    }
    return $result;
  }
  RoomChangeContent._() : super();
  factory RoomChangeContent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RoomChangeContent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RoomChangeContent', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..e<RoomChangeAction>(1, _omitFieldNames ? '' : 'action', $pb.PbFieldType.OE, defaultOrMaker: RoomChangeAction.ROOM_CHANGE_ACTION_UNSPECIFIED, valueOf: RoomChangeAction.valueOf, enumValues: RoomChangeAction.values)
    ..aOS(2, _omitFieldNames ? '' : 'actorSubscriptionId')
    ..pPS(3, _omitFieldNames ? '' : 'targetSubscriptionIds')
    ..aOS(4, _omitFieldNames ? '' : 'body')
    ..aOM<$4.Struct>(5, _omitFieldNames ? '' : 'details', subBuilder: $4.Struct.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RoomChangeContent clone() => RoomChangeContent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RoomChangeContent copyWith(void Function(RoomChangeContent) updates) => super.copyWith((message) => updates(message as RoomChangeContent)) as RoomChangeContent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RoomChangeContent create() => RoomChangeContent._();
  RoomChangeContent createEmptyInstance() => create();
  static $pb.PbList<RoomChangeContent> createRepeated() => $pb.PbList<RoomChangeContent>();
  @$core.pragma('dart2js:noInline')
  static RoomChangeContent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RoomChangeContent>(create);
  static RoomChangeContent? _defaultInstance;

  @$pb.TagNumber(1)
  RoomChangeAction get action => $_getN(0);
  @$pb.TagNumber(1)
  set action(RoomChangeAction v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get actorSubscriptionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set actorSubscriptionId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasActorSubscriptionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearActorSubscriptionId() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.String> get targetSubscriptionIds => $_getList(2);

  /// Human-readable summary (server-generated, for display)
  @$pb.TagNumber(4)
  $core.String get body => $_getSZ(3);
  @$pb.TagNumber(4)
  set body($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasBody() => $_has(3);
  @$pb.TagNumber(4)
  void clearBody() => clearField(4);

  /// Optional structured detail (depends on action)
  @$pb.TagNumber(5)
  $4.Struct get details => $_getN(4);
  @$pb.TagNumber(5)
  set details($4.Struct v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasDetails() => $_has(4);
  @$pb.TagNumber(5)
  void clearDetails() => clearField(5);
  @$pb.TagNumber(5)
  $4.Struct ensureDetails() => $_ensure(4);
}

class ModerationContent extends $pb.GeneratedMessage {
  factory ModerationContent({
    $core.String? body,
    $core.String? actorSubscriptionId,
    $core.Iterable<$core.String>? targetSubscriptionIds,
    $core.String? language,
    $4.Struct? metadata,
  }) {
    final $result = create();
    if (body != null) {
      $result.body = body;
    }
    if (actorSubscriptionId != null) {
      $result.actorSubscriptionId = actorSubscriptionId;
    }
    if (targetSubscriptionIds != null) {
      $result.targetSubscriptionIds.addAll(targetSubscriptionIds);
    }
    if (language != null) {
      $result.language = language;
    }
    if (metadata != null) {
      $result.metadata = metadata;
    }
    return $result;
  }
  ModerationContent._() : super();
  factory ModerationContent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ModerationContent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ModerationContent', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'body')
    ..aOS(2, _omitFieldNames ? '' : 'actorSubscriptionId')
    ..pPS(3, _omitFieldNames ? '' : 'targetSubscriptionIds')
    ..aOS(4, _omitFieldNames ? '' : 'language')
    ..aOM<$4.Struct>(8, _omitFieldNames ? '' : 'metadata', subBuilder: $4.Struct.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ModerationContent clone() => ModerationContent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ModerationContent copyWith(void Function(ModerationContent) updates) => super.copyWith((message) => updates(message as ModerationContent)) as ModerationContent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModerationContent create() => ModerationContent._();
  ModerationContent createEmptyInstance() => create();
  static $pb.PbList<ModerationContent> createRepeated() => $pb.PbList<ModerationContent>();
  @$core.pragma('dart2js:noInline')
  static ModerationContent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ModerationContent>(create);
  static ModerationContent? _defaultInstance;

  /// Human-readable message body describing the action.
  /// Intended for display to end users.
  @$pb.TagNumber(1)
  $core.String get body => $_getSZ(0);
  @$pb.TagNumber(1)
  set body($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBody() => $_has(0);
  @$pb.TagNumber(1)
  void clearBody() => clearField(1);

  /// Subscription ID of the actor who initiated the action.
  @$pb.TagNumber(2)
  $core.String get actorSubscriptionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set actorSubscriptionId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasActorSubscriptionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearActorSubscriptionId() => clearField(2);

  /// Subscription IDs of entities targeted by the action.
  /// Must not contain duplicates and must not include the actor.
  @$pb.TagNumber(3)
  $core.List<$core.String> get targetSubscriptionIds => $_getList(2);

  /// Optional language tag for the body, using BCP-47 (e.g. "en", "fr-CA").
  @$pb.TagNumber(4)
  $core.String get language => $_getSZ(3);
  @$pb.TagNumber(4)
  set language($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasLanguage() => $_has(3);
  @$pb.TagNumber(4)
  void clearLanguage() => clearField(4);

  /// Optional structured metadata associated with the action.
  /// Use only for non-indexed, auxiliary data.
  @$pb.TagNumber(8)
  $4.Struct get metadata => $_getN(4);
  @$pb.TagNumber(8)
  set metadata($4.Struct v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasMetadata() => $_has(4);
  @$pb.TagNumber(8)
  void clearMetadata() => clearField(8);
  @$pb.TagNumber(8)
  $4.Struct ensureMetadata() => $_ensure(4);
}

class TextContent extends $pb.GeneratedMessage {
  factory TextContent({
    $core.String? body,
    $core.String? format,
    $core.Iterable<TextAnnotation>? annotations,
    $core.String? lang,
  }) {
    final $result = create();
    if (body != null) {
      $result.body = body;
    }
    if (format != null) {
      $result.format = format;
    }
    if (annotations != null) {
      $result.annotations.addAll(annotations);
    }
    if (lang != null) {
      $result.lang = lang;
    }
    return $result;
  }
  TextContent._() : super();
  factory TextContent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TextContent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TextContent', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'body')
    ..aOS(2, _omitFieldNames ? '' : 'format')
    ..pc<TextAnnotation>(3, _omitFieldNames ? '' : 'annotations', $pb.PbFieldType.PM, subBuilder: TextAnnotation.create)
    ..aOS(4, _omitFieldNames ? '' : 'lang')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TextContent clone() => TextContent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TextContent copyWith(void Function(TextContent) updates) => super.copyWith((message) => updates(message as TextContent)) as TextContent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TextContent create() => TextContent._();
  TextContent createEmptyInstance() => create();
  static $pb.PbList<TextContent> createRepeated() => $pb.PbList<TextContent>();
  @$core.pragma('dart2js:noInline')
  static TextContent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TextContent>(create);
  static TextContent? _defaultInstance;

  /// Required human-readable message body
  @$pb.TagNumber(1)
  $core.String get body => $_getSZ(0);
  @$pb.TagNumber(1)
  set body($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBody() => $_has(0);
  @$pb.TagNumber(1)
  void clearBody() => clearField(1);

  /// Content format identifier (NOT MIME type)
  /// Examples: "plain", "markdown", "html-lite"
  @$pb.TagNumber(2)
  $core.String get format => $_getSZ(1);
  @$pb.TagNumber(2)
  set format($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFormat() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormat() => clearField(2);

  /// Structured annotations for clients (mentions, links, emojis)
  @$pb.TagNumber(3)
  $core.List<TextAnnotation> get annotations => $_getList(2);

  /// Optional language hint (BCP-47), e.g. "en", "fr-CA"
  @$pb.TagNumber(4)
  $core.String get lang => $_getSZ(3);
  @$pb.TagNumber(4)
  set lang($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasLang() => $_has(3);
  @$pb.TagNumber(4)
  void clearLang() => clearField(4);
}

class TextAnnotation extends $pb.GeneratedMessage {
  factory TextAnnotation({
    TextAnnotation_Type? type,
    $core.int? offset,
    $core.int? length,
    $core.String? value,
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    if (offset != null) {
      $result.offset = offset;
    }
    if (length != null) {
      $result.length = length;
    }
    if (value != null) {
      $result.value = value;
    }
    return $result;
  }
  TextAnnotation._() : super();
  factory TextAnnotation.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TextAnnotation.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TextAnnotation', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..e<TextAnnotation_Type>(1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: TextAnnotation_Type.TYPE_UNSPECIFIED, valueOf: TextAnnotation_Type.valueOf, enumValues: TextAnnotation_Type.values)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'offset', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'length', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TextAnnotation clone() => TextAnnotation()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TextAnnotation copyWith(void Function(TextAnnotation) updates) => super.copyWith((message) => updates(message as TextAnnotation)) as TextAnnotation;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TextAnnotation create() => TextAnnotation._();
  TextAnnotation createEmptyInstance() => create();
  static $pb.PbList<TextAnnotation> createRepeated() => $pb.PbList<TextAnnotation>();
  @$core.pragma('dart2js:noInline')
  static TextAnnotation getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TextAnnotation>(create);
  static TextAnnotation? _defaultInstance;

  @$pb.TagNumber(1)
  TextAnnotation_Type get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(TextAnnotation_Type v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  /// UTF-16 offset & length for cross-platform compatibility
  @$pb.TagNumber(2)
  $core.int get offset => $_getIZ(1);
  @$pb.TagNumber(2)
  set offset($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasOffset() => $_has(1);
  @$pb.TagNumber(2)
  void clearOffset() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get length => $_getIZ(2);
  @$pb.TagNumber(3)
  set length($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLength() => $_has(2);
  @$pb.TagNumber(3)
  void clearLength() => clearField(3);

  /// Target identifier (e.g., profile_id, room_id, URL)
  @$pb.TagNumber(4)
  $core.String get value => $_getSZ(3);
  @$pb.TagNumber(4)
  set value($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasValue() => $_has(3);
  @$pb.TagNumber(4)
  void clearValue() => clearField(4);
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
    final $result = create();
    if (attachmentId != null) {
      $result.attachmentId = attachmentId;
    }
    if (filename != null) {
      $result.filename = filename;
    }
    if (mimeType != null) {
      $result.mimeType = mimeType;
    }
    if (sizeBytes != null) {
      $result.sizeBytes = sizeBytes;
    }
    if (uri != null) {
      $result.uri = uri;
    }
    if (previews != null) {
      $result.previews.addAll(previews);
    }
    if (caption != null) {
      $result.caption = caption;
    }
    if (encrypted != null) {
      $result.encrypted = encrypted;
    }
    if (checksum != null) {
      $result.checksum = checksum;
    }
    return $result;
  }
  AttachmentContent._() : super();
  factory AttachmentContent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AttachmentContent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AttachmentContent', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'attachmentId')
    ..aOS(2, _omitFieldNames ? '' : 'filename')
    ..aOS(3, _omitFieldNames ? '' : 'mimeType')
    ..aInt64(4, _omitFieldNames ? '' : 'sizeBytes')
    ..aOS(5, _omitFieldNames ? '' : 'uri')
    ..pc<AttachmentPreview>(6, _omitFieldNames ? '' : 'previews', $pb.PbFieldType.PM, subBuilder: AttachmentPreview.create)
    ..aOM<TextContent>(7, _omitFieldNames ? '' : 'caption', subBuilder: TextContent.create)
    ..aOB(8, _omitFieldNames ? '' : 'encrypted')
    ..aOS(9, _omitFieldNames ? '' : 'checksum')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AttachmentContent clone() => AttachmentContent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AttachmentContent copyWith(void Function(AttachmentContent) updates) => super.copyWith((message) => updates(message as AttachmentContent)) as AttachmentContent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AttachmentContent create() => AttachmentContent._();
  AttachmentContent createEmptyInstance() => create();
  static $pb.PbList<AttachmentContent> createRepeated() => $pb.PbList<AttachmentContent>();
  @$core.pragma('dart2js:noInline')
  static AttachmentContent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AttachmentContent>(create);
  static AttachmentContent? _defaultInstance;

  /// Logical identifier of the attachment
  @$pb.TagNumber(1)
  $core.String get attachmentId => $_getSZ(0);
  @$pb.TagNumber(1)
  set attachmentId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAttachmentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAttachmentId() => clearField(1);

  /// Original filename (optional, user-facing)
  @$pb.TagNumber(2)
  $core.String get filename => $_getSZ(1);
  @$pb.TagNumber(2)
  set filename($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFilename() => $_has(1);
  @$pb.TagNumber(2)
  void clearFilename() => clearField(2);

  /// MIME type (e.g. image/png, application/pdf)
  @$pb.TagNumber(3)
  $core.String get mimeType => $_getSZ(2);
  @$pb.TagNumber(3)
  set mimeType($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMimeType() => $_has(2);
  @$pb.TagNumber(3)
  void clearMimeType() => clearField(3);

  /// Size in bytes (for quota enforcement & UX)
  @$pb.TagNumber(4)
  $fixnum.Int64 get sizeBytes => $_getI64(3);
  @$pb.TagNumber(4)
  set sizeBytes($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSizeBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearSizeBytes() => clearField(4);

  /// Content location (signed URL or opaque locator)
  @$pb.TagNumber(5)
  $core.String get uri => $_getSZ(4);
  @$pb.TagNumber(5)
  set uri($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasUri() => $_has(4);
  @$pb.TagNumber(5)
  void clearUri() => clearField(5);

  /// Optional previews / thumbnails
  @$pb.TagNumber(6)
  $core.List<AttachmentPreview> get previews => $_getList(5);

  /// Optional caption text
  @$pb.TagNumber(7)
  TextContent get caption => $_getN(6);
  @$pb.TagNumber(7)
  set caption(TextContent v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasCaption() => $_has(6);
  @$pb.TagNumber(7)
  void clearCaption() => clearField(7);
  @$pb.TagNumber(7)
  TextContent ensureCaption() => $_ensure(6);

  /// Indicates whether attachment is end-to-end encrypted
  @$pb.TagNumber(8)
  $core.bool get encrypted => $_getBF(7);
  @$pb.TagNumber(8)
  set encrypted($core.bool v) { $_setBool(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasEncrypted() => $_has(7);
  @$pb.TagNumber(8)
  void clearEncrypted() => clearField(8);

  /// Optional content hash (e.g. sha256:base64)
  @$pb.TagNumber(9)
  $core.String get checksum => $_getSZ(8);
  @$pb.TagNumber(9)
  set checksum($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasChecksum() => $_has(8);
  @$pb.TagNumber(9)
  void clearChecksum() => clearField(9);
}

class AttachmentPreview extends $pb.GeneratedMessage {
  factory AttachmentPreview({
    $core.String? mimeType,
    $core.int? width,
    $core.int? height,
    $core.String? uri,
    $fixnum.Int64? sizeBytes,
  }) {
    final $result = create();
    if (mimeType != null) {
      $result.mimeType = mimeType;
    }
    if (width != null) {
      $result.width = width;
    }
    if (height != null) {
      $result.height = height;
    }
    if (uri != null) {
      $result.uri = uri;
    }
    if (sizeBytes != null) {
      $result.sizeBytes = sizeBytes;
    }
    return $result;
  }
  AttachmentPreview._() : super();
  factory AttachmentPreview.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AttachmentPreview.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AttachmentPreview', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'mimeType')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'width', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'height', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'uri')
    ..aInt64(5, _omitFieldNames ? '' : 'sizeBytes')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AttachmentPreview clone() => AttachmentPreview()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AttachmentPreview copyWith(void Function(AttachmentPreview) updates) => super.copyWith((message) => updates(message as AttachmentPreview)) as AttachmentPreview;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AttachmentPreview create() => AttachmentPreview._();
  AttachmentPreview createEmptyInstance() => create();
  static $pb.PbList<AttachmentPreview> createRepeated() => $pb.PbList<AttachmentPreview>();
  @$core.pragma('dart2js:noInline')
  static AttachmentPreview getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AttachmentPreview>(create);
  static AttachmentPreview? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get mimeType => $_getSZ(0);
  @$pb.TagNumber(1)
  set mimeType($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMimeType() => $_has(0);
  @$pb.TagNumber(1)
  void clearMimeType() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get width => $_getIZ(1);
  @$pb.TagNumber(2)
  set width($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasWidth() => $_has(1);
  @$pb.TagNumber(2)
  void clearWidth() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get height => $_getIZ(2);
  @$pb.TagNumber(3)
  set height($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasHeight() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeight() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get uri => $_getSZ(3);
  @$pb.TagNumber(4)
  set uri($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasUri() => $_has(3);
  @$pb.TagNumber(4)
  void clearUri() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get sizeBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set sizeBytes($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasSizeBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearSizeBytes() => clearField(5);
}

class ReactionContent extends $pb.GeneratedMessage {
  factory ReactionContent({
    $core.String? targetEventId,
    $core.String? reaction,
    $core.bool? add,
  }) {
    final $result = create();
    if (targetEventId != null) {
      $result.targetEventId = targetEventId;
    }
    if (reaction != null) {
      $result.reaction = reaction;
    }
    if (add != null) {
      $result.add = add;
    }
    return $result;
  }
  ReactionContent._() : super();
  factory ReactionContent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReactionContent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReactionContent', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'targetEventId')
    ..aOS(2, _omitFieldNames ? '' : 'reaction')
    ..aOB(3, _omitFieldNames ? '' : 'add')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReactionContent clone() => ReactionContent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReactionContent copyWith(void Function(ReactionContent) updates) => super.copyWith((message) => updates(message as ReactionContent)) as ReactionContent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReactionContent create() => ReactionContent._();
  ReactionContent createEmptyInstance() => create();
  static $pb.PbList<ReactionContent> createRepeated() => $pb.PbList<ReactionContent>();
  @$core.pragma('dart2js:noInline')
  static ReactionContent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReactionContent>(create);
  static ReactionContent? _defaultInstance;

  /// Target message being reacted to
  @$pb.TagNumber(1)
  $core.String get targetEventId => $_getSZ(0);
  @$pb.TagNumber(1)
  set targetEventId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTargetEventId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTargetEventId() => clearField(1);

  /// Reaction key (e.g. 👍, ❤️, :custom_emoji:)
  @$pb.TagNumber(2)
  $core.String get reaction => $_getSZ(1);
  @$pb.TagNumber(2)
  set reaction($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasReaction() => $_has(1);
  @$pb.TagNumber(2)
  void clearReaction() => clearField(2);

  /// add=true → ensure reaction exists
  /// add=false → ensure reaction does not exist
  @$pb.TagNumber(3)
  $core.bool get add => $_getBF(2);
  @$pb.TagNumber(3)
  set add($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasAdd() => $_has(2);
  @$pb.TagNumber(3)
  void clearAdd() => clearField(3);
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
    final $result = create();
    if (algorithm != null) {
      $result.algorithm = algorithm;
    }
    if (ciphertext != null) {
      $result.ciphertext = ciphertext;
    }
    if (nonce != null) {
      $result.nonce = nonce;
    }
    if (senderKeyId != null) {
      $result.senderKeyId = senderKeyId;
    }
    if (recipientKeyIds != null) {
      $result.recipientKeyIds.addAll(recipientKeyIds);
    }
    if (aad != null) {
      $result.aad = aad;
    }
    if (sessionId != null) {
      $result.sessionId = sessionId;
    }
    return $result;
  }
  EncryptedContent._() : super();
  factory EncryptedContent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EncryptedContent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EncryptedContent', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'algorithm')
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'ciphertext', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..aOS(4, _omitFieldNames ? '' : 'senderKeyId')
    ..pPS(5, _omitFieldNames ? '' : 'recipientKeyIds')
    ..a<$core.List<$core.int>>(6, _omitFieldNames ? '' : 'aad', $pb.PbFieldType.OY)
    ..aOS(7, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EncryptedContent clone() => EncryptedContent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EncryptedContent copyWith(void Function(EncryptedContent) updates) => super.copyWith((message) => updates(message as EncryptedContent)) as EncryptedContent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedContent create() => EncryptedContent._();
  EncryptedContent createEmptyInstance() => create();
  static $pb.PbList<EncryptedContent> createRepeated() => $pb.PbList<EncryptedContent>();
  @$core.pragma('dart2js:noInline')
  static EncryptedContent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EncryptedContent>(create);
  static EncryptedContent? _defaultInstance;

  /// Encryption scheme identifier
  /// Examples: "olm.v2", "megolm.v1", "x25519-aesgcm"
  @$pb.TagNumber(1)
  $core.String get algorithm => $_getSZ(0);
  @$pb.TagNumber(1)
  set algorithm($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAlgorithm() => $_has(0);
  @$pb.TagNumber(1)
  void clearAlgorithm() => clearField(1);

  /// Base64 or binary-safe encoded ciphertext
  @$pb.TagNumber(2)
  $core.List<$core.int> get ciphertext => $_getN(1);
  @$pb.TagNumber(2)
  set ciphertext($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCiphertext() => $_has(1);
  @$pb.TagNumber(2)
  void clearCiphertext() => clearField(2);

  /// Optional per-message nonce / IV
  @$pb.TagNumber(3)
  $core.List<$core.int> get nonce => $_getN(2);
  @$pb.TagNumber(3)
  set nonce($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasNonce() => $_has(2);
  @$pb.TagNumber(3)
  void clearNonce() => clearField(3);

  /// Optional sender key identifier
  @$pb.TagNumber(4)
  $core.String get senderKeyId => $_getSZ(3);
  @$pb.TagNumber(4)
  set senderKeyId($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSenderKeyId() => $_has(3);
  @$pb.TagNumber(4)
  void clearSenderKeyId() => clearField(4);

  /// Optional recipient key references (for fan-out)
  @$pb.TagNumber(5)
  $core.List<$core.String> get recipientKeyIds => $_getList(4);

  /// Additional authenticated data (AAD)
  @$pb.TagNumber(6)
  $core.List<$core.int> get aad => $_getN(5);
  @$pb.TagNumber(6)
  set aad($core.List<$core.int> v) { $_setBytes(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasAad() => $_has(5);
  @$pb.TagNumber(6)
  void clearAad() => clearField(6);

  /// Optional key agreement context identifier
  @$pb.TagNumber(7)
  $core.String get sessionId => $_getSZ(6);
  @$pb.TagNumber(7)
  set sessionId($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasSessionId() => $_has(6);
  @$pb.TagNumber(7)
  void clearSessionId() => clearField(7);
}

class CallContent extends $pb.GeneratedMessage {
  factory CallContent({
    $core.String? callId,
    CallContent_CallType? type,
    CallContent_CallAction? action,
    $core.String? sdp,
    $core.String? iceCandidate,
    $4.Struct? metadata,
  }) {
    final $result = create();
    if (callId != null) {
      $result.callId = callId;
    }
    if (type != null) {
      $result.type = type;
    }
    if (action != null) {
      $result.action = action;
    }
    if (sdp != null) {
      $result.sdp = sdp;
    }
    if (iceCandidate != null) {
      $result.iceCandidate = iceCandidate;
    }
    if (metadata != null) {
      $result.metadata = metadata;
    }
    return $result;
  }
  CallContent._() : super();
  factory CallContent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CallContent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CallContent', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'callId')
    ..e<CallContent_CallType>(2, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: CallContent_CallType.CALL_TYPE_UNSPECIFIED, valueOf: CallContent_CallType.valueOf, enumValues: CallContent_CallType.values)
    ..e<CallContent_CallAction>(3, _omitFieldNames ? '' : 'action', $pb.PbFieldType.OE, defaultOrMaker: CallContent_CallAction.CALL_ACTION_UNSPECIFIED, valueOf: CallContent_CallAction.valueOf, enumValues: CallContent_CallAction.values)
    ..aOS(4, _omitFieldNames ? '' : 'sdp')
    ..aOS(5, _omitFieldNames ? '' : 'iceCandidate')
    ..aOM<$4.Struct>(8, _omitFieldNames ? '' : 'metadata', subBuilder: $4.Struct.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CallContent clone() => CallContent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CallContent copyWith(void Function(CallContent) updates) => super.copyWith((message) => updates(message as CallContent)) as CallContent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CallContent create() => CallContent._();
  CallContent createEmptyInstance() => create();
  static $pb.PbList<CallContent> createRepeated() => $pb.PbList<CallContent>();
  @$core.pragma('dart2js:noInline')
  static CallContent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CallContent>(create);
  static CallContent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get callId => $_getSZ(0);
  @$pb.TagNumber(1)
  set callId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCallId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCallId() => clearField(1);

  @$pb.TagNumber(2)
  CallContent_CallType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(CallContent_CallType v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => clearField(2);

  /// OFFER, ANSWER → sdp required
  /// ICE_CANDIDATE → ice_candidate required
  /// END → no payload required
  @$pb.TagNumber(3)
  CallContent_CallAction get action => $_getN(2);
  @$pb.TagNumber(3)
  set action(CallContent_CallAction v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasAction() => $_has(2);
  @$pb.TagNumber(3)
  void clearAction() => clearField(3);

  /// WebRTC payload (SDP or ICE candidate)
  @$pb.TagNumber(4)
  $core.String get sdp => $_getSZ(3);
  @$pb.TagNumber(4)
  set sdp($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSdp() => $_has(3);
  @$pb.TagNumber(4)
  void clearSdp() => clearField(4);

  /// Optional ICE candidate (when action = ICE_CANDIDATE)
  @$pb.TagNumber(5)
  $core.String get iceCandidate => $_getSZ(4);
  @$pb.TagNumber(5)
  set iceCandidate($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasIceCandidate() => $_has(4);
  @$pb.TagNumber(5)
  void clearIceCandidate() => clearField(5);

  /// Optional metadata (bitrate, codecs, device hints)
  @$pb.TagNumber(8)
  $4.Struct get metadata => $_getN(5);
  @$pb.TagNumber(8)
  set metadata($4.Struct v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasMetadata() => $_has(5);
  @$pb.TagNumber(8)
  void clearMetadata() => clearField(8);
  @$pb.TagNumber(8)
  $4.Struct ensureMetadata() => $_ensure(5);
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
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (title != null) {
      $result.title = title;
    }
    if (description != null) {
      $result.description = description;
    }
    if (eligibleVotes != null) {
      $result.eligibleVotes = eligibleVotes;
    }
    if (passingRule != null) {
      $result.passingRule = passingRule;
    }
    if (choices != null) {
      $result.choices.addAll(choices);
    }
    if (closesAt != null) {
      $result.closesAt = closesAt;
    }
    if (eligibleRoles != null) {
      $result.eligibleRoles.addAll(eligibleRoles);
    }
    return $result;
  }
  MotionContent._() : super();
  factory MotionContent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MotionContent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'MotionContent', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'eligibleVotes', $pb.PbFieldType.OU3)
    ..aOM<PassingRule>(7, _omitFieldNames ? '' : 'passingRule', subBuilder: PassingRule.create)
    ..pc<VoteChoice>(8, _omitFieldNames ? '' : 'choices', $pb.PbFieldType.PM, subBuilder: VoteChoice.create)
    ..aInt64(12, _omitFieldNames ? '' : 'closesAt')
    ..pPS(13, _omitFieldNames ? '' : 'eligibleRoles')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MotionContent clone() => MotionContent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MotionContent copyWith(void Function(MotionContent) updates) => super.copyWith((message) => updates(message as MotionContent)) as MotionContent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MotionContent create() => MotionContent._();
  MotionContent createEmptyInstance() => create();
  static $pb.PbList<MotionContent> createRepeated() => $pb.PbList<MotionContent>();
  @$core.pragma('dart2js:noInline')
  static MotionContent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MotionContent>(create);
  static MotionContent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  /// Human-readable description
  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => clearField(3);

  /// Snapshot of eligible voters at creation time (optional, cached)
  @$pb.TagNumber(4)
  $core.int get eligibleVotes => $_getIZ(3);
  @$pb.TagNumber(4)
  set eligibleVotes($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasEligibleVotes() => $_has(3);
  @$pb.TagNumber(4)
  void clearEligibleVotes() => clearField(4);

  /// Number of votes required to pass
  /// Can represent absolute count or percentage thresholds
  /// Passing rule
  @$pb.TagNumber(7)
  PassingRule get passingRule => $_getN(4);
  @$pb.TagNumber(7)
  set passingRule(PassingRule v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasPassingRule() => $_has(4);
  @$pb.TagNumber(7)
  void clearPassingRule() => clearField(7);
  @$pb.TagNumber(7)
  PassingRule ensurePassingRule() => $_ensure(4);

  /// Available choices (YES / NO / ABSTAIN, etc)
  @$pb.TagNumber(8)
  $core.List<VoteChoice> get choices => $_getList(5);

  /// Optional deadline (unix seconds)
  @$pb.TagNumber(12)
  $fixnum.Int64 get closesAt => $_getI64(6);
  @$pb.TagNumber(12)
  set closesAt($fixnum.Int64 v) { $_setInt64(6, v); }
  @$pb.TagNumber(12)
  $core.bool hasClosesAt() => $_has(6);
  @$pb.TagNumber(12)
  void clearClosesAt() => clearField(12);

  /// Roles allowed to vote; eligible_votes is derived
  @$pb.TagNumber(13)
  $core.List<$core.String> get eligibleRoles => $_getList(7);
}

class VoteChoice extends $pb.GeneratedMessage {
  factory VoteChoice({
    $core.String? id,
    $core.String? name,
    $core.String? description,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (name != null) {
      $result.name = name;
    }
    if (description != null) {
      $result.description = description;
    }
    return $result;
  }
  VoteChoice._() : super();
  factory VoteChoice.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory VoteChoice.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'VoteChoice', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  VoteChoice clone() => VoteChoice()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  VoteChoice copyWith(void Function(VoteChoice) updates) => super.copyWith((message) => updates(message as VoteChoice)) as VoteChoice;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VoteChoice create() => VoteChoice._();
  VoteChoice createEmptyInstance() => create();
  static $pb.PbList<VoteChoice> createRepeated() => $pb.PbList<VoteChoice>();
  @$core.pragma('dart2js:noInline')
  static VoteChoice getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VoteChoice>(create);
  static VoteChoice? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => clearField(3);
}

enum PassingRule_Rule {
  absolute, 
  percentage, 
  notSet
}

class PassingRule extends $pb.GeneratedMessage {
  factory PassingRule({
    $core.int? absolute,
    $core.int? percentage,
    $core.String? passingChoiceId,
  }) {
    final $result = create();
    if (absolute != null) {
      $result.absolute = absolute;
    }
    if (percentage != null) {
      $result.percentage = percentage;
    }
    if (passingChoiceId != null) {
      $result.passingChoiceId = passingChoiceId;
    }
    return $result;
  }
  PassingRule._() : super();
  factory PassingRule.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PassingRule.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, PassingRule_Rule> _PassingRule_RuleByTag = {
    1 : PassingRule_Rule.absolute,
    2 : PassingRule_Rule.percentage,
    0 : PassingRule_Rule.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PassingRule', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..a<$core.int>(1, _omitFieldNames ? '' : 'absolute', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'percentage', $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'passingChoiceId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PassingRule clone() => PassingRule()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PassingRule copyWith(void Function(PassingRule) updates) => super.copyWith((message) => updates(message as PassingRule)) as PassingRule;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PassingRule create() => PassingRule._();
  PassingRule createEmptyInstance() => create();
  static $pb.PbList<PassingRule> createRepeated() => $pb.PbList<PassingRule>();
  @$core.pragma('dart2js:noInline')
  static PassingRule getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PassingRule>(create);
  static PassingRule? _defaultInstance;

  PassingRule_Rule whichRule() => _PassingRule_RuleByTag[$_whichOneof(0)]!;
  void clearRule() => clearField($_whichOneof(0));

  /// Absolute number of votes required
  @$pb.TagNumber(1)
  $core.int get absolute => $_getIZ(0);
  @$pb.TagNumber(1)
  set absolute($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAbsolute() => $_has(0);
  @$pb.TagNumber(1)
  void clearAbsolute() => clearField(1);

  /// Percentage required to pass (0–100)
  @$pb.TagNumber(2)
  $core.int get percentage => $_getIZ(1);
  @$pb.TagNumber(2)
  set percentage($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPercentage() => $_has(1);
  @$pb.TagNumber(2)
  void clearPercentage() => clearField(2);

  /// Which choice constitutes "passing" (usually YES)
  @$pb.TagNumber(3)
  $core.String get passingChoiceId => $_getSZ(2);
  @$pb.TagNumber(3)
  set passingChoiceId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPassingChoiceId() => $_has(2);
  @$pb.TagNumber(3)
  void clearPassingChoiceId() => clearField(3);
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
    final $result = create();
    if (motionId != null) {
      $result.motionId = motionId;
    }
    if (choiceId != null) {
      $result.choiceId = choiceId;
    }
    return $result;
  }
  VoteCast._() : super();
  factory VoteCast.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory VoteCast.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'VoteCast', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'motionId')
    ..aOS(2, _omitFieldNames ? '' : 'choiceId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  VoteCast clone() => VoteCast()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  VoteCast copyWith(void Function(VoteCast) updates) => super.copyWith((message) => updates(message as VoteCast)) as VoteCast;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VoteCast create() => VoteCast._();
  VoteCast createEmptyInstance() => create();
  static $pb.PbList<VoteCast> createRepeated() => $pb.PbList<VoteCast>();
  @$core.pragma('dart2js:noInline')
  static VoteCast getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VoteCast>(create);
  static VoteCast? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get motionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set motionId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMotionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMotionId() => clearField(1);

  /// Selected choice
  @$pb.TagNumber(2)
  $core.String get choiceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set choiceId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasChoiceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChoiceId() => clearField(2);
}

class VoteTally extends $pb.GeneratedMessage {
  factory VoteTally({
    $core.String? choiceId,
    $core.int? count,
  }) {
    final $result = create();
    if (choiceId != null) {
      $result.choiceId = choiceId;
    }
    if (count != null) {
      $result.count = count;
    }
    return $result;
  }
  VoteTally._() : super();
  factory VoteTally.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory VoteTally.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'VoteTally', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'choiceId')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'count', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  VoteTally clone() => VoteTally()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  VoteTally copyWith(void Function(VoteTally) updates) => super.copyWith((message) => updates(message as VoteTally)) as VoteTally;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VoteTally create() => VoteTally._();
  VoteTally createEmptyInstance() => create();
  static $pb.PbList<VoteTally> createRepeated() => $pb.PbList<VoteTally>();
  @$core.pragma('dart2js:noInline')
  static VoteTally getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VoteTally>(create);
  static VoteTally? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get choiceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set choiceId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasChoiceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChoiceId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get count => $_getIZ(1);
  @$pb.TagNumber(2)
  set count($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearCount() => clearField(2);
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
    final $result = create();
    if (motionId != null) {
      $result.motionId = motionId;
    }
    if (eligibleVotes != null) {
      $result.eligibleVotes = eligibleVotes;
    }
    if (tallies != null) {
      $result.tallies.addAll(tallies);
    }
    if (totalVotesCast != null) {
      $result.totalVotesCast = totalVotesCast;
    }
    if (deadVotes != null) {
      $result.deadVotes = deadVotes;
    }
    if (targetVotes != null) {
      $result.targetVotes = targetVotes;
    }
    if (passed != null) {
      $result.passed = passed;
    }
    if (closed != null) {
      $result.closed = closed;
    }
    return $result;
  }
  MotionTally._() : super();
  factory MotionTally.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MotionTally.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'MotionTally', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'motionId')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'eligibleVotes', $pb.PbFieldType.OU3)
    ..pc<VoteTally>(3, _omitFieldNames ? '' : 'tallies', $pb.PbFieldType.PM, subBuilder: VoteTally.create)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'totalVotesCast', $pb.PbFieldType.OU3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'deadVotes', $pb.PbFieldType.OU3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'targetVotes', $pb.PbFieldType.OU3)
    ..aOB(8, _omitFieldNames ? '' : 'passed')
    ..aOB(9, _omitFieldNames ? '' : 'closed')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MotionTally clone() => MotionTally()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MotionTally copyWith(void Function(MotionTally) updates) => super.copyWith((message) => updates(message as MotionTally)) as MotionTally;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MotionTally create() => MotionTally._();
  MotionTally createEmptyInstance() => create();
  static $pb.PbList<MotionTally> createRepeated() => $pb.PbList<MotionTally>();
  @$core.pragma('dart2js:noInline')
  static MotionTally getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MotionTally>(create);
  static MotionTally? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get motionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set motionId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMotionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMotionId() => clearField(1);

  /// Total eligible voters
  @$pb.TagNumber(2)
  $core.int get eligibleVotes => $_getIZ(1);
  @$pb.TagNumber(2)
  set eligibleVotes($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasEligibleVotes() => $_has(1);
  @$pb.TagNumber(2)
  void clearEligibleVotes() => clearField(2);

  /// Votes per choice
  @$pb.TagNumber(3)
  $core.List<VoteTally> get tallies => $_getList(2);

  /// Derived counts
  @$pb.TagNumber(4)
  $core.int get totalVotesCast => $_getIZ(3);
  @$pb.TagNumber(4)
  set totalVotesCast($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTotalVotesCast() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotalVotesCast() => clearField(4);

  /// Dead votes (invalid, expired, disqualified)
  @$pb.TagNumber(6)
  $core.int get deadVotes => $_getIZ(4);
  @$pb.TagNumber(6)
  set deadVotes($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(6)
  $core.bool hasDeadVotes() => $_has(4);
  @$pb.TagNumber(6)
  void clearDeadVotes() => clearField(6);

  /// Passing evaluation
  @$pb.TagNumber(7)
  $core.int get targetVotes => $_getIZ(5);
  @$pb.TagNumber(7)
  set targetVotes($core.int v) { $_setUnsignedInt32(5, v); }
  @$pb.TagNumber(7)
  $core.bool hasTargetVotes() => $_has(5);
  @$pb.TagNumber(7)
  void clearTargetVotes() => clearField(7);

  @$pb.TagNumber(8)
  $core.bool get passed => $_getBF(6);
  @$pb.TagNumber(8)
  set passed($core.bool v) { $_setBool(6, v); }
  @$pb.TagNumber(8)
  $core.bool hasPassed() => $_has(6);
  @$pb.TagNumber(8)
  void clearPassed() => clearField(8);

  @$pb.TagNumber(9)
  $core.bool get closed => $_getBF(7);
  @$pb.TagNumber(9)
  set closed($core.bool v) { $_setBool(7, v); }
  @$pb.TagNumber(9)
  $core.bool hasClosed() => $_has(7);
  @$pb.TagNumber(9)
  void clearClosed() => clearField(9);
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
    final $result = create();
    if (code != null) {
      $result.code = code;
    }
    if (message != null) {
      $result.message = message;
    }
    if (required != null) {
      $result.required = required;
    }
    if (minLength != null) {
      $result.minLength = minLength;
    }
    if (maxLength != null) {
      $result.maxLength = maxLength;
    }
    if (minValue != null) {
      $result.minValue = minValue;
    }
    if (maxValue != null) {
      $result.maxValue = maxValue;
    }
    if (pattern != null) {
      $result.pattern = pattern;
    }
    if (minItems != null) {
      $result.minItems = minItems;
    }
    if (maxItems != null) {
      $result.maxItems = maxItems;
    }
    return $result;
  }
  FormValidationRule._() : super();
  factory FormValidationRule.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FormValidationRule.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, FormValidationRule_Rule> _FormValidationRule_RuleByTag = {
    3 : FormValidationRule_Rule.required,
    4 : FormValidationRule_Rule.minLength,
    5 : FormValidationRule_Rule.maxLength,
    6 : FormValidationRule_Rule.minValue,
    7 : FormValidationRule_Rule.maxValue,
    8 : FormValidationRule_Rule.pattern,
    9 : FormValidationRule_Rule.minItems,
    10 : FormValidationRule_Rule.maxItems,
    0 : FormValidationRule_Rule.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FormValidationRule', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
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
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FormValidationRule clone() => FormValidationRule()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FormValidationRule copyWith(void Function(FormValidationRule) updates) => super.copyWith((message) => updates(message as FormValidationRule)) as FormValidationRule;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormValidationRule create() => FormValidationRule._();
  FormValidationRule createEmptyInstance() => create();
  static $pb.PbList<FormValidationRule> createRepeated() => $pb.PbList<FormValidationRule>();
  @$core.pragma('dart2js:noInline')
  static FormValidationRule getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FormValidationRule>(create);
  static FormValidationRule? _defaultInstance;

  FormValidationRule_Rule whichRule() => _FormValidationRule_RuleByTag[$_whichOneof(0)]!;
  void clearRule() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get required => $_getBF(2);
  @$pb.TagNumber(3)
  set required($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasRequired() => $_has(2);
  @$pb.TagNumber(3)
  void clearRequired() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get minLength => $_getIZ(3);
  @$pb.TagNumber(4)
  set minLength($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasMinLength() => $_has(3);
  @$pb.TagNumber(4)
  void clearMinLength() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get maxLength => $_getIZ(4);
  @$pb.TagNumber(5)
  set maxLength($core.int v) { $_setSignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasMaxLength() => $_has(4);
  @$pb.TagNumber(5)
  void clearMaxLength() => clearField(5);

  @$pb.TagNumber(6)
  $core.double get minValue => $_getN(5);
  @$pb.TagNumber(6)
  set minValue($core.double v) { $_setDouble(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasMinValue() => $_has(5);
  @$pb.TagNumber(6)
  void clearMinValue() => clearField(6);

  @$pb.TagNumber(7)
  $core.double get maxValue => $_getN(6);
  @$pb.TagNumber(7)
  set maxValue($core.double v) { $_setDouble(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasMaxValue() => $_has(6);
  @$pb.TagNumber(7)
  void clearMaxValue() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get pattern => $_getSZ(7);
  @$pb.TagNumber(8)
  set pattern($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasPattern() => $_has(7);
  @$pb.TagNumber(8)
  void clearPattern() => clearField(8);

  @$pb.TagNumber(9)
  $core.int get minItems => $_getIZ(8);
  @$pb.TagNumber(9)
  set minItems($core.int v) { $_setSignedInt32(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasMinItems() => $_has(8);
  @$pb.TagNumber(9)
  void clearMinItems() => clearField(9);

  @$pb.TagNumber(10)
  $core.int get maxItems => $_getIZ(9);
  @$pb.TagNumber(10)
  set maxItems($core.int v) { $_setSignedInt32(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasMaxItems() => $_has(9);
  @$pb.TagNumber(10)
  void clearMaxItems() => clearField(10);
}

class FormConditionClause extends $pb.GeneratedMessage {
  factory FormConditionClause({
    $core.String? fieldKey,
    FormConditionOperator? operator,
    $4.Value? value,
    $core.Iterable<$4.Value>? values,
  }) {
    final $result = create();
    if (fieldKey != null) {
      $result.fieldKey = fieldKey;
    }
    if (operator != null) {
      $result.operator = operator;
    }
    if (value != null) {
      $result.value = value;
    }
    if (values != null) {
      $result.values.addAll(values);
    }
    return $result;
  }
  FormConditionClause._() : super();
  factory FormConditionClause.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FormConditionClause.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FormConditionClause', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'fieldKey')
    ..e<FormConditionOperator>(2, _omitFieldNames ? '' : 'operator', $pb.PbFieldType.OE, defaultOrMaker: FormConditionOperator.FORM_CONDITION_OPERATOR_UNSPECIFIED, valueOf: FormConditionOperator.valueOf, enumValues: FormConditionOperator.values)
    ..aOM<$4.Value>(3, _omitFieldNames ? '' : 'value', subBuilder: $4.Value.create)
    ..pc<$4.Value>(4, _omitFieldNames ? '' : 'values', $pb.PbFieldType.PM, subBuilder: $4.Value.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FormConditionClause clone() => FormConditionClause()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FormConditionClause copyWith(void Function(FormConditionClause) updates) => super.copyWith((message) => updates(message as FormConditionClause)) as FormConditionClause;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormConditionClause create() => FormConditionClause._();
  FormConditionClause createEmptyInstance() => create();
  static $pb.PbList<FormConditionClause> createRepeated() => $pb.PbList<FormConditionClause>();
  @$core.pragma('dart2js:noInline')
  static FormConditionClause getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FormConditionClause>(create);
  static FormConditionClause? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldKey => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldKey($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldKey() => clearField(1);

  @$pb.TagNumber(2)
  FormConditionOperator get operator => $_getN(1);
  @$pb.TagNumber(2)
  set operator(FormConditionOperator v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasOperator() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperator() => clearField(2);

  @$pb.TagNumber(3)
  $4.Value get value => $_getN(2);
  @$pb.TagNumber(3)
  set value($4.Value v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearValue() => clearField(3);
  @$pb.TagNumber(3)
  $4.Value ensureValue() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.List<$4.Value> get values => $_getList(3);
}

class FormConditionGroup extends $pb.GeneratedMessage {
  factory FormConditionGroup({
    $core.Iterable<FormConditionClause>? all,
    $core.Iterable<FormConditionClause>? any,
  }) {
    final $result = create();
    if (all != null) {
      $result.all.addAll(all);
    }
    if (any != null) {
      $result.any.addAll(any);
    }
    return $result;
  }
  FormConditionGroup._() : super();
  factory FormConditionGroup.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FormConditionGroup.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FormConditionGroup', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..pc<FormConditionClause>(1, _omitFieldNames ? '' : 'all', $pb.PbFieldType.PM, subBuilder: FormConditionClause.create)
    ..pc<FormConditionClause>(2, _omitFieldNames ? '' : 'any', $pb.PbFieldType.PM, subBuilder: FormConditionClause.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FormConditionGroup clone() => FormConditionGroup()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FormConditionGroup copyWith(void Function(FormConditionGroup) updates) => super.copyWith((message) => updates(message as FormConditionGroup)) as FormConditionGroup;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormConditionGroup create() => FormConditionGroup._();
  FormConditionGroup createEmptyInstance() => create();
  static $pb.PbList<FormConditionGroup> createRepeated() => $pb.PbList<FormConditionGroup>();
  @$core.pragma('dart2js:noInline')
  static FormConditionGroup getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FormConditionGroup>(create);
  static FormConditionGroup? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<FormConditionClause> get all => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<FormConditionClause> get any => $_getList(1);
}

class FormOption extends $pb.GeneratedMessage {
  factory FormOption({
    $core.String? value,
    $core.String? label,
    $core.String? helpText,
    $core.bool? disabled,
    $4.Struct? metadata,
  }) {
    final $result = create();
    if (value != null) {
      $result.value = value;
    }
    if (label != null) {
      $result.label = label;
    }
    if (helpText != null) {
      $result.helpText = helpText;
    }
    if (disabled != null) {
      $result.disabled = disabled;
    }
    if (metadata != null) {
      $result.metadata = metadata;
    }
    return $result;
  }
  FormOption._() : super();
  factory FormOption.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FormOption.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FormOption', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'value')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'helpText')
    ..aOB(4, _omitFieldNames ? '' : 'disabled')
    ..aOM<$4.Struct>(5, _omitFieldNames ? '' : 'metadata', subBuilder: $4.Struct.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FormOption clone() => FormOption()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FormOption copyWith(void Function(FormOption) updates) => super.copyWith((message) => updates(message as FormOption)) as FormOption;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormOption create() => FormOption._();
  FormOption createEmptyInstance() => create();
  static $pb.PbList<FormOption> createRepeated() => $pb.PbList<FormOption>();
  @$core.pragma('dart2js:noInline')
  static FormOption getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FormOption>(create);
  static FormOption? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get helpText => $_getSZ(2);
  @$pb.TagNumber(3)
  set helpText($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasHelpText() => $_has(2);
  @$pb.TagNumber(3)
  void clearHelpText() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get disabled => $_getBF(3);
  @$pb.TagNumber(4)
  set disabled($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDisabled() => $_has(3);
  @$pb.TagNumber(4)
  void clearDisabled() => clearField(4);

  @$pb.TagNumber(5)
  $4.Struct get metadata => $_getN(4);
  @$pb.TagNumber(5)
  set metadata($4.Struct v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasMetadata() => $_has(4);
  @$pb.TagNumber(5)
  void clearMetadata() => clearField(5);
  @$pb.TagNumber(5)
  $4.Struct ensureMetadata() => $_ensure(4);
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
    final $result = create();
    if (inputMask != null) {
      $result.inputMask = inputMask;
    }
    if (displayFormat != null) {
      $result.displayFormat = displayFormat;
    }
    if (currencyCode != null) {
      $result.currencyCode = currencyCode;
    }
    if (decimalScale != null) {
      $result.decimalScale = decimalScale;
    }
    if (keyboard != null) {
      $result.keyboard = keyboard;
    }
    if (autocomplete != null) {
      $result.autocomplete = autocomplete;
    }
    return $result;
  }
  FormFormattingHint._() : super();
  factory FormFormattingHint.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FormFormattingHint.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FormFormattingHint', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'inputMask')
    ..aOS(2, _omitFieldNames ? '' : 'displayFormat')
    ..aOS(3, _omitFieldNames ? '' : 'currencyCode')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'decimalScale', $pb.PbFieldType.O3)
    ..aOS(5, _omitFieldNames ? '' : 'keyboard')
    ..aOS(6, _omitFieldNames ? '' : 'autocomplete')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FormFormattingHint clone() => FormFormattingHint()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FormFormattingHint copyWith(void Function(FormFormattingHint) updates) => super.copyWith((message) => updates(message as FormFormattingHint)) as FormFormattingHint;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormFormattingHint create() => FormFormattingHint._();
  FormFormattingHint createEmptyInstance() => create();
  static $pb.PbList<FormFormattingHint> createRepeated() => $pb.PbList<FormFormattingHint>();
  @$core.pragma('dart2js:noInline')
  static FormFormattingHint getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FormFormattingHint>(create);
  static FormFormattingHint? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get inputMask => $_getSZ(0);
  @$pb.TagNumber(1)
  set inputMask($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasInputMask() => $_has(0);
  @$pb.TagNumber(1)
  void clearInputMask() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get displayFormat => $_getSZ(1);
  @$pb.TagNumber(2)
  set displayFormat($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDisplayFormat() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisplayFormat() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get currencyCode => $_getSZ(2);
  @$pb.TagNumber(3)
  set currencyCode($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasCurrencyCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearCurrencyCode() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get decimalScale => $_getIZ(3);
  @$pb.TagNumber(4)
  set decimalScale($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDecimalScale() => $_has(3);
  @$pb.TagNumber(4)
  void clearDecimalScale() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get keyboard => $_getSZ(4);
  @$pb.TagNumber(5)
  set keyboard($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasKeyboard() => $_has(4);
  @$pb.TagNumber(5)
  void clearKeyboard() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get autocomplete => $_getSZ(5);
  @$pb.TagNumber(6)
  set autocomplete($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasAutocomplete() => $_has(5);
  @$pb.TagNumber(6)
  void clearAutocomplete() => clearField(6);
}

class FormReviewHint extends $pb.GeneratedMessage {
  factory FormReviewHint({
    $core.bool? includeInReview,
    $core.String? label,
    $core.String? sectionLabel,
    $core.String? formatter,
    $core.int? order,
  }) {
    final $result = create();
    if (includeInReview != null) {
      $result.includeInReview = includeInReview;
    }
    if (label != null) {
      $result.label = label;
    }
    if (sectionLabel != null) {
      $result.sectionLabel = sectionLabel;
    }
    if (formatter != null) {
      $result.formatter = formatter;
    }
    if (order != null) {
      $result.order = order;
    }
    return $result;
  }
  FormReviewHint._() : super();
  factory FormReviewHint.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FormReviewHint.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FormReviewHint', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'includeInReview')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'sectionLabel')
    ..aOS(4, _omitFieldNames ? '' : 'formatter')
    ..a<$core.int>(5, _omitFieldNames ? '' : 'order', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FormReviewHint clone() => FormReviewHint()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FormReviewHint copyWith(void Function(FormReviewHint) updates) => super.copyWith((message) => updates(message as FormReviewHint)) as FormReviewHint;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormReviewHint create() => FormReviewHint._();
  FormReviewHint createEmptyInstance() => create();
  static $pb.PbList<FormReviewHint> createRepeated() => $pb.PbList<FormReviewHint>();
  @$core.pragma('dart2js:noInline')
  static FormReviewHint getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FormReviewHint>(create);
  static FormReviewHint? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get includeInReview => $_getBF(0);
  @$pb.TagNumber(1)
  set includeInReview($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasIncludeInReview() => $_has(0);
  @$pb.TagNumber(1)
  void clearIncludeInReview() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get sectionLabel => $_getSZ(2);
  @$pb.TagNumber(3)
  set sectionLabel($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSectionLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearSectionLabel() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get formatter => $_getSZ(3);
  @$pb.TagNumber(4)
  set formatter($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasFormatter() => $_has(3);
  @$pb.TagNumber(4)
  void clearFormatter() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get order => $_getIZ(4);
  @$pb.TagNumber(5)
  set order($core.int v) { $_setSignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasOrder() => $_has(4);
  @$pb.TagNumber(5)
  void clearOrder() => clearField(5);
}

class FormField extends $pb.GeneratedMessage {
  factory FormField({
    $core.String? key,
    FormFieldType? type,
    $core.String? label,
    $core.String? helpText,
    $core.String? placeholder,
    $core.bool? required,
    $4.Value? defaultValue,
    $core.Iterable<FormValidationRule>? validationRules,
    FormConditionGroup? visibilityCondition,
    FormConditionGroup? editabilityCondition,
    $core.Iterable<FormOption>? options,
    $core.Iterable<FormField>? nestedFields,
    $core.Iterable<FormSection>? nestedSections,
    FormFormattingHint? formatting,
    $4.Struct? uiHints,
    FormReviewHint? review,
    $core.Iterable<$core.String>? visibleToRoles,
    $core.bool? repeatable,
    $core.bool? hidden,
  }) {
    final $result = create();
    if (key != null) {
      $result.key = key;
    }
    if (type != null) {
      $result.type = type;
    }
    if (label != null) {
      $result.label = label;
    }
    if (helpText != null) {
      $result.helpText = helpText;
    }
    if (placeholder != null) {
      $result.placeholder = placeholder;
    }
    if (required != null) {
      $result.required = required;
    }
    if (defaultValue != null) {
      $result.defaultValue = defaultValue;
    }
    if (validationRules != null) {
      $result.validationRules.addAll(validationRules);
    }
    if (visibilityCondition != null) {
      $result.visibilityCondition = visibilityCondition;
    }
    if (editabilityCondition != null) {
      $result.editabilityCondition = editabilityCondition;
    }
    if (options != null) {
      $result.options.addAll(options);
    }
    if (nestedFields != null) {
      $result.nestedFields.addAll(nestedFields);
    }
    if (nestedSections != null) {
      $result.nestedSections.addAll(nestedSections);
    }
    if (formatting != null) {
      $result.formatting = formatting;
    }
    if (uiHints != null) {
      $result.uiHints = uiHints;
    }
    if (review != null) {
      $result.review = review;
    }
    if (visibleToRoles != null) {
      $result.visibleToRoles.addAll(visibleToRoles);
    }
    if (repeatable != null) {
      $result.repeatable = repeatable;
    }
    if (hidden != null) {
      $result.hidden = hidden;
    }
    return $result;
  }
  FormField._() : super();
  factory FormField.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FormField.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FormField', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..e<FormFieldType>(2, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: FormFieldType.FORM_FIELD_TYPE_UNSPECIFIED, valueOf: FormFieldType.valueOf, enumValues: FormFieldType.values)
    ..aOS(3, _omitFieldNames ? '' : 'label')
    ..aOS(4, _omitFieldNames ? '' : 'helpText')
    ..aOS(5, _omitFieldNames ? '' : 'placeholder')
    ..aOB(6, _omitFieldNames ? '' : 'required')
    ..aOM<$4.Value>(7, _omitFieldNames ? '' : 'defaultValue', subBuilder: $4.Value.create)
    ..pc<FormValidationRule>(8, _omitFieldNames ? '' : 'validationRules', $pb.PbFieldType.PM, subBuilder: FormValidationRule.create)
    ..aOM<FormConditionGroup>(9, _omitFieldNames ? '' : 'visibilityCondition', subBuilder: FormConditionGroup.create)
    ..aOM<FormConditionGroup>(10, _omitFieldNames ? '' : 'editabilityCondition', subBuilder: FormConditionGroup.create)
    ..pc<FormOption>(11, _omitFieldNames ? '' : 'options', $pb.PbFieldType.PM, subBuilder: FormOption.create)
    ..pc<FormField>(12, _omitFieldNames ? '' : 'nestedFields', $pb.PbFieldType.PM, subBuilder: FormField.create)
    ..pc<FormSection>(13, _omitFieldNames ? '' : 'nestedSections', $pb.PbFieldType.PM, subBuilder: FormSection.create)
    ..aOM<FormFormattingHint>(14, _omitFieldNames ? '' : 'formatting', subBuilder: FormFormattingHint.create)
    ..aOM<$4.Struct>(15, _omitFieldNames ? '' : 'uiHints', subBuilder: $4.Struct.create)
    ..aOM<FormReviewHint>(16, _omitFieldNames ? '' : 'review', subBuilder: FormReviewHint.create)
    ..pPS(17, _omitFieldNames ? '' : 'visibleToRoles')
    ..aOB(18, _omitFieldNames ? '' : 'repeatable')
    ..aOB(19, _omitFieldNames ? '' : 'hidden')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FormField clone() => FormField()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FormField copyWith(void Function(FormField) updates) => super.copyWith((message) => updates(message as FormField)) as FormField;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormField create() => FormField._();
  FormField createEmptyInstance() => create();
  static $pb.PbList<FormField> createRepeated() => $pb.PbList<FormField>();
  @$core.pragma('dart2js:noInline')
  static FormField getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FormField>(create);
  static FormField? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);

  @$pb.TagNumber(2)
  FormFieldType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(FormFieldType v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get label => $_getSZ(2);
  @$pb.TagNumber(3)
  set label($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLabel() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get helpText => $_getSZ(3);
  @$pb.TagNumber(4)
  set helpText($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasHelpText() => $_has(3);
  @$pb.TagNumber(4)
  void clearHelpText() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get placeholder => $_getSZ(4);
  @$pb.TagNumber(5)
  set placeholder($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasPlaceholder() => $_has(4);
  @$pb.TagNumber(5)
  void clearPlaceholder() => clearField(5);

  @$pb.TagNumber(6)
  $core.bool get required => $_getBF(5);
  @$pb.TagNumber(6)
  set required($core.bool v) { $_setBool(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasRequired() => $_has(5);
  @$pb.TagNumber(6)
  void clearRequired() => clearField(6);

  @$pb.TagNumber(7)
  $4.Value get defaultValue => $_getN(6);
  @$pb.TagNumber(7)
  set defaultValue($4.Value v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasDefaultValue() => $_has(6);
  @$pb.TagNumber(7)
  void clearDefaultValue() => clearField(7);
  @$pb.TagNumber(7)
  $4.Value ensureDefaultValue() => $_ensure(6);

  @$pb.TagNumber(8)
  $core.List<FormValidationRule> get validationRules => $_getList(7);

  @$pb.TagNumber(9)
  FormConditionGroup get visibilityCondition => $_getN(8);
  @$pb.TagNumber(9)
  set visibilityCondition(FormConditionGroup v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasVisibilityCondition() => $_has(8);
  @$pb.TagNumber(9)
  void clearVisibilityCondition() => clearField(9);
  @$pb.TagNumber(9)
  FormConditionGroup ensureVisibilityCondition() => $_ensure(8);

  @$pb.TagNumber(10)
  FormConditionGroup get editabilityCondition => $_getN(9);
  @$pb.TagNumber(10)
  set editabilityCondition(FormConditionGroup v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasEditabilityCondition() => $_has(9);
  @$pb.TagNumber(10)
  void clearEditabilityCondition() => clearField(10);
  @$pb.TagNumber(10)
  FormConditionGroup ensureEditabilityCondition() => $_ensure(9);

  @$pb.TagNumber(11)
  $core.List<FormOption> get options => $_getList(10);

  @$pb.TagNumber(12)
  $core.List<FormField> get nestedFields => $_getList(11);

  @$pb.TagNumber(13)
  $core.List<FormSection> get nestedSections => $_getList(12);

  @$pb.TagNumber(14)
  FormFormattingHint get formatting => $_getN(13);
  @$pb.TagNumber(14)
  set formatting(FormFormattingHint v) { setField(14, v); }
  @$pb.TagNumber(14)
  $core.bool hasFormatting() => $_has(13);
  @$pb.TagNumber(14)
  void clearFormatting() => clearField(14);
  @$pb.TagNumber(14)
  FormFormattingHint ensureFormatting() => $_ensure(13);

  @$pb.TagNumber(15)
  $4.Struct get uiHints => $_getN(14);
  @$pb.TagNumber(15)
  set uiHints($4.Struct v) { setField(15, v); }
  @$pb.TagNumber(15)
  $core.bool hasUiHints() => $_has(14);
  @$pb.TagNumber(15)
  void clearUiHints() => clearField(15);
  @$pb.TagNumber(15)
  $4.Struct ensureUiHints() => $_ensure(14);

  @$pb.TagNumber(16)
  FormReviewHint get review => $_getN(15);
  @$pb.TagNumber(16)
  set review(FormReviewHint v) { setField(16, v); }
  @$pb.TagNumber(16)
  $core.bool hasReview() => $_has(15);
  @$pb.TagNumber(16)
  void clearReview() => clearField(16);
  @$pb.TagNumber(16)
  FormReviewHint ensureReview() => $_ensure(15);

  @$pb.TagNumber(17)
  $core.List<$core.String> get visibleToRoles => $_getList(16);

  @$pb.TagNumber(18)
  $core.bool get repeatable => $_getBF(17);
  @$pb.TagNumber(18)
  set repeatable($core.bool v) { $_setBool(17, v); }
  @$pb.TagNumber(18)
  $core.bool hasRepeatable() => $_has(17);
  @$pb.TagNumber(18)
  void clearRepeatable() => clearField(18);

  @$pb.TagNumber(19)
  $core.bool get hidden => $_getBF(18);
  @$pb.TagNumber(19)
  set hidden($core.bool v) { $_setBool(18, v); }
  @$pb.TagNumber(19)
  $core.bool hasHidden() => $_has(18);
  @$pb.TagNumber(19)
  void clearHidden() => clearField(19);
}

class FormSection extends $pb.GeneratedMessage {
  factory FormSection({
    $core.String? id,
    $core.String? title,
    $core.String? description,
    $core.Iterable<FormField>? fields,
    $4.Struct? uiHints,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (title != null) {
      $result.title = title;
    }
    if (description != null) {
      $result.description = description;
    }
    if (fields != null) {
      $result.fields.addAll(fields);
    }
    if (uiHints != null) {
      $result.uiHints = uiHints;
    }
    return $result;
  }
  FormSection._() : super();
  factory FormSection.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FormSection.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FormSection', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..pc<FormField>(4, _omitFieldNames ? '' : 'fields', $pb.PbFieldType.PM, subBuilder: FormField.create)
    ..aOM<$4.Struct>(5, _omitFieldNames ? '' : 'uiHints', subBuilder: $4.Struct.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FormSection clone() => FormSection()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FormSection copyWith(void Function(FormSection) updates) => super.copyWith((message) => updates(message as FormSection)) as FormSection;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormSection create() => FormSection._();
  FormSection createEmptyInstance() => create();
  static $pb.PbList<FormSection> createRepeated() => $pb.PbList<FormSection>();
  @$core.pragma('dart2js:noInline')
  static FormSection getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FormSection>(create);
  static FormSection? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<FormField> get fields => $_getList(3);

  @$pb.TagNumber(5)
  $4.Struct get uiHints => $_getN(4);
  @$pb.TagNumber(5)
  set uiHints($4.Struct v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasUiHints() => $_has(4);
  @$pb.TagNumber(5)
  void clearUiHints() => clearField(5);
  @$pb.TagNumber(5)
  $4.Struct ensureUiHints() => $_ensure(4);
}

class FormStep extends $pb.GeneratedMessage {
  factory FormStep({
    $core.String? id,
    $core.String? title,
    $core.String? description,
    $core.Iterable<FormSection>? sections,
    $4.Struct? uiHints,
    FormConditionGroup? visibilityCondition,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (title != null) {
      $result.title = title;
    }
    if (description != null) {
      $result.description = description;
    }
    if (sections != null) {
      $result.sections.addAll(sections);
    }
    if (uiHints != null) {
      $result.uiHints = uiHints;
    }
    if (visibilityCondition != null) {
      $result.visibilityCondition = visibilityCondition;
    }
    return $result;
  }
  FormStep._() : super();
  factory FormStep.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FormStep.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FormStep', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..pc<FormSection>(4, _omitFieldNames ? '' : 'sections', $pb.PbFieldType.PM, subBuilder: FormSection.create)
    ..aOM<$4.Struct>(5, _omitFieldNames ? '' : 'uiHints', subBuilder: $4.Struct.create)
    ..aOM<FormConditionGroup>(6, _omitFieldNames ? '' : 'visibilityCondition', subBuilder: FormConditionGroup.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FormStep clone() => FormStep()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FormStep copyWith(void Function(FormStep) updates) => super.copyWith((message) => updates(message as FormStep)) as FormStep;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormStep create() => FormStep._();
  FormStep createEmptyInstance() => create();
  static $pb.PbList<FormStep> createRepeated() => $pb.PbList<FormStep>();
  @$core.pragma('dart2js:noInline')
  static FormStep getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FormStep>(create);
  static FormStep? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<FormSection> get sections => $_getList(3);

  @$pb.TagNumber(5)
  $4.Struct get uiHints => $_getN(4);
  @$pb.TagNumber(5)
  set uiHints($4.Struct v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasUiHints() => $_has(4);
  @$pb.TagNumber(5)
  void clearUiHints() => clearField(5);
  @$pb.TagNumber(5)
  $4.Struct ensureUiHints() => $_ensure(4);

  @$pb.TagNumber(6)
  FormConditionGroup get visibilityCondition => $_getN(5);
  @$pb.TagNumber(6)
  set visibilityCondition(FormConditionGroup v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasVisibilityCondition() => $_has(5);
  @$pb.TagNumber(6)
  void clearVisibilityCondition() => clearField(6);
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
    $4.Struct? workflowMetadata,
    $4.Struct? uiHints,
  }) {
    final $result = create();
    if (formId != null) {
      $result.formId = formId;
    }
    if (formVersion != null) {
      $result.formVersion = formVersion;
    }
    if (title != null) {
      $result.title = title;
    }
    if (subtitle != null) {
      $result.subtitle = subtitle;
    }
    if (description != null) {
      $result.description = description;
    }
    if (steps != null) {
      $result.steps.addAll(steps);
    }
    if (workflowMetadata != null) {
      $result.workflowMetadata = workflowMetadata;
    }
    if (uiHints != null) {
      $result.uiHints = uiHints;
    }
    return $result;
  }
  FormSchema._() : super();
  factory FormSchema.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FormSchema.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FormSchema', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'formId')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'formVersion', $pb.PbFieldType.O3)
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOS(4, _omitFieldNames ? '' : 'subtitle')
    ..aOS(5, _omitFieldNames ? '' : 'description')
    ..pc<FormStep>(6, _omitFieldNames ? '' : 'steps', $pb.PbFieldType.PM, subBuilder: FormStep.create)
    ..aOM<$4.Struct>(7, _omitFieldNames ? '' : 'workflowMetadata', subBuilder: $4.Struct.create)
    ..aOM<$4.Struct>(8, _omitFieldNames ? '' : 'uiHints', subBuilder: $4.Struct.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FormSchema clone() => FormSchema()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FormSchema copyWith(void Function(FormSchema) updates) => super.copyWith((message) => updates(message as FormSchema)) as FormSchema;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormSchema create() => FormSchema._();
  FormSchema createEmptyInstance() => create();
  static $pb.PbList<FormSchema> createRepeated() => $pb.PbList<FormSchema>();
  @$core.pragma('dart2js:noInline')
  static FormSchema getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FormSchema>(create);
  static FormSchema? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get formId => $_getSZ(0);
  @$pb.TagNumber(1)
  set formId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFormId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFormId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get formVersion => $_getIZ(1);
  @$pb.TagNumber(2)
  set formVersion($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFormVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormVersion() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get subtitle => $_getSZ(3);
  @$pb.TagNumber(4)
  set subtitle($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSubtitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearSubtitle() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get description => $_getSZ(4);
  @$pb.TagNumber(5)
  set description($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasDescription() => $_has(4);
  @$pb.TagNumber(5)
  void clearDescription() => clearField(5);

  @$pb.TagNumber(6)
  $core.List<FormStep> get steps => $_getList(5);

  @$pb.TagNumber(7)
  $4.Struct get workflowMetadata => $_getN(6);
  @$pb.TagNumber(7)
  set workflowMetadata($4.Struct v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasWorkflowMetadata() => $_has(6);
  @$pb.TagNumber(7)
  void clearWorkflowMetadata() => clearField(7);
  @$pb.TagNumber(7)
  $4.Struct ensureWorkflowMetadata() => $_ensure(6);

  @$pb.TagNumber(8)
  $4.Struct get uiHints => $_getN(7);
  @$pb.TagNumber(8)
  set uiHints($4.Struct v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasUiHints() => $_has(7);
  @$pb.TagNumber(8)
  void clearUiHints() => clearField(8);
  @$pb.TagNumber(8)
  $4.Struct ensureUiHints() => $_ensure(7);
}

class FormPermissions extends $pb.GeneratedMessage {
  factory FormPermissions({
    $core.bool? canEdit,
    $core.bool? canSubmit,
    $core.bool? canSaveDraft,
    $core.bool? canGoBack,
    $core.String? assigneeSubscriptionId,
  }) {
    final $result = create();
    if (canEdit != null) {
      $result.canEdit = canEdit;
    }
    if (canSubmit != null) {
      $result.canSubmit = canSubmit;
    }
    if (canSaveDraft != null) {
      $result.canSaveDraft = canSaveDraft;
    }
    if (canGoBack != null) {
      $result.canGoBack = canGoBack;
    }
    if (assigneeSubscriptionId != null) {
      $result.assigneeSubscriptionId = assigneeSubscriptionId;
    }
    return $result;
  }
  FormPermissions._() : super();
  factory FormPermissions.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FormPermissions.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FormPermissions', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'canEdit')
    ..aOB(2, _omitFieldNames ? '' : 'canSubmit')
    ..aOB(3, _omitFieldNames ? '' : 'canSaveDraft')
    ..aOB(4, _omitFieldNames ? '' : 'canGoBack')
    ..aOS(5, _omitFieldNames ? '' : 'assigneeSubscriptionId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FormPermissions clone() => FormPermissions()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FormPermissions copyWith(void Function(FormPermissions) updates) => super.copyWith((message) => updates(message as FormPermissions)) as FormPermissions;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormPermissions create() => FormPermissions._();
  FormPermissions createEmptyInstance() => create();
  static $pb.PbList<FormPermissions> createRepeated() => $pb.PbList<FormPermissions>();
  @$core.pragma('dart2js:noInline')
  static FormPermissions getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FormPermissions>(create);
  static FormPermissions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get canEdit => $_getBF(0);
  @$pb.TagNumber(1)
  set canEdit($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCanEdit() => $_has(0);
  @$pb.TagNumber(1)
  void clearCanEdit() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get canSubmit => $_getBF(1);
  @$pb.TagNumber(2)
  set canSubmit($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCanSubmit() => $_has(1);
  @$pb.TagNumber(2)
  void clearCanSubmit() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get canSaveDraft => $_getBF(2);
  @$pb.TagNumber(3)
  set canSaveDraft($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasCanSaveDraft() => $_has(2);
  @$pb.TagNumber(3)
  void clearCanSaveDraft() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get canGoBack => $_getBF(3);
  @$pb.TagNumber(4)
  set canGoBack($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasCanGoBack() => $_has(3);
  @$pb.TagNumber(4)
  void clearCanGoBack() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get assigneeSubscriptionId => $_getSZ(4);
  @$pb.TagNumber(5)
  set assigneeSubscriptionId($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasAssigneeSubscriptionId() => $_has(4);
  @$pb.TagNumber(5)
  void clearAssigneeSubscriptionId() => clearField(5);
}

class FormReviewItem extends $pb.GeneratedMessage {
  factory FormReviewItem({
    $core.String? fieldKey,
    $core.String? label,
    $core.String? displayValue,
    $core.bool? emphasized,
  }) {
    final $result = create();
    if (fieldKey != null) {
      $result.fieldKey = fieldKey;
    }
    if (label != null) {
      $result.label = label;
    }
    if (displayValue != null) {
      $result.displayValue = displayValue;
    }
    if (emphasized != null) {
      $result.emphasized = emphasized;
    }
    return $result;
  }
  FormReviewItem._() : super();
  factory FormReviewItem.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FormReviewItem.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FormReviewItem', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'fieldKey')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'displayValue')
    ..aOB(4, _omitFieldNames ? '' : 'emphasized')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FormReviewItem clone() => FormReviewItem()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FormReviewItem copyWith(void Function(FormReviewItem) updates) => super.copyWith((message) => updates(message as FormReviewItem)) as FormReviewItem;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormReviewItem create() => FormReviewItem._();
  FormReviewItem createEmptyInstance() => create();
  static $pb.PbList<FormReviewItem> createRepeated() => $pb.PbList<FormReviewItem>();
  @$core.pragma('dart2js:noInline')
  static FormReviewItem getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FormReviewItem>(create);
  static FormReviewItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fieldKey => $_getSZ(0);
  @$pb.TagNumber(1)
  set fieldKey($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFieldKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearFieldKey() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get displayValue => $_getSZ(2);
  @$pb.TagNumber(3)
  set displayValue($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDisplayValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisplayValue() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get emphasized => $_getBF(3);
  @$pb.TagNumber(4)
  set emphasized($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasEmphasized() => $_has(3);
  @$pb.TagNumber(4)
  void clearEmphasized() => clearField(4);
}

class FormReviewSection extends $pb.GeneratedMessage {
  factory FormReviewSection({
    $core.String? stepId,
    $core.String? stepTitle,
    $core.String? sectionId,
    $core.String? sectionTitle,
    $core.Iterable<FormReviewItem>? items,
  }) {
    final $result = create();
    if (stepId != null) {
      $result.stepId = stepId;
    }
    if (stepTitle != null) {
      $result.stepTitle = stepTitle;
    }
    if (sectionId != null) {
      $result.sectionId = sectionId;
    }
    if (sectionTitle != null) {
      $result.sectionTitle = sectionTitle;
    }
    if (items != null) {
      $result.items.addAll(items);
    }
    return $result;
  }
  FormReviewSection._() : super();
  factory FormReviewSection.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FormReviewSection.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FormReviewSection', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'stepId')
    ..aOS(2, _omitFieldNames ? '' : 'stepTitle')
    ..aOS(3, _omitFieldNames ? '' : 'sectionId')
    ..aOS(4, _omitFieldNames ? '' : 'sectionTitle')
    ..pc<FormReviewItem>(5, _omitFieldNames ? '' : 'items', $pb.PbFieldType.PM, subBuilder: FormReviewItem.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FormReviewSection clone() => FormReviewSection()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FormReviewSection copyWith(void Function(FormReviewSection) updates) => super.copyWith((message) => updates(message as FormReviewSection)) as FormReviewSection;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormReviewSection create() => FormReviewSection._();
  FormReviewSection createEmptyInstance() => create();
  static $pb.PbList<FormReviewSection> createRepeated() => $pb.PbList<FormReviewSection>();
  @$core.pragma('dart2js:noInline')
  static FormReviewSection getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FormReviewSection>(create);
  static FormReviewSection? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get stepId => $_getSZ(0);
  @$pb.TagNumber(1)
  set stepId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasStepId() => $_has(0);
  @$pb.TagNumber(1)
  void clearStepId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get stepTitle => $_getSZ(1);
  @$pb.TagNumber(2)
  set stepTitle($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasStepTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearStepTitle() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get sectionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sectionId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSectionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSectionId() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get sectionTitle => $_getSZ(3);
  @$pb.TagNumber(4)
  set sectionTitle($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSectionTitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearSectionTitle() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<FormReviewItem> get items => $_getList(4);
}

class FormSubmissionSnapshot extends $pb.GeneratedMessage {
  factory FormSubmissionSnapshot({
    $core.String? formInstanceId,
    $core.String? schemaId,
    $core.int? schemaVersion,
    $2.Timestamp? submittedAt,
    $core.String? submittedBySubscriptionId,
    $4.Struct? answers,
    $core.Iterable<FormReviewSection>? formattedSections,
    $core.String? submissionReference,
    FormMessageState? status,
    $core.String? backendMessage,
    $core.String? workflowMessage,
    $4.Struct? metadata,
  }) {
    final $result = create();
    if (formInstanceId != null) {
      $result.formInstanceId = formInstanceId;
    }
    if (schemaId != null) {
      $result.schemaId = schemaId;
    }
    if (schemaVersion != null) {
      $result.schemaVersion = schemaVersion;
    }
    if (submittedAt != null) {
      $result.submittedAt = submittedAt;
    }
    if (submittedBySubscriptionId != null) {
      $result.submittedBySubscriptionId = submittedBySubscriptionId;
    }
    if (answers != null) {
      $result.answers = answers;
    }
    if (formattedSections != null) {
      $result.formattedSections.addAll(formattedSections);
    }
    if (submissionReference != null) {
      $result.submissionReference = submissionReference;
    }
    if (status != null) {
      $result.status = status;
    }
    if (backendMessage != null) {
      $result.backendMessage = backendMessage;
    }
    if (workflowMessage != null) {
      $result.workflowMessage = workflowMessage;
    }
    if (metadata != null) {
      $result.metadata = metadata;
    }
    return $result;
  }
  FormSubmissionSnapshot._() : super();
  factory FormSubmissionSnapshot.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FormSubmissionSnapshot.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FormSubmissionSnapshot', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'formInstanceId')
    ..aOS(2, _omitFieldNames ? '' : 'schemaId')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'schemaVersion', $pb.PbFieldType.O3)
    ..aOM<$2.Timestamp>(4, _omitFieldNames ? '' : 'submittedAt', subBuilder: $2.Timestamp.create)
    ..aOS(5, _omitFieldNames ? '' : 'submittedBySubscriptionId')
    ..aOM<$4.Struct>(6, _omitFieldNames ? '' : 'answers', subBuilder: $4.Struct.create)
    ..pc<FormReviewSection>(7, _omitFieldNames ? '' : 'formattedSections', $pb.PbFieldType.PM, subBuilder: FormReviewSection.create)
    ..aOS(8, _omitFieldNames ? '' : 'submissionReference')
    ..e<FormMessageState>(9, _omitFieldNames ? '' : 'status', $pb.PbFieldType.OE, defaultOrMaker: FormMessageState.FORM_MESSAGE_STATE_UNSPECIFIED, valueOf: FormMessageState.valueOf, enumValues: FormMessageState.values)
    ..aOS(10, _omitFieldNames ? '' : 'backendMessage')
    ..aOS(11, _omitFieldNames ? '' : 'workflowMessage')
    ..aOM<$4.Struct>(12, _omitFieldNames ? '' : 'metadata', subBuilder: $4.Struct.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FormSubmissionSnapshot clone() => FormSubmissionSnapshot()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FormSubmissionSnapshot copyWith(void Function(FormSubmissionSnapshot) updates) => super.copyWith((message) => updates(message as FormSubmissionSnapshot)) as FormSubmissionSnapshot;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormSubmissionSnapshot create() => FormSubmissionSnapshot._();
  FormSubmissionSnapshot createEmptyInstance() => create();
  static $pb.PbList<FormSubmissionSnapshot> createRepeated() => $pb.PbList<FormSubmissionSnapshot>();
  @$core.pragma('dart2js:noInline')
  static FormSubmissionSnapshot getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FormSubmissionSnapshot>(create);
  static FormSubmissionSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get formInstanceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set formInstanceId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFormInstanceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFormInstanceId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get schemaId => $_getSZ(1);
  @$pb.TagNumber(2)
  set schemaId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSchemaId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSchemaId() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get schemaVersion => $_getIZ(2);
  @$pb.TagNumber(3)
  set schemaVersion($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSchemaVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearSchemaVersion() => clearField(3);

  @$pb.TagNumber(4)
  $2.Timestamp get submittedAt => $_getN(3);
  @$pb.TagNumber(4)
  set submittedAt($2.Timestamp v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasSubmittedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearSubmittedAt() => clearField(4);
  @$pb.TagNumber(4)
  $2.Timestamp ensureSubmittedAt() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.String get submittedBySubscriptionId => $_getSZ(4);
  @$pb.TagNumber(5)
  set submittedBySubscriptionId($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasSubmittedBySubscriptionId() => $_has(4);
  @$pb.TagNumber(5)
  void clearSubmittedBySubscriptionId() => clearField(5);

  @$pb.TagNumber(6)
  $4.Struct get answers => $_getN(5);
  @$pb.TagNumber(6)
  set answers($4.Struct v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasAnswers() => $_has(5);
  @$pb.TagNumber(6)
  void clearAnswers() => clearField(6);
  @$pb.TagNumber(6)
  $4.Struct ensureAnswers() => $_ensure(5);

  @$pb.TagNumber(7)
  $core.List<FormReviewSection> get formattedSections => $_getList(6);

  @$pb.TagNumber(8)
  $core.String get submissionReference => $_getSZ(7);
  @$pb.TagNumber(8)
  set submissionReference($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasSubmissionReference() => $_has(7);
  @$pb.TagNumber(8)
  void clearSubmissionReference() => clearField(8);

  @$pb.TagNumber(9)
  FormMessageState get status => $_getN(8);
  @$pb.TagNumber(9)
  set status(FormMessageState v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasStatus() => $_has(8);
  @$pb.TagNumber(9)
  void clearStatus() => clearField(9);

  @$pb.TagNumber(10)
  $core.String get backendMessage => $_getSZ(9);
  @$pb.TagNumber(10)
  set backendMessage($core.String v) { $_setString(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasBackendMessage() => $_has(9);
  @$pb.TagNumber(10)
  void clearBackendMessage() => clearField(10);

  @$pb.TagNumber(11)
  $core.String get workflowMessage => $_getSZ(10);
  @$pb.TagNumber(11)
  set workflowMessage($core.String v) { $_setString(10, v); }
  @$pb.TagNumber(11)
  $core.bool hasWorkflowMessage() => $_has(10);
  @$pb.TagNumber(11)
  void clearWorkflowMessage() => clearField(11);

  @$pb.TagNumber(12)
  $4.Struct get metadata => $_getN(11);
  @$pb.TagNumber(12)
  set metadata($4.Struct v) { setField(12, v); }
  @$pb.TagNumber(12)
  $core.bool hasMetadata() => $_has(11);
  @$pb.TagNumber(12)
  void clearMetadata() => clearField(12);
  @$pb.TagNumber(12)
  $4.Struct ensureMetadata() => $_ensure(11);
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
    $4.Struct? initialValues,
    $4.Struct? serverDraftValues,
    FormSubmissionSnapshot? finalSubmissionSnapshot,
    FormPermissions? permissions,
    $2.Timestamp? expiresAt,
    $4.Struct? workflowContext,
    $core.String? currentWorkflowState,
  }) {
    final $result = create();
    if (formInstanceId != null) {
      $result.formInstanceId = formInstanceId;
    }
    if (schemaId != null) {
      $result.schemaId = schemaId;
    }
    if (schemaVersion != null) {
      $result.schemaVersion = schemaVersion;
    }
    if (title != null) {
      $result.title = title;
    }
    if (description != null) {
      $result.description = description;
    }
    if (state != null) {
      $result.state = state;
    }
    if (reviewRequired != null) {
      $result.reviewRequired = reviewRequired;
    }
    if (schema != null) {
      $result.schema = schema;
    }
    if (initialValues != null) {
      $result.initialValues = initialValues;
    }
    if (serverDraftValues != null) {
      $result.serverDraftValues = serverDraftValues;
    }
    if (finalSubmissionSnapshot != null) {
      $result.finalSubmissionSnapshot = finalSubmissionSnapshot;
    }
    if (permissions != null) {
      $result.permissions = permissions;
    }
    if (expiresAt != null) {
      $result.expiresAt = expiresAt;
    }
    if (workflowContext != null) {
      $result.workflowContext = workflowContext;
    }
    if (currentWorkflowState != null) {
      $result.currentWorkflowState = currentWorkflowState;
    }
    return $result;
  }
  FormRequestContent._() : super();
  factory FormRequestContent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FormRequestContent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FormRequestContent', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'formInstanceId')
    ..aOS(2, _omitFieldNames ? '' : 'schemaId')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'schemaVersion', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'title')
    ..aOS(5, _omitFieldNames ? '' : 'description')
    ..e<FormMessageState>(6, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE, defaultOrMaker: FormMessageState.FORM_MESSAGE_STATE_UNSPECIFIED, valueOf: FormMessageState.valueOf, enumValues: FormMessageState.values)
    ..aOB(7, _omitFieldNames ? '' : 'reviewRequired')
    ..aOM<FormSchema>(8, _omitFieldNames ? '' : 'schema', subBuilder: FormSchema.create)
    ..aOM<$4.Struct>(9, _omitFieldNames ? '' : 'initialValues', subBuilder: $4.Struct.create)
    ..aOM<$4.Struct>(10, _omitFieldNames ? '' : 'serverDraftValues', subBuilder: $4.Struct.create)
    ..aOM<FormSubmissionSnapshot>(11, _omitFieldNames ? '' : 'finalSubmissionSnapshot', subBuilder: FormSubmissionSnapshot.create)
    ..aOM<FormPermissions>(12, _omitFieldNames ? '' : 'permissions', subBuilder: FormPermissions.create)
    ..aOM<$2.Timestamp>(13, _omitFieldNames ? '' : 'expiresAt', subBuilder: $2.Timestamp.create)
    ..aOM<$4.Struct>(14, _omitFieldNames ? '' : 'workflowContext', subBuilder: $4.Struct.create)
    ..aOS(15, _omitFieldNames ? '' : 'currentWorkflowState')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FormRequestContent clone() => FormRequestContent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FormRequestContent copyWith(void Function(FormRequestContent) updates) => super.copyWith((message) => updates(message as FormRequestContent)) as FormRequestContent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormRequestContent create() => FormRequestContent._();
  FormRequestContent createEmptyInstance() => create();
  static $pb.PbList<FormRequestContent> createRepeated() => $pb.PbList<FormRequestContent>();
  @$core.pragma('dart2js:noInline')
  static FormRequestContent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FormRequestContent>(create);
  static FormRequestContent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get formInstanceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set formInstanceId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFormInstanceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFormInstanceId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get schemaId => $_getSZ(1);
  @$pb.TagNumber(2)
  set schemaId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSchemaId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSchemaId() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get schemaVersion => $_getIZ(2);
  @$pb.TagNumber(3)
  set schemaVersion($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSchemaVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearSchemaVersion() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get title => $_getSZ(3);
  @$pb.TagNumber(4)
  set title($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearTitle() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get description => $_getSZ(4);
  @$pb.TagNumber(5)
  set description($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasDescription() => $_has(4);
  @$pb.TagNumber(5)
  void clearDescription() => clearField(5);

  @$pb.TagNumber(6)
  FormMessageState get state => $_getN(5);
  @$pb.TagNumber(6)
  set state(FormMessageState v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasState() => $_has(5);
  @$pb.TagNumber(6)
  void clearState() => clearField(6);

  @$pb.TagNumber(7)
  $core.bool get reviewRequired => $_getBF(6);
  @$pb.TagNumber(7)
  set reviewRequired($core.bool v) { $_setBool(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasReviewRequired() => $_has(6);
  @$pb.TagNumber(7)
  void clearReviewRequired() => clearField(7);

  @$pb.TagNumber(8)
  FormSchema get schema => $_getN(7);
  @$pb.TagNumber(8)
  set schema(FormSchema v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasSchema() => $_has(7);
  @$pb.TagNumber(8)
  void clearSchema() => clearField(8);
  @$pb.TagNumber(8)
  FormSchema ensureSchema() => $_ensure(7);

  @$pb.TagNumber(9)
  $4.Struct get initialValues => $_getN(8);
  @$pb.TagNumber(9)
  set initialValues($4.Struct v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasInitialValues() => $_has(8);
  @$pb.TagNumber(9)
  void clearInitialValues() => clearField(9);
  @$pb.TagNumber(9)
  $4.Struct ensureInitialValues() => $_ensure(8);

  @$pb.TagNumber(10)
  $4.Struct get serverDraftValues => $_getN(9);
  @$pb.TagNumber(10)
  set serverDraftValues($4.Struct v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasServerDraftValues() => $_has(9);
  @$pb.TagNumber(10)
  void clearServerDraftValues() => clearField(10);
  @$pb.TagNumber(10)
  $4.Struct ensureServerDraftValues() => $_ensure(9);

  @$pb.TagNumber(11)
  FormSubmissionSnapshot get finalSubmissionSnapshot => $_getN(10);
  @$pb.TagNumber(11)
  set finalSubmissionSnapshot(FormSubmissionSnapshot v) { setField(11, v); }
  @$pb.TagNumber(11)
  $core.bool hasFinalSubmissionSnapshot() => $_has(10);
  @$pb.TagNumber(11)
  void clearFinalSubmissionSnapshot() => clearField(11);
  @$pb.TagNumber(11)
  FormSubmissionSnapshot ensureFinalSubmissionSnapshot() => $_ensure(10);

  @$pb.TagNumber(12)
  FormPermissions get permissions => $_getN(11);
  @$pb.TagNumber(12)
  set permissions(FormPermissions v) { setField(12, v); }
  @$pb.TagNumber(12)
  $core.bool hasPermissions() => $_has(11);
  @$pb.TagNumber(12)
  void clearPermissions() => clearField(12);
  @$pb.TagNumber(12)
  FormPermissions ensurePermissions() => $_ensure(11);

  @$pb.TagNumber(13)
  $2.Timestamp get expiresAt => $_getN(12);
  @$pb.TagNumber(13)
  set expiresAt($2.Timestamp v) { setField(13, v); }
  @$pb.TagNumber(13)
  $core.bool hasExpiresAt() => $_has(12);
  @$pb.TagNumber(13)
  void clearExpiresAt() => clearField(13);
  @$pb.TagNumber(13)
  $2.Timestamp ensureExpiresAt() => $_ensure(12);

  @$pb.TagNumber(14)
  $4.Struct get workflowContext => $_getN(13);
  @$pb.TagNumber(14)
  set workflowContext($4.Struct v) { setField(14, v); }
  @$pb.TagNumber(14)
  $core.bool hasWorkflowContext() => $_has(13);
  @$pb.TagNumber(14)
  void clearWorkflowContext() => clearField(14);
  @$pb.TagNumber(14)
  $4.Struct ensureWorkflowContext() => $_ensure(13);

  @$pb.TagNumber(15)
  $core.String get currentWorkflowState => $_getSZ(14);
  @$pb.TagNumber(15)
  set currentWorkflowState($core.String v) { $_setString(14, v); }
  @$pb.TagNumber(15)
  $core.bool hasCurrentWorkflowState() => $_has(14);
  @$pb.TagNumber(15)
  void clearCurrentWorkflowState() => clearField(15);
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
    $4.Struct? metadata,
  }) {
    final $result = create();
    if (formInstanceId != null) {
      $result.formInstanceId = formInstanceId;
    }
    if (schemaId != null) {
      $result.schemaId = schemaId;
    }
    if (schemaVersion != null) {
      $result.schemaVersion = schemaVersion;
    }
    if (sourceEventId != null) {
      $result.sourceEventId = sourceEventId;
    }
    if (state != null) {
      $result.state = state;
    }
    if (reviewConfirmed != null) {
      $result.reviewConfirmed = reviewConfirmed;
    }
    if (submissionSnapshot != null) {
      $result.submissionSnapshot = submissionSnapshot;
    }
    if (metadata != null) {
      $result.metadata = metadata;
    }
    return $result;
  }
  FormSubmissionResultContent._() : super();
  factory FormSubmissionResultContent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FormSubmissionResultContent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FormSubmissionResultContent', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'formInstanceId')
    ..aOS(2, _omitFieldNames ? '' : 'schemaId')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'schemaVersion', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'sourceEventId')
    ..e<FormMessageState>(5, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE, defaultOrMaker: FormMessageState.FORM_MESSAGE_STATE_UNSPECIFIED, valueOf: FormMessageState.valueOf, enumValues: FormMessageState.values)
    ..aOB(6, _omitFieldNames ? '' : 'reviewConfirmed')
    ..aOM<FormSubmissionSnapshot>(7, _omitFieldNames ? '' : 'submissionSnapshot', subBuilder: FormSubmissionSnapshot.create)
    ..aOM<$4.Struct>(8, _omitFieldNames ? '' : 'metadata', subBuilder: $4.Struct.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FormSubmissionResultContent clone() => FormSubmissionResultContent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FormSubmissionResultContent copyWith(void Function(FormSubmissionResultContent) updates) => super.copyWith((message) => updates(message as FormSubmissionResultContent)) as FormSubmissionResultContent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FormSubmissionResultContent create() => FormSubmissionResultContent._();
  FormSubmissionResultContent createEmptyInstance() => create();
  static $pb.PbList<FormSubmissionResultContent> createRepeated() => $pb.PbList<FormSubmissionResultContent>();
  @$core.pragma('dart2js:noInline')
  static FormSubmissionResultContent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FormSubmissionResultContent>(create);
  static FormSubmissionResultContent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get formInstanceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set formInstanceId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFormInstanceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFormInstanceId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get schemaId => $_getSZ(1);
  @$pb.TagNumber(2)
  set schemaId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSchemaId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSchemaId() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get schemaVersion => $_getIZ(2);
  @$pb.TagNumber(3)
  set schemaVersion($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSchemaVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearSchemaVersion() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get sourceEventId => $_getSZ(3);
  @$pb.TagNumber(4)
  set sourceEventId($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSourceEventId() => $_has(3);
  @$pb.TagNumber(4)
  void clearSourceEventId() => clearField(4);

  @$pb.TagNumber(5)
  FormMessageState get state => $_getN(4);
  @$pb.TagNumber(5)
  set state(FormMessageState v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasState() => $_has(4);
  @$pb.TagNumber(5)
  void clearState() => clearField(5);

  @$pb.TagNumber(6)
  $core.bool get reviewConfirmed => $_getBF(5);
  @$pb.TagNumber(6)
  set reviewConfirmed($core.bool v) { $_setBool(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasReviewConfirmed() => $_has(5);
  @$pb.TagNumber(6)
  void clearReviewConfirmed() => clearField(6);

  @$pb.TagNumber(7)
  FormSubmissionSnapshot get submissionSnapshot => $_getN(6);
  @$pb.TagNumber(7)
  set submissionSnapshot(FormSubmissionSnapshot v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasSubmissionSnapshot() => $_has(6);
  @$pb.TagNumber(7)
  void clearSubmissionSnapshot() => clearField(7);
  @$pb.TagNumber(7)
  FormSubmissionSnapshot ensureSubmissionSnapshot() => $_ensure(6);

  @$pb.TagNumber(8)
  $4.Struct get metadata => $_getN(7);
  @$pb.TagNumber(8)
  set metadata($4.Struct v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasMetadata() => $_has(7);
  @$pb.TagNumber(8)
  void clearMetadata() => clearField(8);
  @$pb.TagNumber(8)
  $4.Struct ensureMetadata() => $_ensure(7);
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
  notSet
}

class Payload extends $pb.GeneratedMessage {
  factory Payload({
    PayloadType? type,
    $4.Struct? default_7,
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
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    if (default_7 != null) {
      $result.default_7 = default_7;
    }
    if (roomChange != null) {
      $result.roomChange = roomChange;
    }
    if (moderation != null) {
      $result.moderation = moderation;
    }
    if (text != null) {
      $result.text = text;
    }
    if (attachment != null) {
      $result.attachment = attachment;
    }
    if (reaction != null) {
      $result.reaction = reaction;
    }
    if (encrypted != null) {
      $result.encrypted = encrypted;
    }
    if (call != null) {
      $result.call = call;
    }
    if (motion != null) {
      $result.motion = motion;
    }
    if (vote != null) {
      $result.vote = vote;
    }
    if (motionTally != null) {
      $result.motionTally = motionTally;
    }
    if (voteTally != null) {
      $result.voteTally = voteTally;
    }
    if (formRequest != null) {
      $result.formRequest = formRequest;
    }
    if (formSubmissionResult != null) {
      $result.formSubmissionResult = formSubmissionResult;
    }
    return $result;
  }
  Payload._() : super();
  factory Payload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Payload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, Payload_Data> _Payload_DataByTag = {
    7 : Payload_Data.default_7,
    8 : Payload_Data.roomChange,
    10 : Payload_Data.moderation,
    15 : Payload_Data.text,
    16 : Payload_Data.attachment,
    17 : Payload_Data.reaction,
    18 : Payload_Data.encrypted,
    19 : Payload_Data.call,
    25 : Payload_Data.motion,
    26 : Payload_Data.vote,
    28 : Payload_Data.motionTally,
    29 : Payload_Data.voteTally,
    30 : Payload_Data.formRequest,
    31 : Payload_Data.formSubmissionResult,
    0 : Payload_Data.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Payload', package: const $pb.PackageName(_omitMessageNames ? '' : 'chat.v1'), createEmptyInstance: create)
    ..oo(0, [7, 8, 10, 15, 16, 17, 18, 19, 25, 26, 28, 29, 30, 31])
    ..e<PayloadType>(1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: PayloadType.PAYLOAD_TYPE_UNSPECIFIED, valueOf: PayloadType.valueOf, enumValues: PayloadType.values)
    ..aOM<$4.Struct>(7, _omitFieldNames ? '' : 'default', subBuilder: $4.Struct.create)
    ..aOM<RoomChangeContent>(8, _omitFieldNames ? '' : 'roomChange', subBuilder: RoomChangeContent.create)
    ..aOM<ModerationContent>(10, _omitFieldNames ? '' : 'moderation', subBuilder: ModerationContent.create)
    ..aOM<TextContent>(15, _omitFieldNames ? '' : 'text', subBuilder: TextContent.create)
    ..aOM<AttachmentContent>(16, _omitFieldNames ? '' : 'attachment', subBuilder: AttachmentContent.create)
    ..aOM<ReactionContent>(17, _omitFieldNames ? '' : 'reaction', subBuilder: ReactionContent.create)
    ..aOM<EncryptedContent>(18, _omitFieldNames ? '' : 'encrypted', subBuilder: EncryptedContent.create)
    ..aOM<CallContent>(19, _omitFieldNames ? '' : 'call', subBuilder: CallContent.create)
    ..aOM<MotionContent>(25, _omitFieldNames ? '' : 'motion', subBuilder: MotionContent.create)
    ..aOM<VoteCast>(26, _omitFieldNames ? '' : 'vote', subBuilder: VoteCast.create)
    ..aOM<MotionTally>(28, _omitFieldNames ? '' : 'motionTally', subBuilder: MotionTally.create)
    ..aOM<VoteTally>(29, _omitFieldNames ? '' : 'voteTally', subBuilder: VoteTally.create)
    ..aOM<FormRequestContent>(30, _omitFieldNames ? '' : 'formRequest', subBuilder: FormRequestContent.create)
    ..aOM<FormSubmissionResultContent>(31, _omitFieldNames ? '' : 'formSubmissionResult', subBuilder: FormSubmissionResultContent.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Payload clone() => Payload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Payload copyWith(void Function(Payload) updates) => super.copyWith((message) => updates(message as Payload)) as Payload;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Payload create() => Payload._();
  Payload createEmptyInstance() => create();
  static $pb.PbList<Payload> createRepeated() => $pb.PbList<Payload>();
  @$core.pragma('dart2js:noInline')
  static Payload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Payload>(create);
  static Payload? _defaultInstance;

  Payload_Data whichData() => _Payload_DataByTag[$_whichOneof(0)]!;
  void clearData() => clearField($_whichOneof(0));

  /// The `type` MUST correspond to the populated payload.
  /// Servers MUST reject mismatches.
  @$pb.TagNumber(1)
  PayloadType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(PayloadType v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  /// type = PAYLOAD_TYPE_UNSPECIFIED
  @$pb.TagNumber(7)
  $4.Struct get default_7 => $_getN(1);
  @$pb.TagNumber(7)
  set default_7($4.Struct v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasDefault_7() => $_has(1);
  @$pb.TagNumber(7)
  void clearDefault_7() => clearField(7);
  @$pb.TagNumber(7)
  $4.Struct ensureDefault_7() => $_ensure(1);

  /// type = PAYLOAD_TYPE_ROOM_CHANGE
  @$pb.TagNumber(8)
  RoomChangeContent get roomChange => $_getN(2);
  @$pb.TagNumber(8)
  set roomChange(RoomChangeContent v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasRoomChange() => $_has(2);
  @$pb.TagNumber(8)
  void clearRoomChange() => clearField(8);
  @$pb.TagNumber(8)
  RoomChangeContent ensureRoomChange() => $_ensure(2);

  /// type = PAYLOAD_TYPE_MODERATION
  @$pb.TagNumber(10)
  ModerationContent get moderation => $_getN(3);
  @$pb.TagNumber(10)
  set moderation(ModerationContent v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasModeration() => $_has(3);
  @$pb.TagNumber(10)
  void clearModeration() => clearField(10);
  @$pb.TagNumber(10)
  ModerationContent ensureModeration() => $_ensure(3);

  /// type = PAYLOAD_TYPE_TEXT
  @$pb.TagNumber(15)
  TextContent get text => $_getN(4);
  @$pb.TagNumber(15)
  set text(TextContent v) { setField(15, v); }
  @$pb.TagNumber(15)
  $core.bool hasText() => $_has(4);
  @$pb.TagNumber(15)
  void clearText() => clearField(15);
  @$pb.TagNumber(15)
  TextContent ensureText() => $_ensure(4);

  /// type = PAYLOAD_TYPE_ATTACHMENT
  @$pb.TagNumber(16)
  AttachmentContent get attachment => $_getN(5);
  @$pb.TagNumber(16)
  set attachment(AttachmentContent v) { setField(16, v); }
  @$pb.TagNumber(16)
  $core.bool hasAttachment() => $_has(5);
  @$pb.TagNumber(16)
  void clearAttachment() => clearField(16);
  @$pb.TagNumber(16)
  AttachmentContent ensureAttachment() => $_ensure(5);

  /// type = PAYLOAD_TYPE_REACTION
  @$pb.TagNumber(17)
  ReactionContent get reaction => $_getN(6);
  @$pb.TagNumber(17)
  set reaction(ReactionContent v) { setField(17, v); }
  @$pb.TagNumber(17)
  $core.bool hasReaction() => $_has(6);
  @$pb.TagNumber(17)
  void clearReaction() => clearField(17);
  @$pb.TagNumber(17)
  ReactionContent ensureReaction() => $_ensure(6);

  /// type = PAYLOAD_TYPE_ENCRYPTED
  @$pb.TagNumber(18)
  EncryptedContent get encrypted => $_getN(7);
  @$pb.TagNumber(18)
  set encrypted(EncryptedContent v) { setField(18, v); }
  @$pb.TagNumber(18)
  $core.bool hasEncrypted() => $_has(7);
  @$pb.TagNumber(18)
  void clearEncrypted() => clearField(18);
  @$pb.TagNumber(18)
  EncryptedContent ensureEncrypted() => $_ensure(7);

  /// type = PAYLOAD_TYPE_CALL
  @$pb.TagNumber(19)
  CallContent get call => $_getN(8);
  @$pb.TagNumber(19)
  set call(CallContent v) { setField(19, v); }
  @$pb.TagNumber(19)
  $core.bool hasCall() => $_has(8);
  @$pb.TagNumber(19)
  void clearCall() => clearField(19);
  @$pb.TagNumber(19)
  CallContent ensureCall() => $_ensure(8);

  /// type = PAYLOAD_TYPE_MOTION
  @$pb.TagNumber(25)
  MotionContent get motion => $_getN(9);
  @$pb.TagNumber(25)
  set motion(MotionContent v) { setField(25, v); }
  @$pb.TagNumber(25)
  $core.bool hasMotion() => $_has(9);
  @$pb.TagNumber(25)
  void clearMotion() => clearField(25);
  @$pb.TagNumber(25)
  MotionContent ensureMotion() => $_ensure(9);

  /// type = PAYLOAD_TYPE_VOTE
  @$pb.TagNumber(26)
  VoteCast get vote => $_getN(10);
  @$pb.TagNumber(26)
  set vote(VoteCast v) { setField(26, v); }
  @$pb.TagNumber(26)
  $core.bool hasVote() => $_has(10);
  @$pb.TagNumber(26)
  void clearVote() => clearField(26);
  @$pb.TagNumber(26)
  VoteCast ensureVote() => $_ensure(10);

  /// type = PAYLOAD_TYPE_MOTION_TALLY
  @$pb.TagNumber(28)
  MotionTally get motionTally => $_getN(11);
  @$pb.TagNumber(28)
  set motionTally(MotionTally v) { setField(28, v); }
  @$pb.TagNumber(28)
  $core.bool hasMotionTally() => $_has(11);
  @$pb.TagNumber(28)
  void clearMotionTally() => clearField(28);
  @$pb.TagNumber(28)
  MotionTally ensureMotionTally() => $_ensure(11);

  /// type = PAYLOAD_TYPE_VOTE_TALLY
  @$pb.TagNumber(29)
  VoteTally get voteTally => $_getN(12);
  @$pb.TagNumber(29)
  set voteTally(VoteTally v) { setField(29, v); }
  @$pb.TagNumber(29)
  $core.bool hasVoteTally() => $_has(12);
  @$pb.TagNumber(29)
  void clearVoteTally() => clearField(29);
  @$pb.TagNumber(29)
  VoteTally ensureVoteTally() => $_ensure(12);

  /// type = PAYLOAD_TYPE_FORM_REQUEST
  @$pb.TagNumber(30)
  FormRequestContent get formRequest => $_getN(13);
  @$pb.TagNumber(30)
  set formRequest(FormRequestContent v) { setField(30, v); }
  @$pb.TagNumber(30)
  $core.bool hasFormRequest() => $_has(13);
  @$pb.TagNumber(30)
  void clearFormRequest() => clearField(30);
  @$pb.TagNumber(30)
  FormRequestContent ensureFormRequest() => $_ensure(13);

  /// type = PAYLOAD_TYPE_FORM_SUBMISSION_RESULT
  @$pb.TagNumber(31)
  FormSubmissionResultContent get formSubmissionResult => $_getN(14);
  @$pb.TagNumber(31)
  set formSubmissionResult(FormSubmissionResultContent v) { setField(31, v); }
  @$pb.TagNumber(31)
  $core.bool hasFormSubmissionResult() => $_has(14);
  @$pb.TagNumber(31)
  void clearFormSubmissionResult() => clearField(31);
  @$pb.TagNumber(31)
  FormSubmissionResultContent ensureFormSubmissionResult() => $_ensure(14);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
