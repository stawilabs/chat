import 'dart:async';

import 'package:antinvestor_api_chat/antinvestor_api_chat.dart' as pb_chat;
import 'package:antinvestor_api_common/antinvestor_api_common.dart'
    as pb_common;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/rooms/data/room_repository.dart';
import '../../features/rooms/data/room_service.dart';
import '../../features/rooms/data/room_sync_manager.dart';
import '../../features/rooms/domain/room.dart' as domain;
import '../logging/app_logger.dart';
import '../networking/client.dart';

/// Service for synchronizing user data immediately after login
///
/// This service runs after successful authentication to:
/// 1. Fetch all rooms the user is a member of from the server
/// 2. Store rooms locally for immediate display
///
/// Note: Contact synchronization is handled lazily when the user visits the
/// Contacts screen and grants permission.
///
/// Design goals:
/// - Show local data immediately, server data appears as downloaded
/// - Efficient: Paginated fetches, no UI blocking
/// - Reliable: Retry with backoff, graceful failures
class PostLoginSyncService {
  PostLoginSyncService(
    this._chatClient,
    this._roomRepository,
    this._roomService,
    this._roomSyncManager,
  );

  final pb_chat.ChatServiceClient _chatClient;
  final RoomRepository _roomRepository;
  final RoomService _roomService;
  final RoomSyncManager _roomSyncManager;

  /// Configuration
  static const int _roomBatchSize = 50;
  static const int _maxRetries = 3;
  static const Duration _initialBackoff = Duration(milliseconds: 500);
  static const Duration _maxBackoff = Duration(seconds: 10);

  /// Track if sync is already running to prevent duplicates
  bool _isSyncing = false;

  /// Main entry point - runs all post-login syncs
  ///
  /// This method is safe to call multiple times; it will skip if already running.
  /// Currently only syncs rooms. Contact sync is handled lazily when the user
  /// visits the Contacts screen and grants permission.
  ///
  /// Returns true if sync completed successfully, false otherwise.
  Future<bool> runPostLoginSync() async {
    if (_isSyncing) {
      AppLogger.debug('PostLoginSync: Already running, skipping');
      return false;
    }

    _isSyncing = true;
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.info('PostLoginSync: Starting post-login synchronization');

      // Room sync (fetch all rooms from server)
      final roomsSynced = await _syncRoomsWithRetry();

      stopwatch.stop();
      AppLogger.info(
        'PostLoginSync: Completed successfully',
        data: {
          'roomsSynced': roomsSynced,
          'durationMs': stopwatch.elapsedMilliseconds,
        },
      );

      return true;
    } catch (e, stackTrace) {
      stopwatch.stop();
      AppLogger.error(
        'PostLoginSync: Failed',
        error: e,
        stackTrace: stackTrace,
        data: {'durationMs': stopwatch.elapsedMilliseconds},
      );
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Fetch all rooms from server with retry logic
  ///
  /// Returns the number of rooms synced.
  Future<int> _syncRoomsWithRetry() async {
    var retries = 0;
    var backoff = _initialBackoff;

    while (retries < _maxRetries) {
      try {
        return await _syncRooms();
      } catch (e, stackTrace) {
        retries++;
        if (retries >= _maxRetries) {
          AppLogger.error(
            'PostLoginSync: Room sync failed after $retries retries',
            error: e,
            stackTrace: stackTrace,
          );
          // Don't rethrow - continue with contact sync even if rooms fail
          return 0;
        }

        AppLogger.warning(
          'PostLoginSync: Room sync attempt $retries failed, retrying',
          data: {'error': e.toString(), 'backoffMs': backoff.inMilliseconds},
        );

        await Future.delayed(backoff);
        // Exponential backoff with max cap
        backoff = Duration(
          milliseconds: (backoff.inMilliseconds * 2).clamp(
            _initialBackoff.inMilliseconds,
            _maxBackoff.inMilliseconds,
          ),
        );
      }
    }

    return 0;
  }

  /// Fetch all rooms from server using searchRooms API
  ///
  /// Returns the number of rooms synced.
  Future<int> _syncRooms() async {
    AppLogger.info('PostLoginSync: Fetching rooms from server');

    var totalRooms = 0;

    // Create request - empty query returns all rooms the user is a member of
    final request = pb_chat.SearchRoomsRequest(
      query: '',
      cursor: pb_common.PageCursor(limit: _roomBatchSize),
    );

    // searchRooms returns a stream, process each response
    await for (final response in _chatClient.searchRooms(request)) {
      for (final pbRoom in response.data) {
        try {
          await _processRoom(pbRoom);
          totalRooms++;
        } catch (e) {
          AppLogger.warning(
            'PostLoginSync: Failed to process room ${pbRoom.id}',
            data: {'error': e.toString()},
          );
          // Continue with other rooms
        }
      }
    }

    AppLogger.info(
      'PostLoginSync: Rooms fetched and stored',
      data: {'totalRooms': totalRooms},
    );

    return totalRooms;
  }

  /// Process a single room from the API response
  Future<void> _processRoom(pb_chat.Room pbRoom) async {
    // Extract room type from metadata if available
    var roomType = '';
    if (pbRoom.hasMetadata()) {
      final typeValue = pbRoom.metadata.fields['room_type'];
      if (typeValue != null && typeValue.hasStringValue()) {
        roomType = typeValue.stringValue;
      }
    }

    // Convert protobuf room to domain model
    final room = domain.Room(
      id: pbRoom.id,
      name: pbRoom.name,
      type: roomType,
      // Leave lastEventId/lastEventIndex as defaults - will be updated by sync engine
    );

    // Store locally (upsert)
    await _roomRepository.insertRoom(room);

    // Mark room as ready immediately since user is already a member on server
    // This prevents blocking the UI while we fetch member details
    _roomSyncManager.onRoomDownloadedFromServer(pbRoom.id);

    // Queue member sync in background (non-blocking)
    // This populates the local cache but doesn't block the user
    unawaited(_syncRoomMembersBackground(pbRoom.id));

    AppLogger.debug(
      'PostLoginSync: Room stored',
      data: {'roomId': pbRoom.id, 'name': pbRoom.name},
    );
  }

  /// Sync room members in background
  ///
  /// This is fire-and-forget - errors are logged but don't affect the main flow.
  Future<void> _syncRoomMembersBackground(String roomId) async {
    try {
      await _roomService.syncRoomMembers(roomId);
      // Call API sync complete to update any cached state
      await _roomSyncManager.onApiSyncComplete(roomId);
    } catch (e, stackTrace) {
      // Log as warning for visibility - these failures should be investigated
      AppLogger.warning(
        'PostLoginSync: Background member sync failed for room $roomId',
        error: e,
        stackTrace: stackTrace,
        data: {'roomId': roomId},
      );
      // Don't rethrow - this is background work but we want visibility
    }
  }

  /// Check if there are any local rooms
  ///
  /// Used by StartupService to decide sync order.
  Future<bool> hasLocalRooms() async {
    final rooms = await _roomRepository.getAllRooms();
    return rooms.isNotEmpty;
  }
}

/// Create a PostLoginSyncService instance
///
/// This is a factory function rather than a provider to avoid lifecycle issues
/// during async initialization. The service is only needed during startup,
/// not as a long-lived dependency.
Future<PostLoginSyncService> createPostLoginSyncService(Ref ref) async {
  // Read all provider futures upfront to avoid ref being used after disposal
  // during async gaps
  final chatClientFuture = ref.read(chatServiceClientProvider.future);
  final roomRepository = ref.read(roomRepositoryProvider);
  final roomServiceFuture = ref.read(roomServiceProvider.future);
  final roomSyncManager = ref.read(roomSyncManagerProvider);

  // Now await all futures - ref is not used after this point
  final (chatClient, roomService) = await (
    chatClientFuture,
    roomServiceFuture,
  ).wait;

  return PostLoginSyncService(
    chatClient,
    roomRepository,
    roomService,
    roomSyncManager,
  );
}
