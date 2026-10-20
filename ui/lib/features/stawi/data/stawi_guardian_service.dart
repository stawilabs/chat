import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../core/networking/api_config.dart';
import '../domain/guardian_acts.dart';
import '../domain/money_review.dart';
import '../domain/signing_checks.dart' show SigningRefused, bytesEqual;
import 'device_key_store.dart';
import 'stawi_account_service.dart';
import 'stawi_clients.dart';
import 'stawi_identity.dart';

/// Whether this phone can guard other people's accounts, and why not.
enum GuardianKeyState {
  /// The account is not on chain yet.
  noAccount,

  /// This phone's key is not an active key of the person's account.
  notAKey,

  /// This phone's key is a P-256 passkey: the account contract only takes
  /// secp256k1 guardian signatures.
  passkey,

  /// This phone's secp256k1 key can guard.
  ready,
}

/// This phone as a guardian: its key and whether it can guard.
final class GuardianKeyStatus {
  const GuardianKeyStatus({
    required this.state,
    required this.key,
    this.account,
  });

  final GuardianKeyState state;

  /// This phone's key: the guardian key an owner names.
  final Uint8List key;

  /// The person's own account the key is a device key of.
  final Uint8List? account;
}

/// A guardian act settlement prepared and the device checked
/// ([StawiGuardianService.prepareAct]), awaiting the guardian's review.
final class PreparedGuardianAct {
  const PreparedGuardianAct._({
    required this.callId,
    required this.digest,
    required this.review,
  });

  final String callId;
  final Uint8List digest;

  /// Shown before signing; its title is the lock prompt.
  final MoneyReview review;
}

/// Guarding other people's accounts with this phone's key (stawi v0.2.6):
/// register the key as the profile's guardian key (its proof signed behind
/// the device lock), read the accounts it guards, and start or approve a
/// recovery of one, checked on the device and signed behind the lock.
class StawiGuardianService {
  StawiGuardianService({
    required this._accounts,
    required this._keys,
    required this._identity,
    required this._status,
    BigInt? deploymentChainId,
  }) : _chainId = deploymentChainId ?? BigInt.from(ApiConfig.stawiChainId);

  final settlement.AccountServiceClient _accounts;
  final DeviceKeyStore _keys;
  final Future<StawiIdentity> Function() _identity;
  final Future<StawiAccountStatus> Function() _status;
  final BigInt _chainId;

  /// Whether this phone's key can guard: the account's own record of the
  /// key says whether it is an active key and which algorithm it is.
  Future<GuardianKeyStatus> keyStatus() async {
    final s = await _status();
    final key = s.deviceKey.address;
    final state = s.state;
    if (s.account == null || state == null || !s.deployed) {
      return GuardianKeyStatus(state: GuardianKeyState.noAccount, key: key);
    }
    final record = state.keys
        .where((k) => k.active && bytesEqual(k.key, key))
        .firstOrNull;
    return GuardianKeyStatus(
      state: record == null
          ? GuardianKeyState.notAKey
          : record.algorithm ==
                settlement.DeviceKeyAlgorithm.DEVICE_KEY_ALGORITHM_P256
          ? GuardianKeyState.passkey
          : GuardianKeyState.ready,
      key: key,
      account: Uint8List.fromList(state.address),
    );
  }

  /// Registers this phone's key as the profile's guardian key: the key signs
  /// the guardian key proof (stawi_finance_sdk guardianKeyProofDigest over
  /// the deployment's chain, the person's account, the key and the profile)
  /// behind the device lock, and settlement checks it. Idempotent.
  Future<settlement.RegisterGuardianKeyResponse> registerGuardianKey() async {
    final status = await keyStatus();
    switch (status.state) {
      case GuardianKeyState.noAccount:
        throw const StawiUnavailable('Your account is not on chain yet');
      case GuardianKeyState.notAKey:
        throw const StawiUnavailable(deviceNotAKeyMessage);
      case GuardianKeyState.passkey:
        throw const StawiUnavailable(p256CannotGuardNote);
      case GuardianKeyState.ready:
        break;
    }
    final me = await _identity();
    final digest = guardianKeyProofDigest(
      chainId: _chainId,
      account: status.account!,
      key: status.key,
      profileId: me.profileId,
    );
    final key = await _keys.unlock(
      me.profileId,
      reason: 'Register this phone as a guardian key',
    );
    if (!bytesEqual(key.address, status.key)) {
      throw const SigningRefused('this phone\'s key changed');
    }
    return _accounts.registerGuardianKey(
      settlement.RegisterGuardianKeyRequest(
        account: status.account,
        key: status.key,
        signature: key.sign(digest),
      ),
    );
  }

  /// The accounts this person guards, read at the head.
  Future<List<settlement.GuardedAccount>> guarded() async =>
      (await _accounts.listGuardedAccounts(
        settlement.ListGuardedAccountsRequest(),
      )).accounts;

  /// Prepares the guardian act [kind] (REQUEST_RECOVERY with the owner's
  /// [newKey], or APPROVE_RECOVERY) on [address] and checks it on the
  /// device against the account as GetGuardedAccount reads it now
  /// ([checkedGuardianAct]). Nothing is signed yet.
  Future<PreparedGuardianAct> prepareAct({
    required Uint8List address,
    required settlement.AccountCallKind kind,
    Uint8List? newKey,
  }) async {
    final status = await keyStatus();
    if (status.state == GuardianKeyState.passkey) {
      throw const StawiUnavailable(p256CannotGuardNote);
    }
    final guarded = (await _accounts.getGuardedAccount(
      settlement.GetGuardedAccountRequest(address: address),
    )).account;
    if (!bytesEqual(guarded.guardian, status.key)) {
      throw const StawiUnavailable(
        'This phone\'s key is not the one that guards that account',
      );
    }
    final view = GuardedView(guarded);
    final request =
        kind == settlement.AccountCallKind.ACCOUNT_CALL_KIND_REQUEST_RECOVERY;
    if (request ? !view.canRequest : !view.canApprove) {
      throw StawiUnavailable(
        request
            ? 'A recovery of that account is already under way'
            : 'No recovery of that account is waiting for approvals',
      );
    }
    final prepared = await _accounts.prepareAccountCall(
      settlement.PrepareAccountCallRequest(
        address: address,
        kind: kind,
        params: settlement.AccountCallParams(
          guardian: status.key,
          key: request ? newKey : null,
          algorithm: request
              ? settlement.DeviceKeyAlgorithm.DEVICE_KEY_ALGORITHM_SECP256K1
              : null,
        ),
      ),
    );
    final digest = checkedGuardianAct(
      prepared: prepared,
      kind: kind,
      guarded: guarded,
      guardianKey: status.key,
      chainId: _chainId,
      newKey: newKey,
    );
    final to = request ? newKey! : view.newKey!;
    return PreparedGuardianAct._(
      callId: prepared.callId,
      digest: digest,
      review: MoneyReview.guardianAct(
        request: request,
        account: address,
        newKey: to,
        approvals: view.approvals,
        required: view.required,
        threshold: guarded.guardianThreshold,
      ),
    );
  }

  /// Signs a checked guardian act the person reviewed, with this phone's
  /// key behind the device lock (its review title), and submits it.
  Future<settlement.AccountCall> submitAct(PreparedGuardianAct prepared) async {
    final me = await _identity();
    final key = await _keys.unlock(me.profileId, reason: prepared.review.title);
    return (await _accounts.submitAccountCall(
      settlement.SubmitAccountCallRequest(
        callId: prepared.callId,
        authorization: key.sign(prepared.digest),
      ),
    )).call;
  }
}

final stawiGuardianServiceProvider = Provider<StawiGuardianService>((ref) {
  final accounts = ref.watch(stawiAccountServiceProvider);
  return StawiGuardianService(
    accounts: ref.watch(settlementAccountsProvider),
    keys: ref.watch(deviceKeyStoreProvider),
    identity: () => ref.read(stawiIdentityProvider.future),
    status: accounts.status,
  );
});

/// This phone as a guardian.
final stawiGuardianKeyStatusProvider =
    FutureProvider.autoDispose<GuardianKeyStatus>(
      (ref) => ref.watch(stawiGuardianServiceProvider).keyStatus(),
    );

/// The accounts this person guards.
final stawiGuardedAccountsProvider =
    FutureProvider.autoDispose<List<settlement.GuardedAccount>>(
      (ref) => ref.watch(stawiGuardianServiceProvider).guarded(),
    );
