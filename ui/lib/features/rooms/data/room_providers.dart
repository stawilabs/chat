import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/auth_context.dart';
import '../../../core/logging/app_logger.dart';
import '../../messages/data/draft_repository.dart';
import '../domain/room.dart' as domain;
import '../domain/room_with_last_message.dart';
import 'room_service.dart';
import 'room_sync_manager.dart';
import 'room_sync_state.dart';

part 'room_providers.g.dart';

/// Stream provider for watching room sync status
///
/// This provider watches the sync status of a specific room, allowing the UI
/// to react to state changes (CREATING -> SYNCING -> READY).
///
/// Usage:
/// ```dart
/// final syncStatus = ref.watch(roomSyncStatusProvider(roomId));
/// syncStatus.when(
///   data: (status) => status.canSendMessages ? EnabledInput() : DisabledInput(),
///   loading: () => LoadingInput(),
///   error: (e, s) => DisabledInput(),
/// );
/// ```
final roomSyncStatusProvider = StreamProvider.family<RoomSyncStatus, String>((
  ref,
  roomId,
) {
  final manager = ref.watch(roomSyncManagerProvider);
  return manager.watchRoom(roomId);
});

/// Provider to get current sync status synchronously (nullable if not tracked)
final roomSyncStatusSyncProvider = Provider.family<RoomSyncStatus?, String>((
  ref,
  roomId,
) {
  final manager = ref.watch(roomSyncManagerProvider);
  return manager.getStatus(roomId);
});

/// Provider to check if a room can send messages
///
/// Returns true if room is in READY state with a valid subscription ID.
/// Returns false if room is still creating/syncing or status is unknown.
final roomCanSendMessagesProvider = Provider.family<bool, String>((
  ref,
  roomId,
) {
  final statusAsync = ref.watch(roomSyncStatusProvider(roomId));
  return statusAsync.when(
    data: (status) => status.canSendMessages,
    loading: () => false,
    error: (error, stack) => false,
  );
});

/// Provider that syncs room members when entering a room
///
/// This ensures that the current user's subscription is available in the local
/// database before attempting to send messages or perform other operations.
/// Uses caching to avoid redundant syncs.
///
/// Also notifies RoomSyncManager when sync completes, which may transition
/// the room to READY state if subscription is found.
@riverpod
Future<void> syncRoomMembersOnEntry(Ref ref, String roomId) async {
  final roomSyncManager = ref.watch(roomSyncManagerProvider);

  // Skip sync if the room is still being created on the server.
  // The createRoom job in SyncEngine will handle the initial member sync.
  // Calling the API now would fail because the room doesn't exist yet.
  final currentStatus = roomSyncManager.getStatus(roomId);
  if (currentStatus != null && currentStatus.state == RoomSyncState.creating) {
    AppLogger.debug(
      'Skipping member sync on entry - room still creating',
      data: {'roomId': roomId},
    );
    return;
  }

  // Skip API call when we already have a real (non-provisional) subscription.
  // Provisional subscriptions still need syncing to get the real server ID.
  final subId = currentStatus?.currentUserSubscriptionId;
  if (subId != null && !subId.startsWith('provisional_')) {
    AppLogger.debug(
      'Skipping member sync on entry - subscription already known',
      data: {'roomId': roomId},
    );
    return;
  }

  try {
    final service = await ref.watch(roomServiceProvider.future);
    await service.syncRoomMembers(roomId);

    // Notify RoomSyncManager that API sync completed
    // This will check if current user's subscription is now available
    await roomSyncManager.onApiSyncComplete(roomId);

    AppLogger.debug('Room members synced on entry', data: {'roomId': roomId});
  } catch (e) {
    // Log but don't throw - sync failure shouldn't block room entry
    // Moderation events may still provide subscription IDs
    AppLogger.warning(
      'Room member sync on entry failed',
      data: {'roomId': roomId, 'error': e.toString()},
    );
  }
}

/// Provider for getting a room by ID
@riverpod
Future<domain.Room?> roomById(Ref ref, String roomId) async {
  final service = await ref.watch(roomServiceProvider.future);
  return service.getRoomById(roomId);
}

@riverpod
class RoomList extends _$RoomList {
  @override
  Future<List<domain.Room>> build() async {
    final service = await ref.watch(roomServiceProvider.future);
    return service.getAllRooms();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(roomServiceProvider.future);
      return service.getAllRooms();
    });
  }

  /// Create a new room (offline-first)
  /// Saves locally first, then syncs when online
  /// Server handles routing to on/off-platform members
  Future<domain.Room> createRoom({
    required String name,
    required String type,
    String? description,
    bool isPrivate = false,
    List<String> contactIds = const [], // Server determines routing
    Map<String, dynamic>? metadata,
  }) async {
    final service = await ref.read(roomServiceProvider.future);
    final room = await service.createRoom(
      name: name,
      type: type,
      description: description,
      isPrivate: isPrivate,
      contactIds: contactIds,
      metadata: metadata,
    );
    await refresh();
    return room;
  }

  /// Update an existing room (offline-first)
  Future<domain.Room> updateRoom({
    required String roomId,
    String? name,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    final service = await ref.read(roomServiceProvider.future);
    final room = await service.updateRoom(
      roomId: roomId,
      name: name,
      description: description,
      metadata: metadata,
    );
    await refresh();
    return room;
  }

  /// Delete a room (offline-first)
  Future<void> deleteRoom(String roomId) async {
    final service = await ref.read(roomServiceProvider.future);
    await service.deleteRoom(roomId);
    await refresh();
  }

  /// Add members to a room (offline-first)
  Future<void> addMembers({
    required String roomId,
    required List<String> profileIds,
  }) async {
    final service = await ref.read(roomServiceProvider.future);
    await service.addMembers(roomId: roomId, profileIds: profileIds);
  }

  /// Remove members from a room (offline-first)
  Future<void> removeMembers({
    required String roomId,
    required List<String> profileIds,
  }) async {
    final service = await ref.read(roomServiceProvider.future);
    await service.removeMembers(roomId: roomId, profileIds: profileIds);
  }
}

@riverpod
class RoomListWithMessages extends _$RoomListWithMessages {
  @override
  Future<List<RoomWithLastMessage>> build() async {
    final repo = ref.watch(roomRepositoryProvider);
    final draftRepo = ref.watch(draftRepositoryProvider);

    // Get current profile ID for sender name resolution
    final authContext = await ref.watch(currentAuthContextProvider.future);
    final currentProfileId = authContext?.profileId;

    // Get rooms and drafts
    final rooms = await repo.getRoomsWithLastMessage(
      currentProfileId: currentProfileId,
    );
    final draftsMap = await draftRepo.getDraftsMap();

    // Merge draft info into rooms
    return rooms.map((room) {
      final draft = draftsMap[room.id];
      return room.copyWith(draftText: draft);
    }).toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(roomRepositoryProvider);
      final draftRepo = ref.read(draftRepositoryProvider);

      // Get current profile ID for sender name resolution
      final authContext = await ref.read(currentAuthContextProvider.future);
      final currentProfileId = authContext?.profileId;

      final rooms = await repo.getRoomsWithLastMessage(
        currentProfileId: currentProfileId,
      );
      final draftsMap = await draftRepo.getDraftsMap();

      return rooms.map((room) {
        final draft = draftsMap[room.id];
        return room.copyWith(draftText: draft);
      }).toList();
    });
  }
}
