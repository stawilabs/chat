import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/room.dart';
import 'room_service.dart';

/// What the group creation screen asks for: a group room, optionally with
/// the id it was given beforehand (a trading group's pool is created for
/// that id first) and metadata (the pool binding hint).
@immutable
class GroupRoomRequest {
  const GroupRoomRequest({
    required this.name,
    required this.contactIds,
    this.id,
    this.description,
    this.metadata,
  });

  final String name;
  final List<String> contactIds;
  final String? id;
  final String? description;
  final Map<String, dynamic>? metadata;
}

/// Creates a group room; the screen depends on this, not on RoomService, so
/// tests can record what was asked.
typedef CreateGroupRoom = Future<Room> Function(GroupRoomRequest request);

final createGroupRoomProvider = Provider<CreateGroupRoom>(
  (ref) => (request) async {
    final roomService = await ref.read(roomServiceProvider.future);
    return roomService.createRoom(
      id: request.id,
      name: request.name,
      type: 'group',
      description: request.description,
      contactIds: request.contactIds,
      metadata: request.metadata,
    );
  },
);
