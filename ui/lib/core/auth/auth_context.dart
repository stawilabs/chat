import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/rooms/data/room_service.dart';
import '../../features/rooms/data/room_subscription_service.dart';
import '../logging/app_logger.dart';

part 'auth_context.g.dart';

/// Exception thrown when user is not authenticated
class AuthenticationException implements Exception {
  AuthenticationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Exception thrown when subscription is not found for a room
class SubscriptionNotFoundException implements Exception {
  SubscriptionNotFoundException(this.message, {this.roomId});
  final String message;
  final String? roomId;

  @override
  String toString() => message;
}

/// Holds all authentication context in one immutable object
/// This prevents race conditions from separate auth calls
class AuthContext {
  const AuthContext({
    required this.profileId,
    required this.contactId,
    this.accessToken,
  });

  /// Global profile identity from JWT 'sub' claim
  final String profileId;

  /// Contact ID from JWT 'contact_id' claim (phone, email, etc.)
  final String contactId;

  /// Current access token (if available)
  final String? accessToken;

  /// Check if the auth context is valid (has required fields)
  bool get isValid => profileId.isNotEmpty && contactId.isNotEmpty;

  @override
  String toString() =>
      'AuthContext(profileId: $profileId, contactId: $contactId, hasToken: ${accessToken != null})';
}

/// Service that provides unified, atomic access to authentication state
/// and handles subscription ID lookups with automatic sync fallback
class AuthContextService {
  AuthContextService(
    this._authRepo,
    this._subscriptionService,
    this._roomServiceFuture,
  );

  final AuthRepository _authRepo;
  final RoomSubscriptionService _subscriptionService;
  final Future<RoomService> _roomServiceFuture;

  // Cache for recently synced rooms to avoid redundant sync calls
  final Map<String, DateTime> _syncedRooms = {};
  static const _syncCacheDuration = Duration(minutes: 5);

  /// Get all authentication context atomically in one call
  /// Returns null if user is not authenticated
  Future<AuthContext?> getAuthContext() async {
    try {
      final userInfo = await _authRepo.getUserInfo();
      if (userInfo == null) return null;

      final profileId = userInfo['sub'] as String?;
      final contactId = userInfo['contact_id'] as String?;

      if (profileId == null || contactId == null) return null;

      final accessToken = await _authRepo.getAccessToken();

      return AuthContext(
        profileId: profileId,
        contactId: contactId,
        accessToken: accessToken,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to get auth context',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get authentication context or throw if not authenticated
  /// Use this when authentication is required for the operation
  Future<AuthContext> requireAuthContext() async {
    final context = await getAuthContext();
    if (context == null) {
      throw AuthenticationException('User not authenticated');
    }
    if (!context.isValid) {
      throw AuthenticationException(
        'Invalid authentication context: missing profileId or contactId',
      );
    }
    return context;
  }

  /// Get subscription ID for a room, with automatic sync if missing
  ///
  /// This method:
  /// 1. Gets the current auth context atomically
  /// 2. Looks up the subscription in local database
  /// 3. If not found and syncIfMissing is true, syncs room members and retries
  ///
  /// @param roomId The room to get subscription for
  /// @param syncIfMissing If true, sync room members when subscription not found
  /// @param maxRetries Number of sync attempts before giving up
  /// @return Subscription ID if found, null otherwise
  Future<String?> getSubscriptionIdForRoom(
    String roomId, {
    bool syncIfMissing = true,
    int maxRetries = 2,
  }) async {
    final context = await getAuthContext();
    if (context == null || !context.isValid) {
      AppLogger.debug(
        'Cannot get subscription: user not authenticated',
        data: {'roomId': roomId},
      );
      return null;
    }

    // First attempt - check local database
    var subscriptionId = await _subscriptionService.getCurrentSubscriptionId(
      roomId,
      context.profileId,
      context.contactId,
    );

    if (subscriptionId != null) {
      return subscriptionId;
    }

    // Subscription not found - try syncing if enabled
    if (!syncIfMissing) {
      return null;
    }

    AppLogger.debug(
      'Subscription not found locally, attempting sync',
      data: {'roomId': roomId, 'maxRetries': maxRetries},
    );

    // Sync and retry
    for (var retry = 0; retry < maxRetries; retry++) {
      try {
        await _syncRoomMembersIfNeeded(roomId, forceSync: retry > 0);

        subscriptionId = await _subscriptionService.getCurrentSubscriptionId(
          roomId,
          context.profileId,
          context.contactId,
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

  /// Get subscription ID or throw if not found
  /// Use this when subscription is required for the operation
  ///
  /// @param roomId The room to get subscription for
  /// @param syncIfMissing If true, sync room members when subscription not found
  /// @param maxRetries Number of sync attempts before giving up
  /// @return Subscription ID
  /// @throws AuthenticationException if user not authenticated
  /// @throws SubscriptionNotFoundException if subscription not found after sync
  Future<String> requireSubscriptionIdForRoom(
    String roomId, {
    bool syncIfMissing = true,
    int maxRetries = 2,
  }) async {
    // First verify authentication
    final context = await getAuthContext();
    if (context == null || !context.isValid) {
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

  /// Sync room members for a specific room
  /// Uses caching to avoid redundant sync calls
  Future<void> syncRoomMembers(String roomId, {bool forceSync = false}) async {
    await _syncRoomMembersIfNeeded(roomId, forceSync: forceSync);
  }

  /// Clear the sync cache (useful when user logs out)
  void clearSyncCache() {
    _syncedRooms.clear();
  }

  /// Internal method to sync room members with caching
  ///
  /// Only caches successful syncs. Failed syncs are removed from cache
  /// so they can be retried immediately on the next attempt.
  Future<void> _syncRoomMembersIfNeeded(
    String roomId, {
    bool forceSync = false,
  }) async {
    // Check cache
    if (!forceSync) {
      final lastSync = _syncedRooms[roomId];
      if (lastSync != null) {
        final elapsed = DateTime.now().difference(lastSync);
        if (elapsed < _syncCacheDuration) {
          // Even if cached, verify subscription actually exists locally.
          // If it's missing, fall through to sync.
          final context = await getAuthContext();
          if (context != null && context.isValid) {
            final subId = await _subscriptionService.getCurrentSubscriptionId(
              roomId,
              context.profileId,
              context.contactId,
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
            // Subscription missing despite recent sync - force re-sync
            AppLogger.debug(
              'Subscription missing despite cache hit, re-syncing',
              data: {'roomId': roomId},
            );
          }
        }
      }
    }

    // Perform sync
    try {
      final roomService = await _roomServiceFuture;
      await roomService.syncRoomMembers(roomId);

      // Only cache on success
      _syncedRooms[roomId] = DateTime.now();
    } catch (e) {
      // Remove from cache on failure so retry is not blocked
      _syncedRooms.remove(roomId);
      rethrow;
    }
  }
}

/// Provider for AuthContextService
@riverpod
AuthContextService authContextService(Ref ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final subscriptionService = ref.watch(roomSubscriptionServiceProvider);
  final roomServiceFuture = ref.watch(roomServiceProvider.future);

  return AuthContextService(authRepo, subscriptionService, roomServiceFuture);
}

/// Provider for current auth context
/// Returns null if user is not authenticated
@riverpod
Future<AuthContext?> currentAuthContext(Ref ref) async {
  final service = ref.watch(authContextServiceProvider);
  return service.getAuthContext();
}
