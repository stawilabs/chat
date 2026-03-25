import 'package:freezed_annotation/freezed_annotation.dart';

part 'invite_link.freezed.dart';
part 'invite_link.g.dart';

/// Invite link domain model
///
/// Represents a shareable invite link for joining a room.
/// Links can have optional expiration, max uses, and approval requirements.
///
/// Example:
/// ```dart
/// final link = InviteLink(
///   id: 'link-123',
///   roomId: 'room-456',
///   code: 'abc123',
///   createdBy: 'profile-789',
///   createdAt: DateTime.now().millisecondsSinceEpoch,
/// );
/// ```
@freezed
abstract class InviteLink with _$InviteLink {
  const factory InviteLink({
    required String id,
    required String roomId,
    required String code,
    required String createdBy,
    required int createdAt,
    int? expiresAt,
    int? maxUses,
    @Default(0) int useCount,
    @Default(false) bool revoked,
    @Default(false) bool requiresApproval,
    String? name,
  }) = _InviteLink;

  const InviteLink._();

  factory InviteLink.fromJson(Map<String, dynamic> json) =>
      _$InviteLinkFromJson(json);

  /// Returns the full invite URL
  String get inviteUrl => 'https://chat.app/join/$code';

  /// Checks if the link is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch > expiresAt!;
  }

  /// Checks if the link has reached its max uses
  bool get isMaxedOut {
    if (maxUses == null) return false;
    return useCount >= maxUses!;
  }

  /// Checks if the link is valid (not revoked, not expired, not maxed out)
  bool get isValid => !revoked && !isExpired && !isMaxedOut;

  /// Returns a human-readable status string
  String get statusText {
    if (revoked) return 'Revoked';
    if (isExpired) return 'Expired';
    if (isMaxedOut) return 'Max uses reached';
    return 'Active';
  }

  /// Returns remaining uses, or null if unlimited
  int? get remainingUses {
    if (maxUses == null) return null;
    return maxUses! - useCount;
  }
}

/// Represents a user who joined via an invite link
@freezed
abstract class InviteLinkJoin with _$InviteLinkJoin {
  const factory InviteLinkJoin({
    required int id,
    required String inviteLinkId,
    required String profileId,
    required int joinedAt,
    @Default('approved') String status,
  }) = _InviteLinkJoin;

  factory InviteLinkJoin.fromJson(Map<String, dynamic> json) =>
      _$InviteLinkJoinFromJson(json);
}
