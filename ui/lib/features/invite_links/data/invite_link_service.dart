import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xid/xid.dart';

import '../../../core/db/database.dart' hide InviteLink, InviteLinkJoin;
import '../../../core/logging/app_logger.dart';
import '../../../core/sync/pending_job.dart';
import '../../../core/sync/pending_job_repository.dart';
import '../domain/invite_link.dart';
import 'invite_link_repository.dart';

/// Service for managing invite links with offline-first support
///
/// All operations are saved locally first, then queued for server sync.
/// Provides methods for creating, validating, and managing invite links.
class InviteLinkService {
  InviteLinkService(this._repository, this._jobRepository);

  final InviteLinkRepository _repository;
  final PendingJobRepository _jobRepository;

  /// Base URL for invite links
  static const String baseUrl = 'https://chat.app/join/';

  /// Generate a random invite code
  ///
  /// Uses a combination of alphanumeric characters for readability.
  /// Default length is 8 characters.
  static String generateCode({int length = 8}) {
    const chars = 'abcdefghijkmnpqrstuvwxyz23456789'; // Removed confusing chars
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Create a new invite link for a room
  ///
  /// Parameters:
  /// - [roomId]: The room to create the invite for
  /// - [createdBy]: Profile ID of the creator
  /// - [expiresAt]: Optional expiration timestamp (milliseconds)
  /// - [maxUses]: Optional maximum number of uses
  /// - [requiresApproval]: Whether joining requires admin approval
  /// - [name]: Optional custom name/label for the link
  Future<InviteLink> createInviteLink({
    required String roomId,
    required String createdBy,
    int? expiresAt,
    int? maxUses,
    bool requiresApproval = false,
    String? name,
  }) async {
    final id = Xid().toString();
    final code = generateCode();
    final createdAtTs = DateTime.now().millisecondsSinceEpoch;

    final link = InviteLink(
      id: id,
      roomId: roomId,
      code: code,
      createdBy: createdBy,
      createdAt: createdAtTs,
      expiresAt: expiresAt,
      maxUses: maxUses,
      requiresApproval: requiresApproval,
      name: name,
    );

    // Save locally first
    await _repository.insertLink(link);

    // Queue for server sync
    await _jobRepository.addJob(JobType.createInviteLink, {
      'id': id,
      'roomId': roomId,
      'code': code,
      'createdBy': createdBy,
      'createdAt': createdAtTs,
      'expiresAt': expiresAt,
      'maxUses': maxUses,
      'requiresApproval': requiresApproval,
      'name': name,
    });

    AppLogger.info(
      'Invite link created locally and queued for sync',
      data: {'linkId': id, 'roomId': roomId, 'code': code},
    );

    return link;
  }

  /// Create an invite link with a specific expiration duration
  ///
  /// Convenience method that calculates expiration from duration.
  Future<InviteLink> createInviteLinkWithDuration({
    required String roomId,
    required String createdBy,
    required Duration duration,
    int? maxUses,
    bool requiresApproval = false,
    String? name,
  }) async {
    final expiresAt = DateTime.now().add(duration).millisecondsSinceEpoch;
    return createInviteLink(
      roomId: roomId,
      createdBy: createdBy,
      expiresAt: expiresAt,
      maxUses: maxUses,
      requiresApproval: requiresApproval,
      name: name,
    );
  }

  /// Get an invite link by its code
  Future<InviteLink?> getLinkByCode(String code) async =>
      _repository.getLinkByCode(code);

  /// Get an invite link by its ID
  Future<InviteLink?> getLinkById(String id) async =>
      _repository.getLinkById(id);

  /// Get all invite links for a room
  Future<List<InviteLink>> getLinksForRoom(String roomId) async =>
      _repository.getLinksForRoom(roomId);

  /// Get active invite links for a room
  Future<List<InviteLink>> getActiveLinksForRoom(String roomId) async =>
      _repository.getActiveLinksForRoom(roomId);

  /// Watch invite links for a room (reactive stream)
  Stream<List<InviteLink>> watchLinksForRoom(String roomId) =>
      _repository.watchLinksForRoom(roomId);

  /// Revoke an invite link
  Future<void> revokeLink(String linkId) async {
    await _repository.revokeLink(linkId);

    // Queue for server sync
    await _jobRepository.addJob(JobType.revokeInviteLink, {'linkId': linkId});

    AppLogger.info(
      'Invite link revoked locally and queued for sync',
      data: {'linkId': linkId},
    );
  }

  /// Delete an invite link
  Future<void> deleteLink(String linkId) async {
    await _repository.deleteLink(linkId);

    AppLogger.info('Invite link deleted locally', data: {'linkId': linkId});
  }

  /// Validate and use an invite link
  ///
  /// Returns the link if valid, or throws an exception if invalid.
  /// This method checks all validity conditions and increments use count.
  Future<InviteLink> useInviteLink({
    required String code,
    required String profileId,
  }) async {
    final link = await _repository.getLinkByCode(code);

    if (link == null) {
      throw InviteLinkException('Invite link not found');
    }

    if (link.revoked) {
      throw InviteLinkException('This invite link has been revoked');
    }

    if (link.isExpired) {
      throw InviteLinkException('This invite link has expired');
    }

    if (link.isMaxedOut) {
      throw InviteLinkException(
        'This invite link has reached its maximum uses',
      );
    }

    // Increment use count
    await _repository.incrementUseCount(link.id);

    // Record the join (with appropriate status based on approval setting)
    final status = link.requiresApproval ? 'pending' : 'approved';
    await _repository.recordJoin(
      inviteLinkId: link.id,
      profileId: profileId,
      status: status,
    );

    // Queue for server sync
    await _jobRepository.addJob(JobType.useInviteLink, {
      'linkId': link.id,
      'code': code,
      'roomId': link.roomId,
      'profileId': profileId,
      'requiresApproval': link.requiresApproval,
    });

    AppLogger.info(
      'Invite link used locally and queued for sync',
      data: {
        'linkId': link.id,
        'roomId': link.roomId,
        'profileId': profileId,
        'requiresApproval': link.requiresApproval,
      },
    );

    return link;
  }

  /// Get all users who joined via a specific invite link
  Future<List<InviteLinkJoin>> getJoinsForLink(String linkId) async =>
      _repository.getJoinsForLink(linkId);

  /// Get pending approval requests for a room's invite links
  Future<List<InviteLinkJoin>> getPendingApprovalsForRoom(
    String roomId,
  ) async => _repository.getPendingApprovalsForRoom(roomId);

  /// Approve a join request
  Future<void> approveJoinRequest({
    required int joinId,
    required String roomId,
    required String profileId,
  }) async {
    await _repository.updateJoinStatus(joinId: joinId, status: 'approved');

    // Queue for server sync
    await _jobRepository.addJob(JobType.approveJoinRequest, {
      'joinId': joinId,
      'roomId': roomId,
      'profileId': profileId,
    });

    AppLogger.info(
      'Join request approved locally and queued for sync',
      data: {'joinId': joinId, 'profileId': profileId},
    );
  }

  /// Reject a join request
  Future<void> rejectJoinRequest({
    required int joinId,
    required String profileId,
  }) async {
    await _repository.updateJoinStatus(joinId: joinId, status: 'rejected');

    // Queue for server sync
    await _jobRepository.addJob(JobType.rejectJoinRequest, {
      'joinId': joinId,
      'profileId': profileId,
    });

    AppLogger.info(
      'Join request rejected locally and queued for sync',
      data: {'joinId': joinId, 'profileId': profileId},
    );
  }

  /// Parse an invite code from a URL
  ///
  /// Accepts both full URLs and just codes.
  /// Returns null if the URL/code is invalid.
  static String? parseCodeFromUrl(String input) {
    // If it's just the code (no slashes), return it
    if (!input.contains('/')) {
      return input.isNotEmpty ? input : null;
    }

    // Try to parse as URL
    final uri = Uri.tryParse(input);
    if (uri == null) return null;

    // Check for /join/{code} pattern
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[segments.length - 2] == 'join') {
      return segments.last;
    }

    // Check for just /{code} at the end
    if (segments.isNotEmpty) {
      return segments.last;
    }

    return null;
  }
}

/// Exception thrown when invite link operations fail
class InviteLinkException implements Exception {
  InviteLinkException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Provider for InviteLinkService
final inviteLinkServiceProvider = Provider<InviteLinkService>((ref) {
  final repository = ref.watch(inviteLinkRepositoryProvider);
  final jobRepository = PendingJobRepository(AppDatabase.instance);
  return InviteLinkService(repository, jobRepository);
});
