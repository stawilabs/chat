// This is a generated file - do not edit.
//
// Generated from socialtrader/v1/trading.proto.

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

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// PreparedTx is unsigned calldata for a wallet to sign (non-custodial).
class PreparedTx extends $pb.GeneratedMessage {
  factory PreparedTx({
    $core.String? to,
    $core.String? data,
    $core.String? value,
    $fixnum.Int64? chainId,
    $core.String? description,
  }) {
    final result = PreparedTx._();
    if (to != null) result.to = to;
    if (data != null) result.data = data;
    if (value != null) result.value = value;
    if (chainId != null) result.chainId = chainId;
    if (description != null) result.description = description;
    return result;
  }

  PreparedTx._();

  factory PreparedTx.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreparedTx()..mergeFromBuffer(data, registry);
  factory PreparedTx.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreparedTx()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreparedTx',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: PreparedTx.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'to')
    ..aOS(2, _omitFieldNames ? '' : 'data')
    ..aOS(3, _omitFieldNames ? '' : 'value')
    ..aInt64(4, _omitFieldNames ? '' : 'chainId')
    ..aOS(5, _omitFieldNames ? '' : 'description')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreparedTx clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreparedTx copyWith(void Function(PreparedTx) updates) =>
      super.copyWith((message) => updates(message as PreparedTx)) as PreparedTx;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PreparedTx() / PreparedTx.new instead')
  static PreparedTx create() => PreparedTx._();
  static $pb.GeneratedMessage $_createMessage() => PreparedTx._();
  @$core.override
  PreparedTx createEmptyInstance() => PreparedTx._();
  @$core.pragma('dart2js:noInline')
  static PreparedTx getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreparedTx>(PreparedTx.$_createMessage);
  static PreparedTx? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get to => $_getSZ(0);
  @$pb.TagNumber(1)
  set to($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTo() => $_has(0);
  @$pb.TagNumber(1)
  void clearTo() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get data => $_getSZ(1);
  @$pb.TagNumber(2)
  set data($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get value => $_getSZ(2);
  @$pb.TagNumber(3)
  set value($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearValue() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get chainId => $_getI64(3);
  @$pb.TagNumber(4)
  set chainId($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasChainId() => $_has(3);
  @$pb.TagNumber(4)
  void clearChainId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get description => $_getSZ(4);
  @$pb.TagNumber(5)
  set description($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDescription() => $_has(4);
  @$pb.TagNumber(5)
  void clearDescription() => $_clearField(5);
}

class PrepareTxRequest extends $pb.GeneratedMessage {
  factory PrepareTxRequest({
    $core.String? intent,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? params,
  }) {
    final result = PrepareTxRequest._();
    if (intent != null) result.intent = intent;
    if (params != null) result.params.addEntries(params);
    return result;
  }

  PrepareTxRequest._();

  factory PrepareTxRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PrepareTxRequest()..mergeFromBuffer(data, registry);
  factory PrepareTxRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PrepareTxRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PrepareTxRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: PrepareTxRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'intent')
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'params',
        entryClassName: 'PrepareTxRequest.ParamsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('socialtrader.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrepareTxRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PrepareTxRequest copyWith(void Function(PrepareTxRequest) updates) =>
      super.copyWith((message) => updates(message as PrepareTxRequest))
          as PrepareTxRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PrepareTxRequest() / PrepareTxRequest.new instead')
  static PrepareTxRequest create() => PrepareTxRequest._();
  static $pb.GeneratedMessage $_createMessage() => PrepareTxRequest._();
  @$core.override
  PrepareTxRequest createEmptyInstance() => PrepareTxRequest._();
  @$core.pragma('dart2js:noInline')
  static PrepareTxRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PrepareTxRequest>(
          PrepareTxRequest.$_createMessage);
  static PrepareTxRequest? _defaultInstance;

  /// approve|deposit|withdraw|claim_to_free|place_limit|place_ioc|cancel|mint
  @$pb.TagNumber(1)
  $core.String get intent => $_getSZ(0);
  @$pb.TagNumber(1)
  set intent($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIntent() => $_has(0);
  @$pb.TagNumber(1)
  void clearIntent() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $core.String> get params => $_getMap(1);
}

class GetPortfolioRequest extends $pb.GeneratedMessage {
  factory GetPortfolioRequest({
    $core.String? wallet,
  }) {
    final result = GetPortfolioRequest._();
    if (wallet != null) result.wallet = wallet;
    return result;
  }

  GetPortfolioRequest._();

  factory GetPortfolioRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPortfolioRequest()..mergeFromBuffer(data, registry);
  factory GetPortfolioRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPortfolioRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetPortfolioRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: GetPortfolioRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'wallet')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPortfolioRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPortfolioRequest copyWith(void Function(GetPortfolioRequest) updates) =>
      super.copyWith((message) => updates(message as GetPortfolioRequest))
          as GetPortfolioRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use GetPortfolioRequest() / GetPortfolioRequest.new instead')
  static GetPortfolioRequest create() => GetPortfolioRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetPortfolioRequest._();
  @$core.override
  GetPortfolioRequest createEmptyInstance() => GetPortfolioRequest._();
  @$core.pragma('dart2js:noInline')
  static GetPortfolioRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetPortfolioRequest>(
          GetPortfolioRequest.$_createMessage);
  static GetPortfolioRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get wallet => $_getSZ(0);
  @$pb.TagNumber(1)
  set wallet($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWallet() => $_has(0);
  @$pb.TagNumber(1)
  void clearWallet() => $_clearField(1);
}

class Balance extends $pb.GeneratedMessage {
  factory Balance({
    $core.String? token,
    $core.String? symbol,
    $core.String? free,
    $core.String? reserved,
    $core.String? claimable,
  }) {
    final result = Balance._();
    if (token != null) result.token = token;
    if (symbol != null) result.symbol = symbol;
    if (free != null) result.free = free;
    if (reserved != null) result.reserved = reserved;
    if (claimable != null) result.claimable = claimable;
    return result;
  }

  Balance._();

  factory Balance.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Balance()..mergeFromBuffer(data, registry);
  factory Balance.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Balance()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Balance',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: Balance.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'token')
    ..aOS(2, _omitFieldNames ? '' : 'symbol')
    ..aOS(3, _omitFieldNames ? '' : 'free')
    ..aOS(4, _omitFieldNames ? '' : 'reserved')
    ..aOS(5, _omitFieldNames ? '' : 'claimable')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Balance clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Balance copyWith(void Function(Balance) updates) =>
      super.copyWith((message) => updates(message as Balance)) as Balance;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Balance() / Balance.new instead')
  static Balance create() => Balance._();
  static $pb.GeneratedMessage $_createMessage() => Balance._();
  @$core.override
  Balance createEmptyInstance() => Balance._();
  @$core.pragma('dart2js:noInline')
  static Balance getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Balance>(Balance.$_createMessage);
  static Balance? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get symbol => $_getSZ(1);
  @$pb.TagNumber(2)
  set symbol($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSymbol() => $_has(1);
  @$pb.TagNumber(2)
  void clearSymbol() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get free => $_getSZ(2);
  @$pb.TagNumber(3)
  set free($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFree() => $_has(2);
  @$pb.TagNumber(3)
  void clearFree() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get reserved => $_getSZ(3);
  @$pb.TagNumber(4)
  set reserved($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReserved() => $_has(3);
  @$pb.TagNumber(4)
  void clearReserved() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get claimable => $_getSZ(4);
  @$pb.TagNumber(5)
  set claimable($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasClaimable() => $_has(4);
  @$pb.TagNumber(5)
  void clearClaimable() => $_clearField(5);
}

class GetPortfolioResponse extends $pb.GeneratedMessage {
  factory GetPortfolioResponse({
    $core.String? wallet,
    $core.Iterable<Balance>? balances,
  }) {
    final result = GetPortfolioResponse._();
    if (wallet != null) result.wallet = wallet;
    if (balances != null) result.balances.addAll(balances);
    return result;
  }

  GetPortfolioResponse._();

  factory GetPortfolioResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPortfolioResponse()..mergeFromBuffer(data, registry);
  factory GetPortfolioResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPortfolioResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetPortfolioResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: GetPortfolioResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'wallet')
    ..pPM<Balance>(2, _omitFieldNames ? '' : 'balances',
        subBuilder: Balance.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPortfolioResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPortfolioResponse copyWith(void Function(GetPortfolioResponse) updates) =>
      super.copyWith((message) => updates(message as GetPortfolioResponse))
          as GetPortfolioResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetPortfolioResponse() / GetPortfolioResponse.new instead')
  static GetPortfolioResponse create() => GetPortfolioResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetPortfolioResponse._();
  @$core.override
  GetPortfolioResponse createEmptyInstance() => GetPortfolioResponse._();
  @$core.pragma('dart2js:noInline')
  static GetPortfolioResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetPortfolioResponse>(
          GetPortfolioResponse.$_createMessage);
  static GetPortfolioResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get wallet => $_getSZ(0);
  @$pb.TagNumber(1)
  set wallet($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWallet() => $_has(0);
  @$pb.TagNumber(1)
  void clearWallet() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<Balance> get balances => $_getList(1);
}

class GetSolvencyRequest extends $pb.GeneratedMessage {
  factory GetSolvencyRequest() => GetSolvencyRequest._();

  GetSolvencyRequest._();

  factory GetSolvencyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSolvencyRequest()..mergeFromBuffer(data, registry);
  factory GetSolvencyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSolvencyRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSolvencyRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: GetSolvencyRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSolvencyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSolvencyRequest copyWith(void Function(GetSolvencyRequest) updates) =>
      super.copyWith((message) => updates(message as GetSolvencyRequest))
          as GetSolvencyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetSolvencyRequest() / GetSolvencyRequest.new instead')
  static GetSolvencyRequest create() => GetSolvencyRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetSolvencyRequest._();
  @$core.override
  GetSolvencyRequest createEmptyInstance() => GetSolvencyRequest._();
  @$core.pragma('dart2js:noInline')
  static GetSolvencyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSolvencyRequest>(
          GetSolvencyRequest.$_createMessage);
  static GetSolvencyRequest? _defaultInstance;
}

class SolvencyReport extends $pb.GeneratedMessage {
  factory SolvencyReport({
    $core.String? token,
    $core.String? held,
    $core.String? userLiability,
    $core.String? protocolFees,
    $core.String? totalOwed,
    $core.bool? ok,
    $core.String? divergence,
  }) {
    final result = SolvencyReport._();
    if (token != null) result.token = token;
    if (held != null) result.held = held;
    if (userLiability != null) result.userLiability = userLiability;
    if (protocolFees != null) result.protocolFees = protocolFees;
    if (totalOwed != null) result.totalOwed = totalOwed;
    if (ok != null) result.ok = ok;
    if (divergence != null) result.divergence = divergence;
    return result;
  }

  SolvencyReport._();

  factory SolvencyReport.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SolvencyReport()..mergeFromBuffer(data, registry);
  factory SolvencyReport.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SolvencyReport()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SolvencyReport',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: SolvencyReport.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'token')
    ..aOS(2, _omitFieldNames ? '' : 'held')
    ..aOS(3, _omitFieldNames ? '' : 'userLiability')
    ..aOS(4, _omitFieldNames ? '' : 'protocolFees')
    ..aOS(5, _omitFieldNames ? '' : 'totalOwed')
    ..aOB(6, _omitFieldNames ? '' : 'ok')
    ..aOS(7, _omitFieldNames ? '' : 'divergence')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SolvencyReport clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SolvencyReport copyWith(void Function(SolvencyReport) updates) =>
      super.copyWith((message) => updates(message as SolvencyReport))
          as SolvencyReport;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SolvencyReport() / SolvencyReport.new instead')
  static SolvencyReport create() => SolvencyReport._();
  static $pb.GeneratedMessage $_createMessage() => SolvencyReport._();
  @$core.override
  SolvencyReport createEmptyInstance() => SolvencyReport._();
  @$core.pragma('dart2js:noInline')
  static SolvencyReport getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SolvencyReport>(
          SolvencyReport.$_createMessage);
  static SolvencyReport? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get held => $_getSZ(1);
  @$pb.TagNumber(2)
  set held($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHeld() => $_has(1);
  @$pb.TagNumber(2)
  void clearHeld() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get userLiability => $_getSZ(2);
  @$pb.TagNumber(3)
  set userLiability($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUserLiability() => $_has(2);
  @$pb.TagNumber(3)
  void clearUserLiability() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get protocolFees => $_getSZ(3);
  @$pb.TagNumber(4)
  set protocolFees($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasProtocolFees() => $_has(3);
  @$pb.TagNumber(4)
  void clearProtocolFees() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get totalOwed => $_getSZ(4);
  @$pb.TagNumber(5)
  set totalOwed($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTotalOwed() => $_has(4);
  @$pb.TagNumber(5)
  void clearTotalOwed() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get ok => $_getBF(5);
  @$pb.TagNumber(6)
  set ok($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasOk() => $_has(5);
  @$pb.TagNumber(6)
  void clearOk() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get divergence => $_getSZ(6);
  @$pb.TagNumber(7)
  set divergence($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDivergence() => $_has(6);
  @$pb.TagNumber(7)
  void clearDivergence() => $_clearField(7);
}

class GetSolvencyResponse extends $pb.GeneratedMessage {
  factory GetSolvencyResponse({
    $core.bool? ok,
    $core.Iterable<SolvencyReport>? tokens,
  }) {
    final result = GetSolvencyResponse._();
    if (ok != null) result.ok = ok;
    if (tokens != null) result.tokens.addAll(tokens);
    return result;
  }

  GetSolvencyResponse._();

  factory GetSolvencyResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSolvencyResponse()..mergeFromBuffer(data, registry);
  factory GetSolvencyResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSolvencyResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSolvencyResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: GetSolvencyResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..pPM<SolvencyReport>(2, _omitFieldNames ? '' : 'tokens',
        subBuilder: SolvencyReport.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSolvencyResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSolvencyResponse copyWith(void Function(GetSolvencyResponse) updates) =>
      super.copyWith((message) => updates(message as GetSolvencyResponse))
          as GetSolvencyResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use GetSolvencyResponse() / GetSolvencyResponse.new instead')
  static GetSolvencyResponse create() => GetSolvencyResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetSolvencyResponse._();
  @$core.override
  GetSolvencyResponse createEmptyInstance() => GetSolvencyResponse._();
  @$core.pragma('dart2js:noInline')
  static GetSolvencyResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSolvencyResponse>(
          GetSolvencyResponse.$_createMessage);
  static GetSolvencyResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<SolvencyReport> get tokens => $_getList(1);
}

/// TradingService prepares vault and order calldata for a wallet to sign and
/// reads a wallet's vault portfolio. The wallet signature is the authority, so
/// prepare calls are reachable anonymously.
class TradingServiceApi {
  final $pb.RpcClient _client;

  TradingServiceApi(this._client);

  /// Prepares calldata for one intent: approve, deposit, withdraw, claim_to_free,
  /// place_limit, place_ioc, cancel (and mint on local anvil deployments).
  $async.Future<PreparedTx> prepareTx(
          $pb.ClientContext? ctx, PrepareTxRequest request) =>
      _client.invoke<PreparedTx>(
          ctx, 'TradingService', 'PrepareTx', request, PreparedTx());

  /// Reads a wallet's vault balances per token.
  $async.Future<GetPortfolioResponse> getPortfolio(
          $pb.ClientContext? ctx, GetPortfolioRequest request) =>
      _client.invoke<GetPortfolioResponse>(ctx, 'TradingService',
          'GetPortfolio', request, GetPortfolioResponse());

  /// Compares vault holdings to liabilities for every known token.
  $async.Future<GetSolvencyResponse> getSolvency(
          $pb.ClientContext? ctx, GetSolvencyRequest request) =>
      _client.invoke<GetSolvencyResponse>(
          ctx, 'TradingService', 'GetSolvency', request, GetSolvencyResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
