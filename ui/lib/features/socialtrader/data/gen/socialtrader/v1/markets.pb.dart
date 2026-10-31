// This is a generated file - do not edit.
//
// Generated from socialtrader/v1/markets.proto.

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

class Market extends $pb.GeneratedMessage {
  factory Market({
    $core.String? id,
    $core.String? symbol,
    $core.String? marketId,
    $core.String? base,
    $core.String? quote,
    $core.String? orderBook,
    $core.String? baseSymbol,
    $core.String? quoteSymbol,
    $core.int? baseDecimals,
    $core.int? quoteDecimals,
    $core.String? lotSize,
    $core.String? minNotional,
    $core.int? takerFeeBps,
    $core.bool? active,
  }) {
    final result = Market._();
    if (id != null) result.id = id;
    if (symbol != null) result.symbol = symbol;
    if (marketId != null) result.marketId = marketId;
    if (base != null) result.base = base;
    if (quote != null) result.quote = quote;
    if (orderBook != null) result.orderBook = orderBook;
    if (baseSymbol != null) result.baseSymbol = baseSymbol;
    if (quoteSymbol != null) result.quoteSymbol = quoteSymbol;
    if (baseDecimals != null) result.baseDecimals = baseDecimals;
    if (quoteDecimals != null) result.quoteDecimals = quoteDecimals;
    if (lotSize != null) result.lotSize = lotSize;
    if (minNotional != null) result.minNotional = minNotional;
    if (takerFeeBps != null) result.takerFeeBps = takerFeeBps;
    if (active != null) result.active = active;
    return result;
  }

  Market._();

  factory Market.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Market()..mergeFromBuffer(data, registry);
  factory Market.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Market()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Market',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: Market.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'symbol')
    ..aOS(3, _omitFieldNames ? '' : 'marketId')
    ..aOS(4, _omitFieldNames ? '' : 'base')
    ..aOS(5, _omitFieldNames ? '' : 'quote')
    ..aOS(6, _omitFieldNames ? '' : 'orderBook')
    ..aOS(7, _omitFieldNames ? '' : 'baseSymbol')
    ..aOS(8, _omitFieldNames ? '' : 'quoteSymbol')
    ..aI(9, _omitFieldNames ? '' : 'baseDecimals',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(10, _omitFieldNames ? '' : 'quoteDecimals',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(11, _omitFieldNames ? '' : 'lotSize')
    ..aOS(12, _omitFieldNames ? '' : 'minNotional')
    ..aI(13, _omitFieldNames ? '' : 'takerFeeBps',
        fieldType: $pb.PbFieldType.OU3)
    ..aOB(14, _omitFieldNames ? '' : 'active')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Market clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Market copyWith(void Function(Market) updates) =>
      super.copyWith((message) => updates(message as Market)) as Market;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Market() / Market.new instead')
  static Market create() => Market._();
  static $pb.GeneratedMessage $_createMessage() => Market._();
  @$core.override
  Market createEmptyInstance() => Market._();
  @$core.pragma('dart2js:noInline')
  static Market getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Market>(Market.$_createMessage);
  static Market? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get symbol => $_getSZ(1);
  @$pb.TagNumber(2)
  set symbol($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSymbol() => $_has(1);
  @$pb.TagNumber(2)
  void clearSymbol() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get marketId => $_getSZ(2);
  @$pb.TagNumber(3)
  set marketId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMarketId() => $_has(2);
  @$pb.TagNumber(3)
  void clearMarketId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get base => $_getSZ(3);
  @$pb.TagNumber(4)
  set base($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBase() => $_has(3);
  @$pb.TagNumber(4)
  void clearBase() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get quote => $_getSZ(4);
  @$pb.TagNumber(5)
  set quote($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasQuote() => $_has(4);
  @$pb.TagNumber(5)
  void clearQuote() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get orderBook => $_getSZ(5);
  @$pb.TagNumber(6)
  set orderBook($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasOrderBook() => $_has(5);
  @$pb.TagNumber(6)
  void clearOrderBook() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get baseSymbol => $_getSZ(6);
  @$pb.TagNumber(7)
  set baseSymbol($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBaseSymbol() => $_has(6);
  @$pb.TagNumber(7)
  void clearBaseSymbol() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get quoteSymbol => $_getSZ(7);
  @$pb.TagNumber(8)
  set quoteSymbol($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasQuoteSymbol() => $_has(7);
  @$pb.TagNumber(8)
  void clearQuoteSymbol() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get baseDecimals => $_getIZ(8);
  @$pb.TagNumber(9)
  set baseDecimals($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasBaseDecimals() => $_has(8);
  @$pb.TagNumber(9)
  void clearBaseDecimals() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get quoteDecimals => $_getIZ(9);
  @$pb.TagNumber(10)
  set quoteDecimals($core.int value) => $_setUnsignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasQuoteDecimals() => $_has(9);
  @$pb.TagNumber(10)
  void clearQuoteDecimals() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get lotSize => $_getSZ(10);
  @$pb.TagNumber(11)
  set lotSize($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasLotSize() => $_has(10);
  @$pb.TagNumber(11)
  void clearLotSize() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get minNotional => $_getSZ(11);
  @$pb.TagNumber(12)
  set minNotional($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasMinNotional() => $_has(11);
  @$pb.TagNumber(12)
  void clearMinNotional() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.int get takerFeeBps => $_getIZ(12);
  @$pb.TagNumber(13)
  set takerFeeBps($core.int value) => $_setUnsignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasTakerFeeBps() => $_has(12);
  @$pb.TagNumber(13)
  void clearTakerFeeBps() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.bool get active => $_getBF(13);
  @$pb.TagNumber(14)
  set active($core.bool value) => $_setBool(13, value);
  @$pb.TagNumber(14)
  $core.bool hasActive() => $_has(13);
  @$pb.TagNumber(14)
  void clearActive() => $_clearField(14);
}

class ListMarketsRequest extends $pb.GeneratedMessage {
  factory ListMarketsRequest() => ListMarketsRequest._();

  ListMarketsRequest._();

  factory ListMarketsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListMarketsRequest()..mergeFromBuffer(data, registry);
  factory ListMarketsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListMarketsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListMarketsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: ListMarketsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMarketsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMarketsRequest copyWith(void Function(ListMarketsRequest) updates) =>
      super.copyWith((message) => updates(message as ListMarketsRequest))
          as ListMarketsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListMarketsRequest() / ListMarketsRequest.new instead')
  static ListMarketsRequest create() => ListMarketsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListMarketsRequest._();
  @$core.override
  ListMarketsRequest createEmptyInstance() => ListMarketsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListMarketsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListMarketsRequest>(
          ListMarketsRequest.$_createMessage);
  static ListMarketsRequest? _defaultInstance;
}

class ListMarketsResponse extends $pb.GeneratedMessage {
  factory ListMarketsResponse({
    $core.Iterable<Market>? markets,
  }) {
    final result = ListMarketsResponse._();
    if (markets != null) result.markets.addAll(markets);
    return result;
  }

  ListMarketsResponse._();

  factory ListMarketsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListMarketsResponse()..mergeFromBuffer(data, registry);
  factory ListMarketsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListMarketsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListMarketsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: ListMarketsResponse.$_createMessage)
    ..pPM<Market>(1, _omitFieldNames ? '' : 'markets',
        subBuilder: Market.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMarketsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMarketsResponse copyWith(void Function(ListMarketsResponse) updates) =>
      super.copyWith((message) => updates(message as ListMarketsResponse))
          as ListMarketsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ListMarketsResponse() / ListMarketsResponse.new instead')
  static ListMarketsResponse create() => ListMarketsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListMarketsResponse._();
  @$core.override
  ListMarketsResponse createEmptyInstance() => ListMarketsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListMarketsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListMarketsResponse>(
          ListMarketsResponse.$_createMessage);
  static ListMarketsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Market> get markets => $_getList(0);
}

class GetBookRequest extends $pb.GeneratedMessage {
  factory GetBookRequest({
    $core.String? marketId,
    $core.int? depth,
  }) {
    final result = GetBookRequest._();
    if (marketId != null) result.marketId = marketId;
    if (depth != null) result.depth = depth;
    return result;
  }

  GetBookRequest._();

  factory GetBookRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetBookRequest()..mergeFromBuffer(data, registry);
  factory GetBookRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetBookRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetBookRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: GetBookRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'marketId')
    ..aI(2, _omitFieldNames ? '' : 'depth', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBookRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBookRequest copyWith(void Function(GetBookRequest) updates) =>
      super.copyWith((message) => updates(message as GetBookRequest))
          as GetBookRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetBookRequest() / GetBookRequest.new instead')
  static GetBookRequest create() => GetBookRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetBookRequest._();
  @$core.override
  GetBookRequest createEmptyInstance() => GetBookRequest._();
  @$core.pragma('dart2js:noInline')
  static GetBookRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetBookRequest>(
          GetBookRequest.$_createMessage);
  static GetBookRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get marketId => $_getSZ(0);
  @$pb.TagNumber(1)
  set marketId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMarketId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMarketId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get depth => $_getIZ(1);
  @$pb.TagNumber(2)
  set depth($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDepth() => $_has(1);
  @$pb.TagNumber(2)
  void clearDepth() => $_clearField(2);
}

class BookLevel extends $pb.GeneratedMessage {
  factory BookLevel({
    $core.String? price,
    $core.String? size,
  }) {
    final result = BookLevel._();
    if (price != null) result.price = price;
    if (size != null) result.size = size;
    return result;
  }

  BookLevel._();

  factory BookLevel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BookLevel()..mergeFromBuffer(data, registry);
  factory BookLevel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BookLevel()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BookLevel',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: BookLevel.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'price')
    ..aOS(2, _omitFieldNames ? '' : 'size')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BookLevel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BookLevel copyWith(void Function(BookLevel) updates) =>
      super.copyWith((message) => updates(message as BookLevel)) as BookLevel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BookLevel() / BookLevel.new instead')
  static BookLevel create() => BookLevel._();
  static $pb.GeneratedMessage $_createMessage() => BookLevel._();
  @$core.override
  BookLevel createEmptyInstance() => BookLevel._();
  @$core.pragma('dart2js:noInline')
  static BookLevel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BookLevel>(BookLevel.$_createMessage);
  static BookLevel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get price => $_getSZ(0);
  @$pb.TagNumber(1)
  set price($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPrice() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrice() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get size => $_getSZ(1);
  @$pb.TagNumber(2)
  set size($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearSize() => $_clearField(2);
}

class GetBookResponse extends $pb.GeneratedMessage {
  factory GetBookResponse({
    $core.Iterable<BookLevel>? bids,
    $core.Iterable<BookLevel>? asks,
    $core.String? lastTradePrice,
    $core.String? bestBid,
    $core.String? bestAsk,
    $fixnum.Int64? asOfBlock,
  }) {
    final result = GetBookResponse._();
    if (bids != null) result.bids.addAll(bids);
    if (asks != null) result.asks.addAll(asks);
    if (lastTradePrice != null) result.lastTradePrice = lastTradePrice;
    if (bestBid != null) result.bestBid = bestBid;
    if (bestAsk != null) result.bestAsk = bestAsk;
    if (asOfBlock != null) result.asOfBlock = asOfBlock;
    return result;
  }

  GetBookResponse._();

  factory GetBookResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetBookResponse()..mergeFromBuffer(data, registry);
  factory GetBookResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetBookResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetBookResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'socialtrader.v1'),
      createEmptyInstance: GetBookResponse.$_createMessage)
    ..pPM<BookLevel>(1, _omitFieldNames ? '' : 'bids',
        subBuilder: BookLevel.$_createMessage)
    ..pPM<BookLevel>(2, _omitFieldNames ? '' : 'asks',
        subBuilder: BookLevel.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'lastTradePrice')
    ..aOS(4, _omitFieldNames ? '' : 'bestBid')
    ..aOS(5, _omitFieldNames ? '' : 'bestAsk')
    ..a<$fixnum.Int64>(
        6, _omitFieldNames ? '' : 'asOfBlock', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBookResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBookResponse copyWith(void Function(GetBookResponse) updates) =>
      super.copyWith((message) => updates(message as GetBookResponse))
          as GetBookResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetBookResponse() / GetBookResponse.new instead')
  static GetBookResponse create() => GetBookResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetBookResponse._();
  @$core.override
  GetBookResponse createEmptyInstance() => GetBookResponse._();
  @$core.pragma('dart2js:noInline')
  static GetBookResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetBookResponse>(
          GetBookResponse.$_createMessage);
  static GetBookResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<BookLevel> get bids => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<BookLevel> get asks => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get lastTradePrice => $_getSZ(2);
  @$pb.TagNumber(3)
  set lastTradePrice($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLastTradePrice() => $_has(2);
  @$pb.TagNumber(3)
  void clearLastTradePrice() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get bestBid => $_getSZ(3);
  @$pb.TagNumber(4)
  set bestBid($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBestBid() => $_has(3);
  @$pb.TagNumber(4)
  void clearBestBid() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get bestAsk => $_getSZ(4);
  @$pb.TagNumber(5)
  set bestAsk($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBestAsk() => $_has(4);
  @$pb.TagNumber(5)
  void clearBestAsk() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get asOfBlock => $_getI64(5);
  @$pb.TagNumber(6)
  set asOfBlock($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAsOfBlock() => $_has(5);
  @$pb.TagNumber(6)
  void clearAsOfBlock() => $_clearField(6);
}

/// MarketService lists the spot markets and reads their order books.
class MarketServiceApi {
  final $pb.RpcClient _client;

  MarketServiceApi(this._client);

  /// Lists the active markets. Public: market data is read by wallets that have no profile.
  $async.Future<ListMarketsResponse> listMarkets(
          $pb.ClientContext? ctx, ListMarketsRequest request) =>
      _client.invoke<ListMarketsResponse>(
          ctx, 'MarketService', 'ListMarkets', request, ListMarketsResponse());

  /// Reads the top of book for a market.
  $async.Future<GetBookResponse> getBook(
          $pb.ClientContext? ctx, GetBookRequest request) =>
      _client.invoke<GetBookResponse>(
          ctx, 'MarketService', 'GetBook', request, GetBookResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
