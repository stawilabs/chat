import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';
import '../../../features/auth/data/auth_repository.dart';
import 'room_subscription_repository.dart';

part 'room_subscription_service.g.dart';

/// Provider for RoomSubscriptionRepository
final roomSubscriptionRepositoryProvider = Provider<RoomSubscriptionRepository>(
  (ref) => RoomSubscriptionRepository(AppDatabase.instance),
);

/// Service for managing room subscriptions and profile ID updates
/// Handles anonymous subscriptions and profile ID updates
/// Uses RoomSubscriptionRepository for all database operations
class RoomSubscriptionService {
  RoomSubscriptionService(this._repository);
  final RoomSubscriptionRepository _repository;

  /// Update profile ID for an existing subscription
  /// Used when a user authenticates and their profile ID becomes known
  ///
  /// @param id The room subscription to update
  /// @param profileId The profile ID to associate with this subscription
  /// @param contactId Optional contact ID used for this subscription
  /// @return true if update was successful, false if subscription not found
  Future<bool> updateSubscriptionProfile({
    required String id,
    required String profileId,
    String? contactId,
  }) async => _repository.updateSubscriptionProfile(
    id: id,
    profileId: profileId,
    contactId: contactId,
  );

  /// Get all subscriptions for a profile across all rooms
  /// Useful for finding all rooms a user is subscribed to
  ///
  /// @param profileId The profile ID to search for
  /// @return List of room subscriptions for this profile
  Future<List<RoomSubscription>> getProfileSubscriptions(
    String profileId,
  ) async => _repository.getProfileSubscriptions(profileId);

  /// Get all subscriptions without a profile ID (anonymous subscriptions)
  /// Useful for finding subscriptions that need profile assignment
  ///
  /// @param roomId Optional room filter
  /// @return List of anonymous subscriptions
  Future<List<RoomSubscription>> getAnonymousSubscriptions({
    String? roomId,
  }) async => _repository.getAnonymousSubscriptions(roomId: roomId);

  /// Create a new subscription (can be anonymous initially)
  ///
  /// @param id The subscription ID from API
  /// @param roomId The room ID
  /// @param profileId Optional profile ID (can be null for anonymous)
  /// @param contactId Optional contact ID
  /// @param role Optional role in the room
  /// @return true if creation was successful
  Future<bool> createSubscription({
    required String id,
    required String roomId,
    String? profileId,
    String? contactId,
    String? role,
  }) async => _repository.createSubscription(
    id: id,
    roomId: roomId,
    profileId: profileId,
    contactId: contactId,
    role: role,
  );

  /// Remove a subscription from a room
  ///
  /// @param id The subscription ID to remove
  /// @return true if removal was successful
  Future<bool> removeSubscription(String id) async =>
      _repository.removeSubscription(id);

  /// Check if a subscription exists for a profile in a room
  ///
  /// @param roomId The room ID
  /// @param profileId The profile ID
  /// @return true if subscription exists
  Future<bool> hasSubscription(String roomId, String profileId) async =>
      _repository.hasSubscription(roomId, profileId);

  /// Get subscription by subscription ID
  ///
  /// @param id The subscription ID
  /// @return Room subscription if found, null otherwise
  Future<RoomSubscription?> getSubscription(String id) async =>
      _repository.getSubscription(id);

  /// Get current profile's subscription ID for a specific room
  /// Returns null if the profile is not a member of the room
  ///
  /// @param roomId The room ID
  /// @param profileId The current profile's ID
  /// @param contactId The current contact's ID
  /// @return Subscription ID if found, null otherwise
  Future<String?> getCurrentSubscriptionId(
    String roomId,
    String profileId,
    String contactId,
  ) async => _repository.getCurrentSubscriptionId(roomId, profileId, contactId);

  /// Check if a subscription ID belongs to the current profile's contact
  ///
  /// @param roomId The room context
  /// @param id The subscription ID to check
  /// @param profileId The current profile's ID
  /// @param contactId The current contact's ID
  /// @return true if this subscription belongs to current profile's contact
  Future<bool> isCurrentUserSubscription(
    String roomId,
    String id,
    String profileId,
    String contactId,
  ) async =>
      _repository.isCurrentUserSubscription(roomId, id, profileId, contactId);
}

/// Provider for RoomSubscriptionService
@riverpod
RoomSubscriptionService roomSubscriptionService(Ref ref) =>
    RoomSubscriptionService(RoomSubscriptionRepository(AppDatabase.instance));

/// Provider for current user's subscription ID for a specific room
/// Returns the subscription ID or null if not found
@riverpod
Future<String?> currentUserSubscriptionId(Ref ref, String roomId) async {
  final authRepo = ref.watch(authRepositoryProvider);
  final subscriptionService = ref.watch(roomSubscriptionServiceProvider);

  final profileId = await authRepo.getCurrentProfileId();
  final contactId = await authRepo.getCurrentContactId();

  if (profileId == null || contactId == null) {
    return null;
  }

  return subscriptionService.getCurrentSubscriptionId(
    roomId,
    profileId,
    contactId,
  );
}

/// Provider to look up profile ID from a subscription ID
/// Returns the profile ID or null if subscription not found
@riverpod
Future<String?> profileIdFromSubscription(
  Ref ref,
  String subscriptionId,
) async {
  final subscriptionService = ref.watch(roomSubscriptionServiceProvider);
  final member = await subscriptionService.getSubscription(subscriptionId);
  return member?.profileId;
}
