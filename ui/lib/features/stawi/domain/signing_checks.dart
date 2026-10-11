import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import 'account_engine_calls.dart';
import 'intent_bridge.dart';
import 'stawi_payloads.dart';

/// Settlement builds every digest a device signs. Before the device signs one,
/// the app checks that the prepared call is the act the member asked for and
/// that the digest is StawiAccount's ERC-1271 wrapping of the call's typed hash
/// for the member's own account, so a wrong or substituted digest is never
/// signed.
final class SigningRefused implements Exception {
  const SigningRefused(this.reason);

  final String reason;

  @override
  String toString() => 'SigningRefused: $reason';
}

/// The digest to sign for a prepared room call.
Uint8List checkedRoomCallDigest({
  required settlement.PrepareRoomCallResponse prepared,
  required settlement.RoomCallKind kind,
  required String chatRoomId,
  required List<Uint8List> ownAccounts,
}) {
  final call = prepared.call;
  if (call.kind != kind) {
    throw SigningRefused(
      'settlement prepared a ${roomCallKindName(call.kind)} call, '
      'not ${roomCallKindName(kind)}',
    );
  }
  if (call.chatRoomId.isNotEmpty && call.chatRoomId != chatRoomId) {
    throw const SigningRefused('the call was prepared for another room');
  }
  if (!call.requiresSignature) {
    throw const SigningRefused('the call takes no signature');
  }
  final signer = Uint8List.fromList(prepared.signer);
  if (!ownAccounts.any((a) => bytesEqual(a, signer)) ||
      (call.signer.isNotEmpty && !bytesEqual(call.signer, signer))) {
    throw const SigningRefused('the call is not signed by your account');
  }
  final digest = Uint8List.fromList(prepared.digest);
  if (digest.length != 32 || call.typedHash.length != 32) {
    throw const SigningRefused('the prepared digest is malformed');
  }
  final expected = accountWrappedHash(
    signer,
    _chainId(call.chainId),
    call.typedHash,
  );
  if (!bytesEqual(expected, digest) ||
      (call.digest.isNotEmpty && !bytesEqual(call.digest, digest))) {
    throw const SigningRefused(
      'the digest is not your account wrapping of the call',
    );
  }
  return digest;
}

/// The digest a founder signs for a genesis. [card] is the genesis card chat
/// posted in the room; settlement's record must agree with it.
Uint8List checkedGenesisDigest({
  required settlement.RoomGenesis genesis,
  required StawiGenesisView card,
  required String profileId,
  required List<Uint8List> ownAccounts,
}) {
  if (genesis.genesisId != card.genesisId) {
    throw const SigningRefused('settlement returned another genesis');
  }
  if (genesis.state != settlement.RoomGenesisState.ROOM_GENESIS_STATE_PENDING) {
    throw SigningRefused('the genesis is ${_genesisStateName(genesis.state)}');
  }
  if (genesis.genesisHash.length != 32 ||
      !bytesEqual(genesis.genesisHash, card.genesisHash)) {
    throw const SigningRefused(
      'the genesis hash differs from the one posted in the room',
    );
  }
  final founder = genesis.founders
      .where((f) => f.profileId == profileId)
      .firstOrNull;
  if (founder == null) {
    throw const SigningRefused('you are not a founder of this genesis');
  }
  if (!ownAccounts.any((a) => bytesEqual(a, founder.account))) {
    throw const SigningRefused('the founder account is not yours');
  }
  final expected = accountWrappedHash(
    founder.account,
    _chainId(genesis.chainId),
    genesis.genesisHash,
  );
  if (!bytesEqual(expected, founder.signingDigest)) {
    throw const SigningRefused(
      'the signing digest is not your account wrapping of the genesis',
    );
  }
  return Uint8List.fromList(founder.signingDigest);
}

/// The digest to sign for a prepared device call on the member's account.
Uint8List checkedAccountCallDigest({
  required settlement.PrepareAccountCallResponse prepared,
  required settlement.AccountCallKind kind,
  required Uint8List account,
}) {
  final call = prepared.call;
  if (call.kind != kind) {
    throw const SigningRefused('settlement prepared another kind of call');
  }
  if (!bytesEqual(call.address, account)) {
    throw const SigningRefused('the call is for another account');
  }
  if (call.signer.isNotEmpty) {
    throw const SigningRefused('the call needs a guardian signature');
  }
  final digest = Uint8List.fromList(prepared.intentDigest);
  if (digest.length != 32 ||
      (call.intentDigest.isNotEmpty &&
          !bytesEqual(call.intentDigest, digest))) {
    throw const SigningRefused('the prepared digest is malformed');
  }
  return digest;
}

/// The genesis digest to sign for a deployment. It is rebuilt here from the
/// policy settlement showed, this device's key, the identity salt hash profile
/// lists for the account and the account address
/// (stawi_finance_sdk deployAccountDigest), and signed only if it matches.
Uint8List checkedDeployDigest({
  required settlement.PrepareDeployAccountResponse prepared,
  required Uint8List account,
  required Uint8List? identitySaltHash,
  required Uint8List device,
}) {
  if (identitySaltHash == null || identitySaltHash.length != 32) {
    throw const SigningRefused(
      'your profile does not list the identity salt hash for this account',
    );
  }
  if (!bytesEqual(prepared.device, device)) {
    throw const SigningRefused(
      'settlement prepared the genesis for another device key',
    );
  }
  final policy = accountPolicyFrom(prepared.initialPolicy);
  if (!bytesEqual(policy.hash, prepared.initialPolicyHash)) {
    throw const SigningRefused(
      'the initial policy hash does not match the policy shown',
    );
  }
  final expected = deployAccountDigest(
    identitySaltHash: identitySaltHash,
    device: device,
    chainId: _chainId(prepared.chainId),
    account: account,
    policy: policy,
  );
  if (prepared.genesisDigest.length != 32 ||
      !bytesEqual(expected, prepared.genesisDigest)) {
    throw const SigningRefused(
      'the genesis digest is not the one your account, key and policy give',
    );
  }
  return expected;
}

/// The SDK's [AccountPolicy] for settlement's initial_policy. A field the
/// policy cannot hold is refused rather than signed over.
AccountPolicy accountPolicyFrom(finance.AccountPolicyParams p) {
  final limit = BigInt.tryParse(p.periodLimit.isEmpty ? '0' : p.periodLimit);
  final addresses = [p.asset, ...p.allowlist, ...p.guardians];
  if (limit == null ||
      limit.isNegative ||
      limit.bitLength > 256 ||
      addresses.any((a) => a.length != 20) ||
      p.guardianThreshold > 255 ||
      p.allowlistMode.value > 255) {
    throw const SigningRefused('the initial policy is malformed');
  }
  return AccountPolicy(
    asset: p.asset,
    periodLimit: limit,
    periodSeconds: _u64(p.periodSeconds),
    epochStart: _u64(p.epochStart),
    allowlist: p.allowlist,
    guardians: p.guardians,
    guardianThreshold: p.guardianThreshold,
    allowlistMode: p.allowlistMode.value,
  );
}

/// The digest to sign for a prepared contribution: the call must be a
/// CONTRIBUTE from [account] of exactly [amount] into [custody].
Uint8List checkedContributionDigest({
  required settlement.PrepareAccountCallResponse prepared,
  required Uint8List account,
  required Uint8List custody,
  required String amount,
}) {
  final digest = checkedAccountCallDigest(
    prepared: prepared,
    kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_CONTRIBUTE,
    account: account,
  );
  final intent = prepared.financialIntent;
  if (intent.type != finance.IntentType.INTENT_TYPE_CONTRIBUTION ||
      intent.destination.kind !=
          finance.LocationKind.LOCATION_KIND_ROOM_CUSTODY ||
      !bytesEqual(intent.destination.address, custody)) {
    throw const SigningRefused('the call does not pay this room');
  }
  if (intent.account.isNotEmpty && !bytesEqual(intent.account, account)) {
    throw const SigningRefused('the call pays from another account');
  }
  if (intent.amount != amount) {
    throw SigningRefused(
      'the call pays ${intent.amount}, not the $amount you asked for',
    );
  }
  return digest;
}

/// The digest to sign for a prepared engine call, and the call it binds (to
/// show the member: a payoff's ceiling, for one). Checked with the SDK: the
/// digest is the intent's own, the intent binds exactly the engine call
/// settlement returned (verifyEngineCallIntent), and that call is the action,
/// room, loan, product and amount the member asked for.
/// The prepared target must also be the room's own engine for the action
/// (its LoanEngine for loan actions, its RulesEngine otherwise) with an active
/// grant: [engines] is finance's live Room.engines. Without them the call
/// cannot be checked, so it is refused.
({Uint8List digest, EngineCall call}) checkedEngineCall({
  required settlement.PrepareAccountCallResponse prepared,
  required AccountEngineRequest request,
  required Uint8List account,
  required RoomEngineTargets? engines,
}) {
  if (engines == null) throw const SigningRefused(enginesUnknownReason);
  final digest = checkedAccountCallDigest(
    prepared: prepared,
    kind: request.call.kind,
    account: account,
  );
  final intent = sdkIntentOf(prepared.financialIntent);
  if (!bytesEqual(intentDigestOf(intent), digest)) {
    throw const SigningRefused('the digest is not the prepared intent\'s');
  }
  if (intent.account.isNotEmpty && !bytesEqual(intent.account, account)) {
    throw const SigningRefused('the call is made from another account');
  }
  final EngineCall call;
  try {
    call = verifyEngineCallIntent(
      intent,
      prepared.call.engineTarget,
      prepared.call.engineCalldata,
      engines: engines,
    );
  } on EngineCallException catch (e) {
    throw SigningRefused(switch (e.error) {
      EngineCallError.notTheRoomsEngine =>
        'the call targets a contract that is not this room’s active engine',
      _ => 'the engine call does not check out (${e.error.name})',
    });
  }
  if (call.action != request.call.action) {
    throw SigningRefused('settlement prepared ${call.action.functionName}');
  }
  if (!bytesEqual(call.room, request.custody)) {
    throw const SigningRefused('the call is for another room');
  }
  if (request.call.takesLoan && call.loanId != BigInt.from(request.loanId)) {
    throw const SigningRefused('the call names another loan');
  }
  if (request.amount.isNotEmpty &&
      call.amount != BigInt.parse(request.amount)) {
    throw SigningRefused(
      'the call moves ${call.amount}, not the ${request.amount} you asked for',
    );
  }
  if (request.call.takesProduct &&
      !bytesEqual(call.productId, request.productId!)) {
    throw const SigningRefused('the call names another product');
  }
  if (request.call == AccountEngineCall.loanRequest &&
      (call.instalments != request.instalments ||
          call.replaces != BigInt.from(request.replaces))) {
    throw const SigningRefused('the loan terms differ from your request');
  }
  return (digest: digest, call: call);
}

/// Why an engine call is refused when the room's engines are unknown.
const String enginesUnknownReason =
    'the room’s engines could not be read just now (settlement may be '
    'unreachable), so the call cannot be checked against them; try again '
    'shortly';

/// The exit settlement built for a PROPOSE_PRINCIPAL_EXIT with a spend: the
/// ballot's payload hash must be the exit intent's digest, and the intent must
/// move [amount] out of the room.
void checkPrincipalExit(
  settlement.PrepareRoomCallResponse prepared, {
  required String amount,
}) {
  final call = prepared.call;
  if (!call.hasExitIntent()) {
    throw const SigningRefused('settlement returned no exit intent');
  }
  final intent = sdkIntentOf(call.exitIntent);
  if (!bytesEqual(intentDigestOf(intent), call.payloadHash)) {
    throw const SigningRefused('the ballot does not carry this exit');
  }
  if (intent.amount != BigInt.parse(amount)) {
    throw SigningRefused(
      'the exit moves ${intent.amount}, not the $amount proposed',
    );
  }
}

/// Settlement's name for a room call kind, as STAWI_SIGNED_CALL carries it.
String roomCallKindName(settlement.RoomCallKind kind) =>
    kind.name.replaceFirst('ROOM_CALL_KIND_', '');

String _genesisStateName(settlement.RoomGenesisState state) =>
    state.name.replaceFirst('ROOM_GENESIS_STATE_', '').toLowerCase();

BigInt _chainId(Int64 id) => BigInt.parse(id.toStringUnsigned());

BigInt _u64(Int64 v) => BigInt.parse(v.toStringUnsigned());

/// Constant-length byte comparison.
bool bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
