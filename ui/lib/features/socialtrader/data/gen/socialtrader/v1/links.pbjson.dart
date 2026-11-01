// This is a generated file - do not edit.
//
// Generated from socialtrader/v1/links.proto.

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

@$core.Deprecated('Use issueNonceRequestDescriptor instead')
const IssueNonceRequest$json = {
  '1': 'IssueNonceRequest',
  '2': [
    {'1': 'wallet', '3': 1, '4': 1, '5': 9, '10': 'wallet'},
  ],
};

/// Descriptor for `IssueNonceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List issueNonceRequestDescriptor = $convert.base64Decode(
    'ChFJc3N1ZU5vbmNlUmVxdWVzdBIWCgZ3YWxsZXQYASABKAlSBndhbGxldA==');

@$core.Deprecated('Use issueNonceResponseDescriptor instead')
const IssueNonceResponse$json = {
  '1': 'IssueNonceResponse',
  '2': [
    {'1': 'nonce', '3': 1, '4': 1, '5': 9, '10': 'nonce'},
    {
      '1': 'expires_at',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'expiresAt'
    },
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `IssueNonceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List issueNonceResponseDescriptor = $convert.base64Decode(
    'ChJJc3N1ZU5vbmNlUmVzcG9uc2USFAoFbm9uY2UYASABKAlSBW5vbmNlEjkKCmV4cGlyZXNfYX'
    'QYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUglleHBpcmVzQXQSGAoHbWVzc2Fn'
    'ZRgDIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use linkWalletRequestDescriptor instead')
const LinkWalletRequest$json = {
  '1': 'LinkWalletRequest',
  '2': [
    {'1': 'wallet', '3': 1, '4': 1, '5': 9, '10': 'wallet'},
    {'1': 'signature', '3': 2, '4': 1, '5': 9, '10': 'signature'},
  ],
};

/// Descriptor for `LinkWalletRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List linkWalletRequestDescriptor = $convert.base64Decode(
    'ChFMaW5rV2FsbGV0UmVxdWVzdBIWCgZ3YWxsZXQYASABKAlSBndhbGxldBIcCglzaWduYXR1cm'
    'UYAiABKAlSCXNpZ25hdHVyZQ==');

@$core.Deprecated('Use linkWalletResponseDescriptor instead')
const LinkWalletResponse$json = {
  '1': 'LinkWalletResponse',
  '2': [
    {'1': 'profile_id', '3': 1, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'wallet', '3': 2, '4': 1, '5': 9, '10': 'wallet'},
    {
      '1': 'linked_at',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'linkedAt'
    },
  ],
};

/// Descriptor for `LinkWalletResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List linkWalletResponseDescriptor = $convert.base64Decode(
    'ChJMaW5rV2FsbGV0UmVzcG9uc2USHQoKcHJvZmlsZV9pZBgBIAEoCVIJcHJvZmlsZUlkEhYKBn'
    'dhbGxldBgCIAEoCVIGd2FsbGV0EjcKCWxpbmtlZF9hdBgDIAEoCzIaLmdvb2dsZS5wcm90b2J1'
    'Zi5UaW1lc3RhbXBSCGxpbmtlZEF0');

@$core.Deprecated('Use getLinkedWalletRequestDescriptor instead')
const GetLinkedWalletRequest$json = {
  '1': 'GetLinkedWalletRequest',
};

/// Descriptor for `GetLinkedWalletRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getLinkedWalletRequestDescriptor =
    $convert.base64Decode('ChZHZXRMaW5rZWRXYWxsZXRSZXF1ZXN0');

@$core.Deprecated('Use getLinkedWalletResponseDescriptor instead')
const GetLinkedWalletResponse$json = {
  '1': 'GetLinkedWalletResponse',
  '2': [
    {'1': 'wallet', '3': 1, '4': 1, '5': 9, '10': 'wallet'},
    {
      '1': 'linked_at',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'linkedAt'
    },
  ],
};

/// Descriptor for `GetLinkedWalletResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getLinkedWalletResponseDescriptor = $convert.base64Decode(
    'ChdHZXRMaW5rZWRXYWxsZXRSZXNwb25zZRIWCgZ3YWxsZXQYASABKAlSBndhbGxldBI3CglsaW'
    '5rZWRfYXQYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUghsaW5rZWRBdA==');

const $core.Map<$core.String, $core.dynamic> LinkServiceBase$json = {
  '1': 'LinkService',
  '2': [
    {
      '1': 'IssueNonce',
      '2': '.socialtrader.v1.IssueNonceRequest',
      '3': '.socialtrader.v1.IssueNonceResponse',
      '4': {}
    },
    {
      '1': 'LinkWallet',
      '2': '.socialtrader.v1.LinkWalletRequest',
      '3': '.socialtrader.v1.LinkWalletResponse',
      '4': {}
    },
    {
      '1': 'GetLinkedWallet',
      '2': '.socialtrader.v1.GetLinkedWalletRequest',
      '3': '.socialtrader.v1.GetLinkedWalletResponse',
      '4': {'34': 1},
    },
  ],
  '3': {},
};

@$core.Deprecated('Use linkServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    LinkServiceBase$messageJson = {
  '.socialtrader.v1.IssueNonceRequest': IssueNonceRequest$json,
  '.socialtrader.v1.IssueNonceResponse': IssueNonceResponse$json,
  '.google.protobuf.Timestamp': $0.Timestamp$json,
  '.socialtrader.v1.LinkWalletRequest': LinkWalletRequest$json,
  '.socialtrader.v1.LinkWalletResponse': LinkWalletResponse$json,
  '.socialtrader.v1.GetLinkedWalletRequest': GetLinkedWalletRequest$json,
  '.socialtrader.v1.GetLinkedWalletResponse': GetLinkedWalletResponse$json,
};

/// Descriptor for `LinkService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List linkServiceDescriptor = $convert.base64Decode(
    'CgtMaW5rU2VydmljZRLTAQoKSXNzdWVOb25jZRIiLnNvY2lhbHRyYWRlci52MS5Jc3N1ZU5vbm'
    'NlUmVxdWVzdBojLnNvY2lhbHRyYWRlci52MS5Jc3N1ZU5vbmNlUmVzcG9uc2UifLpHaBISSXNz'
    'dWUgYSBTSVdFIG5vbmNlGlJSZXR1cm5zIHRoZSBmdWxsIEVJUC00MzYxIG1lc3NhZ2UgdGhlIH'
    'dhbGxldCBzaWducywgYm91bmQgdG8gdGhlIGNhbGxlcidzIHByb2ZpbGUugrUYDQoLbGlua19t'
    'YW5hZ2US8gEKCkxpbmtXYWxsZXQSIi5zb2NpYWx0cmFkZXIudjEuTGlua1dhbGxldFJlcXVlc3'
    'QaIy5zb2NpYWx0cmFkZXIudjEuTGlua1dhbGxldFJlc3BvbnNlIpoBukeFARINTGluayBhIHdh'
    'bGxldBp0VmVyaWZpZXMgdGhlIFNJV0Ugc2lnbmF0dXJlIGFuZCBiaW5kcyB0aGUgd2FsbGV0IH'
    'RvIHRoZSBjYWxsZXIncyBwcm9maWxlLCByZXBsYWNpbmcgYW55IGVhcmxpZXIgbGluayBvbiBl'
    'aXRoZXIgc2lkZS6CtRgNCgtsaW5rX21hbmFnZRLEAQoPR2V0TGlua2VkV2FsbGV0Eicuc29jaW'
    'FsdHJhZGVyLnYxLkdldExpbmtlZFdhbGxldFJlcXVlc3QaKC5zb2NpYWx0cmFkZXIudjEuR2V0'
    'TGlua2VkV2FsbGV0UmVzcG9uc2UiXpACAbpHRxIRR2V0IGxpbmtlZCB3YWxsZXQaMlRoZSB3YW'
    'xsZXQgbGlua2VkIHRvIHRoZSBjYWxsZXIncyBwcm9maWxlLCBpZiBhbnkugrUYDQoLbGlua19t'
    'YW5hZ2UaWoK1GFYKFHNlcnZpY2Vfc29jaWFsdHJhZGVyEgtsaW5rX21hbmFnZRoPCAESC2xpbm'
    'tfbWFuYWdlGg8IAhILbGlua19tYW5hZ2UaDwgFEgtsaW5rX21hbmFnZQ==');
