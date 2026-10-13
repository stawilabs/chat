import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;

import '../../messages/data/message_sending_service.dart';
import '../../messages/domain/room_event.dart';
import '../domain/governance_requests.dart';
import '../domain/secret_ballot.dart';
import '../domain/signing_checks.dart';
import '../domain/stawi_payloads.dart';
import '../domain/template_rules.dart';
import 'device_key_store.dart';
import 'stawi_clients.dart';
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
  });

  final settlement.RoomServiceClient _rooms;
  final DeviceKeyStore _keys;
  final Future<StawiIdentity> Function() _identity;
  final StawiActSender _send;
  final SecretBallotStore? _ballots;

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
    return PreparedGenesisSignature._(
      conversion: conversion,
      card: card,
      genesis: checked.genesis,
      digest: checked.digest,
      profileId: me.profileId,
    );
  }

  /// Signs a checked genesis the founder has reviewed with this device's key
  /// and sends the signature into the room, under the card. [roomName] names
  /// the room on the device lock prompt.
  Future<RoomEvent> submitGenesisSignature(
    PreparedGenesisSignature prepared, {
    String roomName = 'this room',
  }) async {
    final key = await _keys.unlock(
      prepared.profileId,
      reason: 'Found $roomName on Stawi',
    );
    return _send(
      roomId: prepared.conversion.roomId,
      type: RoomEventType.stawiGenesisSignature,
      parentId: prepared.conversion.id,
      content: StawiGenesisSignatureView.content(
        genesisId: prepared.card.genesisId,
        signature: key.sign(prepared.digest),
        signerKeyId: key.keyId,
      ),
    );
  }

  /// Prepares a governance call with settlement, checks and signs its digest,
  /// and sends it into the room. The room shows it pending until chat posts
  /// the outcome.
  Future<RoomEvent> signedCall({
    required String roomId,
    required settlement.RoomCallKind kind,
    required String summary,
    settlement.RoomCallParams? params,
    Uint8List? account,
    void Function(settlement.PrepareRoomCallResponse prepared)? check,
  }) async {
    final me = await _identity();
    if (me.accounts.isEmpty) {
      throw const StawiUnavailable('Your profile has no Stawi account yet');
    }
    final prepared = await _rooms.prepareRoomCall(
      settlement.PrepareRoomCallRequest(
        chatRoomId: roomId,
        kind: kind,
        params: params,
        account: account,
      ),
    );
    final digest = checkedRoomCallDigest(
      prepared: prepared,
      kind: kind,
      chatRoomId: roomId,
      ownAccounts: account == null ? me.addresses : [account],
    );
    check?.call(prepared);
    final key = await _keys.unlock(me.profileId, reason: summary);
    return _send(
      roomId: roomId,
      type: RoomEventType.stawiSignedCall,
      content: StawiSignedCallView.content(
        callId: prepared.callId,
        kind: roomCallKindName(kind),
        signature: key.sign(digest),
        signerKeyId: key.keyId,
        summary: summary,
      ),
    );
  }
}

extension StawiSecretBallot on StawiRoomService {
  SecretBallotStore get _store =>
      _ballots ?? (throw const StawiUnavailable('Secret ballots are off'));

  /// Casts a secret-ballot vote: the choice is sealed with a fresh salt on
  /// this device, and only its commitment, made for the member's primary
  /// account (which is pinned as the signer), is sent.
  Future<RoomEvent> commitSecretVote({
    required String roomId,
    required int onchainProposalId,
    required finance.VoteChoice choice,
    DateTime? revealClosesAt,
  }) async {
    final account = (await _identity()).primary;
    if (account == null) {
      throw const StawiUnavailable('Your profile has no Stawi account yet');
    }
    final sealed = await _store.seal(
      roomId: roomId,
      proposalId: onchainProposalId,
      choice: choice,
      member: account.address,
      revealClosesAt: revealClosesAt,
    );
    final request = commitVoteRequest(
      onchainProposalId: onchainProposalId,
      commitment: sealed.commitment(onchainProposalId),
    );
    return signedCall(
      roomId: roomId,
      kind: request.kind,
      params: request.params,
      summary: request.summary,
      account: account.address,
    );
  }

  /// Reveals the vote this device sealed for the proposal.
  Future<RoomEvent> revealSecretVote({
    required String roomId,
    required int onchainProposalId,
  }) async {
    final sealed = await _store.load(roomId, onchainProposalId);
    if (sealed == null) {
      throw const StawiUnavailable(revealElsewhereMessage);
    }
    final request = revealVoteRequest(
      onchainProposalId: onchainProposalId,
      choice: sealed.choice,
      salt: sealed.salt,
    );
    final event = await signedCall(
      roomId: roomId,
      kind: request.kind,
      params: request.params,
      summary: request.summary,
      account: sealed.member,
    );
    await _store.markRevealed(roomId, onchainProposalId);
    return event;
  }

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
}
