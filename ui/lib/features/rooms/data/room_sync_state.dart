/// Room synchronization state for tracking room readiness
///
/// This enum represents the lifecycle states of a room from creation
/// to being ready for messaging.
enum RoomSyncState {
  /// Room created locally, job queued for server sync.
  /// User can navigate to room but cannot send messages yet.
  creating,

  /// Room exists on server, waiting for member subscription data.
  /// This state is entered after server confirms room creation
  /// but before we have the current user's subscription ID.
  syncing,

  /// Room is fully ready - has current user's subscription ID.
  /// User can send messages, typing indicators, and read receipts.
  ready,
}

/// Status object combining sync state with subscription information
class RoomSyncStatus {
  const RoomSyncStatus({
    required this.state,
    this.currentUserSubscriptionId,
    this.lastSyncAttempt,
    this.syncError,
    this.isProvisional = false,
  });

  /// Factory for creating initial creating state
  factory RoomSyncStatus.creating() =>
      const RoomSyncStatus(state: RoomSyncState.creating);

  /// Factory for creating syncing state
  factory RoomSyncStatus.syncing({DateTime? lastSyncAttempt}) => RoomSyncStatus(
    state: RoomSyncState.syncing,
    lastSyncAttempt: lastSyncAttempt,
  );

  /// Factory for creating ready state with subscription ID
  factory RoomSyncStatus.ready(String subscriptionId) => RoomSyncStatus(
    state: RoomSyncState.ready,
    currentUserSubscriptionId: subscriptionId,
  );

  /// Factory for creating ready state with a provisional subscription ID.
  /// The room is usable but messages will be re-attributed once the real
  /// subscription arrives from the server.
  factory RoomSyncStatus.readyProvisional(String subscriptionId) =>
      RoomSyncStatus(
        state: RoomSyncState.ready,
        currentUserSubscriptionId: subscriptionId,
        isProvisional: true,
      );

  /// The current sync state
  final RoomSyncState state;

  /// The current user's subscription ID for this room (available when ready)
  final String? currentUserSubscriptionId;

  /// Timestamp of last sync attempt (for retry logic)
  final DateTime? lastSyncAttempt;

  /// Error message if sync failed (internal use, not shown to users)
  final String? syncError;

  /// Whether the subscription is provisional (created locally, not yet confirmed by server)
  final bool isProvisional;

  /// Whether the user can send messages in this room
  ///
  /// Only requires READY state. Subscription ID is looked up lazily
  /// at send time via AuthContextService.requireSubscriptionIdForRoom(),
  /// which will sync if needed. This prevents optimistic-READY states
  /// (after timeout recovery) from permanently blocking the input.
  bool get canSendMessages => state == RoomSyncState.ready;

  /// Whether the room is still being set up
  bool get isSettingUp =>
      state == RoomSyncState.creating || state == RoomSyncState.syncing;

  /// Copy with updated fields
  RoomSyncStatus copyWith({
    RoomSyncState? state,
    String? currentUserSubscriptionId,
    DateTime? lastSyncAttempt,
    String? syncError,
    bool? isProvisional,
  }) => RoomSyncStatus(
    state: state ?? this.state,
    currentUserSubscriptionId:
        currentUserSubscriptionId ?? this.currentUserSubscriptionId,
    lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
    syncError: syncError ?? this.syncError,
    isProvisional: isProvisional ?? this.isProvisional,
  );

  @override
  String toString() =>
      'RoomSyncStatus(state: $state, subscriptionId: ${currentUserSubscriptionId?.substring(0, 8) ?? "null"}, provisional: $isProvisional)';
}
