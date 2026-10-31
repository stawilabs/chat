// This is a generated file - do not edit.
//
// Generated from socialtrader/v1/markets.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use marketDescriptor instead')
const Market$json = {
  '1': 'Market',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'symbol', '3': 2, '4': 1, '5': 9, '10': 'symbol'},
    {'1': 'market_id', '3': 3, '4': 1, '5': 9, '10': 'marketId'},
    {'1': 'base', '3': 4, '4': 1, '5': 9, '10': 'base'},
    {'1': 'quote', '3': 5, '4': 1, '5': 9, '10': 'quote'},
    {'1': 'order_book', '3': 6, '4': 1, '5': 9, '10': 'orderBook'},
    {'1': 'base_symbol', '3': 7, '4': 1, '5': 9, '10': 'baseSymbol'},
    {'1': 'quote_symbol', '3': 8, '4': 1, '5': 9, '10': 'quoteSymbol'},
    {'1': 'base_decimals', '3': 9, '4': 1, '5': 13, '10': 'baseDecimals'},
    {'1': 'quote_decimals', '3': 10, '4': 1, '5': 13, '10': 'quoteDecimals'},
    {'1': 'lot_size', '3': 11, '4': 1, '5': 9, '10': 'lotSize'},
    {'1': 'min_notional', '3': 12, '4': 1, '5': 9, '10': 'minNotional'},
    {'1': 'taker_fee_bps', '3': 13, '4': 1, '5': 13, '10': 'takerFeeBps'},
    {'1': 'active', '3': 14, '4': 1, '5': 8, '10': 'active'},
  ],
};

/// Descriptor for `Market`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List marketDescriptor = $convert.base64Decode(
    'CgZNYXJrZXQSDgoCaWQYASABKAlSAmlkEhYKBnN5bWJvbBgCIAEoCVIGc3ltYm9sEhsKCW1hcm'
    'tldF9pZBgDIAEoCVIIbWFya2V0SWQSEgoEYmFzZRgEIAEoCVIEYmFzZRIUCgVxdW90ZRgFIAEo'
    'CVIFcXVvdGUSHQoKb3JkZXJfYm9vaxgGIAEoCVIJb3JkZXJCb29rEh8KC2Jhc2Vfc3ltYm9sGA'
    'cgASgJUgpiYXNlU3ltYm9sEiEKDHF1b3RlX3N5bWJvbBgIIAEoCVILcXVvdGVTeW1ib2wSIwoN'
    'YmFzZV9kZWNpbWFscxgJIAEoDVIMYmFzZURlY2ltYWxzEiUKDnF1b3RlX2RlY2ltYWxzGAogAS'
    'gNUg1xdW90ZURlY2ltYWxzEhkKCGxvdF9zaXplGAsgASgJUgdsb3RTaXplEiEKDG1pbl9ub3Rp'
    'b25hbBgMIAEoCVILbWluTm90aW9uYWwSIgoNdGFrZXJfZmVlX2JwcxgNIAEoDVILdGFrZXJGZW'
    'VCcHMSFgoGYWN0aXZlGA4gASgIUgZhY3RpdmU=');

@$core.Deprecated('Use listMarketsRequestDescriptor instead')
const ListMarketsRequest$json = {
  '1': 'ListMarketsRequest',
};

/// Descriptor for `ListMarketsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listMarketsRequestDescriptor =
    $convert.base64Decode('ChJMaXN0TWFya2V0c1JlcXVlc3Q=');

@$core.Deprecated('Use listMarketsResponseDescriptor instead')
const ListMarketsResponse$json = {
  '1': 'ListMarketsResponse',
  '2': [
    {
      '1': 'markets',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.socialtrader.v1.Market',
      '10': 'markets'
    },
  ],
};

/// Descriptor for `ListMarketsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listMarketsResponseDescriptor = $convert.base64Decode(
    'ChNMaXN0TWFya2V0c1Jlc3BvbnNlEjEKB21hcmtldHMYASADKAsyFy5zb2NpYWx0cmFkZXIudj'
    'EuTWFya2V0UgdtYXJrZXRz');

@$core.Deprecated('Use getBookRequestDescriptor instead')
const GetBookRequest$json = {
  '1': 'GetBookRequest',
  '2': [
    {'1': 'market_id', '3': 1, '4': 1, '5': 9, '10': 'marketId'},
    {'1': 'depth', '3': 2, '4': 1, '5': 13, '10': 'depth'},
  ],
};

/// Descriptor for `GetBookRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getBookRequestDescriptor = $convert.base64Decode(
    'Cg5HZXRCb29rUmVxdWVzdBIbCgltYXJrZXRfaWQYASABKAlSCG1hcmtldElkEhQKBWRlcHRoGA'
    'IgASgNUgVkZXB0aA==');

@$core.Deprecated('Use bookLevelDescriptor instead')
const BookLevel$json = {
  '1': 'BookLevel',
  '2': [
    {'1': 'price', '3': 1, '4': 1, '5': 9, '10': 'price'},
    {'1': 'size', '3': 2, '4': 1, '5': 9, '10': 'size'},
  ],
};

/// Descriptor for `BookLevel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bookLevelDescriptor = $convert.base64Decode(
    'CglCb29rTGV2ZWwSFAoFcHJpY2UYASABKAlSBXByaWNlEhIKBHNpemUYAiABKAlSBHNpemU=');

@$core.Deprecated('Use getBookResponseDescriptor instead')
const GetBookResponse$json = {
  '1': 'GetBookResponse',
  '2': [
    {
      '1': 'bids',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.socialtrader.v1.BookLevel',
      '10': 'bids'
    },
    {
      '1': 'asks',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.socialtrader.v1.BookLevel',
      '10': 'asks'
    },
    {'1': 'last_trade_price', '3': 3, '4': 1, '5': 9, '10': 'lastTradePrice'},
    {'1': 'best_bid', '3': 4, '4': 1, '5': 9, '10': 'bestBid'},
    {'1': 'best_ask', '3': 5, '4': 1, '5': 9, '10': 'bestAsk'},
    {'1': 'as_of_block', '3': 6, '4': 1, '5': 4, '10': 'asOfBlock'},
  ],
};

/// Descriptor for `GetBookResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getBookResponseDescriptor = $convert.base64Decode(
    'Cg9HZXRCb29rUmVzcG9uc2USLgoEYmlkcxgBIAMoCzIaLnNvY2lhbHRyYWRlci52MS5Cb29rTG'
    'V2ZWxSBGJpZHMSLgoEYXNrcxgCIAMoCzIaLnNvY2lhbHRyYWRlci52MS5Cb29rTGV2ZWxSBGFz'
    'a3MSKAoQbGFzdF90cmFkZV9wcmljZRgDIAEoCVIObGFzdFRyYWRlUHJpY2USGQoIYmVzdF9iaW'
    'QYBCABKAlSB2Jlc3RCaWQSGQoIYmVzdF9hc2sYBSABKAlSB2Jlc3RBc2sSHgoLYXNfb2ZfYmxv'
    'Y2sYBiABKARSCWFzT2ZCbG9jaw==');

const $core.Map<$core.String, $core.dynamic> MarketServiceBase$json = {
  '1': 'MarketService',
  '2': [
    {
      '1': 'ListMarkets',
      '2': '.socialtrader.v1.ListMarketsRequest',
      '3': '.socialtrader.v1.ListMarketsResponse',
      '4': {'34': 1},
    },
    {
      '1': 'GetBook',
      '2': '.socialtrader.v1.GetBookRequest',
      '3': '.socialtrader.v1.GetBookResponse',
      '4': {'34': 1},
    },
  ],
  '3': {},
};

@$core.Deprecated('Use marketServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    MarketServiceBase$messageJson = {
  '.socialtrader.v1.ListMarketsRequest': ListMarketsRequest$json,
  '.socialtrader.v1.ListMarketsResponse': ListMarketsResponse$json,
  '.socialtrader.v1.Market': Market$json,
  '.socialtrader.v1.GetBookRequest': GetBookRequest$json,
  '.socialtrader.v1.GetBookResponse': GetBookResponse$json,
  '.socialtrader.v1.BookLevel': BookLevel$json,
};

/// Descriptor for `MarketService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List marketServiceDescriptor = $convert.base64Decode(
    'Cg1NYXJrZXRTZXJ2aWNlEtMBCgtMaXN0TWFya2V0cxIjLnNvY2lhbHRyYWRlci52MS5MaXN0TW'
    'Fya2V0c1JlcXVlc3QaJC5zb2NpYWx0cmFkZXIudjEuTGlzdE1hcmtldHNSZXNwb25zZSJ5kAIB'
    'ukdgEgxMaXN0IG1hcmtldHMaUFJldHVybnMgZXZlcnkgYWN0aXZlIHNwb3QgbWFya2V0IHdpdG'
    'ggaXRzIHRva2VuIG1ldGFkYXRhIGFuZCBvcmRlciBib29rIGFkZHJlc3MugrUYDwoLbWFya2V0'
    'X3ZpZXcQARLAAQoHR2V0Qm9vaxIfLnNvY2lhbHRyYWRlci52MS5HZXRCb29rUmVxdWVzdBogLn'
    'NvY2lhbHRyYWRlci52MS5HZXRCb29rUmVzcG9uc2UicpACAbpHWRIKT3JkZXIgYm9vaxpLVG9w'
    'IG9mIGJvb2sgcmVhZCBmcm9tIGNoYWluIGFzIG9mIGEgYmxvY2s7IG5ldmVyIGEgY2FjaGVkIG'
    '9yIGVtcHR5IHN1Y2Nlc3MugrUYDwoLbWFya2V0X3ZpZXcQARprgrUYZwoUc2VydmljZV9zb2Np'
    'YWx0cmFkZXISC21hcmtldF92aWV3Gg8IARILbWFya2V0X3ZpZXcaDwgCEgttYXJrZXRfdmlldx'
    'oPCAUSC21hcmtldF92aWV3Gg8IBBILbWFya2V0X3ZpZXc=');
