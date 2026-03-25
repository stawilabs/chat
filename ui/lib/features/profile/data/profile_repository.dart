import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:antinvestor_api_common/antinvestor_api_common.dart' as common;
import 'package:antinvestor_api_profile/antinvestor_api_profile.dart' as pb;
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/files/files_upload_service.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/networking/client.dart';
import '../../auth/data/user_info_provider.dart';
import '../domain/user_status.dart';

/// Contact type enum for phone/email management
enum ContactType { email, phone }

/// Result of a profile update operation
class ProfileUpdateResult {
  const ProfileUpdateResult._({required this.success, this.errorMessage});

  factory ProfileUpdateResult.success() =>
      const ProfileUpdateResult._(success: true);

  factory ProfileUpdateResult.failure(String message) =>
      ProfileUpdateResult._(success: false, errorMessage: message);

  final bool success;
  final String? errorMessage;
}

/// Contact info for display in UI
class ContactInfo {
  const ContactInfo({
    required this.id,
    required this.type,
    required this.value,
    this.isVerified = false,
    this.isPrimary = false,
  });

  final String id;
  final ContactType type;
  final String value;
  final bool isVerified;
  final bool isPrimary;
}

/// Repository for managing user profile data
class ProfileRepository {
  ProfileRepository(this._ref);

  final Ref _ref;

  /// Get the current user's profile from local database
  Future<Profile?> getCurrentProfile() async {
    final db = AppDatabase.instance;
    final userInfo = await _ref.read(userInfoProvider.future);
    if (userInfo?.id == null) return null;

    final query = db.select(db.profiles)
      ..where((t) => t.id.equals(userInfo!.id!));

    return query.getSingleOrNull();
  }

  /// Get the bio from the current profile's metadata
  Future<String?> getCurrentBio() async {
    final profile = await getCurrentProfile();
    if (profile?.metadata == null || profile!.metadata!.isEmpty) {
      return null;
    }

    try {
      final metadataMap = jsonDecode(profile.metadata!) as Map<String, dynamic>;
      return metadataMap['bio'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Update the user's display name
  Future<ProfileUpdateResult> updateDisplayName(String name) async {
    try {
      final profileClient = await _ref.read(profileClientProvider.future);
      final userInfo = await _ref.read(userInfoProvider.future);

      if (userInfo?.id == null) {
        return ProfileUpdateResult.failure('User not authenticated');
      }

      final properties = common.Struct()
        ..fields['name'] = (common.Value()..stringValue = name);

      final request = pb.UpdateRequest(
        id: userInfo!.id,
        properties: properties,
      );

      await profileClient.stub.update(request);

      // Update local database
      await _updateLocalProfile(name: name);

      AppLogger.info('Profile name updated', data: {'name': name});
      return ProfileUpdateResult.success();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to update display name',
        error: e,
        stackTrace: stackTrace,
      );
      return ProfileUpdateResult.failure(e.toString());
    }
  }

  /// Update the user's bio/about text
  Future<ProfileUpdateResult> updateBio(String bio) async {
    try {
      final profileClient = await _ref.read(profileClientProvider.future);
      final userInfo = await _ref.read(userInfoProvider.future);

      if (userInfo?.id == null) {
        return ProfileUpdateResult.failure('User not authenticated');
      }

      final properties = common.Struct()
        ..fields['bio'] = (common.Value()..stringValue = bio);

      final request = pb.UpdateRequest(
        id: userInfo!.id,
        properties: properties,
      );

      await profileClient.stub.update(request);

      // Update local database metadata
      await _updateLocalProfile(bio: bio);

      AppLogger.info('Profile bio updated');
      return ProfileUpdateResult.success();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update bio', error: e, stackTrace: stackTrace);
      return ProfileUpdateResult.failure(e.toString());
    }
  }

  /// Update the user's status
  ///
  /// [status] The new status to set
  /// [statusMessage] Optional custom status message (e.g., "In a meeting")
  Future<ProfileUpdateResult> updateStatus(
    UserStatus status, {
    String? statusMessage,
  }) async {
    try {
      final profileClient = await _ref.read(profileClientProvider.future);
      final userInfo = await _ref.read(userInfoProvider.future);

      if (userInfo?.id == null) {
        return ProfileUpdateResult.failure('User not authenticated');
      }

      final properties = common.Struct()
        ..fields['status'] = (common.Value()
          ..numberValue = status.value.toDouble());

      if (statusMessage != null) {
        properties.fields['status_message'] = (common.Value()
          ..stringValue = statusMessage);
      }

      final request = pb.UpdateRequest(
        id: userInfo!.id,
        properties: properties,
      );

      await profileClient.stub.update(request);

      // Update local database
      await _updateLocalProfile(status: status, statusMessage: statusMessage);

      AppLogger.info(
        'Profile status updated',
        data: {'status': status.name, 'statusMessage': statusMessage},
      );
      return ProfileUpdateResult.success();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to update status',
        error: e,
        stackTrace: stackTrace,
      );
      return ProfileUpdateResult.failure(e.toString());
    }
  }

  /// Get the current user's status
  Future<UserStatus> getCurrentStatus() async {
    final profile = await getCurrentProfile();
    if (profile == null) return UserStatus.offline;
    return UserStatus.fromValue(profile.status);
  }

  /// Get the current user's status message
  Future<String?> getCurrentStatusMessage() async {
    final profile = await getCurrentProfile();
    return profile?.statusMessage;
  }

  /// Clear the user's status message (keeps status)
  Future<ProfileUpdateResult> clearStatusMessage() async {
    final currentStatus = await getCurrentStatus();
    return updateStatus(currentStatus, statusMessage: '');
  }

  /// Update the user's profile photo using a File (mobile/desktop)
  /// Returns the URL of the uploaded avatar
  Future<ProfileUpdateResult> updateProfilePhoto(File imageFile) async {
    return _updateProfilePhotoWithData(null, imageFile);
  }

  /// Update the user's profile photo using raw bytes (web/mobile)
  /// Returns the URL of the uploaded avatar
  Future<ProfileUpdateResult> updateProfilePhotoBytes(Uint8List bytes) async {
    return _updateProfilePhotoWithData(bytes, null);
  }

  /// Internal method that handles both bytes and file uploads
  Future<ProfileUpdateResult> _updateProfilePhotoWithData(
    Uint8List? bytes,
    File? imageFile,
  ) async {
    try {
      AppLogger.debug(
        '_updateProfilePhotoWithData: Starting profile photo update',
      );

      AppLogger.debug(
        '_updateProfilePhotoWithData: Getting profileClientProvider.future',
      );
      final profileClient = await _ref.read(profileClientProvider.future);
      AppLogger.debug('_updateProfilePhotoWithData: Got profile client');

      AppLogger.debug(
        '_updateProfilePhotoWithData: Getting filesUploadServiceProvider',
      );
      final uploadService = _ref.read(filesUploadServiceProvider);
      AppLogger.debug('_updateProfilePhotoWithData: Got upload service');

      AppLogger.debug(
        '_updateProfilePhotoWithData: Getting userInfoProvider.future',
      );
      final userInfo = await _ref.read(userInfoProvider.future);
      AppLogger.debug(
        '_updateProfilePhotoWithData: Got user info: ${userInfo?.id}',
      );

      if (userInfo?.id == null) {
        AppLogger.warning(
          '_updateProfilePhotoWithData: User not authenticated',
        );
        return ProfileUpdateResult.failure('User not authenticated');
      }

      String avatarUrl;

      if (bytes != null) {
        AppLogger.debug(
          '_updateProfilePhotoWithData: Uploading ${bytes.length} bytes',
        );
        final uploadResult = await uploadService.uploadBytes(
          bytes,
          'profile_photo.jpg',
          'image/jpeg',
        );
        avatarUrl = uploadResult.contentUri;
        AppLogger.debug(
          '_updateProfilePhotoWithData: Upload complete, avatarUrl: $avatarUrl',
        );
      } else if (imageFile != null) {
        AppLogger.debug(
          '_updateProfilePhotoWithData: Uploading file: ${imageFile.path}',
        );
        final uploadResult = await uploadService.uploadFile(
          imageFile,
          mimeType: 'image/jpeg',
        );
        avatarUrl = uploadResult.contentUri;
      } else {
        AppLogger.warning(
          '_updateProfilePhotoWithData: No image data provided',
        );
        return ProfileUpdateResult.failure('No image data provided');
      }

      AppLogger.debug(
        '_updateProfilePhotoWithData: Updating profile with avatar URL',
      );

      final properties = common.Struct()
        ..fields['avatar_url'] = (common.Value()..stringValue = avatarUrl);

      final request = pb.UpdateRequest(
        id: userInfo!.id,
        properties: properties,
      );

      AppLogger.debug(
        '_updateProfilePhotoWithData: Calling profileClient.stub.update',
      );
      await profileClient.stub.update(request);
      AppLogger.debug('_updateProfilePhotoWithData: Profile update complete');

      AppLogger.debug('_updateProfilePhotoWithData: Updating local profile');
      await _updateLocalProfile(avatarUrl: avatarUrl);

      AppLogger.info('Profile photo updated', data: {'url': avatarUrl});
      return ProfileUpdateResult.success();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to update profile photo',
        error: e,
        stackTrace: stackTrace,
      );
      return ProfileUpdateResult.failure(e.toString());
    }
  }

  /// Get all contacts (emails and phones) for the current user
  Future<List<ContactInfo>> getContacts() async {
    final db = AppDatabase.instance;
    final userInfo = await _ref.read(userInfoProvider.future);

    if (userInfo?.id == null) return [];

    // Get roster entries for current user
    final query = db.select(db.roster)
      ..where((t) => t.profileId.equals(userInfo!.id!));

    final entries = await query.get();

    return entries.map((entry) {
      return ContactInfo(
        id: entry.id,
        type: entry.contactType == 0 ? ContactType.email : ContactType.phone,
        value: entry.contactDetail,
        isVerified: entry.isVerified,
      );
    }).toList();
  }

  /// Add a new email contact
  Future<ProfileUpdateResult> addEmail(String email) async {
    try {
      final profileClient = await _ref.read(profileClientProvider.future);

      final rawContact = pb.RawContact(contact: email);

      final request = pb.AddRosterRequest(data: [rawContact]);

      await profileClient.stub.addRoster(request);

      AppLogger.info('Email added to profile', data: {'email': email});
      return ProfileUpdateResult.success();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to add email', error: e, stackTrace: stackTrace);
      return ProfileUpdateResult.failure(e.toString());
    }
  }

  /// Add a new phone contact
  Future<ProfileUpdateResult> addPhone(String phone) async {
    try {
      final profileClient = await _ref.read(profileClientProvider.future);

      final rawContact = pb.RawContact(contact: phone);

      final request = pb.AddRosterRequest(data: [rawContact]);

      await profileClient.stub.addRoster(request);

      AppLogger.info('Phone added to profile', data: {'phone': phone});
      return ProfileUpdateResult.success();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to add phone', error: e, stackTrace: stackTrace);
      return ProfileUpdateResult.failure(e.toString());
    }
  }

  /// Remove a contact by ID
  Future<ProfileUpdateResult> removeContact(String contactId) async {
    try {
      final profileClient = await _ref.read(profileClientProvider.future);

      final request = pb.RemoveRosterRequest(id: contactId);

      await profileClient.stub.removeRoster(request);

      // Remove from local database
      final db = AppDatabase.instance;
      await (db.delete(db.roster)..where((t) => t.id.equals(contactId))).go();

      AppLogger.info('Contact removed', data: {'contactId': contactId});
      return ProfileUpdateResult.success();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to remove contact',
        error: e,
        stackTrace: stackTrace,
      );
      return ProfileUpdateResult.failure(e.toString());
    }
  }

  /// Start verification for a contact (sends verification code)
  Future<ProfileUpdateResult> startContactVerification(String contactId) async {
    try {
      final profileClient = await _ref.read(profileClientProvider.future);

      final request = pb.CreateContactVerificationRequest(contactId: contactId);

      await profileClient.stub.createContactVerification(request);

      AppLogger.info('Verification started', data: {'contactId': contactId});
      return ProfileUpdateResult.success();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to start verification',
        error: e,
        stackTrace: stackTrace,
      );
      return ProfileUpdateResult.failure(e.toString());
    }
  }

  /// Verify a contact with the provided code
  Future<ProfileUpdateResult> verifyContact(
    String contactId,
    String code,
  ) async {
    try {
      final profileClient = await _ref.read(profileClientProvider.future);

      final request = pb.CheckVerificationRequest(id: contactId, code: code);

      final response = await profileClient.stub.checkVerification(request);

      if (response.success) {
        // Update local database to mark as verified
        final db = AppDatabase.instance;
        await (db.update(db.roster)..where((t) => t.id.equals(contactId)))
            .write(const RosterCompanion(isVerified: drift.Value(true)));

        AppLogger.info('Contact verified', data: {'contactId': contactId});
        return ProfileUpdateResult.success();
      } else {
        return ProfileUpdateResult.failure('Verification failed');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to verify contact',
        error: e,
        stackTrace: stackTrace,
      );
      return ProfileUpdateResult.failure(e.toString());
    }
  }

  /// Update local profile in database
  Future<void> _updateLocalProfile({
    String? name,
    String? avatarUrl,
    String? bio,
    UserStatus? status,
    String? statusMessage,
  }) async {
    final db = AppDatabase.instance;
    final userInfo = await _ref.read(userInfoProvider.future);

    if (userInfo?.id == null) return;

    // If bio is provided, we need to update the metadata field
    String? metadata;
    if (bio != null) {
      // Get existing profile to preserve other metadata
      final existingProfile = await getCurrentProfile();
      final existingMetadata = existingProfile?.metadata;

      var metadataMap = <String, dynamic>{};
      if (existingMetadata != null && existingMetadata.isNotEmpty) {
        try {
          metadataMap = jsonDecode(existingMetadata) as Map<String, dynamic>;
        } catch (_) {
          // Ignore parsing errors, start fresh
        }
      }
      metadataMap['bio'] = bio;
      metadata = jsonEncode(metadataMap);
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    final companion = ProfilesCompanion(
      id: drift.Value(userInfo!.id!),
      name: name != null ? drift.Value(name) : const drift.Value.absent(),
      avatarUrl: avatarUrl != null
          ? drift.Value(avatarUrl)
          : const drift.Value.absent(),
      metadata: metadata != null
          ? drift.Value(metadata)
          : const drift.Value.absent(),
      status: status != null
          ? drift.Value(status.value)
          : const drift.Value.absent(),
      statusMessage: statusMessage != null
          ? drift.Value(statusMessage)
          : const drift.Value.absent(),
      statusUpdatedAt: status != null
          ? drift.Value(now)
          : const drift.Value.absent(),
      updatedAt: drift.Value(now),
    );

    await db.into(db.profiles).insertOnConflictUpdate(companion);
  }

  /// Sync profile from server to local database
  Future<void> syncProfile() async {
    try {
      final profileClient = await _ref.read(profileClientProvider.future);
      final userInfo = await _ref.read(userInfoProvider.future);

      if (userInfo?.id == null) return;

      final request = pb.GetByIdRequest(id: userInfo!.id);
      final response = await profileClient.stub.getById(request);

      if (response.hasData()) {
        final profile = response.data;
        final db = AppDatabase.instance;

        // Extract properties if available
        String? name;
        String? avatarUrl;
        String? bio;
        int? status;
        String? statusMessage;
        if (profile.hasProperties()) {
          final props = profile.properties;
          if (props.fields.containsKey('name')) {
            name = props.fields['name']?.stringValue;
          }
          if (props.fields.containsKey('avatar_url')) {
            avatarUrl = props.fields['avatar_url']?.stringValue;
          }
          if (props.fields.containsKey('bio')) {
            bio = props.fields['bio']?.stringValue;
          }
          if (props.fields.containsKey('status')) {
            status = props.fields['status']?.numberValue.toInt();
          }
          if (props.fields.containsKey('status_message')) {
            statusMessage = props.fields['status_message']?.stringValue;
          }
        }

        // Build metadata JSON if bio is present
        String? metadata;
        if (bio != null) {
          metadata = jsonEncode({'bio': bio});
        }

        final now = DateTime.now().millisecondsSinceEpoch;

        await db
            .into(db.profiles)
            .insertOnConflictUpdate(
              ProfilesCompanion(
                id: drift.Value(profile.id),
                name: drift.Value(name),
                avatarUrl: drift.Value(avatarUrl),
                metadata: metadata != null
                    ? drift.Value(metadata)
                    : const drift.Value.absent(),
                status: status != null
                    ? drift.Value(status)
                    : const drift.Value.absent(),
                statusMessage: statusMessage != null
                    ? drift.Value(statusMessage)
                    : const drift.Value.absent(),
                statusUpdatedAt: status != null
                    ? drift.Value(now)
                    : const drift.Value.absent(),
                updatedAt: drift.Value(now),
              ),
            );

        AppLogger.info('Profile synced from server');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to sync profile',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Provider for ProfileRepository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref);
});
