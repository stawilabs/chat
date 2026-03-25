import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../rooms/domain/room.dart' as domain;

/// Provider to get a profile by ID
final profileByIdProvider = FutureProvider.family<Profile?, String>((
  ref,
  profileId,
) async {
  final db = AppDatabase.instance;
  final query = db.select(db.profiles)..where((t) => t.id.equals(profileId));

  return query.getSingleOrNull();
});

/// Provider to watch a profile by ID (reactive updates)
final profileByIdStreamProvider = StreamProvider.family<Profile?, String>((
  ref,
  profileId,
) {
  final db = AppDatabase.instance;
  final query = db.select(db.profiles)..where((t) => t.id.equals(profileId));

  return query.watchSingleOrNull();
});

/// Provider to get shared rooms between current user and another profile
final sharedRoomsProvider = FutureProvider.family<List<domain.Room>, String>((
  ref,
  profileId,
) async {
  final db = AppDatabase.instance;

  // Get rooms where both current user and target profile are members
  final memberRooms = await (db.select(
    db.roomSubscriptions,
  )..where((t) => t.profileId.equals(profileId))).get();

  if (memberRooms.isEmpty) {
    return [];
  }

  // Get room details for each membership
  final roomIds = memberRooms.map((m) => m.roomId).toList();
  final rooms = await (db.select(
    db.rooms,
  )..where((t) => t.id.isIn(roomIds))).get();

  return rooms
      .map(
        (r) => domain.Room(
          id: r.id,
          name: r.name ?? 'Unknown Room',
          type: r.type ?? 'group',
          unreadCount: r.unreadCount,
          lastEventId: r.lastEventId,
          lastEventIndex: r.lastEventIndex ?? 0,
        ),
      )
      .toList();
});

/// Provider for the current user's profile
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final db = AppDatabase.instance;

  // Get the first profile (assuming single user)
  final query = db.select(db.profiles)..limit(1);
  return query.getSingleOrNull();
});

/// Provider to search profiles by name
final searchProfilesProvider = FutureProvider.family<List<Profile>, String>((
  ref,
  searchTerm,
) async {
  if (searchTerm.isEmpty) return [];

  final db = AppDatabase.instance;
  final pattern = '%$searchTerm%';
  final query = db.select(db.profiles)..where((t) => t.name.like(pattern));

  return query.get();
});
