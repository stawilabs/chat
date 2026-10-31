// This is a generated file - do not edit.
//
// Generated from socialtrader/v1/pools.proto.

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

import 'package:protobuf/well_known_types/google/protobuf/timestamp.pbjson.dart'
    as $0;

import 'trading.pbjson.dart' as $1;

@$core.Deprecated('Use poolDescriptor instead')
const Pool$json = {
  '1': 'Pool',
  '2': [
    {'1': 'address', '3': 1, '4': 1, '5': 9, '10': 'address'},
    {'1': 'market_id', '3': 2, '4': 1, '5': 9, '10': 'marketId'},
    {'1': 'leader', '3': 3, '4': 1, '5': 9, '10': 'leader'},
    {'1': 'room_ref', '3': 4, '4': 1, '5': 9, '10': 'roomRef'},
    {'1': 'nav', '3': 5, '4': 1, '5': 9, '10': 'nav'},
    {'1': 'nav_per_share', '3': 6, '4': 1, '5': 9, '10': 'navPerShare'},
    {'1': 'total_shares', '3': 7, '4': 1, '5': 9, '10': 'totalShares'},
    {'1': 'member_count', '3': 8, '4': 1, '5': 13, '10': 'memberCount'},
    {
      '1': 'performance_fee_bps',
      '3': 9,
      '4': 1,
      '5': 13,
      '10': 'performanceFeeBps'
    },
    {
      '1': 'min_leader_skin_bps',
      '3': 10,
      '4': 1,
      '5': 13,
      '10': 'minLeaderSkinBps'
    },
    {'1': 'max_tvl_quote', '3': 11, '4': 1, '5': 9, '10': 'maxTvlQuote'},
    {'1': 'paused', '3': 12, '4': 1, '5': 8, '10': 'paused'},
    {'1': 'as_of_block', '3': 13, '4': 1, '5': 4, '10': 'asOfBlock'},
    {'1': 'tier', '3': 14, '4': 1, '5': 9, '10': 'tier'},
  ],
};

/// Descriptor for `Pool`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List poolDescriptor = $convert.base64Decode(
    'CgRQb29sEhgKB2FkZHJlc3MYASABKAlSB2FkZHJlc3MSGwoJbWFya2V0X2lkGAIgASgJUghtYX'
    'JrZXRJZBIWCgZsZWFkZXIYAyABKAlSBmxlYWRlchIZCghyb29tX3JlZhgEIAEoCVIHcm9vbVJl'
    'ZhIQCgNuYXYYBSABKAlSA25hdhIiCg1uYXZfcGVyX3NoYXJlGAYgASgJUgtuYXZQZXJTaGFyZR'
    'IhCgx0b3RhbF9zaGFyZXMYByABKAlSC3RvdGFsU2hhcmVzEiEKDG1lbWJlcl9jb3VudBgIIAEo'
    'DVILbWVtYmVyQ291bnQSLgoTcGVyZm9ybWFuY2VfZmVlX2JwcxgJIAEoDVIRcGVyZm9ybWFuY2'
    'VGZWVCcHMSLQoTbWluX2xlYWRlcl9za2luX2JwcxgKIAEoDVIQbWluTGVhZGVyU2tpbkJwcxIi'
    'Cg1tYXhfdHZsX3F1b3RlGAsgASgJUgttYXhUdmxRdW90ZRIWCgZwYXVzZWQYDCABKAhSBnBhdX'
    'NlZBIeCgthc19vZl9ibG9jaxgNIAEoBFIJYXNPZkJsb2NrEhIKBHRpZXIYDiABKAlSBHRpZXI=');

@$core.Deprecated('Use listPoolsRequestDescriptor instead')
const ListPoolsRequest$json = {
  '1': 'ListPoolsRequest',
};

/// Descriptor for `ListPoolsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listPoolsRequestDescriptor =
    $convert.base64Decode('ChBMaXN0UG9vbHNSZXF1ZXN0');

@$core.Deprecated('Use listPoolsResponseDescriptor instead')
const ListPoolsResponse$json = {
  '1': 'ListPoolsResponse',
  '2': [
    {
      '1': 'pools',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.socialtrader.v1.Pool',
      '10': 'pools'
    },
  ],
};

/// Descriptor for `ListPoolsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listPoolsResponseDescriptor = $convert.base64Decode(
    'ChFMaXN0UG9vbHNSZXNwb25zZRIrCgVwb29scxgBIAMoCzIVLnNvY2lhbHRyYWRlci52MS5Qb2'
    '9sUgVwb29scw==');

@$core.Deprecated('Use getPoolRequestDescriptor instead')
const GetPoolRequest$json = {
  '1': 'GetPoolRequest',
  '2': [
    {'1': 'pool', '3': 1, '4': 1, '5': 9, '10': 'pool'},
  ],
};

/// Descriptor for `GetPoolRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPoolRequestDescriptor =
    $convert.base64Decode('Cg5HZXRQb29sUmVxdWVzdBISCgRwb29sGAEgASgJUgRwb29s');

@$core.Deprecated('Use getPoolResponseDescriptor instead')
const GetPoolResponse$json = {
  '1': 'GetPoolResponse',
  '2': [
    {
      '1': 'pool',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.socialtrader.v1.Pool',
      '10': 'pool'
    },
  ],
};

/// Descriptor for `GetPoolResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPoolResponseDescriptor = $convert.base64Decode(
    'Cg9HZXRQb29sUmVzcG9uc2USKQoEcG9vbBgBIAEoCzIVLnNvY2lhbHRyYWRlci52MS5Qb29sUg'
    'Rwb29s');

@$core.Deprecated('Use membershipDescriptor instead')
const Membership$json = {
  '1': 'Membership',
  '2': [
    {'1': 'pool', '3': 1, '4': 1, '5': 9, '10': 'pool'},
    {'1': 'wallet', '3': 2, '4': 1, '5': 9, '10': 'wallet'},
    {'1': 'shares', '3': 3, '4': 1, '5': 9, '10': 'shares'},
    {'1': 'share_bps', '3': 4, '4': 1, '5': 9, '10': 'shareBps'},
    {'1': 'value_quote', '3': 5, '4': 1, '5': 9, '10': 'valueQuote'},
    {'1': 'queued_shares', '3': 6, '4': 1, '5': 9, '10': 'queuedShares'},
  ],
};

/// Descriptor for `Membership`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List membershipDescriptor = $convert.base64Decode(
    'CgpNZW1iZXJzaGlwEhIKBHBvb2wYASABKAlSBHBvb2wSFgoGd2FsbGV0GAIgASgJUgZ3YWxsZX'
    'QSFgoGc2hhcmVzGAMgASgJUgZzaGFyZXMSGwoJc2hhcmVfYnBzGAQgASgJUghzaGFyZUJwcxIf'
    'Cgt2YWx1ZV9xdW90ZRgFIAEoCVIKdmFsdWVRdW90ZRIjCg1xdWV1ZWRfc2hhcmVzGAYgASgJUg'
    'xxdWV1ZWRTaGFyZXM=');

@$core.Deprecated('Use getMembershipRequestDescriptor instead')
const GetMembershipRequest$json = {
  '1': 'GetMembershipRequest',
  '2': [
    {'1': 'pool', '3': 1, '4': 1, '5': 9, '10': 'pool'},
    {'1': 'wallet', '3': 2, '4': 1, '5': 9, '10': 'wallet'},
  ],
};

/// Descriptor for `GetMembershipRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMembershipRequestDescriptor = $convert.base64Decode(
    'ChRHZXRNZW1iZXJzaGlwUmVxdWVzdBISCgRwb29sGAEgASgJUgRwb29sEhYKBndhbGxldBgCIA'
    'EoCVIGd2FsbGV0');

@$core.Deprecated('Use getMembershipResponseDescriptor instead')
const GetMembershipResponse$json = {
  '1': 'GetMembershipResponse',
  '2': [
    {
      '1': 'membership',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.socialtrader.v1.Membership',
      '10': 'membership'
    },
  ],
};

/// Descriptor for `GetMembershipResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMembershipResponseDescriptor = $convert.base64Decode(
    'ChVHZXRNZW1iZXJzaGlwUmVzcG9uc2USOwoKbWVtYmVyc2hpcBgBIAEoCzIbLnNvY2lhbHRyYW'
    'Rlci52MS5NZW1iZXJzaGlwUgptZW1iZXJzaGlw');

@$core.Deprecated('Use navPointDescriptor instead')
const NavPoint$json = {
  '1': 'NavPoint',
  '2': [
    {'1': 'block', '3': 1, '4': 1, '5': 4, '10': 'block'},
    {
      '1': 'at',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'at'
    },
    {'1': 'nav_per_share', '3': 3, '4': 1, '5': 9, '10': 'navPerShare'},
    {'1': 'nav', '3': 4, '4': 1, '5': 9, '10': 'nav'},
  ],
};

/// Descriptor for `NavPoint`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List navPointDescriptor = $convert.base64Decode(
    'CghOYXZQb2ludBIUCgVibG9jaxgBIAEoBFIFYmxvY2sSKgoCYXQYAiABKAsyGi5nb29nbGUucH'
    'JvdG9idWYuVGltZXN0YW1wUgJhdBIiCg1uYXZfcGVyX3NoYXJlGAMgASgJUgtuYXZQZXJTaGFy'
    'ZRIQCgNuYXYYBCABKAlSA25hdg==');

@$core.Deprecated('Use getPoolPerformanceRequestDescriptor instead')
const GetPoolPerformanceRequest$json = {
  '1': 'GetPoolPerformanceRequest',
  '2': [
    {'1': 'pool', '3': 1, '4': 1, '5': 9, '10': 'pool'},
    {'1': 'from_block', '3': 2, '4': 1, '5': 4, '10': 'fromBlock'},
    {'1': 'limit', '3': 3, '4': 1, '5': 13, '10': 'limit'},
  ],
};

/// Descriptor for `GetPoolPerformanceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPoolPerformanceRequestDescriptor =
    $convert.base64Decode(
        'ChlHZXRQb29sUGVyZm9ybWFuY2VSZXF1ZXN0EhIKBHBvb2wYASABKAlSBHBvb2wSHQoKZnJvbV'
        '9ibG9jaxgCIAEoBFIJZnJvbUJsb2NrEhQKBWxpbWl0GAMgASgNUgVsaW1pdA==');

@$core.Deprecated('Use getPoolPerformanceResponseDescriptor instead')
const GetPoolPerformanceResponse$json = {
  '1': 'GetPoolPerformanceResponse',
  '2': [
    {
      '1': 'series',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.socialtrader.v1.NavPoint',
      '10': 'series'
    },
    {'1': 'return_bps', '3': 2, '4': 1, '5': 9, '10': 'returnBps'},
    {'1': 'max_drawdown_bps', '3': 3, '4': 1, '5': 9, '10': 'maxDrawdownBps'},
    {'1': 'as_of_block', '3': 4, '4': 1, '5': 4, '10': 'asOfBlock'},
    {'1': 'tier', '3': 5, '4': 1, '5': 9, '10': 'tier'},
    {'1': 'formula_version', '3': 6, '4': 1, '5': 9, '10': 'formulaVersion'},
  ],
};

/// Descriptor for `GetPoolPerformanceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPoolPerformanceResponseDescriptor = $convert.base64Decode(
    'ChpHZXRQb29sUGVyZm9ybWFuY2VSZXNwb25zZRIxCgZzZXJpZXMYASADKAsyGS5zb2NpYWx0cm'
    'FkZXIudjEuTmF2UG9pbnRSBnNlcmllcxIdCgpyZXR1cm5fYnBzGAIgASgJUglyZXR1cm5CcHMS'
    'KAoQbWF4X2RyYXdkb3duX2JwcxgDIAEoCVIObWF4RHJhd2Rvd25CcHMSHgoLYXNfb2ZfYmxvY2'
    'sYBCABKARSCWFzT2ZCbG9jaxISCgR0aWVyGAUgASgJUgR0aWVyEicKD2Zvcm11bGFfdmVyc2lv'
    'bhgGIAEoCVIOZm9ybXVsYVZlcnNpb24=');

@$core.Deprecated('Use permitDescriptor instead')
const Permit$json = {
  '1': 'Permit',
  '2': [
    {'1': 'deadline', '3': 1, '4': 1, '5': 9, '10': 'deadline'},
    {'1': 'v', '3': 2, '4': 1, '5': 13, '10': 'v'},
    {'1': 'r', '3': 3, '4': 1, '5': 9, '10': 'r'},
    {'1': 's', '3': 4, '4': 1, '5': 9, '10': 's'},
  ],
};

/// Descriptor for `Permit`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List permitDescriptor = $convert.base64Decode(
    'CgZQZXJtaXQSGgoIZGVhZGxpbmUYASABKAlSCGRlYWRsaW5lEgwKAXYYAiABKA1SAXYSDAoBch'
    'gDIAEoCVIBchIMCgFzGAQgASgJUgFz');

@$core.Deprecated('Use preparePoolDepositRequestDescriptor instead')
const PreparePoolDepositRequest$json = {
  '1': 'PreparePoolDepositRequest',
  '2': [
    {'1': 'pool', '3': 1, '4': 1, '5': 9, '10': 'pool'},
    {'1': 'assets', '3': 2, '4': 1, '5': 9, '10': 'assets'},
    {'1': 'receiver', '3': 3, '4': 1, '5': 9, '10': 'receiver'},
    {
      '1': 'permit',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.socialtrader.v1.Permit',
      '10': 'permit'
    },
  ],
};

/// Descriptor for `PreparePoolDepositRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List preparePoolDepositRequestDescriptor = $convert.base64Decode(
    'ChlQcmVwYXJlUG9vbERlcG9zaXRSZXF1ZXN0EhIKBHBvb2wYASABKAlSBHBvb2wSFgoGYXNzZX'
    'RzGAIgASgJUgZhc3NldHMSGgoIcmVjZWl2ZXIYAyABKAlSCHJlY2VpdmVyEi8KBnBlcm1pdBgE'
    'IAEoCzIXLnNvY2lhbHRyYWRlci52MS5QZXJtaXRSBnBlcm1pdA==');

@$core.Deprecated('Use preparePoolRedeemRequestDescriptor instead')
const PreparePoolRedeemRequest$json = {
  '1': 'PreparePoolRedeemRequest',
  '2': [
    {'1': 'pool', '3': 1, '4': 1, '5': 9, '10': 'pool'},
    {'1': 'shares', '3': 2, '4': 1, '5': 9, '10': 'shares'},
    {'1': 'receiver', '3': 3, '4': 1, '5': 9, '10': 'receiver'},
  ],
};

/// Descriptor for `PreparePoolRedeemRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List preparePoolRedeemRequestDescriptor =
    $convert.base64Decode(
        'ChhQcmVwYXJlUG9vbFJlZGVlbVJlcXVlc3QSEgoEcG9vbBgBIAEoCVIEcG9vbBIWCgZzaGFyZX'
        'MYAiABKAlSBnNoYXJlcxIaCghyZWNlaXZlchgDIAEoCVIIcmVjZWl2ZXI=');

@$core.Deprecated('Use prepareLeaderOrderRequestDescriptor instead')
const PrepareLeaderOrderRequest$json = {
  '1': 'PrepareLeaderOrderRequest',
  '2': [
    {'1': 'pool', '3': 1, '4': 1, '5': 9, '10': 'pool'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.socialtrader.v1.PrepareLeaderOrderRequest.Kind',
      '10': 'kind'
    },
    {'1': 'is_bid', '3': 3, '4': 1, '5': 8, '10': 'isBid'},
    {'1': 'price', '3': 4, '4': 1, '5': 9, '10': 'price'},
    {'1': 'base_amount', '3': 5, '4': 1, '5': 9, '10': 'baseAmount'},
    {'1': 'order_id', '3': 6, '4': 1, '5': 4, '10': 'orderId'},
    {'1': 'max_levels', '3': 7, '4': 1, '5': 13, '10': 'maxLevels'},
    {'1': 'hint_price', '3': 8, '4': 1, '5': 9, '10': 'hintPrice'},
  ],
  '4': [PrepareLeaderOrderRequest_Kind$json],
};

@$core.Deprecated('Use prepareLeaderOrderRequestDescriptor instead')
const PrepareLeaderOrderRequest_Kind$json = {
  '1': 'Kind',
  '2': [
    {'1': 'KIND_UNSPECIFIED', '2': 0},
    {'1': 'KIND_LIMIT', '2': 1},
    {'1': 'KIND_IOC', '2': 2},
    {'1': 'KIND_CANCEL', '2': 3},
    {'1': 'KIND_CLAIM', '2': 4},
    {'1': 'KIND_SELL_FOR_REDEEMS', '2': 5},
  ],
};

/// Descriptor for `PrepareLeaderOrderRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List prepareLeaderOrderRequestDescriptor = $convert.base64Decode(
    'ChlQcmVwYXJlTGVhZGVyT3JkZXJSZXF1ZXN0EhIKBHBvb2wYASABKAlSBHBvb2wSQwoEa2luZB'
    'gCIAEoDjIvLnNvY2lhbHRyYWRlci52MS5QcmVwYXJlTGVhZGVyT3JkZXJSZXF1ZXN0LktpbmRS'
    'BGtpbmQSFQoGaXNfYmlkGAMgASgIUgVpc0JpZBIUCgVwcmljZRgEIAEoCVIFcHJpY2USHwoLYm'
    'FzZV9hbW91bnQYBSABKAlSCmJhc2VBbW91bnQSGQoIb3JkZXJfaWQYBiABKARSB29yZGVySWQS'
    'HQoKbWF4X2xldmVscxgHIAEoDVIJbWF4TGV2ZWxzEh0KCmhpbnRfcHJpY2UYCCABKAlSCWhpbn'
    'RQcmljZSJ2CgRLaW5kEhQKEEtJTkRfVU5TUEVDSUZJRUQQABIOCgpLSU5EX0xJTUlUEAESDAoI'
    'S0lORF9JT0MQAhIPCgtLSU5EX0NBTkNFTBADEg4KCktJTkRfQ0xBSU0QBBIZChVLSU5EX1NFTE'
    'xfRk9SX1JFREVFTVMQBQ==');

@$core.Deprecated('Use createPoolRequestDescriptor instead')
const CreatePoolRequest$json = {
  '1': 'CreatePoolRequest',
  '2': [
    {'1': 'room_ref', '3': 1, '4': 1, '5': 9, '10': 'roomRef'},
    {'1': 'market_id', '3': 2, '4': 1, '5': 9, '10': 'marketId'},
    {
      '1': 'performance_fee_bps',
      '3': 3,
      '4': 1,
      '5': 13,
      '10': 'performanceFeeBps'
    },
    {
      '1': 'min_leader_skin_bps',
      '3': 4,
      '4': 1,
      '5': 13,
      '10': 'minLeaderSkinBps'
    },
    {'1': 'max_tvl_quote', '3': 5, '4': 1, '5': 9, '10': 'maxTvlQuote'},
  ],
};

/// Descriptor for `CreatePoolRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createPoolRequestDescriptor = $convert.base64Decode(
    'ChFDcmVhdGVQb29sUmVxdWVzdBIZCghyb29tX3JlZhgBIAEoCVIHcm9vbVJlZhIbCgltYXJrZX'
    'RfaWQYAiABKAlSCG1hcmtldElkEi4KE3BlcmZvcm1hbmNlX2ZlZV9icHMYAyABKA1SEXBlcmZv'
    'cm1hbmNlRmVlQnBzEi0KE21pbl9sZWFkZXJfc2tpbl9icHMYBCABKA1SEG1pbkxlYWRlclNraW'
    '5CcHMSIgoNbWF4X3R2bF9xdW90ZRgFIAEoCVILbWF4VHZsUXVvdGU=');

@$core.Deprecated('Use createPoolResponseDescriptor instead')
const CreatePoolResponse$json = {
  '1': 'CreatePoolResponse',
  '2': [
    {'1': 'pool', '3': 1, '4': 1, '5': 9, '10': 'pool'},
    {'1': 'tx_hash', '3': 2, '4': 1, '5': 9, '10': 'txHash'},
  ],
};

/// Descriptor for `CreatePoolResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createPoolResponseDescriptor = $convert.base64Decode(
    'ChJDcmVhdGVQb29sUmVzcG9uc2USEgoEcG9vbBgBIAEoCVIEcG9vbBIXCgd0eF9oYXNoGAIgAS'
    'gJUgZ0eEhhc2g=');

const $core.Map<$core.String, $core.dynamic> PoolServiceBase$json = {
  '1': 'PoolService',
  '2': [
    {
      '1': 'ListPools',
      '2': '.socialtrader.v1.ListPoolsRequest',
      '3': '.socialtrader.v1.ListPoolsResponse',
      '4': {'34': 1},
    },
    {
      '1': 'GetPool',
      '2': '.socialtrader.v1.GetPoolRequest',
      '3': '.socialtrader.v1.GetPoolResponse',
      '4': {'34': 1},
    },
    {
      '1': 'GetMembership',
      '2': '.socialtrader.v1.GetMembershipRequest',
      '3': '.socialtrader.v1.GetMembershipResponse',
      '4': {'34': 1},
    },
    {
      '1': 'GetPoolPerformance',
      '2': '.socialtrader.v1.GetPoolPerformanceRequest',
      '3': '.socialtrader.v1.GetPoolPerformanceResponse',
      '4': {'34': 1},
    },
    {
      '1': 'PreparePoolDeposit',
      '2': '.socialtrader.v1.PreparePoolDepositRequest',
      '3': '.socialtrader.v1.PreparedTx',
      '4': {}
    },
    {
      '1': 'PreparePoolRedeem',
      '2': '.socialtrader.v1.PreparePoolRedeemRequest',
      '3': '.socialtrader.v1.PreparedTx',
      '4': {}
    },
    {
      '1': 'PrepareLeaderOrder',
      '2': '.socialtrader.v1.PrepareLeaderOrderRequest',
      '3': '.socialtrader.v1.PreparedTx',
      '4': {}
    },
    {
      '1': 'CreatePool',
      '2': '.socialtrader.v1.CreatePoolRequest',
      '3': '.socialtrader.v1.CreatePoolResponse',
      '4': {}
    },
  ],
  '3': {},
};

@$core.Deprecated('Use poolServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    PoolServiceBase$messageJson = {
  '.socialtrader.v1.ListPoolsRequest': ListPoolsRequest$json,
  '.socialtrader.v1.ListPoolsResponse': ListPoolsResponse$json,
  '.socialtrader.v1.Pool': Pool$json,
  '.socialtrader.v1.GetPoolRequest': GetPoolRequest$json,
  '.socialtrader.v1.GetPoolResponse': GetPoolResponse$json,
  '.socialtrader.v1.GetMembershipRequest': GetMembershipRequest$json,
  '.socialtrader.v1.GetMembershipResponse': GetMembershipResponse$json,
  '.socialtrader.v1.Membership': Membership$json,
  '.socialtrader.v1.GetPoolPerformanceRequest': GetPoolPerformanceRequest$json,
  '.socialtrader.v1.GetPoolPerformanceResponse':
      GetPoolPerformanceResponse$json,
  '.socialtrader.v1.NavPoint': NavPoint$json,
  '.google.protobuf.Timestamp': $0.Timestamp$json,
  '.socialtrader.v1.PreparePoolDepositRequest': PreparePoolDepositRequest$json,
  '.socialtrader.v1.Permit': Permit$json,
  '.socialtrader.v1.PreparedTx': $1.PreparedTx$json,
  '.socialtrader.v1.PreparePoolRedeemRequest': PreparePoolRedeemRequest$json,
  '.socialtrader.v1.PrepareLeaderOrderRequest': PrepareLeaderOrderRequest$json,
  '.socialtrader.v1.CreatePoolRequest': CreatePoolRequest$json,
  '.socialtrader.v1.CreatePoolResponse': CreatePoolResponse$json,
};

/// Descriptor for `PoolService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List poolServiceDescriptor = $convert.base64Decode(
    'CgtQb29sU2VydmljZRKpAQoJTGlzdFBvb2xzEiEuc29jaWFsdHJhZGVyLnYxLkxpc3RQb29sc1'
    'JlcXVlc3QaIi5zb2NpYWx0cmFkZXIudjEuTGlzdFBvb2xzUmVzcG9uc2UiVZACAbpHPhIKTGlz'
    'dCBwb29scxowRXZlcnkgaW5kZXhlZCBwb29sIHdpdGggaXRzIGxhdGVzdCBOQVYgc25hcHNob3'
    'QugrUYDQoJcG9vbF92aWV3EAESlwEKB0dldFBvb2wSHy5zb2NpYWx0cmFkZXIudjEuR2V0UG9v'
    'bFJlcXVlc3QaIC5zb2NpYWx0cmFkZXIudjEuR2V0UG9vbFJlc3BvbnNlIkmQAgG6RzISCEdldC'
    'Bwb29sGiZPbmUgcG9vbCBieSBhZGRyZXNzIG9yIHJvb20gcmVmZXJlbmNlLoK1GA0KCXBvb2xf'
    'dmlldxABEsEBCg1HZXRNZW1iZXJzaGlwEiUuc29jaWFsdHJhZGVyLnYxLkdldE1lbWJlcnNoaX'
    'BSZXF1ZXN0GiYuc29jaWFsdHJhZGVyLnYxLkdldE1lbWJlcnNoaXBSZXNwb25zZSJhkAIBukdK'
    'Eg5HZXQgbWVtYmVyc2hpcBo4QSB3YWxsZXQncyBzaGFyZXMsIHNoYXJlIG9mIHRoZSBwb29sIG'
    'FuZCBxdWV1ZWQgcmVkZWVtcy6CtRgNCglwb29sX3ZpZXcQARLzAQoSR2V0UG9vbFBlcmZvcm1h'
    'bmNlEiouc29jaWFsdHJhZGVyLnYxLkdldFBvb2xQZXJmb3JtYW5jZVJlcXVlc3QaKy5zb2NpYW'
    'x0cmFkZXIudjEuR2V0UG9vbFBlcmZvcm1hbmNlUmVzcG9uc2UigwGQAgG6R2wSEFBvb2wgcGVy'
    'Zm9ybWFuY2UaWE5BViBwZXIgc2hhcmUgc2VyaWVzIGRlcml2ZWQgb25seSBmcm9tIGluZGV4ZW'
    'QgY2hhaW4gZXZlbnRzLCB3aXRoIGl0cyB2ZXJpZmljYXRpb24gdGllci6CtRgNCglwb29sX3Zp'
    'ZXcQARLjAQoSUHJlcGFyZVBvb2xEZXBvc2l0Eiouc29jaWFsdHJhZGVyLnYxLlByZXBhcmVQb2'
    '9sRGVwb3NpdFJlcXVlc3QaGy5zb2NpYWx0cmFkZXIudjEuUHJlcGFyZWRUeCKDAbpHbBIWUHJl'
    'cGFyZSBhIHBvb2wgZGVwb3NpdBpSQ2FsbGRhdGEgZm9yIFN0cmF0ZWd5UG9vbC5kZXBvc2l0LC'
    'BvciBkZXBvc2l0V2l0aFBlcm1pdCB3aGVuIGEgcGVybWl0IGlzIHN1cHBsaWVkLoK1GBAKDHBv'
    'b2xfcHJlcGFyZRABEq4BChFQcmVwYXJlUG9vbFJlZGVlbRIpLnNvY2lhbHRyYWRlci52MS5Qcm'
    'VwYXJlUG9vbFJlZGVlbVJlcXVlc3QaGy5zb2NpYWx0cmFkZXIudjEuUHJlcGFyZWRUeCJRukc6'
    'EhVQcmVwYXJlIGEgcG9vbCByZWRlZW0aIUNhbGxkYXRhIGZvciBTdHJhdGVneVBvb2wucmVkZW'
    'VtLoK1GBAKDHBvb2xfcHJlcGFyZRABEukBChJQcmVwYXJlTGVhZGVyT3JkZXISKi5zb2NpYWx0'
    'cmFkZXIudjEuUHJlcGFyZUxlYWRlck9yZGVyUmVxdWVzdBobLnNvY2lhbHRyYWRlci52MS5Qcm'
    'VwYXJlZFR4IokBukdyEhZQcmVwYXJlIGEgbGVhZGVyIG9yZGVyGlhDYWxsZGF0YSBmb3IgdGhl'
    'IHBvb2wncyBsZWFkZXItb25seSB0cmFkaW5nIGZ1bmN0aW9ucy4gVGhlIGNvbnRyYWN0IGVuZm'
    '9yY2VzIG9ubHlMZWFkZXIugrUYEAoMcG9vbF9wcmVwYXJlEAES3AEKCkNyZWF0ZVBvb2wSIi5z'
    'b2NpYWx0cmFkZXIudjEuQ3JlYXRlUG9vbFJlcXVlc3QaIy5zb2NpYWx0cmFkZXIudjEuQ3JlYX'
    'RlUG9vbFJlc3BvbnNlIoQBukdwEg1DcmVhdGUgYSBwb29sGl9TZW5kcyBQb29sRmFjdG9yeS5j'
    'cmVhdGVQb29sIHdpdGggdGhlIHNlcnZpY2UncyBQT09MX0NSRUFUT1JfUk9MRSBrZXkgYW5kIH'
    'JldHVybnMgdGhlIG5ldyBwb29sLoK1GA0KC3Bvb2xfY3JlYXRlGs4BgrUYyQEKFHNlcnZpY2Vf'
    'c29jaWFsdHJhZGVyEglwb29sX3ZpZXcSDHBvb2xfcHJlcGFyZRILcG9vbF9jcmVhdGUaKAgBEg'
    'lwb29sX3ZpZXcSDHBvb2xfcHJlcGFyZRILcG9vbF9jcmVhdGUaKAgCEglwb29sX3ZpZXcSDHBv'
    'b2xfcHJlcGFyZRILcG9vbF9jcmVhdGUaKAgFEglwb29sX3ZpZXcSDHBvb2xfcHJlcGFyZRILcG'
    '9vbF9jcmVhdGUaDQgEEglwb29sX3ZpZXc=');
