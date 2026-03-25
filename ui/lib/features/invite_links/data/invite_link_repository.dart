import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../domain/invite_link.dart' as domain;

/// Repository for invite link database operations
///
/// Provides database access for invite link management including:
/// - Creating and fetching invite links
/// - Recording link usage
/// - Revoking links
/// - Getting join history
///
/// Example:
/// ```dart
/// final repo = InviteLinkRepository(database);
/// final links = await repo.getLinksForRoom('room-123');
/// final link = await repo.getLinkByCode('abc123');
/// ```
class InviteLinkRepository {
  InviteLinkRepository(this._database);
  final AppDatabase _database;

  /// Insert or update an invite link
  Future<void> insertLink(domain.InviteLink link) async {
    await _database
        .into(_database.inviteLinks)
        .insertOnConflictUpdate(
          InviteLinksCompanion.insert(
            id: link.id,
            roomId: link.roomId,
            code: link.code,
            createdBy: link.createdBy,
            createdAt: link.createdAt,
            expiresAt: Value(link.expiresAt),
            maxUses: Value(link.maxUses),
            useCount: Value(link.useCount),
            revoked: Value(link.revoked),
            requiresApproval: Value(link.requiresApproval),
            name: Value(link.name),
          ),
        );
  }

  /// Get an invite link by its code
  Future<domain.InviteLink?> getLinkByCode(String code) async {
    final query = _database.select(_database.inviteLinks)
      ..where((t) => t.code.equals(code));
    final result = await query.getSingleOrNull();

    if (result == null) return null;
    return _toInviteLink(result);
  }

  /// Get an invite link by its ID
  Future<domain.InviteLink?> getLinkById(String id) async {
    final query = _database.select(_database.inviteLinks)
      ..where((t) => t.id.equals(id));
    final result = await query.getSingleOrNull();

    if (result == null) return null;
    return _toInviteLink(result);
  }

  /// Get all invite links for a room
  Future<List<domain.InviteLink>> getLinksForRoom(String roomId) async {
    final query = _database.select(_database.inviteLinks)
      ..where((t) => t.roomId.equals(roomId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final results = await query.get();

    return results.map(_toInviteLink).toList();
  }

  /// Get active (non-revoked, non-expired) invite links for a room
  Future<List<domain.InviteLink>> getActiveLinksForRoom(String roomId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final query = _database.select(_database.inviteLinks)
      ..where(
        (t) =>
            t.roomId.equals(roomId) &
            t.revoked.equals(false) &
            (t.expiresAt.isNull() | t.expiresAt.isBiggerThanValue(now)),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final results = await query.get();

    // Filter out maxed out links in memory (complex SQL for this)
    return results
        .map(_toInviteLink)
        .where((link) => !link.isMaxedOut)
        .toList();
  }

  /// Revoke an invite link
  Future<void> revokeLink(String id) async {
    await (_database.update(_database.inviteLinks)
          ..where((t) => t.id.equals(id)))
        .write(const InviteLinksCompanion(revoked: Value(true)));
  }

  /// Increment the use count of a link
  Future<void> incrementUseCount(String id) async {
    await _database.customStatement(
      '''
      UPDATE invite_links SET use_count = use_count + 1 WHERE id = ?
    ''',
      [id],
    );
  }

  /// Delete an invite link
  Future<void> deleteLink(String id) async {
    // First delete related joins
    await (_database.delete(
      _database.inviteLinkJoins,
    )..where((t) => t.inviteLinkId.equals(id))).go();
    // Then delete the link
    await (_database.delete(
      _database.inviteLinks,
    )..where((t) => t.id.equals(id))).go();
  }

  /// Record a user joining via an invite link
  Future<void> recordJoin({
    required String inviteLinkId,
    required String profileId,
    String status = 'approved',
  }) async {
    await _database
        .into(_database.inviteLinkJoins)
        .insert(
          InviteLinkJoinsCompanion.insert(
            inviteLinkId: inviteLinkId,
            profileId: profileId,
            joinedAt: DateTime.now().millisecondsSinceEpoch,
            status: Value(status),
          ),
        );
  }

  /// Get all users who joined via a specific invite link
  Future<List<domain.InviteLinkJoin>> getJoinsForLink(String linkId) async {
    final query = _database.select(_database.inviteLinkJoins)
      ..where((t) => t.inviteLinkId.equals(linkId))
      ..orderBy([(t) => OrderingTerm.desc(t.joinedAt)]);
    final results = await query.get();

    return results.map(_toInviteLinkJoin).toList();
  }

  /// Get pending approval requests for a room's invite links
  Future<List<domain.InviteLinkJoin>> getPendingApprovalsForRoom(
    String roomId,
  ) async {
    final results = await _database
        .customSelect(
          '''
      SELECT j.* FROM invite_link_joins j
      INNER JOIN invite_links l ON j.invite_link_id = l.id
      WHERE l.room_id = ? AND j.status = 'pending'
      ORDER BY j.joined_at DESC
      ''',
          variables: [Variable.withString(roomId)],
          readsFrom: {_database.inviteLinkJoins, _database.inviteLinks},
        )
        .get();

    return results.map((row) {
      return domain.InviteLinkJoin(
        id: row.read<int>('id'),
        inviteLinkId: row.read<String>('invite_link_id'),
        profileId: row.read<String>('profile_id'),
        joinedAt: row.read<int>('joined_at'),
        status: row.read<String>('status'),
      );
    }).toList();
  }

  /// Update the approval status of a join request
  Future<void> updateJoinStatus({
    required int joinId,
    required String status,
  }) async {
    await (_database.update(_database.inviteLinkJoins)
          ..where((t) => t.id.equals(joinId)))
        .write(InviteLinkJoinsCompanion(status: Value(status)));
  }

  /// Watch invite links for a room (reactive stream)
  Stream<List<domain.InviteLink>> watchLinksForRoom(String roomId) {
    final query = _database.select(_database.inviteLinks)
      ..where((t) => t.roomId.equals(roomId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    return query.watch().map((rows) => rows.map(_toInviteLink).toList());
  }

  domain.InviteLink _toInviteLink(InviteLink row) => domain.InviteLink(
    id: row.id,
    roomId: row.roomId,
    code: row.code,
    createdBy: row.createdBy,
    createdAt: row.createdAt,
    expiresAt: row.expiresAt,
    maxUses: row.maxUses,
    useCount: row.useCount,
    revoked: row.revoked,
    requiresApproval: row.requiresApproval,
    name: row.name,
  );

  domain.InviteLinkJoin _toInviteLinkJoin(InviteLinkJoin row) =>
      domain.InviteLinkJoin(
        id: row.id,
        inviteLinkId: row.inviteLinkId,
        profileId: row.profileId,
        joinedAt: row.joinedAt,
        status: row.status,
      );
}

/// Provider for InviteLinkRepository
final inviteLinkRepositoryProvider = Provider<InviteLinkRepository>(
  (ref) => InviteLinkRepository(AppDatabase.instance),
);
