import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import 'account_engine_calls.dart';
import 'intent_bridge.dart';
import 'loan_terms.dart';
import 'personal_calls.dart';
import 'proposal_documents.dart';
import 'stawi_payloads.dart';

/// Settlement builds every digest a device signs. Before the device signs one,
/// the app checks that the prepared call is the act the member asked for and
/// that the digest is StawiAccount's ERC-1271 wrapping of the call's typed hash
/// for the member's own account, so a wrong or substituted digest is never
/// signed.
base class SigningRefused implements Exception {
  const SigningRefused(this.reason);

  final String reason;

  @override
  String toString() => 'SigningRefused: $reason';
}

/// The room's contracts and chain as finance indexes the room
/// (Room.governance_address, Room.custody_address, Room.chain_id): what every
/// room call is checked against, never settlement's own word for them.
final class RoomContracts {
  const RoomContracts({required this.chainId, this.governance, this.custody});

  /// The GovernanceModule; null when finance names none yet.
  final Uint8List? governance;

  /// RoomCustody; null when finance names none yet.
  final Uint8List? custody;
  final BigInt chainId;

  /// The contract that verifies a call to [contract], or null when unknown.
  Uint8List? of(RoomContract contract) => switch (contract) {
    RoomContract.governance => governance,
    RoomContract.custody => custody,
  };
}

/// Why a room call is refused when the room's contracts are unknown.
const String roomContractsUnknownReason =
    'the room\'s contracts could not be read just now, so the call cannot '
    'be checked against them; try again shortly';

/// The digest to sign for a prepared room call: stawi_finance_sdk
/// verifyRoomCall rebuilds the call's typed hash from [expected] (the act
/// the person chose), the room's contract for it as finance knows it
/// ([room]), its chain and the signing [account], with the call's nonce and
/// deadline, and returns its account wrapping only when settlement's call is
/// exactly that. Settlement's typed hash is never signed on its word, so a
/// Leave can never carry a vote. A deadline at or before [now] is refused.
Uint8List checkedRoomCall({
  required settlement.PrepareRoomCallResponse prepared,
  required RoomCallExpected expected,
  required String chatRoomId,
  required Uint8List account,
  required RoomContracts? room,
  required DateTime now,
}) {
  if (room == null) throw const SigningRefused(roomContractsUnknownReason);
  if (account.length != 20 || account.every((b) => b == 0)) {
    throw const SigningRefused(noAccountReason);
  }
  final call = prepared.call;
  if (call.kind.value != expected.roomCallKind) {
    throw SigningRefused(
      'settlement prepared a ${roomCallKindName(call.kind)} call, not the '
      'act you chose',
    );
  }
  if (call.chatRoomId.isNotEmpty && call.chatRoomId != chatRoomId) {
    throw const SigningRefused('the call was prepared for another room');
  }
  if (!call.requiresSignature) {
    throw const SigningRefused('the call takes no signature');
  }
  if (!bytesEqual(prepared.signer, account) ||
      (call.signer.isNotEmpty && !bytesEqual(call.signer, account))) {
    throw const SigningRefused('the call is not signed by your account');
  }
  if (call.digest.isNotEmpty && !bytesEqual(call.digest, prepared.digest)) {
    throw const SigningRefused('the prepared digest is malformed');
  }
  final verifier = room.of(expected.contract);
  if (verifier == null) throw const SigningRefused(roomContractsUnknownReason);
  try {
    return verifyRoomCall(
      PreparedRoomCall(
        kind: call.kind.value,
        verifier: call.verifier,
        chainId: _chainId(call.chainId),
        signer: prepared.signer,
        nonce: _u64(call.nonce),
        deadline: _u64(call.deadline),
        params: call.params,
        typedHash: call.typedHash,
        digest: prepared.digest,
      ),
      expected: expected,
      verifier: verifier,
      account: account,
      chainId: room.chainId,
      now: BigInt.from(now.toUtc().millisecondsSinceEpoch ~/ 1000),
    );
  } on RoomCallException catch (e) {
    throw SigningRefused(switch (e.error) {
      RoomCallError.notTheCall || RoomCallError.paramsMismatch =>
        'settlement prepared something else: not the act you chose',
      RoomCallError.notTheRoomsContract =>
        'the call goes to a contract that is not this room\'s',
      RoomCallError.wrongChain => 'the call is for another chain',
      RoomCallError.notYourAccount => 'the call is not signed by your account',
      RoomCallError.typedHashMismatch =>
        'settlement\'s call does not say what you chose: it would sign '
            'another act',
      RoomCallError.digestMismatch =>
        'the digest is not your account\'s signature of this call',
      RoomCallError.expired => 'the call\'s deadline has passed; try again',
    });
    // verifyRoomCall reports malformed inputs as an ArgumentError.
    // ignore: avoid_catching_errors
  } on ArgumentError {
    throw const SigningRefused(roomContractsUnknownReason);
  }
}

/// The parameter word [index] of a checked room call (an officer's
/// invitation expiry is word 2).
BigInt roomCallWord(settlement.PrepareRoomCallResponse prepared, int index) {
  final p = prepared.call.params;
  if (p.length < 32 * (index + 1)) return BigInt.zero;
  return bytesToBigInt(p.sublist(32 * index, 32 * (index + 1)));
}

/// The digest a founder signs for a genesis, and the genesis it was checked
/// against. [card] is the genesis card chat posted in the room; settlement's
/// record must agree with it, and the device recomputes the genesis hash from
/// the record's contents (agent included, stawi_finance_sdk
/// verifyRoomGenesis), so what the founder reviews is what they sign.
({Uint8List digest, settlement.RoomGenesis genesis}) checkedGenesisDigest({
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
  _verifyGenesisContents(genesis);
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
  return (digest: Uint8List.fromList(founder.signingDigest), genesis: genesis);
}

/// Whether [genesis]'s agent address belongs to the profile it is shown as,
/// so the name a founder reviews is who the room pays. No agent needs no
/// check. A founder agent is checked against the founder's own account in the
/// genesis; anyone else against [resolvedAgentAccount], the account this
/// device found for that profile (a DM partner's, through chat), and is
/// unconfirmed without one.
bool genesisAgentConfirmed(
  settlement.RoomGenesis genesis, {
  Uint8List? resolvedAgentAccount,
}) {
  if (genesis.agent.isEmpty) return true;
  final agent = genesis.agent;
  if (agent.length != 20 || genesis.agentProfileId.isEmpty) return false;
  final founder = genesis.founders
      .where((f) => f.profileId == genesis.agentProfileId)
      .firstOrNull;
  if (founder != null) return bytesEqual(founder.account, agent);
  return resolvedAgentAccount != null &&
      bytesEqual(resolvedAgentAccount, agent);
}

/// Recomputes [genesis]'s hash from what it says: settlement's RoomGenesis
/// mapped onto the contract's genesis inputs.
void _verifyGenesisContents(settlement.RoomGenesis genesis) {
  final joinPolicy = switch (genesis.joinPolicy) {
    finance.RoomJoinPolicy.ROOM_JOIN_POLICY_PRIVATE => 0,
    finance.RoomJoinPolicy.ROOM_JOIN_POLICY_PUBLIC => 1,
    _ => throw const SigningRefused('the genesis does not say who can join'),
  };
  // The agent and the profile it is shown as are named together, or not at
  // all.
  if (genesis.agent.isEmpty != genesis.agentProfileId.isEmpty) {
    throw const SigningRefused('the genesis agent is not named');
  }
  try {
    verifyRoomGenesis(
      chainId: _chainId(genesis.chainId),
      factory: genesis.factory,
      constitutionHash: genesis.constitutionHash,
      financePolicyHash: genesis.financePolicyHash,
      securityPolicyHash: genesis.securityPolicyHash,
      asset: genesis.asset,
      initialMembers: [for (final f in genesis.founders) f.account],
      manifestVersion: genesis.manifestVersion,
      paramsHash: genesis.compiledSecurityParamsHash,
      roomBinding: genesis.roomBinding,
      joinPolicy: joinPolicy,
      agent: genesis.agent.isEmpty ? null : genesis.agent,
      genesisHash: genesis.genesisHash,
    );
    // verifyRoomGenesis reports a mismatch, or malformed contents, as an
    // ArgumentError.
    // ignore: avoid_catching_errors
  } on ArgumentError {
    throw const SigningRefused('the genesis hash does not match its contents');
  }
}

/// Why a call is refused when the device has no account address to check it
/// against: an empty address would "match" a call that names none.
const String noAccountReason = 'no account to sign from';

/// The digest to sign for a prepared device call on the member's account.
/// [account] must be the member's own 20-byte address, and the call must name
/// exactly it.
Uint8List checkedAccountCallDigest({
  required settlement.PrepareAccountCallResponse prepared,
  required settlement.AccountCallKind kind,
  required Uint8List account,
}) {
  if (account.length != 20 || account.every((b) => b == 0)) {
    throw const SigningRefused(noAccountReason);
  }
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

/// Why an add-key call that does not add the typed key is refused.
const String notTheTypedKey =
    'this would not add the device key you typed to your account';

/// The digest to sign for adding the device key [key] (a secp256k1 key's
/// 20-byte address) to [account]: an ADD_KEY whose op adds exactly [key] and
/// whose KEY_CHANGE intent binds that op (stawi_finance_sdk verifyAddKey),
/// with the digest the intent's own, on [chainId] (the app's deployment
/// configuration).
Uint8List checkedAddKey({
  required settlement.PrepareAccountCallResponse prepared,
  required Uint8List account,
  required Uint8List key,
  required BigInt chainId,
}) {
  if (key.length != 20 || key.every((b) => b == 0)) {
    throw const SigningRefused('that is not a device key id');
  }
  final digest = checkedAccountCallDigest(
    prepared: prepared,
    kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_ADD_KEY,
    account: account,
  );
  final intent = _intentOf(prepared, digest, account);
  final op = prepared.managementOp;
  if (!prepared.hasManagementOp() ||
      op.authorizationId.isNotEmpty ||
      op.hasAuth() ||
      op.hasPolicy()) {
    throw const SigningRefused(notTheTypedKey);
  }
  try {
    return verifyAddKey(
      intent,
      opKind: op.kind,
      opKey: op.key,
      expectedKey: key,
      account: account,
      // The deployment's chain from the app's own configuration, never the
      // one the prepared intent names.
      chainId: chainId,
      preparedDigest: digest,
    );
  } on KeyChangeException catch (e) {
    throw SigningRefused(switch (e.error) {
      KeyChangeError.notAnAddKey ||
      KeyChangeError.notTheKey ||
      KeyChangeError.opNotBound => notTheTypedKey,
      KeyChangeError.notThisAccount => 'the key change is for another account',
      KeyChangeError.notAKeyChange =>
        'settlement prepared something other than a key change',
      KeyChangeError.digestMismatch =>
        'the digest is not the prepared intent\'s',
    });
    // verifyAddKey reports malformed inputs as an ArgumentError.
    // ignore: avoid_catching_errors
  } on ArgumentError {
    throw const SigningRefused(notTheTypedKey);
  }
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

/// Why a money call is refused when the asset it must move is unknown.
const String assetUnknownReason =
    'the asset could not be read just now, so the call cannot be checked '
    'against it; try again shortly';

/// The digest to sign for a prepared contribution, and the amount it pays
/// (to review): the call must be a CONTRIBUTE from [account] of exactly
/// [amount] (integer minor units, greater than zero) into [custody], in one
/// of the room's assets as finance describes them ([roomAssets]: the token
/// addresses of Room.assets on the room's chain).
({Uint8List digest, BigInt amount}) checkedContribution({
  required settlement.PrepareAccountCallResponse prepared,
  required Uint8List account,
  required Uint8List custody,
  required String amount,
  required List<Uint8List>? roomAssets,
}) {
  final asked = _positiveAmount(amount);
  final assets = roomAssets
      ?.where((a) => a.length == 20 && a.any((b) => b != 0))
      .toList();
  if (assets == null || assets.isEmpty) {
    throw const SigningRefused(assetUnknownReason);
  }
  final digest = checkedAccountCallDigest(
    prepared: prepared,
    kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_CONTRIBUTE,
    account: account,
  );
  // The digest must be the checked intent's own, made from exactly this
  // account: otherwise a harmless intent could ride next to the digest of
  // another act.
  final intent = _intentOf(prepared, digest, account);
  if (intent.type != IntentType.contribution ||
      intent.destination.kind != LocationKind.roomCustody ||
      !bytesEqual(intent.destination.address, custody)) {
    throw const SigningRefused('the call does not pay this room');
  }
  if (!assets.any((a) => bytesEqual(a, intent.asset))) {
    throw const SigningRefused(
      'the call pays in an asset this room does not hold',
    );
  }
  if (intent.amount != asked) {
    throw SigningRefused(
      'the call pays ${intent.amount}, not the $amount you asked for (minor units)',
    );
  }
  return (digest: digest, amount: asked);
}

final RegExp _positiveDecimal = RegExp(r'^[1-9][0-9]{0,77}$');

BigInt _positiveAmount(String amount) {
  if (!_positiveDecimal.hasMatch(amount)) {
    throw const SigningRefused('no amount was asked for');
  }
  return BigInt.parse(amount);
}

/// The digest to sign for a prepared engine call, and the call it binds (to
/// show the member: a payoff's ceiling, for one). Checked with the SDK: the
/// digest is the intent's own, the intent binds exactly the engine call
/// settlement returned, and that call is the action, room, loan, product,
/// amount and terms the member asked for (verifyEngineCallIntent compares
/// every field with [AccountEngineRequest.expected]).
/// The prepared target must also be the room's own engine for the action
/// (its LoanBook for loan actions, its RulesEngine otherwise) with an active
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
  final intent = _intentOf(prepared, digest, account);
  final EngineCall call;
  try {
    call = verifyEngineCallIntent(
      intent,
      prepared.call.engineTarget,
      prepared.call.engineCalldata,
      expected: request.expected,
      engines: engines,
    );
  } on EngineCallException catch (e) {
    throw SigningRefused(switch (e.error) {
      EngineCallError.requestMismatch =>
        'settlement prepared something else: not the call you asked for',
      EngineCallError.notTheRoomsEngine =>
        'the call targets a contract that is not this room’s active engine',
      _ => 'the engine call does not check out (${e.error.name})',
    });
  }
  return (digest: digest, call: call);
}

/// Why a personal call is refused when the personal targets are unknown.
const String personalTargetsUnknownReason =
    'your savings vault and loan book could not be read just now, so the call '
    'cannot be checked against them; try again shortly';

/// The digest to sign for a prepared personal call, and the call it binds (to
/// review). Checked with the SDK against what the person asked for
/// ([PersonalRequest.expected]), their vault and the admitted loan books
/// ([personal], finance VaultService.GetPersonalTargets), the offer they were
/// shown and the book their loan is on. Without the targets nothing is
/// signed.
({Uint8List digest, EngineCall call}) checkedPersonalCall({
  required settlement.PrepareAccountCallResponse prepared,
  required PersonalRequest request,
  required Uint8List account,
  required PersonalTargets? personal,
  Iterable<List<int>> roomCustodies = const [],
}) {
  if (personal == null) {
    throw const SigningRefused(personalTargetsUnknownReason);
  }
  final call = request.call;
  // Only a payoff may leave its amount to settlement's quote.
  if (call.takesAmount &&
      call != PersonalCall.payoff &&
      request.expected.amount <= BigInt.zero) {
    throw const SigningRefused('no amount was asked for');
  }
  if (call.onExistingLoan &&
      (request.loanBook == null ||
          !bytesEqual(request.params.loanBook, request.loanBook!))) {
    throw const SigningRefused('the loan\'s book is not named');
  }
  _checkRole(request, account);
  final digest = checkedAccountCallDigest(
    prepared: prepared,
    kind: call.kind,
    account: account,
  );
  final intent = sdkIntentOf(prepared.financialIntent);
  if (!bytesEqual(intentDigestOf(intent), digest)) {
    throw const SigningRefused('the digest is not the prepared intent\'s');
  }
  if (!bytesEqual(intent.account, account)) {
    throw const SigningRefused('the call is made from another account');
  }
  try {
    final checked = verifyEngineCallIntent(
      intent,
      prepared.call.engineTarget,
      prepared.call.engineCalldata,
      expected: request.expected,
      personal: personal,
      offer: request.offer,
      loanBook: request.loanBook,
      roomCustodies: roomCustodies,
    );
    final bound = request.maxRepay;
    if (call == PersonalCall.payoff &&
        request.expected.amount == BigInt.zero &&
        (bound == null || checked.amount > bound)) {
      throw const SigningRefused(payoffQuoteTooHigh);
    }
    return (digest: digest, call: checked);
  } on EngineCallException catch (e) {
    throw SigningRefused(engineRefusal(e.error));
  }
}

/// Why a quoted payoff above the most the loan could cost is refused.
const String payoffQuoteTooHigh =
    'the quoted payoff is more than this loan could ever cost';

/// The person must be the party the call is theirs to make as: the borrower
/// accepts an offer, pays and pays off; the lender lends what was asked; and
/// either may cancel an offer or ask not yet accepted.
void _checkRole(PersonalRequest request, Uint8List account) {
  final loan = request.loan;
  if (loan == null) return;
  bool mine(List<int> a) => bytesEqual(a, account);
  final ok = switch (request.call) {
    PersonalCall.acceptOffer ||
    PersonalCall.pay ||
    PersonalCall.payoff => mine(loan.borrowerAccount),
    PersonalCall.acceptAsk => mine(loan.lender) || mine(loan.pool),
    PersonalCall.cancel =>
      mine(loan.borrowerAccount) || mine(loan.lender) || mine(loan.pool),
    _ => true,
  };
  if (!ok) throw const SigningRefused('this loan is not yours to act on');
}

/// A refusal in the person's words.
String engineRefusal(EngineCallError e) => switch (e) {
  EngineCallError.requestMismatch =>
    'settlement prepared something else: not the call you asked for',
  EngineCallError.maxRepayMismatch =>
    'the most you could repay is not what the terms give',
  EngineCallError.offerMismatch ||
  EngineCallError.offerUnknown => 'this is not the offer you were shown',
  EngineCallError.notThePersonalTarget || EngineCallError.notTheLoansBook =>
    'the call goes to a contract that is not your vault or this loan\'s book',
  EngineCallError.counterpartyIsARoom || EngineCallError.noCounterparty =>
    'the other person is not a person\'s account',
  _ => 'the call does not check out (${e.name})',
};

/// The digest to sign for a prepared deposit into the person's own vault:
/// a VAULT_DEPOSIT from [account] of exactly [amount] into [pocket], the
/// pocket the person chose (32 zero bytes: free savings), in their vault
/// ([personal]).
Uint8List checkedVaultDeposit({
  required settlement.PrepareAccountCallResponse prepared,
  required Uint8List account,
  required Uint8List pocket,
  required BigInt amount,
  required PersonalTargets? personal,
}) {
  if (personal == null) {
    throw const SigningRefused(personalTargetsUnknownReason);
  }
  if (amount <= BigInt.zero) {
    throw const SigningRefused('no amount was asked for');
  }
  final digest = checkedAccountCallDigest(
    prepared: prepared,
    kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_VAULT_DEPOSIT,
    account: account,
  );
  final intent = _intentOf(prepared, digest, account);
  try {
    verifyVaultDepositIntent(intent, vault: personal.vault, pocket: pocket);
  } on VaultException {
    throw const SigningRefused('the deposit goes to another pocket or vault');
  }
  if (intent.amount != amount) {
    throw SigningRefused(
      'the deposit is ${intent.amount}, not the $amount you asked for (minor units)',
    );
  }
  return digest;
}

/// Why a standing order that is not the loan's own is refused.
const String notTheLoansStandingOrder =
    'this is not your loan\'s automatic payment';

/// The digest to sign for a prepared standing order (automatic payment) for
/// [loan], and the grant it installs (to review). Only an active personal
/// loan the person borrowed gets one, and only the grant the SDK
/// (verifyStandingOrderGrant) finds is the loan's: its id, the vault as
/// target, one instalment's period and at most the largest instalment per
/// period, in [policyAsset].
({Uint8List digest, StandingGrant grant}) checkedStandingGrant({
  required settlement.PrepareAccountCallResponse prepared,
  required Uint8List account,
  required finance.Loan loan,
  required PersonalTargets? personal,
  required List<int> policyAsset,
}) {
  if (loan.state != finance.LoanState.LOAN_STATE_FUNDED) {
    throw const SigningRefused(
      'a standing order starts once the loan is active',
    );
  }
  if (loan.kind == finance.LoanKind.LOAN_KIND_GROUP ||
      !bytesEqual(loan.borrowerAccount, account)) {
    throw const SigningRefused(notTheLoansStandingOrder);
  }
  if (personal == null) {
    throw const SigningRefused(personalTargetsUnknownReason);
  }
  final digest = checkedAccountCallDigest(
    prepared: prepared,
    kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_GRANT_STANDING,
    account: account,
  );
  final intent = _intentOf(prepared, digest, account);
  final op = prepared.managementOp;
  if (!prepared.hasManagementOp() ||
      op.kind != opGrantStanding ||
      op.key.isNotEmpty ||
      op.authorizationId.isNotEmpty ||
      op.hasPolicy() ||
      !op.hasAuth()) {
    throw const SigningRefused(notTheLoansStandingOrder);
  }
  final StandingGrant grant;
  final BigInt amount;
  final PersonalTerms terms;
  try {
    grant = _standingGrantOf(op.auth);
    amount = BigInt.parse(loan.requested.amount);
    terms = LoanTerms(loan.terms).sdk;
  } on FormatException {
    throw const SigningRefused(notTheLoansStandingOrder);
  }
  try {
    verifyStandingOrderGrant(
      intent,
      grant,
      personal: personal,
      book: loan.loanBook,
      pool: loan.pool,
      loanId: _u64(loan.onchainLoanId),
      policyAsset: policyAsset,
      amount: amount,
      terms: terms,
    );
  } on VaultException catch (e) {
    throw SigningRefused(switch (e.error) {
      VaultError.notAStandingGrant =>
        'the signature would not cover the automatic payment shown',
      _ => notTheLoansStandingOrder,
    });
  }
  return (digest: digest, grant: grant);
}

StandingGrant _standingGrantOf(finance.AccountStandingParams a) {
  if (!RegExp(r'^(0|[1-9][0-9]{0,77})$').hasMatch(a.maxPerPeriod)) {
    throw const FormatException('max_per_period');
  }
  return StandingGrant(
    authorizationId: a.authorizationId,
    target: a.target,
    selector: a.selector,
    asset: a.asset,
    maxPerPeriod: BigInt.parse(a.maxPerPeriod),
    periodSeconds: _u64(a.periodSeconds),
    epochStart: _u64(a.epochStart),
    validAfter: _u64(a.validAfter),
    validUntil: _u64(a.validUntil),
  );
}

/// The digest to sign for stopping [loan]'s standing order: a REVOKE_STANDING
/// whose op names exactly the loan's standing order id and whose intent the
/// SDK (verifyStandingOrderRevoke) finds binds that op, in [policyAsset].
Uint8List checkedStandingRevoke({
  required settlement.PrepareAccountCallResponse prepared,
  required Uint8List account,
  required finance.Loan loan,
  required List<int> policyAsset,
}) {
  const wrong = SigningRefused(
    'this would stop something other than your loan\'s automatic payment',
  );
  final digest = checkedAccountCallDigest(
    prepared: prepared,
    kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_REVOKE_STANDING,
    account: account,
  );
  final intent = _intentOf(prepared, digest, account);
  if (loan.loanBook.length != 20 ||
      loan.pool.length != 20 ||
      policyAsset.length != 20 ||
      policyAsset.every((b) => b == 0)) {
    throw wrong;
  }
  final Uint8List id;
  try {
    id = verifyStandingOrderRevoke(
      intent,
      book: loan.loanBook,
      pool: loan.pool,
      loanId: _u64(loan.onchainLoanId),
      policyAsset: policyAsset,
    );
  } on VaultException {
    throw wrong;
  }
  final op = prepared.managementOp;
  if (!prepared.hasManagementOp() ||
      op.kind != opRevokeStanding ||
      op.key.isNotEmpty ||
      op.hasAuth() ||
      op.hasPolicy() ||
      !bytesEqual(op.authorizationId, id)) {
    throw wrong;
  }
  return digest;
}

/// The digest to sign for sending [amount] of the wallet's asset to another
/// address [to] the person gave: a TRANSFER to exactly that user account, of
/// the deployment's asset ([asset], its token address, read on its own and
/// never from the prepared intent).
Uint8List checkedTransferOut({
  required settlement.PrepareAccountCallResponse prepared,
  required Uint8List account,
  required Uint8List to,
  required BigInt amount,
  required List<int>? asset,
}) {
  if (asset == null || asset.length != 20 || asset.every((b) => b == 0)) {
    throw const SigningRefused(assetUnknownReason);
  }
  if (to.length != 20 || to.every((b) => b == 0)) {
    throw const SigningRefused('that is not an address to send to');
  }
  if (amount <= BigInt.zero) {
    throw const SigningRefused('no amount was asked for');
  }
  final digest = checkedAccountCallDigest(
    prepared: prepared,
    kind: settlement.AccountCallKind.ACCOUNT_CALL_KIND_TRANSFER,
    account: account,
  );
  final intent = _intentOf(prepared, digest, account);
  final d = intent.destination;
  if (intent.type != IntentType.transfer ||
      intent.mode != IntentMode.directSignature ||
      intent.room.isNotEmpty ||
      d.kind != LocationKind.userAccount ||
      !bytesEqual(d.address, to)) {
    throw const SigningRefused('the money goes somewhere other than you said');
  }
  if (!bytesEqual(intent.asset, asset)) {
    throw const SigningRefused(
      'the call sends another asset than your wallet holds',
    );
  }
  if (intent.amount != amount) {
    throw SigningRefused(
      'the call sends ${intent.amount}, not the $amount you asked for (minor units)',
    );
  }
  return digest;
}

/// The prepared intent, checked to be the one [digest] signs and made from
/// [account].
/// The prepared call's intent, checked to be the one [digest] signs and made
/// from [account].
FinancialIntent checkedPreparedIntent(
  settlement.PrepareAccountCallResponse prepared,
  Uint8List digest,
  Uint8List account,
) => _intentOf(prepared, digest, account);

FinancialIntent _intentOf(
  settlement.PrepareAccountCallResponse prepared,
  Uint8List digest,
  Uint8List account,
) {
  final intent = sdkIntentOf(prepared.financialIntent);
  if (!bytesEqual(intentDigestOf(intent), digest)) {
    throw const SigningRefused('the digest is not the prepared intent\'s');
  }
  if (!bytesEqual(intent.account, account)) {
    throw const SigningRefused('the call is made from another account');
  }
  return intent;
}

/// Why an engine call is refused when the room's engines are unknown.
const String enginesUnknownReason =
    'the room’s engines could not be read just now (settlement may be '
    'unreachable), so the call cannot be checked against them; try again '
    'shortly';

/// The exit settlement built for a PROPOSE_PRINCIPAL_EXIT with a spend, and
/// the payload hash the ballot must carry (the exit intent's digest): the
/// intent must spend [amount] out of this room's custody ([room], as finance
/// knows it) on its chain, to the account [to] the person chose (a member's
/// or an external one), or between the room's own buckets when [to] is
/// null.
Uint8List checkPrincipalExit(
  settlement.PrepareRoomCallResponse prepared, {
  required String amount,
  required RoomContracts room,
  Uint8List? to,
}) {
  final call = prepared.call;
  if (!call.hasExitIntent()) {
    throw const SigningRefused('settlement returned no exit intent');
  }
  final custody = room.custody;
  if (custody == null) throw const SigningRefused(roomContractsUnknownReason);
  final intent = sdkIntentOf(call.exitIntent);
  final digest = intentDigestOf(intent);
  if (!bytesEqual(digest, call.payloadHash)) {
    throw const SigningRefused('the ballot does not carry this exit');
  }
  if (!bytesEqual(intent.account, custody) ||
      !bytesEqual(intent.source.address, custody) ||
      intent.source.kind != LocationKind.roomCustody ||
      intent.domain.chainId != room.chainId) {
    throw const SigningRefused('the exit spends from another room');
  }
  final d = intent.destination;
  final toOk = to == null
      ? d.kind == LocationKind.roomCustody && bytesEqual(d.address, custody)
      : d.kind == LocationKind.userAccount && bytesEqual(d.address, to);
  if (!toOk) {
    throw const SigningRefused('the exit pays someone other than you chose');
  }
  if (intent.amount != BigInt.parse(amount)) {
    throw SigningRefused(
      'the exit moves ${intent.amount}, not the $amount proposed (minor units)',
    );
  }
  return digest;
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

/// The digest to sign for a by-vote loan request's [proposal]: the
/// borrower's own GovernanceModule.proposeBySig of the room's LOAN vote on
/// the loan the request will take, rebuilt on the device. The payload is
/// LoanBook's approval document for that loan id, of [borrower], for the
/// checked [amount] over [instalments], on the room's custody and the
/// room's LoanBook ([loanBook], finance's Room.engines); the proposal goes
/// to the room's GovernanceModule as finance knows it ([room]) at the
/// proposal's nonce and deadline, wrapped for the borrower's account.
Uint8List checkedLoanVoteProposal({
  required settlement.LoanVoteProposal proposal,
  required RoomContracts room,
  required List<int> loanBook,
  required Uint8List borrower,
  required BigInt amount,
  required int instalments,
  required DateTime now,
}) {
  final governance = room.governance;
  final custody = room.custody;
  if (governance == null || custody == null) {
    throw const SigningRefused(roomContractsUnknownReason);
  }
  if (!bytesEqual(proposal.governance, governance)) {
    throw const SigningRefused(
      'the loan\'s vote is not on this room\'s governance',
    );
  }
  if (proposal.loanId <= Int64.ZERO) {
    throw const SigningRefused('the loan\'s vote names no loan');
  }
  final payload = payloadHashOf(
    loanApprovalDocument(
      loanBook: loanBook,
      custody: custody,
      loanId: _u64(proposal.loanId),
      borrower: borrower,
      amount: amount,
      instalments: instalments,
    ),
  );
  if (!bytesEqual(payload, proposal.payloadHash)) {
    throw const SigningRefused('the loan\'s vote is not on this request');
  }
  final deadline = BigInt.from(proposal.deadline.seconds.toInt());
  if (deadline <= BigInt.from(now.toUtc().millisecondsSinceEpoch ~/ 1000)) {
    throw const SigningRefused('the loan\'s vote proposal has expired');
  }
  final typed = roomCallTypedHash(
    SignedCallKind.propose,
    verifier: governance,
    chainId: room.chainId,
    member: borrower,
    nonce: _u64(proposal.nonce),
    deadline: deadline,
    params: [...bigIntToBytes(BigInt.from(ProposalKinds.loan), 32), ...payload],
  );
  if (!bytesEqual(typed, proposal.typedHash)) {
    throw const SigningRefused(
      'the loan\'s vote proposal is not the proposal it describes',
    );
  }
  final digest = accountWrappedHash(borrower, room.chainId, typed);
  if (!bytesEqual(digest, proposal.digest)) {
    throw const SigningRefused(
      'the loan\'s vote digest is not your account wrapping of it',
    );
  }
  return digest;
}
