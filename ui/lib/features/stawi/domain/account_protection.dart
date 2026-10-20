import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import 'signing_checks.dart';

/// AccountPolicyLib.OpKind values of the account-protection calls (Go
/// stawi.Op*): positional in the contract's enum.
abstract final class ProtectionOps {
  static const int contestRecovery = 4;
  static const int proposePolicy = 8;
  static const int cancelPolicy = 9;
}

/// How long a guardian change waits before the account applies it
/// (StawiAccount's policy delay); the person or a guardian may stop it
/// meanwhile.
const Duration guardianChangeDelay = Duration(hours: 24);

/// keccak256(abi.encode(ManagementOp)) for an op with no key, no
/// authorization and either [policy] or an all-zero policy: the intent's
/// authorization_id for a guardian change (PROPOSE_POLICY), a contest of a
/// recovery or the cancel of a pending policy (Go stawi.ManagementOpHash).
Uint8List managementOpHash({required int kind, AccountPolicy? policy}) {
  if (kind < 0 || kind > 255) {
    throw ArgumentError.value(kind, 'kind', 'an AccountPolicyLib.OpKind');
  }
  const opHead = 13 * 32;
  final zeroPolicy = AccountPolicy(
    asset: Uint8List(20),
    periodLimit: BigInt.zero,
    periodSeconds: BigInt.zero,
    allowlistMode: 0,
  );
  final out = BytesBuilder(copy: false)
    ..add(bigIntToBytes(BigInt.from(32), 32))
    ..add(bigIntToBytes(BigInt.from(kind), 32))
    ..add(Uint8List(32)) // key
    ..add(Uint8List(32)) // authorizationId
    ..add(Uint8List(9 * 32)) // auth: AuthorizationParams, all zero
    ..add(bigIntToBytes(BigInt.from(opHead), 32))
    // The policy tuple without its own leading offset: inside the op it is
    // placed at opHead.
    ..add((policy ?? zeroPolicy).abiEncode().sublist(32));
  return keccak256(out.toBytes());
}

BigInt _u64(Int64 v) => BigInt.parse(v.toStringUnsigned());

/// The account's policy in force as [state] reads it, with [guardians] and
/// [threshold] in place of its own when given: what a guardian change
/// proposes (Go AccountService.managementOp keeps every other field).
AccountPolicy policyInForce(
  settlement.AccountState state, {
  List<Uint8List>? guardians,
  int? threshold,
}) {
  final p = state.policy;
  final limit = BigInt.tryParse(p.periodLimit.isEmpty ? '0' : p.periodLimit);
  if (limit == null || limit.isNegative || p.asset.length != 20) {
    throw const SigningRefused('your account\'s policy could not be read');
  }
  return AccountPolicy(
    asset: p.asset,
    periodLimit: limit,
    periodSeconds: _u64(p.periodSeconds),
    epochStart: _u64(p.epochStart),
    allowlist: p.allowlist,
    guardians: guardians ?? state.guardians,
    guardianThreshold: threshold ?? state.guardianThreshold,
    allowlistMode: p.allowlistMode.value,
  );
}

/// The guardians and threshold after adding (or removing) [guardian], as
/// settlement and the account compute them: [requested] (0 keeps the
/// current threshold) clamped to between 1 and the number of guardians, and
/// 0 once none is left.
({List<Uint8List> guardians, int threshold}) guardianSetAfter(
  settlement.AccountState state,
  Uint8List guardian, {
  required bool add,
  int requested = 0,
}) {
  if (guardian.length != 20 || guardian.every((b) => b == 0)) {
    throw const FormatException('A guardian is a 20-byte address (0x…)');
  }
  final current = [for (final g in state.guardians) Uint8List.fromList(g)];
  final present = current.any((g) => bytesEqual(g, guardian));
  if (add && present) {
    throw const FormatException('That address is already your guardian');
  }
  if (!add && !present) {
    throw const FormatException('That address is not one of your guardians');
  }
  if (bytesEqual(guardian, state.address)) {
    throw const FormatException('Your account cannot guard itself');
  }
  final set = add
      ? [...current, guardian]
      : [
          for (final g in current)
            if (!bytesEqual(g, guardian)) g,
        ];
  if (requested < 0 || requested > 255) {
    throw const FormatException('Choose how many guardians must agree');
  }
  var threshold = requested != 0 ? requested : state.guardianThreshold;
  if (set.isEmpty) {
    threshold = 0;
  } else {
    threshold = threshold.clamp(1, set.length > 255 ? 255 : set.length);
  }
  return (guardians: set, threshold: threshold);
}

void _checkManagementIntent(
  FinancialIntent intent, {
  required IntentType type,
  required Uint8List account,
  required BigInt chainId,
  required Uint8List opHash,
  required String wrongOp,
}) {
  if (intent.type != type ||
      intent.mode != IntentMode.directSignature ||
      intent.room.isNotEmpty ||
      intent.amount != BigInt.zero) {
    throw const SigningRefused(
      'settlement prepared something other than an account change',
    );
  }
  if (!bytesEqual(intent.domain.verifyingContract, account) ||
      intent.domain.chainId != chainId) {
    throw const SigningRefused('the change is for another account');
  }
  if (!bytesEqual(intent.authorizationId, opHash)) {
    throw SigningRefused(wrongOp);
  }
}

bool _zeroOrEmpty(List<int> b) => b.every((x) => x == 0);

/// Why a guardian change that is not the one asked for is refused.
const String notTheGuardianChange =
    'this would not make the guardian change you chose';

/// The digest to sign for adding (or removing) [guardian] on [account]: an
/// ADD_GUARDIAN (REMOVE_GUARDIAN) whose op proposes the policy in force
/// ([state], read off the chain) with exactly the guardian set and
/// threshold [guardianSetAfter] gives and nothing else changed, carried in a
/// POLICY_CHANGE intent that binds that op, on [chainId] (the app's
/// deployment configuration).
Uint8List checkedGuardianChange({
  required settlement.PrepareAccountCallResponse prepared,
  required settlement.AccountState state,
  required Uint8List account,
  required Uint8List guardian,
  required bool add,
  required BigInt chainId,
  int threshold = 0,
}) {
  final digest = checkedAccountCallDigest(
    prepared: prepared,
    kind: add
        ? settlement.AccountCallKind.ACCOUNT_CALL_KIND_ADD_GUARDIAN
        : settlement.AccountCallKind.ACCOUNT_CALL_KIND_REMOVE_GUARDIAN,
    account: account,
  );
  if (!bytesEqual(state.address, account)) {
    throw const SigningRefused('the account read is not yours');
  }
  final intent = checkedPreparedIntent(prepared, digest, account);
  final after = guardianSetAfter(
    state,
    guardian,
    add: add,
    requested: threshold,
  );
  final expected = policyInForce(
    state,
    guardians: after.guardians,
    threshold: after.threshold,
  );
  final op = prepared.managementOp;
  if (!prepared.hasManagementOp() ||
      op.kind != ProtectionOps.proposePolicy ||
      !_zeroOrEmpty(op.key) ||
      !_zeroOrEmpty(op.authorizationId) ||
      op.hasAuth() ||
      !op.hasPolicy()) {
    throw const SigningRefused(notTheGuardianChange);
  }
  final AccountPolicy offered;
  try {
    offered = accountPolicyFrom(op.policy);
  } on SigningRefused {
    throw const SigningRefused(notTheGuardianChange);
  }
  if (!bytesEqual(offered.hash, expected.hash)) {
    throw const SigningRefused(notTheGuardianChange);
  }
  _checkManagementIntent(
    intent,
    type: IntentType.policyChange,
    account: account,
    chainId: chainId,
    opHash: managementOpHash(
      kind: ProtectionOps.proposePolicy,
      policy: expected,
    ),
    wrongOp: notTheGuardianChange,
  );
  return digest;
}

/// The digest to sign for a management call that names nothing but its kind:
/// CONTEST_RECOVERY (a RECOVERY intent) or CANCEL_POLICY (a POLICY_CHANGE
/// intent) on [account], on [chainId].
Uint8List checkedPlainManagementCall({
  required settlement.PrepareAccountCallResponse prepared,
  required settlement.AccountCallKind kind,
  required Uint8List account,
  required BigInt chainId,
}) {
  final (opKind, type) = switch (kind) {
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_CONTEST_RECOVERY => (
      ProtectionOps.contestRecovery,
      IntentType.recovery,
    ),
    settlement.AccountCallKind.ACCOUNT_CALL_KIND_CANCEL_POLICY => (
      ProtectionOps.cancelPolicy,
      IntentType.policyChange,
    ),
    _ => throw ArgumentError.value(kind, 'kind', 'contest or cancel policy'),
  };
  const wrong = 'settlement prepared another account change';
  final digest = checkedAccountCallDigest(
    prepared: prepared,
    kind: kind,
    account: account,
  );
  final intent = checkedPreparedIntent(prepared, digest, account);
  final op = prepared.managementOp;
  if (!prepared.hasManagementOp() ||
      op.kind != opKind ||
      !_zeroOrEmpty(op.key) ||
      !_zeroOrEmpty(op.authorizationId) ||
      op.hasAuth() ||
      op.hasPolicy()) {
    throw const SigningRefused(wrong);
  }
  _checkManagementIntent(
    intent,
    type: type,
    account: account,
    chainId: chainId,
    opHash: managementOpHash(kind: opKind),
    wrongOp: wrong,
  );
  return digest;
}

/// Where a recovery of the account stands.
enum RecoveryStage { none, pending, contested }

/// The account's protection as a person reads it: its guardians, how many
/// must agree, any recovery under way, and whether it is frozen.
final class AccountProtection {
  AccountProtection._({
    required this.guardians,
    required this.threshold,
    required this.frozen,
    required this.guardianFrozen,
    required this.stage,
    required this.approvals,
    required this.approvalsRequired,
    required this.newKey,
    required this.takesOverAt,
    required this.expiresAt,
    required this.pendingChangeAt,
  });

  factory AccountProtection.of(settlement.AccountState s) {
    DateTime? at(Int64 seconds) => seconds <= Int64.ZERO
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            seconds.toInt() * 1000,
            isUtc: true,
          );
    final r = s.recovery;
    final stage = switch (r.state) {
      settlement.AccountRecoveryState.ACCOUNT_RECOVERY_STATE_PENDING =>
        RecoveryStage.pending,
      settlement.AccountRecoveryState.ACCOUNT_RECOVERY_STATE_CONTESTED =>
        RecoveryStage.contested,
      _ => RecoveryStage.none,
    };
    return AccountProtection._(
      guardians: [for (final g in s.guardians) Uint8List.fromList(g)],
      threshold: s.guardianThreshold,
      frozen: s.frozenAtBlock > Int64.ZERO,
      guardianFrozen: s.guardianFrozen,
      stage: stage,
      approvals: r.approvals.toInt(),
      approvalsRequired: r.approvalsRequired.toInt(),
      newKey: stage == RecoveryStage.none || r.newKey.length != 20
          ? null
          : Uint8List.fromList(r.newKey),
      takesOverAt: stage == RecoveryStage.none ? null : at(r.executableAfter),
      expiresAt: stage == RecoveryStage.none ? null : at(r.expiresAt),
      pendingChangeAt: at(s.policy.pendingPolicyAfter),
    );
  }

  final List<Uint8List> guardians;
  final int threshold;

  /// Frozen by one of the account's own devices.
  final bool frozen;

  /// Frozen by the guardians (or by a contested recovery): no device can
  /// lift it.
  final bool guardianFrozen;
  final RecoveryStage stage;
  final int approvals;
  final int approvalsRequired;

  /// The key a recovery would install as the account's only key.
  final Uint8List? newKey;

  /// When a recovery whose approvals are met may install [newKey].
  final DateTime? takesOverAt;

  /// When a recovery lapses if its approvals are not met.
  final DateTime? expiresAt;

  /// When a pending policy change (a guardian change) takes effect.
  final DateTime? pendingChangeAt;

  bool get recovering => stage != RecoveryStage.none;

  /// A device may contest a pending recovery once.
  bool get canContest => stage == RecoveryStage.pending;

  /// The line that says what is going on, or null when nothing is.
  String? headline({Uint8List? thisDevice}) {
    String when(DateTime? t) => t == null ? 'soon' : '${_date(t)} UTC';
    final toThisDevice =
        thisDevice != null && newKey != null && bytesEqual(newKey!, thisDevice);
    switch (stage) {
      case RecoveryStage.pending:
        return '${toThisDevice ? 'Your guardians are moving your account '
                      'to this phone' : 'Your guardians are recovering your '
                      'account to a new key'}: $approvals of $approvalsRequired '
            'approved. It can take over from ${when(takesOverAt)} and lapses '
            '${when(expiresAt)}.';
      case RecoveryStage.contested:
        return 'A recovery was contested: your account is frozen while '
            'your guardians decide ($approvals of $approvalsRequired '
            'approved). It lapses ${when(expiresAt)}.';
      case RecoveryStage.none:
        if (guardianFrozen) {
          return 'Your guardians froze this account. Only they, or a '
              'completed recovery, can lift it.';
        }
        if (frozen) {
          return 'This account is frozen: nothing can be paid out of it.';
        }
        if (pendingChangeAt != null) {
          return 'A change to your guardians takes effect '
              '${when(pendingChangeAt)}.';
        }
        return null;
    }
  }
}

String _date(DateTime t) {
  final u = t.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${u.year}-${two(u.month)}-${two(u.day)} '
      '${two(u.hour)}:${two(u.minute)}';
}
