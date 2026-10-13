import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import 'account_engine_calls.dart';
import 'intent_bridge.dart';
import 'loan_terms.dart';
import 'personal_calls.dart';
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

/// The digest to sign for a prepared contribution, and the amount it pays
/// (to review): the call must be a CONTRIBUTE from [account] of exactly
/// [amount] (integer minor units, greater than zero) into [custody].
({Uint8List digest, BigInt amount}) checkedContribution({
  required settlement.PrepareAccountCallResponse prepared,
  required Uint8List account,
  required Uint8List custody,
  required String amount,
}) {
  final asked = _positiveAmount(amount);
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
/// address [to] the person gave: a TRANSFER to exactly that user account.
Uint8List checkedTransferOut({
  required settlement.PrepareAccountCallResponse prepared,
  required Uint8List account,
  required Uint8List to,
  required BigInt amount,
}) {
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
  if (intent.amount != amount) {
    throw SigningRefused(
      'the call sends ${intent.amount}, not the $amount you asked for (minor units)',
    );
  }
  return digest;
}

/// The prepared intent, checked to be the one [digest] signs and made from
/// [account].
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
      'the exit moves ${intent.amount}, not the $amount proposed (minor units)',
    );
  }
}

/// A proposed invitation commits to the expiry the member chose
/// ([expiresAt]); settlement reports the one the call carries.
void checkProposedInviteExpiry(
  settlement.PrepareRoomCallResponse prepared, {
  required DateTime expiresAt,
}) {
  final want = Int64(expiresAt.toUtc().millisecondsSinceEpoch ~/ 1000);
  if (prepared.call.inviteExpiry != want) {
    throw const SigningRefused(
      'the proposal carries another invitation expiry',
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
