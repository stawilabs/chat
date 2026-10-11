import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/settlement_v1.dart' as settlement;

import '../../messages/data/message_sending_service.dart';
import '../../messages/domain/room_event.dart';
import '../domain/signing_checks.dart';
import '../domain/stawi_payloads.dart';
import 'device_key_store.dart';
import 'stawi_clients.dart';
import 'stawi_identity.dart';

/// Sends one Stawi act into a room as a chat event.
typedef StawiActSender =
    Future<RoomEvent> Function({
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
    required settlement.RoomServiceClient rooms,
    required DeviceKeyStore keys,
    required Future<StawiIdentity> Function() identity,
    required StawiActSender send,
  }) : _rooms = rooms,
       _keys = keys,
       _identity = identity,
       _send = send;

  final settlement.RoomServiceClient _rooms;
  final DeviceKeyStore _keys;
  final Future<StawiIdentity> Function() _identity;
  final StawiActSender _send;

  /// Asks for [roomId] to become a Stawi room. Chat prepares the genesis
  /// with settlement and turns this event into the genesis card.
  Future<RoomEvent> convert({
    required String roomId,
    required String templateId,
    required Map<String, String> ruleValues,
    required List<String> founderSubscriptionIds,
    required StawiJoinPolicy joinPolicy,
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
    return _send(
      roomId: roomId,
      type: RoomEventType.stawiRoomConversion,
      content: StawiConversionView.content(
        templateId: templateId,
        ruleValues: ruleValues,
        founderSubscriptionIds: founderSubscriptionIds,
        joinPolicy: joinPolicy,
      ),
    );
  }

  /// Signs the genesis on [conversion]'s card with this device's key and
  /// sends the signature into the room, under the card.
  Future<RoomEvent> signGenesis(RoomEvent conversion) async {
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
    final digest = checkedGenesisDigest(
      genesis: genesis,
      card: card,
      profileId: me.profileId,
      ownAccounts: me.addresses,
    );
    final key = await _keys.loadOrCreate(me.profileId);
    return _send(
      roomId: conversion.roomId,
      type: RoomEventType.stawiGenesisSignature,
      parentId: conversion.id,
      content: StawiGenesisSignatureView.content(
        genesisId: card.genesisId,
        signature: key.sign(digest),
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
      ),
    );
    final digest = checkedRoomCallDigest(
      prepared: prepared,
      kind: kind,
      chatRoomId: roomId,
      ownAccounts: me.addresses,
    );
    final key = await _keys.loadOrCreate(me.profileId);
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

final stawiRoomServiceProvider = Provider<StawiRoomService>((ref) {
  final sending = ref.watch(messageSendingServiceProvider);
  return StawiRoomService(
    rooms: ref.watch(settlementRoomsProvider),
    keys: ref.watch(deviceKeyStoreProvider),
    identity: () => ref.read(stawiIdentityProvider.future),
    send: sending.sendStawiAct,
  );
});
