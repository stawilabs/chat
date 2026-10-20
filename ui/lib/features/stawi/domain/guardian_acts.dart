/// A guardian's acts on an account they guard (StawiAccount.guardianAct),
/// signed with the guardian's own device key, and the guardian key's proof
/// of possession (settlement RegisterGuardianKey). stawi v0.2.6.
///
/// StawiAccount recovers a guardian's signature with ECDSA, so a guardian is
/// a secp256k1 key: the device key of the guardian's own Stawi account. A
/// P-256 (passkey) key cannot guard.
library;

import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import 'account_protection.dart' show RecoveryStage;
import 'intent_bridge.dart';
import 'signing_checks.dart';

/// AccountPolicyLib.GuardianOpKind values (Go stawi.Guardian*).
abstract final class GuardianOpKinds {
  static const int approveRecovery = 0;
  static const int freeze = 1;
  static const int unfreeze = 2;
  static const int cancelUnfreeze = 3;
  static const int vetoPolicy = 4;
}

/// AccountPolicyLib's key algorithm numbers.
const int secp256k1KeyAlgorithm = 0;
const int p256KeyAlgorithm = 12;

/// keccak256(abi.encode(GuardianOp{kind, newKey, round, algorithm})): the
/// guardian act's intent authorization_id (Go stawi.GuardianOpHash).
Uint8List guardianOpHash({
  required int kind,
  required BigInt round,
  List<int>? newKey,
  int algorithm = secp256k1KeyAlgorithm,
}) {
  final key = newKey ?? Uint8List(20);
  if (key.length != 20) throw ArgumentError('newKey: a 20-byte address');
  if (round.isNegative || round.bitLength > 64) {
    throw ArgumentError.value(round, 'round', 'a uint64');
  }
  return keccak256([
    ...bigIntToBytes(BigInt.from(kind), 32),
    ...Uint8List(12),
    ...key,
    ...bigIntToBytes(round, 32),
    ...bigIntToBytes(BigInt.from(algorithm), 32),
  ]);
}

int _algorithmOf(settlement.DeviceKeyAlgorithm a) =>
    a == settlement.DeviceKeyAlgorithm.DEVICE_KEY_ALGORITHM_P256
    ? p256KeyAlgorithm
    : secp256k1KeyAlgorithm;

BigInt _u64(Int64 v) => BigInt.parse(v.toStringUnsigned());

/// Why a guardian act that is not the one asked for is refused.
const String notTheGuardianAct =
    'this is not the guardian act you chose on that account';

/// The guardian op [kind] asks for on [guarded], as settlement renders it
/// (AccountService.guardianOp): a recovery request names [newKey] in the
/// current round, an approval the pending recovery's key, round and
/// algorithm.
({int kind, Uint8List newKey, BigInt round, int algorithm}) expectedGuardianOp(
  settlement.AccountCallKind kind,
  settlement.GuardedAccount guarded, {
  Uint8List? newKey,
}) {
  final r = guarded.recovery;
  switch (kind) {
    case settlement.AccountCallKind.ACCOUNT_CALL_KIND_REQUEST_RECOVERY:
      if (newKey == null ||
          newKey.length != 20 ||
          newKey.every((b) => b == 0)) {
        throw const SigningRefused('name the owner\'s new key');
      }
      return (
        kind: GuardianOpKinds.approveRecovery,
        newKey: newKey,
        round: _u64(r.round),
        algorithm: secp256k1KeyAlgorithm,
      );
    case settlement.AccountCallKind.ACCOUNT_CALL_KIND_APPROVE_RECOVERY:
      if (r.newKey.length != 20) {
        throw const SigningRefused('no recovery of that account is pending');
      }
      return (
        kind: GuardianOpKinds.approveRecovery,
        newKey: Uint8List.fromList(r.newKey),
        round: _u64(r.round),
        algorithm: _algorithmOf(r.newKeyAlgorithm),
      );
    default:
      throw ArgumentError.value(kind, 'kind', 'a recovery request or approval');
  }
}

/// The digest [guardianKey] signs for the guardian act [kind] on [guarded]
/// (read off the chain through GetGuardedAccount), once settlement's
/// prepared call is checked: the call is that kind on that account, signed
/// by [guardianKey], which the account holds as a guardian; its intent is a
/// zero-amount RECOVERY intent on the guarded account and [chainId],
/// authorized by the guardian at its guardian nonce, binding exactly the op
/// [expectedGuardianOp] renders. Throws [SigningRefused] otherwise.
Uint8List checkedGuardianAct({
  required settlement.PrepareAccountCallResponse prepared,
  required settlement.AccountCallKind kind,
  required settlement.GuardedAccount guarded,
  required Uint8List guardianKey,
  required BigInt chainId,
  Uint8List? newKey,
}) {
  final call = prepared.call;
  final account = Uint8List.fromList(guarded.address);
  if (call.kind != kind) {
    throw const SigningRefused('settlement prepared another kind of call');
  }
  if (account.length != 20 || !bytesEqual(call.address, account)) {
    throw const SigningRefused('the call is for another account');
  }
  if (!bytesEqual(guarded.guardian, guardianKey) ||
      !guarded.guardians.any((g) => bytesEqual(g, guardianKey))) {
    throw const SigningRefused('this phone\'s key does not guard that account');
  }
  if (!bytesEqual(call.signer, guardianKey)) {
    throw const SigningRefused('the call is not signed by this phone\'s key');
  }
  final digest = Uint8List.fromList(prepared.intentDigest);
  if (digest.length != 32 ||
      (call.intentDigest.isNotEmpty &&
          !bytesEqual(call.intentDigest, digest))) {
    throw const SigningRefused('the prepared digest is malformed');
  }
  final intent = sdkIntentOf(prepared.financialIntent);
  if (!bytesEqual(intentDigestOf(intent), digest)) {
    throw const SigningRefused('the digest is not the prepared intent\'s');
  }
  final op = expectedGuardianOp(kind, guarded, newKey: newKey);
  final opHash = guardianOpHash(
    kind: op.kind,
    newKey: op.newKey,
    round: op.round,
    algorithm: op.algorithm,
  );
  if (prepared.call.hasGuardianOp()) {
    final g = prepared.call.guardianOp;
    if (g.kind != op.kind ||
        !bytesEqual(g.newKey, op.newKey) ||
        _u64(g.round) != op.round ||
        g.algorithm != op.algorithm) {
      throw const SigningRefused(notTheGuardianAct);
    }
  }
  final type = op.kind == GuardianOpKinds.approveRecovery
      ? IntentType.recovery
      : IntentType.policyChange;
  if (intent.type != type ||
      intent.mode != IntentMode.directSignature ||
      intent.room.isNotEmpty ||
      intent.amount != BigInt.zero ||
      !bytesEqual(intent.account, account) ||
      !bytesEqual(intent.domain.verifyingContract, account) ||
      intent.domain.chainId != chainId) {
    throw const SigningRefused(notTheGuardianAct);
  }
  if (intent.authorizedBy.type != PrincipalType.guardian ||
      !bytesEqual(intent.authorizedBy.id, guardianKey) ||
      intent.nonce != _u64(guarded.guardianNonce)) {
    throw const SigningRefused(notTheGuardianAct);
  }
  if (!bytesEqual(intent.authorizationId, opHash)) {
    throw const SigningRefused(notTheGuardianAct);
  }
  return digest;
}

/// An account this phone's key guards, as a guardian reads it.
final class GuardedView {
  GuardedView(this.account);

  final settlement.GuardedAccount account;

  settlement.AccountRecovery get _r => account.recovery;

  RecoveryStage get stage => switch (_r.state) {
    settlement.AccountRecoveryState.ACCOUNT_RECOVERY_STATE_PENDING =>
      RecoveryStage.pending,
    settlement.AccountRecoveryState.ACCOUNT_RECOVERY_STATE_CONTESTED =>
      RecoveryStage.contested,
    _ => RecoveryStage.none,
  };

  Uint8List? get newKey => stage == RecoveryStage.none || _r.newKey.length != 20
      ? null
      : Uint8List.fromList(_r.newKey);

  int get approvals => _r.approvals.toInt();
  int get required => _r.approvalsRequired.toInt();

  DateTime? _at(Int64 s) => s <= Int64.ZERO
      ? null
      : DateTime.fromMillisecondsSinceEpoch(s.toInt() * 1000, isUtc: true);

  DateTime? get executableAfter => _at(_r.executableAfter);
  DateTime? get expiresAt => _at(_r.expiresAt);

  /// A guardian may start a recovery only while none is pending.
  bool get canRequest => stage == RecoveryStage.none;

  /// A pending or contested recovery still short of its approvals may be
  /// approved.
  bool get canApprove => stage != RecoveryStage.none && approvals < required;

  /// The account's state in plain words.
  String headline() {
    String when(DateTime? t) => t == null ? 'soon' : '${_date(t)} UTC';
    final k = newKey == null ? '' : ' to ${_short(newKey!)}';
    return switch (stage) {
      RecoveryStage.none when account.guardianFrozen =>
        'Frozen by its guardians.',
      RecoveryStage.none =>
        'No recovery under way. ${account.guardianThreshold} of '
            '${account.guardians.length} guardians must agree to start one.',
      RecoveryStage.pending =>
        'Recovery$k: $approvals of $required approved. It can take over from '
            '${when(executableAfter)} and lapses ${when(expiresAt)}.',
      RecoveryStage.contested =>
        'The owner contested the recovery$k: the account is frozen while the '
            'guardians decide ($approvals of $required approved). It lapses '
            '${when(expiresAt)}.',
    };
  }
}

/// A guardian cannot cancel a recovery: only the owner's phone can contest
/// it, and it lapses by itself.
const String guardianCannotCancelNote =
    'A guardian cannot cancel a recovery. If the owner did not ask for it, '
    'they contest it from their own phone; otherwise it lapses by itself if '
    'too few guardians approve before it expires.';

/// Why guarding is not available on a phone whose key is a P-256 passkey.
const String p256CannotGuardNote =
    'This phone\'s key is a passkey (P-256). The Stawi account contract only '
    'accepts guardian signatures from secp256k1 keys, so this phone cannot '
    'guard anyone. Use a phone whose Stawi key is not a passkey.';

String _short(List<int> a) {
  final h = bytesToHex0x(a).toLowerCase();
  return '${h.substring(0, 6)}…${h.substring(h.length - 4)}';
}

String _date(DateTime t) {
  final u = t.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${u.year}-${two(u.month)}-${two(u.day)} '
      '${two(u.hour)}:${two(u.minute)}';
}
