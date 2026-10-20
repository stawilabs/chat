import 'dart:typed_data';

import 'package:connectrpc/connect.dart' as connect;
import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;

import '../../messages/data/message_sending_service.dart';
import '../../messages/domain/room_event.dart';
import '../domain/governance_requests.dart';
import '../domain/money_review.dart';
import '../domain/room_setup.dart';
import '../domain/secret_ballot.dart';
import '../domain/signing_checks.dart';
import '../domain/stawi_payloads.dart';
import '../domain/template_rules.dart';
import 'device_key_store.dart';
import 'stawi_clients.dart';
import 'stawi_counterparty.dart';
import 'stawi_identity.dart';

/// Sends one Stawi act into a room as a chat event.
typedef StawiActSender = Future<RoomEvent> Function({
  required String roomId,
  required RoomEventType type,
  required Map<String, dynamic> content,
  String? parentId,
});

/// The room acts a member performs through chat: converting the room, signing
/// its genesis, and signed governance calls. Settlement prepares every digest;
/// the device checks and signs it; chat relays the act and posts its outcome.
class StawiRoomService {
  StawiRoomService({
    required this._rooms,
    required this._keys,
    required this._identity,
    required this._send,
    this._ballots,
    this._agentAccounts,
    this._contracts,
    this._memberAccounts,
    this._now = DateTime.now,
  });

  final settlement.RoomServiceClient _rooms;
  final DeviceKeyStore _keys;
  final Future<StawiIdentity> Function() _identity;
  final StawiActSender _send;
  final SecretBallotStore? _ballots;

  /// Resolves an agent who is not a founder to their account, so the device
  /// can confirm the genesis pays the person it names.
  final DmPartnerAccountOf? _agentAccounts;

  /// The room's contracts and chain as finance indexes them: every room call
  /// is checked against them, never against the verifier settlement names.
  final RoomContractsSource? _contracts;

  /// Resolves a member the person chose to the account the act names.
  final MemberAccountOf? _memberAccounts;

  /// The clock a call's deadline is checked against.
  final DateTime Function() _now;

  /// Asks for [roomId] to become a Stawi room. Chat prepares the genesis
  /// with settlement and turns this event into the genesis card.
  Future<RoomEvent> convert({
    required String roomId,
    required String templateId,
    required Map<String, String> ruleValues,
    required List<String> founderSubscriptionIds,
    required StawiJoinPolicy joinPolicy,
    String? agentProfileId,
  }) {
    if (templateId.isEmpty) {
      throw ArgumentError.value(templateId, 'templateId', 'choose a template');
    }
    if (founderSubscriptionIds.isEmpty) {
      throw ArgumentError.value(
        founderSubscriptionIds,
        'founderSubscriptionIds',
        'choose at least one founder',
      );
    }
    final problem = foundingQuorumProblem(
      entered: ruleValues['founding_quorum'] ?? '',
      templateDefault: 0,
      founders: founderSubscriptionIds.length,
    );
    if (problem != null) {
      throw ArgumentError.value(
        ruleValues['founding_quorum'],
        'founding_quorum',
        problem,
      );
    }
    return _send(
      roomId: roomId,
      type: RoomEventType.stawiRoomConversion,
      content: StawiConversionView.content(
        templateId: templateId,
        ruleValues: ruleValues,
        founderSubscriptionIds: founderSubscriptionIds,
        joinPolicy: joinPolicy,
        agentProfileId: agentProfileId,
      ),
    );
  }

  /// Reads the genesis on [conversion]'s card from settlement and checks it
  /// for this founder: the card's hash, the founder's own account wrapping,
  /// and the hash recomputed from the genesis' contents (agent included).
  /// Nothing is signed; the founder reviews the result first.
  Future<PreparedGenesisSignature> prepareGenesisSignature(
    RoomEvent conversion,
  ) async {
    final card = StawiConversionView.fromContent(conversion.content).genesis;
    if (card == null || card.genesisId.isEmpty) {
      throw const SigningRefused('the genesis is not prepared yet');
    }
    final me = await _identity();
    if (!card.isFounder(me.profileId)) {
      throw const SigningRefused('you are not a founder of this genesis');
    }
    final genesis = (await _rooms.getRoomGenesis(
      settlement.GetRoomGenesisRequest(genesisId: card.genesisId),
    )).genesis;
    final checked = checkedGenesisDigest(
      genesis: genesis,
      card: card,
      profileId: me.profileId,
      ownAccounts: me.addresses,
    );
    final setup = _checkedGenesisSetup(checked.genesis, me.profileId);
    return PreparedGenesisSignature._(
      conversion: conversion,
      card: card,
      genesis: checked.genesis,
      digest: checked.digest,
      profileId: me.profileId,
      setupDigests: setup.digests,
      setupProblem: setup.problem,
      agentConfirmed: genesisAgentConfirmed(
        checked.genesis,
        resolvedAgentAccount: await _agentAccountOf(checked.genesis),
      ),
    );
  }

  /// The founder's setup proposals beside the genesis, checked on the device
  /// ([checkedSetupDigests], nonces 0 to 2 on the room's governance as the
  /// factory will deploy it). None when the genesis has no setup or the
  /// founder already signed it; a setup that fails the check is not signed
  /// (the genesis still can be) and says why.
  ({List<Uint8List> digests, String? problem}) _checkedGenesisSetup(
    settlement.RoomGenesis genesis,
    String profileId,
  ) {
    final founder = genesis.founders
        .where((f) => f.profileId == profileId)
        .firstOrNull;
    if (founder == null ||
        !genesis.hasSetup() ||
        founder.setupSigned ||
        founder.setupDigests.isEmpty) {
      return (digests: const [], problem: null);
    }
    try {
      return (
        digests: checkedSetupDigests(
          digests: founder.setupDigests,
          governance: genesis.setup.governance,
          custody: genesis.setup.custody,
          account: Uint8List.fromList(founder.account),
          chainId: chainIdOf(genesis.chainId),
          now: _now(),
          firstNonce: 0,
        ),
        problem: null,
      );
    } on SigningRefused catch (e) {
      return (digests: const [], problem: e.reason);
    }
  }

  /// The account of a genesis agent who is not one of its founders, as this
  /// device can find it; null when it cannot.
  Future<Uint8List?> _agentAccountOf(settlement.RoomGenesis genesis) async {
    final agentId = genesis.agentProfileId;
    if (genesis.agent.isEmpty ||
        agentId.isEmpty ||
        genesis.founders.any((f) => f.profileId == agentId)) {
      return null;
    }
    try {
      return await _agentAccounts?.call(agentId);
    } on Object {
      return null;
    }
  }

  /// Signs a checked genesis the founder has reviewed with this device's key
  /// and sends the signature into the room, under the card. [roomName] names
  /// the room on the device lock prompt.
  ///
  /// The founder's setup proposals ([PreparedGenesisSignature.setupDigests])
  /// are signed under the same unlock and handed to settlement first
  /// (SubmitRoomSetupSignatures, which takes them only while the genesis is
  /// not on chain), so the signature that completes the founding quorum
  /// finds them there. Chat's genesis signature carries none, so the app
  /// sends them itself. A setup settlement refuses does not stop the
  /// genesis: the room then asks a founder to sign the setup later.
  Future<GenesisSigned> submitGenesisSignature(
    PreparedGenesisSignature prepared, {
    String roomName = 'this room',
  }) async {
    if (!prepared.agentConfirmed) {
      throw const SigningRefused(agentNotConfirmed);
    }
    final key = await _keys.unlock(
      prepared.profileId,
      reason: 'Found $roomName on Stawi',
    );
    Object? setupError;
    var setupSigned = false;
    if (prepared.setupDigests.isNotEmpty) {
      try {
        await _rooms.submitRoomSetupSignatures(
          settlement.SubmitRoomSetupSignaturesRequest(
            chatRoomId: prepared.conversion.roomId,
            signatures: [
              for (final d in prepared.setupDigests)
                finance.DeviceSignature(
                  deviceKeyId: key.keyId,
                  algorithm: secp256k1Algorithm,
                  signature: key.sign(d),
                ),
            ],
          ),
        );
        setupSigned = true;
      } on Object catch (error) {
        setupError = error;
      }
    }
    final event = await _send(
      roomId: prepared.conversion.roomId,
      type: RoomEventType.stawiGenesisSignature,
      parentId: prepared.conversion.id,
      content: StawiGenesisSignatureView.content(
        genesisId: prepared.card.genesisId,
        signature: key.sign(prepared.digest),
        signerKeyId: key.keyId,
      ),
    );
    return GenesisSigned(
      event: event,
      setupSigned: setupSigned,
      setupError: setupError ?? prepared.setupProblem,
    );
  }

  /// The room's lending setup, as settlement reports it to this reader.
  /// A room settlement plans no setup for (or a settlement that plans
  /// none) reads as NONE.
  Future<settlement.RoomSetup> roomSetup(String roomId) async {
    try {
      return (await _rooms.getRoomSetup(
        settlement.GetRoomSetupRequest(chatRoomId: roomId),
      )).setup;
    } on connect.ConnectException catch (e) {
      if (e.code != connect.Code.notFound &&
          e.code != connect.Code.unimplemented) {
        rethrow;
      }
      return settlement.RoomSetup(
        chatRoomId: roomId,
        state: settlement.RoomSetupState.ROOM_SETUP_STATE_NONE,
      );
    }
  }

  /// Reads the setup proposals settlement asks this founder to sign and
  /// checks them on the device against the room's contracts as finance
  /// knows them ([checkedSetupDigests], from the founder's current nonce).
  /// Nothing is signed yet: [PreparedSetupSignatures.review] is shown first.
  Future<PreparedSetupSignatures> prepareSetupSignatures(String roomId) async {
    final me = await _identity();
    final account = me.primary;
    if (account == null) {
      throw const StawiUnavailable('Your profile has no Stawi account yet');
    }
    final setup = await roomSetup(roomId);
    if (!RoomSetupProgress(setup).asksMe) {
      throw const StawiUnavailable(
        'The room\'s setup asks for no signature now',
      );
    }
    final room = await _roomContracts(roomId);
    final governance = room?.governance;
    final custody = room?.custody;
    if (room == null || governance == null || custody == null) {
      throw const SigningRefused(roomContractsUnknownReason);
    }
    if (!bytesEqual(setup.governance, governance) ||
        !bytesEqual(setup.custody, custody)) {
      throw const SigningRefused(
        'the setup names other contracts than the room\'s',
      );
    }
    final digests = checkedSetupDigests(
      digests: setup.needsSignatures,
      governance: governance,
      custody: custody,
      account: account.address,
      chainId: room.chainId,
      now: _now(),
    );
    final steps = setup.needsSignatures.length;
    return PreparedSetupSignatures._(
      roomId: roomId,
      profileId: me.profileId,
      digests: digests,
      review: MoneyReview(
        title: 'Propose the room\'s lending setup',
        lines: [
          for (final d in setup.needsSignatures)
            (
              'Proposal',
              setupStepTitle(settlement.RoomSetupStep(step: d.step)),
            ),
        ],
        notes: [setupSigningNote(steps), checkedRoomActNote],
        signLabel: 'Confirm and sign',
        done: 'Setup signed; the votes open shortly',
      ),
    );
  }

  /// Signs the checked setup proposals behind the device lock and gives them
  /// to settlement, which proposes them one at a time.
  Future<settlement.RoomSetup> submitSetupSignatures(
    PreparedSetupSignatures prepared,
  ) async {
    final key = await _keys.unlock(
      prepared.profileId,
      reason: prepared.review.title,
    );
    return (await _rooms.submitRoomSetupSignatures(
      settlement.SubmitRoomSetupSignaturesRequest(
        chatRoomId: prepared.roomId,
        signatures: [
          for (final d in prepared.digests)
            finance.DeviceSignature(
              deviceKeyId: key.keyId,
              algorithm: secp256k1Algorithm,
              signature: key.sign(d),
            ),
        ],
      ),
    )).setup;
  }

  /// The room's contracts as finance indexes them; null when they cannot be
  /// read (every room call is then refused).
  Future<RoomContracts?> _roomContracts(String roomId) async {
    try {
      return await _contracts?.call(roomId);
    } on Object {
      return null;
    }
  }

  /// The account of the member [name] ([profileId]) an act names, as this
  /// device can confirm it: their membership of [roomId] as finance indexes
  /// it, or chat's answer for a DM with them. Refused when neither knows
  /// it, so settlement never chooses who an act is about.
  Future<Uint8List> memberAccount(
    String roomId,
    String profileId, {
    required String name,
  }) async {
    Uint8List? account;
    try {
      account = await _memberAccounts?.call(roomId, profileId);
    } on Object {
      account = null;
    }
    if (account == null ||
        account.length != 20 ||
        account.every((b) => b == 0)) {
      throw SigningRefused(
        '$name\'s Stawi account could not be confirmed on this device',
      );
    }
    return account;
  }

  /// Prepares the signed room act [request] with settlement for the
  /// person's primary account and checks it on the device: the call must be
  /// the act [GovernanceRequest.expected] builds, on the room's contracts as
  /// finance knows them (stawi_finance_sdk verifyRoomCall). Nothing is
  /// signed yet: [PreparedRoomAct.review] is shown first.
  Future<PreparedRoomAct> prepareAct({
    required String roomId,
    required GovernanceRequest request,
  }) async {
    final me = await _identity();
    final account = me.primary;
    if (account == null) {
      throw const StawiUnavailable('Your profile has no Stawi account yet');
    }
    return _prepareChecked(
      roomId: roomId,
      profileId: me.profileId,
      account: account.address,
      request: request,
      title: request.summary,
      lines: request.lines,
      done: 'Signed and sent: ${request.summary}',
    );
  }

  /// A room call settlement holds for the person: how far a signed act has
  /// got, and the on-chain proposal a PROPOSE opened.
  Future<settlement.RoomCall> roomCall(String callId) async =>
      (await _rooms.getRoomCall(settlement.GetRoomCallRequest(callId: callId)))
          .call;

  /// Signs a checked room act the person reviewed, behind the device lock
  /// (its review title), and sends it into the room. A secret ballot's seal
  /// is kept on this device first, so a sent commitment never loses its
  /// salt.
  Future<RoomEvent> submitAct(PreparedRoomAct prepared) async {
    final sealed = prepared.sealed;
    final key = await _keys.unlock(
      prepared.profileId,
      reason: prepared.review.title,
    );
    if (sealed != null) {
      await _store.keep(prepared.roomId, prepared.onchainProposalId, sealed);
    }
    final event = await _send(
      roomId: prepared.roomId,
      type: RoomEventType.stawiSignedCall,
      content: StawiSignedCallView.content(
        callId: prepared.callId,
        kind: roomCallKindName(prepared.kind),
        signature: key.sign(prepared.digest),
        signerKeyId: key.keyId,
        summary: prepared.review.title,
      ),
    );
    if (prepared.reveal) {
      await _store.markRevealed(prepared.roomId, prepared.onchainProposalId);
    }
    return event;
  }

  Future<PreparedRoomAct> _prepareChecked({
    required String roomId,
    required String profileId,
    required Uint8List account,
    required GovernanceRequest request,
    required String title,
    required List<(String, String)> lines,
    required String done,
    int onchainProposalId = 0,
    SealedVote? sealed,
    bool reveal = false,
  }) async {
    final room = await _roomContracts(roomId);
    if (room == null) {
      throw const SigningRefused(roomContractsUnknownReason);
    }
    final prepared = await _rooms.prepareRoomCall(
      settlement.PrepareRoomCallRequest(
        chatRoomId: roomId,
        kind: request.kind,
        params: request.params,
        account: account,
      ),
    );
    if (prepared.call.kind != request.kind) {
      throw SigningRefused(
        'settlement prepared a ${roomCallKindName(prepared.call.kind)} call, '
        'not the act you chose',
      );
    }
    final digest = checkedRoomCall(
      prepared: prepared,
      expected: request.expected(room, prepared),
      chatRoomId: roomId,
      account: account,
      room: room,
      now: _now(),
    );
    return PreparedRoomAct._(
      roomId: roomId,
      callId: prepared.callId,
      kind: request.kind,
      digest: digest,
      profileId: profileId,
      onchainProposalId: onchainProposalId,
      sealed: sealed,
      reveal: reveal,
      review: MoneyReview(
        title: title,
        lines: [...lines, ...?request.linesOf?.call(prepared)],
        notes: const [checkedRoomActNote],
        signLabel: 'Confirm and sign',
        done: done,
      ),
    );
  }
}

/// What a founder's review of the setup says they sign.
String setupSigningNote(int steps) =>
    'Signs $steps proposal${steps == 1 ? '' : 's'} in your name; the members '
    'then vote on each. Nothing moves money until a vote passes.';

/// What every room act's review says was checked on the device.
const String checkedRoomActNote =
    'Checked on this device: this is the act you chose, on this room\'s '
    'contracts, signed by your account.';

/// How a vote is cast.
enum RoomVoteMode {
  /// An open vote (CAST_VOTE).
  open,

  /// A secret ballot's commitment (COMMIT_VOTE); revealed later.
  secret,
}

extension StawiCheckedVotes on StawiRoomService {
  /// Prepares the person's vote [choice] on the room's on-chain proposal
  /// [onchainProposalId] and checks it on the device (stawi_finance_sdk
  /// verifyRoomCall against the room's GovernanceModule as finance knows
  /// it). Nothing is signed or stored yet: [PreparedRoomAct.review], titled
  /// [title], is shown first. A secret ballot seals the choice with a fresh
  /// salt; the seal is kept only once the vote is sent.
  Future<PreparedRoomAct> prepareVote({
    required String roomId,
    required int onchainProposalId,
    required finance.VoteChoice choice,
    required RoomVoteMode mode,
    String? title,
    List<(String, String)> lines = const [],
    DateTime? revealClosesAt,
  }) async {
    if (onchainProposalId <= 0) {
      throw const StawiUnavailable('The vote has not opened yet');
    }
    final me = await _identity();
    final account = me.primary;
    if (account == null) {
      throw const StawiUnavailable('Your profile has no Stawi account yet');
    }
    final SealedVote? sealed;
    final GovernanceRequest request;
    switch (mode) {
      case RoomVoteMode.open:
        sealed = null;
        request = voteRequest(
          onchainProposalId: onchainProposalId,
          choice: choice,
        );
      case RoomVoteMode.secret:
        sealed = _store.fresh(
          choice: choice,
          member: account.address,
          revealClosesAt: revealClosesAt,
        );
        request = commitVoteRequest(
          onchainProposalId: onchainProposalId,
          commitment: sealed.commitment(onchainProposalId),
        );
    }
    return _prepareChecked(
      roomId: roomId,
      profileId: me.profileId,
      account: account.address,
      request: request,
      onchainProposalId: onchainProposalId,
      sealed: sealed,
      title: title ?? request.summary,
      done: mode == RoomVoteMode.secret
          ? 'Secret vote cast; reveal it from this device when voting closes'
          : 'Vote sent',
      lines: [
        if (title == null) ('Proposal', '#$onchainProposalId'),
        ...lines,
        ('Your vote', voteChoiceLabel(choice)),
        if (mode == RoomVoteMode.secret)
          ('Ballot', 'Secret: reveal it from this device when voting closes'),
      ],
    );
  }

  /// Prepares revealing the vote this device sealed on [onchainProposalId],
  /// checked like [prepareVote]. Nothing is signed yet.
  Future<PreparedRoomAct> prepareReveal({
    required String roomId,
    required int onchainProposalId,
    String? title,
    List<(String, String)> lines = const [],
  }) async {
    final sealed = await _store.load(roomId, onchainProposalId);
    if (sealed == null) {
      throw const StawiUnavailable(revealElsewhereMessage);
    }
    final me = await _identity();
    final request = revealVoteRequest(
      onchainProposalId: onchainProposalId,
      choice: sealed.choice,
      salt: sealed.salt,
    );
    return _prepareChecked(
      roomId: roomId,
      profileId: me.profileId,
      account: sealed.member,
      request: request,
      onchainProposalId: onchainProposalId,
      reveal: true,
      title: title ?? request.summary,
      done: 'Vote revealed',
      lines: [
        if (title == null) ('Proposal', '#$onchainProposalId'),
        ...lines,
        ('Your vote', voteChoiceLabel(sealed.choice)),
      ],
    );
  }
}

/// "Yes", "No" or "Abstain".
String voteChoiceLabel(finance.VoteChoice choice) => switch (choice) {
  finance.VoteChoice.VOTE_CHOICE_APPROVE => 'Yes',
  finance.VoteChoice.VOTE_CHOICE_REJECT => 'No',
  _ => 'Abstain',
};

/// A room act settlement prepared and the device checked
/// ([StawiRoomService.prepareAct], [StawiCheckedVotes.prepareVote]),
/// awaiting the person's review. Only the room service builds one, so an
/// unchecked room call digest never reaches the device key.
final class PreparedRoomAct {
  const PreparedRoomAct._({
    required this.roomId,
    required this.callId,
    required this.kind,
    required this.digest,
    required this.profileId,
    required this.review,
    this.onchainProposalId = 0,
    this.sealed,
    this.reveal = false,
  });

  final String roomId;
  final String callId;
  final settlement.RoomCallKind kind;
  final Uint8List digest;
  final String profileId;

  /// The proposal a vote is on (0 for any other act).
  final int onchainProposalId;

  /// What the person is shown before signing; its title is the lock prompt.
  final MoneyReview review;

  /// A secret ballot's seal, kept once the vote is sent.
  final SealedVote? sealed;

  /// Whether this reveals a sealed vote.
  final bool reveal;
}

/// Reads a room's contracts and chain.
typedef RoomContractsSource = Future<RoomContracts?> Function(String roomId);

/// The contracts and chain finance indexes for a room; null when it names
/// neither contract or no chain (the room is not bound yet).
RoomContractsSource financeContractsSource(finance.RoomServiceClient rooms) =>
    (roomId) async {
      final room = (await rooms.getRoom(finance.GetRoomRequest(roomId: roomId)))
          .room;
      Uint8List? address(List<int> a) =>
          a.length == 20 && a.any((b) => b != 0) ? Uint8List.fromList(a) : null;
      final governance = address(room.governanceAddress);
      final custody = address(room.custodyAddress);
      if ((governance == null && custody == null) ||
          room.chainId == Int64.ZERO) {
        return null;
      }
      return RoomContracts(
        governance: governance,
        custody: custody,
        chainId: BigInt.parse(room.chainId.toStringUnsigned()),
      );
    };

/// A room's contracts and chain as finance indexes them; null when not
/// known (nothing is then checked against them, so nothing is signed).
final stawiRoomContractsProvider = FutureProvider.autoDispose
    .family<RoomContracts?, String>(
      (ref, roomId) =>
          financeContractsSource(ref.watch(financeRoomsProvider))(roomId),
    );

/// Resolves a member of a room, named by profile, to their account.
typedef MemberAccountOf = Future<Uint8List?> Function(
  String roomId,
  String profileId,
);

/// The member's account as finance indexes their membership of the room,
/// else chat's answer for a DM with them ([dmPartner]); null when neither
/// knows it.
MemberAccountOf financeMemberAccounts(
  finance.RoomServiceClient rooms, {
  DmPartnerAccountOf? dmPartner,
}) => (roomId, profileId) async {
  try {
    final members = (await rooms.listMembers(
      finance.ListMembersRequest(roomId: roomId),
    )).members;
    final account = members
        .where((m) => m.profileId == profileId)
        .map((m) => m.accountAddress)
        .where((a) => a.length == 20 && a.any((b) => b != 0))
        .firstOrNull;
    if (account != null) return Uint8List.fromList(account);
  } on Object {
    // Fall through to the DM partner.
  }
  return dmPartner?.call(profileId);
};

extension StawiSecretBallot on StawiRoomService {
  SecretBallotStore get _store =>
      _ballots ?? (throw const StawiUnavailable('Secret ballots are off'));

  /// This device's sealed votes in [roomId] still to reveal.
  Future<List<PendingReveal>> pendingReveals(String roomId) =>
      _store.pending(roomId);
}

/// Why a vote cannot be revealed from this device.
const String revealElsewhereMessage =
    'This vote was not cast on this device. A secret vote is sealed on the '
    'device that cast it and its choice never leaves it, so reveal it from '
    'that device.';

/// This device's sealed votes in a room still to reveal.
final stawiPendingRevealsProvider = FutureProvider.autoDispose
    .family<List<PendingReveal>, String>(
      (ref, roomId) =>
          ref.watch(stawiRoomServiceProvider).pendingReveals(roomId),
    );

/// The permissionless room calls: nobody signs them (the engines recompute
/// every amount; the chain checks a passed proposal or exit ballot itself),
/// so the app hands them straight to settlement.
const Set<settlement.RoomCallKind> engineRoomCallKinds = {
  settlement.RoomCallKind.ROOM_CALL_KIND_QUEUE,
  settlement.RoomCallKind.ROOM_CALL_KIND_EXECUTE,
  settlement.RoomCallKind.ROOM_CALL_KIND_COLLECT,
  settlement.RoomCallKind.ROOM_CALL_KIND_SETTLE,
  settlement.RoomCallKind.ROOM_CALL_KIND_REFUND_FORMER,
  settlement.RoomCallKind.ROOM_CALL_KIND_DISBURSE_LOAN,
  settlement.RoomCallKind.ROOM_CALL_KIND_EXECUTE_PRINCIPAL_EXIT,
  settlement.RoomCallKind.ROOM_CALL_KIND_EXECUTE_PRINCIPAL_EXIT_CANCEL,
};

extension StawiEngineCalls on StawiRoomService {
  /// Pushes a permissionless call: a rules-engine call for [memberProfileId]
  /// (COLLECT, SETTLE, REFUND_FORMER) or [loanId] (DISBURSE_LOAN), or a
  /// passed decision's QUEUE or EXECUTE named by [params]. Prepared and
  /// submitted to settlement directly, with no signature and no chat event.
  Future<settlement.RoomCall> pushEngineCall({
    required String roomId,
    required settlement.RoomCallKind kind,
    String? memberProfileId,
    int? loanId,
    settlement.RoomCallParams? params,
  }) async {
    if (!engineRoomCallKinds.contains(kind)) {
      throw ArgumentError.value(kind, 'kind', 'not a permissionless call');
    }
    final prepared = await _rooms.prepareRoomCall(
      settlement.PrepareRoomCallRequest(
        chatRoomId: roomId,
        kind: kind,
        params:
            params ??
            settlement.RoomCallParams(
              engine: settlement.RoomEngineParams(
                member: memberProfileId == null
                    ? null
                    : settlement.RoomMemberRef(profileId: memberProfileId),
                loanId: loanId == null ? null : Int64(loanId),
              ),
            ),
      ),
    );
    if (prepared.call.kind != kind || prepared.call.requiresSignature) {
      throw const SigningRefused('settlement prepared another kind of call');
    }
    return (await _rooms.submitRoomCall(
      settlement.SubmitRoomCallRequest(callId: prepared.callId),
    )).call;
  }
}

final stawiRoomServiceProvider = Provider<StawiRoomService>((ref) {
  final sending = ref.watch(messageSendingServiceProvider);
  return StawiRoomService(
    rooms: ref.watch(settlementRoomsProvider),
    keys: ref.watch(deviceKeyStoreProvider),
    identity: () => ref.read(stawiIdentityProvider.future),
    send: sending.sendStawiAct,
    ballots: SecretBallotStore(const SecureStorageDeviceKeyVault()),
    agentAccounts: ref.watch(dmPartnerAccountOfProvider),
    contracts: financeContractsSource(ref.watch(financeRoomsProvider)),
    memberAccounts: financeMemberAccounts(
      ref.watch(financeRoomsProvider),
      dmPartner: ref.watch(dmPartnerAccountOfProvider),
    ),
  );
});

/// A genesis checked for one founder ([StawiRoomService.prepareGenesisSignature])
/// and awaiting their review. Only the room service builds one, so a digest
/// reaches the device key only after its checks.
final class PreparedGenesisSignature {
  const PreparedGenesisSignature._({
    required this.conversion,
    required this.card,
    required this.genesis,
    required this.digest,
    required this.profileId,
    required this.agentConfirmed,
    this.setupDigests = const [],
    this.setupProblem,
  });

  /// The conversion event whose card the founder signs from.
  final RoomEvent conversion;
  final StawiGenesisView card;

  /// Settlement's genesis, its hash recomputed from these contents.
  final settlement.RoomGenesis genesis;

  /// The founder's account-wrapped digest of the genesis hash.
  final Uint8List digest;

  /// The founder who signs.
  final String profileId;

  /// Whether this device confirmed the genesis agent's address is the account
  /// of the profile it is shown as ([genesisAgentConfirmed]). An unconfirmed
  /// genesis is shown but cannot be signed.
  final bool agentConfirmed;

  /// The founder's setup proposals, checked, signed under the same unlock;
  /// empty when there are none to sign.
  final List<Uint8List> setupDigests;

  /// Why the setup proposals were not offered for signing, when they failed
  /// the device's check.
  final String? setupProblem;
}

/// A sent genesis signature, and what became of the setup signed with it.
final class GenesisSigned {
  const GenesisSigned({
    required this.event,
    required this.setupSigned,
    this.setupError,
  });

  final RoomEvent event;

  /// Whether settlement took the founder's setup signatures.
  final bool setupSigned;

  /// Why it did not, when setup proposals were to be signed.
  final Object? setupError;
}

/// A founder's setup proposals settlement asked for and the device checked,
/// awaiting their review ([StawiRoomService.prepareSetupSignatures]).
final class PreparedSetupSignatures {
  const PreparedSetupSignatures._({
    required this.roomId,
    required this.profileId,
    required this.digests,
    required this.review,
  });

  final String roomId;
  final String profileId;
  final List<Uint8List> digests;
  final MoneyReview review;
}

/// The room's lending setup; refreshed when the room screen asks again.
final stawiRoomSetupProvider = FutureProvider.autoDispose
    .family<settlement.RoomSetup, String>(
      (ref, roomId) => ref.watch(stawiRoomServiceProvider).roomSetup(roomId),
      retry: (_, _) => null,
    );

/// Shown, and refused with, when a genesis' agent could not be confirmed.
const String agentNotConfirmed =
    'The agent could not be confirmed on this device';
