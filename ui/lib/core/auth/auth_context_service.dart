import 'package:antinvestor_auth_runtime/antinvestor_auth_runtime.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/rooms/data/room_service.dart';
import '../../features/rooms/data/room_subscription_service.dart';
import '../logging/app_logger.dart';

part 'auth_context_service.g.dart';

/// Exception thrown when the user is not authenticated.
class AuthenticationException implements Exception {
  AuthenticationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Exception thrown when subscription is not found for a room.
class SubscriptionNotFoundException implements Exception {
  SubscriptionNotFoundException(this.message, {this.roomId});
  final String message;
  final String? roomId;

  @override
  String toString() => message;
}

/// Helper that looks up subscription IDs for the current user, falling
/// back to a server-side sync when the local database is missing the
/// membership row.
///
/// Replaces the legacy `AuthContextService`/`AuthContext` pair. Identity
/// now comes from the runtime's typed [UserClaims] — the helper stores
/// no auth state of its own.
class AuthContextService {
  AuthContextService(
    this._runtime,
    this._subscriptionService,
    this._roomServiceFuture,
  );

  final AuthRuntime _runtime;
  final RoomSubscriptionService _subscriptionService;
  final Future<RoomService> _roomServiceFuture;

  /// Cache for recently synced rooms to avoid redundant sync calls.
  final Map<String, DateTime> _syncedRooms = {};
  static const _syncCacheDuration = Duration(minutes: 5);

  Future<({String profileId, String contactId})?> _requireIds() async {
    if (!_runtime.isAuthenticated) return null;
    final claims = await _runtime.getUserClaims();
    final sub = claims.sub;
    final contact = claims.contactId;
    if (sub == null || sub.isEmpty || contact == null || contact.isEmpty) {
      return null;
    }
    return (profileId: sub, contactId: contact);
  }

  /// Get subscription ID for a room, with automatic sync if missing.
  ///
  /// Returns `null` when unauthenticated, when the required claims are
  /// absent, or when the subscription cannot be found after retrying.
  Future<String?> getSubscriptionIdForRoom(
    String roomId, {
    bool syncIfMissing = true,
    int maxRetries = 2,
  }) async {
    final ids = await _requireIds();
    if (ids == null) {
      AppLogger.debug(
        'Cannot get subscription: user not authenticated',
        data: {'roomId': roomId},
      );
      return null;
    }

    var subscriptionId = await _subscriptionService.getCurrentSubscriptionId(
      roomId,
      ids.profileId,
      ids.contactId,
    );
    if (subscriptionId != null) return subscriptionId;

    if (!syncIfMissing) return null;

    AppLogger.debug(
      'Subscription not found locally, attempting sync',
      data: {'roomId': roomId, 'maxRetries': maxRetries},
    );

    for (var retry = 0; retry < maxRetries; retry++) {
      try {
        await _syncRoomMembersIfNeeded(roomId, forceSync: retry > 0);

        subscriptionId = await _subscriptionService.getCurrentSubscriptionId(
          roomId,
          ids.profileId,
          ids.contactId,
        );
        if (subscriptionId != null) {
          AppLogger.info(
            'Subscription found after sync',
            data: {'roomId': roomId, 'attempt': retry + 1},
          );
          return subscriptionId;
        }
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Room member sync failed',
          data: {'roomId': roomId, 'attempt': retry + 1, 'error': e.toString()},
        );
        if (retry == maxRetries - 1) {
          AppLogger.error(
            'All sync attempts failed',
            error: e,
            stackTrace: stackTrace,
            data: {'roomId': roomId},
          );
        }
      }
    }

    return null;
  }

  /// Get subscription ID or throw if not found.
  Future<String> requireSubscriptionIdForRoom(
    String roomId, {
    bool syncIfMissing = true,
    int maxRetries = 2,
  }) async {
    final ids = await _requireIds();
    if (ids == null) {
      throw AuthenticationException(
        'User not authenticated - cannot get subscription ID',
      );
    }

    final subscriptionId = await getSubscriptionIdForRoom(
      roomId,
      syncIfMissing: syncIfMissing,
      maxRetries: maxRetries,
    );

    if (subscriptionId == null) {
      throw SubscriptionNotFoundException(
        'No subscription found for room $roomId after ${syncIfMissing ? "sync attempt" : "lookup"}',
        roomId: roomId,
      );
    }
    return subscriptionId;
  }

  /// Sync room members for a specific room. Uses caching to avoid
  /// redundant sync calls.
  Future<void> syncRoomMembers(String roomId, {bool forceSync = false}) async {
    await _syncRoomMembersIfNeeded(roomId, forceSync: forceSync);
  }

  /// Clear the sync cache (useful when user logs out).
  void clearSyncCache() {
    _syncedRooms.clear();
  }

  Future<void> _syncRoomMembersIfNeeded(
    String roomId, {
    bool forceSync = false,
  }) async {
    if (!forceSync) {
      final lastSync = _syncedRooms[roomId];
      if (lastSync != null) {
        final elapsed = DateTime.now().difference(lastSync);
        if (elapsed < _syncCacheDuration) {
          final ids = await _requireIds();
          if (ids != null) {
            final subId = await _subscriptionService.getCurrentSubscriptionId(
              roomId,
              ids.profileId,
              ids.contactId,
            );
            if (subId != null) {
              AppLogger.debug(
                'Skipping room sync - recently synced',
                data: {
                  'roomId': roomId,
                  'elapsedSeconds': elapsed.inSeconds,
                  'cacheSeconds': _syncCacheDuration.inSeconds,
                },
              );
              return;
            }
            AppLogger.debug(
              'Subscription missing despite cache hit, re-syncing',
              data: {'roomId': roomId},
            );
          }
        }
      }
    }

    try {
      final roomService = await _roomServiceFuture;
      await roomService.syncRoomMembers(roomId);
      _syncedRooms[roomId] = DateTime.now();
    } catch (e) {
      _syncedRooms.remove(roomId);
      rethrow;
    }
  }
}

/// Provider for [AuthContextService].
@riverpod
AuthContextService authContextService(Ref ref) {
  final runtime = ref.watch(authRuntimeProvider);
  final subscriptionService = ref.watch(roomSubscriptionServiceProvider);
  final roomServiceFuture = ref.watch(roomServiceProvider.future);

  return AuthContextService(runtime, subscriptionService, roomServiceFuture);
}
