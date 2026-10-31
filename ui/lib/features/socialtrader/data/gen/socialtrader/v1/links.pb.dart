// This is a generated file - do not edit.
//
// Generated from socialtrader/v1/links.proto.

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

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class IssueNonceRequest extends $pb.GeneratedMessage {
  factory IssueNonceRequest() => IssueNonceRequest._();

  IssueNonceRequest._();

  factory IssueNonceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IssueNonceRequest()..mergeFromBuffer(data, registry);
  factory IssueNonceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IssueNonceRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IssueNonceRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: IssueNonceRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IssueNonceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IssueNonceRequest copyWith(void Function(IssueNonceRequest) updates) =>
      super.copyWith((message) => updates(message as IssueNonceRequest))
          as IssueNonceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use IssueNonceRequest() / IssueNonceRequest.new instead')
  static IssueNonceRequest create() => IssueNonceRequest._();
  static $pb.GeneratedMessage $_createMessage() => IssueNonceRequest._();
  @$core.override
  IssueNonceRequest createEmptyInstance() => IssueNonceRequest._();
  @$core.pragma('dart2js:noInline')
  static IssueNonceRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<IssueNonceRequest>(
          IssueNonceRequest.$_createMessage);
  static IssueNonceRequest? _defaultInstance;
}

class IssueNonceResponse extends $pb.GeneratedMessage {
  factory IssueNonceResponse({
    $core.String? nonce,
    $0.Timestamp? expiresAt,
    $core.String? message,
  }) {
    final result = IssueNonceResponse._();
    if (nonce != null) result.nonce = nonce;
    if (expiresAt != null) result.expiresAt = expiresAt;
    if (message != null) result.message = message;
    return result;
  }

  IssueNonceResponse._();

  factory IssueNonceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IssueNonceResponse()..mergeFromBuffer(data, registry);
  factory IssueNonceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IssueNonceResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IssueNonceResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: IssueNonceResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'nonce')
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'expiresAt',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IssueNonceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IssueNonceResponse copyWith(void Function(IssueNonceResponse) updates) =>
      super.copyWith((message) => updates(message as IssueNonceResponse))
          as IssueNonceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use IssueNonceResponse() / IssueNonceResponse.new instead')
  static IssueNonceResponse create() => IssueNonceResponse._();
  static $pb.GeneratedMessage $_createMessage() => IssueNonceResponse._();
  @$core.override
  IssueNonceResponse createEmptyInstance() => IssueNonceResponse._();
  @$core.pragma('dart2js:noInline')
  static IssueNonceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IssueNonceResponse>(
          IssueNonceResponse.$_createMessage);
  static IssueNonceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get nonce => $_getSZ(0);
  @$pb.TagNumber(1)
  set nonce($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNonce() => $_has(0);
  @$pb.TagNumber(1)
  void clearNonce() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Timestamp get expiresAt => $_getN(1);
  @$pb.TagNumber(2)
  set expiresAt($0.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasExpiresAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpiresAt() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureExpiresAt() => $_ensure(1);

  /// Full SIWE text to sign.
  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);
}

class LinkWalletRequest extends $pb.GeneratedMessage {
  factory LinkWalletRequest({
    $core.String? wallet,
    $core.String? signature,
  }) {
    final result = LinkWalletRequest._();
    if (wallet != null) result.wallet = wallet;
    if (signature != null) result.signature = signature;
    return result;
  }

  LinkWalletRequest._();

  factory LinkWalletRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LinkWalletRequest()..mergeFromBuffer(data, registry);
  factory LinkWalletRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LinkWalletRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LinkWalletRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: LinkWalletRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'wallet')
    ..aOS(2, _omitFieldNames ? '' : 'signature')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LinkWalletRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LinkWalletRequest copyWith(void Function(LinkWalletRequest) updates) =>
      super.copyWith((message) => updates(message as LinkWalletRequest))
          as LinkWalletRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LinkWalletRequest() / LinkWalletRequest.new instead')
  static LinkWalletRequest create() => LinkWalletRequest._();
  static $pb.GeneratedMessage $_createMessage() => LinkWalletRequest._();
  @$core.override
  LinkWalletRequest createEmptyInstance() => LinkWalletRequest._();
  @$core.pragma('dart2js:noInline')
  static LinkWalletRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LinkWalletRequest>(
          LinkWalletRequest.$_createMessage);
  static LinkWalletRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get wallet => $_getSZ(0);
  @$pb.TagNumber(1)
  set wallet($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWallet() => $_has(0);
  @$pb.TagNumber(1)
  void clearWallet() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get signature => $_getSZ(1);
  @$pb.TagNumber(2)
  set signature($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSignature() => $_has(1);
  @$pb.TagNumber(2)
  void clearSignature() => $_clearField(2);
}

class LinkWalletResponse extends $pb.GeneratedMessage {
  factory LinkWalletResponse({
    $core.String? profileId,
    $core.String? wallet,
    $0.Timestamp? linkedAt,
  }) {
    final result = LinkWalletResponse._();
    if (profileId != null) result.profileId = profileId;
    if (wallet != null) result.wallet = wallet;
    if (linkedAt != null) result.linkedAt = linkedAt;
    return result;
  }

  LinkWalletResponse._();

  factory LinkWalletResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LinkWalletResponse()..mergeFromBuffer(data, registry);
  factory LinkWalletResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LinkWalletResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LinkWalletResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: LinkWalletResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'profileId')
    ..aOS(2, _omitFieldNames ? '' : 'wallet')
    ..aOM<$0.Timestamp>(3, _omitFieldNames ? '' : 'linkedAt',
        subBuilder: $0.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LinkWalletResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LinkWalletResponse copyWith(void Function(LinkWalletResponse) updates) =>
      super.copyWith((message) => updates(message as LinkWalletResponse))
          as LinkWalletResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LinkWalletResponse() / LinkWalletResponse.new instead')
  static LinkWalletResponse create() => LinkWalletResponse._();
  static $pb.GeneratedMessage $_createMessage() => LinkWalletResponse._();
  @$core.override
  LinkWalletResponse createEmptyInstance() => LinkWalletResponse._();
  @$core.pragma('dart2js:noInline')
  static LinkWalletResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LinkWalletResponse>(
          LinkWalletResponse.$_createMessage);
  static LinkWalletResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get profileId => $_getSZ(0);
  @$pb.TagNumber(1)
  set profileId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProfileId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProfileId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get wallet => $_getSZ(1);
  @$pb.TagNumber(2)
  set wallet($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWallet() => $_has(1);
  @$pb.TagNumber(2)
  void clearWallet() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.Timestamp get linkedAt => $_getN(2);
  @$pb.TagNumber(3)
  set linkedAt($0.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasLinkedAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearLinkedAt() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Timestamp ensureLinkedAt() => $_ensure(2);
}

class GetLinkedWalletRequest extends $pb.GeneratedMessage {
  factory GetLinkedWalletRequest() => GetLinkedWalletRequest._();

  GetLinkedWalletRequest._();

  factory GetLinkedWalletRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetLinkedWalletRequest()..mergeFromBuffer(data, registry);
  factory GetLinkedWalletRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetLinkedWalletRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetLinkedWalletRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: GetLinkedWalletRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLinkedWalletRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLinkedWalletRequest copyWith(
          void Function(GetLinkedWalletRequest) updates) =>
      super.copyWith((message) => updates(message as GetLinkedWalletRequest))
          as GetLinkedWalletRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetLinkedWalletRequest() / GetLinkedWalletRequest.new instead')
  static GetLinkedWalletRequest create() => GetLinkedWalletRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetLinkedWalletRequest._();
  @$core.override
  GetLinkedWalletRequest createEmptyInstance() => GetLinkedWalletRequest._();
  @$core.pragma('dart2js:noInline')
  static GetLinkedWalletRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetLinkedWalletRequest>(
          GetLinkedWalletRequest.$_createMessage);
  static GetLinkedWalletRequest? _defaultInstance;
}

class GetLinkedWalletResponse extends $pb.GeneratedMessage {
  factory GetLinkedWalletResponse({
    $core.String? wallet,
    $0.Timestamp? linkedAt,
  }) {
    final result = GetLinkedWalletResponse._();
    if (wallet != null) result.wallet = wallet;
    if (linkedAt != null) result.linkedAt = linkedAt;
    return result;
  }

  GetLinkedWalletResponse._();

  factory GetLinkedWalletResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetLinkedWalletResponse()..mergeFromBuffer(data, registry);
  factory GetLinkedWalletResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetLinkedWalletResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetLinkedWalletResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: GetLinkedWalletResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'wallet')
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'linkedAt',
        subBuilder: $0.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLinkedWalletResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLinkedWalletResponse copyWith(
          void Function(GetLinkedWalletResponse) updates) =>
      super.copyWith((message) => updates(message as GetLinkedWalletResponse))
          as GetLinkedWalletResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetLinkedWalletResponse() / GetLinkedWalletResponse.new instead')
  static GetLinkedWalletResponse create() => GetLinkedWalletResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetLinkedWalletResponse._();
  @$core.override
  GetLinkedWalletResponse createEmptyInstance() => GetLinkedWalletResponse._();
  @$core.pragma('dart2js:noInline')
  static GetLinkedWalletResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetLinkedWalletResponse>(
          GetLinkedWalletResponse.$_createMessage);
  static GetLinkedWalletResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get wallet => $_getSZ(0);
  @$pb.TagNumber(1)
  set wallet($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWallet() => $_has(0);
  @$pb.TagNumber(1)
  void clearWallet() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Timestamp get linkedAt => $_getN(1);
  @$pb.TagNumber(2)
  set linkedAt($0.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasLinkedAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearLinkedAt() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureLinkedAt() => $_ensure(1);
}

/// LinkService binds a wallet to the caller's profile with a Sign-In with
/// Ethereum (EIP-4361) signature over a server nonce. Authenticated only: the
/// profile comes from the caller's claims.
class LinkServiceApi {
  final $pb.RpcClient _client;

  LinkServiceApi(this._client);

  $async.Future<IssueNonceResponse> issueNonce(
          $pb.ClientContext? ctx, IssueNonceRequest request) =>
      _client.invoke<IssueNonceResponse>(
          ctx, 'LinkService', 'IssueNonce', request, IssueNonceResponse());
  $async.Future<LinkWalletResponse> linkWallet(
          $pb.ClientContext? ctx, LinkWalletRequest request) =>
      _client.invoke<LinkWalletResponse>(
          ctx, 'LinkService', 'LinkWallet', request, LinkWalletResponse());
  $async.Future<GetLinkedWalletResponse> getLinkedWallet(
          $pb.ClientContext? ctx, GetLinkedWalletRequest request) =>
      _client.invoke<GetLinkedWalletResponse>(ctx, 'LinkService',
          'GetLinkedWallet', request, GetLinkedWalletResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
