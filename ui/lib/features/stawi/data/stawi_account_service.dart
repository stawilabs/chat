import 'dart:convert';
import 'dart:typed_data';

import 'package:antinvestor_api_authentication/antinvestor_api_authentication.dart'
    as authentication;
import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../domain/account_engine_calls.dart';
import '../domain/signing_checks.dart';
import '../domain/stawi_money.dart';
import 'device_key_store.dart';
import 'stawi_clients.dart';
import 'stawi_identity.dart';

/// Issues the authentication service's genesis session proof (P26): proof
/// that this profile held a live session on this device when its first key
/// was registered, binding the key whose address is [deviceAddress]
/// (pubkey_hash = keccak256(address)). DeployAccount requires one.
typedef GenesisSessionProofs =
    Future<Uint8List> Function({required Uint8List deviceAddress});

/// The proof from the authentication service's IssueGenesisSessionProof,
/// bound to the caller's own live session and device (taken from the token,
/// never from the request). Settlement takes the token as its UTF-8 bytes.
GenesisSessionProofs authenticationSessionProofs(
  authentication.AuthenticationServiceClient client,
) => ({required Uint8List deviceAddress}) async {
  final response = await client.issueGenesisSessionProof(
    authentication.IssueGenesisSessionProofRequest(
      pubkeyHash: bytesToHex(devicePubkeyHash(deviceAddress)),
      deviceKeyId: bytesToHex0x(deviceAddress).toLowerCase(),
    ),
  );
  if (response.token.isEmpty) {
    throw const StawiUnavailable('The sign-in service issued no session proof');
  }
  return Uint8List.fromList(utf8.encode(response.token));
};

final genesisSessionProofsProvider = Provider<GenesisSessionProofs>(
  (ref) => authenticationSessionProofs(ref.watch(authenticationProvider)),
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

  /// The account and this device's key. Reads only: nothing is signed, so
  /// the device lock is not asked.
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

  /// The primary account, deployed with a key of this device: deploys it the
  /// first time money is touched (a signature, so behind the device lock) and
  /// reads the chain every [every] until it is deployed, at most [attempts]
  /// times. Refuses a deployed account this device holds no key of, and
  /// gives up with [accountSetupPendingMessage] when the chain is slower;
  /// trying again picks the pending deployment up without deploying twice.
  Future<StawiAccountRef> ensureReady({
    Duration every = const Duration(seconds: 3),
    int attempts = 60,
  }) async {
    var s = await status();
    final account = s.account;
    if (account == null) {
      throw const StawiUnavailable('Your profile has no Stawi account yet');
    }
    if (!s.deployed && !_genesisUnderway.contains(s.genesisState)) {
      await deploy();
    }
    for (var i = 0; !s.deployed && i < attempts; i++) {
      await Future<void>.delayed(every);
      s = await status();
      if (s.genesisState == 'FAILED') {
        throw const StawiUnavailable(accountSetupFailedMessage);
      }
    }
    if (!s.deployed) {
      throw const StawiUnavailable(accountSetupPendingMessage);
    }
    if (!s.deviceRegistered) {
      throw const StawiUnavailable(deviceNotAKeyMessage);
    }
    return account;
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
    final key = await _keys.unlock(
      me.profileId,
      reason: 'Set up your Stawi account',
    );
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
    final digest = checkedDeployDigest(
      prepared: prepared,
      account: account.address,
      identitySaltHash: account.identitySaltHash,
      device: key.address,
    );
    final signature = key.sign(digest);
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
    final key = await _keys.unlock(
      me.profileId,
      reason: 'Add a device to your Stawi account',
    );
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

  /// Pays [amount] (integer minor units of the account's policy asset) from
  /// the member's primary account into the room whose custody is [custody].
  /// Straight to the chain through settlement; chat is not involved. The
  /// payment lands in the room's SAVINGS bucket and the room's rules engine
  /// applies it.
  ///
  /// [reason] is what the device lock shows the person before signing.
  Future<settlement.AccountCall> contribute({
    required Uint8List custody,
    required String amount,
    String reason = 'Pay into this room',
  }) async {
    if (custody.length != 20) {
      throw const FormatException('A room custody is a 20-byte address');
    }
    if (!_positiveDecimal.hasMatch(amount)) {
      throw const FormatException('Enter a whole amount greater than zero');
    }
    final me = await _identity();
    final account = me.primary;
    if (account == null) {
      throw const StawiUnavailable('Your profile has no Stawi account yet');
    }
    final key = await _keys.unlock(me.profileId, reason: reason);
    final prepared = await _accounts.prepareAccountCall(
      settlement.PrepareAccountCallRequest(
        address: account.address,
        kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_CONTRIBUTE,
        params: settlement.AccountCallParams(room: custody, amount: amount),
      ),
    );
    final digest = checkedContributionDigest(
      prepared: prepared,
      account: account.address,
      custody: custody,
      amount: amount,
    );
    final submitted = await _accounts.submitAccountCall(
      settlement.SubmitAccountCallRequest(
        callId: prepared.callId,
        authorization: key.sign(digest),
      ),
    );
    return submitted.call;
  }

  /// Prepares a loan or withdrawal call on the member's account and checks
  /// it on the device. Nothing is signed yet: the member sees
  /// [PreparedEngineCall.call] (a payoff's quoted ceiling, for one) first.
  /// [engines] is the room's live Room.engines; without them nothing is
  /// prepared, since the call could not be checked.
  Future<PreparedEngineCall> prepareEngineCall(
    AccountEngineRequest request, {
    required RoomEngineTargets? engines,
  }) async {
    if (engines == null) throw const SigningRefused(enginesUnknownReason);
    final account = (await _identity()).primary;
    if (account == null) {
      throw const StawiUnavailable('Your profile has no Stawi account yet');
    }
    final prepared = await _accounts.prepareAccountCall(
      settlement.PrepareAccountCallRequest(
        address: account.address,
        kind: request.call.kind,
        params: settlement.AccountCallParams(
          room: request.custody,
          amount: request.amount.isEmpty ? null : request.amount,
          loanId: request.call.takesLoan ? Int64(request.loanId) : null,
          productId: request.productId,
          instalments: request.call == AccountEngineCall.loanRequest
              ? request.instalments
              : null,
          replaces: request.replaces > 0 ? Int64(request.replaces) : null,
        ),
      ),
    );
    final checked = checkedEngineCall(
      prepared: prepared,
      request: request,
      account: account.address,
      engines: engines,
    );
    return PreparedEngineCall(
      callId: prepared.callId,
      digest: checked.digest,
      call: checked.call,
      request: request,
    );
  }

  /// Signs a prepared, checked engine call on this device and submits it.
  Future<settlement.AccountCall> submitEngineCall(
    PreparedEngineCall prepared,
  ) async {
    final me = await _identity();
    final key = await _keys.unlock(
      me.profileId,
      reason: prepared.request.summary,
    );
    return (await _accounts.submitAccountCall(
      settlement.SubmitAccountCallRequest(
        callId: prepared.callId,
        authorization: key.sign(prepared.digest),
      ),
    )).call;
  }

  /// Follows a submitted account call until it is final, failed or expired,
  /// reading it every [every]. Stops after [attempts] reads.
  Stream<settlement.AccountCall> followAccountCall(
    String callId, {
    Duration every = const Duration(seconds: 3),
    int attempts = 100,
  }) async* {
    for (var i = 0; i < attempts; i++) {
      final call = await accountCall(callId);
      yield call;
      if (accountCallSettled(call.state)) return;
      await Future<void>.delayed(every);
    }
  }

  /// The deployment's asset and whether its testnet faucet is on.
  Future<settlement.GetAssetResponse> testAsset() =>
      _accounts.getAsset(settlement.GetAssetRequest());

  /// Testnet faucet: mints [amount] of the test [asset] (as a person types
  /// it, "1000" or "12.5") to the member's primary account. Settlement
  /// refuses it unless the deployment enables it.
  Future<settlement.FundTestAccountResponse> fundTestAccount(
    String amount,
    StawiAsset asset,
  ) async {
    final units = parseAmountInput(amount, asset);
    final account = (await _identity()).primary;
    if (account == null) {
      throw const StawiUnavailable('Your profile has no Stawi account yet');
    }
    return _accounts.fundTestAccount(
      settlement.FundTestAccountRequest(
        address: account.address,
        amount: units,
      ),
    );
  }
}

/// An engine call settlement prepared and the device checked, awaiting the
/// member's go-ahead.
class PreparedEngineCall {
  const PreparedEngineCall({
    required this.callId,
    required this.digest,
    required this.call,
    required this.request,
  });

  final String callId;
  final Uint8List digest;

  /// What the account will do, decoded from the prepared calldata.
  final EngineCall call;
  final AccountEngineRequest request;
}

/// Settlement's genesis states for a deployment already on its way.
const Set<String> _genesisUnderway = {'PENDING', 'SUBMITTED'};

/// The chain has not finished deploying the account in the time allowed.
const String accountSetupPendingMessage =
    'Your Stawi account is still being set up; try again in a minute';

/// Settlement gave up on the account's deployment.
const String accountSetupFailedMessage =
    'Setting up your Stawi account failed; try again';

/// The account is deployed but this device holds none of its keys.
const String deviceNotAKeyMessage =
    'This device is not a key of your Stawi account. Add this device from '
    'one that is (Stawi account).';

final RegExp _positiveDecimal = RegExp(r'^[1-9][0-9]{0,77}$');

/// Whether an account call has reached a state it will not leave.
bool accountCallSettled(settlement.AccountCallState state) => switch (state) {
  settlement.AccountCallState.ACCOUNT_CALL_STATE_FINAL ||
  settlement.AccountCallState.ACCOUNT_CALL_STATE_FAILED ||
  settlement.AccountCallState.ACCOUNT_CALL_STATE_EXPIRED => true,
  _ => false,
};

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

/// The deployment's asset and whether the testnet faucet mints it.
final stawiTestAssetProvider =
    FutureProvider.autoDispose<settlement.GetAssetResponse>(
      (ref) => ref.watch(stawiAccountServiceProvider).testAsset(),
    );

final stawiAccountStatusProvider =
    FutureProvider.autoDispose<StawiAccountStatus>(
      (ref) => ref.watch(stawiAccountServiceProvider).status(),
    );

/// The account ready for money: watched by every money surface, so setup
/// starts by itself the first time one opens. It fails with a message (and
/// is retried by invalidating it) rather than waiting forever.
final stawiAccountReadyProvider = FutureProvider.autoDispose<StawiAccountRef>(
  (ref) => ref.watch(stawiAccountServiceProvider).ensureReady(),
);
