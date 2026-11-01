// This is a generated file - do not edit.
//
// Generated from socialtrader/v1/pools.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $0;

import 'pools.pbenum.dart';
import 'trading.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'pools.pbenum.dart';

class Pool extends $pb.GeneratedMessage {
  factory Pool({
    $core.String? address,
    $core.String? marketId,
    $core.String? leader,
    $core.String? roomRef,
    $core.String? nav,
    $core.String? navPerShare,
    $core.String? totalShares,
    $core.int? memberCount,
    $core.int? performanceFeeBps,
    $core.int? minLeaderSkinBps,
    $core.String? maxTvlQuote,
    $core.bool? paused,
    $fixnum.Int64? asOfBlock,
    $core.String? tier,
    $core.String? mark,
  }) {
    final result = Pool._();
    if (address != null) result.address = address;
    if (marketId != null) result.marketId = marketId;
    if (leader != null) result.leader = leader;
    if (roomRef != null) result.roomRef = roomRef;
    if (nav != null) result.nav = nav;
    if (navPerShare != null) result.navPerShare = navPerShare;
    if (totalShares != null) result.totalShares = totalShares;
    if (memberCount != null) result.memberCount = memberCount;
    if (performanceFeeBps != null) result.performanceFeeBps = performanceFeeBps;
    if (minLeaderSkinBps != null) result.minLeaderSkinBps = minLeaderSkinBps;
    if (maxTvlQuote != null) result.maxTvlQuote = maxTvlQuote;
    if (paused != null) result.paused = paused;
    if (asOfBlock != null) result.asOfBlock = asOfBlock;
    if (tier != null) result.tier = tier;
    if (mark != null) result.mark = mark;
    return result;
  }

  Pool._();

  factory Pool.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Pool()..mergeFromBuffer(data, registry);
  factory Pool.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Pool()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Pool',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: Pool.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'address')
    ..aOS(2, _omitFieldNames ? '' : 'marketId')
    ..aOS(3, _omitFieldNames ? '' : 'leader')
    ..aOS(4, _omitFieldNames ? '' : 'roomRef')
    ..aOS(5, _omitFieldNames ? '' : 'nav')
    ..aOS(6, _omitFieldNames ? '' : 'navPerShare')
    ..aOS(7, _omitFieldNames ? '' : 'totalShares')
    ..aI(8, _omitFieldNames ? '' : 'memberCount',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(9, _omitFieldNames ? '' : 'performanceFeeBps',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(10, _omitFieldNames ? '' : 'minLeaderSkinBps',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(11, _omitFieldNames ? '' : 'maxTvlQuote')
    ..aOB(12, _omitFieldNames ? '' : 'paused')
    ..a<$fixnum.Int64>(
        13, _omitFieldNames ? '' : 'asOfBlock', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(14, _omitFieldNames ? '' : 'tier')
    ..aOS(15, _omitFieldNames ? '' : 'mark')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Pool clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Pool copyWith(void Function(Pool) updates) =>
      super.copyWith((message) => updates(message as Pool)) as Pool;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Pool() / Pool.new instead')
  static Pool create() => Pool._();
  static $pb.GeneratedMessage $_createMessage() => Pool._();
  @$core.override
  Pool createEmptyInstance() => Pool._();
  @$core.pragma('dart2js:noInline')
  static Pool getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Pool>(Pool.$_createMessage);
  static Pool? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get address => $_getSZ(0);
  @$pb.TagNumber(1)
  set address($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAddress() => $_has(0);
  @$pb.TagNumber(1)
  void clearAddress() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get marketId => $_getSZ(1);
  @$pb.TagNumber(2)
  set marketId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMarketId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMarketId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get leader => $_getSZ(2);
  @$pb.TagNumber(3)
  set leader($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLeader() => $_has(2);
  @$pb.TagNumber(3)
  void clearLeader() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get roomRef => $_getSZ(3);
  @$pb.TagNumber(4)
  set roomRef($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRoomRef() => $_has(3);
  @$pb.TagNumber(4)
  void clearRoomRef() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get nav => $_getSZ(4);
  @$pb.TagNumber(5)
  set nav($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNav() => $_has(4);
  @$pb.TagNumber(5)
  void clearNav() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get navPerShare => $_getSZ(5);
  @$pb.TagNumber(6)
  set navPerShare($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasNavPerShare() => $_has(5);
  @$pb.TagNumber(6)
  void clearNavPerShare() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get totalShares => $_getSZ(6);
  @$pb.TagNumber(7)
  set totalShares($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTotalShares() => $_has(6);
  @$pb.TagNumber(7)
  void clearTotalShares() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get memberCount => $_getIZ(7);
  @$pb.TagNumber(8)
  set memberCount($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMemberCount() => $_has(7);
  @$pb.TagNumber(8)
  void clearMemberCount() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get performanceFeeBps => $_getIZ(8);
  @$pb.TagNumber(9)
  set performanceFeeBps($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPerformanceFeeBps() => $_has(8);
  @$pb.TagNumber(9)
  void clearPerformanceFeeBps() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get minLeaderSkinBps => $_getIZ(9);
  @$pb.TagNumber(10)
  set minLeaderSkinBps($core.int value) => $_setUnsignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasMinLeaderSkinBps() => $_has(9);
  @$pb.TagNumber(10)
  void clearMinLeaderSkinBps() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get maxTvlQuote => $_getSZ(10);
  @$pb.TagNumber(11)
  set maxTvlQuote($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasMaxTvlQuote() => $_has(10);
  @$pb.TagNumber(11)
  void clearMaxTvlQuote() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.bool get paused => $_getBF(11);
  @$pb.TagNumber(12)
  set paused($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasPaused() => $_has(11);
  @$pb.TagNumber(12)
  void clearPaused() => $_clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get asOfBlock => $_getI64(12);
  @$pb.TagNumber(13)
  set asOfBlock($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasAsOfBlock() => $_has(12);
  @$pb.TagNumber(13)
  void clearAsOfBlock() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get tier => $_getSZ(13);
  @$pb.TagNumber(14)
  set tier($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasTier() => $_has(13);
  @$pb.TagNumber(14)
  void clearTier() => $_clearField(14);

  /// The pool's bounded mark (quote per 1e18 base) at the latest snapshot.
  @$pb.TagNumber(15)
  $core.String get mark => $_getSZ(14);
  @$pb.TagNumber(15)
  set mark($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasMark() => $_has(14);
  @$pb.TagNumber(15)
  void clearMark() => $_clearField(15);
}

class ListPoolsRequest extends $pb.GeneratedMessage {
  factory ListPoolsRequest() => ListPoolsRequest._();

  ListPoolsRequest._();

  factory ListPoolsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListPoolsRequest()..mergeFromBuffer(data, registry);
  factory ListPoolsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListPoolsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListPoolsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: ListPoolsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPoolsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPoolsRequest copyWith(void Function(ListPoolsRequest) updates) =>
      super.copyWith((message) => updates(message as ListPoolsRequest))
          as ListPoolsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListPoolsRequest() / ListPoolsRequest.new instead')
  static ListPoolsRequest create() => ListPoolsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListPoolsRequest._();
  @$core.override
  ListPoolsRequest createEmptyInstance() => ListPoolsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListPoolsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListPoolsRequest>(
          ListPoolsRequest.$_createMessage);
  static ListPoolsRequest? _defaultInstance;
}

class ListPoolsResponse extends $pb.GeneratedMessage {
  factory ListPoolsResponse({
    $core.Iterable<Pool>? pools,
  }) {
    final result = ListPoolsResponse._();
    if (pools != null) result.pools.addAll(pools);
    return result;
  }

  ListPoolsResponse._();

  factory ListPoolsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListPoolsResponse()..mergeFromBuffer(data, registry);
  factory ListPoolsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListPoolsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListPoolsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: ListPoolsResponse.$_createMessage)
    ..pPM<Pool>(1, _omitFieldNames ? '' : 'pools',
        subBuilder: Pool.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPoolsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPoolsResponse copyWith(void Function(ListPoolsResponse) updates) =>
      super.copyWith((message) => updates(message as ListPoolsResponse))
          as ListPoolsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListPoolsResponse() / ListPoolsResponse.new instead')
  static ListPoolsResponse create() => ListPoolsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListPoolsResponse._();
  @$core.override
  ListPoolsResponse createEmptyInstance() => ListPoolsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListPoolsResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListPoolsResponse>(
          ListPoolsResponse.$_createMessage);
  static ListPoolsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Pool> get pools => $_getList(0);
}

class GetPoolRequest extends $pb.GeneratedMessage {
  factory GetPoolRequest({
    $core.String? pool,
  }) {
    final result = GetPoolRequest._();
    if (pool != null) result.pool = pool;
    return result;
  }

  GetPoolRequest._();

  factory GetPoolRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPoolRequest()..mergeFromBuffer(data, registry);
  factory GetPoolRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPoolRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetPoolRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: GetPoolRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'pool')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPoolRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPoolRequest copyWith(void Function(GetPoolRequest) updates) =>
      super.copyWith((message) => updates(message as GetPoolRequest))
          as GetPoolRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetPoolRequest() / GetPoolRequest.new instead')
  static GetPoolRequest create() => GetPoolRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetPoolRequest._();
  @$core.override
  GetPoolRequest createEmptyInstance() => GetPoolRequest._();
  @$core.pragma('dart2js:noInline')
  static GetPoolRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetPoolRequest>(
          GetPoolRequest.$_createMessage);
  static GetPoolRequest? _defaultInstance;

  /// Pool address, or the room reference the pool was created with.
  @$pb.TagNumber(1)
  $core.String get pool => $_getSZ(0);
  @$pb.TagNumber(1)
  set pool($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPool() => $_has(0);
  @$pb.TagNumber(1)
  void clearPool() => $_clearField(1);
}

class GetPoolResponse extends $pb.GeneratedMessage {
  factory GetPoolResponse({
    Pool? pool,
  }) {
    final result = GetPoolResponse._();
    if (pool != null) result.pool = pool;
    return result;
  }

  GetPoolResponse._();

  factory GetPoolResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPoolResponse()..mergeFromBuffer(data, registry);
  factory GetPoolResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPoolResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetPoolResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: GetPoolResponse.$_createMessage)
    ..aOM<Pool>(1, _omitFieldNames ? '' : 'pool',
        subBuilder: Pool.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPoolResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPoolResponse copyWith(void Function(GetPoolResponse) updates) =>
      super.copyWith((message) => updates(message as GetPoolResponse))
          as GetPoolResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetPoolResponse() / GetPoolResponse.new instead')
  static GetPoolResponse create() => GetPoolResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetPoolResponse._();
  @$core.override
  GetPoolResponse createEmptyInstance() => GetPoolResponse._();
  @$core.pragma('dart2js:noInline')
  static GetPoolResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetPoolResponse>(
          GetPoolResponse.$_createMessage);
  static GetPoolResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Pool get pool => $_getN(0);
  @$pb.TagNumber(1)
  set pool(Pool value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPool() => $_has(0);
  @$pb.TagNumber(1)
  void clearPool() => $_clearField(1);
  @$pb.TagNumber(1)
  Pool ensurePool() => $_ensure(0);
}

class Membership extends $pb.GeneratedMessage {
  factory Membership({
    $core.String? pool,
    $core.String? wallet,
    $core.String? shares,
    $core.String? shareBps,
    $core.String? valueQuote,
    $core.String? queuedShares,
    $core.String? previewAssets,
    $core.String? previewFee,
  }) {
    final result = Membership._();
    if (pool != null) result.pool = pool;
    if (wallet != null) result.wallet = wallet;
    if (shares != null) result.shares = shares;
    if (shareBps != null) result.shareBps = shareBps;
    if (valueQuote != null) result.valueQuote = valueQuote;
    if (queuedShares != null) result.queuedShares = queuedShares;
    if (previewAssets != null) result.previewAssets = previewAssets;
    if (previewFee != null) result.previewFee = previewFee;
    return result;
  }

  Membership._();

  factory Membership.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Membership()..mergeFromBuffer(data, registry);
  factory Membership.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Membership()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Membership',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: Membership.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'pool')
    ..aOS(2, _omitFieldNames ? '' : 'wallet')
    ..aOS(3, _omitFieldNames ? '' : 'shares')
    ..aOS(4, _omitFieldNames ? '' : 'shareBps')
    ..aOS(5, _omitFieldNames ? '' : 'valueQuote')
    ..aOS(6, _omitFieldNames ? '' : 'queuedShares')
    ..aOS(7, _omitFieldNames ? '' : 'previewAssets')
    ..aOS(8, _omitFieldNames ? '' : 'previewFee')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Membership clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Membership copyWith(void Function(Membership) updates) =>
      super.copyWith((message) => updates(message as Membership)) as Membership;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Membership() / Membership.new instead')
  static Membership create() => Membership._();
  static $pb.GeneratedMessage $_createMessage() => Membership._();
  @$core.override
  Membership createEmptyInstance() => Membership._();
  @$core.pragma('dart2js:noInline')
  static Membership getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Membership>(Membership.$_createMessage);
  static Membership? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get pool => $_getSZ(0);
  @$pb.TagNumber(1)
  set pool($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPool() => $_has(0);
  @$pb.TagNumber(1)
  void clearPool() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get wallet => $_getSZ(1);
  @$pb.TagNumber(2)
  set wallet($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWallet() => $_has(1);
  @$pb.TagNumber(2)
  void clearWallet() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get shares => $_getSZ(2);
  @$pb.TagNumber(3)
  set shares($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasShares() => $_has(2);
  @$pb.TagNumber(3)
  void clearShares() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get shareBps => $_getSZ(3);
  @$pb.TagNumber(4)
  set shareBps($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasShareBps() => $_has(3);
  @$pb.TagNumber(4)
  void clearShareBps() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get valueQuote => $_getSZ(4);
  @$pb.TagNumber(5)
  set valueQuote($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasValueQuote() => $_has(4);
  @$pb.TagNumber(5)
  void clearValueQuote() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get queuedShares => $_getSZ(5);
  @$pb.TagNumber(6)
  set queuedShares($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasQueuedShares() => $_has(5);
  @$pb.TagNumber(6)
  void clearQueuedShares() => $_clearField(6);

  /// What redeeming the full share balance would pay now, from
  /// StrategyPool.previewRedeem at the latest block; empty when shares == 0.
  @$pb.TagNumber(7)
  $core.String get previewAssets => $_getSZ(6);
  @$pb.TagNumber(7)
  set previewAssets($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPreviewAssets() => $_has(6);
  @$pb.TagNumber(7)
  void clearPreviewAssets() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get previewFee => $_getSZ(7);
  @$pb.TagNumber(8)
  set previewFee($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPreviewFee() => $_has(7);
  @$pb.TagNumber(8)
  void clearPreviewFee() => $_clearField(8);
}

class GetMembershipRequest extends $pb.GeneratedMessage {
  factory GetMembershipRequest({
    $core.String? pool,
    $core.String? wallet,
  }) {
    final result = GetMembershipRequest._();
    if (pool != null) result.pool = pool;
    if (wallet != null) result.wallet = wallet;
    return result;
  }

  GetMembershipRequest._();

  factory GetMembershipRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMembershipRequest()..mergeFromBuffer(data, registry);
  factory GetMembershipRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMembershipRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetMembershipRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: GetMembershipRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'pool')
    ..aOS(2, _omitFieldNames ? '' : 'wallet')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMembershipRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMembershipRequest copyWith(void Function(GetMembershipRequest) updates) =>
      super.copyWith((message) => updates(message as GetMembershipRequest))
          as GetMembershipRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetMembershipRequest() / GetMembershipRequest.new instead')
  static GetMembershipRequest create() => GetMembershipRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetMembershipRequest._();
  @$core.override
  GetMembershipRequest createEmptyInstance() => GetMembershipRequest._();
  @$core.pragma('dart2js:noInline')
  static GetMembershipRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetMembershipRequest>(
          GetMembershipRequest.$_createMessage);
  static GetMembershipRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get pool => $_getSZ(0);
  @$pb.TagNumber(1)
  set pool($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPool() => $_has(0);
  @$pb.TagNumber(1)
  void clearPool() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get wallet => $_getSZ(1);
  @$pb.TagNumber(2)
  set wallet($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWallet() => $_has(1);
  @$pb.TagNumber(2)
  void clearWallet() => $_clearField(2);
}

class GetMembershipResponse extends $pb.GeneratedMessage {
  factory GetMembershipResponse({
    Membership? membership,
  }) {
    final result = GetMembershipResponse._();
    if (membership != null) result.membership = membership;
    return result;
  }

  GetMembershipResponse._();

  factory GetMembershipResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMembershipResponse()..mergeFromBuffer(data, registry);
  factory GetMembershipResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMembershipResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetMembershipResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: GetMembershipResponse.$_createMessage)
    ..aOM<Membership>(1, _omitFieldNames ? '' : 'membership',
        subBuilder: Membership.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMembershipResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMembershipResponse copyWith(
          void Function(GetMembershipResponse) updates) =>
      super.copyWith((message) => updates(message as GetMembershipResponse))
          as GetMembershipResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetMembershipResponse() / GetMembershipResponse.new instead')
  static GetMembershipResponse create() => GetMembershipResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetMembershipResponse._();
  @$core.override
  GetMembershipResponse createEmptyInstance() => GetMembershipResponse._();
  @$core.pragma('dart2js:noInline')
  static GetMembershipResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetMembershipResponse>(
          GetMembershipResponse.$_createMessage);
  static GetMembershipResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Membership get membership => $_getN(0);
  @$pb.TagNumber(1)
  set membership(Membership value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMembership() => $_has(0);
  @$pb.TagNumber(1)
  void clearMembership() => $_clearField(1);
  @$pb.TagNumber(1)
  Membership ensureMembership() => $_ensure(0);
}

class NavPoint extends $pb.GeneratedMessage {
  factory NavPoint({
    $fixnum.Int64? block,
    $0.Timestamp? at,
    $core.String? navPerShare,
    $core.String? nav,
  }) {
    final result = NavPoint._();
    if (block != null) result.block = block;
    if (at != null) result.at = at;
    if (navPerShare != null) result.navPerShare = navPerShare;
    if (nav != null) result.nav = nav;
    return result;
  }

  NavPoint._();

  factory NavPoint.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NavPoint()..mergeFromBuffer(data, registry);
  factory NavPoint.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NavPoint()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NavPoint',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: NavPoint.$_createMessage)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'block', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'at',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'navPerShare')
    ..aOS(4, _omitFieldNames ? '' : 'nav')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NavPoint clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NavPoint copyWith(void Function(NavPoint) updates) =>
      super.copyWith((message) => updates(message as NavPoint)) as NavPoint;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use NavPoint() / NavPoint.new instead')
  static NavPoint create() => NavPoint._();
  static $pb.GeneratedMessage $_createMessage() => NavPoint._();
  @$core.override
  NavPoint createEmptyInstance() => NavPoint._();
  @$core.pragma('dart2js:noInline')
  static NavPoint getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NavPoint>(NavPoint.$_createMessage);
  static NavPoint? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get block => $_getI64(0);
  @$pb.TagNumber(1)
  set block($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBlock() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlock() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Timestamp get at => $_getN(1);
  @$pb.TagNumber(2)
  set at($0.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearAt() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureAt() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get navPerShare => $_getSZ(2);
  @$pb.TagNumber(3)
  set navPerShare($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNavPerShare() => $_has(2);
  @$pb.TagNumber(3)
  void clearNavPerShare() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get nav => $_getSZ(3);
  @$pb.TagNumber(4)
  set nav($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNav() => $_has(3);
  @$pb.TagNumber(4)
  void clearNav() => $_clearField(4);
}

class GetPoolPerformanceRequest extends $pb.GeneratedMessage {
  factory GetPoolPerformanceRequest({
    $core.String? pool,
    $fixnum.Int64? fromBlock,
    $core.int? limit,
  }) {
    final result = GetPoolPerformanceRequest._();
    if (pool != null) result.pool = pool;
    if (fromBlock != null) result.fromBlock = fromBlock;
    if (limit != null) result.limit = limit;
    return result;
  }

  GetPoolPerformanceRequest._();

  factory GetPoolPerformanceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPoolPerformanceRequest()..mergeFromBuffer(data, registry);
  factory GetPoolPerformanceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPoolPerformanceRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetPoolPerformanceRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: GetPoolPerformanceRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'pool')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'fromBlock', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(3, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPoolPerformanceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPoolPerformanceRequest copyWith(
          void Function(GetPoolPerformanceRequest) updates) =>
      super.copyWith((message) => updates(message as GetPoolPerformanceRequest))
          as GetPoolPerformanceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetPoolPerformanceRequest() / GetPoolPerformanceRequest.new instead')
  static GetPoolPerformanceRequest create() => GetPoolPerformanceRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetPoolPerformanceRequest._();
  @$core.override
  GetPoolPerformanceRequest createEmptyInstance() =>
      GetPoolPerformanceRequest._();
  @$core.pragma('dart2js:noInline')
  static GetPoolPerformanceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetPoolPerformanceRequest>(
          GetPoolPerformanceRequest.$_createMessage);
  static GetPoolPerformanceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get pool => $_getSZ(0);
  @$pb.TagNumber(1)
  set pool($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPool() => $_has(0);
  @$pb.TagNumber(1)
  void clearPool() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get fromBlock => $_getI64(1);
  @$pb.TagNumber(2)
  set fromBlock($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFromBlock() => $_has(1);
  @$pb.TagNumber(2)
  void clearFromBlock() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);
}

class GetPoolPerformanceResponse extends $pb.GeneratedMessage {
  factory GetPoolPerformanceResponse({
    $core.Iterable<NavPoint>? series,
    $core.String? returnBps,
    $core.String? maxDrawdownBps,
    $fixnum.Int64? asOfBlock,
    $core.String? tier,
    $core.String? formulaVersion,
  }) {
    final result = GetPoolPerformanceResponse._();
    if (series != null) result.series.addAll(series);
    if (returnBps != null) result.returnBps = returnBps;
    if (maxDrawdownBps != null) result.maxDrawdownBps = maxDrawdownBps;
    if (asOfBlock != null) result.asOfBlock = asOfBlock;
    if (tier != null) result.tier = tier;
    if (formulaVersion != null) result.formulaVersion = formulaVersion;
    return result;
  }

  GetPoolPerformanceResponse._();

  factory GetPoolPerformanceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPoolPerformanceResponse()..mergeFromBuffer(data, registry);
  factory GetPoolPerformanceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPoolPerformanceResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetPoolPerformanceResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: GetPoolPerformanceResponse.$_createMessage)
    ..pPM<NavPoint>(1, _omitFieldNames ? '' : 'series',
        subBuilder: NavPoint.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'returnBps')
    ..aOS(3, _omitFieldNames ? '' : 'maxDrawdownBps')
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'asOfBlock', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(5, _omitFieldNames ? '' : 'tier')
    ..aOS(6, _omitFieldNames ? '' : 'formulaVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPoolPerformanceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPoolPerformanceResponse copyWith(
          void Function(GetPoolPerformanceResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetPoolPerformanceResponse))
          as GetPoolPerformanceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetPoolPerformanceResponse() / GetPoolPerformanceResponse.new instead')
  static GetPoolPerformanceResponse create() => GetPoolPerformanceResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetPoolPerformanceResponse._();
  @$core.override
  GetPoolPerformanceResponse createEmptyInstance() =>
      GetPoolPerformanceResponse._();
  @$core.pragma('dart2js:noInline')
  static GetPoolPerformanceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetPoolPerformanceResponse>(
          GetPoolPerformanceResponse.$_createMessage);
  static GetPoolPerformanceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<NavPoint> get series => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get returnBps => $_getSZ(1);
  @$pb.TagNumber(2)
  set returnBps($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReturnBps() => $_has(1);
  @$pb.TagNumber(2)
  void clearReturnBps() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get maxDrawdownBps => $_getSZ(2);
  @$pb.TagNumber(3)
  set maxDrawdownBps($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMaxDrawdownBps() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxDrawdownBps() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get asOfBlock => $_getI64(3);
  @$pb.TagNumber(4)
  set asOfBlock($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAsOfBlock() => $_has(3);
  @$pb.TagNumber(4)
  void clearAsOfBlock() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get tier => $_getSZ(4);
  @$pb.TagNumber(5)
  set tier($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTier() => $_has(4);
  @$pb.TagNumber(5)
  void clearTier() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get formulaVersion => $_getSZ(5);
  @$pb.TagNumber(6)
  set formulaVersion($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasFormulaVersion() => $_has(5);
  @$pb.TagNumber(6)
  void clearFormulaVersion() => $_clearField(6);
}

class Permit extends $pb.GeneratedMessage {
  factory Permit({
    $core.String? deadline,
    $core.int? v,
    $core.String? r,
    $core.String? s,
  }) {
    final result = Permit._();
    if (deadline != null) result.deadline = deadline;
    if (v != null) result.v = v;
    if (r != null) result.r = r;
    if (s != null) result.s = s;
    return result;
  }

  Permit._();

  factory Permit.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Permit()..mergeFromBuffer(data, registry);
  factory Permit.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Permit()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Permit',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: Permit.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'deadline')
    ..aI(2, _omitFieldNames ? '' : 'v', fieldType: $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'r')
    ..aOS(4, _omitFieldNames ? '' : 's')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Permit clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Permit copyWith(void Function(Permit) updates) =>
      super.copyWith((message) => updates(message as Permit)) as Permit;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Permit() / Permit.new instead')
  static Permit create() => Permit._();
  static $pb.GeneratedMessage $_createMessage() => Permit._();
  @$core.override
  Permit createEmptyInstance() => Permit._();
  @$core.pragma('dart2js:noInline')
  static Permit getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Permit>(Permit.$_createMessage);
  static Permit? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deadline => $_getSZ(0);
  @$pb.TagNumber(1)
  set deadline($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeadline() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeadline() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get v => $_getIZ(1);
  @$pb.TagNumber(2)
  set v($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasV() => $_has(1);
  @$pb.TagNumber(2)
  void clearV() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get r => $_getSZ(2);
  @$pb.TagNumber(3)
  set r($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasR() => $_has(2);
  @$pb.TagNumber(3)
  void clearR() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get s => $_getSZ(3);
  @$pb.TagNumber(4)
  set s($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasS() => $_has(3);
  @$pb.TagNumber(4)
  void clearS() => $_clearField(4);
}

class PreparePoolDepositRequest extends $pb.GeneratedMessage {
  factory PreparePoolDepositRequest({
    $core.String? pool,
    $core.String? assets,
    $core.String? receiver,
    Permit? permit,
    $core.String? minShares,
  }) {
    final result = PreparePoolDepositRequest._();
    if (pool != null) result.pool = pool;
    if (assets != null) result.assets = assets;
    if (receiver != null) result.receiver = receiver;
    if (permit != null) result.permit = permit;
    if (minShares != null) result.minShares = minShares;
    return result;
  }

  PreparePoolDepositRequest._();

  factory PreparePoolDepositRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreparePoolDepositRequest()..mergeFromBuffer(data, registry);
  factory PreparePoolDepositRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreparePoolDepositRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreparePoolDepositRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: PreparePoolDepositRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'pool')
    ..aOS(2, _omitFieldNames ? '' : 'assets')
    ..aOS(3, _omitFieldNames ? '' : 'receiver')
    ..aOM<Permit>(4, _omitFieldNames ? '' : 'permit',
        subBuilder: Permit.$_createMessage)
    ..aOS(5, _omitFieldNames ? '' : 'minShares')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreparePoolDepositRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreparePoolDepositRequest copyWith(
          void Function(PreparePoolDepositRequest) updates) =>
      super.copyWith((message) => updates(message as PreparePoolDepositRequest))
          as PreparePoolDepositRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PreparePoolDepositRequest() / PreparePoolDepositRequest.new instead')
  static PreparePoolDepositRequest create() => PreparePoolDepositRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      PreparePoolDepositRequest._();
  @$core.override
  PreparePoolDepositRequest createEmptyInstance() =>
      PreparePoolDepositRequest._();
  @$core.pragma('dart2js:noInline')
  static PreparePoolDepositRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreparePoolDepositRequest>(
          PreparePoolDepositRequest.$_createMessage);
  static PreparePoolDepositRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get pool => $_getSZ(0);
  @$pb.TagNumber(1)
  set pool($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPool() => $_has(0);
  @$pb.TagNumber(1)
  void clearPool() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get assets => $_getSZ(1);
  @$pb.TagNumber(2)
  set assets($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAssets() => $_has(1);
  @$pb.TagNumber(2)
  void clearAssets() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get receiver => $_getSZ(2);
  @$pb.TagNumber(3)
  set receiver($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReceiver() => $_has(2);
  @$pb.TagNumber(3)
  void clearReceiver() => $_clearField(3);

  @$pb.TagNumber(4)
  Permit get permit => $_getN(3);
  @$pb.TagNumber(4)
  set permit(Permit value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPermit() => $_has(3);
  @$pb.TagNumber(4)
  void clearPermit() => $_clearField(4);
  @$pb.TagNumber(4)
  Permit ensurePermit() => $_ensure(3);

  /// Slippage floor: the deposit reverts if it would mint fewer shares. Default "0".
  @$pb.TagNumber(5)
  $core.String get minShares => $_getSZ(4);
  @$pb.TagNumber(5)
  set minShares($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMinShares() => $_has(4);
  @$pb.TagNumber(5)
  void clearMinShares() => $_clearField(5);
}

class PreparePoolRedeemRequest extends $pb.GeneratedMessage {
  factory PreparePoolRedeemRequest({
    $core.String? pool,
    $core.String? shares,
    $core.String? receiver,
    $core.String? minAssets,
  }) {
    final result = PreparePoolRedeemRequest._();
    if (pool != null) result.pool = pool;
    if (shares != null) result.shares = shares;
    if (receiver != null) result.receiver = receiver;
    if (minAssets != null) result.minAssets = minAssets;
    return result;
  }

  PreparePoolRedeemRequest._();

  factory PreparePoolRedeemRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreparePoolRedeemRequest()..mergeFromBuffer(data, registry);
  factory PreparePoolRedeemRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreparePoolRedeemRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreparePoolRedeemRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: PreparePoolRedeemRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'pool')
    ..aOS(2, _omitFieldNames ? '' : 'shares')
    ..aOS(3, _omitFieldNames ? '' : 'receiver')
    ..aOS(4, _omitFieldNames ? '' : 'minAssets')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreparePoolRedeemRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreparePoolRedeemRequest copyWith(
          void Function(PreparePoolRedeemRequest) updates) =>
      super.copyWith((message) => updates(message as PreparePoolRedeemRequest))
          as PreparePoolRedeemRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PreparePoolRedeemRequest() / PreparePoolRedeemRequest.new instead')
  static PreparePoolRedeemRequest create() => PreparePoolRedeemRequest._();
  static $pb.GeneratedMessage $_createMessage() => PreparePoolRedeemRequest._();
  @$core.override
  PreparePoolRedeemRequest createEmptyInstance() =>
      PreparePoolRedeemRequest._();
  @$core.pragma('dart2js:noInline')
  static PreparePoolRedeemRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreparePoolRedeemRequest>(
          PreparePoolRedeemRequest.$_createMessage);
  static PreparePoolRedeemRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get pool => $_getSZ(0);
  @$pb.TagNumber(1)
  set pool($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPool() => $_has(0);
  @$pb.TagNumber(1)
  void clearPool() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get shares => $_getSZ(1);
  @$pb.TagNumber(2)
  set shares($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasShares() => $_has(1);
  @$pb.TagNumber(2)
  void clearShares() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get receiver => $_getSZ(2);
  @$pb.TagNumber(3)
  set receiver($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReceiver() => $_has(2);
  @$pb.TagNumber(3)
  void clearReceiver() => $_clearField(3);

  /// Slippage floor: the redeem reverts if it would pay fewer assets. Default "0".
  @$pb.TagNumber(4)
  $core.String get minAssets => $_getSZ(3);
  @$pb.TagNumber(4)
  set minAssets($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMinAssets() => $_has(3);
  @$pb.TagNumber(4)
  void clearMinAssets() => $_clearField(4);
}

class PrepareLeaderOrderRequest extends $pb.GeneratedMessage {
  factory PrepareLeaderOrderRequest({
    $core.String? pool,
    PrepareLeaderOrderRequest_Kind? kind,
    $core.bool? isBid,
    $core.String? price,
    $core.String? baseAmount,
    $fixnum.Int64? orderId,
    $core.int? maxLevels,
    $core.String? hintPrice,
  }) {
    final result = PrepareLeaderOrderRequest._();
    if (pool != null) result.pool = pool;
    if (kind != null) result.kind = kind;
    if (isBid != null) result.isBid = isBid;
    if (price != null) result.price = price;
    if (baseAmount != null) result.baseAmount = baseAmount;
    if (orderId != null) result.orderId = orderId;
    if (maxLevels != null) result.maxLevels = maxLevels;
    if (hintPrice != null) result.hintPrice = hintPrice;
    return result;
  }

  PrepareLeaderOrderRequest._();

  factory PrepareLeaderOrderRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PrepareLeaderOrderRequest()..mergeFromBuffer(data, registry);
  factory PrepareLeaderOrderRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PrepareLeaderOrderRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrepareLeaderOrderRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: PrepareLeaderOrderRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'pool')
    ..aE<PrepareLeaderOrderRequest_Kind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: PrepareLeaderOrderRequest_Kind.values)
    ..aOB(3, _omitFieldNames ? '' : 'isBid')
    ..aOS(4, _omitFieldNames ? '' : 'price')
    ..aOS(5, _omitFieldNames ? '' : 'baseAmount')
    ..a<$fixnum.Int64>(6, _omitFieldNames ? '' : 'orderId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(7, _omitFieldNames ? '' : 'maxLevels', fieldType: $pb.PbFieldType.OU3)
    ..aOS(8, _omitFieldNames ? '' : 'hintPrice')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrepareLeaderOrderRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrepareLeaderOrderRequest copyWith(
          void Function(PrepareLeaderOrderRequest) updates) =>
      super.copyWith((message) => updates(message as PrepareLeaderOrderRequest))
          as PrepareLeaderOrderRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PrepareLeaderOrderRequest() / PrepareLeaderOrderRequest.new instead')
  static PrepareLeaderOrderRequest create() => PrepareLeaderOrderRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      PrepareLeaderOrderRequest._();
  @$core.override
  PrepareLeaderOrderRequest createEmptyInstance() =>
      PrepareLeaderOrderRequest._();
  @$core.pragma('dart2js:noInline')
  static PrepareLeaderOrderRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PrepareLeaderOrderRequest>(
          PrepareLeaderOrderRequest.$_createMessage);
  static PrepareLeaderOrderRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get pool => $_getSZ(0);
  @$pb.TagNumber(1)
  set pool($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPool() => $_has(0);
  @$pb.TagNumber(1)
  void clearPool() => $_clearField(1);

  @$pb.TagNumber(2)
  PrepareLeaderOrderRequest_Kind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(PrepareLeaderOrderRequest_Kind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get isBid => $_getBF(2);
  @$pb.TagNumber(3)
  set isBid($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsBid() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsBid() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get price => $_getSZ(3);
  @$pb.TagNumber(4)
  set price($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPrice() => $_has(3);
  @$pb.TagNumber(4)
  void clearPrice() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get baseAmount => $_getSZ(4);
  @$pb.TagNumber(5)
  set baseAmount($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBaseAmount() => $_has(4);
  @$pb.TagNumber(5)
  void clearBaseAmount() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get orderId => $_getI64(5);
  @$pb.TagNumber(6)
  set orderId($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasOrderId() => $_has(5);
  @$pb.TagNumber(6)
  void clearOrderId() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get maxLevels => $_getIZ(6);
  @$pb.TagNumber(7)
  set maxLevels($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMaxLevels() => $_has(6);
  @$pb.TagNumber(7)
  void clearMaxLevels() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get hintPrice => $_getSZ(7);
  @$pb.TagNumber(8)
  set hintPrice($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasHintPrice() => $_has(7);
  @$pb.TagNumber(8)
  void clearHintPrice() => $_clearField(8);
}

class CreatePoolRequest extends $pb.GeneratedMessage {
  factory CreatePoolRequest({
    $core.String? roomRef,
    $core.String? marketId,
    $core.int? performanceFeeBps,
    $core.int? minLeaderSkinBps,
    $core.String? maxTvlQuote,
  }) {
    final result = CreatePoolRequest._();
    if (roomRef != null) result.roomRef = roomRef;
    if (marketId != null) result.marketId = marketId;
    if (performanceFeeBps != null) result.performanceFeeBps = performanceFeeBps;
    if (minLeaderSkinBps != null) result.minLeaderSkinBps = minLeaderSkinBps;
    if (maxTvlQuote != null) result.maxTvlQuote = maxTvlQuote;
    return result;
  }

  CreatePoolRequest._();

  factory CreatePoolRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreatePoolRequest()..mergeFromBuffer(data, registry);
  factory CreatePoolRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreatePoolRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreatePoolRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: CreatePoolRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'roomRef')
    ..aOS(2, _omitFieldNames ? '' : 'marketId')
    ..aI(3, _omitFieldNames ? '' : 'performanceFeeBps',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'minLeaderSkinBps',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(5, _omitFieldNames ? '' : 'maxTvlQuote')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreatePoolRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreatePoolRequest copyWith(void Function(CreatePoolRequest) updates) =>
      super.copyWith((message) => updates(message as CreatePoolRequest))
          as CreatePoolRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CreatePoolRequest() / CreatePoolRequest.new instead')
  static CreatePoolRequest create() => CreatePoolRequest._();
  static $pb.GeneratedMessage $_createMessage() => CreatePoolRequest._();
  @$core.override
  CreatePoolRequest createEmptyInstance() => CreatePoolRequest._();
  @$core.pragma('dart2js:noInline')
  static CreatePoolRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreatePoolRequest>(
          CreatePoolRequest.$_createMessage);
  static CreatePoolRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomRef => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomRef($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomRef() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomRef() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get marketId => $_getSZ(1);
  @$pb.TagNumber(2)
  set marketId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMarketId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMarketId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get performanceFeeBps => $_getIZ(2);
  @$pb.TagNumber(3)
  set performanceFeeBps($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPerformanceFeeBps() => $_has(2);
  @$pb.TagNumber(3)
  void clearPerformanceFeeBps() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get minLeaderSkinBps => $_getIZ(3);
  @$pb.TagNumber(4)
  set minLeaderSkinBps($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMinLeaderSkinBps() => $_has(3);
  @$pb.TagNumber(4)
  void clearMinLeaderSkinBps() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get maxTvlQuote => $_getSZ(4);
  @$pb.TagNumber(5)
  set maxTvlQuote($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMaxTvlQuote() => $_has(4);
  @$pb.TagNumber(5)
  void clearMaxTvlQuote() => $_clearField(5);
}

class CreatePoolResponse extends $pb.GeneratedMessage {
  factory CreatePoolResponse({
    $core.String? pool,
    $core.String? txHash,
  }) {
    final result = CreatePoolResponse._();
    if (pool != null) result.pool = pool;
    if (txHash != null) result.txHash = txHash;
    return result;
  }

  CreatePoolResponse._();

  factory CreatePoolResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreatePoolResponse()..mergeFromBuffer(data, registry);
  factory CreatePoolResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreatePoolResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreatePoolResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: CreatePoolResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'pool')
    ..aOS(2, _omitFieldNames ? '' : 'txHash')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreatePoolResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreatePoolResponse copyWith(void Function(CreatePoolResponse) updates) =>
      super.copyWith((message) => updates(message as CreatePoolResponse))
          as CreatePoolResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CreatePoolResponse() / CreatePoolResponse.new instead')
  static CreatePoolResponse create() => CreatePoolResponse._();
  static $pb.GeneratedMessage $_createMessage() => CreatePoolResponse._();
  @$core.override
  CreatePoolResponse createEmptyInstance() => CreatePoolResponse._();
  @$core.pragma('dart2js:noInline')
  static CreatePoolResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreatePoolResponse>(
          CreatePoolResponse.$_createMessage);
  static CreatePoolResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get pool => $_getSZ(0);
  @$pb.TagNumber(1)
  set pool($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPool() => $_has(0);
  @$pb.TagNumber(1)
  void clearPool() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get txHash => $_getSZ(1);
  @$pb.TagNumber(2)
  set txHash($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTxHash() => $_has(1);
  @$pb.TagNumber(2)
  void clearTxHash() => $_clearField(2);
}

/// PoolService reads indexed strategy pools and prepares the calldata that
/// members and leaders sign. Reads and prepares are public: the wallet
/// signature is the authority. CreatePool is the one write the service
/// performs itself, with its pool-creator key, for an authenticated caller.
class PoolServiceApi {
  final $pb.RpcClient _client;

  PoolServiceApi(this._client);

  $async.Future<ListPoolsResponse> listPools(
          $pb.ClientContext? ctx, ListPoolsRequest request) =>
      _client.invoke<ListPoolsResponse>(
          ctx, 'PoolService', 'ListPools', request, ListPoolsResponse());
  $async.Future<GetPoolResponse> getPool(
          $pb.ClientContext? ctx, GetPoolRequest request) =>
      _client.invoke<GetPoolResponse>(
          ctx, 'PoolService', 'GetPool', request, GetPoolResponse());
  $async.Future<GetMembershipResponse> getMembership(
          $pb.ClientContext? ctx, GetMembershipRequest request) =>
      _client.invoke<GetMembershipResponse>(ctx, 'PoolService', 'GetMembership',
          request, GetMembershipResponse());
  $async.Future<GetPoolPerformanceResponse> getPoolPerformance(
          $pb.ClientContext? ctx, GetPoolPerformanceRequest request) =>
      _client.invoke<GetPoolPerformanceResponse>(ctx, 'PoolService',
          'GetPoolPerformance', request, GetPoolPerformanceResponse());
  $async.Future<$1.PreparedTx> preparePoolDeposit(
          $pb.ClientContext? ctx, PreparePoolDepositRequest request) =>
      _client.invoke<$1.PreparedTx>(
          ctx, 'PoolService', 'PreparePoolDeposit', request, $1.PreparedTx());
  $async.Future<$1.PreparedTx> preparePoolRedeem(
          $pb.ClientContext? ctx, PreparePoolRedeemRequest request) =>
      _client.invoke<$1.PreparedTx>(
          ctx, 'PoolService', 'PreparePoolRedeem', request, $1.PreparedTx());
  $async.Future<$1.PreparedTx> prepareLeaderOrder(
          $pb.ClientContext? ctx, PrepareLeaderOrderRequest request) =>
      _client.invoke<$1.PreparedTx>(
          ctx, 'PoolService', 'PrepareLeaderOrder', request, $1.PreparedTx());

  /// Creates a pool for the caller's room with the service's pool-creator key.
  /// The leader is the caller's linked wallet; authenticated callers only.
  $async.Future<CreatePoolResponse> createPool(
          $pb.ClientContext? ctx, CreatePoolRequest request) =>
      _client.invoke<CreatePoolResponse>(
          ctx, 'PoolService', 'CreatePool', request, CreatePoolResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
