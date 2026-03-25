import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../auth/data/auth_repository.dart';
import 'room_subscription_repository.dart';
import 'room_subscription_service.dart';
import 'room_sync_state.dart';

/// A simple value notifier with stream support
///
/// Similar to BehaviorSubject but without the rxdart dependency.
/// Holds a current value and broadcasts changes to listeners.
class _ValueStream<T> {
  _ValueStream(this._value);

  T _value;
  final _controller = StreamController<T>.broadcast();

  T get value => _value;

  Stream<T> get stream async* {
    // Emit current value immediately
    yield _value;
    // Then emit future updates
    yield* _controller.stream;
  }

  void add(T newValue) {
    _value = newValue;
    if (!_controller.isClosed) {
      _controller.add(newValue);
    }
  }

  void close() {
    _controller.close();
  }

  bool get isClosed => _controller.isClosed;
}

/// Health metrics for room synchronization
class RoomSyncHealth {
  const RoomSyncHealth({
    required this.totalRooms,
    required this.readyRooms,
    required this.creatingRooms,
    required this.syncingRooms,
    required this.stuckRooms,
    required this.isHealthy,
    required this.healthIssues,
  });

  /// Total number of tracked rooms
  final int totalRooms;

  /// Rooms in ready state
  final int readyRooms;

  /// Rooms in creating state
  final int creatingRooms;

  /// Rooms in syncing state
  final int syncingRooms;

  /// Rooms stuck in non-ready state for too long
  final int stuckRooms;

  /// Whether room sync is in a healthy state
  final bool isHealthy;

  /// List of detected health issues
  final List<String> healthIssues;

  Map<String, dynamic> toJson() => {
    'totalRooms': totalRooms,
    'readyRooms': readyRooms,
    'creatingRooms': creatingRooms,
    'syncingRooms': syncingRooms,
    'stuckRooms': stuckRooms,
    'isHealthy': isHealthy,
    'healthIssues': healthIssues,
  };
}

/// Result of a room sync recovery operation
class RoomSyncRecoveryResult {
  const RoomSyncRecoveryResult({
    required this.recoveredCount,
    required this.failedCount,
    required this.recoveredRoomIds,
    required this.failedRoomIds,
  });

  final int recoveredCount;
  final int failedCount;
  final List<String> recoveredRoomIds;
  final List<String> failedRoomIds;
}

/// Manager for tracking room synchronization state
///
/// This service tracks the state of each room through its lifecycle:
/// - CREATING: Room created locally, waiting for server confirmation
/// - SYNCING: Room confirmed on server, waiting for member data
/// - READY: Has current user's subscription ID, can send messages
///
/// Features:
/// - Health monitoring with metrics
/// - Automatic recovery for stuck rooms
/// - Extended timeout with multiple retry attempts
/// - Manual recovery mechanisms
///
/// The manager receives updates from:
/// 1. RoomService when a room is created locally
/// 2. SyncEngine when moderation events arrive with subscription IDs
/// 3. API sync fallback when events don't arrive in time
class RoomSyncManager {
  RoomSyncManager(this._authRepository, this._roomSubscriptionRepository);

  final AuthRepository _authRepository;
  final RoomSubscriptionRepository _roomSubscriptionRepository;

  /// In-memory state tracking per room
  final Map<String, _ValueStream<RoomSyncStatus>> _roomStates = {};

  /// Track when each room entered non-ready state
  final Map<String, DateTime> _nonReadyStartTimes = {};

  /// Timeout before falling back to API sync (seconds)
  /// Kept short to minimize user waiting time
  static const _syncTimeoutSeconds = 2;

  /// Maximum time a room can be in non-ready state before considered stuck (seconds)
  static const _stuckThresholdSeconds = 60;

  /// Extended timeout for retry attempts (seconds)
  static const _extendedTimeoutSeconds = 10;

  /// Maximum retry attempts before marking as stuck
  static const _maxRetryAttempts = 3;

  /// Track retry attempts per room
  final Map<String, int> _retryAttempts = {};

  /// Pending timeout timers for rooms awaiting member events
  final Map<String, Timer> _syncTimeouts = {};

  /// Recovery timer for periodic stuck room recovery
  Timer? _recoveryTimer;

  /// Get or create a state stream for a room
  ///
  /// Defaults to READY state (optimistic) - we only block input when we
  /// explicitly know the room is being created. This prevents unnecessary
  /// waiting for existing rooms.
  _ValueStream<RoomSyncStatus> _getOrCreateStream(String roomId) {
    return _roomStates.putIfAbsent(
      roomId,
      // Default to READY - only onRoomCreatedLocally sets CREATING
      () => _ValueStream(const RoomSyncStatus(state: RoomSyncState.ready)),
    );
  }

  /// Watch the sync status for a room
  ///
  /// Returns a stream that emits the current status and updates
  /// as the room progresses through its sync lifecycle.
  ///
  /// Default state is READY (optimistic) - rooms only enter CREATING/SYNCING
  /// states when explicitly triggered by room creation flow.
  Stream<RoomSyncStatus> watchRoom(String roomId) {
    return _getOrCreateStream(roomId).stream;
  }

  /// Get current sync status for a room (non-reactive)
  RoomSyncStatus? getStatus(String roomId) {
    return _roomStates[roomId]?.value;
  }

  /// Start the recovery timer for automatic stuck room recovery
  void startRecoveryTimer() {
    _recoveryTimer?.cancel();
    _recoveryTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkAndRecoverStuckRooms(),
    );
    AppLogger.debug('RoomSyncManager: Recovery timer started');
  }

  /// Stop the recovery timer
  void stopRecoveryTimer() {
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
  }

  /// Get health metrics for room synchronization
  RoomSyncHealth getHealth() {
    var readyCount = 0;
    var creatingCount = 0;
    var syncingCount = 0;
    var stuckCount = 0;
    final issues = <String>[];
    final now = DateTime.now();

    for (final entry in _roomStates.entries) {
      final status = entry.value.value;
      switch (status.state) {
        case RoomSyncState.ready:
          readyCount++;
        case RoomSyncState.creating:
          creatingCount++;
          // Check if stuck
          final startTime = _nonReadyStartTimes[entry.key];
          if (startTime != null &&
              now.difference(startTime).inSeconds > _stuckThresholdSeconds) {
            stuckCount++;
          }
        case RoomSyncState.syncing:
          syncingCount++;
          // Check if stuck
          final startTime = _nonReadyStartTimes[entry.key];
          if (startTime != null &&
              now.difference(startTime).inSeconds > _stuckThresholdSeconds) {
            stuckCount++;
          }
      }
    }

    if (stuckCount > 0) {
      issues.add('$stuckCount room(s) stuck in sync state');
    }
    if (creatingCount > 5) {
      issues.add('Many rooms in creating state: $creatingCount');
    }
    if (syncingCount > 10) {
      issues.add('Many rooms in syncing state: $syncingCount');
    }

    return RoomSyncHealth(
      totalRooms: _roomStates.length,
      readyRooms: readyCount,
      creatingRooms: creatingCount,
      syncingRooms: syncingCount,
      stuckRooms: stuckCount,
      isHealthy: issues.isEmpty,
      healthIssues: issues,
    );
  }

  /// Get list of stuck room IDs
  List<String> getStuckRoomIds() {
    final now = DateTime.now();
    final stuckIds = <String>[];

    for (final entry in _roomStates.entries) {
      final status = entry.value.value;
      if (status.state != RoomSyncState.ready) {
        final startTime = _nonReadyStartTimes[entry.key];
        if (startTime != null &&
            now.difference(startTime).inSeconds > _stuckThresholdSeconds) {
          stuckIds.add(entry.key);
        }
      }
    }

    return stuckIds;
  }

  /// Attempt to recover a specific stuck room
  ///
  /// Returns true if recovery was successful (room is now ready)
  Future<bool> recoverRoom(String roomId) async {
    final status = getStatus(roomId);
    if (status == null || status.state == RoomSyncState.ready) {
      return true; // Already ready or not tracked
    }

    AppLogger.info(
      'RoomSyncManager: Attempting recovery for stuck room',
      data: {'roomId': roomId, 'currentState': status.state.name},
    );

    // Try to find subscription in database
    final subscriptionId = await _findMySubscriptionInDb(roomId);

    if (subscriptionId != null) {
      final stream = _getOrCreateStream(roomId);
      stream.add(RoomSyncStatus.ready(subscriptionId));
      _nonReadyStartTimes.remove(roomId);
      _retryAttempts.remove(roomId);

      AppLogger.info(
        'RoomSyncManager: Room recovered - found subscription',
        data: {'roomId': roomId},
      );
      return true;
    }

    // If no subscription found, mark as ready optimistically
    // This allows the user to try sending messages, and any real
    // permission issues will be caught then
    final stream = _getOrCreateStream(roomId);
    stream.add(const RoomSyncStatus(state: RoomSyncState.ready));
    _nonReadyStartTimes.remove(roomId);
    _retryAttempts.remove(roomId);

    AppLogger.warning(
      'RoomSyncManager: Room recovered optimistically - no subscription found',
      data: {'roomId': roomId},
    );
    return true;
  }

  /// Recover all stuck rooms
  Future<RoomSyncRecoveryResult> recoverAllStuckRooms() async {
    final stuckRoomIds = getStuckRoomIds();
    final recoveredIds = <String>[];
    final failedIds = <String>[];

    for (final roomId in stuckRoomIds) {
      try {
        final recovered = await recoverRoom(roomId);
        if (recovered) {
          recoveredIds.add(roomId);
        } else {
          failedIds.add(roomId);
        }
      } catch (e) {
        AppLogger.error(
          'RoomSyncManager: Failed to recover room',
          error: e,
          data: {'roomId': roomId},
        );
        failedIds.add(roomId);
      }
    }

    AppLogger.info(
      'RoomSyncManager: Bulk recovery completed',
      data: {
        'total': stuckRoomIds.length,
        'recovered': recoveredIds.length,
        'failed': failedIds.length,
      },
    );

    return RoomSyncRecoveryResult(
      recoveredCount: recoveredIds.length,
      failedCount: failedIds.length,
      recoveredRoomIds: recoveredIds,
      failedRoomIds: failedIds,
    );
  }

  /// Internal method to check and recover stuck rooms
  Future<void> _checkAndRecoverStuckRooms() async {
    final health = getHealth();
    if (health.stuckRooms > 0) {
      AppLogger.info(
        'RoomSyncManager: Auto-recovering stuck rooms',
        data: {'stuckCount': health.stuckRooms},
      );
      await recoverAllStuckRooms();
    }
  }

  /// Called when a room is created locally
  ///
  /// If [provisionalSubscriptionId] is provided, the room goes directly to
  /// READY (provisional) state so the user can start sending messages
  /// immediately even while offline. Otherwise falls back to CREATING state.
  void onRoomCreatedLocally(
    String roomId, {
    String? provisionalSubscriptionId,
  }) {
    final stream = _getOrCreateStream(roomId);

    if (provisionalSubscriptionId != null) {
      // Room is immediately usable with provisional subscription
      stream.add(RoomSyncStatus.readyProvisional(provisionalSubscriptionId));
      AppLogger.debug(
        'Room sync: Room created locally with provisional subscription',
        data: {'roomId': roomId},
      );
    } else {
      // Fallback: no provisional subscription, enter CREATING state
      stream.add(RoomSyncStatus.creating());
      _nonReadyStartTimes[roomId] = DateTime.now();
      _retryAttempts[roomId] = 0;
      AppLogger.debug(
        'Room sync: Room created locally',
        data: {'roomId': roomId},
      );
    }
  }

  /// Called when room creation is confirmed by the server
  ///
  /// Transitions from CREATING to SYNCING and starts timeout for member events.
  void onRoomConfirmedByServer(String roomId) {
    final stream = _getOrCreateStream(roomId);
    final currentState = stream.value;

    // Only transition if currently creating
    if (currentState.state == RoomSyncState.creating ||
        currentState.state == RoomSyncState.syncing) {
      stream.add(RoomSyncStatus.syncing(lastSyncAttempt: DateTime.now()));

      // Start timeout for member event arrival
      _startSyncTimeout(roomId);

      AppLogger.debug(
        'Room sync: Room confirmed by server, awaiting member events',
        data: {'roomId': roomId},
      );
    }
  }

  /// Called when moderation event arrives with member subscription IDs
  ///
  /// This is the primary path for getting subscription IDs.
  /// Checks if current user's subscription is in the list and transitions to READY.
  Future<void> onMembersReceived(
    String roomId,
    List<String> subscriptionIds,
  ) async {
    // Cancel any pending timeout
    _cancelSyncTimeout(roomId);

    // Find current user's subscription
    final mySubscription = await _findMySubscription(roomId, subscriptionIds);

    if (mySubscription != null) {
      final stream = _getOrCreateStream(roomId);
      stream.add(RoomSyncStatus.ready(mySubscription));
      _nonReadyStartTimes.remove(roomId);
      _retryAttempts.remove(roomId);

      AppLogger.info(
        'Room sync: Ready - found my subscription from moderation event',
        data: {
          'roomId': roomId,
          'subscriptionId': mySubscription.substring(
            0,
            mySubscription.length < 8 ? mySubscription.length : 8,
          ),
          'totalMembers': subscriptionIds.length,
        },
      );
    } else {
      AppLogger.debug(
        'Room sync: Received member event but my subscription not found',
        data: {'roomId': roomId, 'memberCount': subscriptionIds.length},
      );
    }
  }

  /// Called when a member is added to a room (via moderation event)
  ///
  /// If the added member is the current user, transition to READY.
  Future<void> onMemberAdded(String roomId, String subscriptionId) async {
    // Check if this is the current user's subscription
    final isMySubscription = await _isMySubscription(roomId, subscriptionId);

    if (isMySubscription) {
      final stream = _getOrCreateStream(roomId);
      stream.add(RoomSyncStatus.ready(subscriptionId));
      _nonReadyStartTimes.remove(roomId);
      _retryAttempts.remove(roomId);

      AppLogger.info(
        'Room sync: Ready - current user added to room',
        data: {
          'roomId': roomId,
          'subscriptionId': subscriptionId.substring(
            0,
            subscriptionId.length < 8 ? subscriptionId.length : 8,
          ),
        },
      );
    }
  }

  /// Called when a member is removed from a room (via moderation event)
  ///
  /// If the removed member is the current user, the room becomes inaccessible.
  Future<void> onMemberRemoved(String roomId, String subscriptionId) async {
    final currentStatus = getStatus(roomId);

    // If this was the current user's subscription, reset state
    if (currentStatus?.currentUserSubscriptionId == subscriptionId) {
      final stream = _getOrCreateStream(roomId);
      // Set to syncing - the UI will handle showing appropriate message
      stream.add(RoomSyncStatus.syncing(lastSyncAttempt: DateTime.now()));
      _nonReadyStartTimes[roomId] = DateTime.now();

      AppLogger.info(
        'Room sync: Current user removed from room',
        data: {'roomId': roomId},
      );
    }
  }

  /// Called when API sync completes successfully
  ///
  /// This is the fallback path when moderation events don't arrive in time.
  /// Marks room as READY optimistically - any actual permission issues
  /// will be handled when the user tries to send a message.
  Future<void> onApiSyncComplete(String roomId) async {
    _cancelSyncTimeout(roomId);

    // Try to find subscription in database
    final subscriptionId = await _findMySubscriptionInDb(roomId);

    final stream = _getOrCreateStream(roomId);

    if (subscriptionId != null) {
      stream.add(RoomSyncStatus.ready(subscriptionId));
      _nonReadyStartTimes.remove(roomId);
      _retryAttempts.remove(roomId);

      AppLogger.info(
        'Room sync: Ready - found subscription via API sync',
        data: {
          'roomId': roomId,
          'subscriptionId': subscriptionId.substring(
            0,
            subscriptionId.length < 8 ? subscriptionId.length : 8,
          ),
        },
      );
    } else {
      // Even if we couldn't find the subscription, mark as ready
      // to not block the user. The actual subscription lookup will
      // happen when sending messages, and errors will be shown then.
      stream.add(const RoomSyncStatus(state: RoomSyncState.ready));
      _nonReadyStartTimes.remove(roomId);
      _retryAttempts.remove(roomId);

      AppLogger.warning(
        'Room sync: Ready (optimistic) - subscription not found but API sync complete',
        data: {'roomId': roomId},
      );
    }
  }

  /// Mark a room as ready with a known subscription ID
  ///
  /// Used when subscription ID is already known (e.g., from existing room entry).
  void markReady(String roomId, String subscriptionId) {
    final stream = _getOrCreateStream(roomId);
    stream.add(RoomSyncStatus.ready(subscriptionId));
    _nonReadyStartTimes.remove(roomId);
    _retryAttempts.remove(roomId);

    AppLogger.debug(
      'Room sync: Marked ready with known subscription',
      data: {'roomId': roomId},
    );
  }

  /// Called when a room is downloaded from server during post-login sync
  ///
  /// For rooms fetched from the server, the user is already a member, so we
  /// default to READY state immediately. This prevents blocking the UI while
  /// we fetch subscription details (which is just cache population).
  ///
  /// The subscription ID will be populated later when we fetch room members,
  /// but the user can send messages immediately since the server knows they
  /// are a member.
  void onRoomDownloadedFromServer(String roomId) {
    final stream = _getOrCreateStream(roomId);

    // Only update if not already in a better state
    final current = stream.value;
    if (current.state != RoomSyncState.ready) {
      stream.add(const RoomSyncStatus(state: RoomSyncState.ready));
      _nonReadyStartTimes.remove(roomId);

      AppLogger.debug(
        'Room sync: Room downloaded from server, marked ready',
        data: {'roomId': roomId},
      );
    }
  }

  /// Start a timeout that triggers API sync fallback
  void _startSyncTimeout(String roomId) {
    _cancelSyncTimeout(roomId);

    final retryCount = _retryAttempts[roomId] ?? 0;
    final timeoutDuration = retryCount == 0
        ? const Duration(seconds: _syncTimeoutSeconds)
        : const Duration(seconds: _extendedTimeoutSeconds);

    _syncTimeouts[roomId] = Timer(
      timeoutDuration,
      () => _onSyncTimeout(roomId),
    );
  }

  /// Cancel pending sync timeout for a room
  void _cancelSyncTimeout(String roomId) {
    _syncTimeouts[roomId]?.cancel();
    _syncTimeouts.remove(roomId);
  }

  /// Called when sync timeout fires - triggers API fallback with retry logic
  void _onSyncTimeout(String roomId) {
    final retryCount = _retryAttempts[roomId] ?? 0;

    AppLogger.debug(
      'Room sync: Timeout waiting for member events',
      data: {
        'roomId': roomId,
        'retryCount': retryCount,
        'maxRetries': _maxRetryAttempts,
      },
    );

    // Update retry count
    _retryAttempts[roomId] = retryCount + 1;

    // The actual API call will be triggered by whoever is watching the state
    // This just updates the state to indicate we're still syncing
    final stream = _getOrCreateStream(roomId);
    final current = stream.value;

    if (current.state != RoomSyncState.ready) {
      if (retryCount >= _maxRetryAttempts) {
        // Max retries reached, mark as ready optimistically
        AppLogger.warning(
          'Room sync: Max retries reached, marking ready optimistically',
          data: {'roomId': roomId},
        );
        stream.add(const RoomSyncStatus(state: RoomSyncState.ready));
        _nonReadyStartTimes.remove(roomId);
        _retryAttempts.remove(roomId);
      } else {
        // Still retrying
        stream.add(RoomSyncStatus.syncing(lastSyncAttempt: DateTime.now()));
        // Schedule another timeout
        _startSyncTimeout(roomId);
      }
    }
  }

  /// Find current user's subscription from a list of subscription IDs
  Future<String?> _findMySubscription(
    String roomId,
    List<String> subscriptionIds,
  ) async {
    final currentProfileId = await _authRepository.getCurrentProfileId();
    final currentContactId = await _authRepository.getCurrentContactId();

    if (currentContactId == null) return null;

    // Check each subscription ID to see if it belongs to current user
    for (final subscriptionId in subscriptionIds) {
      final member = await _roomSubscriptionRepository.getSubscription(
        subscriptionId,
      );

      if (member != null &&
          member.contactId == currentContactId &&
          (currentProfileId == null ||
              currentProfileId.isEmpty ||
              member.profileId == currentProfileId)) {
        return subscriptionId;
      }
    }

    return null;
  }

  /// Check if a subscription ID belongs to the current user
  Future<bool> _isMySubscription(String roomId, String subscriptionId) async {
    final currentProfileId = await _authRepository.getCurrentProfileId();
    final currentContactId = await _authRepository.getCurrentContactId();

    if (currentContactId == null) return false;

    return _roomSubscriptionRepository.isCurrentUserSubscription(
      roomId,
      subscriptionId,
      currentProfileId ?? '',
      currentContactId,
    );
  }

  /// Find current user's subscription from database
  ///
  /// Tries multiple strategies to find the subscription:
  /// 1. Match by contactId and profileId
  /// 2. Match by profileId only
  /// 3. Match by contactId only
  Future<String?> _findMySubscriptionInDb(String roomId) async {
    final currentProfileId = await _authRepository.getCurrentProfileId();
    final currentContactId = await _authRepository.getCurrentContactId();

    // Try with both IDs first
    if (currentContactId != null) {
      final subscriptionId = await _roomSubscriptionRepository
          .getCurrentSubscriptionId(
            roomId,
            currentProfileId ?? '',
            currentContactId,
          );
      if (subscriptionId != null) return subscriptionId;
    }

    // Try by profileId only if we have one
    if (currentProfileId != null && currentProfileId.isNotEmpty) {
      final member = await _roomSubscriptionRepository.getMemberByProfileId(
        roomId,
        currentProfileId,
      );
      if (member != null) return member.id;
    }

    return null;
  }

  /// Clean up resources for a room
  void disposeRoom(String roomId) {
    _cancelSyncTimeout(roomId);
    _roomStates[roomId]?.close();
    _roomStates.remove(roomId);
    _nonReadyStartTimes.remove(roomId);
    _retryAttempts.remove(roomId);
  }

  /// Clean up all resources
  void dispose() {
    stopRecoveryTimer();

    for (final roomId in _syncTimeouts.keys.toList()) {
      _cancelSyncTimeout(roomId);
    }

    for (final stream in _roomStates.values) {
      stream.close();
    }
    _roomStates.clear();
    _nonReadyStartTimes.clear();
    _retryAttempts.clear();
  }
}

/// Provider for RoomSyncManager
final roomSyncManagerProvider = Provider<RoomSyncManager>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final memberRepo = ref.watch(roomSubscriptionRepositoryProvider);

  final manager = RoomSyncManager(authRepo, memberRepo);

  // Start the recovery timer for automatic stuck room recovery
  manager.startRecoveryTimer();

  ref.onDispose(manager.dispose);

  return manager;
});

/// Provider for room sync health
final roomSyncHealthProvider = Provider<RoomSyncHealth>((ref) {
  final manager = ref.watch(roomSyncManagerProvider);
  return manager.getHealth();
});
