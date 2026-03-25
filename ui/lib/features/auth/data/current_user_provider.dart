import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_repository.dart';
import 'user_info_provider.dart';

part 'current_user_provider.g.dart';

/// Provider for the current user's PROFILE ID (from JWT 'sub' claim)
/// This represents the entity (person/organization) identity
/// NOT to be confused with contact ID or subscription ID
/// Returns null if the user is not authenticated or no profile info is available
@riverpod
Future<String?> currentProfileId(Ref ref) async {
  final userInfo = await ref.watch(userInfoProvider.future);
  return userInfo?.id;
}

/// Non-null version that throws if profile ID is not available
/// Use this in contexts where authentication is required
@riverpod
Future<String> currentProfileIdOrThrow(Ref ref) async {
  final profileId = await ref.watch(currentProfileIdProvider.future);
  if (profileId == null) {
    throw Exception('Profile not authenticated - no profile ID available');
  }
  return profileId;
}

/// Provider for the current user's CONTACT ID (from JWT 'contact_id' claim)
/// This represents the contact method (phone/email) used for authentication
/// A single profile can have multiple contact IDs
/// Returns null if the user is not authenticated or no contact ID is available
@riverpod
Future<String?> currentContactId(Ref ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getCurrentContactId();
}

/// Non-null version that throws if contact ID is not available
/// Use this in contexts where contact ID is required
@riverpod
Future<String> currentContactIdOrThrow(Ref ref) async {
  final contactId = await ref.watch(currentContactIdProvider.future);
  if (contactId == null) {
    throw Exception('Contact ID not available in JWT token');
  }
  return contactId;
}
