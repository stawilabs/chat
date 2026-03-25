import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/invite_link.dart';
import 'invite_link_service.dart';

part 'invite_link_providers.g.dart';

/// Provider for watching invite links for a specific room
@riverpod
Stream<List<InviteLink>> roomInviteLinks(Ref ref, String roomId) {
  final service = ref.watch(inviteLinkServiceProvider);
  return service.watchLinksForRoom(roomId);
}

/// Provider for getting active invite links for a room
@riverpod
Future<List<InviteLink>> activeRoomInviteLinks(Ref ref, String roomId) async {
  final service = ref.watch(inviteLinkServiceProvider);
  return service.getActiveLinksForRoom(roomId);
}

/// Provider for getting an invite link by code
@riverpod
Future<InviteLink?> inviteLinkByCode(Ref ref, String code) async {
  final service = ref.watch(inviteLinkServiceProvider);
  return service.getLinkByCode(code);
}

/// Provider for getting users who joined via a specific link
@riverpod
Future<List<InviteLinkJoin>> inviteLinkJoins(Ref ref, String linkId) async {
  final service = ref.watch(inviteLinkServiceProvider);
  return service.getJoinsForLink(linkId);
}

/// Provider for pending approval requests for a room
@riverpod
Future<List<InviteLinkJoin>> pendingApprovals(Ref ref, String roomId) async {
  final service = ref.watch(inviteLinkServiceProvider);
  return service.getPendingApprovalsForRoom(roomId);
}

/// Notifier for managing invite link creation and actions
@riverpod
class InviteLinkNotifier extends _$InviteLinkNotifier {
  @override
  FutureOr<void> build() {}

  /// Create a new invite link
  Future<InviteLink> createLink({
    required String roomId,
    required String createdBy,
    Duration? expiresIn,
    int? maxUses,
    bool requiresApproval = false,
    String? name,
  }) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(inviteLinkServiceProvider);

      final InviteLink link;
      if (expiresIn != null) {
        link = await service.createInviteLinkWithDuration(
          roomId: roomId,
          createdBy: createdBy,
          duration: expiresIn,
          maxUses: maxUses,
          requiresApproval: requiresApproval,
          name: name,
        );
      } else {
        link = await service.createInviteLink(
          roomId: roomId,
          createdBy: createdBy,
          maxUses: maxUses,
          requiresApproval: requiresApproval,
          name: name,
        );
      }

      state = const AsyncData(null);

      // Invalidate the room links provider to refresh the list
      ref.invalidate(roomInviteLinksProvider(roomId));
      ref.invalidate(activeRoomInviteLinksProvider(roomId));

      return link;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Revoke an invite link
  Future<void> revokeLink(String linkId, String roomId) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(inviteLinkServiceProvider);
      await service.revokeLink(linkId);

      state = const AsyncData(null);

      // Invalidate providers to refresh
      ref.invalidate(roomInviteLinksProvider(roomId));
      ref.invalidate(activeRoomInviteLinksProvider(roomId));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Delete an invite link
  Future<void> deleteLink(String linkId, String roomId) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(inviteLinkServiceProvider);
      await service.deleteLink(linkId);

      state = const AsyncData(null);

      // Invalidate providers to refresh
      ref.invalidate(roomInviteLinksProvider(roomId));
      ref.invalidate(activeRoomInviteLinksProvider(roomId));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Use an invite link to join a room
  Future<InviteLink> useLink({
    required String code,
    required String profileId,
  }) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(inviteLinkServiceProvider);
      final link = await service.useInviteLink(
        code: code,
        profileId: profileId,
      );

      state = const AsyncData(null);
      return link;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Approve a join request
  Future<void> approveJoin({
    required int joinId,
    required String roomId,
    required String profileId,
  }) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(inviteLinkServiceProvider);
      await service.approveJoinRequest(
        joinId: joinId,
        roomId: roomId,
        profileId: profileId,
      );

      state = const AsyncData(null);

      // Invalidate pending approvals provider
      ref.invalidate(pendingApprovalsProvider(roomId));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Reject a join request
  Future<void> rejectJoin({
    required int joinId,
    required String roomId,
    required String profileId,
  }) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(inviteLinkServiceProvider);
      await service.rejectJoinRequest(joinId: joinId, profileId: profileId);

      state = const AsyncData(null);

      // Invalidate pending approvals provider
      ref.invalidate(pendingApprovalsProvider(roomId));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
