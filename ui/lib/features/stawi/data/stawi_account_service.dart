import 'dart:convert';
import 'dart:typed_data';

import 'package:antinvestor_api_authentication/antinvestor_api_authentication.dart'
    as authentication;
import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../core/networking/api_config.dart';
import '../domain/account_engine_calls.dart';
import '../domain/money_review.dart';
import '../domain/personal_calls.dart';
import '../domain/signing_checks.dart';
import '../domain/stawi_money.dart';
import 'device_key_store.dart';
import 'stawi_clients.dart';
import 'stawi_counterparty.dart';
import 'stawi_identity.dart';
import 'stawi_loan_service.dart';
import 'stawi_vault_service.dart';

/// Issues the authentication service's genesis session proof (P26): proof
/// that this profile held a live session on this device when its first key
/// was registered, binding the key whose address is [deviceAddress]
/// (pubkey_hash = keccak256(address)). DeployAccount requires one.
typedef GenesisSessionProofs = Future<Uint8List> Function({
  required Uint8List deviceAddress,
});

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
  final DevicePublicKey deviceKey;

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
    required this._accounts,
    required this._keys,
    required this._proofs,
    required this._identity,
    this._targets,
    this._loan,
    this._roomAssets,
    BigInt? deploymentChainId,
    this._readyEvery = const Duration(seconds: 3),
    this._readyAttempts = 60,
    this._followEvery = const Duration(seconds: 3),
  }) : _deploymentChainId =
           deploymentChainId ?? BigInt.from(ApiConfig.stawiChainId);

  final settlement.AccountServiceClient _accounts;
  final DeviceKeyStore _keys;
  final GenesisSessionProofs _proofs;
  final Future<StawiIdentity> Function() _identity;

  /// Finance's personal targets (the person's vault and the admitted loan
  /// books), read for every personal call; null reads as unknown, which
  /// refuses the call.
  final Future<PersonalTargets> Function()? _targets;

  /// The token addresses of a room's assets on its chain, as finance
  /// describes them (Room.assets); a contribution must pay in one.
  final Future<List<Uint8List>> Function(String roomId)? _roomAssets;

  /// The chain the deployment is on (the app's configuration): a key change
  /// is checked against it.
  final BigInt _deploymentChainId;

  /// How [ensureReady] polls when a money call finds the account not ready.
  final Duration _readyEvery;
  final int _readyAttempts;

  /// Finance's GetLoan, read while a loan is followed until it is active.
  final Future<finance.GetLoanResponse> Function(LoanRef ref)? _loan;

  /// How [followUntilActive] reads the call and the loan.
  final Duration _followEvery;

  /// How a submitted call is read until it is final.
  Duration get followEvery => _followEvery;

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
  /// times. A FAILED genesis is deployed again, at most once per call; a
  /// deployment that fails again ends with [accountSetupFailedMessage].
  /// Refuses a deployed account this device holds no key of, and gives up
  /// with [accountSetupPendingMessage] when the chain is slower; trying again
  /// picks the pending deployment up without deploying twice. Stops with
  /// [AccountSetupCancelled] once [cancelled] says so.
  Future<StawiAccountRef> ensureReady({
    Duration? every,
    int? attempts,
    bool Function()? cancelled,
  }) async {
    every ??= _readyEvery;
    attempts ??= _readyAttempts;
    void checkCancelled() {
      if (cancelled?.call() ?? false) throw const AccountSetupCancelled();
    }

    var s = await status();
    final account = s.account;
    if (account == null) {
      throw const StawiUnavailable('Your profile has no Stawi account yet');
    }
    var deployed = false;
    Future<void> deployOnce() async {
      if (deployed) throw const StawiUnavailable(accountSetupFailedMessage);
      deployed = true;
      checkCancelled();
      final response = await deploy();
      if (response.genesisState == 'FAILED') {
        throw const StawiUnavailable(accountSetupFailedMessage);
      }
    }

    if (!s.deployed && !_genesisUnderway.contains(s.genesisState)) {
      await deployOnce();
    }
    for (var i = 0; !s.deployed && i < attempts; i++) {
      await Future<void>.delayed(every);
      checkCancelled();
      s = await status();
      if (!s.deployed && s.genesisState == 'FAILED') await deployOnce();
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

  /// Prepares adding another device's key, [keyAddress] (the 20-byte key id
  /// the person typed), to the account and checks it on the device: the op
  /// adds exactly that key and the signed intent binds it. Nothing is signed
  /// yet: [PreparedMoneyCall.review] names the key and the delay, and
  /// [submit] signs it behind the device lock. The account applies it after
  /// its key-change delay.
  Future<PreparedMoneyCall> prepareAddKey(Uint8List keyAddress) async {
    if (keyAddress.length != 20 || keyAddress.every((b) => b == 0)) {
      throw const FormatException('A device key id is a 20-byte address');
    }
    final me = await _identity();
    final account = me.primary;
    if (account == null) {
      throw const StawiUnavailable('Your profile has no Stawi account yet');
    }
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
    final digest = checkedAddKey(
      prepared: prepared,
      account: account.address,
      key: keyAddress,
      chainId: _deploymentChainId,
    );
    return PreparedMoneyCall._(
      callId: prepared.callId,
      digest: digest,
      kind: kind,
      review: MoneyReview.addKey(key: keyAddress),
    );
  }

  Future<settlement.AccountCall> accountCall(String callId) async =>
      (await _accounts.getAccountCall(
        settlement.GetAccountCallRequest(callId: callId),
      )).call;

  /// The personal targets, or null when they cannot be read (which refuses
  /// every personal call, since none could be checked).
  Future<PersonalTargets?> _personalTargets() async {
    final read = _targets;
    if (read == null) return null;
    try {
      return await read();
    } on Object {
      return null;
    }
  }

  /// The token addresses of [roomId]'s assets; null when unknown (which
  /// refuses the contribution).
  Future<List<Uint8List>?> _roomAssetsOf(String roomId) async {
    final read = _roomAssets;
    if (read == null) return null;
    try {
      return await read(roomId);
    } on Object {
      return null;
    }
  }

  /// The deployment's asset token, read on its own; null when unknown.
  Future<Uint8List?> _deploymentAsset() async {
    try {
      final token = (await testAsset()).asset.tokenAddress;
      return token.length == 20 ? Uint8List.fromList(token) : null;
    } on Object {
      return null;
    }
  }

  /// The asset every personal amount is in: the deployment's.
  Future<StawiAsset> _asset() async {
    final info = (await testAsset()).asset;
    return info.assetId.isEmpty
        ? const StawiAsset.unknown('')
        : StawiAsset.fromInfo(info);
  }

  /// Prepares a loan or savings call on the person's own account and checks
  /// it on the device. Nothing is signed yet: [PreparedMoneyCall.review] is
  /// what they are shown first. [counterpartyName] and [pocketName] only
  /// word the review.
  Future<PreparedMoneyCall> preparePersonal(
    PersonalRequest request, {
    String? counterpartyName,
    String? pocketName,
  }) async {
    final account = await ensureReady();
    final targets = await _personalTargets();
    final prepared = await _accounts.prepareAccountCall(
      settlement.PrepareAccountCallRequest(
        address: account.address,
        kind: request.call.kind,
        params: request.params,
      ),
    );
    final checked = checkedPersonalCall(
      prepared: prepared,
      request: request,
      account: account.address,
      personal: targets,
    );
    return PreparedMoneyCall._(
      callId: prepared.callId,
      digest: checked.digest,
      kind: request.call.kind,
      call: checked.call,
      review: MoneyReview.personal(
        request,
        checked.call,
        asset: await _asset(),
        counterpartyName: counterpartyName,
        pocketName: pocketName,
        me: account.address,
      ),
    );
  }

  /// Adds [amount] to the person's own [pocket] (32 zero bytes: free
  /// savings).
  Future<PreparedMoneyCall> prepareDeposit({
    required Uint8List pocket,
    required BigInt amount,
    String? pocketName,
  }) async {
    final account = await ensureReady();
    final targets = await _personalTargets();
    final prepared = await _accounts.prepareAccountCall(
      settlement.PrepareAccountCallRequest(
        address: account.address,
        kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_VAULT_DEPOSIT,
        params: settlement.AccountCallParams(
          pocket: pocket.every((b) => b == 0) ? null : pocket,
          amount: amount.toString(),
        ),
      ),
    );
    final digest = checkedVaultDeposit(
      prepared: prepared,
      account: account.address,
      pocket: pocket,
      amount: amount,
      personal: targets,
    );
    return PreparedMoneyCall._(
      callId: prepared.callId,
      digest: digest,
      kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_VAULT_DEPOSIT,
      review: MoneyReview.deposit(
        amount: amount,
        pocketName:
            pocketName ??
            (pocket.every((b) => b == 0) ? 'Free savings' : 'Savings goal'),
        asset: await _asset(),
      ),
    );
  }

  /// Turns [loan]'s automatic payment [on] or off. Only an active loan the
  /// person borrowed gets one.
  Future<PreparedMoneyCall> prepareStandingOrder(
    finance.Loan loan, {
    required bool on,
    String? title,
  }) async {
    final account = await ensureReady();
    final kind = on
        ? settlement.AccountCallKind.ACCOUNT_CALL_KIND_GRANT_STANDING
        : settlement.AccountCallKind.ACCOUNT_CALL_KIND_REVOKE_STANDING;
    final params = on ? standingOrderParams(loan) : standingRevokeParams(loan);
    final targets = on ? await _personalTargets() : null;
    final policyAsset = (await status()).state?.policy.asset ?? const <int>[];
    if (policyAsset.length != 20 || policyAsset.every((b) => b == 0)) {
      throw const SigningRefused(
        'your account\'s asset could not be read just now, so the automatic '
        'payment cannot be checked; try again shortly',
      );
    }
    final prepared = await _accounts.prepareAccountCall(
      settlement.PrepareAccountCallRequest(
        address: account.address,
        kind: kind,
        params: params,
      ),
    );
    final asset = await _asset();
    final Uint8List digest;
    var perInstalment = BigInt.zero;
    if (on) {
      final checked = checkedStandingGrant(
        prepared: prepared,
        account: account.address,
        loan: loan,
        personal: targets,
        policyAsset: policyAsset,
      );
      digest = checked.digest;
      perInstalment = checked.grant.maxPerPeriod;
    } else {
      digest = checkedStandingRevoke(
        prepared: prepared,
        account: account.address,
        loan: loan,
        policyAsset: policyAsset,
      );
    }
    return PreparedMoneyCall._(
      callId: prepared.callId,
      digest: digest,
      kind: kind,
      review: MoneyReview.standingOrder(
        loan: loan,
        on: on,
        asset: asset,
        perInstalment: perInstalment,
        title: title,
      ),
    );
  }

  /// Sends [amount] from the wallet to [to], a Stawi account found for a
  /// contact. There is no free-text address: only the counterparty lookup
  /// builds a [StawiContactAccount].
  Future<PreparedMoneyCall> prepareTransferOut({
    required StawiContactAccount to,
    required BigInt amount,
  }) async {
    final account = await ensureReady();
    final prepared = await _accounts.prepareAccountCall(
      settlement.PrepareAccountCallRequest(
        address: account.address,
        kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_TRANSFER,
        params: settlement.AccountCallParams(
          amount: amount.toString(),
          destination: finance.ValueLocation(
            kind: finance.LocationKind.LOCATION_KIND_USER_ACCOUNT,
            address: to.address,
          ),
        ),
      ),
    );
    final digest = checkedTransferOut(
      prepared: prepared,
      account: account.address,
      to: to.address,
      amount: amount,
      asset: await _deploymentAsset(),
    );
    return PreparedMoneyCall._(
      callId: prepared.callId,
      digest: digest,
      kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_TRANSFER,
      review: MoneyReview.transferOut(
        to: to.address,
        amount: amount,
        asset: await _asset(),
        name: to.name,
      ),
    );
  }

  /// Pays [amount] (integer minor units) from the person's account into the
  /// room whose custody is [custody]; the room's rules apply it. [title]
  /// words the review around the checked amount, formatted.
  Future<PreparedMoneyCall> prepareContribution({
    required String roomId,
    required Uint8List custody,
    required String amount,
    String roomName = 'this room',
    String? note,
    String Function(String amount)? title,
  }) async {
    if (custody.length != 20) {
      throw const FormatException('A room custody is a 20-byte address');
    }
    if (!_positiveDecimal.hasMatch(amount)) {
      throw const FormatException('Enter a whole amount greater than zero');
    }
    final account = await ensureReady();
    final prepared = await _accounts.prepareAccountCall(
      settlement.PrepareAccountCallRequest(
        address: account.address,
        kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_CONTRIBUTE,
        params: settlement.AccountCallParams(room: custody, amount: amount),
      ),
    );
    final (:digest, amount: checkedAmount) = checkedContribution(
      prepared: prepared,
      account: account.address,
      custody: custody,
      amount: amount,
      roomAssets: await _roomAssetsOf(roomId),
    );
    return PreparedMoneyCall._(
      callId: prepared.callId,
      digest: digest,
      kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_CONTRIBUTE,
      review: MoneyReview.contribution(
        amount: BigInt.parse(checkedAmount.toString()),
        roomName: roomName,
        asset: await _asset(),
        note: note,
        title: title,
      ),
    );
  }

  /// Prepares a loan or withdrawal call on the member's account and checks
  /// it on the device. Nothing is signed yet: the member sees
  /// [PreparedMoneyCall.call] (a payoff's quoted ceiling, for one) first.
  /// [engines] is the room's live Room.engines; without them nothing is
  /// prepared, since the call could not be checked.
  Future<PreparedMoneyCall> prepareEngineCall(
    AccountEngineRequest request, {
    required RoomEngineTargets? engines,
    String? feeLine,
    List<(String, String)> quoteLines = const [],
  }) async {
    if (engines == null) throw const SigningRefused(enginesUnknownReason);
    final account = await ensureReady();
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
    return PreparedMoneyCall._(
      callId: prepared.callId,
      digest: checked.digest,
      kind: request.call.kind,
      call: checked.call,
      review: MoneyReview.engine(
        request,
        checked.call,
        feeLine: feeLine,
        quoteLines: quoteLines,
      ),
    );
  }

  /// Signs a prepared, checked call on this device and submits it. The
  /// device lock shows the review's plain title.
  Future<settlement.AccountCall> submit(PreparedMoneyCall prepared) async =>
      submitSigned(await signCall(prepared));

  /// Signs a prepared, checked call on this device, behind the device lock
  /// (which shows the review's plain title). Nothing is sent.
  Future<SignedMoneyCall> signCall(PreparedMoneyCall prepared) async {
    final me = await _identity();
    final key = await _keys.unlock(me.profileId, reason: prepared.review.title);
    return SignedMoneyCall._(
      callId: prepared.callId,
      authorization: key.sign(prepared.digest),
      review: prepared.review,
    );
  }

  /// Submits [signed]. Settlement takes a call once: the same signed call
  /// again answers the call as it stands, so this is safe to repeat when an
  /// earlier submit's answer was lost.
  Future<settlement.AccountCall> submitSigned(SignedMoneyCall signed) async =>
      (await _accounts.submitAccountCall(
        settlement.SubmitAccountCallRequest(
          callId: signed.callId,
          authorization: signed.authorization,
        ),
      )).call;

  /// Whether [loan]'s standing order (automatic payment) is on, read off the
  /// account's authorizations.
  Future<bool> standingOrderOn(finance.Loan loan) =>
      standingOrderOnRef(LoanRef.of(loan));

  /// Whether the standing order of the loan [ref] names is on.
  Future<bool> standingOrderOnRef(LoanRef ref) async {
    final id = standingOrderId(ref.loanBook, ref.pool, ref.loanId);
    final state = (await status()).state;
    return state?.authorizationIds.any((a) => bytesEqual(a, id)) ?? false;
  }

  /// The wallet: the account's balance of the deployment's asset in minor
  /// units. Null when the chain could not be read: unknown, never zero.
  Future<BigInt?> walletBalance() async {
    final raw = (await status()).state?.balance ?? '';
    return raw.isEmpty ? null : BigInt.tryParse(raw);
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

  /// Follows a loan the person just made or accepted until it is active
  /// (FUNDED) or has ended: first the account call [callId], when given,
  /// until it is final, then finance's GetLoan of [ref] every [every], at
  /// most [attempts] reads each. Returns the last loan read, which is not
  /// active when the chain was slower than that; a call that failed or
  /// expired is a [StawiUnavailable]. A loan finance names otherwise than
  /// [ref] is refused: nothing is granted against another loan.
  Future<finance.Loan> followUntilActive(
    LoanRef ref, {
    String? callId,
    Duration? every,
    int attempts = 40,
  }) async {
    every ??= _followEvery;
    final read = _loan;
    if (read == null) {
      throw const StawiUnavailable('Loans cannot be read just now');
    }
    if (callId != null) {
      settlement.AccountCall? last;
      await for (final call in followAccountCall(
        callId,
        every: every,
        attempts: attempts,
      )) {
        last = call;
      }
      final state = last?.state;
      if (state == settlement.AccountCallState.ACCOUNT_CALL_STATE_FAILED ||
          state == settlement.AccountCallState.ACCOUNT_CALL_STATE_EXPIRED) {
        final why = last?.failureReason ?? '';
        throw StawiUnavailable(
          why.isEmpty ? 'It did not go through; try again' : 'Not done: $why',
        );
      }
    }
    for (var i = 1; ; i++) {
      final loan = (await read(ref)).loan;
      if (LoanRef.of(loan) != ref) {
        throw const StawiUnavailable('Finance answered with another loan');
      }
      if (_loanSettled(loan.state) || i >= attempts) return loan;
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

/// A call settlement prepared and the device checked, awaiting the person's
/// go-ahead: what they see ([review]) and the digest the device signs. Only
/// the checked `prepare*` methods of [StawiAccountService] build one, so a
/// digest that was not checked cannot reach [StawiAccountService.submit].
class PreparedMoneyCall {
  const PreparedMoneyCall._({
    required this.callId,
    required this.digest,
    required this.review,
    required this.kind,
    this.call,
  });

  final String callId;
  final Uint8List digest;
  final MoneyReview review;
  final settlement.AccountCallKind kind;

  /// What the account will do, decoded from the prepared calldata; null for a
  /// call that is not an engine call.
  final EngineCall? call;
}

/// A prepared call signed on this device: exactly what is submitted, kept so
/// that a submit whose answer was lost is repeated as the same call, never
/// prepared again (a new prepare takes the next nonce and pays twice).
class SignedMoneyCall {
  const SignedMoneyCall._({
    required this.callId,
    required this.authorization,
    required this.review,
  });

  final String callId;
  final Uint8List authorization;
  final MoneyReview review;
}

/// Settlement's genesis states for a deployment already on its way.
const Set<String> _genesisUnderway = {'PENDING', 'SUBMITTED'};

/// The chain has not finished deploying the account in the time allowed.
const String accountSetupPendingMessage =
    'Your Stawi account is still being set up; try again in a minute';

/// Settlement gave up on the account's deployment.
const String accountSetupFailedMessage =
    'Setting up your Stawi account failed; try again';

/// [StawiAccountService.ensureReady] stopped because nobody is waiting for it
/// any more.
final class AccountSetupCancelled implements Exception {
  const AccountSetupCancelled();

  @override
  String toString() => 'Stawi account setup stopped';
}

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

/// Whether a loan is active or will never become active.
bool _loanSettled(finance.LoanState state) => switch (state) {
  finance.LoanState.LOAN_STATE_FUNDED ||
  finance.LoanState.LOAN_STATE_PAID ||
  finance.LoanState.LOAN_STATE_DEFAULTED ||
  finance.LoanState.LOAN_STATE_WRITTEN_OFF ||
  finance.LoanState.LOAN_STATE_REJECTED ||
  finance.LoanState.LOAN_STATE_CANCELLED => true,
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
    targets: () => ref.read(stawiVaultServiceProvider).targets(),
    loan: (loanRef) => ref.read(stawiLoanServiceProvider).loan(loanRef),
    roomAssets: financeRoomAssets(ref.watch(financeRoomsProvider)),
  );
});

/// The token addresses of a room's assets on its chain, from finance GetRoom
/// (Room.assets).
Future<List<Uint8List>> Function(String roomId) financeRoomAssets(
  finance.RoomServiceClient rooms,
) => (roomId) async {
  final room = (await rooms.getRoom(finance.GetRoomRequest(roomId: roomId)))
      .room;
  return [
    for (final a in room.assets)
      if (a.chainId == room.chainId && a.tokenAddress.length == 20)
        Uint8List.fromList(a.tokenAddress),
  ];
};

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
final stawiAccountReadyProvider = FutureProvider.autoDispose<StawiAccountRef>((
  ref,
) {
  var disposed = false;
  ref.onDispose(() => disposed = true);
  return ref
      .watch(stawiAccountServiceProvider)
      .ensureReady(cancelled: () => disposed);
});

/// The wallet's balance; null when unknown (shown as "—", never 0).
final stawiWalletBalanceProvider = FutureProvider.autoDispose<BigInt?>(
  (ref) => ref.watch(stawiAccountServiceProvider).walletBalance(),
);

/// The clock money screens read "now" from (an offer's expiry, for one), so
/// tests can fix it.
final stawiClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
