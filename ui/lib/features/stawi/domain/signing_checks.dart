import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

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

/// Settlement's name for a room call kind, as STAWI_SIGNED_CALL carries it.
String roomCallKindName(settlement.RoomCallKind kind) =>
    kind.name.replaceFirst('ROOM_CALL_KIND_', '');

String _genesisStateName(settlement.RoomGenesisState state) =>
    state.name.replaceFirst('ROOM_GENESIS_STATE_', '').toLowerCase();

BigInt _chainId(Int64 id) => BigInt.parse(id.toStringUnsigned());

/// Constant-length byte comparison.
bool bytesEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
