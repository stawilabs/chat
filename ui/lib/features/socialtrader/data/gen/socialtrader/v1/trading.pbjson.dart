// This is a generated file - do not edit.
//
// Generated from socialtrader/v1/trading.proto.

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

@$core.Deprecated('Use preparedTxDescriptor instead')
const PreparedTx$json = {
  '1': 'PreparedTx',
  '2': [
    {'1': 'to', '3': 1, '4': 1, '5': 9, '10': 'to'},
    {'1': 'data', '3': 2, '4': 1, '5': 9, '10': 'data'},
    {'1': 'value', '3': 3, '4': 1, '5': 9, '10': 'value'},
    {'1': 'chain_id', '3': 4, '4': 1, '5': 3, '10': 'chainId'},
    {'1': 'description', '3': 5, '4': 1, '5': 9, '10': 'description'},
  ],
};

/// Descriptor for `PreparedTx`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List preparedTxDescriptor = $convert.base64Decode(
    'CgpQcmVwYXJlZFR4Eg4KAnRvGAEgASgJUgJ0bxISCgRkYXRhGAIgASgJUgRkYXRhEhQKBXZhbH'
    'VlGAMgASgJUgV2YWx1ZRIZCghjaGFpbl9pZBgEIAEoA1IHY2hhaW5JZBIgCgtkZXNjcmlwdGlv'
    'bhgFIAEoCVILZGVzY3JpcHRpb24=');

@$core.Deprecated('Use prepareTxRequestDescriptor instead')
const PrepareTxRequest$json = {
  '1': 'PrepareTxRequest',
  '2': [
    {'1': 'intent', '3': 1, '4': 1, '5': 9, '10': 'intent'},
    {
      '1': 'params',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.socialtrader.v1.PrepareTxRequest.ParamsEntry',
      '10': 'params'
    },
  ],
  '3': [PrepareTxRequest_ParamsEntry$json],
};

@$core.Deprecated('Use prepareTxRequestDescriptor instead')
const PrepareTxRequest_ParamsEntry$json = {
  '1': 'ParamsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `PrepareTxRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List prepareTxRequestDescriptor = $convert.base64Decode(
    'ChBQcmVwYXJlVHhSZXF1ZXN0EhYKBmludGVudBgBIAEoCVIGaW50ZW50EkUKBnBhcmFtcxgCIA'
    'MoCzItLnNvY2lhbHRyYWRlci52MS5QcmVwYXJlVHhSZXF1ZXN0LlBhcmFtc0VudHJ5UgZwYXJh'
    'bXMaOQoLUGFyYW1zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbH'
    'VlOgI4AQ==');

@$core.Deprecated('Use getPortfolioRequestDescriptor instead')
const GetPortfolioRequest$json = {
  '1': 'GetPortfolioRequest',
  '2': [
    {'1': 'wallet', '3': 1, '4': 1, '5': 9, '10': 'wallet'},
  ],
};

/// Descriptor for `GetPortfolioRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPortfolioRequestDescriptor =
    $convert.base64Decode(
        'ChNHZXRQb3J0Zm9saW9SZXF1ZXN0EhYKBndhbGxldBgBIAEoCVIGd2FsbGV0');

@$core.Deprecated('Use balanceDescriptor instead')
const Balance$json = {
  '1': 'Balance',
  '2': [
    {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
    {'1': 'symbol', '3': 2, '4': 1, '5': 9, '10': 'symbol'},
    {'1': 'free', '3': 3, '4': 1, '5': 9, '10': 'free'},
    {'1': 'reserved', '3': 4, '4': 1, '5': 9, '10': 'reserved'},
    {'1': 'claimable', '3': 5, '4': 1, '5': 9, '10': 'claimable'},
  ],
};

/// Descriptor for `Balance`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List balanceDescriptor = $convert.base64Decode(
    'CgdCYWxhbmNlEhQKBXRva2VuGAEgASgJUgV0b2tlbhIWCgZzeW1ib2wYAiABKAlSBnN5bWJvbB'
    'ISCgRmcmVlGAMgASgJUgRmcmVlEhoKCHJlc2VydmVkGAQgASgJUghyZXNlcnZlZBIcCgljbGFp'
    'bWFibGUYBSABKAlSCWNsYWltYWJsZQ==');

@$core.Deprecated('Use getPortfolioResponseDescriptor instead')
const GetPortfolioResponse$json = {
  '1': 'GetPortfolioResponse',
  '2': [
    {'1': 'wallet', '3': 1, '4': 1, '5': 9, '10': 'wallet'},
    {
      '1': 'balances',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.socialtrader.v1.Balance',
      '10': 'balances'
    },
  ],
};

/// Descriptor for `GetPortfolioResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPortfolioResponseDescriptor = $convert.base64Decode(
    'ChRHZXRQb3J0Zm9saW9SZXNwb25zZRIWCgZ3YWxsZXQYASABKAlSBndhbGxldBI0CghiYWxhbm'
    'NlcxgCIAMoCzIYLnNvY2lhbHRyYWRlci52MS5CYWxhbmNlUghiYWxhbmNlcw==');

@$core.Deprecated('Use getSolvencyRequestDescriptor instead')
const GetSolvencyRequest$json = {
  '1': 'GetSolvencyRequest',
};

/// Descriptor for `GetSolvencyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSolvencyRequestDescriptor =
    $convert.base64Decode('ChJHZXRTb2x2ZW5jeVJlcXVlc3Q=');

@$core.Deprecated('Use solvencyReportDescriptor instead')
const SolvencyReport$json = {
  '1': 'SolvencyReport',
  '2': [
    {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
    {'1': 'held', '3': 2, '4': 1, '5': 9, '10': 'held'},
    {'1': 'user_liability', '3': 3, '4': 1, '5': 9, '10': 'userLiability'},
    {'1': 'protocol_fees', '3': 4, '4': 1, '5': 9, '10': 'protocolFees'},
    {'1': 'total_owed', '3': 5, '4': 1, '5': 9, '10': 'totalOwed'},
    {'1': 'ok', '3': 6, '4': 1, '5': 8, '10': 'ok'},
    {'1': 'divergence', '3': 7, '4': 1, '5': 9, '10': 'divergence'},
  ],
};

/// Descriptor for `SolvencyReport`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List solvencyReportDescriptor = $convert.base64Decode(
    'Cg5Tb2x2ZW5jeVJlcG9ydBIUCgV0b2tlbhgBIAEoCVIFdG9rZW4SEgoEaGVsZBgCIAEoCVIEaG'
    'VsZBIlCg51c2VyX2xpYWJpbGl0eRgDIAEoCVINdXNlckxpYWJpbGl0eRIjCg1wcm90b2NvbF9m'
    'ZWVzGAQgASgJUgxwcm90b2NvbEZlZXMSHQoKdG90YWxfb3dlZBgFIAEoCVIJdG90YWxPd2VkEg'
    '4KAm9rGAYgASgIUgJvaxIeCgpkaXZlcmdlbmNlGAcgASgJUgpkaXZlcmdlbmNl');

@$core.Deprecated('Use getSolvencyResponseDescriptor instead')
const GetSolvencyResponse$json = {
  '1': 'GetSolvencyResponse',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
    {
      '1': 'tokens',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.socialtrader.v1.SolvencyReport',
      '10': 'tokens'
    },
  ],
};

/// Descriptor for `GetSolvencyResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSolvencyResponseDescriptor = $convert.base64Decode(
    'ChNHZXRTb2x2ZW5jeVJlc3BvbnNlEg4KAm9rGAEgASgIUgJvaxI3CgZ0b2tlbnMYAiADKAsyHy'
    '5zb2NpYWx0cmFkZXIudjEuU29sdmVuY3lSZXBvcnRSBnRva2Vucw==');

const $core.Map<$core.String, $core.dynamic> TradingServiceBase$json = {
  '1': 'TradingService',
  '2': [
    {
      '1': 'PrepareTx',
      '2': '.socialtrader.v1.PrepareTxRequest',
      '3': '.socialtrader.v1.PreparedTx',
      '4': {}
    },
    {
      '1': 'GetPortfolio',
      '2': '.socialtrader.v1.GetPortfolioRequest',
      '3': '.socialtrader.v1.GetPortfolioResponse',
      '4': {'34': 1},
    },
    {
      '1': 'GetSolvency',
      '2': '.socialtrader.v1.GetSolvencyRequest',
      '3': '.socialtrader.v1.GetSolvencyResponse',
      '4': {'34': 1},
    },
  ],
  '3': {},
};

@$core.Deprecated('Use tradingServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    TradingServiceBase$messageJson = {
  '.socialtrader.v1.PrepareTxRequest': PrepareTxRequest$json,
  '.socialtrader.v1.PrepareTxRequest.ParamsEntry':
      PrepareTxRequest_ParamsEntry$json,
  '.socialtrader.v1.PreparedTx': PreparedTx$json,
  '.socialtrader.v1.GetPortfolioRequest': GetPortfolioRequest$json,
  '.socialtrader.v1.GetPortfolioResponse': GetPortfolioResponse$json,
  '.socialtrader.v1.Balance': Balance$json,
  '.socialtrader.v1.GetSolvencyRequest': GetSolvencyRequest$json,
  '.socialtrader.v1.GetSolvencyResponse': GetSolvencyResponse$json,
  '.socialtrader.v1.SolvencyReport': SolvencyReport$json,
};

/// Descriptor for `TradingService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List tradingServiceDescriptor = $convert.base64Decode(
    'Cg5UcmFkaW5nU2VydmljZRLuAQoJUHJlcGFyZVR4EiEuc29jaWFsdHJhZGVyLnYxLlByZXBhcm'
    'VUeFJlcXVlc3QaGy5zb2NpYWx0cmFkZXIudjEuUHJlcGFyZWRUeCKgAbpHhQESFVByZXBhcmUg'
    'YSB0cmFuc2FjdGlvbhpsQnVpbGRzIHVuc2lnbmVkIGNhbGxkYXRhIGZvciBhIHRyYWRpbmcgaW'
    '50ZW50LiBUaGUgd2FsbGV0IHNpZ25zIGFuZCBzZW5kcyBpdDsgdGhlIHNlcnZpY2UgbmV2ZXIg'
    'aG9sZHMgYSBrZXkugrUYEwoPdHJhZGluZ19wcmVwYXJlEAES1QEKDEdldFBvcnRmb2xpbxIkLn'
    'NvY2lhbHRyYWRlci52MS5HZXRQb3J0Zm9saW9SZXF1ZXN0GiUuc29jaWFsdHJhZGVyLnYxLkdl'
    'dFBvcnRmb2xpb1Jlc3BvbnNlIniQAgG6R1sSD1ZhdWx0IHBvcnRmb2xpbxpIRnJlZSwgcmVzZX'
    'J2ZWQgYW5kIGNsYWltYWJsZSBiYWxhbmNlcyBvZiBhIHdhbGxldCBmb3IgZXZlcnkga25vd24g'
    'dG9rZW4ugrUYEwoPdHJhZGluZ19wcmVwYXJlEAEStwEKC0dldFNvbHZlbmN5EiMuc29jaWFsdH'
    'JhZGVyLnYxLkdldFNvbHZlbmN5UmVxdWVzdBokLnNvY2lhbHRyYWRlci52MS5HZXRTb2x2ZW5j'
    'eVJlc3BvbnNlIl2QAgG6R0ASDlZhdWx0IHNvbHZlbmN5Gi5IZWxkIHZlcnN1cyBvd2VkIHBlci'
    'B0b2tlbiBhcyByZWFkIGZyb20gY2hhaW4ugrUYEwoPdHJhZGluZ19wcmVwYXJlEAEaaoK1GGYK'
    'FHNlcnZpY2Vfc29jaWFsdHJhZGVyEg90cmFkaW5nX3ByZXBhcmUaEwgBEg90cmFkaW5nX3ByZX'
    'BhcmUaEwgCEg90cmFkaW5nX3ByZXBhcmUaEwgFEg90cmFkaW5nX3ByZXBhcmU=');
