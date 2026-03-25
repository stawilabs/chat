import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/db/database.dart';
import 'package:stawi/features/auth/data/user_info_provider.dart';
import 'package:stawi/features/profile/data/profile_repository.dart';
import 'package:stawi/features/profile/domain/user_status.dart';
import 'package:stawi/features/profile/ui/profile_edit_screen.dart';

/// Mock ProfileRepository for testing
class MockProfileRepository implements ProfileRepository {
  List<ContactInfo> mockContacts = [];
  bool shouldFail = false;
  String? failureMessage;

  @override
  Future<ProfileUpdateResult> addEmail(String email) async {
    if (shouldFail) {
      return ProfileUpdateResult.failure(failureMessage ?? 'Failed');
    }
    mockContacts.add(
      ContactInfo(
        id: 'email-${mockContacts.length}',
        type: ContactType.email,
        value: email,
      ),
    );
    return ProfileUpdateResult.success();
  }

  @override
  Future<ProfileUpdateResult> addPhone(String phone) async {
    if (shouldFail) {
      return ProfileUpdateResult.failure(failureMessage ?? 'Failed');
    }
    mockContacts.add(
      ContactInfo(
        id: 'phone-${mockContacts.length}',
        type: ContactType.phone,
        value: phone,
      ),
    );
    return ProfileUpdateResult.success();
  }

  @override
  Future<List<ContactInfo>> getContacts() async {
    return mockContacts;
  }

  @override
  Future<Profile?> getCurrentProfile() async {
    return null;
  }

  @override
  Future<String?> getCurrentBio() async {
    return null;
  }

  @override
  Future<ProfileUpdateResult> removeContact(String contactId) async {
    if (shouldFail) {
      return ProfileUpdateResult.failure(failureMessage ?? 'Failed');
    }
    mockContacts.removeWhere((c) => c.id == contactId);
    return ProfileUpdateResult.success();
  }

  @override
  Future<ProfileUpdateResult> startContactVerification(String contactId) async {
    if (shouldFail) {
      return ProfileUpdateResult.failure(failureMessage ?? 'Failed');
    }
    return ProfileUpdateResult.success();
  }

  @override
  Future<void> syncProfile() async {}

  @override
  Future<ProfileUpdateResult> updateBio(String bio) async {
    if (shouldFail) {
      return ProfileUpdateResult.failure(failureMessage ?? 'Failed');
    }
    return ProfileUpdateResult.success();
  }

  @override
  Future<ProfileUpdateResult> updateDisplayName(String name) async {
    if (shouldFail) {
      return ProfileUpdateResult.failure(failureMessage ?? 'Failed');
    }
    return ProfileUpdateResult.success();
  }

  @override
  Future<ProfileUpdateResult> updateProfilePhoto(File imageFile) async {
    if (shouldFail) {
      return ProfileUpdateResult.failure(failureMessage ?? 'Failed');
    }
    return ProfileUpdateResult.success();
  }

  @override
  Future<ProfileUpdateResult> updateProfilePhotoBytes(Uint8List bytes) async {
    if (shouldFail) {
      return ProfileUpdateResult.failure(failureMessage ?? 'Failed');
    }
    return ProfileUpdateResult.success();
  }

  @override
  Future<ProfileUpdateResult> verifyContact(
    String contactId,
    String code,
  ) async {
    if (shouldFail) {
      return ProfileUpdateResult.failure(failureMessage ?? 'Failed');
    }
    return ProfileUpdateResult.success();
  }

  @override
  Future<ProfileUpdateResult> updateStatus(
    UserStatus status, {
    String? statusMessage,
  }) async {
    if (shouldFail) {
      return ProfileUpdateResult.failure(failureMessage ?? 'Failed');
    }
    return ProfileUpdateResult.success();
  }

  @override
  Future<UserStatus> getCurrentStatus() async {
    return UserStatus.offline;
  }

  @override
  Future<String?> getCurrentStatusMessage() async {
    return null;
  }

  @override
  Future<ProfileUpdateResult> clearStatusMessage() async {
    return ProfileUpdateResult.success();
  }
}

/// Mock UserInfo for testing
class MockUserInfo extends UserInfo {
  const MockUserInfo({
    super.id = 'test-user-id',
    super.name = 'Test User',
    super.email = 'test@example.com',
    super.picture,
    super.phone,
  });
}

void main() {
  late MockProfileRepository mockProfileRepo;

  setUp(() {
    mockProfileRepo = MockProfileRepository();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockProfileRepo),
        userInfoProvider.overrideWith((ref) async => const MockUserInfo()),
      ],
      child: const MaterialApp(home: ProfileEditScreen()),
    );
  }

  group('ProfileEditScreen', () {
    testWidgets('displays app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
    });

    testWidgets('displays Save button in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('displays display name section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Display Name'), findsOneWidget);
    });

    testWidgets('displays about section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('displays email addresses section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Email Addresses'), findsOneWidget);
    });

    testWidgets('displays phone numbers section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Phone Numbers'), findsOneWidget);
    });

    testWidgets('displays tap to add photo text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Tap to add a photo'), findsOneWidget);
    });

    testWidgets('shows empty state when no emails', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No email addresses added'), findsOneWidget);
    });

    testWidgets('shows empty state when no phones', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No phone numbers added'), findsOneWidget);
    });

    testWidgets('displays contacts when they exist', (tester) async {
      mockProfileRepo.mockContacts = [
        const ContactInfo(
          id: 'email-1',
          type: ContactType.email,
          value: 'test@example.com',
          isVerified: true,
        ),
        const ContactInfo(
          id: 'phone-1',
          type: ContactType.phone,
          value: '+1234567890',
        ),
      ];

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('+1234567890'), findsOneWidget);
    });

    testWidgets('displays verified badge for verified contacts', (
      tester,
    ) async {
      mockProfileRepo.mockContacts = [
        const ContactInfo(
          id: 'email-1',
          type: ContactType.email,
          value: 'verified@example.com',
          isVerified: true,
        ),
      ];

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets('displays not verified badge for unverified contacts', (
      tester,
    ) async {
      mockProfileRepo.mockContacts = [
        const ContactInfo(
          id: 'email-1',
          type: ContactType.email,
          value: 'unverified@example.com',
        ),
      ];

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Not verified'), findsOneWidget);
    });

    testWidgets('has add button for email section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find add buttons (there should be 2 - one for emails, one for phones)
      expect(find.byIcon(Icons.add_circle_outline), findsNWidgets(2));
    });

    testWidgets('can enter display name', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'New Name');

      expect(find.text('New Name'), findsOneWidget);
    });

    testWidgets('displays camera icon on avatar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('displays back arrow', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('has delete button for contacts', (tester) async {
      mockProfileRepo.mockContacts = [
        const ContactInfo(
          id: 'email-1',
          type: ContactType.email,
          value: 'test@example.com',
        ),
      ];

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });
}
