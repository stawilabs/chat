import 'package:antinvestor_api_chat/antinvestor_api_chat.dart' as pb_chat;
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xid/xid.dart';

import '../../../core/db/database.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/networking/client.dart';
import '../../../core/sync/pending_job.dart';
import '../../../core/sync/pending_job_repository.dart';
import '../../../core/sync/sync_engine.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/room.dart' as domain;
import 'room_repository.dart';
import 'room_subscription_repository.dart';
import 'room_subscription_service.dart';
import 'room_sync_manager.dart';
import 'room_sync_state.dart';

/// Service for managing rooms with offline-first support
/// All operations are saved locally first, then queued for server sync
/// Supports universal messaging: server handles routing to on/off-platform members
class RoomService {
  RoomService(
    this._roomRepo,
    this._jobRepo,
    this._chatClient,
    this._database,
    this._memberRepo,
    this._roomSyncManager,
    this._authRepo, {
    Future<void> Function()? onJobCreated,
  }) : _onJobCreated = onJobCreated;
  final RoomRepository _roomRepo;
  final PendingJobRepository _jobRepo;
  final pb_chat.ChatServiceClient _chatClient;
  final AppDatabase _database;
  final RoomSubscriptionRepository _memberRepo;
  final RoomSyncManager _roomSyncManager;
  final AuthRepository _authRepo;

  /// Optional callback to trigger immediate job processing (e.g. SyncEngine.triggerUpload)
  final Future<void> Function()? _onJobCreated;

  /// Create a new room (group or direct chat)
  /// Saves locally first, then queues for server sync
  ///
  /// Universal messaging: Pass all contact IDs regardless of platform status.
  /// The server will determine which members are on-platform vs off-platform,
  /// handle credit checks, and forward messages via notification service as needed.
  ///
  /// The room starts in CREATING state. User can navigate to it but cannot
  /// send messages until it transitions to READY (has subscription ID).
  Future<domain.Room> createRoom({
    required String name,
    required String type,
    String? description,
    bool isPrivate = false,
    List<String> contactIds =
        const [], // All member contact IDs - server handles routing
    Map<String, dynamic>? metadata,
  }) async {
    final roomId = Xid().toString();

    final room = domain.Room(
      id: roomId,
      name: name,
      type: type,
      metadata: {
        ...?metadata,
        'description': description ?? '',
        'isPrivate': isPrivate,
        'pendingSync': true,
        'syncState': RoomSyncState.creating.name, // Track sync state
      },
    );

    // Save locally first
    await _roomRepo.insertRoom(room);

    // Create a provisional subscription so the room is immediately usable,
    // even while offline. The provisional ID will be replaced with the real
    // server-assigned subscription once the createRoom job is processed.
    String? provisionalSubscriptionId;
    try {
      final profileId = await _authRepo.getCurrentProfileId();
      final contactId = await _authRepo.getCurrentContactId();
      if (profileId != null && contactId != null) {
        provisionalSubscriptionId = 'provisional_$roomId';
        await _memberRepo.createSubscription(
          id: provisionalSubscriptionId,
          roomId: roomId,
          profileId: profileId,
          contactId: contactId,
          role: 'admin',
        );
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to create provisional subscription, falling back to CREATING state',
        data: {'roomId': roomId, 'error': e.toString()},
      );
      provisionalSubscriptionId = null;
    }

    // Notify RoomSyncManager - if provisional subscription exists, room
    // goes directly to READY (provisional) state; otherwise CREATING.
    _roomSyncManager.onRoomCreatedLocally(
      roomId,
      provisionalSubscriptionId: provisionalSubscriptionId,
    );

    // Queue for server sync - server handles all member types
    await _jobRepo.addJob(JobType.createRoom, {
      'id': roomId,
      'name': name,
      'description': description ?? '',
      'isPrivate': isPrivate,
      'contactIds': contactIds, // Server determines platform status and routing
      'metadata': metadata,
    });

    AppLogger.info(
      'Room created locally and queued for sync',
      data: {
        'roomId': roomId,
        'name': name,
        'type': type,
        'memberCount': contactIds.length,
      },
    );

    // Trigger immediate upload so the room creation job is processed ASAP
    // rather than waiting for the reactive watch stream
    _onJobCreated?.call();

    return room;
  }

  /// Find an existing direct room with a profile, or create a new one
  ///
  /// Searches local subscriptions for a room where the target profile
  /// is a member and the room type is 'direct'. If none found, creates one.
  Future<domain.Room> findOrCreateDirectRoom({
    required String profileId,
    required String contactId,
    String? displayName,
  }) async {
    // Search for existing direct rooms with this profile
    final profileSubs = await _memberRepo.getProfileSubscriptions(profileId);
    for (final sub in profileSubs) {
      final room = await _roomRepo.getRoomById(sub.roomId);
      if (room != null && room.type == 'direct') {
        // Check that the room isn't marked as left
        if (room.metadata?['left'] != true) {
          return room;
        }
      }
    }

    // No existing direct room found, create one
    return createRoom(
      name: displayName ?? 'Direct Message',
      type: 'direct',
      contactIds: [contactId],
    );
  }

  /// Update an existing room
  /// Saves locally first, then queues for server sync
  /// Logs changes as system messages when logChanges is true
  Future<domain.Room> updateRoom({
    required String roomId,
    String? name,
    String? description,
    Map<String, dynamic>? metadata,
    bool logChanges = true,
  }) async {
    // Get existing room
    final existingRoom = await _roomRepo.getRoomById(roomId);
    if (existingRoom == null) {
      throw Exception('Room not found: $roomId');
    }

    // Track what changed for system messages
    final changes = <String>[];
    if (name != null && name != existingRoom.name) {
      changes.add('name changed to "$name"');
    }
    final oldDescription = existingRoom.metadata?['description'] as String?;
    if (description != null && description != oldDescription) {
      changes.add('description updated');
    }

    // Merge metadata
    final updatedMetadata = {
      ...?existingRoom.metadata,
      ...?metadata,
      'description': ?description,
      'pendingSync': true,
    };

    final updatedRoom = existingRoom.copyWith(
      name: name ?? existingRoom.name,
      metadata: updatedMetadata,
    );

    // Save locally first
    await _roomRepo.insertRoom(updatedRoom);

    // Queue for server sync
    await _jobRepo.addJob(JobType.updateRoom, {
      'id': roomId,
      'name': name ?? existingRoom.name,
      'description': description ?? updatedMetadata['description'] ?? '',
      'metadata': metadata,
      'changes': changes,
      'logSystemMessage': logChanges,
    });

    AppLogger.info(
      'Room updated locally and queued for sync',
      data: {'roomId': roomId, 'changes': changes},
    );

    return updatedRoom;
  }

  /// Update room avatar
  /// Saves locally first, then queues for server sync
  Future<domain.Room> updateRoomAvatar({
    required String roomId,
    required String? avatarUrl,
  }) async {
    final existingRoom = await _roomRepo.getRoomById(roomId);
    if (existingRoom == null) {
      throw Exception('Room not found: $roomId');
    }

    final updatedMetadata = {
      ...?existingRoom.metadata,
      'avatarUrl': avatarUrl,
      'pendingSync': true,
    };

    final updatedRoom = existingRoom.copyWith(metadata: updatedMetadata);

    await _roomRepo.insertRoom(updatedRoom);

    await _jobRepo.addJob(JobType.updateRoomAvatar, {
      'id': roomId,
      'avatarUrl': avatarUrl,
    });

    AppLogger.info(
      'Room avatar updated locally and queued for sync',
      data: {'roomId': roomId, 'hasAvatar': avatarUrl != null},
    );

    return updatedRoom;
  }

  /// Update room permissions
  /// Saves locally first, then queues for server sync
  Future<domain.Room> updateRoomPermissions({
    required String roomId,
    String? editInfoPermission,
    String? sendMessagesPermission,
    String? addMembersPermission,
  }) async {
    final existingRoom = await _roomRepo.getRoomById(roomId);
    if (existingRoom == null) {
      throw Exception('Room not found: $roomId');
    }

    final updatedMetadata = {
      ...?existingRoom.metadata,
      'editInfoPermission': ?editInfoPermission,
      'sendMessagesPermission': ?sendMessagesPermission,
      'addMembersPermission': ?addMembersPermission,
      'pendingSync': true,
    };

    final updatedRoom = existingRoom.copyWith(metadata: updatedMetadata);

    await _roomRepo.insertRoom(updatedRoom);

    await _jobRepo.addJob(JobType.updateRoomPermissions, {
      'id': roomId,
      'editInfoPermission': editInfoPermission,
      'sendMessagesPermission': sendMessagesPermission,
      'addMembersPermission': addMembersPermission,
    });

    AppLogger.info(
      'Room permissions updated locally and queued for sync',
      data: {'roomId': roomId},
    );

    return updatedRoom;
  }

  /// Delete a room
  /// Marks as deleted locally, then queues for server sync
  Future<void> deleteRoom(String roomId) async {
    // Mark as deleted in metadata (soft delete)
    final existingRoom = await _roomRepo.getRoomById(roomId);
    if (existingRoom != null) {
      final updatedRoom = existingRoom.copyWith(
        metadata: {
          ...?existingRoom.metadata,
          'deleted': true,
          'pendingSync': true,
        },
      );
      await _roomRepo.insertRoom(updatedRoom);
    }

    // Queue for server sync
    await _jobRepo.addJob(JobType.deleteRoom, {'id': roomId});

    AppLogger.info('Room deletion queued for sync', data: {'roomId': roomId});
  }

  /// Add members to a room
  /// Saves locally first, then queues for server sync
  Future<void> addMembers({
    required String roomId,
    required List<String> profileIds,
  }) async {
    // Queue for server sync
    await _jobRepo.addJob(JobType.addRoomMembers, {
      'roomId': roomId,
      'profileIds': profileIds,
    });

    AppLogger.info(
      'Add members queued for sync',
      data: {'roomId': roomId, 'memberCount': profileIds.length},
    );
  }

  /// Remove members from a room
  /// Queues for server sync
  Future<void> removeMembers({
    required String roomId,
    required List<String> profileIds,
  }) async {
    final subscriptionIds = <String>[];
    for (final profileId in profileIds) {
      final member = await _memberRepo.getMemberByProfileId(roomId, profileId);
      if (member != null) {
        subscriptionIds.add(member.id);
      } else {
        AppLogger.warning(
          'Subscription not found for profile removal',
          data: {'roomId': roomId, 'profileId': profileId},
        );
      }
    }

    // Queue for server sync
    await _jobRepo.addJob(JobType.removeRoomMembers, {
      'roomId': roomId,
      'profileIds': profileIds,
      if (subscriptionIds.isNotEmpty) 'subscriptionIds': subscriptionIds,
    });

    AppLogger.info(
      'Remove members queued for sync',
      data: {'roomId': roomId, 'memberCount': profileIds.length},
    );
  }

  /// Get all rooms (from local database)
  Future<List<domain.Room>> getAllRooms() async {
    final rooms = await _roomRepo.getAllRooms();
    // Filter out deleted rooms
    return rooms.where((room) {
      final metadata = room.metadata;
      if (metadata == null) return true;
      return metadata['deleted'] != true;
    }).toList();
  }

  /// Get a specific room by ID
  Future<domain.Room?> getRoomById(String roomId) async =>
      _roomRepo.getRoomById(roomId);

  /// Check if a room has pending sync
  bool hasPendingSync(domain.Room room) =>
      room.metadata?['pendingSync'] == true;

  /// Leave a room (current user exits the group)
  /// Marks as left locally, then queues for server sync
  Future<void> leaveRoom(String roomId) async {
    // Mark room as left in metadata (soft delete for user)
    final existingRoom = await _roomRepo.getRoomById(roomId);
    if (existingRoom != null) {
      final updatedRoom = existingRoom.copyWith(
        metadata: {
          ...?existingRoom.metadata,
          'left': true,
          'pendingSync': true,
        },
      );
      await _roomRepo.insertRoom(updatedRoom);
    }

    // Queue for server sync
    await _jobRepo.addJob(JobType.leaveRoom, {'id': roomId});

    AppLogger.info('Leave room queued for sync', data: {'roomId': roomId});
  }

  /// Change a member's role in a room
  /// Updates locally first, then queues for server sync
  ///
  /// @param roomId The room ID
  /// @param subscriptionId The subscription ID of the member to update
  /// @param newRole The new role (e.g., 'admin', 'moderator', 'member')
  Future<void> changeMemberRole({
    required String roomId,
    required String subscriptionId,
    required String newRole,
  }) async {
    // Update locally first using repository
    final success = await _memberRepo.updateMemberRole(
      id: subscriptionId,
      newRole: newRole,
    );

    if (!success) {
      // The repository already logs a warning. Abort to avoid queueing
      // a job for a failed local update.
      return;
    }

    // Queue for server sync
    await _jobRepo.addJob(JobType.changeMemberRole, {
      'roomId': roomId,
      'subscriptionId': subscriptionId,
      'role': newRole,
    });

    AppLogger.info(
      'Member role change queued for sync',
      data: {
        'roomId': roomId,
        'subscriptionId': subscriptionId,
        'newRole': newRole,
      },
    );
  }

  /// Promote a member to admin
  /// Convenience method that calls changeMemberRole with 'admin' role
  Future<void> promoteToAdmin({
    required String roomId,
    required String subscriptionId,
  }) async {
    await changeMemberRole(
      roomId: roomId,
      subscriptionId: subscriptionId,
      newRole: 'admin',
    );
  }

  /// Demote a member from admin to regular member
  /// Convenience method that calls changeMemberRole with 'member' role
  Future<void> demoteFromAdmin({
    required String roomId,
    required String subscriptionId,
  }) async {
    await changeMemberRole(
      roomId: roomId,
      subscriptionId: subscriptionId,
      newRole: 'member',
    );
  }

  /// Remove a member from a room by admin action
  /// Different from leaveRoom which is voluntary
  Future<void> removeMemberByAdmin({
    required String roomId,
    required String subscriptionId,
    required String profileId,
  }) async {
    // Remove from local database
    await (_database.delete(
      _database.roomSubscriptions,
    )..where((t) => t.id.equals(subscriptionId))).go();

    // Queue for server sync
    await _jobRepo.addJob(JobType.removeRoomMembers, {
      'roomId': roomId,
      'profileIds': [profileId],
      'isAdminAction': true,
    });

    AppLogger.info(
      'Admin member removal queued for sync',
      data: {
        'roomId': roomId,
        'subscriptionId': subscriptionId,
        'profileId': profileId,
      },
    );
  }

  /// Sync room members from server
  /// Fetches room member subscriptions and stores them locally using the searchRoomSubscriptions API
  Future<void> syncRoomMembers(String roomId) async {
    try {
      // Create request to search room subscriptions
      final request = pb_chat.SearchRoomSubscriptionsRequest(roomId: roomId);

      // Fetch subscriptions from API (unary call returns single response)
      final response = await _chatClient.searchRoomSubscriptions(request);

      var memberCount = 0;

      // Process each subscription from the response
      for (final subscription in response.members) {
        // Extract subscription ID from API response
        final subscriptionId = subscription.id;

        // Extract profileId and contactId from ContactLink
        final profileId =
            subscription.hasMember() && subscription.member.hasProfileId()
            ? subscription.member.profileId
            : null;
        final contactId =
            subscription.hasMember() && subscription.member.hasContactId()
            ? subscription.member.contactId
            : null;

        // Extract role (use first role if multiple, or null)
        final role = subscription.roles.isNotEmpty
            ? subscription.roles.first
            : null;

        // Extract joined timestamp
        final joinedAt = subscription.hasJoinedAt()
            ? subscription.joinedAt.seconds.toInt() * 1000 +
                  subscription.joinedAt.nanos ~/ 1000000
            : null;

        // Insert or update room member
        await _database
            .into(_database.roomSubscriptions)
            .insertOnConflictUpdate(
              RoomSubscriptionsCompanion.insert(
                id: subscriptionId,
                roomId: subscription.roomId,
                profileId: Value(profileId),
                contactId: Value(contactId),
                role: Value(role),
                joinedAt: Value(joinedAt),
              ),
            );

        memberCount++;
      }

      AppLogger.info(
        'Room members synced',
        data: {'roomId': roomId, 'memberCount': memberCount},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to sync room members',
        error: e,
        stackTrace: stackTrace,
        data: {'roomId': roomId},
      );
      rethrow;
    }
  }
}

/// Provider for RoomService
final roomServiceProvider = FutureProvider<RoomService>((ref) async {
  final roomRepo = ref.watch(roomRepositoryProvider);
  final jobRepo = ref.watch(pendingJobRepositoryProvider);
  final chatClient = await ref.watch(chatServiceClientProvider.future);
  final database = AppDatabase.instance;
  final memberRepo = ref.watch(roomSubscriptionRepositoryProvider);
  final roomSyncManager = ref.watch(roomSyncManagerProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  final syncEngine = await ref.watch(syncEngineProvider.future);
  return RoomService(
    roomRepo,
    jobRepo,
    chatClient,
    database,
    memberRepo,
    roomSyncManager,
    authRepo,
    onJobCreated: syncEngine.triggerUpload,
  );
});

/// Provider for RoomRepository
final roomRepositoryProvider = Provider<RoomRepository>(
  (ref) => RoomRepository(AppDatabase.instance),
);
