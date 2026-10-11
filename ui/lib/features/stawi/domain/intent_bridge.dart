import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart' as sdk;

import 'signing_checks.dart';

/// The SDK's [sdk.FinancialIntent] for a finance.v1 FinancialIntent that
/// settlement prepared, field for field, so the device can recompute its
/// digest and run the SDK's checks on it. An enum the SDK does not know is
/// refused rather than guessed.
sdk.FinancialIntent sdkIntentOf(finance.FinancialIntent p) {
  T code<T>(T Function(int) fromCode, int value) {
    try {
      return fromCode(value);
    } on Object {
      throw SigningRefused('the prepared intent has an unknown code $value');
    }
  }

  sdk.Principal principal(finance.Principal x) => sdk.Principal(
    code(sdk.PrincipalType.fromCode, x.type.value),
    Uint8List.fromList(x.id),
  );
  sdk.ValueLocation location(finance.ValueLocation x) => sdk.ValueLocation(
    code(sdk.LocationKind.fromCode, x.kind.value),
    Uint8List.fromList(x.address),
    x.bucket,
  );
  BigInt u64(Int64 v) => BigInt.parse(v.toStringUnsigned());
  final amount = BigInt.tryParse(p.amount.isEmpty ? '0' : p.amount);
  if (amount == null) {
    throw const SigningRefused('the prepared intent amount is malformed');
  }
  return sdk.FinancialIntent(
    intentId: Uint8List.fromList(p.intentId),
    type: code(sdk.IntentType.fromCode, p.type.value),
    domain: sdk.IntentDomain(
      protocolVersion: p.domain.protocolVersion,
      chainId: u64(p.domain.chainId),
      verifyingContract: Uint8List.fromList(p.domain.verifyingContract),
      accountVersion: p.domain.accountVersion,
      moduleVersion: p.domain.moduleVersion,
      environment: p.domain.environment,
    ),
    requestedBy: principal(p.requestedBy),
    authorizedBy: principal(p.authorizedBy),
    account: Uint8List.fromList(p.account),
    room: Uint8List.fromList(p.room),
    source: location(p.source),
    destination: location(p.destination),
    asset: Uint8List.fromList(p.asset),
    amount: amount,
    mode: code(sdk.IntentMode.fromCode, p.mode.value),
    authorizationId: Uint8List.fromList(p.authorizationId),
    capabilityId: Uint8List.fromList(p.capabilityId),
    constitutionHash: Uint8List.fromList(p.constitutionHash),
    securityPolicyHash: Uint8List.fromList(p.securityPolicyHash),
    policyEpoch: u64(p.policyEpoch),
    nonce: u64(p.nonce),
    credentialEpoch: u64(p.credentialEpoch),
    recoveryEpoch: u64(p.recoveryEpoch),
    validAfter: u64(p.validAfter),
    validUntil: u64(p.validUntil),
    countryPolicyVersion: Uint8List.fromList(p.countryPolicyVersion),
    complianceRequired: p.complianceRequired,
  );
}

/// The intent's digest as the account computes it; refuses an intent the SDK
/// cannot encode.
Uint8List intentDigestOf(sdk.FinancialIntent intent) {
  try {
    return intent.digest();
  } on sdk.IntentException catch (e) {
    throw SigningRefused('the prepared intent is malformed ($e)');
  }
}
