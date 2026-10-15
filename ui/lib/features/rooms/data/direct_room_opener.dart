import 'dart:async';

import 'package:stawi_api_chat/stawi_api_chat.dart' as pb;

import '../../../core/logging/app_logger.dart';
import '../../../core/sync/room_type_wire.dart';
import '../domain/room.dart' as domain;
import 'room_repository.dart';

/// Asks chat for the direct room with one person before any local room exists.
///
/// No client id is sent: the server returns the pair's existing DM if there is
/// one. Returns the room stored under the server's id, or null when chat could
/// not be reached within [timeout] (the caller then falls back to the offline
/// placeholder flow). A rejection by the server throws.
Future<domain.Room?> openDirectRoomOnline({
  required RoomRepository roomRepo,
  required Future<pb.CreateRoomResponse> Function(pb.CreateRoomRequest) call,
  required String name,
  required List<String> contactIds,
  bool isPrivate = false,
  Map<String, dynamic>? metadata,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final request = pb.CreateRoomRequest(
    type: roomTypeToWire('direct'),
    name: name,
    isPrivate: isPrivate,
    members: contactIds.map((id) => pb.ContactLink(contactId: id)).toList(),
  );

  final pb.CreateRoomResponse response;
  try {
    response = await call(request).timeout(timeout);
  } catch (e) {
    AppLogger.warning(
      'Direct room not created online, falling back to offline flow',
      data: {'error': e.toString()},
    );
    return null;
  }

  if (response.hasError() || !response.hasRoom()) {
    throw Exception(
      'Room creation failed: ${response.hasError() ? response.error.message : 'no room returned'}',
    );
  }

  final serverId = response.room.id;
  final existing = await roomRepo.getRoomById(serverId);
  if (existing != null) return existing;
  final room = domain.Room(
    id: serverId,
    name: name,
    type: 'direct',
    metadata: metadata,
  );
  await roomRepo.insertRoom(room);
  return room;
}
