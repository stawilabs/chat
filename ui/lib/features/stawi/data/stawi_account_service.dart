import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../domain/signing_checks.dart';
import 'device_key_store.dart';
import 'stawi_clients.dart';
import 'stawi_identity.dart';

/// Issues the authentication service's genesis session proof (P26): proof
/// that this profile held a live session on this device when its first key
/// was registered, binding the key whose address is [deviceAddress]
/// (pubkey_hash = keccak256(address)). DeployAccount requires one.
typedef GenesisSessionProofs =
    Future<Uint8List> Function({required Uint8List deviceAddress});

/// The app has no generated client for the authentication service's genesis
/// session-proof endpoint, so account deployment cannot complete from this
/// build yet.
Future<Uint8List> unavailableGenesisSessionProof({
  required Uint8List deviceAddress,
}) async => throw const StawiUnavailable(
  'Deploying an account needs a genesis session proof, which this version '
  'of the app cannot request yet.',
);

final genesisSessionProofsProvider = Provider<GenesisSessionProofs>(
  (ref) => unavailableGenesisSessionProof,
);

/// The profile's account as the account screen shows it.
class StawiAccountStatus {
  const StawiAccountStatus({
    required this.account,
    required this.state,
    required this.deviceKey,
  });

  /// The primary account profile names; null when the profile has none.
  final StawiAccountRef? account;

  /// The account read off the chain; null when there is no account.
  final settlement.AccountState? state;

  /// This device's key for the profile.
  final DeviceKeyHandle deviceKey;

  bool get deployed => state?.deployed ?? false;

  /// Whether this device's key is an active key of the account.
  bool get deviceRegistered =>
      state?.keys.any(
        (k) => k.active && bytesEqual(k.key, deviceKey.address),
      ) ??
      false;

  /// Settlement's genesis process for the address: PENDING, SUBMITTED,
  /// DEPLOYED or FAILED; empty when none ran.
  String get genesisState => state?.genesisState ?? '';
}

/// The account flows: read the account, deploy it under this device's key,
/// and add further device keys. Settlement builds every digest; the device
/// signs it here after checking it.
class StawiAccountService {
  StawiAccountService({
    required settlement.AccountServiceClient accounts,
    required DeviceKeyStore keys,
    required GenesisSessionProofs proofs,
    required Future<StawiIdentity> Function() identity,
  }) : _accounts = accounts,
       _keys = keys,
       _proofs = proofs,
       _identity = identity;

  final settlement.AccountServiceClient _accounts;
  final DeviceKeyStore _keys;
  final GenesisSessionProofs _proofs;
  final Future<StawiIdentity> Function() _identity;

  Future<StawiAccountStatus> status() async {
    final me = await _identity();
    final key = await _keys.loadOrCreate(me.profileId);
    final account = me.primary;
    if (account == null) {
      return StawiAccountStatus(account: null, state: null, deviceKey: key);
    }
    final response = await _accounts.getAccount(
      settlement.GetAccountRequest(address: account.address),
    );
    return StawiAccountStatus(
      account: account,
      state: response.account,
      deviceKey: key,
    );
  }

  /// Deploys the profile's primary account with this device's key as its
  /// first device: settlement returns the genesis digest, the device signs
  /// it, and settlement attests and relays the deployment.
  Future<settlement.DeployAccountResponse> deploy() async {
    final me = await _identity();
    final account = me.primary;
    if (account == null) {
      throw const StawiUnavailable('Your profile has no Stawi account yet');
    }
    final key = await _keys.loadOrCreate(me.profileId);
    final deviceKey = settlement.DeviceKey(
      publicKey: key.publicKey,
      algorithm: settlement.DeviceKeyAlgorithm.DEVICE_KEY_ALGORITHM_SECP256K1,
    );
    final prepared = await _accounts.prepareDeployAccount(
      settlement.PrepareDeployAccountRequest(
        address: account.address,
        deviceKey: deviceKey,
      ),
    );
    if (!bytesEqual(prepared.device, key.address)) {
      throw const SigningRefused(
        'settlement prepared the genesis for another device key',
      );
    }
    if (prepared.genesisDigest.length != 32) {
      throw const SigningRefused('the genesis digest is malformed');
    }
    final signature = key.sign(prepared.genesisDigest);
    final proof = await _proofs(deviceAddress: key.address);
    return _accounts.deployAccount(
      settlement.DeployAccountRequest(
        address: account.address,
        deviceKey: deviceKey,
        deviceSignature: signature,
        sessionProof: proof,
      ),
    );
  }

  /// Adds another device's key to the account, signed by this device (an
  /// active key). The account applies it after its key-change delay.
  Future<settlement.AccountCall> addDeviceKey(Uint8List keyAddress) async {
    if (keyAddress.length != 20) {
      throw const FormatException('A device key id is a 20-byte address');
    }
    final me = await _identity();
    final account = me.primary;
    if (account == null) {
      throw const StawiUnavailable('Your profile has no Stawi account yet');
    }
    final key = await _keys.loadOrCreate(me.profileId);
    const kind = settlement.AccountCallKind.ACCOUNT_CALL_KIND_ADD_KEY;
    final prepared = await _accounts.prepareAccountCall(
      settlement.PrepareAccountCallRequest(
        address: account.address,
        kind: kind,
        params: settlement.AccountCallParams(
          key: keyAddress,
          algorithm:
              settlement.DeviceKeyAlgorithm.DEVICE_KEY_ALGORITHM_SECP256K1,
        ),
      ),
    );
    final digest = checkedAccountCallDigest(
      prepared: prepared,
      kind: kind,
      account: account.address,
    );
    final submitted = await _accounts.submitAccountCall(
      settlement.SubmitAccountCallRequest(
        callId: prepared.callId,
        authorization: key.sign(digest),
      ),
    );
    return submitted.call;
  }

  Future<settlement.AccountCall> accountCall(String callId) async =>
      (await _accounts.getAccountCall(
        settlement.GetAccountCallRequest(callId: callId),
      )).call;
}

/// Parses a device key id typed or pasted by the member.
Uint8List parseKeyAddress(String text) {
  final bytes = hexToBytes(text.trim());
  if (bytes.length != 20) {
    throw const FormatException('A device key id is a 20-byte address');
  }
  return bytes;
}

final stawiAccountServiceProvider = Provider<StawiAccountService>((ref) {
  return StawiAccountService(
    accounts: ref.watch(settlementAccountsProvider),
    keys: ref.watch(deviceKeyStoreProvider),
    proofs: ref.watch(genesisSessionProofsProvider),
    identity: () => ref.read(stawiIdentityProvider.future),
  );
});

final stawiAccountStatusProvider =
    FutureProvider.autoDispose<StawiAccountStatus>(
      (ref) => ref.watch(stawiAccountServiceProvider).status(),
    );
